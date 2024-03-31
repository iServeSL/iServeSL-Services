import MessagingService.Types;
import ballerina/http;
import ballerinax/twilio;
import ballerina/log;

configurable string twilioPhoneNumber = "+12512415480";
configurable string accountSID = "ACead5af59bdc241e0d32b3315fd5fca44";
configurable string authToken = "df552cfc2a8314d94b86d8c2c2e24044";
twilio:ConnectionConfig twilioConfig = {
    twilioAuth: {
        accountSId: accountSID,
        authToken: authToken
    }
};

twilio:Client twilioClient = check new (twilioConfig);

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

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
