import ballerina/http;
import ballerina/url;

configurable string apiBaseUrl = "http://localhost:9090/api";

final http:Client apiClient = check new (apiBaseUrl);

// Fetch a single asset by its tag.
function getAsset(string assetTag) returns Asset|error {
    return apiClient->get("/assets/" + assetTag);
}

// Fetch a list of assets from an arbitrary /assets or /overdue path (with query string already attached).
function getAssets(string path) returns Asset[]|error {
    return apiClient->get(path);
}

// URL-encode a single query value.
function urlEncode(string value) returns string|error {
    return url:encode(value, "UTF-8");
}

// Build "path?key=value&key2=value2" from a list of already-encoded "key=value" params.
function appendQuery(string path, string[] params) returns string {
    if params.length() == 0 {
        return path;
    }
    string query = "";
    foreach int i in 0 ..< params.length() {
        query += (i == 0 ? "?" : "&") + params[i];
    }
    return path + query;
}

// Print a consistent success/failure message for write operations (POST/PUT/DELETE).
function printResult(http:Response|error response, string verb, int successCode) {
    if response is error {
        io_error("Request failed: " + response.message());
        return;
    }
    if response.statusCode == successCode {
        io_ok(verb);
        return;
    }
    string detail = "";
    json|error body = response.getJsonPayload();
    if body is json {
        detail = body.toString();
    }
    io_error("Failed (HTTP " + response.statusCode.toString() + "). " + detail);
}
