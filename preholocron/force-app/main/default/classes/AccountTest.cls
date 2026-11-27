/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
public class AccountTest {
	@TestSetup
    static void createTestData() {
        Test.startTest();
        Account masterAccount = new Account();
        masterAccount.Name = 'Master Account';
        masterAccount.NumberOfEmployees = 100;
        masterAccount.Type = 'REGULAR';
        masterAccount.Brand__c = 'Master Account';
        masterAccount.Legal_Entity_Name__c = 'Master Account';
        masterAccount.Country_of_HQ__c = 'Indonesia';
        masterAccount.BillingCountry = 'Indonesia';
        insert masterAccount;

        Account mergedAccount = new Account();
        mergedAccount.Name = 'Merged Account';
        mergedAccount.NumberOfEmployees = 100;
        mergedAccount.Type = 'REGULAR';
        mergedAccount.Brand__c = 'Merged Account';
        mergedAccount.Legal_Entity_Name__c = 'Merged Account';
        mergedAccount.Country_of_HQ__c = 'Indonesia';
        mergedAccount.BillingCountry = 'Indonesia';
        mergedAccount.Weekly_Update__c = 'test 2';
        insert mergedAccount;

        Contact cnt1 = new Contact();
        cnt1.AccountId = masterAccount.Id;
        cnt1.LastName = 'Test Contact Dummy1';
        cnt1.Email = 'test@account1.com';
        insert(cnt1);

        // Create test data for opportunities
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
        r1.CurrencyIsoCode = 'IDR';
        r1.Rate_Per_Txn__c = 1000;
        r1.Headline_Rate_per_TPV__c = 10;
        r1.Headline_Rate_per_Txn__c = 1000;
        r1.Reseller_Rate_per_TPV__c = 5;
        r1.Reseller_Rate_per_Txn__c = 500;
        r1.Rate_Per_Event__c = 100;
        r1.Rate_Per_Subaccount__c = 100;
        r1.COGS_Fixed_Fee__c = 50;
        r1.COGS_MDR__c = 2.5;
        insertRateCardList.add(r1);
		insert insertRateCardList;
        
        Opportunity op1 = new Opportunity();
        op1.Name = 'Parent Master Opportunity';
        op1.Type = 'New Acquisition';
        op1.AccountId = masterAccount.Id;
        op1.ContactId = cnt1.Id;
        op1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op1.NextStep = 'Test';
        op1.StageName = 'Qualification';
        op1.ForecastCategoryName = 'Omitted';
        op1.CloseDate = Date.today() + 11;
        op1.Xst_Txn_Act_Date__c = Date.today();
        op1.Xendit_Price_Book__c = xp1.Id;
        op1.StageName = 'Qualification';
        op1.Pains_Priorities_and_Needs__c = 'test';
        op1.Has_Competitor__c = 'No';
        op1.Sales_Goals_Plan__c = 'test';
        op1.Standard_Financial_Terms__c = 'Yes';
        op1.Customer_Signed_Contract_URL__c = 'test.com';
        insert op1;
        
        Opportunity op2 = op1.clone();
        op2.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op2.Name = 'Child Master Opportunity';
        op2.Parent_Opportunity__c = op1.Id;
        op2.StageName = 'Qualification';
        insertOppList.add(op2);

        Opportunity op3 = new Opportunity();
        op3.Name = 'Parent Merged Opportunity';
        op3.Type = 'New Acquisition';
        op3.AccountId = mergedAccount.Id;
        op3.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op3.NextStep = 'Test';
        op3.StageName = 'Qualification';
        op3.ForecastCategoryName = 'Omitted';
        op3.CloseDate = Date.today() + 11;
        op3.Xst_Txn_Act_Date__c = Date.today();
        op3.Xendit_Price_Book__c = xp1.Id;
        op3.StageName = 'Qualification';
        op3.Pains_Priorities_and_Needs__c = 'test';
        op3.Has_Competitor__c = 'No';
        op3.Sales_Goals_Plan__c = 'test';
        op3.Standard_Financial_Terms__c = 'Yes';
        op3.Customer_Signed_Contract_URL__c = 'test.com';
        op3.LeadSource = 'Inbound';
        insert op3;
        
        Opportunity op4 = op3.clone();
        op4.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op4.Name = 'Child Merged Opportunity';
        op4.Parent_Opportunity__c = op3.Id;
        op4.StageName = 'Qualification';
        op4.LeadSource = 'Inbound';
        insertOppList.add(op4);
        
        TriggerBypassUtility.opportunityApprovalTriggerBypass = true;
        insert insertOppList;
        TriggerBypassUtility.opportunityApprovalTriggerBypass = false; 
        Test.stopTest();
    }
    
    
    static testmethod void updateUserAccountTest(){
        Id salesProfileId = [SELECT Id FROM Profile WHERE Name = 'Xendit Sales Profile' LIMIT 1].Id;
        Id userroleCEO  = [SELECT Id FROM UserRole WHERE Name Like 'CEO' LIMIT 1].ID;

        User user1 = new user(
                        Alias = 'User1',
                        Country = 'Indonesia', 
                        Email = 'User'+String.valueOf(date.today())+'@Test.com',
                        Username = 'User'+String.valueOf(date.today())+'@Test.com',
                        FirstName = 'User',
                        IsActive = true,
                        LanguageLocaleKey = 'en_US',
                        EmailEncodingKey = 'ISO-8859-1',
                        LastName = 'One',
                        LocaleSidKey = 'en_GB',                     
                        ProfileId = salesProfileId,
                        TimeZoneSidKey = 'GMT',
                        UserroleId = userroleCEO);
        insert user1;

        System.runAs(user1){
            Test.startTest();
            List<Account> insertAccList = new List<Account>();
            Account acc1 = new Account();
            acc1.Name = 'Test Account1';
            acc1.Industry_Category__c = 'Financial Services';
            acc1.Child_Industry_v2__c = 'Bank';
            acc1.NumberOfEmployees = 100;
            acc1.Business_ID__c = 'TEST123';
            acc1.Type = 'NEW';
            insertAccList.add(acc1);

            Account acc2 = new Account();
            acc2.Name = 'Test Account2';
            acc2.Industry_Category__c = 'Financial Services';
            acc2.Child_Industry_v2__c = 'Bank';
            acc2.NumberOfEmployees = 100;
            acc2.Business_ID__c = 'TEST124';
            acc2.Type = 'GROUP';
            acc2.Country_of_HQ__c = 'Indonesia';
            acc2.BillingCountry = 'Indonesia';
            insertAccList.add(acc2);

            insert insertAccList;

            Account acc1_update = new Account(Id = acc1.Id, CP_Manager__c = user1.Id, ParentId = acc2.Id);
            update acc1_update;
            Test.stopTest();
        }
    }

