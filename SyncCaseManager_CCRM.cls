public with sharing class SyncCaseManager_CCRM {
    private static final String NAMED_CREDENTIAL = 'CRMS_Integration';
    private static final String GRANT_TYPE = '?grant_type=client_credentials';

    private static String getAccessToken() {
        try {
            HTTPResponse response = new NamedCredentialCallout_CRMS(NAMED_CREDENTIAL, GRANT_TYPE).post();
            
            System.debug('Status Code: ' + response.getStatusCode());
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String accessToken = (String)m.get('access_token');
            return accessToken;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new SyncCaseService_CCRM.CRMSIntegrationException('Error in getAccessToken: ' + e.getMessage());
        }
    }

    @future (callout=true)
    public static void updateCase(String externalId, String updateFieldToValueJSON) {
        if (String.isBlank(externalId) || String.isBlank(updateFieldToValueJSON)) {
            System.debug(
                logginglevel.WARN,
                String.format(
                    'externalId/updateFieldToValueJSON: {0} is missing data, not synced', 
                    new List<Object>{externalId, updateFieldToValueJSON}
                )
            );
            return;
        }

        try {
            CRMS_Integration_Setting__c settings = CRMS_Integration_Setting__c.getInstance();
            String accessToken = getAccessToken();

            Http h2 = new Http();
            HttpRequest req2 = new HttpRequest();
            req2.setEndpoint(settings.Base_URL__c + '/services/data/' + settings.API_Version__c + '/sobjects/Case/' + externalId);
            req2.setHeader('Content-Type', 'application/json');
            req2.setHeader('Authorization', 'Bearer ' + accessToken);
            req2.setMethod('PATCH');
            System.debug('updateFieldToValueJSON: ' + updateFieldToValueJSON);
            req2.setBody(updateFieldToValueJSON);
            
            HttpResponse res2 = h2.send(req2);
            System.debug('res2.getStatusCode: ' + res2.getStatusCode());
            
            if (!String.valueOf(res2.getStatusCode()).startsWith('2')) {
                System.debug(LoggingLevel.ERROR, 'Failed to update case. Status code: ' + res2.getStatusCode());
                System.debug(LoggingLevel.ERROR, 'Response body: ' + res2.getBody());
                throw new SyncCaseService_CCRM.CRMSIntegrationException('Failed to update case. Status code: ' + res2.getStatusCode());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in syncCase: ' + e.getMessage());
            throw new SyncCaseService_CCRM.CRMSIntegrationException('Error in syncCase: ' + e.getMessage());
        }
    }

    @future (callout=true)
    public static void updatePQC(String externalId, String updateFieldToValueJSON) {
        if (String.isBlank(externalId) || String.isBlank(updateFieldToValueJSON)) {
            System.debug(
                logginglevel.WARN,
                String.format(
                    'externalId/updateFieldToValueJSON: {0} is missing data, not synced', 
                    new List<Object>{externalId, updateFieldToValueJSON}
                )
            );
            return;
        }

        try {
            CRMS_Integration_Setting__c settings = CRMS_Integration_Setting__c.getInstance();
            String accessToken = getAccessToken();

            Http h2 = new Http();
            HttpRequest req2 = new HttpRequest();
            req2.setEndpoint(settings.Base_URL__c + '/services/data/' + settings.API_Version__c + '/sobjects/ProductQualityComplaints_CRMS__c/' + externalId);
            req2.setHeader('Content-Type', 'application/json');
            req2.setHeader('Authorization', 'Bearer ' + accessToken);
            req2.setMethod('PATCH');
            System.debug('updateFieldToValueJSON: ' + updateFieldToValueJSON);
            req2.setBody(updateFieldToValueJSON);

            HttpResponse res2 = h2.send(req2);
            System.debug('res2.getStatusCode: ' + res2.getStatusCode());
            
            if (!String.valueOf(res2.getStatusCode()).startsWith('2')) {
                System.debug(LoggingLevel.ERROR, 'Failed to update PQC. Status code: ' + res2.getStatusCode());
                System.debug(LoggingLevel.ERROR, 'Response body: ' + res2.getBody());
                throw new SyncCaseService_CCRM.CRMSIntegrationException('Failed to update PQC. Status code: ' + res2.getStatusCode());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in syncPQC: ' + e.getMessage());
            throw new SyncCaseService_CCRM.CRMSIntegrationException('Error in syncPQC: ' + e.getMessage());
        }
    }

    @future (callout=true)
    public static void createCase(String wrapperJSON, String caseId) {
        try {
            CRMS_Integration_Setting__c settings = CRMS_Integration_Setting__c.getInstance();
            String accessToken = getAccessToken();
            
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(settings.Base_URL__c + '/services/data/' + settings.Composite_API_Version__c + '/composite/sobjects/');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setMethod('POST');
            req.setBody(wrapperJSON);
            
            HttpResponse res = h.send(req);
            System.debug('Response Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());

            if (String.valueOf(res.getStatusCode()).startsWith('2')) {
                try {
                    List<Object> responseList = (List<Object>)JSON.deserializeUntyped(res.getBody());
                    if (!responseList.isEmpty()) {
                        Map<String, Object> responseMap = (Map<String, Object>)responseList[0];
                        if (responseMap.containsKey('id') && responseMap.get('success') == true) {
                            String crmsId = (String)responseMap.get('id');
                            Case caseToUpdate = new Case(
                                Id = caseId,
                                ExternalCRMSId_CCRM__c = crmsId
                            );
                            update caseToUpdate;
                            System.debug('Updated Case with CRMS ID: ' + crmsId);
                        }
                    }
                } catch (JSONException e) {
                    System.debug(LoggingLevel.ERROR, 'Failed to parse response: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Response body: ' + res.getBody());
                    throw new SyncCaseService_CCRM.CRMSIntegrationException('Failed to process response from CRMS: ' + e.getMessage());
                }
            } else {
                System.debug(LoggingLevel.ERROR, 'Request failed with status code: ' + res.getStatusCode());
                System.debug(LoggingLevel.ERROR, 'Response body: ' + res.getBody());
                throw new SyncCaseService_CCRM.CRMSIntegrationException('Request to CRMS failed with status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in syncNewCase: ' + e.getMessage());
            throw new SyncCaseService_CCRM.CRMSIntegrationException('Error in syncNewCase: ' + e.getMessage());
        }
    }

    @future (callout=true)
    public static void createPQC(String wrapperJSON, String pqcId) {
        try {
            CRMS_Integration_Setting__c settings = CRMS_Integration_Setting__c.getInstance();
            String accessToken = getAccessToken();

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(settings.Base_URL__c + '/services/data/' + settings.Composite_API_Version__c + '/composite/sobjects/');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setMethod('POST');
            req.setBody(wrapperJSON);

            HttpResponse res = h.send(req);
            System.debug('Response Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            if (String.valueOf(res.getStatusCode()).startsWith('2')) {
                List<Object> responseList = (List<Object>)JSON.deserializeUntyped(res.getBody());
                if (!responseList.isEmpty()) {
                    Map<String, Object> responseMap = (Map<String, Object>)responseList[0];
                    if (responseMap.containsKey('id') && responseMap.get('success') == true) {
                        String crmsId = (String)responseMap.get('id');
                        ProductQualityComplaints_CRMS__c pqcToUpdate = new ProductQualityComplaints_CRMS__c(
                            Id = pqcId,
                            ExternalCRMSId_CCRM__c = crmsId
                        );
                        update pqcToUpdate;
                        System.debug('Updated PQC with CRMS ID: ' + crmsId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in syncNewPQC: ' + e.getMessage());
            throw new SyncCaseService_CCRM.CRMSIntegrationException('Error in syncNewPQC: ' + e.getMessage());
        }
    }
}