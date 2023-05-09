import ballerina/io;
import wso2healthcare/healthcare.fhir.r4;

public isolated function getPatientMatchingResult(r4:Patient patientOne , r4:Patient [] patientList) returns MatchingResult|error {

    json|io:Error readfile = io:fileReadJson("config.json");
    
    if readfile is io:Error {
        io:println("File is error");

    } else {
        json|error threshold =  readfile.threshold;
        json|error fhirpaths =  readfile.fhirpaths;
        json|error weights = readfile.weights;

        

        if threshold is error|| fhirpaths is error || weights is error {
            return error("Configuration error");
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

            RulesRecord rulesTable = {
                ruleArray: rules,
                threshold: config.threshold
            };
            
            return calculateScore(patientOne, patientList,rulesTable);

        }
    }
    return error("Configuration error");
}

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