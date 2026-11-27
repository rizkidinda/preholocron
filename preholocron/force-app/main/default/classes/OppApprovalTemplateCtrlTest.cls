/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
private class OppApprovalTemplateCtrlTest {
    @TestSetup
    static void createTestData() {

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
        insert p1;

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
        insert r1;

        for(Integer i = 0 ; i < 3 ; i++){
            Rate_Card_Pricing_Range__c rpr = new Rate_Card_Pricing_Range__c(
                Name = 'Range ' + (i + 1),	
                Pricing_Range_Type__c = 'Monthly Product TPV',
                Country__c = 'Indonesia',
                Lower_Threshold__c = 0 + (i * 1000),
                Upper_Threshold__c = (i == 3) ? null : 1000 + (i * 1000),
                Product_Family__c = p1.Family,
                Range_Order__c = (i+1),
                Approval_Level__c = (i+1)
            );
            rateCardPrRangeList.add(rpr);
        }

        insert rateCardPrRangeList;

        Map<String, Rate_Card_Pricing_Range__c> rprMap = new Map<String, Rate_Card_Pricing_Range__c>();
        List<Rate_Card_Pricing_Range__c> rprList = [SELECT Id, Product_Family__c, Range_Order__c FROM Rate_Card_Pricing_Range__c];
        for(Rate_Card_Pricing_Range__c rpr : rprList){
            rprMap.put(rpr.Range_Order__c + ':::' + rpr.Product_Family__c, rpr);
        }

        Map<String, Rate_Card__c> rcMap = new Map<String, Rate_Card__c>();
        List<Rate_Card__c> rcList = [SELECT Id, Product__r.Family FROM Rate_Card__c];
        for(Rate_Card__c rc : rcList){
            rcMap.put(rc.Product__r.Family, rc);
        }

        for(Integer j = 0; j < 3; j++){
            String key = (j+1) + ':::' + 'eWallets';
            Rate_Card_Pricing__c tempRP = new Rate_Card_Pricing__c(
                Rate_Per_Txn__c = 500 - (j*50),
                Rate_Per_TPV__c = 5 - (j*1),
                Rate_Card__c = r1.Id,
                Rate_Card_Pricing_Range__c = rprMap.get(key).Id
            );

            rateCardPricingList.add(tempRP);
        }
        
        insert rateCardPricingList;
        
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
        op2.Parent_Opportunity__c = op1.Id;
        op2.StageName = 'Qualification';
        insertOppList.add(op2);
        insert op2;

        Test.stopTest();
    }

    @isTest
    static void TestCheckAccountContact(){
        
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
        
        Test.startTest();
    
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

        Id pricingRT = Schema.SObjectType.Opportunity_Approval__c.getRecordTypeInfosByName().get('Pricing Approval').getRecordTypeId();
        Opportunity_Approval__c oppAppr = new Opportunity_Approval__c(Opportunity__c = parentOpp.Id, RecordTypeId = pricingRT);
        insert oppAppr;
        
		List<Id> oppApprIds = new List<Id>();
		oppApprIds.add(oppAppr.Id);
        //recalled oppty approval
        OpportunityRecalledAction.UnlockOpptyApp(oppApprIds);
        
        PricingApprovalSubmissionTemplateCtrl pAppr = new PricingApprovalSubmissionTemplateCtrl();
        pAppr.apprRecordId = oppAppr.Id;
        Opportunity_Approval__c appr = pAppr.appObj;
        List<OppProductEmailTemplateClass> oppProdList = pAppr.oppProdList;
        String envURL = pAppr.envURL;

        String jsonResult = OppApprovalSummaryTableController.getApprovalData(oppAppr.Id);

        
        Test.stopTest();
    }
}