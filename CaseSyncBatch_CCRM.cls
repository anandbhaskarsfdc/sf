public class CaseSyncBatch_CCRM implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private Integer successCount = 0;
    private Integer failureCount = 0;
    private List<String> errors = new List<String>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT ' + String.join(CaseChangeEventWrapper_CCRM.CASE_SYNC_FIELDS, ', ') 
                     + ' FROM Case '
                     + ' WHERE CCRMSyncStatus_CRMS__c = \'Failed\' '
                     + ' AND RecordType.DeveloperName IN (\'ProductQualityComplaint_CRMS\', \'Medical_Inquiry_CRMS\', \'Interaction_CRMS\')';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        for (Case caseRecord : scope) {
            try {
                String productExternalId = getProductExternalId(caseRecord.ProductId);
                
                CaseChangeEventWrapper_CCRM wrapper = new CaseChangeEventWrapper_CCRM(caseRecord, productExternalId);
                
                //Map<String, Object> body = SyncCaseService_CCRM.buildCaseCompositeBody(wrapper);
                
                if (!String.isBlank(caseRecord.ExternalCCRMId_CRMS__c)) {
                //    SyncCaseManager_CCRM.createCaseInternal(JSON.serialize(body), caseRecord.Id);
                    Map<String, Object> updateFieldToValue = buildUpdateFieldMap(wrapper);
                    SyncCaseManager_CCRM.updateCaseInternal(caseRecord.ExternalCCRMId_CRMS__c, JSON.serialize(updateFieldToValue));
                
                }// else {
                  //  Map<String, Object> updateFieldToValue = buildUpdateFieldMap(wrapper);
                  //  SyncCaseManager_CCRM.updateCaseInternal(caseRecord.ExternalCCRMId_CRMS__c, JSON.serialize(updateFieldToValue));
                //}
                
                successCount++;
            } catch (Exception e) {
                failureCount++;
                String errorMsg = 'Error processing Case ' + caseRecord.Id + ': ' + e.getMessage() + ' at line ' + e.getLineNumber();
                errors.add(errorMsg);
                
                ApplicationLogHandler_CRMS.trackErrorLog(
                    CaseSyncBatch_CCRM.class.getName(),
                    'execute',
                    e.getLineNumber(),
                    e.getTypeName(),
                    e.getMessage(),
                    e.getStackTraceString()
                );
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Case Sync Batch Job Completed: ' + successCount + ' success, ' + failureCount + ' failure'+' '+errors);
    }
    
    private String getProductExternalId(Id productId) {
        if (productId == null) return null;
        
        Product2 product = [
            SELECT ExternalCCRMId_CRMS__c 
            FROM Product2 
            WHERE Id = :productId
            LIMIT 1
        ];
        return product != null ? product.ExternalCCRMId_CRMS__c : null;
    }
    
    @TestVisible
    private Map<String, Object> buildUpdateFieldMap(CaseChangeEventWrapper_CCRM wrapper) {
        Map<String, Object> updateFieldToValue = new Map<String, Object>();
        
        if (wrapper.Origin != null) updateFieldToValue.put('Origin', wrapper.Origin);
        if (wrapper.Status != null) updateFieldToValue.put('Status', wrapper.Status);
        if (wrapper.Priority != null) updateFieldToValue.put('Priority', wrapper.Priority);
        if (wrapper.Type != null) updateFieldToValue.put('Type', wrapper.Type);
        if (wrapper.PQCStatus != null) updateFieldToValue.put('PQCStatus_CRMS__c', wrapper.PQCStatus);
        if (wrapper.NLPJobStatus != null) updateFieldToValue.put('NLP_JobStatus_CRMS__c', wrapper.NLPJobStatus);
        if (wrapper.NLPReasonCodeChangedByAgent != null) updateFieldToValue.put('NLP_ReasonCodeChangedByAgent_CRMS__c', wrapper.NLPReasonCodeChangedByAgent);
        if (wrapper.Tier1 != null) updateFieldToValue.put('Tier1_CRMS__c', wrapper.Tier1);
        if (wrapper.ArgusStatus != null) updateFieldToValue.put('ArgusStatus_CRMS__c', wrapper.ArgusStatus);
        if (wrapper.Tier3 != null) updateFieldToValue.put('Tier3_CRMS__c', wrapper.Tier3);
        if (wrapper.Country != null) updateFieldToValue.put('Country_CRMS__c', wrapper.Country);
        if (wrapper.Keywords != null) updateFieldToValue.put('Keywords_CRMS__c', wrapper.Keywords);
        if (wrapper.PredictedPriority != null) updateFieldToValue.put('PredictedPriority_CRMS__c', wrapper.PredictedPriority);
        if (wrapper.RoutingPriority != null) updateFieldToValue.put('Routing_Priority_CRMS__c', wrapper.RoutingPriority);
        if (wrapper.Tier2 != null) updateFieldToValue.put('Tier2_CRMS__c', wrapper.Tier2);
        if (wrapper.ProductId != null) updateFieldToValue.put('ProductId', wrapper.ProductId);
        if (wrapper.RecordTypeId != null) updateFieldToValue.put('RecordTypeId', wrapper.RecordTypeId);
        if (wrapper.ParentId != null) updateFieldToValue.put('ParentId', wrapper.ParentId);
        if (wrapper.Subject != null) updateFieldToValue.put('Subject', wrapper.Subject);
        if (wrapper.Description != null) updateFieldToValue.put('Description', wrapper.Description);
        
        return updateFieldToValue;
    }
    

    
    public static String scheduleBatch(String cronExp) {
        CaseSyncBatch_CCRM batch = new CaseSyncBatch_CCRM();
        return System.scheduleBatch(batch, 'Case Sync Batch ' + System.now(), 100, 10);
    }
}