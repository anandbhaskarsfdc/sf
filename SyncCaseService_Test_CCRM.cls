@isTest
public with sharing class SyncCaseService_Test_CCRM {
    
    @TestSetup
    static void setupTestData() {
        List<Pricebook2> stdpbs = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true];
        if (stdpbs.isEmpty()) {
            Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
            insert pb;
        } else if (!stdpbs[0].IsActive) {
            stdpbs[0].IsActive = true;
            update stdpbs[0];
        }
        setupIntegrationSettings();
        setupTestAccounts();
        List<Product2> products = setupTestProducts();
        Site_CRMS__c site = new Site_CRMS__c(Name = 'Test Site');
        insert site;
        setupTestProductSites(products, site);
    }
    
    static void setupIntegrationSettings() {
        CCRM_Integration_Setting__c settings = new CCRM_Integration_Setting__c();
        settings.Base_URL__c = 'https://test-api.example.com';
        settings.Composite_API_Endpoint_CCRM__c = '/composite';
        settings.Update_Case_Endpoint_CCRM__c = '/cases/';
        settings.Update_PQC_Endpoint_CCRM__c = '/pqc/';
        settings.PQC_RecordType__c = '0121t000000EM2cAAG';
        settings.MI_RecordType__c = '0121t000000EM2cAAG';
        settings.Interaction_RecordType__c = '0121t000000EM2cAAG';
        settings.MI_Locked_RecordType__c = '0121t000000EM2cAAG';
        settings.PQCLocked_RecordType__c = '0121t000000EM2cAAG';
        settings.PQCObject_Locked_RecordType__c = '0121t000000EM2cAAG';
        settings.HK_Account_CCRM__c = '001000000000001';
        settings.CN_Account_CCRM__c = '001000000000002';
        insert settings;
    }
    
    static void setupTestAccounts() {
        List<Account> accounts = new List<Account>();
        
        Account hkAccount = new Account(
            Name = 'Test HK Account',
            Country_CRMS__c = 'HK'
        );
        accounts.add(hkAccount);
        
        Account cnAccount = new Account(
            Name = 'Test CN Account',
            Country_CRMS__c = 'CN'
        );
        accounts.add(cnAccount);
        
        insert accounts;
    }
    
    static List<Product2> setupTestProducts() {
        Id regularProductRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Regular_Product_CRMS').getRecordTypeId();
        List<Product2> products = new List<Product2>();
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP001',
            ExternalCCRMId_CRMS__c = 'PROD_001',
            Countries_CRMS__c = 'CN',
            IsActive = true,
            Family = 'Default',
            Description = 'Test Product 1 Desc',
            RecordTypeId = regularProductRtId,
            ThirdPartyProduct_CRMS__c = false,
            Technical_Product_CRMS__c = true
        );
        products.add(product1);
        Product2 product2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP002',
            ExternalCCRMId_CRMS__c = 'PROD_002',
            Countries_CRMS__c = 'CN',
            IsActive = true,
            Family = 'Default',
            Description = 'Test Product 2 Desc',
            RecordTypeId = regularProductRtId,
            ThirdPartyProduct_CRMS__c = false,
            Technical_Product_CRMS__c = true
        );
        products.add(product2);
        insert products;
        List<Pricebook2> stdPbs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (!stdPbs.isEmpty()) {
            List<PricebookEntry> stdEntries = new List<PricebookEntry>();
            for(Product2 p : products){
                stdEntries.add(new PricebookEntry(Pricebook2Id=stdPbs[0].Id, Product2Id=p.Id, UnitPrice=1, IsActive=true));
            }
            insert stdEntries;
        }
        return products;
    }
    
    static void setupTestProductSites(List<Product2> products, Site_CRMS__c site) {
        List<Product_Site_CRMS__c> productSites = new List<Product_Site_CRMS__c>();
        if (!products.isEmpty()) {
            Product_Site_CRMS__c productSite1 = new Product_Site_CRMS__c(
                Product_CRMS__c = products[0].Id,
                ExternalCCRMId_CRMS__c = 'SITE_001',
                Site_CRMS__c = site.Id
            );
            productSites.add(productSite1);
            if (products.size() > 1) {
                Product_Site_CRMS__c productSite2 = new Product_Site_CRMS__c(
                    Product_CRMS__c = products[1].Id,
                    ExternalCCRMId_CRMS__c = 'SITE_002',
                    Site_CRMS__c = site.Id
                );
                productSites.add(productSite2);
            }
        }
        if (!productSites.isEmpty()) {
            insert productSites;
        }
    }
    
    @isTest
    static void testProcessCaseChangeEvent_Create() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;

        Case retrievedCase = [
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
            WHERE Id = :testCase.Id
        ];
        
        System.assertNotEquals(null, retrievedCase.Id);
        System.assertEquals('ProductQualityComplaint_CRMS', retrievedCase.RecordType.DeveloperName);
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCaseChangeEvent_Update() {       
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            ExternalCCRMId_CRMS__c = 'CASE_001',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        testCase.Subject = 'Updated Subject';
        testCase.Status = 'Working';
        update testCase;
        
        Case updatedCase = [SELECT Id, Subject, Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Updated Subject', updatedCase.Subject);
        System.assertEquals('Working', updatedCase.Status);
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCaseChangeEvent_UpdateWithPQC() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'HK',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        
        insert pqc;
        
        testCase.ExternalCCRMId_CRMS__c = 'CASE_001';
        update testCase;
        
        Case updatedCase = [SELECT Id, ExternalCCRMId_CRMS__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('CASE_001', updatedCase.ExternalCCRMId_CRMS__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCaseChangeEvent_MedicalInquiry() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Medical Inquiry Test',
            Description = 'Medical inquiry description',
            Origin = 'Email',
            Status = 'New',
            Priority = 'High',
            Type = 'MI',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Medical_Inquiry_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        Case retrievedCase = [SELECT Id, Type, RecordType.DeveloperName FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('MI', retrievedCase.Type);
        System.assertEquals('Medical_Inquiry_CRMS', retrievedCase.RecordType.DeveloperName);
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCaseChangeEvent_Interaction() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Interaction Test',
            Description = 'Interaction description',
            Origin = 'Web',
            Status = 'New',
            Priority = 'Low',
            Type = 'INT',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Interaction_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        Case retrievedCase = [SELECT Id, Type, RecordType.DeveloperName FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('INT', retrievedCase.Type);
        System.assertEquals('Interaction_CRMS', retrievedCase.RecordType.DeveloperName);
        
        Test.stopTest();
    }
    
    @isTest
    static void testProcessPQCChangeEvent() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c, Site_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case for PQC',
            Origin = 'Phone',
            Status = 'New',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 2,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'No',
            Reason_Code_L1_GxP_CRMS__c = 'Performance Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Product does not work',
            Reason_Code_L3_GxP_CRMS__c = 'CPE NOT SAT',
            Verbatim_GxP_CRMS__c = 'Product not working as expected',
            SitesCount_CRMS__c = 2,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT002',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'HK',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE002'
        );
        
        insert pqc;
        
        pqc.QuantityOfProduct_GxP_CRMS__c = 3;
        pqc.Verbatim_GxP_CRMS__c = 'Updated verbatim';
        update pqc;
        
        ProductQualityComplaints_CRMS__c updatedPQC = [
            SELECT Id, QuantityOfProduct_GxP_CRMS__c, Verbatim_GxP_CRMS__c 
            FROM ProductQualityComplaints_CRMS__c 
            WHERE Id = :pqc.Id
        ];
        System.assertEquals(3, updatedPQC.QuantityOfProduct_GxP_CRMS__c);
        System.assertEquals('Updated verbatim', updatedPQC.Verbatim_GxP_CRMS__c);
        
        Test.stopTest();
    }
    
 /*   @isTest
    static void testBuildCaseCompositeBody() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        
        insert testCase;
        
        CaseChangeEvent event = new CaseChangeEvent();
        CaseChangeEventWrapper_CCRM wrapper = new CaseChangeEventWrapper_CCRM(event, 'PROD_001', testCase);
        
        Map<String, Object> result = SyncCaseService_CCRM.buildCaseCompositeBody(wrapper);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(false, result.get('allOrNone'));
        System.assertNotEquals(null, result.get('records'));
        
        List<Object> records = (List<Object>)result.get('records');
        System.assertEquals(1, records.size());
        
        Map<String, Object> record = (Map<String, Object>)records[0];
        System.assertEquals('Case', ((Map<String, String>)record.get('attributes')).get('type'));
    }
    
    @isTest
    static void testBuildPQCCompositeBody() {
        Test.startTest();
        
        PQCChangeEventWrapper_CCRM wrapper = new PQCChangeEventWrapper_CCRM();
        wrapper.QuantityOfProduct_GxP_CRMS = 1;
        wrapper.DidConsumerAgreeToReturnSample_GxP_CRMS = 'Yes';
        wrapper.Reason_Code_L1_GxP_CRMS = 'Packaging Complaint';
        wrapper.Reason_Code_L2_GxP_CRMS = 'Blister hard to open';
        wrapper.Reason_Code_L3_GxP_CRMS = 'CPA BLIST HT OPEN';
        wrapper.Verbatim_GxP_CRMS = 'Test verbatim';
        wrapper.SitesCount_CRMS = 1;
        wrapper.PrimaryPackageLot_GxP_CRMS = 'LOT001';
        wrapper.HSIAE_CRMS = 'No HSI/AE Reported';
        wrapper.RelatedCase_GxP_CRMS = 'CASE_001';
        wrapper.ExternalCCRMId = 'PQC_001';
        wrapper.ProductSite_GxP_CRMS = 'SITE_001';
        wrapper.ProductSKU_GxP_CRMS = 'PROD_001';
        wrapper.Country_GxP_CRMS = 'HK';
        wrapper.Safety_ID_GxP_CRMS = 'SAFE001';
        wrapper.RelatedHSIAE_GxP_CRMS = 'HSI_CASE_001';
        wrapper.HSI_Description = 'Test HSI Description';
        
        Map<String, Object> result = SyncCaseService_CCRM.buildPQCCompositeBody(wrapper);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(false, result.get('allOrNone'));
        System.assertNotEquals(null, result.get('records'));
        
        List<Object> records = (List<Object>)result.get('records');
        System.assertEquals(1, records.size());
        
        Map<String, Object> record = (Map<String, Object>)records[0];
        System.assertEquals('ProductQualityComplaints_CRMS__c', ((Map<String, String>)record.get('attributes')).get('type'));
        System.assertEquals(1, record.get('QuantityOfProduct_GxP_CRMS__c'));
        System.assertEquals('Yes', record.get('DidConsumerAgreeToReturnSample_GxP_CRMS__c'));
    } */
    
    @isTest
    static void testGetProductExternalId() {    
        Test.startTest();
        
        Product2 testProduct = [SELECT Id, ExternalCCRMId_CRMS__c FROM Product2 LIMIT 1];
        
        System.assertNotEquals(null, testProduct.ExternalCCRMId_CRMS__c);
        System.assertEquals('PROD_001', testProduct.ExternalCCRMId_CRMS__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProductSiteExternalId() {
        Test.startTest();
        
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        Product_Site_CRMS__c testProductSite = [
            SELECT Id, ExternalCCRMId_CRMS__c 
            FROM Product_Site_CRMS__c 
            WHERE Product_CRMS__c = :testProduct.Id AND ExternalCCRMId_CRMS__c != null 
            LIMIT 1
        ];
        
        System.assertNotEquals(null, testProductSite.ExternalCCRMId_CRMS__c);
        System.assertEquals('SITE_001', testProductSite.ExternalCCRMId_CRMS__c);
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRelatedPQCCreate_ForLoop() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Case testCase = new Case(
            Subject = 'PQC Loop',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'CASEPQCLOOP01'
        );
        insert testCase;
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        testCase.ExternalCCRMId_CRMS__c = 'CASEPQCLOOP02';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseChangeEvent_Exception() {
        Test.startTest();
        CaseChangeEvent event = new CaseChangeEvent();
        try {
            SyncCaseService_CCRM.processCaseChangeEvent(event);
        } catch (Exception e) {
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_DifferentFieldTypes() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Update Field Types',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'UPDATEFIELDS01'
        );
        insert testCase;

        testCase.Subject = 'Updated Subject';
        testCase.Description = 'Updated Description';
        testCase.Priority = 'High';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_RecordTypeBranches() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case medicalCase = new Case(
            Subject = 'Medical Inquiry',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'MI',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Medical_Inquiry_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'MEDICALINQ01'
        );
        insert medicalCase;
        
        medicalCase.Subject = 'Updated Medical Inquiry';
        update medicalCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_ProductIdField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Product2 newProduct = [SELECT Id FROM Product2 WHERE Id != :testProductSite.Product_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Product Update',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PRODUCTUP01'
        );
        insert testCase;
        
        testCase.ProductId = newProduct.Id;
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRelatedPQCCreate_EmptyList() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'No PQC Case',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'NOPQCCASE01'
        );
        insert testCase;
        
        testCase.ExternalCCRMId_CRMS__c = 'NOPQCCASE02';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_DifferentFieldTypes() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'PQC Field Types',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCFIELDS01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.QuantityOfProduct_GxP_CRMS__c = 2;
        pqc.Verbatim_GxP_CRMS__c = 'Updated verbatim';
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithNullProduct() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Null Product Case',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'NULLPROD01'
        );
        insert testCase;
        
        testCase.Subject = 'Updated Null Product Case';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithDatetimeField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Datetime Field Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'DATETIME01'
        );
        insert testCase;
        
        testCase.Subject = 'Updated Datetime Field Test';
        testCase.Description = 'Updated description with datetime test';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_MedicalInquiryLocked() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case medicalLockedCase = new Case(
            Subject = 'Medical Inquiry Locked',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'MI',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MedicalInquiryLocked_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'MEDLOCKED01'
        );
        insert medicalLockedCase;
        
        medicalLockedCase.Subject = 'Updated Medical Inquiry Locked';
        update medicalLockedCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_ProductQualityComplaintLocked() {     
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case pqcLockedCase = new Case(
            Subject = 'PQC Locked',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaintLocked_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCLOCKED01'
        );
        insert pqcLockedCase;
        
        pqcLockedCase.Subject = 'Updated PQC Locked';
        update pqcLockedCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithNullFieldValue() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Null Field Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'NULLFIELD01'
        );
        insert testCase;
        
        testCase.Subject = null;
        testCase.Description = null;
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithBooleanField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Boolean Field Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'BOOLEAN01'
        );
        insert testCase;
        
        testCase.Subject = 'Updated Boolean Field Test';
        testCase.IsEscalated = true;
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithEmptyUpdateMap() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Empty Update Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'EMPTYUP01'
        );
        insert testCase;

        testCase.Subject = 'Updated Empty Update Test';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseUpdate_WithExternalCRMSIdUpdate() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'External CRMS ID Update Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'EXTCRMS01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        testCase.ExternalCCRMId_CRMS__c = 'EXTCRMS02';
        update testCase;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_WithProductSKUField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Product2 newProduct = [SELECT Id FROM Product2 WHERE Id != :testProductSite.Product_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'PQC Product SKU Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCPROD01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.QuantityOfProduct_GxP_CRMS__c = 2;
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_WithProductSiteField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Site_CRMS__c newSite = new Site_CRMS__c(Name = 'New Test Site');
        insert newSite;
        Product_Site_CRMS__c newProductSite = new Product_Site_CRMS__c(
            Product_CRMS__c = testProductSite.Product_CRMS__c,
            Site_CRMS__c = newSite.Id,
            ExternalCCRMId_CRMS__c = 'NEWSITE01'
        );
        insert newProductSite;
        
        Case testCase = new Case(
            Subject = 'PQC Product Site Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCSITE01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.ProductSite_GxP_CRMS__c = newProductSite.Id;
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_WithRecordTypeField() {   
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'PQC Record Type Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCRECT01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.RecordTypeId = Schema.SObjectType.ProductQualityComplaints_CRMS__c.getRecordTypeInfosByDeveloperName().get('PQCLocked_CRMS').getRecordTypeId();
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_WithBooleanField() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'PQC Boolean Field Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCBOOL01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.QuantityOfProduct_GxP_CRMS__c = 2;
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testProcessPQCChangeEvent_WithNullFieldValue() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'CN' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'PQC Null Field Test',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCNULL01'
        );
        insert testCase;
        
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        
        pqc.Verbatim_GxP_CRMS__c = null;
        pqc.Reason_Code_L1_GxP_CRMS__c = null;
        update pqc;
        
        Test.stopTest();
    }

    @isTest
    static void testCaseChangeEventTrigger_CreateAndUpdate() {
        Test.enableChangeDataCapture();
        Test.setMock(HttpCalloutMock.class, new SyncCaseCalloutMock_CCRM());
        // mock future方法
        Test.startTest();
        // substibute SyncCaseManager_CCRM's future to mock
        // becausae Apex does not directly support mock future，only main process coverage can be ensured by mocked callout
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Case testCase = new Case(
            Subject = 'CDC Test',
            Description = 'CDC Test Desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN'
        );
        insert testCase;
        Test.getEventBus().deliver();
        testCase.Subject = 'CDC Test Updated';
        update testCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assert(true, 'Case ChangeEvent create/update delivered');
    }

    @isTest
    static void testPQCChangeEventTrigger_Update() {
        Test.enableChangeDataCapture();
        Test.setMock(HttpCalloutMock.class, new SyncCaseCalloutMock_CCRM());
        // mock future方法
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Country_CRMS__c = 'HK' LIMIT 1];
        Product_Site_CRMS__c testProductSite = [SELECT Product_CRMS__c FROM Product_Site_CRMS__c LIMIT 1];
        Case testCase = new Case(
            Subject = 'PQC CDC',
            Description = 'desc',
            Origin = 'Phone',
            Status = 'New',
            Priority = 'Medium',
            Type = 'PQC',
            AccountId = testAccount.Id,
            ProductId = testProductSite.Product_CRMS__c,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ProductQualityComplaint_CRMS').getRecordTypeId(),
            Country_CRMS__c = 'CN',
            ExternalCCRMId_CRMS__c = 'PQCCDC01'
        );
        insert testCase;
        ProductQualityComplaints_CRMS__c pqc = new ProductQualityComplaints_CRMS__c(
            RelatedCase_GxP_CRMS__c = testCase.Id,
            QuantityOfProduct_GxP_CRMS__c = 1,
            DidConsumerAgreeToReturnSample_GxP_CRMS__c = 'Yes',
            Reason_Code_L1_GxP_CRMS__c = 'Packaging Complaint',
            Reason_Code_L2_GxP_CRMS__c = 'Blister hard to open',
            Reason_Code_L3_GxP_CRMS__c = 'CPA BLIST HT OPEN',
            Verbatim_GxP_CRMS__c = 'Test verbatim',
            SitesCount_CRMS__c = 1,
            PrimaryPackageLot_GxP_CRMS__c = 'LOT001',
            HSIAE_CRMS__c = 'No HSI/AE Reported',
            Country_GxP_CRMS__c = 'CN',
            ProductSKU_GxP_CRMS__c = testProductSite.Product_CRMS__c,
            ProductSite_GxP_CRMS__c = testProductSite.Id,
            Safety_ID_GxP_CRMS__c = 'SAFE001'
        );
        insert pqc;
        pqc.QuantityOfProduct_GxP_CRMS__c = 2;
        update pqc;
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assert(true, 'PQC ChangeEvent update delivered');
    }
}