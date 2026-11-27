public without sharing class AutoUpdateCampaignMemberStatusBatch implements Database.Batchable<sObject>, Database.Stateful{
    public String query = '';
    public String programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
    public String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
    public String progObjective = '';
    public Set<Id> leadIdSet = new Set<Id>();
    public Set<Id> contactIdSet = new Set<Id>();
    public Set<Id> campaignIdSet = new Set<Id>();

    public AutoUpdateCampaignMemberStatusBatch(Set<Id> campaignId, Set<Id> leadId, Set<Id> contactId, String objective) {
        leadIdSet = leadId;
        contactIdSet = contactId;
        progObjective = objective;
        campaignIdSet = campaignId;
        query = getQuery(campaignIdSet, leadIdSet, contactIdSet, progObjective);
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator( query );
    }


    public void execute(Database.BatchableContext BC, List<CampaignMember> scope){
        try{
            if(scope != null && !scope.isEmpty()){
                UpdateCampaignMemberStatus(scope, progObjective);
            }
            
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('AutoUpdateCampaignMemberStatusBatch','CampaignMemberStatus', 'update', 'Batch Trigger',  e);
        }
    }

    public void finish(Database.BatchableContext BC){
    }

    @TestVisible
    private String getQuery(Set<Id> campaignIdSet, Set<Id> leadIdSet, Set<Id> contactIdSet, String progObjective){
        String qry = 'SELECT Id, CreatedDate, CampaignId, ContactId, Contact_Account_Id__c, Status FROM CampaignMember WHERE Campaign.Objective__c = :progObjective ';
        
        if(campaignIdSet != null && !campaignIdSet.isEmpty()){
            qry += ' AND CampaignId IN :campaignIdSet ';
        }else{
            qry += ' AND Campaign.RecordTypeId = :programCampaignRT AND Campaign.IsActive = TRUE AND Status = :autoUpdateCampaignMemberStatus ';
        }
        
        if(leadIdSet != null && !leadIdSet.isEmpty()){
            qry += ' AND LeadId IN :leadIdSet ';
        }else if(contactIdSet != null && !contactIdSet.isEmpty()){
            qry += ' AND ContactId IN :contactIdSet ';
        }
        return qry;
    }

    @TestVisible
    private void UpdateCampaignMemberStatus(List<CampaignMember> campaignMemberList, String objective){
        Set<Id> selectedCampaignIdSet = new Set<Id>();
        Set<Id> campaignWithObjectiveStatusSet = new Set<Id>();
        Set<Id> campaignToAddStatusSet = new Set<Id>();
        List<CampaignMember> updateCampaignMemberList = new List<CampaignMember>();
        for(CampaignMember cm : campaignMemberList){
            CampaignMember updateCampaignMember = new CampaignMember(Id = cm.Id, CampaignId = cm.CampaignId, Status = objective);
            updateCampaignMemberList.add(updateCampaignMember);
            selectedCampaignIdSet.add(cm.CampaignId);
        }

        for(CampaignMemberStatus cmStatus : [SELECT Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId IN :selectedCampaignIdSet AND Label = :objective]){
            campaignWithObjectiveStatusSet.add(cmStatus.CampaignId);
        }

        for(CampaignMember cm : updateCampaignMemberList){
            if(campaignWithObjectiveStatusSet.isEmpty() || (!campaignWithObjectiveStatusSet.isEmpty() && !campaignWithObjectiveStatusSet.contains(cm.CampaignId))){
                campaignToAddStatusSet.add(cm.CampaignId);
            }
        }

        if(!campaignToAddStatusSet.isEmpty()){
            List<CampaignMemberStatus> createnewStatusList = new List<CampaignMemberStatus>();
            for(Id cmpId : campaignToAddStatusSet){
                createnewStatusList.add(new CampaignMemberStatus(CampaignId = cmpId, Label = objective, HasResponded = TRUE));
            }

            insert createnewStatusList;
        }

        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        update updateCampaignMemberList;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
    }
}