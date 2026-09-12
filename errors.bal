import ballerina/http;

// Builds a response for a missing record.
function notFound(string recordType, string id) returns http:NotFound {
    return {body: {message: recordType + " '" + id + "' not found."}};
}

// Builds a response for invalid request details.
function badRequest(string message) returns http:BadRequest {
    return {body: {message}};
}

// Builds a response for a duplicate identifier.
function duplicateResponse(string recordType, string id) returns http:Conflict {
    return {body: {message: recordType + " '" + id + "' already exists."}};
}
