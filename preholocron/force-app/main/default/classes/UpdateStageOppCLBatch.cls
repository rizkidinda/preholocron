/**
 * @description       : 
 * @group             : 
 * @test class		  : IDScheduleProcessBatchAutoCLOpptyTest
 * @last modified on  : 14-10-2023
 * @last modified by  : Rizki.asriningtyas@xendit.co
**/
public class UpdateStageOppCLBatch implements Database.Batchable<sObject>{
    public String query;
    
    public UpdateStageOppCLBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Opportunity> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity opp : scope) {
            opp.StageName = 'Closed Lost';
            opp.Reason_Lost_Opp__c = 'Dead - No Opportunity';
            opp.Sub_Reason_Opp__c = 'Non Qualified';
            opportunitiesToUpdate.add(opp);
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext ctx) {
    }   
}