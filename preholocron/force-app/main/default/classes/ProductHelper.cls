public class ProductHelper {
    public static void updateChannelKYC(List<Product2> listNew, Map<Id, Product2> listOldMap){
        try{
            Set<Id> updateProductIdSet = new Set<Id>();
            for(Product2 prd : listNew){
                Product2 oldPrd = listOldMap.get(prd.Id);
                if(prd.Family != oldPrd.Family){
                    updateProductIdSet.add(prd.Id);
                }
            }

            if(!updateProductIdSet.isEmpty()){
                Database.executeBatch( new ChannelProductUpdateBatch(updateProductIdSet) ); 
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('ProductHelper','Product2', 'updateChannelKYC', 'ProductTrigger',  e);
        }
    }
}