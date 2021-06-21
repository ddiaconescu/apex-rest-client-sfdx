/**
 * Created by DDiaconescu on 28/12/2018.
 */

@IsTest
private class Rest_Log_Event_Test {
    @IsTest
    static void publishEvent() {
        String testString = TestUtils.generateRandomString(240);
        Datetime startTime = system.now();
        Datetime endTime = startTime.addSeconds(1);

        Rest_Log_Event__e restLogEvent = new Rest_Log_Event__e();
        restLogEvent.Method__c = 'GET';
        restLogEvent.Request_Body__c = testString + '_request_body';
        restLogEvent.Response_Body__c = testString + '_response_body';
        restLogEvent.Message__c = testString + '_message';
        restLogEvent.Status__c = 'Failure';
        restLogEvent.Endpoint__c = testString + '_endpoint';
        restLogEvent.Error_Code__c = '500';
        restLogEvent.Start_Time__c = startTime;
        restLogEvent.End_Time__c = endTime;

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(restLogEvent);
        Test.stopTest();

        Rest_Log__c restLog = [SELECT Id, Method__c, Request_Body__c, Response_Body__c, Message__c, Status__c, Endpoint__c, Error_Code__c, Start_Time__c, End_Time__c, Duration__c FROM Rest_Log__c LIMIT 1];

        system.assert(restLog != null);
        system.assertEquals('GET', restLog.Method__c);
        system.assertEquals(testString + '_request_body', restLog.Request_Body__c);
        system.assertEquals(testString + '_response_body', restLog.Response_Body__c);
        system.assertEquals(testString + '_message', restLog.Message__c);
        system.assertEquals(testString + '_endpoint', restLog.Endpoint__c);
        system.assertEquals('Failure', restLog.Status__c);
        system.assertEquals('500', restLog.Error_Code__c);
        system.assertEquals(startTime, restLog.Start_Time__c);
        system.assertEquals(endTime, restLog.End_Time__c);
        system.assertEquals(1, restLog.Duration__c);

    }
}