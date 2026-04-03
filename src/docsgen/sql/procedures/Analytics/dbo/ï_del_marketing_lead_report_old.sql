
/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE   PROC-- exec
[dbo].[create_report_leads_full]
@mode nvarchar(max) = 'hard'
as
begin

return


 EXEC sp_refreshview 'v_report_leads_full'
 
 --declare @mode nvarchar(max) = 'hard'
 declare @start_date date = case 
 when @mode = 'hard' then (select min(UF_REGISTERED_AT_date) from dm_lcrm_leads_for_report where UF_REGISTERED_AT_date>=getdate()-40)
 when @mode = 'full' then (select min(UF_REGISTERED_AT_date) from dm_lcrm_leads_for_report)			  
 when @mode = 'hard' then (select min(UF_REGISTERED_AT_date) from dm_lcrm_leads_for_report)
 when @mode = 'full' then '20210101'
 end


 if day(getdate())=1
 begin

 set @start_date = '20210101'
 set @start_date = (select min(UF_REGISTERED_AT_date) from dm_lcrm_leads_for_report)		


 end

-- set @start_date = '20240701'


 --select max(created) from v_report_leads_full
declare @a nvarchar(max) = 'report_leads_full started'+' start_date ='+format(@start_date, 'dd.MM.yyyy')+' (num_of_days ='+format(datediff(day, @start_date, getdate()),  '0')+')'
exec log_email @a, 'p.ilin@techmoney.ru'

drop table if exists #TMP_leads
CREATE TABLE #TMP_leads(
	[ID] [numeric](10, 0) NULL,
--	[UF_NAME] [varchar](512) NULL,
	--[UF_PHONE] [varchar](128) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
--	[UF_UPDATED_AT] [datetime2](7) NULL,
--	[UF_ROW_ID] [varchar](128) NULL,
--	[UF_AGENT_NAME] [varchar](128) NULL,
	[UF_STAT_CAMPAIGN] [varchar](512) NULL,
--	[UF_STAT_CLIENT_ID_YA] [varchar](128) NULL,
--	[UF_STAT_CLIENT_ID_GA] [varchar](128) NULL,
	[UF_TYPE] [varchar](128) NULL,
	[UF_SOURCE] [varchar](128) NULL,
	[UF_STAT_AD_TYPE] [varchar](128) NULL,
--	[UF_ACTUALIZE_AT] [datetime2](7) NULL,
--	[UF_CAR_MARK] [varchar](128) NULL,
--	[UF_CAR_MODEL] [varchar](128) NULL,
--	[UF_PHONE_ADD] [varchar](128) NULL,
--	[UF_PARENT_ID] [int] NULL,
--	[UF_GROUP_ID] [varchar](128) NULL,
--	[UF_PRIORITY] [int] NULL,
	[UF_RC_REJECT_CM] [varchar](512) NULL,
	[UF_APPMECA_TRACKER] [varchar](128) NULL,
--	[UF_LOGINOM_CHANNEL] [varchar](128) NULL,
--	[UF_LOGINOM_GROUP] [varchar](128) NULL,
	[UF_LOGINOM_PRIORITY] [int] NULL,
	[UF_LOGINOM_STATUS] [varchar](128) NULL,
	[UF_LOGINOM_DECLINE] [varchar](128) NULL,
	[UF_STAT_SOURCE] [varchar](128) NULL,
--	[UF_FROM_SITE] [int] NULL,
--	[UF_VIEWED] [int] NULL,
	[UF_PARTNER_ID] [nvarchar](256) NULL,
--	[UF_SUM_ACCEPTED] [float] NULL,
--	[UF_SUM_LOAN] [float] NULL,
--	[UF_REGIONS_COMPOSITE] [nvarchar](128) NULL,
--	[UF_ISSUED_AT] [datetime2](7) NULL,
--	[UF_TARGET] [int] NULL,
	[UF_FULL_FORM_LEAD] [int] NULL,
