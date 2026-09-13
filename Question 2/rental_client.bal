
// gRPC Client + Testing
//
// It walks through the full guest/host journey end-to-end, so running it is
// also an integration test of the whole system:
//
// HOW TO RUN:
//   `bal run` from inside this folder. Because the gRPC listener (server) and
//   this client both live in the same module, one command starts the server
//   AND drives the client against it so theres no need for two terminals.


import ballerina/grpc;
import ballerina/io;

// Address of the RentalService server. Kept configurable so it can be pointed
// at a different host/port (e.g. in Config.toml) without touching the code.
configurable string serverUrl = "http://localhost:9090";

public function main() {
    // `do`/`on fail` catches any error bubbling up from the `check`s below so
    // one failed step prints a clear message instead of crashing the client.
    do {
        io:println(" Rental Accommodation System — gRPC Client Demo");

        // Connect to the server. This does not open the network connection
        // yet the generated client dials lazily on the first real call.
        RentalServiceClient rentalClient = check new (serverUrl);

        io:println("\n Step 1: Register a Host and a Guest (client streaming)");
        check registerUsers(rentalClient);

        io:println("\nStep 2: Host lists a new property (simple RPC)");
        string propertyId = check addSampleProperty(rentalClient);

        io:println("\nStep 3: Guest browses available properties (server streaming)");
        check browseProperties(rentalClient);

        io:println("\nStep 4: Guest looks up that property by id (simple RPC)");
        check searchForProperty(rentalClient, propertyId);

        io:println("\nStep 5: Guest books the stay, then confirms it (simple RPCs)");
        check bookAndConfirm(rentalClient, propertyId);

        io:println(" Done — full booking flow completed successfully.");
    } on fail error e {
        io:println("\nClient run failed: ", e.message());
    }
}

function registerUsers(RentalServiceClient rentalClient) returns error? {
    // Opens the stream — nothing is sent to the server yet.
    Create_usersStreamingClient userStream = check rentalClient->create_users();

    UserProfile host = {user_id: "U-HOST-1", name: "Nangula Amutenya", email: "nangula@host.example", role: HOST};
    UserProfile guest = {user_id: "U-GUEST-1", name: "Petrus Shipanga", email: "petrus@guest.example", role: GUEST};

    check userStream->sendUserProfile(host);
    check userStream->sendUserProfile(guest);

    // Half-close the stream: tells the server were done sending
    check userStream->complete();

    // The server then sends back exactly one Confirmation message
    Confirmation? confirmation = check userStream->receiveConfirmation();
    if confirmation is Confirmation {
        io:println("Server response: ", confirmation.message);
    } else {
        io:println("Server closed the stream without sending a confirmation.");
    }
}


// Step 2 SIMPLE RPC
// One request in, one response out. Straightforward request/response call.
function addSampleProperty(RentalServiceClient rentalClient) returns string|error {
    NewProperty newProperty = {
        host_id: "U-HOST-1",
        name: "Seaside Apartment",
        location: "Swakopmund",
        property_type: APARTMENT,
        price_per_night: 950.0,
        status: AVAILABLE
    };

    PropertyId created = check rentalClient->add_property(newProperty);
    io:println("Property created with id: ", created.property_id);
    return created.property_id;
}


// Step 3 — SERVER STREAMING
// One request goes out, but the server can reply with many messages over the
// same call. `forEach` pulls messages off the stream, one at a time, until
// the server closes it
function browseProperties(RentalServiceClient rentalClient) returns error? {
    // An empty filter means "no location/price restriction — show everything"
    PropertyFilter filter = {};
    stream<Property, grpc:Error?> propertyStream = check rentalClient->list_available_properties(filter);

    int count = 0;
    error? streamErr = propertyStream.forEach(function(Property p) {
        count += 1;
        io:println(string `  [${p.property_id}] ${p.name} — ${p.location} — $${p.price_per_night.toString()}/night`);
    });

    if streamErr is error {
        io:println("Error while reading the property stream: ", streamErr.message());
        return streamErr;
    }
    io:println("Received ", count, " available propert(y/ies) from the stream.");
}


// Step 4. SIMPLE RPC
function searchForProperty(RentalServiceClient rentalClient, string propertyId) returns error? {
    SearchResponse response = check rentalClient->search_property({property_id: propertyId});
    io:println("Available: ", response.available.toString(), " — ", response.message);
}


// Step 5 — BOOKING + CONFIRMATION (two simple RPCs, chained) book_property only holds the dates in a temporary cart; nothing is
// committed until confirm_booking re-checks availability and finalizes it.
function bookAndConfirm(RentalServiceClient rentalClient, string propertyId) returns error? {
    BookingRequest request = {
        guest_id: "U-GUEST-1",
        property_id: propertyId,
        check_in: "2026-10-10",
        check_out: "2026-10-14"
    };

    // 5a. Ask the server to hold these dates.
    BookingCartEntry cartEntry = check rentalClient->book_property(request);
    io:println("book_property: ", cartEntry.message);

    if !cartEntry.accepted {
        io:println("Booking was rejected before confirmation — stopping here.");
        return;
    }

    // 5b. Finalize the held booking.
    BookingConfirmation confirmation = check rentalClient->confirm_booking({booking_id: cartEntry.booking_id});
    if confirmation.success {
        io:println(string `Booking ${confirmation.booking_id} confirmed: ${confirmation.nights} night(s), total $${confirmation.total_cost.toString()}`);
    } else {
        io:println("Booking confirmation failed: ", confirmation.message);
    }
}
