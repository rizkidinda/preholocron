/**
 * @description       : To support OppItemController
 * @last modified on  : 18-01-2024
 * @last modified by  : rizki.asriningtyas@xendit.co
**/

public class XenditOppProductHelper {

    public static Map<Id, Opportunity> updateInitialOpportunity;
    
    public static void afterUpdate(List<Xendit_Opportunity_Product__c> listNew, Map<Id, Xendit_Opportunity_Product__c> mapOld){ //move from trigger to a function in helper
        set<id>childOpp=new set<id>();
        map<id,id> childParentMap=new map<id,id>();
        set<id>refreshRampIds=new set<id>();
        set<id>recalculateRampIds=new set<id>();
        
        for(Xendit_Opportunity_Product__c prod:listNew){
            childOpp.add(prod.Opportunity__c);
        }
        
        for(Opportunity record:[select Parent_Opportunity__c from Opportunity where id=:childOpp]){
            childParentMap.put(record.id,record.Parent_Opportunity__c);
        }
            
        for(Xendit_Opportunity_Product__c prod:listNew){
            Xendit_Opportunity_Product__c oldProd=mapOld.get(prod.id);
            if(oldprod.Total_Revenue__c!=prod.Total_Revenue__c || oldprod.TPV__c!=prod.TPV__c)
            {
                refreshRampIds.add(childParentMap.get(prod.Opportunity__c));
                recalculateRampIds.add(childParentMap.get(prod.Opportunity__c));
            }

            Boolean isBillingTypeUpdate = (prod.Billing_Type__c != oldProd.Billing_Type__c) || (prod.Billing_Sub_Type__c != oldProd.Billing_Sub_Type__c);
            Boolean isPricingUpdate = (prod.TPV__c != oldProd.TPV__c) || (prod.Basket_Size__c != oldProd.Basket_Size__c) || (prod.Rate_per_API_Call__c != oldProd.Rate_per_API_Call__c) ||
                                      (prod.Rate_Per_Txn_Sell__c  != oldProd.Rate_Per_Txn_Sell__c) || (prod.Rate_Per_TPV_Sell__c != oldProd.Rate_Per_TPV_Sell__c); //add ratae per api
            if(isBillingTypeUpdate || isPricingUpdate){
                recalculateRampIds.add(childParentMap.get(prod.Opportunity__c));
            }
        System.debug('###Prod Rate per API: ' + prod.Rate_per_API_Call__c + ' old prod:' + oldProd.Rate_per_API_Call__c);
        }
        if(!refreshRampIds.isEmpty()){
            Xendit_CreateChildRampRecords.createRampRecords(refreshRampIds);
        }
        
        if(!recalculateRampIds.isEmpty()){
            System.debug('###Call Xendit_CalculateEstimatedValues');
            Xendit_CalculateEstimatedValues.caculateFormulaFields(recalculateRampIds);
        }

        updateChildOppName(listNew);
    }

    public static void afterInsert(List<Xendit_Opportunity_Product__c> listNew){
        set<id>childOpp=new set<id>();
        map<id,id> childParentMap=new map<id,id>();
        set<id>refreshRampIds=new set<id>();

        for(Xendit_Opportunity_Product__c prod:listNew){
            childOpp.add(prod.Opportunity__c);
        }
        
        for(Opportunity record:[select Parent_Opportunity__c from Opportunity where id=:childOpp]){
            childParentMap.put(record.id,record.Parent_Opportunity__c);
        }

        for(Xendit_Opportunity_Product__c prod:listNew){
            refreshRampIds.add(childParentMap.get(prod.Opportunity__c));
        }

        CheckParentOpportunityLocked(listNew);
        updateOpportunityValue(listNew);
        System.enqueueJob(new RefreshRampRecordsQueueable(refreshRampIds));
        updateChildOppName(listNew);
        
    }

