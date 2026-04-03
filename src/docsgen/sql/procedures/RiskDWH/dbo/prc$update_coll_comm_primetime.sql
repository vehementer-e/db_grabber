
CREATE PROC dbo.prc$update_coll_comm_primetime
	@dt_from date = null,
	@dt_to date = null

AS

if @dt_from is null set @dt_from = dateadd(dd,-7,cast(getdate() as date));
if @dt_to	is null set @dt_to	 = dateadd(dd,-1,cast(getdate() as date));

declare @srcname varchar(250) = 'Update Rep Collection Communications';
declare @vinfo varchar(500);

set datefirst 1;

set @vinfo = concat('START dt_from = ', convert(varchar,@dt_from,120), ' , dt_to = ', convert(varchar,@dt_to,120));

begin try

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#contr_end_dates';

	--Дата окончания договора
	drop table if exists #contr_end_dates;
	select a.external_id, max(a.ContractEndDate) as ContractEndDate, max(a.ContractStartDate) as ContractStartDate
	into #contr_end_dates
	from Reports.dbo.dm_CMRStatBalance_2 a
	group by a.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_comm_base';


	--База
	drop table if exists #stg_comm_base;

	with base as (
	select distinct 
	--top 50
	a.Id,
	a.Number as external_id,
	a.PhoneNumber,
	a.updateDate,

	case a.Manager when 'Викторовна Чупахина Ольга' then 'Чупахина Ольга Викторовна' else a.Manager end as Manager,
	a.CommunicationType,
	a.CommunicationDate,
	a.CommunicationDateTime,
	a.CommunicationResult,
	a.PersonType,
	cast(a.PromiseDate as date) as PromiseDate,
	a.Контакт as Contact,
	try_cast(isnull(a.PromiseSum,0) as float) as PromiseSum,
 
	case when not(a.CommunicationResult = 'Оплачено' and a.Manager = 'Система') 
			and a.Контакт = 'Да'
			and a.PromiseDate is not null then 1 
		else 0 end as PTP_flag,

	case when a.CommunicationDate > b.ContractEndDate then 1 else 0 end as Closed_flag,
	b.ContractEndDate,
	b.ContractStartDate

	--ROW_NUMBER() over(partition by a.Number, a.CommunicationDate, a.PhoneNumber, a.Manager order by a.updateDate desc) as rn
	from stg._Collection.v_Communications a
	inner join dwh_new.dbo.tmp_v_credits c
	on a.Number = c.external_id

	left join #contr_end_dates b
	on a.Number = b.external_id

	where a.CommunicationDate >= @dt_from
	and a.CommunicationDate <= @dt_to
	and a.Manager is not null
	--and a.Manager not in ('Система')
	and a.CommunicationDateTime is not null
	)
	select  
	bs.external_id,
	bs.CommunicationDate,
	bs.CommunicationDateTime,
	bs.CommunicationType,
	bs.CommunicationResult,
	bs.Manager,
	bs.PersonType,
	bs.PhoneNumber,
	bs.PromiseDate,
	bs.PromiseSum,
	bs.PTP_flag,
	bs.Contact,
	bs.Closed_flag,
	bs.ContractStartDate,
	bs.ContractEndDate

	into #stg_comm_base

	from base bs
	--where rn = 1;
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#client_stages';


	-- ClientStage
	drop table if exists #client_stages

	/*
	--var 1
	with base as (
	select cb.external_id,
	cb.CommunicationDate,  
	s.CRMClientStage,
	ROW_NUMBER() over (partition by cb.external_id, cb.CommunicationDate order by s.created desc) as rn
	from #stg_comm_base cb
	left join dwh_new.staging.CRMClient_references r 
	on cb.external_id = r.CMRContractNumber
	left join [dwh_new].[Dialer].[ClientContractStage] s 
	on s.CRMClientGUID=r.CRMClientGUID
	and cast(s.created as date) = cb.CommunicationDate
	)
	select b.CommunicationDate, b.external_id, b.CRMClientStage
	into #client_stages
	from base b
	where b.rn = 1;
	*/
	--var 2 DWH-2442
	;WITH base AS (
		SELECT 
			cb.external_id,
			cb.CommunicationDate,  
			s.CRMClientStage,
			row_number() over (partition by cb.external_id, cb.CommunicationDate order by s.created desc) as rn
		FROM #stg_comm_base AS cb
			LEFT JOIN Stg._loginom.v_ClientContractStage_simple AS s
				ON s.CMRContractNumber = cb.external_id
				AND s.created = cb.CommunicationDate
	)
	select b.CommunicationDate, b.external_id, b.CRMClientStage
	into #client_stages
	from base b
	where b.rn = 1;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#deals';


	-- уникальные договора 
	drop table if exists #deals;

	select distinct external_id,d.ссылка into #deals
	  from #stg_comm_base a
	  join stg._1cCMR.Справочник_Договоры d on d.Код=a.external_id  ;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#total_payments';



	drop table if exists #total_payments;

	select  
	d.external_id, 
	dateadd(year,-2000,cast(a.ДатаПоследнегоПлатежа as date)) as r_date,
	sum(cast(a.СуммаПоследнегоПлатежа as float)) as pay_total

	into #total_payments

	from stg._1cCMR.РегистрСведений_АналитическиеПоказателиМФО a
	inner join #deals d
	on a.Договор = d.Ссылка
	where cast(a.ДатаПоследнегоПлатежа as date) >= dateadd(year,2000, @dt_from) 
	and cast(a.ДатаПоследнегоПлатежа as date) <= dateadd(year,2000, @dt_to) 
	and cast(a.ДатаПоследнегоПлатежа as date) = cast(a.Период as date)
	and a.Регистратор_ТипСсылки = 0x00000060 --платежи
	group by d.external_id, dateadd(year,-2000,cast(a.ДатаПоследнегоПлатежа as date))
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_payments';


	--добавляем платежи между датой коммуникации и датой обещания
	drop table if exists #stg_payments;

	select a.external_id, a.CommunicationDate, a.PhoneNumber, a.Manager, 
	sum(isnull(b.pay_total,0)) as pmt_between_comm_ptp
	into #stg_payments
	from (select distinct a.external_id, 
						a.CommunicationDate, 
						a.PhoneNumber, 
						a.Manager, 
						a.PromiseDate 
				from #stg_comm_base a) a
	left join #total_payments b 
	on a.external_id = b.external_id
	and b.r_date between a.CommunicationDate and a.PromiseDate
	where a.PromiseDate is not null
	group by a.external_id, a.CommunicationDate, a.PhoneNumber, a.Manager
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_dpd_buckets';


	--для признака "сохраненный баланс"   
	drop table if exists #stg_dpd_buckets;
	select dt=dateadd(year,-2000,ap.Период)
		, d=dateadd(year,-2000,cast(ap.Период as date))       
		, bucket    =	   case when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 1 and 30	 then '(2)_1_30'
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 31 and 60 	 then '(3)_31_60'
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 61 and 90	 then '(4)_61_90'
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 91 and 360	 then '(5)_91_360'
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) >= 360				 then '(6)_361+'
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) = 0					 then '(1)_0'
							else '(7)_Other' 
						end     
		, bucketNo =	   case when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 1 and 30	then 1
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 31 and 60	then 2
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 61 and 90	then 3
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) between 91 and 360	then 4
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) >= 360				then 5
								when isnull(ap.КоличествоПолныхДнейПросрочкиУМФО,0) = 0					then 0
							else 0 
						end
		, external_id=de.external_id
	   into #stg_dpd_buckets
	   from  [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] ap 
	   inner join #deals de 
	   on de.ссылка=ap.договор 
	  where cast(ap.Период as date) >= dateadd(year,2000,@dt_from) 
		and cast(ap.Период as date) <= dateadd(year,2000, @dt_to ) ;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_dpd_buckets_begofday';


	--бакет начало дня
	drop table if exists #stg_dpd_buckets_begofday;
	  with d as (
	  select rn=row_number() over (partition by external_id,cast(dt as date) order by dt )
		   , * 
		from #stg_dpd_buckets ap
	  )
	  select * into #stg_dpd_buckets_begofday from d where rn=1

	--бакет конец дня
	;
	  with d as (
	  select rn=row_number() over (partition by external_id,cast(dt as date) order by dt desc)
		   , * 
		from #stg_dpd_buckets ap
	  )
	  delete from d where rn<>1;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_comm_base2';


	--присоединяем платежи и формируем флаг выполненного обещания
	drop table if exists #stg_comm_base2;

	select a.*, 
	case when a.PromiseDate is not null
		and b.pmt_between_comm_ptp >= a.PromiseSum
		and a.PromiseSum > 0
	then 1
	else 0 end as Success_PTP_flag,
	case when a.PromiseDate is not null then b.pmt_between_comm_ptp else 0 end as pmt_between_comm_ptp,
	cast(c.[остаток од] as float) as due_od_yesterday

	into #stg_comm_base2

	from #stg_comm_base a
	left join #stg_payments b
	on a.external_id = b.external_id
	and a.CommunicationDate = b.CommunicationDate
	and isnull(a.Manager,'n') = isnull(b.Manager,'n')
	and isnull(a.PhoneNumber,'n') = isnull(b.PhoneNumber,'n')

	left join Reports.dbo.dm_CMRStatBalance_2 c
	on a.CommunicationDate = dateadd(dd,1,c.d)
	and a.external_id = c.external_id;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_comm_base3';


	--добавляем сохраненный баланс
	drop table if exists #stg_comm_base3;

	select a.*, 
	case when 
	((isnull(d.bucketNo,0) > isnull(e.bucketNo,0)) or (isnull(d.bucketNo,0) = 0 and isnull(e.bucketNo,0) = 0))
	and a.Success_PTP_flag = 1 
	--then iif(cast(f.[остаток од] as float)=0, cast(g.[остаток од] as float), cast(f.[остаток од] as float))
	then cast(g.[остаток од] as float)
	else 0 end as saved_balance,
	cs.CRMClientStage,
	isnull(d.bucket, '(1)_0') as dpd_bucket

	into #stg_comm_base3

	from #stg_comm_base2 a
	left join #stg_dpd_buckets_begofday  d
	on a.external_id = d.external_id
	and a.CommunicationDate = d.d
	left join #stg_dpd_buckets e
	on a.external_id = e.external_id
	and a.PromiseDate = e.d
	left join Reports.dbo.dm_CMRStatBalance_2 f
	on a.external_id = f.external_id
	and a.CommunicationDate = f.d
	left join Reports.dbo.dm_CMRStatBalance_2 g
	on a.external_id = g.external_id
	and a.CommunicationDate = dateadd(dd,1,g.d)

	left join #client_stages cs
	on a.external_id = cs.external_id
	and a.CommunicationDate = cs.CommunicationDate

	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_comm_base4';


	--только звонки
	drop table if exists #stg_comm_base4;

	select a.* 
	into #stg_comm_base4
	from #stg_comm_base3 a
	where a.CommunicationType in ('Исходящий звонок', 'Входящий звонок')
	--and a.Manager <> 'Система' --???
	;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Drop temp (#) tables';


	drop table #client_stages;
	drop table #contr_end_dates;
	drop table #deals;
	drop table #stg_comm_base;
	drop table #stg_comm_base2;
	drop table #stg_comm_base3;
	drop table #stg_dpd_buckets;
	drop table #stg_dpd_buckets_begofday;
	drop table #stg_payments;
	drop table #total_payments;


	/*****************************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Staging tables';


	--AGG, key: external_id, CommunicationDate
	begin transaction 

		delete from dbo.stg_coll_comm_base
		where CommunicationDate between @dt_from and @dt_to

		insert into dbo.stg_coll_comm_base

		select 
		a.external_id, 
		a.CommunicationDate,
		datepart(week,a.CommunicationDate) as CommDateWeek,
		format(a.CommunicationDate, 'MM-yyyy') as CommDateMonth,
		year(a.CommunicationDate) as CommDateYear,
		a.CRMClientStage,
		a.dpd_bucket,
		count(*) as attempt_cnt,
		1 as schedule_cnt,

		--Все звонки
		sum(case when a.PersonType in ('Клиент','Третье лицо') 
		then 1 else 0 end) as contact_total_cnt,

		sum(case when a.PersonType in ('Клиент') 
		then 1 else 0 end) as contact_rpc_cnt,

		sum(case when a.PersonType in ('Третье лицо') 
		then 1 else 0 end) as contact_tpc_cnt,


		--Исходящие звонки

		sum(case when a.CommunicationType = 'Исходящий звонок' 
		and a.PersonType in ('Клиент','Третье лицо') 
		then 1 else 0 end) as outcome_total_cnt,

		sum(case when a.CommunicationType = 'Исходящий звонок' 
		and a.PersonType in ('Клиент') 
		then 1 else 0 end) as outcome_rpc_cnt,

		sum(case when a.CommunicationType = 'Исходящий звонок' 
		and a.PersonType in ('Третье лицо') 
		then 1 else 0 end) as outcome_tpc_cnt,

		--входящие звонки

		sum(case when a.CommunicationType = 'Входящий звонок' 
		and a.PersonType in ('Клиент','Третье лицо') 
		then 1 else 0 end) as income_total_cnt,

		sum(case when a.CommunicationType = 'Входящий звонок' 
		and a.PersonType in ('Клиент') 
		then 1 else 0 end) as income_rpc_cnt,

		sum(case when a.CommunicationType = 'Входящий звонок' 
		and a.PersonType in ('Третье лицо') 
		then 1 else 0 end) as income_tpc_cnt,

		--Обещания

		sum(a.PTP_flag) as ptp_total_cnt,
		sum(case when a.PersonType = 'Клиент' then a.ptp_flag else 0 end) as ptp_rpc_cnt,
		sum(case when a.PersonType = 'Третье лицо' then a.ptp_flag else 0 end) as ptp_tpc_cnt,
		sum(case when a.ptp_flag = 1 then a.due_od_yesterday else 0 end) as ptp_total_rub,
		sum(case when a.ptp_flag = 1 and a.PersonType = 'Клиент' then a.due_od_yesterday else 0 end) as ptp_rpc_rub,
		sum(case when a.ptp_flag = 1 and a.PersonType = 'Третье лицо' then a.due_od_yesterday else 0 end) as ptp_tpc_rub,

		--Сдержанные обещания

		sum(a.success_ptp_flag) as kept_ptp_total_cnt,
		sum(case when a.PersonType = 'Клиент' then a.success_ptp_flag else 0 end) as kept_ptp_rpc_cnt,
		sum(case when a.PersonType = 'Третье лицо' then a.success_ptp_flag else 0 end) as kept_ptp_tpc_cnt,
		sum(case when a.success_ptp_flag = 1 then a.saved_balance else 0 end) as kept_ptp_total_rub,
		sum(case when a.success_ptp_flag = 1 and a.PersonType = 'Клиент' then a.saved_balance else 0 end) as kept_ptp_rpc_rub,
		sum(case when a.success_ptp_flag = 1 and a.PersonType = 'Третье лицо' then a.saved_balance else 0 end) as kept_ptp_tpc_rub,

		--Сумма платежей
		sum(case when a.Success_PTP_flag = 1 then a.pmt_between_comm_ptp else 0 end) as payments

		from #stg_comm_base4 a
		--where a.external_id = '1606022220001'
		--where a.CommunicationDate >= '2020-08-01'
		group by a.external_id, a.CommunicationDate, a.CRMClientStage, a.dpd_bucket

	commit transaction;

	--order by a.external_id, a.CommunicationDate;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#rep_coll_primetime_base';


	--PrimeTime base, key: external_id, CommunicationDate, CommDateHour,
	begin transaction

		delete from dbo.stg_coll_primetime_base
		where CommunicationDate between @dt_from and @dt_to

		insert into dbo.stg_coll_primetime_base
		select 
		a.external_id, 
		datepart(hh,a.CommunicationDateTime) as CommDateHour,
		a.CommunicationDate,

		count(*) as attempt_cnt,

		--Все звонки
		sum(case when a.PersonType in ('Клиент','Третье лицо') 
		then 1 else 0 end) as contact_total_cnt,

		--Обещания
		sum(a.PTP_flag) as ptp_total_cnt,
		sum(case when a.ptp_flag = 1 then a.due_od_yesterday else 0 end) as ptp_total_rub,

		--Сдержанные обещания

		sum(a.success_ptp_flag) as kept_ptp_total_cnt,
		sum(case when a.success_ptp_flag = 1 then a.saved_balance else 0 end) as kept_ptp_total_rub

		from #stg_comm_base4 a
		--where a.external_id = '1606022220001'
		--where a.CommunicationDate >= '2020-08-01'
		group by a.external_id, a.CommunicationDate, datepart(hh,a.CommunicationDateTime)

	commit transaction;
	   	

	/*****************************************************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'REP';


	--Communications отчеты за день/неделю/месяц
	---День
	begin transaction

		delete from dbo.rep_coll_comm_daily

		insert into dbo.rep_coll_comm_daily
		select 
		cast(sysdatetime() as datetime) as dt_dml,
		a.CommunicationDate, a.CRMClientStage, a.dpd_bucket, 
		  sum(a.attempt_cnt			 ) as attempt_cnt				
		, count(distinct a.external_id) as schedule_cnt --sum(a.schedule_cnt) as schedule_cnt		
		, sum(a.contact_total_cnt	 ) as contact_total_cnt	
		, sum(a.outcome_total_cnt	 ) as outcome_total_cnt	
		, sum(a.outcome_rpc_cnt		 ) as outcome_rpc_cnt		
		, sum(a.outcome_tpc_cnt		 ) as outcome_tpc_cnt		
		, sum(a.income_total_cnt	 ) as income_total_cnt	
		, sum(a.income_rpc_cnt		 ) as income_rpc_cnt		
		, sum(a.income_tpc_cnt		 ) as income_tpc_cnt		
		, sum(a.ptp_total_cnt		 ) as ptp_total_cnt		
		, sum(a.ptp_rpc_cnt			 ) as ptp_rpc_cnt			
		, sum(a.ptp_tpc_cnt			 ) as ptp_tpc_cnt			
		, sum(a.ptp_total_rub		 ) as ptp_total_rub		
		, sum(a.ptp_rpc_rub			 ) as ptp_rpc_rub			
		, sum(a.ptp_tpc_rub			 ) as ptp_tpc_rub			
		, sum(a.kept_ptp_total_cnt	 ) as kept_ptp_total_cnt	
		, sum(a.kept_ptp_rpc_cnt	 ) as kept_ptp_rpc_cnt	
		, sum(a.kept_ptp_tpc_cnt	 ) as kept_ptp_tpc_cnt	
		, sum(a.kept_ptp_total_rub	 ) as kept_ptp_total_rub	
		, sum(a.kept_ptp_rpc_rub	 ) as kept_ptp_rpc_rub	
		, sum(a.kept_ptp_tpc_rub	 ) as kept_ptp_tpc_rub	
		, sum(a.contact_rpc_cnt		 ) as contact_rpc_cnt
		, sum(a.contact_tpc_cnt      ) as contact_tpc_cnt
		, sum(a.payments			 ) as payments
		from dbo.stg_coll_comm_base a
		group by a.CommunicationDate, a.CRMClientStage, a.dpd_bucket

	commit transaction;

	--Неделя

	begin transaction

		delete from dbo.rep_coll_comm_weekly

		insert into dbo.rep_coll_comm_weekly
		select 
		cast(sysdatetime() as datetime) as dt_dml,
		a.CommDateWeek, a.CRMClientStage, a.dpd_bucket, 
		  sum(a.attempt_cnt			 ) as attempt_cnt				
		, count(distinct a.external_id) as schedule_cnt 
		, sum(a.contact_total_cnt	 ) as contact_total_cnt	
		, sum(a.outcome_total_cnt	 ) as outcome_total_cnt	
		, sum(a.outcome_rpc_cnt		 ) as outcome_rpc_cnt		
		, sum(a.outcome_tpc_cnt		 ) as outcome_tpc_cnt		
		, sum(a.income_total_cnt	 ) as income_total_cnt	
		, sum(a.income_rpc_cnt		 ) as income_rpc_cnt		
		, sum(a.income_tpc_cnt		 ) as income_tpc_cnt		
		, sum(a.ptp_total_cnt		 ) as ptp_total_cnt		
		, sum(a.ptp_rpc_cnt			 ) as ptp_rpc_cnt			
		, sum(a.ptp_tpc_cnt			 ) as ptp_tpc_cnt			
		, sum(a.ptp_total_rub		 ) as ptp_total_rub		
		, sum(a.ptp_rpc_rub			 ) as ptp_rpc_rub			
		, sum(a.ptp_tpc_rub			 ) as ptp_tpc_rub			
		, sum(a.kept_ptp_total_cnt	 ) as kept_ptp_total_cnt	
		, sum(a.kept_ptp_rpc_cnt	 ) as kept_ptp_rpc_cnt	
		, sum(a.kept_ptp_tpc_cnt	 ) as kept_ptp_tpc_cnt	
		, sum(a.kept_ptp_total_rub	 ) as kept_ptp_total_rub	
		, sum(a.kept_ptp_rpc_rub	 ) as kept_ptp_rpc_rub	
		, sum(a.kept_ptp_tpc_rub	 ) as kept_ptp_tpc_rub	
		, sum(a.contact_rpc_cnt		 ) as contact_rpc_cnt
		, sum(a.contact_tpc_cnt      ) as contact_tpc_cnt
		, sum(a.payments			 ) as payments

		from dbo.stg_coll_comm_base a
		group by a.CommDateWeek, a.CRMClientStage, a.dpd_bucket

	commit transaction;



	--Месяц
	begin transaction

		delete from dbo.rep_coll_comm_monthly

		insert into dbo.rep_coll_comm_monthly
		select 
		cast(sysdatetime() as datetime) as dt_dml,
		a.CommDateMonth, a.CRMClientStage, a.dpd_bucket, 
		  sum(a.attempt_cnt			 ) as attempt_cnt				
		, count(distinct a.external_id) as schedule_cnt 
		, sum(a.contact_total_cnt	 ) as contact_total_cnt	
		, sum(a.outcome_total_cnt	 ) as outcome_total_cnt	
		, sum(a.outcome_rpc_cnt		 ) as outcome_rpc_cnt		
		, sum(a.outcome_tpc_cnt		 ) as outcome_tpc_cnt		
		, sum(a.income_total_cnt	 ) as income_total_cnt	
		, sum(a.income_rpc_cnt		 ) as income_rpc_cnt		
		, sum(a.income_tpc_cnt		 ) as income_tpc_cnt		
		, sum(a.ptp_total_cnt		 ) as ptp_total_cnt		
		, sum(a.ptp_rpc_cnt			 ) as ptp_rpc_cnt			
		, sum(a.ptp_tpc_cnt			 ) as ptp_tpc_cnt			
		, sum(a.ptp_total_rub		 ) as ptp_total_rub		
		, sum(a.ptp_rpc_rub			 ) as ptp_rpc_rub			
		, sum(a.ptp_tpc_rub			 ) as ptp_tpc_rub			
		, sum(a.kept_ptp_total_cnt	 ) as kept_ptp_total_cnt	
		, sum(a.kept_ptp_rpc_cnt	 ) as kept_ptp_rpc_cnt	
		, sum(a.kept_ptp_tpc_cnt	 ) as kept_ptp_tpc_cnt	
		, sum(a.kept_ptp_total_rub	 ) as kept_ptp_total_rub	
		, sum(a.kept_ptp_rpc_rub	 ) as kept_ptp_rpc_rub	
		, sum(a.kept_ptp_tpc_rub	 ) as kept_ptp_tpc_rub	
		, sum(a.contact_rpc_cnt		 ) as contact_rpc_cnt
		, sum(a.contact_tpc_cnt      ) as contact_tpc_cnt
		, sum(a.payments			 ) as payments

		from dbo.stg_coll_comm_base a
		group by a.CommDateMonth, a.CRMClientStage, a.dpd_bucket

	commit transaction;


	/*****************************************************************************/

	--PrimeTime По дням
	begin transaction 

		delete from dbo.rep_coll_prime_time

		insert into dbo.rep_coll_prime_time

		select 
		cast(sysdatetime() as datetime) as dt_dml,
		a.CommunicationDate, a.CommDateHour,
		  sum(a.attempt_cnt			 ) as attempt_cnt	
		, sum(a.contact_total_cnt	 ) as contact_total_cnt	
		, sum(a.ptp_total_cnt		 ) as ptp_total_cnt		
		, sum(a.ptp_total_rub		 ) as ptp_total_rub		
		, sum(a.kept_ptp_total_cnt	 ) as kept_ptp_total_cnt	
		, sum(a.kept_ptp_total_rub	 ) as kept_ptp_total_rub

		from dbo.stg_coll_primetime_base a
		group by a.CommunicationDate, a.CommDateHour

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