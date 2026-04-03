CREATE   PROC dbo.Create_dm_ConstructorEnforcementOrders
as

begin

set nocount on
SET XACT_ABORT ON

--drop table if exists reports.dbo.dm_ConstructorEnforcementOrders
TRUNCATE TABLE reports.dbo.dm_ConstructorEnforcementOrders

INSERT reports.dbo.dm_ConstructorEnforcementOrders
(
    Id,
    UpdatedBy,
    CreatedBy,
    CreateDate,
    UpdateDate,
    ReceiptDate,
    Number,
    Amount,
    Accepted,
    Comment,
    JudicialClaimId,
    AcceptanceDate,
    ReceiptCheckDate,
    ReceiptClaimAmount,
    ReceiptInitCostCollateral,
    ReceiptReturnDate,
    Date,
    ErrorCorrectionNumberDate,
    ErrorCorrectionSubmissionRegistryNumber,
    StartCorrectionNumber,
    AmountRequirementsPledge,
    ClaimJPForm,
    InterimMeasures,
    InterimMeasuresComment,
    Type,
    NewOwner
)
Select 
	Id,
    UpdatedBy,
    CreatedBy,
    CreateDate,
    UpdateDate,
    ReceiptDate,
    Number,
    Amount,
    Accepted,
    Comment,
    JudicialClaimId,
    AcceptanceDate,
    ReceiptCheckDate,
    ReceiptClaimAmount,
    ReceiptInitCostCollateral,
    ReceiptReturnDate,
    Date,
    ErrorCorrectionNumberDate,
    ErrorCorrectionSubmissionRegistryNumber,
    StartCorrectionNumber,
    AmountRequirementsPledge,
    ClaimJPForm,
    InterimMeasures,
    InterimMeasuresComment,
    Type,
    NewOwner
--into reports.dbo.dm_ConstructorEnforcementOrders
from [Stg]._Collection.EnforcementOrders

end
