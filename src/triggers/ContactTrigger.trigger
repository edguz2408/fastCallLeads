/**
 *  Associates Contacts shared over S2S with the customer's account.
 *
 * @author Antonio Grassi
 * @date   02/11/2012
 */
trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {

    S2S_ContactSync.syncNewContacts(Trigger.new);

    if(trigger.isAfter && trigger.isInsert){
        if(trigger.new[0].Role__c == 'Primary Contact'){
             contactsHelper.updateInfo(trigger.new[0].AccountId);
         }
    }

}