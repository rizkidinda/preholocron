@isTest
public class OpportunityContactRoleTest {
	//create test data
	@TestSetup
    static void createTestData(){
        
        List<Product2> insertProductList = new List<Product2>();
        List<Rate_Card__c> insertRateCardList = new List<Rate_Card__c>();
        List<Opportunity> insertOppList = new List<Opportunity>();
        List<Rate_Card_Pricing_Range__c> rateCardPrRangeList = new List<Rate_Card_Pricing_Range__c>();
        List<Rate_Card_Pricing__c> rateCardPricingList = new List<Rate_Card_Pricing__c>();
        
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

        Product2 p4 = new Product2();
        p4.Name = 'Test Prod4';
        p4.ProductCode ='TESTP4';
        p4.CurrencyIsoCode = 'IDR';
        p4.Family = 'XenPlatform';
        p4.IsActive = true;
        insertProductList.add(p4);
        
        Product2 p5 = new Product2();
        p5.Name = 'Test Prod5';
        p5.ProductCode ='TESTP5';
        p5.CurrencyIsoCode = 'IDR';
        p5.Family = 'Unsupported Product - PG';
        p5.IsActive = true;
        insert p5;

        insert insertProductList;

        Map<String, Product2> pMap = new Map<String, Product2>();
        for(Product2 p : insertProductList){
            pMap.put(p.Family, p);
        }

        Xendit_Price_Book__c xp1 = new Xendit_Price_Book__c();
        xp1.Active__c = true;
        xp1.Name = 'Indonesia Price Book';
        xp1.CurrencyIsoCode = 'IDR';
        insert(xp1);

        Rate_Card__c r1 = new Rate_Card__c();
        r1.Xendit_Price_Book__c = xp1.Id;
        r1.Brand__c = 'Xendit';
        r1.Channel__c = 'DANA';
        r1.Product__c = pMap.get('eWallets').Id;
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
        
        Rate_Card__c r2 = new Rate_Card__c();
        r2.Xendit_Price_Book__c = xp1.Id;
        r2.Brand__c = 'Xendit';
        r2.Channel__c = 'BCA';
        r2.Product__c = pMap.get('Escrow').Id;
        r2.Fixed_Rate__c = 100;
        r2.Rate_Per_Txn__c = 0.5;
        r2.CurrencyIsoCode = 'IDR';
        r2.Rate_Per_Txn__c = 1000;
        r2.Headline_Rate_per_TPV__c = 10;
        r2.Headline_Rate_per_Txn__c = 1000;
        r2.Reseller_Rate_per_TPV__c = 5;
        r2.Reseller_Rate_per_Txn__c = 500;
        r2.Rate_Per_Event__c = 100;
        r2.Rate_Per_Subaccount__c = 100;
        insertRateCardList.add(r2);
        
        Rate_Card__c r3 = new Rate_Card__c();
        r3.Xendit_Price_Book__c = xp1.Id;
        r3.Brand__c = 'Illuma';
        r3.Channel__c = 'KTP OCR';
        r3.Product__c = pMap.get('Iluma Products').Id;
        r3.Rate_Per_Event__c = 100;
        r3.Rate_Per_Txn__c = 1000;
        r3.Headline_Rate_per_TPV__c = 10;
        r3.Headline_Rate_per_Txn__c = 1000;
        r3.Reseller_Rate_per_TPV__c = 5;
        r3.Reseller_Rate_per_Txn__c = 500;
        r3.Rate_Per_Event__c = 100;
        r3.Rate_Per_Subaccount__c = 100;
        insertRateCardList.add(r3);

        Rate_Card__c r4 = new Rate_Card__c();
        r4.Xendit_Price_Book__c = xp1.Id;
        r4.Brand__c = 'Xendit';
        r4.Channel__c = 'Default';
        r4.Product__c = pMap.get('XenPlatform').Id;
        r4.Rate_Per_Event__c = 100;
        r4.Rate_Per_Txn__c = 1000;
        r4.Headline_Rate_per_TPV__c = 10;
        r4.Headline_Rate_per_Txn__c = 1000;
        r4.Reseller_Rate_per_TPV__c = 5;
        r4.Reseller_Rate_per_Txn__c = 500;
        r4.Rate_Per_Event__c = 100;
        r4.Rate_Per_Subaccount__c = 100;
        r4.Selected_Value__c = 'Higher';
        r4.Selected_Value_Source__c = 'Rate per TPV';
        r4.Basket_Size_Threshold__c = 10;
        insertRateCardList.add(r4);
        
        Rate_Card__c r5 = new Rate_Card__c();
        r5.Xendit_Price_Book__c = xp1.Id;
        r5.Brand__c = 'Xendit';
        r5.Channel__c = 'Default';
        r5.Product__c = p5.Id;
        r5.Basket_Size_Threshold__c = 10;
        insert r5;


        insert insertRateCardList;

        for(Integer i = 0 ; i < 4 ; i++){
            for(Integer j = 0 ; j < 3 ; j++){
                Rate_Card_Pricing_Range__c rpr = new Rate_Card_Pricing_Range__c(
                    Name = 'Range ' + (j + 1),	
                    Pricing_Range_Type__c = 'Monthly Product TPV',
                    Country__c = 'Indonesia',
                    Lower_Threshold__c = 0 + (j * 1000),
                    Upper_Threshold__c = (j == 3) ? null : 1000 + (j * 1000),
                    Product_Family__c = insertProductList[i].Family,
                    Range_Order__c = (j+1),
                    Approval_Level__c = (j+1)
                );
                rateCardPrRangeList.add(rpr);
            }
        }

        insert rateCardPrRangeList;

        Map<String, Rate_Card_Pricing_Range__c> rprMap = new Map<String, Rate_Card_Pricing_Range__c>();
        List<Rate_Card_Pricing_Range__c> rprList = [SELECT Id, Product_Family__c, Range_Order__c FROM Rate_Card_Pricing_Range__c];
        for(Rate_Card_Pricing_Range__c rpr : rprList){
            rprMap.put(rpr.Range_Order__c + ':::' + rpr.Product_Family__c, rpr);
        }

        Map<String, Rate_Card__c> rcMap = new Map<String, Rate_Card__c>();
        List<Rate_Card__c> rcList = [SELECT Id, Product__r.Family FROM Rate_Card__c WHERE NOT(Product__r.Family LIKE '%Unsupported Product%')];
        for(Rate_Card__c rc : rcList){
            rcMap.put(rc.Product__r.Family, rc);
        }

        for(String prdFam : rcMap.keySet()){
            for(Integer j = 0; j < 3; j++){
                String key = (j+1) + ':::' + prdFam;
                Rate_Card_Pricing__c tempRP = new Rate_Card_Pricing__c(
                    Rate_Per_Txn__c = 500 - (j*50),
                    Rate_Per_TPV__c = 5 - (j*1),
                    Rate_Card__c = rcMap.get(prdFam).Id,
                    Rate_Card_Pricing_Range__c = rprMap.get(key).Id
                );

                rateCardPricingList.add(tempRP);
            }
        }
        
        insert rateCardPricingList;
             
        Test.startTest();
        
        Id masterCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Master Campaign').getRecordTypeId();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Id tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        List<Campaign_Product__c> insertCPList = new List<Campaign_Product__c>();
        List<Channel_Default_TPV__c> defTPVList = new List<Channel_Default_TPV__c>();
        
        Campaign progCampaign = new Campaign(RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', Objective__c = 'Form Sign Up', IsActive = true);
        insert progCampaign;
        
        for(Integer i = 0 ; i < 4 ; i++){
            Campaign_Product__c cp = new Campaign_product__c(Campaign__c = progCampaign.Id, Product__c = insertProductList[i].Id);
            insertCPList.add(cp);
        }
        insert insertCPList;   
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Segment__c = 'Individual';
        acc1.Customer_Folder_URL__c = 'test.com';
        acc1.Country_of_HQ__c = 'Indonesia';
        acc1.BillingCountry = 'Indonesia';
        acc1.currencyIsoCode = 'IDR';
        acc1.Pending_Verification_Data_PROVIDED_date__c = Date.today();
        TriggerBypassUtility.accountTriggerBypass = true;
        insert(acc1);
        TriggerBypassUtility.accountTriggerBypass = false;
        
        Channel_KYC__c insertChannelKYC = new Channel_KYC__c(Account__c = acc1.Id, Product__c = insertProductList[2].Id, Status__c = 'LIVE');
        insert insertChannelKYC;
        
        for(Rate_Card__c rc : insertRateCardList){
            Channel_Default_TPV__c defTPV = new Channel_Default_TPV__c(Rate_Card__c = rc.Id, Segment__c = 'Individual', Country__c = 'Indonesia', Expected_TPV__c = 1000000, CurrencyIsoCode = 'IDR');
            defTPVList.add(defTPV);
        }
        insert defTPVList;
        
        
        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        insert(cnt1);
        
        CampaignMember member = new CampaignMember(
            ContactId = cnt1.Id,
            Status = 'Responded ',
            CampaignId = progCampaign.Id
        ); 
        insert member;
        
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
        op1.Xendit_Price_Book__c = xp1.Id;
        op1.StageName = 'Qualification';
        op1.Pains_Priorities_and_Needs__c = 'test';
        op1.Has_Competitor__c = 'No';
        op1.Sales_Goals_Plan__c = 'test';
        op1.Standard_Financial_Terms__c = 'Yes';
        op1.Customer_Signed_Contract_URL__c = 'test.com';
        op1.currencyIsoCode = 'IDR';
        op1.Pipeline_Source__c = 'Undeclared Interest';
        insert op1;
        
        Test.stopTest();
        
        system.debug('***Check Test: '+ [SELECT Id, Name, Status, HasResponded, Campaign.Objective__c, Campaign.isActive FROM CampaignMember WHERE CampaignId = :progCampaign.Id]);
    }
    
    @isTest
    static void testCreateRole() {
        String parentRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE CreatedDate = TODAY AND RecordTypeId = :parentRT LIMIT 1];
        Contact cnt = [SELECT Id FROM Contact WHERE LastName = 'Test Contact1' LIMIT 1];
        
        Campaign cmp = [SELECT Id, Name, Objective__c, isActive FROM Campaign WHERE CreatedDate = TODAY LIMIT 1];
        system.debug('***Check Campaign: '+ cmp);
        
        cmp.isActive = true;
        update cmp;
        
        Test.startTest();
        OpportunityContactRole opprole = new OpportunityContactRole();
        opprole.ContactId = cnt.Id;
        opprole.Role = 'PIC / Gatekeeper';
        opprole.OpportunityId = opp.Id;
        insert opprole;
        Test.stopTest();
    }
}