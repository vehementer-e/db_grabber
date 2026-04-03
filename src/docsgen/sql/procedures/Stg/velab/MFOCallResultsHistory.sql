
--exec [velab].[MFOCallResultsHistory] 
-- Usage: запуск процедуры с параметрами
-- EXEC [velab].[MFOCallResultsHistory] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE     procedure [velab].[MFOCallResultsHistory] 
as
begin


--if object_id('velab.mfo_buffer') is not null drop table velab.mfo_buffer

declare @DtFrom datetime='40110101'
declare  @DtTo datetime='40210101'


set @DtTo=dateadd(year,2000,cast(getdate() as date))
set @DtFRom=dateadd(day,-20,@DtTo)


if object_id('tempdb..#t_mfo_buffer') is not null
	drop table #t_mfo_buffer


create table #t_mfo_buffer(
	[ContractNo] [nvarchar](14) NULL,
	[MFOContractGUID] [nvarchar](100) NULL,
	[dt] [datetime] NULL,
	[Comment] [ntext] NOT NULL,
	[CallResult] [nvarchar](150) NULL,
	[ContactType] [nvarchar](150) NULL,
	[UserFIO] [nvarchar](100) NULL,
	[UserEmail] [nvarchar](100) NULL,
	[MFO_ClientFIO] [ntext] NULL,
	[MFO_ClientPassportSerial] [nvarchar](20) NULL,
	[MFO_ClientOassportNo] [nvarchar](20) NULL,
	[MFO_ClientPassportIssueDate] [datetime] NULL,
	[MFO_ClientPassportIssueCode] [nvarchar](10) NULL,
	[MFO_ClientPassportIssuePlace] [nvarchar](200) NULL,
	[MFO_ClientMobilePhone] [nvarchar](13) NULL,
	[MFO_ClientContactPhone] [nvarchar](13) NULL,
	[CMRContractGUID] [nvarchar](100) NULL,
	[CRMRequestGUID] [nvarchar](100) NULL,
	[CRMClientGUID] [nvarchar](100) NULL
	)


