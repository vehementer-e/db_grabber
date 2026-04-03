CREATE procedure [risk].[etl_docredy_buffer_tmp] as
begin
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
--exec risk.etl_docredy_buffer_tmp
BEGIN TRY

---------------------------
-------Докредитование------
-------Текущий залог-------
---------------------------

-----------------------------Получаем список договор по клиентам
drop table if exists #person_id;
select 
person.person_id2,
external_id,
credits.startdate,
factenddate = isnull(cast(credits.factenddate as date), getdate())
into #person_id
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
where credits.startdate <> isnull(cast(credits.factenddate as date), getdate())
;
-----------------------------Получаем список заявок по датам (нужно, чтоб определить потом последний договор по дате)
drop table if exists #apps;
select 
number
,call_date as c1_date
,stage 
,row_number() over (partition by number order by call_date desc) as rn
into #apps
from stg._loginom.originationlog ol
where stage = 'Call 1'
and exists (select external_id from risk.credits where external_id = ol.number)
;
-----------------------------Cовокупный период обслуживания кредитных договоров клиента в компании
drop table if exists #num_active_days;	
declare @dd datetime2 = ('0001-01-01')
select 
person_id2,
num_active_days = sum(t.Разность)
into #num_active_days
from
	(
	select 
	distinct 1 - datediff(dd, @dd, dateadd(dd, 1, Дано.startdate)) as Разность
	,Дано.person_id2
	from #person_id Дано
	left join #person_id Левее
		on  Дано.person_id2 = Левее.person_id2
		and (Левее.startdate < Дано.startdate)
		and Дано.startdate <= Левее.factenddate
	where Левее.startdate is null

	union all

	select 
	distinct datediff(dd, @dd, Дано.factenddate)
	,Дано.person_id2
	from #person_id Дано
	left join #person_id Правее
		on	Дано.person_id2 = Правее.person_id2
		and (Правее.startdate <= Дано.factenddate)
		and Дано.factenddate < Правее.factenddate
	where Правее.factenddate is null
	) t
group by person_id2
;
-----------------------------Факт подачи иска в суд
drop table if exists #client_court_decisions;
with isk_sp_space as 
(
	select 
	distinct Deal.Number as external_id
	,concat_ws (' ', rtrim(ltrim(pd.LastName)), rtrim(ltrim(pd.FirstName)), rtrim(ltrim(pd.MiddleName))	
		,isnull(cast(pd.BirthdayDt as date), '19000101')) as person_id2
	,pd.Series as doc_ser
	,pd.Number as doc_num
	from Stg._Collection.Deals Deal
	left join Stg._Collection.JudicialProceeding jp 
		on Deal.Id = jp.DealId
	left join Stg._Collection.JudicialClaims jc 
		on jp.Id = jc.JudicialProceedingId
	left join stg._collection.customerpersonaldata pd 
		on deal.idcustomer = pd.idcustomer
	inner join stg._Collection.customers c 
		on c.Id = Deal.IdCustomer
	where isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate) is not null
	or isnull(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) is not null
)
select distinct person.person_id2
into #client_court_decisions
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id			
left join isk_sp_space i 
	on person.person_id2 = i.person_id2 --по ФИО+ДР			
left join isk_sp_space ii 
	on person.doc_ser = ii.doc_ser
	and person.doc_num = ii.doc_num --по паспорту			
left join isk_sp_space iii 
	on credits.external_id = iii.external_id --по номеру договора
where i.person_id2 is not null
or ii.doc_ser is not null
or iii.doc_num is not null
;
-----------------------------red_velocity
--(1) не формировать предложение клиентам с 5 и более активными кредитами
--(2) ставить на СТОП на 90 дней клиентов, у которых 2 и более активных кредита
--, средний срок между активными кредитами 30 дней и менее (отсчет 90 дней производить от даты выдачи последнего активного кредита)
drop table if exists #src;
select 
person.person_id2
,credits.startdate
,datediff(dd, credits.startdate, lead(credits.startdate) over (partition by person.person_id2 order by credits.startdate)) as next_dt_open
into #src
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
where credits.factenddate is null
;
--
drop table if exists #final;
select 
a.*
,avg(next_dt_open) over (partition by a.person_id2) as avg_delta
,max(a.startdate) over (partition by a.person_id2) as last_startdate
,count(a.person_id2) over (partition by a.person_id2) as cnt_active_credits
into #final
from #src a
;
--
drop table if exists #red_velocity;
select 
distinct final.person_id2
into #red_velocity
from #final final
where final.cnt_active_credits >= 5 --не формировать предложение клиентам с 5 и более активными кредитами 
or --2 и более активных кредита + средний срок между активными кредитами 30 дней и менее + менее 90 дней от даты выдачи последнего активного кредита
	(
	datediff(dd, final.last_startdate, getdate()) < 90
	and final.cnt_active_credits > 1
	and avg_delta <= 30
	)
;
-----------------------------Логика определения дисконтов (koeff)
drop table if exists #koeff_discount_src;
select 
credits.vin
,credits.k_disk as koeff
,row_number() over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as rn
into #koeff_discount_src
from risk.credits credits
left join #apps apps
	on apps.number = credits.external_id
	and apps.rn = 1
where datediff(dd, credits.startdate, getdate()) <= 70
and credits.factenddate is null
;
--
drop table if exists #koeff_discount;
select 
rc.vin
,case 
	when rc.is_overturned_ts = 1 and isnull(a.koeff, 0.85) >= 0.3 then 0.3
	when rc.is_overturned_ts = 1 and isnull(a.koeff, 0.85) < 0.3 then isnull(a.koeff, 0.85)
	when datepart(yyyy, getdate()) - rc.ts_year > 15 and isnull(a.koeff, 0.85) >= 0.6 then 0.6
	when datepart(yyyy, getdate()) - rc.ts_year > 15 and isnull(a.koeff, 0.85) < 0.6 then isnull(a.koeff, 0.6)
	when (rc.ts_category <> 'B' or rc.is_modified_ts = 1) and isnull(a.koeff, 0.85) >= 0.7 then 0.7
	when (rc.ts_category <> 'B' or rc.is_modified_ts = 1) and isnull(a.koeff, 0.85) < 0.7 then isnull(a.koeff, 0.85)
	else 0.85
	end koeff
into #koeff_discount
from risk.collateral rc
left join #koeff_discount_src a
	on rc.vin = a.vin
	and a.rn = 1		
;
-----------------------------Отказы по предыдущим заявкам на уровне клиента
drop table if exists #app_person_decline;
select 
person.person_id2
,1 as flag_decline
into #app_person_decline
from risk.collateral col
inner join risk.person person
	on person.person_id = col.person_id		
left join risk.docr_povt_fio_db_red_decline d1 
	on person.person_id2 = d1.fio_bd
	and d1.cdate = cast(getdate() as date) --по ФИО + др			
