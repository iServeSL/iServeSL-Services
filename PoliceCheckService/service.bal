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

        string criminalStatus = "";

        if isValidNIC {
            map<json> filter_query = {"NIC": NIC};
            stream<PoliceEntry, error?> policeEntry = checkpanic mongoClient->find(collectionName = "police", filter = filter_query, 'limit = 1);

            check policeEntry.forEach(function(PoliceEntry entry) {
                criminalStatus = entry.criminalstatus;
            });

            if criminalStatus is "" {
                criminalStatus = "clear";
            }

        } else {
            return false;
        }

        return true;
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
