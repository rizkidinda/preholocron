/**
 * @description       : 
 * @group             : 
 * @last modified on  : 27-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update,after delete, after undelete) {
    if(!TriggerBypassUtility.opportunityTriggerBypass){
        if (trigger.isBefore) {
            if (trigger.isInsert) {
                OpportunityHelper.CheckParentOpportunityLocked(trigger.new);
                OpportunityHelper.UpdateWeeklyUpdateHistory(trigger.new, null);
                OpportunityHelper.setBDProspectingStage(trigger.new, null);
                OpportunityHelper.convertToUSD(trigger.new, null);
                OpportunityHelper.updateUpsellApproval(trigger.new, null);
                //OpportunityHelper.getUpsellRevenueGoalValue(trigger.new, null, 'Opportunity');
            }
            else if (trigger.isUpdate) {
                // OpportunityHelper.CheckParentOpportunityLocked(trigger.new);
                OpportunityHelper.CheckAccountContact(trigger.new);
                OpportunityHelper.CheckChildOpptyCurrency(trigger.new, trigger.oldMap);
                OpportunityHelper.UpdateWeeklyUpdateHistory(trigger.new, trigger.oldMap);
                OpportunityHelper.setBDProspectingStage(trigger.new, trigger.oldMap);
                OpportunityHelper.checkParentOpportunityPricingApproval(trigger.new, trigger.oldMap, trigger.isBefore);
                OpportunityHelper.convertToUSD(trigger.new, trigger.oldMap);
                OpportunityHelper.updateOpportunityStageAndBDProspecting(trigger.new, trigger.oldMap);
                OpportunityHelper.updateUpsellApproval(trigger.new, trigger.oldMap);
                OpportunityHelper.getUpsellRevenueGoalValue(trigger.new, trigger.oldMap, 'Opportunity');
                OpportunityHelper.getHIRO(trigger.new, trigger.oldMap);
            }
            else if (trigger.isDelete) {
                OpportunityHelper.CheckParentOpportunityLocked(trigger.old);
            }
        }
        else if (trigger.isAfter) {
            if (trigger.isInsert || trigger.isUpdate) {
				OpportunityHelper.UpdateParentStage(trigger.new, trigger.old);
                OpportunityHelper.CheckUpdateParentFields(trigger.new, trigger.old);
            }
            
            /**********************************************************************************************************************
            * On insert of Parent opportunity : Create Ramps for Parent
            * On update of Opportunity : 
            * 			 Parent - 
            * 					  Refresh Ramp = true || Transaction is changed - Refresh Ramp records & Recalculate values
            * 			 Child  - 
            * 					  Parent is changed			- Refresh Ramp records & Recalculate values for new & old parent
            * 					  Probability is changed	- Recalculate values
            * On delete of Child Opportunity : Recalculate values for Parent
            * On undelete of Child Opportunity : Recalculate values for Parent
            *********************************************************************************************************************/
            
            if(trigger.isInsert){
                set<id>parentIds=new set<id>();
                for(Opportunity opp:trigger.new)
                {
                    if(opp.Parent_Opportunity__c==null)
                        parentids.add(opp.id);
                }
                if(!parentIds.isEmpty())
                    Xendit_CreateParentRampRecords.createRampOnOppInsert(parentIds);
                
            }
            
            else if(trigger.isUpdate)
            {
                set<id>refreshRampIds=new set<id>();
                set<id>recalculateRampIds=new set<id>();
                for(Opportunity opp:trigger.new)
                {
                    Opportunity oldOpp=trigger.oldMap.get(opp.id);
                    /***Parent***/
                    if(opp.Parent_Opportunity__c==null && (opp.Refresh_Ramp__c ||(opp.Xst_Txn_Act_Date__c!=oldOpp.Xst_Txn_Act_Date__c) || (opp.CurrencyIsoCode != oldOpp.CurrencyIsoCode) || (opp.OwnerId != oldOpp.OwnerId)))
                    {
                        refreshRampIds.add(opp.id);
                        recalculateRampIds.add(opp.id);
                    }
                    /***Child***/
                    else if (opp.Parent_Opportunity__c!=null)
                    {
                        if(opp.Probability!=oldOpp.Probability)
                            recalculateRampIds.add(opp.Parent_Opportunity__c);
                        if(opp.Parent_Opportunity__c!=oldOpp.Parent_Opportunity__c){
                            refreshRampIds.add(opp.Parent_Opportunity__c);
                            recalculateRampIds.add(opp.Parent_Opportunity__c);
                            if(oldOpp.Parent_Opportunity__c!=null){
                                refreshRampIds.add(oldOpp.Parent_Opportunity__c);
                                recalculateRampIds.add(oldOpp.Parent_Opportunity__c);
                            }
                        }
                    } 
                }
                
                if(!refreshRampIds.isEmpty()) 
                    Xendit_CreateChildRampRecords.createRampRecords(refreshRampIds);
                if(!Xendit_CalculateEstimatedValues.boolOppProductRecalculate && !recalculateRampIds.isEmpty())
                    Xendit_CalculateEstimatedValues.caculateFormulaFields(recalculateRampIds);
    
                OpportunityHelper.AutoClosedWonChildOpportunity(Trigger.New, Trigger.oldMap);
                OpportunityHelper.checkParentOpportunityPricingApproval(trigger.new, trigger.oldMap, trigger.isBefore);
                OpportunityHelper.UpdateOppStageWithContactRole(Trigger.New, Trigger.oldMap);
                OpportunityHelper.UpdateCampaignMemberStatusClosedWon(Trigger.New, Trigger.oldMap);
            }
            
            else if (trigger.isDelete||trigger.isunDelete)
            {
                set<id>recalculateRampIds=new set<id>();
                list<Opportunity> oppList=trigger.isDelete?trigger.old:trigger.new;
                for(Opportunity opp:oppList){
                    if(opp.Parent_Opportunity__c!=null)
                        recalculateRampIds.add(opp.Parent_Opportunity__c);
                }
                if(!Xendit_CalculateEstimatedValues.boolOppProductRecalculate && recalculateRampIds.size()>0)
                    Xendit_CalculateEstimatedValues.caculateFormulaFields(recalculateRampIds);
            }
        }
    }
}