    static testmethod void updateAccountBDStageFields(){
        Id salesProfileId = [SELECT Id FROM Profile WHERE Name = 'Xendit Sales Profile' LIMIT 1].Id;
        Id userroleCEO  = [SELECT Id FROM UserRole WHERE Name Like 'CEO' LIMIT 1].ID;

        User user1 = new user(
                        Alias = 'User1',
                        Country = 'Indonesia', 
                        Email = 'User'+String.valueOf(date.today())+'@Test.com',
                        Username = 'User'+String.valueOf(date.today())+'@Test.com',
                        FirstName = 'User',
                        IsActive = true,
                        LanguageLocaleKey = 'en_US',
                        EmailEncodingKey = 'ISO-8859-1',
                        LastName = 'One',
                        LocaleSidKey = 'en_GB',                     
                        ProfileId = salesProfileId,
                        TimeZoneSidKey = 'GMT',
                        UserroleId = userroleCEO);
        insert user1;

        System.runAs(user1){
            Test.startTest();
            List<Account> insertAccList = new List<Account>();
            Account acc1 = new Account();
            acc1.Name = 'Test Account1';
            acc1.Industry_Category__c = 'Financial Services';
            acc1.Child_Industry_v2__c = 'Bank';
            acc1.NumberOfEmployees = 100;
            acc1.Business_ID__c = 'TEST123';
            acc1.Type = 'NEW';
            acc1.Country_of_HQ__c = 'Indonesia';
            acc1.BillingCountry = 'Indonesia';
            insert acc1;

            Contact cnt1 = new Contact();
            cnt1.AccountId = acc1.Id;
            cnt1.LastName = 'Test Contact1';
            cnt1.Email = 'test@account1.com';
            insert cnt1;

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
            insert op1;

            acc1.Website = 'test.com';
            acc1.Segment__c = 'Individual';
            update acc1;

            Test.stopTest();
        }
    }

