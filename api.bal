import ballerina/http;

configurable int port = 9090;
listener http:Listener apiListener = new (port);

service /api on apiListener {

    // Lists the work orders for an asset.
    resource function get assets/[string assetTag]/workorders() returns WorkOrder[]|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        return asset.workOrders;
    }

    // Looks up one work order for an asset.
    resource function get assets/[string assetTag]/workorders/[string orderId]()
            returns WorkOrder|http:NotFound {
        return lookupWorkOrder(assetTag, orderId);
    }

    // Opens a work order for an asset.
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

    // Updates a work order or closes it with CLOSED status.
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

    // Removes a work order and its tasks.
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

    // Lists the tasks in a work order.
    resource function get assets/[string assetTag]/workorders/[string orderId]/tasks()
            returns Task[]|http:NotFound {
        WorkOrder|http:NotFound workOrder = lookupWorkOrder(assetTag, orderId);
        if workOrder is http:NotFound {
            return workOrder;
        }
        return workOrder.tasks;
    }

    // Looks up one task in a work order.
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

    // Adds a task to a work order.
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

    // Updates a task description and completion state.
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

    // Removes a task from a work order.
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

    // Lists the schedules for an asset.
    resource function get assets/[string assetTag]/schedules() returns Schedule[]|http:NotFound {
        Asset? asset = assetStore[assetTag];
        if asset is () {
            return notFound("Asset", assetTag);
        }
        return asset.schedules;
    }

    // Looks up one schedule for an asset.
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

    // Adds a booking or servicing schedule to an asset.
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

    // Replaces a schedule while keeping its identifier.
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

    // Removes a schedule from an asset.
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

    // Lists assets with maintenance dates before the selected date.
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

    // CREATE
    resource function post assets(Asset newAsset)
            returns Asset|http:Conflict {

        if assetStore.hasKey(newAsset.assetTag) {
            http:Conflict conflictResponse = {
                body: {
                    message: "Asset with assetTag '" +
                        newAsset.assetTag +
                        "' already exists."
                }
            };

            return conflictResponse;
        }

        assetStore[newAsset.assetTag] = newAsset;

        return newAsset;
    }


    // Lists assets for the selected institution and site.
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


    // READ ONE
    resource function get assets/[string assetTag]()
            returns Asset|http:NotFound {

        Asset? asset = assetStore[assetTag];

        if asset is Asset {
            return asset;
        }

        http:NotFound notFound = {
            body: {
                message: "Asset '" + assetTag + "' not found."
            }
        };

        return notFound;
    }


    // UPDATE
    resource function put assets/[string assetTag](Asset updatedAsset)
            returns Asset|http:NotFound|http:BadRequest {

        Asset? existingAsset = assetStore[assetTag];

        if existingAsset is () {
            http:NotFound notFound = {
                body: {
                    message: "Asset '" + assetTag + "' not found."
                }
            };

            return notFound;
        }

        if updatedAsset.assetTag != assetTag {
            http:BadRequest badRequest = {
                body: {
                    message: "assetTag in URL must match assetTag in request body."
                }
            };

            return badRequest;
        }

        assetStore[assetTag] = updatedAsset;

        return updatedAsset;
    }


    // DELETE
    resource function delete assets/[string assetTag]()
            returns http:NoContent|http:NotFound {

        Asset? existingAsset = assetStore[assetTag];

        if existingAsset is () {
            http:NotFound notFound = {
                body: {
                    message: "Asset '" + assetTag + "' not found."
                }
            };

            return notFound;
        }

        _ = assetStore.remove(assetTag);

        http:NoContent noContent = {};

        return noContent;
    }
}