left join risk.docr_povt_passport_red_decline d2 
	on person.doc_ser = d2.passport_series
	and person.doc_num = d2.passport_number
	and d2.cdate = cast(getdate() as date) --по паспорту
where d1.app_list is not null
or d2.app_list is not null
;
-----------------------------discount_price
drop table if exists #discount_price;
select 
distinct col.vin
,cast(round(col.ts_last_marketprice * (1 - (datediff(day, col.src_dt, getdate()) * 0.0001) / 365), 0) as float) as discount_price
into #discount_price
from risk.collateral col
inner join risk.credits credits 
	on credits.vin = col.vin
inner join risk.person person 
	on person.person_id = col.person_id
;
-----------------------------Текущий остаток по кредиту
drop table if exists #credit_cur_rest_dpd;
select 
external_id
,[остаток од] as rest
,dpd as cur_dpd
into #credit_cur_rest_dpd
from dbo.dm_CMRStatBalance
where d = cast(getdate() as date)
;
-----------------------------limit_car
drop table if exists #limit_car;
select 
distinct col.vin
,cast(dpr.discount_price * isnull(kd.koeff, 0.55) - isnull(sum(ccr.rest) over (partition by col.vin), 0) as float) as limit_car
into #limit_car
from risk.collateral col
inner join risk.credits credits
	on credits.vin = col.vin
left join #discount_price dpr 
	on dpr.vin = col.vin
left join #koeff_discount kd 
	on kd.vin = col.vin
left join #credit_cur_rest_dpd ccr
	on ccr.external_id = credits.external_id
;
-----------------------------перечень клиентов с договорами цессии
drop table if exists #cession;
select 
distinct (concat_ws(' ', pd.LastName, pd.FirstName, pd.MiddleName, cast(pd.BirthdayDt as date))) as person_id2
into #cession
from riskCollection.cessions ces
join stg._collection.deals Deal
	on deal.Number = ces.external_id
left join stg._collection.customerpersonaldata pd 
	on deal.idcustomer = pd.idcustomer
where ces.[Обратный выкуп] = 0
;
-----------------------------максимальная просрочка по всем кредитам ever в рамках person_id2
drop table if exists #max_dpd_ever_person_id2;		
select 
person.person_id2
,max(credits.max_dpd) as max_dpd_all
into #max_dpd_ever_person_id2
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
group by person.person_id2
;
-----------------------------CRMClientGUID и ОсновнойТелефонКлиента
drop table if exists #phones;
select
D.Код --external_id
,CMR_Клиент.Ссылка --person_id
,dbo.getGUIDFrom1C_IDRREF(D.Клиент) as CRMClientGUID
,coalesce(nullif(nullif(trim(CRM_КонтактнаяИнформация.НомерТелефонаБезКодов), ''), '0'), nullif(nullif(trim(CMR_Клиент.Телефон), ''), '0')) as ОсновнойТелефонКлиента
,row_number() over (partition by CMR_Клиент.Ссылка order by D.Код desc) as rn
,row_number() over (partition by D.Код order by (select null)) as rn2
into #phones
from Stg._1cCMR.Справочник_Договоры D (nolock) 
inner join stg._1cCMR.Справочник_Клиенты CMR_Клиент 
	on CMR_Клиент.Ссылка = D.Клиент
left join Stg._1cCRM.Справочник_Партнеры CRM_Партнер
	on CRM_Партнер.Ссылка = D.Клиент
left join 
(
	select 
	CRM_КонтактнаяИнформация.Ссылка as Партнер
	,НомерТелефонаБезКодов
	,row_number() over (partition by CRM_КонтактнаяИнформация.Ссылка order by ДатаЗаписи desc, НомерСтроки desc) as rn
	from stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
	where CRM_КонтактнаяИнформация.CRM_ОсновнойДляСвязи = 0x01
	and CRM_КонтактнаяИнформация.Актуальный = 0x01
	and CRM_КонтактнаяИнформация.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
) CRM_КонтактнаяИнформация 
	on CRM_КонтактнаяИнформация.Партнер = CRM_Партнер.Ссылка
	and CRM_КонтактнаяИнформация.rn = 1;
;
-----------------------------probation
drop table if exists #probation;
select 
number
,probation
,probation_povt
,row_number() over (partition by number order by call_date desc) as rn
into #probation
from stg._loginom.Originationlog
where stage = 'Call 2'
;
-----------------------------дельта по последнему действующему кредиту сроком жизни менее 70 дней в рамках одного VIN
drop table if exists #max_delta_active_70;
select 
credits.vin
,iif(credits.creditlimit_fin - credits.amount <= 0, 0, isnull(credits.creditlimit_fin - credits.amount, 0)) as max_delta_active
,row_number() over (partition by credits.person_id order by coalesce(apps.c1_date, credits.startdate) desc) as rn
into #max_delta_active_70
from risk.credits credits
left join #apps apps
	on apps.number = credits.external_id
	and apps.rn = 1
where datediff(dd, credits.startdate, getdate()) <= 70
and credits.factenddate is null
;
-----------------------------максимальная просрочка по всем действующим кредитам сроком жизни менее 70 дней в рамках одного VIN
drop table if exists #max_dpd_da_70;		
select 
vin
,max(max_dpd) as max_dpd_da
into #max_dpd_da_70
from risk.credits
where datediff(dd, startdate, getdate()) <= 70
and factenddate is null
group by vin
;
-----------------------------максимальная просрочка по всем действующим кредитам в рамках person_id2
drop table if exists #max_dpd_cur_person_id2;			
select 
person.person_id2
,max(credits.max_dpd) as max_dpd_now
into #max_dpd_cur_person_id2
from risk.credits credits
inner join risk.person person
	on person.person_id = credits.person_id
where credits.factenddate is null
group by person.person_id2
;
-----------------------------Текущий остаток по клиенту
drop table if exists #pers_cur_rest;				
select 
distinct person.person_id2
,sum(ccr.rest) over (partition by person.person_id2) as pers_rest
into #pers_cur_rest
from #credit_cur_rest_dpd ccr
inner join risk.credits credits 
	on credits.external_id = ccr.external_id
inner join risk.person person 
	on person.person_id = credits.person_id
;
-----------------------------Количество закрытых клиентом договоров
drop table if exists #person_id2_num_closed;	
select 
distinct person.person_id2
,sum(iif(credits.factenddate is null, 0, 1)) over (partition by person.person_id2) as num_closed
into #person_id2_num_closed
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
;
-----------------------------У клиента есть хотя бы один действуюйщий инстоллмент
drop table if exists #isinstallment;			
select 
distinct person.person_id2
,1 as flag_installment
into #isinstallment
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
where credits.IsInstallment = 1
and credits.factenddate is null
;
-----------------------------реструктуризации
drop table if exists #red_kk;
select distinct person.person_id2
into #red_kk
from dbo.dm_restructurings crr
inner join risk.credits credits 
	on credits.external_id = crr.number