--	[UF_STEP] [int] NULL,
--	[UF_SOURCE_SHADOW] [nvarchar](128) NULL,
--	[UF_TYPE_SHADOW] [nvarchar](128) NULL,
--	[UF_CLB_TYPE] [nvarchar](128) NULL,
--	[Тип-Источник] [nvarchar](255) NULL,
--	[CPA] [nvarchar](255) NULL,
--	[cpc] [nvarchar](100) NULL,
--	[Партнеры] [varchar](31) NULL,
--	[Органика] [nvarchar](100) NULL,
--	[Остальные1] [nvarchar](35) NULL,
--	[Представление] [varchar](33) NULL,
	[Канал от источника] [nvarchar](255) NULL,
	[Группа каналов] [nvarchar](255) NULL,
--	[DWHInsertedDate] [datetime] NOT NULL,
--	[UF_CLID] [nvarchar](72) NULL,
--	[UF_MATCH_ALGORITHM] [nvarchar](26) NULL,
--	[UF_CLB_CHANNEL] [nvarchar](50) NULL,
--	[UF_LOAN_MONTH_COUNT] [int] NULL,
--	[UF_STAT_SYSTEM] [nvarchar](16) NULL,
--	[UF_STAT_DETAIL_INFO] [nvarchar](1236) NULL,
--	[UF_STAT_TERM] [nvarchar](1070) NULL,
--	[UF_STAT_FIRST_PAGE] [nvarchar](2032) NULL,
--	[UF_STAT_INT_PAGE] [nvarchar](1268) NULL,
--	[UF_CLT_NAME_FIRST] [nvarchar](36) NULL,
--	[UF_CLT_BIRTH_DAY] [date] NULL,
--	[UF_CLT_EMAIL] [nvarchar](60) NULL,
--	[UF_CLT_AVG_INCOME] [int] NULL,
--	[UF_CAR_COST_RUB] [int] NULL,
--	[UF_CAR_ISSUE_YEAR] [float] NULL
)


-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = @start_date, @End_Registered = getdate()
--SELECT @End_Registered = getdate()
--SELECT @Begin_Registered = dateadd(DAY, -100, @End_Registered)

SELECT @Begin_Registered, @End_Registered

TRUNCATE TABLE #TMP_leads

DECLARE @min_UF_REGISTERED_AT_date date

SELECT @min_UF_REGISTERED_AT_date = min(D.UF_REGISTERED_AT_date)
FROM dbo.dm_lcrm_leads_for_report AS D

IF @Begin_Registered < @min_UF_REGISTERED_AT_date
BEGIN
	EXEC Stg._LCRM.get_leads
		@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
		@Begin_Registered = @Begin_Registered, -- начальная дата
		@End_Registered = @End_Registered, -- конечная дата
		@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
		@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
		@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

	SELECT @Return_Number, @Return_Message
END
ELSE BEGIN
--select 1
	--DWH-1259
	INSERT #TMP_leads
	(
	    ID,
	    UF_REGISTERED_AT,
	    UF_REGISTERED_AT_date,
	   -- UF_ROW_ID,
	    UF_STAT_CAMPAIGN,
	    UF_TYPE,
	    UF_SOURCE,
	    UF_STAT_AD_TYPE,
	    UF_RC_REJECT_CM,
	    UF_APPMECA_TRACKER,
	    UF_LOGINOM_PRIORITY,
	    UF_LOGINOM_STATUS,
	    UF_LOGINOM_DECLINE,
	    UF_STAT_SOURCE,
	    UF_PARTNER_ID,
	    UF_FULL_FORM_LEAD,
	    [Канал от источника],
	    [Группа каналов]
	)
	SELECT 
		D.ID,
		D.UF_REGISTERED_AT,
		D.UF_REGISTERED_AT_date,
	--	D.UF_ROW_ID,
		D.UF_STAT_CAMPAIGN,
		D.UF_TYPE,
		D.UF_SOURCE,
		D.UF_STAT_AD_TYPE,
		D.UF_RC_REJECT_CM,
		D.UF_APPMECA_TRACKER,
		D.UF_LOGINOM_PRIORITY,
		D.UF_LOGINOM_STATUS,
		D.UF_LOGINOM_DECLINE,
		D.UF_STAT_SOURCE,
		D.UF_PARTNER_ID,
		D.UF_FULL_FORM_LEAD,
		D.[Канал от источника],
		D.[Группа каналов]
	FROM dbo.dm_lcrm_leads_for_report AS D
	WHERE D.UF_REGISTERED_AT_date BETWEEN @Begin_Registered AND @End_Registered
