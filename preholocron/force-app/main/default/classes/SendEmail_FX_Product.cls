/*---------------------------------------------------------------
    Author      : Rizki Asriningtyas
    Company     : Xendit
	Unit Test	: OpportunityTest

    <History>
    <Date>      <Authors Name>     <Brief Description of Change>    
	040923		Rizki A				Auto append SE Weekly History
---------------------------------------------------------------*/
public class SendEmail_FX_Product {
    @InvocableVariable
    public string urlOppIds;
    
    @InvocableMethod(label='Send Email to Recipients' description='Send email to specified recipients for opportunities')
    public static void sendEmailToRecipients(List<SendEmail_FX_Product> emailDataList) {
        String toLabel = System.Label.FX_Approver; 
        List<String> recipients = toLabel.split(',');
        
        for (SendEmail_FX_Product emailData : emailDataList) {
            for (String recipient : recipients) {
                String[] recipientParts = recipient.split('@');
                String recipientName = recipientParts[0];
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{recipient});
                email.setSubject('Opportunity Stage Change');
                email.setHtmlBody('Hi ' + recipientName + ',<br><br>' +
                                  'You are receiving this email because an opportunity that consists of FX product is moved to Contracting stage.<br>' +
                                  'You can access the opportunity through this URL: ' + emailData.urlOppIds + '<br><br>' +
                                  'Thanks,<br>Salesforce Admin');
                email.setSenderDisplayName('Xendit - Salesforce System');
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                
                
            }
        }
    }
}