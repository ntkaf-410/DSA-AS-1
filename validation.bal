// Check asset details and nested records before saving.
function validateAsset(Asset asset) returns string? {
    if asset.assetTag.trim() == "" || asset.name.trim() == "" || asset.description.trim() == "" ||
            asset.institution.trim() == "" || asset.site.trim() == "" {
        return "assetTag, name, description, institution, and site must not be blank.";
    }
    if !isValidDate(asset.dateAcquired) {
        return "dateAcquired must be a valid date in YYYY-MM-DD format.";
    }
    map<boolean> scheduleIds = {};
    foreach Schedule schedule in asset.schedules {
        string? problem = validateSchedule(schedule);
        if problem is string {
            return problem;
        }
        if scheduleIds.hasKey(schedule.scheduleId) {
            return "Schedule identifiers must be unique within an asset.";
        }
        scheduleIds[schedule.scheduleId] = true;
    }
    map<boolean> orderIds = {};
    foreach WorkOrder workOrder in asset.workOrders {
        string? problem = validateWorkOrder(workOrder);
        if problem is string {
            return problem;
        }
        if orderIds.hasKey(workOrder.orderId) {
            return "Work order identifiers must be unique within an asset.";
        }
        orderIds[workOrder.orderId] = true;
    }
    return ();
}
