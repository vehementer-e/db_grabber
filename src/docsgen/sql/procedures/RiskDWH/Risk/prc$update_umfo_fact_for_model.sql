CREATE procedure [Risk].[prc$update_umfo_fact_for_model] @rdt date = null

/**************************************************************************
Процедура для обновления факта из УМФО для прогнозной модели

Для расчета требуется срез в таблице dbo.nu_rates_calc_history_regs на @RDT - собирает Артем

Revisions:
dt			user				version		description
13/05/22	datsyplakov			v1.0		Создание процедуры
16/06/22	datsyplakov			v1.1		Изменен алгоритм отбора списаний (прощений) из УМФО
12/07/22	datsyplakov			v1.2		Добавлены платежи по бизнес-займам
											Добавлен дополнительный источник для списаний - ЦМР с начала действия дисконтного калькулятора (дек 2020)
13/08/22	datsyplakov			v1.3		Добавлен костыль на договор IoT 5млн, июнь 2022 - дубли по "ссылка"
03/02/23	datsyplakov			v1.4		Категория WP для не рассчитанного ПДН по инстолментам с выдачей 9000
14/06/23	datsyplakov			v1.5		Выделение категорий ПДН в банкротах
29/08/24	datsyplakov			v1.6		Добавлена заливка списаний и платежей после цессий беззалог risk.bezz_cess_reestr
15/11/24	datsyplakov			v1.7		Добавлено обновление срезов за последние 2 месяца в risk.stg_fcst_CMR_lite - укороченная копия dwh2.dbo.dm_cmrstatbalance

17/03/26	agolitsyn			v2.1		Все операции insert поля overdue_days_p заменены на isnull(a.overdue_days_p, 0)

*************************************************************************/


as 


	declare @srcname varchar(250) = 'UPDATE UMFO FACT for Forecast Model';
	declare @vinfo varchar(1000);


begin try


set @vinfo = 'START date_on = ' + convert(varchar, eomonth(@rdt), 120);

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

				



----------------------------------------------------------------------------------------------------------------------------
-- PART 1 Бизнес-займы
----------------------------------------------------------------------------------------------------------------------------

