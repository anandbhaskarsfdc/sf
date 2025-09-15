@@ -0,0 +1,207 @@
public with sharing class SyncCaseService_CCRM {
    // Custom exception for CRMS integration errors
    public class CRMSIntegrationException extends Exception {}
    
    public static void processCaseChangeEvent(CaseChangeEvent event) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        String recordId = header.recordIds[0];
        System.debug(
            'Received change event for ' +
            header.entityName +
            ' with Id ' + recordId +
            ' for the ' + header.changeType + ' operation.'
        );

        Case newCase = [
            SELECT Id, ExternalCRMSId_CCRM__c, ProductId, CaseNumber
            FROM Case
            WHERE Id = :recordId
        ];
        System.debug('ExternalCRMSId_CCRM__c: ' + newCase.ExternalCRMSId_CCRM__c);

        // Get Product's ExternalCRMSId_CCRM__c
        String productExternalId = getProductExternalId(newCase.ProductId);
        String productSiteExternalId = getProductSiteExternalId(newCase.ProductId);

        if (header.changetype == 'UPDATE') {
            processCaseUpdate(event, header, newCase, productExternalId, productSiteExternalId);
        } else if (header.changetype == 'CREATE') {
            processCaseCreate(event, newCase, productExternalId);
        }
    }

    private static String getProductExternalId(Id productId) {
        if (productId == null) return null;
        
        Product2 product = [
            SELECT ExternalCRMSId_CCRM__c 
            FROM Product2 
            WHERE Id = :productId
        ];
        return product.ExternalCRMSId_CCRM__c;
    }

    private static String getProductSiteExternalId(Id productId) {
        if (productId == null) return null;
        
        Product_Site_CRMS__c productSite = [
            SELECT ExternalCRMSId_CCRM__c 
            FROM Product_Site_CRMS__c 
            WHERE Product_CRMS__c = :productId AND ExternalCRMSId_CCRM__c != null 
            LIMIT 1
        ];
        return productSite.ExternalCRMSId_CCRM__c;
    }

    private static void processCaseUpdate(CaseChangeEvent event, EventBus.ChangeEventHeader header, Case newCase, String productExternalId, String productSiteExternalId) {
        Map<String, Object> updateFieldToValue = new Map<String, Object>();
        
        for (String field : header.changedFields) {
            if (field == 'LastModifiedDate') continue;

            String updateValue = (String)event.get(field);
            if (updateValue == null) {
                System.debug('Deleted field value (set to null): ' + field);
            } else {
                System.debug(
                    'Changed field value: ' + field 
                    + '. New Value: ' + updateValue
                );
            }
            updateFieldToValue.put(field, updateValue);
        }

        if (!updateFieldToValue.isEmpty()) {
            SyncCaseManager_CCRM.updateCase(newCase.ExternalCRMSId_CCRM__c, JSON.serialize(updateFieldToValue));
        }

        if (updateFieldToValue.containsKey('ExternalCRMSId_CCRM__c') && newCase.ExternalCRMSId_CCRM__c != null) {
            processRelatedPQCCreate(newCase.Id, newCase.ExternalCRMSId_CCRM__c, productExternalId, productSiteExternalId);
        }
    }

    private static void processCaseCreate(CaseChangeEvent event, Case newCase, String productExternalId) {
        try {
            CaseChangeEventWrapper_CCRM wrapper = new CaseChangeEventWrapper_CCRM(event, productExternalId, newCase.Id, newCase.CaseNumber);
            System.debug('Extracted Case fields: ' + JSON.serialize(wrapper));
            SyncCaseManager_CCRM.createCase(JSON.serialize(buildCaseCompositeBody(wrapper)), newCase.Id);
        } catch (Exception e) {
            System.debug('Error processing CaseChangeEvent: ' + e.getMessage());
        }
    }

    private static void processRelatedPQCCreate(Id caseId, String externalCRMSId, String productExternalId, String productSiteExternalId) {
        List<ProductQualityComplaints_CRMS__c> pqcs = [
            SELECT Id, Name, QuantityOfProduct_GxP_CRMS__c, DidConsumerAgreeToReturnSample_GxP_CRMS__c,
                   Reason_Code_L3_GxP_CRMS__c, Verbatim_GxP_CRMS__c, Reason_Code_L1_GxP_CRMS__c,
                   Reason_Code_L2_GxP_CRMS__c, SitesCount_CRMS__c, PrimaryPackageLot_GxP_CRMS__c,
                   HSIAE_CRMS__c
            FROM ProductQualityComplaints_CRMS__c 
            WHERE RelatedCase_GxP_CRMS__c = :caseId
        ];
        
        if (!pqcs.isEmpty()) {
            for (ProductQualityComplaints_CRMS__c pqc : pqcs) {
                PQCChangeEventWrapper_CCRM pqcWrapper = new PQCChangeEventWrapper_CCRM();
                pqcWrapper.QuantityOfProduct_GxP_CRMS = pqc.QuantityOfProduct_GxP_CRMS__c;
                pqcWrapper.DidConsumerAgreeToReturnSample_GxP_CRMS = pqc.DidConsumerAgreeToReturnSample_GxP_CRMS__c;
                pqcWrapper.Reason_Code_L3_GxP_CRMS = pqc.Reason_Code_L3_GxP_CRMS__c;
                pqcWrapper.Verbatim_GxP_CRMS = pqc.Verbatim_GxP_CRMS__c;
                pqcWrapper.Reason_Code_L1_GxP_CRMS = pqc.Reason_Code_L1_GxP_CRMS__c;
                pqcWrapper.Reason_Code_L2_GxP_CRMS = pqc.Reason_Code_L2_GxP_CRMS__c;
                pqcWrapper.SitesCount_CRMS = pqc.SitesCount_CRMS__c;
                pqcWrapper.PrimaryPackageLot_GxP_CRMS = pqc.PrimaryPackageLot_GxP_CRMS__c;
                pqcWrapper.HSIAE_CRMS = pqc.HSIAE_CRMS__c;
                pqcWrapper.RelatedCase_GxP_CRMS = externalCRMSId;
                pqcWrapper.ExternalCCRMId = pqc.Id;
                pqcWrapper.ProductSite_GxP_CRMS = productSiteExternalId;
                pqcWrapper.ProductSKU_GxP_CRMS = productExternalId;
                pqcWrapper.Country_GxP_CRMS = 'CN'; 
                System.debug('@@@@@PQC'+JSON.serialize(pqcWrapper));
                SyncCaseManager_CCRM.createPQC(JSON.serialize(buildPQCCompositeBody(pqcWrapper)), pqc.Id);
            }
        }
    }

    public static Map<String, Object> buildCaseCompositeBody(CaseChangeEventWrapper_CCRM wrapper) {
        return new Map<String, Object>{
            'allOrNone' => false,
            'records' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'attributes' => new Map<String, String>{ 'type' => 'Case' },
                    'Origin' => wrapper.Origin,
                    'Status' => wrapper.Status,
                    'Priority' => wrapper.Priority,
                    'Type' => wrapper.Type,
                    'PQCStatus_CRMS__c' => wrapper.PQCStatus,
                    'NLP_JobStatus_CRMS__c' => wrapper.NLPJobStatus,
                    'NLP_ReasonCodeChangedByAgent_CRMS__c' => wrapper.NLPReasonCodeChangedByAgent,
                    'Tier1_CRMS__c' => wrapper.Tier1,
                    'ArgusStatus_CRMS__c' => wrapper.ArgusStatus,
                    'Tier3_CRMS__c' => wrapper.Tier3,
                    'Country_CRMS__c' => wrapper.Country,
                    'Keywords_CRMS__c' => wrapper.Keywords,
                    'PredictedPriority_CRMS__c' => wrapper.PredictedPriority,
                    'Routing_Priority_CRMS__c' => wrapper.RoutingPriority,
                    'Tier2_CRMS__c' => wrapper.Tier2,
                    'ProductId' => wrapper.ProductId,
                    'RecordTypeId' => wrapper.RecordTypeId,
                    'AccountId' => wrapper.AccountId,
                    'ExternalCCRMId_CRMS__c' => wrapper.ExternalCRMSId,
                    'ExternalCCRMCaseNumber_CRMS__c' => wrapper.ExternalCRMSCaseNumber,
                    'InvestigationMinsAccrued_CRMS__c' => wrapper.InvestigationMinsAccrued,
                    'TimesReOpened_CRMS__c' => wrapper.TimesReOpened,
                    'ExtensionOfCompletedInvMilestones_CRMS__c' => wrapper.ExtensionOfCompletedInvMilestones,
                    'CurrentMilestoneDuration_CRMS__c' => wrapper.CurrentMilestoneDuration,
                    'AccumulatedInvestigationsTime_CRMS__c' => wrapper.AccumulatedInvestigationsTime
                }
            }
        };
    }

    public static Map<String, Object> buildPQCCompositeBody(PQCChangeEventWrapper_CCRM wrapper) {
        return new Map<String, Object>{
            'allOrNone' => false,
            'records' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'attributes' => new Map<String, String>{ 'type' => 'ProductQualityComplaints_CRMS__c' },
                    'QuantityOfProduct_GxP_CRMS__c' => wrapper.QuantityOfProduct_GxP_CRMS,
                    'DidConsumerAgreeToReturnSample_GxP_CRMS__c' => wrapper.DidConsumerAgreeToReturnSample_GxP_CRMS,
                    'Reason_Code_L3_GxP_CRMS__c' => wrapper.Reason_Code_L3_GxP_CRMS,
                    'Verbatim_GxP_CRMS__c' => wrapper.Verbatim_GxP_CRMS,
                    'Reason_Code_L1_GxP_CRMS__c' => wrapper.Reason_Code_L1_GxP_CRMS,
                    'Reason_Code_L2_GxP_CRMS__c' => wrapper.Reason_Code_L2_GxP_CRMS,
                    'SitesCount_CRMS__c' => wrapper.SitesCount_CRMS,
                    'PrimaryPackageLot_GxP_CRMS__c' => wrapper.PrimaryPackageLot_GxP_CRMS,
                    'HSIAE_CRMS__c' => wrapper.HSIAE_CRMS,
                    'RelatedCase_GxP_CRMS__c' => wrapper.RelatedCase_GxP_CRMS,
                    'ExternalCCRMId_CRMS__c' => wrapper.ExternalCCRMId,
                    'ProductSite_GxP_CRMS__c' => wrapper.ProductSite_GxP_CRMS,
                    'ProductSKU_GxP_CRMS__c' => wrapper.ProductSKU_GxP_CRMS,
                    'Country_GxP_CRMS__c' => wrapper.Country_GxP_CRMS
                }
            }
        };
    }

    public static void processPQCChangeEvent(ProductQualityComplaints_CRMS__ChangeEvent event) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        String recordId = header.recordIds[0];
        System.debug('Received PQC change event for ' + header.entityName + ' with Id ' + recordId + ' for the ' + header.changeType + ' operation.');
        ProductQualityComplaints_CRMS__c pqc = [
            SELECT Id, ExternalCRMSId_CCRM__c, RelatedCase_GxP_CRMS__c
            FROM ProductQualityComplaints_CRMS__c
            WHERE Id = :recordId
        ];
        System.debug('ExternalCRMSId_CCRM__c: ' + pqc.ExternalCRMSId_CCRM__c);

        if (header.changetype == 'UPDATE') {
            Map<String, Object> updateFieldToValue = new Map<String, Object>();
            for (String field : header.changedFields) {
                if (field == 'LastModifiedDate' || field == 'LastModifiedById') continue;
                updateFieldToValue.put(field, (String)event.get(field));
            }
            SyncCaseManager_CCRM.updatePQC(pqc.ExternalCRMSId_CCRM__c, JSON.serialize(updateFieldToValue));
        }
    }
}