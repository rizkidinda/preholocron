/**
 * @description       : 
 * @group             : 
 * @last modified on  : 23-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public class AutoInsertCampaignInfluenceBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
    public String query = '';
    public Integer i = 1;
    public Map<Integer, String> intKeyMap = new Map<Integer, String>{
        1 => 'Form Sign Up',
        2 => 'Dashboard Sign Up',
        3 => 'Go Live Request',
        4 => 'New active merchant acquired',
        5 => 'Products Activated / Cross-sell',
        6 => 'Upsell'
    };
    public String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
    public String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
    public String progObjective = '';
    public Boolean isInit = false;

    public AutoInsertCampaignInfluenceBatch(Integer currKey, Boolean boolInit) {
        isInit = boolInit;
        i = currKey;
        progObjective = intKeyMap.containsKey(i) ? intKeyMap.get(i) : '';
        query = getQuery(i, isInit);
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator( query );
    }


    public void execute(Database.BatchableContext BC, List<CampaignMember> scope){
        try{
            createCampInfluenceLogic(scope, i);
            
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AutoInsertCampaignInfluenceBatch','CampaignInfluence', 'insert', 'Batch ScheduledJob',  e);
        }
    }

    public void finish(Database.BatchableContext BC){
        i ++;
        if(intKeyMap.containsKey(i)){
            AutoInsertCampaignInfluenceBatch cx = new AutoInsertCampaignInfluenceBatch(i, isInit);
            Database.executeBatch( cx , 200 );
        }
    }

    public void execute( Schedulablecontext sc ){
        AutoInsertCampaignInfluenceBatch cx = new AutoInsertCampaignInfluenceBatch(i, isInit);
        Database.executeBatch( cx , 200 ); 
    }

    @TestVisible
    private String getQuery(Integer intKey, Boolean isInit){
        String qry = 'SELECT Id, CreatedDate, CampaignId, ContactId, Contact_Account_Id__c, Status FROM CampaignMember WHERE ContactId != NULL AND Campaign.RecordTypeId = :programCampaignRT AND Campaign.IsActive = TRUE AND Campaign.Objective__c = :progObjective AND (Status = :autoUpdateCampaignMemberStatus OR HasResponded = TRUE) ';
        if(!isInit){
            qry += ' AND LastModifiedDate = YESTERDAY ';
        }
        return qry;
    }

    @TestVisible
    private void createCampInfluenceLogic(List<CampaignMember> scope, Integer intKey){
        Map<Id, List<String>> campaignAccountIDMap = new Map<Id, List<String>>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();

        for(CampaignMember member : scope){
            system.debug('***Member to Process: '+ member.Id);
            accountIdSet.add(member.Contact_Account_Id__c);
            contactIdSet.add(member.ContactId);
            if(!campaignAccountIDMap.containsKey(member.CampaignId)){
                campaignAccountIDMap.put(member.CampaignId, new List<String>{member.Contact_Account_Id__c});
            }else{
                campaignAccountIDMap.get(member.CampaignId).add(member.Contact_Account_Id__c);
            }
        }

        if(!campaignAccountIDMap.isEmpty()){
            Set<Id> contactRoleOppId = new Set<Id>();
            Map<String, List<Opportunity>> accountIdOppMap = new Map<String, List<Opportunity>>();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            Map<Id, Set<Id>> campaignProductMap = new Map<Id, Set<Id>>();
            Map<String, Set<String>> accIdCampaignInfluenceKeyMap = new Map <String, Set<String>>(); //key : BID <> CampaignId_ContactId
            Map<String, CampaignInfluence> createCampaignInfluenceMap = new Map<String,CampaignInfluence>();
            Map<Id, Set<Id>> contactOppIdMap = new Map<Id, Set<Id>>();
            String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
            CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
            Map<Id, CampaignMember> updateCampaignMemberStatusMap = new Map<Id, CampaignMember>();
            //get opp id from contact role
            for(OpportunityContactRole contactRole : [SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE ContactId IN :contactIdSet]){ //Contact.AccountId IN :accountIdSet AND 
                contactRoleOppId.add(contactRole.OpportunityId);

                if(!contactOppIdMap.containsKey(contactRole.ContactId)){
                    contactOppIdMap.put(contactRole.ContactId, new Set<Id>{contactRole.OpportunityId});
                }else{
                    contactOppIdMap.get(contactRole.ContactId).add(contactRole.OpportunityId);
                }
            }

            String oppQuery = 'SELECT Id, Name, AccountId, Account.Business_Id__c, CampaignId, CreatedDate, Account.Pending_Verification_Data_PROVIDED_date__c, Account.X5th_Transaction_Date__c, (SELECT ContactId, OpportunityId, Opportunity.Account.Business_Id__c FROM OpportunityContactRoles WHERE ContactId != NULL),';
                    oppQuery += ' (SELECT Parent_Opportunity_Lookup__c, Opportunity__r.Account.Business_Id__c, Rate_Card__r.Product__c FROM Xendit_Opportunity_Products_Channel__r WHERE Rate_Card__r.Product__c != NULL) ';
                    oppQuery += ' FROM Opportunity WHERE Id IN :contactRoleOppId ';
                    oppQuery += ' AND RecordType.Name = \'Parent Opportunity\' ';

            String oppStageQuery = ' AND (NOT StageName IN (\'Closed Won\',\'Closed Lost\')) ';
            if(intKey == 5){
                oppQuery += ' AND Type = \'Cross Sell\' ';
            }else if(intKey == 6){
                oppQuery += ' AND Type = \'Upsell\' ';
            }

            oppQuery += oppStageQuery;
            List<Opportunity> oppList = Database.query(oppQuery);
            
            for(Opportunity opp : oppList){
                String oppCampaignId = opp.CampaignId != null ?  '_' + opp.CampaignId : '';
                String mapKeyStr = opp.AccountId + oppCampaignId;
                if(!accountIdOppMap.containsKey(mapKeyStr)){
                    accountIdOppMap.put(mapKeyStr, new List<Opportunity>{opp});
                }else{
                    accountIdOppMap.get(mapKeyStr).add(opp);
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

            //find opportunity with matching contact role = campaign member, and opp product is part of campaign product
            for(CampaignMember selectedCampaignMember : scope){

                Set<Id> campaignProductSet = campaignProductMap.get(selectedCampaignMember.CampaignId);
                if(oppMap != null && !oppMap.isEmpty()){ //if(accountIdOppMap != null && !accountIdOppMap.isEmpty()){
                    List<Opportunity> getOppList = new List<Opportunity>();
                    if(contactOppIdMap.containsKey(selectedCampaignMember.ContactId)){
                        for(Id oppId : contactOppIdMap.get(selectedCampaignMember.ContactId)){
                            if(oppMap.containsKey(oppId)){ 
                                getOppList.add(oppMap.get(oppId));
                            }
                        }
                    }

                    for(Opportunity opp : getOppList){
                        Boolean hasContactRole = false;
                        Date cmCreatedDate = selectedCampaignMember.CreatedDate.date();
                        Date oppCreatedDate = opp.CreatedDate.date();
                        Date glrDate = opp.Account.Pending_Verification_Data_PROVIDED_date__c;
                        //Date fifthTxnDate = opp.Account.X5th_Transaction_Date__c;
                        Date selectedDate = oppCreatedDate;
                        if(intKey == 3){
                            selectedDate = glrDate;
                        }
                        if(selectedDate != null && cmCreatedDate.daysBetween(selectedDate) <= 180){
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
                            Boolean isCrossSellUpsell = (intKey == 5 || intKey == 6);
                            if(hasContactRole && (!isCrossSellUpsell || (isCrossSellUpsell && existingProdInCmpProd.size() > 0)) ){
                                //insert campaign influence
                                String campInflStr = selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId + '_' + opp.Id; //key : BID <> CampaignId_ContactId_OppId
                                CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = selectedCampaignMember.CampaignId, ContactId = selectedCampaignMember.ContactId, OpportunityId = opp.Id, ModelId = defaultModel.Id, External_Id__c = (campInflStr + '_' + defaultModel.Id));
                                createCampaignInfluenceMap.put(createCampInfl.External_Id__c, createCampInfl);
                                updateCampaignMemberStatusMap.put(selectedCampaignMember.Id, new CampaignMember(Id = selectedCampaignMember.Id, CampaignId = selectedCampaignMember.CampaignId, Status = intKeyMap.get(intKey)));
                            }
                        }
                        
                    }
                }
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
                    system.debug('***Member Processed: '+ ((String)JSON.serialize(createCampaignInfluenceList)));
                    insert createCampaignInfluenceList;
                }
            }

            if(isUpdateCampaignMemberStatus(intKey) && !updateCampaignMemberStatusMap.isEmpty()){
                UpdateCampaignMemberStatus(updateCampaignMemberStatusMap, intKey);
            }
        }
    }

    @TestVisible
    private void UpdateCampaignMemberStatus(Map<Id, CampaignMember> updateCampaignMemberMap, Integer intKey){
        Set<Id> selectedCampaignIdSet = new Set<Id>();
        Set<Id> campaignWithObjectiveStatusSet = new Set<Id>();
        Set<Id> campaignToAddStatusSet = new Set<Id>();
        String updateStatus = intKeyMap.get(intKey);
        for(CampaignMember cm : updateCampaignMemberMap.values()){
            selectedCampaignIdSet.add(cm.CampaignId);
        }

        for(CampaignMemberStatus cmStatus : [SELECT Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :selectedCampaignIdSet AND Label = :updateStatus]){
            campaignWithObjectiveStatusSet.add(cmStatus.CampaignId);
        }

        for(CampaignMember cm : updateCampaignMemberMap.values()){
            if(campaignWithObjectiveStatusSet.isEmpty() || (!campaignWithObjectiveStatusSet.isEmpty() && !campaignWithObjectiveStatusSet.contains(cm.CampaignId))){
                campaignToAddStatusSet.add(cm.CampaignId);
            }
        }

        if(!campaignToAddStatusSet.isEmpty()){
            List<CampaignMemberStatus> createnewStatusList = new List<CampaignMemberStatus>();
            for(Id cmpId : campaignToAddStatusSet){
                createnewStatusList.add(new CampaignMemberStatus(CampaignId = cmpId, Label = updateStatus, HasResponded = TRUE));
            }

            insert createnewStatusList;
        }

        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        update updateCampaignMemberMap.values();
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
    }

    @TestVisible
    private Boolean isUpdateCampaignMemberStatus(Integer i){
        return (i == 3);
    }
}