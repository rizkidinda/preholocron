/**
 * @description       : 
 * @group             : 
 * @last modified on  : 26-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest
public without sharing class HIRO_MonthlyCalculationTest {
    @TestSetup
    static void createTestData() {
        //Insert HIRO data
        List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     

        List<HIRO_Percentage__c> hiros = new List<HIRO_Percentage__c>();
        for (String stage : pickListValuesList) {
            if (stage != 'Closed Won' && stage != 'Closed Lost') {
             	HIRO_Percentage__c hiro = new HIRO_Percentage__c();
                hiro.Name = 'test';
                hiro.Stage__c = stage;
                hiro.Pipeline_Source__c = 'Undeclared Interest';
                hiro.Date__c = Date.Today()-2; 
                hiro.HIRO_Percentage__c = 0.1;
                hiro.External_Id__c = hiro.Pipeline_Source__c + '_' + stage;
                hiros.add(hiro);   
            }
        }
        insert hiros;
        
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
        
        Product2 p6 = new Product2();
        p6.Name = 'Test Prod6';
        p6.ProductCode ='TESTP6';
        p6.CurrencyIsoCode = 'IDR';
        p6.Family = 'Cross Border PG FX';
        p6.IsActive = true;
        insert p6;
        
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
        xp1.Name = 'TEST PB IDR';
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
        
        Rate_Card__c r6 = new Rate_Card__c();
        r6.Xendit_Price_Book__c = xp1.Id;
        r6.Brand__c = 'Xendit';
        r6.Channel__c = 'Default';
        r6.Product__c = p6.Id;
        r6.Rate_Per_Event__c = 100;
        r6.Rate_Per_Txn__c = 1000;
        r6.Headline_Rate_per_TPV__c = 10;
        r6.Headline_Rate_per_Txn__c = 1000;
        r6.Reseller_Rate_per_TPV__c = 5;
        r6.Reseller_Rate_per_Txn__c = 500;
        r6.Rate_Per_Event__c = 100;
        r6.Rate_Per_Subaccount__c = 100;
        r6.Selected_Value__c = 'Higher';
        r6.Selected_Value_Source__c = 'Rate per TPV';
        r6.Basket_Size_Threshold__c = 10;
        r6.Xendit_Rate_BPS__c = 10;
        insert r6;
        
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
        List<Rate_Card__c> rcList = [SELECT Id, Product__r.Family FROM Rate_Card__c WHERE NOT((Product__r.Family LIKE '%Unsupported Product%') OR (Product__r.Family LIKE '%Cross Border PG FX%')) ];
        system.debug('rcList:' + rcList);
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
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        //acc1.Estimated_1st_Txn_Date__c = Date.today() + 10;
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Segment__c = 'Individual';
        acc1.Customer_Folder_URL__c = 'test.com';
        TriggerBypassUtility.accountTriggerBypass = true;
        insert(acc1);
        
        Contact cnt1 = new Contact();
        cnt1.AccountId = acc1.Id;
        cnt1.LastName = 'Test Contact1';
        cnt1.Email = 'test@account1.com';
        insert(cnt1);
        
        Map<Integer, String> intKeyMap = new Map<Integer, String>{
            1 => 'Qualification',
            2 => 'Discovery',
            3 => 'Evaluation',
            4 => 'Negotiation',
            5 => 'Contracting',
            6 => 'Integration',
            7 => 'Activation'
    	};
            
        Map<Integer, String> mapPipeline = new Map<Integer, String>{
            1 => 'Undeclared Interest',
            2 => 'Declared Interest',
            3 => 'Outbound',
            4 => 'Partner Referral',
            5 => 'Events',
            6 => 'ABM',
            7 => 'Internal Referral'
    	};
        
        Test.startTest();
        List<Opportunity> oppToInsert = new List<Opportunity>();
        Opportunity op1 = new Opportunity();
        op1.Name = 'Opp Parent ';
        op1.Type = 'New Acquisition';
        op1.AccountId = acc1.Id;
        op1.ContactId = cnt1.Id;
        op1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op1.NextStep = 'Test';
        op1.ForecastCategoryName = 'Omitted';
        op1.CloseDate = Date.today() + 11;
        op1.Xst_Txn_Act_Date__c = Date.today();
        op1.Xendit_Price_Book__c = xp1.Id;
        op1.StageName = 'Closed Won';
        op1.Pains_Priorities_and_Needs__c = 'test';
        op1.Has_Competitor__c = 'No';
        op1.Sales_Goals_Plan__c = 'test';
        op1.Standard_Financial_Terms__c = 'Yes';
        op1.Customer_Signed_Contract_URL__c = 'test.com';
        op1.Pipeline_Source__c = 'Undeclared Interest';
        op1.Qualification_Date__c = Date.Today() - 30;
        op1.Discovery_Date__c = Date.Today() - 1;
        op1.Evaluation_Date__c = Date.Today() - 1;
        op1.Negotiation_Date__c = Date.Today() - 1;
        op1.Onboarding_Contracting_Date__c = Date.Today() - 1;
        op1.Integration_Date__c = Date.Today() - 1;
        op1.Activation_Date__c = Date.Today() - 1;
        
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert op1;
        
        TriggerBypassUtility.opportunityTriggerBypass = true;
        op1.Closed_Won_Date__c = Date.Today() - 30;
        update op1;
        
        Opportunity op1_1 = new Opportunity();
        op1_1.Name = 'Opp Parent 2';
        op1_1.Type = 'New Acquisition';
        op1_1.AccountId = acc1.Id;
        op1_1.ContactId = cnt1.Id;
        op1_1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        op1_1.NextStep = 'Test';
        op1_1.ForecastCategoryName = 'Omitted';
        op1_1.CloseDate = Date.today() + 11;
        op1_1.Xst_Txn_Act_Date__c = Date.today();
        op1_1.Xendit_Price_Book__c = xp1.Id;
        op1_1.StageName = 'Closed Lost';
        op1_1.Reason_Lost_Opp__c = 'Dead - No Opportunity';
        op1_1.Sub_Reason_Opp__c = 'Non Qualified';
        op1_1.Pains_Priorities_and_Needs__c = 'test';
        op1_1.Has_Competitor__c = 'No';
        op1_1.Sales_Goals_Plan__c = 'test';
        op1_1.Standard_Financial_Terms__c = 'Yes';
        op1_1.Customer_Signed_Contract_URL__c = 'test.com';
        op1_1.Closed_Lost_Date__c = Date.Today() - 1;
        op1_1.Pipeline_Source__c = 'Undeclared Interest';
        op1_1.Qualification_Date__c = Date.Today() - 30;
        op1_1.Discovery_Date__c = Date.Today() - 1;
        op1_1.Evaluation_Date__c = Date.Today() - 1;
        op1_1.Negotiation_Date__c = Date.Today() - 1;
        op1_1.Onboarding_Contracting_Date__c = Date.Today() - 1;
        op1_1.Integration_Date__c = Date.Today() - 1;
        op1_1.Activation_Date__c = Date.Today() - 1;
        
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert op1_1;
        
        TriggerBypassUtility.opportunityTriggerBypass = true;
        op1_1.Closed_Lost_Date__c = Date.Today() - 30;
        update op1_1;
        
        Opportunity openOp = new Opportunity();
        openOp.Name = 'Opp Parent OPEN OPPORTUNITY';
        openOp.Type = 'New Acquisition';
        openOp.AccountId = acc1.Id;
        openOp.ContactId = cnt1.Id;
        openOp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        openOp.NextStep = 'Test';
        openOp.ForecastCategoryName = 'Omitted';
        openOp.CloseDate = Date.today() + 11;
        openOp.Xst_Txn_Act_Date__c = Date.today();
        openOp.Xendit_Price_Book__c = xp1.Id;
        openOp.StageName = 'Qualification';
        openOp.Pains_Priorities_and_Needs__c = 'test';
        openOp.Has_Competitor__c = 'No';
        openOp.Sales_Goals_Plan__c = 'test';
        openOp.Standard_Financial_Terms__c = 'Yes';
        openOp.Customer_Signed_Contract_URL__c = 'test.com';
        openOp.Pipeline_Source__c = 'Undeclared Interest';
        openOp.Qualification_Date__c = Date.Today()-90;
        
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert openOp;
        
        Opportunity discOpp = openOp.clone();
        discOpp.StageName = 'Discovery';
        discOpp.No_of_Contact_Roles__c  = 1;
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert discOpp;
        
        Opportunity evOpp = openOp.clone();
        evOpp.StageName = 'Evaluation';
        evOpp.No_of_Contact_Roles__c  = 1;
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert evOpp;
        
        Opportunity negOpp = openOp.clone();
        negOpp.StageName = 'Negotiation';
        negOpp.No_of_Contact_Roles__c  = 1;
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert negOpp;
        
        Opportunity conOpp = openOp.clone();
        conOpp.StageName = 'Contracting';
        conOpp.No_of_Contact_Roles__c  = 1;
        conOpp.Contract_Contact__c = cnt1.Id;
        conOpp.Pricing_Approval__c = 'No Approval Required';
        conOpp.FX_Product_Approval__c = 'No Approval Required';
        conOpp.Fin_Opp_Approval__c = 'No Approval Required';
        conOpp.Upsell_Approval__c = 'No Approval Required';
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert conOpp;
        
        Test.stopTest();
    }
    
    @isTest
    static void testHIROScheduler(){
        Test.startTest();
        HIRO_MonthlyCalculationSch sch = new HIRO_MonthlyCalculationSch();
        sch.execute(null);
        Test.stopTest();
    }
}