    static testmethod void updateAccountOwnertoAM(){
        String divisionAMTeam = '%' + System.Label.AM_DIVISION_DEFAULT + '%';
        User amUser = [SELECT Id FROM User WHERE Division LIKE :divisionAMTeam AND IsActive = TRUE LIMIT 1];
       
        Test.startTest();
        List<Account> insertAccList = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'NEW';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        insert acc1;

        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        insert cnt1;

        acc1.Website = 'test.com';
        acc1.Segment__c = 'Individual';
        acc1.OwnerId = amUser.Id;
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void AccountImportantFieldsTableControllerTest(){
        
        Test.startTest();
        List<Account> insertAccList = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'Test Account 1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'NEW';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        acc1.Weekly_Update__c = 'test';
        insert acc1;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account 2';
        acc2.ParentId = acc1.Id;
        acc2.Industry_Category__c = 'Financial Services';
        acc2.Child_Industry_v2__c = 'Bank';
        acc2.NumberOfEmployees = 100;
        acc2.Business_ID__c = 'TEST456';
        acc2.Type = 'NEW';
        acc2.Country_of_HQ__c = 'Indonesia';
        acc2.BillingCountry = 'Indonesia';
        acc2.Weekly_Update__c = 'test 2';
        insert acc2;

        String strAccData = AccountImportantFieldsTableController.getAccountData(acc1.Id);
        String strSaveResult = AccountImportantFieldsTableController.saveAccData(strAccData);
        
        acc1.Website = 'test.com';
        acc1.Weekly_Update__c = 'test 2';
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void updateXPMAccount(){
        User salesUser = [SELECT Id FROM User WHERE Profile.Name = 'Xendit Sales Profile' AND IsActive = TRUE LIMIT 1];
       
        Test.startTest();
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'XP MASTER';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        insert acc1;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account2';
        acc2.Industry_Category__c = 'Financial Services';
        acc2.Child_Industry_v2__c = 'Bank';
        acc2.NumberOfEmployees = 100;
        acc2.Business_ID__c = 'TEST125';
        acc2.Type = 'XP MANAGED';
        acc2.Country_of_HQ__c = 'Indonesia';
        acc2.BillingCountry = 'Indonesia';
        acc2.ParentId = acc1.Id;
        insert acc2;

        acc1.OwnerId = salesUser.Id;
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void updateAccountToGLRTest(){
        User salesUser = [SELECT Id FROM User WHERE Profile.Name = 'Xendit Sales Profile' AND IsActive = TRUE LIMIT 1];
       
        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        insert p1;
        
        Xendit_Price_Book__c xp1 = new Xendit_Price_Book__c();
        xp1.Active__c = true;
        xp1.Name = 'Indonesia Price Book';
        xp1.CurrencyIsoCode = 'IDR';
        insert(xp1);
        
        Rate_Card__c r1 = new Rate_Card__c();
        r1.Xendit_Price_Book__c = xp1.Id;
        r1.Brand__c = 'Xendit';
        r1.Channel__c = 'DANA';
        r1.Product__c = p1.Id;
        r1.Fixed_Rate__c = 100;
        r1.Rate_Per_TPV__c = 10;
        r1.CurrencyIsoCode = 'IDR';
        r1.Rate_Per_Txn__c = 1000;
        r1.Headline_Rate_per_TPV__c = 10;
        r1.Headline_Rate_per_Txn__c = 1000;
        r1.Reseller_Rate_per_TPV__c = 5;
        r1.Reseller_Rate_per_Txn__c = 500;
        r1.Rate_Per_Event__c = 100;
        r1.Rate_Per_Subaccount__c = 100;
        r1.COGS_Fixed_Fee__c = 50;
        r1.COGS_MDR__c = 2.5;
        insert r1;
        
        Test.startTest();
        GLR_Default_Product__c prdGLR1 = new GLR_Default_Product__c(Country__c = 'Indonesia', Product__c = p1.Id);
        insert prdGLR1;
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'REGULAR';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        acc1.Pipeline_Source__c = 'Undeclared Interest';
        insert acc1;
        
        acc1.GLR_Flag__c = true;
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void updateFirstTouchLastTouch(){        
        Test.startTest();
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'REGULAR';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        insert acc1;
        
        acc1.Heeet__Heeet_First_Click_Campaign_Source__c = 'google';
        acc1.Heeet__Heeet_Google_Campaign_Source__c = 'google';
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void autoCreateDefaultOpp(){        
        Test.startTest();
        
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
        
        GLR_Default_Product__c glrProd = new GLR_Default_Product__c(Country__c = 'Indonesia', Product__c = p1.Id);
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'REGULAR';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        insert acc1;
        
        acc1.Heeet__Heeet_First_Click_Campaign_Source__c = 'google';
        acc1.Heeet__Heeet_Google_Campaign_Source__c = 'google';
        acc1.GLR_Flag__c = true;
        update acc1;

        Test.stopTest();
    }
    
    static testmethod void autoUpdateCamapignMemberStatusBatchTest(){        
        Test.startTest();
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Type = 'REGULAR';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        insert acc1;
        
        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        insert(cnt1);
        
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Campaign progCampaign = new Campaign(Objective__c = 'Dashboard Sign Up', RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true);
        insert progCampaign;
        
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCampaign.Id);
        insert cmStatus;
        
        CampaignMember cm1 = new CampaignMember(CampaignId = progCampaign.Id, ContactId = cnt1.Id, Status = autoUpdateCampaignMemberStatus);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
        
        Account updateAcc1 = new Account(Id = acc1.Id, Business_id__c = 'TEST123');
        update updateAcc1;

        Test.stopTest();
    }
    
    @isTest
    static void testAutoClosedLostOpportunity() {
 		Test.startTest();
        User userid = [SELECT Id FROM User WHERE FederationIdentifier = 'self-serve@xendit.co' LIMIT 1];
        /*Id salesProfileId = [SELECT Id FROM Profile WHERE Name = 'Xendit Sales Profile' LIMIT 1].Id;
        Id userroleCEO  = [SELECT Id FROM UserRole WHERE Name Like 'CEO' LIMIT 1].ID;

        User user1 = new user(
                        Alias = 'User1',
                        Country = 'Indonesia', 
                        Email = 'User'+String.valueOf(date.today())+'@Test.com',
                        Username = 'User'+String.valueOf(date.today())+'@Test.com',
                        FirstName = 'User',
                        IsActive = true,
                        FederationIdentifier = 'self-serve@xendit.co',                    
                        ProfileId = salesProfileId,
                        TimeZoneSidKey = 'GMT',
                        UserroleId = userroleCEO);
        insert user1;
        */
		System.debug('--------------User:' + userid);
        Opportunity op2 = [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE LeadSource ='Inbound' AND Parent_Opportunity__c = NULL LIMIT 1];
		op2.OwnerId = userid.id;
        update op2;
        
        Account acc = [SELECT Id, Name FROM Account WHERE Legal_Entity_Name__c = 'Merged Account'];
        acc.KYC_Verification_Status__c = 'FAILED';
        update acc;
        
        // Verify the changes
        Opportunity updatedOpportunity = [SELECT Id, StageName, Reason_Lost_Opp__c, Sub_Reason_Opp__c
                                         FROM Opportunity
                                         WHERE Id = :op2.Id];
        System.debug('===============updatedOppty:'+ updatedOpportunity);
        //System.assertEquals('Closed Lost', updatedOpportunity.StageName);
        Test.stopTest();

    }

    @isTest
    static void testMergeOpportunitiesOnAccountMerge() {
 		Test.startTest();
        Opportunity op2 = [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Name = 'Child Master Opportunity' AND Parent_Opportunity__c != NULL LIMIT 1];
        Opportunity op4 = [SELECT Id,Parent_Opportunity__c FROM Opportunity WHERE Name = 'Child Merged Opportunity' AND Parent_Opportunity__c != NULL LIMIT 1];
        Account masterAccount1 = [SELECT Id, Name FROM Account WHERE Legal_Entity_Name__c = 'Master Account'];
        Account mergedAccount1 = [SELECT Id, Name FROM Account WHERE Legal_Entity_Name__c = 'Merged Account'];
        Product2 p1 = [SELECT ID FROM Product2 WHERE Name = 'Test Prod1'];
        Rate_Card__c r1= [SELECT ID FROM Rate_Card__c WHERE product__c = :p1.id];
        Contact c1 = [SELECT ID FROM Contact LIMIT 1];
        
        List<Xendit_Opportunity_Product__c> xopList = new List<Xendit_Opportunity_Product__c>();

        Xendit_Opportunity_Product__c xop = new Xendit_Opportunity_Product__c();
        xop.opportunity__c = op4.id;
        xop.Product__c = p1.id;
        xop.Rate_Card__c = r1.id;
        xop.Brand__c = 'Xendit';
        xop.Basket_Size__c=200;        
        xop.Total_Revenue__c=400000;
        xop.TPV__c=6000;
        xop.Rate_Per_TPV_List__c=1.5;
    	xopList.add(xop);
        
        Xendit_Opportunity_Product__c xop2 = new Xendit_Opportunity_Product__c();
        xop2.opportunity__c = op2.id;
        xop2.Product__c = p1.id;
        xop2.Rate_Card__c = r1.id;
        xop2.Brand__c = 'Xendit';
        xop2.Basket_Size__c=200;        
        xop2.Total_Revenue__c=400000;
        xop2.TPV__c=6000;
        xop2.Rate_Per_TPV_List__c=1.5;
    	xopList.add(xop2);
        insert xopList;
        
        OpportunityContactRole newOcr = new OpportunityContactRole(
            OpportunityId = op4.Parent_Opportunity__c,
            ContactId = c1.id,
            Role = 'PIC',
            IsPrimary = TRUE
         );
        insert newOcr;
        
		//merge masterAccount mergedAccount;
		Database.MergeResult results = Database.merge(masterAccount1, mergedAccount1, false);
		test.stopTest();
    }
    
}