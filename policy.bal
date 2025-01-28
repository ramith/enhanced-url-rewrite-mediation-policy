// Copyright (c) 2022 WSO2 LLC (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import choreo/mediation;
import ballerina/http;
import ballerina/log;



configurable string[] dynamicPathOrQueryParameterNames = ["userId", "assessment_id"];

@mediation:RequestFlow
public function rewrite(mediation:Context ctx, http:Request req, string newPath)
    returns http:Response|false|error|() {
    
    map<string[]> queryParams = ctx.queryParams();
    foreach var entry in queryParams.entries() {
        log:printInfo("Query Param: " + entry.toString());
    }

    mediation:ResourcePath currentPath = ctx.resourcePath();
    currentPath.pathSegments().forEach(function (mediation:PathSegment segment) {
        log:printInfo("Path Segment: " + segment.toString());
    });

    foreach string paramName in dynamicPathOrQueryParameterNames {
        if paramExistsinResourcePath(paramName, currentPath) {
            currentPath.resolve()
            log:printInfo(string`Param exists in Resource Path: ParamName ${paramName} Param Value ${}` );
        }
    }


    //boolean hasQuery = false;

    // foreach string paramName in dynamicPathOrQueryParameterNames {
    //     string[]? paramValues = queryParams[paramName];
    //     if paramValues is string[] && paramValues.length() > 0 {
    //         newPath += (hasQuery ? "&" : "?") + paramName + "=" + paramValues[0];
    //         hasQuery = true;
    //     }
    // }

    // foreach string paramName in dynamicPathOrQueryParameterNames {
    //     if oldPath.contains("{" + paramName + "}") {
    //         string[]? paramValues = queryParams[paramName];
    //         if paramValues is string[] && paramValues.length() > 0 {
    //             newPath = newPath.replace("{" + paramName + "}", paramValues[0]);
    //         }
    //     }
    // }

    mediation:ResourcePath mutableResourcePath = check mediation:createMutableResourcePath(newPath);
    ctx.setResourcePath(mutableResourcePath);
    return ();
}


function paramExistsinResourcePath(string paramName, mediation:ResourcePath path) returns boolean {
    foreach var segment in path.pathSegments() {
        if segment.toString() == paramName {
            return true;
        }
    }
    return false;
}

function  paramExistsInQueryParams(string paramName, map<string[]> queryParams) returns boolean {
    return queryParams[paramName] is string[];
}