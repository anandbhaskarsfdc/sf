public with sharing class SyncCaseManager_CCRM {
    private static final String NAMED_CREDENTIAL = 'CCRM_Integration';
    private static final String GRANT_TYPE = '?grant_type=client_credentials';

    public static String getAccessToken() {
            HTTPResponse response = new NamedCredentialCallout_CRMS(NAMED_CREDENTIAL, GRANT_TYPE).post();
            System.debug('AccessToken Response: ' + response.getBody());
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String accessToken = (String)m.get('access_token');
            return accessToken;
        
    }

    @future (callout=true)
    public static void updateCase(String externalId, String updateFieldToValueJSON) {
        updateCaseInternal(externalId, updateFieldToValueJSON);
    }

    
    public static void updateCaseInternal(String externalId, String updateFieldToValueJSON) {
        try{
        Case updateCase = [SELECT Id, CCRMSyncStatus_CRMS__c FROM Case WHERE ExternalCCRMId_CRMS__c = :externalId LIMIT 1];
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

        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
        String accessToken = getAccessToken();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Base_URL__c + settings.Update_Case_Endpoint_CCRM__c + externalId);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setMethod('PATCH');
        req.setBody(updateFieldToValueJSON);
        System.debug('Update Case Request: ' + req);

        HttpResponse res = h.send(req);
        System.debug('Update Case Response: ' + res);
        if (String.valueOf(res.getStatusCode()).startsWith('2')) {
            updateCase.CCRMSyncStatus_CRMS__c = 'Synced';
            update updateCase;
        } else {
            updateCase.CCRMSyncStatus_CRMS__c = 'Failed';
            update updateCase;
        }
        } catch (Exception e) {
           throw e;
        }
    }

    @future (callout=true)
    public static void updatePQC(String externalId, String updateFieldToValueJSON) {
        updatePQCInternal(externalId, updateFieldToValueJSON);
    }

    
    public static void updatePQCInternal(String externalId, String updateFieldToValueJSON) {
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

        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
        String accessToken = getAccessToken();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Base_URL__c + settings.Update_PQC_Endpoint_CCRM__c + externalId);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setMethod('PATCH');
        req.setBody(updateFieldToValueJSON);

        HttpResponse res = h.send(req);
    }
}