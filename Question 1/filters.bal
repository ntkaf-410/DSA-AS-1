// Check whether a supplied location filter is blank.
function hasBlankFilter(string? institution, string? site) returns boolean {
    return (institution is string && institution.trim() == "") ||
        (site is string && site.trim() == "");
}

// Match both location filters without case differences.
function matchesLocation(Asset asset, string? institution, string? site) returns boolean {
    return (institution is () || asset.institution.trim().toLowerAscii() == institution.trim().toLowerAscii()) &&
        (site is () || asset.site.trim().toLowerAscii() == site.trim().toLowerAscii());
}
