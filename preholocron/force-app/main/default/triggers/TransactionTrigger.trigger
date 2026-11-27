trigger TransactionTrigger on Transaction__c (before insert, before update, after insert, after update) {
    if (trigger.isBefore) {
        if (trigger.isInsert) {
            TransactionHelper.updateFieldsBeforeSave(trigger.new, null);
        }
        else if (trigger.isUpdate) {
            TransactionHelper.updateFieldsBeforeSave(trigger.new, trigger.old);
        }
    }
    if (trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            TransactionHelper.CheckOpportunityStage(trigger.new, trigger.old);
        }
    }
}