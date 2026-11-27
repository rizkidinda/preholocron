/**
 * @description       : 
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
public class Test_XenditOpportunityRampClasses {
    static testmethod void createOpp()
    {
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
        
        //ramps are created for parent
        list<Opportunity_Ramp__c> parentRamp=[select id from Opportunity_Ramp__c where Opportunity__c=:opp.id];
        system.debug('parentRamp size : ' + parentRamp.size());
        //system.assertEquals(7, parentRamp.size());
        
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

        //create child
        Opportunity childOpp2=new Opportunity();
        childOpp2.Name='Child Opp2';
        childOpp2.Parent_Opportunity__c=opp2.id;
        childOpp2.AccountId=acc.id;
        childOpp2.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        childOpp2.CurrencyIsoCode='IDR';
        childOpp2.Xst_Txn_Act_Date__c=system.today()+10;
        childOpp2.CloseDate=system.today()+60;
        childOpp2.StageName='Qualification';
        insertChildOppList.add(childOpp2);

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
        insertProductList.add(prod1);

        Xendit_Opportunity_Product__c prod2= new Xendit_Opportunity_Product__c();
        prod2.Basket_Size__c=200;
        prod2.Opportunity__c=childOpp2.id;
        prod2.Rate_Card__c = rcTest.Id;
        insertProductList.add(prod2);

        insert insertProductList;

        test.startTest();

        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        update prod1;
        
        //ramps are created for child opp - prod1
        list<Opportunity_Ramp__c> prod1Ramp=[select id from Opportunity_Ramp__c where Xendit_Opportunity_Product__c=:prod1.id];
        //system.assertEquals(6, prod1Ramp.size());
        
        opp.Xst_Txn_Act_Date__c=system.today()+20;
        opp.Pains_Priorities_and_Needs__c='test';
        opp.Has_Competitor__c = 'No';
        opp.Sales_Goals_Plan__c = 'test';
        opp.Standard_Financial_Terms__c = 'Yes';
        opp.Refresh_Ramp__c = true;
        update opp;
        
        //month=0 ramp transaction date is updated
        Opportunity_Ramp__c firstRamp=[select id,Transaction_Date__c from Opportunity_Ramp__c where Opportunity__c=:opp.id and month__c=1 limit 1];
        system.assertEquals(system.today()+20, firstRamp.Transaction_Date__c);
       
        // prod2.Total_Revenue__c=400000;
        // prod2.TPV__c=6000;
        // prod2.Rate_Per_TPV_List__c=1.5;
        // update prod2;
        
        // //change parent opp from opp2 to opp
        // childOpp2.Parent_Opportunity__c=opp.id;
        // update childOpp2;

        // childOpp2.StageName='Closed Won';
        // childOpp2.Is_Transacting__c = true;
        // update childOpp2;
        
        test.stopTest();
    }
    
    static testmethod void deleteOppProd()
    {
        List<Account> insertAccountList = new List<Account>();

        Account accP=new Account();
        accP.Name='Test Account Parent';
        accP.Segment__c='MM';
        accP.Brand__c='Test Account Parent';
        insert accP;

        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        acc.ParentId=accP.Id;

        insert acc;
        
        List<Opportunity> parentOppList = new List<Opportunity>();
        List<Opportunity> childOppList = new List<Opportunity>();
        List<Xendit_Opportunity_Product__c> xOppList = new List<Xendit_Opportunity_Product__c>();
        
        test.startTest();
        
        //create parent opportunity
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c=system.today()+30;
        opp.CloseDate=system.today()+60;
        opp.StageName='Qualification';
        parentOppList.add(opp);
        
        Opportunity opp2=new Opportunity();
        opp2.Name='Parent Opp2';
        opp2.AccountId=acc.id;
        opp2.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp2.CurrencyIsoCode='IDR';
        opp2.Xst_Txn_Act_Date__c=system.today()+10;
        opp2.CloseDate=system.today()+60;
        opp2.StageName='Qualification';
        parentOppList.add(opp2);
        insert parentOppList;
        
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
        childOppList.add(childOpp);
        
        Opportunity childOpp2=new Opportunity();
        childOpp2.Name='Child Opp2';
        childOpp2.Parent_Opportunity__c=opp2.id;
        childOpp2.AccountId=acc.id;
        childOpp2.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        childOpp2.CurrencyIsoCode='IDR';
        childOpp2.Xst_Txn_Act_Date__c=system.today()+10;
        childOpp2.CloseDate=system.today()+60;
        childOpp2.StageName='Qualification';
        childOppList.add(childOpp2);
        
        insert childOppList;
        
        Xendit_Opportunity_Product__c prod1= new Xendit_Opportunity_Product__c();
        prod1.Basket_Size__c=200;
        prod1.Opportunity__c=childOpp.id;
        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        xOppList.add(prod1);
        
        Xendit_Opportunity_Product__c prod2= new Xendit_Opportunity_Product__c();
        prod2.Basket_Size__c=200;
        prod2.Opportunity__c=childOpp2.id;
        prod2.Total_Revenue__c=400000;
        prod2.TPV__c=6000;
        prod2.Rate_Per_TPV_List__c=1.5;
        xOppList.add(prod2);
        
        insert xOppList;
        
        List<Xendit_Opportunity_Product__c> updateProd = new List<Xendit_Opportunity_Product__c>();

        //prod1.Total_Revenue__c=400000;
        //prod1.TPV__c=6000;
        //prod1.Rate_Per_TPV_List__c=1.5;
        //updateProd.add(prod1);
        
        
        //prod2.Total_Revenue__c=400000;
        //prod2.TPV__c=6000;
        //prod2.Rate_Per_TPV_List__c=1.5;
        //updateProd.add(prod2);

        //update updateProd;
        
        
        //delete 1 prod2
        delete prod2;
        
        //delete 1 child opp2
        //delete childOpp2;
        test.stopTest();
    }
    
    static testmethod void testRampController1()
    {
        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        insert acc;
        
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c=system.today()+30;
        opp.CloseDate=system.today()+60;
        opp.StageName='Qualification';
        insert opp;
        
        test.startTest();

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
        insert childOpp;
        
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
        insert prod1;

        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        update prod1;
        
        Xendit_RampController.displayData data= Xendit_RampController.setupData(opp.id);
        Xendit_RampController.addRampRecord(data, opp.id);
        Xendit_RampController.deleteRampRecord(1, data);
        Xendit_RampController.refreshRampRecord(data);
        // Xendit_RampController.updateData(data);
        
        // Xendit_RampController.deleteRampRecord(10, data);
        // data.opp.StageName='Discovery';
        // Xendit_RampController.updateData(data);
        
        test.stopTest();
    }

    static testmethod void testRampController2()
    {
        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        insert acc;
        
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c=system.today()+30;
        opp.CloseDate=system.today()+60;
        opp.StageName='Qualification';
        insert opp;
        
        test.startTest();

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
        insert childOpp;
        
        Xendit_Opportunity_Product__c prod1= new Xendit_Opportunity_Product__c();
        prod1.Basket_Size__c=200;
        prod1.Opportunity__c=childOpp.id;
        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        insert prod1;
        
        Xendit_RampController.displayData data= Xendit_RampController.setupData(opp.id);
        Xendit_RampController.addRampRecord(data, opp.id);
        // Xendit_RampController.deleteRampRecord(1, data);
        // Xendit_RampController.refreshRampRecord(data);
        // Xendit_RampController.updateData(data);
        
        Xendit_RampController.deleteRampRecord(10, data);
        data.opp.StageName='Discovery';
        Xendit_RampController.updateData(data);
        
        test.stopTest();
    }
    
}