insert into #t_mfo_buffer([ContractNo], [MFOContractGUID], [dt], [Comment], [CallResult], [ContactType], [UserFIO], [UserEmail], [MFO_ClientFIO], [MFO_ClientPassportSerial], [MFO_ClientOassportNo], [MFO_ClientPassportIssueDate], [MFO_ClientPassportIssueCode], [MFO_ClientPassportIssuePlace], [MFO_ClientMobilePhone], [MFO_ClientContactPhone], [CMRContractGUID], [CRMRequestGUID], [CRMClientGUID])
  SELECT ContractNo                   = MFO_Contracts.Номер 
       , MFOContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(MFO_Contracts.Ссылка)  as nvarchar(100))
       , dt                           = DATEADD(YEAR,-2000,MFO_RequestComments.Период)
       , Comment                      = MFO_RequestComments.Комментарий
       , CallResult                   = null
       , ContactType                   = null

       , UserFIO                      = MFO_users.Наименование 
       , UserEmail                    = MFO_users.АдресЭлектроннойПочты
       , MFO_ClientFIO                = MFO_Clients.НаименованиеПолное
       , MFO_ClientPassportSerial     = MFO_Clients.СерияПаспорта
       , MFO_ClientOassportNo         = MFO_Clients.НомерПаспорта
       , MFO_ClientPassportIssueDate  = MFO_Clients.ДатаВыдачиПаспорта
       , MFO_ClientPassportIssueCode  = MFO_Clients.КодПодразделения
       , MFO_ClientPassportIssuePlace = MFO_Contracts.КемВыдан
       , MFO_ClientMobilePhone        = MFO_Contracts.ТелефонМобильный
       , MFO_ClientContactPhone       = MFO_Contracts.ТелефонКонтактныйОсновной
       , CMRContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка)  as nvarchar(100))
    --   , CMRRequestGUID   = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Requests.Ссылка)  as nvarchar(100))
       , CRMRequestGUID               = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)  as nvarchar(100))
       , CRMClientGUID                = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(100))
      
  FROM _1cMFO.[РегистрСведений_ГП_КомментарииЗаявок] MFO_RequestComments
       left join _1cMFO.[Документ_ГП_Заявка] MFO_Requests on MFO_Requests.ссылка=MFO_RequestComments.Заявка
       left join _1cMFO.[Документ_ГП_Договор] MFO_Contracts on MFO_Requests.Ссылка=MFO_Contracts.Заявка
       left join _1cMFO.Справочник_Контрагенты MFO_Clients on MFO_Clients.ССылка=MFO_Contracts.Контрагент
       left join _1cMFO.Справочник_Пользователи MFO_users on MFO_users.ССылка=MFO_RequestComments.Пользователь_Ссылка
       left join _1cCRM.[Документ_ЗаявкаНаЗаймПодПТС] CRM_Requests on CRM_Requests.Ссылка=MFO_Requests.Ссылка--CMR_Contracts.заявка  
               ---- [c1-vsr-sql04].crm.[dbo].Документ_ЗаявкаНаЗаймПодПТС 
       left join _1cCRM.[Справочник_Партнеры]  CRM_Clients on  CRM_Clients.Ссылка=CRM_Requests.Партнер
      ---- [c1-vsr-sql04].crm.dbo.[Справочник_Партнеры] 
       left join _1cCMR.[Справочник_Договоры] CMR_Contracts on  CMR_Contracts.ссылка= MFO_Contracts.ссылка
       left join _1cCMR.[Справочник_Заявка] CMR_Requests on CMR_Contracts.Заявка =CMR_Requests.Ссылка
 where MFO_RequestComments.Период   >=@DtFrom  and MFO_RequestComments.Период<=@DtTo
 /* Т.к. таблица РегистрСведений_ВзаимодействияСКлиентами не обновляется, то данный блок не имеет смысла.
 union all
 SELECT ContractNo                   = MFO_Contracts.Номер 
       , MFOContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(MFO_Contracts.Ссылка)  as nvarchar(100))
       , dt                           =  DATEADD(YEAR,-2000,MFO_RequestComments.Период)
       , Comment                      = MFO_RequestComments.Комментарий
       
       , CallResult                   = t2.Наименование
       , ContactType                   = t3.Наименование

       , UserFIO                      = MFO_users.Наименование 
       , UserEmail                    = MFO_users.АдресЭлектроннойПочты
       , MFO_ClientFIO                = MFO_Clients.НаименованиеПолное
       , MFO_ClientPassportSerial     = MFO_Clients.СерияПаспорта
       , MFO_ClientOassportNo         = MFO_Clients.НомерПаспорта
       , MFO_ClientPassportIssueDate  = MFO_Clients.ДатаВыдачиПаспорта
       , MFO_ClientPassportIssueCode  = MFO_Clients.КодПодразделения
       , MFO_ClientPassportIssuePlace = MFO_Contracts.КемВыдан
       , MFO_ClientMobilePhone        = MFO_Contracts.ТелефонМобильный
       , MFO_ClientContactPhone       = MFO_Contracts.ТелефонКонтактныйОсновной
       , CMRContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка)  as nvarchar(100))
    --   , CMRRequestGUID   = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Requests.Ссылка)  as nvarchar(100))
       , CRMRequestGUID               = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)  as nvarchar(100))
       , CRMClientGUID                = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(100))
  FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ВзаимодействияСКлиентами] MFO_RequestComments
  left join [prodsql02].[mfo].[dbo].[Справочник_РезультатыЗвонков] t2 on MFO_RequestComments.РезультатЗвонка=t2.ссылка
  left join  [prodsql02].[mfo].[dbo].[Справочник_ТипыКонтактовВзаимодействияСКлиентом] t3 on t3.ссылка=MFO_RequestComments.ТипКонтакта

       left join _1cMFO.[Документ_ГП_Заявка] MFO_Requests on MFO_Requests.ссылка=MFO_RequestComments.Заявка
       left join _1cMFO.[Документ_ГП_Договор] MFO_Contracts on MFO_Requests.Ссылка=MFO_Contracts.Заявка
       left join _1cMFO.Справочник_Контрагенты MFO_Clients on MFO_Clients.ССылка=MFO_Contracts.Контрагент
       left join _1cMFO.Справочник_Пользователи MFO_users on MFO_users.ССылка=MFO_RequestComments.Автор
	   left join _1cCMR.[dbo].Документ_ЗаявкаНаЗаймПодПТС CRM_Requests on CRM_Requests.Ссылка=MFO_Requests.Ссылка--CMR_Contracts.заявка
	   left join _1cCMR.dbo.[Справочник_Партнеры]  CRM_Clients on  CRM_Clients.Ссылка=CRM_Requests.Партнер
       left join _1cCMR.[dbo].[Справочник_Договоры] CMR_Contracts on  CMR_Contracts.ссылка= MFO_Contracts.ссылка
       left join _1cCMR.[Справочник_Заявка] CMR_Requests on CMR_Contracts.Заявка =CMR_Requests.Ссылка
 where MFO_RequestComments.Период   >=@DtFrom  and MFO_RequestComments.Период<=@DtTo
 */
 delete from [velab].[mfo_buffer]
 insert into [velab].[mfo_buffer]([ContractNo], [MFOContractGUID], [dt], [Comment], [CallResult], [ContactType], [UserFIO], [UserEmail], [MFO_ClientFIO], [MFO_ClientPassportSerial], [MFO_ClientOassportNo], [MFO_ClientPassportIssueDate], [MFO_ClientPassportIssueCode], [MFO_ClientPassportIssuePlace], [MFO_ClientMobilePhone], [MFO_ClientContactPhone], [CMRContractGUID], [CRMRequestGUID], [CRMClientGUID])
 select [ContractNo], 
 [MFOContractGUID], 
 [dt], 
 [Comment], 
 [CallResult], 
 [ContactType], 
 [UserFIO], 
 [UserEmail], 
 [MFO_ClientFIO], 
 [MFO_ClientPassportSerial], 
 [MFO_ClientOassportNo], 
 [MFO_ClientPassportIssueDate], 
 [MFO_ClientPassportIssueCode], 
 [MFO_ClientPassportIssuePlace], 
 [MFO_ClientMobilePhone], 
 [MFO_ClientContactPhone], 
 [CMRContractGUID], 
 [CRMRequestGUID],
 [CRMClientGUID]
 
 from #t_mfo_buffer


 --ORDER BY   3
end
