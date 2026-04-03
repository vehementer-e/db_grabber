/*****************************************************************************************************************
Процедура для расчета фактических списаний, а также плановых досозданий БУ и плановых списаний


Revisions:
dt			user				version		description
24/09/24	datsyplakov			v1.0		Создание процедуры
09/10/24	datsyplakov			v1.1		Добавлен расчет процентых начислений и досоздание НУ
07/11/24	datsyplakov			v1.2		Добавлен расчет плановых списаний по цессиям беззалога

*****************************************************************************************************************/


CREATE procedure [Risk].[prc$calc_plan_fact_prov_writeoff]
--отчетная дата
@rdt date,
--это версия для функции risk.func$forecast_for_finance_all, которая содержит консолидированную простыню из разных продуктов
@budget_vers int

as 

declare @info varchar(1000);

begin try

	declare @srcname varchar(100) = 'CALC FACT WRITEOFFs and PLAN PROVISIONs AND WRITEOFFs';

	set @info = concat('START rdt ', 
					format(@rdt,'dd.MM.yyyy') ,
					' , budget VIEW vers ' , format(@budget_vers,'###')
					)	
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'LITE_СЗД_ПоказателиЗаймовПредоставленных';


	drop table if exists #pokaz_zaimov;
	select НомерДоговора, ДатаОтчета, 
	ОстатокОДвсего, ОстатокПроцентовВсего, ОстатокПени,
	ПричинаЗакрытияНаименование,
	СуммаСписанияПени, СуммаСписанияПроцениты,
	СуммаПрощенияОсновнойДолг, СуммаПрощенияПроценты, СуммаПрощенияПени, ПроцентыНачислено
	into #pokaz_zaimov
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a with (nolock)
	where a.ДатаОтчета between dateadd(yy,2000,eomonth(@rdt,-1)) and dateadd(yy,2000,@rdt)
	;


	/*

	select a.ДатаОтчета, count(*)
	from #pokaz_zaimov a
	group by a.ДатаОтчета
	order by 1

	*/

	/*

	select distinct a.ДатаОтчета, a.ДатаПересчета 
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a with (nolock)
	where a.ДатаОтчета between '4024-06-30' and '4024-07-31'
	order by 1

	*/



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into risk.prov_stg_check_wo';

	begin transaction;


		delete from risk.prov_stg_check_wo where r_date = @rdt;



		--Плановые списания и досодзания за период из бюджета
		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml,
		concat('[01] План (дельта баланс БУ) v = ',@budget_vers) as descr,
		(	
			select sum(a.provision_od_int_BU) as BU
			from risk.func$forecast_for_finance_all(@budget_vers) a
			where a.r_date = @rdt
		) - (
			select sum(a.provision_od_int_BU) as BU
			from risk.func$forecast_for_finance_all(@budget_vers) a
			where a.r_date = eomonth(@rdt,-1)
		) as val
		;



		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml,
		concat('[12] План (дельта баланс НУ) v = ',@budget_vers) as descr,
		(	
			select sum(a.provision_od_int_NU) as NU
			from risk.func$forecast_for_finance_all(@budget_vers) a
			where a.r_date = @rdt
		) - (
			select sum(a.provision_od_int_NU) as NU
			from risk.func$forecast_for_finance_all(@budget_vers) a
			where a.r_date = eomonth(@rdt,-1)
		) as val
		;



		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml,  
		concat('[02] Списания план v = ',@budget_vers) as descr,
		sum(isnull(a.od_writeoff,0) + isnull(a.int_writeoff,0)) as val 
		from risk.func$forecast_for_finance_all(@budget_vers) a
		where a.r_date = @rdt
		;

		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml,  
		concat('[02] Списания план (цессия беззалог) v = ',@budget_vers) as descr,
		sum(isnull(a.od_writeoff,0) + isnull(a.int_writeoff,0)) as val 
		from risk.func$forecast_for_finance_all(@budget_vers) a
		where a.r_date = @rdt
		and a.product in ('INSTALLMENT','INSTALLMENT_NEW','INSTALLMENT_PDL','PDL')
		;


		--Фактические списания от цессий за период

		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[03] Факт Цессия (списано) ' + case when GROUPING(cr.credit_type_init) = 1 then 'Все продукты' else cr.credit_type_init end as descr,
		sum( a.cess_wo_od + a.cess_wo_int + a.cess_wo_fines ) as val

		from risk.bezz_cess_reestr a
		inner join dwh2.risk.credits cr
		on a.external_id = cr.external_id

		where eomonth(a.cess_dt) = @rdt
		group by rollup(cr.credit_type_init);



		--фактические списания за счет резерва (банкроты)

		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[04] Факт БНКР (списания за счет резерва) ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(0 
			+ isnull(b.ОстатокОДвсего,0)  
			+ isnull(b.ОстатокПроцентовВсего,0) 
			+ isnull(b.ОстатокПени,0)
			+ isnull(d.[остаток иное (комиссии, пошлины и тд)],0)
			- isnull(a.ОстатокОДвсего,0) 
			- isnull(a.ОстатокПроцентовВсего,0)  
			- isnull(a.ОстатокПени,0)
			- isnull(c.[остаток иное (комиссии, пошлины и тд)],0)
		) as val

		from #pokaz_zaimov a
		left join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)

		left join dwh2.dbo.dm_CMRStatBalance c
		on a.НомерДоговора = c.external_id
		and a.ДатаОтчета = dateadd(yy,2000,c.d)

		left join dwh2.dbo.dm_CMRStatBalance d
		on a.НомерДоговора = d.external_id
		and a.ДатаОтчета = dateadd(yy,2000,dateadd(dd,1,d.d))

		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id

		where eomonth(a.ДатаОтчета) = dateadd(yy,2000,@rdt)
		and a.ПричинаЗакрытияНаименование in ('Признание задолженности безнадежной к взысканию',/*СВО*/ 'Списание договора по №377-ФЗ Статья 2 п.1')
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;


		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[05] Количество списанных за счет резерва ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(case when 0 
			+ isnull(b.ОстатокОДвсего,0)  
			+ isnull(b.ОстатокПроцентовВсего,0) 
			+ isnull(b.ОстатокПени,0)
			+ isnull(d.[остаток иное (комиссии, пошлины и тд)],0)
			- isnull(a.ОстатокОДвсего,0) 
			- isnull(a.ОстатокПроцентовВсего,0)  
			- isnull(a.ОстатокПени,0)
			- isnull(c.[остаток иное (комиссии, пошлины и тд)],0) > 0
		then 1 else 0 end) as val

		from #pokaz_zaimov a
		left join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)

		left join dwh2.dbo.dm_CMRStatBalance c
		on a.НомерДоговора = c.external_id
		and a.ДатаОтчета = dateadd(yy,2000,c.d)

		left join dwh2.dbo.dm_CMRStatBalance d
		on a.НомерДоговора = d.external_id
		and a.ДатаОтчета = dateadd(yy,2000,dateadd(dd,1,d.d))

		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id

		where eomonth(a.ДатаОтчета) = dateadd(yy,2000,@rdt)
		and a.ПричинаЗакрытияНаименование in ('Признание задолженности безнадежной к взысканию',/*СВО*/ 'Списание договора по №377-ФЗ Статья 2 п.1')
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;






		--фактические акции прощения (диск кальк) и списания по Оферта 20%

		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[06] Акции списаний и прощений ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(
		isnull(a.СуммаСписанияПроцениты,0) - isnull(b.СуммаСписанияПроцениты,0)
		+ isnull(a.СуммаСписанияПени,0) - isnull(b.СуммаСписанияПени,0)
		+ isnull(a.СуммаПрощенияОсновнойДолг,0) - isnull(b.СуммаПрощенияОсновнойДолг,0)
		+ isnull(a.СуммаПрощенияПроценты,0) - isnull(b.СуммаПрощенияПроценты,0)
		+ isnull(a.СуммаПрощенияПени,0) - isnull(b.СуммаПрощенияПени,0)
		) as val

		from #pokaz_zaimov a
		inner join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)
		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id
		where a.ПричинаЗакрытияНаименование in (
			'Дисконтный калькулятор',
			'Оферта 20% + новый график',
			'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
		)
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;



		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[07] Акции ТОЛЬКО списания ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(
		isnull(a.СуммаСписанияПроцениты,0) - isnull(b.СуммаСписанияПроцениты,0)
		+ isnull(a.СуммаСписанияПени,0) - isnull(b.СуммаСписанияПени,0)
		) as val
		from #pokaz_zaimov a
		inner join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)
		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id
		where a.ПричинаЗакрытияНаименование in (
			'Дисконтный калькулятор',
			'Оферта 20% + новый график',
			'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
		)
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;




		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[08] Акции ТОЛЬКО прощения ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(
		isnull(a.СуммаПрощенияОсновнойДолг,0) - isnull(b.СуммаПрощенияОсновнойДолг,0)
		+ isnull(a.СуммаПрощенияПроценты,0) - isnull(b.СуммаПрощенияПроценты,0)
		+ isnull(a.СуммаПрощенияПени,0) - isnull(b.СуммаПрощенияПени,0)
		) as val
		from #pokaz_zaimov a
		inner join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)
		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id
		where a.ПричинаЗакрытияНаименование in (
			'Дисконтный калькулятор',
			'Оферта 20% + новый график',
			'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
		)
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;



		insert into risk.prov_stg_check_wo
		select 
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[09] Акции количество ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(
		case when 
		isnull(a.СуммаСписанияПроцениты,0) - isnull(b.СуммаСписанияПроцениты,0) > 0
		or isnull(a.СуммаСписанияПени,0) - isnull(b.СуммаСписанияПени,0) > 0
		or isnull(a.СуммаПрощенияОсновнойДолг,0) - isnull(b.СуммаПрощенияОсновнойДолг,0) > 0
		or isnull(a.СуммаПрощенияПроценты,0) - isnull(b.СуммаПрощенияПроценты,0) > 0
		or isnull(a.СуммаПрощенияПени,0) - isnull(b.СуммаПрощенияПени,0) > 0
		then 1 else 0 end
		) as val
		from #pokaz_zaimov a
		inner join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)
		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id
		where a.ПричинаЗакрытияНаименование in (
			'Дисконтный калькулятор',
			'Оферта 20% + новый график',
			'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"'
		)
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;



		--09.10.2024 - процентные начисления
		insert into risk.prov_stg_check_wo
		select @rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[10] Проценты начислено (факт) ' +
		isnull(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end,'ВСЕ ПРОДУКТЫ') as descr,
		sum(a.ПроцентыНачислено - isnull(b.ПроцентыНачислено,0)) as val
		from #pokaz_zaimov a
		inner join #pokaz_zaimov b
		on a.НомерДоговора = b.НомерДоговора
		and a.ДатаОтчета = dateadd(dd,1,b.ДатаОтчета)
		left join dwh2.risk.credits cr
		on a.НомерДоговора = cr.external_id
		group by rollup(case when cr.credit_type_init in ('INST','PDL') then cast(cr.credit_type_init as varchar(100)) else 'PTS' end)
		;



		drop table if exists #stg_plan_int_charge1;
		select 
		cast(a.r_date as date) as r_date, 
		case 	
		when a.product like 'PDL%' then 'PDL'
		when a.product like 'INSTALLMENT%' then 'INST'
		else 'PTS' end as product,
		a.interest,
		a.int_pmt,
		a.int_writeoff
		into #stg_plan_int_charge1
		from risk.func$forecast_for_finance_all(@budget_vers) a
		where a.r_date in (@rdt, eomonth(@rdt,-1))

		
		drop table if exists #stg_plan_int_charge2;
		select 
		a.r_date, 
		case when grouping(a.product) = 1 then 'ВСЕ ПРОДУКТЫ' else a.product end as product,
		sum(a.interest) as int_bal, 
		sum(a.int_pmt) as int_pmt, 
		sum(a.int_writeoff) as int_wo	
		into #stg_plan_int_charge2
		from #stg_plan_int_charge1 a
		group by a.r_date, rollup(a.product)
		;

		insert into risk.prov_stg_check_wo
		select
		@rdt as r_date,
		cast(GETDATE() as datetime) as dt_dml, 
		'[11] Проценты начислено (план) ' + a.product as descr,
		a.int_bal - b.int_bal + a.int_pmt + a.int_wo as val
		from #stg_plan_int_charge2 a
		inner join #stg_plan_int_charge2 b
		on a.r_date = eomonth(b.r_date,1)
		and a.product = b.product
		;

	commit transaction;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try


begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
