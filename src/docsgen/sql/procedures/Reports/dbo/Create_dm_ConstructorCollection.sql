-- exec [Create_dm_ConstructorCollection]
CREATE PROC dbo.Create_dm_ConstructorCollection
as

begin

set nocount on
SET XACT_ABORT ON


--drop table if exists dbo.dm_ConstructorCollection
--DWH-1764
TRUNCATE TABLE dbo.dm_ConstructorCollection
INSERT dbo.dm_ConstructorCollection
(
    [Контакт id],
    [Тип контакта],
    [Тип контактного лица],
    [Фио контакта],
    [Вид контакта],
    Client_id,
    [ФИО Клиента],
    IdCollectingStage,
    IdCustomerType,
    ClaimantId,
    [Телефон клиента],
    ClaimantLegalId,
    StatusNameList,
    ClaimantExecutiveProceedingId,
    [Дата рождения ПД],
    deal_id,
    TableName,
    CustomerId,
    ContactName,
    ContactData,
    IsOperative,
    Комментарий,
    [Дата выдачи],
    [Идентификатор перехода],
    TransitionDate,
    dpd,
    [Старая стадия клиента],
    [Новая стадия клиента],
    [Отв. взыскатель на старой стадии],
    [Отв. взыскатель на новой стадии],
    [Причина перехода на новую стадию],
    CommunicationDate,
    Commentary,
    [Ответственный взыскатель],
    [Куратор СП],
    [Куратор ИП],
    [Идентификатор статуса клиента],
    [Идентификатор передачи в КА],
    jp_id,
    jc_id,
    eo_id,
    ep_id,
    monitoring_id,
    dpi_id,
    pl_id,
    timefromsubmissiontoreceiptjudge_jc,
    timetoaccept_eo,
    timetoreceipt_eo,
    first_rn_client
)
Select 
	[Контакт id],
    [Тип контакта],
    [Тип контактного лица],
    [Фио контакта],
    [Вид контакта],
    Client_id,
    [ФИО Клиента],
    IdCollectingStage,
    IdCustomerType,
    ClaimantId,
    [Телефон клиента],
    ClaimantLegalId,
    StatusNameList,
    ClaimantExecutiveProceedingId,
    [Дата рождения ПД],
    deal_id,
    TableName,
    CustomerId,
    ContactName,
    ContactData,
    IsOperative,
    Комментарий,
    [Дата выдачи],
    [Идентификатор перехода],
    TransitionDate,
    dpd,
    [Старая стадия клиента],
    [Новая стадия клиента],
    [Отв. взыскатель на старой стадии],
    [Отв. взыскатель на новой стадии],
    [Причина перехода на новую стадию],
    CommunicationDate,
    Commentary,
    [Ответственный взыскатель],
    [Куратор СП],
    [Куратор ИП],
    [Идентификатор статуса клиента],
    [Идентификатор передачи в КА],
    jp_id,
    jc_id,
    eo_id,
    ep_id,
    monitoring_id,
    dpi_id,
    pl_id,
    timefromsubmissiontoreceiptjudge_jc,
    timetoaccept_eo,
    timetoreceipt_eo,
	first_rn_client = ROW_NUMBER() over(partition by client_id,jc_id order by (select null))
--into dbo.dm_ConstructorCollection
from [dwh2].[cubes].[vc_ConstructorCollection]

end
