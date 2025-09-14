@isTest
public class SyncCaseCalloutMock_CCRM implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        
        String endpoint = req.getEndpoint();
        if (endpoint != null && endpoint.contains('grant_type=client_credentials')) {
            res.setBody('{"access_token":"dummy_token","instance_url":"https://dummy"}');
        } else if (endpoint != null && endpoint.contains('/composite')) {
            res.setBody('[{"id":"dummy_id","success":true}]');
        } else if (endpoint != null && endpoint.contains('?fields=CaseNumber')) {
            res.setBody('{"CaseNumber":"C-00001"}');
        } else if (endpoint != null && endpoint.contains('sobjects/ContentVersion')) {
            res.setBody('{"id":"mock_content_version_id","success":true}');
            res.setStatusCode(201);
        } else if (endpoint != null && endpoint.contains('query')) {
            res.setBody('{"totalSize":1,"done":true,"records":[{"ContentDocumentId":"mock_content_document_id"}]}');
        } else if (endpoint != null && endpoint.contains('sobjects/ContentDocumentLink')) {
            res.setBody('{"id":"mock_content_document_link_id","success":true}');
            res.setStatusCode(201);
        } else {
            res.setBody('{"success":true}');
        }
        return res;
    }
}