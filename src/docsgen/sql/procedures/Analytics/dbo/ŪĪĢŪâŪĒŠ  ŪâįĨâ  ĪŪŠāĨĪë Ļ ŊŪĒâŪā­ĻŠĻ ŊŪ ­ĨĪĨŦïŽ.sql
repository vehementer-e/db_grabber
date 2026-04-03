
CREATE   proc [dbo].[Подготовка отчета докреды и повторники по неделям]
as
begin


declare @start_date date = (select max(Неделя) from v_Calendar where Неделя< dateadd(month, -1, cast(format( getdate()  , 'yyyy-MM-01') as date) ) )
--select   @start_date
declare @start_date_12_week date = dateadd(week, -12 , @start_date  )
--select   @start_date_12_week
				
									
drop table if exists #Справочник_Договоры									
select dwh_new.dbo.getGUIDFrom1C_IDRREF(Клиент) CRMClientGUID, Код into #Справочник_Договоры from stg._1cCMR.Справочник_Договоры									
drop table if exists #dip_all									
									
select 									
         x.*									
		 , cast(dateadd(day, datediff(day, '1900-01-01',  cdate) / 7 * 7, '1900-01-01')   as date) cweek				
		 , d.CRMClientGUID							
into #dip_all 									
									
from (									
									
select cdate,external_id, main_limit, category, 'Докредитование' t 									
from dwh2.[marketing].[docredy_pts]									
union all									
select cdate,external_id, main_limit, category, 'Повторный' t 									
from dwh_new.dbo.povt_history									
) x									
join #Справочник_Договоры d on d.Код=x.external_id									
where cdate>=@start_date_12_week									
									
create nonclustered index t on #dip_all									
( cweek, CRMClientGUID, t)									
									
drop table if exists #dip_all_over_week								
;									
									
with v as (									
select 									
--top 100 									
  *									
, row_number() over(partition by cweek, CRMClientGUID, t order by main_limit desc, case when category='Красный' then 0 else 1 end desc ) rn_over_week									
, min(cdate) over(partition by cweek, CRMClientGUID, t   ) min_cdate 									
									
from #dip_all									
)									
									
select a.* 						

into #dip_all_over_week 									
from v a									

where a.rn_over_week=1									
									
 --смотрим на все звонки по кейсам докердов и повторников									
									
 --select * from #dip_all_over_month									
									
									
drop table if exists #mv_loans									
select Код									
,  '8'+nullif([Телефон договор CMR], '') [Телефон договор CMR 8]									
,  '8'+nullif([Основной телефон клиента CRM], '') [Основной телефон клиента CRM 8]									
, CRMClientGUID 									
, Фамилия+' '+Имя+' '+Отчество+format([Дата рождения], 'yyyyMMdd') ФИОДатаРождения	
, [Дата выдачи день]
, [Дата выдачи месяц]
, [Дата погашения день]
, [Дата погашения месяц]
, isInstallment
into #mv_loans 									
from analytics.dbo.mv_loans									
									
--select * from #mv_loans									
									
									
									
