public class UpdateADUserBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public Id recId = null;
    List<SObject> scopeList = new List<sObject>();
    public String objName = '';
    public UpdateADUserBatch(Id recordId, String objectName) {
        recId = recordId;
        objName = objectName;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String additionalField = objName == 'Account' ? ' , Team_Assignment__c ' : '';
        String query = 'SELECT Id, CP_Manager__c, OwnerId, Business_ID__c, Update_to_AD__c ' + additionalField + ' FROM ' + objName + ' WHERE Id = :recId';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){

        scopeList = scope;
    }

    public void finish(Database.BatchableContext BC){
       try{
            Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
            String integName = !org.IsSandbox ? 'AD_User_Field_Update_URL_PRD' : 'AD_User_Field_Update_URL_Staging';
            Admin_Dashboard_Integration_Setting__mdt ADuserUpdateSetting = REST_AdminDashboardSyncSetup.getADSettings(integName);
            if(!scopeList.isEmpty() && !ADuserUpdateSetting.Deactivate__c){
                sObject selectedObj = scopeList.get(0);
                System.enqueueJob(new UpdateADUserQueue(selectedObj, objName));
            }

        }catch(Exception e){
            ExceptionUtility.createExceptionLog('UpdateADUserBatch','Account/Lead', 'RESTAPI', 'BatchJob',  e);
        }
    }
}