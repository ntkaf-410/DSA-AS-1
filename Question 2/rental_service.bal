import ballerina/grpc;

// Once you run `bal grpc --input rental.proto --output .`, replace the two
// lines above the service block below with whatever @grpc:Descriptor
// annotation the tool generated, and delete the generated skeleton's own
// empty service block so you don't get a duplicate declaration.

configurable int grpcPort = 9090;
listener grpc:Listener rentalListener = new (grpcPort);

service "RentalService" on rentalListener {

    // Host lists a new property. Status defaults to AVAILABLE if the
    // client leaves it unset.
    remote function add_property(NewProperty value) returns PropertyId|error {
        if value.host_id.trim() == "" || value.name.trim() == "" || value.location.trim() == "" {
            return error("host_id, name, and location are required.");
        }
        if value.price_per_night <= 0.0 {
            return error("price_per_night must be greater than zero.");
        }

        string propertyId = nextPropertyId();
        Property property = {
            property_id: propertyId,
            host_id: value.host_id,
            name: value.name,
            location: value.location,
            property_type: value.property_type,
            price_per_night: value.price_per_night,
            status: value.status == PROPERTY_STATUS_UNSPECIFIED ? AVAILABLE : value.status
        };
        propertyStore[propertyId] = property;
        return {property_id: propertyId};
    }

    // Client streaming — register a batch of Hosts/Guests, then send one
    // confirmation once the client closes the stream.
    remote function create_users(stream<UserProfile, grpc:Error?> clientStream) returns Confirmation|error {
        int registered = 0;
        error? streamErr = clientStream.forEach(function(UserProfile user) {
            if user.user_id.trim() != "" && !userStore.hasKey(user.user_id) {
                userStore[user.user_id] = user;
                registered += 1;
            }
        });
        if streamErr is error {
            return error("Failed while receiving user profiles: " + streamErr.message());
        }
        return {
            success: true,
            users_registered: registered,
            message: registered.toString() + " user profile(s) registered."
        };
    }

    // Host edits a listing. Fields left at their zero value (empty string,
    // 0, or *_UNSPECIFIED) are treated as "leave unchanged" so a client
    // can patch just the price or just the status.
    remote function update_property(UpdatePropertyRequest value) returns Property|error {
        Property? existing = propertyStore[value.property_id];
        if existing is () {
            return error("Property '" + value.property_id + "' was not found.");
        }
        if existing.host_id != value.host_id {
            return error("host_id does not match the owner of this property.");
        }

        Property updated = {
            property_id: existing.property_id,
            host_id: existing.host_id,
            name: value.name.trim() == "" ? existing.name : value.name,
            location: value.location.trim() == "" ? existing.location : value.location,
            property_type: value.property_type == PROPERTY_TYPE_UNSPECIFIED ? existing.property_type : value.property_type,
            price_per_night: value.price_per_night > 0.0 ? value.price_per_night : existing.price_per_night,
            status: value.status == PROPERTY_STATUS_UNSPECIFIED ? existing.status : value.status
        };
        propertyStore[value.property_id] = updated;
        return updated;
    }

    // Host deletes a listing. Responds with the Host's remaining available
    // properties so the client can refresh its view in one round trip.
    remote function remove_property(RemovePropertyRequest value) returns PropertyList|error {
        Property? existing = propertyStore[value.property_id];
        if existing is () {
            return error("Property '" + value.property_id + "' was not found.");
        }
        if existing.host_id != value.host_id {
            return error("host_id does not match the owner of this property.");
        }
        _ = propertyStore.remove(value.property_id);

        Property[] remaining = [];
        foreach Property p in propertyStore {
            if p.host_id == value.host_id && p.status == AVAILABLE {
                remaining.push(p);
            }
        }
        return {properties: remaining};
    }

    // Server streaming — push back every AVAILABLE property matching the
    // filter, one message at a time.
    remote function list_available_properties(PropertyFilter value) returns stream<Property, error?>|error {
        Property[] matches = [];
        foreach Property p in propertyStore {
            if p.status != AVAILABLE {
                continue;
            }
            if value.location.trim() != "" && !p.location.toLowerAscii().includes(value.location.trim().toLowerAscii()) {
                continue;
            }
            if value.min_price > 0.0 && p.price_per_night < value.min_price {
                continue;
            }
            if value.max_price > 0.0 && p.price_per_night > value.max_price {
                continue;
            }
            matches.push(p);
        }
        return matches.toStream();
    }

    // Guest looks up one property by id.
    remote function search_property(SearchRequest value) returns SearchResponse|error {
        Property? found = propertyStore[value.property_id];
        if found is () {
            return {
                available: false,
                message: "Property '" + value.property_id + "' does not exist.",
                property: ()
            };
        }
        if found.status != AVAILABLE {
            return {
                available: false,
                message: "Property '" + value.property_id + "' is not available right now.",
                property: found
            };
        }
        return {
            available: true,
            message: "Property is available.",
            property: found
        };
    }

    // Guest asks to hold a property for given dates. Validated and parked
    // in the booking cart — nothing is committed until confirm_booking.
    remote function book_property(BookingRequest value) returns BookingCartEntry|error {
        Property? property = propertyStore[value.property_id];
        if property is () {
            return {booking_id: "", accepted: false, message: "Property '" + value.property_id + "' does not exist."};
        }
        string? problem = validateStay(value.check_in, value.check_out);
        if problem is string {
            return {booking_id: "", accepted: false, message: problem};
        }

        string bookingId = nextBookingId();
        bookingCart[bookingId] = {
            bookingId,
            guestId: value.guest_id,
            propertyId: value.property_id,
            checkIn: value.check_in,
            checkOut: value.check_out
        };
        return {
            booking_id: bookingId,
            accepted: true,
            message: "Held. Call confirm_booking with this booking_id to finalize."
        };
    }

    // Re-checks the cart entry against every confirmed booking for date
    // overlaps, prices the stay, commits it, and clears the cart entry.
    remote function confirm_booking(ConfirmBookingRequest value) returns BookingConfirmation|error {
        PendingBooking? pending = bookingCart[value.booking_id];
        if pending is () {
            return failedConfirmation(value.booking_id, "", "No pending booking found for booking_id '" + value.booking_id + "'.");
        }

        Property? property = propertyStore[pending.propertyId];
        if property is () {
            _ = bookingCart.remove(value.booking_id);
            return failedConfirmation(value.booking_id, pending.propertyId, "Property no longer exists.");
        }

        foreach ConfirmedBooking existing in confirmedBookings {
            if existing.propertyId == pending.propertyId &&
                    datesOverlap(pending.checkIn, pending.checkOut, existing.checkIn, existing.checkOut) {
                _ = bookingCart.remove(value.booking_id);
                return failedConfirmation(value.booking_id, pending.propertyId, "Those dates were just taken by another booking.");
            }
        }

        int|string nights = nightsBetween(pending.checkIn, pending.checkOut);
        if nights is string {
            _ = bookingCart.remove(value.booking_id);
            return failedConfirmation(value.booking_id, pending.propertyId, nights);
        }

        confirmedBookings.push({
            bookingId: pending.bookingId,
            propertyId: pending.propertyId,
            guestId: pending.guestId,
            checkIn: pending.checkIn,
            checkOut: pending.checkOut
        });
        _ = bookingCart.remove(value.booking_id);

        return {
            success: true,
            booking_id: pending.bookingId,
            property_id: pending.propertyId,
            nights: nights,
            total_cost: <float>nights * property.price_per_night,
            message: "Booking confirmed."
        };
    }
}

// Shared shape for every confirm_booking failure path — keeps the remote
// function above from repeating the same six-field record five times.
function failedConfirmation(string bookingId, string propertyId, string message) returns BookingConfirmation {
    return {
        success: false,
        booking_id: bookingId,
        property_id: propertyId,
        nights: 0,
        total_cost: 0.0,
        message: message
    };
}