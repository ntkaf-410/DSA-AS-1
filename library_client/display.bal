import ballerina/io;

// Pad a string with a trailing fill character so simple tables line up in the terminal.
function padRight(string text, int width, string fillChar = " ") returns string {
    string result = text;
    while result.length() < width {
        result += fillChar;
    }
    return result;
}

function io_ok(string verb) {
    io:println("  [OK] " + verb + " succeeded.");
}

function io_error(string message) {
    io:println("  [ERROR] " + message);
}

// Print the full detail of a single asset, including its schedules.
function printAssetSummary(Asset asset) {
    io:println("");
    io:println("  Asset Tag   : " + asset.assetTag);
    io:println("  Name        : " + asset.name);
    io:println("  Description : " + asset.description);
    io:println("  Institution : " + asset.institution);
    io:println("  Site        : " + asset.site);
    io:println("  Status      : " + asset.status);
    io:println("  Acquired    : " + asset.dateAcquired);
    if asset.schedules.length() > 0 {
        io:println("  Schedules   :");
        foreach Schedule s in asset.schedules {
            io:println("    - " + s.scheduleId + " [" + s.'type + "] due " + s.dueDate + " - " + s.description);
        }
    } else {
        io:println("  Schedules   : (none)");
    }
}

// Print a compact table of assets for the global/campus/overdue views.
function printAssetTable(Asset[] assets) {
    if assets.length() == 0 {
        io:println("  No assets found.");
        return;
    }
    io:println("  " + padRight("Asset Tag", 18) + padRight("Name", 26) +
            padRight("Institution", 20) + padRight("Site", 28) + padRight("Status", 16) + "Due Date");
    io:println("  " + padRight("", 108, "-"));
    foreach Asset asset in assets {
        string dueDate = earliestDueDate(asset);
        io:println("  " + padRight(asset.assetTag, 18) + padRight(truncate(asset.name, 24), 26) +
                padRight(truncate(asset.institution, 18), 20) + padRight(truncate(asset.site, 26), 28) +
                padRight(asset.status, 16) + dueDate);
    }
}

// Shorten long text so table columns stay aligned.
function truncate(string text, int maxLength) returns string {
    if text.length() <= maxLength {
        return text;
    }
    int cut = maxLength - 3;
    if cut < 0 {
        cut = 0;
    }
    return text.substring(0, cut) + "...";
}

// Find the nearest maintenance/servicing due date for the table's "Due Date" column.
function earliestDueDate(Asset asset) returns string {
    string? earliest = ();
    foreach Schedule s in asset.schedules {
        if s.'type == "MAINTENANCE" || s.'type == "SERVICING" {
            if earliest is () || s.dueDate < earliest {
                earliest = s.dueDate;
            }
        }
    }
    return earliest ?: "-";
}
