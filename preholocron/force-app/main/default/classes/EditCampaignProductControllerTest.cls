@isTest
private class EditCampaignProductControllerTest {
    //create test data
    @TestSetup
    static void createTestData(){
        List<Product2> insertProductList = new List<Product2>();
        List<Campaign_Product__c> insertCampaignProductList = new List<Campaign_Product__c>();

        Product2 p1 = new Product2();
        p1.Name = 'Test Prod1';
        p1.ProductCode ='TESTP1';
        p1.CurrencyIsoCode = 'IDR';
        p1.Family = 'eWallets';
        p1.IsActive = true;
        insertProductList.add(p1);
        
        Product2 p2 = new Product2();
        p2.Name = 'Test Prod2';
        p2.ProductCode ='TESTP2';
        p2.CurrencyIsoCode = 'IDR';
        p2.Family = 'Escrow';
        p2.IsActive = true;
        insertProductList.add(p2);
        
        Product2 p3 = new Product2();
        p3.Name = 'Test Prod3';
        p3.ProductCode ='TESTP3';
        p3.CurrencyIsoCode = 'IDR';
        p3.Family = 'Iluma Products';
        p3.IsActive = true;
        insertProductList.add(p3);

        insert insertProductList;

        Campaign c1 = new Campaign();
        c1.Name = 'Test Campaign 1';
        insert c1;

        Campaign_Product__c cp1 = new Campaign_Product__c();
        cp1.Campaign__c = c1.Id;
        cp1.Product__c = p1.Id;
        insertCampaignProductList.add(cp1);

        Campaign_Product__c cp2 = new Campaign_Product__c();
        cp2.Campaign__c = c1.Id;
        cp2.Product__c = p2.Id;
        insertCampaignProductList.add(cp2);
        insert insertCampaignProductList;
    }


    @isTest
    static void controllerTest(){
        Campaign getCampaign = [SELECT Id FROM Campaign LIMIT 1];
        String result = EditCampaignProductController.setupData(getCampaign.Id);

        List<String> productIds = new List<String>();
        List<Product2> getProducts = [SELECT Id, Name, Family FROM Product2];
        for(Product2 product : getProducts){
            if(product.Family != 'eWallets'){
                productIds.add(product.Id);
            }
        }

        String saveResult = EditCampaignProductController.saveData(JSON.serialize(productIds), getCampaign.Id);
        system.assertEquals('success', saveResult, 'saveResult is failed!');
    }
}