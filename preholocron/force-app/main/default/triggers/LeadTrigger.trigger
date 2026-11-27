trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    if(!TriggerBypassUtility.leadTriggerBypass){
        if(trigger.isBefore){
            if(trigger.isInsert){
                LeadHelper.linkPardotVisitorID(trigger.New, null);
                LeadHelper.UpdateWeeklyUpdateHistory(trigger.New, null);
                LeadHelper.updateUTMCategory(trigger.New, null);
            }else if(trigger.isUpdate){
                LeadHelper.linkPardotVisitorID(trigger.New, trigger.oldMap);
                LeadHelper.UpdateWeeklyUpdateHistory(trigger.New, trigger.oldMap);
                LeadHelper.UpdateFirstLastTouchLeadSource(trigger.New, trigger.oldMap);
                LeadHelper.updateUTMCategory(trigger.New, trigger.oldMap);
            }
        }
       else if(trigger.isAfter){
            if(trigger.isInsert){
                LeadHelper.updateLeadOwner(trigger.New, null);
            }else if(trigger.isUpdate){
                LeadHelper.updateLeadOwner(trigger.New, trigger.oldMap);
                LeadHelper.CreateLeadOppCampaignInfluence(trigger.New, trigger.oldMap);
                LeadHelper.UpdateCampaignMemberStatusDashboardSignUp(trigger.New, trigger.oldMap);
            }
        }
    }
}