inner join risk.person person 
	on person.person_id = credits.person_id
where datediff(dd, dateadd(dd, - 70, getdate()), isnull(crr.period_end, getdate())) >= 0
and crr.operation_type <> 'Другое'
;
-----------------------------перечень клиентов по ключу ФИО+Дата рождения с исп.сроком, выдача была не позднее последних 180 дней
drop table if exists #isp_srok_clients;
select distinct person.person_id2
into #isp_srok_clients
from risk.credits credits
inner join risk.person person
	on person.person_id = credits.person_id
where credits.credit_type_init = 'PTS_31'
and datediff(dd, credits.startdate, cast(getdate() as date)) < 180
;
-----------------------------docredy_buffer
drop table if exists #docredy_buffer;
select 
distinct first_value(credits.external_id) over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as external_id
,cast(null as varchar(100)) as category
,'Докредитование' as [Type]
,cast(null as float) as main_limit
,cast(null as varchar(100)) as [Минимальный срок кредитования]
,cast(null as float) as [Ставка %]
,null as [Сумма платежа]
,null as [Рекомендуемая дата повторного обращения]
,person.fio
,person.birth_date
,concat_ws (' ', col.ts_brand, col.ts_model ,col.ts_year) as [auto]
,col.vin
,first_value(credits.pos) over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as pos
,first_value(credits.rp) over (partition by credits.vin  order by coalesce(apps.c1_date, credits.startdate) desc) as rp
,first_value(credits.channel) over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as channel
,person.doc_ser
,person.doc_num
,person.mobile_phone as ТелефонМобильный
,person.region_fact as region_projivaniya
,'Не брать ПТС' as Berem_pts
,'ПТС  в компании' as Nalichie_pts
,null as not_end
,cast(1 as bit) as flag_good
,mdpd.max_dpd_all
,cdpd.max_dpd_now
,isnull(max(ccr.cur_dpd) over (partition by col.vin), 0) as overdue_days --максимальная текущая просрочка по всем действующим кредитам в рамках одного VIN
,min(credits.dob) over (partition by col.vin) as dod --dob по последнему договору в рамках одного VIN
,nad.num_active_days
,col.ts_last_marketprice as market_price
,null as collateral_id
,cast(col.src_dt as datetime) as price_date
,dpr.discount_price as discount_price
,sum(ccr.rest) over (partition by col.vin) as col_rest --текущий совокупный остаток в рамках одного VIN
,pcr.pers_rest --текущий совокупный остаток в рамках одного person_id2
,convert(numeric(3,3), isnull(kd.koeff, 0.55)) as koeff
,pnc.num_closed
,limc.limit_car --discount_price*koeff-col_rest
,1000000 - pcr.pers_rest as limit_client
,cast(case when apd.flag_decline = 1 or ii.flag_installment = 1 or person.age > 65 then 1 else 0 end as bit) as red_visa
,cast(case 
		when (
				(
					min(credits.dob) over (partition by credits.vin) /*dod*/ < 70
					and (md70.max_delta_active < 50000 or mdpd70.max_dpd_da > 0)
					)
				--в течение последних 180 дней была выдача по продукту "испытательный срок"
				or isrk.person_id2 is not null
				)
		then 1
		else 0
		end as bit) as red_dod
,cast(case 
		when isnull(max(ccr.cur_dpd) over (partition by col.vin), 0) >= 5 /*overdue_days*/
			or cdpd.max_dpd_now >= 5 --в рамках одного клиента текущая просрочка более 5 дней
			or crt.person_id2 is not null --подан иск в суд 		
		then 1
		else 0
		end as bit) as red_dpd				   
,case when (1000000 - isnull(pcr.pers_rest, 0) < 50000) then 1 else 0 end red_limit --1.Доступная сумма кредита менее 50 000 рублей	
,cast(--Если попал под 1-6 мы его устанавливаем в красный (продублировать условия из red_***) + добавляем условие по исторической просрочке 180 дней
	case 
		when (
				(1000000 - isnull(pcr.pers_rest, 0) < 50000) --red_limit			
				or isnull(max(ccr.cur_dpd) over (partition by col.vin), 0) >= 5 /*overdue_days*/ --red_dpd
				or cdpd.max_dpd_now >= 5 --в рамках одного клиента текущая просрочка более 5 дней
				or crt.person_id2 IS NOT NULL --подан иск в суд
				or (
					min(credits.dob) over (partition by credits.vin) /*dod*/ < 70
					and (
						md70.max_delta_active < 50000
						or mdpd70.max_dpd_da > 0
						)
					) --red_dod
				--в течение последних 180 дней была выдача по продукту "испытательный срок"
				or isrk.person_id2 is not null --red_dod 
				or crr.person_id2 is not null --у клиента есть договор, по которому действуют кредитные каникулы или каникулы закончились менее 70 дней назад 
				or ces.person_id2 is not null --цессированные
				or limc.limit_car < 50000
				or year(getdate()) - col.ts_year > 20 --red_car
				or cdpd.max_dpd_now >= 180
				or apd.flag_decline = 1 --отказные заявки клиента
				or auto_dec.vin is not null --отказные завки машины
				or ii.flag_installment = 1 --у клиента есть выданные инстолменты
				or rv.person_id2 is not null --red_velocity
				or pmt_delay.vin is not null --клиенты, взявшие отсрочку платежа + с момента отсрочки платежа (по одному из активных кредитов клиента) прошло менее 65 дней
				or person.age > 65 --возраст более 65 лет
				)
		then 1
		else 0
		end as bit) as is_red
,cast(case 
		when (
				--1.Выполняется условие: по всем договорам клиента в компании не было просрочек свыше 9 дней + 
				--самый последний из активных договоров клиента оформлен 130 и более дней назад
				(
					min(credits.dob) over (partition by credits.vin) /*dod*/ > 129
					and cdpd.max_dpd_now < 5
					and isnull(max(ccr.cur_dpd) over (partition by col.vin), 0) /*overdue_days*/ = 0
					and mdpd.max_dpd_all < 10
					)
				--2.Выполняется условие: по всем договорам клиента в компании не было просрочек свыше 13 дней И
				--самый последний из активных договоров клиента оформлен от 100 до 129 дней назад И
				--совокупный период обслуживания кредитных договоров клиента в компании составляет 280 дней и более 
				or (
					min(credits.dob) over (partition by credits.vin) /*dod*/ between 100 and 129
					and cdpd.max_dpd_now < 5
					and isnull(max(ccr.cur_dpd) over (partition by col.vin), 0) = 0 /*overdue_days*/
					and mdpd.max_dpd_all < 14
					and nad.num_active_days > 279
					)
				)
		then 1
		else 0
		end as bit) as is_green
