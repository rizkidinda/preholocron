public class ContactHandler {
    public static void updateContactAMEmail(List<Contact> listNew){
        try{
            Set<Id> accIdSet = new Set<Id>();
            String amDivisionLabel = System.Label.AM_DIVISION_DEFAULT;
            Map<Id, User> AMTeamUsers = new Map<Id, User>([SELECT Id, Email, Division FROM User WHERE Id IN
                                                        (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = 'AM Team')]);
            //get accounts
            for(Contact con : listNew){
                accIdSet.add(con.AccountId);
            }

            Map<Id,Account> accMap = New Map<Id, Account>([SELECT Id, OwnerId, Owner.Division, Owner.Email, Go_Live_Status__c FROM Account WHERE Id IN :accIdSet]);
            for(Contact con : listNew){
                Account currAcc = accMap.get(con.AccountId);
                if(currAcc != null && ((!String.isBlank(currAcc.Owner.Division) && currAcc.Owner.Division.contains(amDivisionLabel)) || AMTeamUsers.containsKey(currAcc.OwnerId))){
                    con.AM_Email__c = currAcc.Owner.Email;
                }
                con.Go_Live_Status__c = currAcc.Go_Live_Status__c;
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('ContactHandler','Contact', 'updateContactAMEmail', 'ContactTrigger',  e);
        }
    }

     /*
    Name : linkPardotVisitorID
    Description : link visitor ID from front end dashboard to SF Pardot
    */
    public static void linkPardotVisitorID(List<Contact> listNew, Map<Id, Contact> listOldMap){
        try{
            String pardotURLField = System.Label.Pardot_URL_Field;
            Pardot_API_Setting__mdt pardotSetup = REST_PardotSetup.getPardotAPISettings();
            for(Contact c : listNew){
                //format sample : http://pi.pardot.com/prospect/read?id=19143351 --> length : 46, index = : 37 ... 46 - (37+1) = 8
                String prospectIdURL = String.valueOf(c.get(pardotURLField));
                System.debug('prospectIdURL : ' + prospectIdURL);
                String prospectId = !String.isBlank(prospectIdURL) && prospectIdURL.indexOf('=') > -1 && (prospectIdURL.indexOf('=') + 1) < prospectIdURL.length() ? prospectIdURL.mid(prospectIdURL.indexOf('=') + 1 , prospectIdURL.length() - (prospectIdURL.indexOf('=') + 1 )) : '';
                System.debug('prospectId : ' + prospectId);
                Boolean contactWithURLandVisitorID = (!String.isBlank(prospectId) && !String.isBlank(c.Visitor_ID__c));
                Contact oldContact = listOldMap != null && listOldMap.containsKey(c.Id) ? listOldMap.get(c.Id) : null;
                if((listOldMap == null && contactWithURLandVisitorID) ||
                (oldContact != null && contactWithURLandVisitorID && (prospectIdURL != oldContact.get(pardotURLField) || c.Visitor_ID__c != oldContact.Visitor_ID__c))){
                    //if contact new OR contact update (on field pi url / visitor ID), call Pardot API
                    if(Test.isRunningTest() || !pardotSetup.Deactivated__c){
                        c.Assign_To_Prospect__c = true;
                    }
                }
            }
        }catch(Exception e) {
            ExceptionUtility.createExceptionLog('ContactHandler','Contact', 'linkPardotVisitorID', 'ContactTrigger',  e);
        }
    }
    
    
    /*
    Name : updateUTMCategory
    Description : automatically update UTM category and category group fields for specific contacts when there are changes in the Google Campaign source and medium.
    */
    public static void updateUTMCategory(List<Contact> listNew, Map<Id, Contact> oldMap) {
        Map<String, Map<String, String>> utmMapping = new Map<String, Map<String, String>>();
        List<Contact> contactListToProcess = new List<Contact>();
        
        for (UTM_Category_and_Category_Group_Mapping__c mapping : [SELECT Source_Vendor_Partner__c, Medium_Campaign__c, UTM_Category__c, UTM_Category_Group__c, isPartner__c FROM UTM_Category_and_Category_Group_Mapping__c]) {
            String key;
            if (mapping.isPartner__c) {
                key = mapping.Medium_Campaign__c;
            } else {
                key = mapping.Source_Vendor_Partner__c + mapping.Medium_Campaign__c;
            }
            utmMapping.put(key, new Map<String, String>{
                'Category' => mapping.UTM_Category__c,
                'CategoryGroup' => mapping.UTM_Category_Group__c
            });
        }
        
        for (Contact contact : listNew) {
            if ((contact.Last_Interaction_UTM_Category__c == null && contact.Last_Interaction_UTM_Category_Group__c == null) ||
                (contact.Heeet__Heeet_Google_Campaign_Source__c != oldMap.get(contact.Id).Heeet__Heeet_Google_Campaign_Source__c ||
                 contact.Heeet__Heeet_Google_Campaign_Medium__c != oldMap.get(contact.Id).Heeet__Heeet_Google_Campaign_Medium__c)) {
                     contactListToProcess.add(contact);
                 }
        }
        
        for (Contact contact : contactListToProcess) {
            String lastClickKey = contact.Heeet__Heeet_Google_Campaign_Source__c + contact.Heeet__Heeet_Google_Campaign_Medium__c;
            if (utmMapping.containsKey(contact.Heeet__Heeet_Google_Campaign_Medium__c)) { // If Medium is found in utmMapping, use Medium for mapping
                contact.Last_Interaction_UTM_Category__c = utmMapping.get(contact.Heeet__Heeet_Google_Campaign_Medium__c).get('Category');
                contact.Last_Interaction_UTM_Category_Group__c = utmMapping.get(contact.Heeet__Heeet_Google_Campaign_Medium__c).get('CategoryGroup');
            } else if (utmMapping.containsKey(lastClickKey)) {
                contact.Last_Interaction_UTM_Category__c = utmMapping.get(lastClickKey).get('Category');
                contact.Last_Interaction_UTM_Category_Group__c = utmMapping.get(lastClickKey).get('CategoryGroup');
            }
		}
    }
}