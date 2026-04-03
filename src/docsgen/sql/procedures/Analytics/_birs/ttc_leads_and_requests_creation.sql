CREATE     proc [_birs].[ttc_leads_and_requests_creation]
@mode nvarchar(max) = 'update',
@days int = 0--,
as
begin

if @mode = 'update'
begin


declare @datefrom date = getdate()-@days
--declare @datefrom date = '20230718'

--select getdate()-16

DROP TABLE	 IF EXISTS #leads
	SELECT cast(id as nvarchar(50))	id
		,companynaumen
		,creationdate
		,[Группа каналов]
		,[Канал от источника]
		,ФлагПрофильныйИтог
		,uf_source
		,uf_type
		,is_inst_lead
		,ДатаЛидаЛСРМ
	INTO #leads
	FROM Feodor.dbo.dm_leads_history_light
	WHERE [Канал от источника] <> 'cpa нецелевой'
		AND ДатаЛидаЛСРМ >= @datefrom


insert into  #leads
	SELECT lcrm_id id
		,isnull(companynaumen, '')
		,creationdate
		,[Группа каналов]
		,[Канал от источника]
		,Профильный
		,uf_source
		, uf_type
		,is_inst_lead
		,[UF_REGISTERED_AT] ДатаЛидаЛСРМ
	--INTO #leads					--  select *   
	FROM Feodor.dbo.dm_leads_history_online_current_day
	WHERE [Канал от источника] <> 'cpa нецелевой'
	and 	   [UF_REGISTERED_AT] >=@datefrom
													
