import ballerina/time;

// Turn a YYYY-MM-DD string into a day count (days since epoch) so dates can
// be compared and subtracted. Returns an error message on bad input instead
// of an `error`, so callers can fold it straight into a response message.
function dayNumber(string date) returns int|string {
    time:Utc|time:Error utc = time:utcFromString(date + "T00:00:00.00Z");
    if utc is time:Error {
        return "'" + date + "' is not a valid date. Use YYYY-MM-DD.";
    }
    return <int>(utc[0] / 86400);
}

// Check-out must be strictly after check-in.
function validateStay(string checkIn, string checkOut) returns string? {
    int|string inDay = dayNumber(checkIn);
    if inDay is string {
        return inDay;
    }
    int|string outDay = dayNumber(checkOut);
    if outDay is string {
        return outDay;
    }
    if outDay <= inDay {
        return "checkOut must be a date after checkIn.";
    }
    return ();
}

// Number of nights between two already-validated dates.
function nightsBetween(string checkIn, string checkOut) returns int|string {
    int|string inDay = dayNumber(checkIn);
    if inDay is string {
        return inDay;
    }
    int|string outDay = dayNumber(checkOut);
    if outDay is string {
        return outDay;
    }
    return outDay - inDay;
}

// True if [aIn, aOut) and [bIn, bOut) share any night.
function datesOverlap(string aIn, string aOut, string bIn, string bOut) returns boolean {
    int|string aInDay = dayNumber(aIn);
    int|string aOutDay = dayNumber(aOut);
    int|string bInDay = dayNumber(bIn);
    int|string bOutDay = dayNumber(bOut);
    if aInDay is string || aOutDay is string || bInDay is string || bOutDay is string {
        // Already validated earlier in the flow — treat as no overlap rather
        // than fail confirm_booking on a malformed stored record.
        return false;
    }
    return aInDay < bOutDay && bInDay < aOutDay;
}