/**
 * @description       : 
 * @group             : 
 * @test class		  : IDScheduleProcessBatchAutoCLOpptyTest
 * @last modified on  : 02-11-2023
 * @last modified by  : Rizki.asriningtyas@xendit.co
**/
public with sharing class ClosedWonOppUpsellSch implements Schedulable {
    public void execute (SchedulableContext SC){
        String baseJobName = 'ClosedWonOppUpsellSch'; 
        set<String> openStatus = new set<String>{'Queued','Preparing','Processing','Holding'};
        List<AsyncApexJob> runningJobs = [SELECT ApexClass.Name, Id, Status From AsyncApexJob WHERE ApexClass.Name = :baseJobName AND Status IN: openStatus];
       
        if (runningJobs.size() == 0) {
            String query = 'SELECT ID, Type, StageName, Reason_Lost_Opp__c, Sub_Reason_Opp__c FROM Opportunity WHERE StageName = \'Contracting\' AND Type = \'Upsell\' AND Onboarding_Contracting_Date__c < LAST_N_MONTHS:3';
            AutoCloseWonUpsellOpty batchUpdate = new AutoCloseWonUpsellOpty(query);
            Database.executeBatch(batchUpdate, 10);
        }
        
        Datetime timestamp = system.now().addDays(1);
        String day = string.valueOf(timestamp.day());
        String month = string.valueOf(timestamp.month());
        String hour = string.valueOf(timestamp.hour());
        String minute = string.valueOf(timestamp.minute());
        String second = string.valueOf(timestamp.second());
        String year = string.valueOf(timestamp.year());
        
        String strJobName = 'ClosedWonOppUpsellSch' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        
        List<CronJobDetail> scheduledJobs = [SELECT Id From CronJobDetail WHERE Name=:strJobName];
        if (scheduledJobs.size() == 0) {
            System.schedule(strJobName, strSchedule, new ClosedWonOppUpsellSch());
        }
        
        if (SC != null) {
            System.abortJob(SC.getTriggerId());            
        }
    }
}