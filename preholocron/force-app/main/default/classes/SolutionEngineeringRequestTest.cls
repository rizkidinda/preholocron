/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
private class SolutionEngineeringRequestTest {
    @TestSetup
    static void createTestData() {
        Test.startTest();
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Segment__c = 'Individual';
        acc1.Customer_Folder_URL__c = 'test.com';
        TriggerBypassUtility.accountTriggerBypass = true;
        insert(acc1);
        TriggerBypassUtility.accountTriggerBypass = false;
        
        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        insert(cnt1);
        
        Opportunity op1 = new Opportunity();
        op1.Name = 'Opp Parent 1';
        op1.Type = 'New Acquisition';
        op1.AccountId = acc1.Id;
        op1.ContactId = cnt1.Id;
        op1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op1.NextStep = 'Test';
        op1.StageName = 'Qualification';
        op1.ForecastCategoryName = 'Omitted';
        op1.CloseDate = Date.today() + 11;
        op1.Xst_Txn_Act_Date__c = Date.today();
        op1.StageName = 'Qualification';
        op1.Pains_Priorities_and_Needs__c = 'test';
        op1.Has_Competitor__c = 'No';
        op1.Sales_Goals_Plan__c = 'test';
        op1.Standard_Financial_Terms__c = 'Yes';
        op1.Customer_Signed_Contract_URL__c = 'test.com';
        insert op1;
        Test.stopTest();
    }

    @isTest
    static void createRecordTest(){
        Opportunity opp = [SELECT Id, RecordType.Name FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Solution_Engineering_Request__c rec = new Solution_Engineering_Request__c(Opportunity__c = opp.Id, Language__c = 'en', Specific_merchant_teams_impacted__c = 'test', Is_Merchant_an_existing_client_of_ours__c = 'No', Xendit_Entity_on_contract__c = 'PT Sinar', Merchant_IT_Resources_avalabilities__c = 'Yes', Any_third_parties_will_be_involved__c = 'Yes');
        insert rec;
    }
}