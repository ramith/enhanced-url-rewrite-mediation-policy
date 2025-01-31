import ballerina/http;
import ballerina/log;
import ballerina/regex;
import choreo/mediation;

@mediation:RequestFlow
public function rewrite(mediation:Context ctx, http:Request req, string newPath, string variablesToReplace)
    returns http:Response|false|error|() {

    string[] dynamicPathOrQueryParameterNames = tokenize(variablesToReplace, ",");
    map<string[]> foundValues = {};

    map<string[]> queryParams = ctx.queryParams();
    map<mediation:PathParamValue> pathParams = ctx.resolvedPathParams();

    foreach string paramName in dynamicPathOrQueryParameterNames {
        string[]|mediation:PathParamValue? foundValue = queryParams[paramName];
        if foundValue is string[] && foundValue.length() > 0 { // value is supplied a query param.
            log:printInfo(string `Param exists in Query Params: ParamName ${paramName} Param Value ${foundValue.toString()}`);
            foundValues[paramName] = foundValue;
            continue;
        }

        foundValue = pathParams[paramName];
        if !(foundValue is ()) {
            log:printInfo(string `Param exists in Path Params: ParamName ${paramName} Param Value ${foundValue.toString()}`);
            foundValues[paramName] = [toString(foundValue)];
            continue;
        }

        log:printInfo(string `Param does not exist in Query Params: ParamName ${paramName}`);

    }

    string replacedPath = newPath;

    foreach string paramName in dynamicPathOrQueryParameterNames {
        string[]? foundValueArray = foundValues[paramName];
        if foundValueArray is string[] && foundValueArray.length() > 0 {
            string flattened = foundValueArray.reduce(isolated function(string acc, string value) returns string => acc + value, "");
            replacedPath = replacePlaceholder(replacedPath, paramName, flattened);
        }
    }

    log:printInfo(string `Replaced Path: ${replacedPath}`);
    mediation:ResourcePath mutableResourcePath = check mediation:createMutableResourcePath(replacedPath);
    ctx.setResourcePath(mutableResourcePath);
    return ();
}

function replacePlaceholder(string path, string placeholder, string replacement) returns string {
    log:printInfo(string `Replacing ${placeholder} with ${replacement}`);
    string searchTerm = "${" + placeholder + "}";
    int? startIndex = path.indexOf(searchTerm, 0);

    if startIndex == () || startIndex == -1 {
        log:printInfo(string `Search term ${searchTerm} not found in ${path}`);
        return path;
    }
    int endIndex = startIndex + searchTerm.length();
    string prefix = string:substring(path, 0, startIndex);
    string suffix = string:substring(path, endIndex);
    log:printInfo(string `Prefix: ${prefix} Suffix: ${suffix}`);
    return prefix + replacement + suffix;
}

isolated function toString(mediation:PathParamValue value) returns string {
    if value is string|int|boolean|float|decimal {
        return value.toString();
    } else {
        return value.reduce(isolated function(string acc, mediation:PathParamValue val) returns string => acc + toString(val), "");
    }
}

isolated function tokenize(string str, string delimiter) returns string[] {
    string[] tokens = regex:split(str, delimiter);
    return tokens;
}
