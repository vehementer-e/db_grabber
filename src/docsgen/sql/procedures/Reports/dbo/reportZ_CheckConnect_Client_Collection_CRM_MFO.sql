-- =============================================
-- Author:		Kurdin S
-- Create date: 2020-06-10
-- Description:	Отчет о телефонах клиентов в Коллекшн, СРМ и МФО 

-- =============================================

CREATE PROCEDURE [dbo].[reportZ_CheckConnect_Client_Collection_CRM_MFO]
	-- Add the parameters for the stored procedure here

@PageNo int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


-------- Данные из Коллекшн

drop table if exists #collection_cust
select 
		Id CustId
		,([LastName]+' '+[Name]+' '+[MiddleName]) FioCustomer
		,CrmCustomerId
into #collection_cust
-- select *
from [Stg].[_Collection].[Customers]


drop table if exists #collection_cust_cont
select [Id]
      ,[Phone]
      ,[IsOperative]
      ,[IdContactType]
      ,[IdCustomer]
      ,[ContactPersonType]
      ,[Fio] [FioContact]
      ,[CommunicationCustomerTypeId]
      ,[IsConfirmedDataContactPerson]
into #collection_cust_cont
-- select *
from [Stg].[_Collection].[CustomerContact]
where [IsOperative] = 0

-- select * from #collection_cust_cont

drop table if exists #collection_cust_crmid
select * into #collection_cust_crmid from #collection_cust_cont cn left join #collection_cust cs on cn.IdCustomer = cs.CustId

drop table if exists #collection_cust_crmid_2
select CustId [Id]
--      ,IdCustomer
	  ,CustId 
	  ,CrmCustomerId
	  ,FioCustomer
	  ,[FioContact]
	  ,[Phone]
      ,[IsOperative]
      ,[IdContactType]
      ,[ContactPersonType]
      ,[CommunicationCustomerTypeId]
      ,[IsConfirmedDataContactPerson] 
into #collection_cust_crmid_2
from #collection_cust_crmid

drop table if exists #collection_CRMClient_references
select * 
into #collection_CRMClient_references
from dwh_new.[staging].[CRMClient_references] r 
join #collection_cust_crmid_2 c on r.CRMClientGUID = c.CrmCustomerId

drop table if exists #collection_CRM_MFO_references
select --[Id],
	  CustId
	  ,CrmCustomerId
	  ,MFORequestNumber
	  ,FioCustomer
	  ,[FioContact]
      ,[ContactPersonType]
      ,[CommunicationCustomerTypeId]
      ,[IdContactType]
	  ,[Phone]
      ,[IsOperative]

      ,[IsConfirmedDataContactPerson]
	  ,CRMClientIDRREF
	  ,CRMClientFIO
	  ,MFOContractFIO

into #collection_CRM_MFO_references
from #collection_CRMClient_references



-------- Данные из СРМ

drop table if exists #crm_tip_contact
select [Ссылка]
      ,[ПометкаУдаления]
      ,[Наименование] [РольНаим]
      ,[Описание]
into #crm_tip_contact  
  from Stg._1ccrm.[Справочник_РолиКонтактныхЛицПартнеров]

--  select * from #crm_tip_contact

drop table if exists #crm_vid_contact
select [Ссылка]
      ,[ПометкаУдаления]
      ,[ИмяПредопределенныхДанных]
      ,[Родитель]
      ,[ЭтоГруппа]
      ,[Наименование]
      ,[АдресТолькоРоссийский]
      ,[ВидПоляДругое]
      ,[ВключатьСтрануВПредставление]
      ,[ЗапретитьРедактированиеПользователем]
      ,[Используется]
      ,[МожноИзменятьСпособРедактирования]
      ,[ОбязательноеЗаполнение]
      ,[ПроверятьКорректность]
      ,[ПроверятьПоФИАС]
      ,[РазрешитьВводНесколькихЗначений]
      ,[РедактированиеТолькоВДиалоге]
      ,[РеквизитДопУпорядочивания]
      ,[СкрыватьНеактуальныеАдреса]
      ,[ТелефонCДобавочнымНомером]
      ,[Тип]
      ,[УдалитьМногострочноеПоле]
      ,[УказыватьОКТМО]
      ,[ХранитьИсториюИзменений]
      ,[CRM_ИспользоватьДляОповещений]
      ,[CRM_Основной]
