/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 21-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public class AccountHelper {
    public static Set<Id> deleteOppty = new Set<Id>();

    public static void setDefaultValuePreProcess(List<Account> listNew, Map<Id, Account> listOldMap) {
        for (Account acc : listNew) {
            if (acc.GLR_Flag__c && (acc.Customer_Folder_URL__c == null || acc.Customer_Folder_URL__c == '')) {
                acc.Customer_Folder_URL__c = 'PLEASE FILL UP';
            }
        }
    }

    public static void updateAccountOwner(List<Account> listNew, Map<Id, Account> listOldMap){
        try{
            Set<Id> updatedAccIdSet = new Set<Id>();
            List<Account> updatedAccList = new List<Account>();
            List<Account> updateAccContactList = new List<Account>();
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email, Profile.Name, AD_User_Category__c, FederationIdentifier, Division FROM User]);
            Opportunity_Exception_User__mdt defaultSalesOpsUser = [SELECT Id, User_Email__c FROM Opportunity_Exception_User__mdt WHERE DeveloperName = 'Default_Sales_Ops_User' LIMIT 1];
            Set<String> adminProfileSet = new Set<String>{'System Administrator','Xendit API Profile'};
            for(Account acc : listNew){
                Account oldAcc = listOldMap != null && listOldMap.containsKey(acc.Id) ? listOldMap.get(acc.Id) : null;
                if(
                    !String.isBlank(acc.Business_ID__c) && 
                    ((!String.isBlank(acc.CP_Manager__c) && (oldAcc == null || (oldAcc != null && oldAcc.CP_Manager__c != acc.CP_Manager__c) || (acc.Update_to_AD__c && oldAcc.Update_to_AD__c != acc.Update_to_AD__c) || (acc.Team_Assignment__c != oldAcc.Team_Assignment__c)) && !adminProfileSet.contains(userMap.get(acc.CP_Manager__c).Profile.Name) && userMap.get(acc.CP_Manager__c).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ||
                    (!String.isBlank(acc.OwnerId) && (oldAcc == null || (oldAcc != null && oldAcc.OwnerId != acc.OwnerId) || (acc.Update_to_AD__c && oldAcc.Update_to_AD__c != acc.Update_to_AD__c) || (acc.Team_Assignment__c != oldAcc.Team_Assignment__c)) && !adminProfileSet.contains(userMap.get(acc.OwnerId).Profile.Name) && userMap.get(acc.OwnerId).FederationIdentifier != defaultSalesOpsUser.User_Email__c))
                ){
                    updatedAccIdSet.add(acc.Id);
                    updatedAccList.add(acc);
                }

                if(oldAcc != null && (oldAcc.OwnerId != acc.OwnerId || oldAcc.Go_Live_Status__c != acc.Go_Live_Status__c)){
                    updateAccContactList.add(acc);
                }
            }

            if(!updateAccContactList.isEmpty()){
                updateContactAMEmail(updateAccContactList, userMap);
            }

            if(!updatedAccIdSet.isEmpty()){
                Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
                String integName = !org.IsSandbox ? 'AD_User_Field_Update_URL_PRD' : 'AD_User_Field_Update_URL_Staging';
                Admin_Dashboard_Integration_Setting__mdt ADuserUpdateSetting = REST_AdminDashboardSyncSetup.getADSettings(integName);
                    if(!ADuserUpdateSetting.Deactivate__c){
                        for(Id accId : updatedAccIdSet){
                        Database.executeBatch(new UpdateADUserBatch(accId, 'Account'), 1);
                    }
                }

                List<Account> deactivateAccountFlag = new List<Account>();
                for(Account a : updatedAccList){
                    if(a.Update_to_AD__c){
                        deactivateAccountFlag.add(new Account(Id = a.Id, update_to_AD__c = false));
                    }
                }
                if(!deactivateAccountFlag.isEmpty()){
                    TriggerBypassUtility.accountTriggerBypass = true;
                    update deactivateAccountFlag;
                    TriggerBypassUtility.accountTriggerBypass = false;
                }
            }
            
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateAccountOwner', 'AccountTrigger',  e);
        }
    }

