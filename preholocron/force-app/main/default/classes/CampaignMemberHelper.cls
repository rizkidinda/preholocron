/**
* @description       : 
* @group             : 
* @last modified on  : 28-11-2023
* @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public class CampaignMemberHelper {
    
    /*
	Name : AutoCreateCrossSellUpsellOpportunity
	Description : auto create opp for cross sell / upsell everytime program campaign updated to Tactic Engaged
	*/
    public static void AutoCreateCrossSellUpsellOpportunity(List<CampaignMember> listNew, Map<Id, CampaignMember> oldMap){
        system.debug('AutoCreateCrossSellUpsellOpportunity start');
        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
        Set<Id> campaignIdSet = new Set<Id>();
        List<CampaignMember> selectedCrossSellCampaignMemberList = new List<CampaignMember>();
        List<CampaignMember> selectedUpsellCampaignMemberList = new List<CampaignMember>();
        for(CampaignMember member : listNew){
            if(member.CampaignId != null){
                campaignIdSet.add(member.CampaignId);
            }
        }
        
        for(Campaign campaignObj : [SELECT Id, RecordType.Name, Objective__c FROM Campaign WHERE Id IN :campaignIdSet]){
            campaignMap.put(campaignObj.Id, campaignObj);
        }
        
        for(CampaignMember member : listNew){
            Boolean isValidCrossSellAutoCreateOpp = IsValidCrossSellUpsellAutoCreateOpp(member, oldMap, campaignMap, 'Products Activated / Cross-sell');
            Boolean isValidUpsellAutoCreateOpp = IsValidCrossSellUpsellAutoCreateOpp(member, oldMap, campaignMap, 'Upsell');
            system.debug('***Valid Upsell: '+ isValidUpsellAutoCreateOpp);
            if(isValidCrossSellAutoCreateOpp){
                selectedCrossSellCampaignMemberList.add(member);
            }else if(isValidUpsellAutoCreateOpp){
                selectedUpsellCampaignMemberList.add(member);
            }
        }
        
        if(!selectedCrossSellCampaignMemberList.isEmpty()){
            CreateCrossSellUpsellOpportunity(selectedCrossSellCampaignMemberList, 'Cross Sell');
        }
        
        if(!selectedUpsellCampaignMemberList.isEmpty()){
            CreateCrossSellUpsellOpportunity(selectedUpsellCampaignMemberList, 'Upsell');
        }
    }
    
    /*
Name : CreateCrossSellUpsellOpportunity
Description : auto create opportunity for cross sell
*/
    public static void CreateCrossSellUpsellOpportunity(List<CampaignMember> listNew, String objective){
        system.debug('CreateCrossSellUpsellOpportunity start');
        Map<Id, List<String>> campaignAccountIDMap = new Map<Id, List<String>>();
        Map<String, Set<Id>> accountIdContactMap = new Map<String, Set<Id>>();
        Set<Id> accountIdSet = new Set<Id>();
        
        for(CampaignMember member : listNew){
            accountIdSet.add(member.Contact_Account_Id__c);
            if(!campaignAccountIDMap.containsKey(member.CampaignId)){
                campaignAccountIDMap.put(member.CampaignId, new List<String>{member.Contact_Account_Id__c});
            }else{
                campaignAccountIDMap.get(member.CampaignId).add(member.Contact_Account_Id__c);
            }
            
            if(!accountIdContactMap.containsKey(member.Contact_Account_Id__c)){
                accountIdContactMap.put(member.Contact_Account_Id__c, new Set<Id>{member.ContactId});
            }else{
                accountIdContactMap.get(member.Contact_Account_Id__c).add(member.ContactId);
            }
        }
        
        if(!campaignAccountIDMap.isEmpty()){
            Set<Id> contactRoleOppId = new Set<Id>();
            Map<Id, Set<Id>> campaignProductMap = new Map<Id, Set<Id>>();
            Map<String, Set<Id>> accIdLiveProductMap = new Map<String, Set<Id>>();
            Map<String, Map<String,Set<Id>>> accIdOppProductMap = new Map<String, Map<String,Set<Id>>>();
            Map<String, List<Opportunity>> accountIdOppMap = new Map<String, List<Opportunity>>();
            Map<String, OpportunityContactRole> oppContactRoleMap = new Map<String, OpportunityContactRole>();
            Map<String, Set<Id>> campOppMap = new Map<String, Set<Id>>();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            Map<String, Set<String>> accIdCampaignInfluenceKeyMap = new Map <String, Set<String>>(); //key : BID <> CampaignId_ContactId
            
            //get opp id from contact role
            for(OpportunityContactRole contactRole : [SELECT OpportunityId FROM OpportunityContactRole WHERE Contact.AccountId IN :accountIdSet]){
                contactRoleOppId.add(contactRole.OpportunityId);
            }
            
            //get opportunity + contact role + opp product
            List<Opportunity> oppList = GetRelatedOpp(accountIdSet, contactRoleOppId, objective);
            for(Opportunity opp : oppList){
                String oppCampaignId = opp.CampaignId != null ?  '_' + opp.CampaignId : '';
                String mapKeyStr = opp.AccountId + oppCampaignId;
                if(!accountIdOppMap.containsKey(mapKeyStr)){
                    accountIdOppMap.put(mapKeyStr, new List<Opportunity>{opp});
                }else{
                    accountIdOppMap.get(mapKeyStr).add(opp);
                }
                
                if(!campOppMap.containsKey(mapKeyStr)){
                    campOppMap.put(mapKeyStr, new Set<Id>{opp.Id});
                }else{
                    campOppMap.get(mapKeyStr).add(opp.Id);
                }
                
                oppMap.put(opp.Id, opp);
            }
            
            //get campaign product from existing campaigns
            for(Campaign_Product__c campaignProduct : [SELECT Campaign__c, Product__c FROM Campaign_Product__c WHERE Product__c != NULL AND Campaign__c IN :campaignAccountIDMap.keySet()]){
                if(!campaignProductMap.containsKey(campaignProduct.Campaign__c)){
                    campaignProductMap.put(campaignProduct.Campaign__c, new Set<Id>{campaignProduct.Product__c});
                }else{
                    campaignProductMap.get(campaignProduct.Campaign__c).add(campaignProduct.Product__c);
                }
            }
            
            //get channel kyc product from existing BID
            for(Channel_KYC__c channelKYC : [SELECT Account__c, Account__r.Business_Id__c, Product__c FROM Channel_KYC__c WHERE Product__c != NULL AND Account__c IN :accountIdSet AND Status__c = 'LIVE']){
                if(!accIdLiveProductMap.containsKey(channelKYC.Account__c)){
                    accIdLiveProductMap.put(channelKYC.Account__c, new Set<Id>{channelKYC.Product__c});
                }else{
                    accIdLiveProductMap.get(channelKYC.Account__c).add(channelKYC.Product__c);
                }
            }
            
            //find opportunity with matching contact role = campaign member, and opp product is part of campaign product
            for(CampaignMember selectedCampaignMember : listNew){
                Set<Id> campaignProductSet = campaignProductMap.get(selectedCampaignMember.CampaignId);
                Set<Id> clonecampaignProductSet = new Set<Id>();
                if(campaignProductSet != null && !campaignProductSet.isEmpty()){
                    clonecampaignProductSet = campaignProductSet.clone();
                }
                Boolean hasExstOpp = false;
                if(accountIdOppMap != null && !accountIdOppMap.isEmpty()){
                    List<Opportunity> getOppList = new List<Opportunity>();
                    String accCampaignKeyStr = selectedCampaignMember.Contact_Account_Id__c + '_' + selectedCampaignMember.CampaignId;
                    for(String accCampKey : accountIdOppMap.keySet()){
                        if(accCampKey.contains(selectedCampaignMember.Contact_Account_Id__c)){ //if string contains account Id
                            List<Opportunity> opp1List = accountIdOppMap.get(accCampKey);
                            getOppList.addAll(opp1List);
                        }
                    }
                    
                    if(campOppMap.containsKey(accCampaignKeyStr)){
                        hasExstOpp = true;
                        clonecampaignProductSet = new Set<Id>();
                        for(Id oppId : campOppMap.get(accCampaignKeyStr)){
                            Boolean hasContactRole = false;
                            if(oppMap.containsKey(oppId)){
                                Opportunity selectedOpp = oppMap.get(oppId);
                                for(OpportunityContactRole contactRole : selectedOpp.OpportunityContactRoles){
                                    if(contactRole.ContactId == selectedCampaignMember.ContactId){
                                        hasContactRole = true;
                                    }
                                }
                                
                                if(!hasContactRole){
                                    //create opp contact role
                                    OpportunityContactRole tempOppContactRole = new OpportunityContactRole(ContactId = selectedCampaignMember.ContactId, OpportunityId = oppId);
                                    String ocrKey = oppId + '_' + selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId;
                                    oppContactRoleMap.put(ocrKey, tempOppContactRole);
                                    
                                    //insert campaign influence
                                    String campInflStr = selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId + '_' + oppId; //key : BID <> CampaignId_ContactId_OppId
                                    //bidCampaignInfluenceKeyMap = new Map<String, Set<String>>(); 
                                    if(!accIdCampaignInfluenceKeyMap.containsKey(selectedCampaignMember.Contact_Account_Id__c)){
                                        accIdCampaignInfluenceKeyMap.put(selectedCampaignMember.Contact_Account_Id__c, new Set<String>{campInflStr}); 
                                    }else{
                                        accIdCampaignInfluenceKeyMap.get(selectedCampaignMember.Contact_Account_Id__c).add(campInflStr);
                                    }
                                }
                            }
                        }
                    }
                    
                    system.debug('***clonecampaignProductSet: '+ clonecampaignProductSet);
                    if(!hasExstOpp){
                        for(Opportunity opp : getOppList){
                            Boolean hasContactRole = false;
                            Set<Id> existingProdInCmpProd = new Set<Id>();
                            
                            for(OpportunityContactRole contactRole : opp.OpportunityContactRoles){
                                if(contactRole.ContactId == selectedCampaignMember.ContactId){
                                    hasContactRole = true;
                                }
                            }
                            if(campaignProductSet != null && !campaignProductSet.isEmpty()){
                                for(Xendit_Opportunity_Product__c xOpp : opp.Xendit_Opportunity_Products_Channel__r){
                                    if(campaignProductSet.contains(xOpp.Rate_Card__r.Product__c)){
                                        existingProdInCmpProd.add(xOpp.Rate_Card__r.Product__c);
                                    }
                                }   
                            }
                            
                            //if opportunity with same contact role found
                            if(existingProdInCmpProd.size() > 0){
                                
                                //var to insert opp product in new opportunity
                                clonecampaignProductSet.removeAll(existingProdInCmpProd);
                                
                                if(hasContactRole){ //if same contact with campaign member found in contact role
                                    //insert campaign influence
                                    String campInflStr = selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId + '_' + opp.Id; //key : BID <> CampaignId_ContactId_OppId
                                    //bidCampaignInfluenceKeyMap = new Map<String, Set<String>>(); 
                                    if(!accIdCampaignInfluenceKeyMap.containsKey(selectedCampaignMember.Contact_Account_Id__c)){
                                        accIdCampaignInfluenceKeyMap.put(selectedCampaignMember.Contact_Account_Id__c, new Set<String>{campInflStr}); 
                                    }else{
                                        accIdCampaignInfluenceKeyMap.get(selectedCampaignMember.Contact_Account_Id__c).add(campInflStr);
                                    }
                                }
                            }
                            
                        }
                    }
                }
                system.debug('***clonecampaignProductSet: '+ clonecampaignProductSet);
                Set<Id> bidLiveProduct = accIdLiveProductMap.get(selectedCampaignMember.Contact_Account_Id__c);
                if(clonecampaignProductSet != null && !clonecampaignProductSet.isEmpty() && bidLiveProduct != null && !bidLiveProduct.isEmpty()){
                    clonecampaignProductSet = RemoveCampProdByChannelKYC(clonecampaignProductSet, bidLiveProduct,objective);
                }
                
                if(clonecampaignProductSet != null && !clonecampaignProductSet.isEmpty()){
                    Map<String, Set<Id>> tempCampProductMap = new Map<String, Set<Id>>();
                    if(!accIdOppProductMap.containsKey(selectedCampaignMember.Contact_Account_Id__c)){
                        tempCampProductMap.put(selectedCampaignMember.CampaignId, clonecampaignProductSet);
                        accIdOppProductMap.put(selectedCampaignMember.Contact_Account_Id__c, tempCampProductMap);
                    }else{
                        tempCampProductMap = accIdOppProductMap.get(selectedCampaignMember.Contact_Account_Id__c);
                        Set<Id> prodSet = new Set<Id>();
                        if(tempCampProductMap.containsKey(selectedCampaignMember.CampaignId)){
                            prodSet = tempCampProductMap.get(selectedCampaignMember.CampaignId);
                        }
                        prodSet.addAll(clonecampaignProductSet);
                        Map<String, Set<Id>> tempMap = new Map<String, Set<Id>>();
                        tempMap.put(selectedCampaignMember.CampaignId, prodSet);
                        accIdOppProductMap.put(selectedCampaignMember.Contact_Account_Id__c, tempMap);
                    }
                    
                    //insert campaign influence
                    String campInflStr = selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId;
                    //bidCampaignInfluenceKeyMap = new Map<String, Set<String>>(); 
                    if(!accIdCampaignInfluenceKeyMap.containsKey(selectedCampaignMember.Contact_Account_Id__c)){
                        accIdCampaignInfluenceKeyMap.put(selectedCampaignMember.Contact_Account_Id__c, new Set<String>{campInflStr}); //key : BID <> CampaignId_ContactId
                    }else{
                        accIdCampaignInfluenceKeyMap.get(selectedCampaignMember.Contact_Account_Id__c).add(campInflStr);
                    }
                    
                }
            }
            //if(accIdOppProductMap != null && !accIdOppProductMap.isEmpty()){
            //create opportunity with opp product
            system.debug('***accIdOppProductMap: '+accIdOppProductMap);
            system.debug('***accountIdContactMap: '+accountIdContactMap);
            system.debug('***accIdCampaignInfluenceKeyMap: '+accIdCampaignInfluenceKeyMap);
            system.debug('***oppContactRoleMap: '+oppContactRoleMap);
            system.debug('***objective: '+objective);
            System.enqueueJob(new CrossSellAutoCreateOppQueue(accIdOppProductMap, accountIdContactMap, accIdCampaignInfluenceKeyMap, oppContactRoleMap, objective));
            //}
        }
    }
    
    /*
Name : IsValidCrossSellUpsellAutoCreateOpp
Description : determine if campaign member is eligible to create auto opp - cross sell logic
*/
    public static boolean IsValidCrossSellUpsellAutoCreateOpp(CampaignMember member, Map<Id, CampaignMember> oldMap, Map<Id, Campaign> campaignMap, String objective){
        String autoCreateOppMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        CampaignMember oldRec = oldMap != null ? oldMap.get(member.Id) : null;
        Campaign selectedCampaign = campaignMap.get(member.CampaignId);
        Boolean isProgramCrossSellCampaign = (selectedCampaign != null && selectedCampaign.RecordType.Name == 'Program Campaign' && (selectedCampaign.Objective__c == objective));
        return (!String.isBlank(member.Contact_Account_Id__c) && (oldRec == null || (oldRec != null && oldRec.Status != member.Status)) && 
                isProgramCrossSellCampaign && member.Status == autoCreateOppMemberStatus && member.ContactId != null);
    }
    
    /*
Name : GetRelatedOpp
Description : get related opp to auto create opp - cross sell / upsell logic
*/
    public static List<Opportunity> GetRelatedOpp(Set<Id> accountIdSet, Set<Id> contactRoleOppId, String objective){
        List<String> oppType = new List<String>();
        List<Opportunity> oppList = new List<Opportunity>();
        oppType.add(objective);
        if(objective == 'Cross Sell'){
            oppType.add('New Acquisition');
        }
        
        if(!oppType.isEmpty()){
            oppList = [SELECT Id, Name, AccountId, Account.Business_Id__c, CampaignId, (SELECT ContactId, OpportunityId, Opportunity.Account.Business_Id__c FROM OpportunityContactRoles WHERE ContactId != NULL),
                       (SELECT Parent_Opportunity_Lookup__c, Opportunity__r.Account.Business_Id__c, Rate_Card__r.Product__c FROM Xendit_Opportunity_Products_Channel__r WHERE Rate_Card__r.Product__c != NULL)
                       FROM Opportunity WHERE (AccountId IN :accountIdSet OR Id IN :contactRoleOppId)
                       AND RecordType.Name = 'Parent Opportunity' 
                       AND (NOT StageName IN ('Closed Won','Closed Lost')) 
                       AND Type IN :oppType];
        }
        return oppList;
    }
    
    public static Set<Id> RemoveCampProdByChannelKYC(Set<Id> clonecampaignProductSet, Set<Id> bidLiveProduct, String objective){
        List<Id> clonecampaignProductList = new List<Id>();
        if(objective == 'Cross Sell'){
            clonecampaignProductSet.removeAll(bidLiveProduct);
            clonecampaignProductList = new List<Id>(clonecampaignProductSet);
        }else if(objective == 'Upsell'){
            List<Id> bidLiveProductList = new List<Id>(bidLiveProduct);
            clonecampaignProductList = new List<Id>(clonecampaignProductSet);
            for (Integer i = (clonecampaignProductList.size()-1) ; i>= 0 ; i--){
                if(!bidLiveProductList.contains(clonecampaignProductList[i])){ //if not included in channel kyc live products, remove from list
                    clonecampaignProductList.remove(i);
                }
            } 
        }
        
        return new Set<Id>(clonecampaignProductList);
    }
    
    
    /*
Name : AutoCreateOpportunity
Description : auto-create cross-sell opportunity
*/
    public static void AutoCreateOpportunity(Map<String, Map<String,Set<Id>>> accIdProductMap, Map<String, Set<Id>> accountIdContactMap, Map<String, Set<String>> accIdCampaignInfluenceKeyMap, Map<String, OpportunityContactRole> oppContactRoleMap, String objective){
        try{
            system.debug('AutoCreateOpportunity start');
            system.debug('***accIdProductMap : '+ accIdProductMap);
            system.debug('***accountIdContactMap : '+ accountIdContactMap);
            system.debug('***accIdCampaignInfluenceKeyMap : '+ accIdCampaignInfluenceKeyMap);
            system.debug('***oppContactRoleMap : '+ oppContactRoleMap);
            system.debug('***objective : '+ objective);
            List<Account> accountToUpdate = new List<Account>();
            Map<String, String> accCountryMap = new Map<String, String>();
            Map<String, Account> accountMap = new Map<String, Account>();
            Map<String, Double> defTPVMap = new Map<String, Double>();
            Map<String, CampaignInfluence> createCampaignInfluenceMap = new Map<String,CampaignInfluence>();
            List<Xendit_Opportunity_Product__c> createOppProductList = new List<Xendit_Opportunity_Product__c>();
            List<OpportunityContactRole> createOppContactRoleList = new List<OpportunityContactRole>();
            List<Id> parentIdList = new List<Id>();
            Set<String> accIdSet = new Set<String>();
            String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
            String defaultUserEmail = System.Label.DEFAULT_OWNER_EMAIL;
            Set<String> accIdWithNewOpp = new Set<String>();
            CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
            User defaultUser = [SELECT Id FROM User WHERE FederationIdentifier = :defaultUserEmail LIMIT 1];
            if(accIdProductMap != null && !accIdProductMap.isEmpty()){
                accIdSet.addAll(accIdProductMap.keySet());
            }
            
            if(accIdCampaignInfluenceKeyMap != null && !accIdCampaignInfluenceKeyMap.isEmpty()){
                accIdSet.addAll(accIdCampaignInfluenceKeyMap.keySet());
            }
            
            if(oppContactRoleMap != null && !oppContactRoleMap.isEmpty()){
                createOppContactRoleList.addAll(oppContactRoleMap.values());
            }
            
            //get related account
            for(Account acc : [SELECT Id, Customer_Folder_URL__c, Pipeline_Source__c, Business_Id__c, Country_of_HQ__c, BillingCountry, OwnerId, CurrencyIsoCode FROM Account WHERE Id IN :accIdSet]){
                accountMap.put(acc.Id, acc);
            }
            for(String accId : accountMap.keySet()){
                Account acc = accountMap.get(accId);
                String accCountry = acc.Country_of_HQ__c;
                system.debug('***Country HQ: '+ acc.Country_of_HQ__c);
                system.debug('***accId: '+ accId);
                if(!String.isBlank(acc.Country_of_HQ__c) || !String.isBlank(acc.BillingCountry)){
                    accCountry = !String.isBlank(acc.Country_of_HQ__c) ? acc.Country_of_HQ__c : acc.BillingCountry;
                }
                
                if(accIdProductMap != null && !accIdProductMap.isEmpty() && accIdProductMap.containsKey(accId)){
                    accCountryMap.put(acc.Id, accCountry);
                }
                system.debug('***accCountryMap: '+ accCountryMap);
            }
            
            if(!accCountryMap.isEmpty()){
                Map<String, Set<Id>> accDefaultProdMap = new Map<String, Set<Id>>();
                Map<String, Opportunity> accParentOppMap = new Map<String, Opportunity>();
                Map<Id, Opportunity> accChildOppMap = new Map<Id, Opportunity>();
                Map<String, Id> pbNameIdMap = new Map<String, Id>();
                Id parentOppRecTypeId = OpportunityHelper.getParentRecordTypeId();
                Id childOppRecTypeId = OpportunityHelper.getChildRecordTypeId();
                //get pricebook
                for(Xendit_Price_Book__c pb : [SELECT Id, Name FROM Xendit_Price_Book__c WHERE Active__c = TRUE]){
                    pbNameIdMap.put(pb.Name, pb.Id);
                }
                
                //get default TPV
                for(Channel_Default_TPV__c defTPV : [SELECT Id, Country__c, Expected_TPV__c, Rate_Card__c, Segment__c FROM Channel_Default_TPV__c WHERE Country__c IN :accCountryMap.values()]){
                    String defSegment = defTPV.Segment__c != null ? defTPV.Segment__c : 'Individual';
                    String defTPVKey = defTPV.Country__c + '_' + defSegment + '_' + defTPV.Rate_Card__c;
                    defTPVMap.put(defTPVKey, defTPV.Expected_TPV__c);
                }
                
                for(String accId : accCountryMap.keySet()){
                    //get country
                    Account accObj = accountMap.get(accId);
                    //get default prod set
                    
                    if(accIdProductMap.containsKey(accId)){
                        Map<String, Set<Id>> campProdMap = accIdProductMap.get(accId);
                        for(String campaignId : campProdMap.keySet()){
                            Set<Id> defaultProdSet = campProdMap.get(campaignId);
                            if(defaultProdSet != null && !defaultProdSet.isEmpty()){
                                accDefaultProdMap.put((accObj.Id + '_' + campaignId), defaultProdSet);
                                //create parent opp
                                Date estFirstTxnDate = Date.today() + 30;
                                Opportunity parentOpp = new Opportunity();
                                if (objective == 'Upsell') {
                                    parentOpp.Name = 'ParentOpp';
                                    parentOpp.Created_via_Campaign__c = true;
                                    parentOpp.RecordTypeId = parentOppRecTypeId; 
                                    parentOpp.AccountId = accObj.Id;
                                    parentOpp.OwnerId = defaultUser.Id; 
                                    parentOpp.CurrencyIsoCode = accObj.CurrencyIsoCode;
                                    parentOpp.CloseDate = estFirstTxnDate;
                                    parentOpp.Xst_Txn_Act_Date__c = estFirstTxnDate;
                                    //StageName = 'Qualification', 
                                    parentOpp.StageName = 'Contracting'; 
                                    parentOpp.Type = objective;
                                    parentOpp.CampaignId = campaignId;
                                    parentOpp.Pains_Priorities_and_Needs__c = 'PLEASE FILL UP';
                                    parentOpp.Has_Competitor__c = 'No';
                                    parentOpp.Sales_Goals_Plan__c = 'PLEASE FILL UP';
                                    parentOpp.Standard_Financial_Terms__c = 'Yes';
                                    parentOpp.Customer_Signed_Contract_URL__c = 'PLEASE FILL UP';
                                    parentOpp.Opportunity_Name_Remark__c = 'Generated by Campaign '+ campaignId;
                                    parentOpp.Next_Step_Blockers__c = 'PLEASE FILL UP';
                                    parentOpp.Pipeline_Source__c = accObj.Pipeline_Source__c;
                                } else {
                                    parentOpp.Name = 'ParentOpp';
                                    parentOpp.Created_via_Campaign__c = true;
                                    parentOpp.RecordTypeId = parentOppRecTypeId; 
                                    parentOpp.AccountId = accObj.Id;
                                    parentOpp.OwnerId = defaultUser.Id; 
                                    parentOpp.CurrencyIsoCode = accObj.CurrencyIsoCode;
                                    parentOpp.CloseDate = estFirstTxnDate;
                                    parentOpp.Xst_Txn_Act_Date__c = estFirstTxnDate;
                                    parentOpp.StageName = 'Qualification';
                                    parentOpp.Type = objective;
                                    parentOpp.CampaignId = campaignId;
                                    parentOpp.Pipeline_Source__c = accObj.Pipeline_Source__c;
                                }
                                
                                if (accObj.Customer_Folder_URL__c == null) {
                                    Account acc = new Account();
                                    acc.Id = accObj.Id;
                                    acc.Customer_Folder_URL__c = 'PLEASE FILL UP';
                                    accountToUpdate.add(acc);    
                                }
                                
                                accParentOppMap.put(accObj.Id + '_' + campaignId, parentOpp); 
                            }
                        }
                    }
                }
                
                if(!accParentOppMap.isEmpty()){
                    if (accountToUpdate.size() > 0) {
                        List<Database.Saveresult> accountUpdateResult = Database.update(accountToUpdate, false);
                    }
                    List<Database.Saveresult> parentInsertResults = Database.insert(accParentOppMap.values(), false);
                    //List<Id> parentIdList = new List<Id>();
                    for (Database.SaveResult sr : parentInsertResults) {
                        if (sr.isSuccess()) {
                            parentIdList.add(sr.getId());
                        }
                    }
                    
                    for(Opportunity opp : [SELECT AccountId, Id, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName, Account.Business_Id__c, Account.Brand__c, Account.BillingCountryCode, Opportunity_Name_Remark__c FROM Opportunity WHERE Id IN :parentIdList]){
                        String oppRemark = !String.isBlank(opp.Opportunity_Name_Remark__c) ? (' - ' + opp.Opportunity_Name_Remark__c) : '';
                        String oppName = opp.Account.Brand__c + ' - ' + opp.Account.BillingCountryCode + ' - New' + oppRemark;
                        Opportunity childOpp = new Opportunity(Name = oppName, Parent_Opportunity__c = opp.Id, RecordTypeId = childOppRecTypeId, AccountId = opp.AccountId, OwnerId = defaultUser.Id, CurrencyIsoCode = opp.CurrencyIsoCode, CloseDate = opp.Xst_Txn_Act_Date__c, Xst_Txn_Act_Date__c = opp.Xst_Txn_Act_Date__c, StageName = opp.StageName, Xendit_Price_Book__c = AccountHelper.getRelatedPriceBook(opp.CurrencyIsoCode, pbNameIdMap), Type = objective);
                        accChildOppMap.put(opp.AccountId, childOpp);
                        
                        if(accountIdContactMap.containsKey(opp.AccountId)){
                            for(Id contactId : accountIdContactMap.get(opp.AccountId)){
                                OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = contactId, OpportunityId = opp.Id);
                                createOppContactRoleList.add(oppContactRole);
                            }
                        }
                        
                        //create campaign influence
                        if(accIdCampaignInfluenceKeyMap != null && !accIdCampaignInfluenceKeyMap.isEmpty() && accIdCampaignInfluenceKeyMap.containsKey(opp.AccountId)){
                            accIdWithNewOpp.add(opp.AccountId);
                            Set<String> CampInflStr = accIdCampaignInfluenceKeyMap.get(opp.AccountId);
                            for(String CIStr : CampInflStr){
                                List<String> CampInflStrSet = CIStr.split('_');
                                if(CampInflStrSet.size() > 1 && defaultModel != null){
                                    String oppId = (CampInflStrSet.size() == 3) ? CampInflStrSet[2] : opp.Id; //campaignId_ContactId_OppId
                                    String externalId = (CampInflStrSet.size() == 3) ? (CIStr + '_' + defaultModel.Id) : (CIStr + '_' + opp.Id + '_' + defaultModel.Id); 
                                        CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = CampInflStrSet[0], ContactId = CampInflStrSet[1], OpportunityId = oppId, ModelId = defaultModel.Id, External_Id__c = externalId);
                                    createCampaignInfluenceMap.put(externalId, createCampInfl);
                                }
                            }
                        }
                    }
                    
                    if(!accChildOppMap.isEmpty()){
                        List<Database.Saveresult> childInsertResults = Database.insert(accChildOppMap.values(), false);
                        List<Id> childIdList = new List<Id>();
                        Set<Id> allDefaultProdSet = new Set<Id>();
                        for (Database.SaveResult sr : childInsertResults) {
                            if (sr.isSuccess()) {
                                childIdList.add(sr.getId());
                            }
                        }
                        
                        //get rate card query
                        for(String accCampaignStr : accDefaultProdMap.keySet()){
                            allDefaultProdSet.addAll(accDefaultProdMap.get(accCampaignStr));
                        }
                        
                        List<Rate_Card__c> rcList = [SELECT Id, Product__c, Xendit_Price_Book__c, Basket_Size_Threshold__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, CurrencyIsoCode, 
                                                     Fixed_Rate__c, Reseller_Rate_per_TPV__c, Reseller_Rate_per_Txn__c, Rate_Per_TPV__c,Rate_Per_Txn__c, Rate_Per_Event__c, Rate_Per_Subaccount__c, 
                                                     Product__r.Basket_Size_Enterprise__c, Product__r.Basket_Size_Individuals__c, Product__r.Basket_Size_MM__c, Product__r.Basket_Size_SME__c, Brand__c, Channel__c 
                                                     FROM Rate_Card__c WHERE Product__c IN :allDefaultProdSet];
                        
                        for(Opportunity opp : [SELECT AccountId, Parent_Opportunity__r.CampaignId, Account.Business_Id__c, Id, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName, Xendit_Price_Book__c, Account.Segment__c, Account.Industry_Category__c FROM Opportunity WHERE Id IN :childIdList]){
                            //get filtered rate card
                            List<Rate_Card__c> filteredRCList = AccountHelper.getFilteredRateCard(opp.Xendit_Price_Book__c, accDefaultProdMap.get(opp.AccountId + '_' + opp.Parent_Opportunity__r.CampaignId), rcList);
                            if(!filteredRCList.isEmpty()){
                                for(Rate_Card__c rct : filteredRCList){
                                    String defSegment = opp.Account.Segment__c != null ? opp.Account.Segment__c : 'Individual';
                                    String cty = accCountryMap.get(opp.AccountId);
                                    String defTPVKey = cty + '_' + defSegment + '_' + rct.Id;
                                    Double getDefTPV = defTPVMap.containsKey(defTPVKey) ? defTPVMap.get(defTPVKey) : 0;
                                    Xendit_Opportunity_Product__c createxOpp = new Xendit_Opportunity_Product__c(From_Lead_Conversion__c = true, Opportunity__c = opp.Id, Product__c = rct.Product__c, Rate_Card__c = rct.Id, TPV__c = getDefTPV);
                                    createOppProductList.add(createxOpp);
                                }
                            }
                        }
                        
                        if(!createOppProductList.isEmpty()){
                            Database.insert(createOppProductList, false);
                            XenditOppProductHelper.updateChildOppName(createOppProductList);
                        }
                    }
                }
            }
            
            if(accIdCampaignInfluenceKeyMap != null && !accIdCampaignInfluenceKeyMap.isEmpty()){
                for(String accCI : accIdCampaignInfluenceKeyMap.keySet()){
                    if(!accIdWithNewOpp.contains(accCI)){
                        Set<String> CampInflStr = accIdCampaignInfluenceKeyMap.get(accCI);
                        for(String CIStr : CampInflStr){
                            List<String> CampInflStrSet = CIStr.split('_');
                            if(CampInflStrSet.size() > 2 && defaultModel != null){
                                CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = CampInflStrSet[0], ContactId = CampInflStrSet[1], OpportunityId = CampInflStrSet[2], ModelId = defaultModel.Id, External_Id__c = (CIStr + '_' + defaultModel.Id));
                                createCampaignInfluenceMap.put(createCampInfl.External_Id__c, createCampInfl);
                            }
                        }
                    }
                }
            }
            
            if(!createOppContactRoleList.isEmpty()){
                Database.insert(createOppContactRoleList, false);
            }
            
            if(!createCampaignInfluenceMap.isEmpty()){
                List<CampaignInfluence> createCampaignInfluenceList = createCampaignInfluenceMap.values();
                Set<String> exstCampaignInfluenceExtIdSet = new Set<String>();
                for(CampaignInfluence ci : [SELECT Id, External_Id__c FROM CampaignInfluence WHERE External_Id__c IN :createCampaignInfluenceMap.keySet()]){
                    exstCampaignInfluenceExtIdSet.add(ci.External_Id__c);
                }
                
                if(!exstCampaignInfluenceExtIdSet.isEmpty()){
                    for (Integer i = (createCampaignInfluenceList.size()-1) ; i>= 0 ; i--){
                        CampaignInfluence ci = createCampaignInfluenceList[i];
                        if(exstCampaignInfluenceExtIdSet.contains(ci.External_Id__c)){
                            createCampaignInfluenceList.remove(i);
                        }
                    } 
                }
                
                if(createCampaignInfluenceList != null && !createCampaignInfluenceList.isEmpty()){
                    Database.insert(createCampaignInfluenceList, false);
                    //UpdateCampaignInfluencePercentage(createCampaignInfluenceList);
                }
            }
            
            system.debug('***Success Opp: '+ parentIdList);
            if (parentIdList.size() > 0) {
                system.debug('***Start Upsell Calculation from Campaign');
                List<Opportunity> newCreatedOpportunities = [SELECT Id, Name, Type, StageName, Created_via_Campaign__c, Upsell_Opportunity_Revenue_Goal__c, Addressable_Merchant_Revenue_Monthly_USD__c, RecordTypeId FROM Opportunity WHERE Id IN :parentIdList];
                OpportunityHelper.getUpsellRevenueGoalValue(newCreatedOpportunities, null, 'Campaign');
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignMemberHelper','CampaignMember', 'AutoCreateOpportunity', 'CampaignMemberTrigger',  e);
        }
    }
    /*
Name : TacticCampaignMemberDataUpdate 
Description : automation on tactic campaign member data update : 
1. auto-update campaign member in Program Campaign (Parent) when Tactic Campaign's campaign member status updated
*/
    public static void TacticCampaignMemberDataUpdate(List<CampaignMember> listNew, Map<Id, CampaignMember> oldMap, System.TriggerOperation operationType){
        try{
            Set<Id> campaignIdSet = new Set<Id>();
            Set<Id> tacticProgMasterCampaignIdSet = new Set<Id>();
            Set<Id> leadContIdSet = new Set<Id>();
            Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
            Map<Id, CampaignMember> campaignMemberMap = new Map<Id, CampaignMember>();
            Map<Id, Set<Id>> campMemberNotRespondedMap = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> allCampLeadContMemberMap = new Map<Id, Set<Id>>();
            Map<String, Set<Id>> allCampContactCampMemberIdMap = new Map<String, Set<Id>>();
            Map<String, Set<Id>> campLeadContMemberMap = new Map<String, Set<Id>>();
            List<CampaignMember> campMemberList = new List<CampaignMember>();
            String tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
            String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            String masterCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
            String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
            for(CampaignMember member : listNew){
                if(member.CampaignId != null){
                    campaignIdSet.add(member.CampaignId);
                }
                
                if(member.ContactId != null){
                    leadContIdSet.add(member.ContactId);
                }else if(member.LeadId != null){
                    leadContIdSet.add(member.LeadId);
                }
            }
            
            for(Campaign campaignObj : [SELECT Id, RecordTypeId, Objective__c, ParentId, Parent.RecordTypeId, Parent.ParentId, Parent.Parent.RecordTypeId FROM Campaign WHERE Id IN :campaignIdSet]){
                campaignMap.put(campaignObj.Id, campaignObj);
                if(campaignObj.RecordTypeId == tacticCampaignRT){ //tactic campaign
                    tacticProgMasterCampaignIdSet.add(campaignObj.Id);
                }
                
                if(campaignObj.ParentId != null && campaignObj.Parent.RecordTypeId == programCampaignRT){ //program campaign
                    tacticProgMasterCampaignIdSet.add(campaignObj.ParentId);
                }
                
                if(campaignObj.Parent.ParentId != null && campaignObj.Parent.Parent.RecordTypeId == masterCampaignRT){ //master campaign
                    tacticProgMasterCampaignIdSet.add(campaignObj.Parent.ParentId);
                }
            }
            
            if(tacticProgMasterCampaignIdSet != null && !tacticProgMasterCampaignIdSet.isEmpty()){
                campMemberList = [SELECT Id, Status, CampaignId, HasResponded, LeadId, ContactId FROM CampaignMember WHERE LeadOrContactId IN :leadContIdSet AND CampaignId IN :tacticProgMasterCampaignIdSet];
                for(CampaignMember campMember : campMemberList){
                    Id leadOrContactId = campMember.ContactId != null ? campMember.ContactId : campMember.LeadId;
                    String campLeadContactKey = campMember.CampaignId + '_' + leadOrContactId;
                    if(!allCampLeadContMemberMap.containsKey(campMember.CampaignId)){
                        allCampLeadContMemberMap.put(campMember.CampaignId, new Set<Id>{leadOrContactId});
                    }else{
                        allCampLeadContMemberMap.get(campMember.CampaignId).add(leadOrContactId);
                    }
                    
                    if(!allCampContactCampMemberIdMap.containsKey(campLeadContactKey)){
                        allCampContactCampMemberIdMap.put(campLeadContactKey, new Set<Id>{campMember.Id});
                    }else{
                        allCampContactCampMemberIdMap.get(campLeadContactKey).add(campMember.Id);
                    }
                    
                    if(!campMember.HasResponded && campMember.Status != autoUpdateCampaignMemberStatus){
                        if(!campMemberNotRespondedMap.containsKey(campMember.CampaignId)){
                            campMemberNotRespondedMap.put(campMember.CampaignId, new Set<Id>{leadOrContactId});
                        }else{
                            campMemberNotRespondedMap.get(campMember.CampaignId).add(leadOrContactId);
                        }
                        
                        if(!campLeadContMemberMap.containsKey(campLeadContactKey)){
                            campLeadContMemberMap.put(campLeadContactKey, new Set<Id>{campMember.Id});
                        }else{
                            campLeadContMemberMap.get(campLeadContactKey).add(campMember.Id);
                        }
                    }
                }
            }
            
            
            switch on operationType{
                when AFTER_INSERT{
                    AddTacticCampaignMember(listNew, allCampLeadContMemberMap, allCampContactCampMemberIdMap, campaignMap);
                    UpdateProgramCampaignMemberToTacticEngaged(listNew, oldMap, campaignMap, campMemberNotRespondedMap, campLeadContMemberMap);
                }   
                when AFTER_UPDATE{
                    UpdateProgramCampaignMemberToTacticEngaged(listNew, oldMap, campaignMap, campMemberNotRespondedMap, campLeadContMemberMap);
                }  
            }
            
            
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignMemberHelper','CampaignMember', 'TacticCampaignMemberDataUpdate', 'CampaignMemberTrigger',  e);
        }
    }
    
    /*
Name : UpdateProgramCampaignMemberToTacticEngaged 
Description : auto-update campaign member in Program Campaign (Parent) when Tactic Campaign's campaign member status updated
*/
    public static void UpdateProgramCampaignMemberToTacticEngaged(List<CampaignMember> listNew, Map<Id, CampaignMember> oldMap, Map<Id, Campaign> campaignMap, Map<Id, Set<Id>> campMemberNotRespondedMap, Map<String, Set<Id>> campLeadContMemberMap){
        try{
            String tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
            String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
            Map<Id, CampaignMember> updateCampaignMemberMap = new Map<Id, CampaignMember>();
            for(CampaignMember member : listNew){
                CampaignMember oldRec = oldMap != null ? oldMap.get(member.Id) : null;
                Campaign selectedCampaign = campaignMap.get(member.CampaignId);
                Boolean isTacticCampaign = false;
                Boolean isParentProgramCampaign = false;
                Boolean isRespondedStatus = false;
                
                isTacticCampaign = selectedCampaign.RecordTypeId == tacticCampaignRT;
                isParentProgramCampaign = selectedCampaign.ParentId != NULL && selectedCampaign.Parent.RecordTypeId == programCampaignRT;
                isRespondedStatus = member.HasResponded && member.Status != selectedCampaign.Objective__c;
                
                if((oldRec == null || (oldRec != null && oldRec.Status != member.Status)) && isTacticCampaign && isParentProgramCampaign && isRespondedStatus){
                    //check if there's program campaign member hasn't responded and NOT Tactic Engaged
                    Set<Id> notRespondedLeadOrContIdSet = campMemberNotRespondedMap.get(selectedCampaign.ParentId);
                    
                    //if there is campaign member hasn't responded with the same lead / contact id
                    Id leadOrContactId = member.ContactId != null ? member.ContactId : member.LeadId;
                    if(notRespondedLeadOrContIdSet != null && !notRespondedLeadOrContIdSet.isEmpty() && notRespondedLeadOrContIdSet.contains(leadOrContactId)){
                        //get related campaign member Id
                        String campLeadContactKey = selectedCampaign.ParentId + '_' + leadOrContactId;
                        if(campLeadContMemberMap.containsKey(campLeadContactKey)){
                            for(Id campMemberId : campLeadContMemberMap.get(campLeadContactKey)){
                                updateCampaignMemberMap.put(campMemberId, new CampaignMember(Id = campMemberId, CampaignId = selectedCampaign.ParentId, Status = autoUpdateCampaignMemberStatus));
                            }
                        }
                    }
                }
            }
            
            if(!updateCampaignMemberMap.isEmpty()){
                Set<Id> selectedCampaignIdSet = new Set<Id>();
                Set<Id> campaignWithTacticEngStatusSet = new Set<Id>();
                Set<Id> campaignToAddStatusSet = new Set<Id>();
                for(CampaignMember cm : updateCampaignMemberMap.values()){
                    selectedCampaignIdSet.add(cm.CampaignId);
                }
                
                for(CampaignMemberStatus cmStatus : [SELECT Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :selectedCampaignIdSet AND Label = :autoUpdateCampaignMemberStatus]){
                    campaignWithTacticEngStatusSet.add(cmStatus.CampaignId);
                }
                
                for(CampaignMember cm : updateCampaignMemberMap.values()){
                    if(campaignWithTacticEngStatusSet.isEmpty() || (!campaignWithTacticEngStatusSet.isEmpty() && !campaignWithTacticEngStatusSet.contains(cm.CampaignId))){
                        campaignToAddStatusSet.add(cm.CampaignId);
                    }
                }
                
                if(!campaignToAddStatusSet.isEmpty()){
                    List<CampaignMemberStatus> createnewStatusList = new List<CampaignMemberStatus>();
                    for(Id cmpId : campaignToAddStatusSet){
                        createnewStatusList.add(new CampaignMemberStatus(CampaignId = cmpId, Label = autoUpdateCampaignMemberStatus, HasResponded = TRUE));
                    }
                    
                    insert createnewStatusList;
                }
                
                update updateCampaignMemberMap.values();
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignMemberHelper','CampaignMember', 'UpdateProgramCampaignMemberToTacticEngaged', 'CampaignMemberTrigger',  e);
        }
    }
    
    /*
Name : AddTacticCampaignMember
Description : auto-insert campaign member to program & master campaign when tactic campaign member created
*/
    public static void AddTacticCampaignMember(List<CampaignMember> listNew, Map<Id, Set<Id>> allCampLeadContMemberMap, Map<String, Set<Id>> allCampContactCampMemberIdMap, Map<Id, Campaign> campaignMap){
        try{
            Set<String> tacticLeadOrContactIdSet = new Set<String>();
            String tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
            String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            String masterCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
            Map<String, CampaignMember> insertCampaignMemberMap = new Map<String, CampaignMember>();
            
            for(String strkey : allCampContactCampMemberIdMap.keySet()){
            }
            for(CampaignMember member : listNew){
                Campaign selectedCampaign = campaignMap.containsKey(member.CampaignId) ? campaignMap.get(member.CampaignId) : null;
                if(selectedCampaign != null){
                    if(selectedCampaign.RecordTypeId == tacticCampaignRT){
                        String tacticLeadOrContactId = member.ContactId != null ? member.ContactId : member.LeadId;
                        
                        if(selectedCampaign.ParentId != null && selectedCampaign.Parent.RecordTypeId == programCampaignRT){
                            String progKey = selectedCampaign.ParentId + '_' + tacticLeadOrContactId;
                            Set<Id> exstCampMemberIdSet = allCampContactCampMemberIdMap.containsKey(progKey) ? allCampContactCampMemberIdMap.get(progKey) : null;
                            Set<Id> leadContMemberSet = allCampLeadContMemberMap.containsKey(selectedCampaign.ParentId) ? allCampLeadContMemberMap.get(selectedCampaign.ParentId) : new Set<Id>();
                            if(exstCampMemberIdSet == null && (leadContMemberSet.isEmpty() || (!leadContMemberSet.isEmpty() && !leadContMemberSet.contains(tacticLeadOrContactId))) ){
                                insertCampaignMemberMap.put(progKey, new CampaignMember(CampaignId = selectedCampaign.ParentId, LeadId = member.LeadId, ContactId = member.ContactId));
                            }
                        }
                        
                        if(selectedCampaign.Parent.ParentId != null && selectedCampaign.Parent.Parent.RecordTypeId == masterCampaignRT){
                            String masterKey = selectedCampaign.Parent.ParentId + '_' + tacticLeadOrContactId;
                            Set<Id> exstCampMemberIdSet = allCampContactCampMemberIdMap.containsKey(masterKey) ? allCampContactCampMemberIdMap.get(masterKey) : null;
                            Set<Id> leadContMemberSet = allCampLeadContMemberMap.containsKey(selectedCampaign.Parent.ParentId) ? allCampLeadContMemberMap.get(selectedCampaign.Parent.ParentId) : new Set<Id>();
                            if(exstCampMemberIdSet == null && (leadContMemberSet.isEmpty() || (!leadContMemberSet.isEmpty() && !leadContMemberSet.contains(tacticLeadOrContactId))) ){
                                insertCampaignMemberMap.put(masterKey, new CampaignMember(CampaignId = selectedCampaign.Parent.ParentId, LeadId = member.LeadId, ContactId = member.ContactId));
                            }
                        }
                    }
                } 
            }
            
            if(!insertCampaignMemberMap.isEmpty()){
                insert insertCampaignMemberMap.values();
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignMemberHelper','CampaignMember', 'AddTacticCampaignMember', 'CampaignMemberTrigger',  e);
        }
    }
    
    /*
Name : DeleteTacticCampaignMember
Description : auto-delete campaign member to program & master campaign when tactic campaign member deleted
*/
    public static void DeleteTacticCampaignMember(List<CampaignMember> listOld){
        try{
            String tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
            String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            String masterCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
            Set<Id> tacticProgLeadOrContIdSet = new Set<Id>();
            Set<Id> parentCampIdSet = new Set<Id>();
            Set<Id> campaignIdSet = new Set<Id>();
            Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
            Map<Id, Map<String, Set<Id>>> parentCampMemberIdMap = new Map<Id, Map<String, Set<Id>>>();
            Map<String, Set<Id>> allCampContactCampMemberIdMap = new Map<String, Set<Id>>();
            List<CampaignMember> deletedCampaignMemberList = new List<CampaignMember>();
            Map<Id, CampaignMember> deleteParentCampaignMemberMap = new Map<Id, CampaignMember>();
            
            for(CampaignMember member : listOld){
                if(member.CampaignId != null){
                    campaignIdSet.add(member.CampaignId);
                }
            }
            
            for(Campaign campaignObj : [SELECT Id, RecordTypeId, Objective__c, ParentId, Parent.RecordTypeId, Parent.ParentId, Parent.Parent.RecordTypeId FROM Campaign WHERE Id IN :campaignIdSet]){
                campaignMap.put(campaignObj.Id, campaignObj);
            }
            
            for(CampaignMember member : listOld){
                Campaign selectedCampaign = campaignMap.containsKey(member.CampaignId) ? campaignMap.get(member.CampaignId) : null;
                if(selectedCampaign != null && (selectedCampaign.RecordTypeId == tacticCampaignRT || selectedCampaign.RecordTypeId == programCampaignRT)){
                    deletedCampaignMemberList.add(member);
                    Id leadOrContactId = member.ContactId != null ? member.ContactId : member.LeadId;
                    tacticProgLeadOrContIdSet.add(leadOrContactId);
                    if(selectedCampaign.ParentId != null){
                        parentCampIdSet.add(selectedCampaign.ParentId);
                    }    
                }
            }
            
            
            if(!tacticProgLeadOrContIdSet.isEmpty() && !parentCampIdSet.isEmpty()){
                //get related campaign member with the same parent
                for(CampaignMember cm : [SELECT Id, LeadId, ContactId, CampaignId, Campaign.RecordTypeId, Campaign.ParentId, Campaign.Parent.RecordTypeId FROM CampaignMember WHERE LeadOrContactId IN :tacticProgLeadOrContIdSet AND (CampaignId IN :parentCampIdSet OR Campaign.ParentId IN :parentCampIdSet)]){
                    Id leadOrContactId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
                    String campLeadContactKey = cm.CampaignId + '_' + leadOrContactId;
                    
                    if(!allCampContactCampMemberIdMap.containsKey(campLeadContactKey)){
                        allCampContactCampMemberIdMap.put(campLeadContactKey, new Set<Id>{cm.Id});
                    }else{
                        allCampContactCampMemberIdMap.get(campLeadContactKey).add(cm.Id);
                    }
                    
                    if(cm.Campaign.ParentId != null){
                        Map<String, Set<Id>> keyCMIdMap = new Map<String, Set<Id>>();
                        Set<Id> cmIdSet = new Set<Id>();
                        String cmKey = cm.Campaign.ParentId + '_' + leadOrContactId;
                        if(parentCampMemberIdMap.containsKey(cm.campaign.ParentId)){
                            keyCMIdMap = parentCampMemberIdMap.get(cm.campaign.ParentId);
                            if(keyCMIdMap.containsKey(cmKey)){
                                cmIdSet = keyCMIdMap.get(cmKey);
                            }
                        }
                        cmIdSet.add(cm.Id);
                        keyCMIdMap.put(cmKey, cmIdSet);
                        parentCampMemberIdMap.put(cm.Campaign.ParentId, keyCMIdMap);
                    }
                }
                
                for(CampaignMember cm : deletedCampaignMemberList){
                    Campaign selectedCampaign = campaignMap.containsKey(cm.CampaignId) ? campaignMap.get(cm.CampaignId) : null;
                    if(selectedCampaign.ParentId != null){
                        Id leadOrContactId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
                        String cmKey = selectedCampaign.ParentId + '_' + leadOrContactId;
                        
                        if(parentCampMemberIdMap.containsKey(selectedCampaign.ParentId)){
                            Map<String, Set<Id>> keyCMIdMap = parentCampMemberIdMap.get(selectedCampaign.ParentId);
                            if(keyCMIdMap.containsKey(cmKey)){ //if existing related lead / contact id in other tactic campaign under the same parent campaign
                                //do nothing
                            }else{
                                //check parent campaign with the same key
                                if(allCampContactCampMemberIdMap.containsKey(cmKey)){
                                    Set<Id> cmToDelete = allCampContactCampMemberIdMap.get(cmKey);
                                    for(Id cmid : cmToDelete){
                                        deleteParentCampaignMemberMap.put(cmid, new CampaignMember(Id = cmid));
                                    }
                                }
                            }
                        }else{
                            //check parent campaign with the same key
                            if(allCampContactCampMemberIdMap.containsKey(cmKey)){
                                Set<Id> cmToDelete = allCampContactCampMemberIdMap.get(cmKey);
                                for(Id cmid : cmToDelete){
                                    deleteParentCampaignMemberMap.put(cmid, new CampaignMember(Id = cmid));
                                }
                            }
                        }
                    }
                }
                
                if(!deleteParentCampaignMemberMap.isEmpty()){
                    delete deleteParentCampaignMemberMap.values();
                }
            }
            
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignMemberHelper','CampaignMember', 'DeleteTacticCampaignMember', 'CampaignMemberTrigger',  e);
        }
    }
    
    public static void cascadeDownProgramCampaignMemberStatus(List<CampaignMember> listNewCampaignMember, Map<Id, CampaignMember> oldCampaignMemberMap){
        Set<Id> campaignIds = new Set<Id>();
        for (CampaignMember cm : listNewCampaignMember) {
            CampaignMember oldCm = oldCampaignMemberMap.get(cm.Id);
            if (oldCm.Status != null && cm.Status != oldCm.Status) {
                campaignIds.add(cm.campaignId);
            }
        }
        
        //Only run if there are field changes
        if (campaignIds.size() > 0) {
            Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
            Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            Map<Id, Campaign> mapCampaignById = new Map<Id, Campaign>([SELECT Id, RecordTypeId, Status, Offer_Type__c, Objective__c FROM Campaign WHERE Id IN :campaignIds AND RecordTypeId = :programRecordTypeId]);
            
            //Get campaign member status mapping
            Map<String, Default_Campaign_Member_Status__mdt> mapMemberObjectiveStatus = new Map<String, Default_Campaign_Member_Status__mdt>();
            for (Default_Campaign_Member_Status__mdt defCmStatus : [SELECT Id, Campaign_Hierarchy__c, Responded_Status__c, Objective__c, Offer_Type__c, Tactics_Type__c, Objective_Status__c FROM Default_Campaign_Member_Status__mdt WHERE Objective_Status__c != NULL]) {
                String mapKey = defCmStatus.Offer_Type__c + '_' + defCmStatus.Objective_Status__c;
                mapMemberObjectiveStatus.put(mapKey, defCmStatus);
            }
            
            //Filter campaign member to be processed and map status by member whoId
            campaignIds.clear();
            Set<Id> memberWhoIds = new Set<Id>();
            Map<String, String> mapProgramMemberStatuses = new Map<String, String>();
            Map<String, String> mapStatusByCampaignId = new Map<String, String>();
            for (CampaignMember cm : listnewCampaignMember) {
                CampaignMember oldCm = oldCampaignMemberMap.get(cm.Id);
                if (mapCampaignById != null && mapCampaignById.get(cm.CampaignId) != null) {
                    Campaign relatedCampaign = mapCampaignById.get(cm.CampaignId);
                    String mapKey = relatedCampaign.Offer_Type__c + '_' + cm.Status;
                    system.debug('***Map Key: '+ mapKey);
                    if (mapMemberObjectiveStatus != null && mapMemberObjectiveStatus.get(mapKey) != null) {
                        campaignIds.add(cm.CampaignId);
                        mapStatusByCampaignId.put(cm.CampaignId, cm.Status);
                        if (cm.LeadId != null) {
                            memberWhoIds.add(cm.LeadId);
                            mapProgramMemberStatuses.put(cm.LeadId, cm.Status);
                        }
                        if (cm.ContactId != null) {
                            memberWhoIds.add(cm.ContactId);
                            mapProgramMemberStatuses.put(cm.ContactId, cm.Status);
                        }
                        if (cm.AccountId != null) {
                            memberWhoIds.add(cm.AccountId);
                            mapProgramMemberStatuses.put(cm.AccountId, cm.Status);
                        }
                    }
                }
            }
            
            //Get tactic member
            List<CampaignMemberStatus> childCampaignStatusesToInsert = new List<CampaignMemberStatus>();
            List<CampaignMember> childMemberToUpdate = new List<CampaignMember>();
            List<CampaignMember> childMembers = [SELECT Id, Type, Status, CampaignId, Campaign.ParentId, LeadId, ContactId, AccountId FROM CampaignMember WHERE Campaign.ParentId IN :campaignIds AND Status = 'Tactic Engaged' AND (LeadId IN :memberWhoIds OR ContactId IN :memberWhoIds OR AccountId IN :memberWhoIds)];
            
            Set<Id> tacticCampaignIds = new Set<Id>();
            for (CampaignMember cm : childMembers) {    
                tacticCampaignIds.add(cm.CampaignId);
            }
            
            //Get tactic campaign existing statuses
            Map<String, String> mapExistingCampaignStatuses = new Map<String, String>();
            if (tacticCampaignIds.size() > 0) {
                for (CampaignMemberStatus cms : [SELECT Id, Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :tacticCampaignIds]) {
                    if(mapExistingCampaignStatuses.containsKey(cms.CampaignId)) {
                        String conStatuses = mapExistingCampaignStatuses.get(cms.CampaignId) + ';' + cms.Label;
                        mapExistingCampaignStatuses.put(cms.CampaignId, conStatuses);
                    } else {
                        mapExistingCampaignStatuses.put(cms.CampaignId, cms.Label);
                    }
                }
            }
            
            for (CampaignMember cm : childMembers) {
                String memberType = cm.Type;
                String memberWhoId = memberType == 'Lead' ? cm.LeadId : memberType == 'Account' ? cm.AccountId : memberType == 'Contact' ? cm.ContactId : null;
                system.debug('***Type: '+ memberType);
                system.debug('***WhoId: '+ memberWhoId);
                system.debug('***mapExistingCampaignStatuses: '+ mapExistingCampaignStatuses);
                system.debug('***mapProgramMemberStatuses: '+ mapProgramMemberStatuses);
                if (memberWhoId != null && memberWhoId != '') {
                    //Compare existing statuses with new status
                    String existingStatuses = mapExistingCampaignStatuses.get(cm.CampaignId);
                    String newStatus = mapProgramMemberStatuses.get(memberWhoId);
                    //If status already exist, just update
                    if (existingStatuses.contains(newStatus) && newStatus != cm.Status) {
                        cm.Status = newStatus;
                        childMemberToUpdate.add(cm);
                    } else { //Else insert new campaign status, copy from program objective status
                        CampaignMemberStatus newCms = new CampaignMemberStatus();
                        newCms.Label = newStatus;
                        newCms.CampaignId = cm.CampaignId;
                        childCampaignStatusesToInsert.add(newCms);
                        
                        cm.Status = newStatus;
                        childMemberToUpdate.add(cm);
                    }
                }
            }
            
            if (childCampaignStatusesToInsert.size() > 0) {
                insert childCampaignStatusesToInsert;
            }
            
            if (childMemberToUpdate.size() > 0) {
                update childMemberToUpdate;
            }
        }
    }
    
    public static void rollUpTacticEngagedCampaignMemberStatus(List<CampaignMember> listNewCampaignMember, Map<Id, CampaignMember> oldCampaignMemberMap){
        String tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        List<CampaignMember> programMemberToUpdate = new List<CampaignMember>();
        List<CampaignMemberStatus> programCampaignStatusesToInsert = new List<CampaignMemberStatus>();
        Set<Id> tacticCampaignIds = new Set<Id>();
        Set<Id> tacticWhoIds = new Set<Id>();
        Map<String, String> mapTacticStatusByWhoId = new Map<String, String>();
        for (CampaignMember cm : listNewCampaignMember) {
            if (cm.Campaign_Record_Type__c == tacticRecordTypeId && (cm.Status == 'Tactic Engaged' || cm.HasResponded)) {
                tacticCampaignIds.add(cm.CampaignId);
                if (cm.LeadId != null) {
                    tacticWhoIds.add(cm.LeadId);
                    mapTacticStatusByWhoId.put(cm.LeadId, cm.Status);
                }
                if (cm.ContactId != null) {
                    tacticWhoIds.add(cm.ContactId);
                    mapTacticStatusByWhoId.put(cm.ContactId, cm.Status);
                }
                if (cm.AccountId != null) {
                    tacticWhoIds.add(cm.AccountId);
                    mapTacticStatusByWhoId.put(cm.AccountId, cm.Status);
                }
            }
        }
        
        if (tacticCampaignIds.size() > 0) {
            Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            Set<Id> programCampaignIds = new Set<Id>();
            for (Campaign cmp : [SELECT Id, ParentId FROM Campaign WHERE Id IN :tacticCampaignIds AND RecordTypeId = :tacticRecordTypeId AND Parent.RecordTypeId = :programRecordTypeId]) {
                programCampaignIds.add(cmp.ParentId);
            }
            
            //Get program campaign existing statuses
            if (programCampaignIds.size() > 0) {
                Map<String, String> mapExistingCampaignStatuses = new Map<String, String>();
                for (CampaignMemberStatus cms : [SELECT Id, Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :programCampaignIds]) {
                    if(mapExistingCampaignStatuses.containsKey(cms.CampaignId)) {
                        String conStatuses = mapExistingCampaignStatuses.get(cms.CampaignId) + ';' + cms.Label;
                        mapExistingCampaignStatuses.put(cms.CampaignId, conStatuses);
                    } else {
                        mapExistingCampaignStatuses.put(cms.CampaignId, cms.Label);
                    }
                }
                
                for (CampaignMember cm : [SELECT Id, CampaignId, Status, LeadId, AccountId, ContactId, Type FROM CampaignMember WHERE CampaignId IN :programCampaignIds AND Status != 'Tactic Engaged' AND (LeadId IN :tacticWhoIds OR AccountId IN :tacticWhoIds OR ContactId IN :tacticWhoIds)]) {
                    String memberType = cm.Type;
                    String memberWhoId = memberType == 'Lead' ? cm.LeadId : memberType == 'Account' ? cm.AccountId : memberType == 'Contact' ? cm.ContactId : null;
                    system.debug('***Type: '+ memberType);
                    system.debug('***WhoId: '+ memberWhoId);
                    system.debug('***mapExistingCampaignStatuses: '+ mapExistingCampaignStatuses);
                    system.debug('***mapTacticStatusByWhoId: '+ mapTacticStatusByWhoId);
                    if (memberWhoId != null && memberWhoId != '') {
                        //Compare existing statuses with new status
                        String existingStatuses = mapExistingCampaignStatuses.get(cm.CampaignId);
                        String newStatus = mapTacticStatusByWhoId.get(memberWhoId);
                        //If status already exist, just update
                        if (existingStatuses.contains(newStatus) && newStatus != cm.Status) {
                            cm.Status = newStatus;
                            programMemberToUpdate.add(cm);
                        } else { //Else insert new campaign status, copy from tactic objective status
                            CampaignMemberStatus newCms = new CampaignMemberStatus();
                            newCms.Label = newStatus;
                            newCms.CampaignId = cm.CampaignId;
                            newCms.HasResponded = true;
                            programCampaignStatusesToInsert.add(newCms);
                            
                            cm.Status = newStatus;
                            programMemberToUpdate.add(cm);
                        }
                    }
                }
            }
            
            if (programCampaignStatusesToInsert.size() > 0) {
                insert programCampaignStatusesToInsert;
            }
            
            if (programMemberToUpdate.size() > 0) {
                update programMemberToUpdate;
            }
        }
    }
    
    public static void countCampaignObjectiveActualResponse(List<CampaignMember> listNewCampaignMember, Map<Id, CampaignMember> oldCampaignMemberMap){
        Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id masterRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> masterIds = new Set<Id>();
        Set<Id> programIds = new Set<Id>();
        Set<Id> tacticIds = new Set<Id>();
        Set<String> tacticObjectiveStatuses = new Set<String>();
        Set<String> programObjectiveStatuses = new Set<String>();
        List<Campaign> campaignToUpdate = new List<Campaign>();
        for (CampaignMember cm : listNewCampaignMember) {
            CampaignMember oldCm = oldCampaignMemberMap.get(cm.Id);
            if (cm.Status != oldCm.Status) {
                campaignIds.add(cm.CampaignId);
                if (cm.Campaign_Record_Type__c == programRecordTypeId) {
                    programIds.add(cm.CampaignId);
                    masterIds.add(cm.Campaign.ParentId);
                } else if (cm.Campaign_Record_Type__c == tacticRecordTypeId) {
                    tacticIds.add(cm.CampaignId);
                }
            }
        }
        
        if (campaignIds.size() > 0) {
            //Get campaign member status mapping
            Map<String, Default_Campaign_Member_Status__mdt> mapMemberObjectiveStatus = new Map<String, Default_Campaign_Member_Status__mdt>();
            for (Default_Campaign_Member_Status__mdt defCmStatus : [SELECT Id, Campaign_Hierarchy__c, Responded_Status__c, Objective__c, Offer_Type__c, Tactics_Type__c, Objective_Status__c FROM Default_Campaign_Member_Status__mdt WHERE Objective_Status__c != NULL]) {
                String mapKey = defCmStatus.Objective__c + '_' + defCmStatus.Offer_Type__c + '_' + defCmStatus.Tactics_Type__c;
                mapMemberObjectiveStatus.put(mapKey, defCmStatus);

                if (defCmStatus.Objective__c != null) {
                    programObjectiveStatuses.add(defCmStatus.Objective_Status__c);
                }
                
                if (defCmStatus.Tactics_Type__c != null) {
                    tacticObjectiveStatuses.add(defCmStatus.Objective_Status__c);
                }
            }
            
            if (mapMemberObjectiveStatus != null && !mapMemberObjectiveStatus.isEmpty()) {
                system.debug('***Campaign Ids: '+ campaignIds);
                // Map<String, Set<String>> mapProgramTacticMembers = new Map<String, Set<String>>();
                // for (CampaignMember cm : [SELECT Id, Status, ContactId, Campaign.Objective__c, Campaign.Offer_Type__c, Campaign.Tactics_Type__c, CampaignId, Campaign.ParentId, Campaign.RecordTypeId FROM CampaignMember WHERE CampaignId IN :campaignIds]) {
                //     String mapKey = cm.Campaign.Objective__c + '_' + cm.Campaign.Offer_Type__c + '_' + cm.Campaign.Tactics_Type__c;
                    // system.debug('***Campaign Member: '+ cm.Id + '_' + cm.Status);
                    // system.debug('***Campaign map Key: '+ mapKey);
                    // if (mapMemberObjectiveStatus.get(mapKey) != null && mapMemberObjectiveStatus.get(mapKey).Objective_Status__c == cm.Status) {
                    //     if(mapProgramTacticMembers.containsKey(cm.CampaignId)) {
                    //         Set<String> contactIds = mapProgramTacticMembers.get(cm.CampaignId);
                    //         contactIds.add(cm.ContactId);
                    //         mapProgramTacticMembers.put(cm.CampaignId, contactIds);
                    //     } else {
                    //         mapProgramTacticMembers.put(cm.CampaignId, new Set<String> { cm.ContactId });
                    //     }
                    // }
                    
                //     if (mapMemberObjectiveStatus.get(mapKey) != null && mapMemberObjectiveStatus.get(mapKey).Objective_Status__c == cm.Status) {
                //         if (cm.Campaign.RecordTypeId == programRecordTypeId) {
                //             programIds.add(cm.CampaignId);
                //             masterIds.add(cm.Campaign.ParentId);
                //         } else if (cm.Campaign.RecordTypeId == tacticRecordTypeId) {
                //             tacticIds.add(cm.CampaignId);
                //         }
                //     }
                // }
                
                if (tacticIds.size() > 0) {
                    Map<Id,AggregateResult> programTacticAggregates = new Map<Id,AggregateResult>([SELECT CampaignId Id, COUNT(Id) totalRecord FROM CampaignMember WHERE CampaignId IN :tacticIds AND Status IN :tacticObjectiveStatuses GROUP BY CampaignId]);
                    if (programTacticAggregates != null && !programTacticAggregates.isEmpty()) {
                        for (Id agr : programTacticAggregates.keySet()) {
                            AggregateResult agrResult = programTacticAggregates.get(agr);
                            Campaign updCampaign = new Campaign();
                            updCampaign.Id = agr;
                            updCampaign.Response_Count_Actual__c = (Integer)agrResult.get('totalRecord');
                            campaignToUpdate.add(updCampaign);
                        }
                    }
                }

                if (programIds.size() > 0) {
                    Map<Id,AggregateResult> programTacticAggregates = new Map<Id,AggregateResult>([SELECT CampaignId Id, COUNT(Id) totalRecord FROM CampaignMember WHERE CampaignId IN :programIds AND Status IN :programObjectiveStatuses GROUP BY CampaignId]);
                    if (programTacticAggregates != null && !programTacticAggregates.isEmpty()) {
                        for (Id agr : programTacticAggregates.keySet()) {
                            AggregateResult agrResult = programTacticAggregates.get(agr);
                            Campaign updCampaign = new Campaign();
                            updCampaign.Id = agr;
                            updCampaign.Response_Count_Actual__c = (Integer)agrResult.get('totalRecord');
                            campaignToUpdate.add(updCampaign);
                        }
                    }
                }
                
                if (masterIds.size() > 0) {
                    Map<Id,AggregateResult> masterAggregates = new Map<Id,AggregateResult>([SELECT Campaign.ParentId Id, COUNT_DISTINCT(ContactId) totalRecord FROM CampaignMember WHERE CampaignId IN :programIds AND Status IN :programObjectiveStatuses GROUP BY Campaign.ParentId]);
                    system.debug('***Check Master: '+ ((String)JSON.serialize(masterAggregates)));
                    if (masterAggregates != null && !masterAggregates.isEmpty()) {
                        for (Id agr : masterAggregates.keySet()) {
                            AggregateResult agrResult = masterAggregates.get(agr);
                            Campaign updCampaign = new Campaign();
                            updCampaign.Id = agr;
                            updCampaign.Response_Count_Actual__c = (Integer)agrResult.get('totalRecord');
                            campaignToUpdate.add(updCampaign);
                        }
                    }
                }
                
                // system.debug('***Map Result: '+ mapProgramTacticMembers);
                // if (mapProgramTacticMembers != null && !mapProgramTacticMembers.isEmpty()) {
                //     for (String loopMap : mapProgramTacticMembers.keySet()) {
                //         system.debug('***Campaign Loop: '+ loopMap);
                //         system.debug('***Campaign Loop: '+ mapProgramTacticMembers.get(loopMap).size());
                //         Campaign updCampaign = new Campaign();
                //         updCampaign.Id = loopMap;
                //         updCampaign.Response_Count_Actual__c = mapProgramTacticMembers.get(loopMap).size();
                //         campaignToUpdate.add(updCampaign);
                //     }
                // }
                
                // //Additional logic to update master unique member
                // Map<String, Set<String>> mapMasterMembers = new Map<String, Set<String>>();
                // for (CampaignMember cm : [SELECT Id, Status, ContactId, Campaign.Objective__c, Campaign.Offer_Type__c, Campaign.Tactics_Type__c, CampaignId, Campaign.ParentId FROM CampaignMember WHERE Campaign.ParentId IN :masterIds]) {
                //     String mapKey = cm.Campaign.Objective__c + '_' + cm.Campaign.Offer_Type__c + '_' + cm.Campaign.Tactics_Type__c;
                //     if (mapMemberObjectiveStatus.get(mapKey) != null && mapMemberObjectiveStatus.get(mapKey).Objective_Status__c == cm.Status) {
                //         if(mapMasterMembers.containsKey(cm.Campaign.ParentId)) {
                //             Set<String> contactIds = mapMasterMembers.get(cm.Campaign.ParentId);
                //             contactIds.add(cm.ContactId);
                //             mapMasterMembers.put(cm.Campaign.ParentId, contactIds);
                //         } else {
                //             mapMasterMembers.put(cm.Campaign.ParentId, new Set<String> { cm.ContactId });
                //         }
                //     }
                // }
                
                // if (mapMasterMembers != null && !mapMasterMembers.isEmpty()) {
                //     for (String loopMap : mapMasterMembers.keySet()) {
                //         system.debug('***Master Loop: '+ loopMap);
                //         system.debug('***Master Loop: '+ mapMasterMembers.get(loopMap).size());
                //         Campaign updCampaign = new Campaign();
                //         updCampaign.Id = loopMap;
                //         updCampaign.Response_Count_Actual__c = mapMasterMembers.get(loopMap).size();
                //         campaignToUpdate.add(updCampaign);
                //     }
                // }
            }
        }
        
        if (campaignToUpdate.size() > 0) {
            TriggerBypassUtility.campaignMemberTriggerBypass = true;
            update campaignToUpdate;
            TriggerBypassUtility.campaignMemberTriggerBypass = false;
        }
    }
}