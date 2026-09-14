import ballerina/http;
import ballerina/test;

http:Client apiClient = check new ("http://localhost:9091/api");

// Check institution and site filters through the API.
@test:Config {}
function testAssetFilters() returns error? {
    Asset[] allAssets = check apiClient->get("/assets");
    test:assertEquals(allAssets.length(), 5);

    Asset[] institutionAssets = check apiClient->get("/assets?institution=namibia%20university%20of%20science%20and%20technology");
    test:assertEquals(institutionAssets.length(), 3);
    foreach Asset asset in institutionAssets {
        test:assertEquals(asset.institution, "Namibia University of Science and Technology");
    }

    Asset[] siteAssets = check apiClient->get("/assets?site=Main%20Campus%20-%20Computer%20Lab%203");
    test:assertEquals(siteAssets.length(), 1);
    test:assertEquals(siteAssets[0].assetTag, "IUM-LAB-PC-077");

    Asset[] combined = check apiClient->get("/assets?institution=University%20of%20Namibia&site=Main%20Campus%20-%20Computer%20Lab%203");
    test:assertEquals(combined.length(), 0);

    Asset[] unknown = check apiClient->get("/assets?institution=Unknown");
    test:assertEquals(unknown.length(), 0);

    http:Response blank = check apiClient->get("/assets?site=%20");
    test:assertEquals(blank.statusCode, 400);
}

// Check filters when saved location names contain surrounding spaces.
@test:Config {}
function testLocationWhitespace() returns error? {
    Asset asset = {
        assetTag: "TEST-LOCATION", name: "Test laptop", description: "Test asset.",
        institution: " Test Institution ", site: " Test Campus ", status: "AVAILABLE", dateAcquired: "2024-01-01",
        schedules: [{scheduleId: "S1", 'type: "MAINTENANCE", dueDate: "2025-01-01", description: "Service."}]
    };
    http:Response created = check apiClient->post("/assets", asset);
    test:assertEquals(created.statusCode, 201);
    Asset[] assets = check apiClient->get("/assets?institution=%20test%20institution%20&site=%20TEST%20CAMPUS%20");
    test:assertEquals(assets.length(), 1);
    test:assertEquals(assets[0].assetTag, "TEST-LOCATION");
    Asset[] overdue = check apiClient->get("/overdue?asOf=2026-01-01&institution=Test%20Institution&site=Test%20Campus");
    test:assertEquals(overdue.length(), 1);
    test:assertEquals(overdue[0].assetTag, "TEST-LOCATION");
}
