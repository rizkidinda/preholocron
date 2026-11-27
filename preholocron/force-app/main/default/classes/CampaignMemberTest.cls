/**
 * @description       : 
 * @group             : 
 * @last modified on  : 29-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@IsTest
private class CampaignMemberTest {
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
        
        Campaign masterCampaign = new Campaign(RecordTypeId = masterCampaignRT, Name = 'Test Master Campaign', IsActive = true);
        insert masterCampaign;
        
        Campaign progCampaign = new Campaign(RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true, ParentId = masterCampaign.Id);
        insert progCampaign;
        
        Campaign tacticCampaign = new Campaign(RecordTypeId = tacticCampaignRT, Name = 'Test Tactic Campaign', IsActive = true, ParentId = progCampaign.Id);
        insert tacticCampaign;
        
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
        
        OpportunityContactRole opprole = new OpportunityContactRole();
        opprole.ContactId = cnt1.Id;
        opprole.Role = 'PIC / Gatekeeper';
        opprole.OpportunityId = op1.Id;
        insert opprole;
        
        Opportunity op2 = op1.clone();
        op2.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op2.Parent_Opportunity__c = op1.Id;
        op2.StageName = 'Qualification';
        op2.Xendit_Price_Book__c = xp1.Id;
        op2.AccountId = acc1.Id;
        op2.currencyIsoCode = 'IDR';
        insert op2;
        
        Test.stopTest();
    }
    
    @isTest
    static void insertNewTacticMember(){
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        Campaign tacticCamp = [SELECT Id FROM Campaign WHERE RecordType.Name = 'Tactic Campaign' LIMIT 1];
        CampaignMember cm1 = new CampaignMember(CampaignId = tacticCamp.Id, ContactId = cont1.Id);
        insert cm1;
        
        delete cm1;
    }
    
    @isTest
    static void autoCreateCrossSellOppInsertMember(){
        Test.startTest();
        Opportunity op2 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', op2.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    Decimal getTotalEstTPV = opc.getTotalEstTPV();
                    String getTrxCount = opc.getTrxCount();
                    String getTotalRevenue = opc.getTotalRevenue();
                    String getTotalRevenueTPV = opc.getTotalRevenueTPV();
                    String getTotalRevenueTxn = opc.getTotalRevenueTxn();
                    String getTotalRevenueSubaccount = opc.getTotalRevenueSubaccount();
                    String getTotalRevenueEvent = opc.getTotalRevenueEvent();
                    String getProjectedCost = opc.getProjectedCost();
                    String getLowestRatePerTxn = opc.getLowestRatePerTxn();
                    Integer getBillingApprovalLevel = opc.getBillingApprovalLevel();
                    Integer getPricingApprovalLevel = opc.getPricingApprovalLevel();
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 450;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }
        
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordType.Name = 'Program Campaign' LIMIT 1];
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCamp.Id);
        insert cmStatus;
        
        Campaign updateProgCamp = new Campaign(Id = progCamp.Id, Objective__c = 'Products Activated / Cross-sell');
        update updateProgCamp;
        
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        CampaignMember cm1 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id, Status = autoUpdateCampaignMemberStatus);
        insert cm1;
        Test.stopTest();
    }
    
    @isTest
    static void autoCreateCrossSellOppUpdateMember(){
        Opportunity op1 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Parent Opportunity' LIMIT 1];
        Opportunity op2 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', op2.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    Decimal getTotalEstTPV = opc.getTotalEstTPV();
                    String getTrxCount = opc.getTrxCount();
                    String getTotalRevenue = opc.getTotalRevenue();
                    String getTotalRevenueTPV = opc.getTotalRevenueTPV();
                    String getTotalRevenueTxn = opc.getTotalRevenueTxn();
                    String getTotalRevenueSubaccount = opc.getTotalRevenueSubaccount();
                    String getTotalRevenueEvent = opc.getTotalRevenueEvent();
                    String getProjectedCost = opc.getProjectedCost();
                    String getLowestRatePerTxn = opc.getLowestRatePerTxn();
                    Integer getBillingApprovalLevel = opc.getBillingApprovalLevel();
                    Integer getPricingApprovalLevel = opc.getPricingApprovalLevel();
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 450;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }
        
        Test.startTest();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordType.Name = 'Program Campaign' LIMIT 1];
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCamp.Id);
        insert cmStatus;
        
        Campaign updateProgCamp = new Campaign(Id = progCamp.Id, Objective__c = 'Products Activated / Cross-sell');
        update updateProgCamp;
        
        Opportunity updateOp1 = new Opportunity(Id = op1.Id, CampaignId = progCamp.Id);
        TriggerBypassUtility.opportunityTriggerBypass = true;
        update updateOp1;
        TriggerBypassUtility.opportunityTriggerBypass = false;
        
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = op1.Id, ContactId = cont1.Id);
        insert ocr;
        
        CampaignMember cm1 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
        
        CampaignMember updatecm1 = new CampaignMember(Id = cm1.Id, Status = autoUpdateCampaignMemberStatus);
        update updatecm1;
        
        Test.stopTest();
    }
    
    @isTest
    static void autoUpdateProgCampaignToTacticEngaged(){
        Id tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Campaign tacticCamp = [SELECT Id FROM Campaign WHERE RecordTypeId = :tacticCampaignRT LIMIT 1];
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordTypeId = :programCampaignRT LIMIT 1];
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        
        CampaignMember cm1 = new CampaignMember(CampaignId = tacticCamp.Id, ContactId = cont1.Id);
        CampaignMember cm2 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        insert cm2;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
        
        CampaignMember updatecm1 = new CampaignMember(Id = cm1.Id, Status = 'Responded');
        update updatecm1;
    }
    
    @isTest
    static void testRollUpTacticStatus(){
        Id tacticCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic Campaign').getRecordTypeId();
        Id programCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        Campaign tacticCamp = [SELECT Id FROM Campaign WHERE RecordTypeId = :tacticCampaignRT LIMIT 1];
        Campaign progCamp = [SELECT Id, Objective__c, Offer_Type__c FROM Campaign WHERE RecordTypeId = :programCampaignRT LIMIT 1];
        progCamp.Objective__c = 'Upsell';
        progCamp.Offer_Type__c = 'White Paper';
        update progCamp;
        
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        
        CampaignMember cm1 = new CampaignMember(CampaignId = tacticCamp.Id, ContactId = cont1.Id, Status = 'Tactic Engaged');
        CampaignMember cm2 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        insert cm2;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;

        delete cm1;
    }
    
    @isTest
    static void autoInsertCampaignInfluenceBatchGLRTest(){
        Opportunity op1 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Parent Opportunity' LIMIT 1];
        Opportunity op2 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', op2.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    Decimal getTotalEstTPV = opc.getTotalEstTPV();
                    String getTrxCount = opc.getTrxCount();
                    String getTotalRevenue = opc.getTotalRevenue();
                    String getTotalRevenueTPV = opc.getTotalRevenueTPV();
                    String getTotalRevenueTxn = opc.getTotalRevenueTxn();
                    String getTotalRevenueSubaccount = opc.getTotalRevenueSubaccount();
                    String getTotalRevenueEvent = opc.getTotalRevenueEvent();
                    String getProjectedCost = opc.getProjectedCost();
                    String getLowestRatePerTxn = opc.getLowestRatePerTxn();
                    Integer getBillingApprovalLevel = opc.getBillingApprovalLevel();
                    Integer getPricingApprovalLevel = opc.getPricingApprovalLevel();
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 450;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }
        
        Test.startTest();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordType.Name = 'Program Campaign' LIMIT 1];
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCamp.Id);
        insert cmStatus;
        
        Campaign updateProgCamp = new Campaign(Id = progCamp.Id, Objective__c = 'Go Live Request', isActive = true);
        update updateProgCamp;
        
        Opportunity updateOp1 = new Opportunity(Id = op1.Id, CampaignId = progCamp.Id);
        TriggerBypassUtility.opportunityTriggerBypass = true;
        update updateOp1;
        TriggerBypassUtility.opportunityTriggerBypass = false;
        
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = op1.Id, ContactId = cont1.Id);
        insert ocr;
        
        CampaignMember cm1 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id, Status = autoUpdateCampaignMemberStatus);
        TriggerBypassUtility.campaignMemberTriggerBypass = true;
        insert cm1;
        TriggerBypassUtility.campaignMemberTriggerBypass = false;
        
		AutoInsertCampaignInfluenceBatch cx = new AutoInsertCampaignInfluenceBatch(3,true);
        Database.executeBatch(cx,10);
        
        Test.stopTest();
    }
    
    @isTest
    static void autoCreateUpsellOppInsertMember(){
        Test.startTest();
        Opportunity op2 = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', op2.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    Decimal getTotalEstTPV = opc.getTotalEstTPV();
                    String getTrxCount = opc.getTrxCount();
                    String getTotalRevenue = opc.getTotalRevenue();
                    String getTotalRevenueTPV = opc.getTotalRevenueTPV();
                    String getTotalRevenueTxn = opc.getTotalRevenueTxn();
                    String getTotalRevenueSubaccount = opc.getTotalRevenueSubaccount();
                    String getTotalRevenueEvent = opc.getTotalRevenueEvent();
                    String getProjectedCost = opc.getProjectedCost();
                    String getLowestRatePerTxn = opc.getLowestRatePerTxn();
                    Integer getBillingApprovalLevel = opc.getBillingApprovalLevel();
                    Integer getPricingApprovalLevel = opc.getPricingApprovalLevel();
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 450;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }
        
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCamp = [SELECT Id FROM Campaign WHERE RecordType.Name = 'Program Campaign' LIMIT 1];
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCamp.Id);
        insert cmStatus;
        
        Campaign updateProgCamp = new Campaign(Id = progCamp.Id, Objective__c = 'Upsell');
        update updateProgCamp;
        
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        CampaignMember cm1 = new CampaignMember(CampaignId = progCamp.Id, ContactId = cont1.Id, Status = autoUpdateCampaignMemberStatus);
        insert cm1;
        Test.stopTest();
    }
}