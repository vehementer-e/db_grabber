
CREATE proc [_birs].[docrNpovt_creation]
as
begin


declare @start_date date = dateadd(month, -12, cast(format( getdate()  , 'yyyy-MM-01') as date) )
--declare @start_date date = '20190601'
declare @start_date_3_month date = dateadd(month, -3 , @start_date  )
									
drop table if exists #Справочник_Договоры									
select dwh_new.dbo.getGUIDFrom1C_IDRREF(Клиент) CRMClientGUID, Код into #Справочник_Договоры from stg._1cCMR.Справочник_Договоры									
drop table if exists #dip_all									
									
select 									
         x.*									
		 , cast(format(cdate, 'yyyy-MM-01') as date) cmonth							
		 , d.CRMClientGUID							
into #dip_all 									
									
from (									
									
select cdate,external_id, main_limit, category, 'Докредитование' t 									
from dwh_new.dbo.docredy_history									
union all									
select cdate,external_id, main_limit, category, 'Повторный' t 									
from dwh_new.dbo.povt_history									
) x									
join #Справочник_Договоры d on d.Код=x.external_id									
where cdate >= @start_date_3_month 								
									
create nonclustered index t on #dip_all									
( cmonth, CRMClientGUID, t)									
									
drop table if exists #dip_all_over_month									
;									
									
with v as (									
select 									
--top 100 									
  *									
, row_number() over(partition by cmonth, CRMClientGUID, t order by main_limit desc, case when category='Красный' then 0 else 1 end desc  ) rn_over_month 									
, min(cdate) over(partition by cmonth, CRMClientGUID, t order by main_limit desc, case when category='Красный' then 0 else 1 end desc  ) min_cdate 									
, min(cmonth) over(partition by  CRMClientGUID  ) first_month 									
									
from #dip_all									
)									
									
select a.*, case when main_limit=0 then 1 else 0 end is_red

into #dip_all_over_month 									
from v a																		
where a.rn_over_month=1									
									
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
	
where  cc.creationdate >= @start_date_3_month 								

	
	
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
	, [Верификация КЦ месяц]								
	, [Предварительное одобрение]								
	, [Контроль данных]								
	, [Отказ Carmoney]								
	, Одобрено								
	, [Заем выдан]								
	, [Выданная сумма]								
	, case when [вид займа]='Повторный' then [вид займа] else 'Докредитование' end t
	, case 	 when  [Место cоздания] in ('Ввод операторами FEDOR', 'Ввод операторами КЦ') then 1 else 0 end	by_operator
	, case 	 when  [Место cоздания] not in ('Ввод операторами FEDOR', 'Ввод операторами КЦ') then 1 else 0 end by_client
	into #fa 								
	from Analytics.dbo.mv_dm_Factor_Analysis a left join #dr on #dr.Ссылка=a.[Ссылка заявка]								
	where [вид займа]<>'Первичный' and isPts=1						
	--select * from #fa								
							
									
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
									
	drop table if exists #fa_clients_over_month								
