public without sharing class ParentOppImportantFieldsTableController {
    
    @AuraEnabled
    public static String getOppData(Id OppId){
        try {
            List<String> weeklyUpdateStatusPicklist = new List<String>();
            Schema.DescribeFieldResult fieldResult = Opportunity.Weekly_Update_Status__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.isActive()){
                    weeklyUpdateStatusPicklist.add(pickListVal.getValue());
                } 
            }     
            String strReturnVal = null;
            List<Opportunity> getOpp = [SElECT Id, Name, AccountId, Account.Brand__c, Addressable_Merchant_TPV_Monthly__c, Addressable_Merchant_Revenue_Monthly__c, Gross_Take_Rate__c, Addressable_Monthly_Profitability__c, Segment__c, Owner.Name,  
            Xst_Txn_Act_Date__c, Account.Status__c, StageName, Why_Us__c, Weekly_Update_Status__c, Weekly_Update__c, Weekly_Update_History__c, Next_Step_Blockers__c, CurrencyIsoCode, Manager_thoughts__c,Total_Gross_Profit_Margin__c
            FROM Opportunity WHERE Id = :OppId];
            if(!getOpp.isEmpty()){
                FieldsTableWrapper returnVal = new FieldsTableWrapper();
                Opportunity oppObj = getOpp[0];
                Set<String> activeProductNameSet = new Set<String>();
                Set<String> productIdSet = new Set<String>();
                List<OppProductWrapper> oppProductWrapperList = new List<OppProductWrapper>();
                Map<Id, String> childOppMap = new Map<Id, String>();
                Map<String, Set<String>> childOppProductNameMap = new Map<String, Set<String>>();
                returnVal.oppId = oppObj.Id;
                returnVal.brandName = oppObj.Account.Brand__c;
                returnVal.tpvMonthly = oppObj.Addressable_Merchant_TPV_Monthly__c;
                returnVal.revMonthly = oppObj.Addressable_Merchant_Revenue_Monthly__c;
                returnVal.totalGrossProfit = oppObj.Total_Gross_Profit_Margin__c;
                returnVal.grossTakeRate = oppObj.Gross_Take_Rate__c != null ? oppObj.Gross_Take_Rate__c / 100 : oppObj.Gross_Take_Rate__c;
                returnVal.grossProfit = oppObj.Addressable_Monthly_Profitability__c != null ? oppObj.Addressable_Monthly_Profitability__c / 100 : oppObj.Addressable_Monthly_Profitability__c;
                returnVal.segment = oppObj.Segment__c;
                returnVal.ownerName = oppObj.Owner.Name;
                returnVal.estTxnDate = oppObj.Xst_Txn_Act_Date__c;
                returnVal.accStatus = oppObj.Account.Status__c;
                returnVal.stageName = oppObj.StageName;
                returnVal.whyUs = oppObj.Why_Us__c;
                returnVal.weeklyUpdateStatus = oppObj.Weekly_Update_Status__c;
                returnVal.weeklyUpdate = oppObj.Weekly_Update__c;
                returnVal.weeklyUpdateWithHistory = oppObj.Weekly_Update_History__c;
                returnVal.nextStepBlocker = oppObj.Next_Step_Blockers__c;
                returnVal.managerThoughts = oppObj.Manager_thoughts__c;
                returnVal.oppCurrency = oppObj.CurrencyIsoCode;
                returnVal.oppLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + OppId;
                returnVal.weeklyUpdateStatusPicklist = weeklyUpdateStatusPicklist;
                returnVal.oppName = oppObj.Name;

                for(Xendit_Opportunity_Product__c xOpp :[SELECT Id, Opportunity__c, Product__r.Family, Product__c, Product__r.Name FROM Xendit_Opportunity_Product__c WHERE Grand_Parent_Opportunity_ID__c =:OppId AND Product__c != null ORDER BY Product__r.Family, Product__r.Name ASC]){
                    productIdSet.add(xOpp.Product__c);
                    Set<String> currProdNameSet = new Set<String>();
                    if(childOppProductNameMap.containsKey(xOpp.Product__r.Family)){
                        currProdNameSet = childOppProductNameMap.get(xOpp.Product__r.Family);
                    } 
                    currProdNameSet.add(xOpp.Product__r.Name);
                    childOppProductNameMap.put(xOpp.Product__r.Family, currProdNameSet);
                }

                if(!childOppProductNameMap.isEmpty()){
                    for(String fam : childOppProductNameMap.keySet()){
                        OppProductWrapper tempWrap = new OppProductWrapper();
                        //tempWrap.childOppId = URL.getSalesforceBaseUrl().toExternalForm() + '/' + childOppId;
                        tempWrap.productFamily = fam;
                        tempWrap.productNames = childOppProductNameMap.get(fam);
                        oppProductWrapperList.add(tempWrap);
                    }
                    returnVal.oppProductList = oppProductWrapperList;
                }

                if(!productIdSet.isEmpty()){
                    for (Channel_KYC__c CK:[SELECT Id, Product__r.Name FROM Channel_KYC__c 
                                    WHERE Account__c = :oppObj.AccountId AND Status__c = 'LIVE' AND Product__c IN :productIdSet])
                    {
                        activeProductNameSet.add(CK.Product__r.Name);
                    }
                    if(!activeProductNameSet.isEmpty()){
                        returnVal.activeProductsName = String.join(new List<String>(activeProductNameSet),', ');
                    }
                }

                strReturnVal = JSON.serialize(returnVal);
            }

            return strReturnVal;
        } catch (Exception e) {
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }

    @AuraEnabled
    public static String saveOppData(String oppData){
        try{
            String val = 'pass';
            Opportunity updateOpp = new Opportunity();
            if(String.isNotBlank(oppData)){
                FieldsTableWrapper parsedWrap = (FieldsTableWrapper) JSON.deserialize(oppData, FieldsTableWrapper.class);
                if(parsedWrap.oppId != null){
                    updateOpp = new Opportunity(Id = parsedWrap.oppId, Why_Us__c = parsedWrap.whyUs, Weekly_Update_Status__c = parsedWrap.weeklyUpdateStatus, Weekly_Update__c = parsedWrap.weeklyUpdate, Next_Step_Blockers__c = parsedWrap.nextStepBlocker, Manager_thoughts__c = parsedWrap.managerThoughts);
                    update updateOpp;
                }   
            }else{
                val = 'empty';
            }
            return val;
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = 'Error upon saving the record : ' + String.join(new List<String>(errmsgList), '\n');
            return errMsg;
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }

    public class FieldsTableWrapper
    {
        @AuraEnabled public Id oppId {get;set;}
        @AuraEnabled public String brandName {get;set;}
        @AuraEnabled public Double tpvMonthly {get;set;}
        @AuraEnabled public Double revMonthly {get;set;}
        @AuraEnabled public Double totalGrossProfit {get;set;}
        @AuraEnabled public Double grossTakeRate {get;set;}
        @AuraEnabled public Double grossProfit {get;set;}
        @AuraEnabled public String segment {get;set;}
        @AuraEnabled public String ownerName {get;set;}
        @AuraEnabled public Date estTxnDate {get;set;}
        @AuraEnabled public String accStatus {get;set;}
        @AuraEnabled public String stageName {get;set;}
        @AuraEnabled public String whyUs {get;set;}
        @AuraEnabled public String weeklyUpdateStatus {get;set;}
        @AuraEnabled public String weeklyUpdate {get;set;}
        @AuraEnabled public String weeklyUpdateWithHistory {get;set;}
        @AuraEnabled public String nextStepBlocker {get;set;}
        @AuraEnabled public String managerThoughts {get;set;} 
        @AuraEnabled public String activeProductsName {get;set;}
        @AuraEnabled public String oppLink {get;set;}
        @AuraEnabled public String oppCurrency {get;set;}
        @AuraEnabled public List<String> weeklyUpdateStatusPicklist {get;set;}
        @AuraEnabled public List<OppProductWrapper> oppProductList {get;set;}
        @AuraEnabled public String oppName {get;set;}
        public FieldsTableWrapper() {
            oppId = null;
            brandName = '';
            tpvMonthly = null;
            revMonthly = null;
            totalGrossProfit = null;
            grossTakeRate = null;
            grossProfit = null;
            segment = '';
            ownerName = '';
            estTxnDate = null;
            accStatus = '';
            stageName = '';
            whyUs = '';
            weeklyUpdateStatus = '';
            weeklyUpdate = '';
            weeklyUpdateWithHistory = '';
            nextStepBlocker = '';
            managerThoughts = '';
            activeProductsName = '';
            oppLink = '';
            oppCurrency = '';
            weeklyUpdateStatusPicklist = new List<String>();
            oppProductList = new List<OppProductWrapper>();
            oppName = '';
        }
    }

    public class OppProductWrapper
    {
        @AuraEnabled public string productFamily{get;set;}
        @AuraEnabled public string childOppId{get;set;}
        @AuraEnabled public Set<String> productNames{get;set;}
        public OppProductWrapper(){
            productFamily = '';
            childOppId = '';
            productNames = new Set<String>();
        }
    }
}