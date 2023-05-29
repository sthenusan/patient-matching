

import ballerina/test;
import ballerina/http;

RuleBasedPatientMatcher rpm = new RuleBasedPatientMatcher();

ConfigurationRecord config = {
    fhirpaths: ["Patient.name.given[1]", "Patient.name.family", "Patient.gender", "Patient.birthDate"],
    "MPIColumnNames": ["FirstName", "LastName", "gender", "dob"],
    "MPITableName": "patient",
    "masterPatientIndexHost": "localhost",
    "masterPatientIndexPort": 3306,
    "masterPatientIndexDb": "patient_db",
    "masterPatientIndexDbUser": "root",
    "masterPatientIndexDbPassword": "0207THEnu$an"
};

MPIDbConfig mpiDbConfig = {
            host: "localhost",
            port: 3306,
            database: "patient_db",
            username: "root",
            password: "0207THEnu$an"
};

@test:Config {}
public function testForMatch() returns error? {
    json|http:ClientError jsonPayload = getResponse().getJsonPayload();
    if jsonPayload is json {
        error|http:Response matchPatients = rpm.matchPatients(getRequst(),config);
        if matchPatients is http:Response {
            test:assertEquals(matchPatients.getJsonPayload(), <anydata>jsonPayload, msg = "Response is not as expected");
        }
    }

    test:assertEquals(rpm.getMPIConfigData(config),mpiDbConfig);

    
}



public function getRequst() returns PatientMatchRequest {
    return {
        "resourceType": "Parameters",
        "id": "example",
        "parameter": [
            {
                "name": "resource",
                "resource": {
                    "resourceType": "Patient",
                    "identifier": [
                        {
                            "use": "official",
                            "type": {
                                "coding": [
                                    {
                                        "system": "http://hl7.org/fhir/v2/0203",
                                        "code": "MR"
                                    }
                                ]
                            },
                            "system": "urn:oid:1.2.36.146.595.217.0.1",
                            "value": "12345"
                        }
                    ],
                    "id": "123",
                    "name": [
                        {
                            "use": "official",
                            "family": "Cox",
                            "given": [
                                "charles",
                                "Brian",
                                "che"

                            ]
                        }
                    ],
                    "gender": "male",
                    "birthDate": "2019-07-18"
                }
            },
            {
                "name": "count",
                "valueInteger": "1"
            },
            {
                "name": "onlyCertainMatches",
                "valueBoolean": "false"
            }
        ]
    };
}

public function getResponse() returns http:Response {
    http:Response response = new;
    json load = {
    "resourceType": "Bundle",
    "meta": {
        "profile": [
            "http://hl7.org/fhir/StructureDefinition/Bundle"
        ]
    },
    "type": "searchset",
    "timestamp": "[1688100428,0.790215000]",
    "total": 1,
    "entry": [
        {
            "resource": {
                "gender": "male",
                "addr_line1": "1088 Abernathy Estate",
                "FirstName": "Brian",
                "mobile": "555-164-6702",
                "addr_postalCode": "02215",
                "language": "en-US",
                "SSN": "999-24-4970",
                "addr_state": "Massachusetts",
                "insurance_coverage": "Medicaid",
                "dob": "2019-07-18",
                "addr_line2": null,
                "id": 1,
                "LastName": "Cox",
                "addr_city": "Brookline",
                "maritalStatus": "S",
                "addr_country": "US"
            },
            "search": {
                "mode": "match",
                "score": 1.0
            }
        }
    ]
};
    response.statusCode = 200;
    response.setPayload(load);
    return response;
}


