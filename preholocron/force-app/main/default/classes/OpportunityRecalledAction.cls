/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class OpportunityRecalledAction {
    @InvocableMethod (label='Unlock Opportunity Approval')    
    public Static void UnlockOpptyApp(List<Id> listOpptyAppID){
        List<Opportunity_Approval__c> updateOpptyApp = new List<Opportunity_Approval__c>();
        
        List<Opportunity_Approval__c> listOpptyAppToUnlock= [Select Id, Name, Status__c,FX_Type_Approved__c, Billing_Type_Approved__c from Opportunity_Approval__c where id =:listOpptyAppID];
        for (Opportunity_Approval__c OpptyAppToUnlock : listOpptyAppToUnlock)
        {
            if(Approval.isLocked(OpptyAppToUnlock.id)){
            	Approval.unlock(OpptyAppToUnlock.id);
            }
            
            if(opptyAppToUnlock.Status__c != 'Recalled'){
                OpptyAppToUnlock.Status__c = 'Recalled';
                OpptyAppToUnlock.FX_Type_Approved__c = false;
                OpptyAppToUnlock.Billing_Type_Approved__c = false;
                updateOpptyApp.add(OpptyAppToUnlock);
            }
        }
        
        update updateOpptyApp;
    }
}