,cast(null as bit) as is_yellow
,null as score
,null as score_date
,null as has_bureau
,null as scoring
,cast(case 
		when min(credits.dob) over (partition by credits.vin) /*dod*/ < 35
			and case 
				when 1000000 - isnull(pcr.pers_rest, 0) <= limc.limit_car
					and 1000000 - isnull(pcr.pers_rest, 0) <= md70.max_delta_active
					then 1000000 - isnull(pcr.pers_rest, 0)
				when limc.limit_car <= 1000000 - isnull(pcr.pers_rest, 0)
					and limc.limit_car <= md70.max_delta_active
					then limc.limit_car
				when md70.max_delta_active <= 1000000 - isnull(pcr.pers_rest, 0)
					and md70.max_delta_active <= limc.limit_car
					then md70.max_delta_active
				end >= 50000
			and mdpd70.max_dpd_da = 0
		then 1
		else 0
		end as bit) as is_orange
,cast(null as varchar(100)) as [group]
,cast(null as varchar(100)) as GUID
,md70.max_delta_active
,mdpd70.max_dpd_da
,case 
	when (
			(limc.limit_car < 50000 and limc.limit_car <> 0)			
			or year(getdate()) - col.ts_year > 20 --возраст автомобиля более 20 лет
			)
		or auto_dec.vin is not null
	then 1
	else 0
	end red_car
,cast(iif(crr.person_id2 is not null, 1, 0) as bit) as red_chd --у клиента есть договор, по которому действуют кредитные каникулы или каникулы закончились менее 70 дней назад
,cast(iif(rv.person_id2 is not null, 1, 0) as bit) as red_velocity
,cast(iif(max(pmt_delay.vin) over (partition by col.vin) is not null, 1, 0) as bit) as red_pmt_delay --клиенты, взявшие отсрочку платежа + с момента отсрочки платежа (по одному из активных кредитов клиента) прошло менее 65 дней
,phones.CRMClientGUID
,phones.ОсновнойТелефонКлиента
,person.last_name
,person.first_name
,person.patronymic
,first_value(credits.CurrRate) over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as CurrRate
,first_value(credits.credit_type) over (partition by credits.vin order by coalesce(apps.c1_date, credits.startdate) desc) as credit_type
into #docredy_buffer
from risk.collateral col
inner join risk.credits credits
	on credits.vin = col.vin
inner join risk.person person 
	on person.person_id = col.person_id
left join #apps apps
	on apps.number = credits.external_id
	and apps.rn = 1
left join #max_delta_active_70 md70 
	on md70.vin = col.vin
	and md70.rn = 1
left join #max_dpd_da_70 mdpd70 
	on mdpd70.vin = col.vin
left join #max_dpd_ever_person_id2 mdpd 
	on mdpd.person_id2 = person.person_id2
left join #max_dpd_cur_person_id2 cdpd 
	on cdpd.person_id2 = person.person_id2
left join #num_active_days nad 
	on nad.person_id2 = person.person_id2
left join #credit_cur_rest_dpd ccr 
	on ccr.external_id = credits.external_id
left join #pers_cur_rest pcr 
	on PCR.person_id2 = person.person_id2
left join #person_id2_num_closed pnc 
	on pnc.person_id2 = person.person_id2
left join #koeff_discount kd 
	on kd.vin = col.vin
left join risk.docr_povt_vin_red_decline auto_dec
	on credits.vin = auto_dec.vin
	and auto_dec.cdate = cast(getdate() as date)
left join #app_person_decline apd 
	on apd.person_id2 = person.person_id2
left join #isinstallment ii 
	on ii.person_id2 = person.person_id2
left join #isp_srok_clients isrk 
	on isrk.person_id2 = person.person_id2
left join #discount_price dpr 
	on dpr.vin = col.vin
left join #limit_car limc 
	on limc.vin = col.vin
left join #client_court_decisions crt 
	on crt.person_id2 = person.person_id2
left join #red_kk crr 
	on crr.person_id2 = person.person_id2
left join #cession ces 
	on ces.person_id2 = person.person_id2
left join #red_velocity rv 
	on rv.person_id2 = person.person_id2
left join risk.credits pmt_delay 
	on pmt_delay.vin = col.vin
	and datediff(dd, pmt_delay.pmt_delay_dt, getdate()) < 65
	and pmt_delay.factenddate is not null
left join #phones phones
	on phones.Ссылка = person.person_id
	and phones.rn = 1
where col.is_active = 1
;
-----------------------------update category
update #docredy_buffer
set 
category = case 
				when credit_type = 'AUTOCREDIT' then 'Красный' --RDWH-28
				when is_red = 1	then 'Красный'
				when is_orange * (1 - is_red) = 1 then 'Красный' --'Оранжевый'--Кузнецов/Ставничая 16/06/2022
				when is_green * (1 - is_red) * (1 - is_orange) = 1	then 'Зеленый'
				when (1 - is_red) * (1 - is_orange) * (1 - is_green) = 1 then 'Желтый'
				end
,is_green = is_green * (1 - is_red) * (1 - is_orange)
,is_yellow = (1 - is_red) * (1 - is_orange) * (1 - is_green)
;
-----------------------------update main_limit
with cte_to_update as 
(
	select 
	* ,round(iif(limit_client < limit_car, limit_client, limit_car), - 3) as limit
	from #docredy_buffer
)
update t
set 
main_limit = case  
				when is_red = 1	then 0
				when category = 'Красный' then 0 --Кузнецов/Ставничая 11/07/2022
				when is_orange = 1 and limit <= max_delta_active then floor(limit / 1000.0) * 1000
				when is_orange = 1 and max_delta_active <= limit then floor(max_delta_active / 1000.0) * 1000				
				else cast(limit as int)
				end
from cte_to_update t
;

