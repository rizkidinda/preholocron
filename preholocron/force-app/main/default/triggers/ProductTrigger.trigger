trigger ProductTrigger on Product2 (after update) {
    if(!TriggerBypassUtility.productTriggerBypass){
        if(trigger.isUpdate){
            ProductHelper.updateChannelKYC(trigger.New, trigger.oldMap);
        }
    }
}