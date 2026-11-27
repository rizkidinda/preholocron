/**
 * @description       : 
 * @group             : 
 * @last modified on  : 19-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger CampaignMemberTrigger on CampaignMember (after insert, after update, after delete) {
    if(!TriggerBypassUtility.campaignMemberTriggerBypass){
        if(trigger.isAfter){
            if(trigger.isInsert){
                CampaignMemberHelper.AutoCreateCrossSellUpsellOpportunity(trigger.new, null);
                CampaignMemberHelper.TacticCampaignMemberDataUpdate(trigger.new, null, trigger.operationType);

                if (trigger.isAfter) {
                    CampaignMemberHelper.rollUpTacticEngagedCampaignMemberStatus(trigger.new, null);
                }
            }else if(trigger.isUpdate){
                CampaignMemberHelper.AutoCreateCrossSellUpsellOpportunity(trigger.new, trigger.oldMap);
                CampaignMemberHelper.TacticCampaignMemberDataUpdate(trigger.new, trigger.oldMap, trigger.operationType);

                if (trigger.isAfter) {
                    CampaignMemberHelper.cascadeDownProgramCampaignMemberStatus(trigger.new, trigger.oldMap);
                    CampaignMemberHelper.countCampaignObjectiveActualResponse(trigger.new, trigger.oldMap);
                }
            }else if(trigger.isDelete){
                CampaignMemberHelper.DeleteTacticCampaignMember(trigger.old);
            }
        }
    }
}