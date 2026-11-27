@isTest
public class UtilityTest {
	@isTest
    static void testGetMapPicklist() {
        Test.StartTest();
        Map<String, String> mapTest = Utility.getMapPicklist('Lead', 'Status');
        Test.StopTest();
    }
    
    @isTest
    static void testGetFieldOptions() {
        Test.StartTest();
        List<SelectOption> listOptions = Utility.getFieldOptions('Lead', 'Status', true);
        Test.StopTest();
    }
    
    @isTest
    static void testValueConversion() {
        Test.StartTest();
        Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();
        Decimal result = Utility.valueConversion(conversionRateMap, 1000.99, 'USD', 'USD');
        Test.StopTest();
    }
    
    @isTest
    static void testGetObjectPrefix() {
        Test.StartTest();
        String objPrefix = Utility.getObjectPrefix('Lead');
        Test.StopTest();
    }
    
    @isTest
    static void testAdminProfilesSet() {
        Test.StartTest();
        Set<String> setProfile = Utility.adminProfilesSet();
        Test.StopTest();
    }
    
    @isTest
    static void testConvertStringtoListbyComma() {
        Test.StartTest();
        List<List<String>> listTemp = new List<List<String>>();
        List<String> listA = new List<String>();
        listA.add('test 1');
        listA.add('test 2');
        listA.add('test 3');
        listTemp.add(listA);
        
        List<List<String>> stringTrim = Utility.convertStringtoListbyComma(listTemp);
        Test.StopTest();
    }
    
    @isTest
    static void testFilterCampaignByRecordTypeId() {
        Test.StartTest();
        String masterRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        String programRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String tacticRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        
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
        
        List<Campaign> tempCampaign = new List<Campaign>();
        tempCampaign.add(recMaster);
        tempCampaign.add(recProgram);
        tempCampaign.add(recTactic);
        
        Map<Id, List<Campaign>> tempResult = Utility.filterCampaignByRecordTypeId(tempCampaign);
        Test.StopTest();
    }
}