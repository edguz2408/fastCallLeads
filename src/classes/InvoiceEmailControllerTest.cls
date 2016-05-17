/*
 Author: Edwin Guzman
 Date: 05/16/2016
*/
@istest
public class InvoiceEmailControllerTest {

    public static FastCall_Transaction__c getTransaction(){
                
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCity = 'Test City',
            BillingCountry = 'USA',
            BillingState = 'FL',
            BillingStreet = '123 st',
            BillingPostalCode = '10545'
        );
        
        insert testAccount;
        
        contact testContact = new contact();
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'Test';
        testContact.LastName = 'Test';
        testContact.Email = 'test@fc.com';
        testContact.Role__c = 'Primary Contact';
        
        insert testContact;
        
        sfLma__License__c testLicense = new sfLma__License__c();
        testLicense.sfLma__Used_Licenses__c = 2;
        testLicense.sfLma__Account__c = testAccount.Id;
        
        insert testLicense;
        
        Product2 testPlan = new Product2();
        testPlan.Interval__c = 'month';
        testPlan.Name = 'Test Product';
        testPlan.ProductCode = 'Test Product';
        
        insert testPlan;
        
        FastCall_Subscription__c testSubscription = new FastCall_Subscription__c(
            Name = 'Test Subscription',
            Account__c = testAccount.Id,
            plan__c = testPlan.Id,
            quantity__c = 1
        );
        
        insert testSubscription;
        
        FastCall_Invoice__c testInvoice = new FastCall_Invoice__c();
        testInvoice.Account__c = testAccount.Id;
        testInvoice.Subscription__c = testSubscription.Id;
        testInvoice.Period_Start__c = datetime.now();
        testInvoice.Period_End__c = datetime.now().addDays(1);
        
        insert testInvoice;
        
        FastCall_Transaction__c testTransaction = new FastCall_Transaction__c();
        testTransaction.Account__c = testAccount.Id;
        testTransaction.Invoice__c = testInvoice.Id;
        testTransaction.Success__c = true;
        testTransaction.Amount__c = 500;
        
        insert testTransaction;
        
        return testTransaction;
            
    }
    
    public static testmethod void shouldGetFullResults(){
        
        test.startTest();
        
        InvoiceEmailController controller = new InvoiceEmailController();
        controller.transactionId = getTransaction().Id;
        
        test.stopTest();
        
        System.assert(controller.getResults().isEmpty() == false);
        
    }
}