drop table if exists #bus_umfo;
select distinct r.Займ
into #bus_umfo
from stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr --[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr 
inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r --[c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r 
on r.ссылка=dr.ссылка 						
inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d --[c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d 
on r.Займ=d.ссылка	
and типклиентов <> 'ФЛ'
where d.ПометкаУдаления = 0
;



exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#bus_umfo';



drop table if exists #busines_loans;
select 
a.ссылка as ссылка, 
a.номердоговора as номердоговора,
a.Дата as Дата, 
a.СуммаЗайма as СуммаЗайма,
a.СрокЗайма as СрокЗайма,
a.СрокЗаймаПериодичность as СрокЗаймаПериодичность,
a.ПроцентнаяСтавка as ПроцентнаяСтавка
into #busines_loans
--from [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] a
from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный a
inner join (select distinct b.Займ from #bus_umfo b) b
on a.Ссылка = b.Займ
--13.08.2022 костыль договор IoT на 5 млн выданный в июне 2022 задублился
where a.Ссылка <> 0xA2E60050568397CF11ECEBC67B7FDA2D
--20.02.2023 костыль договор IoT на 5 млн выданный в июЛе 2022 задублился
and a.Ссылка <> 0xA2E60050568397CF11ECFE98358EE671


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#busines_loans';




drop table if exists #bus_cred_end_date;
select 
case 
when a.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7 
when a.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
else a.Займ end as Займ, 
min(dateadd(yyyy,-2000,cast(a.ДатаЗакрытия as date))) as end_date
into #bus_cred_end_date
from Stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a (nolock)
inner join (select distinct займ from #bus_umfo) b
--13.08.2022 костыль договор IoT на 5 млн выданный в июне 2022 задублился
on case 
when a.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7
when a.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
else a.Займ end = b.займ
where dateadd(yyyy,-2000,cast(a.ДатаЗакрытия as date)) <> '0001-01-01'
and a.ДатаОтчета <= dateadd(yy,2000,@rdt)
group by a.Займ
;



exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#bus_cred_end_date';



begin tran

delete from riskdwh.risk.stg_fcst_bus_cred;

set @vinfo = concat('stg_fcst_bus_cred deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


insert into riskdwh.risk.stg_fcst_bus_cred
select 
a.ссылка as zaim, 
a.номердоговора as nomerdogovora, 
--count(*) over (partition by a.Номердоговора) as cnt,
--ROW_NUMBER() over (partition by a.Номердоговора order by a.ссылка) as rown,
case 
	when a.Ссылка in (0xA2CA0050568397CF11EA5D33F0495D4A, 0xA2CA0050568397CF11EA5D348F11457B) then concat(a.НомерДоговора, '#1')
	when a.Ссылка in (0xA2D30050568397CF11EAE2E0FCDF9AB0, 0xA2D30050568397CF11EB150429512A71) then concat(a.НомерДоговора, '#2')
	when a.Ссылка = 0xA2E50050568397CF11ECE261F224784D then '4#1'
	when a.Ссылка in (0xA2E70050568397CF11ED0773F7197BFF, 0xA2E70050568397CF11ED0773377FB0FA) then concat(a.НомерДоговора, '#2')
	when a.ссылка = 0xA2E70050568397CF11ED2839F3ED7F6B then '8#2'
	when a.ссылка = 0xA2E70050568397CF11ED117EF5506FCD then '7#2'
	else a.Номердоговора
end as external_id,
DATEADD(yyyy, -2000, cast(a.Дата as date)) as credit_date,
eomonth(DATEADD(yyyy, -2000, cast(a.Дата as date))) as generation,
0 as flag_closed_in_month,
'other' as segment_rbp,

case 
when a.ссылка = 0xA2CA0050568397CF11EA5D348F11457B then cast('2020-01-31' as date)
when a.ссылка = 0xA2CA0050568397CF11EA5D3AB7A78E0C then cast('2020-02-29' as date)
when a.ссылка = 0xA2CA0050568397CF11EA5D33F0495D4A then cast('2020-02-29' as date)
when a.ссылка = 0xA2CD0050568397CF11EA72AE2A4FC127 then cast('2020-04-30' as date)
else isnull(c.end_date,cast('4444-01-01' as date)) 
end as end_date,
cast(a.СуммаЗайма as float) as amount,

a.СрокЗайма as srokzaima, 
case a.СрокЗаймаПериодичность 
when 0x8977E94A02613ED94F056B48851C9CF3 then 'days'
when 0x91746E7894AE8D1341B547A80378C78D then 'weeks'
when 0x8C9351E0903E73064E15492B2775C4AD then 'months'
when 0x9479EE93203F0A79410EFD11EEC18DD7 then 'years'
end as periodicity,

case 
when a.ссылка in (0xA2E70050568397CF11ED0773377FB0FA, 0xA2E70050568397CF11ED0773F7197BFF) then 3
when a.ссылка in (0xA2E60050568397CF11ECFE98358EE671, 0xA2E70050568397CF11ED117EF5506FCD) then 12
when a.СрокЗаймаПериодичность = 0x8C9351E0903E73064E15492B2775C4AD and a.СрокЗайма in (12,24,36,48) then a.СрокЗайма
when a.СрокЗаймаПериодичность = 0x8977E94A02613ED94F056B48851C9CF3 and a.СрокЗайма between 340 and 390 then 12
when a.СрокЗаймаПериодичность = 0x8977E94A02613ED94F056B48851C9CF3 and a.СрокЗайма between 705 and 755 then 24
when a.СрокЗаймаПериодичность = 0x8977E94A02613ED94F056B48851C9CF3 and a.СрокЗайма < 341 then 12
when a.СрокЗаймаПериодичность = 0x8C9351E0903E73064E15492B2775C4AD and a.СрокЗайма < 12 then 12
end as term,
cast(a.ПроцентнаяСтавка as float) as int_rate,
'BUSINESS' as flag_kk,
@rdt as date_on,
cast(getdate() as datetime) as dt_dml


from #busines_loans a
left join #bus_cred_end_date c
on a.ссылка = c.Займ

where eomonth(DATEADD(yyyy, -2000, cast(a.Дата as date))) <= @rdt;
;




set @vinfo = concat('stg_fcst_bus_cred inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

commit tran;


select @vinfo = concat('Cnt doubles by external_id in stg_fcst_bus_cred = ',count(*))
from (
	select a.external_id
	from riskdwh.risk.stg_fcst_bus_cred a
	group by a.external_id
	having count(*)>1
) a
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



--портфельные срезы

begin tran;

delete from RiskDWH.Risk.stg_fcst_bus_bal where mob_date = @rdt;


set @vinfo = concat('stg_fcst_bus_bal deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;




insert into RiskDWH.Risk.stg_fcst_bus_bal
select 
a.zaim,
a.external_id, 
a.generation,
a.term,
a.segment_rbp,
a.flag_kk,
dateadd(yyyy,-2000,cast(b.ДатаОтчета as date)) as mob_date,
DATEDIFF(MM, a.generation, dateadd(yyyy,-2000,cast(b.ДатаОтчета as date))) as mob,

RiskDWH.dbo.get_bucket_360_m(isnull(b.ДнейПросрочки,0)) as dpd_bucket_360,
cast(SUBSTRING(RiskDWH.dbo.get_bucket_360_m(isnull(b.ДнейПросрочки,0)),2,2) as int) as dpd_bucket_num_360,
RiskDWH.dbo.get_bucket_90(isnull(b.ДнейПросрочки,0)) as dpd_bucket_90,
cast(SUBSTRING(RiskDWH.dbo.get_bucket_90(isnull(b.ДнейПросрочки,0)),2,2) as int) as dpd_bucket_num_90,
isnull(b.ДнейПросрочки,0) as overdue_days,
cast(isnull(b.ОстатокОДвсего,0) as float) as principal_rest,
a.end_date,
@rdt as date_on,
cast(getdate() as datetime) as dt_dml

from RiskDWH.Risk.stg_fcst_bus_cred a
inner join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных b (nolock)
--on a.zaim = b.Займ
--13.08.2022 костыль договор IoT на 5 млн выданный в июне 2022 задублился
on a.zaim = case 
	when b.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7 
	when b.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
	else b.Займ end
--and dateadd(yyyy,-2000,cast(b.ДатаОтчета as date)) = EOMONTH(dateadd(yyyy,-2000,cast(b.ДатаОтчета as date)))
and dateadd(yyyy,-2000,cast(b.ДатаОтчета as date)) = @rdt
;


set @vinfo = concat('stg_fcst_bus_bal inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


with a as (select * from RiskDWH.Risk.stg_fcst_bus_bal)
delete from a where a.external_id in ('2#1','3#1','4','5') and a.mob_date > a.end_date and a.mob_date = @rdt;
;


update a set a.end_date = b.end_date
from RiskDWH.Risk.stg_fcst_bus_bal a
inner join RiskDWH.risk.stg_fcst_bus_cred b
on a.zaim = b.zaim
;


commit tran;






begin tran;

delete from RiskDWH.Risk.stg_fcst_bus_default;

set @vinfo = concat('stg_fcst_bus_default deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;




insert into RiskDWH.Risk.stg_fcst_bus_default
select a.zaim, a.external_id, min(dateadd(yyyy,-2000,cast(b.ДатаОтчета as date))) as dt_default_from,
@rdt as date_on,
cast(getdate() as datetime) as dt_dml
from RiskDWH.Risk.stg_fcst_bus_cred a
left join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных b (nolock)
--13.08.2022 костыль договор IoT на 5 млн выданный в июне 2022 задублился
on a.zaim = case 
	when b.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7 
	when b.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
	else b.Займ end
and b.ДатаОтчета <= dateadd(yy,2000,@rdt)
where b.ДнейПросрочки >= 91
group by a.zaim, a.external_id
;


set @vinfo = concat('stg_fcst_bus_default inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;




drop table #bus_cred_end_date;
drop table #bus_umfo;
drop table #busines_loans;



--~12min

----------------------------------------------------------------------------------------------------------------------------
-- PART 2 Списания УМФО
----------------------------------------------------------------------------------------------------------------------------


--declare @rdt date = '2022-03-31';



--списания и прощения из УМФО
--собираем все списания (прощения)
drop table if exists #stg1_umfo_writeoff;
select 
a.НомерДоговора as external_id, 
dateadd(yy,-2000, cast(a.ДатаОтчета as date)) as r_date,
a.ПричинаЗакрытияНаименование as close_reason,
СуммаСписанияПроцениты as int_wo,
СуммаСписанияПени as fee_wo,
СуммаПрощенияОсновнойДолг as od_forgive,
СуммаПрощенияПроценты as int_forgive,
СуммаПрощенияПени as fee_forgive

into #stg1_umfo_writeoff
from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a (nolock)
where isnull(a.ПричинаЗакрытияНаименование,'') <> ''
and a.ПричинаЗакрытияНаименование not in ('Закрытие долга залоговым имуществом','Признание задолженности безнадежной к взысканию','Служебная записка')
and ( СуммаСписанияПроцениты > 0
	or СуммаСписанияПени > 0
	or СуммаПрощенияОсновнойДолг > 0
	or СуммаПрощенияПроценты > 0
	or СуммаПрощенияПени > 0
)	
and a.ДатаОтчета <= dateadd(yy,2000,@rdt)
;

--вычисляем разность: текущая строка - предыдущая: так как сумма в таблице накапливается
drop table if exists #stg2_umfo_writeoff;
select a.external_id, a.r_date, a.close_reason,
a.int_wo - lag(a.int_wo,1,0) over (partition by a.external_id order by a.r_date) as int_wo,
a.fee_wo - lag(a.fee_wo,1,0) over (partition by a.external_id order by a.r_date) as fee_wo,
a.od_forgive - lag(a.od_forgive,1,0) over (partition by a.external_id order by a.r_date) as od_forgive,
a.int_forgive - lag(a.int_forgive,1,0) over (partition by a.external_id order by a.r_date) as int_forgive,
a.fee_forgive - lag(a.fee_forgive,1,0) over (partition by a.external_id order by a.r_date) as fee_forgive
into #stg2_umfo_writeoff
from #stg1_umfo_writeoff a
where 1=1
--and a.external_id = '20080310000118'
--and a.r_date < cast(getdate() as date)
;


--причесываем: избавляемся от отрицательных и оставляем только значимые (> 0)
drop table if exists #write_off_umfo;
with base as (
	select a.external_id, a.r_date, a.close_reason,
	case when a.int_wo < 0 then 0 else a.int_wo end as int_wo,
	case when a.fee_wo < 0 then 0 else a.fee_wo end as fee_wo,
	case when a.od_forgive < 0 then 0 else a.od_forgive end as od_forgive,
	case when a.int_forgive < 0 then 0 else a.int_forgive end as int_forgive,
	case when a.fee_forgive < 0 then 0 else a.fee_forgive end as fee_forgive
	from #stg2_umfo_writeoff a
)
select * 
into #write_off_umfo
from base a
where a.int_wo > 0 or a.fee_wo > 0 or a.od_forgive > 0 or a.int_forgive > 0 or a.fee_forgive > 0
;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#write_off_umfo';



--дополнительный источник со списаниями - МФО
drop table if exists #write_off__mfo_with_offer;

with base as (
	select distinct 
	cast(a.moment as date) as r_date, 
	a.external_id, 
	max(d.Наименование) over (partition by a.external_id, cast(a.moment as date)) as offer_name,
	cast(isnull(-1 * a.principal		, 0) as float) as od_writeoff,
	cast(isnull(-1 * a.percents			, 0) as float) as int_writeoff,
	cast(isnull(-1 * a.fines			, 0) as float) as fee_writeoff,
	cast(isnull(-1 * a.overpayment		, 0) as float) as over_writeoff,
	cast(isnull(-1 * a.other_payments	, 0) as float) as other_writeoff,

	cast(isnull(-1 * a.principal		, 0) as float) +
	cast(isnull(-1 * a.percents			, 0) as float) +
	cast(isnull(-1 * a.fines			, 0) as float) +
	cast(isnull(-1 * a.overpayment		, 0) as float) +
	cast(isnull(-1 * a.other_payments	, 0) as float) as total_writeoff

	from dwh_new.dbo.balance_wtiteoff a
	inner join stg._1cCMR.Справочник_Договоры b
	on a.external_id = b.Код
	inner join [Stg].[_1cCMR].[РегистрНакопления_АктивныеАкции] c
	on c.Договор = b.Ссылка
	and dateadd(year,-2000,cast(c.Период as date)) = cast(a.moment as date)
	inner join [Stg].[_1cCMR].[Справочник_Акции] d
	on c.Акция = d.Ссылка
	inner join dwh_new.dbo.tmp_v_credits t
	on a.external_id = t.external_id
	where not exists (select 1 from #write_off_umfo w
						where a.external_id = w.external_id)
)
select b.external_id, b.r_date, b.offer_name, 
sum(b.od_writeoff		) as od_writeoff	, 
sum(b.int_writeoff		) as int_writeoff	, 
sum(b.fee_writeoff		) as fee_writeoff	, 
sum(b.other_writeoff	) as other_writeoff, 
sum(b.over_writeoff		) as over_writeoff	, 
sum(b.total_writeoff	) as total_writeoff
into #write_off__mfo_with_offer
from base b
where b.r_date <= @rdt
group by b.external_id, b.r_date, b.offer_name
having sum(b.od_writeoff) > 0 or sum(b.int_writeoff) > 0
;



exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#write_off__mfo_with_offer';


drop table if exists #cmr_writeoff;
with base as (
	select a.external_id, a.d, 
	a.[основной долг уплачено] - a.[ОД уплачено без Сторно по акции] as od_wo,
	a.[Проценты уплачено] - a.[Проценты уплачено без Сторно по акции] as int_wo,
	a.ПениУплачено - a.[Пени уплачено без Сторно по акции] as fee_wo
	from dwh2.dbo.dm_CMRStatBalance a
)
select a.external_id, a.d, a.od_wo, a.int_wo, a.fee_wo
into #cmr_writeoff
from base a
where a.od_wo > 0
;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#cmr_writeoff';


--проверяем на дубли
select @vinfo = concat('Doubles in CMR od writeoffs = ', count(*)) 
from (
	select a.external_id
	from #cmr_writeoff a
	group by a.external_id
	having count(*)>1
) a

exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



--итоговый список списаний
begin tran;

delete from RiskDWH.Risk.stg_fcst_writeoff;

set @vinfo = concat('stg_fcst_writeoff deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



with base as (
	select a.external_id , a.r_date, a.od_forgive as od_wo, a.int_forgive + a.int_wo as int_wo
	from #write_off_umfo a
	union 
	select b.external_id, b.r_date, b.od_writeoff as od_wo, b.int_writeoff as int_wo
	from #write_off__mfo_with_offer b
)
insert into RiskDWH.Risk.stg_fcst_writeoff

select a.external_id, a.r_date, 
case 
when a.r_date < '2020-12-01' then a.od_wo --до диск калькулятора
when a.od_wo = 0 then isnull(b.od_wo,0) --в умфо нет списания по ОД
else a.od_wo end as od_wo,

case 
when a.r_date < '2020-12-01' then a.int_wo --до диск калькулятора
when a.od_wo = 0 and a.int_wo - isnull(b.od_wo,0) < 0 then a.int_wo --в умфо нет списания по ОД и дельта %%-ОД < 0
when a.od_wo = 0 then a.int_wo - isnull(b.od_wo,0) --в умфо нет списания по ОД
else a.int_wo end as int_wo,

@rdt as date_on, cast(getdate() as datetime) as dt_dml

from base a
left join #cmr_writeoff b
on a.external_id = b.external_id
--отличие дат не более 15 дней назад и 1 день вперед
and b.d between dateadd(dd,-15,a.r_date) and dateadd(dd,1,a.r_date)
where not exists (select 1 from risk.bezz_cess_reestr c where a.external_id = c.external_id)


--insert into RiskDWH.Risk.stg_fcst_writeoff
--select b.external_id, b.r_date, b.od_wo, b.int_wo, @rdt as date_on, cast(getdate() as datetime) as dt_dml
--from base b
;

set @vinfo = concat('stg_fcst_writeoff inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



--списания беззалог с апреля 2024
insert into RiskDWH.Risk.stg_fcst_writeoff
select a.external_id, a.cess_dt as r_date,
a.cess_wo_od as od_wo,
a.cess_wo_int as int_wo, 
@rdt as date_on, cast(getdate() as datetime) as dt_dml

from risk.bezz_cess_reestr a
where a.cess_dt <= @rdt;




commit tran;



drop table #write_off__mfo_with_offer;
drop table #write_off_umfo;
drop table #stg1_umfo_writeoff;
drop table #stg2_umfo_writeoff;
drop table #cmr_writeoff;

--~4min







----------------------------------------------------------------------------------------------------------------------------
-- PART 3 Портфель УМФО
----------------------------------------------------------------------------------------------------------------------------

--declare @rdt date = '2022-03-31';

--Банкроты

drop table if exists #stg_bankrupt;
select a.Контрагент as contragent,
min(cast(dateadd(yy,-2000,a.дата) as date)) as dt
into #stg_bankrupt
--from [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_БанкротствоЗаемщика] a
from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
group by a.Контрагент;


drop table if exists #bankrupt;
select distinct a.Ссылка as ssylka, b.dt, a.НомерДоговора as external_id
into #bankrupt
from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный a
inner join #stg_bankrupt b
on a.Контрагент = b.contragent
where a.НомерДоговора <> '1'
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#bankrupt';




--ЗаймПред

drop table if exists #stg_umfo;
with base1 as (
	select 
	dateadd(yy,-2000,cast(a.ДатаОтчета as date)) as r_date,
	--13.08.2022 костыль IoT 5млн июнь 2022
	case 
	when a.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7 
	when a.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
	else a.Займ end as zaim,

	case 
	when a.Займ in (0xA2CA0050568397CF11EA5D33F0495D4A, 0xA2CA0050568397CF11EA5D348F11457B) then concat(a.НомерДоговора, '#1')
	when a.Займ in (0xA2D30050568397CF11EAE2E0FCDF9AB0, 0xA2D30050568397CF11EB150429512A71) then concat(a.НомерДоговора, '#2')
	when a.Займ = 0xA2E50050568397CF11ECE261F224784D then '4#1'
	when a.Займ in (0xA2E70050568397CF11ED0773F7197BFF, 0xA2E70050568397CF11ED0773377FB0FA) then concat(a.НомерДоговора, '#2')
	when a.Займ = 0xA2E70050568397CF11ED2839F3ED7F6B then '8#2'
	when a.Займ = 0xA2E70050568397CF11ED117EF5506FCD then '7#2'
	else a.Номердоговора
	end as external_id, 
	cast(a.СуммаЗайма as float) as amount,
	case when a.ДатаОтчета >= '4021-08-01' then a.ДнейПросрочкиДляРезервов else a.ДнейПросрочки end as dpd, 
	a.ГруппаРВПЗ as RVPZ_group,
	cast(isnull(a.ОстатокОДвсего,0) as float) as total_od,
	cast(isnull(a.ОстатокПроцентовВсего,0) as float) as total_int,
	cast(isnull(a.ОстатокПени,0) as float) as total_fee,
	cast(isnull(a.ОстатокОДвсего,0) as float) + cast(isnull(a.ОстатокПроцентовВсего,0) as float) + cast(isnull(a.ОстатокПени,0) as float) as total_gross,
	cast(isnull(a.ОстатокРезерв,0) as float) as prov_BU_gross,
	cast(isnull(a.ОстатокРезервНУ,0) as float) as prov_NU_gross
	from (
		select p.*
			, ROW_NUMBER() over(partition by Номердоговора, ДатаОтчета order by займ) as row_nn
		from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных p (nolock)
		where 1=1
		and p.ДатаОтчета = dateadd(yy,2000,@rdt)
		) a where a.row_nn = 1
), base2 as (
	select a.r_date, a.zaim, a.external_id, a.amount,
	a.dpd, a.RVPZ_group,
	a.total_od, a.total_int, a.total_fee, a.total_gross,
	case when a.total_gross = 0 then 0.0 else a.prov_BU_gross / a.total_gross end as rate_BU,
	a.prov_BU_gross,
	case when a.total_gross = 0 then 0.0 else a.prov_NU_gross / a.total_gross end as rate_NU,
	a.prov_NU_gross
	from base1 a
)
select a.r_date, a.zaim, a.external_id, a.amount,
a.dpd, a.RVPZ_group,
a.total_od, a.total_int, a.total_fee, a.total_gross,	
a.total_od * a.rate_BU as prov_BU_od,
a.total_int * a.rate_BU as prov_BU_int,
a.total_fee * a.rate_BU as prov_BU_fee,
a.prov_BU_gross,
a.total_od * a.rate_NU as prov_NU_od,
a.total_int * a.rate_NU as prov_NU_int,
a.total_fee * a.rate_NU as prov_NU_fee,
a.prov_NU_gross
into #stg_umfo
from base2 a
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_umfo';



--Определение сегмента для нормативного (НУ) резерва 
begin tran;

delete from RiskDWH.risk.stg_fcst_umfo where r_date = @rdt;


set @vinfo = concat('stg_fcst_umfo deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;




with base as (
	select a.*, 
	--case when b.ssylka is not null then 1 else 0 end as flag_bankrupt,
	case when d.flag_bnkr = 1 then 1 else 0 end as flag_bankrupt,

	--case when a.RVPZ_group in ('Займ реструктурированный необеспеченный','Займ реструктурированный обеспеченный') then 'R' else 'NR' end as flag_restruct,
	case when d.flag_restruct = 1 then 'R' else 'NR' end as flag_restruct,
	--case when c.pdn > 0.5 then 'P' else 'NP' end as flag_pdn_more_05,
	case 
		when c.pdn <= 0.5 then 'NP'
		when c.pdn <= 0.8 then 'P1' 
		when c.pdn > 0.8 then 'P2'	
		when c.pdn is null and a.amount < 10000 and cr.IsInstallment = 1 then 'WP' --03.02.2023 - для IL с выдачей 9000 --14.06.2023 < 10тыс
		else 'NP' end
	as flag_pdn_more_05, --13.04.2022 выделение ПДН > 80%
	
	--case when nc.external_id is null then 'C' else 'NC' end as flag_collaterised,
	case when d.flag_collateralized_new = 1 then 'C' else 'NC' end as flag_collaterised,
	
	case when bu.zaim is not null then 1 else 0 end as flag_corp
	
	from #stg_umfo a
	left join #bankrupt b
	on a.zaim = b.ssylka
	and a.r_date >= b.dt
	--left join stg._loginom.pdn_calculation_2gen_stg c
	--on a.external_id = cast(c.Number as varchar(100))
	--left join [C2-VSR-LSQL].[loginomdb].[dwh].[PDN_calculation_gen2] c
	--on a.external_id = cast(c.Number as varchar)
	--left join stg._loginom.pdn_calculation_2gen_stg c
	--left join dwh2.risk.pdn_calculation_2gen c --изменили в рамках задачи - DWH-2205
	--	on a.external_id = cast(c.Number as varchar(100))

	--для прогноза поставили ПДН на отчётную дату
	left join	(
				select p.dogNum as Number
					, case when s.external_id is not null or UPPER(p.nomenkGroup) like UPPER('ПТС Займ для Самозанятых') then 0 else PDNOnRepDate end
						as pdn
				from dwh2.[finAnalytics].[PBR_MONTHLY] p
				left join RiskDWH.risk.Samozan_Reestr s on p.dogNum = s.external_id
				where eomonth(repmonth) = @rdt and dogStatus = 'Действует'
				) c --поменяли источник
		on a.external_id = cast(c.Number as varchar(100))

	left join riskdwh.[cm\a.borisov].spr_non_collaterised_311220_v4 nc
	on a.external_id = nc.external_id
	left join RiskDWH.Risk.stg_fcst_bus_cred bu
	on a.zaim = bu.zaim
	left join (select a.r_date, a.vers, a.external_id, 
		max(a.flag_bnkr) as flag_bnkr, 
		max(a.flag_restruct) as flag_restruct, 
		max(a.flag_collateralized_new) as flag_collateralized_new
		from dbo.nu_rates_calc_history_regs  a
		group by a.r_date, a.vers, a.external_id
	) d
	on a.external_id = d.external_id
	and a.r_date = d.r_date
	--and d.vers = 3 --!!!
	and d.vers = (select max(vers) from dbo.nu_rates_calc_history_regs where r_date = @rdt)
	left join dwh2.risk.credits cr
	on a.external_id = cr.external_id
)
insert into RiskDWH.risk.stg_fcst_umfo

select a.r_date, a.zaim, a.external_id, a.amount, a.dpd,
a.total_od, a.total_int, a.total_fee, a.total_gross,
a.prov_BU_od, a.prov_BU_int, a.prov_BU_fee, a.prov_BU_gross,
a.prov_NU_od, a.prov_NU_int, a.prov_NU_fee, a.prov_NU_gross,
case 
when a.flag_bankrupt = 1 and a.flag_pdn_more_05 = 'P1' then 'BANKRUPT_P1'
when a.flag_bankrupt = 1 and a.flag_pdn_more_05 = 'P2' then 'BANKRUPT_P2'
when a.flag_bankrupt = 1 and a.flag_pdn_more_05 = 'WP' then 'BANKRUPT_WP'
when a.flag_bankrupt = 1 then 'BANKRUPT'
when a.flag_corp = 1 then 'UL'
else concat(a.flag_pdn_more_05,'_', a.flag_restruct,'_', a.flag_collaterised)
end as NU_segment,
@rdt as date_on,
cast(getdate() as datetime) as dt_dml
from base a 
;


set @vinfo = concat('stg_fcst_umfo inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;




drop table #bankrupt;
drop table #stg_bankrupt;


----------------------------------------------------------------------------------------------------------------------------
-- PART 4 Историческая просрочка
----------------------------------------------------------------------------------------------------------------------------

--declare @rdt date = '2022-03-31';


/*
	delete from RiskDWH.Risk.stg_fcst_hist_dpd where r_date = @rdt;

	insert into RiskDWH.Risk.stg_fcst_hist_dpd
	select dateadd(yy,-2000,cast(a.ДатаОтчета as date)) as r_date,
	a.НомерДоговора as external_id, 
	a.ДнейПросрочкиДляРезервов as dpd_hist
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a (nolock)
	where a.ДатаОтчета = dateadd(yy,2000,@rdt)
*/


begin tran;
	
	delete from RiskDWH.Risk.stg_fcst_hist_dpd where r_date = @rdt;

	set @vinfo = concat('stg_fcst_hist_dpd deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



	insert into RiskDWH.Risk.stg_fcst_hist_dpd
	select 
	a.r_date,
	a.external_id,
	a.dpd,
	@rdt as date_on,
	cast(getdate() as datetime) as dt_dml
	from #stg_umfo a
	where a.r_date = @rdt
	;

	set @vinfo = concat('stg_fcst_hist_dpd inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;





----------------------------------------------------------------------------------------------------------------------------
-- PART 5 Платежи из МФО
----------------------------------------------------------------------------------------------------------------------------

--declare @rdt date = '2022-03-31';


begin tran;

delete from RiskDWH.Risk.stg_fcst_payment where cdate between EOMONTH(@rdt,-3) and @rdt;

set @vinfo = concat('stg_fcst_payment deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


insert into RiskDWH.Risk.stg_fcst_payment
select a.external_id, a.cdate, isnull(a.overdue_days_p, 0) as overdue_days_p, 
cast(isnull(a.percents_cnl,0) as float) as percents_cnl,
cast(isnull(a.principal_cnl,0) as float) as principal_cnl,
cast(isnull(a.fines_cnl,0) as float) as fines_cnl,
cast(isnull(a.otherpayments_cnl,0) as float) as other_cnl,
@rdt as date_on, 
cast(getdate() as datetime) as dt_dml 
from (select external_id, d as cdate, dpd_p_coll as overdue_days_p, percents_cnl, principal_cnl, fines_cnl, otherpayments_cnl
	from dwh2.dbo.dm_CMRStatBalance) a
--from dwh_new.dbo.stat_v_balance2 a
where (a.percents_cnl > 0 or a.principal_cnl > 0 or a.fines_cnl > 0 or a.otherpayments_cnl > 0)
and a.cdate between EOMONTH(@rdt,-3) and @rdt
;


set @vinfo = concat('stg_fcst_payment inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;





--выручка от цессий беззалог
begin tran;



with a as (select * from RiskDWH.Risk.stg_fcst_payment)
delete from a
where exists (select 1 from risk.bezz_cess_reestr b where a.external_id = b.external_id and a.cdate >= b.cess_dt)
;



insert into RiskDWH.Risk.stg_fcst_payment
select 
a.external_id, 
a.cess_dt as cdate, 
isnull(b.[dpd day-1], 0) as overdue_days_p, 
isnull(a.cess_rev_int,0) as percents_cnl,
isnull(a.cess_rev_od,0) as principal_cnl,
isnull(a.cess_rev_fines,0) as fines_cnl,
0 as other_cnl,
@rdt as date_on, 
cast(getdate() as datetime) as dt_dml 

from risk.bezz_cess_reestr a
left join dwh2.dbo.dm_CMRStatBalance b
on a.external_id = b.external_id
and a.cess_dt = b.d
where a.cess_dt <= @rdt
;


set @vinfo = concat('stg_fcst_payment inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;








drop table if exists #stg_business_payment;
with cred_and_dt as (
	select a.zaim, a.external_id, a.credit_date as r_date
	from risk.stg_fcst_bus_cred a 
	where a.credit_date <> eomonth(a.credit_date)
union 
	select a.zaim, a.external_id, cast(b.dt as date) as r_date
	from risk.stg_fcst_bus_cred a
	inner join dwh2.risk.calendar b
	on b.dt between a.generation and iif(a.end_date = '4444-01-01', @rdt, a.end_date)
	and b.dt = eomonth(b.dt)
union 
	select a.zaim, a.external_id, a.end_date as r_date
	from risk.stg_fcst_bus_cred a
	where a.end_date < '4444-01-01'
	and a.end_date <> eomonth(a.end_date)
)
select a.zaim, a.external_id, a.r_date, 
b.ОплаченоВсего as od_pmt_acc,
b.ПроцентыОплачено as int_pmt_acc,
b.ПениОплачено as fee_pmt_acc
into #stg_business_payment
from cred_and_dt a 
left join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных b
--on a.zaim = b.Займ
--13.08.2022 костыль договор IoT на 5 млн выданный в июне 2022 задублился
on a.zaim = case 
	when b.Займ = 0xA2E60050568397CF11ECEBC67B7FDA2D then 0xA2E70050568397CF11ED12DE071C5DA7 
	when b.Займ = 0xA2E60050568397CF11ECFE98358EE671 then 0xA2E80050568397CF11ED2DADBE1A4EE8
	else b.Займ end
and dateadd(yy,2000,a.r_date) = b.ДатаОтчета
;

begin tran;

with base as (
	select a.zaim, a.external_id, a.r_date,
	a.od_pmt_acc - lag(a.od_pmt_acc,1,0) over (partition by a.zaim order by a.r_date) as od_pmt,
	a.int_pmt_acc - lag(a.int_pmt_acc,1,0) over (partition by a.zaim order by a.r_date) as int_pmt,
	a.fee_pmt_acc - lag(a.fee_pmt_acc,1,0) over (partition by a.zaim order by a.r_date) as fee_pmt
	from #stg_business_payment a
)
insert into risk.stg_fcst_payment

select 
a.external_id, 
a.r_date as cdate, 
-1 as overdue_days_p,
a.int_pmt as percents_cnl,
a.od_pmt as principal_cnl,
a.fee_pmt as fines_cnl,
0 as other_cnl,
@rdt as date_on,
cast(getdate() as datetime) as dt_dml
from base a
where a.od_pmt + a.int_pmt + a.fee_pmt > 0
and a.r_date between EOMONTH(@rdt,-3) and @rdt
;


set @vinfo = concat('stg_fcst_payment BUSINESS inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


commit tran;


drop table #stg_business_payment;
drop table #stg_umfo;

----------------------------------------------------------------------------------------------------------------------------
-- PART 6 Портфель ЦМР
----------------------------------------------------------------------------------------------------------------------------


begin tran;

delete from risk.stg_fcst_CMR_lite where d between EOMONTH(@rdt,-2) and @rdt;

set @vinfo = concat('stg_fcst_CMR_lite deleted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

insert into risk.stg_fcst_CMR_lite
select 
a.external_id, 
a.d, 
a.[остаток од], 
a.dpd, 
a.[Проценты начислено  нарастающим итогом] 
from dwh2.dbo.dm_cmrstatbalance a
where a.d between EOMONTH(@rdt,-2) and @rdt
;

set @vinfo = concat('stg_fcst_CMR_lite inserted Rowcnt = ', @@ROWCOUNT); exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

commit tran;


----------------------------------------------------------------------------------------------------------------------------
-- PART FINAL Проверки
----------------------------------------------------------------------------------------------------------------------------




select @vinfo = concat('COUNT OD=0 %%>0 PTS = ', count(*), ', INT = ', format(sum(a.total_int),'### ### ### ###'))
from risk.stg_fcst_umfo a
where a.r_date = @rdt
and exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.IsInstallment = 0)
and a.total_od = 0 and a.total_int > 0;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;




select @vinfo = concat('COUNT OD=0 %%>0 INST = ', count(*), ', INT = ', format(sum(a.total_int),'### ### ### ###'))
from risk.stg_fcst_umfo a
where a.r_date = @rdt
and exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.credit_type_init = 'INST')
and a.total_od = 0 and a.total_int > 0;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


select @vinfo = concat('COUNT OD=0 %%>0 PDL = ', count(*), ', INT = ', format(sum(a.total_int),'### ### ### ###'))
from risk.stg_fcst_umfo a
where a.r_date = @rdt
and exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.credit_type_init = 'PDL')
and a.total_od = 0 and a.total_int > 0;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';


EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
	,@recipients =  'Александр Голицын <a.golicyn@carmoney.ru>; Тимур Сулейманов <t.sulejmanov@carmoney.ru>'
	,@body = 'Процедура [Risk].[prc$update_umfo_fact_for_model] отработала'
	,@body_format = 'TEXT'
	,@subject = 'Обновились STG_FCST_* objects';

end try 


begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
