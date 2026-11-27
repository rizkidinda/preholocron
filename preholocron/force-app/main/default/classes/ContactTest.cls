@isTest
public class ContactTest {
    @isTest
    static void updateLastTouch() {
        Test.startTest();
        UTM_Category_and_Category_Group_Mapping__c mapping = new UTM_Category_and_Category_Group_Mapping__c();
        mapping.Source_Vendor_Partner__c = 'google';
        mapping.Medium_Campaign__c = 'organic';
        mapping.UTM_Category__c = 'Google Organic Search';
        mapping.UTM_Category_Group__c = 'Organic/Direct';
        insert mapping;
        
        UTM_Category_and_Category_Group_Mapping__c mapping2 = new UTM_Category_and_Category_Group_Mapping__c();
        mapping2.Source_Vendor_Partner__c = 'xxx [partner/vendor_name]';
        mapping2.Medium_Campaign__c = 'merchant_referral';
        mapping2.UTM_Category__c = 'Merchant Referral';
        mapping2.UTM_Category_Group__c = 'Referral';
        mapping2.IsPartner__c = TRUE;
        insert mapping2;
        
        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe'
        );
        insert contact;
        
        Contact updateContact = new Contact(Id = contact.id,Heeet__Heeet_Google_Campaign_Source__c = 'google',Heeet__Heeet_Google_Campaign_Medium__c = 'organic');
        update updateContact;
        
        Contact updateContact2 = new Contact(Id = contact.id,Heeet__Heeet_Google_Campaign_Source__c = 'ABC',Heeet__Heeet_Google_Campaign_Medium__c = 'merchant_referral');
        update updateContact2;
        
        Test.stopTest();
    }
}