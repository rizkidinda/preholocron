public without sharing class REST_AdminDashboardSyncSetup {

    public static Admin_Dashboard_Integration_Setting__mdt getADSettings(String strAction){
        Admin_Dashboard_Integration_Setting__mdt getSetting = [SELECT Base_URL__c, API_Key__c, Deactivate__c FROM Admin_Dashboard_Integration_Setting__mdt WHERE DeveloperName =: strAction LIMIT 1];
        return getSetting;
    }

    public static String getJSONBody (Map<Id, User> userMap, String objCPManagerId, String objOwnerId, String accTeamAssignment){
        Map<String, String> objBody = new Map<String, String>();
        Set<String> adminProfileSet = new Set<String>{'System Administrator','Xendit API Profile'};
        User objOwner = userMap.containsKey(objOwnerId) ? userMap.get(objOwnerId) : null;
        User objCPManager = userMap.containsKey(objCPManagerId) ? userMap.get(objCPManagerId) : null;
        if(objCPManager != null){
            objBody.put('channel_partnership_manager',objCPManager.FederationIdentifier);
        }else if(objOwner != null && objOwner.AD_User_Category__c == 'CP Manager'){
            objBody.put('channel_partnership_manager',objOwner.FederationIdentifier);
        }

        if(objOwner != null && !adminProfileSet.contains(objOwner.Profile.Name)){
            if(objOwner.AD_User_Category__c == 'Hybrid' && accTeamAssignment == 'Existing'){
                //update to Account Manager (AD)
                objBody.put('account_manager_name',objOwner.FederationIdentifier);
                objBody.put('account_manager_email',objOwner.FederationIdentifier);
            }else if(objOwner.AD_User_Category__c == 'Hybrid' && accTeamAssignment != 'Existing'){
                objBody.put('sales_rep_name',objOwner.FederationIdentifier);
            }else if(objOwner.AD_User_Category__c == 'AM'){
                objBody.put('account_manager_name',objOwner.FederationIdentifier);
                objBody.put('account_manager_email',objOwner.FederationIdentifier);
            }else if(objOwner.AD_User_category__c == 'BD Manager'){
                objBody.put('business_development_manager',objOwner.FederationIdentifier);
            }else if(String.isBlank(objOwner.AD_User_Category__c) || objOwner.AD_User_Category__c == 'Sales Rep'){
                objBody.put('sales_rep_name',objOwner.FederationIdentifier);
            }
        }

        return JSON.serialize(objBody);
    }

    @future(callout=true)
    public static void updateUserFields(String bid, String strJSON, String baseURL, String apiKey) {
        if(!String.isBlank(bid)){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseURL + '?business_id=' + bid);
            req.setMethod('PATCH');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-key',apiKey);
            req.setBody(strJSON);
            try{
                HttpResponse res = h.send(req);
                if(res != null && res.getStatusCode() != 200){
                    Exception_Logger__c ExLoggerRec = new Exception_Logger__c (Error_Message__c = bid + res.getBody() + strJSON, Object_Name__c = 'Account/Lead', Trigger_Name__c = 'updateUserFields', Error_Category__c = 'HTTP PATCH');
                    insert ExLoggerRec;
                }
            }catch(exception e){
                System.debug(e.getMessage());
                ExceptionUtility.createExceptionLog('updateUserFields','Account/Lead', 'updateUserFields', 'HttpPatch',  e);
            }
        }
    }
}