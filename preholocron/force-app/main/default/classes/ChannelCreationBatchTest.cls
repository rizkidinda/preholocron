/**
 * @description       : 
 * @group             : 
 * @last modified on  : 04-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest
private class ChannelCreationBatchTest {
    static void createData(){
        //test devops center
        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        insert(p1);

        Xendit_Price_Book__c xp1 = new Xendit_Price_Book__c();
        xp1.Active__c = true;
        xp1.Name = 'TEST PB IDR';
        xp1.CurrencyIsoCode = 'IDR';
        insert(xp1);

        Rate_Card__c r1 = new Rate_Card__c();
        r1.Xendit_Price_Book__c = xp1.Id;
        r1.Brand__c = 'Xendit';
        r1.Channel__c = 'DANA';
        r1.Product__c = p1.Id;
        r1.Fixed_Rate__c = 100;
        r1.Rate_Per_TPV__c = 10;
        insert(r1);

        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        insert(acc1);

        Transaction__c txn1 = new Transaction__c();
        txn1.Account__c = acc1.Id;
        txn1.Product_Lookup__c = p1.Id;
        txn1.Date__c = date.today();
        txn1.CurrencyIsoCode = 'IDR';
        insert(txn1);
    }

    static testMethod void testBatch(){
        
        Test.startTest();
        createData();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ChannelCreationBatch channelSched = new ChannelCreationBatch(1, new Set<Id>{acc.Id});
        String sch = '0 0 1 * * ? *'; 
        System.schedule('Daily_Channel_Creation_Batch_Test', sch, channelSched );
        Test.stopTest();
        
    }
}