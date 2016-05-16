trigger TransactionAfter on FastCall_Transaction__c (after insert) {
    InvoiceEmailHelper.emailsFactory(trigger.new);
}