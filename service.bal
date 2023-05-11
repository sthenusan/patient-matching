// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import ballerina/http;
import ballerinax/health.fhir.r4;

# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.
service /fhir on new http:Listener(9090) {

    resource function post patientmatch(@http:Payload PatientMatchingRequest patientMatchingRequest) returns MatchingResult|error {
        return getPatientMatchingResult(patientMatchingRequest.newPatient ,patientMatchingRequest.patientList);
    }
}
public type PatientMatchingRequest record {
    r4:Patient newPatient;
    r4:Patient [] patientList;
};
