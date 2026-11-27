@isTest()
public class LeadTest {
    @TestSetup
    static void createTestData(){
        Id masterCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        
        Campaign masterCampaign = new Campaign(RecordTypeId = masterCampaignRT, Name = 'Test Master Campaign', IsActive = true);
        insert masterCampaign;
        
        Campaign progCampaign = new Campaign(RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true, ParentId = masterCampaign.Id);
        insert progCampaign;
        
        Campaign tacticCampaign = new Campaign(RecordTypeId = tacticCampaignRT, Name = 'Test Tactic Campaign', IsActive = true, ParentId = progCampaign.Id);
        insert tacticCampaign;
    }
    
    @isTest
    static void updateUserLeadTest(){
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
            ld1.OwnerId = user1.Id;
            insert ld1;

            Lead ld1_update = new Lead(Id = ld1.Id, CP_Manager__c = user1.Id, Visitor_ID__c = '12345', pi__url__c = 'pardot.com?id=6789012', Weekly_Update__c = 'test weekly update');
            update ld1_update;
            
            REST_PardotAssignProspectIdBatch cx = new REST_PardotAssignProspectIdBatch(1,'Lead');
            Database.executeBatch( cx , 1 ); 
            String sch = '0 5 * * * ?'; 
            System.schedule('Assign_To_Prospect_Scheduler', sch, cx );
            Test.stopTest();
        }
    }
    
    @isTest
    static void updateFirstTouchLastTouch(){
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
            //ld1.LeadSource = 'Website';
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
            ld1.OwnerId = user1.Id;
            insert ld1;

            Lead ld1_update = new Lead(Id = ld1.Id, Heeet__Heeet_First_Click_Campaign_Source__c = 'google', Heeet__Heeet_Google_Campaign_Source__c = 'google');
            update ld1_update;
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testAutoCreateCampInfluence(){
        Test.startTest();

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
        //ld1.LeadSource = 'Website';
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

        insert ld1;
        
        // Create a UTM Category and Category Group Mapping record
        UTM_Category_and_Category_Group_Mapping__c mapping = new UTM_Category_and_Category_Group_Mapping__c();
        mapping.Source_Vendor_Partner__c = 'google';
        mapping.Medium_Campaign__c = 'organic';
        mapping.UTM_Category__c = 'Google Organic Search';
        mapping.UTM_Category_Group__c = 'Organic/Direct';
        insert mapping;
        
        UTM_Category_and_Category_Group_Mapping__c mapping2 = new UTM_Category_and_Category_Group_Mapping__c();
        mapping2.Source_Vendor_Partner__c = 'xxx [partner/vendor_name]';
        mapping2.Medium_Campaign__c = 'merchant_referral';
        mapping2.UTM_Category__c = 'Merchant Referral';
        mapping2.UTM_Category_Group__c = 'Referral';
        mapping2.IsPartner__c = TRUE;
        insert mapping2;
        
        Lead ld1_update = new Lead(Id = ld1.Id, Heeet__Heeet_First_Click_Campaign_Source__c = 'google', Heeet__Heeet_Google_Campaign_Medium__c='organic', 
                                   Heeet__Heeet_Google_Campaign_Source__c = 'google',Heeet__Heeet_First_Click_Campaign_Medium__c='organic');
        update ld1_update;
        
        Lead ld2_update = new Lead(Id = ld1.Id, Heeet__Heeet_Google_Campaign_Source__c = 'ABC',Heeet__Heeet_First_Click_Campaign_Medium__c='merchant_referral');
        update ld2_update;
        
        Id progCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordTypeId = :progCampaignRT LIMIT 1];
        Campaign updateProgCamp = new Campaign(Id = progCamp.Id, Objective__c = 'Pipe Progression');
        update updateProgCamp;
        
        CampaignMemberStatus tacticEngagedStatus = new CampaignMemberStatus(Label = 'Tactic Engaged', CampaignId = progCamp.Id);
        insert tacticEngagedStatus;
        
        CampaignMember insertLeadMember = new CampaignMember(LeadId = ld1.Id, CampaignId = progCamp.Id, Status = 'Tactic Engaged');
        insert insertLeadMember;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(ld1.id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
		lc.setOwnerId(UserInfo.getUserId());
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        Test.stopTest();
    }
    
    @isTest
    static void autoUpdateCamapignMemberStatusBatchTest(){        
        Test.startTest();
        
        Lead ld1 = new Lead();
        ld1.Xendit_Account_Email__c = 'test.merchant1@test.com';
        ld1.Company = 'Test Merchant Company';
        ld1.Brand__c = 'Test Merchant 1';
        ld1.CurrencyIsoCode = 'IDR';
        ld1.MobilePhone = '22918273';
        ld1.Website = 'https://test-merchant1.com';
        ld1.Number_of_Employees_Lead_Qual__c = '75';
        ld1.Status = 'New';
        //ld1.LeadSource = 'Website';
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

        insert ld1;
        
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Campaign progCampaign = new Campaign(Objective__c = 'Dashboard Sign Up', RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true);
        insert progCampaign;
        
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCampaign.Id);
        insert cmStatus;
        
        CampaignMember cm1 = new CampaignMember(CampaignId = progCampaign.Id, LeadId = ld1.Id, Status = autoUpdateCampaignMemberStatus);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
        
        Lead updateLd1 = new Lead(Id = ld1.Id, Business_id__c = 'TEST123');
        update updateLd1;

        Test.stopTest();
    }
}