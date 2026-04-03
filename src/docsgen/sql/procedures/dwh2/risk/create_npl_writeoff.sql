CREATE procedure [risk].[create_npl_writeoff] as 
begin
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
--exec risk.create_npl_writeoff
BEGIN TRY
------------------------
------списания MFO------
------------------------
declare @rdt date = '2016-06-29';
------------------------------забираем списания ОД и % из MFO
drop table if exists #stg1_umfo_writeoff;
select 
a.НомерДоговора as external_id
,dateadd(yy,-2000, cast(a.ДатаОтчета as date)) as r_date
,a.ПричинаЗакрытияНаименование as close_reason
,СуммаСписанияПроцениты as int_wo
,СуммаСписанияПени as fee_wo
,СуммаПрощенияОсновнойДолг as od_forgive
,СуммаПрощенияПроценты as int_forgive
,СуммаПрощенияПени as fee_forgive
into #stg1_umfo_writeoff
from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a (nolock)
inner join risk.credits credits
	on a.НомерДоговора = credits.external_id
where isnull(a.ПричинаЗакрытияНаименование,'') <> ''
and a.ПричинаЗакрытияНаименование not in ('Закрытие долга залоговым имуществом','Признание задолженности безнадежной к взысканию','Служебная записка')
and (СуммаСписанияПроцениты > 0
	or СуммаСписанияПени > 0
	or СуммаПрощенияОсновнойДолг > 0
	or СуммаПрощенияПроценты > 0
	or СуммаПрощенияПени > 0
	)
