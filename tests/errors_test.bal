import ballerina/http;
import ballerina/test;

// Reset the sample records before each test.
@test:BeforeEach
function resetAssets() {
    assetStore = {};
    sampleData();
}

// Check invalid assets without changing saved records.
@test:Config {}
function testAssetValidation() returns error? {
    Asset asset = {
        assetTag: "TEST-ASSET", name: "Test printer", description: "Test asset.",
        institution: "Test institution", site: "Test campus", status: "AVAILABLE", dateAcquired: "2024-01-01"
    };
    Schedule schedule = {scheduleId: "S1", 'type: "MAINTENANCE", dueDate: "2026-02-30", description: "Clean printer."};
    asset.schedules = [schedule];
    http:Response invalidDate = check apiClient->post("/assets", asset);
    test:assertEquals(invalidDate.statusCode, 400);
    schedule.dueDate = "2026-01-01";
    asset.schedules = [schedule, schedule];
    http:Response duplicates = check apiClient->post("/assets", asset);
    test:assertEquals(duplicates.statusCode, 400);
    asset.schedules = [];
    WorkOrder workOrder = {orderId: "W1", status: "OPEN", description: "Repair printer.", tasks: []};
    asset.workOrders = [workOrder, workOrder];
    http:Response duplicateOrders = check apiClient->post("/assets", asset);
    test:assertEquals(duplicateOrders.statusCode, 400);
    workOrder.tasks = [{taskId: "T1", description: "Check power."}, {taskId: "T1", description: "Check cable."}];
    asset.workOrders = [workOrder];
    http:Response duplicateTasks = check apiClient->post("/assets", asset);
    test:assertEquals(duplicateTasks.statusCode, 400);
    asset.workOrders = [];
    asset.institution = " ";
    http:Response blank = check apiClient->post("/assets", asset);
    test:assertEquals(blank.statusCode, 400);
    asset.institution = "Test institution";
    asset.dateAcquired = "2023-02-29";
    http:Response invalidAcquired = check apiClient->post("/assets", asset);
    test:assertEquals(invalidAcquired.statusCode, 400);
    http:Response notSaved = check apiClient->get("/assets/TEST-ASSET");
    test:assertEquals(notSaved.statusCode, 404);

    Asset original = check apiClient->get("/assets/NUST-LAP-014");
    Asset changed = original.clone();
    changed.schedules = [schedule, schedule];
    http:Response invalidUpdate = check apiClient->put("/assets/NUST-LAP-014", changed);
    test:assertEquals(invalidUpdate.statusCode, 400);
    Asset saved = check apiClient->get("/assets/NUST-LAP-014");
    test:assertEquals(saved, original);
}

// Check malformed payloads, unknown routes, and unsupported methods.
@test:Config {}
function testWrongApiCalls() returns error? {
    http:Request malformed = new;
    malformed.setTextPayload("{", "application/json");
    http:Response malformedResponse = check apiClient->post("/assets/NUST-LAP-014/schedules", malformed);
    test:assertEquals(malformedResponse.statusCode, 400);
    http:Response missingFields = check apiClient->post("/assets/NUST-LAP-014/workorders", {orderId: "W1"});
    test:assertEquals(missingFields.statusCode, 400);
    http:Response wrongType = check apiClient->post("/assets/NUST-LIB-PRI-001/workorders/WO-554/tasks",
        {taskId: "T2", description: "Test task.", completed: "yes"});
    test:assertEquals(wrongType.statusCode, 400);
    http:Response unknown = check apiClient->get("/missing/route");
    test:assertEquals(unknown.statusCode, 404);
    http:Response wrongMethod = check apiClient->patch("/assets/NUST-LAP-014/schedules", {});
    test:assertEquals(wrongMethod.statusCode, 405);
}

// Check missing parents and children for each nested resource.
@test:Config {}
function testMissingRecords() returns error? {
    string[] paths = [
        "/assets/MISSING/schedules", "/assets/MISSING/schedules/S1",
        "/assets/NUST-LAP-014/schedules/MISSING", "/assets/MISSING/workorders",
        "/assets/MISSING/workorders/W1", "/assets/NUST-LAP-014/workorders/MISSING",
        "/assets/MISSING/workorders/W1/tasks", "/assets/MISSING/workorders/W1/tasks/T1",
        "/assets/NUST-LAP-014/workorders/MISSING/tasks",
        "/assets/NUST-LAP-014/workorders/MISSING/tasks/T1",
        "/assets/NUST-LIB-PRI-001/workorders/WO-554/tasks/MISSING"
    ];
    foreach string path in paths {
        http:Response response = check apiClient->get(path);
        test:assertEquals(response.statusCode, 404, path);
    }
    foreach string path in ["/assets/MISSING/schedules/S1", "/assets/NUST-LAP-014/schedules/MISSING"] {
        http:Response updated = check apiClient->put(path,
            {scheduleId: "S1", 'type: "BOOKING", dueDate: "2026-09-15", description: "Meeting."});
        test:assertEquals(updated.statusCode, 404);
        http:Response deleted = check apiClient->delete(path);
        test:assertEquals(deleted.statusCode, 404);
    }
    foreach string path in ["/assets/MISSING/workorders/W1", "/assets/NUST-LAP-014/workorders/MISSING"] {
        http:Response updated = check apiClient->put(path,
            {orderId: "W1", status: "OPEN", description: "Repair.", tasks: []});
        test:assertEquals(updated.statusCode, 404);
        http:Response deleted = check apiClient->delete(path);
        test:assertEquals(deleted.statusCode, 404);
    }
    foreach string path in ["/assets/MISSING/workorders/W1/tasks/T1",
            "/assets/NUST-LAP-014/workorders/MISSING/tasks/T1",
            "/assets/NUST-LIB-PRI-001/workorders/WO-554/tasks/MISSING"] {
        http:Response updated = check apiClient->put(path, {taskId: "T1", description: "Repair."});
        test:assertEquals(updated.statusCode, 404);
        http:Response deleted = check apiClient->delete(path);
        test:assertEquals(deleted.statusCode, 404);
    }
}

// Check invalid nested changes without replacing saved data.
@test:Config {}
function testNestedValidation() returns error? {
    string path = "/assets/NUST-LIB-PRI-001/workorders/WO-554";
    WorkOrder original = check apiClient->get(path);
    WorkOrder changed = original.clone();
    changed.tasks = [original.tasks[0], original.tasks[0]];
    http:Response duplicateTasks = check apiClient->put(path, changed);
    test:assertEquals(duplicateTasks.statusCode, 400);
    WorkOrder saved = check apiClient->get(path);
    test:assertEquals(saved, original);
    changed.tasks = [];
    changed.description = " ";
    http:Response blankOrder = check apiClient->put(path, changed);
    test:assertEquals(blankOrder.statusCode, 400);
    http:Response blankTask = check apiClient->put(path + "/tasks/T1", {taskId: "T1", description: " "});
    test:assertEquals(blankTask.statusCode, 400);
    http:Response closedNew = check apiClient->post("/assets/NUST-LAP-014/workorders",
        {orderId: "W1", status: "CLOSED", description: "Repair.", tasks: []});
    test:assertEquals(closedNew.statusCode, 400);
    http:Response blankSchedule = check apiClient->post("/assets/NUST-LAP-014/schedules",
        {scheduleId: " ", 'type: "BOOKING", dueDate: "2026-09-15", description: "Meeting."});
    test:assertEquals(blankSchedule.statusCode, 400);
}
