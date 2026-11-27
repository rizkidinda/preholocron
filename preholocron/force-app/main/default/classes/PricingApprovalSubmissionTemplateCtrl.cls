public without sharing class PricingApprovalSubmissionTemplateCtrl {

    public String apprRecordId{get;set;} 
    public Decimal totalHeadlineRevenue {get;set;}
    
    public Opportunity_Approval__c appObj{
        get{
            if(!String.isBlank(apprRecordId)){
                List<Opportunity_Approval__c> getApprObj = [SElECT Id, Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Account.Brand__c, Opportunity__r.Account.Segment__c, Opportunity__r.Account.Industry_Category__c, 
                                                        toLabel(Opportunity__r.Account.Child_Industry_v2__c),Opportunity__r.Addressable_Merchant_TPV_Monthly__c, Opportunity__r.Addressable_Merchant_Revenue_Monthly__c,
                                                        Opportunity__r.Gross_Take_Rate__c, Opportunity__r.Addressable_Monthly_Profitability__c, Opportunity__r.Xst_Txn_Act_Date__c, Requests__c, Justification2__c,
                                                        Opportunity__c, Opportunity__r.Account.Name, Opportunity__r.AccountId, Opportunity__r.CurrencyIsoCode, Opportunity__r.Addressable_Project_Cost_Monthly__c, Opportunity__r.Total_Gross_Profit_Margin__c
                                                        FROM Opportunity_Approval__c WHERE Id =: apprRecordId LIMIT 1 ];
            return getApprObj[0];
            }else{
                return null;
            }
            
        }
        set;
    }

    public List<OppProductEmailTemplateClass> oppProdList{
        get{
            List<OppProductEmailTemplateClass> returnList = new List<OppProductEmailTemplateClass>();
            if(!String.isBlank(apprRecordId)){
                totalHeadlineRevenue = 0;
                for(Xendit_Opportunity_Product__c xOpp : [SELECT Id, currencyIsoCode, Product__r.Name, Rate_Per_TPV_Sell__c, Rate_Per_Txn_Sell__c, Rate_Card__r.Headline_Rate_per_TPV__c, Rate_Card__r.Headline_Rate_per_Txn__c, Product__r.Family,
                Rate_Card__r.COGS_Fixed_Fee__c, Rate_Card__r.COGS_MDR__c, Billing_Type__c, Billing_Sub_Type__c, Is_Below_COGS__c, Available_Lowest_Rate_per_Txn__c, Available_Lowest_Rate_per_TPV__c, Projected_Cost__c, Total_Revenue__c, 
                Revenue_TPV__c, Revenue_Txn__c, Revenue_Subaccount__c, Revenue_Event__c, TPV__c, Basket_Size__c, FX_Rate__c, Fixed_Rate_Sell__c, Number_Subaccount__c, Rate_Per_Subaccount_Sell__c, Event_Count__c, Rate_Per_Event_Sell__c,
                Parent_Opportunity_Lookup__c, Rate_Card__c, Rate_Card__r.Selected_Value__c, Rate_Card__r.Selected_Value_Source__c, Rate_Card__r.Basket_Size_Threshold__c, Rate_Card__r.Description__c, Product_Label__c,
                Xendit_Rate_BPS__c,Rate_to_customer_BPS__c,Expected_Monthly_Volume__c, Margin_BPS__c,Rate_Card__r.Brand__c,FX_Product_Approval__c                                          
               FROM Xendit_Opportunity_Product__c WHERE Opportunity__r.StageName != 'Closed Lost' AND Parent_Opportunity_Lookup__c IN (SELECT Opportunity__c FROM Opportunity_Approval__c WHERE Id =: apprRecordId)]){
                    OppProductEmailTemplateClass temp = new OppProductEmailTemplateClass();
                    String billSubtype = !String.isBlank(xOpp.Billing_Sub_Type__c) ? ' - ' + xOpp.Billing_Sub_Type__c : '';
                    temp.channelName = xOpp.Product__r.Name + (String.isBlank(xOpp.Rate_Card__r.Description__c) ? '' : (' - ' + xOpp.Rate_Card__r.Description__c));
                    temp.offeredMDR = xOpp.Rate_Per_TPV_Sell__c != null ? xOpp.Rate_Per_TPV_Sell__c : 0;
                    temp.availableLowestMDR = xOpp.Available_Lowest_Rate_per_TPV__c != null ? xOpp.Available_Lowest_Rate_per_TPV__c : 0;
                    temp.thresholdMDR = xOpp.Rate_Card__r.Headline_Rate_per_TPV__c != null ? xOpp.Rate_Card__r.Headline_Rate_per_TPV__c : 0;
                    temp.cogsMDR = xOpp.Rate_Card__r.COGS_MDR__c != null? xOpp.Rate_Card__r.COGS_MDR__c : 0;
                    temp.offeredRatePerTxn = xOpp.Rate_Per_Txn_Sell__c != null ? xOpp.Rate_Per_Txn_Sell__c : 0;
                    temp.availableLowestRatePerTxn = xOpp.Available_Lowest_Rate_per_Txn__c != null ? xOpp.Available_Lowest_Rate_per_Txn__c : 0;
                    temp.thresholdRatePerTxn = xOpp.Rate_Card__r.Headline_Rate_per_Txn__c != null ? xOpp.Rate_Card__r.Headline_Rate_per_Txn__c : 0;
                    temp.cogsRatePerTxn = xOpp.Rate_Card__r.COGS_Fixed_Fee__c != null ? xOpp.Rate_Card__r.COGS_Fixed_Fee__c : 0;
                    temp.withDiscount = ((temp.offeredMDR < temp.availableLowestMDR) || (temp.offeredRatePerTxn < temp.availableLowestRatePerTxn)) ? 'Yes' : 'No';
                    temp.belowCOGS = (xOpp.Is_Below_COGS__c) ? 'Yes' : 'No';
                    temp.billingType = xOpp.Billing_Type__c + billSubtype;
                    temp.currencyIsoCode = xOpp.currencyIsoCode;
                    temp.totalRevenue = xOpp.Total_Revenue__c != null ? xOpp.Total_Revenue__c : 0;
                    temp.projectedCost = xOpp.Projected_Cost__c != null ? xOpp.Projected_Cost__c : 0;
                    temp.productFamily = xOpp.Product__r.Family;
                    //calculate headline revenue
                    Rate_Card__c selectedRateCardObj = new Rate_Card__c(Id = xOpp.Rate_Card__c, Headline_Rate_per_TPV__c = xOpp.Rate_Card__r.Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c = xOpp.Rate_Card__r.Headline_Rate_per_Txn__c, 
                                                                        COGS_Fixed_Fee__c = xOpp.Rate_Card__r.COGS_Fixed_Fee__c, COGS_MDR__c = xOpp.Rate_Card__r.COGS_MDR__c, Selected_Value__c = xOpp.Rate_Card__r.Selected_Value__c, Selected_Value_Source__c = xOpp.Rate_Card__r.Selected_Value_Source__c, Basket_Size_Threshold__c = xOpp.Rate_Card__r.Basket_Size_Threshold__c);
                    String strFormula = RevenueClass.getRevenueFormula(xOpp.Product__r.Family);
                    Xendit_Opportunity_Product__c headlineOppProduct = xOpp;
                    headlineOppProduct.Rate_Per_Txn_Sell__c = temp.thresholdRatePerTxn;
                    headlineOppProduct.Rate_Per_TPV_Sell__c = temp.thresholdMDR;
                    headlineOppProduct.Fixed_Rate_Sell__c = temp.thresholdRatePerTxn;
                    headlineOppProduct.Rate_Per_Subaccount_Sell__c = temp.thresholdRatePerTxn;
                    headlineOppProduct.Rate_Per_Event_Sell__c = temp.thresholdRatePerTxn;
                    OppProductClass opc = new OppProductClass(xOpp.Parent_Opportunity_Lookup__c);
                    if(xOpp.Product__r.Family != null && xOpp.Product__r.Family.contains('Unsupported Product')){ //exclude headline for unsupported product - make headline revenue the same as actual revenue
                        headlineOppProduct.Total_Revenue__c = xOpp.Total_Revenue__c != null ? xOpp.Total_Revenue__c : 0;
                        temp.isUnsupportedProduct = true;
                        temp.channelName = !String.isBlank(xOpp.Product_Label__c) ? xOpp.Product_Label__c : (xOpp.Product__r.Name + (String.isBlank(xOpp.Rate_Card__r.Description__c) ? '' : (' - ' + xOpp.Rate_Card__r.Description__c)));
                    }else{
                        opc.recalculate(strFormula, headlineOppProduct, selectedRateCardObj);
                    }
                    temp.headlineTotalRevenue = headlineOppProduct.Total_Revenue__c != null ? headlineOppProduct.Total_Revenue__c : 0;
                    totalHeadlineRevenue += temp.headlineTotalRevenue;
                    returnList.add(temp);
                }
            }

            return returnList;
        }
        set;
    }

    public String envURL{
        get{
            String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            return baseURL;
        }
        set;
    }

    public Double rateOriCurrency{
        get{
            Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();
            if(conversionRateMap.containsKey(appObj.Opportunity__r.CurrencyIsoCode)){
                return conversionRateMap.get(appObj.Opportunity__r.CurrencyIsoCode);
            }
            return 1;
        }
        set;
    }

    
}