delete from #docredy_buffer
where pos is null
or isnull(pers_rest, 0) = 0
or limit_car is null
;
-----------------------------Сменил ФИО
update #docredy_buffer -- Назарова -> РАЗОРЕНОВА 20.10 по договорености с Ставничей
set 
fio = 'РАЗОРЕНОВА ИННА ОЛЕГОВНА'
,last_name = 'НАЗАРОВА'
where fio like 'НАЗАРОВА ИННА ОЛЕГОВНА'
and vin = 'XW8ZZZ61ZGG011318';
-----------------------------внесение данных docredy_buffer
BEGIN TRANSACTION
	delete from risk.docredy_buffer_tmp;  

	insert into risk.docredy_buffer_tmp (
	external_id
	,category
	,Type
	,main_limit
	,[Минимальный срок кредитования]
	,[Ставка %]
	,[Сумма платежа]
	,[Рекомендуемая дата повторного обращения]
	,fio
	,birth_date
	,Auto
	,vin
	,pos
	,rp
	,channel
	,doc_ser
	,doc_num
	,ТелефонМобильный
	,region_projivaniya
	,Berem_pts
	,Nalichie_pts
	,not_end
	,flag_good
	,max_dpd_all
	,max_dpd_now
	,overdue_days
	,dod
	,num_active_days
	,market_price
	,collateral_id
	,price_date
	,discount_price
	,col_rest
	,pers_rest
	,koeff
	,num_closed
	,limit_car
	,limit_client
	,red_visa
	,red_dod
	,red_dpd
	,red_limit
	,is_red
	,is_green
	,is_yellow
	,score
	,score_date
	,has_bureau
	,scoring
	,[group]
	,GUID
	,max_delta_active
	,max_dpd_da
	,RED_CAR
	,RED_CHD
	,is_orange
	,red_velocity
	,red_pmt_delay
	,CRMClientGUID
	,ОсновнойТелефонКлиента
	,last_name
	,first_name
	,patronymic
	,CurrRate
	)
	select 
	external_id
	,category
	,Type
	,main_limit
	,[Минимальный срок кредитования]
	,[Ставка %]
	,[Сумма платежа]
	,[Рекомендуемая дата повторного обращения]
	,fio
	,birth_date
	,Auto
	,vin
	,pos
	,rp
	,channel
	,doc_ser
	,doc_num
	,ТелефонМобильный
	,isnull(region_projivaniya, '%') as region_projivaniya
	,Berem_pts
	,Nalichie_pts
	,not_end
	,flag_good
	,max_dpd_all
	,max_dpd_now
	,overdue_days
	,dod
	,num_active_days
	,market_price
	,collateral_id
	,price_date
	,discount_price
	,col_rest
	,pers_rest
	,koeff
	,num_closed
	,limit_car
	,limit_client
	,red_visa
	,red_dod
	,red_dpd
	,red_limit
	,is_red
	,is_green
	,is_yellow
	,score
	,score_date
	,has_bureau
	,scoring
	,[group]
	,[GUID]
	,max_delta_active
	,max_dpd_da
	,RED_CAR
	,RED_CHD
	,is_orange
	,red_velocity
	,red_pmt_delay
	,CRMClientGUID
	,ОсновнойТелефонКлиента
	,last_name
	,first_name
	,patronymic
	,CurrRate
	from #docredy_buffer
;
COMMIT TRANSACTION;

---------------------------
--------Повторники---------
-------Текущий залог-------
---------------------------

-----------------------------клиенты, у которых на текущий момент нет активных договоров
drop table if exists #cli_base;
select 
sign(sum(case when credits.factenddate is null then 1 else 0 end)) as not_end
,person.person_id2
into #cli_base
from risk.credits credits
inner join risk.person person 
	on person.person_id = credits.person_id
group by person.person_id2
;
-----------------------------povt_buffer_curr_collateral
drop table if exists #povt_buffer_curr_collateral;
select 
distinct first_value(credits.external_id) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as external_id
,first_value(credits.startdate) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as startdate
,cast(null as varchar(20)) as category
,'Повторный заём с известным залогом' as [TYPE]
,cast(null as int) as [main_limit]
,cast(null as int) as [Минимальный срок кредитования]
,cast(null as float) as [Ставка %]
,cast(null as int) as [Сумма платежа]
,cast(null as int) as [Рекомендуемая дата повторного обращения]
,person.FIO as fio
,person.birth_date as [birth_date]
,concat_ws (' ', col.ts_brand, col.ts_model, col.ts_year) as [Auto]
,col.vin as vin
,first_value(credits.pos) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as pos
,first_value(credits.rp) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as rp
,first_value(credits.channel) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as channel
,person.doc_ser as doc_ser
,person.doc_num as doc_num
,person.mobile_phone as ТелефонМобильный
,person.region_fact as region_projivaniya
,'Не брать ПТС' as Berem_pt
,'ПТС не в компании' as Nalichie_pts
,cast(0 as int) as not_end
,cast(mdpd.max_dpd_all as int) as max_dpd_all
,cast(min(datediff(d, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) as dod
,cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) as was_closed_ago
,cast(null as int) as flag
,first_value(credits.creditlimit_client) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as LIMIT
,cast(nad.num_active_days as int) as num_active_days
,col.ts_last_marketprice as market_price
,cast(null as int) as collateral_id
,col.src_dt as price_date
,datediff(d, col.src_dt, getdate()) as [days]
,cast(dpr.discount_price as float) as discount_price
,cast(isnull(kd.koeff, 0.55) as float) as koeff
,limc.limit_car as limit_car
,case when isnull(dpr.discount_price, 0) * 0.7 < 50000 then 1 else 0 end red_lim
,case when person.age > 65 then 1 else 0 end as red_age
,cast(0 as int) as red_7days
,case when mdpd.max_dpd_all > 180 then 1 else 0 end red_dpd
,case 
	when isnull(dpr.discount_price, 0) * 0.7 < 50000 --red_lim                  
		or max_dpd_all > 180 --red_dpd
		or year(getdate()) - col.ts_year > 20 --возраст автомобиля red_car
		or ces.person_id2 is not null -- цессии
		or crt.person_id2 is not null -- был суд
		or apd.flag_decline = 1 --отказные заявки клиента
		or auto_dec.vin is not null --отказные завки машины 
		or person.age > 65 --возраст более 65 лет			
	then 1
	else 0
	end is_red
,case 
	when cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) <= 90
		and nad.num_active_days >= 280
		and mdpd.max_dpd_all <= 14
	then 1
	else 0
	end is_green
,case 
	when cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) > 90
		and cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) < 367
		and dpr.discount_price * 0.7 * 0.9 >= 50000
	then 1
	else 0
	end is_blue
