
/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE     PROC-- exec
[dbo].[marketing_lead_report]
@mode nvarchar(max) = ''
as 


--exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._marketing_lead_report at 8:00'--STOP 
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics._marketing_lead_report at 8:00', @step_name = 'marketing_lead_report LF'
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics._marketing_lead_report at 8:00', @step_name = 'report'

 
 declare @start_date date = getdate()-120
 declare @end_date date = getdate() 

drop table if exists #TMP_leads
CREATE TABLE #TMP_leads(
	[ID] nvarchar(50) NULL,
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
		D.created UF_REGISTERED_AT,
		d.date UF_REGISTERED_AT_date,
	--	D.UF_ROW_ID,
		D.STAT_CAMPAIGN UF_STAT_CAMPAIGN,
		D.type UF_TYPE,
		D.source  UF_SOURCE,
		D.stat_type UF_STAT_AD_TYPE,
		cast(null as nvarchar(50)) UF_RC_REJECT_CM,
		D.appmetrica  UF_APPMECA_TRACKER,
		D.mms_priority UF_LOGINOM_PRIORITY,
		D.marketing_status UF_LOGINOM_STATUS,
		D.decline_reason UF_LOGINOM_DECLINE,
		cast(d.stat_source as nvarchar(50) ) UF_STAT_SOURCE,
		D.PARTNER_ID UF_PARTNER_ID,
		 0 UF_FULL_FORM_LEAD,
		D.channel  [Канал от источника],
		D.channel_group  [Группа каналов]
	FROM v_lead AS D
	WHERE cast(D.created_at_time as date) BETWEEN @start_date AND @end_date

--SELECT count(1) FROM #TMP_leads
--SELECT TOP(100) * FROM #TMP_leads

--;with v  as (select *, row_number() over(partition by UF_ROW_ID order by id ) rn from #TMP_leads ) delete from v where rn>1	and  UF_ROW_ID is not null
;with v  as (select *, row_number() over(partition by id order by id ) rn from #TMP_leads ) delete from v where rn>1 


--delete a from #TMP_leads a join badis_lcrm b on a.id=b.id

 
 drop table if exists #fl

 select 

lead_id id,
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
where id is null
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
 isnull( marketing_lead_id,  Номер) marketing_lead_id ,
 ispdl ispdl  
 , source
 , case when marketing_lead_id is null then 1 else 0 end hasNoLeadId
 , productType
 , region
into #fa 


from v_fa		 a
--left join stg._LF.request b on a.номер=b.number



insert into #TMP_leads (id, UF_REGISTERED_AT, UF_REGISTERED_AT_date)

select Номер, [Верификация КЦ], [Верификация КЦ] from #fa
where hasNoLeadId = 1 and [Верификация КЦ]>= @start_date


drop table if exists [#request_costs_cpa]
			  select number, [Расходы на CPA]  into [#request_costs_cpa]from  Analytics.[dbo].[request_costs_cpa]
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

 select a.*, b.[CPA трафик в МП источник],b.is_inst_lead,b.[UF_PARTNER_ID аналитический] , case when s.productType is not null then s.productType when a.UF_SOURCE like '%big%' then 'BIG INST' when a.UF_SOURCE like '%inst%' then 'INST' else 'PTS' end productType  from 	#TMP_leads a
 left join #columns_from_functions b on a.id=b.id
 left join v_source s on s.source = a.uf_source
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
, isnull(f.source,  a.[UF_SOURCE]						) [UF_SOURCE]
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
, f.ispdl
, isnull(f.productType, a.productType)  productType
, f.region
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
from Feodor.dbo.lead a
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
ispdl,
marketing_lead_id [lead_id],
[Группа каналов],
[Канал от источника],
source,
productType,
region

from 
#fa f 
) f on f.[lead_id]
=a.id
left join [#request_costs_cpa] rq on rq.number=f.[Номер CRM]

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
	  , isPdl
	  , productType
	  , region
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
	  ,isPdl
	  , productType
	  , region

 --alter table marketing_lead_report_lf add isPdl tinyint
 --alter table marketing_lead_report_lf add productType varchar(100)
 --alter table marketing_lead_report_lf add region varchar(100)

begin tran
delete from marketing_lead_report_lf where [UF_REGISTERED_AT день] IN (SELECT [UF_REGISTERED_AT день] FROM #t1 WHERE [UF_REGISTERED_AT день] IS NOT NULL GROUP BY [UF_REGISTERED_AT день])
insert into marketing_lead_report_lf 
select 
*
from #t1
commit tran

--select top 0 * into analytics.dbo.report_leads_flow 
--from analytics.dbo.report_leads_full 


--select * from dwh where table_name='report_leads_flow'
--update a set a.region = b.region from marketing_lead_report_lf  a join v_fa b on a.[Номер CRM] = b.number