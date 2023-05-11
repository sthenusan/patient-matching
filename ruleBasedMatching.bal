import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4utils as utils;
import ballerina/io;

public class RuleBasedPatientMatching {
    *PatientMatcher;

    public function matchPatients(r4:Patient patient, r4:Patient[] patientList) returns MatchingResult|error {
        return getPatientMatchingResult(patient, patientList);
    }
}

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
public type RulesListRecord record {
    Rule[] ruleArray;
    float threshold;
};

# Record to hold configuration details
#
# + threshold - threshold value for matching
# + fhirpaths - rule fhirpaths  
# + weights - weights for each rule
public type ConfigRecord record {
    float threshold;
    json [] fhirpaths;
    json [] weights;
};

# Calculate match score between two patients based on rules and weights
#
# + patientOne - Patient one 
# + patientList - List of patients to check match 
# + ruleTable - fhirpath rules and threshold
# + return - Returns matching result record
public isolated function calculateScore(r4:Patient patientOne, r4:Patient[] patientList, RulesListRecord ruleTable) returns MatchingResult|error {

    float maxScore = 0;
    r4:Patient maxScorePatientTwo = patientList[0];
    foreach r4:Patient patientTwo in patientList {
        float score = 0;
        foreach Rule item in ruleTable.ruleArray {
            string fhirPathRule = item.fhirPath;
            map<anydata> resultMapPatientOne = utils:getFhirPathResult(<map<json>>patientOne.toJson(), fhirPathRule).entries();
            map<anydata> resultMapPatientTwo = utils:getFhirPathResult(<map<json>>patientTwo.toJson(), fhirPathRule).entries();
            if (resultMapPatientOne.hasKey("result") && resultMapPatientTwo.hasKey("result")) {
                float x = ((resultMapPatientOne.get("result") == resultMapPatientTwo.get("result")) ? item.weight : 0);
                score += x;
            } else {
                return utils:createFhirPathError("No result found for the given FHIRPath expression in one of the patient: " ,fhirPathRule);
                
              
            }
        }
        if score >= ruleTable.threshold && score > maxScore {
            maxScore = score;
            maxScorePatientTwo = patientTwo;
        }

    }
    // return matching result if max score is greater than threshold
    if maxScore >= ruleTable.threshold {
        return {
            newPatient: patientOne,
            matchedPatient: maxScorePatientTwo,
            ismatch: true
        };
    } else {
        return {
            newPatient: patientOne,
            matchedPatient: (),
            ismatch: false
        };
    }

}


public isolated function getPatientMatchingResult(r4:Patient patientOne , r4:Patient [] patientList) returns MatchingResult|error {

    json|io:Error readfile = io:fileReadJson("config.json");
    
    if readfile is io:Error {
        io:println("File is error");

    } else {
        json|error threshold =  readfile.threshold;
        json|error fhirpaths =  readfile.fhirpaths;
        json|error weights = readfile.weights;

        

        if threshold is error|| fhirpaths is error || weights is error {
            return utils:createFhirPathError("Configuration error","");
        } else {
            Rule [] rules =[];
            ConfigRecord config = {
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

            RulesListRecord rulesTable = {
                ruleArray: rules,
                threshold: config.threshold
            };
            
            return calculateScore(patientOne, patientList,rulesTable);

        }
    }
    return utils:createFhirPathError("Configuration error"," ");
}
