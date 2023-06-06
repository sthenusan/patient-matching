# Patient Matching Algorithm

## Introduction

* When a developer wants to implement a new type of patient matching algorithm. He/she can create a new class that extends the patient-macther interface and implement the abstract methods there.

* This service includes implementation for rule based patient matching algorithm. The algorithm is based on the rules that are deifined by developer and can be configured as FhirPaths in the config.json file. 

* The configurations may vary for different types of patient matching algorithms.

* Developer should define the configuration as explained below for the rule based Patient Matching Algorithm. 

* FhirPath rules for Patient Matching should be given as a list of strings in the config.json file.

* The Master Patient Index Table Name and column Names for the respective FhirPaths , Master Patient Index Database Configurations should be given for rule based Patient Matching Algorithm. 

* Sample Config.json file is given below for reference.

```
{
    "algorithm": "rulebased",
    "rulebased": {
        "fhirpaths": ["Patient.name.given[1]","Patient.name.family","Patient.gender","Patient.birthDate"],
        "MPIColumnNames":["FirstName","LastName","gender","dob"],
        "MPITableName" : "patient",
        "masterPatientIndexHost": "localhost",
        "masterPatientIndexPort": 3306,
        "masterPatientIndexDb": "patient_db",
        "masterPatientIndexDbUser": "root",
        "masterPatientIndexDbPassword": "0207THEnu$an"
    }
}
``` 
