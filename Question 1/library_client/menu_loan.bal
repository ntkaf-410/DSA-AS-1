import ballerina/http;
import ballerina/io;

// Lets a staff member either loan out an asset (e.g. a laptop or book) or book a
// room/lab for a specific date, then pushes the change back to the API with a
// single PUT so the asset's status and schedule list stay consistent.
function runLoanBookingMenu() returns error? {
    string assetTag = io:readln("\nEnter the assetTag to loan or book: ").trim();
    Asset|error result = getAsset(assetTag);
    if result is error {
        io_error("Could not find asset '" + assetTag + "': " + result.message());
        return;
    }
    Asset asset = result;
    printAssetSummary(asset);

    if asset.status != "AVAILABLE" {
        io:println("\n  This resource is currently '" + asset.status + "', not AVAILABLE.");
        string proceed = io:readln("  Proceed anyway? (y/N): ").trim().toLowerAscii();
        if proceed != "y" {
            io:println("  Cancelled.");
            return;
        }
    }

    io:println("\n  1. Loan this resource   (e.g. laptop, book, equipment)");
    io:println("  2. Book this resource   (e.g. meeting room, lab)");
    io:println("  0. Cancel");
    string action = io:readln("  Select an option: ").trim();

    if action == "1" {
        loanAsset(asset);
    } else if action == "2" {
        bookAsset(asset);
    } else {
        io:println("  Cancelled.");
    }
}

// Mark an asset as loaned out.
function loanAsset(Asset asset) {
    Asset updated = asset.clone();
    updated.status = "LOANED_OUT";
    http:Response|error response = apiClient->put("/assets/" + asset.assetTag, updated);
    printResult(response, "Loan of '" + asset.name + "' (" + asset.assetTag + ")", 200);
}

// Add a booking schedule for a room/lab and mark it occupied for that date.
function bookAsset(Asset asset) {
    string scheduleId = io:readln("  Booking reference (scheduleId): ").trim();
    string dueDate = io:readln("  Booking date (YYYY-MM-DD): ").trim();
    string description = io:readln("  Purpose / time slot: ").trim();

    Schedule booking = {scheduleId, 'type: "BOOKING", dueDate, description};

    Asset updated = asset.clone();
    updated.status = "OCCUPIED";
    updated.schedules.push(booking);

    http:Response|error response = apiClient->put("/assets/" + asset.assetTag, updated);
    printResult(response, "Booking of '" + asset.name + "' (" + asset.assetTag + ") for " + dueDate, 200);
}
