/*
Author: Edwin Guzman
Date: 05/02/2016
*/
public class ContactsHelper {
    
    final static String APIURL = ((Stripe_Urls__c.getValues('Customers') != null) ?
                                  Stripe_Urls__c.getValues('Customers').url__c : null);
    final static String APIKEY = 'sk_test_4fWfSKnU5DhEw5QGqkOgqRz2';
    //final static String APIKEY = StripeAPI.ApiKey;
    
    private static Account getAccount(Id acctId){
        return([select Id, Name, Stripe_ID__c From Account Where Id = :acctId Limit 1][0]);        
    }
    
    public static boolean checkContainsPrimaryContact(Id accountId){
        return ([Select Id 
                 From Contact 
                 Where AccountId = :accountId
                 and Role__c = 'Primary Contact' ].size() > 0);
    }
    
    @future(callout=true)
    public static void updateInfo(String acctId){
        
        Account acct = getAccount(acctId);
        
        if(acct != null){
            String customerId = acct.Stripe_ID__c;
            String email = acct.Name;
            
            String data = 'email=';
            data += email;
            
            HttpResponse response;
            
            if(!test.isRunningTest()){
                response = StripeHttpHelper.makeHttpCall(
                    new StripeHttpHelper.HttpWrapper(
                        APIURL,
                        APIKEY,
                        data,
                        customerId,
                        'POST'));
            } else {
                response = new HttpResponse ();
                response.setStatusCode(200);
            }
        }
        
        
    }
    
}