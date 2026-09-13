// In-memory persistence for the rental accommodation system.
// Everything lives in maps for the lifetime of the process, as the
// assignment allows (Ballerina maps/tables as the data store).

// Properties keyed by propertyId.
map<Property> propertyStore = {};

// Registered Hosts/Guests keyed by userId.
map<UserProfile> userStore = {};

// A pending request sitting in the temporary booking cart, waiting on
// confirm_booking. Not part of the .proto contract — purely server-side.
type PendingBooking record {|
    string bookingId;
    string guestId;
    string propertyId;
    string checkIn;
    string checkOut;
|};

// A booking that has already been confirmed, kept around so future
// confirm_booking calls can be checked against it for date overlaps.
type ConfirmedBooking record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
|};

map<PendingBooking> bookingCart = {};
ConfirmedBooking[] confirmedBookings = [];

int propertyCounter = 0;
int bookingCounter = 0;

// Simple counter-based ids — fine for an in-memory, single-process server.
function nextPropertyId() returns string {
    propertyCounter += 1;
    return string `PROP-${propertyCounter}`;
}

function nextBookingId() returns string {
    bookingCounter += 1;
    return string `BOOK-${bookingCounter}`;
}