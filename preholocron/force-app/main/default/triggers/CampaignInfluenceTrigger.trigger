/**
 * @description       : 
 * @group             : 
 * @last modified on  : 06-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger CampaignInfluenceTrigger on CampaignInfluence (before insert, after insert, after update, after delete) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            CampaignInfluenceHelper.PopulateExternalId(trigger.new);
        }
    }
    if(trigger.isAfter){
        if(trigger.isInsert){
            CampaignInfluenceHelper.UpdateCampaignInfluencePercentage(trigger.new);
            CampaignInfluenceHelper.calculateCampaignRevenueFields(trigger.new, null);
        }else if(trigger.isUpdate){
            CampaignInfluenceHelper.calculateCampaignRevenueFields(trigger.new, trigger.oldMap);
        }else if(trigger.isDelete){
            CampaignInfluenceHelper.UpdateCampaignInfluencePercentage(trigger.old);
        }
    }
}