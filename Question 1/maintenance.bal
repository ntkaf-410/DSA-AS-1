import ballerina/time;

// Return today's date in UTC.
function currentDate() returns string {
    return time:utcToString(time:utcNow()).substring(0, 10);
}

// Check the date format and calendar day.
function isValidDate(string value) returns boolean {
    if value.length() != 10 || value.substring(4, 5) != "-" || value.substring(7, 8) != "-" {
        return false;
    }
    int[] characters = value.toCodePointInts();
    foreach int index in 0 ..< 10 {
        if index == 4 || index == 7 {
            continue;
        }
        int digit = characters[index];
        if digit < 48 || digit > 57 {
            return false;
        }
    }
    int|error year = int:fromString(value.substring(0, 4));
    int|error month = int:fromString(value.substring(5, 7));
    int|error day = int:fromString(value.substring(8, 10));
    if year is error || month is error || day is error {
        return false;
    }
    return year > 0 && time:dateValidate({year, month, day}) is ();
}

// Find a past maintenance or servicing date for an asset.
function hasOverdueMaintenance(Asset asset, string cutoff) returns boolean {
    foreach Schedule schedule in asset.schedules {
        if (schedule.'type == "MAINTENANCE" || schedule.'type == "SERVICING") &&
                isValidDate(schedule.dueDate) && schedule.dueDate < cutoff {
            return true;
        }
    }
    return false;
}
