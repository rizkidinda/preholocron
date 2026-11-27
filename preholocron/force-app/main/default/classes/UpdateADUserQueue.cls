public class UpdateADUserQueue implements Queueable, Database.AllowsCallouts{
    public sObject rec;
    public String objName = '';
    public UpdateADUserQueue(sObject record, String objectName) {
        rec = record;
        objName = objectName;
    }

    public void execute(QueueableContext qc){
        try{
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email, Profile.Name, AD_User_Category__c, FederationIdentifier, Division FROM User]);
            Opportunity_Exception_User__mdt defaultSalesOpsUser = [SELECT Id, User_Email__c FROM Opportunity_Exception_User__mdt WHERE DeveloperName = 'Default_Sales_Ops_User' LIMIT 1];
            Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
            String integName = !org.IsSandbox ? 'AD_User_Field_Update_URL_PRD' : 'AD_User_Field_Update_URL_Staging';
            Admin_Dashboard_Integration_Setting__mdt ADuserUpdateSetting = REST_AdminDashboardSyncSetup.getADSettings(integName);

            switch on objName{
                when 'Account'{
                    Account acc = (Account)rec;
                    if(!ADuserUpdateSetting.Deactivate__c){
                        //construct JSON format
                        Id accCPManager = (userMap.containsKey(acc.CP_Manager__c) && userMap.get(acc.CP_Manager__c).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ? acc.CP_Manager__c : null;
                        Id accOwnerId = (userMap.containsKey(acc.OwnerId) && userMap.get(acc.OwnerId).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ? acc.OwnerId : null;
                        String strJSONBody = REST_AdminDashboardSyncSetup.getJSONBody(userMap, accCPManager, accOwnerId, acc.Team_Assignment__c);
                        system.debug('strJSONBody : ' + strJSONBody);
                        REST_AdminDashboardSyncSetup.updateUserFields(acc.Business_ID__c, strJSONBody, ADuserUpdateSetting.Base_URL__c, ADuserUpdateSetting.API_Key__c);
                    }
                }

                when 'Lead'{
                    Lead l = (Lead)rec;
                    if(!ADuserUpdateSetting.Deactivate__c){
                        //construct JSON format
                        Id lCPManager = (userMap.containsKey(l.CP_Manager__c) && userMap.get(l.CP_Manager__c).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ? l.CP_Manager__c : null;
                        Id lOwnerId = (userMap.containsKey(l.OwnerId) && userMap.get(l.OwnerId).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ? l.OwnerId : null;
                        String teamAssignment = ''; //Team_Assignment__c is on Account
                        String strJSONBody = REST_AdminDashboardSyncSetup.getJSONBody(userMap, lCPManager, lOwnerId, teamAssignment);
                        REST_AdminDashboardSyncSetup.updateUserFields(l.Business_ID__c, strJSONBody, ADuserUpdateSetting.Base_URL__c, ADuserUpdateSetting.API_Key__c);
                    }
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('UpdateADUserQueue','UpdateADUserQueue', 'UpdateADUserQueue', 'Queue',  e);
        }
    }
}