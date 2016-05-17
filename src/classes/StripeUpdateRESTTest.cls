/*
 Author: Edwin Guzman
 Date: 05/16/2016
*/
@isTest
public class StripeUpdateRESTTest {
	public static Account getAccount(){

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
        System.assert(testAccount != null, 'Account cannot be null');

        return testAccount;

    }
    
    public static Account getAccount(String acctName){
        return([Select Id, Stripe_ID__c From Account Where Name =:acctName]);
    }

    public static Product2 getProduct(){
        
        Product2 testProd = New Product2(
            productCode = 'Testprod',
            Name = 'Test Prod'
            
        );
        
        insert testProd;
        System.assert(testProd != null, 'Product cannot be null');
        
        return testProd;
    }
    
    public static Fast_Call_Coupon__c getCoupon(){
        Fast_Call_Coupon__c  result = new Fast_Call_Coupon__c (
            Amount_off__c = 10,
            Coupon_Id__c = 'TestCoupon',
            Currency__c = 'usd'
        );
        insert result;
        
        return result;
    }

    public static void getSubscription(){

  			List<FastCall_Subscription__c> subs = new List<FastCall_Subscription__c>();

            subs.add(new FastCall_Subscription__c(
                Account__c = getAccount().Id,
                plan__c = getProduct().Id,
                Quantity__c = 1,
                Status__c = 'active'
            ));

            insert subs;
        	System.assertEquals(1, subs.size());


    }
    
    public static FastCall_Transaction__c getTransaction(){
        FastCall_Transaction__c result = new FastCall_Transaction__c(
            Account__c = getAccount('Test Account').Id,
            Uuid__c = 'Test Charge',
            Name = 'Test Charge',
            Success__c = true
            
        );
        
        insert result;
        
        FastCall_Transaction__c transactAfter = [Select Id, Account__c From FastCall_Transaction__c 
                                                 Where Account__c = :getAccount('Test Account').Id Limit 1];
        
        System.assertEquals(false, transactAfter == null);
        System.assertEquals(getAccount('Test Account').Id, transactAfter.Account__c);        
        
        return result;
    }
    
    public static FastCall_Transaction__c getTransaction(Id accountId){
        return ([Select Id, Uuid__c From FastCall_Transaction__c Where Account__c = :accountId]);
    }
    
    public static void init(){
        getSubscription();
        
        //Creating custom setting values
        Stripe_Settings__c settings = new Stripe_Settings__c(
        	Stripe_Secret_Live_Key__c = 'TestLiveKey',
            Stripe_Secret_Test_Key__c = 'TestKey'
        );

        insert settings;

    }
    
    public static testmethod void shouldGetCurrentRecord(){

        init();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        
        req.requestURI = sfdcUrl;        
        req.params.put('currentrecord', test_subscription.Id);
        req.params.put('action', 'getCurrentRecord');
        req.httpMethod = 'GET';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.init();

        System.assert(res.responseBody != null); 
        
        

    }
    
    public static testmethod void shouldGetPlans(){

        init();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        
        req.requestURI = sfdcUrl;        
        req.params.put('action', 'getPlan');
        req.httpMethod = 'GET';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.init();

        System.assert(res.responseBody != null); 
        
        

    }
	
    public static testmethod void shouldGetCoupons(){

        init();
        getCoupon();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        
        req.requestURI = sfdcUrl;        
        req.params.put('action', 'getCoupons');
        req.httpMethod = 'GET';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.init();

        System.assert(res.responseBody != null); 
        
        

    }
    
    public static testmethod void shouldGetTransactions(){

        init();
        getTransaction();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        
        req.requestURI = sfdcUrl;        
        req.params.put('action', 'getTransactions');
        req.params.put('account', String.valueOf(getAccount('Test Account').Id));
        req.httpMethod = 'GET';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.init();

        System.assert(res.responseBody != null); 
        
        

    }
    
