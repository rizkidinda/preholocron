/**
 * @description       : 
 * @group             : 
 * @last modified on  : 18-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class OpportunityContactRoleHelper {
    public static void campaignInfluenceChecker(List<OpportunityContactRole>  newContactRole, Map<Id, OpportunityContactRole> oldContactRoleMap){
        String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
        String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Map<Id, Set<Id>> contactOppIdMap = new Map<Id, Set<Id>>();
        Set<String> campaignOpportunityType = new Set<String>{
            'Form Sign Up',
            'Dashboard Sign Up',
            'Go Live Request',
            'New active merchant acquired',
            'Products Activated / Cross-sell',
            'Upsell'
        };

        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> contactRoleOppId = new Set<Id>();
        for (OpportunityContactRole role : newContactRole) {
            opportunityIds.add(role.OpportunityId);
            contactIds.add(role.ContactId);
            contactRoleOppId.add(role.OpportunityId);
            if(!contactOppIdMap.containsKey(role.ContactId)){
                contactOppIdMap.put(role.ContactId, new Set<Id>{role.OpportunityId});
            }else{
                contactOppIdMap.get(role.ContactId).add(role.OpportunityId);
            }
        }

        if (opportunityIds.size() > 0 && contactIds.size() > 0) {
            Map<String, List<Opportunity>> accountIdOppMap = new Map<String, List<Opportunity>>();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            Map<Id, Set<Id>> campaignProductMap = new Map<Id, Set<Id>>();
            Map<String, Set<String>> accIdCampaignInfluenceKeyMap = new Map <String, Set<String>>();
            Map<String, CampaignInfluence> createCampaignInfluenceMap = new Map<String,CampaignInfluence>();
            Map<Id, List<String>> campaignAccountIDMap = new Map<Id, List<String>>();
            CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
            List<CampaignMember> memberList = [SELECT Id, CreatedDate, CampaignId, Campaign.Objective__c, ContactId, Contact_Account_Id__c, Status FROM CampaignMember WHERE ContactId != NULL AND Campaign.RecordTypeId = :programCampaignRT AND Campaign.IsActive = TRUE AND Campaign.Objective__c IN :campaignOpportunityType AND (Status = 'Tactic Engaged' OR HasResponded = TRUE)];
            for(CampaignMember member : memberList){
                if(!campaignAccountIDMap.containsKey(member.CampaignId)){
                    campaignAccountIDMap.put(member.CampaignId, new List<String>{member.Contact_Account_Id__c});
                }else{
                    campaignAccountIDMap.get(member.CampaignId).add(member.Contact_Account_Id__c);
                }
            }
            
            String oppQuery = 'SELECT Id, Name, Type, AccountId, Account.Business_Id__c, CampaignId, CreatedDate, Account.Pending_Verification_Data_PROVIDED_date__c, Account.X5th_Transaction_Date__c, (SELECT ContactId, OpportunityId, Opportunity.Account.Business_Id__c FROM OpportunityContactRoles WHERE ContactId != NULL),';
            oppQuery += ' (SELECT Parent_Opportunity_Lookup__c, Opportunity__r.Account.Business_Id__c, Rate_Card__r.Product__c FROM Xendit_Opportunity_Products_Channel__r WHERE Rate_Card__r.Product__c != NULL) ';
            oppQuery += ' FROM Opportunity WHERE Id IN :opportunityIds ';
            oppQuery += ' AND RecordType.Name = \'Parent Opportunity\' ';
            
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
            for(CampaignMember selectedCampaignMember : memberList){
                Set<Id> campaignProductSet = campaignProductMap.get(selectedCampaignMember.CampaignId);
                if(oppMap != null && !oppMap.isEmpty()){
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
                        Date selectedDate = oppCreatedDate;
                        if(selectedCampaignMember.Campaign.Objective__c == 'Go Live Request'){
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
                            Boolean isCrossSellUpsell = (selectedCampaignMember.Campaign.Objective__c == 'Products Activated / Cross-sell' || selectedCampaignMember.Campaign.Objective__c == 'Upsell');
                            if(hasContactRole && (!isCrossSellUpsell || (isCrossSellUpsell && existingProdInCmpProd.size() > 0)) ){
                                //insert campaign influence
                                String campInflStr = selectedCampaignMember.CampaignId + '_' + selectedCampaignMember.ContactId + '_' + opp.Id;
                                CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = selectedCampaignMember.CampaignId, ContactId = selectedCampaignMember.ContactId, OpportunityId = opp.Id, ModelId = defaultModel.Id, External_Id__c = (campInflStr + '_' + defaultModel.Id));
                                createCampaignInfluenceMap.put(createCampInfl.External_Id__c, createCampInfl);
                            }
                        }
                    }
                }
            }

            if(!createCampaignInfluenceMap.isEmpty() && createCampaignInfluenceMap.values().size() > 0){
                upsert createCampaignInfluenceMap.values() External_Id__c;
            }

            // String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
            // for (CampaignMember cm : [SELECT Id, CreatedDate, CampaignId, Campaign.Objective__c, ContactId, Contact_Account_Id__c, Status FROM CampaignMember WHERE ContactId != NULL AND Campaign.RecordTypeId = :programCampaignRT AND Campaign.IsActive = TRUE AND Campaign.Objective__c IN :campaignOpportunityType AND (Status = 'Tactic Engaged' OR HasResponded = TRUE)]) {
            //     5 => 'Products Activated / Cross-sell',
            //     6 => 'Upsell'
            //     if () {

            //     }
            // }

            // Map<String, CampaignInfluence> mapOpptyContactCampaignInfluence = new Map<String, CampaignInfluence>();
            // for (CampaignInfluence ci : [SELECT Id, Status, ContactId, CampaignId, Campaign.Objective__c, OpportunityId, Opportunity.Type FROM CampaignInfluence WHERE OpportunityId IN :opportunityIds AND ContactId IN :contactIds]) {
            //     String mapKey = ci.ContactId + '_' + ci.OpportunityId;
            //     if (ci.Campaign.Objective__c == 'Products Activated / Cross-sell') {
            //         mapKey = mapKey + '_Cross Sell';
            //     } else if (ci.Campaign.Objective__c == 'Upsell') {
            //         mapKey = mapKey + '_Upsell';
            //     }
            //     mapOpptyContactCampaignInfluence.put(mapKey, ci);
            // }

            // if (mapOpptyContactCampaignInfluence != null && !mapOpptyContactCampaignInfluence.isEmpty()) {
            //     for (OpportunityContactRole role : [SELECT Id, OpportunityId, Opportunity.Type, CampaignId, ContactId FROM OpportunityContactRole WHERE Id IN :roleIds]) {
            //         String mapKey = role.ContactId + '_' + role.OpportunityId;
            //         if (role.Opportunity.Type == 'Cross Sell' || role.Opportunity.Type == 'Upsell') {
            //             mapKey = mapKey + '_' + role.Opportunity.Type;
            //         }

            //         if (mapOpptyContactCampaignInfluence.get(mapKey) == null) {
            //             roleToProcess.add(role);
            //         }
            //     }

            //     if (roleToProcess.size() > 0) {

            //     }
            // }
        }
    }
}