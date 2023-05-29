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

    # Post method to match the patient
    #
    # + patientMatchingRequest - Patient Matching Record
    # + return - Matching Result or Error
    resource function post patientmatch(@http:Payload PatientMatchingRequest patientMatchingRequest) returns error|http:Response {
        PatientMatcher patientMatcher;

        if getAlgoType() is "rulebased" {
            patientMatcher = new RuleBasedPatientMatching();
        } else {
            return createPatientMatchingError("Error reading configurations from config.json file"); 
        }
        return patientMatcher.matchPatients(patientMatchingRequest.newPatient);

    }

    # Post method to verify wheather two patients are same or not
    #
    # + patientCheckRequest - Patient Verify Request Record
    # + return - True if both patients are same or False if not
    resource function post verifypatient(@http:Payload PatientVerifyRequest patientCheckRequest) returns error|http:Response {
        PatientMatcher patientMatcher = new RuleBasedPatientMatching();
        return patientMatcher.verifyPatient(patientCheckRequest.newPatient ,patientCheckRequest.oldPatient);
    }
}

# Record to hold the patient details to be matched
#
# + newPatient - New patient to be matched
public type PatientMatchingRequest record {
    r4:Patient newPatient;
};

# Record to hold the patient details to be verified
#
# + newPatient - Patient to be verified  
# + oldPatient - Patient to be verified against
public type PatientVerifyRequest record {
    r4:Patient newPatient;
    r4:Patient oldPatient;
};

# Function to get the algorithm type from the config.json file
# + return - json which contains the algorithm type or error
public isolated function getAlgoType() returns json|error {
    json|io:Error readfile = io:fileReadJson("config.json");
    string algotype;      
    if readfile is io:Error {
        algotype = "rulebased";

    } else {
        algotype =  check readfile.algorithm;
    }
    return algotype;

}
