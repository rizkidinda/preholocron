/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
private class CampaignTest {
    @isTest
    static void testCampaign() {
        String masterRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        String programRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String tacticRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        
        Test.startTest();
   		Campaign recMaster = new Campaign(RecordTypeId = masterRecType, Name = 'Test Master Campaign' + system.now(), Objective__c = 'Demand Gen');
        insert recMaster;
        
        Campaign recProgram = new Campaign();
        recProgram.ParentId = recMaster.Id;
        recProgram.RecordTypeId = programRecType;
        recProgram.Name = 'Test Program Campaign' + system.now();
        recProgram.Objective__c = 'Pipe Gen';
        recProgram.Offer_Type__c = 'Landing Page';
        insert recProgram;
        
        Campaign recTactic = new Campaign(ParentId = recProgram.Id, RecordTypeId = tacticRecType, Name = 'Test Tactic Campaign' + system.now(), startDate = Date.Today(), endDate = Date.Today() + 30);
        insert recTactic;
        
        recProgram.EndDate = date.today();
        update recProgram;
        Test.stopTest();
    }
}