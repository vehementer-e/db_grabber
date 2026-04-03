
-- exec [etl].[CRMClients_references_into_staging]
CREATE procedure [etl].[CRMClients_references_into_staging]
as



 
begin try
           


	-- Адрес постоянной регистрации и  Адрес фактического проживания из CRM   
	 if object_id('tempdb.dbo.#R_CRM_Request') is not null drop table #R_CRM_Request  
	  select *  into #R_CRM_Request 
	  from   
	  ----[c1-vsr-sql04].crm.[dbo].Документ_ЗаявкаНаЗаймПодПТС 
	  stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС 
	  CRM_Request  

	  where НомерЗаявки<>'' 
	  select count(*) FROM    #R_CRM_Request
 
	 if object_id('tempdb.dbo.#R_CRM_Clients') is not null drop table #R_CRM_Clients   
	  select * into #R_CRM_Clients 
	  from 
	  ----[c1-vsr-sql04].crm.dbo.[Справочник_Партнеры] 
	  stg._1cCRM.[Справочник_Партнеры] 
	  CRM_Clients 
 
	 if object_id('tempdb.dbo.#R_CRM_Clients_ContactInfo') is not null drop table #R_CRM_Clients_ContactInfo  
	  select * into #R_CRM_Clients_ContactInfo 
	  from 
	 ---- [c1-vsr-sql04].crm.dbo.[Справочник_Партнеры_контактнаяИнформация] 
	  stg._1cCRM.[Справочник_Партнеры_контактнаяИнформация] 
	  CRM_Clients_ContactInfo 
 
	 if object_id('tempdb.dbo.#R_CRM_ContactInfo_Type') is not null drop table #R_CRM_ContactInfo_Type  
	  select * into #R_CRM_ContactInfo_Type 
	  from 
	  ----[c1-vsr-sql04].crm.dbo.Справочник_ВидыКонтактнойИнформации 
	  stg._1cCRM.Справочник_ВидыКонтактнойИнформации 
	  CRM_ContactInfo_Type 

	 if object_id('tempdb.dbo.#R_business_reg') is not null drop table #R_business_reg  
	  select * into #R_business_reg from 
	  ----[c1-vsr-sql04].crm.dbo.[Справочник_БизнесРегионы] 
	  stg._1cCRM.[Справочник_БизнесРегионы] 
	  business_reg 

	 if object_id('tempdb.dbo.#R_CRM_Request_Status') is not null drop table #R_CRM_Request_Status  
	  select * into #R_CRM_Request_Status from 
	  ----[c1-vsr-sql04].crm.dbo.Справочник_СтатусыЗаявокПодЗалогПТС 
	  stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС 
	  CRM_Request_Status


	if object_id('tempdb.dbo.#R_All_clients') is not null drop table #R_All_clients
	 SELECT  CRM_Request.Номер Number
 		  , CRM_Request.Дата Дата
		  , CRM_Request_Status.Наименование [RequestStatus]
		  , cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(100))  CRMClientGUID
		  , concat(CRM_Request.Фамилия,' ',CRM_Request.Имя,' ',CRM_Request.Отчество)    fio
		  , CRM_Request.АдресПроживания  
		  , business_reg.Наименование Наименование_РегионФактическогоПроживания
		  , case when CRM_ContactInfo_Type.Наименование =N'Адрес постоянной регистрации' then CRM_Clients_ContactInfo.Представление else null end [Адрес постоянной регистрации]
		  , case when CRM_ContactInfo_Type.Наименование =N'Адрес фактического проживания' then CRM_Clients_ContactInfo.Представление else null end [Адрес фактического проживания]
		  --, CRM_ContactInfo_Type.Наименование
		  into #R_All_clients
	  FROM #R_CRM_Request CRM_Request
	 inner join #R_CRM_Clients CRM_Clients on  CRM_Clients.Ссылка=CRM_Request.Партнер
	  left join #R_CRM_Clients_ContactInfo CRM_Clients_ContactInfo on  CRM_Clients_ContactInfo.Ссылка=CRM_Request.Партнер
	  left join #R_CRM_ContactInfo_Type CRM_ContactInfo_Type on CRM_ContactInfo_Type.Ссылка = CRM_Clients_ContactInfo.Вид
	  left join #R_business_reg  business_reg on business_reg.Ссылка=CRM_Clients.РегионФактическогоПроживания
	 inner join #R_CRM_Request_Status CRM_Request_Status on CRM_Request.Статус = CRM_Request_Status.Ссылка 
	 where CRM_ContactInfo_Type.Наименование in (N'Адрес постоянной регистрации',N'Адрес фактического проживания')
 
 

	if object_id('tempdb.dbo.#R_crm_addresses') is not null drop table #R_crm_addresses
	 ;
	with addr_reg as (
	select number,   [Адрес постоянной регистрации] from (
	 select Number
		  , row_number()  over (partition by number order by [Адрес постоянной регистрации])  rn
		  , [Адрес постоянной регистрации]
	  from #R_All_clients
	)q where q.rn>1
	)
	, 
	 addr_fact as (
	select number,   [Адрес фактического проживания] from (
	 select Number
		  , row_number()  over (partition by number order by [Адрес фактического проживания])  rn
		  , [Адрес фактического проживания]
	  from #R_All_clients
	)q where q.rn>1
	)

	  select  distinct
	 s1.Number
	 --,cl.RequestStatus
	 --,
	 ,s1.CRMClientGUID
	 ,s1.fio
	 --,cl.АдресПроживания
	 --,cl.Наименование_РегионФактическогоПроживания
	,s1.[Адрес постоянной регистрации]
	,s1.[Адрес фактического проживания]

	into #R_crm_addresses

	   from (SELECT 
			 cl.Number
			 --,cl.RequestStatus
			 --,
			 ,cl.CRMClientGUID
			 ,cl.fio
			 --,cl.АдресПроживания
			 --,cl.Наименование_РегионФактическогоПроживания
			,ar.[Адрес постоянной регистрации]
			,af.[Адрес фактического проживания] 
			, row_number()  over (partition by cl.Number order by cl.Дата desc)  rn  
			   FROM (select distinct  cl.Number

					 ,cl.Дата
					 ,cl.RequestStatus
					 ,cl.CRMClientGUID
					 ,cl.fio
					 ,cl.АдресПроживания
					 ,cl.Наименование_РегионФактическогоПроживания from #R_All_clients cl )cl
			   join addr_reg ar on ar.Number=cl.Number
			   join addr_fact af on ar.number=af.number
			where   cl.RequestStatus in 
			(
			 N'Одобрено'
			,N'Договор зарегистрирован'
			,N'Проблемный'
			,N'Просрочен'
			,N'Платеж опаздывает'
			,N'Заем погашен'
			,N'Договор подписан'
			,N'Контроль получения ДС'
			,N'Заем выдан')
	) s1
	where s1.rn=1 -- берем только первый адрес 


	if object_id('staging.CRMClients_references') is not null truncate table staging.CRMClients_references

	insert into  staging.CRMClients_references

	SELECT 
		  CRMRequestFIO as CRMClientFIO
		, Format(dateadd(year,-2000,[ДатаРождения]),'dd.MM.yyyy') as ДатаРождения
		, [МобильныйТелефон] as МобильныйТелефон
		, [Адрес постоянной регистрации] as 'Адрес регистрации'
		, [Адрес фактического проживания]  as 'Адрес проживания'
		, [СерияПаспорта] as 'Паспорт серия'
		, [НомерПаспорта] as 'Паспорт номер'
		, ClientsRaw.CRMClientIDRREF
		, ClientsRaw.CRMClientGUID as CRMClientGUID

	FROM
	(
	  SELECT CRM_Requests.Номер		CRMRequestNumber
		  -- , CRM_Requests.Дата		CRMRequestDateTime     
		   , CRM_Clients.ссылка		CRMClientIDRREF
		   , CRMClientGUID    = cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(CRM_Clients.Ссылка)  as nvarchar(64))
		  -- , CRMClientFIO=CRM_Clients.Наименование
		   ,  CRMRequestFIO=ltrim(rtrim(CRM_Requests.Фамилия))+' '+ltrim(rtrim(CRM_Requests.Имя))+' '+ltrim(rtrim(CRM_Requests.Отчество))
		   , LAST_NUM = FIRST_VALUE(CRM_Requests.Номер) over(Partition by CRM_Clients.ссылка order by CRM_Requests.Дата desc) 
		   , CRM_Requests.МобильныйТелефон
		   , CRM_Requests.ДатаРождения 
		   , CRM_Requests.НомерПаспорта
		   , CRM_Requests.СерияПаспорта

	  FROM   #R_CRM_Clients CRM_Clients
			 left join #R_CRM_Request  CRM_Requests on  CRM_Clients.Ссылка=CRM_Requests.Партнер
		
			 where CRM_Requests.Партнер is not null

	) ClientsRaw 
	left join #R_crm_addresses Adresses
	on Adresses.Number = ClientsRaw.CRMRequestNumber
	Where ClientsRaw.CRMRequestNumber = LAST_NUM

end try

begin catch
           
	if @@TRANCOUNT>0
		rollback tran;	
	;throw

end catch


