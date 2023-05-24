import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4utils as utils;
import ballerina/io;

# Fhirpath rule record
#
# + fhirPath - fhirpath expression  
# + weight - fhirpath weight
public type Rule record {
    string fhirPath;
    float weight;
};

# Record to hold rules and threshold
#
# + ruleArray - rules array 
# + threshold - threshold value
public type RulesList record {
    Rule[] ruleArray;
    float threshold;
};

# Record to hold configuration details
#
# + threshold - threshold value for matching
# + fhirpaths - rule fhirpaths  
# + weights - weights for each rule
public type Config record {
    float threshold;
    json [] fhirpaths;
    json [] weights;
};

public type MPIConfig record {
    string mpiUrl;
    string mpiUsername;
    string mpiPassword;
};

public class RuleBasedPatientMatching {
    *PatientMatcher;

    public function matchPatients(r4:Patient newPatient) returns MatchingResult|error {

            RulesList rulesTable;
            json|io:Error readfile = io:fileReadJson("config.json");
            if readfile is io:Error {
                return utils:createFhirPathError("Configuration error","");

            } else {
                json|error threshold =  readfile.threshold;
                json|error fhirpaths =  readfile.fhirpaths;
                json|error weights = readfile.weights;

                if threshold is error|| fhirpaths is error || weights is error {
                    return utils:createFhirPathError("Configuration error","");
                } else {
                    Rule [] rules =[];
                    Config config = {
                        threshold: <float>threshold,
                        fhirpaths:<json[]>fhirpaths,
                        weights: <json[]>weights
                    };

                    foreach var path in config.fhirpaths {
                        Rule rule = {
                            weight: <float>config.weights[<int>config.fhirpaths.indexOf(path)],
                            fhirPath: path.toString()
                        };
                        rules.push(rule);
                    }

                    rulesTable = {
                        ruleArray: rules,
                        threshold: config.threshold
                    };
                    
                }
            }

            r4:Patient[] patients = getPatients();

            foreach r4:Patient patient in patients {
                if self.verifyPatient(newPatient, patient) is true {
                    return {
                        newPatient: newPatient,
                        matchedPatient: patient,
                        ismatch: true
                    };
                    
                } else {
                    continue;
                }
            }

            return {
                newPatient: newPatient,
                matchedPatient: null,
                ismatch: false
            };
    }

    public function verifyPatient(r4:Patient newPatient, r4:Patient oldPatient) returns boolean|error {

        json|io:Error readfile = io:fileReadJson("config.json");
        
        if readfile is io:Error {
            return utils:createFhirPathError("Configuration error","");

        } else {
            json|error threshold =  readfile.threshold;
            json|error fhirpaths =  readfile.fhirpaths;
            json|error weights = readfile.weights;

            if threshold is error|| fhirpaths is error || weights is error {
                return utils:createFhirPathError("Configuration error","");
            } else {
                Rule [] rules =[];
                Config config = {
                    threshold: <float>threshold,
                    fhirpaths:<json[]>fhirpaths,
                    weights: <json[]>weights
                };

                foreach var path in config.fhirpaths {
                    Rule rule = {
                        weight: <float>config.weights[<int>config.fhirpaths.indexOf(path)],
                        fhirPath: path.toString()
                    };
                    rules.push(rule);
                }

                RulesList rulesTable = {
                    ruleArray: rules,
                    threshold: config.threshold
                };

                float score = 0;
                foreach Rule item in rulesTable.ruleArray {
                    string fhirPathRule = item.fhirPath;
                    map<anydata> resultMapPatientOne = utils:getFhirPathResult(<map<json>>newPatient.toJson(), fhirPathRule).entries();
                    map<anydata> resultMapPatientTwo = utils:getFhirPathResult(<map<json>>oldPatient.toJson(), fhirPathRule).entries();
                    if resultMapPatientOne.hasKey("result") && resultMapPatientTwo.hasKey("result") {
                        float x = ((resultMapPatientOne.get("result") == resultMapPatientTwo.get("result")) ? item.weight : 0);
                        score += x;
                    } else {
                        return utils:createFhirPathError("No result found for the given FHIRPath expression in one of the patient: " ,fhirPathRule);
                    }
                }
                if score >= rulesTable.threshold{
                    return true;
                } else {
                    return false;
                }
            }
            
        }
    }
  
};

function getPatients() returns r4:Patient[] {
    r4:Patient[] patientList = [
    {
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
    },
    {
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

    }
];
    return patientList;
}




