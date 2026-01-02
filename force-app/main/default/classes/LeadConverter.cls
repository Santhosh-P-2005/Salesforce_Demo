public class LeadConverter {
    
    public static void convertLead(Id leadId)
    {
        //Added for testing
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setAccountId('001IT00002zcGn7YAE');
        lc.setContactId('003IT00002pMLOtYAO');
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult res = Database.convertLead(lc);
        
        System.debug('Attached Account Id: ' + res.getAccountId());
        System.debug('Attached Contact Id: ' + res.getContactId());
        
    }
}
