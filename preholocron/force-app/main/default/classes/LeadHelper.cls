public class LeadHelper {
    public static void updateLeadOwner(List<Lead> listNew, Map<Id, Lead> listOldMap){
        try{
            Set<Id> updatedLeadIdSet = new Set<Id>();
            List<Lead> updatedLeadList = new List<Lead>();
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email, Profile.Name, AD_User_Category__c, FederationIdentifier, Division FROM User]);
            Opportunity_Exception_User__mdt defaultSalesOpsUser = [SELECT Id, User_Email__c FROM Opportunity_Exception_User__mdt WHERE DeveloperName = 'Default_Sales_Ops_User' LIMIT 1];
            Set<String> adminProfileSet = new Set<String>{'System Administrator','Xendit API Profile'};
            for(Lead l : listNew){
                Lead oldLead = listOldMap != null && listOldMap.containsKey(l.Id) ? listOldMap.get(l.Id) : null;
                if(
                    !String.isBlank(l.Business_ID__c) && 
                    ((!String.isBlank(l.CP_Manager__c) && (oldLead == null || (oldLead != null && oldLead.CP_Manager__c != l.CP_Manager__c) || (l.Update_to_AD__c && oldLead.Update_to_AD__c != l.Update_to_AD__c)) && !adminProfileSet.contains(userMap.get(l.CP_Manager__c).Profile.Name) && userMap.get(l.CP_Manager__c).FederationIdentifier != defaultSalesOpsUser.User_Email__c) ||
                    (!String.isBlank(l.OwnerId) && String.valueOf(l.OwnerId).startsWith('005') && (oldLead == null || (oldLead != null && oldLead.OwnerId != l.OwnerId) || (l.Update_to_AD__c && oldLead.Update_to_AD__c != l.Update_to_AD__c)) && !adminProfileSet.contains(userMap.get(l.OwnerId).Profile.Name) && userMap.get(l.OwnerId).FederationIdentifier != defaultSalesOpsUser.User_Email__c))
                ){
                    updatedLeadIdSet.add(l.Id);
                    updatedLeadList.add(l);
                }
            }

            if(!updatedLeadIdSet.isEmpty()){
                Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
                String integName = !org.IsSandbox ? 'AD_User_Field_Update_URL_PRD' : 'AD_User_Field_Update_URL_Staging';
                Admin_Dashboard_Integration_Setting__mdt ADuserUpdateSetting = REST_AdminDashboardSyncSetup.getADSettings(integName);
                    if(!ADuserUpdateSetting.Deactivate__c){
                        for(Id leadId : updatedLeadIdSet){
                        Database.executeBatch(new UpdateADUserBatch(leadId, 'Lead'), 1);
                    }
                }
                
                List<Lead> deactivateLeadFlag = new List<Lead>();
                for(Lead l : updatedLeadList){
                    if(l.Update_to_AD__c){
                        deactivateLeadFlag.add(new Lead(Id = l.Id, update_to_AD__c = false));
                    }
                }
                if(!deactivateLeadFlag.isEmpty()){
                    TriggerBypassUtility.leadTriggerBypass = true;
                    update deactivateLeadFlag;
                    TriggerBypassUtility.leadTriggerBypass = false;
                }
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'updateLeadOwner', 'LeadTrigger',  e);
        }

    }

    /*
    Name : linkPardotVisitorID
    Description : link visitor ID from front end dashboard to SF Pardot
    */
    public static void linkPardotVisitorID(List<Lead> listNew, Map<Id, Lead> listOldMap){
        try{
            String pardotURLField = System.Label.Pardot_URL_Field;
            Pardot_API_Setting__mdt pardotSetup = REST_PardotSetup.getPardotAPISettings();
            List<Assign_To_Prospect_Event__e> insertProspectEventList = new List<Assign_To_Prospect_Event__e>();
            for(Lead l : listNew){
                //format sample : http://pi.pardot.com/prospect/read?id=19143351 --> length : 46, index = : 37 ... 46 - (37+1) = 8
                String prospectIdURL = String.valueOf(l.get(pardotURLField));
                System.debug('prospectIdURL : ' + prospectIdURL);
                String prospectId = !String.isBlank(prospectIdURL) && prospectIdURL.indexOf('=') > -1 && (prospectIdURL.indexOf('=') + 1) < prospectIdURL.length() ? prospectIdURL.mid(prospectIdURL.indexOf('=') + 1 , prospectIdURL.length() - (prospectIdURL.indexOf('=') + 1 )) : '';
                System.debug('prospectId : ' + prospectId);
                Boolean leadWithURLandVisitorID = (!String.isBlank(prospectId) && !String.isBlank(l.Visitor_ID__c));
                Lead oldLead = listOldMap != null && listOldMap.containsKey(l.Id) ? listOldMap.get(l.Id) : null;
                if((listOldMap == null && leadWithURLandVisitorID) ||
                (oldLead != null && leadWithURLandVisitorID && (prospectIdURL != oldLead.get(pardotURLField) || l.Visitor_ID__c != oldLead.Visitor_ID__c))){
                    //if lead new OR lead update (on field pi url / visitor ID), call Pardot API
                    if(Test.isRunningTest() || !pardotSetup.Deactivated__c){
                        //REST_PardotSetup.assignVisitorIdToProspect(l.Business_ID__c, l.Visitor_ID__c, prospectId, pardotSetup.Business_Unit_ID__c);
                        //Assign_To_Prospect_Event__e tempProspectEvent = new Assign_To_Prospect_Event__e(Business_ID__c = l.Business_ID__c, Prospect_ID__c = prospectId, Visitor_ID__c = l.Visitor_ID__c);
                        //insertProspectEventList.add(tempProspectEvent);
                        l.Assign_To_Prospect__c = true;
                    }
                }
            }

            // if(!insertProspectEventList.isEmpty()){
            //     system.debug('insertProspectEventList insert');
            //     EventBus.publish(insertProspectEventList);
            // }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'linkPardotVisitorID', 'LeadTrigger',  e);
        }
    }

    /*
    Name : UpdateWeeklyUpdateHistory
    Description : update weekly update history automatically when user update weekly update field
    */
    public static void UpdateWeeklyUpdateHistory(List<Lead> listNew, Map<Id, Lead> oldMap){
        try{
            for(Lead l : listNew){
                DateTime todayDate = Datetime.now();
                String strTodayDate = todayDate.format('dd/MM/yyyy');
                String currWeeklyUpdate = !String.isBlank(l.Weekly_Update__c) ? strTodayDate + ' ' + UserInfo.getName() + ': ' + l.Weekly_Update__c : '';
                if(oldMap == null){
                    l.Weekly_Update_History__c = currWeeklyUpdate;
                }else if(l.Id != null && oldMap.containsKey(l.Id) && oldMap.get(l.Id).Weekly_Update__c != l.Weekly_Update__c){
                    String weeklyHistory = l.Weekly_Update_History__c != null ? l.Weekly_Update_History__c : '';
                    l.Weekly_Update_History__c = currWeeklyUpdate +'<br/>'+weeklyHistory;
                }
            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'UpdateWeeklyUpdateHistory', 'LeadTrigger',  e);
        }
    }

    /*
    Name : UpdateFirstLastTouchLeadSource
    Description : update first & last touch lead source
    */
    public static void UpdateFirstLastTouchLeadSource(List<Lead> listNew, Map<Id, Lead> oldMap){
        try{
            for(Lead l : listNew){
                Lead oldLead = oldMap.get(l.Id);
                if(oldLead != null){
                    String currFirstTouchLeadSource = l.LeadSource;
                    String currLastTouchLeadSource = l.Last_Touch_Lead_source__c;
                    l.LeadSource = HeeetHelper.getFirstTouchLeadSource(l, oldLead, currFirstTouchLeadSource);
                    l.Last_Touch_Lead_source__c = HeeetHelper.getLastTouchLeadSource(l, oldLead, currLastTouchLeadSource);
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'UpdateFirstLastTouchLeadSource', 'LeadTrigger',  e);
        }
    }

    /*
    Name : CreateLeadOppCampaignInfluence
    Description : auto create campaign influence to opp created by converted lead
    */
    public static void CreateLeadOppCampaignInfluence(List<Lead> listNew, Map<Id, Lead> oldMap){
        try{
            Map<Id, Id> leadOppMap = new Map<Id, Id>();
            Map<Id, Id> leadContactMap = new Map<Id, Id>();
            for(Lead leadRec : listNew){
                Lead oldLeadRec = oldMap.get(leadRec.Id);
                if(oldLeadRec != null && leadRec.IsConverted && leadRec.IsConverted != oldLeadRec.IsConverted && leadRec.ConvertedOpportunityId != null && leadRec.ConvertedContactId != null){
                    leadOppMap.put(leadRec.Id, leadRec.ConvertedOpportunityId);
                    leadContactMap.put(leadRec.Id, leadRec.ConvertedContactId);
                }
            }

            if(!leadOppMap.isEmpty()){
                String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
                CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
                for(Id leadId : leadOppMap.keySet()){
                    Set<Id> contactId = new Set<Id>();
                    contactId.add(leadContactMap.get(leadId));
                    CreateLeadOppCampInfluenceBatch cx = new CreateLeadOppCampInfluenceBatch(leadId, contactId, leadOppMap.get(leadId), defaultModel.Id, 'CONVERTED_LEAD');
                    Database.executeBatch(cx, 200); 
                }
                
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'CreateLeadOppCampaignInfluence', 'LeadTrigger',  e);
        }
    }

    /*
    Name : UpdateCampaignMemberStatusDashboardSignUp
    Description : update camp member status to Dashboard Sign Up when lead BID is populated
    */
    public static void UpdateCampaignMemberStatusDashboardSignUp(List<Lead> listNew, Map<Id, Lead> oldMap){
        try{
            Set<Id> updateLeadIdSet = new Set<Id>();
            for(Lead l : listNew){
                Lead oldLead = oldMap.get(l.Id);
                if(String.isBlank(oldLead.Business_Id__c) && !String.isBlank(l.Business_Id__c)){ // if Business Id is populated
                    updateLeadIdSet.add(l.Id);
                }
            }

            if(!updateLeadIdSet.isEmpty()){
                AutoUpdateCampaignMemberStatusBatch cx = new AutoUpdateCampaignMemberStatusBatch(null, updateLeadIdSet, null, 'Dashboard Sign Up');
                Database.executeBatch(cx, 200);
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('LeadHelper','Lead', 'UpdateCampaignMemberStatusDashboardSignUp', 'LeadTrigger',  e);
        }
    }
    
    /*
    Name : updateUTMCategory
    Description : automatically update UTM category and category group fields for specific leads when there are changes in the Google Campaign source and medium.
    */
    public static void updateUTMCategory(List<Lead> listNew, Map<Id, Lead> oldMap) {
        Map<String, Map<String, String>> utmMapping = new Map<String, Map<String, String>>();
        List<Lead> leadListToProcess = new List<Lead>();
        
        for (Lead lead : listNew) {
            if ((lead.First_Interaction_UTM_Category__c == null && lead.First_Interaction_UTM_Category_Group__c == null) ||
                (lead.Last_Interaction_UTM_Category__c == null && lead.Last_Interaction_UTM_Category_Group__c == null) ||
                (lead.Heeet__Heeet_Google_Campaign_Source__c != oldMap.get(lead.Id).Heeet__Heeet_Google_Campaign_Source__c ||
                 lead.Heeet__Heeet_Google_Campaign_Medium__c != oldMap.get(lead.Id).Heeet__Heeet_Google_Campaign_Medium__c)) {
                     leadListToProcess.add(lead);
                 }
        }
        
        if (leadListToProcess.size() > 0) {
            for (UTM_Category_and_Category_Group_Mapping__c mapping : [SELECT Source_Vendor_Partner__c, Medium_Campaign__c, UTM_Category__c, UTM_Category_Group__c, isPartner__c FROM UTM_Category_and_Category_Group_Mapping__c]) {
                String key;
                if (mapping.isPartner__c) {
                    key = mapping.Medium_Campaign__c;
                } else {
                    key = mapping.Source_Vendor_Partner__c +'_'+ mapping.Medium_Campaign__c;
                }
                utmMapping.put(key, new Map<String, String>{
                    'Category' => mapping.UTM_Category__c,
                    'CategoryGroup' => mapping.UTM_Category_Group__c
                });
            }
            
            for (Lead lead : leadListToProcess) {
                String firstClickKey = lead.Heeet__Heeet_First_Click_Campaign_Source__c +'_'+ lead.Heeet__Heeet_First_Click_Campaign_Medium__c;
                String lastClickKey = lead.Heeet__Heeet_Google_Campaign_Source__c + '_'+lead.Heeet__Heeet_Google_Campaign_Medium__c;
                
                if (lead.First_Interaction_UTM_Category__c == null && lead.First_Interaction_UTM_Category_Group__c == null) {
                    if (utmMapping.containsKey(lead.Heeet__Heeet_First_Click_Campaign_Medium__c)) { // If Medium is found in utmMapping, use Medium for mapping
                        lead.First_Interaction_UTM_Category__c = utmMapping.get(lead.Heeet__Heeet_First_Click_Campaign_Medium__c).get('Category');
                		lead.First_Interaction_UTM_Category_Group__c = utmMapping.get(lead.Heeet__Heeet_First_Click_Campaign_Medium__c).get('CategoryGroup');
                    }
                    else if (utmMapping.containsKey(firstClickKey)) {
                        lead.First_Interaction_UTM_Category__c = utmMapping.get(firstClickKey).get('Category');
                        lead.First_Interaction_UTM_Category_Group__c = utmMapping.get(firstClickKey).get('CategoryGroup');
                    }
                 }
                
                if ((lead.Last_Interaction_UTM_Category__c == null && lead.Last_Interaction_UTM_Category_Group__c == null) ||
                    (lead.Heeet__Heeet_Google_Campaign_Source__c != oldMap.get(lead.Id).Heeet__Heeet_Google_Campaign_Source__c ||
                     lead.Heeet__Heeet_Google_Campaign_Medium__c != oldMap.get(lead.Id).Heeet__Heeet_Google_Campaign_Medium__c)) {
                         
                     if (utmMapping.containsKey(lead.Heeet__Heeet_Google_Campaign_Medium__c)) { // If Medium is found in utmMapping, use Medium for mapping
                         lead.Last_Interaction_UTM_Category__c = utmMapping.get(lead.Heeet__Heeet_Google_Campaign_Medium__c).get('Category');
                         lead.Last_Interaction_UTM_Category_Group__c = utmMapping.get(lead.Heeet__Heeet_Google_Campaign_Medium__c).get('CategoryGroup');
                     }   
                     else if (utmMapping.containsKey(lastClickKey)) {
                        lead.Last_Interaction_UTM_Category__c = utmMapping.get(lastClickKey).get('Category');
                        lead.Last_Interaction_UTM_Category_Group__c = utmMapping.get(lastClickKey).get('CategoryGroup');
                     }
                }
            }
        }
    }
}