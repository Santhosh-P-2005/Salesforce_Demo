public class LeadHandler {
    
    public static void afterUpdate(List<Lead> newList, Map<Id, Lead> oldMap)
    {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> fileIds = new Set<Id>();
        
        for(Lead l : newList)
        {
            for(ContentDocumentLink file : [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersion.FileExtension
                                            FROM ContentDocumentLink WHERE LinkedEntityId = :l.Id])
            {
                String fileName = file.ContentDocument.Title;
                String extension = file.ContentDocument.LatestPublishedVersion.FileExtension;
                
                if (!oldMap.get(l.Id).Process_GFX_File__c && l.Process_GFX_File__c && fileName.toUpperCase().contains('GFX') && extension.equalsIgnoreCase('txt'))
                {
                    leadIds.add(l.Id);
                    fileIds.add(file.ContentDocumentId);
                }
            }
        }
        
        LeadHelper.fileProcessor(leadIds, fileIds);
    }
}