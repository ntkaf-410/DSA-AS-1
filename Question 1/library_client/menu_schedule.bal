import ballerina/http;
import ballerina/io;

// Lets staff view, add, update, and remove booking/maintenance/servicing schedules
// for a chosen asset, using the /assets/{assetTag}/schedules endpoints.
function runScheduleManager() returns error? {
    string assetTag = io:readln("\nEnter assetTag to manage schedules for: ").trim();
    Asset|error initial = getAsset(assetTag);
    if initial is error {
        io_error("Could not find asset '" + assetTag + "': " + initial.message());
        return;
    }
    Asset asset = initial;

    boolean managing = true;
    while managing {
        io:println("\nSchedules for " + asset.assetTag + " (" + asset.name + "):");
        if asset.schedules.length() == 0 {
            io:println("    (none)");
        } else {
            foreach Schedule s in asset.schedules {
                io:println("    - " + s.scheduleId + " [" + s.'type + "] due " + s.dueDate + " - " + s.description);
            }
        }

        io:println("\n  1. Add schedule");
        io:println("  2. Update schedule");
        io:println("  3. Delete schedule");
        io:println("  0. Back to main menu");
        string choice = io:readln("  Select an option: ").trim();

        match choice {
            "1" => {
                addSchedule(assetTag);
            }
            "2" => {
                updateSchedule(assetTag);
            }
            "3" => {
                deleteSchedule(assetTag);
            }
            "0" => {
                managing = false;
            }
            _ => {
                io:println("  Invalid option.");
            }
        }

        if managing && choice != "0" {
            Asset|error refreshed = getAsset(assetTag);
            if refreshed is Asset {
                asset = refreshed;
            }
        }
    }
}

function addSchedule(string assetTag) {
    string scheduleId = io:readln("  scheduleId: ").trim();
    string scheduleType = io:readln("  type (BOOKING / MAINTENANCE / SERVICING): ").trim().toUpperAscii();
    string dueDate = io:readln("  dueDate (YYYY-MM-DD): ").trim();
    string description = io:readln("  description: ").trim();

    Schedule schedule = {scheduleId, 'type: scheduleType, dueDate, description};
    http:Response|error response = apiClient->post("/assets/" + assetTag + "/schedules", schedule);
    printResult(response, "Schedule '" + scheduleId + "' created", 201);
}

function updateSchedule(string assetTag) {
    string scheduleId = io:readln("  scheduleId to update: ").trim();
    string scheduleType = io:readln("  new type (BOOKING / MAINTENANCE / SERVICING): ").trim().toUpperAscii();
    string dueDate = io:readln("  new dueDate (YYYY-MM-DD): ").trim();
    string description = io:readln("  new description: ").trim();

    Schedule schedule = {scheduleId, 'type: scheduleType, dueDate, description};
    http:Response|error response = apiClient->put("/assets/" + assetTag + "/schedules/" + scheduleId, schedule);
    printResult(response, "Schedule '" + scheduleId + "' updated", 200);
}

function deleteSchedule(string assetTag) {
    string scheduleId = io:readln("  scheduleId to delete: ").trim();
    http:Response|error response = apiClient->delete("/assets/" + assetTag + "/schedules/" + scheduleId);
    printResult(response, "Schedule '" + scheduleId + "' deleted", 204);
}
