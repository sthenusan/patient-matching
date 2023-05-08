// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import wso2healthcare/healthcare.fhir.r4;
import ballerina/http;
import ballerina/io;

# A service representing a network-accessible API for the Patient-matching evaluation.
# bound to port `9090`.
service /fhir on new http:Listener(9090) {

    resource function post patientmatch(@http:Payload r4:Patient patient1, @http:Payload r4:Patient[] patientList) returns error? {


        //Read configuration file to get the patientList and rulesTable
        json|io:Error readfile = io:fileReadJson("config.json");
        io:println("readfile: ", readfile);

    }
}

// r4:Patient patient1 = {
//     "resourceType": "Patient",
//     "id": "1",
//     "meta": {
//         "profile": [
//             "http://hl7.org/fhir/StructureDefinition/Patient"
//         ]
//     },
//     "active": true,
//     "name": [
//         {
//             "use": "official",
//             "family": "Fernando",
//             "given": [
//                 "Peter",
//                 "James"
//             ]
//         }
//     ],
//     "gender": "male",
//     "birthDate": "1974-12-25",
//     "language": "en-US"
// };

// r4:Patient patient2 = {
//     "resourceType": "Patient",
//     "id": "123",
//     "active": true,
//     "name": [
//         {
//             "use": "official",
//             "family": "Fernando",
//             "given": [
//                 "Peter",
//                 "James"
//             ]
//         }
//     ],
//     "gender": "male",
//     "birthDate": "1974-12-25",
//     "language": "en-US"
// };

// r4:Patient patient3 = {
//     "resourceType": "Patient",
//     "id": "1234",
//     "active": true,
//     "name": [
//         {
//             "use": "official",
//             "family": "Chalmer",
//             "given": [
//                 "Peter",
//                 "James"
//             ]
//         }
//     ],
//     "gender": "male",
//     "birthDate": "1974-12-25",
//     "language": "en-UK"

// };

// r4:Patient[] patientList = [patient2, patient3];

// RulesRecord rulesTable = {
//     ruleArray: [rule1, rule2, rule3, rule4],
//     threshold: 4.0
// };

// Rule rule1 = {
//     fhirPath: "Patient.name.family",
//     weight: 1.0
// };

// Rule rule2 = {
//     fhirPath: "Patient.gender",
//     weight: 1.0
// };

// Rule rule3 = {
//     fhirPath: "Patient.birthDate",
//     weight: 1.0
// };

// Rule rule4 = {
//     fhirPath: "Patient.language",
//     weight: 1.0
// };