into #crm_vid_contact
  from [Stg].[_1cCRM].[Справочник_ВидыКонтактнойИнформации]

drop table if exists #crm_partner
select 
	   [Ссылка] [СсылкаКлиента]
      ,([CRM_Фамилия]+' '+[CRM_Имя]+' '+[CRM_Отчество]) [ФИО_Клиента]
      ,[ПометкаУдаления]

      ,[Родитель]
      ,[ЭтоГруппа]
      ,[Код]
      ,[Наименование]
      ,[НаименованиеПолное]
      ,[Пол]
      ,[ЮрФизЛицо]
      ,[CRM_ОсновноеКонтактноеЛицо]
      ,[CRM_ФизЛицо]
      ,[НомерАБС]
       
into #crm_partner
from Stg.[_1cCRM].[Справочник_Партнеры]


drop table if exists #crm_contact_face
select 
	   f.[Ссылка]

	  ,f.[Наименование] [ФИО_КонтактногоЛица]
	  --,p2.[ФИО_Клиента] [ФИО_КонтактногоЛица2]
	  ,t.[РольНаим]
      --,[ПометкаУдаления]
      ,[Владелец]
	  ,p.[СсылкаКлиента]
	  ,p.[ФИО_Клиента]
      
      ,f.[Комментарий]
      --,f.[Пол]
      ,f.[ДатаРождения]
      ,f.[CRM_Взаимодействия]

      ,f.[CRM_Должность]
      --,f.[CRM_Заказчик]
      --,f.[CRM_Ключевой]

      --,f.[CRM_Противник]
      --,f.[CRM_РольКонтактногоЛица]
      ,f.[CRM_Состояние]
      --,f.[CRM_Спонсор]
      --,f.[CRM_Сторонник]
      ,f.[CRM_ТипОтношенийПредставление]
       
into #crm_contact_face 
--select *
from Stg._1ccrm.[Справочник_КонтактныеЛицаПартнеров] f
left join #crm_partner p on p.[СсылкаКлиента] = f.[Владелец]
--left join #partner p2 on p2.[СсылкаКлиента] = f.[Ссылка]
	left join #crm_tip_contact t on t.[Ссылка] = f.[CRM_РольКонтактногоЛица]

--  select * from #crm_contact_face where [ФИО_КонтактногоЛица]<>[ФИО_Клиента]

drop table if exists #crm_contact_info
select k.[Ссылка]

      ,[СсылкаКлиента]
	  ,[ФИО_Клиента]
	  ,[ФИО_КонтактногоЛица]
	  ,[РольНаим]
	  --,[НомерСтроки]
      ,k.[Тип]
	  --,t.[Наименование]
  --    ,[Вид]  
	  ,c.[Наименование] [Вид_Наим]
      ,[Представление]
      --,[ЗначенияПолей]
      --,[АдресЭП]
      --,[ДоменноеИмяСервера]
      ,[НомерТелефона]
      ,[НомерТелефонаБезКодов]
      ,[CRM_ОсновнойДляСвязи]
      --,[ИнформацияДляМФО]
      ,[Актуальный]
	  --,c.*
into #crm_contact_info
from [Stg].[_1cCRM].[Справочник_КонтактныеЛицаПартнеров_КонтактнаяИнформация] k
left join #crm_contact_face f on f.[Ссылка] = k.[Ссылка]
  left join #crm_vid_contact c on k.[Вид]=c.[Ссылка]
--	left join #tip_contact t on t.[Ссылка] = k.[Тип]
  --join (select top(100) [Ссылка] from [Stg].[_1cCRM].[Справочник_Партнеры]) p on p.[Ссылка] = k.[Ссылка]


