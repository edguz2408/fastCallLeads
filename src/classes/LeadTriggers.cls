/**
 * Gathers all the code used in the Apex triggers.
 *
 * @author Antonio Grassi
 * @date   July 10, 2010
 */
public with sharing class LeadTriggers {
    
    //Phones to add to the LeadPhone__c table when a new Lead is created.
    private static final Set<String> PHONE_FIELDS = new Set<String>{'Phone','MobilePhone'};
    
    // A custom exception class, to help in identifying errors
    public class MyException extends Exception {}

    /**
     * This method is invoked for new Leads, to automatically call'em after being
     * inserted.
     */
    public void processNewLeads(Lead[] leads) {
        try {

            Map<String, Customer> customerMap = new Map<String, Customer>();
            
            LeadWrapper[] positiveLeads = new LeadWrapper[]{};
            
            List<LeadPhone__c> leadPhones = new List<LeadPhone__c>();
            
            for (Lead l:leads) {
                
                LeadWrapper lw = new LeadWrapper(l);
                
                if (!l.DoNotCall && !Util.isNull(PhoneUtils.extractPhoneToDial(lw))) {
                    positiveLeads.add(lw);
                }
                
                Set<String> phonesAdded = new Set<String>();
                
                //We insert a new entry for each different phone in PHONE_FIELDS for that lead. 
                for (String pf: PHONE_FIELDS) {
                    if ((l.get(pf) != null) && (!phonesAdded.contains(String.valueOf(l.get(pf))))) {
                       leadPhones.add(new LeadPhone__c(Name = l.Id, Phone__c = String.valueOf(l.get(pf))));
                       phonesAdded.add(String.valueOf(l.get(pf)));
                    }
                }
            }
            
            if (!leadPhones.isEmpty()) {
                insert leadPhones;
            }         
            
            List<CallProcessAction> actions = CallProcessController.getInstance().initiateDefaultProcess(positiveLeads);
            
            if (!actions.isEmpty()) {
                CallProcessController.getInstance().commitActions(actions);
            }
            
            try {
                
                if (!actions.isEmpty()) {
                   CallProcessController.getInstance().executeImmediateActions(actions, false);
                }
                
            }
            catch (Exception e) {
                System.debug('LeadTriggers::processNewLeads - Exception: ' + e.getMessage());
                
                for (CallProcessAction action: actions) {
                    action.setStatus(CallProcessAction.STATUS_NOT_STARTED);
                }
                
                if (!actions.isEmpty()) {
                    CallProcessController.getInstance().commitActions(actions);
                }
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ERROR - LeadTriggers::processNewLeads() - ' + e.getMessage());
        }
    }
    
    public void leadBeforeInsert(Lead[] leads) {
        addCompanyName(leads);
        fillAndFormatLeadData(leads);
        assignLeadOwner(leads);
        updateOwnerEmail(leads);
        
    }
    
    public void leadBeforeUpdate(Lead[] leads) {
        fillAndFormatLeadData(leads);
        updateOwnerEmail(leads);
    }
    
    private string getCompanyName(String emailStr){
       String rawValue = emailStr.split('@')[1];
       emailStr = rawValue.remove(rawValue.substringAfterLast('.'));
       return emailStr;
        
    }
    
    private void addCompanyName(List<Lead> leads){
        
        for(Lead l : leads){
            if(l.Company.contains('[not provided]')){               
                if(!String.isBlank(l.Email) && !String.isEmpty(l.Email)){
                    l.Company = getCompanyName(l.Email);
                } else if(!String.isEmpty(l.Company_Email__c) && !String.isBlank(l.Company_Email__c)){                
                   l.Company = getCompanyName(l.Company_Email__c);
                } else {
                    l.addError('At least one email must be provided');
                }
            }
        }
    }

    public void removeLeadFromCampaign(Map<Id,Lead> leadsMap) {
        Campaign_Settings__c settings = Campaign_Settings__c.getOrgDefaults();

        if (settings != null && settings.Free_installs_campaign_Id__c != null && 
            settings.Sales_edition_install_campaign_Id__c != null) {

                Set<String> campaignIds = new Set<String> {settings.Free_installs_campaign_Id__c,settings.Sales_edition_install_campaign_Id__c};
                Set<Id> leadsToRemoveFromCampaign = new Set<Id>();
                Set<Id> contactsToRemoveFromCampaign = new Set<Id>();
                List<CampaignMember> membersToRemove = new List<CampaignMember>();

                for (Lead l :leadsMap.values()) {
                    if (!l.IsConverted && l.Status == 'App Uninstalled') {
                        leadsToRemoveFromCampaign.add(l.Id);
                    } 
                    else if (l.IsConverted && l.ConvertedContactId != null) {
                        contactsToRemoveFromCampaign.add(l.ConvertedContactId);
                    } 
                }

                if (leadsToRemoveFromCampaign.size() > 0) {
                    membersToRemove.addAll([SELECT CampaignId, LeadId FROM CampaignMember 
                                            WHERE CampaignId IN :campaignIds 
                                            AND LeadId IN :leadsToRemoveFromCampaign]);
                }

                if (contactsToRemoveFromCampaign.size() > 0) {
                    membersToRemove.addAll([SELECT CampaignId, ContactId FROM CampaignMember 
                                            WHERE CampaignId IN :campaignIds 
                                            AND ContactId IN :contactsToRemoveFromCampaign]);
                }

                if (membersToRemove.size() > 0) {
                    delete membersToRemove;
                } 

        }

    }
    
    /**
     * Prefills new/updated Leads area codes, and formats the Phone field
     */
    private void fillAndFormatLeadData(Lead[] leads) {
        
        Map<String, Lead[]> areaCodeToLeadsMap = new Map<String, Lead[]>();
        
        for (Lead l:leads) {

            String phone = PhoneUtils.extractPhoneToDial(new LeadWrapper(l));
            
            if (phone != null) {
                
                phone = phone.replaceAll('[^0-9]','');
                
                try {
                    String areaCode = phone.length() >= 3 ? phone.substring(0,3) : phone;

                    if (!areaCodeToLeadsMap.containsKey(areaCode)) {
                        areaCodeToLeadsMap.put(areaCode, new Lead[]{});
                    }
                    
                    areaCodeToLeadsMap.get(areaCode).add(l);
                }
                catch (StringException e) {
                    system.debug(LoggingLevel.ERROR, 'Unable to get area code from phone number:' + phone + ':');
                }
            }
            
            //PhoneUtils.cleanPhones(l);
            
        }
        
        Area_Code__c[] areaCodes = [select Name, Time_Zone__c
                                    from Area_Code__c
                                    where name in :areaCodeToLeadsMap.keySet()];
        
        for (Area_Code__c a:areaCodes) {
            
            for (Lead l:areaCodeToLeadsMap.get(a.Name)) {
                l.Time_Zone__c = a.Time_Zone__c;
            }
        }
    }
    
    /**
     * Sets the OwnerId and Customer__c fields, based on the Customer_External_Id__c
     * and ConnectionReceivedId fields.
     */
    private void assignLeadOwner(Lead[] leads) {

        Map<Id, String> userIdToEmailMap = new Map<Id, String>();
        
        Set<String> externalIdList = new Set<String>();
        
        Map<String, Lead[]> externalIdToLeadsMap = new Map<String, Lead[]>();
        Map<String, Lead[]> connectionIdToLeadsMap = new Map<String, Lead[]>();
        
        for (Lead l:leads) {

            if (!Util.isNull(l.Customer_External_ID__c)) {
                
                if (!externalIdToLeadsMap.containsKey(l.Customer_External_ID__c)) {
                    externalIdToLeadsMap.put(l.Customer_External_ID__c, new Lead[]{});
                }
                
                externalIdToLeadsMap.get(l.Customer_External_ID__c).add(l);
            }
            else if (l.ConnectionReceivedId != null || l.ConnectionSentId != null) {

                String connectionId = l.ConnectionReceivedId != null ?
                                      l.ConnectionReceivedId :
                                      l.ConnectionSentId;

                if (connectionId.length() == 18) {
                    connectionId = connectionId.substring(0, 15);
                }
                
                if (!connectionIdToLeadsMap.containsKey(connectionId)) {
                    connectionIdToLeadsMap.put(connectionId, new Lead[]{});
                }

                
                                
                connectionIdToLeadsMap.get(connectionId).add(l);
            }
        }
        
        if (externalIdToLeadsMap.size() > 0) {
            assignLeadOwnerByExternalId(externalIdToLeadsMap);
        }
        
        if (connectionIdToLeadsMap.size() > 0) {
            assignLeadOwnerByConnectionId(connectionIdToLeadsMap);
        }
    }
    
    private void assignLeadOwnerByExternalId(Map<String, Lead[]> externalIdToLeadsMap) {

        for(System_ID__c sid:[select Customer_External_ID__c,
                                     System_ID__c,
                                     Customer__c
                              from System_ID__c
                              where Customer_External_ID__c in:externalIdToLeadsMap.keySet()]) {

            for (Lead l:externalIdToLeadsMap.get(sid.Customer_External_ID__c)) {
                l.Customer__c = sid.Customer__c;
                l.OwnerId = sid.System_ID__c;
            }
        }
    }
    
    private void assignLeadOwnerByConnectionId(Map<String, Lead[]> connectionIdToLeadsMap) {
        
        for (Customer__c c:[select Id,
                                   Connection_Id__c,
                                   (
                                       select System_Id__c
                                       from System_IDs__r
                                   )
                            from Customer__c
                            where Connection_Id__c in :connectionIdToLeadsMap.keySet()]) {

            if (c.System_IDs__r != null && !c.System_IDs__r.isEmpty()) {
                
                for (Lead l:connectionIdToLeadsMap.get(c.Connection_Id__c)) {
                    
                    l.Customer__c = c.Id;
                    l.OwnerId = c.System_IDs__r[0].System_Id__c;
                }
            }
        }
    }
    
    private void updateOwnerEmail(Lead[] leads) {
        Map<Id, Lead[]> ownerIdToLeadsMap = new Map<Id, Lead[]>();
        Set<Id> ownerIds = new Set<Id>();
        
        for (Lead l:leads) {
            
            if (!ownerIdToLeadsMap.containsKey(l.OwnerId)) {
                ownerIdToLeadsMap.put(l.OwnerId, new Lead[]{});
            }
            
            ownerIdToLeadsMap.get(l.OwnerId).add(l);
            ownerIds.add(l.OwnerId);
        }
        
        for (User u:[select Id, Email
                     from User
                     where Id in :ownerIds]) {
        
            for (Lead l:ownerIdToLeadsMap.get(u.Id)) {
                l.OwnerEmail__c = u.Email;
            }

            ownerIdToLeadsMap.remove(u.Id);
        }
        
        for (Lead[] unresolvedLeads:ownerIdToLeadsMap.values()) {
            
            for (Lead l:unresolvedLeads) {
                l.OwnerEmail__c = null;
            }
        }
    }
}