insert into  #leads
	SELECT cast(id as nvarchar(50))	id
		,isnull(companynaumen, '')
		,creationdate
		,[Группа каналов]
		,[Канал от источника]
		,ФлагПрофильныйИтог
		,uf_source
		,uf_type
		,is_inst_lead
		,ДатаЛидаЛСРМ
	--INTO #leads					--  select *   
	FROM Feodor.dbo.lead_light_tbl
	WHERE [Канал от источника] <> 'cpa нецелевой'
	and 	   [UF_REGISTERED_AT] >=@datefrom
	
	;with v  as (select *, row_number() over(partition by id order by creationdate desc) rn from #leads ) delete from v where rn>1

		--select * from #leads


drop table if exists #zayvki_lf
		
select		
	number,  original_lead_id	  lead_id
into 		
	#zayvki_lf	
from 		
	stg._lf.request

drop table if exists #zayvki		
		
select		
	Номер,	
	ДатаЗаявкиПолная,	
	ПризнакЗайм,	
	ПризнакЗаявка,	
	[Выданная сумма],	
	isnull(b.lead_id, cast( fa.[lcrm id]	as nvarchar(36)) )	[lcrm id]
into 		
	#zayvki	
from 		
	Reports.dbo.dm_Factor_Analysis_001 fa
	left join #zayvki_lf b on fa.Номер=	b.number
		
		--exec create_table '#zayvki_lf'

drop table if exists #zvonki		
		
SELECT 		
	f.uuid,	
	f.creationdate creationdate,	
	f.phonenumbers,	
	--f.statetitle,	
	f.projectuuid,	
	f.projecttitle,	
	cast(f.lcrm_id as nvarchar(36)) lcrm_id,	
--	f.speaking_time,	
	f.attempt_result,	
	f.attempt_start,		   
	f.session_id,
	f.login
into 		
	#zvonki	
FROM 		
	[Feodor].[dbo].[dm_calls_history]  f (nolock)	
 join #leads  p on try_cast(p.id as numeric)=f.lcrm_id	 
 and f.attempt_start>=p.ДатаЛидаЛСРМ
 and f.creationdate>=p.ДатаЛидаЛСРМ

insert into  #zvonki		
		
SELECT 		
	f.uuid,	
	f.creationdate creationdate,	
	f.phonenumbers,	
	--f.statetitle,	
	f.projectuuid,	
	f.projecttitle,	
	f.lcrm_id,	
--	f.speaking_time,	
	f.attempt_result,	
	f.attempt_start,		   
	f.session_id,
	f.login
 
FROM 		
	[Feodor].[dbo].[dm_calls_history_current_day]  f (nolock)	
 join #leads  p on p.id=f.lcrm_id		  and f.attempt_start is not  null	 

insert into  #zvonki		
		
SELECT 		
	f.uuid,	
	f.creationdate creationdate,	
	f.phonenumbers,	
	--f.statetitle,	
	f.projectuuid,	
	f.projecttitle,	
	f.lead_id,	
--	f.speaking_time,	
	f.attempt_result,	
	f.attempt_start,		   
	f.session_id,
	f.login
 
FROM 		
	[Feodor].[dbo].[dm_calls_history_lf]  f (nolock)	
 join #leads  p on p.id=f.lead_id		  and f.attempt_start is not  null


 ;with v  as (select *, row_number() over(partition by session_id order by (select null)) rn from #zvonki ) delete from v where rn>1


--join [NaumenDbReport].[dbo].[mv_outcoming_call_project]  p on f.projectuuid = p.uuid
--
drop table if exists #zvonki_popytka		
		
select		
	ROW_NUMBER() over(partition by uuid order by attempt_start) ПопыткаКейс,	
	ROW_NUMBER() over(partition by lcrm_id order by attempt_start) Попытка,	
	count(*) over(partition by lcrm_id  ) [Попыток],	
	min(creationdate) over(partition by lcrm_id  ) [min creationdate],		  
	*	
into		
	#zvonki_popytka	
from		
	#zvonki	


	--select * from  #zvonki_popytka
		
--drop table if exists #zvonki_popytka_itog		
		
--select		
--	*	
--into		
--	#zvonki_popytka_itog	
--from		
--	#zvonki_popytka	
--where Попытка <= 10		
		
drop table if exists #ttc		
		
select 		
	f.session_id session_id,	
	f.uuid id,	
	TTC,	
	target_time_client_time,	
	f.creationdate  ,
	[Порядковый номер диалога]
into  		
	#ttc	
FROM 		
	[Analytics].[dbo].ttc_all_calls	 f
where creationdate >= @datefrom

		
drop table if exists #max_popytka		
		
select 		
	lcrm_id,	
	max(Попытка) Попытка_макс	
into 		
	#max_popytka	
from 		
	--#zvonki_popytka_itog	
	#zvonki_popytka
group by 		
	lcrm_id	

	
	/*

drop table if exists #vozvrat

SELECT id
into #vozvrat
  FROM [Analytics].[dbo].[v_feodor_leads]
  where Возврат is not null --and [Дата лида] >= @datefrom	
  
  */
drop table if exists #zayvka_popytka		
		
select		
	lcrm_id,	
	Попытка_макс,	
	ПризнакЗаявка,	
	ДатаЗаявкиПолная,	
	ПризнакЗайм,	
	[Выданная сумма]--,
	--iif(v.id is null,0,1) ПризнакВозврат
into		
	#zayvka_popytka	
from 		
	#max_popytka mp	
	left join #zayvki z on mp.lcrm_id = z.[lcrm id]	
--	left join #vozvrat v on z.[LCRM ID] = v.id
 	
drop table if exists #ttc_case
select id, crd, creationdateCC TTC into #ttc_case from report_TTC_details2 a
join (select distinct uuid from #zvonki ) b on a.id=b.uuid


--select * from #ttc_case


drop table if exists #itog		
		
select		
	i.ПопыткаКейс,	
	i.Попытка  ,	
	case when i.Попытка >= 10 then '10+' else format(i.Попытка, '0') end [Попытка группа],	
	case when i.Попытка >= 10 then 10 else i.Попытка  end [Попытка группа число],	
	i.Попыток,	
	case when i.Попыток >= 10 then '10+' else format(i.Попыток, '0') end [Попыток группа],	
    i.[min creationdate] [Дата первого кейса],
	    l.ДатаЛидаЛСРМ ,

	i.uuid,	
	i.phonenumbers,	
	--i.statetitle,	
	i.projecttitle,	
	i.projectuuid,	
	i.lcrm_id,	
	i.session_id,	
--	i.speaking_time,	
	i.attempt_result,	
	i.attempt_start ДатаЗвонка,	
	iif(i.login is null,0,1) ПризнакДозвон,
	 isnull(t.TTC, t_case.TTC) TTC,	
	isnull (t_case.crd ,t.target_time_client_time ) target_time_client_time,	
	z.ПризнакЗаявка,
	--z.ПризнакВозврат,
	z.ПризнакЗайм,	
	z.[Выданная сумма],	
	l.ФлагПрофильныйИтог,	
	case 	
		when t_case.ttc <= 2 then 'до 2 минут'
		when t_case.ttc between 2 and  5 then '2 - 5 минут'
		when t_case.ttc between 5 and  10 then '5 - 10 минут'
		when t_case.ttc between 10 and 20 then '10 - 20 минут'
		when t_case.ttc between 20 and  60 then '20 - 60 минут'
		when t_case.ttc between 60 and  120 then '60 - 120 минут'
		when t_case.ttc>120 then 'более 120 минут'
	end  'TTC кейс диапазон',	
	datepart(hour, i.[min creationdate]) ЧасСозданияПервогоКейса,	
	datepart(hour, i.attempt_start) ЧасЗвонка,	
	i.creationdate ДатаСозданияКейса,	
	t.ttc 'TTC от звонка',	
	case 	
		when t.ttc <= 2 then 'до 2 минут'
		when t.ttc between 2 and  5 then '2 - 5 минут'
		when t.ttc between 5 and  10 then '5 - 10 минут'
		when t.ttc between 10 and 20 then '10 - 20 минут'
		when t.ttc between 20 and  60 then '20 - 60 минут'
		when t.ttc between 60 and  120 then '60 - 120 минут'
		when t.ttc > 120 then 'более 120 минут'
 
	end 'TTC звонок диапазон'
	    ,l.is_inst_lead 
	    ,l.companynaumen
		,l.[Группа каналов]
		,l.[Канал от источника]
		,l.uf_source
		,l.uf_type
into #itog		
from #zvonki_popytka i		
	left join #ttc t on i.session_id = t.session_id	
	left join #ttc_case t_case on t_case.id = i.uuid and i.ПопыткаКейс=1
	left join #zayvka_popytka z on z.Попытка_макс = i.Попытка and z.lcrm_id = i.lcrm_id	
	left join #leads  l on i.lcrm_id = l.ID	
	
--select 		
--	*	
--from #itog i	
--order by ДатаЗвонка	
--
--declare @datefrom date = '20230701'

-- drop table if exists _birs.[TTC_leads_and_requests]
-- select * into _birs.[TTC_leads_and_requests] from #itog

delete from  _birs.[TTC_leads_and_requests] where 	  [ДатаЛидаЛСРМ]  >= @datefrom
insert into _birs.[TTC_leads_and_requests] 
select * from  #itog
--order by 4


-- drop table if exists _birs.[TTC_leads_and_requests]
-- select * into _birs.[TTC_leads_and_requests] from #itog
--delete from _birs.TTC_leads_and_requests
--insert into _birs.TTC_leads_and_requests
--select * from #itog

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '7DC62D9A-57D6-40AA-9A67-5A8F025AAAF2'

--alter table  _birs.[TTC_leads_and_requests] alter column lcrm_id nvarchar(36)
end

if @mode = 'select'
begin


drop table if exists #dm_feodor_projects
select  Name, max(new_name) new_name into #dm_feodor_projects from feodor.dbo.dm_feodor_projects
where new_name is not null
group by Name
--order by 


   select 
    a.[ПопыткаКейс] 
,   a.[Попытка] 
,   a.[Попытка группа] 
,   a.[Попытка группа число] 
,   a.[Попыток] 
,   a.[Попыток группа] 
,   a.[Дата первого кейса] 
,   cast(a.[Дата первого кейса]  as time) [Время первого кейса]
,   a.[ДатаЛидаЛСРМ] 
,   a.[uuid] 
,   a.[phonenumbers] 
--,   a.[statetitle] 
,   a.[projecttitle] 
,   a.[projectuuid] 
,   a.[lcrm_id] 
,   a.[session_id] 
--,   a.[speaking_time] 
,   a.[attempt_result] 
,   a.[ДатаЗвонка] 
,   a.[ПризнакДозвон] 
,   a.[TTC] 
,   a.[target_time_client_time] 
,   a.[ПризнакЗаявка] 
--,   a.[ПризнакВозврат] 
,   a.[ПризнакЗайм] 
,   a.[Выданная сумма] 
,   a.[ФлагПрофильныйИтог] 
,   a.[TTC кейс диапазон] 
,   a.[ЧасСозданияПервогоКейса] 
,   a.[ЧасЗвонка] 
,   a.[ДатаСозданияКейса] 
,   a.[TTC от звонка] 
,   a.[TTC звонок диапазон] 
,   a.[is_inst_lead] 
,   a.[Группа каналов] 
,   a.[Канал от источника] 
,   a.[uf_source] 
,   a.[uf_type] 
,   isnull(b.new_Name,  a.[companynaumen] )    [companynaumen]

from 

analytics._birs.TTC_leads_and_requests a
left join #dm_feodor_projects b on a.[companynaumen]=b.Name

 --exec select_table 'analytics._birs.TTC_leads_and_requests'

end



end