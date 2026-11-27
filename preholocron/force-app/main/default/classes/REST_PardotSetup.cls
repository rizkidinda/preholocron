public without sharing class REST_PardotSetup {
    public static Pardot_API_Setting__mdt getPardotAPISettings(){
        Pardot_API_Setting__mdt getSetting = [SELECT Business_Unit_ID__c, Deactivated__c FROM Pardot_API_Setting__mdt LIMIT 1];
        return getSetting;
    }

    @future(callout=true)
    public static void assignVisitorIdToProspect(String bid, String visitorId, String prospectId, String businessUnitID) {
        if(!String.isBlank(visitorId) && !String.isBlank(prospectId) && prospectId.isNumeric()){
            Map<String, Integer> objBody = new Map<String, Integer>();
            objBody.put('prospectId', Integer.valueOf(prospectId));
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://pi.pardot.com/api/v5/objects/visitors/' + visitorId + '/do/assignToProspect');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization','Bearer '+ UserInfo.getSessionID());
            req.setHeader('Pardot-Business-Unit-Id', businessUnitID);
            req.setBody(JSON.serialize(objBody));
            try{
                HttpResponse res = h.send(req);
                if(res != null && res.getStatusCode() != 200){
                    Exception_Logger__c ExLoggerRec = new Exception_Logger__c (Error_Message__c = bid + res.getBody() + JSON.serialize(objBody), Object_Name__c = 'Lead', Trigger_Name__c = 'assignVisitorIdToProspect', Error_Category__c = 'HTTP POST');
                    insert ExLoggerRec;
                }
            }catch(exception e){
                System.debug(e.getMessage());
                ExceptionUtility.createExceptionLog('assignVisitorIdToProspect','Lead', 'assignVisitorIdToProspect', 'HttpPost',  e);
            }
        }
    }
}