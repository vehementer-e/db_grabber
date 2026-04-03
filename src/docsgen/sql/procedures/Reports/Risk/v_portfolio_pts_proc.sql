CREATE procedure [Risk].[v_portfolio_pts_proc]
as
begin
SET DATEFIRST 1	 ;

SET XACT_ABORT  ON;
begin try
drop table if exists #smpl
SELECT distinct
	o.number
	, stage
	, call_date
	, strategy_version
	, client_type_1
	, client_type_2
	, Decision
	, Decision_Code
	, APR
	, Branch_id
	, probation
	, no_probation
	, offername
	, o.last_name
	, year_ts
	, nbchPV2score
	, apr_segment
	, EqxScore
	, okbscore
	,  passport_series
	, passport_number
	, sourceRequest
	, sourceRequests
	, pts_type, leadsource
into #smpl
from [stg].[_loginom].[Originationlog] o
left join (select number, last_name, leadsource, sourceRequest, sourceRequests from [stg].[_loginom].[application] where stage = 'Call 1') a
on o.number = a.number
left join (select number, pts_type from [stg].[_loginom].[application] where stage = 'Call 2') a2
on o.number = a2.number
where call_date>='20231001'
and (o.number<>'19061300000088' and o.number<>'20101300041806' and o.number<>'21011900071506' and o.number<>'21011900071507')




drop table if exists #a
select distinct
		number, call_date as C1_date, APR as C1_APR,  nbchPV2score, probation, no_probation, apr_segment,passport_series, passport_number, sourceRequest, sourceRequests, EqxScore, leadsource,
		offername as C1_offername, client_type_1, decision as C1_decision, decision_code as C1_dec_code,
		case when (Branch_id='3645' or Branch_id='5271') then 1 else 0 end as REFIN_FL, strategy_version, 
		ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
into #a
	from #smpl
	where stage='Call 1' and Last_name not like '%Тест%'




drop table if exists #ab
select b.*
into #ab
from 
			(select distinct 
				number, client_type_2, decision as C2_decision, decision_code as C2_dec_code, strategy_version, nbchPV2score, year_ts, passport_series, passport_number,
				case when (Branch_id='3645' or Branch_id='5271') then 1 else 0 end as REFIN_FL, apr c2_apr, apr_segment c2_apr_segment, probation, EqxScore, pts_type,
		case when (probation = 1 and no_probation =1) then 1 else 0 end as no_probation,
				ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
			from #smpl
			where stage='Call 2') b
			where b.rn=1


drop table if exists #ac
select c.* 
into #ac
from 
			(select distinct 
				number, decision as C15_decision, decision_code as C15_dec_code,
				ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
			from #smpl
			where stage='Call 1.5') c
			where c.rn=1



drop table if exists #ad
select D.* 
into #ad
from 
			(select distinct 
				number, decision as C3_decision, decision_code as C3_dec_code,
				ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
			from #smpl
			where stage='Call 3') D
			where D.rn=1




drop table if exists #ae
select E.* 
into #ae
from 
			(select distinct 
				number, decision as C4_decision, decision_code as C4_dec_code,
				ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
			from #smpl
			where stage='Call 4') E
			where E.rn=1



drop table if exists #ba
select B.* 
into #ba
from		
			(select distinct 
						number, APR_SEGMENT as C1_APR_SEGMENT, micro_ever,
						ROW_NUMBER() OVER(PARTITION BY number ORDER BY score_carmoney DESC) rn
			from [stg].[_loginom].[score]
			where stage='Call 1') B
			where b.rn=1




drop table if exists #guid
SELECT distinct number, sourceRequest, sourceRequests, COUNT(value) AS guid_count
into #guid
FROM #a
CROSS APPLY STRING_SPLIT(sourceRequests, ';')
WHERE RTRIM(LTRIM(value)) <> '' and rn = 1
GROUP BY number, sourceRequest, sourceRequests;




