public class EditCampaignProductController {
    @AuraEnabled
    public static string setupData(Id campaignId){
        try {
            Map<String, List<Product2>> prdFamMap = new Map<String, List<Product2>>();
            Map<String, List<Id>> prdCampignMap = new Map<String, List<Id>>();
            List<prodFamilyWrapper> prodFamWrapper = new List<prodFamilyWrapper>();
            for(Product2 prd : [SELECT Id, Name, Family, Product_Code_Batch_Data__c FROM Product2 WHERE Family != NULL AND IsActive = TRUE ORDER BY Family, Name]){
                if(!prdFamMap.containsKey(prd.Family)){
                    prdFamMap.put(prd.Family, new List<Product2>{prd});
                }else{
                    prdFamMap.get(prd.Family).add(prd);
                }
            }

            for(Campaign_Product__c cp : [SELECT Id, Product__c FROM Campaign_Product__c WHERE Campaign__c =: campaignId]){
                if(!prdCampignMap.containsKey(cp.Product__c)){
                    prdCampignMap.put(cp.Product__c, new List<Id>{cp.Id});
                }else{
                    prdCampignMap.get(cp.Product__c).add(cp.Id);
                }
            }

            for(String prodFamStr : prdFamMap.keySet()){
                prodFamilyWrapper tempPFWrapper = new prodFamilyWrapper();
                tempPFWrapper.prodFamily = prodFamStr;
                List<productWrapper> tempPWrapperList = new List<productWrapper>();
                List<String> selectedIds = new List<String>();
                for(Product2 prd : prdFamMap.get(prodFamStr)){
                    productWrapper tempWrapper = new productWrapper();
                    tempWrapper.Id = prd.Id;
                    tempWrapper.prdFamily = prd.Family;
                    tempWrapper.prdName = prd.Name;
                    tempWrapper.prdCode = prd.Product_Code_Batch_Data__c;
                    tempWrapper.isSelected = !prdCampignMap.isEmpty() && prdCampignMap.containsKey(prd.Id);
                    if(tempWrapper.isSelected){
                        selectedIds.add(tempWrapper.Id);
                    }
                    tempWrapper.campaignProdIds = !prdCampignMap.isEmpty() && prdCampignMap.containsKey(prd.Id) ? prdCampignMap.get(prd.Id) : new List<Id>();
                    tempPWrapperList.add(tempWrapper);
                }
                tempPFWrapper.productList = tempPWrapperList;
                tempPFWrapper.selectedIds = selectedIds;
                prodFamWrapper.add(tempPFWrapper);
            }
            
            return JSON.serialize(prodFamWrapper);
        } catch (Exception e) {
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }

    @AuraEnabled
    public static string saveData(String productIdStr, Id campaignId){
        try {
            system.debug('productIdStr : ' + productIdStr);
            List<String> productIds = new List<String>();
            Object[] productIdVals = (Object[]) JSON.deserializeUntyped(productIdStr);
            if(productIdVals.size() > 0){       
                for (Object prdId : productIdVals) {
                    productIds.add(String.valueof(prdId) );
                }
            }
            system.debug('productIds : ' + JSON.serialize(productIds));
            String returnVal = 'success'; //tbc
            List<Campaign_Product__c> delCampProdList = new List<Campaign_Product__c>();
            List<Campaign_Product__c> insertCampProdList = new List<Campaign_Product__c>();
            List<String> exstProdList = new List<String>();
            for(Campaign_Product__c cp : [SELECT Id, Product__c FROM Campaign_Product__c WHERE Campaign__c =: campaignId]){
                if(productIds == null || productIds.size() == 0 || (productIds.size() > 0 && !productIds.contains(cp.Product__c))){
                    delCampProdList.add(new Campaign_Product__c(Id = cp.Id));
                }else if(productIds != null && productIds.size() > 0 && productIds.contains(cp.Product__c)){
                    exstProdList.add(cp.Product__c);
                }
            }
            if(!exstProdList.isEmpty()){
                for (Integer i = (productIds.size()-1) ; i>= 0 ; i--){
                    String p = productIds[i];
                    if(exstProdList.contains(p)){
                        productIds.remove(i);
                    }
                } 
            }

            if(productIds != null && !productIds.isEmpty()){
                for(String xp : productIds){
                    insertCampProdList.add(new Campaign_Product__c(Campaign__c = campaignId, Product__c = xp));
                }
                insert insertCampProdList;
            }

            if(!delCampProdList.isEmpty()){
                delete delCampProdList;
            }
            
            return returnVal;
        } catch (Exception e) {
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }

    public class prodFamilyWrapper

    {
        @AuraEnabled public String prodFamily {get;set;}
        @AuraEnabled public List<productWrapper> productList {get;set;}
        @AuraEnabled public List<String> selectedIds {get;set;}
        public prodFamilyWrapper() {
            prodFamily = '';
            productList = new List<productWrapper>();
            selectedIds = new List<String>();
        }
    }

    public class productWrapper
    {
        @AuraEnabled public String Id {get;set;} 
        @AuraEnabled public String prdFamily {get;set;} 
        @AuraEnabled public String prdName {get;set;}
        @AuraEnabled public String prdCode {get;set;}
        @AuraEnabled public List<Id> campaignProdIds {get;set;}
        @AuraEnabled public Boolean isSelected {get;set;}
        public productWrapper(){
            Id = '';
            prdFamily = '';
            prdName = '';
            prdCode = '';
            campaignProdIds = new List<Id>();
            isSelected = false;
        }
    }
}