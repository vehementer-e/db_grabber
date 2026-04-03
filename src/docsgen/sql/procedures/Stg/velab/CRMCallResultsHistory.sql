--exec [velab].[CRMCallResultsHistory] 
CREATE    procedure [velab].[CRMCallResultsHistory] 

as
begin

set nocount on

declare @DtFrom  datetime='40110101',@DtTo datetime='40210101'

set @DtTo=dateadd(year,2000,cast(getdate() as date))
set @DtFRom=dateadd(day,-20,@DtTo)


if object_id('tempdb.dbo.#rv') is not null drop table #rv
  select 
          Ссылка,	ВерсияДанных,	ПометкаУдаления,	ИмяПредопределенныхДанных,	Код=cast(Код as varchar(100)),Наименование=	cast(Наименование as varchar(1024)),	Успешный,	Collection,	Seller,	Сортировка,	ОбластьДанныхОсновныеДанные
          into #rv
           from 
         ----  [c1-vsr-sql04].crm.dbo.[Справочник_CM_РезультатыВзаимодействия] 
           _1cCRM.[Справочник_CM_РезультатыВзаимодействия] 


if OBJECT_ID('tempdb..#t_crm_buffer') is not null
	drop table #t_crm_buffer
create table #t_crm_buffer
(
	[ContractNo] [nvarchar](14) NULL,
	[MFOContractGUID] [nvarchar](100) NULL,
	[dt] [datetime2](0) NULL,
	[Comment] [nvarchar](max) NULL,
	[UserFIO] [nvarchar](100) NULL,
	[UserEmail] [nvarchar](255) NULL,
	[CRM_ClientFIO] [nvarchar](150) NULL,
	[CRM_ClientPassportSerial] [nvarchar](5) NULL,
	[CRM_ClientOassportNo] [nvarchar](6) NULL,
	[CRM_ClientPassportIssueDate] [datetime2](0) NULL,
	[CRM_ClientPassportIssueCode] [nvarchar](10) NULL,
	[CRM_ClientPassportIssuePlace] [nvarchar](500) NULL,
	[phoneNo] [nvarchar](100) NULL,
	[CRM_ClientMobilePhone] [nvarchar](16) NULL,
	[CRM_ClientContactPhone] [int] NULL,
	[CMRContractGUID] [nvarchar](100) NULL,
	[CRMRequestGUID] [nvarchar](100) NULL,
	[CRMClientGUID] [nvarchar](100) NULL,
	[crm_код] [varchar](256) NULL,
	[crm_успешный] [binary](1) NOT NULL,
	[Содержание] [nvarchar](max) NULL
)


