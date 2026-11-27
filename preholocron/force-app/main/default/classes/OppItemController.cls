/**
 * @description       : Controller for page to manage opportunity item
 * @last modified on  : 18-01-2024
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class OppItemController {

    public static final Integer SHOW_PB = 0;
    public static final Integer SHOW_PRD = 1;
    public static final Integer SHOW_OPP = 2;
    
    public Id idOpp {get;set;}
    public Opportunity objOpp {get;set;}
    public Set<String> xOppProductFamilySet {get;set;}
    public Map<String, List<OppProductClass>> arrOppProductsMap {get;set;}
    public List<ProductRateClass> arrRateList {get;set;}
    public Map<String, List<ProductRateClass>> arrRateMap {get;set;}
    public Map<String, OppProdFamilyClass> prodFamMap {get;set;}
    public Set<String> productFamilySet {get;set;}
    public Map<String, Integer> productFamilyMap {get;set;}
    //public List<Xendit_Opportunity_Product_Calculation__c> oppProdCalcList {get;set;}
    public List<Rate_Card_Pricing__c> rateCardList {get;set;}
    public Set<Id> stProductOppIds {get;set;} // set of product id in Opp product items
    public String strFormulaName {get;set;}
    public Set<String> stProdChannels {get;set;} // set of prod ID + channel in existing open opp in same account
    //public List<Channel_KYC__c> arrKYC {get;set;} // existing active channel KYC
    public Set<String> stProdKYC {get;set;}
    public Boolean hasRateCardCalc {get;set;} //return true if at least 1 rate card is in opp product calculation records per product family
    
    // layout options
    public Integer showType {get;set;}
    public Boolean bolEditable {get;set;}
    
    // message
    public String strErrorMsg {get;set;}
    public String strSuccessMsg {get;set;}
    
    public OppItemController()
    {
        strFormulaName = '';
    }
    
    public void clearMesages()
    {
        strSuccessMsg = strErrorMsg = ''; // clear
    }
    
    /** initialisation */
    public PageReference init()
    {
        system.debug('init');
        clearMesages();
        showType = SHOW_OPP; // default
        bolEditable = false;

        reloadOpportunity();
        //reloadOppProductCalculations();
        getRateCardPricing();
        reloadOpportunityProducts();
        getLowestAvailableValues(arrOppProductsMap);
        reloadProductRates();
        getUserIsEditable();
        return null;
    }
    
    // load list of product
    public void reloadProductRates()
    {
        
        arrRateList = new List<ProductRateClass>();
       	arrRateMap = new Map<String, List<ProductRateClass>>();
        productFamilySet = new Set<String>();
        productFamilyMap = new Map<String, Integer>();

        ProductRateClass objR;
        String strTmp;
        system.debug('DEBUG stProdOpp ' + stProductOppIds);
        if (objOpp.Xendit_Price_Book__c != null) {
            for(Rate_Card__c R:[SELECT Id, Name, Xendit_price_book__c, Product__c, Brand__c, Channel__c,
                                CurrencyIsoCode, Description__c, Fixed_Rate__c,Rate_Per_TPV__c, Rate_Per_Txn__c, Headline_Rate_per_TPV__c, Headline_Rate_per_Txn__c, Reseller_Rate_per_TPV__c, Reseller_Rate_per_Txn__c,
                                Rate_Per_Event__c,  Rate_Per_Subaccount__c, Xendit_Rate_BPS__c,Product__r.Name, Product__r.Family, Product__r.ProductCode, Product__r.is_Vas_product__c,
                                Product__r.Basket_Size_Enterprise__c, Product__r.Basket_Size_SME__c, Product__r.Basket_Size_Individuals__c, Product__r.Basket_Size_MM__c, //for default Basket Size
                                (SELECT Id, Rate_Per_Txn__c, Rate_Per_TPV__c, Rate_Card__c, Rate_Card_Pricing_Range__c, Rate_Card_Pricing_Range__r.Pricing_Range_Type__c, Rate_Card_Pricing_Range__r.Range_Order__c, 
                                Rate_Card_Pricing_Range__r.Lower_Threshold__c, Rate_Card_Pricing_Range__r.Upper_Threshold__c, Rate_Card_Pricing_Range__r.Approval_Level__c
                                FROM Rate_Card_Pricings__r WHERE Rate_Card_Pricing_Range__c != null ORDER BY Rate_Card_Pricing_Range__r.Range_Order__c)
                                FROM Rate_Card__c WHERE Xendit_Price_Book__c = :objOpp.Xendit_Price_Book__c
                                	AND Product__r.IsActive = true 
                                ORDER BY Product__r.Family, Product__r.Name])
            {
                strTmp = R.Product__c;//  + '' + R.Channel__c; (per July 22, no channel)
                
                if (R.Product__c != null && (!stProductOppIds.contains(R.Id) || R.Product__r.Family.contains('Unsupported Product')) )  //Unsupported product will always be displayed
                {
                   
                    objR = new ProductRateClass();
                    objR.R = R;
                    objR.P = R.Product__r;
                    Set<String> exceptionType = new Set<String>{'Upsell'};
                    Boolean exstSameProduct = false;
                    if(arrOppProductsMap != null && !arrOppProductsMap.isEmpty()){
                        for(String fam : arrOppProductsMap.keySet()){
                            for(OppProductClass oPC : arrOppProductsMap.get(fam)){
                                Xendit_Opportunity_Product__c oppProduct = oPC.XP;
                                if(oppProduct != null && oppProduct.Product__c == R.Product__c){
                                    exstSameProduct = true;
                                    break;
                                }
                            }
                        }
                    }
                    
                    
                    if(R.Product__r.Family != null && !R.Product__r.Family.contains('Unsupported Product')){ //exclude Unsupported Product for validation
                        if (!exceptionType.contains(objOpp.Type) && stProdChannels.contains(strTmp)) {
                            // disabled
                            objR.isDisabled = (objOpp.Type == 'Winback/Churn Recovery') ? false : true;
                            objR.Notes = 'This Channel is selected in another open opportunity, please use or update the existing opportunity.';
                        }
                        else if (!exceptionType.contains(objOpp.Type) && stProdKYC.contains(strTmp)) {
                            // disabled
                            objR.isDisabled = (objOpp.Type == 'Winback/Churn Recovery' || objOpp.Type == 'Renegotiation') ? false : true;
                            objR.Notes = 'This Channel is already activated with this merchant BID. Please check the "Channel KYC" section under the Account page.';
                        }
                        else if(objOpp.Type == 'Upsell' && !stProdKYC.contains(strTmp)){
                            objR.isDisabled = true;
                            objR.Notes = 'This Channel is not activated yet, you are not allowed to select it to upsell';
                        }
                        else if(objOpp.Type == 'Renegotiation' && !stProdKYC.contains(strTmp)){
                            objR.isDisabled = true;
                            objR.Notes = 'This Channel is not activated yet, you are not allowed to select it to Renegotiation';
                        }else if(objOpp.Type == 'Winback/Churn Recovery'){
                            objR.Notes = 'Available to select';
                        }
    
                        Boolean isReseller = objOpp.Account.Is_Reseller__c;
                        if(exstSameProduct && !isReseller){
                            objR.isDisabled = true;
                            objR.Notes = 'Another Rate Card with the same Product has been selected';
                        }
                    }
                                       
                    arrRateList.add(objR); 
                    if(R.Product__r.Family != null && !arrRateMap.containsKey(R.Product__r.Family)){
                        arrRateMap.put(R.Product__r.Family, new List<ProductRateClass>{objR});
                        productFamilySet.add(R.Product__r.Family);
                    }else{
                        arrRateMap.get(R.Product__r.Family).add(objR);
                    }

                    Integer tempCount = 1;
                    if(productFamilyMap.containsKey(R.Product__r.Family)){
                        tempCount = productFamilyMap.get(R.Product__r.Family) + 1;
                    }

                    if(R.Product__r.Family != null && R.Product__r.Family.contains('Unsupported Product')){
                        tempCount = 10;
                    }
                    
                    productFamilyMap.put(R.Product__r.Family, tempCount);
                }
                else {
                    system.debug('DEBUG: exlude this ' + R.Product__c);
                }
            }
        }
        
    }
    
    // reload opportunity
    public void reloadOpportunity()
    {
        
        objOpp = new Opportunity();
        //arrKYC = new List<Channel_KYC__c>();
        stProductOppIds = new Set<Id>();
        stProdChannels = new Set<String>();
        stProdKYC = new Set<String>();
        strFormulaName = '';
        bolEditable = false;
        
        idOpp = ApexPages.currentPage().getParameters().get('id');
        if (idOpp != null) {
            objOpp = [SELECT Id, Name, CloseDate, StageName, Amount, AccountId, Xendit_Price_Book__c,
                      	Type, Parent_Pricing_Approval__c, CurrencyIsoCode, Parent_Opportunity__r.StageName, Segment__c, Account.Is_Reseller__c
                      FROM Opportunity WHERE id = :idOpp];
            
        }
        else {
            strErrorMsg = 'Please provide a valid Opportunity ID';
        }
        
        if (objOpp != null) {
            bolEditable = (objOpp.StageName != 'Closed Won' && objOpp.StageName != 'Closed Lost');
            if (objOpp.Parent_Pricing_Approval__c == 'Submitted' || objOpp.Parent_Pricing_Approval__c == 'Approved') {
                bolEditable = false;
            }
            if (objOpp.Parent_Opportunity__c != null && 
                (objOpp.Parent_Opportunity__r.StageName == 'Integration' || objOpp.Parent_Opportunity__r.StageName == 'Activation' || 
                 	objOpp.Parent_Opportunity__r.StageName == 'Closed Won') 
               ) 
            {
                bolEditable = false;
            }
            
            if (objOpp.Xendit_Price_Book__c == null) {
                showType = SHOW_PB;
            }
            
            for (Xendit_Opportunity_Product__c objXOP : [SELECT Id, Name, Product__c, Channel__c, Opportunity__r.Type 
                                                         FROM Xendit_Opportunity_Product__c WHERE Opportunity__c != :objOpp.Id
                                                        	AND Opportunity__r.AccountId = :objOpp.AccountId
                                                        	AND Opportunity__r.StageName != 'Closed Won' AND Opportunity__r.StageName != 'Closed Lost'])
            {
                /*if (objOpp.Type == 'Winback / Renegotiation') {
                    // only check from another renegotiation
                    if (objXOP.Opportunity__r.Type == 'Winback / Renegotiation') {
                        stProdChannels.add(objXOP.Product__c);
                    }
                }*/ //SFDC Sprint 4 : Winback / Renegotiation can select all products
                //else {
                    stProdChannels.add(objXOP.Product__c);// + '' + objXOP.Channel__c);
                //}
                
            }
            
            //if (objOpp.Type != 'Winback / Renegotiation') { //SFDC Sprint 4 : Winback / Renegotiation can select all products
                for (Channel_KYC__c CK:[SELECT Id, Product__c, Status__c FROM Channel_KYC__c 
                                    WHERE Account__c = :objOpp.AccountId AND Status__c IN ('IN_PROGRESS', 'PASSED', 'LIVE')])
                {
                    //arrKYC.add(CK);
                    stProdKYC.add(CK.Product__c);
                }
            //}
            system.debug('DEBUG: st KYC ' + stProdKYC);
        }
        else {
            strErrorMsg = 'Opportunity data cannot be found. Please provide a valid Opportunity ID';
        }
        
    }
        
    // reload opportunity prod items
    public void reloadOpportunityProducts()
    {
        xOppProductFamilySet = new Set<String>();
        arrOppProductsMap = new Map<String, List<OppProductClass>>();
        //arrOppProducts = new List<OppProductClass>();
        OppProductClass objOP;
        if (objOpp != null && objOpp.Id != null ) {
            for(Xendit_Opportunity_Product__c xOP: [SELECT Id, Name, Opportunity__c , Opportunity__r.Account.Is_Reseller__c, Product__c, Rate_Card__c, Rate_Card__r.Description__c, FX_Rate__c, Basket_Size__c, Brand__c, Event_Count__c,
                                                    Channel__c, CurrencyIsoCode, Manual_Billing__c, Transaction_Count__c, Revenue_Subaccount__c, Number_Subaccount__c, Opportunity_Account_Is_Reseller__c,
                                                    Fixed_Rate_List__c, Fixed_Rate_Sell__c, Rate_per_TPV_from_Pricing_Table__c, Rate_Per_TPV_List__c, Rate_Per_TPV_Sell__c, Revenue_Event__c,
                                                    Rate_per_Txn_from_Pricing_Table__c, Rate_Per_Txn_List__c,Rate_Per_Txn_Sell__c, Revenue_TPV__c, Revenue_Txn__c, TPV__c, Total_Revenue__c,
                                                    Rate_Per_Event_List__c, Rate_Per_Event_Sell__c,Rate_Per_Subaccount_List__c, Rate_Per_Subaccount_Sell__c,
                                                    Product__r.Name, Product__r.ProductCode, Product__r.Family, Special_Notes__c, Billing_Type__c, Billing_Sub_Type__c, Projected_Cost__c, Product_Label__c, Custom_Pricing_Description__c,
                                                    Rate_Card__r.Reseller_Rate_per_TPV__c, Rate_Card__r.Reseller_Rate_Per_Txn__c, Rate_Card__r.Headline_Rate_per_TPV__c, Rate_Card__r.Headline_Rate_per_Txn__c,
                                                    Rate_Card__r.Price_Floor_Rate_per_TPV__c, Rate_Card__r.Price_Floor_Rate_per_Txn__c, Rate_Card__r.Rate_Per_Txn__c, Rate_Card__r.Rate_Per_TPV__C, Rate_Card__r.COGS_Fixed_Fee__c, Rate_Card__r.COGS_MDR__c, Opportunity__r.Owner.Approval_Level__c,
                                                    Rate_Card__r.Selected_Value__c, Rate_Card__r.Selected_Value_Source__c, Rate_Card__r.Basket_Size_Threshold__c, Pricing_Approver_Level__c, Billing_Type_Approver_Level__c, Available_Lowest_Rate_per_TPV__c, Available_Lowest_Rate_per_Txn__c,
                                                    Xendit_Rate_BPS__c,Rate_to_customer_BPS__c,Expected_Monthly_Volume__c, Margin_BPS__c,Rate_Card__r.Brand__c,FX_Product_Approval__c, Product__r.Is_VAS_Product__c, No_of_API_Calls__c, Rate_per_API_Call__c, Tier_Structure__c 
                                                    FROM Xendit_Opportunity_Product__c WHERE Opportunity__c = :idOpp ORDER BY Rate_Card__r.Product__r.Family, Rate_Card__r.Product__r.Name])
            {
                if(xOP.Product__r.Family != null){
                    objOP = new OppProductClass(idOpp);
                    objOP.XP = xOP;
                    objOP.P = xOp.Product__r;
                    
                    //add vas logic
                    if(xOP.Product__r.Is_VAS_Product__c){
                        objOP.productFamilyFormula = RevenueClass.getRevenueFormula('VAS Product');
                        xOppProductFamilySet.add('VAS Product');
                    }
                    else{
                        objOP.productFamilyFormula = RevenueClass.getRevenueFormula(xOP.Product__r.Family);
                        xOppProductFamilySet.add(xOP.Product__r.Family);
                    }
                    
                    if(!String.isBlank(objOP.XP.Rate_Card__r.Selected_Value__c) && !String.isBlank(objOP.XP.Rate_Card__r.Selected_Value_Source__c) && objOP.XP.Rate_Card__r.Basket_Size_Threshold__c != null){ //change to rate card fields
                        objOP.calcSelectionType = objOP.XP.Rate_Card__r.Selected_Value__c;
                        objOP.calcThreshold = objOP.XP.Rate_Card__r.Basket_Size_Threshold__c;
                        Boolean ratePerTxnForHigherVal = (objOP.XP.Rate_Card__r.Selected_Value__c == 'Higher' && objOP.XP.Rate_Card__r.Selected_Value_Source__c == 'Rate per Txn') || (objOP.XP.Rate_Card__r.Selected_Value__c == 'Lower' && objOP.XP.Rate_Card__r.Selected_Value_Source__c == 'Rate per TPV');
                        Boolean ratePerTPVForHigherVal = (objOP.XP.Rate_Card__r.Selected_Value__c == 'Higher' && objOP.XP.Rate_Card__r.Selected_Value_Source__c == 'Rate per TPV') || (objOP.XP.Rate_Card__r.Selected_Value__c == 'Lower' && objOP.XP.Rate_Card__r.Selected_Value_Source__c == 'Rate per Txn');
                        objOP.selectedFieldForHigherThreshold = ratePerTxnForHigherVal ? 'RatePerTxn' : 'MDR';
                        objOP.rateCardAutoCalc = true;
                    }

                    //add vas logic
                    if(xOP.Product__r.Is_VAS_Product__c){
                        if(!arrOppProductsMap.containsKey('VAS Product')){
                            arrOppProductsMap.put('VAS Product', new List<OppProductClass>{objOP});
                        }else{
                            arrOppProductsMap.get('VAS Product').add(objOP);
                        }
                    }
                    else if(!arrOppProductsMap.containsKey(xOP.Product__r.Family)){
                        arrOppProductsMap.put(xOP.Product__r.Family, new List<OppProductClass>{objOP});
                    }else{
                        arrOppProductsMap.get(xOP.Product__r.Family).add(objOP);
                    }

                    if (xOP.Product__c != null) {
                        // stProductOppIds.add(xOP.Product__c);
                        stProductOppIds.add(xOP.Rate_Card__c);
                    }

                    if(String.isBlank(objOP.XP.Product_Label__c)){
                        //set default value
                        objOP.XP.Product_Label__c = objOP.XP.Product__r.Name;
                    }
                    
                }
            }

            if(!arrOppProductsMap.isEmpty()){
                reloadProductFamilyConfig();
            }
        }
    }
    
    public void reloadProductFamilyConfig(){
        prodFamMap = new Map<String, OppProdFamilyClass>();
        if(arrOppProductsMap != null && !arrOppProductsMap.isEmpty()){
            for(String fam : arrOppProductsMap.keySet()){
                System.debug('fam: '+ fam );
                for(OppProductClass arr : arrOppProductsMap.get(fam)){
                    OppProdFamilyClass tempProdFam = new OppProdFamilyClass();
                    tempProdFam.showColSubaccount = getShowColSubaccount(arr.productFamilyFormula);
                    tempProdFam.showColFixedRate = getShowColFixedRate(arr.productFamilyFormula);
                    tempProdFam.showColTPV = getShowColTPV(arr.productFamilyFormula);
                    tempProdFam.showColTPVRate = getShowColTPVRate(arr.productFamilyFormula, arr.XP.CurrencyIsoCode, fam);
                    tempProdFam.showColFXRate = getShowColFXRate(arr.productFamilyFormula);
                    tempProdFam.showColBucket = getShowColBucket(arr.productFamilyFormula);
                    tempProdFam.showColTransCount = getShowColTransCount(arr.productFamilyFormula);
                    tempProdFam.showColTxnRate = getShowColTxnRate(arr.productFamilyFormula);
                    tempProdFam.showColEvent = getShowColEvent(arr.productFamilyFormula);
                    tempProdFam.showProjectedCost = getShowProjectedCost(arr.productFamilyFormula);
                    tempProdFam.showProductLabel = getShowProductLabel(arr.productFamilyFormula);
                    tempProdFam.showEditMonthlyRev = getShowEditMonthlyRev(arr.productFamilyFormula);
                    tempProdFam.showCustomPricingDesc = getShowCustomPricingDesc(arr.productFamilyFormula);
                    tempProdFam.showDescription = getShowDescription(arr.productFamilyFormula);
                    tempProdFam.showVASProduct = getShowVASProduct(arr.productFamilyFormula);
                    tempProdFam.totalOppProduct = arrOppProductsMap.get(fam).size();
                    tempProdFam.allColSubaccount = null;
                    tempProdFam.allRateSubaccount = null;
                    tempProdFam.allColFixedRate = null;
                    tempProdFam.allColTPV = null;
                    tempProdFam.allColTPVRate = null;
                    tempProdFam.allColBucket = null;
                    tempProdFam.allColTxnRate = null;
                    tempProdFam.allColEvent = null;
                    tempProdFam.allColRatePerEvent = null;
                    tempProdFam.showFXProduct = getShowFXProduct(arr.productFamilyFormula);
                    tempProdFam.allColRateToCust = null;
                    // for(Xendit_Opportunity_Product_Calculation__c opc : oppProdCalcList){ //temp - change to rate card fields
                    //     if(arr.XP.Rate_Card__c == opc.Rate_Card__c){
                    //         tempProdFam.hasRateCardCalc = true;
                    //     }
                    // }
                    if((!String.isBlank(arr.XP.Rate_Card__r.Selected_Value__c) && !String.isBlank(arr.XP.Rate_Card__r.Selected_Value_Source__c) && arr.XP.Rate_Card__r.Basket_Size_Threshold__c != null)){ 
                        tempProdFam.hasRateCardCalc = true;
                    }
                    System.debug('check currency:' + arr.XP.CurrencyIsoCode);
                    prodFamMap.put(fam, tempProdFam);
                }
            }
        }
    }
    
    public PageReference showEditPricebook()
    {
        showType = SHOW_PB;
        return null;
    }
    
    // save product family and pricebook
    public PageReference savePricebook()
    {
        clearMesages();
        // assume validation ok
        if (objOpp.Id == null) return null; // skip
        strErrorMsg = ''; // clear
        if (objOpp.Xendit_Price_Book__c == null) return null;
        
        try {
            update(objOpp);
            showType = SHOW_OPP;
        }
        catch(DmlException e) {
            strErrorMsg = e.getMessage();
        }
        catch(Exception e) {
            strErrorMsg = e.getMessage();
        }
        
        reloadOpportunity();
        reloadProductRates();
        getRateCardPricing();
        return null;
    }
    
    // show list of products
    public PageReference showProductList()
    {
        showType = SHOW_PRD;
        return null;
    }
    
    // hide list of product
    public PageReference hideProductList()
    {
        showType = SHOW_OPP;
        clearMesages();
        return null;
    }
    
    // delete selected opportunity products
    public PageReference deleteProducts()
    {
        clearMesages();
        Map<String, List<OppProductClass>> tempList = arrOppProductsMap;
        arrOppProductsMap = new Map<String, List<OppProductClass>>();
        List<Xendit_Opportunity_Product__c> lsDel = new List<Xendit_Opportunity_Product__c>();
        for(String fam : tempList.keySet()){
            for(OppProductClass xO: tempList.get(fam)) {
                if (xO.isSelected) {
                    lsDel.add(xO.XP);
                    if (xO.XP.Product__c != null && stProductOppIds.contains(xO.XP.Product__c)) {
                        stProductOppIds.remove(xO.XP.Product__c);
                    }
                }
                else {
                    if(!arrOppProductsMap.containsKey(fam)){
                        arrOppProductsMap.put(fam, new List<OppProductClass>{xO});
                    }else{  
                        arrOppProductsMap.get(fam).add(xO);
                    }
                    
                }
            }
        }
        try {
            if (lsDel.size() > 0) {
                delete(lsDel);
                reloadOpportunityProducts();
            }
            reloadProductRates();
            reloadOpportunity();
            // update amount
            calculateOpportunityAmount();
            update(objOpp);
        }
        catch(DmlException e) {
            strErrorMsg = e.getMessage();
        }
        catch(Exception e) {
            strErrorMsg = e.getMessage();
        }
        
        return null;
    }
    
    // save existing product items
    public PageReference saveProducts()
    {
        clearMesages();
        try {
            Decimal decTotal = 0.0;
            List<Xendit_Opportunity_Product__c> arrItems = new List<Xendit_Opportunity_Product__c>();
            Integer validOppProd = 0;
            Integer totalOppProd = 0;
            getStdPricingTableValues(arrOppProductsMap);
            for(String fam : arrOppProductsMap.keySet()){
                for (OppProductClass itemP: arrOppProductsMap.get(fam))
                {
                    totalOppProd++;
                    Map<String, String> isValidTemp = itemP.isValid(itemP.productFamilyFormula);
                    system.debug('isValidTemp : ' + JSON.serialize(isValidTemp));
                    if (itemP.isValid(itemP.productFamilyFormula) == null) {
                        validOppProd++;
                        Rate_Card__c rc = new Rate_Card__c(Id = itemP.XP.Rate_Card__c, Selected_Value__c = itemP.XP.Rate_Card__r.Selected_Value__c, Selected_Value_Source__c = itemP.XP.Rate_Card__r.Selected_Value_Source__c, Basket_Size_Threshold__c = itemP.XP.Rate_Card__r.Basket_Size_Threshold__c);
                        itemP.recalculate(itemP.productFamilyFormula, itemP.XP, rc);
                        
                        if(String.isBlank(itemP.XP.Product_Label__c)){
                            itemP.XP.Product_Label__c = itemP.XP.Product__r.Name;
                        }
                        arrItems.add(itemP.XP);
                        decTotal += itemP.getTotalRevenueAmount();
                        
                    }
                }
            }
            if(arrItems.size() > 0 && validOppProd < totalOppProd){
                strErrorMsg = 'Please input the correct values';
            }else if (arrItems.size() > 0 && validOppProd == totalOppProd) {
                clearMesages();
                update(arrItems);
                reloadOpportunity();
                reloadOpportunityProducts();
                calculateOpportunityAmount();
                reloadProductFamilyConfig();
                update(objOpp);
                
                strSuccessMsg = 'Data saved!';
            }
        }
        catch(DmlException e) {
            Set<String> errMsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errMsgList.add(e.getDmlMessage(i)); 
                system.debug('error : ' + e.getDmlMessage(i));
            }
            strErrorMsg = String.join(new List<String>(errMsgList),'\n');
        }
        catch(Exception e) {
            system.debug('error : ' + e.getMessage());
            strErrorMsg = e.getMessage();
        }
        return null;
    }
    
    // calculate amount in Opportunity
    public void calculateOpportunityAmount()
    {
        String strPriceAppv = 'No approval required';
        String strFXProdAppv = 'No approval required';
        Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();  
        Decimal decTotal = 0.0;
        Decimal decTotalTPV = 0.0;
        for(String fam : arrOppProductsMap.keySet()){
            for (OppProductClass itemP: arrOppProductsMap.get(fam))
            {
                decTotal += Utility.valueConversion(conversionRateMap, itemP.getTotalRevenueAmount(), itemP.XP.CurrencyIsoCode, objOpp.CurrencyIsoCode);
                if (itemP.XP.TPV__c != null) {
                    decTotalTPV += Utility.valueConversion(conversionRateMap, itemP.XP.TPV__c, itemP.XP.CurrencyIsoCode, objOpp.CurrencyIsoCode);
                }
                
                if(itemp.checkFXApproval()){
                    strFXProdAppv = 'Approval Required';
                }
                
                // check for pricing change
                if (itemP.checkPricingApproval()) {
                    strPriceAppv = 'Approval Required';
                }
            }
        }
        objOpp.Pricing_Approval__c = strPriceAppv;
        objOpp.FX_Product_Approval__c = strFXProdAppv;
        objOpp.Amount = decTotal;
        objOpp.Estimated_Monthly_Revenue__c = decTotal;
        //objOpp.Estimated_Annual_TPV_Local__c = decTotalTPV;
    }

    
    // add selected product to opportunity products
    public PageReference addProducts()
    {
        clearMesages();
        Xendit_Opportunity_Product__c objXOP;
        List<Xendit_Opportunity_Product__c> lsXOP = new List<Xendit_Opportunity_Product__c>();
        Boolean isProductExist = false;
        Boolean isVASProductExist = false;
        Boolean isDataProductExist = false;
        Integer countVasProduct= 0;
        Set<Id> prodIdSet = new Set<Id>();
        Set<String> exstProdNameSet = new Set<String>();
        try {
            Boolean isReseller = objOpp.Account.Is_Reseller__c;
            for(String fam : productFamilySet){
                for(ProductRateClass P: arrRateMap.get(fam)) {
                    if (P.isSelected) {
                        Boolean isUnsupportedProduct = (P.P.Family != null && P.P.Family.contains('Unsupported Product'));
                        if(P.P.is_vas_product__c ){  //only for datprod -->  product family = data product
                            countVasProduct++;
                            isDataProductExist = (P.P.Family == 'Data Product');
                        }

                        objXOP = new Xendit_Opportunity_Product__c();
                        objXOP.Opportunity__c = idOpp;
                        objXOP.Product__c = P.P.Id;
                        objXOP.Rate_Card__c = P.R.Id;
                        objXOP.CurrencyIsoCode = P.R.CurrencyIsoCode;
                        objXOP.Fixed_Rate_List__c = P.R.Fixed_Rate__c;
                        objXOP.Fixed_Rate_Sell__c = P.R.Fixed_Rate__c;
                        objXOP.Product_Label__c = P.P.Name;

                        //add default Billing Type value
                        objXOP.Billing_Type__c = 'Direct Billing';
                        objXOP.Billing_Sub_Type__c = 'Standard';
    
                        if(isReseller){
                            Boolean resellerHasValue = P.R.Reseller_Rate_per_TPV__c != null || P.R.Reseller_Rate_per_Txn__c != null;
                            Double resellerTempTxn = null;
                            Double resellerTempTPV = null;
                            if(P.R.Rate_Card_Pricings__r != null && P.R.Rate_Card_Pricings__r.size() > 0){
                                Integer rateCardPricingTotal = P.R.Rate_Card_Pricings__r.size();
                                Rate_Card_Pricing__c selectedRateCardPriceObj = P.R.Rate_Card_Pricings__r[rateCardPricingTotal - 1]; //get the last index as the last range
                                resellerTempTxn = selectedRateCardPriceObj.Rate_Per_Txn__c;
                                resellerTempTPV = selectedRateCardPriceObj.Rate_Per_TPV__c;
                            }
                            objXOP.Rate_Per_TPV_List__c = resellerHasValue ? P.R.Reseller_Rate_per_TPV__c : resellerTempTPV;
                            objXOP.Rate_Per_TPV_Sell__c = resellerHasValue ? P.R.Reseller_Rate_per_TPV__c : resellerTempTPV;
                            objXOP.Rate_Per_Txn_List__c = resellerHasValue ? P.R.Reseller_Rate_per_Txn__c : resellerTempTxn;
                            objXOP.Rate_Per_Txn_Sell__c = resellerHasValue ? P.R.Reseller_Rate_per_Txn__c : resellerTempTxn;
                            if(P.P.is_vas_product__c){
                               objXOP.Rate_per_API_Call__c = resellerHasValue ? P.R.Reseller_Rate_per_Txn__c : resellerTempTxn;            //set rate per API All based on rate per txn
                            }
                        }else{
                            Boolean isHeadlinePriceValid = P.R.Headline_Rate_per_TPV__c != null || P.R.Headline_Rate_per_Txn__c != null; //one of the value exist
                            objXOP.Rate_Per_TPV_List__c = isHeadlinePriceValid ? P.R.Headline_Rate_per_TPV__c : P.R.Rate_Per_TPV__c;
                            objXOP.Rate_Per_TPV_Sell__c = isHeadlinePriceValid ? P.R.Headline_Rate_per_TPV__c : P.R.Rate_Per_TPV__c;
                            objXOP.Rate_Per_Txn_List__c = isHeadlinePriceValid ? P.R.Headline_Rate_per_Txn__c : P.R.Rate_Per_Txn__c;
                            objXOP.Rate_Per_Txn_Sell__c = isHeadlinePriceValid ? P.R.Headline_Rate_per_Txn__c : P.R.Rate_Per_Txn__c;
                            if(P.P.is_vas_product__c){
                            	objXOP.Rate_per_API_Call__c = isHeadlinePriceValid ? P.R.Headline_Rate_per_Txn__c : P.R.Rate_Per_Txn__c;     //set rate per API All based on rate per txn
                            }
                        }
                        objXOP.Rate_Per_Event_List__c = P.R.Rate_Per_Event__c;
                        objXOP.Rate_Per_Event_Sell__c = P.R.Rate_Per_Event__c;
                        objXOP.Rate_Per_Subaccount_List__c = P.R.Rate_Per_Subaccount__c;
                        objXOP.Rate_Per_Subaccount_Sell__c = P.R.Rate_Per_Subaccount__c;
                        objXOP.Basket_Size__c = (objOpp.Segment__c == 'Enterprise' && P.P.Basket_Size_Enterprise__c != null) ? P.P.Basket_Size_Enterprise__c : ((objOpp.Segment__c == 'SME' && P.P.Basket_Size_SME__c != null)? P.P.Basket_Size_SME__c : ((objOpp.Segment__c == 'Individual' && P.P.Basket_Size_Individuals__c != null) ? P.P.Basket_Size_Individuals__c : ((objOpp.Segment__c == 'MM' && P.P.Basket_Size_MM__c != null) ? P.P.Basket_Size_MM__c : null))); //for default Basket Size
                        
                        if (P.R.Brand__c != null) {
                            objXOP.Brand__c = P.R.Brand__c;
                        }
                        if (P.R.Channel__c != null) {
                            objXOP.Channel__c = P.R.Channel__c;
                        }
    
                        if(arrOppProductsMap != null && !arrOppProductsMap.isEmpty()){
                            for(String fam2 : arrOppProductsMap.keySet()){
                                for(OppProductClass opc : arrOppProductsMap.get(fam2)){
                                    //add new condition for VAS Product
                                    if((opc.p.Is_VAS_Product__c != P.P.Is_VAS_Product__c  && (opc.p.Name.contains('Data Product') || P.P.Name.contains('Data Product')))){ //only for data product
                                        isVASProductExist = true;
                                        break;
                                    }
                                    else if(opc.XP.Product__c == objXOP.Product__c && fam2 != null && !fam2.contains('Unsupported Product')){
                                        isProductExist = true;
                                        exstProdNameSet.add(opc.XP.Product__r.Name);
                                        break;
                                    }
                                }
                            }
                        }
                        if(prodIdSet != null && !prodIdSet.isEmpty() && prodIdSet.contains(objXOP.Product__c) && !isUnsupportedProduct){
                            isProductExist = true;
                            exstProdNameSet.add(P.R.Product__r.Name);
                        }

                        prodIdSet.add(objXOP.Product__c);
                        
                        //add new condition for VAS Product
                        if(countVasProduct != prodIdSet.size() && countVasProduct != 0 && isDataProductExist == true){
                            isVASProductExist = true;
                        }

                        if((!isProductExist || isReseller) && !isVASProductExist){
                            lsXOP.add(objXOP);
                        }
                    }
                }
            }

            if(isVASProductExist){
                strErrorMsg = 'You cannot mix PG and VAS product in the same child opportunity. Please create a new child opportunity for the PG or VAS product - Data Product separately.';
                reloadOpportunity();
                reloadOpportunityProducts();
                reloadProductRates();
            }
            else if(isProductExist && !isReseller){
                String exstProdNameStr = String.join(new List<String>(exstProdNameSet),' , ');
                strErrorMsg = 'You are not allowed to select multiple rate cards from the same product : ' + exstProdNameStr;
            }
            else if (lsXOP.size() > 0) {
                clearMesages();
                insert(lsXOP);
                
                // reload
                reloadOpportunity();
                reloadOpportunityProducts();
                reloadProductRates();
                getLowestAvailableValues(arrOppProductsMap);

                showType = SHOW_OPP;
            }else{
                clearMesages();
                showType = SHOW_OPP;
            }
            
        }
        catch(DmlException e) {
            //strErrorMsg = e.getMessage();
            Set<String> errMsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errMsgList.add(e.getDmlMessage(i)); 
            }
            strErrorMsg = String.join(new List<String>(errMsgList),'\n');
        }
        catch(Exception e) {
            strErrorMsg = e.getMessage();
        }
            
        return null;
    }
    
    // search product
    public PageReference search()
    {
        reloadProductRates();
        return null;
    }
    
    public String getOppAmount()
    {
        Decimal dec = (objOpp.Amount == null) ? 0.0 : objOpp.Amount;
        return dec.setScale(2).format();
    }
    
    // show total Opp Product
    public Integer getOppProductCount()
    {
        Integer count = 0;
        if(arrOppProductsMap != null && !arrOppProductsMap.isEmpty()){
            for(String fam : arrOppProductsMap.keySet()){
                count += arrOppProductsMap.get(fam).size();
            }
        }
        return count;
    }
    
    // back to opportunity
    public PageReference back()
    {
        return new PageReference('/' + idOpp);
    }
    
    // check if parent is locked and return error message, blank if no error
    public String getIsParentLocked()
    {
        String str = '';
        if (objOpp.Parent_Pricing_Approval__c == 'Submitted') {
            str = 'Parent Opportunity is being submitted for Pricing Approval. You are not allowed to update the pricing anymore.';
        }
        else if (objOpp.Parent_Pricing_Approval__c == 'Approved') {
            str = 'Parent Opportunity has been approved for Pricing Approval. You are not allowed to update the pricing anymore.';
        }
        
        if (objOpp.Parent_Opportunity__r.StageName == 'Activation' || 
           	objOpp.Parent_Opportunity__r.StageName == 'Integration' || 
           	objOpp.Parent_Opportunity__r.StageName == 'Closed Won') 
        {
            str = 'The Parent Opportunity is in ' + objOpp.Parent_Opportunity__r.StageName + ' Stage. You are not allowed to update the pricing anymore.';
        }
        return str;
    }

    // code to show PB (pricebook options)
    public Integer getShowPB()
    {
        return SHOW_PB;
    }
    // show products search
    public Integer getShowPRD()
    {
        return SHOW_PRD;
    }
    // show opprotunity details
    public Integer getShowOPP()
    {
        return SHOW_OPP;
    }
    // show help text all
    public String getAllHelptext()
    {
        String str = '';
        Boolean isVAS = false;
        Boolean isNonVAS = false;
        for(String fam2 : xOppProductFamilySet){
            if (fam2.contains('VAS Product')) {
                isVAS = true;
            } else {
                isNonVAS = true;
            }
        }
        if(!xOppProductFamilySet.isEmpty()){
            str += '<p><b>Transaction Count</b> = Estimated Monthly Channel Potential TPV / Avg TPV per Txn</p>';
            if(isNonVAS){
                str += '<p><b>Estimated Monthly Revenue</b> = (Transaction Count x Rate per Txn) + (Estimated Monthly Channel Potential TPV x Merchant Discount Rate (%))</p>';
            }
            if(isVAS){
                str += '<p><b>Estimated Monthly Revenue VAS Product</b> = (No of API Calls x Rate per API Call)</p>';
            }
        }
        return str;
    }
    
    // LAYOUT SETTINGS RELATED
    public Boolean getShowColTPV(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA1 || 
           	strFormulaName == RevenueClass.FORMULA2 || 
           	strFormulaName == RevenueClass.FORMULA3 || 
           	strFormulaName == RevenueClass.FORMULA4 || 
           	strFormulaName == RevenueClass.FORMULA5 ||
            strFormulaName == RevenueClass.FORMULA7 ||
            strFormulaName == RevenueClass.FORMULA8) 
        {
            return true;
        }
        else {
            return false;
        }
        
    }
    public Boolean getShowColTransCount(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA1 || 
           	strFormulaName == RevenueClass.FORMULA2 || 
           	strFormulaName == RevenueClass.FORMULA3 || 
           	strFormulaName == RevenueClass.FORMULA4 || 
           	strFormulaName == RevenueClass.FORMULA5 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColBucket(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA1 || 
            strFormulaName == RevenueClass.FORMULA2 || 
           	strFormulaName == RevenueClass.FORMULA3 || 
           	strFormulaName == RevenueClass.FORMULA4 || 
           	strFormulaName == RevenueClass.FORMULA5 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColTxnCount()
    {
        if (strFormulaName == RevenueClass.FORMULA1 || 
           	strFormulaName == RevenueClass.FORMULA3 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColRevenueTPV()
    {
        if (strFormulaName == RevenueClass.FORMULA3 || 
           	strFormulaName == RevenueClass.FORMULA5 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColRevenueTxn()
    {
        if (strFormulaName == RevenueClass.FORMULA3 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColFXRate(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA4 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColTPVRate(String strFormulaName,String CurrencyIso, String prodFam)
    {
        if (strFormulaName == RevenueClass.FORMULA2 || 
           	strFormulaName == RevenueClass.FORMULA3 || 
           	strFormulaName == RevenueClass.FORMULA4 || 
           	strFormulaName == RevenueClass.FORMULA5 ||
            strFormulaName == RevenueClass.FORMULA7 || (strFormulaName == RevenueClass.FORMULA1 && CurrencyIso == 'PHP' && prodFam == 'Over the Counter (OTC)'))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public Boolean getShowColTxnRate(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA1 || 
           	strFormulaName == RevenueClass.FORMULA3 ||
            strFormulaName == RevenueClass.FORMULA7) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColFixedRate(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA5 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowColEvent(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA6 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowProjectedCost(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA7 ||
            strFormulaName == RevenueClass.FORMULA8 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowProductLabel(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA7 ||
            strFormulaName == RevenueClass.FORMULA8 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowEditMonthlyRev(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA8 ) {
            return true;
        }
        else {
            return false;
        }
    }
    public Boolean getShowCustomPricingDesc(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA8 ) {
            return true;
        }
        else {
            return false;
        }
    }
    
    public Boolean getShowFXProduct(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA9 ) {
            return true;
        }
        else {
            return false;
        }
    }
    
    public Boolean getShowDescription(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA7  ||
            strFormulaName == RevenueClass.FORMULA8) {
            return false;
        }
        else {
            return true;
        }
    }
    public Boolean getShowColSubaccount(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA5 ) {
            return true;
        }
        else {
            return false;
        }
    }

    public Boolean getShowVASProduct(String strFormulaName)
    {
        if (strFormulaName == RevenueClass.FORMULA10 ) {
            return true;
        }
        else {
            return false;
        }
    }
    
    public void getUserIsEditable(){
        //add exception for admin user to edit data
        User currUser = [SELECT Id, Bypass_VR__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(currUser.Profile.Name == 'System Administrator' && currUser.Bypass_VR__c) bolEditable = true;
    }

    public void getStdPricingTableValues(Map<String,List<OppProductClass>> oppProducClsMap){
        if(oppProducClsMap != null && !oppProducClsMap.isEmpty()){
            for(String fam : oppProducClsMap.keySet()){
                List<OppProductClass> oppProducClsList = oppProducClsMap.get(fam);
                if(oppProducClsList != null && !oppProducClsList.isEmpty()){
                    Map<Id, List<Rate_Card_Pricing__c>> rateCardPricingMap = getRateCardPricingMap(oppProducClsList);
                    Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();  
        
                    for (OppProductClass itemP: oppProducClsList)
                    {
                        if(rateCardPricingMap.containsKey(itemP.XP.Rate_Card__c)){
                            //populate rate card pricing default value and pricing approval level
                            List<Rate_Card_Pricing__c> getRateCardPriceList = rateCardPricingMap.get(itemP.XP.Rate_Card__c);
                            Rate_Card__c rc = new Rate_Card__c(Id = itemP.XP.Rate_Card__c, Selected_Value__c = itemP.XP.Rate_Card__r.Selected_Value__c, Selected_Value_Source__c = itemP.XP.Rate_Card__r.Selected_Value_Source__c, Basket_Size_Threshold__c = itemP.XP.Rate_Card__r.Basket_Size_Threshold__c, 
                                                               Price_Floor_Rate_per_TPV__c = itemP.XP.Rate_Card__r.Price_Floor_Rate_per_TPV__c, Price_Floor_Rate_per_Txn__c = itemP.XP.Rate_Card__r.Price_Floor_Rate_per_Txn__c, Headline_Rate_per_TPV__c = itemP.XP.Rate_Card__r.Headline_Rate_per_TPV__c,
                                                               Headline_Rate_per_Txn__c = itemP.XP.Rate_Card__r.Headline_Rate_per_Txn__c, Reseller_Rate_per_Txn__c = itemP.XP.Rate_Card__r.Reseller_Rate_per_Txn__c, Product__c = itemP.P.Id);
                            Integer ownerApprLevel = itemP.XP.Opportunity__r.Owner.Approval_Level__c != null ? Integer.valueOf(itemP.XP.Opportunity__r.Owner.Approval_Level__c) : 0;
                            itemP.getStdPricingTableVal(getRateCardPriceList, conversionRateMap, itemP.XP, rc, ownerApprLevel);
                        }
                    }
                }
                oppProducClsMap.put(fam, oppProducClsList);
            }
        }
    }

    public void getLowestAvailableValues(Map<String, List<OppProductClass>> oppProductClsMap){
        if(oppProductClsMap != null && !oppProductClsMap.isEmpty()){
            for(String key : oppProductClsMap.keySet()){
                List<OppProductClass> oppProducClsList = oppProductClsMap.get(key);
                if(oppProducClsList != null && !oppProducClsList.isEmpty()){
                    Map<Id, List<Rate_Card_Pricing__c>> rateCardPricingMap = getRateCardPricingMap(oppProducClsList);
                    for (OppProductClass itemP: oppProducClsList)
                    {
                        Boolean resellerHasValue = itemP.XP.Rate_Card__r.Reseller_Rate_per_TPV__c != null || itemP.XP.Rate_Card__r.Reseller_Rate_per_Txn__c != null;
                        Boolean priceFloorHasValue = itemP.XP.Rate_Card__r.Price_Floor_Rate_per_TPV__c != null || itemP.XP.Rate_Card__r.Price_Floor_Rate_per_Txn__c != null;
                        Integer ownerApprLevel = itemP.XP.Opportunity__r.Owner.Approval_Level__c != null ? Integer.valueOf(itemP.XP.Opportunity__r.Owner.Approval_Level__c) : 0;
                        Integer highestApprLevel = 3; //determine the highest approval level for price floor
                        
                        if(ownerApprLevel == highestApprLevel && priceFloorHasValue){
                            //get price floor pricing
                            itemP.availableLowestRatePerTPV = itemP.XP.Rate_Card__r.Price_Floor_Rate_per_TPV__c != null ? itemP.XP.Rate_Card__r.Price_Floor_Rate_per_TPV__c / 100 : null;
                            itemP.availableLowestRatePerTxn = itemP.XP.Rate_Card__r.Price_Floor_Rate_per_Txn__c != null ? itemP.XP.Rate_Card__r.Price_Floor_Rate_per_Txn__c : null;
                        }else if(itemP.XP.Opportunity__r.Account.Is_Reseller__c && resellerHasValue){
                            //select reseller value
                            itemP.availableLowestRatePerTPV = itemP.XP.Rate_Card__r.Reseller_Rate_per_TPV__c != null ? itemP.XP.Rate_Card__r.Reseller_Rate_per_TPV__c / 100 : null;
                            itemP.availableLowestRatePerTxn = itemP.XP.Rate_Card__r.Reseller_Rate_per_Txn__c != null ? itemP.XP.Rate_Card__r.Reseller_Rate_per_Txn__c : null;
        
                        }else if(rateCardPricingMap.containsKey(itemP.XP.Rate_Card__c) && (itemP.XP.Opportunity__r.Account.Is_Reseller__c || ownerApprLevel != 0)){
                            //populate rate card pricing default value and pricing approval level
                            List<Rate_Card_Pricing__c> getRateCardPriceList = rateCardPricingMap.get(itemP.XP.Rate_Card__c);
        
                            for(Rate_Card_Pricing__c rcp : getRateCardPriceList){
                                //for reseller : get last range; else : get latest range with the same owner approval level
                                if(itemP.XP.Opportunity__r.Account.Is_Reseller__c || (ownerApprLevel == rcp.Rate_Card_Pricing_Range__r.Approval_Level__c)){
                                    itemP.availableLowestRatePerTPV = rcp.Rate_Per_TPV__c != null ? rcp.Rate_Per_TPV__c / 100 : null;
                                    itemP.availableLowestRatePerTxn = rcp.Rate_Per_Txn__c != null ? rcp.Rate_Per_Txn__c : null;
                                }
                            }
                        }else{
                            //get headline pricing
                            Boolean headlineHasValue = itemP.XP.Rate_Card__r.Headline_Rate_per_TPV__c != null || itemP.XP.Rate_Card__r.Headline_Rate_per_Txn__c != null;
                            Double availableLowestRatePerTPV = headlineHasValue ? itemP.XP.Rate_Card__r.Headline_Rate_per_TPV__c : itemP.XP.Rate_Card__r.Rate_per_TPV__c;
                            itemP.availableLowestRatePerTPV = availableLowestRatePerTPV != null ? availableLowestRatePerTPV / 100 : null;
                            itemP.availableLowestRatePerTxn = headlineHasValue ? itemP.XP.Rate_Card__r.Headline_Rate_per_Txn__c : itemP.XP.Rate_Card__r.Rate_per_Txn__c;
                        }
                    }
                    oppProductClsMap.put(key,oppProducClsList);
                }
            }
        }
    }

    public Map<Id, List<Rate_Card_Pricing__c>> getRateCardPricingMap(List<OppProductClass> oppProducClsList){   
        Map<Id, List<Rate_Card_Pricing__c>> rateCardPricingMap = new Map<Id, List<Rate_Card_Pricing__c>>();

        //loop Xendit Opp Product to get all rate card Ids
        Set<Id> rateCardSet = new Set<Id>();
        for(OppProductClass itemP : oppProducClsList){
            Id rateCardId = itemP.XP.Rate_Card__c;
            if(rateCardId != null){
                rateCardSet.add(rateCardId);
            }
        }

        for(Rate_Card_Pricing__c rcPrice : rateCardList){
            //map rate card with related rate card pricing
            if(!rateCardPricingMap.containsKey(rcPrice.Rate_Card__c)){
                rateCardPricingMap.put(rcPrice.Rate_Card__c, new List<Rate_Card_Pricing__c>{rcPrice});
            }else{
                rateCardPricingMap.get(rcPrice.Rate_Card__c).add(rcPrice);
            }
        }
        return rateCardPricingMap;
    }

    public List<Rate_Card_Pricing__c> getRateCardPricing(){
        rateCardList = new List<Rate_Card_Pricing__c>();
        rateCardList = [SELECT Id, Rate_Per_Txn__c, Rate_Per_TPV__c, Rate_Card__c, Rate_Card_Pricing_Range__c, Rate_Card__r.Reseller_Rate_per_Txn__c, 
                                                    Rate_Card_Pricing_Range__r.Pricing_Range_Type__c, Rate_Card_Pricing_Range__r.Range_Order__c, Rate_Card_Pricing_Range__r.Lower_Threshold__c, 
                                                    Rate_Card_Pricing_Range__r.Upper_Threshold__c, Rate_Card_Pricing_Range__r.Approval_Level__c,
                                                    Rate_Card__r.Selected_Value_Source__c, Rate_Card__r.Selected_Value__c, Rate_Card__r.Basket_Size_Threshold__c
                                                    FROM Rate_Card_Pricing__c WHERE Rate_Card_Pricing_Range__c != null ORDER BY Rate_Card__c, Rate_Card_Pricing_Range__r.Range_Order__c];
        
        return rateCardList;
    }
    
}