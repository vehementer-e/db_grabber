CREATE   PROC dbo.Create_dm_ConstructorCustomersStatus
as

begin

set nocount on
SET XACT_ABORT ON


--drop table if exists dbo.dm_ConstructorCustomersStatus
TRUNCATE TABLE dbo.dm_ConstructorCustomersStatus

INSERT dbo.dm_ConstructorCustomersStatus
(
    [Идентификатор статуса клиента],
    CustomerId,
    [Статус клиента],
    BankruptConfirmed_BankruptcyFilingDate,
    DateResultOfCourtsDecisionBankrupt,
    BankruptConfirmed_InitiatorBankruptcy,
    BankruptConfirmed_NumberBankruptcyCaseInCourt,
    ResultOfCourtsDecisionBankrupt,
    BankruptcyFilingDate,
    CourtDecisionDate,
    CourtDecisionGranted,
    InitiatorBankruptcy,
    NumberBankruptcyCaseInCourt,
    ComplaintResponseDate,
    ComplaintSubstantiated,
    ComplaintSubstantiatedDate,
    DateOfComplaint,
    DenyCall,
    [Смерть подтвержденная],
    Comment,
    DateOfSendingApplicationToOVD,
    FakeDocuments,
    InaccurateInformation,
    PlaceOfWorkNotConfirmed,
    PledgedBy3persons,
    RealizationTransport,
    RegistrationResult,
    ResultApplicationReviewInOVDId,
    Wanted,
    RepresentativeAddress,
    RepresentativeFIO,
    RepresentativePhone,
    [Дата сообщения о смерти],
    [Дата снятия статуса],
    DenyCollectors,
    HardFraud_DenyCollectors,
    IsSetRealUserOfTheLoan,
    NameOfIdentifiedBorrower,
    ActionButtonsConfirmed,
    DateClose,
    DateOpen,
    Number,
    Provided,
    Date,
    ActivationDate,
    ActivatedBy
)
Select 
	[Идентификатор статуса клиента],
    CustomerId,
    [Статус клиента],
    BankruptConfirmed_BankruptcyFilingDate,
    DateResultOfCourtsDecisionBankrupt,
    BankruptConfirmed_InitiatorBankruptcy,
    BankruptConfirmed_NumberBankruptcyCaseInCourt,
    ResultOfCourtsDecisionBankrupt,
    BankruptcyFilingDate,
    CourtDecisionDate,
    CourtDecisionGranted,
    InitiatorBankruptcy,
    NumberBankruptcyCaseInCourt,
    ComplaintResponseDate,
    ComplaintSubstantiated,
    ComplaintSubstantiatedDate,
    DateOfComplaint,
    DenyCall,
    [Смерть подтвержденная],
    Comment,
    DateOfSendingApplicationToOVD,
    FakeDocuments,
    InaccurateInformation,
    PlaceOfWorkNotConfirmed,
    PledgedBy3persons,
    RealizationTransport,
    RegistrationResult,
    ResultApplicationReviewInOVDId,
    Wanted,
    RepresentativeAddress,
    RepresentativeFIO,
    RepresentativePhone,
    [Дата сообщения о смерти],
    [Дата снятия статуса],
    DenyCollectors,
    HardFraud_DenyCollectors,
    IsSetRealUserOfTheLoan,
    NameOfIdentifiedBorrower,
    ActionButtonsConfirmed,
    DateClose,
    DateOpen,
    Number,
    Provided,
    Date,
    ActivationDate,
    ActivatedBy
--into dbo.dm_ConstructorCustomersStatus
from [dwh2].[cubes].dim_ConstructorCustomersStatus

end