insert into #t_crm_buffer
    
    
  SELECT 
  
  ContractNo                   = isnull(MFO_Contracts.Номер,CRM_Requests.Номер)
       , MFOContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(MFO_Contracts.Ссылка)  as nvarchar(100))
       , dt                           = DATEADD(YEAR,-2000,CRM_ClientTouch.дата)
       , Comment                      = CRM_ClientTouch.Комментарий


       , UserFIO                      = CRM_users.Наименование 
       , UserEmail                    = CRM_UserSettings.Значение_Строка
       , CRM_ClientFIO                = CRM_Clients.Наименование

       , CRM_ClientPassportSerial     = CRM_Requests.СерияПаспорта
       , CRM_ClientOassportNo         = CRM_Requests.НомерПаспорта

       , CRM_ClientPassportIssueDate  = CRM_Requests.ДатаВыдачи_Паспорта

       , CRM_ClientPassportIssueCode  = CRM_Requests.КодПодразделения_Паспорта

       , CRM_ClientPassportIssuePlace = CRM_Requests.КемВыдан_Паспорт
	   , phoneNo					  = CRM_TelCall.АбонентКакСвязаться
       , CRM_ClientMobilePhone        = CRM_Requests.МобильныйТелефон

       , CRM_ClientContactPhone       = null--CRM_Requests.ТелефонКонтактныйОсновной
       , CMRContractGUID              = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Contracts.Ссылка)  as nvarchar(100))
    --   , CMRRequestGUID   = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CMR_Requests.Ссылка)  as nvarchar(100))
       , CRMRequestGUID               = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)  as nvarchar(100))
       , CRMClientGUID                = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(100))
 
      , cast(rv.Код as varchar(256)) crm_код
      -- , rv.Период
       , rv.Успешный crm_успешный
        
       , CRM_ClientTouch.Содержание
  FROM  #rv  rv
        left join _1ccrm.[Документ_CRM_Взаимодействие] CRM_ClientTouch on rv.Ссылка=CRM_ClientTouch.РезультатCollection
	    left join _1cCRM.РегистрСведений_CRM_ДокументыВзаимодействия dv on  dv.взаимодействие=CRM_ClientTouch.ссылка
	    left join _1ccrm.[Документ_ТелефонныйЗвонок] CRM_TelCall on  CRM_TelCall.Ссылка=dv.Документ_Ссылка
        left join _1cCRM.[Документ_CM_ОбещаниеОплатить] oo on   oo.ВзаимодействиеОснование=CRM_ClientTouch.Ссылка
        left join _1ccrm.Справочник_Пользователи CRM_users  on  CRM_ClientTouch.Автор =CRM_users.Ссылка
        left join _1cCRM.[РегистрСведений_CRM_НастройкиПользователей] CRM_UserSettings on CRM_UserSettings.Пользователь=CRM_ClientTouch.Автор and Настройка=0xB81400155D4D107811E958A304CCCF4D

        left join  _1ccrm.[Справочник_Партнеры] CRM_Clients on CRM_Clients.Ссылка= CRM_ClientTouch.Партнер 
        left join _1cCRM.[Документ_ЗаявкаНаЗаймПодПТС] CRM_Requests on  CRM_Clients.Ссылка=CRM_Requests.Партнер
        left join _1cMFO.[Документ_ГП_Заявка] MFO_Requests  on CRM_Requests.Ссылка=MFO_Requests.Ссылка--CMR_Contracts.заявка
        left join _1cMFO.[Документ_ГП_Договор] MFO_Contracts on MFO_Requests.Ссылка=MFO_Contracts.Заявка
     
 --and CRM_ClientTouch.[Пометка удаления]=0x00

        left join  _1cCMR.[Справочник_Договоры] CMR_Contracts on  CMR_Contracts.ссылка= MFO_Contracts.ссылка
        left join   [_1cCMR].[Справочник_Заявка] CMR_Requests on CMR_Contracts.Заявка =CMR_Requests.Ссылка
       
      where CRM_ClientTouch.дата   >=@DtFrom  and CRM_ClientTouch.дата<=@DtTo
             and isnull(MFO_Contracts.Номер,CRM_Requests.Номер) is not null
  --    ORDER BY  MFO_Contracts.Номер


    delete from velab.crm_buffer
	insert into velab.crm_buffer(
		[ContractNo], [MFOContractGUID], [dt], [Comment], [UserFIO], [UserEmail], [CRM_ClientFIO], [CRM_ClientPassportSerial], [CRM_ClientOassportNo], [CRM_ClientPassportIssueDate], [CRM_ClientPassportIssueCode], [CRM_ClientPassportIssuePlace], [phoneNo], [CRM_ClientMobilePhone], [CRM_ClientContactPhone], [CMRContractGUID], [CRMRequestGUID], [CRMClientGUID], [crm_код], [crm_успешный], [Содержание]
		)
	select [ContractNo], [MFOContractGUID], [dt], [Comment], [UserFIO], [UserEmail], [CRM_ClientFIO], [CRM_ClientPassportSerial], [CRM_ClientOassportNo], [CRM_ClientPassportIssueDate], [CRM_ClientPassportIssueCode], [CRM_ClientPassportIssuePlace], [phoneNo], [CRM_ClientMobilePhone], [CRM_ClientContactPhone], [CMRContractGUID], [CRMRequestGUID], [CRMClientGUID], [crm_код], [crm_успешный], [Содержание]
	
	from #t_crm_buffer

end
