@isTest
private class XenditOppProductHelperTest {
    @TestSetup
    static void createTestData() {
        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        p1.Basket_Size_Enterprise__c = 4;
        p1.Basket_Size_MM__c = 3;
        p1.Basket_Size_SME__c = 2;
        p1.Basket_Size_Individuals__c = 1;
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
        insert(ld1);

        Interested_Product_Channel__c ipc1 = new Interested_Product_Channel__c();
        ipc1.Lead__c = ld1.Id;
        ipc1.Channel_Potential_TPV_local__c = 100000000;
        ipc1.Product__c = p1.Id;
        ipc1.CurrencyIsoCode = 'IDR';
        insert(ipc1);
        
        List<Opportunity> insertParentOppList = new List<Opportunity>();
        List<Opportunity> insertChildOppList = new List<Opportunity>();
        List<Xendit_Opportunity_Product__c> insertProductList = new List<Xendit_Opportunity_Product__c>();
        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        acc.Customer_Folder_URL__c = 'test.com';
        insert acc;
        
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c=system.today()+30;
        opp.CloseDate=system.today()+60;
        opp.StageName='Qualification';
        insertParentOppList.add(opp);

        Opportunity opp2=new Opportunity();
        opp2.Name='Parent Opp2';
        opp2.AccountId=acc.id;
        opp2.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp2.CurrencyIsoCode='IDR';
        opp2.Xst_Txn_Act_Date__c=system.today()+10;
        opp2.CloseDate=system.today()+60;
        opp2.StageName='Qualification';
        insertParentOppList.add(opp2);

        insert insertParentOppList;
       
        //create child
        Opportunity childOpp=new Opportunity();
        childOpp.Name='Child Opp';
        childOpp.Parent_Opportunity__c=opp.id;
        childOpp.AccountId=acc.id;
        childOpp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        childOpp.CurrencyIsoCode='IDR';
        childOpp.Xst_Txn_Act_Date__c=system.today()+30;
        childOpp.CloseDate=system.today()+60;
        childOpp.StageName='Qualification';
        insertChildOppList.add(childOpp);
        insert insertChildOppList;
        
        Xendit_Price_Book__c pb = new Xendit_Price_Book__c();
        pb.Name = 'Test PB';
        pb.Active__c = true;
        pb.CurrencyIsoCode = 'IDR';
        insert pb;
        
        Rate_Card__c rcTest = new Rate_Card__c();
        rcTest.Xendit_Price_Book__c = pb.Id;
        insert rcTest;
        
        Xendit_Opportunity_Product__c prod1= new Xendit_Opportunity_Product__c();
        prod1.Basket_Size__c=200;
        prod1.Opportunity__c=childOpp.id;
        prod1.Rate_Card__c = rcTest.Id;
        prod1.From_Lead_Conversion__c = TRUE;
        insertProductList.add(prod1);
        
        insert insertProductList;  
    }
    
    static testMethod void testAutoCalculateOppProduct(){
        Test.startTest();

        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(ld.id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
		lc.setOwnerId(UserInfo.getUserId());
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Xendit_Opportunity_Product__c xOppProd = [SELECT Id, Opportunity__c, Billing_Type__c, Total_Revenue__c FROM Xendit_Opportunity_Product__c LIMIT 1];
        xOppProd.Total_Revenue__c = 1000; 
        update xOppProd;
        
        Test.stopTest();
    }

}