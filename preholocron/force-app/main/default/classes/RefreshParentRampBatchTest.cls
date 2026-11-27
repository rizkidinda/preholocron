@isTest()
public class RefreshParentRampBatchTest {
	static testmethod void createOpp()
    {
        List<Opportunity> insertParentOppList = new List<Opportunity>();
        List<Opportunity> insertChildOppList = new List<Opportunity>();
        List<Xendit_Opportunity_Product__c> insertProductList = new List<Xendit_Opportunity_Product__c>();
        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        acc.Customer_Folder_URL__c = 'test.com';
        insert acc;
        
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c= Date.newInstance(2023, 7, 15);
        opp.CloseDate=Date.newInstance(2023, 7, 15);
        opp.StageName='Qualification';
        insert opp;
        
        //ramps are created for parent
        list<Opportunity_Ramp__c> parentRamp=[select id from Opportunity_Ramp__c where Opportunity__c=:opp.id];
        system.debug('parentRamp size : ' + parentRamp.size());
        system.assertEquals(6, parentRamp.size());

        test.startTest();
        opp.Refresh_Parent_Ramp__c= true;
        update opp;
        
        RefreshParentRampBatch cx = new RefreshParentRampBatch();
        Database.executeBatch( cx , 1 ); 
        test.stopTest();
    }
}