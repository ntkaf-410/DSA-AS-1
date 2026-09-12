import ballerina/http;

configurable int port = 9090;
listener http:Listener apiListener = new (port);

service /api on apiListener {

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
