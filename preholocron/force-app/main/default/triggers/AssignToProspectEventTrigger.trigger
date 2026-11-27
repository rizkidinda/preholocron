trigger AssignToProspectEventTrigger on Assign_To_Prospect_Event__e (after insert) {
    Pardot_API_Setting__mdt pardotAPISetting = REST_PardotSetup.getPardotAPISettings();
    for(Assign_To_Prospect_Event__e event : trigger.New){
        REST_PardotSetup.assignVisitorIdToProspect(event.Business_ID__c, event.Visitor_ID__c, event.Prospect_ID__c, pardotAPISetting.Business_Unit_ID__c); 
    }
}