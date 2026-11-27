public without sharing class AccountImportantFieldsTableController {
    @AuraEnabled
    public static String getAccountData(Id accountId){
        try {
            String defaultLineBreak = System.Label.ACC_SUB_STATUS_LINEBREAK;
            List<String> weeklyUpdateStatusPicklist = new List<String>();
            Schema.DescribeFieldResult fieldResult = Account.Account_Weekly_Update_Status__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.isActive()){
                    weeklyUpdateStatusPicklist.add(pickListVal.getValue());
                } 
            }     
            String strReturnVal = null;
            List<Account> getAccountObj = [SElECT Id, Type, Brand__c, Segment__c, Status__c, Account_Sub_Status__c, Ultimate_Parent_Account_Division__c, is_top5_L30D_growth_ultiparent_of_owner__c, is_btm5_L30D_growth_ultiparent_of_owner__c, 
                                           MTD_Rev_USD__c, MTD_Rev_delta_USD__c, L30D_Rev_USD__c, L30D_Rev_delta_USD__c, L7D_Rev_USD__c, L7D_Rev_delta_USD__c, Weekly_Update__c, Weekly_Update_History__c, Account_Weekly_Update_Status__c  
                                           FROM Account WHERE Id =: accountId LIMIT 1 ];
            if(!getAccountObj.isEmpty()){
                AccountTableWrapper returnVal = new AccountTableWrapper();
                returnVal.accObj = getAccountObj[0];
                returnVal.suml7DDeltaUSD = getAccountObj[0].L7D_Rev_delta_USD__c != null ? getAccountObj[0].L7D_Rev_delta_USD__c : 0;
                returnVal.sumL7DRevUSD = getAccountObj[0].L7D_Rev_USD__c != null ? getAccountObj[0].L7D_Rev_USD__c : 0;
                returnVal.suml30DDeltaUSD = getAccountObj[0].L30D_Rev_delta_USD__c != null ? getAccountObj[0].L30D_Rev_delta_USD__c : 0;
                returnVal.sumL30DRevUSD = getAccountObj[0].L30D_Rev_USD__c != null ? getAccountObj[0].L30D_Rev_USD__c : 0;
                returnVal.sumMTDDDeltaUSD = getAccountObj[0].MTD_Rev_delta_USD__c != null ? getAccountObj[0].MTD_Rev_delta_USD__c : 0;
                returnVal.sumMTDRevUSD = getAccountObj[0].MTD_Rev_USD__c != null ? getAccountObj[0].MTD_Rev_USD__c : 0;
                returnVal.accSubStatus = getAccountObj[0].Account_Sub_Status__c;
                if(!String.isBlank(returnVal.accSubStatus)){
                    String subStatus = getAccountObj[0].Account_Sub_Status__c;
                    
                    String updateSubStatus = subStatus.replaceAll(defaultLineBreak, '<br/>');
                    system.debug('updateSubStatus : ' + updateSubStatus);
                    returnVal.accSubStatus = updateSubStatus;
                }

                returnVal.ultiParentDivision = getAccountObj[0].Ultimate_Parent_Account_Division__c;
                if(!String.isBlank(returnVal.ultiParentDivision)){
                    String ultiParentDiv = getAccountObj[0].Ultimate_Parent_Account_Division__c;
                    String updateUltiParentDiv = ultiParentDiv.replaceAll(defaultLineBreak, '<br/>');
                    returnVal.ultiParentDivision = updateUltiParentDiv;
                }

                //get accounts under it
                for(Account childAcc : [SELECT Id, MTD_Rev_USD__c, MTD_Rev_delta_USD__c, L30D_Rev_USD__c, L30D_Rev_delta_USD__c, L7D_Rev_USD__c, L7D_Rev_delta_USD__c
                FROM Account WHERE ParentId =: accountId OR Parent.ParentId =: accountId OR Parent.Parent.ParentId =: accountId OR Parent.Parent.Parent.ParentId =: accountId OR Parent.Parent.Parent.Parent.ParentId =: accountId]){
                    returnVal.suml7DDeltaUSD += (childAcc.L7D_Rev_delta_USD__c != null ? childAcc.L7D_Rev_delta_USD__c: 0);
                    returnVal.sumL7DRevUSD += (childAcc.L7D_Rev_USD__c != null ? childAcc.L7D_Rev_USD__c  : 0);
                    returnVal.suml30DDeltaUSD += (childAcc.L30D_Rev_delta_USD__c != null ? childAcc.L30D_Rev_delta_USD__c : 0);
                    returnVal.sumL30DRevUSD += (childAcc.L30D_Rev_USD__c != null ? childAcc.L30D_Rev_USD__c : 0);
                    returnVal.sumMTDDDeltaUSD += (childAcc.MTD_Rev_delta_USD__c != null ? childAcc.MTD_Rev_delta_USD__c  : 0);
                    returnVal.sumMTDRevUSD += (childAcc.MTD_Rev_USD__c != null ? childAcc.MTD_Rev_USD__c : 0);
                }
                returnVal.weeklyUpdateStatusPicklist = weeklyUpdateStatusPicklist;
                strReturnVal = JSON.serialize(returnVal);
            }
            return strReturnVal;
        }catch (Exception e) {
            system.debug('error on getAccountData : '+e.getmessage());
            return null;
        }
    }

    @AuraEnabled
    public static String saveAccData(String accData){
        try{
            String val = 'pass';
            Account updateAcc = new Account();
            if(String.isNotBlank(accData)){
                AccountTableWrapper parsedWrap = (AccountTableWrapper) JSON.deserialize(accData, AccountTableWrapper.class);
                if(parsedWrap.accObj != null && parsedWrap.accObj.Id != null){
                    updateAcc = new Account(Id = parsedWrap.accObj.Id, Account_Weekly_Update_Status__c = parsedWrap.accObj.Account_Weekly_Update_Status__c, Weekly_Update__c = parsedWrap.accObj.Weekly_Update__c);
                    update updateAcc;
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

    public class AccountTableWrapper{
        @AuraEnabled public Account accObj {get;set;}
        @AuraEnabled public Decimal suml7DDeltaUSD {get;set;}
        @AuraEnabled public Decimal sumL7DRevUSD {get;set;}
        @AuraEnabled public Decimal suml30DDeltaUSD {get;set;}
        @AuraEnabled public Decimal sumL30DRevUSD {get;set;}
        @AuraEnabled public Decimal sumMTDDDeltaUSD {get;set;}
        @AuraEnabled public Decimal sumMTDRevUSD {get;set;}
        @AuraEnabled public List<String> weeklyUpdateStatusPicklist {get;set;}
        @AuraEnabled public String accSubStatus {get;set;}
        @AuraEnabled public String ultiParentDivision {get;set;}
        public AccountTableWrapper(){
            accObj = new Account();
            suml7DDeltaUSD = 0;
            sumL7DRevUSD = 0;
            suml30DDeltaUSD = 0;
            sumL30DRevUSD = 0;
            sumMTDDDeltaUSD = 0;
            sumMTDRevUSD = 0;
            weeklyUpdateStatusPicklist = new List<String>();
            accSubStatus = '';
            ultiParentDivision = '';
        }
    }
}