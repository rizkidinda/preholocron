/*
Type Name       : OppProductEmailTemplateClass
Author          : Xendit
Created Date    : 3/17/2023
Description     : Class for opportunity product wrapper in approval email template
Change History  :
3/17/2023       GDevita     Created
*/
public class OppProductEmailTemplateClass
{
    public String channelName {get;set;}
    public Double offeredMDR {get;set;}
    public Double availableLowestMDR {get;set;}
    public Double thresholdMDR {get;set;}
    public Double cogsMDR {get;set;}
    public Double offeredRatePerTxn {get;set;}
    public Double availableLowestRatePerTxn {get;set;}
    public Double thresholdRatePerTxn {get;set;}
    public Double cogsRatePerTxn {get;set;}
    public Double projectedCost {get;set;}
    public String withDiscount {get;set;}
    public String belowCOGS {get;set;}
    public String billingType {get;set;}
    public String currencyIsoCode {get;set;}
    public Double totalRevenue {get;set;}
    public String cogsCombineStr {get;set;}
    public Double headlineTotalRevenue {get;set;}
    public Boolean isUnsupportedProduct {get;set;}
    public String productFamily {get;set;}
    
    public OppProductEmailTemplateClass() {
        channelName = '';
        offeredMDR = 0;
        availableLowestMDR = 0;
        thresholdMDR = 0;
        offeredRatePerTxn = 0;
        availableLowestRatePerTxn = 0;
        thresholdRatePerTxn = 0;
        projectedCost = 0;
        withDiscount = 'No';
        belowCOGS = 'No';
        billingType = '';
        currencyIsoCode = '';
        totalRevenue = 0;
        cogsCombineStr = '';
        headlineTotalRevenue = 0;
        isUnsupportedProduct = false;
        productFamily = '';
    }
}