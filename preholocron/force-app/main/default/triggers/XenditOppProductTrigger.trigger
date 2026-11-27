trigger XenditOppProductTrigger on Xendit_Opportunity_Product__c (before insert, before update, before delete, after insert, after update,after delete) {
    if (trigger.isBefore)
    {
        if(trigger.isInsert){
            XenditOppProductHelper.CalculateInitialValue(trigger.new, trigger.isInsert);
            XenditOppProductHelper.setParentOpportunity(trigger.new);
        }
        else if(trigger.isUpdate){
            XenditOppProductHelper.setParentOpportunity(trigger.new);
            XenditOppProductHelper.setApprovalLevel(trigger.new);
        }
        else if (trigger.isDelete) {
            XenditOppProductHelper.CheckParentOpportunityLocked(trigger.old);
        }
    }
    
    
    /**********************************************************************************************************************
    * On insert : Refresh Ramp records & Recalculate values
    * On update : If Total revenue || TPV is changed - Refresh Ramp records & Recalculate values
    * On delete : Recalculate values for Grand Parent Opportunity
    *********************************************************************************************************************/
    
    if (trigger.isAfter) 
    {
        
        if (trigger.isInsert) {
            XenditOppProductHelper.afterInsert(trigger.new);
        }
        else if (trigger.isUpdate){
            XenditOppProductHelper.afterUpdate(trigger.new, trigger.oldMap);
        }
        else if (trigger.isDelete) {
            set<id>recalculateRampIds=new set<id>();
            set<id>childOpp=new set<id>();
            map<id,id> childParentMap=new map<id,id>();
            
            for(Xendit_Opportunity_Product__c prod:trigger.old)
                childOpp.add(prod.Opportunity__c);
            
            for(Opportunity record:[select Parent_Opportunity__c from Opportunity where id=:childOpp]){
                childParentMap.put(record.id,record.Parent_Opportunity__c);
            }
            
            for(Xendit_Opportunity_Product__c prod:trigger.old){
                recalculateRampIds.add(childParentMap.get(prod.Opportunity__c));
            }
                
            if(!recalculateRampIds.isEmpty()){  
                Xendit_CalculateEstimatedValues.caculateFormulaFields(recalculateRampIds);
                XenditOppProductHelper.updateChildOppName(trigger.old);
            }
        }
    
        
    } 
}