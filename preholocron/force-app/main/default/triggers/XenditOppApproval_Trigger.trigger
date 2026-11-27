/*
Type Name: XenditOppApproval_Trigger
Author: Xendit
Created Date: 27/09/2022
Description: Opportunity Approval Apex Trigger
Change History:
27/09/2022      BCX Admin       Created
08/03/2023      GDevita         SFDC-133: Pricing Approval revamp
*/

trigger XenditOppApproval_Trigger on Opportunity_Approval__c (before insert, before update, after update) {
    if(!TriggerBypassUtility.opportunityApprovalTriggerBypass){
        if(trigger.isBefore){
            if(trigger.isInsert){
                XenditOppApproval_TriggerHandler.beforeInsert(trigger.new);
            }
            else if(trigger.isUpdate){
                XenditOppApproval_TriggerHandler.beforeUpdate(trigger.new, trigger.oldMap);
            }
        }
        else if(trigger.isAfter){
            if(trigger.isUpdate){
                XenditOppApproval_TriggerHandler.afterUpdate(trigger.new);
            }
        }
    }
}