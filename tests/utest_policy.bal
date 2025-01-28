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
import ballerina/http;
import ballerina/test;

import choreo/mediation;

@test:Config {}
public function testRequestFlowMultipleInstance() {
    mediation:Context ctx = createContext("get", "/realage/result", {}, {"user_id": ["someuserId222"]});
    http:Response|false|error|() result = rewrite(ctx, new, "/rat/user/${user_id}/realage-result");
    assertResult(result, ctx.resourcePath().toString(), "/rat/user/someuserId222/realage-result");
}

function assertResult(http:Response|false|error|() result, string resourcePath, string expResourcePath) {
    if !(result is ()) {
        test:assertFail("Expected '()', found " + (typeof result).toString());
    }

    test:assertEquals(resourcePath, expResourcePath);
}

function createContext(string httpMethod, string resPath, map<string> pathParams, map<string[]> queryParams) returns mediation:Context {
    mediation:ResourcePath originalPath = checkpanic mediation:createImmutableResourcePath(resPath);

    map<mediation:PathParamValue> pathParamValues = {};

    foreach var [key, val] in pathParams.entries() {
        pathParamValues[key] = val;
    }

    mediation:Context originalCtx =
                mediation:createImmutableMediationContext(httpMethod, originalPath.pathSegments(), pathParamValues, queryParams);
    mediation:ResourcePath mutableResPath = checkpanic mediation:createMutableResourcePath(resPath);
    return mediation:createMutableMediationContext(originalCtx, mutableResPath.pathSegments(), pathParamValues, queryParams);
}
