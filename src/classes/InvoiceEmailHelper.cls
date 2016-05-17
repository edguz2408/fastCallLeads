/*
 Author: Edwin Guzman
 Date: 05/15/2016
*/
public class InvoiceEmailHelper {


    private static Map<Id, List<Contact>> getContacts(List<Id> accountIds){
        Map<Id, List<Contact>> result = new Map<Id, List<Contact>>();

        for(Account acct : [Select Id, (Select Id from contacts where Role__c IN ('billing', 'Primary Contact'))
                            From Account
                            Where Id IN :accountIds
                           ])
        {
            if(!result.containsKey(acct.Id)){
                result.put(acct.Id, acct.contacts);
            }
        }
       return result;
    }

    public static void emailsFactory(List<FastCall_Transaction__c> transactions){

        List<EmailTemplate> template = [Select Id, Subject, Body
                                        From EmailTemplate
                                        Where DeveloperName = 'New_Invoice'];
                                        
        List<EmailWrapper> objs = new List<EmailWrapper>();

        if(!template.isEmpty()){
            List<Id> acctIds = new List<Id>();
            Map<Id, List<Contact>> contacts = new Map<Id, List<Contact>>();

            for(FastCall_Transaction__c trans : transactions){
                acctIds.add(trans.account__c);
            }

            if(!acctIds.isEmpty()){
                contacts = getContacts(acctIds);
                System.debug('Contacts:: ' + contacts);
            }

               for(FastCall_Transaction__c trans : transactions){
                 if(contacts.containsKey(trans.Account__c)){
                     if(!contacts.get(trans.Account__c).isEmpty()){
                         for(contact c : contacts.get(trans.Account__c)){
                             objs.add(new EmailWrapper(c.Id, trans.Id, template[0].Id ));
                         }
                     } else {
                         trans.addError('No Billing/Primary contacts were found for this account');
                     }

                 }
            }

        }

        if(!objs.isEmpty())
            sendEmails(objs);
    }

    private static void sendEmails(List<EmailWrapper> objs){
        List<messaging.SingleEmailMessage> emails = new List<messaging.SingleEmailMessage>();

        for(EmailWrapper em : objs){
            messaging.SingleEmailMessage email = new messaging.SingleEmailMessage();
            email.setTargetObjectId(em.recipientId);
            email.setTemplateId(em.templateId);
            email.setWhatId(em.recordId);
            email.setSaveAsActivity(false);
            emails.add(email);
        }
        System.debug('emails:: ' + emails);
        if(!emails.isEmpty())
            messaging.sendEmail(emails, false);
    }

    public class EmailWrapper {
        public Id recipientId {get; private set;}
        public Id recordId {get; private set;}
        public Id templateId {get; private set;}

        public EmailWrapper(Id recipientId, Id recordId, Id templateId){
            this.recipientId = recipientId;
            this.recordId = recordId;
            this.templateId = templateId;
        }
    }
}