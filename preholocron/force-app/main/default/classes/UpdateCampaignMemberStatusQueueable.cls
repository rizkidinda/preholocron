public class UpdateCampaignMemberStatusQueueable implements Queueable {
    Set<Id> parentOppIdSet = new Set<Id>();

    public UpdateCampaignMemberStatusQueueable(Set<Id> oppIds) {
        parentOppIdSet = oppIds;
    }

    public void execute(QueueableContext qc){
        try{
            system.debug('oppIdSet : ' + JSON.serialize(parentOppIdSet));
            OpportunityHelper.updateCampaignMemberStatus(parentOppIdSet);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('UpdateCampaignMemberStatusQueueable','CampaignMember', 'UpdateCampaignMemberStatusQueueable', 'Queue',  e);
        }
        
    }
}