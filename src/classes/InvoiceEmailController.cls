/*
 Author: Edwin Guzman
 Date: 05/15/2016
*/
public class InvoiceEmailController {

    public String transactionId {get; set;}

    private List<FastCall_Invoice__c> getInvoiceInfo(String invoice_Id){
        return ([Select Account__c, Account__r.Name, Total__c, Period_Start__c,
                 Period_End__c, Subscription__r.quantity__c,
                 Subscription__r.plan__r.Name, Subscription__r.plan__r.Interval__c,
                 Account__r.BillingAddress, (Select Success__c from FastCall_Transactions__r)
                 from FastCall_Invoice__c
                 Where Id = :invoice_Id
                 Limit 1
                ]);
    }

    private List<FastCall_Transaction__c> getTransactionInfo(Id transaction_Id){
        return ([Select Id, Invoice__c, Amount__c, Success__c
                 From FastCall_Transaction__c
                 Where Id = :transaction_Id
                 Limit 1]);
    }

    private List<sfLma__License__c> getLicenseInfo(String accountId){
        return([Select sfLma__Licensed_Seats__c, sfLma__Used_Licenses__c
               From sfLma__License__c
               Where sfLma__Account__c = :accountId
               Limit 1]);
    }

    private string getAddressString(System.Address address){
        String result = address.getStreet();

        result += ', ';
        result += address.getCity();
        result += ', ';
        result += address.getState();
        result += ', ';
        result += address.getPostalCode();
        result += ', ';
        result += address.getCountry();

        return result;
    }

    public List<InvoiceWrapper> getResults(){

        List<InvoiceWrapper> result = new List<InvoiceWrapper>();
        List<FastCall_Invoice__c> invoice = new List<FastCall_Invoice__c>();

        List<FastCall_Transaction__c> transact = getTransactionInfo(transactionId);

        if(!transact.isEmpty())
           invoice = getInvoiceInfo(transact[0].Invoice__c);

        if(!invoice.isEmpty()){
           List<sfLma__License__c> license = getLicenseInfo(invoice[0].Account__c);
            if(!license.isEmpty()){
                result.add(new InvoiceWrapper(
                   invoice[0].Period_Start__c != null ? String.valueOf(invoice[0].Period_Start__c).split(' ')[0] : null,
                   invoice[0].Period_End__c != null ? String.valueOf(invoice[0].Period_End__c).split(' ')[0] : null,
                   invoice[0].Account__r.Name,
                   String.valueOf(transact[0].Amount__c),
                   transact[0].success__c == true ? 'Yes' : 'No',
                   invoice[0].Subscription__r.plan__r.Name,
                   invoice[0].Subscription__r.quantity__c != null ? String.valueOf(invoice[0].Subscription__r.quantity__c) : null,
                   invoice[0].Subscription__r.plan__r.Interval__c == 'year' ? 'Annual' :
                   invoice[0].Subscription__r.plan__r.Interval__c == 'month' ? 'Monthly' : '',
                   invoice[0].Account__r.BillingAddress != null ? getAddressString(invoice[0].Account__r.BillingAddress) : null,
                   String.valueOf(license[0].sfLma__Licensed_Seats__c),
                   String.valueOf(license[0].sfLma__Used_Licenses__c)

                ));
            }

        }

        return result;
    }


    public class InvoiceWrapper{

        public String startDate {get; private set;}
        public String endDate {get; private set;}
        public String account {get; private set;}
        public String paidAmount {get; private set;}
        public String success {get; private set;}
        public String plan {get; private set;}
        public String quantity {get; private set;}
        public String period {get; private set;}
        public String billingAddress {get; private set;}
        public String seats {get; private set;}
        public String usedSeats {get; private set;}

        public InvoiceWrapper(String startDate, String endDate, String account, String paidAmount, String success,
                              String plan, String quantity, String period, String billingAddress,
                              String seats, String usedSeats)
        {

            this.startDate = startDate;
            this.endDate = endDate;
            this.account = account;
            this.paidAmount = paidAmount;
            this.success = success;
            this.plan = plan;
            this.quantity = quantity;
            this.period = period;
            this.billingAddress = billingAddress;
            this.seats = seats;
            this.usedSeats = usedSeats;

        }


    }

}