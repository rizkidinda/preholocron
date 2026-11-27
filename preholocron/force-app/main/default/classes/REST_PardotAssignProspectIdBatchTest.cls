/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest
private class REST_PardotAssignProspectIdBatchTest {
    static void createData(){
        Lead ld1 = new Lead();
        ld1.Xendit_Account_Email__c = 'test.merchant1@test.com';
        ld1.Company = 'Test Merchant Company';
        ld1.Brand__c = 'Test Merchant 1';
        ld1.Business_ID__c = '12929kdmduh28ejm2292';
        ld1.CurrencyIsoCode = 'IDR';
        ld1.MobilePhone = '22918273';
        ld1.Website = 'https://test-merchant1.com';
        ld1.Number_of_Employees_Lead_Qual__c = '75';
        ld1.Status = 'New';
        ld1.LeadSource = 'Website';
        ld1.LastName = 'Test Merchant';
        ld1.Email = 'test.merchant1@test.com';
        ld1.Country_of_HQ__c = 'Indonesia';
        ld1.Country = 'Indonesia';
        ld1.Child_Industry_v2__c = 'others';
        ld1.Industry_Category__c = 'Others';
        ld1.Referral_Code__c = 'XNDT123';
        ld1.Business_Entity_Type__c = 'id_individual';
        ld1.Expected_Transaction_Volume__c = 'lt $10K';
        ld1.Average_Transaction_Size_Lead_Qual__c = '10K - 50K USD per month';
        ld1.Estimated_Transactions_Handle_Each_Month__c = '25 - 100';
        ld1.Contact_Person_Role_Lead_Qual__c = 'Founder / Owner / Director';
        ld1.How_do_you_want_to_use_Xendit__c = 'intent_api';
        ld1.Segments__c = 'Enterprise';
        ld1.Estimated_1st_Transaction_Date__c = date.today();
        ld1.Visitor_ID__c = '1234567';
        ld1.pi__url__c = 'http://pardot.com?id=8888';
        insert(ld1);
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        insert(acc1);

        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        cnt1.Visitor_ID__c = '8901234';
        insert(cnt1);
        
        cnt1.pi__url__c = 'http://pardot.com?id=7777';
        update cnt1;
    }

    static testMethod void testBatch(){
        
        Test.startTest();
        createData();
        System.schedule('Assign Lead to Prospect Id Test', '0 00 * * * ?', new REST_PardotAssignProspectIdBatch(1,'Lead'));
        System.schedule('Assign Contact to Prospect Id Test', '0 00 * * * ?', new REST_PardotAssignProspectIdBatch(1,'Contact'));
        Test.stopTest();
        
    }
}