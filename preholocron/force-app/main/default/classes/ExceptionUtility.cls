/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class ExceptionUtility {
    public static void createExceptionLog(String ClassName,String ObjectName,String MethodName,String TriggerName,Exception e) {
        List<Exception_Logger__c> exceptionList = new List<Exception_Logger__c>();
        
        //Create Exception Logger Record
        Exception_Logger__c ExLoggerRec = new Exception_Logger__c();
        ExLoggerRec.Error_Category__c = e.getTypeName();
        ExLoggerRec.Error_Line_Number__c = e.getLineNumber();
        ExLoggerRec.Error_Message__c = e.getMessage();
        ExLoggerRec.Error_Stack_Trace__c = e.getStackTraceString();
        ExLoggerRec.Object_Name__c = ObjectName;
        ExLoggerRec.Trigger_Name__c = TriggerName;
        ExLoggerRec.Class_Name__c = ClassName;
        ExLoggerRec.Method_Name__c = MethodName;
        
        exceptionList.add(ExLoggerRec);
        
        try{
            insert exceptionList;
        }Catch(DmlException dmlEx){
            System.debug('There is problem on creating Exception Log:' + dmlEx.getMessage());
        }
    }

    public static Exception_Logger__c constructDatabaseError(String ClassName,String ObjectName,String MethodName,String TriggerName,String errorMessage) {
        //Create Exception Logger Record
        Exception_Logger__c ExLoggerRec = new Exception_Logger__c();
        ExLoggerRec.Error_Category__c = '';
        ExLoggerRec.Error_Line_Number__c = null;
        ExLoggerRec.Error_Message__c = errorMessage;
        ExLoggerRec.Error_Stack_Trace__c = '';
        ExLoggerRec.Object_Name__c = ObjectName;
        ExLoggerRec.Trigger_Name__c = TriggerName;
        ExLoggerRec.Class_Name__c = ClassName;
        ExLoggerRec.Method_Name__c = MethodName;
        
        return ExLoggerRec;
    }
}