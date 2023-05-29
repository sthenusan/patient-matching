// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4utils as fhirpath;
import ballerinax/mysql;

const SEARCH_SET = "searchset";
const RESULT = "result";

# Record to hold fhirpath rules.
public type RulesRecord record {|
    # array of fhirpath rules
    string[] fhirpathArray;
|};

# Record to hold MPI database configuration details.
public type MPIDbConfig record {|
    # host name of MPI database
    string host;
    # port of MPI database
    int port;
    # username of MPI database
    string username;
    # password of MPI database
    string password;
    # database name of MPI database
    string database;
|};

# Implementation of the RuleBasedPatientMatching Algorithm.
public isolated class RuleBasedPatientMatcher {
    *PatientMatcher;

    public isolated function matchPatients(PatientMatchRequest patientMatchRequest, ConfigurationRecord? config) returns error|http:Response {
        json[] parametersArray = patientMatchRequest.'parameter;
        r4:Patient|error sourcePatient = (check parametersArray[0].'resource).cloneWithType();
        string|error strPatientCount = (check parametersArray[1].valueInteger).cloneWithType();
        string|error strOnlyCertainMatches = (check parametersArray[2].valueBoolean).cloneWithType();
        if sourcePatient is error {
            string errorMessage = "Error occurred while getting the source patient from the request.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, sourcePatient.detail().toString(), cause = sourcePatient,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if strPatientCount is error {
            string errorMessage = "Error occurred while getting the expected patient count from the request.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, strPatientCount.detail().toString(), cause = strPatientCount,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if strOnlyCertainMatches is error {
            string errorMessage = "Error occurred while getting the OnlyCertainMatches boolean flag from the request.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, strOnlyCertainMatches.detail().toString(), cause = strOnlyCertainMatches,
                        statuscode = http:STATUS_BAD_REQUEST);
        }

        int|error patientCount = int:fromString(strPatientCount);
        boolean|error onlyCertainMatches = boolean:fromString(strOnlyCertainMatches);
        if patientCount is error {
            string errorMessage = "Error occurred while casting the patient count string to integer.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, patientCount.detail().toString(), cause = patientCount,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if onlyCertainMatches is error {
            string errorMessage = "Error occurred while casting the onlyCertainMatches flag from string to boolean.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, onlyCertainMatches.detail().toString(), cause = onlyCertainMatches,
                        statuscode = http:STATUS_BAD_REQUEST);
        }

        r4:BundleEntry[]|error? patientArray = self.getMatchingPatients(<r4:Patient>sourcePatient, config ?: {});
        if patientArray is () {
            http:Response response = new;
            response.setJsonPayload("No matching patient found");
            return response;
        }
        if patientArray is error {
            string errorMessage = "Error occurred while getting the matching patients from MPI.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, patientArray.detail().toString(), cause = patientArray,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        http:Response response = new;
        if onlyCertainMatches is true && patientArray.length() > 1 {
            response.setJsonPayload("Multiple matching patients found while onlyCertainMatches flag is true");
        }
        if patientArray.length() < patientCount {
            r4:Bundle bundle = {
                'type: SEARCH_SET,
                total: patientArray.length(),
                'entry: patientArray,
                timestamp: time:utcNow().toString()
            };
            response.setJsonPayload(bundle.toJson());
        } else {
            patientArray.setLength(patientCount);
            r4:Bundle bundle = {
                'type: SEARCH_SET,
                total: patientArray.length(),
                'entry: patientArray,
                timestamp: time:utcNow().toString()
            };
            response.setJsonPayload(bundle.toJson());
        }
        return response;
    }

    isolated function getMpiDbClient(ConfigurationRecord config) returns sql:Client|error {
        MPIDbConfig|error dbConfig = self.getMPIConfigData(config);
        if dbConfig is error {
            string errorMessage = "Error occurred while getting the configurations details for the database client from config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, dbConfig.detail().toString(), cause = dbConfig,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        mysql:Client dbClient = check new (dbConfig.host, dbConfig.username, dbConfig.password, dbConfig.database, dbConfig.port);
        return dbClient;
    }

    isolated function getMatchingPatients(r4:Patient patient, ConfigurationRecord config) returns error|r4:BundleEntry[] {
        stream<record {}, sql:Error?>|error dbPatientStream = self.getMPIData(patient, check self.getPatientMatcherRuleData(config), config);
        if dbPatientStream is error {
            string errorMessage = "Error occurred while getting the matching patients from MPI.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, dbPatientStream.detail().toString(), cause = dbPatientStream,
                        statuscode = http:STATUS_NOT_FOUND);
        }
        r4:BundleEntry[] patients = [];
        record {|anydata...;|}[]|sql:Error patientArray = from record {} patientRecords in dbPatientStream
            select patientRecords;
        if patientArray is sql:Error {
            string errorMessage = "Error occurred while getting the matching patients from MPI.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, patientArray.detail().toString(), cause = patientArray,
                        statuscode = http:STATUS_NOT_FOUND);
        }
        foreach int i in 0 ... patientArray.length()-1 {
            r4:BundleEntrySearch bundleEntrySearch = {
                mode: "match",
                score: 1.0
            };
            r4:BundleEntry bundleEntry = {
                'resource: patientArray[i],
                search: bundleEntrySearch

            };
            patients.push(bundleEntry);
        }
        return patients;
    }

    isolated function getMPIData(r4:Patient patient, RulesRecord rulesTable, ConfigurationRecord config) returns stream<record {}, sql:Error?>|error {
        sql:Client|error dbClient = self.getMpiDbClient(config);
        if dbClient is error {
            string errorMessage = "Error occurred while getting the database client to access MPI.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, dbClient.detail().toString(), cause = dbClient,
                        statuscode = http:STATUS_NOT_FOUND);
        }
        error|string qry = self.getSQLQuery(patient, rulesTable, config);
        if qry is error {
            string errorMessage = "Error occurred while generating SQL query.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, qry.detail().toString(), cause = qry,
                        statuscode = http:STATUS_NOT_FOUND);
        }
        sql:ParameterizedQuery queryString = ``;
        queryString.strings = [qry];
        stream<record {}, sql:Error?> resultStream = dbClient->query(queryString);
        return resultStream;
    }

    isolated function getMPIConfigData(ConfigurationRecord config) returns MPIDbConfig|error {
        json|error masterPatientIndexHost = config?.masterPatientIndexHost;
        json|error masterPatientIndexPort = config?.masterPatientIndexPort;
        json|error masterPatientIndexDb = config?.masterPatientIndexDb;
        json|error masterPatientIndexDbUser = config?.masterPatientIndexDbUser;
        json|error masterPatientIndexDbPassword = config?.masterPatientIndexDbPassword;
        if masterPatientIndexHost is error {
            string errorMessage = "Error occurred while getting the masterPatientIndexHost from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, masterPatientIndexHost.detail().toString(), cause = masterPatientIndexHost,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if masterPatientIndexPort is error {
            string errorMessage = "Error occurred while getting the masterPatientIndexPort from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, masterPatientIndexPort.detail().toString(), cause = masterPatientIndexPort,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if masterPatientIndexDb is error {
            string errorMessage = "Error occurred while getting the masterPatientIndexDb from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, masterPatientIndexDb.detail().toString(), cause = masterPatientIndexDb,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if masterPatientIndexDbUser is error {
            string errorMessage = "Error occurred while getting the masterPatientIndexDbUser from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, masterPatientIndexDbUser.detail().toString(), cause = masterPatientIndexDbUser,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if masterPatientIndexDbPassword is error {
            string errorMessage = "Error occurred while getting the masterPatientIndexDbPassword from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, masterPatientIndexDbPassword.detail().toString(), cause = masterPatientIndexDbPassword,
                    statuscode = http:STATUS_BAD_REQUEST);
        }
        MPIDbConfig mpiDbConfig = {
            host: <string>masterPatientIndexHost,
            port: <int>masterPatientIndexPort,
            database: <string>masterPatientIndexDb,
            username: <string>masterPatientIndexDbUser,
            password: <string>masterPatientIndexDbPassword
        };
        return mpiDbConfig;
    }

    isolated function getSQLQuery(r4:Patient patient, RulesRecord rulesTable, ConfigurationRecord config) returns (error|string) {
        json|error MPIColumnNames = config?.masterPatientIndexColumnNames;
        json|error MPITableName = config?.masterPatientIndexTableName;
        if MPIColumnNames is error {
            string errorMessage = "Error occurred while getting the MPIColumnNames from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, MPIColumnNames.detail().toString(), cause = MPIColumnNames,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        if MPITableName is error {
            string errorMessage = "Error occurred while getting the MPITableName from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, MPITableName.detail().toString(), cause = MPITableName,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        json[] parameters = <json[]>MPIColumnNames;
        string tableName = <string>MPITableName;
        string query = "SELECT * FROM ";
        query = string `${query} ${tableName} WHERE `;
        int lastIndex = parameters.length() - 1;
        foreach int i in 0 ... parameters.length() {
            string fhirPathRule = rulesTable.fhirpathArray[i];
            fhirpath:FhirPathResult fhirPathResult = fhirpath:getFhirPathResult(<map<json>>patient.toJson(), fhirPathRule);
            if i == lastIndex {
                string fhirPathRuleLastIndex = rulesTable.fhirpathArray[i];
                map<anydata> resultMapLastIndex = fhirpath:getFhirPathResult(<map<json>>patient.toJson(), fhirPathRuleLastIndex);
                if resultMapLastIndex.hasKey(RESULT) {
                    json resultValue = <json>fhirPathResult.get(RESULT);
                    if resultValue is json[] {
                        json[] resultJson = <json[]>fhirPathResult.get(RESULT);
                        json resultFirstElement = resultJson[0];
                        string queryParam = string `${"\""}${resultFirstElement.toString()}${"\""}`;
                        query = string ` ${query} ${parameters[i].toString()} = ${queryParam}`;
                    } else {
                        string queryParam = string `${"\""}${resultValue.toString()}${"\""}`;
                        query = string `${query} ${parameters[i].toString()} = ${queryParam}`;
                    }
                    break;
                } else {
                    return fhirpath:createFhirPathError("No result found for the given FHIRPath expression in the patient: ", fhirPathRuleLastIndex);
                }
            }
            if fhirPathResult.hasKey(RESULT) {
                json resultPath = <json>fhirPathResult.get(RESULT);
                if fhirPathResult.get(RESULT) is json[] {
                    json[] resultValue = <json[]>fhirPathResult.get(RESULT);
                    json resultFirstElement = resultValue[0];
                    string queryParam = string `${"\""}${resultFirstElement.toString()}${"\""}`;
                    query = string `${query} ${parameters[i].toString()} = ${queryParam} AND `;
                } else {
                    string queryParam = string `${"\""}${resultPath.toString()}${"\""}`;
                    query = string `${query} ${parameters[i].toString()} = ${queryParam} AND `;
                }
            } else {
                return fhirpath:createFhirPathError("No result found for the given FHIRPath expression in the patient: ", fhirPathRule);
            }
        }
        return query;
    }

    isolated function getPatientMatcherRuleData(ConfigurationRecord config) returns RulesRecord|error {
        json|error fhirpaths = config?.fhirpaths;
        if fhirpaths is error {
            string errorMessage = "Error occurred while getting the FHIRPath rules from the config.json file.";
            return throwFHIRError(errorMessage, r4:ERROR, r4:TRANSIENT_EXCEPTION, fhirpaths.detail().toString(), cause = fhirpaths,
                        statuscode = http:STATUS_BAD_REQUEST);
        }
        return {
            fhirpathArray: from json path in <json[]>fhirpaths select path.toString()
        };
    }
};

isolated function throwFHIRError(string message, r4:Severity errServerity, r4:IssueType code, string diagnostic
            , error cause, int statuscode) returns r4:FHIRError => r4:createFHIRError(message = message, errServerity = errServerity,
                        code = code, diagnostic = diagnostic, cause = cause, httpStatusCode = statuscode);

# Record to hold the patient match request.
public type PatientMatchRequest record {
    # resource type name
    string resourceType;
    # resource Id
    string id;
    # parameter resource in fhir specification
    json[] 'parameter;
};

# Record to hold the configuration details for the rule based patient matching algorithm.
public type ConfigurationRecord record {
    # fhirpaths to be used in the patient matching algorithm 
    json fhirpaths?;
    # column names of the MPI table
    json masterPatientIndexColumnNames?;
    # MPI table name
    json masterPatientIndexTableName?;
    # MPI DB host
    json masterPatientIndexHost?;
    # MPI DB port
    json masterPatientIndexPort?;
    # MPI DB name
    json masterPatientIndexDb?;
    # MPI DB username
    json masterPatientIndexDbUser?;
    # MPI DB password for the username
    json masterPatientIndexDbPassword?;
};
