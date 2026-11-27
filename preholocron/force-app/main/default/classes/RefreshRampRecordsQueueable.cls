public class RefreshRampRecordsQueueable implements Queueable{
    Set<Id> parentOppIdSet = new Set<Id>();
    public RefreshRampRecordsQueueable(Set<Id> oppIds) {
        parentOppIdSet = oppIds;
    }

    public void execute(QueueableContext qc){
        try{
            system.debug('oppIdSet : ' + JSON.serialize(parentOppIdSet));
            TriggerBypassUtility.opportunityTriggerBypass = true;
            Xendit_CreateChildRampRecords.createRampRecords(parentOppIdSet);
            Xendit_CalculateEstimatedValues.caculateFormulaFields(parentOppIdSet);
            TriggerBypassUtility.opportunityTriggerBypass = false;
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('RefreshRampRecordsQueueable','OpportunityRamp', 'RefreshRampRecordsQueueable', 'Queue',  e);
        }
        
    }
}