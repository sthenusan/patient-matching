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
import wso2healthcare/healthcare.fhir.r4;

# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.
service /fhir on new http:Listener(9090) {

    resource function get patientmatch() returns MatchingResult?|error? {
        return getPatientMatchingResult(patient1,patientList);
        
    }
}

r4:Patient[] patientList = [patient2, patient3];
r4:Patient patient1 = {
    "resourceType": "Patient",
    "id": "1",
    "meta": {
        "profile": [
            "http://hl7.org/fhir/StructureDefinition/Patient"
        ]
    },
    "active": true,
    "name": [
        {
            "use": "official",
            "family": "Fernando",
            "given": [
                "Peter"
            ]
        }
    ],
    "gender": "male",
    "birthDate": "1974-12-25",
    "language": "en-US"
};

r4:Patient patient2 = {
    "resourceType": "Patient",
    "id": "123",
    "active": true,
    "name": [
        {
            "use": "official",
            "family": "Fernando",
            "given": [
                "Peeter"
            ]
        }
    ],
    "gender": "male",
    "birthDate": "1974-12-25",
    "language": "en-US"
};

r4:Patient patient3 = {
    "resourceType": "Patient",
    "id": "1234",
    "active": true,
    "name": [
        {
            "use": "official",
            "family": "Chalmer",
            "given": [
                "Peter",
                "James"
            ]
        }
    ],
    "gender": "male",
    "birthDate": "1974-12-25",
    "language": "en-UK"

};



