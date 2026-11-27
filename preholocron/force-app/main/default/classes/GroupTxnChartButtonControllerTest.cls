/**
 * @description       : 
 * @group             : 
 * @last modified on  : 16-10-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
@isTest
private class GroupTxnChartButtonControllerTest {
    static void DataHelper(){
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        //acc1.Estimated_1st_Txn_Date__c = Date.today() + 10;
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123CHARTTEST';
        acc1.Type = 'REGULAR';
        insert acc1;

        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        insert p1;

        Transaction__c tr1 = new Transaction__c();
        tr1.Account__c = acc1.Id;
        tr1.Date__c = Date.today();
        tr1.Aggregated_Type__c = 'Monthly';
        tr1.Transaction_Count__c = 1;
        tr1.Product_Lookup__c = p1.Id;
        tr1.Business_ID__c = acc1.Business_ID__c;
        tr1.TPV_USD__c = 10000;
        insert tr1;

    }

    @isTest(SeeAllData='true')
    private static void testRunReport(){
        Test.startTest();
        DataHelper();

        Account getAccount = [SELECT Id FROM Account WHERE Business_ID__c = 'TEST123CHARTTEST' LIMIT 1];
        String resultSave = GroupTransactionChartButtonController.setupData(getAccount.Id, true, 'Account_with_Transactions_Group');

        Test.stopTest();
    }
    
    @isTest(SeeAllData='true')
    public static void testSetupReportURL() {
        Test.startTest();
        Report rt = [SELECT Id,Name, DeveloperName FROM Report WHERE Name LIKE '%L60D Weekly Revenue for Group Account%' LIMIT 1];
        String testReportUrl = GroupTransactionChartButtonController.setupReportURL(rt.DeveloperName);
        String expectedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Report/' + rt.Id + '/view';
        System.assertEquals(expectedUrl, testReportUrl);
        Test.stopTest();
    }

}