    // check if parent opportunity is locked
    public static void CheckParentOpportunityLocked(Xendit_Opportunity_Product__c[] listOpp)
    {
        if (listOpp != null)
        {
            Set<Id> stParentIds = new Set<Id>();
            Set<Id> stLockedIds = new Set<Id>();
            String strErrMsg = '';
            for(Xendit_Opportunity_Product__c O: listOpp) {
                if (O.Grand_Parent_Opportunity_ID__c != null) {
                    stParentIds.add(O.Grand_Parent_Opportunity_ID__c);
                }
            }
            if (stParentIds.size() > 0)
            {
                system.debug('DEBUG: parent ids ' + stParentIds);
                User currUser = [SELECT Id, Bypass_VR__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                // get parent opp information
                for(Opportunity Op: [SELECT Id, Name, StageName, Pricing_Approval__c FROM Opportunity WHERE Id IN :stParentIds])
                {
                    if (Op.StageName == 'Integration' || Op.StageName == 'Activation' || Op.StageName == 'Closed Won') {
                        stLockedIds.add(Op.Id);
                        strErrMsg = 'The Parent Opportunity is in ' + Op.StageName + ' Stage. You are not allowed to update the pricing anymore.';
                    }
                    else if (Op.Pricing_Approval__c == 'Submitted' || Op.Pricing_Approval__c == 'Approved') {
                        stLockedIds.add(Op.Id);
                        strErrMsg = 'Pricing Approval for this parent opportunity has been ' + Op.Pricing_Approval__c + '. You are not allowed to update the pricing anymore.';
                    }
                }
                
                if (stLockedIds != null) {
                    system.debug('DEBUG: parent locked ' + stLockedIds);
                    for(Xendit_Opportunity_Product__c O: listOpp) {
                        if (!currUser.Bypass_VR__c && O.Grand_Parent_Opportunity_ID__c != null && stLockedIds.contains(O.Grand_Parent_Opportunity_ID__c)) {
                            // O.addError('Parent_Opportunity__c', 'Parent Opportunity record is currently locked');
                            O.addError('Grand_Parent_Opportunity_ID__c', strErrMsg);
                        }
                    }
                }
            }
        }
    }
    
    //calculate revenue values upon insert
    public static void CalculateInitialValue(List<Xendit_Opportunity_Product__c> listNew, Boolean isTriggerNew){
        try{
            List<Xendit_Opportunity_Product__c> convertOppProductList = new List<Xendit_Opportunity_Product__c>();
            Set<Id> OpportunityIdSet = new Set<Id>();
            updateInitialOpportunity = new Map<Id, Opportunity>();
            Set<Id> rateCardSet = new Set<Id>();
            Map<Id, Rate_Card__c> rateCardMap = new Map<Id, Rate_Card__c>();

            for(Xendit_Opportunity_Product__c op : listNew){
                if(op.From_Lead_Conversion__c && isTriggerNew){
                    convertOppProductList.add(op);
                    OpportunityIdSet.add(op.Opportunity__c);
                    if(op.Rate_Card__c != null) rateCardSet.add(op.Rate_Card__c);
                } 
            }

            if(!convertOppProductList.isEmpty()){

                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity> ([SELECT Id, Amount, Estimated_Monthly_Revenue__c, AccountId, Account.Is_Reseller__c, OwnerId, CurrencyIsoCode, Xst_Txn_Act_Date__c, StageName, Xendit_Price_Book__c, Segment__c
                                                                         FROM Opportunity WHERE Id IN :OpportunityIdSet]);
                //List<Xendit_Opportunity_Product_Calculation__c> xOppProdCalc = new List<Xendit_Opportunity_Product_Calculation__c>();
                
                if(!rateCardSet.isEmpty()){
                    // xOppProdCalc = [SELECT Id, Rate_Card__c, Threshold_Value__c, Threshold_Field__c, Rate_per_Txn_to_Select__c, Use_Rate_per_Txn_for_gt_Threshold__c, Use_MDR_for_gt_Threshold__c
                    //                 FROM Xendit_Opportunity_Product_Calculation__c WHERE Rate_Card__c IN :rateCardSet AND Rate_Card__r.Product__r.IsActive = true ];

                    rateCardMap = new Map<Id, Rate_Card__c>([SELECT Id, Product__c, Product__r.Family, Selected_Value__c, Selected_Value_Source__c, Basket_Size_Threshold__c, 
                                                            Xendit_Price_Book__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, CurrencyIsoCode, 
                                                            Fixed_Rate__c, Reseller_Rate_per_TPV__c, Reseller_Rate_per_Txn__c, Rate_Per_TPV__c,Rate_Per_Txn__c, Rate_Per_Event__c, Rate_Per_Subaccount__c, Product__r.Is_VAS_Product__c,
                                                            Product__r.Basket_Size_Enterprise__c, Product__r.Basket_Size_Individuals__c, Product__r.Basket_Size_MM__c, Product__r.Basket_Size_SME__c, Brand__c, Channel__c 
                                                            FROM Rate_Card__c WHERE Id IN :rateCardSet]);
                }
                for(Xendit_Opportunity_Product__c op : convertOppProductList){
                    op = createDefaultOppProductDetails(op, oppMap.get(op.Opportunity__c), rateCardMap.get(op.Rate_Card__c));
                    OppProductClass objOP = new OppProductClass(op.Opportunity__c);
                    Opportunity getOpp = oppMap.get(op.Opportunity__c);
                    String strFormulaName = null;
                    objOP.XP = op;
                    if(rateCardMap.containsKey(op.Rate_Card__c)){
                        strFormulaName = RevenueClass.getRevenueFormula(rateCardMap.get(op.Rate_Card__c).Product__r.Family);
                    } 
                    objOP.productFamilyFormula = strFormulaName;
                    if(strFormulaName != null){
                        objOP.recalculate(strFormulaName, objOP.XP, rateCardMap.get(op.Rate_Card__c));
                        op = objOP.XP;
                        if(!updateInitialOpportunity.containsKey(op.Opportunity__c)){
                            getOpp.Amount = objOP.getTotalRevenueAmount();
                            getOpp.Estimated_Monthly_Potential_TPV__c = objOP.getTotalEstTPV();
                            getOpp.Estimated_Monthly_Projected_Cost__c = Double.valueOf(objOP.getProjectedCost());
                            
                        }else{
                            Decimal decTotal = updateInitialOpportunity.get(op.Opportunity__c).Amount;
                            Decimal decTPV = updateInitialOpportunity.get(op.Opportunity__c).Estimated_Monthly_Potential_TPV__c;
                            Decimal decCost = updateInitialOpportunity.get(op.Opportunity__c).Estimated_Monthly_Projected_Cost__c;
                            getOpp.Amount = decTotal + objOP.getTotalRevenueAmount();
                            getOpp.Estimated_Monthly_Potential_TPV__c = decTPV + objOP.getTotalEstTPV();
                            getOpp.Estimated_Monthly_Projected_Cost__c = Double.valueOf(decCost) + Double.valueOf(objOP.getProjectedCost());
                        }
                        getOpp.Estimated_Monthly_Revenue__c = getOpp.Amount;
                        updateInitialOpportunity.put(op.Opportunity__c, getOpp);
                    } 
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('XenditOppProductHelper','Xendit_Opportunity_Product__c', 'CalculateInitialValue', 'XenditOppProductTrigger',  e);
        }
    }
    public static void updateOpportunityValue(List<Xendit_Opportunity_Product__c> listNew){
        if(updateInitialOpportunity != null && !updateInitialOpportunity.isEmpty()){
            UpdateInitialOppValue();
        }else{
            updateChildOppName(listNew);
        }
    }

    public static void UpdateInitialOppValue(){
        try{
            if(updateInitialOpportunity != null && !updateInitialOpportunity.isEmpty()){
                List<Opportunity> updateOppList = updateInitialOpportunity.values();
                if(!updateOppList.isEmpty()){
                    setChildOpportunityName(updateOppList);
                    update updateOppList;
                }
            } 
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('XenditOppProductHelper','Xendit_Opportunity_Product__c', 'UpdateInitialOppValue', 'XenditOppProductTrigger',  e);
        }
    }

    public static void setParentOpportunity(List<Xendit_Opportunity_Product__c> listNew){
        for(Xendit_Opportunity_Product__c xOP : listNew){
            if(String.isNotBlank(xOP.Grand_Parent_Opportunity_ID__c)){
                xOP.Parent_Opportunity_Lookup__c = xOP.Grand_Parent_Opportunity_ID__c;
            } 
        }
    }

    public static void setApprovalLevel(List<Xendit_Opportunity_Product__c> listNew){
        System.debug('###setApprovalLevel');
        List<Billing_Type_Approval_Level__mdt> billTypeApprList = [SELECT Billing_Type__c, Billing_Sub_Type__c, Approval_Level__c FROM Billing_Type_Approval_Level__mdt];
        List<Rate_Card_Pricing__c> rateCardPricingList = [SELECT Id, Rate_Per_Txn__c, Rate_Per_TPV__c, Rate_Card__c, Rate_Card_Pricing_Range__c,Rate_Card__r.Reseller_Rate_per_Txn__c,
                                                        Rate_Card_Pricing_Range__r.Pricing_Range_Type__c, Rate_Card_Pricing_Range__r.Range_Order__c, Rate_Card_Pricing_Range__r.Lower_Threshold__c, 
                                                        Rate_Card_Pricing_Range__r.Upper_Threshold__c, Rate_Card_Pricing_Range__r.Approval_Level__c
                                                        FROM Rate_Card_Pricing__c WHERE Rate_Card_Pricing_Range__c != null ORDER BY Rate_Card__c, Rate_Card_Pricing_Range__r.Range_Order__c];
        Map<Id, List<Rate_Card_Pricing__c>> rateCardPricingMap = new Map<Id, List<Rate_Card_Pricing__c>>();
        Map<Id, Rate_Card__c> rateCardMap = new Map<Id, Rate_Card__c>();
        Set<Id> rateCardIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for(Rate_Card_Pricing__c rcPrice : rateCardPricingList){
            //map rate card with related rate card pricing
            if(!rateCardPricingMap.containsKey(rcPrice.Rate_Card__c)){
                rateCardPricingMap.put(rcPrice.Rate_Card__c, new List<Rate_Card_Pricing__c>{rcPrice});
            }else{
                rateCardPricingMap.get(rcPrice.Rate_Card__c).add(rcPrice);
            }
        }
        System.debug('###rateCardPricingMap:' + rateCardPricingMap);
        for(Xendit_Opportunity_Product__c xOpp : listNew){
            rateCardIdSet.add(xOpp.Rate_Card__c);
            oppIdSet.add(xOpp.Parent_Opportunity_Lookup__c);
        }

        if(!rateCardIdSet.isEmpty()){
            rateCardMap = new Map<Id, Rate_Card__c>([SELECT Id, Reseller_Rate_per_Txn__c, Product__c, Product__r.Family, Selected_Value__c, Selected_Value_Source__c, Basket_Size_Threshold__c,
                                                    Price_Floor_Rate_per_Txn__c, Price_Floor_Rate_per_TPV__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, Product__r.Is_VAS_Product__c
                                                    FROM Rate_Card__c WHERE Id IN :rateCardIdSet]);
        }

        if(!oppIdSet.isEmpty()){
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, Owner.Name, Owner.Approval_Level__c FROM Opportunity WHERE Id IN :oppIdSet]);
        }

        Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();  
        for(Xendit_Opportunity_Product__c xOpp : listNew){
            OppProductClass opc = new OppProductClass(xOpp.Opportunity__c);
            Opportunity selectedOpp = opportunityMap.get(xOpp.Parent_Opportunity_Lookup__c);
            Integer oppOwnerLevel = selectedOpp.Owner.Approval_Level__c != null ? Integer.valueOf(selectedOpp.Owner.Approval_Level__c) : 0;
            for(Billing_Type_Approval_Level__mdt billType : billTypeApprList){
                if(xOpp.Billing_Type__c == billType.Billing_Type__c && xOpp.Billing_Sub_Type__c == billType.Billing_Sub_Type__c){
                    xOpp.Billing_Type_Approver_Level__c = billType.Approval_Level__c; //set billing type approval level
                    break;
                }
            }

            if(rateCardPricingMap.containsKey(xOpp.Rate_Card__c)){
                System.debug('###XenditOpp pricing approver level : ' + xOpp.Id + ':::' + xOpp.Pricing_Approver_Level__c);
                opc.getStdPricingTableVal(rateCardPricingMap.get(xOpp.Rate_Card__c), conversionRateMap, xOpp, rateCardMap.get(xOpp.Rate_Card__c), oppOwnerLevel);
            }else{
                opc.getUnsupportedApproverLevelVal(xOpp, rateCardMap.get(xOpp.Rate_Card__c), oppOwnerLevel);
            }
        }
    }

    public static void updateChildOppName(List<Xendit_Opportunity_Product__c> listNew){
        try{
            Map<Id, Opportunity> updateOppMap = new Map<Id, Opportunity>();

            for(Xendit_Opportunity_Product__c xOpp : listNew){
                updateOppMap.put(xOpp.Opportunity__c, new Opportunity(Id = xOpp.Opportunity__c));
            }
            List<Opportunity> updateOppList = updateOppMap.values();
            setChildOpportunityName(updateOppList);
            TriggerBypassUtility.opportunityTriggerBypass = true;
            update updateOppList;
            TriggerBypassUtility.opportunityTriggerBypass = false;
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('XenditOppProductHelper','Xendit_Opportunity_Product__c', 'updateChildOppName', 'XenditOppProductTrigger',  e);
        }
    }

    public static void setChildOpportunityName(List<Opportunity> oppList){

        Map<Id, Set<String>> oppProdFamMap = new Map<Id, Set<String>>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        List<Opportunity> updateOppList = new List<Opportunity>();
        //get list of child opportunity
        for(Opportunity opp : oppList){
            oppProdFamMap.put(opp.Id, new Set<String>());
        }

        //get opp product under the child opps
        for(Xendit_Opportunity_Product__c xOpp : [SELECT Id, Opportunity__c, Rate_Card__r.Product__r.Family FROM Xendit_Opportunity_Product__c WHERE Opportunity__c IN :oppProdFamMap.keySet()]){
            
            //map child opp with related opp product's family
            if(oppProdFamMap.containsKey(xOpp.Opportunity__c) && xOpp.Rate_Card__r.Product__r.Family != null){
                oppProdFamMap.get(xOpp.Opportunity__c).add(xOpp.Rate_Card__r.Product__r.Family);
            }
        }

        for(Opportunity opp : [SELECT Id, Account.Brand__c, Account.BillingCountryCode, Opportunity_Name_Remark__c FROM Opportunity WHERE Id IN :oppProdFamMap.keySet() ]){
            oppMap.put(opp.Id, opp);
        }

        //determine child opp additional name
        for(Opportunity oppObj : oppList){
            Id oppId = oppObj.Id;
            Opportunity opp = oppMap.get(oppId);
            String oppRemark = !String.isBlank(opp.Opportunity_Name_Remark__c) ? (' - ' + opp.Opportunity_Name_Remark__c) : '';
            String oppName = opp.Account.Brand__c + ' - ' + opp.Account.BillingCountryCode + ' - Child - <InsertProdFam>' + oppRemark;
            if(oppProdFamMap.containsKey(oppId) && oppProdFamMap.get(oppId).size() > 0){
                List<String> oppProdFamList = new List<String>(oppProdFamMap.get(oppId));
                String prdFamStr = oppProdFamList.size() > 1 ? 'Multi Products' : oppProdFamList[0];
                String oppStrName = oppName.replace('<InsertProdFam>', prdFamStr);
                oppObj.Name = oppStrName;
            }else{
                String oppStrName = oppName.replace('<InsertProdFam>', 'New');
                oppObj.Name = oppStrName;
            }
        }
    }

    public static Xendit_Opportunity_Product__c createDefaultOppProductDetails(Xendit_Opportunity_Product__c createxOpp, Opportunity opp, Rate_Card__c rct){
        createxOpp.Opportunity__c = opp.Id;
        createxOpp.Product__c = rct.Product__c;
        createxOpp.Rate_Card__c = rct.Id;
        createxOpp.CurrencyIsoCode = rct.CurrencyIsoCode;
        createxOpp.Fixed_Rate_List__c = rct.Fixed_Rate__c;
        createxOpp.Fixed_Rate_Sell__c = rct.Fixed_Rate__c;
        createxOpp.Billing_Type__c = 'Direct Billing';
        createxOpp.Billing_Sub_Type__c = 'Standard';
        if(opp.Account.Is_Reseller__c){
            createxOpp.Rate_Per_TPV_List__c = rct.Reseller_Rate_per_TPV__c;
            createxOpp.Rate_Per_TPV_Sell__c = rct.Reseller_Rate_per_TPV__c;
            createxOpp.Rate_Per_Txn_List__c = rct.Reseller_Rate_per_Txn__c;
            createxOpp.Rate_Per_Txn_Sell__c = rct.Reseller_Rate_per_Txn__c;
        }else{
            Boolean isHeadlinePriceValid = rct.Headline_Rate_per_TPV__c != null || rct.Headline_Rate_per_Txn__c != null;
            createxOpp.Rate_Per_TPV_List__c = isHeadlinePriceValid ? rct.Headline_Rate_per_TPV__c : rct.Rate_Per_TPV__c;
            createxOpp.Rate_Per_TPV_Sell__c = isHeadlinePriceValid ? rct.Headline_Rate_per_TPV__c : rct.Rate_Per_TPV__c;
            createxOpp.Rate_Per_Txn_List__c = isHeadlinePriceValid ? rct.Headline_Rate_per_Txn__c : rct.Rate_Per_Txn__c;
            createxOpp.Rate_Per_Txn_Sell__c = isHeadlinePriceValid ? rct.Headline_Rate_per_Txn__c : rct.Rate_Per_Txn__c;
        }
        createxOpp.Rate_Per_Event_List__c = rct.Rate_Per_Event__c;
        createxOpp.Rate_Per_Event_Sell__c = rct.Rate_Per_Event__c;
        createxOpp.Rate_Per_Subaccount_List__c = rct.Rate_Per_Subaccount__c;
        createxOpp.Rate_Per_Subaccount_Sell__c = rct.Rate_Per_Subaccount__c;
        createxOpp.Basket_Size__c = (opp.Segment__c == 'Enterprise' && rct.Product__r.Basket_Size_Enterprise__c != null) ? rct.Product__r.Basket_Size_Enterprise__c : ((opp.Segment__c == 'SME' && rct.Product__r.Basket_Size_SME__c != null)? rct.Product__r.Basket_Size_SME__c : ((opp.Segment__c == 'Individual' && rct.Product__r.Basket_Size_Individuals__c != null) ? rct.Product__r.Basket_Size_Individuals__c : ((opp.Segment__c == 'MM' && rct.Product__r.Basket_Size_MM__c != null) ? rct.Product__r.Basket_Size_MM__c : null))); //for default Basket Size
        
        if (rct.Brand__c != null) {
            createxOpp.Brand__c = rct.Brand__c;
        }
        if (rct.Channel__c != null) {
            createxOpp.Channel__c = rct.Channel__c;
        }

        return createxOpp;
    }
}