

--exec [collection].[say_summary_table_admin_resource_update];

CREATE  	procedure [collection].[say_summary_table_admin_resource_update]

	as
	begin

--------------------------------------------------------------------------------------------------
	--исходный реестр договоров переданных на сопровождение с добавлением известных дат ИП
	drop table if exists #base_list_admin_resource;
	select
			dar.number 'номер договора'
			,d.IdCustomer 'id клиента'
			,dbo.customer_fio(d.IdCustomer) 'фио клиента'
			,dar.type_list 'тип реестра'
			,dar.id_IL 'id ИЛ'
			,seo.[№ ИЛ]
			,seo.[id_залога] 'id залога'
			,btc.dt_closed 'пдп дата'
			,cast(seo. [Дата возбуждения ИП] as date) 'возбуждение ИП дата'
			,cast(seo. [Дата ареста авто] as date) 'арест залога дата'
			,cast(seo. [Дата первых торгов] as date) 'первые торги дата'
			,cast(seo. [Дата вторых торгов] as date) 'вторые торги дата'
			,cast(seo. [Дата принятия на баланс] as date) 'принятие залога на баланс дата'
	into #base_list_admin_resource 
	from
			collection.say_admin_resource_log_deals								dar
			join stg._Collection.deals													d on d.number = dar.number
			left join 
					(
						select
								*
						from
								collection.say_enforcement_proceedings_log_everyday
						where 1=1
								and r_date = (select max(r_date) from collection.say_enforcement_proceedings_log_everyday)
					)																	seo on seo.id_IL = dar.id_IL
			left join
					(
						select 
								IdCustomer
								,Number
								,ChangeDate dt_closed
						from
						(
								select
										d.Number
										,d.IdCustomer
										,cast(dh.ChangeDate as date) ChangeDate
										,ROW_NUMBER() over (partition by d.Number order by dh.ChangeDate desc) rn
								from
										stg._Collection.DealHistory					dh
										join stg._Collection.Deals					d on d.id = dh.ObjectId
								where 1=1
										and dh.field = 'Стадия коллектинга договора'
										and dh.NewValue = 9
						)base_deal_closed
						where 1=1
								and rn = 1
					)																	btc on btc.Number = dar.Number
	;

--------------------------------------------------------------------------------------------------
	--сбор остатка од на дату начала сопровождения и сегодня
	declare @d date = (select max(d) from dwh2.dbo.dm_cmrstatbalance cmr)
	drop table if exists #base_principal_rest;
	select
			external_id
			,cast(coalesce(sum(case when flag_dt = 1 then last_principal_rest end),0) as int) st_principal_rest
			,cast(coalesce(sum(case when flag_dt = 2 then last_principal_rest end),0) as int) end_principal_rest
	into #base_principal_rest
	from
	(	
		select
				d
				,external_id
				,last_principal_rest = prev_od
				,case when d = '2021-08-01' then 1 else 2 end flag_dt
		from
				#base_list_admin_resource							dlar 
				INNER JOIN dwh2.dbo.dm_cmrstatbalance cmr
					on dlar.[номер договора] = cmr.external_id
					
			and (cmr.d= '2021-08-01' or cmr.d= @d)
	)t1
	group by 
			external_id
	;
	

--------------------------------------------------------------------------------------------------
	--сбор сумм cash за 2 месяца до передачи и после до сегодняшнего дня
	drop table if exists #base_sum_pay;
	with stg_coll_bal as 
		(select d as r_date,
			r_year,
			r_month,
    		r_day,
    		external_id,
    		isnull(dpd_coll,0)                     as overdue_days,
    		isnull(dpd_p_coll,0)                   as overdue_days_p,
    		cast(isnull([остаток од],   0) as float) as principal_rest,
    		cast(isnull([остаток од],   0) as float) +
    		cast(isnull([остаток %],    0) as float) as principal_percents_rest,
    		cast(isnull(principal_cnl,    0) as float) +
    		cast(isnull(percents_cnl,     0) as float) +
    		cast(isnull(fines_cnl,        0) as float) +
    		cast(isnull(otherpayments_cnl,0) as float) +
    		cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
			isnull([сумма поступлений], 0) as pay_total_calc,
    		prev_dpd_coll as lag_overdue_days,
    		prev_od as lag_principal_rest,
    		bucket_coll as bucket_coll,
    		bucket_p_coll as bucket_p_coll,
			case when [Тип Продукта] = 'PDL' then 'INSTALLMENT' 
			     when [Тип Продукта] in ('ПТС',  'ПТС31') then 'PTS'  when [Тип Продукта] = 'Инстоллмент' then 'INSTALLMENT' end as product
		from [dwh2].[dbo].[dm_CMRStatBalance]
		)
	select
			external_id
			,cast(coalesce(sum(case when r_date < '2021-08-01' then pay_total end),0) as int) from_sum_pay
			,cast(coalesce(sum(case when r_date >= '2021-08-01' then pay_total end),0) as int) after_sum_pay
	into #base_sum_pay
	from
			stg_coll_bal							mfo
			join #base_list_admin_resource							dlar on dlar.[номер договора] = mfo.external_id
	where 1=1
			and r_date >= '2021-06-01'
	group by 
			external_id
	;

--------------------------------------------------------------------------------------------------
	--сбор данных для ставки в таблицу для отчёта
	drop table if exists #summary_table_admin_resource;
	select
			cast(getdate() as date) dt_rep
			,blar.*
			,coalesce(bpr.st_principal_rest,0) 'од на дату передачи'
			,coalesce(bpr.end_principal_rest,0) 'од на дату отчёта'
			,coalesce(bsp.from_sum_pay,0) 'cash за 2 месяца до передачи'
			,coalesce(bsp.after_sum_pay,0) 'cash после передачи'
	into #summary_table_admin_resource
	from
			#base_list_admin_resource													blar
			left join #base_principal_rest												bpr on bpr.external_id = blar.[номер договора]
			left join #base_sum_pay														bsp on bsp.external_id = blar.[номер договора]
	;

--------------------------------------------------------------------------------------------------

	if OBJECT_ID('collection.say_admin_resource_summary_table') is null
	begin
		select top(0) 
		*
		into collection.say_admin_resource_summary_table
		from #summary_table_admin_resource
		end
	begin
		insert into collection.say_admin_resource_summary_table
		select * from #summary_table_admin_resource
	end
	end
