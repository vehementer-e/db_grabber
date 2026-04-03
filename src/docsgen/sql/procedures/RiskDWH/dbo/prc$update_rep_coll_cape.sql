
CREATE procedure [dbo].[prc$update_rep_coll_cape] 
@flag_exclude_kk bit = 1
as 

SET NOCOUNT ON
SET XACT_ABORT ON
set datefirst 1


declare
@rdt date, 
@month_first_day date, 
@srcname nvarchar(100);

set @srcname = 'UPDATE_REP_COLL_CAPE';
--set @rdt = cast(dateadd(dd,-1,sysdatetime()) as date);
set @rdt = dateadd(dd, -1, cast (RiskDWH.dbo.date_trunc( 'wk', getdate()) as date))
set @month_first_day = convert(date, convert(varchar(7),@rdt,120) + '-01' , 120  );

declare @dtFrom date = dateadd(dd,1,eomonth(cast(getdate() as date),-2));


declare @vinfo varchar(1000) = concat('START Repdate = ', convert(varchar,@rdt,120), ' flag_exclude_kk = ', cast(@flag_exclude_kk as varchar(1)));


begin try

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


	--Кредитные каникулы
	drop table if exists #kk;
	create table #kk (external_id varchar(200),dt_from date,dt_to date);

	if @flag_exclude_kk = 1
	begin
		--Кредитные каникулы из Space + ЦМР
		drop table if exists #kk_base;
		select 
		a.IdCustomer,
		a.Number,
		cast(a.CreditVacationDateBegin as date) as kk_dt_from,
		cast(a.CreditVacationDateEnd   as date) as kk_dt_to
		into #kk_base
		from stg._Collection.Deals a
		--where a.Number = '18072706510001' or a.IdCustomer = 22995
		where a.CreditVacationDateBegin is not null
		or a.CreditVacationDateEnd is not null
		;

		--ПДП
		delete from #kk_base where kk_dt_to is null; --26/01/2021 - 31 шт

		--дата начала IS NULL
		with dst as (select * from #kk_base a where a.kk_dt_from is null) --26/01/2021 - 21 шт
		merge into dst
		using Reports.dbo.DWH_694_credit_vacation_cmr src
		on (dst.Number = src.Договор)
		when matched then update 
			set dst.kk_dt_from = src.Период --26/01/2021 - для всех из 21 подтянулась дата начала из ЦМР
		;

		--каникулы из ЦМР, которых нет в реестре Space
		insert into #kk_base --26/01/2021 +3 шт из ЦМР
		select d.IdCustomer, d.Number, a.Период as kk_dt_from, a.ДатаОкончания as kk_dt_to
		from Reports.dbo.DWH_694_credit_vacation_cmr a
		left join stg._Collection.Deals d
		on a.Договор = d.Number
		where not exists (select 1 from #kk_base b
			where a.Договор = b.Number)



		insert into #kk
		select k.number, k.kk_dt_from, k.kk_dt_to from #kk_base k

		--select c.Договор, c.ДатаПоГрафику, c.ДатаОкончания
		--from Reports.dbo.DWH_694_credit_vacation_cmr c;
	end;


	--Soft, middle, predel
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#cape';

	drop table if exists #cape
	select distinct  s.CRMClientStage, s.external_id as CMRContractNumber ,t.person_id, credit_week, s.cdate as date_report	
	into #cape	
	from RiskDWH.dbo.stg_client_stage s
	left join dwh_new.dbo.tmp_v_credits t 
	on s.external_id = t.external_id	
	where s.cdate >= @dtFrom
	and s.cdate <= @rdt
	and s.CRMClientStage not in ( 'Closed', 'Current')
	and not exists (select 1 from #kk k where s.external_id = k.external_id and s.cdate between k.dt_from and k.dt_to)
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#gr';

	drop table if exists #gr
	select CRMClientStage,date_report,COUNT(distinct CMRContractNumber) as dogovor, COUNT(distinct person_id) as client	
	into #gr	
	from #cape	
	group by CRMClientStage, date_report;

	
	--hard
	

	--история перехода между отв взыскателями - промежуточная таблица 1
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg1_claimants';

	drop table if exists #stg1_claimants;

	select c.idCustomer,
	c.id,
	c.ChangeDate,
	c.old_employee_fio,
	c.new_employee_fio,
	ROW_NUMBER() over (partition by c.idCustomer order by c.ChangeDate, c.id) as rown_asc

	into #stg1_claimants
	from (
		select b.idCustomer,
		b.id,
		b.ChangeDate,
		b.old_employee_fio,
		b.new_employee_fio,
		--ROW_NUMBER() over (partition by b.idCustomer, cast(b.ChangeDate as date), b.old_employee_fio, b.new_employee_fio order by b.ChangeDate) as rown
		ROW_NUMBER() over (partition by b.idCustomer, cast(b.ChangeDate as date) order by b.ChangeDate desc) as rown

		from (
			select 
			a.ObjectId as idCustomer,
			a.id, 
			a.ChangeDate, 

			case 
			when a.OldValue is null then null
			else concat(trim(b.LastName), ' ', trim(b.FirstName),' ', trim(b.MiddleName)) end as old_employee_fio,

			case 
			when a.NewValue is null then null
			else concat(trim(c.LastName), ' ', trim(c.FirstName),' ', trim(c.MiddleName)) end as new_employee_fio

			from stg._Collection.CustomerHistory a
			left join stg._Collection.Employee b
			on a.OldValue = b.Id
			left join stg._Collection.Employee c
			on a.NewValue = c.Id
			where 1=1
			and a.Field = 'Ответственный взыскатель'
			and cast(a.ChangeDate as date) < cast(getdate() as date)
			and a.Metadata is not null
			--and a.ObjectId = 42776

		union all

			select 
			a.ObjectId as idCustomer,
			a.id, 
			a.ChangeDate, 

			case 
			when isnull(a.OldValue,'') = '' then null
			else trim(a.OldValue) end as old_employee_fio,

			case 
			when isnull(a.NewValue,'') = '' then null
			else trim(a.NewValue) end as new_employee_fio

			from stg._Collection.CustomerHistory a
			where 1=1
			and a.Field = 'Ответственный взыскатель'
			and cast(a.ChangeDate as date) < cast(getdate() as date)
			and a.Metadata is null
		) b
	) c 
	where c.rown = 1
	and isnull(c.old_employee_fio,'n') <> isnull(c.new_employee_fio,'n')
	;

	/***************************************************************************************/
	--история перехода между отв взыскателями - промежуточная таблица 2
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg2_claimants';

	drop table if exists #stg2_claimants;
		select 
		a.idCustomer, 
		a.ChangeDate as dt_from, 
		isnull(lead(a.ChangeDate) over (partition by a.idCustomer order by a.ChangeDate), cast('4444-01-01' as date)) as dt_to,
		a.new_employee_fio as employee_fio

	into #stg2_claimants
		from #stg1_claimants a
	union all
		select b.idCustomer,
		cast('1111-01-01' as date) as dt_from,
		b.ChangeDate as dt_to,
		b.old_employee_fio as employee_fio
		from #stg1_claimants b
		where b.rown_asc = 1
		--order by 3 desc
	;


	--история перехода между отв взыскателями - промежуточная таблица 3
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg3_claimants';

	drop table if exists #stg3_claimants;
	select a.idCustomer, 
	cast(a.dt_from as date) as dt_from,

	case when cast(a.dt_to as date) = cast('4444-01-01' as date)
	then cast('4444-01-01' as date)
	else dateadd(dd,-1,cast(a.dt_to as date)) end as dt_to,

	a.employee_fio

	into #stg3_claimants 
	from #stg2_claimants a
	where not (cast(a.dt_from as date) = cast(a.dt_to as date))
	;

	/***************************************************************************************/
	--декартово произведение отчетных дат и клиентов с отв сотрудниками
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#clients_claimants';

	drop table if exists #clients_claimants;

	with dates as (
	select @dtFrom as dt --dateadd(dd,1,eomonth(cast(getdate() as date),-2)) as dt 
	union all
	select dateadd(dd,1,dt) as dt
	from dates d
	where dt < @rdt --dateadd(dd, -1, cast (RiskDWH.dbo.date_trunc( 'wk', getdate()) as date)) 
	), empl as (
	select a.idCustomer, a.dt_from, a.dt_to, a.employee_fio
	from #stg3_claimants a
	where a.employee_fio is not null
	), base as (
	select * from dates a
	left join empl e 
	on a.dt	between e.dt_from and e.dt_to
	)
	select b.dt, b.idCustomer, b.employee_fio
	into #clients_claimants
	from base b
	where 1=1
	--and b.dt = '2021-01-11'
	--and b.idCustomer = 29873
	--order by b.dt, b.dt_from


	/***************************************************************************************/


	--перечень сотрудников харда
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#hard_emp';

	drop table if exists #hard_emp;
	select * 
	into #hard_emp
	from (values
	('Бугайчук Павел Валерьевич','Hard Москва'),
	('Тарасенко Дмитрий Владимирович','Hard Москва'),
	('Деговцов Александр Юрьевич','Hard Москва'),
	('Таруашвили Сергей Геннадьевич','Hard Москва'),
	('Захаров Алексей Владимирович','Hard Москва'),
	('Куприянов Константин Борисович','Hard Москва'),
	('Лошкарев Максим Сергеевич','Hard Москва'),

	('Дюкарев Алексей Викторович','Hard Регионы'),
	('Василенко Олег Александрович','Hard Регионы'),
	('Долгирев Андрей Семенович','Hard Регионы'),
	('Макарьев Родион Игоревич','Hard Регионы'),
	('Кусов Сергей Александрович','Hard Регионы'),
	('Чальцев Павел Владимирович','Hard Регионы'),
	('Галиуллин Рустем Рауфович','Hard Регионы'),
	('Якупов Ильдар Нургалиевич','Hard Регионы'),
	('Дулясов Александр Геннадьевич','Hard Регионы')
	) a (employee_fio, stage_name)
	;


	--добавляем статус и определяем регион/мск
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#clients_claimants_sts';

	drop table if exists #clients_claimants_sts;
	with sts as (
	select 
	a.CustomerId,
	b.Name as cli_status,
	coalesce(cast(a.Date as date), cast(a.CreateDate as date), cast(a.ActivationDate as date), cast('1111-01-01' as date)) as dt_from,
	iif(a.IsActive = 1, cast('4444-01-01' as date), cast(a.UpdateDate as date)) as dt_to,
	a.IsActive
	from stg._Collection.CustomerStatus a
	left join stg._Collection.CustomerState b
	on a.CustomerStateId = b.Id
	where a.IsActive = 1 or a.UpdateDate is not null
	)
	select a.dt, a.idCustomer, a.employee_fio, h.stage_name,
	STRING_AGG(b.cli_status, ';') as cli_status_list
	into #clients_claimants_sts
	from #clients_claimants a
	left join sts b
	on a.idCustomer = b.CustomerId 
	and a.dt between b.dt_from and b.dt_to
	inner join #hard_emp h
	on a.employee_fio = h.employee_fio

	group by a.dt, a.idCustomer, a.employee_fio, h.stage_name

	;

	--удаляем ненужные клиентов со статусами, в которых Хард не работает
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'delete from #clients_claimants_sts';

	with a as (select * from #clients_claimants_sts)
	delete from a
	where (a.cli_status_list like '%Банкрот подтверждённый%'
	or a.cli_status_list like '%HardFraud%'
	or a.cli_status_list like '%Смерть подтвержденная%'
	or a.cli_status_list like '%КА%'
	or a.cli_status_list like '%Отказ от взаимодействия по 230 ФЗ%'
	or a.cli_status_list like '%Безнадежное взыскание%'
	)
	;


	/*******************************************************************/



	--стадия коллектинга (клиент)
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_cli_coll_stages';

	drop table if exists #stg_cli_coll_stages;
	with base as (
		select a.ObjectId as idCustomer, 
		a.ChangeDate,
		b.[Name] as old_val,
		c.[Name] as new_val,
		ROW_NUMBER() over (partition by a.ObjectId, cast(a.ChangeDate as date) order by a.ChangeDate desc) as rown_by_day,
		ROW_NUMBER() over (partition by a.ObjectId order by a.ChangeDate asc) as rown_total
		from stg._Collection.CustomerHistory a
		left join stg._Collection.collectingStage b
		on a.OldValue = b.Id
		left join stg._Collection.collectingStage c
		on a.NewValue = c.Id
		where a.Field = 'Стадия коллектинга'
		and exists (select 1 from #clients_claimants_sts s
				where a.ObjectId = s.idCustomer)
		--and a.ObjectId = 15390--13917
		--order by a.ChangeDate desc
	), src as (
		select b.idCustomer, 
		cast(b.ChangeDate as date) as dt_from, 
		case when lead(b.ChangeDate) over (partition by b.idCustomer order by b.ChangeDate) is null
		then cast('4444-01-01' as date)
		else dateadd(dd,-1, cast(lead(b.ChangeDate) over (partition by b.idCustomer order by b.ChangeDate) as date))
		end as dt_to,
		b.new_val as cli_coll_stage
		from base b
		where b.rown_by_day = 1

		union all

		select b.idCustomer, 
		cast('1111-01-01' as date) as dt_from,
		dateadd(dd,-1,cast(b.ChangeDate as date)) as dt_to,
		b.old_val as cli_coll_stage
		from base b
		where b.rown_total = 1
	)
	select s.idCustomer, s.dt_from, s.dt_to, s.cli_coll_stage
	into #stg_cli_coll_stages
	from src s

	;


	--база с килентами
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#cli_base';

	drop table if exists #cli_base;
	select a.idCustomer, a.dt, a.employee_fio, a.stage_name, a.cli_status_list, b.cli_coll_stage,
	concat(trim(c.LastName), ' ', trim(c.[name]), ' ', trim(c.MiddleName)) as cli_fio
	into #cli_base
	from #clients_claimants_sts a
	left join #stg_cli_coll_stages b
	on a.idCustomer = b.idCustomer
	and a.dt between b.dt_from and b.dt_to
	left join stg._collection.customers c
	on a.idCustomer = c.id
	where isnull(b.cli_coll_stage,'n') in ('Hard','ИП','СБ','Legal')
	;


	
	--атрибуты договоров (стадия, статус) - 1 промежуточная таблица
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg1_con_attr';

	drop table if exists #stg1_con_attr;
	select 
	dls.IdCustomer,
	dls.Number as external_id,
	a.ObjectId as deal_id,
	case
	when a.Field = 'Статус договора' then 'con_status'
	when a.Field = 'Стадия коллектинга договора' then 'con_stage'
	end as attr_name,

	a.ChangeDate,

	case 
	when a.Field = 'Статус договора' then d.Name
	when a.Field = 'Стадия коллектинга договора' then b.Name
	end as old_val,

	case 
	when a.Field = 'Статус договора' then e.Name
	when a.Field = 'Стадия коллектинга договора' then c.Name
	end as new_val

	into #stg1_con_attr
	from stg._Collection.DealHistory a
	inner join stg._Collection.Deals dls
	on a.ObjectId = dls.Id
	left join stg._Collection.DealStatus dsts
	on dls.IdStatus = dsts.Id

	left join stg._Collection.collectingStage b
	on a.OldValue = b.Id
	and a.Field = 'Стадия коллектинга договора'
	left join stg._Collection.collectingStage c
	on a.NewValue = c.Id
	and a.Field = 'Стадия коллектинга договора'

	left join stg._Collection.DealStatus d
	on a.OldValue = d.Id
	and a.Field = 'Статус договора'
	left join stg._Collection.DealStatus e
	on a.NewValue = e.Id
	and a.Field = 'Статус договора'
	where 1=1
	--and a.ObjectId = 10637
	and a.Field in ('Стадия коллектинга договора','Статус договора')
	and exists (select 1 from #cli_base cb			
				where cb.idCustomer = dls.IdCustomer)
	and isnull(dsts.Name,'n') not in ('Аннулирован')
	;


	--атрибуты договоров (стадия, статус) - 2 промежуточная таблица
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg2_con_attr';

	drop table if exists #stg2_con_attr;
	with base as (
	select a.IdCustomer, a.external_id, a.deal_id, a.attr_name,
	a.ChangeDate, a.old_val, a.new_val,
	ROW_NUMBER() over (partition by a.IdCustomer, a.external_id, a.attr_name, cast(a.ChangeDate as date) order by a.ChangeDate desc) as rown_by_day,
	ROW_NUMBER() over (partition by a.IdCustomer, a.external_id, a.attr_name order by a.ChangeDate asc) as rown_total
	from #stg1_con_attr a
	), src as (
		select 
		b.IdCustomer, b.external_id, b.deal_id, b.attr_name, 
		cast(b.ChangeDate as date) as dt_from,
		case when lead(b.ChangeDate) over (partition by b.IdCustomer, b.external_id, b.attr_name order by b.ChangeDate) is null
		then cast('4444-01-01' as date)
		else dateadd(dd,-1,cast(lead(b.ChangeDate) over (partition by b.IdCustomer, b.external_id, b.attr_name order by b.ChangeDate) as date))
		end as dt_to,
		b.new_val as val
		from base b
		where b.rown_by_day = 1

	union all

		select c.IdCustomer, c.external_id, c.deal_id, c.attr_name,
		cast('1111-01-01' as date) as dt_from,
		dateadd(dd,-1,cast(c.ChangeDate as date)) as dt_to,
		c.old_val as val
		from base c
		where c.rown_total = 1
	)
	select s.IdCustomer, s.external_id, s.deal_id, s.attr_name, 
	s.dt_from, s.dt_to, s.val

	into #stg2_con_attr
	from src s
	;

	--база дата-клиент-договор-взыскатель
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#cli_con_base';

	drop table if exists #cli_con_base;
	select a.idCustomer, a.dt, a.cli_fio,
	a.stage_name, a.employee_fio, 
	a.cli_coll_stage, a.cli_status_list,

	d.Number as external_id,
	d.id as deal_id,

	b.val as con_stage,
	c.val as con_status,
	isnull(cmr.dpd,-1) as dpd,
	max(isnull(cmr.dpd,-1)) over (partition by a.idCustomer, a.dt) as mx_dpd


	into #cli_con_base
	from #cli_base a
	inner join stg._Collection.Deals d
	on a.idCustomer = d.IdCustomer
	inner join stg._Collection.DealStatus ds
	on d.IdStatus = ds.Id

	left join #stg2_con_attr b
	on d.Id = b.deal_id
	and b.attr_name = 'con_stage'
	and a.dt between b.dt_from and b.dt_to

	left join #stg2_con_attr c
	on d.Id = c.deal_id
	and c.attr_name = 'con_status'
	and a.dt between c.dt_from and c.dt_to

	left join Reports.dbo.dm_CMRStatBalance_2 cmr
	on d.Number = cmr.external_id
	and a.dt = cmr.d

	where ds.Name not in ('Аннулирован')
	----исключаем кредитные каникулы
	and not exists (select 1 from #kk k
				where d.number = k.external_id
				and a.dt between k.dt_from and k.dt_to)
	;

	--агрегат по хард мск/регионы по дням
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#CustContrStageByDate';

	drop table if exists #CustContrStageByDate;
	select a.dt as BindingDate, 
	a.stage_name as stage_name2, 
	count(distinct a.idCustomer) as cnt_client,
	count(distinct a.external_id) as cnt_contract

	into #CustContrStageByDate
	from #cli_con_base a
	where 1=1
	and isnull(a.con_stage,'n') <> 'Closed'
	and isnull(a.con_status,'n') <> 'Погашен'
	and not (a.cli_coll_stage = 'СБ' and a.mx_dpd < 90)
	group by a.dt, a.stage_name
	;



	/********************************************************************************************/


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#total_base';	

	drop table if exists #total_base;
	select c.r_date, c.stage_name, c.cnt_client, c.cnt_contract
	into #total_base
	from (
		select a.BindingDate as r_date,
		a.stage_name2 as stage_name,
		a.cnt_client,
		a.cnt_contract
		from #CustContrStageByDate a
	union all
		select a.BindingDate as r_date,
		'Hard' as stage_name,
		sum(a.cnt_client) as cnt_client,
		sum(a.cnt_contract) as cnt_contract
		from #CustContrStageByDate a
		group by a.BindingDate
	union all
		select b.date_report as r_date,
		b.CRMClientStage as stage_name,
		b.client as cnt_client,
		b.dogovor as cnt_contract
		from #gr b
		where b.CRMClientStage in ('Predelinquency','Soft','Middle','Prelegal')
	) c
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#rep_daily';	

	drop table if exists #rep_daily;

	with stages as (
	select cast(stage_name as nvarchar(100)) as stage_name
	from (values
	('Hard Москва'		),
	('Hard Регионы'		),
	('Middle'			),
	('Predelinquency'	),
	('Prelegal'			),
	('Soft'				),
	('Испол.п-во'		),
	('Hard'				)
	) aa (stage_name)
	), repdates as (
	select @rdt as r_date
	union all
	select dateadd(dd,-1,r_date) as r_date
	from repdates
	where r_date > @dtFrom
	)
	select r.r_date, s.stage_name, 
	isnull(t.cnt_client,0) as cnt_client,
	isnull(t.cnt_contract,0) as cnt_contract,
	iif(s.stage_name = 'Hard',isnull(hrdmsc.employee_cnt,0) + isnull(hrdreg.employee_cnt,0) + isnull(ispprz.employee_cnt,0),
	isnull(d.employee_cnt,0)) as employee_cnt,

	case when iif(s.stage_name = 'Hard',isnull(hrdmsc.employee_cnt,0) + isnull(hrdreg.employee_cnt,0) + isnull(ispprz.employee_cnt,0),
	isnull(d.employee_cnt,0)) = 0 then 0 
	else cast(isnull(t.cnt_client,0) as float) / 
	iif(s.stage_name = 'Hard',isnull(hrdmsc.employee_cnt,0) + isnull(hrdreg.employee_cnt,0) + isnull(ispprz.employee_cnt,0), isnull(d.employee_cnt,0))
	end as client_to_empl,

	case when iif(s.stage_name = 'Hard',isnull(hrdmsc.employee_cnt,0) + isnull(hrdreg.employee_cnt,0) + isnull(ispprz.employee_cnt,0),
	isnull(d.employee_cnt,0)) = 0 then 0 
	else cast(isnull(t.cnt_contract,0) as float) / 
	iif(s.stage_name = 'Hard',isnull(hrdmsc.employee_cnt,0) + isnull(hrdreg.employee_cnt,0) + isnull(ispprz.employee_cnt,0), isnull(d.employee_cnt,0))
	end as contract_to_empl,

	case when r.r_date between @month_first_day and @rdt then 1 else 0 end as current_month,
	case when r.r_date between dateadd(dd,-7*3-6,@rdt) and dateadd(dd,-7*3,@rdt) then 1 else 0 end as week_1,
	case when r.r_date between dateadd(dd,-7*2-6,@rdt) and dateadd(dd,-7*2,@rdt) then 1 else 0 end as week_2,
	case when r.r_date between dateadd(dd,-7*1-6,@rdt) and dateadd(dd,-7*1,@rdt) then 1 else 0 end as week_3,
	case when r.r_date between dateadd(dd,-7*0-6,@rdt) and dateadd(dd,-7*0,@rdt) then 1 else 0 end as week_4

	into #rep_daily

	from stages as s
	cross join repdates as r
	left join #total_base as t
	on s.stage_name = t.stage_name
	and r.r_date = t.r_date
	left join RiskDWH.dbo.det_coll_cape d
	on s.stage_name = d.stage_name
	and r.r_date between d.dt_from and d.dt_to
	left join RiskDWH.dbo.det_coll_cape hrdmsc 
	on r.r_date between hrdmsc.dt_from and hrdmsc.dt_to
	and hrdmsc.stage_name = 'Hard Москва'
	left join RiskDWH.dbo.det_coll_cape hrdreg 
	on r.r_date between hrdreg.dt_from and hrdreg.dt_to
	and hrdreg.stage_name = 'Hard Регионы'
	left join RiskDWH.dbo.det_coll_cape ispprz 
	on r.r_date between ispprz.dt_from and ispprz.dt_to
	and ispprz.stage_name = 'Испол.п-во'
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'REP';	
	
	--drop table dbo.rep_coll_cape_2;
	begin transaction;
	
		delete from RiskDWH.dbo.rep_coll_cape_2 
		where rep_dt = @rdt;

		insert into RiskDWH.dbo.rep_coll_cape_2 
		select 
		@rdt as rep_dt,
		cast(sysdatetime() as datetime) as dt_dml,
		b.seg, b.stage_name, 
		concat(substring(convert(varchar,b.dt_from,104),1,5), '-',
			substring(convert(varchar,b.dt_to,104),1,5)) as dt_period_char,
		b.avg_client, b.avg_contract, b.avg_client_to_empl, b.avg_contract_to_empl
		--into dbo.rep_coll_cape_2
		from (
			select cast('CM' as nvarchar(100)) as seg,
			a.stage_name, 
			min(a.r_date) as dt_from,
			max(a.r_date) as dt_to,
			round(avg(a.cnt_client)		 ,0)	as avg_client,
			round(avg(a.cnt_contract)	 ,0)	as avg_contract,
			round(avg(a.client_to_empl)	 ,0)	as avg_client_to_empl,
			round(avg(a.contract_to_empl),0)	as avg_contract_to_empl
			from #rep_daily a
			where a.current_month = 1
			group by a.stage_name
		union all
			select cast('WK1' as nvarchar(100)) as seg,
			a.stage_name, 
			min(a.r_date) as dt_from,
			max(a.r_date) as dt_to,
			round(avg(a.cnt_client)		 ,0)	as avg_client,
			round(avg(a.cnt_contract)	 ,0)	as avg_contract,
			round(avg(a.client_to_empl)	 ,0)	as avg_client_to_empl,
			round(avg(a.contract_to_empl),0)	as avg_contract_to_empl
			from #rep_daily a
			where a.week_1 = 1
			group by a.stage_name
		union all
			select cast('WK2' as nvarchar(100)) as seg,
			a.stage_name, 
			min(a.r_date) as dt_from,
			max(a.r_date) as dt_to,
			round(avg(a.cnt_client)		 ,0)	as avg_client,
			round(avg(a.cnt_contract)	 ,0)	as avg_contract,
			round(avg(a.client_to_empl)	 ,0)	as avg_client_to_empl,
			round(avg(a.contract_to_empl),0)	as avg_contract_to_empl
			from #rep_daily a
			where a.week_2 = 1
			group by a.stage_name
		union all
			select cast('WK3' as nvarchar(100)) as seg,
			a.stage_name, 
			min(a.r_date) as dt_from,
			max(a.r_date) as dt_to,
			round(avg(a.cnt_client)		 ,0)	as avg_client,
			round(avg(a.cnt_contract)	 ,0)	as avg_contract,
			round(avg(a.client_to_empl)	 ,0)	as avg_client_to_empl,
			round(avg(a.contract_to_empl),0)	as avg_contract_to_empl
			from #rep_daily a
			where a.week_3 = 1
			group by a.stage_name
		union all
			select cast('WK4' as nvarchar(100)) as seg,
			a.stage_name, 
			min(a.r_date) as dt_from,
			max(a.r_date) as dt_to,
			round(avg(a.cnt_client)		 ,0)	as avg_client,
			round(avg(a.cnt_contract)	 ,0)	as avg_contract,
			round(avg(a.client_to_empl)	 ,0)	as avg_client_to_empl,
			round(avg(a.contract_to_empl),0)	as avg_contract_to_empl
			from #rep_daily a
			where a.week_4 = 1
			group by a.stage_name
		) b
		;

	commit transaction;
	

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';
	
end try

begin catch

if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
