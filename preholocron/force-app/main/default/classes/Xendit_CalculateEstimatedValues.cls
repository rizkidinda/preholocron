public class Xendit_CalculateEstimatedValues {
    
    /**********************************************************************************************************************
    * Query Parent Opportunities, Child Opportunities, Xendit Products and Ramp Records
    * Loop through each one of them and sum up its values
    * Update Products, Child and Parent Opportunities
    *********************************************************************************************************************/
        
    public static Boolean boolOppProductRecalculate = false;
    public static void caculateFormulaFields(set<id>parentids) {
        System.debug('##in caculateFormulaFields');
        boolOppProductRecalculate = true;
        list<Opportunity_Ramp__c> rampList=new list<Opportunity_Ramp__c>();
        map<decimal,Opportunity_Ramp__c> parentRampMap=new map<decimal,Opportunity_Ramp__c>();
        list<Opportunity>updateOpportunities=new list<Opportunity>();
        list<Xendit_Opportunity_Product__c> updateProducts=new list<Xendit_Opportunity_Product__c>();
        map<id,map<id,Opportunity>> parentChildMap=new map<id,map<id,opportunity>>();
        map<id,Opportunity> parentOppMap=new map<id,opportunity>();
        map<id,list<Xendit_Opportunity_Product__c>> oppProdMap=new map<id,list<Xendit_Opportunity_Product__c>>();
        map<id,list<Opportunity_Ramp__c>> prodRampMap=new map<id,list<Opportunity_Ramp__c>>();
        set<id>productIds=new set<id>();
        set<id>childOppIds=new set<id>();
        
        try{   
            Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();  
            for(Opportunity parentRec:[SELECT Id, AccountId, Addressable_iY_Revenue__c,Addressable_wiY_Revenue__c,Addressable_iY_TPV__c, Billing_Type_Approval_Level__c, Pricing_Approver_Level__c, Opp_Product_Below_COGS_Count__c,Opp_Product_with_Manual_Billing__c, Need_L1_Billing_Type_Approval__c, Opp_Unsuported_Product_Count__c,
                                       Addressable_wiY_TPV__c, CurrencyIsoCode, Owner.Approval_Level__c FROM Opportunity where id =:parentids])
            {
                
                parentOppMap.put(parentRec.id,parentRec);
            }
            
            
            for(Opportunity opp:[select Estimated_wiY_TPV__c,Estimated_iY_Revenue__c,Estimated_Monthly_Potential_TPV__c,Parent_Opportunity__c, Opp_Product_Below_COGS_Count__c,Opp_Product_with_Manual_Billing__c,Opp_Unsuported_Product_Count__c,
                                 Estimated_iY_TPV__c,Estimated_wiY_Revenue__c,Estimated_Monthly_Revenue__c, Estimated_Monthly_Projected_Cost__c, Xst_Txn_Act_Date__c, Parent_Opportunity__r.Xst_Txn_Act_Date__c, OwnerId, Parent_Opportunity__r.OwnerId, CurrencyIsoCode, Billing_Type_Approval_Level__c, Pricing_Approver_Level__c, Need_L1_Billing_Type_Approval__c
                                 from opportunity where StageName != 'Closed Lost' AND Parent_Opportunity__c=:parentOppMap.keyset()])
            {
                map<id,opportunity> tempMap=new map<id,opportunity>();
                if(parentChildMap.containsKey(opp.Parent_Opportunity__c))
                    tempMap=parentChildMap.get(opp.Parent_Opportunity__c);
                tempMap.put(opp.id,opp);
                parentChildMap.put(opp.Parent_Opportunity__c,tempMap);
                childOppIds.add(opp.id);
            }
            
            List<Xendit_Opportunity_Product__c> xOppList = [select id,Total_Revenue__c,TPV__c,Opportunity__c, Parent_Opportunity_Lookup__c, Projected_Cost__c,
                                                            Estimated_iY_TPV__c,Estimated_wiY_TPV__c,Estimated_wiY_Revenue__c, CurrencyIsoCode, Billing_Type_Approver_Level__c, Pricing_Approver_Level__c, Is_Below_COGS__c, Is_Manual_Billing__c,
                                                            Rate_Card__c, Billing_Type__c, Billing_Sub_Type__c, Rate_Per_Txn_Sell__c, Rate_Per_TPV_Sell__c, Basket_Size__c, Opportunity_Account_Is_Reseller__c, Rate_per_Txn_from_Pricing_Table__c, Rate_per_TPV_from_Pricing_Table__c,
                                                            Available_Lowest_Rate_per_Txn__c, Available_Lowest_Rate_per_TPV__c, Product__r.Family, Product__r.Is_VAS_Product__c, No_of_API_Calls__c, Rate_per_API_Call__c  
                                                            from Xendit_Opportunity_Product__c
                                                            where Opportunity__c=:childOppIds];
            if(!xOppList.isEmpty()){
                System.debug('##XCE: call setApprovalLevel '+ xOppList);
                XenditOppProductHelper.setApprovalLevel(xOppList);
            }
            
            for(Xendit_Opportunity_Product__c prod: xOppList)
            {
                list<Xendit_Opportunity_Product__c> tempList=new list<Xendit_Opportunity_Product__c>();
                
                if(oppProdMap.containsKey(prod.Opportunity__c))
                    tempList=oppProdMap.get(prod.Opportunity__c);
                tempList.add(prod);
                oppProdMap.put(prod.Opportunity__c,tempList);
                productIds.add(prod.id);
            }
            
            for(Opportunity_Ramp__c ramp:[select id,Estimated_TPV__c,Estimated_Opportunity_weighted_TPV__c,Xendit_Opportunity_Product__c,
                                          Estimated_Revenue__c,Estimated_Opportunity_weighted_Revenue__c, CurrencyIsoCode,
                                          Transaction_Date__c from Opportunity_Ramp__c where Xendit_Opportunity_Product__c=:productIds])
            {
                list<Opportunity_Ramp__c> tempList=new list<Opportunity_Ramp__c>();
                
                if(prodRampMap.containsKey(ramp.Xendit_Opportunity_Product__c))
                    tempList=prodRampMap.get(ramp.Xendit_Opportunity_Product__c);
                tempList.add(ramp);
                prodRampMap.put(ramp.Xendit_Opportunity_Product__c,tempList);
            }
            
            List<Integer> parentPriceApprLevel = new List<Integer>();
            List<Integer> parentBillTypeApprLevel = new List<Integer>();
            
            for(Opportunity parentRec:parentOppMap.values())
            {
                parentRec.Addressable_iY_Revenue__c=0;
                parentRec.Addressable_wiY_TPV__c=0;
                parentRec.Addressable_wiY_Revenue__c=0;
                parentRec.Addressable_iY_TPV__c=0;
                parentRec.Addressable_Merchant_TPV_Monthly__c=0;
                parentRec.Addressable_Merchant_Revenue_Monthly__c=0;
                parentRec.Addressable_Project_Cost_Monthly__c = 0;
                parentRec.Opp_Product_Below_COGS_Count__c = 0;
                parentRec.Opp_Unsuported_Product_Count__c = 0;
                parentRec.Opp_Product_with_Manual_Billing__c = 0;
                if(parentChildMap.containsKey(parentRec.id))
                {
                    map<id,opportunity> tempChildMap=new map<id,opportunity> ();
                    tempChildMap=parentChildMap.get(parentRec.id);
                    List<Integer> priceApprLevel = new List<Integer>();
                    List<Integer> billTypeApprLevel = new List<Integer>();
                    Boolean parentOppOwnerUpdate = false;
                    for(Opportunity childOpp:tempChildMap.values())
                    {
                        childOpp.Estimated_iY_TPV__c=0;
                        childOpp.Estimated_iY_Revenue__c=0;
                        childOpp.Estimated_wiY_TPV__c=0;
                        childOpp.Estimated_wiY_Revenue__c=0; 
                        childOpp.Estimated_Monthly_Potential_TPV__c=0;
                        childOpp.Estimated_Monthly_Revenue__c=0;
                        childOpp.Estimated_Monthly_Projected_Cost__c = 0;
                        childOpp.Opp_Product_Below_COGS_Count__c = 0;
                        childOpp.Opp_Unsuported_Product_Count__c = 0;
                        childOpp.Opp_Product_with_Manual_Billing__c = 0;
                        childOpp.Xst_Txn_Act_Date__c = childOpp.Parent_Opportunity__r.Xst_Txn_Act_Date__c != null ? childOpp.Parent_Opportunity__r.Xst_Txn_Act_Date__c : null;
                        if(childOpp.OwnerId != childOpp.Parent_Opportunity__r.OwnerId){
                            childOpp.OwnerId = childOpp.Parent_Opportunity__r.OwnerId;
                            parentOppOwnerUpdate = true;
                        }
                        

                        if(oppProdMap.containskey(childOpp.id))
                        {
                            for(Xendit_Opportunity_Product__c prod:oppProdMap.get(childOpp.id))
                            {
                                prod.Estimated_iY_TPV__c=0;
                                prod.Estimated_iY_Revenue__c=0; 
                                prod.Estimated_wiY_TPV__c=0;
                                prod.Estimated_wiY_Revenue__c=0;
                                if(prod.TPV__c==null)prod.TPV__c=0;
                                if(prod.Total_Revenue__c==null)prod.Total_Revenue__c=0;
                                if(prod.Projected_Cost__c == null)prod.Projected_Cost__c = 0;
                                
                                if(prodRampMap.containsKey(prod.id))
                                {
                                    for(Opportunity_Ramp__c ramp:prodRampMap.get(prod.id))
                                    {
                                        if(ramp.Estimated_TPV__c==null)ramp.Estimated_TPV__c=0;
                                        if(ramp.Estimated_Revenue__c==null)ramp.Estimated_Revenue__c=0;
                                        
                                        if(ramp.Transaction_Date__c.year()==system.today().year()){
                                            prod.Estimated_iY_TPV__c= prod.Estimated_iY_TPV__c+Utility.valueConversion(conversionRateMap,ramp.Estimated_TPV__c, ramp.CurrencyIsoCode,prod.CurrencyIsoCode);
                                            prod.Estimated_iY_Revenue__c=prod.Estimated_iY_Revenue__c+Utility.valueConversion(conversionRateMap,ramp.Estimated_Revenue__c, ramp.CurrencyIsoCode,prod.CurrencyIsoCode);
                                            prod.Estimated_wiY_TPV__c=prod.Estimated_wiY_TPV__c+Utility.valueConversion(conversionRateMap,ramp.Estimated_Opportunity_weighted_TPV__c, ramp.CurrencyIsoCode,prod.CurrencyIsoCode);
                                            prod.Estimated_wiY_Revenue__c= prod.Estimated_wiY_Revenue__c+Utility.valueConversion(conversionRateMap,ramp.Estimated_Opportunity_weighted_Revenue__c, ramp.CurrencyIsoCode,prod.CurrencyIsoCode);
                                        }
                                    }
                                }
                                
                                system.debug('$$$$'+prod);
                                updateProducts.add(prod);
                                childOpp.Estimated_iY_TPV__c=childOpp.Estimated_iY_TPV__c+Utility.valueConversion(conversionRateMap,prod.Estimated_iY_TPV__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_iY_Revenue__c=childOpp.Estimated_iY_Revenue__c+Utility.valueConversion(conversionRateMap,prod.Estimated_iY_Revenue__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_wiY_TPV__c=childOpp.Estimated_wiY_TPV__c+Utility.valueConversion(conversionRateMap,prod.Estimated_wiY_TPV__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_wiY_Revenue__c=childOpp.Estimated_wiY_Revenue__c+Utility.valueConversion(conversionRateMap,prod.Estimated_wiY_Revenue__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_Monthly_Potential_TPV__c= childOpp.Estimated_Monthly_Potential_TPV__c+Utility.valueConversion(conversionRateMap,prod.TPV__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_Monthly_Revenue__c=childOpp.Estimated_Monthly_Revenue__c+Utility.valueConversion(conversionRateMap,prod.Total_Revenue__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);
                                childOpp.Estimated_Monthly_Projected_Cost__c= childOpp.Estimated_Monthly_Projected_Cost__c + Utility.valueConversion(conversionRateMap,prod.Projected_Cost__c, prod.CurrencyIsoCode,childOpp.CurrencyIsoCode);

                                if(prod.Billing_Type_Approver_Level__c != null){
                                    billTypeApprLevel.add(Integer.valueOf(prod.Billing_Type_Approver_Level__c));
                                }
                                System.debug('###XCE - prod.Pricing_Approver_Level__c : ' + prod.Pricing_Approver_Level__c );
                                if(prod.Pricing_Approver_Level__c != null){
                                    priceApprLevel.add(Integer.valueOf(prod.Pricing_Approver_Level__c));
                                    System.debug('###XCE - prod.Pricing_Approver_Level__c : ' + prod.Pricing_Approver_Level__c );
                                }

                                if(prod.Is_Below_COGS__c){
                                    childOpp.Opp_Product_Below_COGS_Count__c +=1;
                                }

                                if(prod.Product__r.Family != null && prod.Product__r.Family.contains('Unsupported Product')){
                                    childOpp.Opp_Unsuported_Product_Count__c += 1;
                                }

                                if(prod.Is_Manual_Billing__c){
                                    childOpp.Opp_Product_with_Manual_Billing__c += 1;
                                }

                                system.debug('monthly rev : ' );
                            }
                        }
                        if(!billTypeApprLevel.isEmpty()){
                            billTypeApprLevel.sort();
                            childOpp.Billing_Type_Approval_Level__c = billTypeApprLevel.get(billTypeApprLevel.size() - 1);
                            childOpp.Need_L1_Billing_Type_Approval__c = billTypeApprLevel.contains(1) ? true : false;
                        }

                        if(!priceApprLevel.isEmpty()){
                            priceApprLevel.sort();
                            childOpp.Pricing_Approver_Level__c = priceApprLevel.get(priceApprLevel.size() - 1);
                            System.debug('###XCE - childOpp.Pricing_Approver_Level__c : ' + childOpp.Pricing_Approver_Level__c );
                        }

                        parentRec.Addressable_iY_Revenue__c=parentRec.Addressable_iY_Revenue__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_iY_Revenue__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_wiY_TPV__c=parentRec.Addressable_wiY_TPV__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_wiY_TPV__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_wiY_Revenue__c=parentRec.Addressable_wiY_Revenue__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_wiY_Revenue__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_iY_TPV__c=parentRec.Addressable_iY_TPV__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_iY_TPV__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_Merchant_TPV_Monthly__c=parentRec.Addressable_Merchant_TPV_Monthly__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_Monthly_Potential_TPV__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_Merchant_Revenue_Monthly__c=parentRec.Addressable_Merchant_Revenue_Monthly__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_Monthly_Revenue__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Addressable_Project_Cost_Monthly__c = parentRec.Addressable_Project_Cost_Monthly__c+ Utility.valueConversion(conversionRateMap, childOpp.Estimated_Monthly_Projected_Cost__c, childOpp.CurrencyIsoCode, parentRec.CurrencyIsoCode);
                        parentRec.Refresh_Ramp__c=false;
                        parentRec.Opp_Product_Below_COGS_Count__c += childOpp.Opp_Product_Below_COGS_Count__c;
                        parentRec.Opp_Unsuported_Product_Count__c += childOpp.Opp_Unsuported_Product_Count__c;
                        parentRec.Opp_Product_with_Manual_Billing__c += childOpp.Opp_Product_with_Manual_Billing__c;
                        parentRec.Amount = parentRec.Addressable_Merchant_Revenue_Monthly__c;
                        if(childOpp.Billing_Type_Approval_Level__c != null){
                            parentBillTypeApprLevel.add(Integer.valueOf(childOpp.Billing_Type_Approval_Level__c));
                        }

                        if(childOpp.Pricing_Approver_Level__c != null){
                            parentPriceApprLevel.add(Integer.valueOf(childOpp.Pricing_Approver_Level__c));
                        }

                        if(childOpp.Need_L1_Billing_Type_Approval__c){
                            parentRec.Need_L1_Billing_Type_Approval__c = true;
                        }
                        
                        updateOpportunities.add(childOpp);
                    }
                    if(!parentBillTypeApprLevel.isEmpty()){
                        parentBillTypeApprLevel.sort();
                        parentRec.Billing_Type_Approval_Level__c = parentBillTypeApprLevel.get(parentBillTypeApprLevel.size() - 1);
                    }

                    if(!parentPriceApprLevel.isEmpty()){
                        parentPriceApprLevel.sort();
                        parentRec.Pricing_Approver_Level__c = parentPriceApprLevel.get(parentPriceApprLevel.size() - 1);
                    }

                    Decimal estMonthlyProfitability = parentRec.Addressable_Project_Cost_Monthly__c > 0 ? (parentRec.Addressable_Merchant_Revenue_Monthly__c - parentRec.Addressable_Project_Cost_Monthly__c) / parentRec.Addressable_Project_Cost_Monthly__c : 0;
                    if(parentRec.Opp_Product_Below_COGS_Count__c > 0){
                        //if parent has at least 1 product below COGS, default pricing approver
                        if(estMonthlyProfitability >= 0){
                            parentRec.Pricing_Approver_Level__c = Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT);
                        }else{
                            parentRec.Pricing_Approver_Level__c = Integer.valueOf(System.Label.EXCEPTION_APPROVER_LEVEL_DEFAULT);
                        }   
                    }else{
                        if(parentRec.Addressable_Project_Cost_Monthly__c > 0 && estMonthlyProfitability >= 0 && estMonthlyProfitability < 0.1){
                            parentRec.Pricing_Approver_Level__c = Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT);
                        }
                    }

                    Integer ownerApprLevel = parentRec.Owner.Approval_Level__c != null ? Integer.valueOf(parentRec.Owner.Approval_Level__c) : 0;
                    if(parentRec.Pricing_Approver_Level__c <= ownerApprLevel){
                        parentRec.Pricing_Approver_Level__c = 0;
                    }

                    //if owner id is changed, update to initial pricing approval status
                    if(parentOppOwnerUpdate){
                        Boolean isPricingApprovalExist = parentRec.Pricing_Approver_Level__c != null && parentRec.Pricing_Approver_Level__c > 0;
                        Boolean isBillingApprovalExist = parentRec.Billing_Type_Approval_Level__c != null && parentRec.Billing_Type_Approval_Level__c > 0;
                        parentRec.Pricing_Approval__c = isPricingApprovalExist || isBillingApprovalExist ? 'Approval Required' : 'No approval required';
                    }
                }
                
                updateOpportunities.add(parentRec);
                
            }
            
            //update records
            database.update(updateProducts,false);
            database.update(updateOpportunities,false);

            OpportunityHelper.updateAddressableOppAccount(null, null, parentOppMap.values());
            boolOppProductRecalculate = false;
        }
        catch(Exception ex){ 
            boolOppProductRecalculate = false;
            system.debug('$$$'+ex.getMessage()+'\n'+ex.getLineNumber()+'\n'+ex.getCause());
        }
    }
}