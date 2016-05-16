trigger TransactionTriggers on recurly__Transaction__c (before insert, before update) {
	
	Set<recurly__Transaction__c> transactionsToLink = new Set<recurly__Transaction__c>{};
	Set<String> stripeIds = new Set<String>{};
	
	for (recurly__Transaction__c t:Trigger.new) {
		
		if (t.Stripe_Customer_ID__c != null &&
			(Trigger.isInsert || (Trigger.oldMap.get(t.Id).Stripe_Customer_ID__c != t.Stripe_Customer_ID__c))) {
			
			transactionsToLink.add(t);
			stripeIds.add(t.Stripe_Customer_ID__c);
		}
	}
	
	if (!transactionsToLink.isEmpty()) {
		
		Map<String, Id> stripeToSFDCMap = new Map<String, Id>{};
		
		for (Account a:[select Id, Stripe_ID__c from Account where Stripe_ID__c in :stripeIds]) {
			stripeToSFDCMap.put(a.Stripe_ID__c, a.Id);
		}
		
		for (recurly__Transaction__c t:transactionsToLink) {
			if (stripeToSFDCMap.containsKey(t.Stripe_Customer_ID__c)) {
				t.recurly__Account__c = stripeToSFDCMap.get(t.Stripe_Customer_ID__c);
			}
		}
	}
}