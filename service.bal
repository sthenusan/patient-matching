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
import ballerina/io;

# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.
service /fhir on new http:Listener(9090) {

    resource function post patientmatch(@http:Payload PatientMatchingRequest patientMatchingRequest) returns MatchingResult|error {
        PatientMatcher patientMatcher;

        if getAlgoType() is "rule-based" {
            patientMatcher = new RuleBasedPatientMatching();
        } else {
            return error("Error reading config.json file"); 
        }
        return patientMatcher.matchPatients(patientMatchingRequest.newPatient);

    }

    resource function post verifypatient(@http:Payload PatientCheckRequest patientCheckRequest) returns boolean|error {
        PatientMatcher patientMatcher = new RuleBasedPatientMatching();
        return patientMatcher.verifyPatient(patientCheckRequest.newPatient ,patientCheckRequest.oldPatient);
    }
}
public type PatientMatchingRequest record {
    r4:Patient newPatient;
};

public type PatientCheckRequest record {
    r4:Patient newPatient;
    r4:Patient oldPatient;
};

public function getAlgoType() returns json|error {
    json|io:Error readfile = io:fileReadJson("config.json");
    string algotype;
        
    if readfile is io:Error {
        algotype = "rule-based";

    } else {
        algotype =  check readfile.algorithm;
    }
    
    return algotype;

}