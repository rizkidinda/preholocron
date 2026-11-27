/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest
private class ProductTriggerTest {
    @TestSetup
    static void makeData(){
        List<Account> accList = new List<Account>();
        List<Channel_KYC__c> channelList = new List<Channel_KYC__c>();

        Product2 product1 = new Product2(Name = 'Product 1', ProductCode ='TESTP1', CurrencyIsoCode = 'IDR', Family = 'eWallets', IsActive = true);
        insert product1;

        for(integer i = 0 ; i < 10 ; i++){
            Account temp = new Account(Name = 'Test Account ' + i, NumberOfEmployees = 100, Industry_Category__c = 'Financial Services', Child_Industry_v2__c = 'Bank', Business_ID__c = 'TEST123' + i);
            accList.add(temp);
        }
        insert accList;

        for(integer i = 0 ; i < 10 ; i++){
            Channel_KYC__c temp = new Channel_KYC__c(Account__c = accList[i].Id, CurrencyIsoCode = product1.CurrencyIsoCode, Product__c = product1.Id, Status__c = 'LIVE');
            channelList.add(temp);
        }
        insert channelList;
    }

    @isTest 
    static void updateChannelTest(){
        Product2 getPrd = [SELECT Id FROM Product2 WHERE ProductCode = 'TESTP1' LIMIT 1 ];
        Product2 updatePrd = new Product2(Id = getPrd.Id, Family = 'QR');

        Test.startTest();
        update updatePrd;
        Test.stopTest();
        System.assertEquals(10, [select count() from Channel_KYC__c where Product_Family__c = 'QR']);
    }
}