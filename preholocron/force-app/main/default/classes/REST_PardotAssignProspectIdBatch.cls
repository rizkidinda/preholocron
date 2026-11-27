public without sharing class REST_PardotAssignProspectIdBatch implements database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Schedulable{

    public String pardotURLField = System.Label.Pardot_URL_Field;
    public Integer batchSize = 20;
    public List<Lead> updateLeads = new List<Lead>();
    public List<Contact> updateContacts = new List<Contact>();
    public List<Exception_Logger__c> exceptionList = new List<Exception_Logger__c>();
    public String strObjName = 'Lead';

    public REST_PardotAssignProspectIdBatch(Integer batchInt, String objName) {
        batchSize = batchInt != null ? batchInt : 20;
        strObjName = objName;
    }

    //start
    public Database.QueryLocator start (Database.BatchableContext BC){
        String businessIdStr = strObjName == 'Contact' ? 'Business_ID_Formula__c' : 'Business_ID__c';
        String qryStr = 'SELECT Id, ' + businessIdStr + ' , ' + pardotURLField + ' , Visitor_ID__c, Assign_To_Prospect__c FROM '+ strObjName +' WHERE Assign_To_Prospect__c = TRUE';
        return Database.getQueryLocator(qryStr);
    }
	    
    public void execute(Database.BatchableContext BC, List<sObject> scope){

        try{
            List<sObject> objList = (List<sObject>)scope;
            Pardot_API_Setting__mdt pardotSetup = REST_PardotSetup.getPardotAPISettings();
            
            for(sObject l : objList){
                String prospectIdURL = String.valueOf(l.get(pardotURLField));
                String prospectId = !String.isBlank(prospectIdURL) && prospectIdURL.indexOf('=') > -1 && (prospectIdURL.indexOf('=') + 1) < prospectIdURL.length() ? prospectIdURL.mid(prospectIdURL.indexOf('=') + 1 , prospectIdURL.length() - (prospectIdURL.indexOf('=') + 1 )) : '';
                //ENDPOINT
                if(!String.isBlank(String.valueOf(l.get('Visitor_ID__c'))) && !String.isBlank(prospectId) && prospectId.isNumeric()){
                    Map<String, Integer> objBody = new Map<String, Integer>();
                    objBody.put('prospectId', Integer.valueOf(prospectId));
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('https://pi.pardot.com/api/v5/objects/visitors/' + String.valueOf(l.get('Visitor_ID__c')) + '/do/assignToProspect');
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('Authorization','Bearer '+ UserInfo.getSessionID());
                    req.setHeader('Pardot-Business-Unit-Id', pardotSetup.Business_Unit_ID__c);
                    req.setBody(JSON.serialize(objBody));
                    try{
                        HttpResponse res = h.send(req);
                        
                        if(res != null && res.getStatusCode() != 200){
                            String businessIdStr = strObjName == 'Contact' ? 'Business_ID_Formula__c' : 'Business_ID__c';
                            Exception_Logger__c ExLoggerRec = new Exception_Logger__c (Error_Message__c = String.valueOf(l.get(businessIdStr)) + res.getBody() + JSON.serialize(objBody), Object_Name__c = strObjName, Trigger_Name__c = 'REST_PardotAssignProspectIdBatch', Error_Category__c = 'HTTP POST');
                            exceptionList.add(ExLoggerRec);
                        }
                        
                        if(strObjName == 'Lead'){
                            Lead updateLeadTemp = new Lead(Id = String.valueOf(l.get('Id')), Assign_To_Prospect__c = false);
                            updateLeads.add(updateLeadTemp);
                        }else if(strObjName == 'Contact'){
                            Contact updateContactTemp = new Contact(Id = String.valueOf(l.get('Id')), Assign_To_Prospect__c = false);
                            updateContacts.add(updateContactTemp);
                        }
                        
                    }catch(exception e){
                        System.debug(e.getMessage());
                        ExceptionUtility.createExceptionLog('assignVisitorIdToProspect',strObjName, 'REST_PardotAssignProspectIdBatch', 'HttpPost',  e);
                    }

                    if(Test.isRunningTest()){
                       if(strObjName == 'Lead'){
                            Lead updateLeadTemp = new Lead(Id = String.valueOf(l.get('Id')), Assign_To_Prospect__c = false);
                            updateLeads.add(updateLeadTemp);
                        }else if(strObjName == 'Contact'){
                            Contact updateContactTemp = new Contact(Id = String.valueOf(l.get('Id')), Assign_To_Prospect__c = false);
                            updateContacts.add(updateContactTemp);
                        }
                   }
                }
            }
        }catch(exception e){
            System.debug(e.getMessage());
            ExceptionUtility.createExceptionLog('REST_PardotAssignProspectIdBatch',strObjName, 'REST_PardotAssignProspectIdBatch', 'HttpPost',  e);
        }
    }
   
    public void finish( Database.BatchableContext BC ) {
        try{
            if(!updateLeads.isEmpty()){
                TriggerBypassUtility.leadTriggerBypass = true;
                update updateLeads;
                TriggerBypassUtility.leadTriggerBypass = false;
            }

            if(!updateContacts.isEmpty()){
                TriggerBypassUtility.contactTriggerBypass = true;
                update updateContacts;
                TriggerBypassUtility.contactTriggerBypass = false;
            }
            if(!exceptionList.isEmpty()) insert exceptionList;
        }
        catch (exception e){
            ExceptionUtility.createExceptionLog('REST_PardotAssignProspectIdBatch',strObjName, 'REST_PardotAssignProspectIdBatch', 'HttpPost',  e);
        }
    }

    public void execute( Schedulablecontext sc ){
        REST_PardotAssignProspectIdBatch cx = new REST_PardotAssignProspectIdBatch(batchSize, strObjName);
        Database.executeBatch( cx , batchSize ); 
    }
}