trigger ContactTrigger on Contact (before insert, before update) {
    if(!TriggerBypassUtility.contactTriggerBypass){
        if(trigger.isBefore){
            if(trigger.isInsert){
                ContactHandler.updateContactAMEmail(trigger.New);
                ContactHandler.linkPardotVisitorID(trigger.New, null);
            }else if(trigger.isUpdate){
                ContactHandler.linkPardotVisitorID(trigger.New, trigger.oldMap);
                ContactHandler.updateUTMCategory(trigger.New, trigger.oldMap);
            }
        }
    }
}