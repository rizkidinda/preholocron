public class CreateLeadOppCampInfluenceBatch implements Database.Batchable<sObject>, Database.Stateful{
    public String query;
    public Id leadId;
    public Set<Id> contactIdSet;
    public Id oppId;
    public Id modelId;
    public String purpose;

    public CreateLeadOppCampInfluenceBatch(Id leadObjId, Set<Id> contactObjId, Id oppobjId, Id modelObjId, String purposeStr) {
        leadId = leadObjId;
        contactIdSet = contactObjId;
        oppId = oppObjId;
        modelId = modelObjId;
        purpose = purposeStr;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        query = 'SELECT Id, Status, CampaignId, LeadId, ContactId, LeadOrContactId, HasResponded FROM CampaignMember ';
        if(purpose == 'CONVERTED_LEAD'){
            query += ' WHERE LeadId =: leadId AND Campaign.RecordTypeId =:programCampaignRT AND Campaign.Objective__c = \'Pipe Progression\' AND ( Status = :autoUpdateCampaignMemberStatus OR HasResponded = TRUE ) ';
        }else if(purpose == 'STAGE_ADVANCED_OPP'){
            query += 'WHERE ContactId IN :contactIdSet AND Campaign.RecordTypeId =:programCampaignRT AND Campaign.Objective__c = \'Pipe Progression\' AND Status =:autoUpdateCampaignMemberStatus ';
        }
        
        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext BC, List<CampaignMember> scope){
        try{
            List<CampaignInfluence> createCampInflList = new List<CampaignInfluence>();
            if(!scope.isEmpty()){
                switch on purpose {
                    when 'CONVERTED_LEAD'  {
                        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
                        Id selectedContactId = new List<Id>(contactIdSet)[0];
                        Map<String, CampaignMember> updateCampaignMemberStatusMap = new Map<String, CampaignMember>();
                        for(CampaignMember cm : scope){
                            String externalId =  cm.CampaignId + '_' + selectedContactId + '_' + oppId + '_' + modelId; //campaignid_contactid_oppid_modelid
                            CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = cm.CampaignId, ContactId = selectedContactId, OpportunityId = oppId, ModelId = modelId, External_Id__c = externalId);
                            createCampInflList.add(createCampInfl);
                            if(cm.Status == autoUpdateCampaignMemberStatus){
                                CampaignMember cmTemp = new CampaignMember(Id = cm.Id, CampaignId = cm.CampaignId, Status = 'Stage Advanced');
                                updateCampaignMemberStatusMap.put(externalId, cmTemp);
                            }
                        }
        
                        if(!createCampInflList.isEmpty()){
                            insert createCampInflList;
                        }

                        if(!updateCampaignMemberStatusMap.isEmpty()){
                            UpdateCampaignMemberStatusToStageAdvanced(updateCampaignMemberStatusMap);
                        }
                    }
                    when 'STAGE_ADVANCED_OPP' {
                        Map<String, Id> campInflMap = new Map<String, Id>();
                        Map<String, CampaignInfluence> createCampaignInfluenceMap = new Map<String, CampaignInfluence>();
                        Map<String, CampaignMember> extIdCampaignMemberMap = new Map<String, CampaignMember>();
                        Map<String, CampaignMember> updateCampaignMemberStatusMap = new Map<String, CampaignMember>();
                        for(CampaignMember cm : scope){
                            //get existing campaign influence first
                            String externalId =  cm.CampaignId + '_' + cm.ContactId + '_' + oppId + '_' + modelId; //campaignid_contactid_oppid_modelid
                            campInflMap.put(externalId, null);
                            extIdCampaignMemberMap.put(externalId, cm);
                        }

                        for(CampaignInfluence ci : [SELECT Id, OpportunityId, ContactId, External_Id__c FROM CampaignInfluence WHERE External_Id__c IN :campInflMap.keySet()]){
                            campInflMap.put(ci.External_Id__c, ci.Id);
                        }

                        for(String externalId : campInflMap.keySet()){
                            if(campInflMap.get(externalId) == null){
                                //insert campaign influence
                                List<String> externalIdList = externalId.split('_');
                                if(externalIdList.size() > 3){
                                    createCampaignInfluenceMap.put(externalId, new CampaignInfluence(CampaignId = externalIdList[0], ContactId = externalIdList[1], OpportunityId = oppId, ModelId = modelId, External_Id__c = externalId));

                                    if(extIdCampaignMemberMap.containsKey(externalId)){
                                        CampaignMember cm = new CampaignMember(Id = extIdCampaignMemberMap.get(externalId).Id, CampaignId = externalIdList[0], Status = 'Stage Advanced');
                                        updateCampaignMemberStatusMap.put(externalId, cm);
                                    }
                                }
                            }
                        }

                        if(!createCampaignInfluenceMap.isEmpty()){
                            insert createCampaignInfluenceMap.values();
                        }

                        if(!updateCampaignMemberStatusMap.isEmpty()){
                            UpdateCampaignMemberStatusToStageAdvanced(updateCampaignMemberStatusMap);
                        }
                    }
                }
                
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CreateLeadOppCampInfluenceBatch','CampaignInfluence', 'insert', 'Batch ScheduledJob',  e);
        }
    }

    public void finish(Database.BatchableContext BC){
        
    }

    @TestVisible
    private void UpdateCampaignMemberStatusToStageAdvanced(Map<String, CampaignMember> updateCampaignMemberStatusMap){
        Set<Id> selectedCampaignIdSet = new Set<Id>();
        Set<Id> campaignWithStageAdvStatusSet = new Set<Id>();
        Set<Id> campaignToAddStatusSet = new Set<Id>();
        for(CampaignMember cm : updateCampaignMemberStatusMap.values()){
            selectedCampaignIdSet.add(cm.CampaignId);
        }

        for(CampaignMemberStatus cmStatus : [SELECT Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :selectedCampaignIdSet AND Label = 'Stage Advanced']){
            campaignWithStageAdvStatusSet.add(cmStatus.CampaignId);
        }

        for(CampaignMember cm : updateCampaignMemberStatusMap.values()){
            if(campaignWithStageAdvStatusSet.isEmpty() || (!campaignWithStageAdvStatusSet.isEmpty() && !campaignWithStageAdvStatusSet.contains(cm.CampaignId))){
                campaignToAddStatusSet.add(cm.CampaignId);
            }
        }

        if(!campaignToAddStatusSet.isEmpty()){
            List<CampaignMemberStatus> createnewStatusList = new List<CampaignMemberStatus>();
            for(Id cmpId : campaignToAddStatusSet){
                createnewStatusList.add(new CampaignMemberStatus(CampaignId = cmpId, Label = 'Stage Advanced', HasResponded = true));
            }

            insert createnewStatusList;
        }

        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        update updateCampaignMemberStatusMap.values();
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
    }
}