import ballerina/http;
import ballerinax/mongodb;
import ballerina/regex;

//Database Connection
mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:<password>@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
mongodb:Client mongoClient = checkpanic new (mongoConfig);

# A service representing a network-accessible API
# bound to port `5050`.
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"]
    }
}
service / on new http:Listener(5050) {

    resource function get checkAvailability/[string NIC]() returns boolean|InvalidNicError?|error {
        // Validate the NIC format using a regular expression
        string nicPattern = "^(\\d{9}[vVxX]|\\d{12})$"; // NIC pattern with or without 'v' or 'x'
        // Check if the NIC matches the pattern
        boolean isValidNIC = regex:matches(NIC, nicPattern);

        // string criminalStatus = "";

        if isValidNIC {
            boolean valid = false;
            map<json> queryString = {"NIC": NIC};
            stream<PoliceEntry, error?> resultData = check mongoClient->find(collectionName = "police", filter = (queryString));

            check resultData.forEach(function(PoliceEntry datas) {

                valid = true;

            });

            return valid;
            //     criminalStatus = entry.criminalstatus;
            // });

            // if criminalStatus is "" {
            //     criminalStatus = "clear";
            // }

        } else {
            return {
                body: {
                    errmsg: string `Invalid NIC: ${NIC}`
                }
            };
        }
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