drop table if exists #tisk
select 
	#a.Number, #a.C1_date, day(C1_date) as [DAY], month(C1_date) as MON, concat(month(C1_date),'_',year(C1_date)) as STAGE_DATE_AGG, --ПЕРИОД
	case when pts_type = 1 then 'Бумажный' 
		when pts_type = 2 then 'Электронный'
		else 'Недошел до Call 2' end as pts_type, leadsource,
	case when #guid.sourceRequest is not null then 1 else 0 end as fl_transfer,
	case when guid_count > 1 then (guid_count - 1) else 0 end as cnt_transfer,
	case when #ab.Passport_series is not null then #ab.Passport_series else #a.Passport_series end as Passport_series,
	case when #ab.Passport_number is not null then #ab.Passport_number else #a.Passport_number end as Passport_number, 
	case when #ab.EqxScore is not null then #ab.EqxScore else #a.EqxScore end as EqxScore,
	case when c1_date >= '20240903 11:40' then 'new_score' 
		when c1_date >= '20240425' then '25.04-30.06.' 
			else 'old_score' end as period_date,
	case when #AB.strategy_version is not null then #AB.strategy_version else #a.strategy_version end as strategy_version_last, --стратегия
	--определяем тип клиента
	case	when  (#AB.client_type_2='docred' or #AB.client_type_2='parallel') then '2.ACTIVE' --если на С2 докредит или паралел, то это активный клиент
			when  (#AB.client_type_2='repeated') then '3.REPEATED' --если С2 повторный, значит это повторный клиент
			when  (#A.client_type_1='repeated') then '3.REPEATED' --если на С1 повторный, значит повторный клиент
			when  (#A.client_type_1='active') then '2.ACTIVE' --если на С1 активный, значит активный клиент
			else '1.NEW' --все остальные новые
	end as CLIENT_TYPE,
	--определяем тип стратегии
	case	when  #a.strategy_version='INST_V1' then 'INST' --инстолмент
			when (#AB.client_type_2='docred' or #AB.client_type_2='parallel' or #AB.client_type_2='repeated') then 'REP' --по типу клиента определяем повторного клиента, если нет на С2, то смотрим на С1
			when  (#A.client_type_1='repeated' or #A.client_type_1='active') then 'REP'
			else 'NEW'
	end as STRAT_TYPE,
	--определяем макисмальную стадию
	case	when #AE.C4_decision is not null then 'Call 4' --дошел до С4
			when #AD.C3_decision  is not null then 'Call 3'--дошел до С3
			when #AB.C2_decision  is not null then 'Call 2'--дошел до С2
			when #AC.C15_decision  is not null then 'Call 1.5'--дошел до С15
			else 'Call 1'
	end as MAX_STAGE,
	case	when #AE.C4_dec_code is not null then #AE.C4_dec_code
			when #AD.C3_dec_code is not null then #AD.C3_dec_code
			when #AB.C2_dec_code is not null then #AB.C2_dec_code
			when #AC.C15_dec_code is not null then #AC.C15_dec_code
			when #a.C1_dec_code is not null then #a.C1_dec_code
	end as DECISION_CODE,
	case when #ab.probation is not null then #ab.probation else #a.probation end as probation, 
	#a.C1_decision, #AC.C15_decision, #AB.C2_decision, #AD.C3_decision, #AE.C4_decision, --решения на С1, С15, С2, С3, С4
	case when #a.REFIN_FL=1 or #AB.REFIN_FL=1 then 1 else 0 end as REFIN_FL_,  --признак рефинансирования
--RBP (risk best pricing. RBP1 сегмент самый лучший, самые хорошие ставки, )	
	#a.C1_APR, #a.C1_offername, #A.APR_SEGMENT c1_apr_segment, #ab.C2_APR, #ab.c2_apr_segment, year_ts,
-- other-для воронки	
	case	when C1_decision ='Decline' then 0 else 1 end as AR_CALL1, --подсчет неотказов (если решение на С1 отказ, то 0, иначе (положительно или доработка) , то 1)
	case	when #AC.C15_decision ='Decline' or #AC.C15_decision is null then 0 else 1 end as AR_CALL15,--подсчет полож.решений (если решение на С15 отказ или не принято, то 0, иначе положительно), то 1)
	case	when #AB.C2_decision ='Decline' or #AB.C2_decision is null then 0 else 1 end as AR_CALL2,
	case	when #AD.C3_decision ='Decline' or #AD.C3_decision is null then 0 else 1 end as AR_CALL3,
	case	when #AE.C4_decision ='Decline' or #AE.C4_decision is null then 0 else 1 end as AR_CALL4
into #tisk
from #a
--определение решений на С1, С15, С2, С3, С4
left join #ab
on #a.number=#AB.number
left join #AC
on #a.number=#AC.number
left join #AD
on #a.number=#AD.number
left join #AE
on #a.number= #ae.number
left join #ba
on #a.number=#ba.number
left join (select number, apr_segment c2_apr_segment from [stg].[_loginom].[Originationlog] where stage = 'Call 2' and call_date >= '20230127 12:18') m
on #a.number=m.number
left join #guid
on #a.number=#guid.number
where #a.rn=1 and #a.strategy_version <> 'INST_V1'






/* проверка данных о договоре*/ 
drop table if exists #tisk1
select	distinct 
		A.*, B.*,
case	when PROBATION=1 then 'RBP_PROBATION' --сегмент RBP испытательный срок
			--when a.no_probation = 1 then 'RBP_NO_PROBATION'
			when (REFIN_FL_ = 1) then 'RBP_REFIN' ----сегмент RBP рефинансирование
			when (C1_APR_SEGMENT in ('1','2','3','4', '1001','1002','1003') or 
				c2_apr_segment in ('1','2','3','4', '1001','1002','1003')) then 'RBP 1'
			when (C1_APR_SEGMENT in ('10','20','21','22','23','24', '1101') or
				c2_apr_segment in ('10','20','21','22','23','24', '1101')) then 'RBP 2'
			when C1_date>='20211111 00:03' and (C1_APR_SEGMENT in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202') 
				or c2_apr_segment in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202')) then 'RBP 3'
			else 'RBP 4'
	end as RBP_GR
into #tisk1
from #tisk A
left join (
select distinct 
		[ДоговорНомер], 
		cast(isnull(replace(СуммаВыдачи,',','.'),0) as float) as amount_agr, ISSUED_FL=1, --флаг договора есть/нет
		cast(ПроцСтавкаКредит as nvarchar(1488)) as APR
from reports.dbo.report_Agreement_InterestRate --[c2-vsr-dwh].reports.dbo.report_Agreement_InterestRate --если в этой таблице есть договор, значит можно поставить флаг, что была выдача
) B
on cast(A.number as nvarchar(1488))=cast(B.ДоговорНомер as nvarchar(1488))




--final table
DROP TABLE IF EXISTS #tisk2
select distinct
R.*,
case	when (R.AR_CALL1+R.AR_CALL15+R.AR_CALL2+R.AR_CALL3+R.AR_CALL4)>0 and R.ISSUED_FL=1 then R.amount_agr
		else 0
		end as LIMIT,
case	when (R.MAX_STAGE='Call 1' and R.AR_CALL1=0) then '4.1. Strategy_Decline C1' --максимальная стадия по заявка С1 и на С1 он не одобрен, то это отказ на С1
		when (R.MAX_STAGE='Call 2' and R.AR_CALL2=0) then '4.2. Strategy_Decline C2'--максимальная стадия по заявка С2 и на С2 он не одобрен, то это отказ на С2
		when (R.MAX_STAGE='Call 1.5' and R.AR_CALL15=0) then '5.CH_Decline' --максимальная стадия по заявка С15 и на С15 он не одобрен, то это отказ чекера
		when (R.MAX_STAGE='Call 3' and R.AR_CALL3=0) or (R.MAX_STAGE='Call 4' and R.AR_CALL4=0) then '6.UW_Decline' --максимальная стадия по заявка С3 или С4 и на С3 или С4 он не одобрен, то это отказ андер
		when (R.amount_agr is not null and R.ISSUED_FL=1) then '1.Issued' --выданные
		when (R.MAX_STAGE='Call 4' and R.AR_CALL4=1) then '2.LOAN NOT ISSUED' --заявка была на С4 и кредит одобрен, при этом нет флага Выдан, то это одобрено, но не выдано
		when (R.MAX_STAGE='Call 1' and R.AR_CALL1=1) then '3.1. ANNUL F C1' --ANNUL это когда одобрено, но нужно подгрузить документы и они не подгружены в течении 5 дней (отказ клиента: не ответил на вопросы, не подгрузил доки)
		when (R.MAX_STAGE='Call 1.5' and R.AR_CALL15=1) then '3.2. ANNUL F C15'
		when (R.MAX_STAGE='Call 2' and R.AR_CALL2=1) then '3.3. ANNUL F C2'
		when (R.MAX_STAGE='Call 3' and R.AR_CALL3=1) then '3.4. ANNUL F C3'
		else '7.WTF'
end as FIN_STATUS
INTO #tisk2
from #tisk1 R





--определяем дубли
DROP TABLE IF EXISTS #double
select distinct c.Номер, c.[Дубль], c.[Канал от источника] 
,c.[Группа каналов],
								case	when [Группа каналов]='CPA' then [Канал от источника]
										when [Группа каналов]='CPC' then [Группа каналов]
										when [Группа каналов]='Органика' then [Группа каналов]
										when [Группа каналов]='Партнеры' then [Группа каналов]
										else 'ДРУГОЕ'
								end as gr_CHANNEL
INTO #double
FROM [Reports].[dbo].[dm_Factor_Analysis] c
where [Номер] in (
select distinct number from #smpl)



----повторники
DROP TABLE IF EXISTS #povt;
with a as
(select distinct #tisk2.number, category, count(*) over (partition by #tisk2.number) cnt_num,
case when category = 'Красный' then 1 else 0 end as is_red,
case when category = 'Оранжевый' then 1 else 0 end as is_orange,
case when category = 'Желтый' then 1 else 0 end as is_yellow,
case when category = 'Синий' then 1 else 0 end as is_blue,
case when category = 'Зеленый' then 1 else 0 end as is_green
from #tisk2
left join dwh_new.dbo.povt_history r
on #tisk2.passport_series = r.doc_ser and #tisk2.passport_number = r.doc_num and cast(c1_date as date) = cdate
)
select distinct number, cnt_num, max(is_red) over (partition by number) is_red, 
			max(is_orange) over (partition by number) is_orange, 
			max(is_yellow) over (partition by number) is_yellow, 
			max(is_blue) over (partition by number) is_blue, 
			max(is_green) over (partition by number) is_green 
into #povt
from a




DROP TABLE IF EXISTS #povt2
select *,
case when is_red = 1 and is_orange = 0 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'К'
	when is_red = 0 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'О'
	when is_red = 0 and is_orange = 0 and is_yellow = 1 and  is_blue = 0 and is_green = 0 then 'Ж'
	when is_red = 0 and is_orange = 0 and is_yellow = 0 and  is_blue = 1 and is_green = 0 then 'С'
	when is_red = 0 and is_orange = 0 and is_yellow = 0 and  is_blue = 0 and is_green = 1 then 'З'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'КО'
	when is_red = 1 and is_yellow = 1 and is_orange = 0 and  is_blue = 0 and is_green = 0 then 'КЖ'
	when is_red = 1 and is_blue = 1 and is_orange = 0 and  is_yellow = 0 and is_green = 0 then 'КС'
	when is_red = 1 and is_green = 1 and is_orange = 0 and  is_yellow = 0 and is_blue = 0 then 'КЗ'
	when is_orange = 1 and is_yellow = 1 and is_red = 0 and  is_blue = 0 and is_green = 0 then 'OЖ'
	when is_orange = 1 and is_blue = 1 and is_red = 0 and  is_yellow = 0 and is_green = 0 then 'OC'
	when is_orange = 1 and is_green = 1 and is_red = 0 and  is_yellow = 0 and is_blue = 0 then 'OЗ'
	when is_yellow = 1 and is_blue = 1 and is_red = 0 and  is_orange= 0 and is_green = 0 then 'ЖС'
	when is_yellow = 1 and is_green = 1 and is_red = 0 and  is_orange = 0 and is_blue = 0 then 'ЖЗ'
	when is_blue = 1 and is_green = 1 and is_red = 0 and  is_yellow = 0 and is_orange = 0 then 'СЗ'
	when is_red = 1 and is_orange = 1 and is_yellow = 1 and  is_blue = 0 and is_green = 0 then 'КОЖ'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 1 and is_green = 0 then 'КОС'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 1 then 'КОЗ'
	when is_red = 1 and is_orange = 0 and is_yellow = 1 and  is_blue = 1 and is_green = 0 then 'КЖС'
	when is_red = 1 and is_orange = 0 and is_yellow = 1 and  is_blue = 0 and is_green = 1 then 'КЖЗ'
	when is_red = 1 and is_orange = 0 and is_yellow = 0 and  is_blue = 1 and is_green = 1 then 'КСЗ'
	when is_red = 0 and is_orange = 1 and is_yellow = 1 and  is_blue = 1 and is_green = 0 then 'ОЖС'
	when is_red = 0 and is_orange = 1 and is_yellow = 1 and  is_blue = 0 and is_green = 1 then 'ОЖЗ'
	when is_red = 0 and is_orange = 0 and is_yellow = 1 and  is_blue = 1 and is_green = 1 then 'ЖСЗ'

	else 'WTF' end as gr_category,
case when (is_red + is_orange + is_yellow + is_blue + is_green) = 1 then 'sole_category'
	when (is_red + is_orange + is_yellow + is_blue + is_green) > 1 then 'combo_category'
	else 'WTF' end as total_category,
case when is_red = 1 and is_orange = 0 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'К'
	when is_red = 0 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'О'
	when is_red = 0 and is_orange = 0 and is_yellow = 1 and  is_blue = 0 and is_green = 0 then 'Ж'
	when is_red = 0 and is_orange = 0 and is_yellow = 0 and  is_blue = 1 and is_green = 0 then 'С'
	when is_red = 0 and is_orange = 0 and is_yellow = 0 and  is_blue = 0 and is_green = 1 then 'З'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 0 then 'О'
	when is_red = 1 and is_yellow = 1 and is_orange = 0 and  is_blue = 0 and is_green = 0 then 'Ж'
	when is_red = 1 and is_blue = 1 and is_orange = 0 and  is_yellow = 0 and is_green = 0 then 'С'
	when is_red = 1 and is_green = 1 and is_orange = 0 and  is_yellow = 0 and is_blue = 0 then 'З'
	when is_orange = 1 and is_yellow = 1 and is_red = 0 and  is_blue = 0 and is_green = 0 then 'Ж'
	when is_orange = 1 and is_blue = 1 and is_red = 0 and  is_yellow = 0 and is_green = 0 then 'C'
	when is_orange = 1 and is_green = 1 and is_red = 0 and  is_yellow = 0 and is_blue = 0 then 'З'
	when is_yellow = 1 and is_blue = 1 and is_red = 0 and  is_orange= 0 and is_green = 0 then 'С'
	when is_yellow = 1 and is_green = 1 and is_red = 0 and  is_orange = 0 and is_blue = 0 then 'З'
	when is_blue = 1 and is_green = 1 and is_red = 0 and  is_yellow = 0 and is_orange = 0 then 'З'
	when is_red = 1 and is_orange = 1 and is_yellow = 1 and  is_blue = 0 and is_green = 0 then 'Ж'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 1 and is_green = 0 then 'С'
	when is_red = 1 and is_orange = 1 and is_yellow = 0 and  is_blue = 0 and is_green = 1 then 'З'
	when is_red = 1 and is_orange = 0 and is_yellow = 1 and  is_blue = 1 and is_green = 0 then 'С'
	when is_red = 1 and is_orange = 0 and is_yellow = 1 and  is_blue = 0 and is_green = 1 then 'З'
	when is_red = 1 and is_orange = 0 and is_yellow = 0 and  is_blue = 1 and is_green = 1 then 'З'
	when is_red = 0 and is_orange = 1 and is_yellow = 1 and  is_blue = 1 and is_green = 0 then 'С'
	when is_red = 0 and is_orange = 1 and is_yellow = 1 and  is_blue = 0 and is_green = 1 then 'З'
	when is_red = 0 and is_orange = 0 and is_yellow = 1 and  is_blue = 1 and is_green = 1 then 'З'

	else 'WTF' end as gr_sole_category
into #povt2
from #povt






DROP TABLE IF EXISTS #rep_type_pts
select a.number, cnt_closed_pts
into #rep_type_pts
from #tisk2 a
left join (select distinct number, max(case when Names = 'closed_pts' or Names = 'cnt_closed_pts' then [Values] end) as cnt_closed_pts
			from stg._loginom.strategy_calc with (nolock)
			where (Names = 'closed_pts'or Names = 'cnt_closed_pts')
			group by number) o
on a.number = o.number



DROP TABLE IF EXISTS #rep_type_inst
select a.number, cnt_closed_inst
into #rep_type_inst
from #tisk2 a
left join (select distinct number, max(case when Names = 'closed_inst' or Names = 'cnt_closed_inst' then [Values] end) as cnt_closed_inst
			from stg._loginom.strategy_calc with (nolock)
			where (Names = 'closed_inst'or Names = 'cnt_closed_inst')
			group by number) s
on a.number = s.number
                                                                                                                                                     


DROP TABLE IF EXISTS #rep_type_pdl
select a.number, cnt_closed_pdl
into #rep_type_pdl
from #tisk2 a
left join (select distinct number, max(case when Names = 'closed_pdl' or Names = 'cnt_closed_pdl' then [Values] end) as cnt_closed_pdl
			from stg._loginom.strategy_calc with (nolock)
			where (Names = 'closed_pdl'or Names = 'cnt_closed_pdl')
			group by number) t
on a.number = t.number







DROP TABLE IF EXISTS #category_povt
select t.number, cast(c1_date as date) c1_date, t.Passport_series,	u.Passport_number, u.category
into #category_povt
from #tisk2 t
left join (select cdate, Passport_series, Passport_number, category
				from dwh2.[risk].[povt_inst_buffer_history]) u
on cast(c1_date as date) =  u.cdate and t.Passport_series = u.Passport_series and t.Passport_number = u.Passport_number


;

drop table if exists #pivot;
-----выгрузка в ексель
with a as
(select distinct #tisk2.*, Дубль, no_probation, k_disk, fl_rus_auto, all_fl = 1, 
cast (c1_date as date) [date],
case	when (MAX_STAGE='Call 1' and AR_CALL1=0) then 'Call 1'
		when (MAX_STAGE='Call 1.5' and AR_CALL15=0) then 'Call 1.5'		
		when (MAX_STAGE='Call 2' and AR_CALL2=0) then 'Call 2'
		when (MAX_STAGE='Call 3' and AR_CALL3=0)  then 'Call 3'
		when (MAX_STAGE='Call 4' and AR_CALL4=0) then 'Call 4'
		when AR_CALL4=1 and C4_decision='Accept' then 'Одобрено' 
		else ''
		end as rejectStage,
case when  max_stage = 'Call 4' and C4_decision = 'Accept'  then 'Accept'
	when decision_code is not null and decision_code <> '' then 'Decline'
	when decision_code = '' and max_stage <> 'Call 4' then 'Not_finished'
	else 'WTF'
	end as Decision,
fpd0, fpd4, fpd7, fpd30,  _30_4_CMR,  _90_6_CMR,  _90_12_CMR,
case when fpd0 is not null then 1 else 0 end as fpd0_base,
case when fpd4 is not null then 1 else 0 end as fpd4_base,
case when fpd7 is not null then 1 else 0 end as fpd7_base,
case when fpd30 is not null then 1 else 0 end as fpd30_base,
case when _30_4_CMR is not null then 1 else 0 end as _30_4_CMR_base,
case when _90_6_CMR is not null then 1 else 0 end as _90_6_CMR_base,
case when _90_12_CMR is not null then 1 else 0 end as _90_12_CMR_base,
case when fpd0 = 1 then limit else 0 end as fpd0_limit,
case when fpd4 = 1 then limit else 0 end as fpd4_limit,
case when fpd7 = 1 then limit else 0 end as fpd7_limit,
case when fpd30 = 1 then limit else 0 end as fpd30_limit,
case when _30_4_CMR = 1 then limit else 0 end as _30_4_limit,
case when _90_6_CMR = 1 then limit else 0 end as _90_6_limit,
case when _90_12_CMR = 1 then limit else 0 end as _90_12_limit,
case when fpd0 is not null then LIMIT else 0 end as fpd0_limit_base,
case when fpd4 is not null then LIMIT else 0 end as fpd4_limit_base,
case when fpd7 is not null then LIMIT else 0 end as fpd7_limit_base,
case when fpd30 is not null then LIMIT else 0 end as fpd30_limit_base,
case when _30_4_CMR is not null then LIMIT else 0 end as _30_4_CMR_limit_base,
case when _90_6_CMR is not null then LIMIT else 0 end as _90_6_CMR_limit_base,
case when _90_12_CMR is not null then LIMIT else 0 end as _90_12_CMR_limit_base,
case when CLIENT_TYPE = '1.NEW' and RBP_GR = 'RBP 1' then 'New RBP 1'
	when CLIENT_TYPE = '1.NEW' and RBP_GR  in ('RBP 2', 'RBP 3', 'RBP 4') then 'New Main'
	when CLIENT_TYPE = '1.NEW' and RBP_GR = 'RBP_PROBATION' then 'Probation'
	when CLIENT_TYPE = '3.REPEATED' and RBP_GR  in ('RBP 1', 'RBP 2', 'RBP 3', 'RBP 4') then 'Repeated'
	when CLIENT_TYPE = '2.ACTIVE' and RBP_GR  in ('RBP 1', 'RBP 2', 'RBP 3', 'RBP 4') then 'Active'
	else 'N/A' end as SalesPlanSegment,
AR_CALL1_base = 1,
case when C15_decision in ('Accept', 'Decline') then 1 else 0 end as AR_CALL15_base,
case when C2_decision in ('Accept', 'Decline') then 1 else 0 end as AR_CALL2_base,
case when C3_decision in ('Accept', 'Decline') then 1 else 0 end as AR_CALL3_base,
case when C4_decision in ('Accept', 'Decline') then 1 else 0 end as AR_CALL4_base
, case when convert (float, APR, 103) is not null then convert (float, APR, 103) * LIMIT  else 0 end as APR_amount,
category category_povt_inst,
case when (isnull(cnt_closed_inst, 0) + isnull(cnt_closed_pdl, 0)) > 0 and cnt_closed_pts = 0 and client_type = '3.REPEATED' and (category <> 'Красный' or category is null)
		then 1 else 0 end as fl_switch_to_pts,
gr_category, total_category, gr_sole_category
from #tisk2
left join (select [Номер], [Дубль], gr_channel
			from #double) s
on s.[Номер] = #tisk2.number
left join (select number, result_1_3,
			case when result_1_3 = '100.0103.001' then 1 else 0 end as fl_rus_auto
			from [Stg].[_loginom].[callcheckverif_log] with (nolock) where stage = 'Call 1.5') d
on #tisk2.number = d.number
left join (select number, no_probation, k_disk from [stg].[_loginom].[Originationlog] with (nolock) where stage = 'Call 2') p
on p.number = #tisk2.number
left join (select number, fpd0, fpd4, fpd7, fpd30,  _30_4_CMR,  _90_6_CMR,  _90_12_CMR from [dwh2].[dbo].[dm_OverdueIndicators] with (nolock)) a
on a.number = #tisk2.number
left join (select * from #rep_type_pts) y
on  y.number = #tisk2.number
left join (select * from #rep_type_pdl) u
on  u.number = #tisk2.number
left join (select * from #rep_type_inst) e
on  e.number = #tisk2.number
left join (select number, category from #category_povt) c
on c.number = #tisk2.number
left join #povt2
on #povt2.number = #tisk2.number
)
select a.*,
case when Decision = 'Not_finished' then 0 else 1 end as finished,
case when FIN_STATUS = '3.4. ANNUL F C3' then 0 else AR_CALL3_base end as AR_UW_base,
case when fl_rus_auto != 1 and year_TS in (2000, 2001, 2002, 2003) and c1_date >= '20241113 12:38' then 1 else 0 end as fl_year_car
, [CHANNEL]
into #pivot
from a
left join (select number, CHANNEL
			from [stg].[_loginom].[application] where stage = 'Call 1') s
on s.number = a.number

SET DATEFIRST 1	;
drop table if exists #pivot1;
select * 
,isRussianAuto = cast(null as int)
,Region = cast(null as varchar(100))
,fl_check= cast(null as varchar(100))
,Income_amount = cast(null as float)
,Request_amount = cast(null as float)
,APPROVED_AMOUNT = cast(null as float)
,DATEPART(hour, C1_date) as call_date_h
,concat( format( DATEADD(d, 1 - DATEPART(w, C1_date), C1_date), 'dd.MM' ), ' - ' ,-- Начало недели (понедельник)
FORMAT(DATEADD(day,6,DATEADD(d, 1 - DATEPART(w, C1_date), C1_date)), 'dd.MM')) AS [week]
,datepart(ww, C1_date) as week_of_year
,case when AR_CALL4=1 and decision='Accept' then 'Одобрено' else MAX_STAGE end as MAX_STAGE_bi
,case
		when AR_CALL4=1 and decision='Accept' then 'Одобрено' 
		when Decision_code = '100.0223.002' then 'Банкротство'
when Decision_code = '100.0208.008' then 'Верификация клиента'
when Decision_code = '100.0208.006' then 'Верификация клиента'
when Decision_code = '100.0208.005' then 'Верификация клиента'
when Decision_code = '100.0208.003' then 'Верификация клиента'
when Decision_code = '100.0208.009' then 'Верификация клиента'
when Decision_code = '100.0208.002' then 'Верификация клиента'
when Decision_code = '100.0211.004' then 'Верификация клиента'
when Decision_code = '100.0208.011' then 'Верификация клиента'
when Decision_code = '100.0208.010' then 'Верификация клиента'
when Decision_code = '100.0208.004' then 'Верификация клиента'
when Decision_code = '100.0208.012' then 'Верификация клиента'
when Decision_code = '100.0201.008' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0110.007' then 'Внутренняя кредитная история'
when Decision_code = '100.0110.009' then 'Внутренняя кредитная история'
when Decision_code = '100.0110.006' then 'Внутренняя кредитная история'
when Decision_code = '100.0120.008' then 'Внутренняя кредитная история'
when Decision_code = '100.0120.006' then 'Внутренняя кредитная история'
when Decision_code = '100.0110.008' then 'Внутренняя кредитная история'
when Decision_code = '100.0224.002' then 'Внутренняя кредитная история'
when Decision_code = '100.0110.010' then 'Внутренняя кредитная история'
when Decision_code = '100.0112.004' then 'История обращений заявителя'
when Decision_code = '100.0203.006' then 'История обращений заявителя'
when Decision_code = '100.0203.001' then 'История обращений заявителя'
when Decision_code = '100.0112.003' then 'История обращений заявителя'
when Decision_code = '100.0121.002' then 'Проверка паспорта'
when Decision_code = '100.0122.002' then 'Проверка паспорта'
when Decision_code = '100.0122.003' then 'Проверка паспорта'
when Decision_code = '100.0100.001' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0100.003' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0106.002' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0110.005' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0100.005' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0100.002' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0100.041' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0160.000' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0103.013' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0103.012' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0100.113' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0016.003' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0103.006' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0090.002' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0214.006' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0103.007' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0214.001' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0205.002' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0103.008' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0103.004' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0214.004' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0490.002' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0103.009' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0235.004' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0103.011' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0123.007' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0060.015' then 'Негативная информациия (БКИ)'
when Decision_code = '100.0060.018' then 'Негативная информациия (БКИ)'
when Decision_code = '100.0060.107' then 'Негативная информациия (БКИ)'
when Decision_code = '200.0060.015' then 'Негативная информациия (БКИ)'
when Decision_code = '200.0060.018' then 'Негативная информациия (БКИ)'
when Decision_code = '200.0060.107' then 'Негативная информациия (БКИ)'
when Decision_code = '100.0060.118' then 'Негативная информациия (БКИ)'
when Decision_code = '200.0060.118' then 'Негативная информациия (БКИ)'
when Decision_code = '100.0406.007' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0406.008' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0406.002' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0406.010' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0480.001' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0090.003' then 'Негативная информациия (ГИБДД)'
when Decision_code = '100.0080.006' then 'Негативная информациия (ФССП)'
when Decision_code = '100.0080.007' then 'Негативная информациия (ФССП)'
when Decision_code = '100.0080.005' then 'Негативная информациия (ФССП)'
when Decision_code = '100.0080.008' then 'Негативная информациия (ФССП)'
when Decision_code = '100.0120.001' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.002' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.004' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0070.002' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.072' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.071' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.091' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0120.092' then 'Негативная информация (внутренние источники)'
when Decision_code = '100.0070.207' then 'Банкротство'
when Decision_code = '100.0082.001' then 'Негативная информация (Федеральный розыск)'
when Decision_code = '100.0070.007' then 'Банкротство'
when Decision_code = '100.0124.002' then 'Негативы (фото)'
when Decision_code = '100.0213.009' then 'Негативы (фото)'
when Decision_code = '100.0213.013' then 'Негативы (фото)'
when Decision_code = '100.0213.006' then 'Негативы (фото)'
when Decision_code = '100.0213.004' then 'Негативы (фото)'
when Decision_code = '100.0213.012' then 'Негативы (фото)'
when Decision_code = '100.0213.007' then 'Негативы (фото)'
when Decision_code = '100.0213.011' then 'Негативы (фото)'
when Decision_code = '100.0124.003' then 'Негативы (фото)'
when Decision_code = '100.0213.014' then 'Негативы (фото)'
when Decision_code = '100.0213.016' then 'Негативы (фото)'
when Decision_code = '100.0124.004' then 'Негативы (фото)'
when Decision_code = '100.0213.017' then 'Негативы (фото)'
when Decision_code = '100.0213.015' then 'Негативы (фото)'
when Decision_code = '100.0213.018' then 'Негативы (фото)'
when Decision_code = '100.0130.021' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0130.001' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0130.003' then 'Минимальные требования (заявитель)'
when Decision_code = '100.0206.002' then 'Проверка ГИБДД'
when Decision_code = '100.0206.005' then 'Проверка ГИБДД'
when Decision_code = '100.0206.004' then 'Проверка ГИБДД'
when Decision_code = '100.0206.007' then 'Проверка ГИБДД'
when Decision_code = '100.0206.010' then 'Проверка ГИБДД'
when Decision_code = '100.0206.008' then 'Проверка ГИБДД'
when Decision_code = '100.0115.002' then 'Проверка паспорта'
when Decision_code = '100.0114.002' then 'Проверка паспорта'
when Decision_code = '100.0114.004' then 'Проверка паспорта'
when Decision_code = '100.0114.003' then 'Проверка паспорта'
when Decision_code = '100.0115.003' then 'Проверка паспорта'
when Decision_code = '100.0116.002' then 'Проверка паспорта'
when Decision_code = '100.0115.004' then 'Проверка паспорта'
when Decision_code = '100.0117.005' then 'Проверка ПТС'
when Decision_code = '100.0117.004' then 'Проверка ПТС'
when Decision_code = '100.0117.003' then 'Проверка ПТС'
when Decision_code = '100.0117.006' then 'Проверка ПТС'
when Decision_code = '100.0212.001' then 'Проверка работодателя'
when Decision_code = '100.0233.011' then 'Проверка работодателя'
when Decision_code = '100.0231.008' then 'Проверка работодателя'
when Decision_code = '100.0232.011' then 'Проверка работодателя'
when Decision_code = '100.0230.010' then 'Проверка работодателя'
when Decision_code = '100.0230.009' then 'Проверка работодателя'
when Decision_code = '100.0232.010' then 'Проверка работодателя'
when Decision_code = '100.0233.010' then 'Проверка работодателя'
when Decision_code = '100.0118.003' then 'Проверка ПТС'
when Decision_code = '100.0118.002' then 'Проверка ПТС'
when Decision_code = '100.0301.006' then 'Проверка фото авто'
when Decision_code = '100.0301.002' then 'Проверка фото авто'
when Decision_code = '100.0301.005' then 'Проверка фото авто'
when Decision_code = '100.0301.003' then 'Проверка фото авто'
when Decision_code = '100.0301.004' then 'Проверка фото авто'
when Decision_code = '100.0302.005' then 'Проверка фото клиента'
when Decision_code = '100.0302.010' then 'Проверка фото клиента'
when Decision_code = '100.0302.008' then 'Проверка фото клиента'
when Decision_code = '100.0302.006' then 'Проверка фото клиента'
when Decision_code = '100.0110.902' then 'Продукт ИСПЫТАТЕЛЬНЫЙ СРОК '
when Decision_code = '100.0110.903' then 'Продукт ИСПЫТАТЕЛЬНЫЙ СРОК '
when Decision_code = '100.0216.006' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0216.007' then 'Минимальные требования (предмет залога)'
when Decision_code = '100.0120.905' then 'Негативы (фото)'
when Decision_code = '100.0120.906' then 'Негативы (фото)'
when Decision_code = '100.0120.903' then 'Негативы (фото)'
when Decision_code = '100.0120.907' then 'Негативы (фото)'
when Decision_code = '100.0119.003' then 'Негативы (фото)'
when Decision_code = '100.0119.004' then 'Негативы (фото)'
when Decision_code = '100.0119.005' then 'Негативы (фото)'
when Decision_code = '100.0218.002' then 'ФССП'
when Decision_code = '100.0218.001' then 'ФССП'
		else 'Другое'
	end as Decision_description
,case
	when AR_CALL4=1 and decision='Accept' then 'Одобрено' 
when decision_code = '100.0100.041' then 'Регион проживания не удовлетворяет требованиям'
when decision_code = '100.0100.001' then 'Регион регистрации не удовлетворяет требованиям'
when decision_code = '100.0100.002' then 'Возраст не удовлетворяет требованиям'
when decision_code = '100.0100.005' then 'Срок действия паспорта истек'
when decision_code = '100.0100.113' then 'Паспорт недействителен'
when decision_code = '100.0100.003' then 'Паспорт недействителен'
when decision_code = '100.0110.005' then 'Красная зона без CRM-предложений'
when decision_code = '100.0110.006' then 'Историческая просрочка в компании >180 дней'
when decision_code = '100.0110.007' then 'Активные клиенты без докреда'
when decision_code = '100.0110.009' then 'Активные клиенты с красным предложением докреда'
when decision_code = '100.0110.008' then 'Информация о наличии обращений КарМани в суд по клиенту'
when decision_code = '100.0110.010' then 'Предыдущий займ открыт < 35 дней (для докредов)'
when decision_code = '100.0120.006' then 'Активный клиент с недавно открытым договором с просрочкой и небольшая возможная сумма займа'
when decision_code = '100.0120.008' then 'Активный договор беззалога'
when decision_code = '100.0160.000' then 'Сегмент Испытательный срок и б/у Авто'
when decision_code = '100.0090.002' then 'Авто под обременением (реестр залогов)'
when decision_code = '100.0490.002' then 'Авто под обременением (реестр залогов)'
when decision_code = '100.0070.002' then 'Черный список ФЛ (внутренний и Финмониторинг)'
when decision_code = '100.0120.001' then 'Повторное обращение после жесткого отказа по клиенту (cooling 30 дней)'
when decision_code = '100.0120.002' then 'Повторное обращение после жесткого отказа по машине (cooling 30 дней)'
when decision_code = '100.0120.004' then 'Более 3х заявок в день'
when decision_code = '100.0120.071' then 'Отказ по повторному обращению в течение 7 дней после отказа по клиенту (cooling 7 дней)'
when decision_code = '100.0120.072' then 'Отказ по повторному обращению в течение 7 дней после отказа по машине (cooling 7 дней)'
when decision_code = '100.0120.091' then 'Отказ по повторному обращению в течение 90 дней после жесткого отказа по клиенту (cooling 90 дней)'
when decision_code = '100.0120.092' then 'Повторное обращение после жесткого отказа по машине (cooling 90 дней)'
when decision_code = '100.0070.007' then 'Банкротство'
when decision_code = '100.0070.207' then 'Банкротство'
when decision_code = '100.0082.001' then 'Заявитель в Федеральном розыске'
when decision_code = '100.0080.005' then 'Конфискация по УКРФ, а также иные типы Конфискаций'
when decision_code = '100.0080.006' then 'Сумма ИП по обязательствам кредитного характера >50 000 руб'
when decision_code = '100.0080.007' then 'Общая задолженность по исполнительным производствам превышает 300 000 рублей'
when decision_code = '100.0080.008' then 'По ФССП есть задолженность «Обращение взыскания на заложенное имущество"'
when decision_code = '100.0090.003' then 'Авто в розыске'
when decision_code = '100.0406.002' then 'Ограничение на автомобиль по данным ГИБДД и задолженность/исполнительное производство по данным ФССП'
when decision_code = '100.0406.008' then 'Авто постановлено на учет в день обращения или позднее (сравнение даты постановки на учет из заявки с датой заявки)'
when decision_code = '100.0406.007' then 'Негативные факторы (дубликат ПТС и частая смена собственников и недавняя регистрация)'
when decision_code = '100.0406.010' then 'ТС снято с учета'
when decision_code = '100.0480.001' then 'Ограничение на автомобиль по данным ГИБДД и по данным ФССП есть ИП, закрытое по ст. 46 в последние 6 мес'
when decision_code = '100.0060.015' then 'Просрочка >=30 дней и [сумма просрочки > 50 000 или (Кол-во счето в прорсочке >=4 и доля счетов в просрочке >=50%)] (ЭКС и НБКИ)'
when decision_code = '200.0060.015' then 'Просрочка >=30 дней и [сумма просрочки > 50 000 или (Кол-во счето в прорсочке >=4 и доля счетов в просрочке >=50%)] (ЭКС)'
when decision_code = '100.0060.018' then 'Доля просроченных займов и микрокредит или сумма просрочки (ЭКС и НБКИ)'
when decision_code = '100.0060.118' then 'Доля просроченных займов и микрокредит или сумма просрочки (ЭКС и НБКИ)'
when decision_code = '200.0060.018' then 'Доля просроченных займов и микрокредит или сумма просрочки (ЭКС)'
when decision_code = '200.0060.118' then 'Доля просроченных займов и микрокредит или сумма просрочки (ЭКС)'
when decision_code = '100.0060.107' then 'Банкротство'
when decision_code = '200.0060.107' then 'Банкротство'
when decision_code = '100.0130.001' then 'Максимально возможная сумма кредита <50 000 руб.'
when decision_code = '100.0130.003' then 'Максимально возможная сумма кредита <50 000 руб.'
when decision_code = '100.0130.021' then 'Нет ни одного предложения без комиссионных продуктов'
when decision_code = '100.0130.041' then 'Нет ни одного предложения без комиссионных продуктов'
when decision_code = '100.9999.999' then 'Отказ по списку заявок'
when decision_code = '100.0709.002' then 'Адрес фактического места жительства не соответствует минимальным требованиям'
when decision_code = '100.0106.002' then 'Регион фактического проживания вне списка допустимых регионов'
when decision_code = '100.0711.002' then 'Подозрение на подделку паспорта/ генератор документов'
when decision_code = '100.0711.003' then 'Признак применения фотошопа'
when decision_code = '100.0711.004' then 'Негатив в метаданных'
when decision_code = '100.0711.005' then 'Расхождение в данных паспорта'
when decision_code = '100.0711.006' then 'Фото с экрана/скриншот'
when decision_code = '100.0711.007' then 'Черно-белое фото'
when decision_code = '100.0711.008' then 'Другой негатив'
when decision_code = '100.0223.002' then 'Заявитель банкрот'
when decision_code = '100.0817.002' then 'Заявитель банкрот'
when decision_code = '100.0201.008' then 'Долг Автокредит БОЛЕЕ 15%'
when decision_code = '100.0202.003' then 'Имеются просрочки свыше 180 дней'
when decision_code = '100.0202.005' then 'Текущая просрочка более 5 дней'
when decision_code = '100.0224.002' then 'Не подходит под условия докредитования/параллельный займ'
when decision_code = '100.0211.004' then 'Негатив от КЛ (должник, алкоголик, наркоман)'
when decision_code = '100.0813.004' then 'КЛ не знает клиента/номер не существует, клиент подтвердил номер'
when decision_code = '100.0813.005' then 'Негатив от КЛ (должник, алкоголик, наркоман)'
when decision_code = '100.0813.006' then 'КЛ не знает клиента/номер не существует, не удалось подтвердить номер'
when decision_code = '100.0208.002' then 'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве'
when decision_code = '100.0208.003' then 'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику), заявку перезаводим'
when decision_code = '100.0208.004' then 'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)'
when decision_code = '100.0208.005' then 'Отказ клиента, клиент не оформлял займ'
when decision_code = '100.0208.008' then 'Клиент дает противоречивую инф-ю'
when decision_code = '100.0208.009' then 'Клиент "Олень" (приведен 3-ми лицами)'
when decision_code = '100.0208.010' then 'Клиент подтвердил, что обратился за кредитом под влиянием 3х лиц'
when decision_code = '100.0208.011' then 'Клиент пьян'
when decision_code = '100.0208.012' then 'Отвечает 3 лицо - представляется клиентом'
when decision_code = '100.0814.004' then 'Отказ клиента'
when decision_code = '100.0814.005' then 'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику)'
when decision_code = '100.0814.006' then 'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)'
when decision_code = '100.0814.007' then 'Отказ клиента, клиент не оформлял займ'
when decision_code = '100.0814.008' then 'Кредит для 3-х лиц'
when decision_code = '100.0814.009' then 'Клиент дает противоречивую инф-ю'
when decision_code = '100.0814.010' then 'Клиент "Олень" (приведен 3-ми лицами)'
when decision_code = '100.0814.011' then 'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве'
when decision_code = '100.0814.013' then 'Клиент пьян'
when decision_code = '100.0814.014' then 'Отвечает 3-е лицо'
when decision_code = '100.0814.015' then 'Клиент подтвердил, что обратился за кредитом под влиянием 3х лиц'
when decision_code = '100.0814.016' then 'Телефон клиента не существует'
when decision_code = '100.0812.006' then 'Телефон не актуален'
when decision_code = '100.0812.007' then 'Телефон принадлежит другой компании'
when decision_code = '100.0812.008' then 'Декрет '
when decision_code = '100.0812.009' then 'Негативная информация от работодателя '
when decision_code = '100.0812.010' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0232.010' then 'Негативная информация от работодателя '
when decision_code = '100.0232.011' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0811.008' then 'Декрет '
when decision_code = '100.0811.009' then 'Негативная информация от работодателя '
when decision_code = '100.0811.010' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0230.009' then 'Негативная информация от работодателя '
when decision_code = '100.0230.010' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0809.007' then 'Декрет '
when decision_code = '100.0809.008' then 'Негативная информация от работодателя '
when decision_code = '100.0809.010' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0233.010' then 'Негативная информация от работодателя '
when decision_code = '100.0233.011' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0109.002' then 'Прописка нет /Фактический да (не  соответствует списку регионов расширения ) '
when decision_code = '100.0109.004' then 'Прописка нет/Фактический нет '
when decision_code = '100.0109.005' then 'Прописка да /Фактический нет '
when decision_code = '100.0215.002' then 'Отказать'
when decision_code = '100.0101.002' then 'Подозрение на подделку документов/фотошоп/непрофильные фото'
when decision_code = '100.0101.003' then 'Расхождение данных в документах'
when decision_code = '100.0101.004' then 'Документы недействительны, требуют замены'
when decision_code = '100.0121.002' then 'Совпадение с базой мошенников '
when decision_code = '100.0706.002' then 'Совпадение с базой мошенников '
when decision_code = '100.0122.002' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0122.003' then 'Фото клиента не соответствует фото в паспорте'
when decision_code = '100.0707.002' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0707.003' then 'Фото клиента не соответствует фото в паспорте'
when decision_code = '100.0102.002' then 'ПТС взамен утраченного/утерянного менее 45 дней назад'
when decision_code = '100.0103.004' then 'Коммерческий транспорт (желтые номера)'
when decision_code = '100.0103.006' then 'Отечественные авто (категория B), возраст более 13 лет'
when decision_code = '100.0103.007' then 'Иностранные авто (категория B), возраст более 20 лет'
when decision_code = '100.0103.008' then 'Газель, Соболь (грузовая) категории В, возраст  более 11 лет'
when decision_code = '100.0103.009' then 'ТС категории А, прицеп'
when decision_code = '100.0103.011' then 'Самоходная машина, возраст более 25 лет'
when decision_code = '100.0103.012' then 'Возраст клиента не соответствует требованиям'
when decision_code = '100.0103.013' then 'У заявителя нет ТС в собственности'
when decision_code = '100.0712.002' then 'Возраст клиента не соответствует требованиям'
when decision_code = '100.0712.003' then 'Адрес регистрации вне зоны присутствия бизнеса'
when decision_code = '100.0123.007' then 'Условия рефинансируемого договора не соответствуют требованиям по продукту'
when decision_code = '100.0214.001' then 'Авто с серьезными повреждениями / не на ходу'
when decision_code = '100.0214.004' then 'Авто с низкой ликвидностью'
when decision_code = '100.0214.006' then 'Авто не проходит на минимальную сумму кредита'
when decision_code = '100.0124.002' then 'Много документов не с оригинала'
when decision_code = '100.0124.003' then 'Партнерская заявка - типаж БОМЖ, ЦЫГАНЕ, НАРКОМАН'
when decision_code = '100.0124.004' then 'Фото документов скачены из интернета'
when decision_code = '100.0213.004' then 'Другое'
when decision_code = '100.0213.006' then 'Инвалидность (нерабочая группа)'
when decision_code = '100.0213.007' then 'Ранее был отказ в течение 7 дней'
when decision_code = '100.0213.009' then 'Подозрение в мошенничестве: геолокация'
when decision_code = '100.0213.011' then 'Негатив по соц. сетям (алкоголик, наркоман и прочее)'
when decision_code = '100.0213.012' then 'Негатив по соц сетям - подписан на запрещенные сообщества'
when decision_code = '100.0213.013' then 'Типаж БОМЖ, ЦЫГАНЕ, НАРКОМАН'
when decision_code = '100.0213.014' then 'Занятость не удовлетворяет требованиям'
when decision_code = '100.0213.015' then 'Сегодня оформлен займ, VIN совпадает'
when decision_code = '100.0213.016' then 'Вне зоны действия бизнеса проживает/ работает'
when decision_code = '100.0213.017' then 'Клиент выдает себя за 3е лицо'
when decision_code = '100.0213.018' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0815.002' then 'Инвалидность (нерабочая группа)'
when decision_code = '100.0815.003' then 'Негатив по соц. сетям (алкоголик, наркоман и прочее)'
when decision_code = '100.0815.004' then 'Негатив по соц сетям - подписан на запрещенные сообщества'
when decision_code = '100.0815.005' then 'Есть активный кредитный договор'
when decision_code = '100.0815.007' then 'Есть активная одобренная заявка'
when decision_code = '100.0815.008' then 'Типаж БОМЖ, ЦЫГАНЕ'
when decision_code = '100.0815.009' then 'Подозрение в мошенничестве: геолокация'
when decision_code = '100.0815.010' then 'Занятость не удовлетворяет требованиям'
when decision_code = '100.0815.011' then 'Вне зоны действия бизнеса проживает/ работает'
when decision_code = '100.0815.012' then 'Клиент выдает себя за 3е лицо'
when decision_code = '100.0815.013' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0114.002' then 'Документы недействительны, требуют замены'
when decision_code = '100.0114.003' then 'Паспорт иностранного государства'
when decision_code = '100.0114.004' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0702.002' then 'Документы недействительны, требуют замены'
when decision_code = '100.0702.003' then 'Расхождение данных в документах'
when decision_code = '100.0702.004' then 'Фото не с оригинала документа '
when decision_code = '100.0702.005' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0702.006' then 'Паспорт иностранного государства'
when decision_code = '100.0115.002' then 'Адрес регистрации не соответствует минимальным требованиям/отсутствует'
when decision_code = '100.0115.003' then 'Документы недействительны, требуют замены'
when decision_code = '100.0115.004' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0703.002' then 'Адрес регистрации не соответствует минимальным требованиям/отсутствует'
when decision_code = '100.0703.003' then 'Документы недействительны, требуют замены'
when decision_code = '100.0703.004' then 'Расхождение данных в документах'
when decision_code = '100.0703.005' then 'Фото не с оригинала документа '
when decision_code = '100.0703.006' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0116.002' then 'Документы недействительны, требуют замены'
when decision_code = '100.0116.003' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0210.004' then 'Рабочий телефон кукушка'
when decision_code = '100.0210.005' then 'Негативная информация от работодателя '
when decision_code = '100.0210.006' then 'Занятость опровергли /не работает / уволили'
when decision_code = '100.0206.002' then 'Ограничения ТС по клиенту=собственнику из списка'
when decision_code = '100.0206.004' then 'Ограничения на ТС по прошлому собственнику из списка'
when decision_code = '100.0206.005' then 'ЗАЛОГ был в тотале восстановлен'
when decision_code = '100.0206.006' then 'ТС в угоне/розыске'
when decision_code = '100.0206.007' then 'Совокупность условных негативов'
when decision_code = '100.0206.008' then 'Постановка авто день в день'
when decision_code = '100.0206.010' then 'ТС снято с учета'
when decision_code = '100.0205.002' then 'Авто в залоге '
when decision_code = '100.0708.003' then 'Фамилия и/или имя на карте (в заявке) не соответствуют данным паспорта'
when decision_code = '100.0231.008' then 'Негативная информация - компания не работает/фиктивная компания'
when decision_code = '100.0810.007' then 'Негативная информация - компания не работает/фиктивная компания'
when decision_code = '100.0212.001' then 'Негативная информация, компания ликвидирована, банкрот'
when decision_code = '100.0808.005' then 'Негативная информация, компания ликвидирована, банкрот'
when decision_code = '100.0203.001' then 'Подозрение в мошенничестве '
when decision_code = '100.0203.006' then 'Текущая просрочка в Кармани у родственника'
when decision_code = '100.0802.003' then 'Подозрение в мошенничестве '
when decision_code = '100.0802.004' then 'Текущая просрочка в Кармани у родственника'
when decision_code = '100.0204.002' then 'Анкета найдена, есть негатив из списка'
when decision_code = '100.0112.003' then 'Подозрение в мошенничестве: другой человек в предыдущих заявках'
when decision_code = '100.0112.004' then 'Ранее был отказ в течении 7 дней'
when decision_code = '100.0701.003' then 'У клиента есть активная одобренная заявка'
when decision_code = '100.0701.004' then 'У клиента есть активный кредитный договор'
when decision_code = '100.0235.004' then 'ТС было в тотале восстановлено'
when decision_code = '100.0301.002' then 'Автомобиль с серьезными повреждениями кузова/Ошибки на приборке/Тс не на ходу'
when decision_code = '100.0301.003' then 'Признаки исправления подручными средствами VIN кода /маркировочных таблиц'
when decision_code = '100.0301.004' then 'ТС с низкой ликвидностью '
when decision_code = '100.0301.005' then 'Прочий негатив'
when decision_code = '100.0301.006' then 'Фотошоп фото автомобиля'
when decision_code = '100.0302.005' then 'Инвалидность (нерабочая группа)'
when decision_code = '100.0302.006' then 'Клиент "Олень" (приведен 3-ми лицами)'
when decision_code = '100.0302.007' then 'Визуальный андеррайтинг клиента.  Клиент не подходит по статусу ТС (дорогое авто и неопрятный человек, алкоголик итд)'
when decision_code = '100.0302.008' then 'Фотошоп фото клиента'
when decision_code = '100.0302.009' then 'Фото в паспорте не соответствует фото клиента/фото клиента на фоне авто'
when decision_code = '100.0302.010' then 'Типаж БОМЖ, ЦЫГАНЕ, НАРКОМАН'
when decision_code = '100.0302.011' then 'КОБАЛЬТ - совпадение с базой мошенников'
when decision_code = '100.0221.002' then 'Регион проживания клиента отсутствует в списке допустимых'
when decision_code = '100.0221.003' then 'Регион авто не соответствует региону прописки клиента'
when decision_code = '100.0110.902' then 'Регион проживания клиента отсутствует в списке допустимых'
when decision_code = '100.0110.903' then 'Регион авто не соответствует региону прописки клиента'
when decision_code = '100.0117.003' then 'ПТС взамен утраченного/утерянного менее 45 дней назад'
when decision_code = '100.0117.004' then 'Некорректный VIN, номер кузова в ПТС или отсутствует'
when decision_code = '100.0117.005' then 'Клиент не является собственником авто'
when decision_code = '100.0117.006' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0216.006' then 'Лимит по оценке верификатора ниже текущей задолженности в справке'
when decision_code = '100.0216.007' then 'Клиент не удовлетворяет требованиям по рефинансированию'
when decision_code = '100.0118.002' then 'Некорректный VIN, номер кузова в ПТС или отсутствует (для ЭПТС)'
when decision_code = '100.0118.003' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0710.002' then 'Подозрение на подделку/фотошоп'
when decision_code = '100.0120.903' then 'Фото клиента не соответствует фото клиента с паспортом (другой человек на фото с паспортом)'
when decision_code = '100.0120.904' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0120.905' then 'Типаж БОМЖ, ЦЫГАНЕ, НАРКОМАН'
when decision_code = '100.0120.906' then 'Непрофильное фото'
when decision_code = '100.0120.907' then 'Фото сделано с экрана/взято из соц.сетей'
when decision_code = '100.0705.002' then 'Фото клиента не соответствует фото клиента с паспортом (другой человек на фото с паспортом)'
when decision_code = '100.0705.003' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0705.004' then 'Типаж БОМЖ, ЦЫГАНЕ'
when decision_code = '100.0705.005' then 'Непрофильное фото'
when decision_code = '100.0705.006' then 'Фото с экрана/фотокопии'
when decision_code = '100.0119.003' then 'Фото клиента не соответствует фото в паспорте'
when decision_code = '100.0119.004' then 'Фото не с оригинала документа '
when decision_code = '100.0119.005' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0704.002' then 'Фото клиента не соответствует фото в паспорте'
when decision_code = '100.0704.003' then 'Фото не с оригинала документа '
when decision_code = '100.0704.004' then 'Подозрение на подделку документов/фотошоп'
when decision_code = '100.0218.001' then 'Кредитные платежи более 50 000'
when decision_code = '100.0218.002' then 'Любая задолженность  свыше 300 000'
when decision_code = '100.0801.004' then 'Наличие задолженности по обязательствам кредитного характера (любая сумма)'
when decision_code = '100.0801.005' then 'Задолженность по всем обязательствам свыше 50 000 руб.'
when decision_code = '100.0801.006' then 'Обращение взыскания (арест) на имущество Заявителя/наличие уголовной статьи'
when decision_code = '100.0801.007' then 'Наличие ИП, закрытых по ст. 46.1.3, 46.1.4, в течение последнего года'
when decision_code = '100.0208.006' then 'Кредит для 3-х лиц'
when decision_code = '100.0016.003' then 'Паспорт не соответсвует маске (Дбрейн)'
when decision_code = '100.0120.101' then 'Активный кредитный продукт'
 end as Decision_description_detal
,max(C1_date) over () as date_upd
,reasonDescription as reasonDescription_new
,category as category_new
,checkType as checkType_new
into #pivot1
from #pivot t
left join stg.[_loginom].Origination_dict_reason_codes a with(nolock)
on t.decision_code=a.reasonCode

update t 
set 
	fl_check= case
			when a.uw_segment = 100 then 'Упрощенная верификация'
			else 'Полная верификация' end 
from #pivot1 t
join stg._loginom.originationlog as a with(nolock)
on t.number=a.number and a.stage ='Call 2'
--where a.Call_date >='20231201' and a.Call_date <'20240515'

update t set
t.Income_amount=a.Income_amount
from #pivot1 t
join  [Stg].[_loginom].[Originationlog] a with(nolock)
on t.number = a.number
where a.Income_amount is not null

update t set
Request_amount=a.request_amount
from #pivot1 t
join  [Stg].[_loginom].[Originationlog] a with(nolock)
on t.number = a.number
where a.Request_amount is not null

update t set
t.APPROVED_AMOUNT =a.APPROVED_AMOUNT
from #pivot1 t
join Stg._loginom.calculated_term_and_amount a with(nolock)
on t.number = a.number
where a.APPROVED_AMOUNT is not null

update t set
t.Region=a.Region
from #pivot1 t
join  [Stg].[_loginom].[Originationlog] a with(nolock)
on t.number = a.number
where a.Region is not null


update t set
t.isRussianAuto=case when Result_1_3 = '100.0103.001' then 1
					when  Result_1_3 = '100.0103.010' then 0
					end
from #pivot1 t
join  [stg].[_loginom].[callcheckverif_log] a with(nolock)
on t.number = a.number
where a.Result_1_3 is not null

--drop table [Reports].risk.v_portfolio_pts
--ALTER TABLE [Reports].risk.v_portfolio_pts ADD Decision_description_detal varchar(max);
begin tran
truncate table [Reports].risk.v_portfolio_pts;
--select * into [Reports].risk.v_portfolio_pts from  #pivot1
--select * from  #pivot1
insert into [Reports].risk.v_portfolio_pts
(

 [Number]	
, [C1_date]	
, [DAY]	
, [MON]
, [STAGE_DATE_AGG]	
, [pts_type]	
, [leadsource]	
, [fl_transfer]	
, [cnt_transfer]	
, [Passport_series]	
, [Passport_number]	
, [EqxScore]	
, [period_date]	
, [strategy_version_last]	
, [CLIENT_TYPE]	
, [STRAT_TYPE]	
, [MAX_STAGE]	
, [DECISION_CODE]	
, [probation]	
, [C1_decision]	
, [C15_decision]	
, [C2_decision]	
, [C3_decision]	
, [C4_decision]	
, [REFIN_FL_]	
, [C1_APR]	
, [C1_offername]	
, [c1_apr_segment]	
, [C2_APR]	
, [c2_apr_segment]	
, [year_ts]
, [AR_CALL1]	
, [AR_CALL15]	
, [AR_CALL2]	
, [AR_CALL3]	
, [AR_CALL4]	
, [ДоговорНомер]
, [amount_agr]	
, [ISSUED_FL]	
, [APR]	
, [RBP_GR]	
, [LIMIT]	
, [FIN_STATUS]	
, [Дубль]	
, [no_probation]	
, [k_disk]	
, [fl_rus_auto]	
, [all_fl]	
, [date]	
, [rejectStage]	
, [Decision]	
, [fpd0]	
, [fpd4]	
, [fpd7]	
, [fpd30]	
, [_30_4_CMR]	
, [_90_6_CMR]	
, [_90_12_CMR]	
, [fpd0_base]	
, [fpd4_base]	
, [fpd7_base]	
, [fpd30_base]	
, [_30_4_CMR_base]	
, [_90_6_CMR_base]
, [_90_12_CMR_base]	
, [fpd0_limit]	
, [fpd4_limit]	
, [fpd7_limit]	
, [fpd30_limit]	
, [_30_4_limit]	
, [_90_6_limit]	
, [_90_12_limit]	
, [fpd0_limit_base]	
, [fpd4_limit_base]	
, [fpd7_limit_base]	
, [fpd30_limit_base]	
, [_30_4_CMR_limit_base]	
, [_90_6_CMR_limit_base]	
, [_90_12_CMR_limit_base]	
, [SalesPlanSegment]	
, [AR_CALL1_base]	
, [AR_CALL15_base]	
, [AR_CALL2_base]	
, [AR_CALL3_base]	
, [AR_CALL4_base]	
, [APR_amount]	
, [category_povt_inst]	
, [fl_switch_to_pts]	
, [gr_category]	
, [total_category]	
, [gr_sole_category]	
, [finished]	
, [AR_UW_base]	
, [fl_year_car]	
, [CHANNEL]	
, [fl_check]	
, [Income_amount]	
, [Request_amount]	
, [APPROVED_AMOUNT]	
, [week]	
, [week_of_year]	
, [MAX_STAGE_bi]	
, [Decision_description]	
, [date_upd]
, [call_date_h]
, [Decision_description_detal]
, [Region]
, [isRussianAuto]
, [reasonDescription_new]
, [category_new]
, [checkType_new]
)
select
 [Number]	
, [C1_date]	
, [DAY]	
, [MON]
, [STAGE_DATE_AGG]	
, [pts_type]	
, [leadsource]	
, [fl_transfer]	
, [cnt_transfer]	
, [Passport_series]	
, [Passport_number]	
, [EqxScore]	
, [period_date]	
, [strategy_version_last]	
, [CLIENT_TYPE]	
, [STRAT_TYPE]	
, [MAX_STAGE]	
, [DECISION_CODE]	
, [probation]	
, [C1_decision]	
, [C15_decision]	
, [C2_decision]	
, [C3_decision]	
, [C4_decision]	
, [REFIN_FL_]	
, [C1_APR]	
, [C1_offername]	
, [c1_apr_segment]	
, [C2_APR]	
, [c2_apr_segment]	
, [year_ts]
, [AR_CALL1]	
, [AR_CALL15]	
, [AR_CALL2]	
, [AR_CALL3]	
, [AR_CALL4]	
, [ДоговорНомер]
, [amount_agr]	
, [ISSUED_FL]	
, [APR]	
, [RBP_GR]	
, [LIMIT]	
, [FIN_STATUS]	
, [Дубль]	
, [no_probation]	
, [k_disk]	
, [fl_rus_auto]	
, [all_fl]	
, [date]	
, [rejectStage]	
, [Decision]	
, [fpd0]	
, [fpd4]	
, [fpd7]	
, [fpd30]	
, [_30_4_CMR]	
, [_90_6_CMR]	
, [_90_12_CMR]	
, [fpd0_base]	
, [fpd4_base]	
, [fpd7_base]	
, [fpd30_base]	
, [_30_4_CMR_base]	
, [_90_6_CMR_base]
, [_90_12_CMR_base]	
, [fpd0_limit]	
, [fpd4_limit]	
, [fpd7_limit]	
, [fpd30_limit]	
, [_30_4_limit]	
, [_90_6_limit]	
, [_90_12_limit]	
, [fpd0_limit_base]	
, [fpd4_limit_base]	
, [fpd7_limit_base]	
, [fpd30_limit_base]	
, [_30_4_CMR_limit_base]	
, [_90_6_CMR_limit_base]	
, [_90_12_CMR_limit_base]	
, [SalesPlanSegment]	
, [AR_CALL1_base]	
, [AR_CALL15_base]	
, [AR_CALL2_base]	
, [AR_CALL3_base]	
, [AR_CALL4_base]	
, [APR_amount]	
, [category_povt_inst]	
, [fl_switch_to_pts]	
, [gr_category]	
, [total_category]	
, [gr_sole_category]	
, [finished]	
, [AR_UW_base]	
, [fl_year_car]	
, [CHANNEL]	
, [fl_check]	
, [Income_amount]	
, [Request_amount]	
, [APPROVED_AMOUNT]	
, [week]	
, [week_of_year]	
, [MAX_STAGE_bi]	
, [Decision_description]	
, [date_upd]
, [call_date_h]
, [Decision_description_detal]
, [Region]
, [isRussianAuto]
, [reasonDescription_new]
, [category_new]
, [checkType_new]
from #pivot1
drop table [dwh2].risk.v_portfolio_pts
select * into [dwh2].risk.v_portfolio_pts
from [Reports].risk.v_portfolio_pts

commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
