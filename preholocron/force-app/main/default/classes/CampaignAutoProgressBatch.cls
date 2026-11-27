/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class CampaignAutoProgressBatch implements Database.Batchable<sObject>{
    public String query;
    
    public CampaignAutoProgressBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Campaign> scope) {
        List<Campaign> campaignToUpdate = new List<Campaign>();
        for (Campaign cmp : scope) {
            Boolean isUpdated = false;
            Campaign tempCmp = new Campaign();
            tempCmp.Id = cmp.Id;
            if (cmp.Status == 'Confirmed') {
                tempCmp.Status = 'In Progress';
                isUpdated = true;
            } else if (cmp.Status == 'In Progress' && Date.Today() > cmp.EndDate) {
                tempCmp.Status = 'Completed';
                isUpdated = true;
            }

            if (Date.Today() > cmp.Campaign_Association_End_Date__c && cmp.isActive) {
                tempCmp.isActive = false;
                isUpdated = true;
            }

            if (isUpdated = true) {
                campaignToUpdate.add(tempCmp);
            }
        }

        system.debug('***Update: '+ campaignToUpdate);
        if (campaignToUpdate.size() > 0) {
            update campaignToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext ctx) {
    }   
}