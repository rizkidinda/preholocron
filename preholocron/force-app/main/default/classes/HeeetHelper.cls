public class HeeetHelper {
    public static String getLastTouchLeadSource(sObject newObj, sObject oldObj, String currLastTouchLeadSource){
        String lastTouchVal = !String.isBlank(currLastTouchLeadSource) ? currLastTouchLeadSource : '';
        Boolean validVal = !String.isBlank((String)newObj.get('Heeet__Heeet_Google_Campaign_Source__c')) || !String.isBlank((String)newObj.get('Heeet__Heeet_Google_Campaign_Medium__c'));
        if(validVal && 
        ((String)newObj.get('Heeet__Heeet_Google_Campaign_Source__c') != (String)oldObj.get('Heeet__Heeet_Google_Campaign_Source__c') 
            || (String)newObj.get('Heeet__Heeet_Google_Campaign_Medium__c') != (String)oldObj.get('Heeet__Heeet_Google_Campaign_Medium__c'))
        ){
            String heeetGoogleCampaignSource = String.isBlank((String)newObj.get('Heeet__Heeet_Google_Campaign_Source__c')) ? '' : (String)newObj.get('Heeet__Heeet_Google_Campaign_Source__c');
            String heeetGoogleCampaignMedium = String.isBlank((String)newObj.get('Heeet__Heeet_Google_Campaign_Medium__c')) ? '' : (String)newObj.get('Heeet__Heeet_Google_Campaign_Medium__c');
            lastTouchVal = heeetGoogleCampaignSource + ' ' + heeetGoogleCampaignMedium;
        }
        return lastTouchVal.trim();
    }

    public static String getFirstTouchLeadSource(sObject newObj, sObject oldObj, String currFirstTouchLeadSource){
        String firstTouchVal = !String.isBlank(currFirstTouchLeadSource) ? currFirstTouchLeadSource : '';
        Boolean validVal = !String.isBlank((String)newObj.get('Heeet__Heeet_First_Click_Campaign_Source__c')) || !String.isBlank((String)newObj.get('Heeet__Heeet_First_Click_Campaign_Medium__c'));
        if(validVal && 
        String.isBlank(currFirstTouchLeadSource) && 
        ((String)newObj.get('Heeet__Heeet_First_Click_Campaign_Source__c') != (String)oldObj.get('Heeet__Heeet_First_Click_Campaign_Source__c') 
            || (String)newObj.get('Heeet__Heeet_First_Click_Campaign_Medium__c') != (String)oldObj.get('Heeet__Heeet_First_Click_Campaign_Medium__c'))
        ){
            String heeetFirstClickCampaignSource = String.isBlank((String)newObj.get('Heeet__Heeet_First_Click_Campaign_Source__c')) ? '' : (String)newObj.get('Heeet__Heeet_First_Click_Campaign_Source__c');
            String heeetFirstClickCampaignMedium = String.isBlank((String)newObj.get('Heeet__Heeet_First_Click_Campaign_Medium__c')) ? '' : (String)newObj.get('Heeet__Heeet_First_Click_Campaign_Medium__c');
            firstTouchVal = heeetFirstClickCampaignSource + ' ' + heeetFirstClickCampaignMedium;
        }
        return firstTouchVal.trim();
    }
}