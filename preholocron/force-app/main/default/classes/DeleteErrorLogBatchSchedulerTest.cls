@isTest()

private class DeleteErrorLogBatchSchedulerTest {
    
    @isTest
    static void deleteErrorLog(){
        Exception_Logger__c ExLoggerRec = new Exception_Logger__c();
        ExLoggerRec.Error_Category__c = 'System.CalloutException';
        ExLoggerRec.Error_Line_Number__c = 50;
        ExLoggerRec.Error_Message__c = 'Connection or inbound has closed';
        ExLoggerRec.Error_Stack_Trace__c = 'Class.REST_AdminDashboardSyncSetup.updateUserFields: line 50, column 1';
        ExLoggerRec.Object_Name__c = 'Account/Lead';
        ExLoggerRec.Trigger_Name__c = 'HttpPatch';
        ExLoggerRec.Class_Name__c = 'updateUserFields';
        ExLoggerRec.Method_Name__c = 'updateUserFields';
        insert ExLoggerRec;

        DeleteErrorLogBatchScheduler cx = new DeleteErrorLogBatchScheduler(true);
        Database.executeBatch(cx, 1);
        
        String sch = '0 0 1 * * ? *'; 
        System.schedule('Weekly_Delete_Log_Batch_Test', sch, cx );
    }
}