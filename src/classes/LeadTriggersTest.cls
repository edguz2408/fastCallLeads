@isTest
public class LeadTriggersTest {

    /*****************
     * Code coverage *
     *****************/
    
    public static testmethod void test() {
        Lead newLead = new Lead();
        newLead.LastName = 'Rilo';
        newLead.Company = 'Shooger';
        newLead.Customer_External_ID__c = 'Shooger';
        
        insert newLead;
        
        System.debug('#newLead: ' + newLead);
        
        newLead.Phone = '(323) 4561234/345';
        update newLead;
        
        System.debug('#newLead: ' + newLead);
    }
    
    public static testmethod void leadShouldGetCompanyFromEmail(){
        
        test.startTest();
        
        Lead newLead = new Lead();
        newLead.LastName = 'Rilo';
        newLead.Company = '[not provided]';
        newLead.Email = 'test@fastcall.com';
        newLead.Customer_External_ID__c = 'Shooger';
        
        insert newLead;
        
        test.stopTest();
        
        Lead l = [Select company From Lead where Id = :newLead.Id];
        
        System.assertEquals('fastcall.', l.Company);
        
    }
    
    public static testmethod void leadShouldGetCompanyFromCompanyEmail(){
        
        test.startTest();
        
        Lead newLead = new Lead();
        newLead.LastName = 'Rilo';
        newLead.Company = '[not provided]';
        newLead.Company_Email__c = 'test@fastcall.com';
        newLead.Customer_External_ID__c = 'Shooger';
        
        insert newLead;
        
        test.stopTest();
        
        Lead l = [Select company From Lead where Id = :newLead.Id];
        
        System.assertEquals('fastcall.', l.company);
        
    }
    
    public static testmethod void leadShouldFailWhenInsertingLeadsWithoutEmails(){
        
        test.startTest();
        
        Lead newLead = new Lead();
        newLead.LastName = 'Rilo';
        newLead.Company = '[not provided]';        
        newLead.Customer_External_ID__c = 'Shooger';
        
        List<Database.SaveResult> results = Database.insert(new List<Lead> {newLead}, false); 
        
        test.stopTest();
        
        for(Database.SaveResult result : results){
            if(!result.isSuccess()){
                for(Database.Error err : result.getErrors()){
                    System.assertEquals('At least one email must be provided', err.getMessage());
                    break;
                }
            }
        }
        
    }
    
    public static testmethod void testOwnerEmail() {
        List<Lead> leads = new List<Lead>();
        
        Lead lead = new Lead();
        lead.LastName = 'Test';
        lead.Company = 'Test';
        leads.add(lead);
        
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.OwnerEmail__c = 'test@test.com';
        leads.add(lead2);
        
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        
        Lead lead3 = new Lead();
        lead3.LastName = 'Test3';
        lead3.Company = 'Test3';
        lead3.OwnerId = g.Id;
        leads.add(lead3);
              
        String id = Userinfo.getUserId();
        User user = [SELECT Email FROM User WHERE Id =: id LIMIT 1];
        
        Test.startTest();
        
        insert leads;
        
        Lead newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == user.Email);
        
        newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead2.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == user.Email);
        
        newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead3.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == null);
        
        Test.stopTest();
    }
    
    public static testmethod void testUpdateOwnerEmail() {
        List<Lead> leads = new List<Lead>();
        
        Lead lead = new Lead();
        lead.LastName = 'Test';
        lead.Company = 'Test';
        leads.add(lead);
        
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.OwnerEmail__c = 'test@test.com';
        leads.add(lead2);
        
        Lead lead3 = new Lead();
        lead3.LastName = 'Test3';
        lead3.Company = 'Test3';
        leads.add(lead3);
        
        insert leads;
        
        String id = Userinfo.getUserId();
        User user = [SELECT Email FROM User WHERE Id =: id LIMIT 1];
        User user2 = [SELECT Id, Email FROM User WHERE IsActive = true AND (NOT Id =: id) LIMIT 1]; 
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
           
        lead.OwnerEmail__c = 'test@test.com';
        lead2.OwnerId = user2.Id;
        lead3.OwnerId = g.Id;
                
        Test.startTest();
        update leads;
        
        Lead newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == user.Email);
        
        newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead2.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == user2.Email);
        
        newLead = [SELECT Id, OwnerEmail__c FROM Lead WHERE Id =: lead3.Id LIMIT 1];
        System.assert(newLead.OwnerEmail__c == null);
        
        Test.stopTest();
    }
    
    public static testmethod void testSharedLead() {
        
        Customer__c customer = new Customer__c();
        customer.Name = 'TestCustomer';
        customer.Key__c = 'testCustomer';
        customer.Calls_Per_ISR__c = 3;
        insert customer;
        
        List<Lead> leads = new List<Lead>();
        
        Lead lead = new Lead();
        lead.LastName = 'Test';
        lead.Company = 'Test';
        lead.Customer_External_ID__c = customer.Id;
        leads.add(lead);
        
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.Customer__c = customer.Id;
        leads.add(lead2);
        
        Test.startTest();
        insert leads;
        
        lead = [SELECT Customer_External_ID__c, Customer__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
        System.assert(lead.Customer_External_ID__c == customer.Id);
        System.assert(lead.Customer__c == null);
        
        lead2 = [SELECT Id, Customer__c FROM Lead WHERE Id =: lead2.Id LIMIT 1];
        System.assert(lead2.Customer__c == customer.Id);
        
        Test.stopTest();
    }
    
}