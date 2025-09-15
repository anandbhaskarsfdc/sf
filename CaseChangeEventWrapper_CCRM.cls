public class CaseChangeEventWrapper_CCRM {
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
    
    public Integer CountOfAEs;
    public Integer InvestigationMinsAccrued;
    public Integer TimesReOpened;
    public Integer ExtensionOfCompletedInvMilestones;
    public Integer CurrentMilestoneDuration;
    public Integer AccumulatedInvestigationsTime;
    public Integer CountOfPQCs;

    
    public CaseChangeEventWrapper_CCRM(CaseChangeEvent event, String productExternalId, String caseId, String caseNumber) {
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
        this.RecordTypeId = '0121t000000EM2PAAW';
        this.ExternalCRMSId = caseId;
        this.ExternalCRMSCaseNumber = caseNumber;
        this.AccountId = '001bY00000PLxi4QAD';
       
        this.InvestigationMinsAccrued = ((Decimal)event.get('InvestigationMinsAccrued_CRMS__c')).intValue();
        this.TimesReOpened = ((Decimal)event.get('TimesReOpened_CRMS__c')).intValue();
        this.ExtensionOfCompletedInvMilestones = ((Decimal)event.get('ExtensionOfCompletedInvMilestones_CRMS__c')).intValue();
        this.CurrentMilestoneDuration = ((Decimal)event.get('CurrentMilestoneDuration_CRMS__c')).intValue();
        this.AccumulatedInvestigationsTime = ((Decimal)event.get('AccumulatedInvestigationsTime_CRMS__c')).intValue();
        
    }
}