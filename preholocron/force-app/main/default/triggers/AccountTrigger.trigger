/**
 * @description       : 
 * @group             : 
 * @last modified on  : 22-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger AccountTrigger on Account (before insert, before update, after insert, after update, after delete) {
    if(!TriggerBypassUtility.accountTriggerBypass){
        if(trigger.isBefore){
            if(trigger.isInsert){
                AccountHelper.setDefaultValuePreProcess(trigger.New, null);
                AccountHelper.updateWeeklyUpdateHistory(trigger.New, null);
            }else if(trigger.isUpdate){
                AccountHelper.updateWeeklyUpdateHistory(trigger.New, trigger.oldMap);
                AccountHelper.updateFirstLastTouchLeadSource(trigger.New, trigger.oldMap);
            }
        }
        else if(trigger.isAfter){
            if(trigger.isInsert){
                AccountHelper.updateAccountOwner(trigger.New, null);
                AccountHelper.updateUltimateParent(trigger.New, null);
            }else if(trigger.isUpdate){
                AccountHelper.updateXPAccountOwner(trigger.New, trigger.oldMap);
                AccountHelper.updateAccountOwner(trigger.New, trigger.oldMap);
                AccountHelper.updateUltimateParent(trigger.New, trigger.oldMap);
                AccountHelper.updateAccountRevenueValues(trigger.New, trigger.oldMap);
                AccountHelper.updateParentAccountName(trigger.New, trigger.oldMap);
                AccountHelper.updateOppBDProspectingStage(trigger.New, trigger.oldMap);
                AccountHelper.CreateOpportunityGLR(trigger.newMap, trigger.oldMap);
                AccountHelper.UpdateCampaignMemberStatusDashboardSignUp(trigger.New, trigger.oldMap);
                AccountHelper.AutoClosedLostOpportunity(trigger.New, trigger.oldMap);
            }
            else if(trigger.isDelete){
                AccountHelper.MergeOpportunitiesOnAccountMerge(trigger.new, trigger.old);
                System.debug('######trigger after delete');
            }
        }
    }
}