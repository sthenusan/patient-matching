import ballerinax/health.fhir.r4;

public type PatientMatcher distinct object {
    public function matchPatients(r4:Patient patient, r4:Patient[] patientList) returns (MatchingResult|error);

};

# record to store matching result
#
# + newPatient - new Patient who is being added to the system
# + matchedPatient - Matched Patient 
# + ismatch - flag to indicate whether the two patients are matched 
public type MatchingResult record {
    r4:Patient newPatient;
    r4:Patient matchedPatient?;
    boolean ismatch;
};