@isTest
public class CampaignAutoProgressTest {
	@testSetup
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
        recProgram.isActive = true;
        recProgram.Status = 'Planned';
        insert recProgram;
        
        Campaign recProgram2 = new Campaign();
        recProgram2.ParentId = recMaster.Id;
        recProgram2.RecordTypeId = programRecType;
        recProgram2.Name = 'Test Program Campaign 2' + system.now();
        recProgram2.Objective__c = 'Pipe Gen';
        recProgram2.Offer_Type__c = 'Landing Page';
        recProgram2.isActive = true;
        recProgram2.StartDate = Date.Today() - 7;
        recProgram2.Campaign_Association_End_Date__c = Date.Today() - 1;
        recProgram2.EndDate = Date.Today() - 1;
        recProgram2.Status = 'In Progress';
        insert recProgram2;
        
        Campaign recTactic = new Campaign(ParentId = recProgram.Id, RecordTypeId = tacticRecType, Name = 'Test Tactic Campaign' + system.now(), startDate = Date.Today(), endDate = Date.Today() + 30);
        insert recTactic;
        
        recProgram.EndDate = date.today();
        update recProgram;
        Test.stopTest();
    }
    
    @isTest
    static void testRunBatch(){
        Test.StartTest();
        CampaignAutoProgressSch sch = new CampaignAutoProgressSch();
        sch.execute(null);
        Test.StopTest();
    }
}