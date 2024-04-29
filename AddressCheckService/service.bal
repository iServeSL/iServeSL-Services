import ballerina/http;
import ballerinax/mongodb;
import ballerina/regex;

type Citizen record {
    json _id;
    string NIC;
    map<json> address;
};

mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:wvHYdk4g9OwjUTsw@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
//creating a new client
mongodb:Client mongoClient = checkpanic new (mongoConfig);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"]
    }
}
service / on new http:Listener(9090) {

    //Check for the given Address
    resource function get checkAddress(string NIC, string no, string village, string city, string postalcode, string? street = " ") returns boolean|InvalidNicError?|error? {
        boolean valid = false;
        
        // Validate the NIC format using a regular expression
        string nicPattern = "^(\\d{9}[vVxX]|\\d{12})$"; // NIC pattern with or without 'v' or 'x'
        // Check if the NIC matches the pattern
        boolean isValidNIC = regex:matches(NIC, nicPattern);

        if isValidNIC {
            map<json> queryString = {
                "NIC": NIC,
                "address": {
                    "no": no,
                    "street": street == () ? "" : (<string>street).toLowerAscii(),
                    "village": village.toLowerAscii(),
                    "city": city.toLowerAscii(),
                    "postalcode": postalcode
                }
            };
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