drop table if exists #docr_cases_sessions									
select  cc.creationdate, 									
        cc.projectuuid, 									
	   cc.projecttitle, 								
	   cc.uuid, 								
	   cc.phonenumbers,								
	   dos.attempt_start,								
	   dos.attempt_result,								
	   dos.login								
	   into #docr_cases_sessions								
	 from  [Reports].[dbo].[dm_report_DIP_mv_call_case] cc 								
	 left join [Reports].[dbo].[dm_report_DIP_detail_outbound_sessions] dos on dos.case_uuid=cc.uuid	
	 where  cc.creationdate>=@start_date_12_week
	  ;								
									
	--select * from #mv_loans								
									
									
									
									
	drop table if exists #dr								
	select  format(dateadd(year, -2000 , ДатаРождения), 'yyyyMMdd') ДатаРождения , Ссылка into #dr from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС								
	drop table if exists #fa								
	select 								
									
	  dwh_new.dbo.getGUIDFrom1C_IDRREF([Ссылка клиент]) CRMClientGUID_factor								
	, nullif(ФИО, '') +ДатаРождения ФИОДатаРождения								
	, [вид займа]								
	, [Ссылка клиент]								
	,'8'+ Телефон [Телефон 8]								
	, Номер								
	, [Верификация КЦ]								
	, [Верификация КЦ Неделя]								
	, [Предварительное одобрение]								
	, [Контроль данных]								
	, [Отказ Carmoney]								
	, Одобрено								
	, [Заем выдан]								
	, [Выданная сумма]								
	, case when [вид займа]='Повторный' then [вид займа] else 'Докредитование' end t								
	into #fa 								
	from Analytics.dbo.mv_dm_Factor_Analysis a left join #dr on #dr.Ссылка=a.[Ссылка заявка]								
	where [вид займа]<>'Первичный' and isPts=1
	--select * from #fa			
	
	--select top 1 [Верификация КЦ],[Верификация КЦ Неделя]  from   Analytics.dbo.mv_dm_Factor_Analysis
	--order by 1 desc
									
	drop table if exists #fa_clients								
	select								
									
	case 								
	when a.CRMClientGUID_factor <>'00000000-0000-0000-0000-000000000000'  then a.CRMClientGUID_factor 								
	when x2.CRMClientGUID is not null  then x2.CRMClientGUID								
	when x.CRMClientGUID is not null  then x.CRMClientGUID								
	when x1.CRMClientGUID is not null then x1.CRMClientGUID end CRMClientGUID								
	, 								
	a.*								
	into #fa_clients								
	from #fa  a								
	outer apply (select top 1 * from #mv_loans b where b.[Основной телефон клиента CRM 8]=a.[Телефон 8] ) x								
	outer apply (select top 1 * from #mv_loans b where b.[Телефон договор CMR 8]=a.[Телефон 8] ) x1								
	outer apply (select top 1 * from #mv_loans b where b.ФИОДатаРождения=a.ФИОДатаРождения ) x2								
	--order by [Верификация КЦ]								
									
	drop table if exists #fa_clients_over_week								
;									
									
	with v as (								
	select *, count([Заем выдан])  over(partition by CRMClientGUID, t, [Верификация КЦ Неделя]) [Заем выдан_итог] , sum([Выданная сумма])  over(partition by CRMClientGUID, t, [Верификация КЦ Неделя]) [Выданная сумма_итог] , ROW_NUMBER() over(partition by CRMClientGUID, t, [Верификация КЦ Неделя] order by 								
	 [Заем выдан]                  desc								
	, Одобрено					   desc			
	, [Контроль данных]			   desc					
	, [Предварительное одобрение]  desc								
		, [Верификация КЦ неделя]   desc							
									
	) rn_over_week from #fa_clients								
	)								
									
	select * into #fa_clients_over_week from v where rn_over_week=1								
									
	--select * from #fa_clients_over_month								
									
									
	drop table if exists #mfo_ref								
									
	select '8'+телефонмобильный [телефонмобильный 8]								
	, dwh_new.dbo.getGUIDFrom1C_IDRREF([КонтрагентКлиент]) CRMClientGUID								
	into #mfo_ref								
	from stg._1cMFO.Документ_ГП_Заявка								
	where [КонтрагентКлиент]<>0								
	--where year([ДатаРождения])>3900								
	--order by [ДатаРождения] desc								
	--select * from #mfo_ref								
									
	--exec analytics.dbo.select_table 'stg._1cMFO.Документ_ГП_Заявка'								
									
									
	drop table if exists #docr_cases_sessions_clients								
									
	select a.*
,cast(dateadd(day, datediff(day, '1900-01-01',  a.creationdate) / 7 * 7, '1900-01-01')   as date)  creationdate_week
--, cast(format(a.creationdate, 'yyyy-MM-01') as date) creationdate_month								
	, isnull( isnull(x.CRMClientGUID, x1.CRMClientGUID ), x2.CRMClientGUID ) CRMClientGUID								
	into #docr_cases_sessions_clients								
	from #docr_cases_sessions a								
	outer apply (select top 1 * from #mv_loans b where b.[Основной телефон клиента CRM 8]=a.phonenumbers ) x								
	outer apply (select top 1 * from #mv_loans b where b.[Телефон договор CMR 8]=a.phonenumbers ) x1								
	outer apply (select top 1 * from #mfo_ref b where b.[телефонмобильный 8]=a.phonenumbers ) x2								
									
	drop table if exists #docr_cases_sessions_clients_over_week								
									
	;								
	with v as (								
	select  *
	, ROW_NUMBER() over(partition by CRMClientGUID, creationdate_week order by login desc, attempt_start desc) rn_over_week  
	, count(*) over(partition by CRMClientGUID, creationdate_week  ) count_over_week
	
	from #docr_cases_sessions_clients								
	)								
									
	select *  into #docr_cases_sessions_clients_over_week								
	from v where rn_over_week=1								
									
									
	--select * from reports.dbo.dm_Factor_Analysis where Телефон='9652639593'								
	--select * from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС where МобильныйТелефон='9652639593'								
									
	--update #dip_all_over_month								
	--set t='Докредитование'								
	--where t='Докердитование'								
									
	drop table if exists #f								
									
	select 								
	  a.cweek								
	, a.min_cdate								
	, a.CRMClientGUID								
	, a.main_limit								
	, a.category								
	, a.t								
    , case when isnull(aa.main_limit, 0)=0 and a.main_limit>0 then  1 else 0 end [is_new]	
	    , case 
	when isnull(aa.main_limit, 0)=0 and a.main_limit>0 then  'Появился лимит'
	when isnull(aa.main_limit, 0)> a.main_limit  then  'Уменьшился лимит'
	when isnull(aa.main_limit, 0)< a.main_limit  then  'Увеличился лимит'
	else  ''end [is_new2]	
	, b.creationdate_week								
	, b.attempt_start								
	, b.login								
	, b.count_over_week								
	, c.Номер								
	, c.[Верификация КЦ]								
	, c.[Верификация КЦ Неделя]								
	, c.[Предварительное одобрение]								
	, c.[Контроль данных]								
	, c.[Одобрено]								
	, c.[Отказ Carmoney]								
	, c.[Заем выдан_итог]								
	, c.[Выданная сумма_итог]								
	into #f								
	from 								
	#dip_all_over_week a								
	left join #docr_cases_sessions_clients_over_week b on a.CRMClientGUID=b.CRMClientGUID and a.cweek=b.creationdate_week								
	left join #fa_clients_over_week c on a.CRMClientGUID=c.CRMClientGUID and a.cweek=c.[Верификация КЦ Неделя] and a.t=c.t								
	outer apply (select top 1 main_limit from #dip_all_over_week aa where a.CRMClientGUID=aa.CRMClientGUID and aa.cweek between dateadd(day, -4*7, a.cweek ) and dateadd(day, -1*7, a.cweek )  and a.t=aa.t order by aa.main_limit desc	 ) aa							
	
	--select * from #f
	--where attempt_start>getdate()-10 and category='Красный' and guid='4BE21927-08CB-11E8-A814-00155D941900'

	--select top 100 * from reports.dbo.dm_Report_DIP_to_Naumen_history
	--where crmclientguid='31EF978F-4AD9-41BC-8CC1-56A82C1726C0'
	--order by 1 desc
	--select * from #dip_all 
	--where crmclientguid='31EF978F-4AD9-41BC-8CC1-56A82C1726C0'
	--order by 1 desc



  --drop table if exists analytics.dbo.[отчет по базам докредитования и повторников по неделям]
	drop table if exists #final
	
	select 								
	  cweek								
	, category								
	, t								
	, is_new								
	, is_new2								
	, sum(count_over_week)                       [Количество попыток] 								
	, count(CRMClientGUID)                     [Количество клиентов] 								
	, sum(cast(main_limit as bigint))                     [Сумма лимитов] 								
	, count(creationdate_week)           [Загружено в обзвон] 								
	, count(attempt_start)                [Совершена попытка дозвона] 								
	, count(login)                        [Дозвон]								
	, count(Номер)                        [Количество заявок] 								
	, count([Предварительное одобрение])  [Предварительное одобрение]								
	, count([Контроль данных]		   )  [Контроль данных]		   				
	, count([Одобрено]				   )  [Одобрено]				   
	, count([Отказ Carmoney]		   )  [Отказ Carmoney]		   				
	, sum([Заем выдан_итог]			   )  [Заем выдан]			   		
	, sum([Выданная сумма_итог]		       )  [Выданная сумма]		   		
	, getdate() as created
	, x.no_successfull_call_3_month  
	, isnull(docr.[Дата выдачи месяц], povt.[Дата погашения месяц]) [Месяц выдачи по докредам и погашения по повторным]


	into 		  #final

  	from #f		a
	outer apply (select top 1 case when login  is null then 1 end no_successfull_call_3_month from  #f		b where a.CRMClientGUID=b.CRMClientGUID and b.cweek between dateadd(WEEK, -12, a.cweek) and   dateadd(WEEK, -1, a.cweek)  and b.attempt_start is not null order by case when login  is not null then 1 else 0 end desc ) x 
    outer apply (select top 1 [Дата выдачи месяц] from  #mv_loans		b where a.t='Докредитование' and  a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата выдачи день]<a.min_cdate order by b.[Дата выдачи день] desc ) docr 
	outer apply (select top 1 [Дата погашения месяц] from  #mv_loans		b where a.t='Повторный' and  a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата погашения день]<a.min_cdate order by b.[Дата погашения день] desc ) povt 
	where a.cweek>=@start_date
							
    group by cweek, category, t, is_new, is_new2		, x.no_successfull_call_3_month	, isnull(docr.[Дата выдачи месяц], povt.[Дата погашения месяц]) 							
    order by cweek, category, t, is_new, is_new2		, x.no_successfull_call_3_month	, isnull(docr.[Дата выдачи месяц], povt.[Дата погашения месяц]) 							

 --   select * into ##final7 from #final



	--drop table if exists analytics.dbo.[отчет по базам докредитования и повторников по неделям]
	--select * into analytics.dbo.[отчет по базам докредитования и повторников по неделям] from #final
	delete from analytics.dbo.[отчет по базам докредитования и повторников по неделям]
	where  cweek>=@start_date

	insert into analytics.dbo.[отчет по базам докредитования и повторников по неделям]
	select * from  #final
	where  cweek>=@start_date


	end


	