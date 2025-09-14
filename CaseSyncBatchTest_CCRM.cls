@isTest
public class CaseSyncBatchTest_CCRM {
    
    @testSetup
    static void setupTestData() {
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName IN ('ProductQualityComplaint_CRMS', 'Medical_Inquiry_CRMS', 'Interaction_CRMS')
        ];
        
        Id pqcRecordTypeId;
        Id miRecordTypeId;
        Id interactionRecordTypeId;
        
        for (RecordType rt : recordTypes) {
            if (rt.DeveloperName == 'ProductQualityComplaint_CRMS') {
                pqcRecordTypeId = rt.Id;
            } else if (rt.DeveloperName == 'Medical_Inquiry_CRMS') {
                miRecordTypeId = rt.Id;
            } else if (rt.DeveloperName == 'Interaction_CRMS') {
                interactionRecordTypeId = rt.Id;
            }
        }
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Country_CRMS__c = 'CN'
        );
        insert testAccount;
        
      
        Id productRtId = null;
        Map<String, Schema.RecordTypeInfo> productRtMap = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName();
        if (productRtMap.containsKey('Regular_Product_CRMS')) {
            productRtId = productRtMap.get('Regular_Product_CRMS').getRecordTypeId();
        } else if (!productRtMap.isEmpty()) {
            productRtId = productRtMap.values()[0].getRecordTypeId();
        }
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            ExternalCCRMId_CRMS__c = 'PROD-001',
            Countries_CRMS__c = 'CN',
            IsActive = true,
            Family = 'Default',
            Description = 'Test Product Desc',
            RecordTypeId = productRtId,
            ThirdPartyProduct_CRMS__c = false,
            Technical_Product_CRMS__c = true
        );
        insert testProduct;

      
        Site_CRMS__c testSite = new Site_CRMS__c();
        insert testSite;

        Product_Site_CRMS__c testProductSite = new Product_Site_CRMS__c(
            Product_CRMS__c = testProduct.Id,
            ExternalCCRMId_CRMS__c = 'SITE-001',
            Site_CRMS__c = testSite.Id
        );
        insert testProductSite;
        
     
        Case testPQCCase = new Case(
            Subject = 'Test PQC Case',
            Status = 'New',
            Origin = 'Phone',
            Priority = 'Medium',
            AccountId = testAccount.Id,
            ProductId = testProduct.Id,
            RecordTypeId = pqcRecordTypeId,
            CCRMSyncStatus_CRMS__c = 'Failed',
            Country_CRMS__c = 'CN'
        );
        insert testPQCCase;
        
      
        Case testMICase = new Case(
            Subject = 'Test MI Case',
            Status = 'New',
            Origin = 'Email',
            Priority = 'Low',
            AccountId = testAccount.Id,
            ProductId = testProduct.Id,
            RecordTypeId = miRecordTypeId,
            CCRMSyncStatus_CRMS__c = 'Failed',
            Country_CRMS__c = 'CN'
        );
        insert testMICase;
     
        ProductQualityComplaints_CRMS__c testPQC = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testPQCCase.Id,
            ProductSKU_GxP_CRMS__c = testProduct.Id,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            CCRMSyncStatus_CRMS__c = 'Failed'
        );
        insert testPQC;
    }
    
    @isTest
    static void testCaseSyncBatch() {
 
        Test.startTest();
        CaseSyncBatch_CCRM batch = new CaseSyncBatch_CCRM();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        

        List<Case> updatedCases = [SELECT Id, CCRMSyncStatus_CRMS__c FROM Case WHERE CCRMSyncStatus_CRMS__c = 'Failed'];
        System.assertEquals(2, updatedCases.size(), 'Cases should still have Failed status since callouts are not made in test context');
    }
    
    @isTest
    static void testPQCSyncBatch() {

        Test.startTest();
        PQCSyncBatch_CCRM batch = new PQCSyncBatch_CCRM();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<ProductQualityComplaints_CRMS__c> updatedPQCs = [SELECT Id, CCRMSyncStatus_CRMS__c FROM ProductQualityComplaints_CRMS__c WHERE CCRMSyncStatus_CRMS__c = 'Failed'];
        System.assertEquals(1, updatedPQCs.size(), 'PQCs should still have Failed status since callouts are not made in test context');
    }
    
    @isTest
    static void testCaseSyncScheduler() {

        Test.startTest();
        String jobId = CaseSyncScheduler_CCRM.scheduleDaily();
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');

        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, cronTriggers.size(), 'Scheduled job should be created');
        Test.stopTest();
    }
    
    @isTest
    static void testPQCSyncScheduler() {

        Test.startTest();
        String jobId = PQCSyncScheduler_CCRM.scheduleDaily();
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');
        

        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, cronTriggers.size(), 'Scheduled job should be created');
        Test.stopTest();
    }
    

    @isTest
    static void testScheduleBatch() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        String jobId = CaseSyncBatch_CCRM.scheduleBatch(cronExp);
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');
        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, cronTriggers.size(), 'Scheduled job should be created');
        Test.stopTest();
    }

    @isTest
    static void testBuildUpdateFieldMap() {
       
        Case testCase = [SELECT Id, Origin, Status, Priority, Type, PQCStatus_CRMS__c, NLP_JobStatus_CRMS__c, NLP_ReasonCodeChangedByAgent_CRMS__c, Tier1_CRMS__c, ArgusStatus_CRMS__c, Tier3_CRMS__c, Country_CRMS__c, Keywords_CRMS__c, PredictedPriority_CRMS__c, Routing_Priority_CRMS__c, Tier2_CRMS__c, ProductId, RecordTypeId, RecordType.DeveloperName, ParentId, Subject, Description, CaseNumber, AccountId, Account.Country_CRMS__c, Case.Parent.ExternalCCRMId_CRMS__c,Case.InvestigationMinsAccrued_CRMS__c,Case.TimesReOpened_CRMS__c,Case.ExtensionOfCompletedInvMilestones_CRMS__c, Case.CurrentMilestoneDuration_CRMS__c, Case.AccumulatedInvestigationsTime_CRMS__c FROM Case LIMIT 1];
        String productExternalId = 'prodId';
        CaseChangeEventWrapper_CCRM wrapper = new CaseChangeEventWrapper_CCRM(testCase, productExternalId);

       
        CaseSyncBatch_CCRM batch = new CaseSyncBatch_CCRM();
        Map<String, Object> result = batch.buildUpdateFieldMap(wrapper);

        System.assertEquals(testCase.Origin, result.get('Origin'));
        System.assertEquals(testCase.Status, result.get('Status'));
        System.assertEquals(testCase.Priority, result.get('Priority'));
        System.assertEquals(testCase.Type, result.get('Type'));
        System.assertEquals(testCase.PQCStatus_CRMS__c, result.get('PQCStatus_CRMS__c'));
        System.assertEquals(testCase.NLP_JobStatus_CRMS__c, result.get('NLP_JobStatus_CRMS__c'));
        System.assertEquals(testCase.NLP_ReasonCodeChangedByAgent_CRMS__c, result.get('NLP_ReasonCodeChangedByAgent_CRMS__c'));
        System.assertEquals(testCase.Tier1_CRMS__c, result.get('Tier1_CRMS__c'));
        System.assertEquals(testCase.ArgusStatus_CRMS__c, result.get('ArgusStatus_CRMS__c'));
        System.assertEquals(testCase.Tier3_CRMS__c, result.get('Tier3_CRMS__c'));
        System.assertEquals(testCase.Country_CRMS__c, result.get('Country_CRMS__c'));
        System.assertEquals(testCase.Keywords_CRMS__c, result.get('Keywords_CRMS__c'));
        System.assertEquals(testCase.PredictedPriority_CRMS__c, result.get('PredictedPriority_CRMS__c'));
        System.assertEquals(testCase.Routing_Priority_CRMS__c, result.get('Routing_Priority_CRMS__c'));
        System.assertEquals(testCase.Tier2_CRMS__c, result.get('Tier2_CRMS__c'));
        System.assertEquals(productExternalId, result.get('ProductId'));
        System.assertEquals(testCase.ParentId, result.get('ParentId'));
        System.assertEquals(testCase.Subject, result.get('Subject'));
        System.assertEquals(testCase.Description, result.get('Description'));
    }
    
    @isTest
    static void testCaseSyncSchedulerHourlyAndCustom() {
        Test.startTest();
        // Hourly
        String jobIdHourly = CaseSyncScheduler_CCRM.scheduleHourly();
        System.assertNotEquals(null, jobIdHourly, 'Hourly job should be scheduled successfully');
        List<CronTrigger> cronTriggersHourly = [SELECT Id FROM CronTrigger WHERE Id = :jobIdHourly];
        System.assertEquals(1, cronTriggersHourly.size(), 'Hourly scheduled job should be created');
        // Custom
        String customCron = '0 30 3 * * ?';
        String jobIdCustom = CaseSyncScheduler_CCRM.scheduleCustom(customCron);
        System.assertNotEquals(null, jobIdCustom, 'Custom job should be scheduled successfully');
        List<CronTrigger> cronTriggersCustom = [SELECT Id FROM CronTrigger WHERE Id = :jobIdCustom];
        System.assertEquals(1, cronTriggersCustom.size(), 'Custom scheduled job should be created');
        Test.stopTest();
    }

    @isTest
    static void testPQCSyncSchedulerHourlyAndCustom() {
        Test.startTest();
        // Hourly
        String jobIdHourly = PQCSyncScheduler_CCRM.scheduleHourly();
        System.assertNotEquals(null, jobIdHourly, 'Hourly job should be scheduled successfully');
        List<CronTrigger> cronTriggersHourly = [SELECT Id FROM CronTrigger WHERE Id = :jobIdHourly];
        System.assertEquals(1, cronTriggersHourly.size(), 'Hourly scheduled job should be created');
        // Custom
        String customCron = '0 15 4 * * ?';
        String jobIdCustom = PQCSyncScheduler_CCRM.scheduleCustom(customCron);
        System.assertNotEquals(null, jobIdCustom, 'Custom job should be scheduled successfully');
        List<CronTrigger> cronTriggersCustom = [SELECT Id FROM CronTrigger WHERE Id = :jobIdCustom];
        System.assertEquals(1, cronTriggersCustom.size(), 'Custom scheduled job should be created');
        Test.stopTest();
    }

    @isTest
    static void testPQCSyncBatchSchedule() {
        Test.startTest();
     
        String cronExp = '0 0 2 * * ?';
        String jobId = PQCSyncBatch_CCRM.scheduleBatch(cronExp);
        System.assertNotEquals(null, jobId, 'PQC Batch job should be scheduled successfully');
        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, cronTriggers.size(), 'Scheduled PQC batch job should be created');
        Test.stopTest();
    }

    @isTest
    static void testPQCSyncBatchSchedule_Exception() {
        Test.startTest();
   
        Boolean exceptionThrown = false;
        try {
            PQCSyncBatch_CCRM.scheduleBatch('invalid cron');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }

    @isTest
    static void testBuildUpdateFieldMap_PQC() {
       
        PQCChangeEventWrapper_CCRM wrapper = new PQCChangeEventWrapper_CCRM();
        wrapper.QuantityOfProduct_GxP_CRMS = 1;
        wrapper.Reason_Code_L3_GxP_CRMS = 'L3';
        wrapper.Verbatim_GxP_CRMS = 'verbatim';
        wrapper.Reason_Code_L1_GxP_CRMS = 'L1';
        wrapper.Reason_Code_L2_GxP_CRMS = 'L2';
        wrapper.SitesCount_CRMS = 2;
        wrapper.PrimaryPackageLot_GxP_CRMS = 'lot';
        wrapper.HSIAE_CRMS = 'hsiae';
        wrapper.RelatedCase_GxP_CRMS = 'caseid';
        wrapper.ProductSite_GxP_CRMS = 'siteid';
        wrapper.ProductSKU_GxP_CRMS = 'skuid';
        wrapper.Country_GxP_CRMS = 'CN';
        wrapper.Safety_ID_GxP_CRMS = 'safeid';
        wrapper.RelatedHSIAE_GxP_CRMS = 'relatedhsiae';
        wrapper.HSI_Description = 'desc';

        PQCSyncBatch_CCRM batch = new PQCSyncBatch_CCRM();
        Map<String, Object> resultMap = batch.buildUpdateFieldMap(wrapper);

        System.assertEquals(15, resultMap.size());
    
        
    }

}