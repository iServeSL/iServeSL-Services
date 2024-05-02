import MessagingService.Types;
import ballerina/http;
import ballerinax/twilio;
import ballerina/log;

configurable string twilioPhoneNumber = "+12512415480";
configurable string accountSID = "ACead5af59bdc241e0d32b3315fd5fca44";
configurable string authToken = "5e264a92d29f8fe9da037bf3384d8911";
twilio:ConnectionConfig twilioConfig = {
    twilioAuth: {
        accountSId: accountSID,
        authToken: authToken
    }
};

twilio:Client twilioClient = check new (twilioConfig);

# A service representing a network-accessible API
# bound to port `6060`.
service / on new http:Listener(6060) {

    resource function post message(@http:Payload Types:MessageRequest messageRequest) returns string|error {
        twilio:SmsResponse|error smsResponse = twilioClient->sendSms(twilioPhoneNumber, messageRequest.recipient, messageRequest.message);
        if (smsResponse is error) {
            log:printError(smsResponse.toString());
            return smsResponse;
        } else {
            log:printInfo(smsResponse.toJsonString());
            return smsResponse.toJsonString();
        }
    }
}
