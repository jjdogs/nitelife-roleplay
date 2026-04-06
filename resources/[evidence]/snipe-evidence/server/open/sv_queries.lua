Queries = {
    ["check_dna"] = {
        ["qb"] = [[
            SELECT IF(p.citizenid = NULL,  "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name FROM players p 
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.dna = @dna AND sei.is_taken = 1
        ]],
        ["qbx"] = [[
            SELECT IF(p.citizenid = NULL,  "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name FROM players p 
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.dna = @dna AND sei.is_taken = 1
        ]],
        ["esx"] = [[
            SELECT IF(u.identifier = NULL, "UNKNOWN", CONCAT(firstname, lastname)) as name FROM users u 
            LEFT JOIN snipe_evidence_identifiers sei ON u.identifier = sei.identifier
            WHERE sei.dna = @dna AND sei.is_taken = 1
        ]]
    },
    ["check_fingerprint"] = {
        ["qb"] = [[
            SELECT IF(p.citizenid = NULL, "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name FROM players p 
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.fingerprint = @fingerprint AND sei.is_fingerprint_taken = 1
        ]],
        ["qbx"] = [[
            SELECT IF(p.citizenid = NULL, "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name FROM players p 
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.fingerprint = @fingerprint AND sei.is_fingerprint_taken = 1
        ]],
        ["esx"] = [[
            SELECT IF(u.identifier = NULL, "UNKNOWN", CONCAT(firstname, lastname)) as name FROM users u 
            LEFT JOIN snipe_evidence_identifiers sei ON u.identifier = sei.identifier
            WHERE sei.fingerprint = @fingerprint AND sei.is_fingerprint_taken = 1
        ]]
    },

    ["get_fingerprint_by_identifier"] = {
        ["qb"] = [[
            SELECT IF(p.citizenid = NULL, "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name, sei.fingerprint as fingerprint FROM players p
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.identifier = @identifier
        ]],

        ["qbx"] = [[
            SELECT IF(p.citizenid = NULL, "UNKNOWN", CONCAT(JSON_VALUE(p.charinfo, "$.firstname"), " ", JSON_VALUE(p.charinfo, "$.lastname"))) as name, sei.fingerprint as fingerprint FROM players p
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.identifier = @identifier
        ]],

        ["esx"] = [[
            SELECT IF(u.identifier = NULL, "UNKNOWN", CONCAT(firstname, lastname)) as name, sei.fingerprint FROM users u 
            LEFT JOIN snipe_evidence_identifiers sei ON u.identifier = sei.identifier
            WHERE sei.identifier = @identifier
        ]]
    },

    ["get_fingerprint_ui_data_by_identifier"] = {
        ["qb"] = [[
            SELECT sei.fingerprint as id, JSON_VALUE(p.charinfo, "$.firstname") as fname, JSON_VALUE(p.charinfo, "$.lastname") as lname, JSON_VALUE(p.charinfo, "$.birthdate") as dob, 
            (IF(JSON_VALUE(p.charinfo, "$.gender") = 0, "Male", "Female")) as gender, 
            sei.fingerprint as fingerprint, (IF(sei.is_fingerprint_taken = 1, true, false)) as is_registered FROM players p
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.identifier = @identifier
        ]],

        ["qbx"] = [[
            SELECT sei.fingerprint as id, JSON_VALUE(p.charinfo, "$.firstname") as fname, JSON_VALUE(p.charinfo, "$.lastname") as lname, JSON_VALUE(p.charinfo, "$.birthdate") as dob, 
            (IF(JSON_VALUE(p.charinfo, "$.gender") = 0, "Male", "Female")) as gender, 
            sei.fingerprint as fingerprint, (IF(sei.is_fingerprint_taken = 1, true, false)) as is_registered FROM players p
            LEFT JOIN snipe_evidence_identifiers sei ON p.citizenid = sei.identifier
            WHERE sei.identifier = @identifier
        ]],

        ["esx"] = [[
            SELECT sei.fingerprint as id, firstname as fname, lastname as lname, dateofbirth as dob, sex as gender, sei.fingerprint as fingerprint, (IF(sei.is_fingerprint_taken = 1, true, false)) as is_registered FROM users u 
            LEFT JOIN snipe_evidence_identifiers sei ON u.identifier = sei.identifier
            WHERE sei.identifier = @identifier
        ]],
    }


}