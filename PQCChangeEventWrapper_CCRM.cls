public with sharing class PQCChangeEventWrapper_CCRM {
    public static final String RECORD_TYPE_ID = '0121t000000EM2cAAG';
    
    public Decimal QuantityOfProduct_GxP_CRMS { get; set; }
    public String RelatedCase_GxP_CRMS { get; set; }
    public String DidConsumerAgreeToReturnSample_GxP_CRMS { get; set; }
    public String Name { get; set; }
    public String Reason_Code_L3_GxP_CRMS { get; set; }
    public String Verbatim_GxP_CRMS { get; set; }
    public String RecordTypeId { get { return RECORD_TYPE_ID; } }
    public String Reason_Code_L1_GxP_CRMS { get; set; }
    public String Reason_Code_L2_GxP_CRMS { get; set; }
    public Decimal SitesCount_CRMS { get; set; }
    public String PrimaryPackageLot_GxP_CRMS { get; set; }
    public String HSIAE_CRMS { get; set; }
    public Id RelatedCaseId { get; set; }
    public String ExternalCCRMId { get; set; }
    public String ProductSite_GxP_CRMS { get; set; }
    public String ProductSKU_GxP_CRMS { get; set; }
    public String Country_GxP_CRMS { get; set; }
    public String Safety_ID_GxP_CRMS { get; set; }
    public String RelatedHSIAE_GxP_CRMS { get; set; }
    public String HSI_Description { get; set; }

    public PQCChangeEventWrapper_CCRM() {
    }


    public void updateRelatedCaseExternalId(String externalId) {
        if (externalId != null) {
            this.RelatedCase_GxP_CRMS = externalId;
        }
    }
}