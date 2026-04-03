CREATE   PROC dbo.Create_dm_ConstructorDeals_KA_History
as

begin

set nocount on
SET XACT_ABORT ON

--drop table if exists dbo.dm_ConstructorDeals_KA_History
TRUNCATE TABLE dbo.dm_ConstructorDeals_KA_History

INSERT dbo.dm_ConstructorDeals_KA_History
(
    IdCustomer,
    CustomerFio,
    IdDeal,
    NameKA,
    PhoneKA,
    ReestrNumber,
    DealNumber,
    KaTransferDt,
    PlannedReviewDt,
    TransferredDebtAmount,
    IsPaid,
    KaReturnDt,
    CallDt,
    CallReason,
    OutgoingNotificationNumber,
    NotificationDate,
    OutgoingRegistryNumber,
    IsActive,
    rn
)
Select 
	IdCustomer,
    CustomerFio,
    IdDeal,
    NameKA,
    PhoneKA,
    ReestrNumber,
    DealNumber,
    KaTransferDt,
    PlannedReviewDt,
    TransferredDebtAmount,
    IsPaid,
    KaReturnDt,
    CallDt,
    CallReason,
    OutgoingNotificationNumber,
    NotificationDate,
    OutgoingRegistryNumber,
    IsActive,
    rn 
--into dbo.dm_ConstructorDeals_KA_History
from [dwh2].[cubes].dim_ConstructorDeals_KA_History


end
