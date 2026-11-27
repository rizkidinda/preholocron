/**
 * @description       : 
 * @group             : 
 * @last modified on  : 29-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public class CampaignInfluenceHelper {
    /*
    Name : PopulateExternalId
    Description : auto-populate external Id value 
    */
    public static void PopulateExternalId(List<CampaignInfluence> listNew){
        for(CampaignInfluence ci : listNew){
            ci.External_Id__c = ci.CampaignId + '_' + ci.ContactId + '_' + ci.OpportunityId + '_' + ci.ModelId;
        }
    }

     /*
    Name : UpdateCampaignInfluencePercentage
    Description : auto-update campaign influence percentage
    
    public static void UpdateCampaignInfluencePercentage(List<CampaignInfluence> campaignInfluenceList){
        try{
            system.debug('UpdateCampaignInfluencePercentage start');
            Set<Id> oppIdSet = new Set<Id>();
            Map<Id, Map<String, Set<Id>>> oppCampaignContactMap = new Map<Id, Map<String, Set<Id>>>();
            Map<String, CampaignInfluence> upsertCampaignInfluenceMap = new Map<String, CampaignInfluence>();
            Map<String, Id> campInfMap = new Map<String, Id>();
            for(CampaignInfluence ci: campaignInfluenceList){
                if(ci.OpportunityId != null){
                    oppIdSet.add(ci.OpportunityId);
                }
            }
            List<CampaignInfluence> exstCampInfList = [SELECT Id, External_Id__c, OpportunityId, CampaignId, ContactId, ModelId, Influence FROM CampaignInfluence WHERE opportunityId IN :oppIdSet];
            for(CampaignInfluence ci : exstCampInfList){
                campInfMap.put(ci.External_Id__c, ci.Id);
                String campKey = ci.CampaignId + '_' + ci.OpportunityId + '_' + ci.ModelId;

                Map<String, Set<Id>> tempCampaignContactMap = new Map<String, Set<Id>>();
                if(!oppCampaignContactMap.containsKey(ci.OpportunityId)){
                    tempCampaignContactMap.put(campKey, new Set<Id>{ci.ContactId});
                    
                }else{
                    tempCampaignContactMap = oppCampaignContactMap.get(ci.OpportunityId);
                    if(!tempCampaignContactMap.containsKey(campKey)){
                        tempCampaignContactMap.put(campKey, new Set<Id>{ci.ContactId});
                    }else{
                        tempCampaignContactMap.get(campKey).add(ci.ContactId);
                    }
                }
                
                oppCampaignContactMap.put(ci.OpportunityId, tempCampaignContactMap);
            }

            if(!oppCampaignContactMap.isEmpty()){
                for(Id oppId : oppCampaignContactMap.keySet()){
                    Map<String, Set<Id>> campContMap = oppCampaignContactMap.get(oppId);
                    if(campContMap != null && !campContMap.isEmpty()){
                        for(String key : campContMap.keySet()){
                            List<String> keySplit = key.split('_');
                            if(keySplit.size() > 2){
                                Set<Id> contactIdSet = campContMap.get(key);
                                if(contactIdSet != null && !campContMap.isEmpty()){
                                    for(Id contId : contactIdSet){
                                        String upsertKey =  keySplit[0] + '_' + contId + '_' + keySplit[1] + '_' + keySplit[2];
                                        Id ciId = campInfMap.get(upsertKey);
                                        Double percentageVal = (100 / campContMap.size()) / contactIdSet.size();
                                        if(ciId != null){
                                            upsertCampaignInfluenceMap.put(upsertKey, new CampaignInfluence(Id = ciId, Influence = percentageVal));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if(!upsertCampaignInfluenceMap.isEmpty()){
                    update upsertCampaignInfluenceMap.values();
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignInfluenceHelper','CampaignInfluence', 'UpdateCampaignInfluencePercentage', 'CampaignInfluenceTrigger',  e);
        }
    }
	*/
    public static void UpdateCampaignInfluencePercentage(List<CampaignInfluence> campaignInfluenceList){
    try{
        system.debug('UpdateCampaignInfluencePercentage start');
        Set<Id> oppIdSet = new Set<Id>();
        
        for(CampaignInfluence ci: campaignInfluenceList){
            if(ci.OpportunityId != null){
                oppIdSet.add(ci.OpportunityId);
            }
        }
        
        // Query existing CampaignInfluence records with Campaign.Is_CP__c
        List<CampaignInfluence> exstCampInfList = [
            SELECT Id, External_Id__c, OpportunityId, CampaignId, ContactId, ModelId, Influence, Campaign.Is_CP_Event__c 
            FROM CampaignInfluence WHERE OpportunityId IN :oppIdSet
        ];
        
        // Organize campaign influences by Opportunity and Is_CP__c
        Map<Id, Map<Boolean, List<CampaignInfluence>>> oppCampaignGroupMap = new Map<Id, Map<Boolean, List<CampaignInfluence>>>();
        for(CampaignInfluence ci : exstCampInfList){
            Boolean isCP = ci.Campaign.Is_CP_Event__c ;
            
            if (!oppCampaignGroupMap.containsKey(ci.OpportunityId)) {
                oppCampaignGroupMap.put(ci.OpportunityId, new Map<Boolean, List<CampaignInfluence>>());
            }
            
            Map<Boolean, List<CampaignInfluence>> cpGroupMap = oppCampaignGroupMap.get(ci.OpportunityId);
            
            if (!cpGroupMap.containsKey(isCP)) {
                cpGroupMap.put(isCP, new List<CampaignInfluence>());
            }
            
            cpGroupMap.get(isCP).add(ci);
        }
        
        // Calculate influence percentage correctly
        List<CampaignInfluence> updateList = new List<CampaignInfluence>();
        for (Id oppId : oppCampaignGroupMap.keySet()) {
            Map<Boolean, List<CampaignInfluence>> cpGroupMap = oppCampaignGroupMap.get(oppId);
            
            for (Boolean isCP : cpGroupMap.keySet()) {
                List<CampaignInfluence> campaignInfluences = cpGroupMap.get(isCP);
                Double influencePercentage = 100.0 / campaignInfluences.size();
                
                for (CampaignInfluence ci : campaignInfluences) {
                    ci.Influence = influencePercentage;
                    updateList.add(ci);
                }
            }
        }
        
            if (!updateList.isEmpty()) {
                update updateList;
            }
        } catch(Exception e){
            ExceptionUtility.createExceptionLog('CampaignInfluenceHelper','CampaignInfluence', 'UpdateCampaignInfluencePercentage', 'CampaignInfluenceTrigger', e);
        }
    }



    public static void calculateCampaignRevenueFields(List<CampaignInfluence> listNewCampaignInfluence, Map<Id, CampaignInfluence> oldCampaignInfluenceMap){
        Set<Id> programIds = new Set<Id>();
        for (CampaignInfluence ci : listNewCampaignInfluence) {
            CampaignInfluence oldCI = oldCampaignInfluenceMap != null && oldCampaignInfluenceMap.get(ci.Id) != null ? oldCampaignInfluenceMap.get(ci.Id) : null;
            if (oldCI == null || (oldCI != null && ci.Influence != null && ci.Influence != oldCI.Influence)) {
                programIds.add(ci.CampaignId);
            }
        }

        if (programIds.size() > 0) {
            Map<String, Decimal> mapCalculationByCampaignId = new Map<String, Decimal>();
            List<CampaignInfluence> listInfluence = [SELECT Id, CampaignId, OpportunityId, Opportunity.Addressable_Merchant_Revenue_Monthly_USD__c, Influence FROM CampaignInfluence WHERE CampaignId IN :programIds];
            if (listInfluence.size() > 0) {
                for (CampaignInfluence ci : listInfluence) {
                    system.debug('***Addressable_Merchant_Revenue_Monthly_USD__c: '+ ci.Opportunity.Addressable_Merchant_Revenue_Monthly_USD__c);
                    system.debug('***Influence: '+ ci.Influence);
                    if (ci.Opportunity.Addressable_Merchant_Revenue_Monthly_USD__c != null) {
                        Decimal monthlyRev = ci.Opportunity.Addressable_Merchant_Revenue_Monthly_USD__c;
                        Decimal influence = ci.Influence / 100;
                        Decimal result = monthlyRev * influence;
                        system.debug('***MoM Result: '+ result);
                        if (mapCalculationByCampaignId != null && mapCalculationByCampaignId.get(ci.CampaignId) != null) {
                            Decimal tempValue = mapCalculationByCampaignId.get(ci.CampaignId) + result;
                            mapCalculationByCampaignId.put(ci.CampaignId, tempValue);
                        } else {
                            mapCalculationByCampaignId.put(ci.CampaignId, result);
                        }
                    }
                }
                
                system.debug('***Result: '+ mapCalculationByCampaignId);
                
                List<Campaign> campaignToUpdate = new List<Campaign>();
                if (mapCalculationByCampaignId != null && !mapCalculationByCampaignId.isEmpty()) {
                    for (String cmp : mapCalculationByCampaignId.keySet()) {
                        Campaign upCampaign = new Campaign();
                        upCampaign.Id = cmp;
                        upCampaign.Campaign_Rev_Share_USD__c = mapCalculationByCampaignId.get(cmp);
                        campaignToUpdate.add(upCampaign);
                    }
                }
                
                system.debug('***Result: '+ campaignToUpdate);
                
                if (campaignToUpdate.size() > 0) {
                    update campaignToUpdate;
                }   
            }
        }
    }
}