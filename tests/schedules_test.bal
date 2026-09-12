import ballerina/http;
import ballerina/test;

// Checks schedule changes and their effect on overdue results.
@test:Config {}
function testSchedules() returns error? {
    string path = "/assets/NUST-LAP-014/schedules";
    Schedule schedule = {scheduleId: "TEST-SCH", 'type: "SERVICING", dueDate: "2026-01-01", description: "Clean fans."};
    http:Response created = check apiClient->post(path, schedule);
    test:assertEquals(created.statusCode, 201);
    Schedule saved = check apiClient->get(path + "/TEST-SCH");
    test:assertEquals(saved, schedule);
    Schedule[] schedules = check apiClient->get(path);
    test:assertEquals(schedules.length(), 1);
    http:Response duplicate = check apiClient->post(path, schedule);
    test:assertEquals(duplicate.statusCode, 409);

    Asset[] overdue = check apiClient->get("/overdue?asOf=2026-02-01");
    test:assertEquals(overdue.length(), 1);
    test:assertEquals(overdue[0].assetTag, "NUST-LAP-014");
    schedule.dueDate = "2027-01-01";
    http:Response updated = check apiClient->put(path + "/TEST-SCH", schedule);
    test:assertEquals(updated.statusCode, 200);
    saved = check apiClient->get(path + "/TEST-SCH");
    test:assertEquals(saved.dueDate, "2027-01-01");
    overdue = check apiClient->get("/overdue?asOf=2026-02-01");
    test:assertEquals(overdue.length(), 0);

    schedule.scheduleId = "OTHER";
    http:Response mismatch = check apiClient->put(path + "/TEST-SCH", schedule);
    test:assertEquals(mismatch.statusCode, 400);
    schedule.scheduleId = "TEST-SCH";
    schedule.dueDate = "2026-02-30";
    http:Response invalid = check apiClient->put(path + "/TEST-SCH", schedule);
    test:assertEquals(invalid.statusCode, 400);
    saved = check apiClient->get(path + "/TEST-SCH");
    test:assertEquals(saved.dueDate, "2027-01-01");

    http:Response deleted = check apiClient->delete(path + "/TEST-SCH");
    test:assertEquals(deleted.statusCode, 204);
    http:Response missing = check apiClient->get(path + "/TEST-SCH");
    test:assertEquals(missing.statusCode, 404);
    http:Response deleteMissing = check apiClient->delete(path + "/TEST-SCH");
    test:assertEquals(deleteMissing.statusCode, 404);
    http:Response updateMissing = check apiClient->put(path + "/TEST-SCH", schedule);
    test:assertEquals(updateMissing.statusCode, 404);

    schedule.dueDate = "2027-01-01";
    schedule.'type = "UNKNOWN";
    http:Response invalidType = check apiClient->post(path, schedule);
    test:assertEquals(invalidType.statusCode, 400);
    http:Response missingAsset = check apiClient->post("/assets/MISSING/schedules", schedule);
    test:assertEquals(missingAsset.statusCode, 404);
    schedules = check apiClient->get(path);
    test:assertEquals(schedules.length(), 0);
}
