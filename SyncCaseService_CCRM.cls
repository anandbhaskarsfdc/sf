public with sharing class SyncCaseService_CCRM {

    public static void processCaseChangeEvent(CaseChangeEvent event) {
        try {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            if (header.changeType == 'DELETE') {
                return;
            }
            String recordId = header.recordIds[0];
            System.debug(
                'Received change event for ' +
                header.entityName +
                ' with Id ' + recordId +
                ' for the ' + header.changeType + ' operation.'
            );

            Case newCase = [
                SELECT Id, 
                    ExternalCCRMId_CRMS__c, 
                    ProductId, 
                    CaseNumber, 
                    RecordType.DeveloperName,
                    Parent.CaseNumber,
                    Account.Country_CRMS__c,
                    ParentId,
                    Parent.ExternalCCRMId_CRMS__c
                FROM Case
                WHERE Id = :recordId
            ];
            System.debug('change fields: ' + header.changedFields);

            if (newCase.ExternalCCRMId_CRMS__c == null) {
                return;
            }

            // Get Product's ExternalCRMSId_CCRM__c
            String productExternalId = getProductExternalId(newCase.ProductId);
            String productSiteExternalId = getProductSiteExternalId(newCase.ProductId);

            if (header.changetype == 'UPDATE') {
                processCaseUpdate(event, header, newCase, productExternalId, productSiteExternalId);
            } 
        } catch (Exception e) {
            ApplicationLogHandler_CRMS.trackErrorLog(
                SyncCaseService_CCRM.class.getName(),
                'processCaseChangeEvent',
                e.getLineNumber(),
                e.getTypeName(),
                e.getMessage(),
                e.getStackTraceString()
            );
        }
    }

    private static String getProductExternalId(Id productId) {
        if (productId == null) return null;
        
        List<Product2> products = [
            SELECT ExternalCCRMId_CRMS__c 
            FROM Product2 
            WHERE Id = :productId
        ];

        if (!products.isEmpty()) {
            return products[0].ExternalCCRMId_CRMS__c;
        }
        return null;
    }

    private static String getProductSiteExternalId(Id productId) {
        if (productId == null) return null;
        
        List<Product_Site_CRMS__c> productSites = [
            SELECT ExternalCCRMId_CRMS__c 
            FROM Product_Site_CRMS__c 
            WHERE Product_CRMS__c = :productId AND ExternalCCRMId_CRMS__c != null 
            LIMIT 1
        ];

        if (!productSites.isEmpty()) {
            return productSites[0].ExternalCCRMId_CRMS__c;
        }
        return null;
    }

    private static void processCaseUpdate(CaseChangeEvent event, EventBus.ChangeEventHeader header, Case newCase, String productExternalId, String productSiteExternalId) {
        Map<String, Object> updateFieldToValue = new Map<String, Object>();
        Set<String> skippedFields = new Set<String>{
            'LastModifiedDate',
            'LastModifiedById',
            'ClosedDate',
            'IsClosed',
            'InitialAgent_CRMS__c',
            'CCRMSyncStatus_CRMS__c',
            'ExternalCCRMCaseNumber_CRMS__c',
            'ExternalCCRMId_CRMS__c' // Skip ExternalCCRMId_CRMS__c from updates
        };
        
        for (String field : header.changedFields) {
            if (skippedFields.contains(field)) {
                continue;
            }
            
            Object value;
            Object updateValueObj = event.get(field);
            if (updateValueObj instanceof Datetime) {
                value = ((Datetime)updateValueObj).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            } else if (updateValueObj != null) {
                value = String.valueOf(updateValueObj);
            } else {
                value = null;
            }
            updateFieldToValue.put(field, value);
        }

        if (!updateFieldToValue.isEmpty()) {
            SyncCaseManager_CCRM.updateCase(newCase.ExternalCCRMId_CRMS__c, JSON.serialize(updateFieldToValue));
        }
    }

    public static void processPQCChangeEvent(ProductQualityComplaints_CRMS__ChangeEvent event) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        String recordId = header.recordIds[0];
        System.debug('Received PQC change event for ' + header.entityName + ' with Id ' + recordId + ' for the ' + header.changeType + ' operation.');
        ProductQualityComplaints_CRMS__c pqc = [
            SELECT Id, ExternalCCRMId_CRMS__c, RelatedCase_GxP_CRMS__c,ProductSKU_GxP_CRMS__r.ExternalCCRMId_CRMS__c,ProductSite_GxP_CRMS__r.ExternalCCRMId_CRMS__c
            FROM ProductQualityComplaints_CRMS__c
            WHERE Id = :recordId
        ];
        String productExternalId = pqc.ProductSKU_GxP_CRMS__r.ExternalCCRMId_CRMS__c;
        String productSiteExternalId = pqc.ProductSite_GxP_CRMS__r.ExternalCCRMId_CRMS__c;
        System.debug('productExternalId: ' + productExternalId);
        System.debug('productSiteExternalId: ' + productSiteExternalId);
        System.debug('ExternalCCRMId_CRMS__c: ' + pqc.ExternalCCRMId_CRMS__c);

        if (header.changetype == 'UPDATE') {
            Map<String, Object> updateFieldToValue = new Map<String, Object>();
            for (String field : header.changedFields) {
                if (field == 'LastModifiedDate' || field == 'LastModifiedById') continue;
                Object value;
                if (field == 'ProductSKU_GxP_CRMS__c') {
                    value = productExternalId;
                } else if (field == 'ProductSite_GxP_CRMS__c') {
                    value = productSiteExternalId;
                } else {
                    value = event.get(field);
                    if (value instanceof Datetime) {
                        value = ((Datetime)value).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                    } else if (value instanceof Boolean) {
                        value = (Boolean)value;
                    } else if (value != null) {
                        value = String.valueOf(value);
                    }
                }
                updateFieldToValue.put(field, value);
            }
            SyncCaseManager_CCRM.updatePQC(pqc.ExternalCCRMId_CRMS__c, JSON.serialize(updateFieldToValue));
        }
    }
}