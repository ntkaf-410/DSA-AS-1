import ballerina/http;
import ballerina/test;

// Check work orders and task changes through the API.
@test:Config {}
function testWorkOrders() returns error? {
    string path = "/assets/NUST-LAP-014/workorders";
    WorkOrder workOrder = {orderId: "TEST-WO", status: "OPEN", description: "Replace screen.", tasks: []};
    http:Response created = check apiClient->post(path, workOrder);
    test:assertEquals(created.statusCode, 201);
    WorkOrder[] orders = check apiClient->get(path);
    test:assertEquals(orders.length(), 1);
    http:Response duplicate = check apiClient->post(path, workOrder);
    test:assertEquals(duplicate.statusCode, 409);

    string taskPath = path + "/TEST-WO/tasks";
    Task task = {taskId: "T1", description: "Check display cable."};
    http:Response taskCreated = check apiClient->post(taskPath, task);
    test:assertEquals(taskCreated.statusCode, 201);
    Task savedTask = check apiClient->get(taskPath + "/T1");
    test:assertFalse(savedTask.completed);
    Task[] tasks = check apiClient->get(taskPath);
    test:assertEquals(tasks.length(), 1);
    http:Response duplicateTask = check apiClient->post(taskPath, task);
    test:assertEquals(duplicateTask.statusCode, 409);
    task.completed = true;
    http:Response taskUpdated = check apiClient->put(taskPath + "/T1", task);
    test:assertEquals(taskUpdated.statusCode, 200);
    WorkOrder saved = check apiClient->get(path + "/TEST-WO");
    test:assertTrue(saved.tasks[0].completed);

    saved.status = "IN_PROGRESS";
    http:Response updated = check apiClient->put(path + "/TEST-WO", saved);
    test:assertEquals(updated.statusCode, 200);
    saved.status = "CLOSED";
    http:Response closed = check apiClient->put(path + "/TEST-WO", saved);
    test:assertEquals(closed.statusCode, 200);
    saved = check apiClient->get(path + "/TEST-WO");
    test:assertEquals(saved.status, "CLOSED");

    saved.status = "INVALID";
    http:Response invalid = check apiClient->put(path + "/TEST-WO", saved);
    test:assertEquals(invalid.statusCode, 400);
    saved.status = "OPEN";
    saved.orderId = "OTHER";
    http:Response mismatch = check apiClient->put(path + "/TEST-WO", saved);
    test:assertEquals(mismatch.statusCode, 400);
    task.taskId = "OTHER";
    http:Response taskMismatch = check apiClient->put(taskPath + "/T1", task);
    test:assertEquals(taskMismatch.statusCode, 400);
    task.taskId = "T2";
    task.description = " ";
    http:Response invalidTask = check apiClient->post(taskPath, task);
    test:assertEquals(invalidTask.statusCode, 400);

    http:Response taskDeleted = check apiClient->delete(taskPath + "/T1");
    test:assertEquals(taskDeleted.statusCode, 204);
    http:Response missingTask = check apiClient->get(taskPath + "/T1");
    test:assertEquals(missingTask.statusCode, 404);
    http:Response deleted = check apiClient->delete(path + "/TEST-WO");
    test:assertEquals(deleted.statusCode, 204);
    http:Response missing = check apiClient->get(path + "/TEST-WO");
    test:assertEquals(missing.statusCode, 404);
    http:Response missingOrder = check apiClient->post(taskPath, task);
    test:assertEquals(missingOrder.statusCode, 404);
    http:Response missingAsset = check apiClient->post("/assets/MISSING/workorders", workOrder);
    test:assertEquals(missingAsset.statusCode, 404);
}
