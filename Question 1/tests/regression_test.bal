import ballerina/http;
import ballerina/test;
import ballerina/time;

// Check the original asset operations after adding validation.
@test:Config {}
function testAssetCrud() returns error? {
    Asset asset = {
        assetTag: "TEST-CRUD", name: "Test laptop", description: "Test asset.",
        institution: "Test institution", site: "Test campus", status: "AVAILABLE", dateAcquired: "2024-02-29"
    };
    http:Response created = check apiClient->post("/assets", asset);
    test:assertEquals(created.statusCode, 201);
    http:Response duplicate = check apiClient->post("/assets", asset);
    test:assertEquals(duplicate.statusCode, 409);
    Asset saved = check apiClient->get("/assets/TEST-CRUD");
    test:assertEquals(saved, asset);
    asset.name = "Updated laptop";
    http:Response updated = check apiClient->put("/assets/TEST-CRUD", asset);
    test:assertEquals(updated.statusCode, 200);
    saved = check apiClient->get("/assets/TEST-CRUD");
    test:assertEquals(saved.name, "Updated laptop");
    http:Response mismatch = check apiClient->put("/assets/NUST-LAP-014", asset);
    test:assertEquals(mismatch.statusCode, 400);
    http:Response deleted = check apiClient->delete("/assets/TEST-CRUD");
    test:assertEquals(deleted.statusCode, 204);
    http:Response missing = check apiClient->get("/assets/TEST-CRUD");
    test:assertEquals(missing.statusCode, 404);
    http:Response missingUpdate = check apiClient->put("/assets/TEST-CRUD", asset);
    test:assertEquals(missingUpdate.statusCode, 404);
    http:Response missingDelete = check apiClient->delete("/assets/TEST-CRUD");
    test:assertEquals(missingDelete.statusCode, 404);
}

// Check date boundaries and return each overdue asset only once.
@test:Config {}
function testOverdueBoundaries() returns error? {
    string path = "/assets/NUST-LAP-014/schedules";
    foreach Schedule schedule in [
        {scheduleId: "OLD-BOOKING", 'type: "BOOKING", dueDate: "2019-01-01", description: "Past booking."},
        {scheduleId: "DUE-TODAY", 'type: "SERVICING", dueDate: "2020-01-01", description: "Due today."},
        {scheduleId: "FUTURE", 'type: "MAINTENANCE", dueDate: "2020-01-02", description: "Future service."}
    ] {
        http:Response created = check apiClient->post(path, schedule);
        test:assertEquals(created.statusCode, 201);
    }
    Asset[] onDate = check apiClient->get("/overdue?asOf=2020-01-01");
    test:assertEquals(onDate.length(), 0);
    Asset[] nextDate = check apiClient->get("/overdue?asOf=2020-01-03");
    test:assertEquals(nextDate.length(), 1);
    test:assertEquals(nextDate[0].assetTag, "NUST-LAP-014");
    Asset[] implicitDate = check apiClient->get("/overdue");
    string today = time:utcToString(time:utcNow()).substring(0, 10);
    Asset[] explicitDate = check apiClient->get("/overdue?asOf=" + today);
    test:assertEquals(implicitDate, explicitDate);
}

// Check that nested identifiers belong to their own parent records.
@test:Config {}
function testNestedIdentifiersStayScoped() returns error? {
    Schedule schedule = {scheduleId: "SHARED", 'type: "BOOKING", dueDate: "2027-01-01", description: "Booking."};
    WorkOrder workOrder = {orderId: "SHARED", status: "OPEN", description: "Check resource.", tasks: []};
    foreach string tag in ["NUST-LAP-014", "UNAM-RM-BB2-002"] {
        http:Response scheduleCreated = check apiClient->post("/assets/" + tag + "/schedules", schedule);
        test:assertEquals(scheduleCreated.statusCode, 201);
        http:Response orderCreated = check apiClient->post("/assets/" + tag + "/workorders", workOrder);
        test:assertEquals(orderCreated.statusCode, 201);
        http:Response taskCreated = check apiClient->post("/assets/" + tag + "/workorders/SHARED/tasks",
            {taskId: "SHARED", description: "Check power."});
        test:assertEquals(taskCreated.statusCode, 201);
    }
    http:Response deletedSchedule = check apiClient->delete("/assets/UNAM-RM-BB2-002/schedules/SHARED");
    test:assertEquals(deletedSchedule.statusCode, 204);
    Schedule[] roomSchedules = check apiClient->get("/assets/UNAM-RM-BB2-002/schedules");
    test:assertEquals(roomSchedules.length(), 1);
    test:assertEquals(roomSchedules[0].scheduleId, "SCH-101");
    Schedule laptopSchedule = check apiClient->get("/assets/NUST-LAP-014/schedules/SHARED");
    test:assertEquals(laptopSchedule, schedule);
    http:Response deletedOrder = check apiClient->delete("/assets/UNAM-RM-BB2-002/workorders/SHARED");
    test:assertEquals(deletedOrder.statusCode, 204);
    Task laptopTask = check apiClient->get("/assets/NUST-LAP-014/workorders/SHARED/tasks/SHARED");
    test:assertEquals(laptopTask.description, "Check power.");
}
