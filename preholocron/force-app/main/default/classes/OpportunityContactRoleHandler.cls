/**
 * @description       : 
 * @group             : 
 * @last modified on  : 20-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class OpportunityContactRoleHandler extends TriggerHandler {
    // public override void beforeInsert(){ 
        
    // }
    // public override void beforeUpdate() {
        
    // }
    // public override void beforeDelete() {
        
    // }
    public override void afterInsert() {
        OpportunityContactRoleHelper.campaignInfluenceChecker((List<OpportunityContactRole>) Trigger.new, (Map<Id, OpportunityContactRole>) Trigger.oldMap);
    }
    // public override void afterUpdate() {
        
    // }
    // public override void afterDelete() {
        
    // }
    // public override void afterUndelete() {
        
    // }
}