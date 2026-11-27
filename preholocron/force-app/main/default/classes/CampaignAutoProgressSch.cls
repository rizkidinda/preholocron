/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public with sharing class CampaignAutoProgressSch implements Schedulable {
    public void execute (SchedulableContext SC){
        String baseJobName = 'CampaignAutoProgressBatch'; 
        set<String> openStatus = new set<String>{'Queued','Preparing','Processing','Holding'};
        List<AsyncApexJob> runningJobs = [SELECT ApexClass.Name, Id, Status From AsyncApexJob WHERE ApexClass.Name = :baseJobName AND Status IN: openStatus];
       
        if (runningJobs.size() == 0) {
            String query = 'SELECT Id, Status, StartDate, EndDate, Campaign_Association_End_Date__c, isActive FROM Campaign WHERE (Status = \'Confirmed\' AND StartDate <= TODAY AND EndDate >= TODAY) OR (Status = \'In Progress\' AND EndDate < TODAY) OR (isActive = TRUE AND Campaign_Association_End_Date__c < TODAY)';
            CampaignAutoProgressBatch batchUpdate = new CampaignAutoProgressBatch(query);
            Database.executeBatch(batchUpdate, 30);
        }
        
        Datetime timestamp = system.now().addDays(1);
        String day = string.valueOf(timestamp.day());
        String month = string.valueOf(timestamp.month());
        String hour = string.valueOf(timestamp.hour());
        String minute = string.valueOf(timestamp.minute());
        String second = string.valueOf(timestamp.second());
        String year = string.valueOf(timestamp.year());
        
        String strJobName = 'CampaignAutoProgressSch_' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        
        List<CronJobDetail> scheduledJobs = [SELECT Id From CronJobDetail WHERE Name=:strJobName];
        if (scheduledJobs.size() == 0) {
            System.schedule(strJobName, strSchedule, new CampaignAutoProgressSch());
        }
        
        if (SC != null) {
            System.abortJob(SC.getTriggerId());            
        }
    }
}