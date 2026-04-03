
/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
create   
proc
--exec [dbo].[create_report_leads_full] 'full'
[dbo].[create_report_leads_full_backup_05_03_2023]
@mode nvarchar(max) = 'hard'
as
begin


exec log_email 'report_leads_full started', 'p.ilin@techmoney.ru'


 EXEC sp_refreshview 'v_report_leads_full'
 
 --declare @mode nvarchar(max) = 'hard'
 declare @start_date date = case 
 when @mode = 'hard' then getdate()-60
 when @mode = 'light' then getdate()-5
 when @mode = 'full' then '20210101'
 end

 if   DATENAME(dw, getdate())='sunday'
  begin

 set @start_date = getdate()-60

 end

 if day(getdate())=1
 begin

 set @start_date = '20210101'

 end



 --select max(created) from v_report_leads_full


drop table if exists #TMP_leads
CREATE TABLE #TMP_leads(
	[ID] [numeric](10, 0) NULL,
--	[UF_NAME] [varchar](512) NULL,
	--[UF_PHONE] [varchar](128) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
--	[UF_UPDATED_AT] [datetime2](7) NULL,
	[UF_ROW_ID] [varchar](128) NULL,
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
	[UF_PARTNER_ID] [nvarchar](128) NULL,
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


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message

--SELECT count(1) FROM #TMP_leads
--SELECT TOP(100) * FROM #TMP_leads



 
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
 drop table if exists #mv_dm_Factor_Analysis
 select 
Номер ,
[Верификация КЦ] ,
[Верификация КЦ месяц] ,
[Предварительное одобрение] ,
[Контроль данных] ,
[Отказ Carmoney] ,
Одобрено ,
[Выданная сумма] ,
[Заем выдан] ,
[Заем выдан месяц] ,
[Заем выдан день] ,
[Верификация КЦ день] ,
[Группа каналов] ,
[Канал от источника] ,
isinstallment 

into #mv_dm_Factor_Analysis 

from mv_dm_Factor_Analysis
;
drop table if exists #t1
;
 with tmp_leads as (

 select *
 , Analytics.dbo.lcrm_source_of_cpa_trafic_mp(UF_APPMECA_TRACKER) [CPA трафик в МП источник]
 , Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, UF_LOGINOM_PRIORITY) is_inst_lead

 , case when  Analytics.dbo.lcrm_признак_корректного_заполнения_вебмастера(UF_SOURCE, UF_REGISTERED_AT)=1 then [UF_PARTNER_ID] end [UF_PARTNER_ID аналитический]
 , UF_REGISTERED_AT_date [UF_REGISTERED_AT день]
 from #TMP_leads

 )
 
 
 , v as (

SELECT 
   a.id
,  a.[UF_REGISTERED_AT день]           
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


,  [Кампания обзвона] = case 
                              when isnull(UF_LOGINOM_STATUS, '') = 'declined' then 'declined' 
                              when isnull([CompanyNaumen], 'Не определен') not in ('Не определен', 'Non-Feodor', 'Отп. в никуда (VoidCC)', 'depr. - mfo (lcrm_cc)') then [CompanyNaumen] end
                             --when [UF_FULL_FORM_LEAD] =1 then 'Полная заявка' end
,  case when Обработан is not null or [Номер CRM] is  not null then 1 else 0 end [Признак обработан лид]
,  case when Дозвон is not null  or [Номер CRM] is  not null then 1 else 0 end [Признак дозвон]
,  isnull(isnull(fl.isInstallment, b.isinstallment), is_inst_lead) [isInstallment feodor]
,  isnull(f.isInstallment, is_inst_lead)  [isInstallment crm]
,  case when fl.[Признак профильный]=1 or fl.[Номер заявки] is not null or [Номер CRM] is not null then 1 else 0 end [Признак профильный лид]
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

from 
(
select * from

TMP_leads ) a
left join
(  select   id
, IsInstallment
,  CompanyNaumen
,  ВремяПервойПопытки
,  isnull(isnull(ВремяПервойПопытки, FedorДатаЛида) , case when [Удален из обзвона] =1 then creationdate end   )   Обработан 
,  isnull(ВремяПервогоДозвона, case when ВремяПервойПопытки is not null and FedorДатаЛида is not null then ВремяПервойПопытки end ) Дозвон 


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
[Группа каналов],
[Канал от источника]

from 
#mv_dm_Factor_Analysis f 
) f on f.[Номер CRM]
=a.UF_ROW_ID
left join Analytics.[dbo].[Отчет аллоцированные расходы CPA] rq on rq.Номер=a.UF_ROW_ID

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
	  ,count(*) [Количество лидов]
      ,sum([Признак обработан лид]      )    [Признак обработан лид]      
      ,sum([Признак дозвон]				)    [Признак дозвон]				
      ,sum([Признак профильный лид]		)    [Признак профильный лид]		
      ,sum([Признак заявка со звонка]	)    [Признак заявка со звонка]	
      ,sum([Признак займ со звонка]		)    [Признак займ со звонка]		
      ,sum([Сумма займа со звонка]		)    [Сумма займа со звонка]	
	  ,sum([Признак заявка CRM]         )       [Признак заявка CRM]
      ,sum([Признак Предварительное одобрение CRM] ) [Признак Предварительное одобрение CRM]
      ,sum([Признак Контроль данных CRM] 		   ) [Признак Контроль данных CRM] 			
      ,sum([Признак Отказ Carmoney CRM] 				   ) [Признак Отказ Carmoney CRM] 				
      ,sum([Признак Одобрено CRM] 				   ) [Признак Одобрено CRM] 				
      ,sum([Признак Заем выдан CRM] 			   ) [Признак Заем выдан CRM] 				
   --   ,string_agg(case when [Признак Заем выдан CRM] =1 then cast(UF_ROW_ID as nvarchar(max)) end , ',') [Выданные займы CRM]
      ,sum([Сумма займа CRM] 					   ) [Сумма займа CRM] 						
      ,sum([Расходы на CPA] 					   ) [Расходы на CPA] 						
      ,count([возврат] 					   ) [Возврат] 						
      ,sum([выданная сумма возврат] 					   ) [Выданная сумма возврат] 						


	  ,getdate() as created
	  ,isnull(isnull([Заем выдан день CRM], [Верификация КЦ день CRM]), [UF_REGISTERED_AT день]) [Дата займа лида заявки]
	  ,[Статус лида аналитический]
	  ,[CPA трафик в МП источник]
	  ,[UF_APPMECA_TRACKER]
	  ,count(ВремяПервойПопытки) [TTC_client_count]
	  ,sum(datediff(minute, [UF_REGISTERED_AT день], ВремяПервойПопытки)) [TTC_client_sum]
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
--add  [TTC_client_count] bigint
--alter table report_leads_full
--add  [TTC_client_sum] bigint

begin tran
delete from analytics.dbo.report_leads_full where [UF_REGISTERED_AT день] IN (SELECT [UF_REGISTERED_AT день] FROM #t1 WHERE [UF_REGISTERED_AT день] IS NOT NULL GROUP BY [UF_REGISTERED_AT день])
insert into analytics.dbo.report_leads_full 
select 
*
from #t1
commit tran



exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '0335B3B7-29EA-46ED-88E3-80933E636104'

--select getdate() dt into report_leads_full_status
insert into report_leads_full_status
select getdate()

exec log_email 'report_leads_full finished', 'p.ilin@techmoney.ru'
 --EXEC generate_select_table_script 'analytics.dbo.report_leads_full'



 end