public static void updateXPAccountOwner(List<Account> listNew, Map<Id, Account> listOldMap){
        List<Account> updateAccOwnerList = new List<Account>();
        for(Account acc : listNew){
            Account oldAcc = listOldMap != null && listOldMap.containsKey(acc.Id) ? listOldMap.get(acc.Id) : null;

            if(oldAcc != null && oldAcc.OwnerId != acc.OwnerId && acc.Type == 'XP MASTER'){ //for XP Master
                updateAccOwnerList.add(acc);
            }
        }

        if(!updateAccOwnerList.isEmpty()){
            updateXPSAccount(updateAccOwnerList);
        }
    }

    public static void updateUltimateParent(List<Account> listNew, Map<Id, Account> listOldMap){
        try{
            Set<String> updatedUltimateParentIds = new Set<String>();
            for(Account acc : listNew){
                //store updated Parent Accounts
                if(!String.isBlank(acc.ParentId) && (listOldMap == null || (acc.ParentId != listOldMap.get(acc.Id).ParentId))){
                    updatedUltimateParentIds.add(acc.Ultimate_Parent_Formula__c);
                }
            }

            //get user detail
            User getUser = OpportunityHelper.getCurrentUser();
            Opportunity_Exception_User__mdt defaultDEUser = Opportunity_Exception_User__mdt.getInstance('Default_DE_User');
            if(getUser.FederationIdentifier != null && !getUser.FederationIdentifier.contains(defaultDEUser.User_Email__c) && !updatedUltimateParentIds.isEmpty()){ //exclude daily sync from DE
                UltimateParentUpdateBatch cx = new UltimateParentUpdateBatch(updatedUltimateParentIds);
                Database.executeBatch( cx , 100 ); 
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateUltimateParent', 'AccountTrigger',  e);
        }
        
    }

    public static void updateAccountRevenueValues(List<Account> listNew, Map<Id, Account> listOldMap){
        try{
            Set<String> updatedAccIds = new Set<String>();
            for(Account acc : listNew){
                //store accId if : 
                //1) parent updated
                //2) currency changed
                if(acc.ParentId != listOldMap.get(acc.Id).ParentId || (!String.isBlank(acc.CurrencyIsoCode) && acc.CurrencyIsoCode != listOldMap.get(acc.Id).CurrencyIsoCode)){
                    updatedAccIds.add(acc.Id);
                    if(acc.ParentId != listOldMap.get(acc.Id).ParentId && acc.ParentId == null){
                        updatedAccIds.add(listOldMap.get(acc.Id).ParentId);
                    }
                }
            }

            //get user detail
            User getUser = OpportunityHelper.getCurrentUser();
            Opportunity_Exception_User__mdt defaultDEUser = Opportunity_Exception_User__mdt.getInstance('Default_DE_User');
            if(getUser.FederationIdentifier != null && !getUser.FederationIdentifier.contains(defaultDEUser.User_Email__c) && !updatedAccIds.isEmpty()){ //exclude daily sync from DE
                ParentAccountRevenueUpdateBatch cx = new ParentAccountRevenueUpdateBatch(updatedAccIds);
                Database.executeBatch( cx , 1 ); 
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateAccountRevenueValues', 'AccountTrigger',  e);
        }
        
    }

    public static void updateParentAccountName(List<Account> listNew, Map<Id, Account> listOldMap){
        try{
            Set<Id> updatedAccNameSetId = new Set<Id>();
            for(Account acc : listNew){
                Account oldAcc = listOldMap.get(acc.Id);
                if(acc.Name != oldAcc.Name || acc.BillingCountry != oldAcc.BillingCountry){
                    updatedAccNameSetId.add(acc.Id);
                }

            }

            if(!updatedAccNameSetId.isEmpty()){
                List<Account> childAccounts = [SELECT Id, Name FROM Account WHERE ParentId IN :updatedAccNameSetId];
                TriggerBypassUtility.accountTriggerBypass = TRUE;
                TriggerBypassUtility.opportunityTriggerBypass = TRUE;
                User UserBypassVR = new User(Id = UserInfo.getUserId(), Bypass_VR__c = true);
                update UserBypassVR;
                update childAccounts;
                UserBypassVR.Bypass_VR__c = false;
                update UserBypassVR;
                TriggerBypassUtility.accountTriggerBypass = FALSE;
                TriggerBypassUtility.opportunityTriggerBypass = FALSE;
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateAccountRevenueValues', 'AccountTrigger',  e);
        }
    }

    public static void updateXPSAccount(List<Account> listNew){
        try{
            Map<Id, List<Account>> accChildMap = new Map<Id, List<Account>>();
            List<Account> updateChildAccountList = new List<Account>();
            for(Account acc : listNew){
                accChildMap.put(acc.Id, new List<Account>());
            }
            for(Account childAcc : [SELECT Id, OwnerId, ParentId, Parent.OwnerId, Parent.Ultimate_Parent_Formula__c FROM Account WHERE ParentId IN :accChildMap.keySet() AND Parent.Type = 'XP MASTER' AND Type = 'XP MANAGED']){
                if(childAcc.OwnerId != childAcc.Parent.OwnerId){
                    Account childAccTemp = new Account(Id = childAcc.Id, OwnerId = childAcc.Parent.OwnerId, Ultimate_Parent__c = childAcc.Parent.Ultimate_Parent_Formula__c);
                    updateChildAccountList.add(childAccTemp);
                }
            }

            if(!updateChildAccountList.isEmpty()){
                update updateChildAccountList;
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateXPSAccount', 'AccountTrigger',  e);
        }
    }
    
    public static void updateOppBDProspectingStage(List<Account> listNew, Map<Id, Account> mapOld){
        /*
        if some of the account fields changed : 
        Website, Segment, No. of Employee, Transaction Volume
        */

        Set<Id> accountIdSet = new Set<Id>();

        for(Account acc : listNew){
            Account oldAcc = mapOld.get(acc.Id);
            Boolean isWebsiteChanged = isFieldChanged(acc.Website, oldAcc.Website);
            Boolean isSegmentChanged = isFieldChanged(acc.Segment__c, oldAcc.Segment__c);
            Boolean isEmployeeChanged = isFieldChanged(acc.Number_of_Employees_Lead_Qual__c, oldAcc.Number_of_Employees_Lead_Qual__c);
            Boolean isTxnVolChanged = (isFieldChanged(acc.Expected_Transaction_Volume__c, oldAcc.Expected_Transaction_Volume__c) || 
                                      isFieldChanged(acc.Estimated_Transactions_Handle_Each_Month__c, oldAcc.Estimated_Transactions_Handle_Each_Month__c) || 
                                      isFieldChanged(acc.Average_Transaction_Size_Lead_Qual__c, oldAcc.Average_Transaction_Size_Lead_Qual__c));
            if(isWebsiteChanged || isSegmentChanged || isEmployeeChanged || isTxnVolChanged){
                accountIdSet.add(acc.Id);
            }
        }

        if(!accountIdSet.isEmpty()){
            Id parentOppRecTypeId = OpportunityHelper.getParentRecordTypeId();
            List<Opportunity> parentOppList = [SELECT Id, Update_BD_Stage_From_Account__c, RecordTypeId, AccountId, StageName, Xst_Txn_Act_Date__c, Pains_Priorities_and_Needs__c, Next_Step_Blockers__c, BD_Prospecting_Stage__c 
                                               FROM Opportunity WHERE AccountId IN :accountIdSet AND RecordTypeId = :parentOppRecTypeId AND StageName = 'Qualification'];
            for(Opportunity opp : parentOppList){
                opp.Update_BD_Stage_From_Account__c = true;
            }

            if(parentOppList != null && !parentOppList.isEmpty()){
                TriggerBypassUtility.opportunityTriggerBypass = true;
                OpportunityHelper.setBDProspectingStage(parentOppList, null);
                update parentOppList;
                TriggerBypassUtility.opportunityTriggerBypass = false;
            }
        }
    }

    public static Boolean isFieldChanged(String strFieldNew , String strFieldOld){
        return (strFieldNew != strFieldOld);
    }

    /* 
        Method Name : updateContactAMEmail
        Description : Update contact's AM Email when account owner is updated to AM
    */
    public static void updateContactAMEmail(List<Account> accList, Map<Id, User> userMap){
        try{
            Map<Id, Id> accOwnerIdMap = new Map<Id, Id>();
            String amDivisionLabel = System.Label.AM_DIVISION_DEFAULT;

            //get list of users in the public group
            Map<Id, User> AMTeamUsers = new Map<Id, User>([SELECT Id, Email, Division FROM User WHERE Id IN
                                                        (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = 'AM Team')]);

            for(Account acc : accList){
                accOwnerIdMap.put(acc.Id, acc.OwnerId);
            }
            //get contacts related to the accounts
            List<Contact> updateContactList = new List<Contact>();
            for(Contact con : [SELECT Id, AccountId, Account.Go_Live_Status__c FROM Contact WHERE AccountId IN :accOwnerIdMap.keySet()]){
                Contact tempCon = new Contact(Id = con.Id);
                Id accOwnerId = accOwnerIdMap.get(con.AccountId);
                User accOwner = userMap.get(accOwnerId);
                //if account owner division is AM, OR user is in the AM Team public group -> update contact AM Email field
                if((!String.isBlank(accOwner.Division) && accOwner.Division.contains(amDivisionLabel)) || AMTeamUsers.containsKey(accOwner.Id)){
                    tempCon.AM_Email__c = accOwner.Email;
                }else{
                    tempCon.AM_Email__c = null;
                }

                tempCon.Go_Live_Status__c = con.Account.Go_Live_Status__c;
                
                updateContactList.add(tempCon);
            }

            if(!updateContactList.isEmpty()){
                update updateContactList;
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'updateContactAMEmail', 'AccountTrigger',  e);
        }
    }

    public static void updateWeeklyUpdateHistory(List<Account> listNew, Map<Id, Account> oldMap){
        try{
            for(Account acc : listNew){
                DateTime todayDate = Datetime.now();
                String strTodayDate = todayDate.format('dd/MM/yyyy');
                String currWeeklyUpdate = !String.isBlank(acc.Weekly_Update__c) ? strTodayDate + ' ' + UserInfo.getName() + ': ' + acc.Weekly_Update__c : '';
                if(oldMap == null){
                    acc.Weekly_Update_History__c = currWeeklyUpdate;
                }else if(acc.Id != null && oldMap.containsKey(acc.Id) && oldMap.get(acc.Id).Weekly_Update__c != acc.Weekly_Update__c){
                    String weeklyHistory = acc.Weekly_Update_History__c != null ? acc.Weekly_Update_History__c : '';
                    acc.Weekly_Update_History__c = currWeeklyUpdate +'<br/>'+weeklyHistory;
                }
            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'UpdateWeeklyUpdateHistory', 'AccountTrigger',  e);
        }
    }

/*
    Name : UpdateFirstLastTouchLeadSource
    Description : update first & last touch lead source
    */
    public static void updateFirstLastTouchLeadSource(List<Account> listNew, Map<Id, Account> oldMap){
        try{
            for(Account acc : listNew){
                Account oldAcc = oldMap.get(acc.Id);
                if(oldAcc != null){
                    String currFirstTouchLeadSource = acc.AccountSource;
                    String currLastTouchLeadSource = acc.Last_Touch_Lead_source__c;
                    acc.AccountSource = HeeetHelper.getFirstTouchLeadSource(acc, oldAcc, currFirstTouchLeadSource);
                    acc.Last_Touch_Lead_source__c = HeeetHelper.getLastTouchLeadSource(acc, oldAcc, currLastTouchLeadSource);
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'UpdateFirstLastTouchLeadSource', 'AccountTrigger',  e);
        }
    }
    
    /*
    Name : CreateOpportunityGLR
    Description : create opportunity when GLR Flag updated to TRUE
    */
    public static void CreateOpportunityGLR(Map<Id, Account> newMap, Map<Id, Account> oldMap){
        List<Exception_Logger__c> exceptionList = new List<Exception_Logger__c>();
        String defaultUserEmail = System.Label.DEFAULT_OWNER_EMAIL;
        User defaultOppOwner = [SELECT Id FROM User WHERE Email = :defaultUserEmail OR FederationIdentifier = :defaultUserEmail LIMIT 1];
        try{
            Map<Id, String> accCountryGLRMap = new Map<Id, String>();
            for(Id newAccId : newMap.keySet()){
                Account acc = newMap.get(newAccId);
                Account oldAcc = oldMap.get(newAccId);
                if(acc.Id != null && acc.GLR_Flag__c && oldAcc.GLR_Flag__c != acc.GLR_Flag__c && (acc.Pipeline_Source__c == 'Undeclared Interest' || acc.Pipeline_Source__c == 'Declared Interest')){
                    String accCountry = acc.Country_of_HQ__c;
                    if(!String.isBlank(acc.Country_of_HQ__c) || !String.isBlank(acc.BillingCountry)){
                        accCountry = !String.isBlank(acc.Country_of_HQ__c) ? acc.Country_of_HQ__c : acc.BillingCountry;
                    }
                    accCountryGLRMap.put(acc.Id, accCountry);
                }
            }

            if(!accCountryGLRMap.isEmpty()){
                Map<String, Set<Id>> defaultProductCountryMap = new Map<String, Set<Id>>();
                Map<Id, Set<Id>> accDefaultProdMap = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> accOppProdMap = new Map<Id, Set<Id>>();
                Map<Id, Opportunity> accParentOppMap = new Map<Id, Opportunity>();
                Map<Id, Opportunity> accChildOppMap = new Map<Id, Opportunity>();
                Map<String, Id> pbNameIdMap = new Map<String, Id>();
                List<Xendit_Opportunity_Product__c> createOppProductList = new List<Xendit_Opportunity_Product__c>();
                Id parentOppRecTypeId = OpportunityHelper.getParentRecordTypeId();
                Id childOppRecTypeId = OpportunityHelper.getChildRecordTypeId();
                //get pricebook
                for(Xendit_Price_Book__c pb : [SELECT Id, Name FROM Xendit_Price_Book__c WHERE Active__c = TRUE]){
                    pbNameIdMap.put(pb.Name, pb.Id);
                }

                //query all default products based on country
                for(GLR_Default_Product__c dp : [SELECT Country__c, Product__c FROM GLR_Default_Product__c WHERE Country__c != NULL AND Product__c != NULL AND Country__c IN :accCountryGLRMap.values()]){
                    if(!defaultProductCountryMap.containsKey(dp.Country__c)){
                        defaultProductCountryMap.put(dp.Country__c, new Set<Id>{dp.Product__c});
                    }else{
                        defaultProductCountryMap.get(dp.Country__c).add(dp.Product__c);
                    }
                }
                
                //query exst opp product related to the account
                for(Xendit_Opportunity_Product__c xOpp : [SELECT Opportunity_Account_Id__c, Rate_Card__r.Product__c FROM Xendit_Opportunity_Product__c WHERE Rate_Card__r.Product__c != NULL AND Opportunity_Account_Id__c IN :accCountryGLRMap.keySet()]){
                    if(!accOppProdMap.containsKey(xOpp.Opportunity_Account_Id__c)){
                        accOppProdMap.put(xOpp.Opportunity_Account_Id__c, new Set<Id>{xOpp.Rate_Card__r.Product__c});
                    }else{
                        accOppProdMap.get(xOpp.Opportunity_Account_Id__c).add(xOpp.Rate_Card__r.Product__c);
                    }
                }

                for(Id accId : accCountryGLRMap.keySet()){
                    //get country
                    String accCountry = accCountryGLRMap.get(accId);
                    if(!String.isBlank(accCountry)){
                        //get default prod set
                        Set<Id> defaultProdSet = defaultProductCountryMap.containsKey(accCountry) ? defaultProductCountryMap.get(accCountry) : null;
                        
                        //get opp prod set
                        Set<Id> oppProdSet = accOppProdMap.containsKey(accId) ? accOppProdMap.get(accId) : null;

                        if(defaultProdSet != null){
                            if(oppProdSet != null){
                                List<Id> oppProdList = new List<Id>(oppProdSet);
                                defaultProdSet.removeAll(oppProdSet);
                            }
                            
                            if(!defaultProdSet.isEmpty()){
                                accDefaultProdMap.put(accId, defaultProdSet);

                                Id ownerId = newMap.get(accId).OwnerId;
                                if (newMap.get(accId).Type == 'XP MANAGED' || newMap.get(accId).Type == 'XP Sub (Managed)') {
                                    ownerId = defaultOppOwner.Id;
                                }

                                Date estFirstTxnDate = Date.today() + 30;
                                Opportunity parentOpp = new Opportunity(Name = 'ParentOpp', Pipeline_Source__c = newMap.get(accId).Pipeline_Source__c, RecordTypeId = parentOppRecTypeId, AccountId = accId, OwnerId = ownerId, CurrencyIsoCode = newMap.get(accId).CurrencyIsoCode, CloseDate = estFirstTxnDate, Xst_Txn_Act_Date__c = estFirstTxnDate, StageName = 'Qualification');
                                accParentOppMap.put(accId, parentOpp);
                            }
                        }
                    }
                }

                if(!accParentOppMap.isEmpty()){
                    List<Database.Saveresult> parentInsertResults = Database.insert(accParentOppMap.values(), false);
                    List<Id> parentIdList = new List<Id>();
                    for (Database.SaveResult sr : parentInsertResults) {
                        if (sr.isSuccess()) {
                            parentIdList.add(sr.getId());
                        } else {
                            // Record failed to save
                            for (Database.Error error : sr.getErrors()) {
                                // Handle each error
                                exceptionList.add(ExceptionUtility.constructDatabaseError('AccountHelper','CreateOpportunityGLR', 'insert', 'Auto Create Parent Opportunity GLR', error.getMessage()));
                            }
                        }
                    }

                    for(Opportunity opp : [SELECT AccountId, Id, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName FROM Opportunity WHERE Id IN :parentIdList]){
                        Opportunity childOpp = new Opportunity(Name = 'ChildOpp', Parent_Opportunity__c = opp.Id, RecordTypeId = childOppRecTypeId, AccountId = opp.AccountId, OwnerId = opp.OwnerId, CurrencyIsoCode = opp.CurrencyIsoCode, CloseDate = opp.Xst_Txn_Act_Date__c, Xst_Txn_Act_Date__c = opp.Xst_Txn_Act_Date__c, StageName = opp.StageName, Xendit_Price_Book__c = getRelatedPriceBook(opp.CurrencyIsoCode, pbNameIdMap));
                        accChildOppMap.put(opp.AccountId, childOpp);
                    }

                    if(!accChildOppMap.isEmpty()){
                        List<Database.Saveresult> childInsertResults = Database.insert(accChildOppMap.values(), false);
                        List<Id> childIdList = new List<Id>();
                        Set<Id> allDefaultProdSet = new Set<Id>();
                        for (Database.SaveResult sr : childInsertResults) {
                            if (sr.isSuccess()) {
                                childIdList.add(sr.getId());
                            } else {
                                // Record failed to save
                                for (Database.Error error : sr.getErrors()) {
                                    // Handle each error
                                    exceptionList.add(ExceptionUtility.constructDatabaseError('AccountHelper','CreateOpportunityGLR', 'insert', 'Auto Create Child Opportunity GLR', error.getMessage()));
                                }
                            }
                        }

                        //get rate card query
                        for(Id accId : accDefaultProdMap.keySet()){
                            allDefaultProdSet.addAll(accDefaultProdMap.get(accId));
                        }

                        //createOpportunityProductAsync(allDefaultProdSet, accDefaultProdMap, childIdList);
                        List<Rate_Card__c> rcList = [SELECT Id, Product__c, Xendit_Price_Book__c, Basket_Size_Threshold__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, CurrencyIsoCode, 
                                                    Fixed_Rate__c, Reseller_Rate_per_TPV__c, Reseller_Rate_per_Txn__c, Rate_Per_TPV__c,Rate_Per_Txn__c, Rate_Per_Event__c, Rate_Per_Subaccount__c, 
                                                    Product__r.Basket_Size_Enterprise__c, Product__r.Basket_Size_Individuals__c, Product__r.Basket_Size_MM__c, Product__r.Basket_Size_SME__c, Brand__c, Channel__c 
                                                    FROM Rate_Card__c WHERE Product__c IN :allDefaultProdSet];

                        for(Opportunity opp : [SELECT AccountId, Id, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName, Xendit_Price_Book__c FROM Opportunity WHERE Id IN :childIdList]){
                            //get filtered rate card
                            List<Rate_Card__c> filteredRCList = getFilteredRateCard(opp.Xendit_Price_Book__c, accDefaultProdMap.get(opp.AccountId), rcList);
                            if(!filteredRCList.isEmpty()){
                                for(Rate_Card__c rct : filteredRCList){
                                    Xendit_Opportunity_Product__c createxOpp = new Xendit_Opportunity_Product__c(From_Lead_Conversion__c = true, Opportunity__c = opp.Id, Product__c = rct.Product__c, Rate_Card__c = rct.Id);
                                    createOppProductList.add(createxOpp);
                                }
                            }
                        }

                        if(!createOppProductList.isEmpty()){
                            List<Database.Saveresult> opportunityProductInsertResult = Database.insert(createOppProductList, false);
                            List<Id> productList = new List<Id>();
                            for (Database.SaveResult sr : opportunityProductInsertResult) {
                                if (sr.isSuccess()) {
                                    productList.add(sr.getId());
                                } else {
                                    // Record failed to save
                                    for (Database.Error error : sr.getErrors()) {
                                        // Handle each error
                                        exceptionList.add(ExceptionUtility.constructDatabaseError('AccountHelper','CreateOpportunityGLR', 'insert', 'Auto Create Child Products GLR', error.getMessage()));
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (exceptionList.size() > 0) {
                insert exceptionList;
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'CreateOpportunityGLR', 'AccountTrigger',  e);
        }
    }

    // @future
    // public static void createOpportunityProductAsync(Set<Id> allDefaultProdSet, Map<Id, Set<Id>> accDefaultProdMap, Set<Id> childIdList) {
    //     List<Rate_Card__c> rcList = [SELECT Id, Product__c, Xendit_Price_Book__c, Basket_Size_Threshold__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, CurrencyIsoCode, 
    //                                 Fixed_Rate__c, Reseller_Rate_per_TPV__c, Reseller_Rate_per_Txn__c, Rate_Per_TPV__c,Rate_Per_Txn__c, Rate_Per_Event__c, Rate_Per_Subaccount__c, 
    //                                 Product__r.Basket_Size_Enterprise__c, Product__r.Basket_Size_Individuals__c, Product__r.Basket_Size_MM__c, Product__r.Basket_Size_SME__c, Brand__c, Channel__c 
    //                                 FROM Rate_Card__c WHERE Product__c IN :allDefaultProdSet];

    //     for(Opportunity opp : [SELECT AccountId, Id, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName, Xendit_Price_Book__c FROM Opportunity WHERE Id IN :childIdList]){
    //         //get filtered rate card
    //         List<Rate_Card__c> filteredRCList = getFilteredRateCard(opp.Xendit_Price_Book__c, accDefaultProdMap.get(opp.AccountId), rcList);
    //         if(!filteredRCList.isEmpty()){
    //             for(Rate_Card__c rct : filteredRCList){
    //                 Xendit_Opportunity_Product__c createxOpp = new Xendit_Opportunity_Product__c(From_Lead_Conversion__c = true, Opportunity__c = opp.Id, Product__c = rct.Product__c, Rate_Card__c = rct.Id);
    //                 createOppProductList.add(createxOpp);
    //             }
    //         }
    //     }

    //     if(!createOppProductList.isEmpty()){
    //         Database.insert(createOppProductList, false);
    //     }
    // }

    /*
    Name : getRelatedPriceBook
    Description : get price book Id based on currency
    */
    public static Id getRelatedPriceBook(String currencyIsoCode, Map<String, Id> pbNameIdMap){
        String pbStr = 'USD Price Book';
        if(currencyIsoCode == 'IDR'){
            pbStr = 'Indonesia Price Book';
        }else if(currencyIsoCode == 'PHP'){
            pbStr = 'Philippines Price Book';
        }else if(currencyIsoCode == 'SGD'){
            pbStr = 'SGD Price Book';
        }

        return (pbNameIdMap.containsKey(pbStr) ? pbNameIdMap.get(pbStr) : null);
    }

    /*
    Name : getFilteredRateCard
    Description : get rate card based on product and pricebook
    */
    public static List<Rate_Card__c> getFilteredRateCard(Id pbId, Set<Id> defaultProdId, List<Rate_Card__c> rcList){
        List<Rate_Card__c> returnList = new List<Rate_Card__c>();
        for(Rate_Card__c rc : rcList){
            if(pbId != null && rc.Xendit_Price_Book__c == pbId && defaultProdId.contains(rc.Product__c)){
                returnList.add(rc);
            }
        }
        return returnList;
    }

     /*
    Name : UpdateCampaignMemberStatusDashboardSignUp
    Description : update camp member status to Dashboard Sign Up when account BID is populated
    */
    public static void UpdateCampaignMemberStatusDashboardSignUp(List<Account> listNew, Map<Id, Account> oldMap){
        try{
            Set<Id> updateAccountIdSet = new Set<Id>();
            Set<Id> updateContactIdSet = new Set<Id>();
            for(Account a : listNew){
                Account oldAccount = oldMap.get(a.Id);
                if(String.isBlank(oldAccount.Business_Id__c) && !String.isBlank(a.Business_Id__c)){ // if Business Id is populated
                    updateAccountIdSet.add(a.Id);
                }
            }

            if(!updateAccountIdSet.isEmpty()){
                //get related contact
                for(Contact c : [SELECT Id FROM Contact WHERE AccountId IN :updateAccountIdSet]){
                    updateContactIdSet.add(c.Id);
                }

                if(!updateContactIdSet.isEmpty()){
                    AutoUpdateCampaignMemberStatusBatch cx = new AutoUpdateCampaignMemberStatusBatch(null, null, updateContactIdSet, 'Dashboard Sign Up');
                    Database.executeBatch(cx, 200);
                }
                
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'UpdateCampaignMemberStatusDashboardSignUp', 'AccountTrigger',  e);
        }
    }
    
    /*
    Name: AutoClosedLostOpportunity
    Description:Auto closed lost opportunity when KYC verification status of Account is updated to FAILED
    */
    public static void AutoClosedLostOpportunity(List<Account> listNew, Map<Id, Account> oldMap){
        Set<Id> accountIdsToUpdate = new Set<Id>();
        String defaultUserEmail = System.Label.DEFAULT_OWNER_EMAIL; //self-serve@xendit.co
        
        for (Account acc : listNew) {
            Account oldAcc = oldMap.get(acc.Id);
            if (acc.KYC_Verification_Status__c == 'FAILED' && (oldAcc == null || oldAcc.KYC_Verification_Status__c != 'FAILED')) {
                accountIdsToUpdate.add(acc.Id);
            }
        }
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();        
        for (Opportunity opp : [SELECT Id,Reason_Lost_Opp__c,Sub_Reason_Opp__c
                                FROM Opportunity
                                WHERE AccountId IN :accountIdsToUpdate
                                AND LeadSource = 'Inbound'
                                AND Owner.federationIdentifier =: defaultUserEmail
                                AND StageName NOT IN ('Closed Won','Closed Lost') ]) 
        {
            opp.StageName = 'Closed Lost';
            opp.Reason_Lost_Opp__c='Dead - Lost';
            opp.Sub_Reason_Opp__c='Did not hit target objective within marketing campaign active period';
            opportunitiesToUpdate.add(opp);
        }        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }

    public static void MergeOpportunitiesOnAccountMerge(List<Account> listNew, List<Account> listOld) {
        Set<Id> mergedAccountIds = new Set<Id>();
        Map<Id, Opportunity> opportunitiesByAccountId = new Map<Id, Opportunity>();
        List<Opportunity> masterOppty = new List<Opportunity>();
        List<Opportunity> losingOppty = new List<Opportunity>();
        Set<Id> stParentOppInbound = new Set<Id>(); 
        Id stParentOppOutbound; 

        for (Account mergedAccount : listOld) {
            if (mergedAccount.MasterRecordId != null) {
                mergedAccountIds.add(mergedAccount.MasterRecordId);
            }
        } 

        if(mergedAccountIds.size()>0){
            List<Opportunity> parentInbound = [SELECT Id FROM Opportunity WHERE AccountId IN :mergedAccountIds AND LeadSource = 'Inbound'];
            for(Opportunity opp: parentInbound){
                stParentOppInbound.add(opp.id);
            }
            
            // Query for opportunities related to the merged account.   
            List<Opportunity> childOpportunities = [SELECT Id, Name, AccountId, Xendit_Price_Book__c, StageName, CreatedById, LeadSource, Parent_Opportunity__c, OwnerId
                                               FROM Opportunity
                                               WHERE AccountId IN :mergedAccountIds AND Parent_Opportunity__c != null];
            for (Opportunity opp : childOpportunities) {
                if (stParentOppInbound.contains(opp.Parent_Opportunity__c)) {
                    losingOppty.add(opp); // This opportunity was associated with the deleted account before the merge                     
                } else {
                    masterOppty.add(opp);  // This opportunity was originally associated with the master account  
                } 
            }
        } 
                
        for (Opportunity inboundOppty : losingOppty) {
            for (Opportunity outboundOppty : masterOppty) {
				if (canMergeOpportunities(inboundOppty, outboundOppty)) {
                    deleteOppty.add(inboundOppty.Id);
                    stParentOppOutbound = outboundOppty.parent_opportunity__c;
                }
            }
        }

        if (deleteOppty.size()> 0) {
            Set<Id> setParentDeleteOppty = new Set<Id>();
            for(Opportunity delOpty: [SELECT ID, Name, parent_opportunity__c FROM Opportunity WHERE ID IN :deleteOppty]){
                setParentDeleteOppty.add(delOpty.parent_opportunity__c);
            }
        
            List<Opportunity> getAllChildInboundOppty = [SELECT Id, Name, LeadSource FROM Opportunity WHERE parent_opportunity__c IN: setParentDeleteOppty];

            if(deleteOppty.size() == getAllChildInboundOppty.size()){
                System.debug('####running merge');
                deleteOppty.addAll(setParentDeleteOppty);   //Add the parent opportunity for deletion since all child opportunities meet the specified conditions
                List<CampaignInfluence> lstcampaignInfluence = [SELECT Id, OpportunityId, CampaignId, ContactId, Influence, External_Id__c, RevenueShare, ModelId, iY_Rev_Share__c 
                                                                FROM CampaignInfluence WHERE OpportunityId IN :setParentDeleteOppty];
                
                List<OpportunityContactRole> lstOpptyContactRole = [SELECT OpportunityId, ContactId, Role, IsPrimary, Id, CurrencyIsoCode FROM OpportunityContactRole WHERE OpportunityId IN: setParentDeleteOppty];
                
                List<CampaignInfluence> newCampaignInfluences = new List<CampaignInfluence>();
                for (CampaignInfluence ci : lstcampaignInfluence) {
                    CampaignInfluence newCi = new CampaignInfluence( OpportunityId = stParentOppOutbound,CampaignId = ci.CampaignId, ContactId = ci.ContactId,
                                                                    Influence = ci.Influence, External_Id__c = ci.External_Id__c, ModelId = ci.ModelId);
                    newCampaignInfluences.add(newCi);
                }
                
                if (!newCampaignInfluences.isEmpty()) {
                    insert newCampaignInfluences;
                }
                
                List<OpportunityContactRole> newOpptyContactRoles = new List<OpportunityContactRole>();
                for (OpportunityContactRole ocr : lstOpptyContactRole) {
                    OpportunityContactRole newOcr = new OpportunityContactRole(
                        OpportunityId = stParentOppOutbound,
                        ContactId = ocr.ContactId,
                        Role = ocr.Role,
                        IsPrimary = ocr.IsPrimary,
                        CurrencyIsoCode = ocr.CurrencyIsoCode
                    );
                    newOpptyContactRoles.add(newOcr);
                }
                
                if (!newOpptyContactRoles.isEmpty()) {
                    System.debug('####create OCR');
                    insert newOpptyContactRoles;
                }
            }
            System.debug('####call delete account');
            List<Id> deleteOpptyList = new List<Id>(deleteOppty);
            deleteOpportunitiesAsync(deleteOpptyList);
        }      
    }

    private static Boolean canMergeOpportunities(Opportunity inboundOppty, Opportunity outboundOppty) {
        // Add logic to check if opportunities can be merged based on product matching and pricebook
        Boolean samePricebook = inboundOppty.Xendit_Price_Book__c == outboundOppty.Xendit_Price_Book__c;
        if (samePricebook) {
            Map<Id, Xendit_Opportunity_Product__c> inboundProductMap = getProductMap(inboundOppty.Id);
            Map<Id, Xendit_Opportunity_Product__c> outboundProductMap = getProductMap(outboundOppty.Id);

            // Check if there is at least one common product between the inbound and outbound opportunities
            for (Id productId : inboundProductMap.keySet()) {
                if (outboundProductMap.containsKey(productId)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static Map<Id, Xendit_Opportunity_Product__c> getProductMap(Id opportunityId) {
        Map<Id, Xendit_Opportunity_Product__c> productMap = new Map<Id, Xendit_Opportunity_Product__c>();
        List<Xendit_Opportunity_Product__c> products = [SELECT Product__c FROM Xendit_Opportunity_Product__c WHERE Opportunity__c = :opportunityId];
        
        for (Xendit_Opportunity_Product__c product : products) {
            productMap.put(product.Product__c, product);
        } 
    
        return productMap;
    }
    
    @future
    public static void deleteOpportunitiesAsync(List<Id> opportunityIds) {
        try{
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();        
            for (Opportunity updateFlagOppty :[SELECT ID, is_merged_account__c from Opportunity WHERE ID IN :opportunityIds]){
                updateFlagOppty.is_merged_account__c = TRUE;
                opportunitiesToUpdate.add(updateFlagOppty);
            }
            TriggerBypassUtility.opportunityTriggerBypass = true;
            System.debug('####bypass true');
            update opportunitiesToUpdate;
            TriggerBypassUtility.opportunityTriggerBypass = false;
            
            system.debug('####deleteOpportunitiesAsync:' + opportunitiesToUpdate + ' oppIds :' + opportunityIds);
            delete [SELECT Id FROM Opportunity WHERE Id IN :opportunityIds];
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AccountHelper','Account', 'DeleteOpportunitiesAsyncWhenMergeAccount', 'AccountTrigger',  e);
        }
    }
}