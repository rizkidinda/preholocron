public class ParentAccountRevenueUpdateBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
    public String query;
    public Set<String> accSet = new Set<String>();
    public List<Account> updateAccountList = new List<Account>();
    public Set<String> parentSet = new Set<String>();
    public Boolean reRun = false;
    

    public ParentAccountRevenueUpdateBatch(Set<String> accountIdSet) {
        accSet = accountIdSet;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        Id idRTParent = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        String accSetQry = accSet != null && !accSet.isEmpty() ? ' WHERE Id IN :accSet ' : ' WHERE Count_Opportunity__c > 0 ';
        query = ' SELECT Id, CurrencyIsoCode, ParentId, ';
        query += ' (SELECT Id, Addressable_iY_Revenue__c, Addressable_iY_TPV__c, Addressable_Merchant_Revenue_Monthly__c, Addressable_Merchant_TPV_Monthly__c, ';
        query += ' Addressable_wiY_Revenue__c, Addressable_wiY_TPV__c, CurrencyIsoCode FROM Opportunities WHERE RecordTypeId =: idRTParent AND StageName != \'Closed Lost\' '; 
        query += ' AND (StageName != \'Closed Won\' OR (StageName = \'Closed Won\' AND Xst_Txn_Act_Date__c = LAST_N_MONTHS:6))), ';
        query += ' (SELECT Id, CurrencyIsoCode, Addressable_iY_Revenue__c, Addressable_iY_TPV__c, Addressable_Merchant_Revenue_Monthly__c, ';
        query += ' Addressable_Merchant_TPV_Monthly__c, Addressable_wiY_Revenue__c, Addressable_wiY_TPV__c FROM ChildAccounts) FROM Account ';
        query += accSetQry;

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope){
        try{
            if(!scope.isEmpty()){
                List<Account> updateAccountList = updateAccountRevenueCalculation(scope);
                if(updateAccountList != null && !updateAccountList.isEmpty()){
                    TriggerBypassUtility.accountTriggerBypass = true;
                    TriggerBypassUtility.opportunityTriggerBypass = true;
                    update updateAccountList;
                    parentSet = new Set<String>();
                    for(Account acc : updateAccountList){
                        if(acc.ParentId != null) parentSet.add(acc.ParentId);
                    }
    
                    while(parentSet != null && !parentSet.isEmpty()){
                        List<Account> updateParentAccList = updateParentAccountCalculation(parentSet);
                        update updateParentAccList;
                        Set<String> tempParentId = new Set<String>();
                        for(Account acc : updateParentAccList){
                            if(acc.ParentId != null) tempParentId.add(acc.ParentId);
                        }
    
                        parentSet = tempParentId;
                    }
                    TriggerBypassUtility.accountTriggerBypass = false;
                    TriggerBypassUtility.opportunityTriggerBypass = false;
                    //if(!parentSet.isEmpty()){
                        //reRun = true;
                        //accSet = parentSet;
                    //}
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('ParentAccountRevenueUpdateBatch','Account', 'upsert', 'Batch ScheduledJob',  e);
        }
        
    }

    public void finish(Database.BatchableContext BC){
		System.debug('reRun : ' + reRun);
		// if(reRun){
        //     TriggerBypassUtility.accountTriggerBypass = true;
        //     Database.executeBatch(new ParentAccountRevenueUpdateBatch(accSet),1);
        // }
	}

    public List<Account> updateAccountRevenueCalculation(List<Account> accList){
        List<Account> updateAccountList = new List<Account>();
            Id idRTParent = OpportunityHelper.getParentRecordTypeId();
            Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();
            for(Account acc : accList){
                if((acc.Opportunities != null && !acc.Opportunities.isEmpty()) || (acc.ChildAccounts != null && !acc.ChildAccounts.isEmpty())){
                    Decimal addressableiYRevenue = 0;
                    Decimal addressableiYTPV = 0;
                    Decimal addressableMonthlyRevenue = 0;
                    Decimal addressableMonthlyTPV = 0;
                    Decimal addressablewiYRevenue = 0;
                    Decimal addressablewiYTPV = 0;
                    for(Opportunity opp : acc.Opportunities){
                        addressableiYRevenue = opp.Addressable_iY_Revenue__c != null ? addressableiYRevenue + Utility.valueConversion(conversionRateMap, opp.Addressable_iY_Revenue__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableiYRevenue;
                        addressableiYTPV = opp.Addressable_iY_TPV__c != null ? addressableiYTPV + Utility.valueConversion(conversionRateMap, opp.Addressable_iY_TPV__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableiYTPV;
                        addressableMonthlyRevenue = opp.Addressable_Merchant_Revenue_Monthly__c != null ? addressableMonthlyRevenue + Utility.valueConversion(conversionRateMap, opp.Addressable_Merchant_Revenue_Monthly__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableMonthlyRevenue;
                        addressableMonthlyTPV = opp.Addressable_Merchant_TPV_Monthly__c != null ? addressableMonthlyTPV + Utility.valueConversion(conversionRateMap, opp.Addressable_Merchant_TPV_Monthly__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableMonthlyTPV;
                        addressablewiYRevenue = opp.Addressable_wiY_Revenue__c != null ? addressablewiYRevenue + Utility.valueConversion(conversionRateMap, opp.Addressable_wiY_Revenue__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressablewiYRevenue;
                        addressablewiYTPV = opp.Addressable_wiY_TPV__c != null ? addressablewiYTPV + Utility.valueConversion(conversionRateMap, opp.Addressable_wiY_TPV__c, opp.CurrencyIsoCode, acc.CurrencyIsoCode) : addressablewiYTPV;
                    }

                    for(Account child : acc.ChildAccounts){
                        addressableiYRevenue = child.Addressable_iY_Revenue__c != null ? addressableiYRevenue + Utility.valueConversion(conversionRateMap, child.Addressable_iY_Revenue__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableiYRevenue;
                        addressableiYTPV = child.Addressable_iY_TPV__c != null ? addressableiYTPV + Utility.valueConversion(conversionRateMap, child.Addressable_iY_TPV__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableiYTPV;
                        addressableMonthlyRevenue = child.Addressable_Merchant_Revenue_Monthly__c != null ? addressableMonthlyRevenue + Utility.valueConversion(conversionRateMap, child.Addressable_Merchant_Revenue_Monthly__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableMonthlyRevenue;
                        addressableMonthlyTPV = child.Addressable_Merchant_TPV_Monthly__c != null ? addressableMonthlyTPV + Utility.valueConversion(conversionRateMap, child.Addressable_Merchant_TPV_Monthly__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressableMonthlyTPV;
                        addressablewiYRevenue = child.Addressable_wiY_Revenue__c != null ? addressablewiYRevenue + Utility.valueConversion(conversionRateMap, child.Addressable_wiY_Revenue__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressablewiYRevenue;
                        addressablewiYTPV = child.Addressable_wiY_TPV__c != null ? addressablewiYTPV + Utility.valueConversion(conversionRateMap, child.Addressable_wiY_TPV__c, child.CurrencyIsoCode, acc.CurrencyIsoCode) : addressablewiYTPV;
                    }

                    updateAccountList.add(new Account(Id = acc.Id, Addressable_iY_Revenue__c = addressableiYRevenue, Addressable_iY_TPV__c = addressableiYTPV, 
                                                    Addressable_Merchant_Revenue_Monthly__c = addressableMonthlyRevenue, Addressable_Merchant_TPV_Monthly__c = addressableMonthlyTPV, 
                                                    Addressable_wiY_Revenue__c = addressablewiYRevenue, Addressable_wiY_TPV__c = addressablewiYTPV, ParentId = acc.ParentId));
                }
            }
        return updateAccountList;
    }

    public List<Account> updateParentAccountCalculation(Set<String> parentId){
        Id idRTParent = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        String pQuery = ' SELECT Id, CurrencyIsoCode, ParentId, ';
        pQuery += ' (SELECT Id, Addressable_iY_Revenue__c, Addressable_iY_TPV__c, Addressable_Merchant_Revenue_Monthly__c, Addressable_Merchant_TPV_Monthly__c, ';
        pQuery += ' Addressable_wiY_Revenue__c, Addressable_wiY_TPV__c, CurrencyIsoCode FROM Opportunities WHERE RecordTypeId =: idRTParent AND StageName != \'Closed Lost\' '; 
        pQuery += ' AND (StageName != \'Closed Won\' OR (StageName = \'Closed Won\' AND Xst_Txn_Act_Date__c = LAST_N_MONTHS:6))), ';
        pQuery += ' (SELECT Id, CurrencyIsoCode, Addressable_iY_Revenue__c, Addressable_iY_TPV__c, Addressable_Merchant_Revenue_Monthly__c, ';
        pQuery += ' Addressable_Merchant_TPV_Monthly__c, Addressable_wiY_Revenue__c, Addressable_wiY_TPV__c FROM ChildAccounts) FROM Account ';
        pQuery +=  ' WHERE Id IN :parentId';

        List<Account> getParentAccountList = Database.query(pQuery);
        List<Account> updateAccountList = updateAccountRevenueCalculation(getParentAccountList);
        return updateAccountList;
    }

    public void execute( Schedulablecontext sc ){
        ParentAccountRevenueUpdateBatch cx = new ParentAccountRevenueUpdateBatch(null);
        Database.executeBatch( cx , 1 ); 
    }
    
}