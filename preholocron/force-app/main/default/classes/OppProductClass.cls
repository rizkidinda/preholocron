/** to support OppItemController */
public class OppProductClass {
    public Xendit_Opportunity_Product__c XP {get;set;}
    public Boolean isSelected {get;set;}
    public Product2 P {get;set;}
    public String calcSelectionType {get;set;}
    public Double calcThreshold {get;set;}
    public String selectedFieldForHigherThreshold {get;set;}
    public Boolean ratePerTxnActive {get;set;}
    public Boolean MDRActive {get;set;}
    public Boolean rateCardAutoCalc {get;set;}
    public Decimal availableLowestRatePerTxn {get;set;}
    public Decimal availableLowestRatePerTPV {get;set;}
    public String productFamilyFormula {get;set;}
    public Boolean showBillingApprovalMsg {get;set;}
    public Boolean showPricingApprovalMsg {get;set;}
	public OppProductClass(Id idOpp)
    {
        isSelected = false;
        XP = new Xendit_Opportunity_Product__c(Opportunity__c = idOpp);
        P = new Product2();
        calcSelectionType = '';
        calcThreshold = null;
        selectedFieldForHigherThreshold = '';
        ratePerTxnActive = true;
        MDRActive = true;
        rateCardAutoCalc = false;
        productFamilyFormula = '';
        showBillingApprovalMsg = false;
        showPricingApprovalMsg = false;
    }
    
