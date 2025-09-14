public class CaseChangeEventWrapper_CCRM {
   
    public static final List<String> CASE_SYNC_FIELDS = new List<String> {
        'Id',
        'Origin',
        'Status',
        'Priority',
        'Type',
        'PQCStatus_CRMS__c',
        'NLP_JobStatus_CRMS__c',
        'NLP_ReasonCodeChangedByAgent_CRMS__c',
        'Tier1_CRMS__c',
        'ArgusStatus_CRMS__c',
        'Tier3_CRMS__c',
        'Country_CRMS__c',
        'Keywords_CRMS__c',
        'PredictedPriority_CRMS__c',
        'Routing_Priority_CRMS__c',
        'Tier2_CRMS__c',
        'ProductId',
        'RecordTypeId',
        'RecordType.DeveloperName',
        'ExternalCCRMId_CRMS__c',
        'ExternalCCRMCaseNumber_CRMS__c',
        'AccountId',
        'Account.Country_CRMS__c',
        'ParentId',
        'Parent.ExternalCCRMId_CRMS__c',
        'Parent.CaseNumber',
        'InvestigationMinsAccrued_CRMS__c',
        'TimesReOpened_CRMS__c',
        'ExtensionOfCompletedInvMilestones_CRMS__c',
        'CurrentMilestoneDuration_CRMS__c',
        'AccumulatedInvestigationsTime_CRMS__c',
        'Subject',
        'Description',
        'CaseNumber',
        'CCRMSyncStatus_CRMS__c'
    };

    public String Origin;
    public String Status;
    public String Priority;
    public String Type;
    public String PQCStatus;
    public String NLPJobStatus;
    public String NLPReasonCodeChangedByAgent;
    public String Tier1;
    public String ArgusStatus;
    public String Tier3;
    public String Country;
    public String Keywords;
    public String PredictedPriority;
    public String RoutingPriority;
    public String Tier2;
    public String ProductId;
    public String RecordTypeId;
    public String ExternalCRMSId;
    public String ExternalCRMSCaseNumber;
    public String AccountId;
    public String ParentId;
    public Integer CountOfAEs;
    public Integer InvestigationMinsAccrued;
    public Integer TimesReOpened;
    public Integer ExtensionOfCompletedInvMilestones;
    public Integer CurrentMilestoneDuration;
    public Integer AccumulatedInvestigationsTime;
    public Integer CountOfPQCs;
    public String Subject;
    public String Description;  
   
    
    public CaseChangeEventWrapper_CCRM(Case caseObj, String productExternalId) {
        this.Origin = caseObj.Origin;
        this.Status = caseObj.Status;
        this.Priority = caseObj.Priority;
        this.Type = caseObj.Type;
        this.PQCStatus = caseObj.PQCStatus_CRMS__c;
        this.NLPJobStatus = caseObj.NLP_JobStatus_CRMS__c;
        this.NLPReasonCodeChangedByAgent = caseObj.NLP_ReasonCodeChangedByAgent_CRMS__c;
        this.Tier1 = caseObj.Tier1_CRMS__c;
        this.ArgusStatus = caseObj.ArgusStatus_CRMS__c;
        this.Tier3 = caseObj.Tier3_CRMS__c;
        this.Country = caseObj.Country_CRMS__c;
        this.Keywords = caseObj.Keywords_CRMS__c;
        this.PredictedPriority = caseObj.PredictedPriority_CRMS__c;
        this.RoutingPriority = caseObj.Routing_Priority_CRMS__c;
        this.Tier2 = caseObj.Tier2_CRMS__c;
        this.ProductId = productExternalId;
        this.RecordTypeId = getRecordTypeId(caseObj);
        this.ExternalCRMSId = caseObj.Id;
        this.ExternalCRMSCaseNumber = caseObj.CaseNumber;
        this.AccountId = getAccountId(caseObj);
        this.ParentId = caseObj.Parent?.ExternalCCRMId_CRMS__c;
        this.InvestigationMinsAccrued = caseObj.InvestigationMinsAccrued_CRMS__c != null ? Integer.valueOf(caseObj.InvestigationMinsAccrued_CRMS__c) : 0;
        this.TimesReOpened = caseObj.TimesReOpened_CRMS__c != null ? Integer.valueOf(caseObj.TimesReOpened_CRMS__c) : 0;
        this.ExtensionOfCompletedInvMilestones = caseObj.ExtensionOfCompletedInvMilestones_CRMS__c != null ? Integer.valueOf(caseObj.ExtensionOfCompletedInvMilestones_CRMS__c) : 0;
        this.CurrentMilestoneDuration = caseObj.CurrentMilestoneDuration_CRMS__c != null ? Integer.valueOf(caseObj.CurrentMilestoneDuration_CRMS__c) : 0;
        this.AccumulatedInvestigationsTime = caseObj.AccumulatedInvestigationsTime_CRMS__c != null ? Integer.valueOf(caseObj.AccumulatedInvestigationsTime_CRMS__c) : 0;
        this.Subject = caseObj.Subject;
        this.Description = caseObj.Description;
    }

    public CaseChangeEventWrapper_CCRM(CaseChangeEvent event, String productExternalId, Case newCase) {
        this.Origin = (String)event.get('Origin');
        this.Status = (String)event.get('Status');
        this.Priority = (String)event.get('Priority');
        this.Type = (String)event.get('Type');
        this.PQCStatus = (String)event.get('PQCStatus_CRMS__c');
        this.NLPJobStatus = (String)event.get('NLP_JobStatus_CRMS__c');
        this.NLPReasonCodeChangedByAgent = (String)event.get('NLP_ReasonCodeChangedByAgent_CRMS__c');
        this.Tier1 = (String)event.get('Tier1_CRMS__c');
        this.ArgusStatus = (String)event.get('ArgusStatus_CRMS__c');
        this.Tier3 = (String)event.get('Tier3_CRMS__c');
        this.Country = (String)event.get('Country_CRMS__c');
        this.Keywords = (String)event.get('Keywords_CRMS__c');
        this.PredictedPriority = (String)event.get('PredictedPriority_CRMS__c');
        this.RoutingPriority = (String)event.get('Routing_Priority_CRMS__c');
        this.Tier2 = (String)event.get('Tier2_CRMS__c');
        this.ProductId = productExternalId;
        this.RecordTypeId = getRecordTypeId(newCase);
        this.ExternalCRMSId = newCase.Id;
        this.ExternalCRMSCaseNumber = newCase.CaseNumber;
        this.AccountId = getAccountId(newCase);
        this.ParentId = newCase.Parent.ExternalCCRMId_CRMS__c;
        this.InvestigationMinsAccrued = event.get('InvestigationMinsAccrued_CRMS__c') != null ? ((Decimal)event.get('InvestigationMinsAccrued_CRMS__c')).intValue() : 0;
        this.TimesReOpened = event.get('TimesReOpened_CRMS__c') != null ? ((Decimal)event.get('TimesReOpened_CRMS__c')).intValue() : 0;
        this.ExtensionOfCompletedInvMilestones = event.get('ExtensionOfCompletedInvMilestones_CRMS__c') != null ? ((Decimal)event.get('ExtensionOfCompletedInvMilestones_CRMS__c')).intValue() : 0;
        this.CurrentMilestoneDuration = event.get('CurrentMilestoneDuration_CRMS__c') != null ? ((Decimal)event.get('CurrentMilestoneDuration_CRMS__c')).intValue() : 0;
        this.AccumulatedInvestigationsTime = event.get('AccumulatedInvestigationsTime_CRMS__c') != null ? ((Decimal)event.get('AccumulatedInvestigationsTime_CRMS__c')).intValue() : 0;
        this.Subject = (String)event.get('Subject');
        this.Description = (String)event.get('Description');
    }
    private static String getAccountId(Case newCase) {
        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
       return newCase.Account.Country_CRMS__c == 'HK' ? settings.HK_Account_CCRM__c : settings.CN_Account_CCRM__c;

    }

    private static String getPQCRecordTypeId() {
        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
        return settings.PQC_RecordType__c;
    }

    private static String getMIRecordTypeId() {
        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
        return settings.MI_RecordType__c;
    }

    private static String getInteractionRecordTypeId() {
        CCRM_Integration_Setting__c settings = CCRM_Integration_Setting__c.getInstance();
        return settings.Interaction_RecordType__c;
    }

    private static String getRecordTypeId(Case newCase) {
        if (newCase.RecordType.DeveloperName == 'ProductQualityComplaint_CRMS') {
            return getPQCRecordTypeId();
        } else if (newCase.RecordType.DeveloperName == 'Medical_Inquiry_CRMS') {
            return getMIRecordTypeId();
        } else if (newCase.RecordType.DeveloperName == 'Interaction_CRMS') {
            return getInteractionRecordTypeId();
        } else {
            return null;
        }
    }

}