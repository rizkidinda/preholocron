/**
 * @description       : 
 * @group             : 
 * @last modified on  : 18-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new OpportunityContactRoleHandler().run();
}