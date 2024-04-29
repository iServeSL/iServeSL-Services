# Copyright (c) 2024 Sachin Akash

import ballerina/http;
import ballerinax/mongodb;
import ballerina/regex;

type Citizen record {
    json _id;
    string NIC;
};

mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:wvHYdk4g9OwjUTsw@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
//creating a new client
mongodb:Client mongoClient = checkpanic new (mongoConfig);

service / on new http:Listener(7070) {

    //Check for the given NIC
    resource function get checkNIC/[string NIC]() returns boolean|InvalidNicError?|error? {

        // Validate the NIC format using a regular expression
        string nicPattern = "^(\\d{9}[vVxX]|\\d{12})$"; // NIC pattern with or without 'v' or 'x'
        // Check if the NIC matches the pattern
        boolean isValidNIC = regex:matches(NIC, nicPattern);

        if isValidNIC {

            boolean valid = false;
            map<json> queryString = {"NIC": NIC};
            stream<Citizen, error?> resultData = check mongoClient->find(collectionName = "citizen", filter = (queryString));

            check resultData.forEach(function(Citizen datas) {

                valid = true;

            });

            return valid;

        } else {
            return {
                body: {
                    errmsg: string `Invalid NIC: ${NIC}`
                }
            };
        }

    }

}

public type InvalidNicError record {|
    *http:BadRequest;
    ErrorMsg body;
|};

public type ErrorMsg record {|
    string errmsg;
|};