END

insert into #TMP_leads
SELECT 
		D.ID,
		D.UF_REGISTERED_AT,
		D.UF_REGISTERED_AT_date,
	--	D.UF_ROW_ID,
		D.UF_STAT_CAMPAIGN,
		D.UF_TYPE,
		D.UF_SOURCE,
		D.UF_STAT_AD_TYPE,
		D.UF_RC_REJECT_CM,
		D.UF_APPMECA_TRACKER,
		D.UF_LOGINOM_PRIORITY,
		D.UF_LOGINOM_STATUS,
		D.UF_LOGINOM_DECLINE,
		D.UF_STAT_SOURCE,
		D.UF_PARTNER_ID,
		D.UF_FULL_FORM_LEAD,
		D.[Канал от источника],
		D.[Группа каналов]
	FROM _lcrm_requests AS D
	WHERE D.UF_REGISTERED_AT_date BETWEEN @Begin_Registered AND @End_Registered

--SELECT count(1) FROM #TMP_leads
--SELECT TOP(100) * FROM #TMP_leads

--;with v  as (select *, row_number() over(partition by UF_ROW_ID order by id ) rn from #TMP_leads ) delete from v where rn>1	and  UF_ROW_ID is not null
;with v  as (select *, row_number() over(partition by id order by id ) rn from #TMP_leads ) delete from v where rn>1 


delete a from #TMP_leads a join badis_lcrm b on a.id=b.id

 
 drop table if exists #fl

 select 

id ,
Возврат ,
[Выданная сумма возврат] ,
[Верификация КЦ] ,
[Предварительное одобрение] ,
[Контроль данных] ,
Одобрено ,
[Заем Выдан] ,
[Выданная Сумма] ,
[Номер заявки] ,
[Признак профильный] ,
[Признак непрофильный] ,
[Статус лида] ,
IsInstallment 

into #fl 

from v_feodor_leads
;
 drop table if exists #fa
 drop table if exists #fa
 select 
Номер ,
[Верификация КЦ] ,
cast(format([Верификация КЦ] , 'yyyy-MM-01') as date) [Верификация КЦ месяц] ,
 
[Предварительное одобрение] ,
[Контроль данных] ,
isnull([Отказ документов клиента], Отказано)[Отказ Carmoney] ,
Одобрено ,
[Выданная сумма] ,
[Заем выдан] ,
cast(format([Заем выдан] , 'yyyy-MM-01') as date) [Заем выдан месяц] ,
cast([Заем выдан]  as date) [Заем выдан день] ,
cast([Верификация КЦ] as date) [Верификация КЦ день] ,
[Группа каналов] ,
[Канал от источника] ,
1-isPts isinstallment ,
[LCRM ID] [lcrm id]

into #fa 


from reports.dbo.dm_factor_analysis_001


drop table if exists [#Отчет аллоцированные расходы CPA]
			  select Номер, [Расходы на CPA]  into [#Отчет аллоцированные расходы CPA]from  Analytics.[dbo].[Отчет аллоцированные расходы CPA]
;
drop table if exists #columns_from_functions

select id
 , Analytics.dbo.lcrm_source_of_cpa_trafic_mp(UF_APPMECA_TRACKER) [CPA трафик в МП источник]
 , Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, null) is_inst_lead

 , case when  Analytics.dbo.lcrm_признак_корректного_заполнения_вебмастера(UF_SOURCE, UF_REGISTERED_AT)=1 then [UF_PARTNER_ID] end [UF_PARTNER_ID аналитический]
 --, UF_REGISTERED_AT_date [UF_REGISTERED_AT день]
 into #columns_from_functions
 from #TMP_leads

drop table if exists #t1
;
 with tmp_leads as (

 select a.*, b.[CPA трафик в МП источник],b.is_inst_lead,b.[UF_PARTNER_ID аналитический]   from 	#TMP_leads a
 left join #columns_from_functions b on a.id=b.id

 )
 
 
 , v as (

SELECT 
   a.id
   ,case when a.[Группа каналов]='cpc' then a.id   end	   id_for_details
--,  a.[UF_REGISTERED_AT день]           
,  a.UF_REGISTERED_AT_date [UF_REGISTERED_AT день]           
,  isnull(f.[Группа каналов],  a.[Группа каналов])			  [Группа каналов]	 
,  isnull(f.[Канал от источника], a.[Канал от источника]	) [Канал от источника]			
,  a.[UF_TYPE]						
,  a.[UF_SOURCE]						
,  a.UF_RC_REJECT_CM					 
,  a.UF_LOGINOM_DECLINE				
,  a.UF_LOGINOM_PRIORITY				
,  a.UF_LOGINOM_STATUS				
,  a.[UF_STAT_SOURCE]                  
,  a.[UF_STAT_AD_TYPE]                 
,  a.[UF_STAT_CAMPAIGN]                
,  a.[UF_PARTNER_ID аналитический]	
,  a.[UF_FULL_FORM_LEAD]				
,  a.is_inst_lead


,  [Кампания обзвона] =  case when CompanyNaumen='Полная заявка' then CompanyNaumen
                              when isnull(UF_LOGINOM_STATUS, '') = 'declined' then 'Не попал в обзвон' 
                              when isnull([CompanyNaumen], 'Не определен') not in ('Не определен', 'Non-Feodor', 'Отп. в никуда (VoidCC)', 'depr. - mfo (lcrm_cc)') then [CompanyNaumen] else 'Не попал в обзвон' end
                             --when [UF_FULL_FORM_LEAD] =1 then 'Полная заявка' end
,  case when Обработан is not null or [Номер CRM] is not null   then 1 else 0 end [Признак обработан лид]
,  case when Дозвон is not null  or [Номер CRM] is not null  then 1 else 0 end [Признак дозвон]
,  isnull(isnull(fl.isInstallment, b.isinstallment), is_inst_lead) [isInstallment feodor]
,  isnull(f.isInstallment, is_inst_lead)  [isInstallment crm]
,  case when fl.[Признак профильный]=1 or [Номер CRM] is not null then 1 else 0 end [Признак профильный лид]
,  case when fl.[Признак непрофильный]=1 then 1 else 0 end [Признак непрофильный лид]
,  case when fl.[Номер заявки] is not null then 1 else 0 end     [Признак заявка со звонка]
,  case when fl.[Предварительное Одобрение] is not null then 1 else 0 end [Признак Предварительноеодобрение со звонка]
,  case when fl.[Контроль Данных] is not null then 1 else 0 end [Признак Контроль данных со звонка]
,  case when fl.[Заем Выдан] is not null then 1 else 0 end [Признак займ со звонка]
,  case when fl.[Выданная Сумма] >0 then fl.[Выданная Сумма] else null end [Сумма займа со звонка]
,  case when [Номер CRM] is not null then 1 else 0 end [Признак заявка CRM]
,  case when [Предварительное одобрение CRM] is not null then 1 else 0 end [Признак Предварительное одобрение CRM]
,  case when [Контроль данных CRM] is not null then 1 else 0 end [Признак Контроль данных CRM]
,  case when [Отказ Carmoney CRM] is not null then 1 else 0 end [Признак Отказ Carmoney CRM]
,  case when [Одобрено CRM] is not null then 1 else 0 end [Признак Одобрено CRM]
,  case when [Заем выдан CRM] is not null then 1 else 0 end [Признак Заем выдан CRM]
,  case when [Выданная сумма CRM] >0 then [Выданная сумма CRM] else null end [Сумма займа CRM]
, [Заем выдан месяц CRM]
, [Заем выдан день CRM]
, [Верификация КЦ месяц CRM]
, [Верификация КЦ день CRM]
,  rq.[Расходы на CPA]
,  Возврат
,  [Выданная сумма возврат]
,  case when [Номер CRM] is not null then 'Заявка'
        when [Признак непрофильный]=1  then 'Непрофильный'
        when left([Статус лида], 13)='Отказ клиента'  then 'Отказ клиента'
        when Дозвон is null then 'Недозвон'
        else  'Остальные' end [Статус лида аналитический]
, a.[CPA трафик в МП источник]
, a.[UF_APPMECA_TRACKER]
, b.ВремяПервойПопытки
, b.seconds_to_pay
, [Номер CRM]
from 
(
select * from

TMP_leads ) a
left join
(  select   id
, IsInstallment
,  CompanyNaumen
,  ВремяПервойПопытки
,  case when CompanyNaumen='Полная заявка' then getdate() else 
isnull(isnull(ВремяПервойПопытки, FedorДатаЛида) , case when [Удален из обзвона] =1 then creationdate end   ) 
end
Обработан 
,  case when CompanyNaumen='Полная заявка' then getdate() else 

 isnull(ВремяПервогоДозвона, case when ВремяПервойПопытки is not null and FedorДатаЛида is not null then ВремяПервойПопытки end )  
 end Дозвон
, seconds_to_pay
from Feodor.dbo.dm_leads_history a
) b on a.id=b.id

left join #fl fl on a.id=fl.id

left join
(
select 

Номер [Номер CRM],
[Верификация КЦ] [Верификация КЦ CRM],
[Верификация КЦ месяц] [Верификация КЦ месяц CRM],
[Предварительное одобрение] [Предварительное одобрение CRM],
[Контроль данных] [Контроль данных CRM],
Одобрено [Одобрено CRM],
[Отказ Carmoney] [Отказ Carmoney CRM],
[Выданная сумма] [Выданная сумма CRM],
[Заем выдан] [Заем выдан CRM],
[Заем выдан месяц] [Заем выдан месяц CRM],
[Заем выдан день] [Заем выдан день CRM],
[Верификация КЦ день] [Верификация КЦ день CRM],
isinstallment,
[lcrm id],
[Группа каналов],
[Канал от источника]

from 
#fa f 
) f on f.[lcrm id]
=a.id
left join [#Отчет аллоцированные расходы CPA] rq on rq.Номер=f.[Номер CRM]

)


SELECT [UF_REGISTERED_AT день]               [UF_REGISTERED_AT день]
      ,[Группа каналов]					     [Группа каналов]
      ,[Канал от источника]					 [Канал от источника]
      ,[UF_TYPE]							 [UF_TYPE]
      ,[UF_SOURCE]							 [UF_SOURCE]
      ,UF_RC_REJECT_CM					     [UF_RC_REJECT_CM]
      ,UF_LOGINOM_DECLINE					 UF_LOGINOM_DECLINE
      ,UF_LOGINOM_PRIORITY					 UF_LOGINOM_PRIORITY
      ,UF_LOGINOM_STATUS					 UF_LOGINOM_STATUS
      ,[UF_STAT_SOURCE]                      --utm source
      ,[UF_STAT_AD_TYPE]                     --utm medium
      ,[UF_STAT_CAMPAIGN]                    --utm campaign
      ,[UF_PARTNER_ID аналитический]		 [UF_PARTNER_ID аналитический]
      ,[UF_FULL_FORM_LEAD]					 [UF_FULL_FORM_LEAD]
	  ,is_inst_lead
	  ,[isinstallment crm]
	  ,[isinstallment feodor]
      ,[Кампания обзвона]					 [Кампания обзвона]
      ,[Верификация КЦ месяц CRM]
	  ,[Верификация КЦ день CRM]
	  ,[Заем выдан день CRM]
	  ,[Заем выдан месяц CRM]
	  ,cast(count_big(*)                                             as bigint) [Количество лидов]
      ,sum(cast([Признак обработан лид]                 as bigint)        )                   [Признак обработан лид]      
      ,sum(cast([Признак дозвон]				        as bigint)        )                [Признак дозвон]				
      ,sum(cast([Признак профильный лид]		        as bigint)        )                [Признак профильный лид]		
      ,sum(cast([Признак заявка со звонка]	            as bigint)        )                    [Признак заявка со звонка]	
      ,sum(cast([Признак займ со звонка]		        as bigint)        )                [Признак займ со звонка]		
      ,sum(cast([Сумма займа со звонка]		            as bigint)        )                    [Сумма займа со звонка]	
	  ,sum(cast([Признак заявка CRM]                    as bigint)        )                   [Признак заявка CRM]
      ,sum(cast([Признак Предварительное одобрение CRM] as bigint)        )        [Признак Предварительное одобрение CRM]
      ,sum(cast([Признак Контроль данных CRM] 		    as bigint)        )         [Признак Контроль данных CRM] 			
      ,sum(cast([Признак Отказ Carmoney CRM] 			as bigint)	      ) [Признак Отказ Carmoney CRM] 				
      ,sum(cast([Признак Одобрено CRM] 				    as bigint)        )         [Признак Одобрено CRM] 				
      ,sum(cast([Признак Заем выдан CRM] 			    as bigint)        )         [Признак Заем выдан CRM] 				
   --   ,string_agg(case when [Признак Заем выдан CRM] =1 then cast(UF_ROW_ID as nvarchar(max)) end , ',') [Выданные займы CRM]
      ,sum(cast([Сумма займа CRM] 			    as bigint) 					   ) [Сумма займа CRM] 						
      ,sum(cast([Расходы на CPA] 			    as bigint) 					   ) [Расходы на CPA] 						
      ,cast(count([возврат] 					   )  as bigint) [Возврат] 						
      ,sum(cast([выданная сумма возврат] 			    as bigint) 					   ) [Выданная сумма возврат] 						


	  ,getdate() as created
	  ,isnull(isnull([Заем выдан день CRM], [Верификация КЦ день CRM]), [UF_REGISTERED_AT день]) [Дата займа лида заявки]
	  ,[Статус лида аналитический]
	  ,[CPA трафик в МП источник]
	  ,[UF_APPMECA_TRACKER]
	  ,count(ВремяПервойПопытки) [TTC_client_count]
	  ,sum(cast(datediff(minute, [UF_REGISTERED_AT день], ВремяПервойПопытки) 			    as bigint)) [TTC_client_sum]
	  ,[Номер CRM]
	  ,sum(seconds_to_pay)	 seconds_to_pay
	  ,id_for_details
	  into #t1
  FROM v
 -- where [UF_REGISTERED_AT день]>=@start_date
  group by [UF_REGISTERED_AT день]
      ,[Группа каналов]
      ,[Канал от источника]
      ,[UF_TYPE]
      ,[UF_SOURCE]
      ,UF_RC_REJECT_CM					 

      ,UF_LOGINOM_DECLINE
      ,UF_LOGINOM_PRIORITY
      ,UF_LOGINOM_STATUS
	  ,[UF_STAT_SOURCE] --utm source
      ,[UF_STAT_AD_TYPE] --utm medium
      ,[UF_STAT_CAMPAIGN] --utm campaign
      ,[UF_PARTNER_ID аналитический]
      ,[Кампания обзвона]
      ,[UF_FULL_FORM_LEAD]
	  ,is_inst_lead
	  ,[isinstallment crm]
	  ,[isinstallment feodor]
	  ,[Верификация КЦ месяц CRM]
	  ,[Верификация КЦ день CRM]
	  ,[Заем выдан день CRM]
	  ,[Заем выдан месяц CRM]
	  ,isnull(isnull([Заем выдан день CRM], [Верификация КЦ день CRM]), [UF_REGISTERED_AT день]) 
	  ,[Статус лида аналитический]
	  ,[CPA трафик в МП источник]
	  ,[UF_APPMECA_TRACKER]
	  ,[Номер CRM]
	  ,id_for_details

--exec generate_select_table_script 'analytics.dbo.report_leads_full'

--drop table if exists analytics.dbo.report_leads_full
--select  *
--into analytics.dbo.report_leads_full 
--from #t1
--create nonclustered index t on Analytics.dbo.report_leads_full
--(
--[UF_REGISTERED_AT день], 
--[Верификация КЦ день CRM], 
--[Заем выдан день CRM]--, 
--)

-- EXEC sp_refreshview 'v_report_leads_full'
--select * from analytics.dbo.v_report_leads_full 

--alter table report_leads_full
--add  [Номер CRM] varchar(128)
--alter table report_leads_full
--add  [TTC_client_count] bigint
--alter table report_leads_full
--add  [TTC_client_sum] bigint
--alter table report_leads_full
--add  [seconds_to_pay] bigint	 
--alter table report_leads_full
--add  id_for_details numeric

begin tran
delete from analytics.dbo.report_leads_full where [UF_REGISTERED_AT день] IN (SELECT [UF_REGISTERED_AT день] FROM #t1 WHERE [UF_REGISTERED_AT день] IS NOT NULL GROUP BY [UF_REGISTERED_AT день])
insert into analytics.dbo.report_leads_full 
select 
*
from #t1
commit tran

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '0335B3B7-29EA-46ED-88E3-80933E636104'



IF  EXISTS(SELECT 1 
          FROM msdb.dbo.sysjobs J 
          JOIN msdb.dbo.sysjobactivity A 
              ON A.job_id=J.job_id 
          WHERE J.name=N'Analytics. Подготовка отчета по лидам каждый день в 8:30' 
          AND A.run_requested_date IS NOT NULL 
          AND A.stop_execution_date IS NULL
         )
    begin
--select getdate() dt into report_leads_full_status
 exec log_email 'report_leads_full excel started', 'p.ilin@techmoney.ru'

 insert into report_leads_full_status
 select getdate()

  --exec exec_python 	'update_leads_report_excel()'	   , 1
 

	end
	--select 1/0
--	select distinct   [UF_REGISTERED_AT день], created from analytics.dbo.report_leads_full
	-- where [UF_REGISTERED_AT день]=getdate()-1
	--order by 1


if not exists (select top 1 1 from analytics.dbo.report_leads_full where [UF_REGISTERED_AT день]=cast(getdate()-1 as date))
begin
 exec log_email 'В report_leads_full нет записей за вчера', 'p.ilin@techmoney.ru'
 --select 1/0
end


	   
 
  declare @html  nvarchar(max)
  exec spQueryToHtmlTable '
   select a.Дата, a.UF_SOURCE, a.[Выданная сумма]  [Выданная сумма bot], b.[Выданная сумма] [Выданная сумма excel]   from (
 
  select cast([Заем выдан] as date) Дата,  Источник UF_SOURCE, sum([Выданная сумма]) [Выданная сумма]   from  reports.dbo.dm_factor_analysis_001
																	   
group by Источник,  cast([Заем выдан] as date)			   ) a
left join (
 
 select [Заем выдан день CRM] Дата, UF_SOURCE, sum([Сумма займа CRM]) [Выданная сумма]    from report_leads_full
group by UF_SOURCE	, [Заем выдан день CRM]	
) b on a.UF_SOURCE=b.UF_SOURCE	   and b.Дата=a.Дата
where	 b.[Выданная сумма]  <> a.[Выданная сумма]   	and a.UF_SOURCE<>''''	and a.Дата between   ''20230501'' and   getdate()-1
   --and 1=0
 
  
  
  ' , default,  @html output	   
  if  @html is not null
  begin
 
 exec msdb.dbo.sp_send_dbmail   
     @profile_name = null,  
     @recipients = 'p.ilin@techmoney.ru',  
     @body = @html,  
     @body_format = 'html',  
     @subject = 'Не сходятся выдачи excel бот'	
 end else 	  print('Письмо не отправлено')
	 

exec log_email 'report_leads_full finished', 'p.ilin@techmoney.ru'
 --EXEC generate_select_table_script 'analytics.dbo.report_leads_full'


 end
