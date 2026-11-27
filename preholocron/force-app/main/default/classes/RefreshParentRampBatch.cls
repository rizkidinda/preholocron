public class RefreshParentRampBatch implements Database.Batchable<sObject>, Database.Stateful{
	public String query;
    public Database.QueryLocator start(Database.BatchableContext BC){
        Id idRTParent = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        query = ' SELECT Id FROM Opportunity WHERE RecordTypeId =: idRTParent AND Refresh_Parent_Ramp__c = true AND Xst_Txn_Act_Date__c != NULL'; 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        try{
            if(!scope.isEmpty()){
                List<Opportunity> oppList = new List<Opportunity>(scope);
                for(Opportunity opp : oppList){
                    List<Opportunity_Ramp__c> rampList = [SELECT Id FROM Opportunity_Ramp__c WHERE Opportunity__c =: opp.Id];
              		Integer rampCount = rampList != null ? rampList.size() : 0;
                    Xendit_RampController.displayData setupData = Xendit_RampController.setupData(opp.Id);
                    
                    Xendit_RampController.displayData refreshedData = new Xendit_RampController.displayData();
                    if(rampCount > 0){
                        refreshedData = Xendit_RampController.refreshOppList(setupData);
                    }else{
                        refreshedData = Xendit_RampController.refreshDefaultRampOppList(setupData);
                    }
                    Xendit_RampController.displayData updateData = Xendit_RampController.updateData(refreshedData);
                    
                }
            } 
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('RefreshParentRampBatch','Opportunity', 'update', 'Batch',  e);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}