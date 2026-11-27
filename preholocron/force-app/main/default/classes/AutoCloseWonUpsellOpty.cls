/**
 * @description       : 
 * @group             : 
 * @test class		  : IDScheduleProcessBatchAutoCLOpptyTest
 * @last modified on  : 02-11-2023
 * @last modified by  : Rizki.asriningtyas@xendit.co
**/
public with sharing class AutoCloseWonUpsellOpty implements Database.Batchable<sObject>{
    public String query;
    
    public AutoCloseWonUpsellOpty(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Opportunity> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Date today = Date.today();
        for(Opportunity opp: scope){
            opp.StageName = 'Closed Lost';
            opp.Reason_Lost_Opp__c = 'Dead - Lost';
            opp.Sub_Reason_Opp__c = 'Did not hit target objective within marketing campaign active period';
            opportunitiesToUpdate.add(opp);
        }

        if(!opportunitiesToUpdate.isEmpty()) {
            system.debug('update :'+ opportunitiesToUpdate);
            update opportunitiesToUpdate;

        }
    }
    
    public void finish(Database.BatchableContext ctx) {

    }   
}