    public static testmethod void shouldUpdateSubscription(){

        init();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c, Stripe_Subscription_ID__c, Coupon__r.Coupon_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        String couponId = getCoupon().Coupon_Id__c;
        
        req.requestURI = sfdcUrl;        
        req.params.put('subscription', test_subscription.Stripe_Subscription_ID__c);
        req.params.put('product', test_subscription.plan__r.ProductCode);
        req.params.put('action', 'doupdate');
        req.params.put('quantity', String.valueOf(test_subscription.Quantity__c)); 
        req.params.put('transaction', '');  
        req.params.put('coupon', couponId);
        req.params.put('stripe', test_subscription.Stripe_Id__c);
        req.params.put('currentrecord', test_subscription.Id);
        req.params.put('trial', '');
        req.params.put('cancel', ''); 
        req.httpMethod = 'POST';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.initPost();
         
         FastCall_Subscription__c subcriptionAfter = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c, Stripe_Subscription_ID__c, Coupon__r.Coupon_Id__c
                                                      from FastCall_Subscription__c
                                                      where Id = :test_subscription.Id];
         

        System.assertEquals(200, res.statusCode); 
        System.assertEquals(couponId, subcriptionAfter.Coupon_Id__c); 
        
        

    }
    
    public static testmethod void shouldRefundTransaction(){

        init();
        getTransaction();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c, Stripe_Subscription_ID__c, Coupon__r.Coupon_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        String couponId = getCoupon().Coupon_Id__c;
        
        System.assert(getTransaction(getAccount('Test Account').Id) != null, 'transaction cannot be null');
        
        req.requestURI = sfdcUrl;        
        req.params.put('subscription', test_subscription.Stripe_Subscription_ID__c);
        req.params.put('product', test_subscription.plan__r.ProductCode);
        req.params.put('action', 'doupdate');
        req.params.put('quantity', String.valueOf(test_subscription.Quantity__c)); 
        req.params.put('transaction', String.valueOf(getTransaction(getAccount('Test Account').Id).Uuid__c));         
        req.params.put('stripe', test_subscription.Stripe_Id__c);
        req.params.put('currentrecord', test_subscription.Id);        
        
        req.httpMethod = 'POST';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.initPost();
         
        FastCall_Transaction__c transactAfter = [Select Id, Refunded__c 
                                                 From FastCall_Transaction__c 
                                                 Where Account__c = :getAccount('Test Account').Id 
                                                 Limit 1];
        
        
        System.assertEquals(200, res.statusCode); 
        System.assertEquals(true, transactAfter.Refunded__c); 
        
        

    }
    
    public static testmethod void shouldCancelSubscription(){

        init();
        getTransaction();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
         
        FastCall_Subscription__c test_subscription = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c, Stripe_Subscription_ID__c, Coupon__r.Coupon_Id__c
                                                      from FastCall_Subscription__c
                                                      Limit 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/subscriptions/';
        String couponId = getCoupon().Coupon_Id__c;
        
        System.assert(getTransaction(getAccount('Test Account').Id) != null, 'transaction cannot be null');
        
        req.requestURI = sfdcUrl;        
        req.params.put('subscription', test_subscription.Stripe_Subscription_ID__c);        
        req.params.put('action', 'cancelSubscription');                
        req.params.put('stripe', test_subscription.Stripe_Id__c);
        req.params.put('cancelatend', '');
        req.params.put('trial', '');
        req.params.put('currentrecord', test_subscription.Id);        
        
        req.httpMethod = 'GET';
        RestContext.request = req;        
        RestContext.response = res;        
		
        
        StripeUpdateREST.init();
         
         FastCall_Subscription__c subcriptionAfter = [Select Id, Account__c, Quantity__c, 
                                                      Status__c, Trial_end__c, plan__r.ProductCode, Coupon_Id__c,
                                                      Stripe_Id__c, Stripe_Subscription_ID__c, Coupon__r.Coupon_Id__c
                                                      from FastCall_Subscription__c
                                                      where Id = :test_subscription.Id];
        
        
        System.assertEquals(200, res.statusCode); 
        System.assertEquals('canceled', subcriptionAfter.Status__c); 
        
        

    }



}