;									
									
	with v as (								
	select *
	,  max(case when by_operator=1 then [Верификация КЦ] end) over(partition by CRMClientGUID, t, [Верификация КЦ месяц])  request_by_operator
	,  max(case when by_client=1 then [Верификация КЦ] end) over(partition by CRMClientGUID, t, [Верификация КЦ месяц]) request_by_client
	, min([Заем выдан]) over(partition by CRMClientGUID, t, [Верификация КЦ месяц]) [Заем выдан_время]
	, count([Заем выдан]) over(partition by CRMClientGUID, t, [Верификация КЦ месяц]) [Заем выдан_итог]
	, sum([Выданная сумма]) over(partition by CRMClientGUID, t, [Верификация КЦ месяц]) [Выданная сумма_итог]
	, ROW_NUMBER() over(partition by CRMClientGUID, t, [Верификация КЦ месяц] order by 								
	case when [Заем выдан] is not null then 1 else 0 end desc
	, [Заем выдан]        
	,case when Одобрено is not null then 1 else 0 end desc
	, Одобрено					   desc			
	,case when [Контроль данных] is not null then 1 else 0 end desc
	 , [Контроль данных]			   desc					
	,case when [Предварительное одобрение] is not null then 1 else 0 end desc
	 , [Предварительное одобрение]  desc								

	, [Верификация КЦ]   							
									
	) rn_over_month from #fa_clients								
	)								
									
	select * into #fa_clients_over_month from v where rn_over_month=1								
									
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
									
	select a.*, cast(format(a.creationdate, 'yyyy-MM-01') as date) creationdate_month								
	, isnull( isnull(x.CRMClientGUID, x1.CRMClientGUID ), x2.CRMClientGUID ) CRMClientGUID								
	into #docr_cases_sessions_clients								
	from #docr_cases_sessions a								
	outer apply (select top 1 * from #mv_loans b where b.[Основной телефон клиента CRM 8]=a.phonenumbers ) x								
	outer apply (select top 1 * from #mv_loans b where b.[Телефон договор CMR 8]=a.phonenumbers ) x1								
	outer apply (select top 1 * from #mfo_ref b where b.[телефонмобильный 8]=a.phonenumbers ) x2								
									
	drop table if exists #docr_cases_sessions_clients_over_month								
									
	;								
	with v as (								
	select  *
	, ROW_NUMBER() over(partition by CRMClientGUID, creationdate_month order by login desc, attempt_start desc) rn_over_month 
	, count(*) over(partition by CRMClientGUID, creationdate_month  ) count_over_month 
	from #docr_cases_sessions_clients								
	)								
									
	select *  into #docr_cases_sessions_clients_over_month								
	from v where rn_over_month=1								
									
		
	drop table if exists #bl								
		
		select 
    a.[ReasonAdding_subject] 	 
,   a.[Phone] 
,   a.[create_at] 
	into #bl
from 

Stg._1cCRM.BlackPhoneList a

	drop table if exists #bl_client								


   select a.[create_at] [create_at] 
   	, isnull( isnull(x.CRMClientGUID, x1.CRMClientGUID ), x2.CRMClientGUID ) CRMClientGUID								
, case when [ReasonAdding_subject] = 'Исключение номера телефона (бессрочно)'	then 1 end unlim
into #bl_client
   from  #bl a


	outer apply (select top 1 * from #mv_loans b where b.[Основной телефон клиента CRM 8]='8'+a.[Phone] ) x								
	outer apply (select top 1 * from #mv_loans b where b.[Телефон договор CMR 8]='8'+a.[Phone] ) x1								
	outer apply (select top 1 * from #mfo_ref b where b.[телефонмобильный 8]='8'+a.[Phone] ) x2	


	--	exec select_table 'black', 'stg'
	DROP TABLE IF EXISTS  [#balance]
	
	SELECT --TOP 10000   
	D
	, КОД  КОД_balance
	,  [DPD НАЧАЛО ДНЯ], MAX([DPD НАЧАЛО ДНЯ]) OVER(PARTITION BY КОД ORDER BY D) [MAX DPD НАЧАЛО ДНЯ]
	, [прошло ДНЕЙ С ВЫДАЧИ]
		  INTO [#balance]
	FROM v_balance
	where [Тип Продукта]<>'Инстоллмент'


	
	drop table if exists #allos								
	 select session_id, connected, leg_id into #allos from v_call_legs where connected is not null and leg_id=1


	   	drop table if exists #phonenumbers							
		  select [Основной телефон клиента CRM 8] tel, CRMClientGUID CRMClientGUID into   #phonenumbers from 	#mv_loans union 
		  select [Телефон договор CMR 8], CRMClientGUID  from 	#mv_loans 


	   	drop table if exists #allos_on_number							


	   select b.CRMClientGUID, a.attempt_start into #allos_on_number from v_call a 
	   join  #phonenumbers b on a.client_number=b.tel   
	   join  #allos allos on allos.session_id=a.session_id



	   --select * from #allos_on_number 
	   --order by 2

	   	drop table if exists #see_marketing							
	    select distinct a.Код, a.МесяцПлатежа into #see_marketing from mv_repayments a join #dip_all b on a.ДеньПлатежа=b.cdate and  a.CRMClientGUID=b.CRMClientGUID and b.main_limit>0 and a.[Платеж онлайн]=1



	drop table if exists #f								
									
	select 								
	  a.cmonth								
	, a.external_id								
	, a.min_cdate								
	, a.CRMClientGUID	 							
	, a.main_limit								
	, a.category [Категория сегмент]								
	, a.t								
    , case when isnull(aa.main_limit, 0)=0 and a.main_limit>0 then  1 else 0 end [is_new]									
    , case 
	when isnull(aa.main_limit, 0)=0 and a.main_limit>0 then  'Появился лимит'
	when isnull(aa.main_limit, 0)> a.main_limit  then  'Уменьшился лимит'
	when isnull(aa.main_limit, 0)< a.main_limit  then  'Увеличился лимит'
	else  ''end [is_new2]									
	, b.creationdate_month								
	, b.attempt_start								
	, b.count_over_month								
	, b.login								
	, c.Номер		
	, c.request_by_operator
	, c.request_by_client
	, c.[Верификация КЦ]								
	, c.[Верификация КЦ месяц]								
	, c.[Предварительное одобрение]								
	, c.[Контроль данных]								
	, c.[Одобрено]								
	, c.[Отказ Carmoney]								
	, c.[Заем выдан_итог]								
	, c.[Заем выдан_время]								
	, c.[Выданная сумма_итог]	
	, isnull(isnull(docr.код, povt.Код), isnull(docr2.код, povt2.Код)) Код
	, isnull(docr.[Основной телефон клиента CRM 8], povt.[Основной телефон клиента CRM 8]) [Основной телефон клиента CRM 8]
	, isnull( isnull(docr.[Дата выдачи день], povt.[Дата погашения день]), isnull(docr2.[Дата выдачи день], povt2.[Дата погашения день])) [Дата предыдущего]
, cnt_closed.cnt cnt_closed
, cnt_opened.cnt cnt_opened
, case when bl.bl=1 then 'В ЧС' else '' end	[В чс сегмент]
, case when  bl_UNLIM.bl_UNLIM=1 then 'В ЧС БЕССРОЧНО' else '' end	[В чс бессрочно сегмент]
, case when  bl_90.bl_90=1 then 'В ЧС 90 дней' else '' end	[В чс 90 дней сегмент]
, balance.*
, isnull(last_time_not_same.cmonth, a.first_month)	  cmonth_last_time_not_same
, last_time_not_same.t	  t_last_time_not_same
, a.is_red
, retro_requests.*
, last_retro_requests.*
, last_allo.attempt_start	last_allo_attempt_start
, see_marketing.cnt_see_marketing
	into #f								
	from 								
	#dip_all_over_month a								
	left join #docr_cases_sessions_clients_over_month b on a.CRMClientGUID=b.CRMClientGUID and a.cmonth=b.creationdate_month								
	left join #fa_clients_over_month c on a.CRMClientGUID=c.CRMClientGUID and a.cmonth=c.[Верификация КЦ месяц] and a.t=c.t								
	left join #dip_all_over_month aa on a.CRMClientGUID=aa.CRMClientGUID and a.cmonth=dateadd(month, 1, aa.cmonth ) and a.t=aa.t								
	outer apply (select top 1 Код, [Дата выдачи день] , [Основной телефон клиента CRM 8] from  #mv_loans		b where a.t='Докредитование' and  a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата выдачи день]<a.min_cdate order by b.[Дата выдачи день] desc ) docr 
	outer apply (select top 1 Код, [Дата выдачи день] , [Основной телефон клиента CRM 8] from  #mv_loans		b where a.external_id=b.Код ) docr2 
	outer apply (select top 1 Код, [Дата погашения день], [Основной телефон клиента CRM 8] from  #mv_loans		b where a.t='Повторный' and  a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата погашения день]<a.min_cdate order by b.[Дата погашения день] desc ) povt 
	outer apply (select top 1 Код, [Дата погашения день], [Основной телефон клиента CRM 8] from  #mv_loans		b  where a.external_id=b.Код ) povt2 







 	outer apply (select   count(*) cnt from  #mv_loans		b where   a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата выдачи день]<a.min_cdate and isnull(b.[Дата погашения день], getdate())>a.min_cdate   ) cnt_opened 
 	outer apply (select   count(*) cnt from  #mv_loans		b where   a.CRMClientGUID=b.CRMClientGUID and b.isInstallment=0 and b.[Дата погашения день]<a.min_cdate  ) cnt_closed 
 	outer apply (select  top 1 1 bl from  #bl_client		b where   a.CRMClientGUID=b.CRMClientGUID and b.create_at<a.min_cdate  ) bl 
 	outer apply (select  top 1 1 bl_UNLIM from  #bl_client	b where   a.CRMClientGUID=b.CRMClientGUID AND unlim=1 and b.create_at<a.min_cdate  ) bl_UNLIM 
 	outer apply (select  top 1 1 bl_90 from  #bl_client		b where   a.CRMClientGUID=b.CRMClientGUID and b.create_at BETWEEN DATEADD(DAY, -90, a.min_cdate  ) AND a.min_cdate ) bl_90 
 	outer apply (select  top 1 * from  [#balance]		b where   isnull(isnull(docr.код, povt.Код), isnull(docr2.код, povt2.Код))=b.КОД_balance and b.d<=a.min_cdate  order by b.d desc ) balance 
 	outer apply (select  count(*) cnt_see_marketing from  [#see_marketing]		b where   isnull(isnull(docr.код, povt.Код), isnull(docr2.код, povt2.Код))=b.Код and b.МесяцПлатежа<a.cmonth   ) see_marketing 
 	outer apply (select  top 1 cmonth, t from  #dip_all_over_month		b where   a.CRMClientGUID=b.CRMClientGUID and a.cmonth>b.cmonth /*and a.t=b.t*/ and a.is_red<>b.is_red  order by b.cmonth desc ) last_time_not_same 
 	outer apply (select  
 	  count([Отказ Carmoney]) request_refuses
 	, count(case when Одобрено is not null and [Заем выдан] is null then 1 end) request_not_TU 
 	, count(case when [Предварительное одобрение] is not null and [Контроль данных] is null  then 1 end) request_not_KD 
 	
 	from  #fa		b where   a.CRMClientGUID=b.CRMClientGUID_factor and a.t=b.t and b.[Верификация КЦ] between dateadd(day, -90, a.min_cdate) and a.min_cdate and b.[Верификация КЦ] between isnull(docr.[Дата выдачи день], povt.[Дата погашения день]) and a.min_cdate ) retro_requests 
 	  
 	outer apply (select  
 	  count([Отказ Carmoney]) last_request_refuses
 	, count(case when Одобрено is not null and [Заем выдан] is null then 1 end)  last_request_not_TU 
 	, count(case when [Предварительное одобрение] is not null and [Контроль данных] is null  then 1 end)  last_request_not_KD 
 	, count(*) cnt
 	   from (
 	select top 1 * from  #fa		b where   a.CRMClientGUID=b.CRMClientGUID_factor and a.t=b.t  and b.[Верификация КЦ] between dateadd(day, -90, a.min_cdate) and a.min_cdate and b.[Верификация КЦ] between dateadd(day, 1, isnull(docr.[Дата выдачи день], povt.[Дата погашения день])) and a.min_cdate order by b.[Верификация КЦ]  desc ) x ) last_retro_requests 
 	 
 	outer apply (select  top 1 attempt_start attempt_start from  #allos_on_number		b where   a.CRMClientGUID=b.CRMClientGUID and b.attempt_start < a.min_cdate order by b.attempt_start desc ) last_allo
   	
	--SELECT count(*) cnt FROM  #f1
	-- where cnt_closed>2	and main_limit>0
	-- order by [Дата предыдущего] desc

	-- select * from #f
	--where CRMClientGUID='03B4F0A1-0907-11E8-A814-00155D941900'
	----where last_request_not_KD>0
	--order by cmonth

	drop table if exists ##f1

		select  a.*
		, datediff(day, [Дата предыдущего], a.min_cdate) [Дней с предыдущего]
		, case when datediff(day, last_allo_attempt_start, a.min_cdate) is not null then 'Было алло до этого' else 'Не было алло' end [Было ли предыдущее алло сегмент]
		, case when cnt_see_marketing>0 then 'Видел предложение' else 'Не видел предложение' end [Видел ли предложение сегмент]
		, case 
		when datediff(day, last_allo_attempt_start, a.min_cdate)<=365 then 'Менее года с предыдущего алло' 
		when datediff(day, last_allo_attempt_start, a.min_cdate)>365 then  'Более года с предыдущего алло' 
		else 'Не было алло' end [Менее года с предыдущего алло сегмент]
		, case 
		when datediff(day, last_allo_attempt_start, a.min_cdate)<=90 then  'Менее 90 дней с предыдущего алло' 
		when datediff(day, last_allo_attempt_start, a.min_cdate)> 90 then  'Более 90 дней с предыдущего алло' 
		else 'Не было алло' end [Менее 90 дней с предыдущего алло сегмент]
		, case when datediff(month,  cast(format([Дата предыдущего], 'yyyy-MM-01' ) as date), cmonth)<=12 then '[Менее года с предыдущего]' else '[Более года с предыдущего]' end [Менее года с предыдущего займа сегмент]
		, datediff(day, [Дата предыдущего], isnull(a.[Заем выдан_время] , a.[Верификация КЦ])  ) 	[Через сколько заявка]

		, case when f.[Первичная сумма]>=f.[Выданная сумма] then 'Порезан'  when  f.[Первичная сумма]<f.[Выданная сумма] then 'Не порезан'  end [Порезан сегмент]
		, case when f.[Первичная сумма]>=f.[Выданная сумма] and f.[Первичная сумма]-f.[Выданная сумма]<=main_limit then 'Хватает лимита'  
		 when f.[Первичная сумма]>=f.[Выданная сумма] and f.[Первичная сумма]-f.[Выданная сумма]>main_limit then 'Не хватает лимита' else '' end [Порезан и хватает лимита сегмент]
		, case 
		when b.Сумма<=330000 then '1) 0..330'
		when b.Сумма<=330000*2 then '2) 330..660'
		when b.Сумма<=330000*4 then '3) 660+' end  [Сумма сегмент]
		, case 
		when b.[Текущая процентная ставка]<=60 then '1) 0..60'
		when b.[Текущая процентная ставка]<=100 then '2) 60..90'
		when b.[Текущая процентная ставка]>100 then '3) 100+' end  [Процентная ставка сегмент]
		,case f.[Признак страховка] when 1 then 'Страховка' else 'Без страховки' end  [Страховка сегмент]
		,case when isnull(mv.[Признак Доработки Верификация ТС]     , 0)   +
		 isnull(mv.[Признак Доработки КД]                 , 0)   +
		 isnull(mv.[Признак Доработки Верификация клиента], 0)	  >0 then 'Доработки' else '' end [Признак Доработки сегмент]
		 , case 
		 when cnt_closed	 =1 then 'L2'
		 when cnt_closed	 >2 then 'L3+'
		 end [Лояльность сегмент]
		 , b.[Канал первого займа] [Канал по первому займу сегмент]
		 , b.[Канал] [Канал по последнему займу сегмент]
		 , datediff(minute, f.[КОнтроль данных] ,f.[Заем выдан]) TTC
		 , case 
		 when datediff(minute, f.[КОнтроль данных] ,f.[Заем выдан]) <= 15 then '1) TTC <15 мин'
		 when datediff(minute, f.[КОнтроль данных] ,f.[Заем выдан]) <= 60 then '2) TTC 15..60 мин'
		 when datediff(minute, f.[КОнтроль данных] ,f.[Заем выдан]) >  60 then '3) TTC >60 мин'
		 else '' end   [TTC сегмент]
		 
		 , datediff(minute, f.[КОнтроль данных] ,f.Одобрено) TTY
		  , case 
		 when datediff(minute, f.[КОнтроль данных] ,f.Одобрено) <= 15 then '1) TTY <15 мин'
		 when datediff(minute, f.[КОнтроль данных] ,f.Одобрено) <= 60 then '2) TTY 15..60 мин'
		 when datediff(minute, f.[КОнтроль данных] ,f.Одобрено) >  60 then '3) TTY >60 мин'
		 else '' end   [TTY сегмент]
		 , b.[Способ оформления займа]	   [Способ оформления займа сегмент]
		 , isnull( f.[Место cоздания], '' ) 	[Место создания сегмент]
		, CASE WHEN [MAX DPD НАЧАЛО ДНЯ]>14 THEN '1) Просрочка > 14 дней' else '2) Без просрочки > 14 дней' end [Наличие исторической просрочки по последнему займу сегмент] 
		,cast(format([Дата предыдущего], 'yyyy-MM-01' ) as date) [Месяц предыдущего]
		, datediff(month,  cast(format([Дата предыдущего], 'yyyy-MM-01' ) as date), cmonth)	  [Месяцев прошло]
		into ##f1
		from #f	 a
		left join mv_loans b on a.Код=b.Код
		left join reports.dbo.dm_factor_analysis_001 f on a.Код=f.нОмер
		left join mv_dm_Factor_Analysis mv on a.Код=mv.нОмер
	--where CRMClientGUID = '7D838F8C-1B07-4197-91FB-C7F952BF32C9'
	order by cmonth				 
 
	drop table if exists _birs.docrNpovt
	select * into _birs.docrNpovt
	from 	##f1
--	select CRMClientGUID, count(distinct Код) cnt from #f1
--group by CRMClientGUID
--order by 2 desc
--	drop table if exists #final
		
		end