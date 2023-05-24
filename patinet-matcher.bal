import ballerinax/health.fhir.r4;

public type PatientMatcher distinct object {
    public function matchPatients(r4:Patient newPatient) returns (MatchingResult|error);
    public function verifyPatient(r4:Patient newPatient, r4:Patient oldPatient) returns (boolean|error);
};

# Record to store matching result
#
# + newPatient - new Patient who is being added to the system
# + matchedPatient - Matched Patient 
# + ismatch - flag to indicate whether the two patients are matched 
public type MatchingResult record {
    r4:Patient newPatient;
    r4:Patient? matchedPatient;
    boolean ismatch;
};
