public without sharing class DeleteErrorLogBatchScheduler implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
    Boolean isTest = false;

    public DeleteErrorLogBatchScheduler(Boolean testVal) {
        isTest = testVal;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String val = isTest ? '' : ' WHERE CreatedDate != THIS_WEEK ';
		String query = 'SELECT Id FROM Exception_Logger__c ' + val ;
		return Database.getQueryLocator(query);
	}

    public void execute(Database.BatchableContext BC, List<Exception_Logger__c> scope){
        try{
            List<Exception_Logger__c> deleteLogList = scope;
            if(!scope.isEmpty()){
                delete deleteLogList;
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('DeleteErrorLogBatchScheduler','Exception_Logger__c', 'delete', 'Batch ScheduledJob',  e);
        }
        
    }

    public void finish(Database.BatchableContext BC){
		
	}

    public void execute( Schedulablecontext sc ){
        DeleteErrorLogBatchScheduler cx = new DeleteErrorLogBatchScheduler(false);
        Database.executeBatch( cx , 200 ); 
    }
}