@isTest
public class ContactsHelperTest {
    public static Account getAccount(){
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Stripe_ID__c = 'teststripe'
            
        );
        
        insert testAccount;
        System.assert(testAccount != null, 'Account cannot be null');
        
        return testAccount;
        
    }
    
    static testmethod void shouldCreatePrimaryContact(){
        
        test.startTest();
        
        contact testContact = new Contact();
        testContact.AccountId = getAccount().Id;
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'Test';
        testContact.Role__c = 'Primary Contact';
        
        insert testContact;
        
        test.stopTest();
    }
    
    static testmethod void shouldfailToCreatePrimaryContact(){
        
        test.startTest();
        
        Account acct = getAccount();
        
        contact testContact = new Contact();
        testContact.AccountId = acct.Id;
        testContact.FirstName = 'Test Contact';
        testContact.LastName = 'Test';
        testContact.Role__c = 'Primary Contact';
        
        insert testContact;
        
        contact testContact2 = new Contact();
        testContact2.AccountId = acct.Id;
        testContact2.FirstName = 'Test Contact';
        testContact2.LastName = 'Test';
        testContact2.Role__c = 'Primary Contact';
        
        for(Database.SaveResult r : Database.insert(new List<contact> {testContact2}, false)){
            for(Database.Error err : r.getErrors()){
                System.assertEquals('This account already contains a primary contact', err.getMessage());
            }
        }
        
        test.stopTest();
    }
}