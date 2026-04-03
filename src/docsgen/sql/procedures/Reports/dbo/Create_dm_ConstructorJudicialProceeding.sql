-- exec [Create_dm_ConstructorCollection]
CREATE   PROC dbo.Create_dm_ConstructorJudicialProceeding
as

begin

set nocount on
SET XACT_ABORT ON

--drop table if exists dbo.dm_ConstructorJudicialProceeding
TRUNCATE TABLE dbo.dm_ConstructorJudicialProceeding

INSERT dbo.dm_ConstructorJudicialProceeding
(
    Id,
    UpdateDate,
    SubmissionClaimDate,
    AmountClaim,
    UpdatedBy,
    CreatedBy,
    CreateDate,
    CourtId,
    OutgoingRegistryRequirementNumber,
    OutgoingRequirementNumber,
    TotalRequirement,
    DealId,
    DocumentGuid,
    StatusCourtDetermination,
    IsFake,
    DepartamentFSSPId,
    DWHInsertedDate,
    ProcessGUID,
    IsCmrStateDutyClaimPackageSend
)
Select 
	Id,
    UpdateDate,
    SubmissionClaimDate,
    AmountClaim,
    UpdatedBy,
    CreatedBy,
    CreateDate,
    CourtId,
    OutgoingRegistryRequirementNumber,
    OutgoingRequirementNumber,
    TotalRequirement,
    DealId,
    DocumentGuid,
    StatusCourtDetermination,
    IsFake,
    DepartamentFSSPId,
    DWHInsertedDate,
    ProcessGUID,
    IsCmrStateDutyClaimPackageSend
--into dbo.dm_ConstructorJudicialProceeding
from [Stg]._Collection.JudicialProceeding

end
