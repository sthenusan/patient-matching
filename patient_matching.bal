import wso2healthcare/healthcare.fhir.r4;

# record to store matching result
#
# + patientOne - Patient one  
# + patientTwo - Patient two  
# + ismatch - flag to indicate whether the two patients are matched 
# + score - Patient matching score
public type MatchingResult record {
    r4:Patient patientOne;
    r4:Patient patientTwo?;
    boolean ismatch;
    float score;
};

# fhirpath rule record
#
# + fhirPath - fhirpath expression  
# + weight - fhirpath weight
public type Rule record {
    string fhirPath;
    float weight;
};

# record to hold rules and threshold
#
# + ruleArray - rules array 
# + threshold - threshold value
public type RulesRecord record {
    Rule[] ruleArray;
    float threshold;
};

# calculate match score between two patients based on rules and weights
#
# + patientOne - Patient one 
# + patientList - List of patients to check match 
# + ruleTable - fhirpath rules and threshold
# + return - Returns matching result record
public isolated function calculateScore(r4:Patient patientOne, r4:Patient[] patientList, RulesRecord ruleTable) returns MatchingResult|error {

    float maxScore = 0;
    r4:Patient maxScorePatientTwo = patientList[0];
    foreach r4:Patient patientTwo in patientList {
        float score = 0;
        foreach Rule item in ruleTable.ruleArray {
            string fhirPathRule = item.fhirPath;
            map<anydata> resultMapPatientOne = getFhirPathResult(<map<json>>patientOne.toJson(), fhirPathRule).entries();
            map<anydata> resultMapPatientTwo = getFhirPathResult(<map<json>>patientTwo.toJson(), fhirPathRule).entries();
            if (resultMapPatientOne.hasKey("result") && resultMapPatientTwo.hasKey("result")) {
                float x = ((resultMapPatientOne.get("result") == resultMapPatientTwo.get("result")) ? item.weight : 0);
                score += x;
            } else {
                return createFhirPathError("No result found for the given FHIRPath expression in one of the patient: " ,fhirPathRule);
                
              
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
            patientOne: patientOne,
            patientTwo: maxScorePatientTwo,
            ismatch: true,
            score: maxScore
        };
    } else {
        return {
            patientOne: patientOne,
            patientTwo: (),
            ismatch: false,
            score: maxScore
        };
    }

}