drop table if exists #crm_contact_info_res
select distinct
      --Id,
	  CustId
	  ,CrmCustomerId
	  ,[MFORequestNumber]
	  --,crm.[Ссылка]
	  --,crm.[СсылкаКлиента]
	  ,crm.[ФИО_Клиента]
	  ,crm.[ФИО_КонтактногоЛица]
	  ,isnull(crm.[РольНаим],'Клиент') [Роль]
	  --,crm.[Тип]
	  ,crm.[Вид_Наим] [Вид связи]
      --,crm.[Представление]
      --,crm.[НомерТелефона]
      ,crm.[НомерТелефонаБезКодов] [НомерТелефона]
      ,crm.[CRM_ОсновнойДляСвязи]
      ,crm.[Актуальный]
into #crm_contact_info_res	  
from #crm_contact_info crm
join #collection_CRM_MFO_references col on  crm.[СсылкаКлиента] =col.[CRMClientIDRREF]
where not [Вид_Наим] in ('E-mail для рассылки' ,'Электронная почта') --and [ФИО_КонтактногоЛица]<>[ФИО_Клиента]

--select * from #crm_contact_info_res

-------- Данные из МФО
drop table if exists #mfo_contact_info
select --Id,
   CustId,
   CrmCustomerId,
   a.Номер as external_id,
   [КонтрагентКлиент],
   ([Фамилия]+' '+[Имя]+' '+[Отчество]) [ФИО клиента],
   (case when a.ТелефонМобильный = ''                then 'Nan' else a.ТелефонМобильный end)                as [ТелефонМобильный],
   (case when a.ТелефонСупруги = ''                  then 'Nan' else ТелефонСупруги end)                    as [ТелСупруги],
   (case when a.ТелефонАдресаПроживания = ''         then 'Nan' else a.ТелефонАдресаПроживания end)         as [ТелефонАдресаПроживания],
   (case when a.ТелефонКонтактныйОсновной = ''       then 'Nan' else a.ТелефонКонтактныйОсновной end)       as [ТелефонКонтактныйОсновной],
   (case when a.ТелефонКонтактныйДополнительный = '' then 'Nan' else a.ТелефонКонтактныйДополнительный end) as [ТелефонКонтактныйДополнительный],
   (case when a.КЛТелМобильный = ''                  then 'Nan' else a.КЛТелМобильный end)                  as [КонтактноеЛицоТелМобильный],
   (case when a.КЛТелКонтактный = ''                 then 'Nan' else a.КЛТелКонтактный end)                 as [КонтактноеЛицоТелКонтактный],
   (case when a.ТелМобильныйРуководителя = ''        then 'Nan' else a.ТелМобильныйРуководителя end)        as [ТелМобильныйРуководителя],
   (case when a.ТелРабочийРуководителя = ''          then 'Nan' else a.ТелРабочийРуководителя end)          as [ТелРабочийРуководителя],
   (case when a.ЭлектроннаяПочта = ''                then 'Nan' else a.ЭлектроннаяПочта end)                as email,
   row_number() over (partition by a.Номер order by a.Номер) as rn

into #mfo_contact_info
-- select * 
from [Stg].[_1cMFO].[Документ_ГП_Заявка] a
join (select * from #collection_CRMClient_references) col on  a.[Номер] =col.[MFOContractNumber]

---
delete from dbo.z_dwh549_client_tel_collection

insert into dbo.z_dwh549_client_tel_collection
select *
--into dbo.z_dwh549_client_tel_collection
from #collection_CRM_MFO_references order by 1 desc

-----
delete from dbo.z_dwh549_client_tel_crm

insert into dbo.z_dwh549_client_tel_crm
select *
--into dbo.z_dwh549_client_tel_crm
from #crm_contact_info_res order by 1 desc

-----
delete from dbo.z_dwh549_client_tel_mfo

insert into dbo.z_dwh549_client_tel_mfo
select *
--into dbo.z_dwh549_client_tel_mfo
from #mfo_contact_info order by 1 desc


/*

if @PageNo = 1

select top(10000) *
from #collection_CRM_MFO_references order by 1 desc


if @PageNo = 2

select top(10000) * 
from #crm_contact_info_res order by 1 desc


if @PageNo = 3

select top(10000) * 
from #mfo_contact_info order by 1 desc

*/
END
