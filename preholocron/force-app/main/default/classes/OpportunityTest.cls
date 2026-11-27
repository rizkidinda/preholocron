/**
 * @description       : 
 * @group             : 
 * @last modified on  : 15-01-2024
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
@isTest()
private class OpportunityTest {
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
                hiro.Date__c = Date.Today(); 
                hiro.HIRO_Percentage__c = 26;
                hiros.add(hiro);   
            }
        }
        insert hiros;

        Test.startTest();
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
        insertProductList.add(p5);

        Product2 p6 = new Product2();
        p6.Name = 'Test Prod6';
        p6.ProductCode ='TESTP6';
        p6.CurrencyIsoCode = 'IDR';
        p6.Family = 'Cross Border PG FX';
        p6.IsActive = true;
        insertProductList.add(p6);
        
        Product2 p7 = new Product2();
        p7.Name = 'Test Prod7';
        p7.ProductCode ='TESTP7';
        p7.CurrencyIsoCode = 'IDR';
        p7.Family = 'Escrow';
        p7.IsActive = true;
        p7.is_VAS_Product__c = true;
        insertProductList.add(p7);

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
        List<Rate_Card__c> rcList = [SELECT Id, Product__r.Family FROM Rate_Card__c WHERE NOT((Product__r.Family LIKE '%Unsupported Product%') 
                                    OR (Product__r.Family LIKE '%Cross Border PG FX%') OR (Product__r.Is_VAS_Product__c = TRUE)) ];
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
        TriggerBypassUtility.accountTriggerBypass = false;
        
        List<Transaction__c> txnList = new List<Transaction__c>();
        Transaction__c tr1 = new Transaction__c();
        tr1.Account__c = acc1.Id;
        tr1.Date__c = Date.today();
        tr1.Aggregated_Type__c = 'Weekly';
        tr1.Product_Lookup__c = p1.Id;
        tr1.Business_ID__c = acc1.Business_ID__c;
        tr1.Transaction_Count__c = 10;
        tr1.Revenue_USD__c = 300;
        txnList.add(tr1);
        
        Transaction__c tr2 = new Transaction__c();
        tr2.Account__c = acc1.Id;
        tr2.Date__c = Date.today().addDays(-7);
        tr2.Aggregated_Type__c = 'Weekly';
        tr2.Product_Lookup__c = p1.Id;
        tr2.Business_ID__c = acc1.Business_ID__c;
        tr2.Transaction_Count__c = 10;
        tr2.Revenue_USD__c = 300;
        txnList.add(tr2);
        
        Transaction__c tr3 = new Transaction__c();
        tr3.Account__c = acc1.Id;
        tr3.Date__c = Date.today().addMonths(-1);
        tr3.Aggregated_Type__c = 'Monthly';
        tr3.Product_Lookup__c = p1.Id;
        tr3.Business_ID__c = acc1.Business_ID__c;
        tr3.Transaction_Count__c = 10;
        tr3.Revenue_USD__c = 500;
        txnList.add(tr3);
        
        Transaction__c tr4 = new Transaction__c();
        tr4.Account__c = acc1.Id;
        tr4.Date__c = Date.today().addMonths(-2);
        tr4.Aggregated_Type__c = 'Monthly';
        tr4.Product_Lookup__c = p1.Id;
        tr4.Business_ID__c = acc1.Business_ID__c;
        tr4.Transaction_Count__c = 10;
        tr4.Revenue_USD__c = 800;
        txnList.add(tr4);
        
        insert txnList;
        
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
        op1.Pipeline_Source__c = 'Undeclared Interest';
        TriggerBypassUtility.opportunityTriggerBypass = true;
        insert op1;
        TriggerBypassUtility.opportunityTriggerBypass = false;

        Opportunity op2 = op1.clone();
        op2.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op2.Parent_Opportunity__c = op1.Id;
        op2.StageName = 'Qualification';
        insertOppList.add(op2);
  
        Opportunity op3 = op2.clone();
        op3.RecordTypeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        op3.Parent_Opportunity__c = op1.Id;
        op3.StageName = 'Qualification';
        insertOppList.add(op3);
        
        insert insertOppList;

        User updateUser = new User(Id = UserInfo.getUserId(), Approval_Level__c = '1');
        update updateUser;

        Test.stopTest();
    }

	@isTest
    static void testOppItemsUISave_NormalAccount(){

       List<Opportunity> oppList = [SELECT Id, RecordType.Name FROM Opportunity];
       Opportunity childOpp = new Opportunity();
       Opportunity parentOpp = new Opportunity();
       Boolean childFlag = false;
        for(Opportunity opp : oppList){
            if(opp.recordType.Name == 'Parent Opportunity'){
                parentOpp = opp;
            }else if(opp.recordType.Name == 'Child Opportunity' && !childFlag){
                childOpp = opp;
                childFlag = true;
            }
        }

        OppItemController oppCtrl = new OppItemController();
        oppCtrl.init();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        system.debug('DEBUG: TEST id ' + oppCtrl.idOpp);
        oppCtrl.getAllHelptext();
        oppCtrl.getShowPRD();
        oppCtrl.getShowPB();
        oppCtrl.getShowOPP();
        oppCtrl.getOppAmount();
        oppCtrl.getOppProductCount();
        oppCtrl.getShowColRevenueTPV();
        oppCtrl.getShowColRevenueTxn();
        oppCtrl.getShowColTxnCount();
        
        oppCtrl.savePricebook();
        
        oppCtrl.showProductList();
        oppCtrl.hideProductList();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }

            Product2 unsupportProd = [SELECT Id, Name FROM Product2 WHERE Family = 'Unsupported Product - PG' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == unsupportProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        Test.startTest();
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            oppCtrl.saveProducts();
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

        Opportunity updateParentIntegration = new Opportunity(Id = parentOpp.Id, StageName = 'Integration');
        TriggerBypassUtility.opportunityTriggerBypass = true;
        update updateParentIntegration;
        TriggerBypassUtility.opportunityTriggerBypass = false;
        oppCtrl.reloadOpportunity();
        oppCtrl.getIsParentLocked();

        Utility.getObjectPrefix('Opportunity');
        Utility.getFieldOptions('Opportunity', 'StageName', true);

        Test.stopTest();
    }

    @isTest
    static void testOppItemsUIDelete_NormalAccount(){

        Test.startTest();

        Opportunity childOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
         OppItemController oppCtrl = new OppItemController();
         ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
         oppCtrl.init();
         system.debug('DEBUG: TEST id ' + oppCtrl.idOpp);
         
         oppCtrl.savePricebook();
         
         if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
         {
             Product2 escrowProd = [SELECT Id, Name FROM Product2 WHERE Family = 'Escrow' LIMIT 1];
             for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                 if(oppCtrl.arrRateList[i].P.Name == escrowProd.Name){
                     oppCtrl.arrRateList[i].isSelected = true;
                 }
             }
             
             oppCtrl.addProducts();
         }
         
         if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
         {
            oppCtrl.saveProducts();
             List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
             String selectedKey = keyList[0];
             List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
             
             currList[0].isSelected = true;
             oppCtrl.arrOppProductsMap.put(selectedKey,currList);
             oppCtrl.deleteProducts();
             
         }
 
         Test.stopTest();
     }
    
    @isTest
    static void testOppItemsUISave_ResellerAccount(){
        Test.startTest();
        Account acc = [SELECT Id, Is_Reseller__c FROM Account LIMIT 1];
        TriggerBypassUtility.accountTriggerBypass = true;
        Account updateAcc = new Account(Id = acc.Id, Is_Reseller__c = true);
        update updateAcc;
        TriggerBypassUtility.accountTriggerBypass = false;

       Opportunity childOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'Iluma Products' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == ewalletProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            oppCtrl.saveProducts();
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                    opc.XP.Rate_to_customer_BPS__c = 20;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            oppCtrl.saveProducts();
        }
        Test.stopTest();
    }
    
    @isTest
    static void testOppItemsUISave_FXProduct(){
        Test.startTest();
        Opportunity childOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 FXProd = [SELECT Id, Name FROM Product2 WHERE Family = 'Cross Border PG FX' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == FXProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            oppCtrl.saveProducts();
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                    opc.XP.Rate_to_customer_BPS__c = 100000;
                    opc.XP.Expected_Monthly_Volume__c = 10;
                    Rate_Card__c rc = new Rate_Card__c(Id = opc.XP.Rate_Card__c, Selected_Value__c = opc.XP.Rate_Card__r.Selected_Value__c, Selected_Value_Source__c = opc.XP.Rate_Card__r.Selected_Value_Source__c, Basket_Size_Threshold__c = opc.XP.Rate_Card__r.Basket_Size_Threshold__c);
                    opc.recalculate(opc.productFamilyFormula, opc.XP, rc);
                    
                    Decimal compareCheck = opc.compareVals(10,20, 'Lower'); 
                    Decimal compareCheck2 = opc.compareVals(10,20, 'Higher');
                    Decimal compareCheck3 = opc.compareVals(30,20, 'Lower');
                    Integer compareIntCheck = opc.compareValInt(10,20, 'Lower');
                    Integer compareIntCheck2 = opc.compareValInt(10,20, 'Higher');
                    Integer compareIntCheck3 = opc.compareValInt(30,20, 'Higher');
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            oppCtrl.saveProducts();
        }
        Test.stopTest();
    }

    @isTest
    static void testOppItemsUISave_VASProduct(){
        Test.startTest();
        Opportunity childOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 VASrod = [SELECT Id, Name FROM Product2 WHERE Is_VAS_Product__c = TRUE LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == VASrod.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            oppCtrl.saveProducts();
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());
            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                    opc.XP.Rate_to_customer_BPS__c = 100000;
                    opc.XP.Expected_Monthly_Volume__c = 10;
                    opc.XP.No_of_API_Calls__c = 10;
                    opc.XP.Rate_per_API_Call__c = 1000;

                    Rate_Card__c rc = new Rate_Card__c(Id = opc.XP.Rate_Card__c, Selected_Value__c = opc.XP.Rate_Card__r.Selected_Value__c, Selected_Value_Source__c = opc.XP.Rate_Card__r.Selected_Value_Source__c, Basket_Size_Threshold__c = opc.XP.Rate_Card__r.Basket_Size_Threshold__c);
                    opc.recalculate(opc.productFamilyFormula, opc.XP, rc);

                }
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            oppCtrl.saveProducts();
        }
        Test.stopTest();
    }

    @isTest
    static void testOppItemsUISave_withORPricing(){
        Test.startTest();
        Account acc = [SELECT Id, Is_Reseller__c FROM Account LIMIT 1];
        TriggerBypassUtility.accountTriggerBypass = true;
        Account updateAcc = new Account(Id = acc.Id, Is_Reseller__c = true);
        update updateAcc;
        TriggerBypassUtility.accountTriggerBypass = false;

       Opportunity childOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Child Opportunity' LIMIT 1];
        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
            Product2 xpProd = [SELECT Id, Name FROM Product2 WHERE Family = 'XenPlatform' LIMIT 1];
            for(Integer i = 0 ; i < oppCtrl.arrRateList.size() ; i++){
                if(oppCtrl.arrRateList[i].P.Name == xpProd.Name){
                    oppCtrl.arrRateList[i].isSelected = true;
                }
            }
            
            oppCtrl.addProducts();
        }
        
        if (oppCtrl.arrOppProductsMap != null && oppCtrl.arrOppProductsMap.size() > 0) 
        {
            oppCtrl.saveProducts();
            List<String> keyList = new List<String>(oppCtrl.arrOppProductsMap.keySet());

            for(String prodFam : oppCtrl.arrOppProductsMap.keySet()){
                String selectedKey = prodFam;
                List<OppProductClass> currList = oppCtrl.arrOppProductsMap.get(selectedKey);
                for(OppProductClass opc : currList){
                    opc.XP.TPV__c = 500;
                    opc.XP.Rate_Per_TPV_Sell__c = 3;
                    opc.XP.Basket_Size__c = 100;
                    opc.XP.Fixed_Rate_Sell__c = 400;
                    opc.XP.Rate_Per_Txn_Sell__c = 400;
                    opc.XP.Number_Subaccount__c = 1;
                    opc.XP.Rate_Per_Subaccount_Sell__c = 500;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            oppCtrl.saveProducts();
        }
        Test.stopTest();
    }

    @isTest
    static void testOppItemsUISave_belowCOGS(){

       List<Opportunity> oppList = [SELECT Id, RecordType.Name, AccountId FROM Opportunity];
       Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
       Opportunity childOpp = new Opportunity();
       Opportunity parentOpp = new Opportunity();
       Boolean childFlag = false;
        for(Opportunity opp : oppList){
            if(opp.recordType.Name == 'Parent Opportunity'){
                parentOpp = opp;
            }else if(opp.recordType.Name == 'Child Opportunity' && !childFlag){
                childOpp = opp;
                childFlag = true;
            }
        }

        Account acc = [SELECT Id, Business_ID__c FROM Account WHERE Id =: parentOpp.AccountId LIMIT 1];

        Test.startTest();

        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
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
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 20;
                    opc.XP.Rate_Per_TPV_Sell__c = 1;
                    opc.XP.Basket_Size__c = 100;
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }
        
        Test.stopTest();
    }

    @isTest
    static void testOppAddTransaction(){

       List<Opportunity> oppList = [SELECT Id, RecordType.Name, AccountId FROM Opportunity];
       Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
       Opportunity childOpp = new Opportunity();
       Opportunity parentOpp = new Opportunity();
       Boolean childFlag = false;
        for(Opportunity opp : oppList){
            if(opp.recordType.Name == 'Parent Opportunity'){
                parentOpp = opp;
            }else if(opp.recordType.Name == 'Child Opportunity' && !childFlag){
                childOpp = opp;
                childFlag = true;
            }
        }

        Account acc = [SELECT Id, Business_ID__c FROM Account WHERE Id =: parentOpp.AccountId LIMIT 1];

        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
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
        Opportunity updateParent1 = new Opportunity(Id = parentOpp.Id, Pains_Priorities_and_Needs__c = '', Created_via_Campaign__c = true, Type = 'Upsell');
        TriggerBypassUtility.opportunityTriggerBypass = true;
        update updateParent1;
        TriggerBypassUtility.opportunityTriggerBypass = false;

        Opportunity updateParent2 = new Opportunity(Id = parentOpp.Id, Pains_Priorities_and_Needs__c = 'test', StageName = 'Contracting');
        update updateParent2;
        
        Transaction__c trUpdate = [SELECT Id FROM Transaction__c WHERE Account__c = :acc.Id AND Aggregated_Type__c = 'Weekly' AND Date__c = THIS_WEEK LIMIT 1];
        trUpdate.Transaction_Count__c = 8;
        update trUpdate;

        Test.stopTest();
    }
    
    @isTest
    static void TestCheckAccountContact(){
        
       List<user> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'Xendit Sales Profile' AND IsActive = TRUE LIMIT 1];
       List<Opportunity> oppList = [SELECT Id, RecordType.Name, AccountId FROM Opportunity];
       Product2 ewalletProd = [SELECT Id, Name FROM Product2 WHERE Family = 'eWallets' LIMIT 1];
       Opportunity childOpp = new Opportunity();
       Opportunity parentOpp = new Opportunity();
       Boolean childFlag = false;
        for(Opportunity opp : oppList){
            if(opp.recordType.Name == 'Parent Opportunity'){
                parentOpp = opp;
            }else if(opp.recordType.Name == 'Child Opportunity' && !childFlag){
                childOpp = opp;
                childFlag = true;
            }
        }

        Account acc = [SELECT Id, Business_ID__c FROM Account WHERE Id =: parentOpp.AccountId LIMIT 1];

        OppItemController oppCtrl = new OppItemController();
        ApexPages.currentPage().getParameters().put('Id', childOpp.Id);
        oppCtrl.init();
        
        if (oppCtrl.arrRateList != null && oppCtrl.arrRateList.size() > 0)
        {
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
                    opc.XP.TPV__c = 2000;
                    opc.XP.Rate_Per_Txn_Sell__c = 450;
                    opc.XP.Rate_Per_TPV_Sell__c = 4;
                    opc.XP.Basket_Size__c = 100;
                    opc.XP.Rate_to_customer_BPS__c = 20;
                    Boolean getcheckFXApproval = opc.checkFXApproval();
                    
                }
                
                oppCtrl.arrOppProductsMap.put(selectedKey,currList);
            }
            
            oppCtrl.saveProducts();
        }

        Test.startTest();
        Contact cnt = [SELECT Id FROM Contact LIMIT 1];

        parentOpp.OwnerId = userForTesting[0].Id;
        update parentOpp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(contactId = cnt.Id, OpportunityId = parentOpp.Id, Role = 'Other', isPrimary = FALSE );
        insert ocr;
        
        Opportunity updateParentOpp  = new Opportunity(Id = parentOpp.Id, StageName = 'Discovery');

        system.runAs(userForTesting[0])
        {
			try{
                update updateParentOpp;
            }catch(Exception e){
                system.debug('e : ' + e.getMessage());
                Boolean expectedExceptionThrown =  e.getMessage().contains('For Opportunity with Stage as Discovery, at least one contact related to the Opportunity or Account with Role as "PIC" or "Decision Maker" or "Founder / Owner / Director" has to be identified') ? true : false;
                System.assertEquals(expectedExceptionThrown, false);
            }           
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteOpportunity()
    {   
        
        test.startTest();
        
        Opportunity childOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Child Opportunity' LIMIT 1];
        delete childOpp;
        
        test.stopTest();
    }
    
    @isTest
    static void testSendEmailToRecipients() {
        // Create test data
        SendEmail_FX_Product emailData = new SendEmail_FX_Product();
        emailData.urlOppIds = 'https://example.com/opportunityId123';
        
        List<SendEmail_FX_Product> emailDataList = new List<SendEmail_FX_Product>();
        emailDataList.add(emailData);
        
        // Call the sendEmailToRecipients method
        Test.startTest();
        SendEmail_FX_Product.sendEmailToRecipients(emailDataList);
        Test.stopTest();
    }
    
    @isTest
    static void testWeeklyUpdateHistory()
    {   
        test.startTest();
        Opportunity parentOpp = [SELECT Id, SE_Updates_Comments__c,Weekly_Update_History__c, SE_Update_with_History__c, Weekly_Update__c FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' LIMIT 1];
        parentOpp.SE_Updates_Comments__c = 'Testing';
        update parentOpp;
        parentOpp.Weekly_Update__c = 'Testing';
		update parentOpp;
        test.stopTest();
    }

    @isTest
    static void testSubmitApproval()
    {   
        
        test.startTest();
        
        Opportunity parentOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' LIMIT 1];
        Id pricingRT = Schema.SObjectType.Opportunity_Approval__c.getRecordTypeInfosByName().get('Pricing Approval').getRecordTypeId();
        Opportunity_Approval__c oppAppr = new Opportunity_Approval__c(Opportunity__c = parentOpp.Id, RecordTypeId = pricingRT);
        insert oppAppr;
        
        List<user> userForTesting = [SELECT Id FROM User WHERE Profile.Name = 'Xendit Sales Profile' AND IsActive = TRUE LIMIT 1];
        parentOpp.ownerId = userForTesting[0].Id;
        update parentOpp;
        
        test.stopTest();
    }
    
    @isTest
    static void testUpdateCampaignMemberStatus()
    {   
        
        test.startTest();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCampaign = new Campaign(RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true, Objective__c  = 'Pipe Progression', Offer_Type__c  = 'Contact Me');
        insert progCampaign;
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCampaign.Id);
        insert cmStatus;
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        CampaignMember cm1 = new CampaignMember(CampaignId = progCampaign.Id, ContactId = cont1.Id, Status= autoUpdateCampaignMemberStatus);
        insert cm1;
        Opportunity parentOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' LIMIT 1];
        OpportunityContactRole oppContactRole1 = new OpportunityContactRole(contactId = cont1.Id, OpportunityId = parentOpp.Id, Role = 'PIC', isPrimary = FALSE);
        insert oppContactRole1;
        
        parentOpp.StageName = 'Discovery';
        update parentOpp;
        
        test.stopTest();
    }
    
    @isTest
    static void autoUpdateCamapignMemberStatusBatchTest()
    {   
        
        test.startTest();
        Id proCampaignRT = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program Campaign').getRecordTypeId();
        String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
        Campaign progCampaign = new Campaign(RecordTypeId = proCampaignRT, Name = 'Test Program Campaign', IsActive = true, Objective__c  = 'Upsell', Offer_Type__c  = 'Contact Me');
        insert progCampaign;
        CampaignMemberStatus cmStatus = new CampaignMemberStatus(Label = autoUpdateCampaignMemberStatus, CampaignId = progCampaign.Id);
        insert cmStatus;
        Contact cont1 = [SELECT Id FROM Contact LIMIT 1];
        CampaignMember cm1 = new CampaignMember(CampaignId = progCampaign.Id, ContactId = cont1.Id, Status= autoUpdateCampaignMemberStatus);
        insert cm1;
        Opportunity parentOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' LIMIT 1];
        OpportunityContactRole oppContactRole1 = new OpportunityContactRole(contactId = cont1.Id, OpportunityId = parentOpp.Id, Role = 'PIC', isPrimary = FALSE);
        insert oppContactRole1;
        
        String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
        CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
        CampaignInfluence createCampInfl = new CampaignInfluence(CampaignId = progCampaign.Id, ContactId = cont1.Id, OpportunityId = parentOpp.Id, ModelId = defaultModel.Id);
        insert createCampInfl;
        
        parentOpp.StageName = 'Closed Won';
        update parentOpp;
        
        test.stopTest();
    }
	
    @isTest
    static void updateOpportunityStageAndBDProspecting(){
        test.startTest();
        List<user> userForTesting = [SELECT Id, name FROM User WHERE UserRole.Name LIKE '%BDR%' AND IsActive = TRUE LIMIT 1];
        
        Contact contact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'johndoe@example.com');
        insert contact;
        
        Opportunity parentOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' LIMIT 1];
        parentOpp.ForecastCategoryName = 'Omitted';
        parentOpp.CloseDate = Date.today() + 11;
        parentOpp.Xst_Txn_Act_Date__c = Date.today();
        parentOpp.Pains_Priorities_and_Needs__c = 'test';
        parentOpp.Has_Competitor__c = 'No';
        parentOpp.Sales_Goals_Plan__c = 'test';
        parentOpp.Standard_Financial_Terms__c = 'Yes';
        parentOpp.Customer_Signed_Contract_URL__c = 'test.com';
        parentOpp.LeadSource = 'Inbound';
        parentOpp.Pipeline_Source__c = 'Undeclared Interest';
        parentOpp.Pricing_Approval__c = 'Approved';
        parentOpp.Contract_Contact__c = contact.id; 
        parentOpp.StageName = 'Contracting';
        update parentOpp;
        
        Opportunity updateOpp = [SELECT Id FROM Opportunity WHERE Recordtype.Name = 'Parent Opportunity' AND StageName = 'Contracting' LIMIT 1];
        updateOpp.OwnerId = userForTesting[0].Id;
        update updateOpp;
        test.stopTest();
    }
}