,cast(null as int) as is_yellow
,case when cast(min(datediff(d, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) <= 7 then 1 else 0 end is_orange
,cast(null as float) AS score
,cast(null as datetime) AS score_date
,cast(null as int) AS [group]
,cast(null as varchar(32)) AS [GUID]
,cast(sum(datediff(dd, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) as cred_hist_length
,cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) as term_from_last_closed --то же самое, что was_close_ago
,cast(first_value(credits.InitialRate) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as float) as last_int_rate
,CAST(null as varchar(256)) as rbp_gr_action
,person.last_name
,person.first_name
,person.patronymic as middle_name
into #povt_buffer_curr_collateral
from risk.collateral col
inner join risk.credits credits 
	on credits.vin = col.vin
	and credits.credit_type <> 'INST'
inner join risk.person person
	on person.person_id = col.person_id
inner join #cli_base cb 
	on cb.person_id2 = person.person_id2
	and cb.not_end = 0
left join #apps apps
	on apps.number = credits.external_id
	and apps.rn = 1
left join #max_dpd_ever_person_id2 mdpd 
	on mdpd.person_id2 = person.person_id2
left join #num_active_days nad 
	on nad.person_id2 = person.person_id2
left join #discount_price dpr 
	on dpr.vin = col.vin
left join #limit_car limc
	on limc.vin = col.vin
left join #koeff_discount kd 
	on kd.vin = col.vin
left join #client_court_decisions crt 
	on crt.person_id2 = person.person_id2
left join #cession ces 
	on ces.person_id2 = person.person_id2
left join #app_person_decline apd 
	on apd.person_id2 = person.person_id2
left join risk.docr_povt_vin_red_decline auto_dec 
	on credits.vin = auto_dec.vin
	and auto_dec.cdate = cast(getdate() as date)
;
-----------------------------CRMClientGUID, ОсновнойТелефонКлиента, probation
drop table if exists #povt_buffer_curr_collateral_total;
select 
curr.*
,phones.CRMClientGUID
,phones.ОсновнойТелефонКлиента
,probation.probation
,probation.probation_povt
into #povt_buffer_curr_collateral_total
from #povt_buffer_curr_collateral curr
left join #probation probation
	on probation.number = curr.external_id
	and probation.rn = 1
left join #phones phones
	on phones.Код = curr.external_id
	and phones.rn2 = 1
;
-----------------------------update category
update #povt_buffer_curr_collateral_total
set 
category = case 
				when is_red = 1 then 'Красный'
				when is_green * (1 - is_red) * (1 - is_orange) = 1 then 'Зеленый'
				when (1 - is_red) * (1 - is_orange) * (1 - is_green) * (1 - is_blue) = 1 then 'Желтый'
				when (1 - is_red) * (1 - is_orange) * (1 - is_green) * is_blue = 1 then 'Синий'
				when (1 - is_red) * is_orange = 1 then 'Оранжевый'
				end
,is_green = (1 - is_red) * (1 - is_orange) * is_green
,is_blue = (1 - is_red) * (1 - is_orange) * (1 - is_green) * is_blue
,is_yellow = (1 - is_red) * (1 - is_orange) * (1 - is_green) * (1 - is_blue)
,is_orange = (1 - is_red) * is_orange
;
-----------------------------main_limit
declare @max_main_limit int = 1e6;
with cte_to_update as 
(
	select 
	*
	,round(iif(limit < limit_car, limit, limit_car), - 3) as main_limit_upd
	from #povt_buffer_curr_collateral_total
)
update t
set main_limit = case 
					when is_red = 1 then 0
					else iif(cast(main_limit_upd as int) < @max_main_limit, cast(main_limit_upd as int), @max_main_limit) /*П. Прокопенко 12.02.2025*/
					end
from cte_to_update t
;
-----------------------------update rbp_gr_action
update #povt_buffer_curr_collateral_total
set rbp_gr_action = 
case 
	when max_dpd_all > 60 then '01. Max APR'
	when max_dpd_all between 31 and 60 then '02. +10 b.p.'
	when cred_hist_length <= 60 then '03. The Same'
	when cred_hist_length > 180 and term_from_last_closed <= 180 and max_dpd_all between 15 and 30 then '04. 5 b.p. discount'
	when cred_hist_length between 61 and 180 and term_from_last_closed <= 180 and max_dpd_all between 15 and 30 then '03. The Same'
	when cred_hist_length > 60 and term_from_last_closed > 180 and max_dpd_all between 15 and 30 then '03. The Same'
	when cred_hist_length > 180 and term_from_last_closed > 180 and max_dpd_all between 8 and 14 then '05. 10 b.p. discount'
	when cred_hist_length > 180 and term_from_last_closed > 180 and max_dpd_all between 0 and 7 then '06. 15 b.p. discount'
	when cred_hist_length between 61 and 180 and term_from_last_closed > 180 and max_dpd_all between 0 and 14 then '05. 10 b.p. discount'
	when cred_hist_length > 180 and term_from_last_closed <= 180 and max_dpd_all between 0 and 14 then '06. 15 b.p. discount'
	when cred_hist_length between 61 and 180 and term_from_last_closed <= 180 and max_dpd_all between 0 and 14 then '05. 10 b.p. discount'
	else '00. Empty'
	end
;
-----------------------------update [Ставка %]
update #povt_buffer_curr_collateral_total
set [Ставка %] = 
case 
	when rbp_gr_action = '01. Max APR' then 79.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 66 then 79.0
	when rbp_gr_action = '03. The Same' and last_int_rate >= 79 then 79.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 79 then 79.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate >= 84 then 79.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 90 then 79.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 60 and last_int_rate < 66 then 74.0
	when rbp_gr_action = '03. The Same' and last_int_rate >= 74 and last_int_rate < 79 then 74.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 76 and last_int_rate < 79 then 74.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 80 and last_int_rate < 84 then 74.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 85 and last_int_rate < 90 then 74.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 56 and last_int_rate < 60 then 70.0
	when rbp_gr_action = '03. The Same' and last_int_rate >= 68 and last_int_rate < 74 then 70.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 72 and last_int_rate < 76 then 70.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 74 and last_int_rate <= 80 then 70.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 80 and last_int_rate < 85 then 70.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 50 and last_int_rate < 56 then 62.0
	when rbp_gr_action = '03. The Same' and last_int_rate >= 60 and last_int_rate < 68 then 62.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 66 and last_int_rate < 72 then 62.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 66 and last_int_rate <= 74 then 62.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 72 and last_int_rate < 80 then 62.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 46 and last_int_rate < 50 then 56.0
	when rbp_gr_action = '03. The Same' and last_int_rate >= 56 and last_int_rate < 60 then 56.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 60 and last_int_rate < 66 then 56.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 60 and last_int_rate <= 66 then 56.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 68 and last_int_rate < 72 then 56.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 40 and last_int_rate < 46 then 50.0
	when rbp_gr_action = '03. The Same' and last_int_rate > 40 and last_int_rate < 56 then 50.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 50 and last_int_rate < 60 then 50.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 50 and last_int_rate <= 60 then 50.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 60 and last_int_rate < 68 then 50.0
	when rbp_gr_action = '02. +10 b.p.' and last_int_rate < 40 then 40.0
	when rbp_gr_action = '03. The Same' and last_int_rate <= 40 then 40.0
	when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate < 50 then 40.0
	when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate <= 50 then 40.0
	when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate < 60 then 40.0
	end
;
---------------------------
--------Повторники---------
-------Новый залог---------
---------------------------

drop table if exists #povt_buffer_new_collateral;
select 
distinct first_value(credits.external_id) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as external_id
,first_value(credits.startdate) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as startdate
,cast(null as varchar(20)) as category
,cast('Повторный заём с новым залогом' as varchar(34)) as [TYPE]
,cast(0 as int) as main_limit
,cast(null as int) as [Минимальный срок кредитования]
,cast(null as float) as [Ставка %]
,cast(null as int) as [Сумма платежа]
,cast(null as int) as [Рекомендуемая дата повторного обращения]
,person.FIO as fio
,person.birth_date as birth_date
,cast(null as varchar(535)) as [Auto]
,cast(null as varchar(60)) as vin
,first_value(credits.pos) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as pos
,first_value(credits.rp) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as rp
,first_value(credits.channel) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as channel
,person.doc_ser as doc_ser
,person.doc_num as doc_num
,person.mobile_phone as ТелефонМобильный
,person.region_fact AS region_projivaniya
,'Не брать ПТС' as Berem_pt
,'ПТС не в компании' as Nalichie_pts
,cast(0 as int) as not_end
,cast(mdpd.max_dpd_all as int) as max_dpd_all
,cast(min(datediff(d, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) as dod
,cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) as was_closed_ago
,cast(null as int) as flag
,first_value(credits.creditlimit_client) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as LIMIT
,cast(nad.num_active_days as int) as num_active_days
,cast(null as float) as market_price
,cast(null as int) as collateral_id
,cast(null as date) as price_date
,cast(null as int) as [days]
,cast(null as float) as discount_price
,cast(null as float) as koeff
,cast(null as float) as limit_car
,cast(0 as int) as red_lim
,case when person.age > 65 then 1 else 0 end red_age
,cast(0 as int) as red_7days
,case when mdpd.max_dpd_all > 180 then 1 else 0 end red_dpd
,case 
	when max_dpd_all > 180 --red_dpd
	or ces.person_id2 is not null -- цессии
	or crt.person_id2 is not null -- был суд
	or apd.flag_decline = 1 --отказные заявки клиента
	or person.age > 65 --возраст более 65 лет			
	then 1
	else 0
	end is_red
,cast(0 as int) as is_green
,cast(0 as int) as is_blue
,cast(null as int) as is_yellow
,case when cast(min(datediff(d, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) <= 7 then 1 else 0 end is_orange
,cast(null as float) as score
,cast(null as datetime) as score_date
,cast(null as int) as [group]
,cast(null as varchar(32)) as [GUID]
,cast(sum(datediff(dd, credits.startdate, credits.factenddate)) over (partition by person.person_id2) as int) as cred_hist_length
,cast(min(datediff(d, credits.factenddate, getdate())) over (partition by person.person_id2) as int) as term_from_last_closed --то же самое, что was_close_ago
,cast(first_value(credits.InitialRate) over (partition by person.person_id2 order by coalesce(apps.c1_date, credits.startdate) desc) as float) as last_int_rate
,cast(null as varchar(256)) as rbp_gr_action
,person.last_name
,person.first_name
,person.patronymic as middle_name
into #povt_buffer_new_collateral
from risk.collateral col
inner join risk.credits credits 
	on credits.vin = col.vin
	and credits.credit_type <> 'INST'
inner join risk.person person 
	on person.person_id = col.person_id
inner join #cli_base cb 
	on cb.person_id2 = person.person_id2
	and cb.not_end = 0
left join #apps apps
	on apps.number = credits.external_id
	and apps.rn = 1
left join #max_dpd_ever_person_id2 mdpd 
	on mdpd.person_id2 = person.person_id2
left join #num_active_days nad 
	on nad.person_id2 = person.person_id2
left join #discount_price dpr 
	on dpr.vin = col.vin
left join #limit_car limc 
	on limc.vin = col.vin
left join #koeff_discount kd 
	on kd.vin = col.vin
left join #client_court_decisions crt 
	on crt.person_id2 = person.person_id2
left join #cession ces 
	on ces.person_id2 = person.person_id2
left join #app_person_decline apd 
	on apd.person_id2 = person.person_id2
left join risk.docr_povt_vin_red_decline auto_dec 
	on credits.vin = auto_dec.vin
	and auto_dec.cdate = cast(getdate() as date)
;
-----------------------------CRMClientGUID, ОсновнойТелефонКлиента, probation
drop table if exists #povt_buffer_new_collateral_total;
select 
new.*
,phones.CRMClientGUID
,phones.ОсновнойТелефонКлиента
,probation.probation
,probation.probation_povt
into #povt_buffer_new_collateral_total
from #povt_buffer_new_collateral new
left join #probation probation
	on probation.number = new.external_id
	and probation.rn = 1
left join #phones phones
	on phones.Код = new.external_id
	and phones.rn2 = 1
;
-----------------------------update category
update #povt_buffer_new_collateral_total
set category = case 
				when is_red = 1 then 'Красный'
				when (1 - is_red) * is_orange = 1 then 'Оранжевый'
				when is_green = 1 then 'Зеленый' 
				when (1 - is_red) * (1 - is_orange) = 1 then 'Желтый'
				end
,is_yellow = (1 - is_red) * (1 - is_orange)
,is_orange = (1 - is_red) * is_orange
;
-----------------------------update rbp_gr_action
update #povt_buffer_new_collateral_total
set rbp_gr_action = case 
				when max_dpd_all > 60 then '01. Max APR'
				when max_dpd_all between 31 and 60 then '02. +10 b.p.'
				when cred_hist_length <= 60 then '03. The Same'
				when cred_hist_length > 180 and term_from_last_closed <= 180 and max_dpd_all between 15 and 30 then '04. 5 b.p. discount'
				when cred_hist_length between 61 and 180 and term_from_last_closed <= 180 and max_dpd_all between 15 and 30 then '03. The Same'
				when cred_hist_length > 60 and term_from_last_closed > 180 and max_dpd_all between 15 and 30 then '03. The Same'
				when cred_hist_length > 180 and term_from_last_closed > 180 and max_dpd_all between 8 and 14 then '05. 10 b.p. discount'
				when cred_hist_length > 180 and term_from_last_closed > 180 and max_dpd_all between 0 and 7 then '06. 15 b.p. discount'
				when cred_hist_length between 61 and 180 and term_from_last_closed > 180 and max_dpd_all between 0 and 14 then '05. 10 b.p. discount'
				when cred_hist_length > 180 and term_from_last_closed <= 180 and max_dpd_all between 0 and 14 then '06. 15 b.p. discount'
				when cred_hist_length between 61 and 180 and term_from_last_closed <= 180 and max_dpd_all between 0 and 14 then '05. 10 b.p. discount'
				else '00. Empty'
				end
;
-----------------------------update [Ставка %]
update #povt_buffer_new_collateral_total
set [Ставка %] = case 
				when rbp_gr_action = '01. Max APR' then 79.0 
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 66 then 79.0
				when rbp_gr_action = '03. The Same' and last_int_rate >= 79 then 79.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 79 then 79.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate >= 84 then 79.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 90 then 79.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 60 and last_int_rate < 66 then 74.0
				when rbp_gr_action = '03. The Same' and last_int_rate >= 74 and last_int_rate < 79 then 74.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 76 and last_int_rate < 79 then 74.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 80 and last_int_rate < 84 then 74.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 85 and last_int_rate < 90 then 74.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 56 and last_int_rate < 60 then 70.0
				when rbp_gr_action = '03. The Same' and last_int_rate >= 68 and last_int_rate < 74 then 70.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 72 and last_int_rate < 76 then 70.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 74 and last_int_rate <= 80 then 70.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 80 and last_int_rate < 85 then 70.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 50 and last_int_rate < 56 then 62.0
				when rbp_gr_action = '03. The Same' and last_int_rate >= 60 and last_int_rate < 68 then 62.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 66 and last_int_rate < 72 then 62.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 66 	and last_int_rate <= 74 then 62.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 72 and last_int_rate < 80 then 62.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 46 and last_int_rate < 50 then 56.0
				when rbp_gr_action = '03. The Same' and last_int_rate >= 56 and last_int_rate < 60 then 56.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 60 and last_int_rate < 66 then 56.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 60 and last_int_rate <= 66 then 56.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 68 and last_int_rate < 72 then 56.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate >= 40 and last_int_rate < 46 then 50.0
				when rbp_gr_action = '03. The Same' and last_int_rate > 40 and last_int_rate < 56 then 50.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate >= 50 and last_int_rate < 60 then 50.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate > 50 and last_int_rate <= 60 then 50.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate >= 60 and last_int_rate < 68 then 50.0
				when rbp_gr_action = '02. +10 b.p.' and last_int_rate < 40 then 40.0 
				when rbp_gr_action = '03. The Same' and last_int_rate <= 40 then 40.0
				when rbp_gr_action = '04. 5 b.p. discount' and last_int_rate < 50 then 40.0
				when rbp_gr_action = '05. 10 b.p. discount' and last_int_rate <= 50 then 40.0
				when rbp_gr_action = '06. 15 b.p. discount' and last_int_rate < 60 then 40.0
				end
;
-----------------------------внесение данных povt_buffer
if OBJECT_ID('risk.povt_buffer_tmp') is null
begin
	select top(0) * into risk.povt_buffer_tmp
	from #povt_buffer_new_collateral_total
end;

BEGIN TRANSACTION
	delete from risk.povt_buffer_tmp; 

	insert into risk.povt_buffer_tmp (
	external_id,
	startdate,
	category,
	TYPE,
	main_limit,
	[Минимальный срок кредитования],
	[Ставка %],
	[Сумма платежа],
	[Рекомендуемая дата повторного обращения],
	fio,
	birth_date,
	Auto,
	vin,
	pos,
	rp,
	channel,
	doc_ser,
	doc_num,
	ТелефонМобильный,
	region_projivaniya,
	Berem_pt,
	Nalichie_pts,
	not_end,
	max_dpd_all,
	dod,
	was_closed_ago,
	flag,
	LIMIT,
	num_active_days,
	market_price,
	collateral_id,
	price_date,
	days,
	discount_price,
	koeff,
	limit_car,
	red_lim,
	red_age,
	red_7days,
	red_dpd,
	is_red,
	is_green,
	is_blue,
	is_yellow,
	is_orange,
	score,
	score_date,
	[group],
	GUID,
	cred_hist_length,
	term_from_last_closed,
	last_int_rate,
	rbp_gr_action,
	last_name,
	first_name,
	middle_name,
	CRMClientGUID,
	ОсновнойТелефонКлиента,
	probation,
	probation_povt
	)
	select
	external_id,
	startdate,
	category,
	TYPE,
	main_limit,
	[Минимальный срок кредитования],
	[Ставка %],
	[Сумма платежа],
	[Рекомендуемая дата повторного обращения],
	fio,
	birth_date,
	Auto,
	vin,
	pos,
	rp,
	channel,
	doc_ser,
	doc_num,
	ТелефонМобильный,
	region_projivaniya,
	Berem_pt,
	Nalichie_pts,
	not_end,
	max_dpd_all,
	dod,
	was_closed_ago,
	flag,
	LIMIT,
	num_active_days,
	market_price,
	collateral_id,
	price_date,
	days,
	discount_price,
	koeff,
	limit_car,
	red_lim,
	red_age,
	red_7days,
	red_dpd,
	is_red,
	is_green,
	is_blue,
	is_yellow,
	is_orange,
	score,
	score_date,
	[group],
	GUID,
	cred_hist_length,
	term_from_last_closed,
	last_int_rate,
	rbp_gr_action,
	last_name,
	first_name,
	middle_name,
	CRMClientGUID,
	ОсновнойТелефонКлиента,
	probation,
	probation_povt
	from #povt_buffer_curr_collateral_total;

	insert into risk.povt_buffer_tmp
	select
	external_id,
	startdate,
	category,
	TYPE,
	main_limit,
	[Минимальный срок кредитования],
	[Ставка %],
	[Сумма платежа],
	[Рекомендуемая дата повторного обращения],
	fio,
	birth_date,
	Auto,
	vin,
	pos,
	rp,
	channel,
	doc_ser,
	doc_num,
	ТелефонМобильный,
	region_projivaniya,
	Berem_pt,
	Nalichie_pts,
	not_end,
	max_dpd_all,
	dod,
	was_closed_ago,
	flag,
	LIMIT,
	num_active_days,
	market_price,
	collateral_id,
	price_date,
	days,
	discount_price,
	koeff,
	limit_car,
	red_lim,
	red_age,
	red_7days,
	red_dpd,
	is_red,
	is_green,
	is_blue,
	is_yellow,
	is_orange,
	score,
	score_date,
	[group],
	GUID,
	cred_hist_length,
	term_from_last_closed,
	last_int_rate,
	rbp_gr_action,
	last_name,
	first_name,
	middle_name,
	CRMClientGUID,
	ОсновнойТелефонКлиента,
	probation,
	probation_povt
	from #povt_buffer_new_collateral_total;

COMMIT TRANSACTION;

drop table if exists #person_id;
drop table if exists #num_active_days;
drop table if exists #client_court_decisions;
drop table if exists #red_velocity;
drop table if exists #koeff_discount;
drop table if exists #app_person_decline;
drop table if exists #discount_price;
drop table if exists #credit_cur_rest_dpd;
drop table if exists #limit_car;
drop table if exists #cession;
drop table if exists #max_dpd_ever_person_id2;
drop table if exists #phones;
drop table if exists #probation;
drop table if exists #max_delta_active_70;
drop table if exists #max_dpd_da_70;
drop table if exists #max_dpd_cur_person_id2;
drop table if exists #pers_cur_rest;
drop table if exists #person_id2_num_closed;
drop table if exists #isinstallment;
drop table if exists #red_kk;
drop table if exists #isp_srok_clients;
drop table if exists #docredy_buffer;
drop table if exists #cli_base;
drop table if exists #src;
drop table if exists #final;
drop table if exists #koeff_discount_src;
drop table if exists #povt_buffer_curr_collateral;
drop table if exists #povt_buffer_curr_collateral_total;
drop table if exists #povt_buffer_new_collateral;
drop table if exists #povt_buffer_new_collateral_total;

END TRY

begin catch
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

	if @@TRANCOUNT>0
		rollback TRANSACTION;
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'ala.kurikalov@smarthorizon.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;

