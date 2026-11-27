/** to support OppItemController */
public class OppProdFamilyClass {
    public Integer totalOppProduct {get;set;}
    public Boolean showColSubaccount {get;set;}
    public Boolean showColFixedRate {get;set;}
    public Boolean showColTPV {get;set;}
    public Boolean showColTPVRate {get;set;}
    public Boolean showColFXRate {get;set;}
    public Boolean showColBucket {get;set;}
    public Boolean showColTransCount {get;set;}
    public Boolean showColTxnRate {get;set;}
    public Boolean showColEvent {get;set;}
    public Boolean showProjectedCost {get;set;}
    public Boolean showProductLabel {get;set;}
    public Boolean showEditMonthlyRev {get;set;}
    public Boolean showCustomPricingDesc {get;set;}
    public Boolean showDescription {get;set;}
    public Boolean hasRateCardCalc {get;set;}
    public Decimal allColSubaccount {get;set;}
    public Decimal allRateSubaccount {get;set;}
    public Decimal allColFixedRate {get;set;}
    public Decimal allColTPV {get;set;}
    public Decimal allColTPVRate {get;set;}
    public Decimal allColBucket {get;set;}
    public Decimal allColTxnRate {get;set;}
    public Decimal allColEvent {get;set;}
    public Decimal allColRatePerEvent {get;set;}
    public Xendit_Opportunity_Product__c applyAllVal {get;set;}
    public Boolean showFXProduct {get;set;}
    public Decimal allColRateToCust {get;set;}
    public Boolean showVASProduct {get;set;}

    
    public OppProdFamilyClass() {
        totalOppProduct = 0;
        showColSubaccount = false;
        showColFixedRate = false;
        showColTPV = false;
        showColTPVRate = false;
        showColFXRate = false;
        showColBucket = false;
        showColTransCount = false;
        showColTxnRate = false;
        showColEvent = false;
        showProjectedCost = false;
        showProductLabel = false;
        showEditMonthlyRev = false;
        showCustomPricingDesc = false;
        showDescription = false;
        hasRateCardCalc = false;
        allColSubaccount = null;
        allRateSubaccount = null;
        allColFixedRate = null;
        allColTPV = null;
        allColTPVRate = null;
        allColBucket = null;
        allColTxnRate = null;
        allColRatePerEvent = null;
        showFXProduct = false;
        allColRateToCust = null;
        showVASProduct = false;
        applyAllVal = new Xendit_Opportunity_Product__c();
    }
}