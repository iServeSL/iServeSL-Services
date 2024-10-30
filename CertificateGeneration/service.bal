import ballerina/io;
import ballerina/http;
import ballerinax/mongodb;

mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:<password>@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
//Create a new database client
mongodb:Client mongoClient = checkpanic new (mongoConfig);

configurable string messagingService = "http://localhost:6060";
//Create a new messaging service client
http:Client messagingServiceClient = check new(messagingService);

type policeUserData record {
    string NIC;
    string fullname;
    map<json> address;
    string DoB;
    string criminalstatus;
};

type citizenUserData record {
    string NIC;
    string fullname;
    map<json> address;
    string DoB;
    string maritalStatus;
};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"]
    }
}
service / on new http:Listener(8081) {
    //Get a specific user record (Police character certificate generation)
    resource function get getPoliceUserRecord/[string nic]() returns policeUserData[]|error? {

        map<json> queryString = {"NIC": nic};
        stream<policeUserData, error?> resultData = check mongoClient->find(collectionName = "police", filter = (queryString));
        policeUserData[] allData = [];
        int index = 0;
        check resultData.forEach(function(policeUserData data) {
            allData[index] = data;
            index += 1;

            io:println(data.NIC);
            io:println(data.fullname);
            io:println(data.address);
            io:println(data.DoB);
            io:println(data.criminalstatus);
        });

        return allData;
    }

    //Get a specific user record (Grama niladhari certificate generation)
    resource function get getCitizenUserRecord/[string nic]() returns citizenUserData[]|error? {

        map<json> queryString = {"NIC": nic};
        stream<citizenUserData, error?> resultData = check mongoClient->find(collectionName = "citizen", filter = (queryString));
        citizenUserData[] allData = [];
        int index = 0;
        check resultData.forEach(function(citizenUserData data) {
            allData[index] = data;
            index += 1;

            io:println(data.NIC);
            io:println(data.fullname);
            io:println(data.address);
            io:println(data.DoB);
            io:println(data.maritalStatus);
        });

        return allData;
    }
}
