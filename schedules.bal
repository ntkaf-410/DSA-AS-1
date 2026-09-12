// Find a schedule by its identifier within an asset.
function findScheduleIndex(Asset asset, string scheduleId) returns int? {
    foreach int index in 0 ..< asset.schedules.length() {
        if asset.schedules[index].scheduleId == scheduleId {
            return index;
        }
    }
    return ();
}

// Check the required schedule details before saving.
function validateSchedule(Schedule schedule) returns string? {
    if schedule.scheduleId.trim() == "" || schedule.description.trim() == "" {
        return "scheduleId and description must not be blank.";
    }
    if schedule.'type != "BOOKING" && schedule.'type != "MAINTENANCE" && schedule.'type != "SERVICING" {
        return "Schedule type must be BOOKING, MAINTENANCE, or SERVICING.";
    }
    if !isValidDate(schedule.dueDate) {
        return "dueDate must be a valid date in YYYY-MM-DD format.";
    }
    return ();
}