and ОтчетнаяДата > @rdt
;
----------------------------вычисляем разность: текущая строка - предыдущая: так как сумма накапливается
drop table if exists #stg2_umfo_writeoff;
select 
a.external_id
,a.r_date
,a.close_reason
,a.int_wo - lag(a.int_wo,1,0) over (partition by a.external_id order by a.r_date) as int_wo
,a.fee_wo - lag(a.fee_wo,1,0) over (partition by a.external_id order by a.r_date) as fee_wo
,a.od_forgive - lag(a.od_forgive,1,0) over (partition by a.external_id order by a.r_date) as od_forgive
,a.int_forgive - lag(a.int_forgive,1,0) over (partition by a.external_id order by a.r_date) as int_forgive
,a.fee_forgive - lag(a.fee_forgive,1,0) over (partition by a.external_id order by a.r_date) as fee_forgive
into #stg2_umfo_writeoff
from #stg1_umfo_writeoff a
where a.r_date < cast(getdate() as date)
;
------------------------причесываем: избавляемся от отрицательных и оставляем только значимые (> 0)
drop table if exists #write_off_umfo;
with base as (
	select 
	a.external_id
	, a.r_date
	, a.close_reason
	,case when a.int_wo < 0 then 0 else a.int_wo end int_wo
	,case when a.fee_wo < 0 then 0 else a.fee_wo end fee_wo
	,case when a.od_forgive < 0 then 0 else a.od_forgive end od_forgive
	,case when a.int_forgive < 0 then 0 else a.int_forgive end int_forgive
	,case when a.fee_forgive < 0 then 0 else a.fee_forgive end fee_forgive
	from #stg2_umfo_writeoff a
)
select * 
into #write_off_umfo
from base
where base.int_wo > 0 
or base.fee_wo > 0 
or base.od_forgive > 0 
or base.int_forgive > 0 
or base.fee_forgive > 0
;
------------------------
drop table if exists #write_off__mfo_with_offer;
with base2 as (
	select 
	distinct cast(a.moment as date) as r_date
	,a.external_id
	,max(act.Наименование) over (partition by a.external_id, cast(a.moment as date)) as offer_name
	,cast(isnull(-1 * a.principal, 0) as float) as od_writeoff
	,cast(isnull(-1 * a.percents, 0) as float) as int_writeoff
	,cast(isnull(-1 * a.fines, 0) as float) as fee_writeoff
	,cast(isnull(-1 * a.overpayment, 0) as float) as over_writeoff
	,cast(isnull(-1 * a.other_payments, 0) as float) as other_writeoff

	,cast(isnull(-1 * a.principal, 0) as float) +
	cast(isnull(-1 * a.percents, 0) as float) +
	cast(isnull(-1 * a.fines, 0) as float) +
	cast(isnull(-1 * a.overpayment, 0) as float) +
	cast(isnull(-1 * a.other_payments, 0) as float) as total_writeoff

	from dwh_new.dbo.balance_wtiteoff a
	inner join stg._1cCMR.Справочник_Договоры dogs
		on a.external_id = dogs.Код
	inner join [Stg].[_1cCMR].[РегистрНакопления_АктивныеАкции] a_act
		on a_act.Договор = dogs.Ссылка
		and dateadd(year,-2000,cast(a_act.Период as date)) = cast(a.moment as date)
	inner join [Stg].[_1cCMR].[Справочник_Акции] act
		on a_act.Акция = act.Ссылка
	inner join risk.credits credits
		on a.external_id = credits.external_id
	where not exists (select 1 from #write_off_umfo w where a.external_id = w.external_id)
)
select 
base2.external_id
,base2.r_date
,base2.offer_name
,sum(base2.od_writeoff) as od_writeoff
,sum(base2.int_writeoff) as int_writeoff
,sum(base2.fee_writeoff) as fee_writeoff
,sum(base2.other_writeoff) as other_writeoff
,sum(base2.over_writeoff) as over_writeoff
,sum(base2.total_writeoff) as total_writeoff
into #write_off__mfo_with_offer
from base2
group by base2.external_id, base2.r_date, base2.offer_name
having sum(base2.od_writeoff) > 0  
or sum(base2.int_writeoff) > 0
;
-------------------------итоговый список списаний MFO
drop table if exists #mfo_write_off;
with base3 as (
	select 
	mfo.external_id
	,mfo.r_date
	,isnull(mfo.od_forgive,0) as od_wo
	,isnull(mfo.int_forgive,0) + isnull(mfo.int_wo,0) as int_wo
	from #write_off_umfo mfo

	union 

	select 
	mfo_of.external_id
	,mfo_of.r_date
	,mfo_of.od_writeoff as od_wo
	,mfo_of.int_writeoff as int_wo
	from #write_off__mfo_with_offer mfo_of
)
select 
base3.external_id
,base3.r_date
,sum(isnull(base3.od_wo,0)) as od_wo
,sum(isnull(base3.int_wo,0)) as int_wo
into #mfo_write_off
from base3
group by base3.external_id, base3.r_date
;
------------------------
------списания CMR------
------------------------

------------------------------забираем списания ОД из ЦМР (сторно)
drop table if exists #cmr_writeoff;
select 
stbal.external_id
,stbal.d
,stbal.[основной долг уплачено] - stbal.[ОД уплачено без Сторно по акции] as od_wo
into #cmr_writeoff
from dbo.dm_CMRStatBalance stbal
where (stbal.[основной долг уплачено] - stbal.[ОД уплачено без Сторно по акции]) > 0
;
------------------соединяем списания УМФО и ЦМР
drop table if exists #stg_write_off;
select 
mfo.external_id
--,mfo.r_date
,eomonth(mfo.r_date) as r_date_month_end
,case 
	when mfo.r_date < '2020-12-01' then mfo.od_wo --до диск калькулятора
	when mfo.od_wo = 0 then isnull(cmr.od_wo,0) --в умфо нет списания по ОД
	else mfo.od_wo 
	end od_wo
	
,case 
	when mfo.r_date < '2020-12-01' then mfo.int_wo --до диск калькулятора
	when mfo.od_wo = 0 and mfo.int_wo - isnull(cmr.od_wo,0) < 0 then mfo.int_wo --в умфо нет списания по ОД и дельта %%-ОД < 0
	when mfo.od_wo = 0 then mfo.int_wo - isnull(cmr.od_wo,0) --в умфо нет списания по ОД
	else mfo.int_wo 
	end int_wo
	
into #stg_write_off
from #mfo_write_off mfo
left join #cmr_writeoff cmr
	on mfo.external_id = cmr.external_id
	--отличие дат не более 15 дней назад и 1 день вперед
	and cmr.d between dateadd(dd,-15,mfo.r_date) and dateadd(dd, 1, mfo.r_date)
;
--суммирование списаний в рамках месяца
drop table if exists #stg_write_off_total;
select 
distinct external_id
,r_date_month_end
,sum(od_wo) as od_wo
,sum(int_wo) as int_wo
into #stg_write_off_total
from #stg_write_off
group by
external_id
,r_date_month_end
;
----------------------------------выборка для npl_90
drop table if exists #npl_src;
select 
d
,eomonth(d) as d_month_end
,external_id
,contractStartdate
,max(d) over (partition by external_id) as date_closed
,cast([сумма] as money) as credit_amount
,creditmonths
,concat(year(contractStartdate),' ',month(contractStartdate)) as vintage
,case 
	when ContractEndDate is not null and ContractEndDate <= d then 1
	else 0
	end closed
,dpd_coll
,dpd_p_coll
,case 
	when [остаток од] < 0.01 or (ContractEndDate is not null and ContractEndDate <= d) then 0
	else cast(isnull([остаток од], 0) as money) 
	end [остаток од]
into #npl_src
from dbo.dm_CMRStatBalance st
where d < dateadd(dd, - 1, cast(getdate() as date))
and d >= '2025-01-01'
;
----------------------------------свод
drop table if exists #total;
select 
npl_src.external_id
,npl_src.contractStartdate
,npl_src.credit_amount
,npl_src.creditmonths
,npl_src.vintage
,npl_src.closed
,npl_src.dpd_coll
,npl_src.dpd_p_coll
,npl_src.[остаток од]
,swo.od_wo
,swo.int_wo
,case when npl_src.dpd_p_coll > 90 then npl_src.[остаток од] else 0 end npl_90
into #total
from #npl_src npl_src
left join #stg_write_off_total swo
	on npl_src.external_id = swo.external_id
	and npl_src.d_month_end = swo.r_date_month_end
where npl_src.d = eomonth(npl_src.d) 
or npl_src.d = npl_src.date_closed
;
----------------------------------внесение
if OBJECT_ID('risk.npl_writeoff') is null
begin
	select top(0) * into risk.npl_writeoff
	from #total
end;

BEGIN TRANSACTION

	merge into risk.npl_writeoff tow
	using #total total
		on tow.external_id = total.external_id
		and tow.creditmonths = total.creditmonths
	when matched then update set 
	tow.closed = total.closed,
	tow.dpd_coll = total.dpd_coll,
	tow.[остаток од] = total.[остаток од],
	tow.od_wo = total.od_wo,
	tow.int_wo = total.int_wo,
	tow.npl_90 = total.npl_90
	when not matched then 
	insert (
	external_id
	,contractStartdate
	,credit_amount
	,creditmonths
	,vintage
	,closed
	,dpd_coll
	,dpd_p_coll
	,[остаток од]
	,od_wo
	,int_wo
	,npl_90) 
	values (
	total.external_id
	,total.contractStartdate
	,total.credit_amount
	,total.creditmonths
	,total.vintage
	,total.closed
	,total.dpd_coll
	,total.dpd_p_coll
	,total.[остаток од]
	,total.od_wo
	,total.int_wo
	,total.npl_90)
	;
COMMIT TRANSACTION;

drop table if exists #stg1_umfo_writeoff;
drop table if exists #stg2_umfo_writeoff;
drop table if exists #write_off_umfo;
drop table if exists #write_off__mfo_with_offer;
drop table if exists #mfo_write_off;
drop table if exists #cmr_writeoff;
drop table if exists #stg_write_off;
drop table if exists #stg_write_off_total;
drop table if exists #npl_src;
drop table if exists #total;

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