    // validate input (simple)
    public Map<String, String> isValid(String strFormula)
    {
        Map<String, String> mapErr = new Map<String, String>();
        String strErr;
        
        if (strFormula == RevenueClass.FORMULA1) 
        {
            if(XP.Product__r.Family =='Over the Counter (OTC)' && XP.CurrencyIsoCode == 'PHP' && XP.Rate_Per_TPV_Sell__c == null){
               mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) cannot be blank');
            }
            if (XP.Basket_Size__c == null) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn cannot be blank');
            }
            else if (XP.Basket_Size__c <= 0) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn must be bigger than zero');
            }
            if (XP.TPV__c == null) {
                mapErr.put('TPV__c', 'TPV cannot be blank');
            }
            else if (XP.TPV__c <= 0) {
                mapErr.put('TPV__c', 'TPV must be bigger than zero');
            }
            if (XP.Rate_Per_Txn_Sell__c == null) {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Rate Per Txn (Selling) cannot be blank');
            }
            else if (XP.Rate_Per_Txn_Sell__c <= 0 && XP.Product__r.Family !='Over the Counter (OTC)' && XP.CurrencyIsoCode != 'PHP') {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Rate Per Txn (Selling) must be bigger than zero');
            }
        }
        if (strFormula == RevenueClass.FORMULA2 || 
            strFormula == RevenueClass.FORMULA4 || strFormula == RevenueClass.FORMULA5 ) 
        {
            
            if (XP.TPV__c == null) {
                mapErr.put('TPV__c', 'TPV cannot be blank');
            }
            else if (XP.TPV__c <= 0) {
                mapErr.put('TPV__c', 'TPV must be bigger than zero');
            }
            if (XP.Rate_Per_TPV_Sell__c == null) {
                mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) cannot be blank');
            }
            else if (XP.Rate_Per_TPV_Sell__c <= 0  ) {
                mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) must be bigger than zero');
            }
            if (XP.Basket_Size__c == null) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn cannot be blank');
            }
            else if (XP.Basket_Size__c <= 0) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn must be bigger than zero');
            }
        }
        
        if (strFormula == RevenueClass.FORMULA3) 
        {
            system.debug('DEBUG: check formula 3 -- ' + XP);
            
            if (XP.Basket_Size__c == null) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn cannot be blank');
            }
            else if (XP.Basket_Size__c <= 0) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn must be bigger than zero');
            }
			
            if (XP.TPV__c == null) {
                mapErr.put('TPV__c', 'TPV cannot be blank');
            }
            else if (XP.TPV__c <= 0) {
                mapErr.put('TPV__c', 'TPV must be bigger than zero');
            }
            /*if (XP.Rate_Per_Txn_Sell__c == null) {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Rate Per Txn (Selling) cannot be blank');
            }
            else */
            if (XP.Rate_Per_Txn_Sell__c < 0) {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Rate Per Txn (Selling) must be bigger than zero');
            }
            
            /*if (XP.Rate_Per_TPV_Sell__c == null) {
                mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) cannot be blank');
            }
            else */
            if (XP.Rate_Per_TPV_Sell__c < 0) {
                mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) must be bigger than zero');
            }
            
            // updates, either can be blank
            if ((XP.Rate_Per_Txn_Sell__c == null || XP.Rate_Per_Txn_Sell__c  == 0) && 
                (XP.Rate_Per_TPV_Sell__c == null || XP.Rate_Per_TPV_Sell__c  == 0))
            {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Both Rate Per Txn (Selling) and Rate Per TPV (Selling) cannot be blank');
            }
            
        }

        if (strFormula == RevenueClass.FORMULA7) 
        {
            if (XP.Basket_Size__c == null) { XP.Basket_Size__c = 0; 
            } else if (XP.Basket_Size__c < 0) {
                mapErr.put('Basket_Size__c', 'Avg TPV per Txn cannot be less than zero');
            }
			
            if (XP.TPV__c == null) { XP.TPV__c = 0; 
            } else if (XP.TPV__c < 0) {
                mapErr.put('TPV__c', 'TPV cannot be less than zero');
            }
            
            if(XP.Rate_Per_Txn_Sell__c == null){ XP.Rate_Per_Txn_Sell__c = 0;
            } else if (XP.Rate_Per_Txn_Sell__c < 0) {
                mapErr.put('Rate_Per_Txn_Sell__c', 'Rate Per Txn (Selling) cannot be less than zero');
            }
            
            if (XP.Rate_Per_TPV_Sell__c == null) { XP.Rate_Per_TPV_Sell__c = 0;
            } else if (XP.Rate_Per_TPV_Sell__c < 0) {
                mapErr.put('Rate_Per_TPV_Sell__c', 'Rate Per TPV (Selling) cannot be less than zero');
            }
        }

        if (strFormula == RevenueClass.FORMULA5 ) 
        {
            XP.Rate_Per_Txn_Sell__c = XP.Fixed_Rate_Sell__c;
            if (XP.Fixed_Rate_Sell__c == null) {
                mapErr.put('Fixed_Rate_Sell__c', 'Fixed Rate (Selling) cannot be blank');
            }
            else if (XP.Fixed_Rate_Sell__c <= 0) {
                mapErr.put('Fixed_Rate_Sell__c', 'Fixed Rate (Selling) must be bigger than zero');
            }
            if (XP.Number_Subaccount__c == null) {
                mapErr.put('Number_Subaccount__c', 'Number of Active Subaccount cannot be blank');
            }
            else if (XP.Number_Subaccount__c <= 0) {
                mapErr.put('Number_Subaccount__c', 'Number of Active Subaccount must be bigger than zero');
            }
            if (XP.Rate_Per_Subaccount_Sell__c == null) {
                mapErr.put('Rate_Per_Subaccount_Sell__c', 'Rate Per Subaccount (Selling) cannot be blank');
            }
            else if (XP.Rate_Per_Subaccount_Sell__c <= 0) {
                mapErr.put('Rate_Per_Subaccount_Sell__c', 'Rate Per Subaccount (Selling) must be bigger than zero');
            }
            
        }
        else if (strFormula == RevenueClass.FORMULA6 ) 
        {
            
            if (XP.Event_Count__c == null) {
                mapErr.put('Event_Count__c', 'Event count cannot be blank');
            }
            else if (XP.Event_Count__c <= 0) {
                mapErr.put('Event_Count__c', 'Event count must be bigger than zero');
            }
            if (XP.Rate_Per_Event_Sell__c == null) {
                mapErr.put('Rate_Per_Event_Sell__c', 'Rate Per Event (Selling) cannot be blank');
            }
            else if (XP.Rate_Per_Event_Sell__c <= 0) {
                mapErr.put('Rate_Per_Event_Sell__c', 'Rate Per Event (Selling) must be bigger than zero');
            }
        }
        else if (strFormula == RevenueClass.FORMULA9){
            if(XP.Rate_to_customer_BPS__c == null ){
                mapErr.put('Rate_to_customer_BPS__c', 'Rate to Customer (BPS) cannot be blank');
            }
            if(XP.Expected_Monthly_Volume__c == null ){
                mapErr.put('Expected_Monthly_Volume__c', 'Expected monthly volume cannot be blank');
            }
        }
        else if (strFormula == RevenueClass.FORMULA10){
            if(XP.No_of_API_Calls__c == null ){
                mapErr.put('No_of_API_Calls__c', 'No of API Calls cannot be blank');
            }
            if(XP.Rate_per_API_Call__c == null ){
                mapErr.put('Rate_per_API_Call__c', 'Rate per API Call cannot be blank');
            }
        }
        
        if (mapErr.size() > 0) { 
            for(String s: mapErr.keySet()) {
                XP.addError(s, mapErr.get(s));
            }
            
            return mapErr; 
        }
        else { return null; }
    }
    
    // recalculate some formula fields
    public void recalculate(String strFormula, Xendit_Opportunity_Product__c XP, Rate_Card__c rc)
    {
        if(strFormula == RevenueClass.FORMULA8){
            XP.Total_Revenue__c = XP.Total_Revenue__c == null ? 0 : XP.Total_Revenue__c; 
            XP.Revenue_TPV__c = XP.Revenue_TPV__c == null ? 0 : XP.Revenue_TPV__c;
            XP.Revenue_Txn__c = XP.Revenue_Txn__c == null ? 0 : XP.Revenue_Txn__c;
            XP.Revenue_Subaccount__c = XP.Revenue_Subaccount__c == null ? 0 : XP.Revenue_Subaccount__c;
            XP.Revenue_Event__c = XP.Revenue_Event__c == null ? 0 : XP.Revenue_Event__c;
        }else{
            XP.Total_Revenue__c = 0; // reset
            XP.Revenue_TPV__c = 0;
            XP.Revenue_Txn__c = 0;
            XP.Revenue_Subaccount__c = 0;
            XP.Revenue_Event__c = 0;
        }
        
        XP.Projected_Cost__c = calculateCost(XP, strFormula);
        if (strFormula == RevenueClass.FORMULA1) {
            if (XP.TPV__c != null && XP.Basket_Size__c != null && XP.Rate_Per_Txn_Sell__c != null) {XP.Revenue_Txn__c = (XP.TPV__c / XP.Basket_Size__c) * XP.Rate_Per_Txn_Sell__c;
            }
            if(XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null){ XP.Revenue_TPV__c = XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01;}
            
            if(XP.Product__r.Family =='Over the Counter (OTC)' && XP.CurrencyIsoCode == 'PHP'){ XP.Total_Revenue__c = XP.Revenue_TPV__c + XP.Revenue_Txn__c;
            }else{ XP.Total_Revenue__c = XP.Revenue_Txn__c;}
        }
        else if (strFormula == RevenueClass.FORMULA2) {
            
            if (XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null) {
                XP.Revenue_TPV__c = XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01;
                XP.Total_Revenue__c = XP.Revenue_TPV__c;
            }
            
        }
        else if (strFormula == RevenueClass.FORMULA3) {
            if (XP.TPV__c != null && XP.Basket_Size__c != null && XP.Rate_Per_Txn_Sell__c != null){
                XP.Revenue_Txn__c = (XP.TPV__c / XP.Basket_Size__c) * XP.Rate_Per_Txn_Sell__c;
            }
            
            if (XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null) 
            {
                XP.Revenue_TPV__c = XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01;
            } 
            XP.Total_Revenue__c = XP.Revenue_TPV__c + XP.Revenue_Txn__c;
        }
        else if (strFormula == RevenueClass.FORMULA4) {
            
            if (XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null) 
            {
                // todo, get FX Rate
                if (XP.FX_Rate__c == null) {
                    XP.FX_Rate__c = 1; // default
                }
                
                XP.Revenue_TPV__c = XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01 * XP.FX_Rate__c;
                XP.Total_Revenue__c = XP.Revenue_TPV__c;
            }
            
        }

        else if (strFormula == RevenueClass.FORMULA6) {
            
            if (XP.Event_Count__c != null && XP.Rate_Per_Event_Sell__c != null) 
            {
                XP.Revenue_Event__c = XP.Event_Count__c * XP.Rate_Per_Event_Sell__c;
                XP.Total_Revenue__c = XP.Revenue_Event__c;
            }
            
        }                
        else if(strFormula == RevenueClass.FORMULA9){
            if(XP.Xendit_Rate_BPS__c != null && XP.Expected_Monthly_Volume__c != null){
                decimal margin;
                if (XP.Xendit_Rate_BPS__c > 0) {
                    margin = (XP.Rate_to_customer_BPS__c - XP.Xendit_Rate_BPS__c);
                } else {
                    margin = -(XP.Rate_to_customer_BPS__c - XP.Xendit_Rate_BPS__c);
                }
                
                XP.Total_Revenue__c = margin/10000 * XP.Expected_Monthly_Volume__c;
                XP.FX_Product_Approval__c = False;
                if(margin < 0){
                    XP.FX_Product_Approval__c = TRUE;
                }
            }
        }
        
        else if (strFormula == RevenueClass.FORMULA7) {
            
            if (XP.TPV__c != null && XP.Basket_Size__c != null && XP.Rate_Per_Txn_Sell__c != null && XP.Basket_Size__c > 0) 
            {
                XP.Revenue_Txn__c = (XP.TPV__c / XP.Basket_Size__c) * XP.Rate_Per_Txn_Sell__c;
                
            }else{
                XP.Revenue_Txn__c = 0;
            }

            if (XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null) 
            {
                XP.Revenue_TPV__c = XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01;
            }else{
                XP.Revenue_TPV__c = 0;
            }

            XP.Total_Revenue__c = XP.Revenue_TPV__c + XP.Revenue_Txn__c;
        }
        else if (strFormula == RevenueClass.FORMULA5) {
            
            if (XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null && 
                XP.Fixed_Rate_Sell__c != null && XP.Number_Subaccount__c != null && 
                XP.Rate_Per_Subaccount_Sell__c != null) 
            {
                XP.Rate_Per_Txn_Sell__c = XP.Fixed_Rate_Sell__c;
                XP.Revenue_Subaccount__c = XP.Number_Subaccount__c * XP.Rate_Per_Subaccount_Sell__c;
                XP.Revenue_TPV__c = XP.Fixed_Rate_Sell__c * XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01;
                XP.Total_Revenue__c = XP.Revenue_TPV__c + XP.Revenue_Subaccount__c;
            }
            
        }
        else if (strFormula == RevenueClass.FORMULA10) {
            if (XP.No_of_API_Calls__c != null && XP.Rate_per_API_Call__c != null){
                XP.Total_Revenue__c = XP.No_of_API_Calls__c * XP.Rate_per_API_Call__c;
            }
        }


        //if(xOppProdCalcList != null && !xOppProdCalcList.isEmpty()){
            if((!String.isBlank(rc.Selected_Value__c) && !String.isBlank(rc.Selected_Value_Source__c) && rc.Basket_Size_Threshold__c != null)){ 
               //logic 1 : use threshold
               //Double rcThreshold = xOppCalcObj.Threshold_Value__c;
               Double rcThreshold = rc.Basket_Size_Threshold__c;
               Double xOppThresActVal = XP.Basket_Size__c;
               Boolean isRatePerTxnFieldsValid = xOppThresActVal != null && XP.TPV__c != null && XP.Rate_Per_Txn_Sell__c != null;
               Boolean isMDRFieldsValid = XP.TPV__c != null && XP.Rate_Per_TPV_Sell__c != null;
               Double currTotalRev = XP.Total_Revenue__c;
               Double currRevTxn = XP.Revenue_Txn__c;
               Double currRevTPV = XP.Revenue_TPV__c;
               Boolean ratePerTxnForHigherVal = (rc.Selected_Value__c == 'Higher' && rc.Selected_Value_Source__c == 'Rate per Txn') || (rc.Selected_Value__c == 'Lower' && rc.Selected_Value_Source__c == 'Rate per TPV');
               Boolean ratePerTPVForHigherVal = (rc.Selected_Value__c == 'Higher' && rc.Selected_Value_Source__c == 'Rate per TPV') || (rc.Selected_Value__c == 'Lower' && rc.Selected_Value_Source__c == 'Rate per Txn');
               
                
                
                if(xOppThresActVal != null && xOppThresActVal != 0 && rcThreshold != null && xOppThresActVal > rcThreshold){
                Double newVal = (ratePerTxnForHigherVal && isRatePerTxnFieldsValid) ? (XP.TPV__c / XP.Basket_Size__c) * XP.Rate_Per_Txn_Sell__c : ((ratePerTPVForHigherVal && isMDRFieldsValid) ? XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01 : currTotalRev);
                XP.Total_Revenue__c = newVal;
                XP.Revenue_TPV__c = (ratePerTxnForHigherVal && isRatePerTxnFieldsValid) ? 0 : 
                                    ((ratePerTPVForHigherVal && isMDRFieldsValid) ? newVal : currRevTPV);
                XP.Revenue_Txn__c = (ratePerTxnForHigherVal && isRatePerTxnFieldsValid) ? newVal : 
                                    ((ratePerTPVForHigherVal && isMDRFieldsValid) ? 0 : currRevTxn);
               }else{
                Double newVal = (!ratePerTxnForHigherVal && isRatePerTxnFieldsValid && XP.Basket_Size__c != null && XP.Basket_Size__c != 0) ? (XP.TPV__c / XP.Basket_Size__c) * XP.Rate_Per_Txn_Sell__c : 
                ((!ratePerTPVForHigherVal && isMDRFieldsValid) ? XP.TPV__c * XP.Rate_Per_TPV_Sell__c * 0.01 : currTotalRev);
                XP.Total_Revenue__c = newVal;
                XP.Revenue_TPV__c = (!ratePerTxnForHigherVal && isRatePerTxnFieldsValid) ? 0 : ((!ratePerTPVForHigherVal && isMDRFieldsValid) ? newVal : currRevTPV);
                XP.Revenue_Txn__c = (!ratePerTxnForHigherVal && isRatePerTxnFieldsValid) ? newVal : ((!ratePerTPVForHigherVal && isMDRFieldsValid) ? 0 : currRevTxn);
               }
        }
        
        system.debug('DEBUG: formula Total_Revenue__c' + strFormula + ' total ' + XP.Total_Revenue__c);
    }

    public Double calculateCost(Xendit_Opportunity_Product__c XP, String strFormula){
        system.debug('calculate cost');
        //total cost = (COGS (fixed fee) * txn count) + ((COGS (MDR) /100) * est monthly tpv)
        Double txnCount = XP.TPV__c != null && XP.Basket_Size__c != null && XP.Basket_Size__c > 0 ? Double.valueOf(Integer.valueOf(XP.TPV__c / XP.Basket_Size__c)) : null;
        Double costFixedFee = XP.Rate_Card__r.COGS_Fixed_Fee__c != null && txnCount != null ? Double.valueOf(XP.Rate_Card__r.COGS_Fixed_Fee__c) * Double.valueOf(txnCount) : 0;
        Double costMDR = XP.Rate_Card__r.COGS_MDR__c != null && XP.TPV__c != null ? (Double.valueOf(XP.Rate_Card__r.COGS_MDR__c) * 0.01) * Double.valueOf(XP.TPV__c) : 0;
        system.debug('cost fixed fee : ' + costFixedFee + ' costMDR : ' + costMDR);
        if(strFormula == RevenueClass.FORMULA7 || strFormula == RevenueClass.FORMULA8){
            return XP.Projected_Cost__c;
        }
        return (costFixedFee + costMDR);
    }

    public Double compareVals(Double d1, Double d2, String state){
        if(state == 'Higher'){
            if(d1 > d2){
                return d1;
            }else {
                return d2;
            }
        }else if(state == 'Lower'){
            if(d1 <= d2){
                return d1;
            }else {
                return d2;
            }
        }else{
            return null;
        }
    }  
    
    public Integer compareValInt(Double d1, Double d2, String state){
        if(state == 'Higher'){
            if(d1 > d2){
                return 1;
            }else {
                return 2;
            }
        }else if(state == 'Lower'){
            if(d1 <= d2){
                return 1;
            }else {
                return 2;
            }
        }else{
            return null;
        }
    }  
    
    //check if fx product need approval
    public Boolean checkFXApproval(){
        Boolean chk  = false;
        decimal margin;
        if(Xp.Rate_to_customer_BPS__c != NULL && Xp.Xendit_Rate_BPS__c != NULL ){
            if (XP.Xendit_Rate_BPS__c > 0) {
                margin = (XP.Rate_to_customer_BPS__c - XP.Xendit_Rate_BPS__c);
            } else{
                margin = -(XP.Rate_to_customer_BPS__c - XP.Xendit_Rate_BPS__c);
            }
            
            XP.FX_Product_Approval__c = False;
            if(margin < 0){
                chk = true;
                XP.FX_Product_Approval__c = TRUE;
            }
        }
        
        return chk;
    }
    
    // check if require pricing approval
    public Boolean checkPricingApproval()
    {
        Boolean chk = false;  
        if((XP.Pricing_Approver_Level__c != null && XP.Pricing_Approver_Level__c > 0 ) || (XP.Billing_Type__c != null && !(XP.Billing_Type__c == 'Direct Billing' && XP.Billing_Sub_Type__c == 'Standard'))){
            chk = true; 
        }
        return chk;
    }
    
    // show total revenue in amount
    public Decimal getTotalRevenueAmount()
    {
        Decimal decRes = (XP.Total_Revenue__c == null) ? 0.0 : XP.Total_Revenue__c;
        return decRes;
    }

    // show total est monthly TPV
    public Decimal getTotalEstTPV()
    {
        Decimal decRes = (XP.TPV__c == null) ? 0.0 : XP.TPV__c;
        return decRes;
    }
    
    // show transaction count
    public String getTrxCount()
    {
        Decimal decRes = (XP.Basket_Size__c == null || XP.Basket_Size__c == 0 || XP.TPV__c == null) ? 0.0 : (XP.TPV__c / XP.Basket_Size__c);
        return decRes.setScale(0).format();
    }
    // show total revenue
    public String getTotalRevenue()
    {
        Decimal decRes = (XP.Total_Revenue__c == null) ? 0.00 : XP.Total_Revenue__c;
        System.debug('Total Revenue get: '+ XP.Product_Label__c + ' ' + decRes);
        return getCents(decRes);
    }
    // show total revenue
    public String getTotalRevenueTPV()
    {
        Decimal decRes = (XP.Revenue_TPV__c == null) ? 0.0 : XP.Revenue_TPV__c;
        return decRes.setScale(2).format();
    }
    // show total revenue
    public String getTotalRevenueTxn()
    {
        Decimal decRes = (XP.Revenue_Txn__c == null) ? 0.0 : XP.Revenue_Txn__c;
        return decRes.setScale(2).format();
    }
    
    // show total revenue
    public String getTotalRevenueSubaccount()
    {
        Decimal decRes = (XP.Revenue_Subaccount__c == null) ? 0.0 : XP.Revenue_Subaccount__c;
        return decRes.setScale(2).format();
    }
    
    // show total revenue
    public String getTotalRevenueEvent()
    {
        Decimal decRes = (XP.Revenue_Event__c == null) ? 0.0 : XP.Revenue_Event__c;
        return decRes.setScale(2).format();
    }
    // show total projected cost
    public String getProjectedCost()
    {
        Decimal decRes = (XP.Projected_Cost__c == null) ? 0.0 : XP.Projected_Cost__c;
        return decRes.setScale(2).format();
    }

    // show total revenue
    public String getLowestRatePerTxn()
    {
        Decimal decRes = (XP.Revenue_Event__c == null) ? 0.0 : XP.Revenue_Event__c;
        return decRes.setScale(2).format();
    }

    public Integer getBillingApprovalLevel(){
        Integer returnVal = 0;
        returnVal = XP.Billing_Type_Approver_Level__c != null ? Integer.valueOf(XP.Billing_Type_Approver_Level__c) : 0;
        return returnVal;
    }

    public Integer getPricingApprovalLevel(){
        Integer returnVal = 0;
        Integer ownerApprovalLevel = XP.Opportunity__r.Owner.Approval_Level__c != null ? Integer.valueOf(XP.Opportunity__r.Owner.Approval_Level__c) : 0;
        returnVal = XP.Pricing_Approver_Level__c != null  && Integer.valueOf(XP.Pricing_Approver_Level__c) > ownerApprovalLevel ? Integer.valueOf(XP.Pricing_Approver_Level__c) : 0;
        return returnVal;
    }

    //get standard pricing table values
    public void getStdPricingTableVal(List<Rate_Card_Pricing__c> rateCardPriceList, Map<String, Decimal> conversionRateMap, Xendit_Opportunity_Product__c xOpp, Rate_Card__c rc, Integer ownerLevel){
        Integer i = 1;
        Integer apprLevelPricingTable = null;
        Integer selectedArray = null;
        Decimal currRatePerTxn = 0;
        Product2 getVASProduct = [SELECT Name, is_Vas_Product__c FROM Product2 WHERE id = :xOpp.product__c LIMIT 1];    //cannot get direct to ratecard from oppitemcontroller
        if(getVASProduct.is_Vas_Product__c){
            currRatePerTxn = xOpp.Rate_per_API_Call__c != null ? xOpp.Rate_per_API_Call__c : 0;
        }else{
            currRatePerTxn = xOpp.Rate_Per_Txn_Sell__c != null ? xOpp.Rate_Per_Txn_Sell__c : 0;
        }
        Decimal currRatePerTPV = xOpp.Rate_Per_TPV_Sell__c != null ? xOpp.Rate_Per_TPV_Sell__c : 0;
        Decimal userLowestRatePerTxn = null;
        Decimal userLowestRatePerTPV = null;
        Decimal rcHeadlineRatePerTPV = rc.Headline_Rate_per_TPV__c != null ? rc.Headline_Rate_per_TPV__c : 0;
        Decimal rcHeadlineRatePerTxn = rc.Headline_Rate_per_Txn__c != null ? rc.Headline_Rate_per_Txn__c : 0;
        Boolean isAmtgtHeadline = currRatePerTxn >= rcHeadlineRatePerTxn && currRatePerTPV >= rcHeadlineRatePerTPV; 
        Boolean isPopulated = false;
        Boolean isORValue = (!String.isBlank(rc.Selected_Value__c) && !String.isBlank(rc.Selected_Value_Source__c) && rc.Basket_Size_Threshold__c != null); //use rate card selected value
        Boolean ratePerTxnForHigherVal = isORValue && (rc.Selected_Value__c == 'Higher' && rc.Selected_Value_Source__c == 'Rate per Txn') || (rc.Selected_Value__c == 'Lower' && rc.Selected_Value_Source__c == 'Rate per TPV');
        Boolean ratePerTPVForHigherVal = isORValue && (rc.Selected_Value__c == 'Higher' && rc.Selected_Value_Source__c == 'Rate per TPV') || (rc.Selected_Value__c == 'Lower' && rc.Selected_Value_Source__c == 'Rate per Txn');
        Boolean ratePerAPIForHigherVal = isORValue && (rc.Selected_Value__c == 'Higher' && rc.Selected_Value_Source__c == 'Rate per API') || (rc.Selected_Value__c == 'Lower' && rc.Selected_Value_Source__c == 'Rate per API');

        for(Rate_Card_Pricing__c prc : rateCardPriceList){
            String rangeType = prc.Rate_Card_Pricing_Range__r.Pricing_Range_Type__c;
            Double selectedAmount = null;
            //add new range = 'Monthly API Count'
            if(rangeType == 'Monthly API Count'){
                selectedAmount = xOpp.No_of_API_Calls__c != null ? xOpp.No_of_API_Calls__c : null; 
            }
            else if(rangeType == 'Monthly Transaction Count'){
                //get Monthly Txn Count
                selectedAmount = xOpp.TPV__c != null && xOpp.Basket_Size__c != null && xOpp.Basket_Size__c > 0 ? Double.valueOf(Integer.valueOf(xOpp.TPV__c / xOpp.Basket_Size__c)) : null;
            }else if(rangeType == 'Monthly Product TPV'){
                //get monthly TPV
                selectedAmount =  xOpp.TPV__c != null ? xOpp.TPV__c : null;
            }
            Boolean isReseller = xOpp.Opportunity_Account_Is_Reseller__c;
            Boolean isLastPriceRange = i == rateCardPriceList.size();
            Boolean isAmtgtLowerThreshold = selectedAmount != null && ((prc.Rate_Card_Pricing_Range__r.Lower_Threshold__c > 0 && selectedAmount > prc.Rate_Card_Pricing_Range__r.Lower_Threshold__c) 
                                            || (prc.Rate_Card_Pricing_Range__r.Lower_Threshold__c == 0 && selectedAmount >= prc.Rate_Card_Pricing_Range__r.Lower_Threshold__c));
            Boolean isAmtlteUpperThreshold = selectedAmount != null && (prc.Rate_Card_Pricing_Range__r.Upper_Threshold__c == null || selectedAmount <= prc.Rate_Card_Pricing_Range__r.Upper_Threshold__c);
            Decimal rangeRatePerTxn = prc.Rate_Per_Txn__c != null ? prc.Rate_Per_Txn__c : 0;
            Decimal rangeRatePerTPV = prc.Rate_Per_TPV__c != null ? prc.Rate_Per_TPV__c : 0;  
            Boolean isStdRange = false;
            Integer intOwnerLevel = ownerLevel != null ? ownerLevel : 0;
            Integer rangeApprovalLevel = prc.Rate_Card_Pricing_Range__r.Approval_Level__c != null ? Integer.valueOf(prc.Rate_Card_Pricing_Range__r.Approval_Level__c) : 0;
            
            if(
                (isReseller && isLastPriceRange) ||
                (!isReseller && isAmtgtLowerThreshold && isAmtlteUpperThreshold)
            ){
                //get std value
                xOpp.Rate_per_Txn_from_Pricing_Table__c = rangeRatePerTxn;
                xOpp.Rate_per_TPV_from_Pricing_Table__c = rangeRatePerTPV;
                isStdRange = true;
                if(!isPopulated){
                    xOpp.Pricing_Approver_Level__c = prc.Rate_Card_Pricing_Range__r.Approval_Level__c != null ? Integer.valueOf(prc.Rate_Card_Pricing_Range__r.Approval_Level__c) : 0;
                }
                selectedArray = i; //to get the next record in the loop after this
                System.debug('###xOpp.Pricing_Approver_Level__c ' + selectedArray +' :'+ xOpp.Pricing_Approver_Level__c );
            }

            if( isAmtgtHeadline ||
                (!isPopulated && (isStdRange || intOwnerLevel >= rangeApprovalLevel) && ( //!isPopulated = not stamped as approvel level 0
                (!isORValue && currRatePerTxn >= rangeRatePerTxn && currRatePerTPV >= rangeRatePerTPV ) ||
                (isORValue && (ratePerTxnForHigherVal && rangeRatePerTxn > 0 && currRatePerTxn >= rangeRatePerTxn) || 
                    (ratePerTPVForHigherVal && rangeRatePerTPV > 0 && currRatePerTPV >= rangeRatePerTPV)|| 
                    (ratePerAPIForHigherVal && rangeRatePerTxn > 0 && currRatePerTxn >= rangeRatePerTxn))
                ))
                ){
                xOpp.Pricing_Approver_Level__c = 0;
                isPopulated = true;
            }

            //if current pricing range have same approver level with the current user, populate the value
            if(ownerLevel != null && ownerLevel > 0 && prc.Rate_Card_Pricing_Range__r.Approval_Level__c != null && Integer.valueOf(prc.Rate_Card_Pricing_Range__r.Approval_Level__c) == ownerLevel){
                userLowestRatePerTxn = rangeRatePerTxn;
                userLowestRatePerTPV = rangeRatePerTPV;
            }

            i++;
        }

        //if level is highest approver, can use price floor value
        Boolean priceFloorHasValue = rc.Price_Floor_Rate_per_TPV__c != null || rc.Price_Floor_Rate_per_Txn__c != null;
        if(ownerLevel != null && ownerLevel == Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT) && priceFloorHasValue){
            userLowestRatePerTPV = rc.Price_Floor_Rate_per_TPV__c != null ? rc.Price_Floor_Rate_per_TPV__c : null;
            userLowestRatePerTxn = rc.Price_Floor_Rate_per_Txn__c != null ? rc.Price_Floor_Rate_per_Txn__c : null;
        }

        Decimal stdRatePerTxn = xOpp.Rate_per_Txn_from_Pricing_Table__c != null ? xOpp.Rate_per_Txn_from_Pricing_Table__c : 0;
        Decimal stdRatePerTPV = xOpp.Rate_per_TPV_from_Pricing_Table__c != null ? xOpp.Rate_per_TPV_from_Pricing_Table__c : 0;
        
        xOpp.Available_Lowest_Rate_per_Txn__c = userLowestRatePerTxn != null && userLowestRatePerTxn < stdRatePerTxn ? userLowestRatePerTxn : stdRatePerTxn;
        xOpp.Available_Lowest_Rate_per_TPV__c = userLowestRatePerTPV != null && userLowestRatePerTPV < stdRatePerTPV ? userLowestRatePerTPV : stdRatePerTPV;
        
        if(isPopulated){

        }
        else if((rc.Product__r.Family != null && rc.Product__r.Family.contains('Unsupported Product')) ||
                (xOpp.Product__r.Family != null && xOpp.Product__r.Family.contains('Unsupported Product'))){
                getUnsupportedApproverLevelVal(xOpp, rc, ownerLevel);
        }
        //if existing pricing range and value inputted is below standard pricing from the table
        else if(selectedArray != null && selectedArray < rateCardPriceList.size() && ((stdRatePerTxn > 0 && currRatePerTxn < stdRatePerTxn) 
                || (stdRatePerTPV > 0 && currRatePerTPV < stdRatePerTPV))){    //add rateperAPI
            //get the next pricing approver level - because provided price range is ordered by the pricing range
            for(Integer j = selectedArray ; j < rateCardPriceList.size() ; j++){
                Decimal selectedRatePerTxn = rateCardPriceList[j].Rate_Per_Txn__c != null ? rateCardPriceList[j].Rate_Per_Txn__c : 0;
                Decimal selectedRatePerTPV = rateCardPriceList[j].Rate_Per_TPV__c != null ? rateCardPriceList[j].Rate_Per_TPV__c : 0;
                //Decimal selectedRatePerAPI = rateCardPriceList[j].Rate_Per_API_Call__c != null ? rateCardPriceList[j].Rate_Per_API_Call__c : 0;   //add rateperAPI TAKEOUT

                //add rateperAPI condition if currRateperAPI >= rangeRatePerAPI
                if((!isORValue && (stdRatePerTxn > 0 && currRatePerTxn < stdRatePerTxn && currRatePerTxn >= selectedRatePerTxn) || 
                    (stdRatePerTPV > 0 && currRatePerTPV < stdRatePerTPV && currRatePerTPV >= selectedRatePerTPV)) ||
                    (isORValue && (ratePerTxnForHigherVal && stdRatePerTxn > 0 && currRatePerTxn < stdRatePerTxn && currRatePerTxn >= selectedRatePerTxn) || 
                    (ratePerTPVForHigherVal && stdRatePerTPV > 0 && currRatePerTPV < stdRatePerTPV && currRatePerTPV >= selectedRatePerTPV)|| 
                    (ratePerAPIForHigherVal && stdRatePerTxn > 0 && currRatePerTxn < stdRatePerTxn && currRatePerTxn >= selectedRatePerTxn))
                    ){
                        
                    xOpp.Pricing_Approver_Level__c = rateCardPriceList[j].Rate_Card_Pricing_Range__r.Approval_Level__c;
                   
                    if(ownerLevel != null && ownerLevel > 0 && rateCardPriceList[j].Rate_Card_Pricing_Range__r.Approval_Level__c != null && Integer.valueOf(rateCardPriceList[j].Rate_Card_Pricing_Range__r.Approval_Level__c) <= ownerLevel){
                        xOpp.Pricing_Approver_Level__c = 0;
                    }
                    System.debug('###pricing approver level based on pricing range'+ xOpp.Pricing_Approver_Level__c);
                    break;
                }else{
                    xOpp.Pricing_Approver_Level__c = Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT);
                    if(ownerLevel != null && ownerLevel > 0 && xOpp.Pricing_Approver_Level__c <= ownerLevel){
                        xOpp.Pricing_Approver_Level__c = 0;
					}
                    System.debug('###else pricing approver level based on pricing range' + xOpp.Pricing_Approver_Level__c);
                }
            }
        }else if(rateCardPriceList != null && !rateCardPriceList.isEmpty() && (selectedArray == null || selectedArray == rateCardPriceList.size())){
            //add condition for reseller account
            if((xOpp.Rate_Per_Txn_Sell__c >= rc.Reseller_Rate_per_Txn__c && xOpp.Rate_per_API_Call__c == NULL) || (xOpp.Rate_per_API_Call__c >= rc.Reseller_Rate_per_Txn__c && xOpp.Rate_per_API_Call__c != NULL) && xOpp.Opportunity_Account_Is_Reseller__c){
                xOpp.Pricing_Approver_Level__c = 0;
            }
            else{
                //go to highest approver level which is 3
                System.debug('###go to highest approver level');
                xOpp.Pricing_Approver_Level__c = Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT);
                if(ownerLevel != null && ownerLevel > 0 && xOpp.Pricing_Approver_Level__c <= ownerLevel){
                        xOpp.Pricing_Approver_Level__c = 0;
                }
            }
        }
    }

    public void getUnsupportedApproverLevelVal(Xendit_Opportunity_Product__c xOpp, Rate_Card__c rc, Integer ownerLevel){
        Integer intOwnerLevel = ownerLevel != null ? ownerLevel : 0;
        Integer defaultApproverLevel = Integer.valueOf(System.Label.HIGHEST_APPROVER_LEVEL_DEFAULT);
        if((rc.Product__r.Family != null && rc.Product__r.Family.contains('Unsupported Product')) ||
                (xOpp.Product__r.Family != null && xOpp.Product__r.Family.contains('Unsupported Product'))){
            xOpp.Pricing_Approver_Level__c = intOwnerLevel >= defaultApproverLevel ? 0 : defaultApproverLevel;
        }
    }

    private String getCents(Decimal x){
        String y = String.valueOf(x);
        String z = '.';
        if(y.contains(',')){
            z = ',';
        } 

        if(y.indexOf(z) > -1){
            y = y.substring(0, y.indexOf(z));
        }
        
        if(x - Decimal.valueOf(y) == 0){
            return String.valueOf(x.format()) + z + '00';
        }else{
            return String.valueOf(x.format());
        }
    }
}