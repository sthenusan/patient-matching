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

const  DEFAULT_ALGO = "rulebased";
configurable string algoType = "rulebased";
# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.

isolated service /patient on new http:Listener(9090) {

    private final map<PatientMatcher> patientMatcherMap = {
        "rulebased" : new RuleBasedPatientMatcher()
    };
    private final PatientMatcher patientMatcher;
    public function init() returns error? {
        if (self.patientMatcherMap.hasKey(algoType)) {
            self.patientMatcher = <PatientMatcher>self.patientMatcherMap[algoType];
        } else {
            self.patientMatcher = <PatientMatcher>self.patientMatcherMap[DEFAULT_ALGO];
        } 
    }

    # Post method to match patients
    #
    # + patientMatchRequest - Patient Match Request Record
    # + return - Matching Result or Error
    resource isolated function post 'match(@http:Payload PatientMatchRequest patientMatchRequest) returns error|http:Response {
        ConfigurationRecord?|error config = getConfigurations();
        if config is error || config is () {
            return self.patientMatcher.matchPatients(patientMatchRequest); 
        }
        return self.patientMatcher.matchPatients(patientMatchRequest,config); 
    }
}

# Method to get configurations from config.json file
# + return - Configurations as a json
public isolated function getConfigurations() returns ConfigurationRecord?|error {
    json|io:Error configFile = io:fileReadJson("config.json");
    if configFile is json {
        return <ConfigurationRecord> {
        "fhirpaths" : check configFile.fhirpaths,
        "masterPatientIndexTableName" : check configFile.masterPatientIndexTableName,
        "masterPatientIndexColumnNames" : check configFile.masterPatientIndexColumnNames,
        "masterPatientIndexHost" : check configFile.masterPatientIndexHost,
        "masterPatientIndexPort" : check configFile.masterPatientIndexPort,
        "masterPatientIndexDb" : check configFile.masterPatientIndexDb,
        "masterPatientIndexDbUser" : check configFile.masterPatientIndexDbUser,
        "masterPatientIndexDbPassword" : check configFile.masterPatientIndexDbPassword
        };
    }
    return ();
}
