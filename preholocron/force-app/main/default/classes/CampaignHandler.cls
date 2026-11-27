/**
 * @description       : 
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class CampaignHandler extends TriggerHandler{
    public override void beforeInsert(){ 
        Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id masterRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        
        //Filter campaign records based on record type
        Map<Id, List<Campaign>> filteredCampaigns = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.new);
        List<Campaign> tacticCampaigns = filteredCampaigns.get(tacticRecordTypeId);
        List<Campaign> programCampaigns = filteredCampaigns.get(programRecordTypeId);
        List<Campaign> masterCampaigns = filteredCampaigns.get(masterRecordTypeId);
        
        //Call specific method only for Tactic Campaign
        if (tacticCampaigns != null && !tacticCampaigns.isEmpty()) {
            CampaignHelper.preProcessCampaign(tacticCampaigns, null);
            CampaignHelper.campaignStatusManager(tacticCampaigns, null);
        }

        //Call specific method only for Program Campaign
        if (programCampaigns != null && !programCampaigns.isEmpty()) {
            CampaignHelper.preProcessCampaign(programCampaigns, null);
            CampaignHelper.campaignStatusManager(programCampaigns, null);
        }

        //Call specific method only for Master Campaign
        if (masterCampaigns != null && !masterCampaigns.isEmpty()) {
            CampaignHelper.preProcessCampaign(masterCampaigns, null);
            CampaignHelper.campaignStatusManager(masterCampaigns, null);
        }
    }
    
    public override void afterInsert(){ 
        Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id masterRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        
        Map<Id, List<Campaign>> filteredCampaigns = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.new);
        List<Campaign> tacticCampaigns = filteredCampaigns.get(tacticRecordTypeId);
        List<Campaign> programCampaigns = filteredCampaigns.get(programRecordTypeId);
        List<Campaign> masterCampaigns = filteredCampaigns.get(masterRecordTypeId);
        
        if (tacticCampaigns != null && !tacticCampaigns.isEmpty()) {
            CampaignHelper.popoulateParentCampaignPeriod(tacticCampaigns, null);
        }

        if (programCampaigns != null && !programCampaigns.isEmpty()) {

        }

        if (masterCampaigns != null && !masterCampaigns.isEmpty()) {

        }
    }
    
    public override void beforeUpdate(){ 
        Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id masterRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        
        Map<Id, List<Campaign>> filteredCampaign = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.new);
        List<Campaign> newTacticCampaigns = filteredCampaign.get(tacticRecordTypeId);
        List<Campaign> newProgramCampaigns = filteredCampaign.get(programRecordTypeId);
        List<Campaign> newMasterCampaigns = filteredCampaign.get(masterRecordTypeId);

        Map<Id, List<Campaign>> filteredOldCampaign = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.old);
        List<Campaign> oldTacticCampaigns = filteredOldCampaign.get(tacticRecordTypeId);
        List<Campaign> oldProgramCampaigns = filteredOldCampaign.get(programRecordTypeId);
        List<Campaign> oldMasterCampaigns = filteredOldCampaign.get(masterRecordTypeId);
        
        if (newTacticCampaigns != null && !newTacticCampaigns.isEmpty() && oldTacticCampaigns != null && !oldTacticCampaigns.isEmpty()) {
            Map<Id, Campaign> listOldTacticMapID = new Map<Id, Campaign>(oldTacticCampaigns);
            CampaignHelper.preProcessCampaign(newTacticCampaigns, listOldTacticMapID);
            CampaignHelper.campaignStatusManager(newTacticCampaigns, listOldTacticMapID);
        }

        if (newProgramCampaigns != null && !newProgramCampaigns.isEmpty() && oldProgramCampaigns != null && !oldProgramCampaigns.isEmpty()) {
            Map<Id, Campaign> listOldProgramMapID = new Map<Id, Campaign>(oldProgramCampaigns);
            CampaignHelper.preProcessCampaign(newProgramCampaigns, listOldProgramMapID);
            CampaignHelper.campaignStatusManager(newProgramCampaigns, listOldProgramMapID);
        }

        if (newMasterCampaigns != null && !newMasterCampaigns.isEmpty() && oldMasterCampaigns != null && !oldMasterCampaigns.isEmpty()) {
            Map<Id, Campaign> listOldMasterMapID = new Map<Id, Campaign>(oldMasterCampaigns);
            CampaignHelper.preProcessCampaign(newMasterCampaigns, listOldMasterMapID);
            CampaignHelper.campaignStatusManager(newMasterCampaigns, listOldMasterMapID);
        }
    }
    
    public override void afterUpdate(){
        Id tacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id masterRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        
        Map<Id, List<Campaign>> filteredCampaign = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.new);
        List<Campaign> newTacticCampaigns = filteredCampaign.get(tacticRecordTypeId);
        List<Campaign> newProgramCampaigns = filteredCampaign.get(programRecordTypeId);
        List<Campaign> newMasterCampaigns = filteredCampaign.get(masterRecordTypeId);

        Map<Id, List<Campaign>> filteredOldCampaign = Utility.filterCampaignByRecordTypeId((List<Campaign>) Trigger.old);
        List<Campaign> oldTacticCampaigns = filteredOldCampaign.get(tacticRecordTypeId);
        List<Campaign> oldProgramCampaigns = filteredOldCampaign.get(programRecordTypeId);
        List<Campaign> oldMasterCampaigns = filteredOldCampaign.get(masterRecordTypeId);
        
        if (newTacticCampaigns != null && !newTacticCampaigns.isEmpty() && oldTacticCampaigns != null && !oldTacticCampaigns.isEmpty()) {
            Map<Id, Campaign> listOldTacticMapID = new Map<Id, Campaign>(oldTacticCampaigns);
            CampaignHelper.popoulateParentCampaignPeriod(newTacticCampaigns, listOldTacticMapID);
        }

        if (newProgramCampaigns != null && !newProgramCampaigns.isEmpty() && oldProgramCampaigns != null && !oldProgramCampaigns.isEmpty()) {

        }

        if (newMasterCampaigns != null && !newMasterCampaigns.isEmpty() && oldMasterCampaigns != null && !oldMasterCampaigns.isEmpty()) {

        }
    }
}