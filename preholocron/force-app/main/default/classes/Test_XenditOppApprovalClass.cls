/**
 * @description       : 
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
public class Test_XenditOppApprovalClass {
    static testmethod void testApprovalClass(){
        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        acc.Country_of_HQ__c = 'Indonesia';
        insert acc;
        
        User getSalesRep = [SELECT Id FROM User WHERE UserRole.Name = 'ID Sales Rep' AND IsActive = TRUE LIMIT 1];
        
        Opportunity opp=new Opportunity();
        opp.Name='Parent Opp';
        opp.AccountId=acc.id;
        opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
        opp.CurrencyIsoCode='IDR';
        opp.Xst_Txn_Act_Date__c=system.today()+30;
        opp.CloseDate=system.today()+60;
        opp.StageName='Qualification';
        opp.OwnerId = getSalesRep.Id;
        insert opp;
        
        //create child
        Opportunity childOpp=new Opportunity();
        childOpp.Name='Child Opp';
        childOpp.Parent_Opportunity__c=opp.id;
        childOpp.AccountId=acc.id;
        childOpp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
        childOpp.CurrencyIsoCode='IDR';
        childOpp.Xst_Txn_Act_Date__c=system.today()+30;
        childOpp.CloseDate=system.today()+60;
        childOpp.StageName='Qualification';
        childOpp.OwnerId = getSalesRep.Id;
        insert childOpp;
        
        Xendit_Price_Book__c pb = new Xendit_Price_Book__c();
        pb.Name = 'Test PB';
        pb.Active__c = true;
        pb.CurrencyIsoCode = 'IDR';
        insert pb;
        
        Rate_Card__c rcTest = new Rate_Card__c();
        rcTest.Xendit_Price_Book__c = pb.Id;
        insert rcTest;
        
        Xendit_Opportunity_Product__c prod1= new Xendit_Opportunity_Product__c();
        prod1.Basket_Size__c=200;
        prod1.Opportunity__c=childOpp.id;
        prod1.Rate_Card__c = rcTest.Id;
        insert prod1;
        
        prod1.Total_Revenue__c=400000;
        prod1.TPV__c=6000;
        prod1.Rate_Per_TPV_List__c=1.5;
        update prod1;

        test.startTest();

        Opportunity updateParentOpp = new Opportunity(Id = opp.Id, Billing_Type_Approval_Level__c = 0, Pricing_Approver_Level__c = 1, Opp_Product_Below_COGS_Count__c = 0);
        TriggerBypassUtility.opportunityTriggerBypass = true;
        update updateParentOpp;
        TriggerBypassUtility.opportunityTriggerBypass = false;
        
        User l1Manager = [SELECT Id, Approval_Level__c FROM User WHERE Approval_Level__c = '1' LIMIT 1];

        Opportunity_Approval__c app=new Opportunity_Approval__c();
        app.RecordTypeId=Schema.SObjectType.Opportunity_Approval__c.getRecordTypeInfosByName().get('Pricing Approval').getRecordTypeId();
        app.CurrencyIsoCode='IDR';
        app.Opportunity__c=opp.id;
        app.Any_Product_in_Loss_Making__c='No';
        app.Required_Manual_Billing__c='Yes';
        insert app;

        app.L1_Manager__c = l1Manager.Id;
        app.Approval_Step__c = 1;
        TriggerBypassUtility.opportunityApprovalTriggerBypass = true;
        update app;
        TriggerBypassUtility.opportunityApprovalTriggerBypass = false;
        
        
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(app.id);
        req.setComments('Submitting request for approval.');
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
        System.assert(result.isSuccess());
        
        // First, get the ID of the newly created item
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        
        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 =new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 = Approval.process(req2);      
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        
        test.stopTest();
    }
}