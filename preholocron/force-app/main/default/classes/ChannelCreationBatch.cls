/*
Class Name : ChannelCreationBatch
Test Class : ChannelCreationBatchTest
Description : Daily batch for auto creation Channel, which Transaction's products are not yet listed in the channel
*/

public without sharing class ChannelCreationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public Set<Id> accSet = new Set<Id>();
    public Integer batchSize = 50;
    public ChannelCreationBatch(Integer batchInt, Set<Id> accountIdSet) {
        batchSize = batchInt != null ? batchInt : 50;
        accSet = accountIdSet;
    }

    //start
    public Database.QueryLocator start (Database.BatchableContext BC){
        String qryStr = 'SELECT Id, Account__c, Product_Lookup__c FROM Transaction__c WHERE (Product_Lookup__c != NULL AND LastModifiedDate = YESTERDAY) ';

        if(accSet != null){
            qryStr += ' OR (Product_Lookup__c != NULL AND Account__c IN :accSet) ';
        }
        system.debug('qryStr : ' + qryStr);

        return Database.getQueryLocator(qryStr);
    }

    //execute
    public void execute(Database.BatchableContext BC, List<sObject> scope){

        try{
            List<Transaction__c> transactionList = scope;
            Set<String> txnPrdAllIdSet = new Set<String>();
            Set<String> accPrdSet = new Set<String>(); //account:::product to mass create channels
            Map<String, Channel_KYC__c> keyChannelMap = new Map<String, Channel_KYC__c>(); //key : accId:::ProductID
            Set<String> accIdSet = new Set<String>();
            for(Transaction__c txn : transactionList){
                accIdSet.add(txn.Account__c);
            }

            if(!accIdSet.isEmpty()){
                Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id, Product_Lookup__c FROM Transactions__r WHERE Product_Lookup__c != NULL),
                                            (SELECT Id, Product__c FROM Channel_KYC__r WHERE Product__c != NULL)
                                            FROM Account WHERE Id IN :accIdSet]);

                for(Id accId : accMap.keySet()){
                    Account acc = accMap.get(accId);
                    List<Channel_KYC__c> cKYCList = acc.Channel_KYC__r;
                    List<Transaction__c> txnList = acc.Transactions__r;
                    Set<String> cKYCPrdIdSet = new Set<String>();
                    Set<String> txnPrdIdSet = new Set<String>();

                    //get Channels and store the existing products
                    if(cKYCList != null && !cKYCList.isEmpty()){
                        for(Channel_KYC__c cKYC : cKYCList){
                            cKYCPrdIdSet.add(cKYC.Product__c);
                        }
                    }   

                    //get Transactions and store the existing products
                    if(txnList != null && !txnList.isEmpty()){
                        for(Transaction__c txn : txnList){
                            txnPrdIdSet.add(txn.Product_Lookup__c);
                        }
                    } 

                    if(!txnPrdIdSet.isEmpty() && !cKYCPrdIdSet.isEmpty()) txnPrdIdSet.removeAll(cKYCPrdIdSet);
                    txnPrdAllIdSet.addAll(txnPrdIdSet);

                    for(String prdId : txnPrdIdSet){
                        accPrdSet.add(acc.Id + ':::' + prdId);
                    }
                }

                if(!accPrdSet.isEmpty() && !txnPrdAllIdSet.isEmpty() ){
                
                    //get product from query
                    Map<Id, Product2> prdMap = new Map<Id, Product2>([SELECT Id, CurrencyIsoCode, (SELECT Id, Channel__c FROM Xendit_Product_Price__r WHERE Channel__c != NULL) FROM Product2 WHERE Id  IN :txnPrdAllIdSet]);
                    
                    for(String accPrd : accPrdSet){
                        String accId = accPrd.split(':::')[0];
                        String prdId = accPrd.split(':::')[1];
                        String rChannel = '';
                        Product2 prod = prdMap.get(prdId);
                        List<Rate_Card__c> rcList = prod.Xendit_Product_Price__r;
                        if(rcList != null && !rcList.isEmpty()){
                            rChannel = rcList[0].Channel__c;
                        }
                        Channel_KYC__c newChannel = new Channel_KYC__c(Account__c = accId, Channel__c = rChannel, CurrencyIsoCode = prod.CurrencyIsoCode, Product__c = prod.Id, Status__c = 'LIVE');
                        keyChannelMap.put(accPrd, newChannel);
                    }
    
                    if(!keyChannelMap.isEmpty()) insert keyChannelMap.values();
                }
            }
            
        }catch(exception e){
            system.debug('error on executing batch ChannelCreationBatch : ' + e.getMessage());
            ExceptionUtility.createExceptionLog('ChannelCreationBatch','Channel_KYC__c', 'insert Channel_KYC__c', 'ChannelCreationBatch',  e);
        }

    }

    public void finish( Database.BatchableContext BC ) {

    }

    public void execute( Schedulablecontext sc ){
        ChannelCreationBatch cx = new ChannelCreationBatch( batchSize, accSet );
        Database.executeBatch( cx , batchSize ); 
    }
}