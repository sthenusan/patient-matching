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
import ballerina/io;    
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4utils.patientmatching as pm;
# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.
service /fhir on new http:Listener(9090) {

    # Post method to match the patient
    #
    # + patientMatchingRequest - Patient Matching Record
    # + return - Matching Result or Error
    isolated resource function post patientmatch(@http:Payload PatientMatchingRequest patientMatchingRequest) returns error|http:Response {
        json|error config = getConfigurations();
        if (config is error) {
            return pm:createPatientMatchingError("Could not find the configuration file");
        }
        pm:PatientMatcherRecord patientMatcher = pm:patientMatcherRegistry.getPatientMatcherImpl();
        pm:MatchPatients matchfunc = patientMatcher.matchPatients;
        return matchfunc(patientMatchingRequest.sourcePatient,config);

    }

    # Post method to verify wheather two patients are same or not
    #
    # + patientCheckRequest - Patient Verify Request Record
    # + return - True if both patients are same or False if not
    isolated resource function post verifypatient(@http:Payload PatientVerifyRequest patientCheckRequest) returns error|http:Response {
        json|error config = getConfigurations();
        if (config is error) {
            return pm:createPatientMatchingError("Could not find the configuration file");
        }
        pm:patientMatcherRegistry.registerPatientMatcherImpl(newPatientMatcher);
        pm:PatientMatcherRecord patientMatcher = pm:patientMatcherRegistry.getPatientMatcherImpl();
        pm:VerifyPatient verifyfunc = patientMatcher.verifyPatient;
        return verifyfunc(patientCheckRequest.sourcePatient, patientCheckRequest.targetPatient,config);
    }
}

# Record to hold the patient details to be matched
#
# + sourcePatient - New patient to be matched
public type PatientMatchingRequest record {
    r4:Patient sourcePatient;
};

# Record to hold the patient details to be verified
#
# + sourcePatient - Patient to be verified  
# + targetPatient - Patient to be verified against
public type PatientVerifyRequest record {
    r4:Patient sourcePatient;
    r4:Patient targetPatient;
};

public isolated function getConfigurations() returns json|error {
    json|io:Error configFile = io:fileReadJson("patientMatcherConfig.json");

    if (configFile is json) {
        return configFile;
    } else {
        return pm:createPatientMatchingError("Could not find the configuration file");
    }
}
