/**
 * @description       : 
 * @group             : 
 * @test class		  : IDScheduleProcessBatchAutoCLOpptyTest
 * @last modified on  : 14-10-2023
 * @last modified by  : Rizki.asriningtyas@xendit.co
**/
public class IDScheduleProcessBatchAutoCLOppty implements Schedulable {
    public void execute (SchedulableContext SC){
        String baseJobName = 'UpdateStageOppCLBatch'; 
        set<String> openStatus = new set<String>{'Queued','Preparing','Processing','Holding'};
        List<AsyncApexJob> runningJobs = [SELECT ApexClass.Name, Id, Status From AsyncApexJob WHERE ApexClass.Name = :baseJobName AND Status IN: openStatus];
       
        if (runningJobs.size() == 0) {
            String defaultUserEmail = System.Label.DEFAULT_OWNER_EMAIL;	//self-serve@xendit.co
            String queryForCLOppty = 'SELECT Id, Name FROM Opportunity WHERE LeadSource = \'Inbound\' AND Owner.Email = \'' + defaultUserEmail + '\' AND No_Stage_Movement__c = TRUE AND Opportunity.StageName NOT IN (\'Closed Won\', \'Closed Lost\')';

            UpdateStageOppCLBatch batchUpdate = new UpdateStageOppCLBatch(queryForCLOppty);
            Database.executeBatch(batchUpdate, 10);
        }
        if (SC != null) {
            System.abortJob(SC.getTriggerId()); //--> abort scheduler      
        }
        
        Datetime timestamp = System.now();
        Datetime day = timestamp.addDays(1);
        String month = String.valueOf(timestamp.month());
        String year = String.valueOf(timestamp.year());
        String strJobName = 'IDScheduleProcessBatchAutoCLOppty_' + year + month + String.valueOf(day.day()) + '_0230';
        String strSchedule = '0 30 2 ' + String.valueOf(day.day()) + ' ' + month + ' ? ' + year;

        List<CronJobDetail> scheduledJobs = [SELECT Id From CronJobDetail WHERE Name=:strJobName];
        if (scheduledJobs.size() == 0) {
            System.schedule(strJobName, strSchedule, new IDScheduleProcessBatchAutoCLOppty());
        }      
    }
}