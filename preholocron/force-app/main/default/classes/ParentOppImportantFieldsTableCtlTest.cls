/**
 * @description       : 
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
public class ParentOppImportantFieldsTableCtlTest {
    static testmethod void TestLogic(){
        
        Test.startTest();
        List<Product2> insertProductList = new List<Product2>();
        List<Rate_Card__c> insertRateCardList = new List<Rate_Card__c>();
        List<Opportunity> insertOppList = new List<Opportunity>();
        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        insertProductList.add(p1);
        
        Product2 p2 = new Product2();
        p2.Name = 'Test Prod2';
        p2.ProductCode ='TESTP2';
        p2.CurrencyIsoCode = 'IDR';
        p2.Family = 'Escrow';
        p2.IsActive = true;
        insertProductList.add(p2);
        
        Product2 p3 = new Product2();
        p3.Name = 'Test Prod3';
        p3.ProductCode ='TESTP3';
        p3.CurrencyIsoCode = 'IDR';
        p3.Family = 'Iluma Products';
        p3.IsActive = true;
        insertProductList.add(p3);

        insert insertProductList;
        
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
        insertRateCardList.add(r1);
        
        Rate_Card__c r2 = new Rate_Card__c();
        r2.Xendit_Price_Book__c = xp1.Id;
        r2.Brand__c = 'Xendit';
        r2.Channel__c = 'BCA';
        r2.Product__c = p2.Id;
        r2.Fixed_Rate__c = 100;
        r2.Rate_Per_Txn__c = 0.5;
        insertRateCardList.add(r2);
        
        Rate_Card__c r3 = new Rate_Card__c();
        r3.Xendit_Price_Book__c = xp1.Id;
        r3.Brand__c = 'Illuma';
        r3.Channel__c = 'KTP OCR';
        r3.Product__c = p3.Id;
        r3.Rate_Per_Event__c = 100;
        insertRateCardList.add(r3);

        insert insertRateCardList;
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Segment__c = 'Enterprise';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        insert(acc1);
        
        Opportunity op1 = new Opportunity();
        op1.Name = 'Opp Parent 1';
        op1.Type = 'New Acquisition';
        op1.AccountId = acc1.Id;
        op1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op1.NextStep = 'Test';
        //op1.Country__c = 'Indonesia';
        //op1.Country_of_HQ__c = 'Indonesia';
        op1.StageName = 'Qualification';
        op1.ForecastCategoryName = 'Omitted';
        op1.CloseDate = Date.today() + 11;
        op1.Xst_Txn_Act_Date__c = Date.today();
        op1.Xendit_Price_Book__c = xp1.Id;
        op1.CurrencyIsoCode = 'IDR';
        op1.Weekly_Update__c = 'testWeeklyUpdate';
        insert op1;
        
        Opportunity op2 = op1.clone();
        op2.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op2.Parent_Opportunity__c = op1.Id;
        op2.Product_Family__c = 'eWallets';
        op2.Xendit_Price_Book__c = xp1.Id;
        op2.CurrencyIsoCode = 'IDR';
        insert op2;

        Xendit_Opportunity_Product__c prod1= new Xendit_Opportunity_Product__c();
        prod1.Basket_Size__c=200;
        prod1.Opportunity__c=op2.id;
        prod1.Product__c = p1.Id;
        prod1.Rate_Card__c = insertRateCardList[0].Id;
        insert prod1;
        
        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        prod1.CurrencyIsoCode = 'IDR';
        update prod1;

        Channel_KYC__c kyc1 = new Channel_KYC__c(CurrencyIsoCode = 'IDR', Account__c = acc1.Id, Status__c = 'LIVE', Product__c = p1.Id);
        
        Test.stopTest();
        
        String getOppData = ParentOppImportantFieldsTableController.getOppData(op1.Id);
        getOppData.replace('testWeeklyUpdate', 'testWeeklyUpdate1');
        String resultOppData = ParentOppImportantFieldsTableController.saveOppData (getOppData);
        
        
    }
}