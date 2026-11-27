/**
 * @description       : 
 * @group             : 
 * @test-classes	  : IDScheduleProcessBatchAutoCLOpptyTest
 * @last modified on  : 03-11-2023
 * @last modified by  : Rizki.asriningtyas@xendit.co
**/
@isTest
public class IDScheduleProcessBatchAutoCLOpptyTest {
    @testSetup
    static void testSchedulable(){
        Test.startTest();
        
        // Create a test data setup
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User newUser = new User();
        newUser.FirstName = 'self-service';
        newUser.LastName = 'User';
        newUser.Email = 'self_service@xendit.co';
        newUser.Username = 'self_service@xendit.co';
        newUser.Alias = 'ssuser';
        newUser.TimeZoneSidKey = 'America/New_York'; 
        newUser.LocaleSidKey = 'en_US'; 
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.ProfileId = systemAdminProfile.Id; 
        newUser.LanguageLocaleKey = 'en_US'; 
		newUser.IsActive = TRUE;
        insert newUser;
		User userForTesting = [SELECT Id FROM User WHERE Email = 'self_service@xendit.co' AND IsActive = TRUE LIMIT 1];
                   
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
        op1.Qualification_Date__c = Date.valueOf('2023-01-01');
        op1.OwnerId = userForTesting.Id;
        op1.LeadSource = 'Inbound';
        insert op1;
        
       	op1.Discovery_Date__c = Date.valueOf('2023-01-01');
        update op1;


        Opportunity op2 = new Opportunity();
        op2.Name = 'Opp Parent 2';
        op2.Type = 'New Acquisition';
        op2.AccountId = acc1.Id;
        op2.ContactId = cnt1.Id;
        op2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op2.NextStep = 'Test';
        op2.ForecastCategoryName = 'Omitted';
        op2.CloseDate = Date.today() + 11;
        op2.Xst_Txn_Act_Date__c = Date.today();
        op2.Pains_Priorities_and_Needs__c = 'test';
        op2.Has_Competitor__c = 'No';
        op2.Sales_Goals_Plan__c = 'test';
        op2.Standard_Financial_Terms__c = 'Yes';
        op2.Customer_Signed_Contract_URL__c = 'test.com';
        op2.OwnerId = userForTesting.Id;
        op2.LeadSource = 'Inbound';
        insert op2;
       
		Contact contact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'johndoe@example.com');
        insert contact;
        
        op2.Pricing_Approval__c = 'Approved';
        op2.Contract_Contact__c = contact.id; 
        op2.StageName = 'Contracting';
        op2.Onboarding_Contracting_Date__c = Date.valueOf('2023-01-01');
        update op2;

        // Create a ContactRole record
        OpportunityContactRole role = new OpportunityContactRole(OpportunityId = op2.Id, ContactId = contact.Id, Role = 'Decision Maker');
        insert role;        

    }

    @isTest
    static void testRunSchBatchAutoCLOppty(){
        Test.StartTest();
        IDScheduleProcessBatchAutoCLOppty job = new IDScheduleProcessBatchAutoCLOppty();
        String jobId = System.schedule('Test IDScheduleProcessBatchAutoCLOppty', '0 0 09 * * ?', job);
        
        // Get the scheduled job
        CronTrigger cronTrigger = [SELECT Id, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        IDScheduleProcessBatchAutoCLOppty scheduledJob = new IDScheduleProcessBatchAutoCLOppty();
        scheduledJob.execute(null);
        
        String query = 'SELECT Id FROM Opportunity WHERE StageName = \'Qualification\'';
        UpdateStageOppCLBatch batch = new UpdateStageOppCLBatch(query);
        Database.executeBatch(batch);
        
        Test.StopTest();
    }

    @isTest
    static void testRunBatchAutoCWUpsell(){
        Test.StartTest();
        ClosedWonOppUpsellSch sch = new ClosedWonOppUpsellSch();
        sch.execute(null);
        String query = 'SELECT Id FROM Opportunity WHERE StageName = \'Contracting\'';
        AutoCloseWonUpsellOpty batch = new AutoCloseWonUpsellOpty(query);
        Database.executeBatch(batch);
        Test.StopTest();
    }
}