import ballerinax/health.fhir.r4utils.patientmatching as pm;
import ballerinax/health.fhir.r4;
import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;

isolated final readonly & pm:PatientMatcherRecord newPatientMatcher = {
    matchPatients: ruleBasedMatchPatients,
    verifyPatient: ruleBasedVerifyPatient,
    getMpiDbClient: getMpiDbClient
};

public isolated function ruleBasedMatchPatients(r4:Patient sourcePatient, json config) returns error|http:Response {
    http:Response response = new;
    response.statusCode = 200;
    response.setPayload("Rule based patient matching is not implemented yet");
    return response;

}

public isolated function getMpiDbClient(json config) returns sql:Client|error {

    mysql:Client dbClient = check new ("dbConfig.host", "dbConfig.username", "dbConfig.password", "dbConfig.database", 2012);
    return dbClient;
}

public isolated function ruleBasedVerifyPatient(r4:Patient sourcePatient, r4:Patient targetPatient, json config) returns error|http:Response {
    http:Response response = new;
    response.statusCode = 200;  
    response.setPayload("Rule based patient matching is not implemented yet");
    return response;
}
