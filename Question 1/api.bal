import ballerina/http;

configurable int port = 9090;
listener http:Listener apiListener = new (port);

service /api on apiListener {

    // List the work orders for an asset.
    resource function get assets/[string assetTag]/workorders() returns WorkOrder[]|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        return asset.workOrders;
    }

    // Look up one work order for an asset.
    resource function get assets/[string assetTag]/workorders/[string orderId]()
            returns WorkOrder|http:NotFound {
        return lookupWorkOrder(assetTag, orderId);
    }

    // Open a work order for an asset.
    resource function post assets/[string assetTag]/workorders(WorkOrder workOrder)
            returns WorkOrder|http:NotFound|http:BadRequest|http:Conflict {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        string? problem = validateWorkOrder(workOrder);
        if problem is string {
            return badRequest(problem);
        }
        if workOrder.status != "OPEN" {
            return badRequest("A new work order must have OPEN status.");
        }
        if findWorkOrderIndex(asset, workOrder.orderId) is int {
            return duplicateResponse("Work order", workOrder.orderId);
        }
        asset.workOrders.push(workOrder);
        return workOrder;
    }

    // Update a work order or close it with CLOSED status.
    resource function put assets/[string assetTag]/workorders/[string orderId](WorkOrder workOrder)
            returns WorkOrder|http:NotFound|http:BadRequest {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        int? index = findWorkOrderIndex(asset, orderId);
        if index is () {
            return notFound("Work order", orderId);
        }
        if workOrder.orderId != orderId {
            return badRequest("orderId in URL must match orderId in request body.");
        }
        string? problem = validateWorkOrder(workOrder);
        if problem is string {
            return badRequest(problem);
        }
        asset.workOrders[index] = workOrder;
        return workOrder;
    }

    // Remove a work order and its tasks.
    resource function delete assets/[string assetTag]/workorders/[string orderId]()
            returns http:NoContent|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        int? index = findWorkOrderIndex(asset, orderId);
        if index is () {
            return notFound("Work order", orderId);
        }
        _ = asset.workOrders.remove(index);
        http:NoContent response = {};
        return response;
    }

    // List the tasks in a work order.
    resource function get assets/[string assetTag]/workorders/[string orderId]/tasks()
            returns Task[]|http:NotFound {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        return workOrder.tasks;
    }

    // Look up one task in a work order.
    resource function get assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId]()
            returns Task|http:NotFound {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        int? index = findTaskIndex(workOrder, taskId);
        if index is () {
            return notFound("Task", taskId);
        }
        return workOrder.tasks[index];
    }

    // Add a task to a work order.
    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(Task task)
            returns Task|http:NotFound|http:BadRequest|http:Conflict {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        string? problem = validateTask(task);
        if problem is string {
            return badRequest(problem);
        }
        if findTaskIndex(workOrder, task.taskId) is int {
            return duplicateResponse("Task", task.taskId);
        }
        workOrder.tasks.push(task);
        return task;
    }

    // Update a task description and completion state.
    resource function put assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId](Task task)
            returns Task|http:NotFound|http:BadRequest {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        int? index = findTaskIndex(workOrder, taskId);
        if index is () {
            return notFound("Task", taskId);
        }
        if task.taskId != taskId {
            return badRequest("taskId in URL must match taskId in request body.");
        }
        string? problem = validateTask(task);
        if problem is string {
            return badRequest(problem);
        }
        workOrder.tasks[index] = task;
        return task;
    }

    // Remove a task from a work order.
    resource function delete assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId]()
            returns http:NoContent|http:NotFound {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        int? index = findTaskIndex(workOrder, taskId);
        if index is () {
            return notFound("Task", taskId);
        }
        _ = workOrder.tasks.remove(index);
        http:NoContent response = {};
        return response;
    }

    // List the schedules for an asset.
    resource function get assets/[string assetTag]/schedules() returns Schedule[]|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        return asset.schedules;
    }

    // Look up one schedule for an asset.
    resource function get assets/[string assetTag]/schedules/[string scheduleId]()
            returns Schedule|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        int? index = findScheduleIndex(asset, scheduleId);
        if index is () {
            return notFound("Schedule", scheduleId);
        }
        return asset.schedules[index];
    }

    // Add a booking or servicing schedule to an asset.
    resource function post assets/[string assetTag]/schedules(Schedule schedule)
            returns Schedule|http:NotFound|http:BadRequest|http:Conflict {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        string? problem = validateSchedule(schedule);
        if problem is string {
            return badRequest(problem);
        }
        if findScheduleIndex(asset, schedule.scheduleId) is int {
            return duplicateResponse("Schedule", schedule.scheduleId);
        }
        asset.schedules.push(schedule);
        return schedule;
    }

    // Replace a schedule while keeping its identifier.
    resource function put assets/[string assetTag]/schedules/[string scheduleId](Schedule schedule)
            returns Schedule|http:NotFound|http:BadRequest {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        int? index = findScheduleIndex(asset, scheduleId);
        if index is () {
            return notFound("Schedule", scheduleId);
        }
        if schedule.scheduleId != scheduleId {
            return badRequest("scheduleId in URL must match scheduleId in request body.");
        }
        string? problem = validateSchedule(schedule);
        if problem is string {
            return badRequest(problem);
        }
        asset.schedules[index] = schedule;
        return schedule;
    }

    // Remove a schedule from an asset.
    resource function delete assets/[string assetTag]/schedules/[string scheduleId]()
            returns http:NoContent|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        int? index = findScheduleIndex(asset, scheduleId);
        if index is () {
            return notFound("Schedule", scheduleId);
        }
        _ = asset.schedules.remove(index);
        http:NoContent response = {};
        return response;
    }

    // List assets with maintenance dates before the selected date.
    resource function get overdue(string? asOf = (), string? institution = (), string? site = ())
            returns Asset[]|http:BadRequest {
        string cutoff = asOf ?: currentDate();
        if !isValidDate(cutoff) {
            return {body: {message: "asOf must be a valid date in YYYY-MM-DD format."}};
        }
        if hasBlankFilter(institution, site) {
            return {body: {message: "institution and site must not be blank."}};
        }
        Asset[] overdueAssets = [];
        foreach Asset asset in assetStore {
            if matchesLocation(asset, institution, site) && hasOverdueMaintenance(asset, cutoff) {
                overdueAssets.push(asset);
            }
        }
        return overdueAssets;
    }

    // Create an asset after checking its details.
    resource function post assets(Asset newAsset)
            returns Asset|http:Conflict|http:BadRequest {

        if assetStore.hasKey(newAsset.assetTag) {
            return duplicateResponse("Asset", newAsset.assetTag);
        }
        string? problem = validateAsset(newAsset);
        if problem is string {
            return badRequest(problem);
        }
        assetStore[newAsset.assetTag] = newAsset;

        return newAsset;
    }


    // List assets for the selected institution and site.
    resource function get assets(string? institution = (), string? site = ())
            returns Asset[]|http:BadRequest {
        if hasBlankFilter(institution, site) {
            return {body: {message: "institution and site must not be blank."}};
        }

        Asset[] assets = [];

        foreach Asset asset in assetStore {
            if matchesLocation(asset, institution, site) {
                assets.push(asset);
            }
        }

        return assets;
    }


    // Look up an asset by its tag.
    resource function get assets/[string assetTag]()
            returns Asset|http:NotFound {

        Asset? asset = assetStore[assetTag];

        if asset is Asset {
            return asset;
        }

        return notFound("Asset", assetTag);
    }


    // Replace an asset after checking its tag and details.
    resource function put assets/[string assetTag](Asset updatedAsset)
            returns Asset|http:NotFound|http:BadRequest {

        Asset? existingAsset = assetStore[assetTag];

        if existingAsset is () {
            return notFound("Asset", assetTag);
        }

        if updatedAsset.assetTag != assetTag {
            return badRequest("assetTag in URL must match assetTag in request body.");
        }
        string? problem = validateAsset(updatedAsset);
        if problem is string {
            return badRequest(problem);
        }

        assetStore[assetTag] = updatedAsset;

        return updatedAsset;
    }


    // Remove an asset by its tag.
    resource function delete assets/[string assetTag]()
            returns http:NoContent|http:NotFound {

        Asset? existingAsset = assetStore[assetTag];

        if existingAsset is () {
            return notFound("Asset", assetTag);
        }

        _ = assetStore.remove(assetTag);

        http:NoContent noContent = {};

        return noContent;
    }
}
