trigger Rest_Log_Event on Rest_Log_Event__e (after insert) {
    List<Rest_Log__c> restLogList = new List<Rest_Log__c>();
    for (Rest_Log_Event__e item : Trigger.new) {
        Rest_Log__c restLog = new Rest_Log__c();
        restLog.End_Time__c = item.End_Time__c;
        restLog.Endpoint__c = item.Endpoint__c;
        restLog.Error_Code__c = item.Error_Code__c;
        restLog.Message__c = item.Message__c;
        restLog.Method__c = item.Method__c;
        restLog.Request_Body__c = item.Request_Body__c;
        restLog.Response_Body__c = item.Response_Body__c;
        restLog.Stack_Trace__c = item.Stack_Trace__c;
        restLog.Start_Time__c = item.Start_Time__c;
        restLog.Status__c = item.Status__c;

        restLogList.add(restLog);
    }
    insert restLogList;
}