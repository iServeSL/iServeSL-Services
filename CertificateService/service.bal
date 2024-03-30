import ballerina/io;
import ballerina/http;
import ballerina/log;
import ballerinax/mongodb;
import CertificateService.Types;
import ballerina/uuid;

mongodb:ConnectionConfig mongoConfig = {
    connection: {
        url: "mongodb+srv://SachinAkash01:wvHYdk4g9OwjUTsw@iservesl-db.7oh0h24.mongodb.net/iServeSL-DB?retryWrites=true&w=majority"
    },
    databaseName: "iServeSL-DB"
};
//Create a new database client
mongodb:Client mongoClient = checkpanic new (mongoConfig);

configurable string messagingService = "https://localhost:9090/message";
//Create a new messaging service client
http:Client messagingServiceClient = check new(messagingService);

type requestData record {
    json _id;
    string NIC;
    map<json> address;
    string status;
    string phone;
    string id;
};

type requestCheck record {
    string NIC;
    string status;
};

type requestCompletedCheck record {
    string id;
    string status;
    string NIC;
};

type requestCompletedData record{
    string NIC;
    string fullname;
    map<json> address;
    string DoB;
    string criminalstatus;
};

type RequestConflict record {|
    *http:Conflict;
    record {
        string message;
    } body;
|};

service / on new http:Listener(8080) {
    //creating an entry for user requests
    resource function post newRequestRecord(@http:Payload Types:CertificateRequest request) returns string|RequestConflict|error {
        log:printInfo(request.toJsonString());

        string uuidString = uuid:createType1AsString();
        boolean valid = false;

        map<json> doc = {
            "NIC": request.NIC,
            "address": {
                "no": request.no,
                "street": request.street,
                "village": request.village,
                "city": request.city,
                "postalcode": request.postalcode
            },
            "status": "pending",
            "phone": request.phone,
            "id": uuidString
        };

        map<json> queryString = {"NIC": request.NIC, "status": "pending"};
        stream<requestCheck, error?> result = check mongoClient->find(collectionName = "requests", filter = (queryString));
        
        check result.forEach(function(requestCheck datas) {
            valid = true;
        });

        if (!valid){
            error? insertResult = check mongoClient->insert(doc, collectionName = "requests");
            if (insertResult !is error) {
                return uuidString;
            }
            else{
                return {body: { message: "Request already exists" }};
            }
        }
        else{
            return {body: { message: "Request already exists" }};
        }    
    }

    //Get user requests from the database
    resource function get getRequests() returns requestData[]|error {

        stream<requestData, error?> resultData = check mongoClient->find(collectionName = "requests");

        requestData[] allData = [];
        int index = 0;
        check resultData.forEach(function(requestData data) {
            allData[index] = data;
            index += 1;

            io:println(data.id);
            io:println(data.NIC);
            io:println(data.address);
            io:println(data.status);
            io:println(data.phone);
            io:println(data.id);

        });

        return allData;
    }

    //Get a specific record
    resource function get getReqRecord/[string id]() returns requestData[]|error? {

        map<json> queryString = {"id": id};
        stream<requestData, error?> resultData = check mongoClient->find(collectionName = "requests", filter = (queryString));
        requestData[] allData = [];
        int index = 0;
        check resultData.forEach(function(requestData data) {
            allData[index] = data;
            index += 1;

            io:println(data.NIC);
            io:println(data.address);
            io:println(data.status);
            io:println(data.phone);
            io:println(data.id);
        });

        return allData;
    }

    //get details of users
    resource function get getCompletedReq/[string id]() returns json|error? {
        boolean valid = false;
        string nic ="";
        map<json> queryString = {"id": id, "status": "completed"};
        stream<requestCompletedCheck, error?> result = check mongoClient->find(collectionName = "requests", filter = (queryString));
        json[] allData = [];

        check result.forEach(function(requestCompletedCheck datas) {
            valid = true;
            nic = datas.NIC;
        });

        if (valid){
            map<json> queryString1 = {"NIC": nic};
            stream<requestCompletedData, error?> resultData = check mongoClient->find(collectionName = "police", filter = queryString1);
            
            check resultData.forEach(function(requestCompletedData data) {
                json dataJson = {
                "NIC": data.NIC,
                "fullname": data.fullname,
                "address": data.address,
                "DoB": data.DoB,
                "criminalstatus": data.criminalstatus
            };
            allData.push(dataJson);
            });
            json responseData = {"id": id, "data": allData[0]};

            return responseData;
        }
        else{
            return ();
        }
    }

    //Updating user request status
    resource function put updateRequest/[string id]/[string status]() returns int|error {

        map<json> queryString = {"$set": {"status": status}};
        map<json> filter = {"id": id};

        int|error resultData = check mongoClient->update(queryString, "requests", filter = filter);

        if (status == "completed") {
            map<json> filter_query = {"id": id};
            stream<requestData, error?> entry_details = checkpanic mongoClient->find(collectionName = "requests", filter = filter_query, 'limit = 1);

            string phone_number = "";
            check entry_details.forEach(function(requestData entry) {
                phone_number = entry.phone;
            });

            log:printInfo(phone_number.toJsonString());

            string|error smsResponse = check messagingServiceClient->/message.post({
                recipient: phone_number,
                message: string `Your Certificate Request has been completed. Use the ID '${id}' to download the certificate.`
            });

            if (smsResponse is error) {
                log:printError(smsResponse.toString());
            } else {
                log:printInfo(smsResponse.toJsonString());
            }
        }

        return resultData;
    }
}
