public without sharing class UltimateParentUpdateBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
    public String query;
    public Boolean reRun = false;
    public Set<String> accSet = new Set<String>();

    public UltimateParentUpdateBatch(Set<String> accountIdSet) {
        accSet = accountIdSet;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String ultAccSetQry = accSet != null && !accSet.isEmpty() ? ' AND Ultimate_Parent_Formula__c IN :accSet ' : '';
		query = 'SELECT Id, Is_Updated_Ultimate_Parent__c, Ultimate_Parent__c, Ultimate_Parent_Formula__c FROM Account WHERE Is_Ultimate_Parent__c = FALSE AND Is_Updated_Ultimate_Parent__c = FALSE ';
        query += ultAccSetQry;
        query += ' LIMIT 10000';
        system.debug(':::query:::' + query);
        system.debug(':::accSet:::' + JSON.serialize(accSet));
		return Database.getQueryLocator(query);
	}

    public void execute(Database.BatchableContext BC, List<Account> scope){
        try{
            List<Account> accUpdateList = new List<Account>();
            if(!scope.isEmpty()){
                List<Account> xList = scope;
                for(Account x : xList){
                    x.Ultimate_Parent__c = x.Ultimate_Parent_Formula__c;
                    accUpdateList.add(x);
                }
                TriggerBypassUtility.accountTriggerBypass = true;
                TriggerBypassUtility.opportunityTriggerBypass = true;
                update accUpdateList;
                TriggerBypassUtility.accountTriggerBypass = false;
                TriggerBypassUtility.opportunityTriggerBypass = false;
                reRun = true;
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('UltimateParentUpdateBatch','Account', 'update', 'Batch ScheduledJob',  e);
        }
        
    }

    public void finish(Database.BatchableContext BC){
		System.debug('reRun : ' + reRun);
		if(reRun)
		  Database.executeBatch(new UltimateParentUpdateBatch(accSet),100);
	}

    public void execute( Schedulablecontext sc ){
        UltimateParentUpdateBatch cx = new UltimateParentUpdateBatch(null);
        Database.executeBatch( cx , 100 ); 
    }
}