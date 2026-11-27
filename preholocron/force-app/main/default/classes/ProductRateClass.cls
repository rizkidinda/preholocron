/** to support OppItemController */
public class ProductRateClass {
    
    public Product2 P {get;set;}
    public Rate_Card__c R {get;set;}
    public Boolean isSelected {get;set;} 
    public Boolean isDisabled {get;set;}
    public String Notes {get;set;}
    public ProductRateClass()
    {
        P = new Product2();
        R = new Rate_Card__c();
        isSelected = false;
        isDisabled = false;
        Notes = '';
    }
}