/**
 * @description       : 
 * @group             : 
 * @last modified on  : 22-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public class Utility {
    // public get picklist options in map (string, string)
    public static Map<String, String> getMapPicklist(String strObject, String strField) {
        Map<String, String> options = new Map<String, String>();
        
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(strObject).getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = field_map.get(strField).getDescribe().getPickListValues();       
        for (Schema.PicklistEntry pv : picklistValues) {
            // options.add(new SelectOption(pv.getValue(),pv.getLabel()));  
            options.put(pv.getValue(), pv.getLabel());
        }

        return options;
    }
    
    // public get picklist options
    public static List<SelectOption> getFieldOptions(String strObject, String strField, Boolean addBlank) {
        List<SelectOption> options = new List<SelectOption>();
        if (addBlank) {
            options.add(new SelectOption('', ''));
        }
        
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(strObject).getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = field_map.get(strField).getDescribe().getPickListValues();       
        for (Schema.PicklistEntry pv : picklistValues) {
            options.add(new SelectOption(pv.getValue(),pv.getLabel()));  
        }

        return options;
    }
    
    // function to get prefix of an object
    public static String getObjectPrefix(String strObjectName)
    {
        Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
        system.debug('==>m is==>'+m);
        Schema.SObjectType s = m.get(strObjectName) ;
        system.debug('==>Sobject Type is ==>'+s);
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        String str = r.getKeyPrefix();
        return str;
    }

    public static Decimal valueConversion(Map<String, Decimal> conversionRateMap, Decimal value, String oriCurrency, String convCurrency){
        if(value != null && conversionRateMap.containsKey(oriCurrency) && conversionRateMap.containsKey(convCurrency)){
            Decimal rateUSD = conversionRateMap.get('USD');
            Decimal rateOri = conversionRateMap.get(oriCurrency);
            Decimal rateConvert = conversionRateMap.get(convCurrency);
            Decimal result = ((rateUSD / rateOri) * value) * rateConvert;
            return result;
        }else{
            return value == null ? 0 : value;
        }
    }

    public static Set<String> adminProfilesSet(){
        return new Set<String>{'System Administrator','Xendit API Profile','Xendit Sales Ops Profile'};
    }
    
    @InvocableMethod(label='String to List by Comma')
    public static List<List<String>> convertStringtoListbyComma(List<List<String>> str){
        List<String> returnVal = str[0][0].split(',');
        List<List<String>> returnValList = new List<List<String>>();
        System.debug('returnVal : ' + JSON.serialize(returnVal));
        returnValList.add(returnVal);
        return returnValList;
    }
    
    public static Map<Id, List<Campaign>> filterCampaignByRecordTypeId(List<Campaign> listSObjects) {
        Map<Id, List<Campaign>> mapCampaignsByRecordTypeId = new Map<Id, List<Campaign>>();
        for (Campaign cmp : listSObjects) {
            if(mapCampaignsByRecordTypeId.containsKey(cmp.RecordTypeId)) {
                List<Campaign> tempCampaign = mapCampaignsByRecordTypeId.get(cmp.RecordTypeId);
                tempCampaign.add(cmp);
                mapCampaignsByRecordTypeId.put(cmp.RecordTypeId, tempCampaign);
            } else {
                mapCampaignsByRecordTypeId.put(cmp.RecordTypeId, new List<Campaign> { cmp });
            } 
        }
        return mapCampaignsByRecordTypeId;
    }
}