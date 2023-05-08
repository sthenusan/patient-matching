// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

# Client method to access utils package for fhirpath evaluation.
#
# + fhirResource - requested fhir resource
# + fhirPath - fhirpath requested for evaluvation
# + return - result of the fhirpath expression
public isolated function getFhirPathResult(map<json> fhirResource, string fhirPath) returns FhirPathResult {

    string|json|int|float|boolean|byte|error results = evaluateFhirPath(fhirResource, fhirPath);

    if results is error {
        FhirPathResult result = {
            resultenError: results.message()
        };
        return result;
    } else {
        FhirPathResult result = {
            result: results
        };
        return result;
    }
}

# Client record to hold the results of fhirpath evaluation.
#
# + result - Result of the fhirpath expression  
# + resultenError - Error message if the result is an error  
public type FhirPathResult record {
    string|json|int|float|boolean|byte result?;
    string resultenError?;
};
