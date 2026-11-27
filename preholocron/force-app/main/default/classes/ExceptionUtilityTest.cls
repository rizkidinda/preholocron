/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest()
public class ExceptionUtilityTest {
    static testmethod void ErrorHandling()
    {
        test.startTest();
    
        User currUser = [SELECT Id, Bypass_VR__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        currUser.Bypass_VR__c = TRUE;
        update currUser;

        Account accP=new Account();
        accP.Name='Test Account Parent';
        accP.Type='GROUP';
        accP.Segment__c='MM';
        accP.Brand__c='Test Account Parent';
        insert accP;

        Account acc=new Account();
        acc.Name='Test Account';
        acc.Segment__c='MM';
        acc.Brand__c='Test Account';
        acc.ParentId=accP.Id;

        insert acc;

        currUser.Bypass_VR__c = FALSE;
        update currUser;
            
        Set<String> accId = new Set<String>{accP.Id};
        ParentAccountRevenueUpdateBatch cx = new ParentAccountRevenueUpdateBatch(accId);
        Database.executeBatch( cx , 1 ); 
            
        test.stopTest();
    }
    
    static testmethod void constructDatabaseErrorTest() {
        Exception_Logger__c testLog = ExceptionUtility.constructDatabaseError('AccountHelper','CreateOpportunityGLR', 'insert', 'Auto Create Child Opportunity GLR', 'test');
    }
}