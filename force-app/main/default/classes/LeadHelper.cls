public class LeadHelper {

    public static void fileProcessor(Set<Id> leadIds, Set<Id> fileIds) {
        if (leadIds.isEmpty()) return;
        //test updated
        Map<Id, ContentDocumentLink> leadToFileMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId,
            LinkedEntityId,
            ContentDocument.LatestPublishedVersion.VersionData
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :fileIds
        ]) {
            leadToFileMap.put(cdl.LinkedEntityId, cdl);
        }
        
        Map<String, Account> nameToAccountMap = new Map<String, Account>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        
        for (Lead l : [SELECT Id, Email FROM Lead WHERE Id IN :leadIds]) {
            if (!leadToFileMap.containsKey(l.Id)) {
                continue;
            }
            
            ContentDocumentLink cdl = leadToFileMap.get(l.Id);
            String fileBody = cdl.ContentDocument.LatestPublishedVersion.VersionData.toString();
            List<String> lines = fileBody.split('\n');
            
            String fromName;
            Datetime gfxSent;
            String trader;
            Decimal price;
            Decimal totalPrice;
            Date settlementDate;
            Date maturityDate;
            
            for (String line : lines) {
                line = line.trim();
                
                if (line.startsWith('From')) {
                    fromName = line.substringAfter(':').trim();
                }
                else if (line.startsWith('Sent')) {
                    String str = line.substringAfter(':').trim();
                    String rawVal = str.substringBefore('UTC').trim();
                    
                    List<String> parts = rawVal.split(' ');
                    Date datePart = parseDate(parts[0]);
                    
                    Integer month = datePart.month();
                    Integer day   = datePart.day();
                    Integer year  = datePart.year();
                    
                    String timePart = parts[1];
                    List<String> timeTokens = timePart.split(':');
                    Integer hour = Integer.valueOf(timeTokens[0]);
                    Integer minute = Integer.valueOf(timeTokens[1]);
                    
                    gfxSent = DateTime.newInstanceGmt(year, month, day, hour, minute, 0);
                }
                else if (line.startsWith('Trader')) {
                    String str = line.substringAfter(':').trim();
                    trader = str.substringBefore('ISIN').trim();
                }
                else if (line.startsWith('Price')) {
                    String str = line.substringAfter(':').trim();
                    price = Decimal.valueOf(str.substringBefore('Maturity').trim());
                    String dateval = line.substringAfter('Maturity').replace(':', '').trim();
                    maturityDate = parseDate(dateval);
                }
                else if (line.startsWith('Settlement')) {
                    String str = line.substringAfter(':').trim();
                    String dateVal = str.substringBefore('Venue').trim();
                    settlementDate = parseDate(dateVal);
                }
                else if (line.startsWith('** T')) {
                    String str = line.substringAfter('USD').trim();
                    totalPrice = Decimal.valueOf(str.substringBefore('*').trim().replace(',',''));
                }
            }

            if (fromName != null) {
                if (!nameToAccountMap.containsKey(fromName)) {
                    List<Account> accList = [
                        SELECT Id, Name
                        FROM Account
                        WHERE Name = :fromName
                        LIMIT 1
                    ];
                    if (!accList.isEmpty()) {
                        nameToAccountMap.put(fromName, accList[0]);
                    }
                }
                
                if (nameToAccountMap.containsKey(fromName)) {
                    Account accToUpdate = nameToAccountMap.get(fromName);
                    accToUpdate.GFX_Sent__c    = gfxSent;
                    accToUpdate.Trader__c      = trader;
                    accToUpdate.Price__c       = price;
                    accToUpdate.Total_Price__c = totalPrice;
                    accToUpdate.Maturity__c    = maturityDate;
                    accToUpdate.Settlement__c  = settlementDate;
                    
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(l.Id);
                    lc.setAccountId(accToUpdate.Id);
                    lc.setConvertedStatus('Closed - Converted');
                    
                    List<Contact> conList = [
                        SELECT Id, Email 
                        FROM Contact 
                        WHERE AccountId = :accToUpdate.Id 
                        AND Email = :l.Email 
                        LIMIT 1
                    ];
                    
                    if (!conList.isEmpty()) {
                        lc.setContactId(conList[0].Id);
                    }
                    
                    leadsToConvert.add(lc);
                    
                    if(!accountsToUpdate.contains(accToUpdate))
                    {
                        accountsToUpdate.add(accToUpdate);
                    }
                }
            }
        }
        
        System.debug('Accounts to update: ' + accountsToUpdate);
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        if (!leadsToConvert.isEmpty()) {
            List<Database.LeadConvertResult> results = Database.convertLead(leadsToConvert, false);
            
            for (Database.LeadConvertResult res : results) {
                if (!res.isSuccess()) {
                    System.debug('Lead conversion failed for LeadId: ' + res.getLeadId() + ', Msg: ' + res.getErrors()[0].getMessage());
                }
            }
        }
    }
    
    public static Date parseDate(String dateStrVal) {
        List<String> dateTokens = dateStrVal.split('/');
        Integer month = Integer.valueOf(dateTokens[0]);
        Integer day   = Integer.valueOf(dateTokens[1]);
        Integer year  = Integer.valueOf(dateTokens[2]);
        if (year < 100) {
            year += 2000;
        }
        return Date.newInstance(year, month, day);
    }
}
