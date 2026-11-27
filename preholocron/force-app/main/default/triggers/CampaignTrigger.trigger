/**
 * @description       : 
 * @group             : 
 * @last modified on  : 22-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
trigger CampaignTrigger on Campaign (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new CampaignHandler().run();
}