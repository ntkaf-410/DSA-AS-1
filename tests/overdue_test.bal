import ballerina/http;
import ballerina/test;

// Checks past maintenance dates and excludes bookings and dates due today.
@test:Config {}
function testOverdueAssets() returns error? {
    Asset[] overdue = check apiClient->get("/overdue?asOf=2026-09-01");
    test:assertEquals(overdue.length(), 1);
    test:assertEquals(overdue[0].assetTag, "IUM-LAB-PC-077");

    Asset[] later = check apiClient->get("/overdue?asOf=2026-09-12");
    test:assertEquals(later.length(), 2);
    Asset[] institution = check apiClient->get("/overdue?asOf=2026-09-12&institution=Namibia%20University%20of%20Science%20and%20Technology");
    test:assertEquals(institution.length(), 1);
    test:assertEquals(institution[0].assetTag, "NUST-LIB-PRI-001");
    Asset[] site = check apiClient->get("/overdue?asOf=2026-09-12&site=Main%20Campus%20-%20Computer%20Lab%203");
    test:assertEquals(site.length(), 1);
    Asset[] none = check apiClient->get("/overdue?asOf=2020-01-01");
    test:assertEquals(none.length(), 0);

    foreach string date in ["2026-02-29", "2026-13-01", "2026-04-31", "2026-1-01", "invalid", ""] {
        http:Response invalid = check apiClient->get("/overdue?asOf=" + date);
        test:assertEquals(invalid.statusCode, 400);
    }
    http:Response leapDay = check apiClient->get("/overdue?asOf=2024-02-29");
    test:assertEquals(leapDay.statusCode, 200);
    http:Response today = check apiClient->get("/overdue");
    test:assertEquals(today.statusCode, 200);
    http:Response blank = check apiClient->get("/overdue?institution=%20");
    test:assertEquals(blank.statusCode, 400);
}
