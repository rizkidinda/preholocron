public without sharing class ChannelProductUpdateBatch implements Database.Batchable<sObject>{

    //for QueryLocator
    public Set<Id> productIdSet = new Set<Id>();

    public ChannelProductUpdateBatch(Set<Id> prdSet) {
        productIdSet = prdSet;
    }

    //Query Locator (start)
    public Database.QueryLocator start( Database.BatchableContext BC ){
        String qry = 'SELECT Id, Product_Family__c, Product__r.Family FROM Channel_KYC__c WHERE Is_ProdFam_Same__c = FALSE AND Product__c != NULL ';
        if(!productIdSet.isEmpty()){
            qry += ' AND Product__c IN :productIdSet ';
        }
        return Database.getQueryLocator( qry );
    }  

    //EXECUTE - BATCH
    public void execute( Database.BatchableContext BC, List<Channel_KYC__c> scope ){
        try{
            if(!scope.isEmpty()){
                List<Channel_KYC__c> updateChannelList = new List<Channel_KYC__c>();
                for(Channel_KYC__c channel : scope){
                    Channel_KYC__c temp = new Channel_KYC__c(Id = channel.Id, Product_Family__c = channel.Product__r.Family);
                    updateChannelList.add(temp);
                }
                update updateChannelList;
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('ChannelProductUpdateBatch','ChannelKYC', 'update', 'Batch ScheduledJob',  e);
        }
    }

    //Finish
    public void finish( Database.BatchableContext BC ) {

    }
}