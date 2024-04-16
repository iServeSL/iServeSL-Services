# Copyright (c) 2024 Sachin Akash

import ballerina/http;
import ballerinax/mongodb;
import ballerina/regex;

//Database Connection
mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:wvHYdk4g9OwjUTsw@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
mongodb:Client mongoClient = checkpanic new (mongoConfig);

# A service representing a network-accessible API
# bound to port `7070`.

service / on new http:Listener(7070) {

    resource function get checkStatus/[string NIC]() returns string|InvalidNicError?|error {
        // Validate the NIC format using a regular expression
        string nicPattern = "^(\\d{9}[vVxX]|\\d{12})$"; // NIC pattern with or without 'v' or 'x'
        // Check if the NIC matches the pattern
        boolean isValidNIC = regex:matches(NIC, nicPattern);

        string status = "";

        if isValidNIC {
            map<json> filter_query = {"NIC": NIC};
            stream<PoliceEntry, error?> policeEntry = checkpanic mongoClient->find(collectionName = "police", filter = filter_query, 'limit = 1);

            check policeEntry.forEach(function(PoliceEntry entry) {
                status = entry.criminalstatus;
            });

            if status is "" {
                status = "clear";
            }

        } else {
            return {
                body: {
                    errmsg: string `Invalid NIC: ${NIC}`
                }
            };
        }

        return status;
    }
}

public type PoliceEntry record {
    readonly string NIC;
    string criminalstatus;
};

public type InvalidNicError record {|
    *http:BadRequest;
    ErrorMsg body;
|};

public type ErrorMsg record {|
    string errmsg;
|};
