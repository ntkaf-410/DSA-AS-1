import ballerina/http;

// Find a work order by its identifier within an asset.
function findWorkOrderIndex(Asset asset, string orderId) returns int? {
    foreach int index in 0 ..< asset.workOrders.length() {
        if asset.workOrders[index].orderId == orderId {
            return index;
        }
    }
    return ();
}

// Find a work order or return the missing record response.
function lookupWorkOrder(string assetTag, string orderId) returns WorkOrder|http:NotFound {
    Asset? asset = assetStore[assetTag];
    if asset is () {
        return notFound("Asset", assetTag);
    }
    int? index = findWorkOrderIndex(asset, orderId);
    if index is () {
        return notFound("Work order", orderId);
    }
    return asset.workOrders[index];
}

// Find a task by its identifier within a work order.
function findTaskIndex(WorkOrder workOrder, string taskId) returns int? {
    foreach int index in 0 ..< workOrder.tasks.length() {
        if workOrder.tasks[index].taskId == taskId {
            return index;
        }
    }
    return ();
}

// Check the required task details before saving.
function validateTask(Task task) returns string? {
    if task.taskId.trim() == "" || task.description.trim() == "" {
        return "taskId and description must not be blank.";
    }
    return ();
}

// Check a work order and reject duplicate task identifiers.
function validateWorkOrder(WorkOrder workOrder) returns string? {
    if workOrder.orderId.trim() == "" || workOrder.description.trim() == "" {
        return "orderId and description must not be blank.";
    }
    if workOrder.status != "OPEN" && workOrder.status != "IN_PROGRESS" && workOrder.status != "CLOSED" {
        return "Work order status must be OPEN, IN_PROGRESS, or CLOSED.";
    }
    map<boolean> taskIds = {};
    foreach Task task in workOrder.tasks {
        string? problem = validateTask(task);
        if problem is string {
            return problem;
        }
        if taskIds.hasKey(task.taskId) {
            return "Task identifiers must be unique within a work order.";
        }
        taskIds[task.taskId] = true;
    }
    return ();
}
