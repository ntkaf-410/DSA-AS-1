import ballerina/io;

// Lists every asset across every institution/campus in the ministry.
function runGlobalView() returns error? {
    Asset[]|error result = getAssets("/assets");
    if result is error {
        io_error("Could not load assets: " + result.message());
        return;
    }
    io:println("\n--- Global Asset View (" + result.length().toString() + " asset(s)) ---");
    printAssetTable(result);
}

// Filters resources by institution and/or site/campus.
function runCampusView() returns error? {
    string institution = io:readln("\nInstitution (leave blank to skip): ").trim();
    string site = io:readln("Site / campus (leave blank to skip): ").trim();

    string[] params = [];
    do {
        if institution != "" {
            params.push("institution=" + check urlEncode(institution));
        }
        if site != "" {
            params.push("site=" + check urlEncode(site));
        }
    } on fail error e {
        io_error("Could not encode filter values: " + e.message());
        return;
    }

    string path = appendQuery("/assets", params);
    Asset[]|error result = getAssets(path);
    if result is error {
        io_error("Could not load assets: " + result.message());
        return;
    }
    io:println("\n--- Campus View (" + result.length().toString() + " asset(s)) ---");
    printAssetTable(result);
}

// Shows assets with a maintenance/servicing schedule that is already past due,
// optionally scoped to an institution and/or site, and to a chosen as-of date.
function runOverdueDashboard() returns error? {
    string asOf = io:readln("\nAs-of date (YYYY-MM-DD, blank = today): ").trim();
    string institution = io:readln("Institution filter (blank to skip): ").trim();
    string site = io:readln("Site filter (blank to skip): ").trim();

    string[] params = [];
    do {
        if asOf != "" {
            params.push("asOf=" + check urlEncode(asOf));
        }
        if institution != "" {
            params.push("institution=" + check urlEncode(institution));
        }
        if site != "" {
            params.push("site=" + check urlEncode(site));
        }
    } on fail error e {
        io_error("Could not encode filter values: " + e.message());
        return;
    }

    string path = appendQuery("/overdue", params);
    Asset[]|error result = getAssets(path);
    if result is error {
        io_error("Could not load overdue assets: " + result.message());
        return;
    }
    io:println("\n--- Overdue Dashboard (" + result.length().toString() + " item(s)) ---");
    printAssetTable(result);
}
