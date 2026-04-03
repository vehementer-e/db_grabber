  
 
 CREATE PROCEDURE [collection].[etl_say_report_convers_1_90_history] 
	@reloadMonth smallint = 2
   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try
  
  declare @start_dt date =  dateadd(dd,1, EOMONTH(getdate(), -@reloadMonth)); -- первая дата предыдущего месяца - начало сборки отчета
  --select @start_dt;
-------------------------------------------------------------------------------------------------
	--справочник коммуникаций
	
	drop table if exists #spav_comm;
	select *
	into #spav_comm
	from collection.say_sprav_comm_convers_1_90 --сменил на двх2
	;

	EXEC [collection].set_debug_info @sp_name
			,'1';

-------------------------------------------------------------------------------------------------
	--стадия коллектинга договора
	
	-- select * from #stage_history where number = '20120300057716' order by date_stage_begin desc

	drop table if exists #stage_history;
	select t4.number 
		,cast([ChangeDate] as date) date_stage_begin
		,cast(dateadd(dd,-1,lag(t4.[ChangeDate],1,dateadd(dd,1,getdate())) over (partition by number order by [ChangeDate] desc)) as date) date_stage_end
		,name stage_collection
	into #stage_history
	from 
	(
			SELECT t2.number
				,t1.*
				,t3.[name]
				,ROW_NUMBER() over (partition by t2.number, cast([ChangeDate] as date) order by [ChangeDate] desc) aa
			FROM [Stg].[_Collection].[DealHistory] t1
			join [Stg].[_Collection].[Deals] t2 on t2.id = t1.[ObjectId]
			join [Stg].[_Collection].collectingStage t3 on t3.Id = t1.newvalue
			where [Field] = 'Стадия коллектинга договора'
	)t4
	where aa = 1
	;
	--------добавил 020422

	drop table if exists #base_lost_claimant_id;															
	select ObjectId															
			,coalesce(NewValue,0) ClaimantId													
			,dt_rt dt_st													
	into #base_lost_claimant_id															
	from (SELECT [ChangeDate]															
					,cast([ChangeDate] as date) dt_rt											
					,[OldValue]											
					,[NewValue]											
					,[ObjectId]											
					,ROW_NUMBER() over (partition by [ObjectId] order by [ChangeDate] desc) rn											
			FROM [Stg].[_Collection].[CustomerHistory]													
			where 1 = 1													
					and field = 'Ответственный взыскатель')aaa											
	where 1 = 1															
			and rn = 1

	;
	EXEC [collection].set_debug_info @sp_name
			,'2';

-------------------------------------------------------------------------------------------------
	--база договоров

	-- select * from #balance_cmr where external_id = '20120300057716' order by cdate desc
	-- select * from RiskDWH.dbo.stg_coll_bal_cmr where external_id = '20120300057716' order by r_date desc
	
	--select * from #balance_cmr;
	--ALTER TABLE #balance_cmr ADD summ numeric(38,2);
	drop table if exists #balance_cmr;
	select balance_cmr_base.external_id
			,balance_cmr_base.id_deal_space
			,balance_cmr_base.id_customer_spase
			,balance_cmr_base.r_date cdate
			,balance_cmr_base.overdue_days_corr
			,balance_cmr_base.principal_rest
			,balance_cmr_base.stage_collection
			,balance_cmr_base.product_type
			,balance_cmr_base.freeze_flag
			,balance_cmr_base.claimant_fio
			,balance_cmr_base.summ
			--,case when (sum(case when balance_cmr_base.cdate between dateadd(dd,1,promise_start_dt) and promise_end_dt -- отказались от среза "наличие обещания" по договору на стадии
			--	  then 1 else 0 end)) > 0 then 1 else 0 end valid_promises
	into #balance_cmr
	from
	(
		select 
				balance_cmr.external_id
				,deals.Id id_deal_space
				,deals.IdCustomer id_customer_spase
				,balance_cmr.r_date
				,balance_cmr.overdue_days_p as overdue_days_corr
				,balance_cmr.principal_rest
				,stage_history.stage_collection
				,balance_cmr.product_type  --убрал таблицу left join risk.strategy_datamart_hourly d on d.external_id = balance_cmr.external_id
				,case when k.[number] is not null then 'FREEZE' else 'OTHER' end as freeze_flag
				,e.LastName+' '+e.FirstName+' '+e.MiddleName as claimant_fio
				,balance_cmr.summ
		from  ( --select *
				--from RiskDWH.dbo.zzz_coll_bal_cmr_apr_june
				--union all
				select 
				external_id,
				d as r_date,
				dpd_p_coll as overdue_days_p,
				[остаток од] as principal_rest,
				[Сумма] as summ,
				[Тип продукта] as product_type
				from dbo.dm_cmrstatbalance
				--where d < '2020-04-01' or d > '2020-06-30' ---убрали срез
				) balance_cmr
        --left join risk.strategy_datamart_hourly d on d.external_id = balance_cmr.external_id --через источник брал тип продукта
		left join dbo.dm_restructurings  k on balance_cmr.external_id=k.[number] and cast(k.[create_at] as date) =cast(getdate() as date) --and k.[стадия договора] not in ('Closed','Current')	--devDB.dbo.say_log_dogovora_kk вырезал	
	    			
		join [Stg].[_Collection].[Deals] deals on deals.number = balance_cmr.external_id
		join stg._collection.customers c on c.id = deals.idcustomer
        left join #base_lost_claimant_id blc on blc.ObjectId = deals.idcustomer
        left join stg._collection.Employee e on blc.claimantid=e.id


		left join #stage_history stage_history on stage_history.number = balance_cmr.external_id 
												and balance_cmr.r_date between stage_history.date_stage_begin and stage_history.date_stage_end
		where balance_cmr.r_date >= @start_dt
	)balance_cmr_base
	group by balance_cmr_base.external_id
				,balance_cmr_base.id_deal_space
				,balance_cmr_base.id_customer_spase
				,balance_cmr_base.r_date
				,balance_cmr_base.overdue_days_corr
				,balance_cmr_base.principal_rest
				,balance_cmr_base.stage_collection
				,balance_cmr_base.product_type
				,balance_cmr_base.freeze_flag
				,balance_cmr_base.claimant_fio
				,balance_cmr_base.summ
	;

	EXEC [collection].set_debug_info @sp_name
			,'3';

	
-------------------------------------------------------------------------------------------------
	--база платежей
	
	drop table if exists #sum_pay;
	select
			balance_cmr.external_id
			,deals.Id id_deal_space
			,balance_cmr.d as cdate  --change cdate
			,sum(balance_cmr.[сумма поступлений]) sum_pay  --change total_CF 
	into #sum_pay
	from dbo.dm_cmrstatbalance balance_cmr --dwh_new.dbo.v_balance_cmr
	join [Stg].[_Collection].[Deals] deals on deals.number = balance_cmr.external_id
	where 1 = 1
			--and balance_cmr.cdate >= @start_dt
			and balance_cmr.[сумма поступлений] > 0	
	group by balance_cmr.external_id
			,deals.Id
			,balance_cmr.d; --change cdate
	
-------------------------------------------------------------------------------------------------
	--база коммуникаций
	
	drop table if exists #base_comm_all;
	select comm.id id_comm
			,1 cnt
			,comm.iddeal id_deal_space
			,comm.CustomerId id_cust
			,comm.date comm_dt_tm
			,cast(comm.date as date) comm_dt
			,coalesce(cast(comm.PromiseDate as date),'2000-01-01') comm_prom_dt
			,comm_type.name comm_type_name
			,comm_res.name comm_res_name
			,case when cont_type.Id = 3 then 'Не определен' else cont_type.name end cont_type_name
			,comm_type.Id comm_type_id
			,comm_res.Id comm_res_id
			,cont_type.Id cont_type_id
			,coalesce(spav_comm.promise,0) fl_promise
			,coalesce(sum_pay_1.fl_promice_kept,0) fl_promice_kept
			,coalesce(comm.PromiseSum,0) promise_sum
-----------------------unit_attemp	
			,case when comm_type.id = 1 and cont_type.Id = 1 then 1 else 0 end outbound_customer_attemp
			,case when comm_type.id = 2 and cont_type.Id = 1 then 1 else 0 end inbound_customer_attemp
			,case when comm_type.id = 10 and cont_type.Id = 1 then 1 else 0 end message_mess_customer_attemp
			,case when comm_type.id = 11 and cont_type.Id = 1 then 1 else 0 end message_network_customer_attemp
			,case when comm_type.id = 16 and cont_type.Id = 1 then 1 else 0 end message_mobail_customer_attemp
			,case when comm_type.id = 3 and cont_type.Id = 1 then 1 else 0 end visit_customer_attemp
			,case when comm_type.id = 1 and cont_type.Id = 2 then 1 else 0 end outbound_third_person_attemp
			,case when comm_type.id = 2 and cont_type.Id = 2 then 1 else 0 end inbound_third_person_attemp
			,case when comm_type.id = 10 and cont_type.Id = 2 then 1 else 0 end message_mess_third_person_attemp
			,case when comm_type.id = 11 and cont_type.Id = 2 then 1 else 0 end message_network_third_person_attemp
			,case when comm_type.id = 16 and cont_type.Id = 2 then 1 else 0 end message_mobail_third_person_attemp
			,case when comm_type.id = 3 and cont_type.Id = 2 then 1 else 0 end visit_third_person_attemp
			,case when comm_type.id = 1 and cont_type.Id = 3 then 1 else 0 end outbound_Indefined_attemp
			,case when comm_type.id = 2 and cont_type.Id = 3 then 1 else 0 end inbound_Indefined_attemp
			,case when comm_type.id = 10 and cont_type.Id = 3 then 1 else 0 end message_mess_Indefined_attemp
			,case when comm_type.id = 11 and cont_type.Id = 3 then 1 else 0 end message_network_Indefined_attemp
			,case when comm_type.id = 16 and cont_type.Id = 3 then 1 else 0 end message_mobail_Indefined_attemp
			,case when comm_type.id = 3 and cont_type.Id = 3 then 1 else 0 end visit_Indefined_attemp
-----------------------unit_contact
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end outbound_customer_contact
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end inbound_customer_contact
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end message_mess_customer_contact
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end message_network_customer_contact
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end message_mobail_customer_contact
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end visit_customer_contact
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end outbound_third_person_contact
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end inbound_third_person_contact
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end message_mess_third_person_contact
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end message_network_third_person_contact
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end message_mobail_third_person_contact
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end visit_third_person_contact
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end outbound_Indefined_contact
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end inbound_Indefined_contact
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end message_mess_Indefined_contact
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end message_network_Indefined_contact
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end message_mobail_Indefined_contact
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end visit_Indefined_contact
-----------------------unit_promise
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end outbound_customer_promise
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end inbound_customer_promise
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end message_mess_customer_promise
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end message_network_customer_promise
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end message_mobail_customer_promise
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end visit_customer_promise
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end outbound_third_person_promise
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end inbound_third_person_promise
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end message_mess_third_person_promise
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end message_network_third_person_promise
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end message_mobail_third_person_promise
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end visit_third_person_promise
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end outbound_Indefined_promise
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end inbound_Indefined_promise
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end message_mess_Indefined_promise
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end message_network_Indefined_promise
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end message_mobail_Indefined_promise
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end visit_Indefined_promise
-----------------------unit_promise_sum
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_customer_promise_sum
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_customer_promise_sum
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_customer_promise_sum
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_customer_promise_sum
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_customer_promise_sum
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_customer_promise_sum
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_third_person_promise_sum
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_third_person_promise_sum
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_third_person_promise_sum
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_third_person_promise_sum
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_third_person_promise_sum
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_third_person_promise_sum
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_Indefined_promise_sum
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_Indefined_promise_sum
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_Indefined_promise_sum
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_Indefined_promise_sum
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_Indefined_promise_sum
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_Indefined_promise_sum
-----------------------unit_promise_kept
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end outbound_customer_promise_kept
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end inbound_customer_promise_kept
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mess_customer_promise_kept
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_network_customer_promise_kept
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mobail_customer_promise_kept
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end visit_customer_promise_kept
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end outbound_third_person_promise_kept
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end inbound_third_person_promise_kept
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mess_third_person_promise_kept
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_network_third_person_promise_kept
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mobail_third_person_promise_kept
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end visit_third_person_promise_kept
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end outbound_Indefined_promise_kept
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end inbound_Indefined_promise_kept
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mess_Indefined_promise_kept
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_network_Indefined_promise_kept
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end message_mobail_Indefined_promise_kept
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end visit_Indefined_promise_kept
-----------------------unit_promise_kept_sum
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_customer_promise_kept_sum
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_customer_promise_kept_sum
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_customer_promise_kept_sum
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_customer_promise_kept_sum
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_customer_promise_kept_sum
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_customer_promise_kept_sum
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_third_person_promise_kept_sum
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_third_person_promise_kept_sum
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_third_person_promise_kept_sum
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_third_person_promise_kept_sum
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_third_person_promise_kept_sum
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_third_person_promise_kept_sum
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end outbound_Indefined_promise_kept_sum
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end inbound_Indefined_promise_kept_sum
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mess_Indefined_promise_kept_sum
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_network_Indefined_promise_kept_sum
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end message_mobail_Indefined_promise_kept_sum
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end visit_Indefined_promise_kept_sum
-----------------------unit_promise_deferred_promise
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end outbound_customer_deferred_promise
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end inbound_customer_deferred_promise
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mess_customer_deferred_promise
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end message_network_customer_deferred_promise
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mobail_customer_deferred_promise
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end visit_customer_deferred_promise
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end outbound_third_person_deferred_promise
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end inbound_third_person_deferred_promise
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mess_third_person_deferred_promise
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end message_network_third_person_deferred_promise
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mobail_third_person_deferred_promise
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end visit_third_person_deferred_promise
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end outbound_Indefined_deferred_promise
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end inbound_Indefined_deferred_promise
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mess_Indefined_deferred_promise
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end message_network_Indefined_deferred_promise
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end message_mobail_Indefined_deferred_promise
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end visit_Indefined_deferred_promise
-----------------------unit_refusal_to_pay
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end outbound_customer_refusal_to_pay
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end inbound_customer_refusal_to_pay
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mess_customer_refusal_to_pay
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_network_customer_refusal_to_pay
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mobail_customer_refusal_to_pay
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end visit_customer_refusal_to_pay
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end outbound_third_person_refusal_to_pay
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end inbound_third_person_refusal_to_pay
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mess_third_person_refusal_to_pay
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_network_third_person_refusal_to_pay
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mobail_third_person_refusal_to_pay
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end visit_third_person_refusal_to_pay
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end outbound_Indefined_refusal_to_pay
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end inbound_Indefined_refusal_to_pay
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mess_Indefined_refusal_to_pay
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_network_Indefined_refusal_to_pay
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end message_mobail_Indefined_refusal_to_pay
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end visit_Indefined_refusal_to_pay
-----------------------unit_consultation
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end outbound_customer_consultation
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end inbound_customer_consultation
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end message_mess_customer_consultation
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end message_network_customer_consultation
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end message_mobail_customer_consultation
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end visit_customer_consultation
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end outbound_third_person_consultation
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end inbound_third_person_consultation
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end message_mess_third_person_consultation
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end message_network_third_person_consultation
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end message_mobail_third_person_consultation
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end visit_third_person_consultation
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end outbound_Indefined_consultation
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end inbound_Indefined_consultation
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end message_mess_Indefined_consultation
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end message_network_Indefined_consultation
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end message_mobail_Indefined_consultation
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end visit_Indefined_consultation
			
	into #base_comm_all
	from [Stg].[_Collection].[Communications] comm
	
	join #spav_comm spav_comm on spav_comm.comm_type_id = comm.CommunicationType
								and spav_comm.comm_res_id = comm.CommunicationResultId
								and spav_comm.cont_type_id = comm.ContactPersonType
	join [Stg].[_Collection].[communicationType] comm_type on comm_type.Id = comm.CommunicationType
	join [Stg].[_Collection].[CommunicationResult] comm_res on comm_res.Id = comm.CommunicationResultId
	join [Stg].[_Collection].[ContactPersonType] cont_type on cont_type.Id = comm.ContactPersonType
	left join (select comm.id id_comm
						,comm.iddeal id_deal_space
						,cast(comm.date as date) comm_dt
						,coalesce(cast(comm.PromiseDate as date),'2000-01-01') comm_prom_dt
						,coalesce(comm.PromiseSum,0) promise_sum
						,case when sum(sum_pay.sum_pay) > 0
								   and sum(sum_pay.sum_pay) >= coalesce(comm.PromiseSum,0) then 1 else 0 end fl_promice_kept
				from [Stg].[_Collection].[Communications] comm
				join #sum_pay sum_pay on sum_pay.id_deal_space = comm.iddeal
											and sum_pay.cdate between cast(comm.date as date) and coalesce(cast(comm.PromiseDate as date),'2000-01-01')
				group by comm.id
						,comm.iddeal
						,comm.date
						,cast(comm.date as date)
						,coalesce(cast(comm.PromiseDate as date),'2000-01-01')
						,coalesce(comm.PromiseSum,0) 
				having (case when sum(sum_pay.sum_pay) > 0 and sum(sum_pay.sum_pay) >= coalesce(comm.PromiseSum,0) then 1 else 0 end) = 1)sum_pay_1
				on sum_pay_1.id_comm = comm.id
	where 1 = 1
			and cast(comm.date as date) >= @start_dt
	group by comm.id
			,comm.iddeal
			,comm.CustomerId
			,comm.date
			,cast(comm.date as date)
			,coalesce(cast(comm.PromiseDate as date),'2000-01-01')
			,comm_type.Id
			,comm_type.name
			,comm_res.Id
			,comm_res.name
			,cont_type.Id
			,case when cont_type.Id = 3 then 'Не определен' else cont_type.name end
			,coalesce(spav_comm.promise,0)
			,coalesce(sum_pay_1.fl_promice_kept,0)
			,coalesce(comm.PromiseSum,0)
-----------------------unit_attemp	
			,(case when comm_type.id = 1 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 then 1 else 0 end )
-----------------------unit_contact
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.contact = 1 then 1 else 0 end )
-----------------------unit_promise
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 then 1 else 0 end )
-----------------------unit_promise_sum
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 then coalesce(comm.PromiseSum,0) else 0 end
-----------------------unit_promise_kept
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then 1 else 0 end )
-----------------------unit_promise_kept_sum
			,case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
			,case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.promise = 1 and coalesce(sum_pay_1.fl_promice_kept,0) = 1 then coalesce(comm.PromiseSum,0) else 0 end
-----------------------unit_promise_deferred_promise
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.deferred_promise = 1 then 1 else 0 end )
-----------------------unit_refusal_to_pay
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.refusal_to_pay = 1 then 1 else 0 end )
-----------------------unit_consultation
			,(case when comm_type.id = 1 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 1 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 2 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 1 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 2 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 10 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 11 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 16 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			,(case when comm_type.id = 3 and cont_type.Id = 3 and spav_comm.consultation = 1 then 1 else 0 end )
			
			;

			EXEC [collection].set_debug_info @sp_name
			,'4';

-----------------------------------------------------------
	--агригирование коммуникаций
	
	drop table if exists #base_comm_agg;
	select id_deal_space
			,comm_dt
			,attempt_total = sum(outbound_customer_attemp+ 	message_mess_customer_attemp+ 	message_network_customer_attemp+ 	visit_customer_attemp+ 	outbound_third_person_attemp+ 	message_mess_third_person_attemp+ 	message_network_third_person_attemp+ 	visit_third_person_attemp+ 	outbound_Indefined_attemp+ 	message_mess_Indefined_attemp+ 	message_network_Indefined_attemp+ 	visit_Indefined_attemp)
			,attempt_fact = max(outbound_customer_attemp+ 	message_mess_customer_attemp+ 	message_network_customer_attemp+ 	visit_customer_attemp+ 	outbound_third_person_attemp+ 	message_mess_third_person_attemp+ 	message_network_third_person_attemp+ 	visit_third_person_attemp+ 	outbound_Indefined_attemp+ 	message_mess_Indefined_attemp+ 	message_network_Indefined_attemp+ 	visit_Indefined_attemp)
			,attempt_calls = sum(outbound_customer_attemp+ 	outbound_third_person_attemp+ 	outbound_Indefined_attemp)
			,attempt_internet = sum(message_mess_customer_attemp+ 	message_network_customer_attemp+ 	message_mess_third_person_attemp+ 	message_network_third_person_attemp+ 	message_mess_Indefined_attemp+ 	message_network_Indefined_attemp)
			,contacts_fact = max(outbound_customer_contact+ 	message_mess_customer_contact+ 	message_network_customer_contact+ 	visit_customer_contact+ 	outbound_third_person_contact+ 	message_mess_third_person_contact+ 	message_network_third_person_contact+ 	visit_third_person_contact+ 	outbound_Indefined_contact+ 	message_mess_Indefined_contact+ 	message_network_Indefined_contact+ 	visit_Indefined_contact)
			,contacts_total = sum(outbound_customer_contact+ 	message_mess_customer_contact+ 	message_network_customer_contact+ 	visit_customer_contact+ 	outbound_third_person_contact+ 	message_mess_third_person_contact+ 	message_network_third_person_contact+ 	visit_third_person_contact+ 	outbound_Indefined_contact+ 	message_mess_Indefined_contact+ 	message_network_Indefined_contact+ 	visit_Indefined_contact)
			,contacts_total_rpc = sum(outbound_customer_contact+ 	message_mess_customer_contact+ 	message_network_customer_contact+ 	visit_customer_contact)
			,contacts_total_tpc = sum(outbound_third_person_contact+ 	message_mess_third_person_contact+ 	message_network_third_person_contact+ 	visit_third_person_contact)
			,contacts_calls = sum(outbound_customer_contact+ 	outbound_third_person_contact+ 	outbound_Indefined_contact)
			,contacts_calls_rpc = sum(outbound_customer_contact)
			,contacts_calls_tpc = sum(outbound_third_person_contact)
			,contacts_internet = sum(message_mess_customer_contact+ 	message_network_customer_contact+ 	message_mess_third_person_contact+ 	message_network_third_person_contact+ 	message_mess_Indefined_contact+ 	message_network_Indefined_contact)
			,contacts_internet_rpc = sum(message_mess_customer_contact+ 	message_network_customer_contact)
			,contacts_internet_tpc = sum(message_mess_third_person_contact+ 	message_network_third_person_contact)
			,contacts_visit = sum(visit_customer_contact+ 	visit_third_person_contact+ 	visit_Indefined_contact)
			,contacts_visit_rpc = sum(visit_customer_contact)
			,contacts_visit_tpc = sum(visit_third_person_contact)
			,promise_fact = max(outbound_customer_promise+ 	message_mess_customer_promise+ 	message_network_customer_promise+ 	visit_customer_promise+ 	outbound_third_person_promise+ 	message_mess_third_person_promise+ 	message_network_third_person_promise+ 	visit_third_person_promise+ 	outbound_Indefined_promise+ 	message_mess_Indefined_promise+ 	message_network_Indefined_promise+ 	visit_Indefined_promise)
			,promise_total = sum(outbound_customer_promise+ 	message_mess_customer_promise+ 	message_network_customer_promise+ 	visit_customer_promise+ 	outbound_third_person_promise+ 	message_mess_third_person_promise+ 	message_network_third_person_promise+ 	visit_third_person_promise+ 	outbound_Indefined_promise+ 	message_mess_Indefined_promise+ 	message_network_Indefined_promise+ 	visit_Indefined_promise)
			,promise_total_rpc = sum(outbound_customer_promise+ 	message_mess_customer_promise+ 	message_network_customer_promise+ 	visit_customer_promise)
			,promise_total_tpc = sum(outbound_third_person_promise+ 	message_mess_third_person_promise+ 	message_network_third_person_promise+ 	visit_third_person_promise)
			,promise_calls = sum(outbound_customer_promise+ 	outbound_third_person_promise+ 	outbound_Indefined_promise)
			,promise_calls_rpc = sum(outbound_customer_promise)
			,promise_calls_tpc = sum(outbound_third_person_promise)
			,promise_internet = sum(message_mess_customer_promise+ 	message_network_customer_promise+ 	message_mess_third_person_promise+ 	message_network_third_person_promise+ 	message_mess_Indefined_promise+ 	message_network_Indefined_promise)
			,promise_internet_rpc = sum(message_mess_customer_promise+ 	message_network_customer_promise)
			,promise_internet_tpc = sum(message_mess_third_person_promise+ 	message_network_third_person_promise)
			,promise_visit = sum(visit_customer_promise+ 	visit_third_person_promise+ 	visit_Indefined_promise)
			,promise_visit_rpc = sum(visit_customer_promise)
			,promise_visit_tpc = sum(visit_third_person_promise)
			,promise_total_rur = sum(outbound_customer_promise_sum+	message_mess_customer_promise_sum+	message_network_customer_promise_sum+	visit_customer_promise_sum+	outbound_third_person_promise_sum+	message_mess_third_person_promise_sum+	message_network_third_person_promise_sum+	visit_third_person_promise_sum+	outbound_Indefined_promise_sum+	message_mess_Indefined_promise_sum+	message_network_Indefined_promise_sum+	visit_Indefined_promise_sum)
			,promise_total_rpc_rur = sum(outbound_customer_promise_sum+	message_mess_customer_promise_sum+	message_network_customer_promise_sum+	visit_customer_promise_sum)
			,promise_total_tpc_rur = sum(outbound_third_person_promise_sum+	message_mess_third_person_promise_sum+	message_network_third_person_promise_sum+	visit_third_person_promise_sum+	outbound_Indefined_promise_sum)
			,promise_kept_fact = max(outbound_customer_promise_kept+ 	message_mess_customer_promise_kept+ 	message_network_customer_promise_kept+ 	visit_customer_promise_kept+ 	outbound_third_person_promise_kept+ 	message_mess_third_person_promise_kept+ 	message_network_third_person_promise_kept+ 	visit_third_person_promise_kept+ 	outbound_Indefined_promise_kept+ 	message_mess_Indefined_promise_kept+ 	message_network_Indefined_promise_kept+ 	visit_Indefined_promise_kept)
			,promise_kept_total = sum(outbound_customer_promise_kept+ 	message_mess_customer_promise_kept+ 	message_network_customer_promise_kept+ 	visit_customer_promise_kept+ 	outbound_third_person_promise_kept+ 	message_mess_third_person_promise_kept+ 	message_network_third_person_promise_kept+ 	visit_third_person_promise_kept+ 	outbound_Indefined_promise_kept+ 	message_mess_Indefined_promise_kept+ 	message_network_Indefined_promise_kept+ 	visit_Indefined_promise_kept)
			,promise_kept_total_rpc = sum(outbound_customer_promise_kept+ 	message_mess_customer_promise_kept+ 	message_network_customer_promise_kept+ 	visit_customer_promise_kept)
			,promise_kept_total_tpc = sum(outbound_third_person_promise_kept+ 	message_mess_third_person_promise_kept+ 	message_network_third_person_promise_kept+ 	visit_third_person_promise_kept)
			,promise_kept_calls = sum(outbound_customer_promise_kept+ 	outbound_third_person_promise_kept+ 	outbound_Indefined_promise_kept)
			,promise_kept_calls_rpc = sum(outbound_customer_promise_kept)
			,promise_kept_calls_tpc = sum(outbound_third_person_promise_kept)
			,promise_kept_internet = sum(message_mess_customer_promise_kept+ 	message_network_customer_promise_kept+ 	message_mess_third_person_promise_kept+ 	message_network_third_person_promise_kept+ 	message_mess_Indefined_promise_kept+ 	message_network_Indefined_promise_kept)
			,promise_kept_internet_rpc = sum(message_mess_customer_promise_kept+ 	message_network_customer_promise_kept)
			,promise_kept_internet_tpc = sum(message_mess_third_person_promise_kept+ 	message_network_third_person_promise_kept)
			,promise_kept_visit = sum(visit_customer_promise_kept+ 	visit_third_person_promise_kept+ 	visit_Indefined_promise_kept)
			,promise_kept_visit_rpc = sum(visit_customer_promise_kept)
			,promise_kept_visit_tpc = sum(visit_third_person_promise_kept)
			,promise_kept_total_rur = sum(outbound_customer_promise_kept_sum+	message_mess_customer_promise_kept_sum+	message_network_customer_promise_kept_sum+	visit_customer_promise_kept_sum+	outbound_third_person_promise_kept_sum+	message_mess_third_person_promise_kept_sum+	message_network_third_person_promise_kept_sum+	visit_third_person_promise_kept_sum+	outbound_Indefined_promise_kept_sum+	message_mess_Indefined_promise_kept_sum+	message_network_Indefined_promise_kept_sum+	visit_Indefined_promise_kept_sum)
			,promise_kept_total_rpc_rur = sum(outbound_customer_promise_kept_sum+	message_mess_customer_promise_kept_sum+	message_network_customer_promise_kept_sum+	visit_customer_promise_kept_sum)
			,promise_kept_total_tpc_rur = sum(outbound_third_person_promise_kept_sum+	message_mess_third_person_promise_kept_sum+	message_network_third_person_promise_kept_sum+	visit_third_person_promise_kept_sum+	outbound_Indefined_promise_kept_sum)
			,deferred_promise_total = sum(outbound_customer_deferred_promise+ 	message_mess_customer_deferred_promise+ 	message_network_customer_deferred_promise+ 	visit_customer_deferred_promise+ 	outbound_third_person_deferred_promise+ 	message_mess_third_person_deferred_promise+ 	message_network_third_person_deferred_promise+ 	visit_third_person_deferred_promise+ 	outbound_Indefined_deferred_promise+ 	message_mess_Indefined_deferred_promise+ 	message_network_Indefined_deferred_promise+ 	visit_Indefined_deferred_promise)
			,refusal_to_pay_total = sum(outbound_customer_refusal_to_pay+ 	message_mess_customer_refusal_to_pay+ 	message_network_customer_refusal_to_pay+ 	visit_customer_refusal_to_pay+ 	outbound_third_person_refusal_to_pay+ 	message_mess_third_person_refusal_to_pay+ 	message_network_third_person_refusal_to_pay+ 	visit_third_person_refusal_to_pay+ 	outbound_Indefined_refusal_to_pay+ 	message_mess_Indefined_refusal_to_pay+ 	message_network_Indefined_refusal_to_pay+ 	visit_Indefined_refusal_to_pay)
			,consultation_total = sum(outbound_customer_consultation+ 	message_mess_customer_consultation+ 	message_network_customer_consultation+ 	visit_customer_consultation+ 	outbound_third_person_consultation+ 	message_mess_third_person_consultation+ 	message_network_third_person_consultation+ 	visit_third_person_consultation+ 	outbound_Indefined_consultation+ 	message_mess_Indefined_consultation+ 	message_network_Indefined_consultation+ 	visit_Indefined_consultation)
	into #base_comm_agg
	from #base_comm_all base_comm_all
	group by id_deal_space
			,comm_dt
			;

			EXEC [collection].set_debug_info @sp_name
			,'5';


-----------------------------------------------------------
	--агрегирование коммуникаций входящего звонка
	

-----------------------------------------------------------
	--агригирование коммуникаций Мобильное приложение
	
	---------------------------------------------------------------------------
-- договоры, которые в листах
	drop table if exists #call_list_base;
	select ccd.DealNumber
			,deals.id id_deal_space
			,ccd.ProjectUID
			,ccd.CreateDate report_dt_tm
			,cast(ccd.CreateDate as date) report_dt
			,ccd.StrategyActionId
			,ccd.ProjectName
			,case when lower(ccd.ProjectName) like '%Predel%' then 'Predelinquency'
				  when lower(ccd.ProjectName) like '%Soft%' then 'Soft'
				  when lower(ccd.ProjectName) like '%Midle%' then 'Middle'
				  when lower(ccd.ProjectName) like '%PreLegal%' then 'Prelegal'
				  end coll_stage_list
	into #call_list_base
	from stg._collection.CallCaseData ccd
	join stg._collection.NaumenCampaigns nc on nc.name = ccd.ProjectName
	join stg._Collection.Deals deals on deals.Number = ccd.DealNumber
	where 1 = 1
			and lower(nc.DisplayName) not like '%автоинформатор%'
			and ccd.CaseUrl is not null
	;

-- договоры, которые на стадии,в т.ч. в листах
	drop table if exists #report_convers_1_90;
	select balance_cmr.external_id
			,balance_cmr.cdate
			,dateadd(day,- datepart(day,balance_cmr.cdate) + 1, convert(date,balance_cmr.cdate)) month_report
			,datepart(ww,dateadd(dd,-1,balance_cmr.cdate)) week_report
			,case when balance_cmr.overdue_days_corr > 90 then '[04.91+]'
					when balance_cmr.overdue_days_corr > 60 then '[03.61-90]'
					when balance_cmr.overdue_days_corr > 30 then '[02.31-60]'
					when balance_cmr.overdue_days_corr > 00 then '[01.01-30]'
															else '[0.0]' end bucket_overdue
			,balance_cmr.stage_collection
			,case when call_list_base.id_deal_space is not null
				  then '01.dailer'
				  else '03.other' end type_strategy
			,case when call_list_base.id_deal_space is not null then 1 else 0 end deal_calllist
			,case when call_list_base.id_deal_space is null
				  then 1 else 0 end deal_other
			,coalesce(balance_cmr.principal_rest,0) principal_rest
			,1 amount_deals
			,coalesce(base_comm_agg.attempt_fact,0) attempt_fact
			,coalesce(base_comm_agg.attempt_total,0) attempt_total
			,coalesce(base_comm_agg.attempt_calls,0) attempt_calls
			,coalesce(base_comm_agg.attempt_internet,0) attempt_internet
			,coalesce(base_comm_agg.contacts_fact,0) contacts_fact
			,coalesce(base_comm_agg.contacts_total,0) contacts_total
			,coalesce(base_comm_agg.contacts_total_rpc,0) contacts_total_rpc
			,coalesce(base_comm_agg.contacts_total_tpc,0) contacts_total_tpc
			,coalesce(base_comm_agg.contacts_calls,0) contacts_calls
			,coalesce(base_comm_agg.contacts_calls_rpc,0) contacts_calls_rpc
			,coalesce(base_comm_agg.contacts_calls_tpc,0) contacts_calls_tpc
			,coalesce(base_comm_agg.contacts_internet,0) contacts_internet
			,coalesce(base_comm_agg.contacts_internet_rpc,0) contacts_internet_rpc
			,coalesce(base_comm_agg.contacts_internet_tpc,0) contacts_internet_tpc
			,coalesce(base_comm_agg.contacts_visit,0) contacts_visit
			,coalesce(base_comm_agg.contacts_visit_rpc,0) contacts_visit_rpc
			,coalesce(base_comm_agg.contacts_visit_tpc,0) contacts_visit_tpc
			,coalesce(base_comm_agg.promise_fact,0) promise_fact
			,coalesce(base_comm_agg.promise_total,0) promise_total
			,coalesce(base_comm_agg.promise_total_rpc,0) promise_total_rpc
			,coalesce(base_comm_agg.promise_total_tpc,0) promise_total_tpc
			,coalesce(base_comm_agg.promise_calls,0) promise_calls
			,coalesce(base_comm_agg.promise_calls_rpc,0) promise_calls_rpc
			,coalesce(base_comm_agg.promise_calls_tpc,0) promise_calls_tpc
			,coalesce(base_comm_agg.promise_internet,0) promise_internet
			,coalesce(base_comm_agg.promise_internet_rpc,0) promise_internet_rpc
			,coalesce(base_comm_agg.promise_internet_tpc,0) promise_internet_tpc
			,coalesce(base_comm_agg.promise_visit,0) promise_visit
			,coalesce(base_comm_agg.promise_visit_rpc,0) promise_visit_rpc
			,coalesce(base_comm_agg.promise_visit_tpc,0) promise_visit_tpc
			,coalesce(base_comm_agg.promise_total_rur,0) promise_total_rur
			,coalesce(base_comm_agg.promise_total_rpc_rur,0) promise_total_rpc_rur
			,coalesce(base_comm_agg.promise_total_tpc_rur,0) promise_total_tpc_rur
			,coalesce(base_comm_agg.promise_kept_fact,0) promise_kept_fact
			,coalesce(base_comm_agg.promise_kept_total,0) promise_kept_total
			,coalesce(base_comm_agg.promise_kept_total_rpc,0) promise_kept_total_rpc
			,coalesce(base_comm_agg.promise_kept_total_tpc,0) promise_kept_total_tpc
			,coalesce(base_comm_agg.promise_kept_calls,0) promise_kept_calls
			,coalesce(base_comm_agg.promise_kept_calls_rpc,0) promise_kept_calls_rpc
			,coalesce(base_comm_agg.promise_kept_calls_tpc,0) promise_kept_calls_tpc
			,coalesce(base_comm_agg.promise_kept_internet,0) promise_kept_internet
			,coalesce(base_comm_agg.promise_kept_internet_rpc,0) promise_kept_internet_rpc
			,coalesce(base_comm_agg.promise_kept_internet_tpc,0) promise_kept_internet_tpc
			,coalesce(base_comm_agg.promise_kept_visit,0) promise_kept_visit
			,coalesce(base_comm_agg.promise_kept_visit_rpc,0) promise_kept_visit_rpc
			,coalesce(base_comm_agg.promise_kept_visit_tpc,0) promise_kept_visit_tpc
			,coalesce(base_comm_agg.promise_kept_total_rur,0) promise_kept_total_rur
			,coalesce(base_comm_agg.promise_kept_total_rpc_rur,0) promise_kept_total_rpc_rur
			,coalesce(base_comm_agg.promise_kept_total_tpc_rur,0) promise_kept_total_tpc_rur
			,coalesce(base_comm_agg.deferred_promise_total,0) deferred_promise_total
			,coalesce(base_comm_agg.refusal_to_pay_total,0) refusal_to_pay_total
			,coalesce(base_comm_agg.consultation_total,0) consultation_total
			,case when coalesce(base_comm_agg.promise_total,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_total_debt_rur
			,case when coalesce(base_comm_agg.promise_total_rpc,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_total_rpc_debt_rur
			,case when coalesce(base_comm_agg.promise_total_tpc,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_total_tpc_debt_rur
			,case when coalesce(base_comm_agg.promise_kept_total,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_kept_total_debt_rur
			,case when coalesce(base_comm_agg.promise_kept_total_rpc,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_kept_total_rpc_debt_rur
			,case when coalesce(base_comm_agg.promise_kept_total_tpc,0) > 0 then coalesce(balance_cmr.principal_rest,0) else 0 end promise_kept_total_tpc_debt_rur
	        ,balance_cmr.product_type
			,balance_cmr.freeze_flag
			,balance_cmr.claimant_fio
			,coalesce(balance_cmr.summ,0) summ
	
	into  #report_convers_1_90
	from #balance_cmr balance_cmr
	left join #call_list_base call_list_base on call_list_base.id_deal_space = balance_cmr.id_deal_space
												and call_list_base.report_dt = balance_cmr.cdate
												and call_list_base.coll_stage_list = balance_cmr.stage_collection
	left join #base_comm_agg base_comm_agg on base_comm_agg.id_deal_space = balance_cmr.id_deal_space
											and base_comm_agg.comm_dt = balance_cmr.cdate
	where 1 = 1
			and balance_cmr.cdate < cast(getdate() as date)
			and balance_cmr.cdate >=@start_dt --@start_dt
			and balance_cmr.cdate not in (
											'2020-01-01'
											,'2020-01-02'
											,'2021-01-01'
											,'2021-01-02'
											--,'2021-02-14'
											)
			and	balance_cmr.stage_collection  in ('Predelinquency'
													,'Soft'
													,'Middle'
													,'Prelegal'
													,'Skip'
													,'Hard'
													,'Legal'
													,'ИП')
	;

	EXEC [collection].set_debug_info @sp_name
			,'6';


--------------------------------------------------------------------------------------
-- сбор отчетной таблицы таблицы devDB.dbo.say_report_convers_1_90_history

--ALTER TABLE devDB.dbo.say_report_convers_1_90_history ADD product_type varchar (255)
--drop column product_type from devDB.dbo.say_report_convers_1_90_history

 BEGIN TRANSACTION



	delete from collection.say_report_convers_1_90_history where [отчетный_месяц] >=@start_dt;               --@start_dt;
	insert collection.say_report_convers_1_90_history(

       [номер_договора]
      ,[отчетная_дата]
      ,[отчетный_месяц]
      ,[неделя_в_году]
      ,[бакет_просрочки]
      ,[стадия_взыскания]
      ,[тип_взыскания]
      ,[договор_в_дайлере]
      ,[договор_вне_дайлера]
      ,[кол_во_договоров_на_стадии]
      ,[кол_во_договоров_с_попытками]
      ,[кол_во_попыток]
      ,[кол_во_попыток_звонком]
      ,[кол_во_попыток_интернетом]
      ,[факт_контакта]
      ,[кол_во_контактов]
      ,[кол_во_контактов_с_клиентом]
      ,[кол_во_контактов_с_третьим_лицом]
      ,[кол_во_контактов_звонком]
      ,[кол_во_контактов_звонком_с_клиентом]
      ,[кол_во_контактов_звонком_с_третьим_лицом]
      ,[кол_во_контактов_интернетом]
      ,[кол_во_контактов_интернетом_с_клиентом]
      ,[кол_во_контактов_интернетом_с_третьим_лицом]
      ,[кол_во_контактов_выездом]
      ,[кол_во_контактов_выездом_с_клиентом]
      ,[кол_во_контактов_выездом_с_третьим_лицом]
      ,[факт_обещания]
      ,[кол_во_обещаний]
      ,[кол_во_обещаний_с_клиентом]
      ,[кол_во_обещаний_с_третьим_лицом]
      ,[кол_во_обещаний_звонком]
      ,[кол_во_обещаний_звонком_с_клиентом]
      ,[кол_во_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_обещаний_интернетом]
      ,[кол_во_обещаний_интернетом_с_клиентом]
      ,[кол_во_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_обещаний_выездом]
      ,[кол_во_обещаний_выездом_с_клиентом]
      ,[кол_во_обещаний_выездом_с_третьим_лицом]
      ,[сумма_обещаний]
      ,[сумма_обещаний_с_клиентом]
      ,[сумма_обещаний_с_третьим_лицом]
      ,[факт_исполненного_обещания]
      ,[кол_во_исполненных_обещаний]
      ,[кол_во_исполненных_обещаний_с_клиентом]
      ,[кол_во_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_звонком]
      ,[кол_во_исполненных_обещаний_звонком_с_клиентом]
      ,[кол_во_исполненных_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_интернетом]
      ,[кол_во_исполненных_обещаний_интернетом_с_клиентом]
      ,[кол_во_исполненных_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_выездом]
      ,[кол_во_исполненных_обещаний_выездом_с_клиентом]
      ,[кол_во_исполненных_обещаний_выездом_с_третьим_лицом]
      ,[сумма_исполненных_обещаний]
      ,[сумма_исполненных_обещаний_с_клиентом]
      ,[сумма_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_отложенных_обещаний]
      ,[кол_вот_отказов_от_оплаты]
      ,[кол_во_консультаций]
      ,[сумма_остатка_од]
      ,[сумма_остатка_од_по_обещанию]
      ,[сумма_остатка_од_по_обещанию_от_клиента]
      ,[сумма_остатка_од_по_обещанию_от_третьего_лица]
      ,[сумма_остатка_од_по_исполненному_обещанию]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_клиента]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_третьего_лица]
      ,[product_type]
      ,[freeze_flag]
      ,[claimant_fio]
      ,[summ]



)

	select /*external_id*/ 'all_deals'
	        --,case when product_type='PTS' then 1 else 2 end as product_type
			
			,cdate
			,month_report
			,week_report
			,bucket_overdue
			,stage_collection
			,type_strategy
			,sum(deal_calllist) deal_calllist
			,sum(deal_other) deal_other
			,sum(amount_deals) amount_deals
			,sum(attempt_fact) attempt_fact
			,sum(attempt_total) attempt_total
			,sum(attempt_calls) attempt_calls
			,sum(attempt_internet) attempt_internet
			,sum(contacts_fact) contacts_fact
			,sum(contacts_total) contacts_total
			,sum(contacts_total_rpc)
			,sum(contacts_total_tpc)
			,sum(contacts_calls) contacts_calls
			,sum(contacts_calls_rpc) contacts_calls_rpc
			,sum(contacts_calls_tpc) contacts_calls_tpc
			,sum(contacts_internet) contacts_internet
			,sum(contacts_internet_rpc) contacts_internet_rpc
			,sum(contacts_internet_tpc) contacts_internet_tpc
			,sum(contacts_visit) contacts_visit
			,sum(contacts_visit_rpc) contacts_visit_rpc
			,sum(contacts_visit_tpc) contacts_visit_tpc
			,sum(promise_fact) promise_fact
			,sum(promise_total) promise_total
			,sum(promise_total_rpc) promise_total_rpc
			,sum(promise_total_tpc) promise_total_tpc
			,sum(promise_calls) promise_calls
			,sum(promise_calls_rpc) promise_calls_rpc
			,sum(promise_calls_tpc) promise_calls_tpc
			,sum(promise_internet) promise_internet
			,sum(promise_internet_rpc) promise_internet_rpc
			,sum(promise_internet_tpc) promise_internet_tpc
			,sum(promise_visit) promise_visit
			,sum(promise_visit_rpc) promise_visit_rpc
			,sum(promise_visit_tpc) promise_visit_tpc
			,sum(promise_total_rur) promise_total_rur
			,sum(promise_total_rpc_rur) promise_total_rpc_rur
			,sum(promise_total_tpc_rur) promise_total_tpc_rur
			,sum(promise_kept_fact) promise_kept_fact
			,sum(promise_kept_total) promise_kept_total
			,sum(promise_kept_total_rpc) promise_kept_total_rpc
			,sum(promise_kept_total_tpc) promise_kept_total_tpc
			,sum(promise_kept_calls) promise_kept_calls
			,sum(promise_kept_calls_rpc) promise_kept_calls_rpc
			,sum(promise_kept_calls_tpc) promise_kept_calls_tpc
			,sum(promise_kept_internet) promise_kept_internet
			,sum(promise_kept_internet_rpc) promise_kept_internet_rpc
			,sum(promise_kept_internet_tpc) promise_kept_internet_tpc
			,sum(promise_kept_visit) promise_kept_visit
			,sum(promise_kept_visit_rpc) promise_kept_visit_rpc
			,sum(promise_kept_visit_tpc) promise_kept_visit_tpc
			,sum(promise_kept_total_rur) promise_kept_total_rur
			,sum(promise_kept_total_rpc_rur) promise_kept_total_rpc_rur
			,sum(promise_kept_total_tpc_rur) promise_kept_total_tpc_rur
			,sum(deferred_promise_total) deferred_promise_total
			,sum(refusal_to_pay_total) refusal_to_pay_total
			,sum(consultation_total) consultation_total
			,sum(principal_rest) consultation_total
			,sum(promise_total_debt_rur) promise_total_debt_rur
			,sum(promise_total_rpc_debt_rur) promise_total_rpc_debt_rur
			,sum(promise_total_tpc_debt_rur) promise_total_tpc_debt_rur
			,sum(promise_kept_total_debt_rur) promise_kept_total_debt_rur
			,sum(promise_kept_total_rpc_debt_rur) promise_kept_total_rpc_debt_rur
			,sum(promise_kept_total_tpc_debt_rur) promise_kept_total_tpc_debt_rur
			,product_type
			,freeze_flag
			,claimant_fio
			--,max(summ) 


						,CASE 
        WHEN summ =3000 THEN '[01.3000]' 
        WHEN summ>3000 AND summ <=5000 THEN '[02.3001-5000]' 
        WHEN summ >5000 AND summ <=10000 THEN '[03.5001-10000]' 
        WHEN summ > 10000 AND summ <=30000 THEN '[04.10001-30000]'
        WHEN summ>30000 AND summ<=50000 THEN '[05.30001-50000]' 
        WHEN summ>50000 THEN '[06.50000 и больше]'
    
    END 




	--select * from #report_convers_1_90;
	--ALTER TABLE #report_convers_1_90 ADD summ numeric(38,2);		
	from #report_convers_1_90
	where month_report >= @start_dt  --@start_dt
	group by --external_id ---добавленна групировка
	            cdate
				,
							CASE 
        WHEN summ =3000 THEN '[01.3000]' 
        WHEN summ>3000 AND summ <=5000 THEN '[02.3001-5000]' 
        WHEN summ >5000 AND summ <=10000 THEN '[03.5001-10000]' 
        WHEN summ > 10000 AND summ <=30000 THEN '[04.10001-30000]'
        WHEN summ>30000 AND summ<=50000 THEN '[05.30001-50000]' 
        WHEN summ>50000 THEN '[06.50000 и больше]'
    
    END 
	            ,product_type
				,freeze_flag
	            ,month_report
				,week_report
				,bucket_overdue
				,stage_collection
				,type_strategy
				,claimant_fio
	;

-- сбор отчетной таблицы таблицы devDB.dbo.say_report_convers_1_90_cm

--ALTER TABLE devDB.dbo.say_report_convers_1_90_cm ADD product_type varchar (255)



	/*delete from collection.say_report_convers_1_90_cm;
	insert collection.say_report_convers_1_90_cm (

	[номер_договора]
      ,[отчетная_дата]
      ,[отчетный_месяц]
      ,[неделя_в_году]
      ,[бакет_просрочки]
      ,[стадия_взыскания]
      ,[тип_взыскания]
      ,[договор_в_дайлере]
      ,[договор_вне_дайлера]
      ,[кол_во_договоров_на_стадии]
      ,[кол_во_договоров_с_попытками]
      ,[кол_во_попыток]
      ,[кол_во_попыток_звонком]
      ,[кол_во_попыток_интернетом]
      ,[факт_контакта]
      ,[кол_во_контактов]
      ,[кол_во_контактов_с_клиентом]
      ,[кол_во_контактов_с_третьим_лицом]
      ,[кол_во_контактов_звонком]
      ,[кол_во_контактов_звонком_с_клиентом]
      ,[кол_во_контактов_звонком_с_третьим_лицом]
      ,[кол_во_контактов_интернетом]
      ,[кол_во_контактов_интернетом_с_клиентом]
      ,[кол_во_контактов_интернетом_с_третьим_лицом]
      ,[кол_во_контактов_выездом]
      ,[кол_во_контактов_выездом_с_клиентом]
      ,[кол_во_контактов_выездом_с_третьим_лицом]
      ,[факт_обещания]
      ,[кол_во_обещаний]
      ,[кол_во_обещаний_с_клиентом]
      ,[кол_во_обещаний_с_третьим_лицом]
      ,[кол_во_обещаний_звонком]
      ,[кол_во_обещаний_звонком_с_клиентом]
      ,[кол_во_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_обещаний_интернетом]
      ,[кол_во_обещаний_интернетом_с_клиентом]
      ,[кол_во_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_обещаний_выездом]
      ,[кол_во_обещаний_выездом_с_клиентом]
      ,[кол_во_обещаний_выездом_с_третьим_лицом]
      ,[сумма_обещаний]
      ,[сумма_обещаний_с_клиентом]
      ,[сумма_обещаний_с_третьим_лицом]
      ,[факт_исполненного_обещания]
      ,[кол_во_исполненных_обещаний]
      ,[кол_во_исполненных_обещаний_с_клиентом]
      ,[кол_во_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_звонком]
      ,[кол_во_исполненных_обещаний_звонком_с_клиентом]
      ,[кол_во_исполненных_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_интернетом]
      ,[кол_во_исполненных_обещаний_интернетом_с_клиентом]
      ,[кол_во_исполненных_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_выездом]
      ,[кол_во_исполненных_обещаний_выездом_с_клиентом]
      ,[кол_во_исполненных_обещаний_выездом_с_третьим_лицом]
      ,[сумма_исполненных_обещаний]
      ,[сумма_исполненных_обещаний_с_клиентом]
      ,[сумма_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_отложенных_обещаний]
      ,[кол_вот_отказов_от_оплаты]
      ,[кол_во_консультаций]
      ,[сумма_остатка_од]
      ,[сумма_остатка_од_по_обещанию]
      ,[сумма_остатка_од_по_обещанию_от_клиента]
      ,[сумма_остатка_од_по_обещанию_от_третьего_лица]
      ,[сумма_остатка_од_по_исполненному_обещанию]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_клиента]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_третьего_лица]
      ,[product_type]

	  )


	select external_id 'номер_договора'
			,cdate 'отчетная_дата'
			,month_report 'отчетный_месяц'
			,week_report 'неделя_в_году'
			,bucket_overdue 'бакет_просрочки'
			,stage_collection 'стадия_взыскания'
			,type_strategy 'тип_взыскания'
			,deal_calllist 'договор_в_дайлере'
			,deal_other 'договор_вне_дайлера'
			,amount_deals 'кол_во_договоров_на_стадии'
			,attempt_fact 'кол_во_договоров_с_попытками'
			,attempt_total 'кол_во_попыток'
			,attempt_calls 'кол_во_попыток_звонком'
			,attempt_internet 'кол_во_попыток_интернетом'
			,contacts_fact 'факт_контакта'
			,contacts_total 'кол_во_контактов'
			,contacts_total_rpc 'кол_во_контактов_с_клиентом'
			,contacts_total_tpc 'кол_во_контактов_с_третьим_лицом'
			,contacts_calls 'кол_во_контактов_звонком'
			,contacts_calls_rpc 'кол_во_контактов_звонком_с_клиентом'
			,contacts_calls_tpc 'кол_во_контактов_звонком_с_третьим_лицом'
			,contacts_internet 'кол_во_контактов_интернетом'
			,contacts_internet_rpc 'кол_во_контактов_интернетом_с_клиентом'
			,contacts_internet_tpc 'кол_во_контактов_интернетом_с_третьим_лицом'
			,contacts_visit 'кол_во_контактов_выездом'
			,contacts_visit_rpc 'кол_во_контактов_выездом_с_клиентом'
			,contacts_visit_tpc 'кол_во_контактов_выездом_с_третьим_лицом'
			,promise_fact 'факт_обещания'
			,promise_total 'кол_во_обещаний'
			,promise_total_rpc 'кол_во_обещаний_с_клиентом'
			,promise_total_tpc 'кол_во_обещаний_с_третьим_лицом'
			,promise_calls 'кол_во_обещаний_звонком'
			,promise_calls_rpc 'кол_во_обещаний_звонком_с_клиентом'
			,promise_calls_tpc 'кол_во_обещаний_звонком_с_третьим_лицом'
			,promise_internet 'кол_во_обещаний_интернетом'
			,promise_internet_rpc 'кол_во_обещаний_интернетом_с_клиентом'
			,promise_internet_tpc 'кол_во_обещаний_интернетом_с_третьим_лицом'
			,promise_visit 'кол_во_обещаний_выездом'
			,promise_visit_rpc 'кол_во_обещаний_выездом_с_клиентом'
			,promise_visit_tpc 'кол_во_обещаний_выездом_с_третьим_лицом'
			,promise_total_rur 'сумма_обещаний'
			,promise_total_rpc_rur 'сумма_обещаний_с_клиентом'
			,promise_total_tpc_rur 'сумма_обещаний_с_третьим_лицом'
			,promise_kept_fact 'факт_исполненного_обещания'
			,promise_kept_total 'кол_во_исполненных_обещаний'
			,promise_kept_total_rpc 'кол_во_исполненных_обещаний_с_клиентом'
			,promise_kept_total_tpc 'кол_во_исполненных_обещаний_с_третьим_лицом'
			,promise_kept_calls 'кол_во_исполненных_обещаний_звонком'
			,promise_kept_calls_rpc 'кол_во_исполненных_обещаний_звонком_с_клиентом'
			,promise_kept_calls_tpc 'кол_во_исполненных_обещаний_звонком_с_третьим_лицом'
			,promise_kept_internet 'кол_во_исполненных_обещаний_интернетом'
			,promise_kept_internet_rpc 'кол_во_исполненных_обещаний_интернетом_с_клиентом'
			,promise_kept_internet_tpc 'кол_во_исполненных_обещаний_интернетом_с_третьим_лицом'
			,promise_kept_visit 'кол_во_исполненных_обещаний_выездом'
			,promise_kept_visit_rpc 'кол_во_исполненных_обещаний_выездом_с_клиентом'
			,promise_kept_visit_tpc 'кол_во_исполненных_обещаний_выездом_с_третьим_лицом'
			,promise_kept_total_rur 'сумма_исполненных_обещаний'
			,promise_kept_total_rpc_rur 'сумма_исполненных_обещаний_с_клиентом'
			,promise_kept_total_tpc_rur 'сумма_исполненных_обещаний_с_третьим_лицом'
			,deferred_promise_total 'кол_во_отложенных_обещаний'
			,refusal_to_pay_total 'кол_вот_отказов_от_оплаты'
			,consultation_total 'кол_во_консультаций'
			,principal_rest 'сумма_остатка_од'
			,promise_total_debt_rur 'сумма_остатка_од_по_обещанию'
			,promise_total_rpc_debt_rur 'сумма_остатка_од_по_обещанию_от_клиента'
			,promise_total_tpc_debt_rur 'сумма_остатка_од_по_обещанию_от_третьего_лица'
			,promise_kept_total_debt_rur 'сумма_остатка_од_по_исполненному_обещанию'
			,promise_kept_total_rpc_debt_rur 'сумма_остатка_од_по_исполненному_обещанию_от_клиента'
			,promise_kept_total_tpc_debt_rur 'сумма_остатка_од_по_исполненному_обещанию_от_третьего_лица'
			,product_type
			
	from #report_convers_1_90
	where month_report = dateadd(mm,1,@start_dt)
	;

	-- сбор отчетной таблицы таблицы devDB.dbo.say_report_convers_1_90_lm
	--ALTER TABLE devDB.dbo.say_report_convers_1_90_lm ADD product_type varchar (255)
	

	delete from collection.say_report_convers_1_90_lm;
	insert collection.say_report_convers_1_90_lm (

	[номер_договора]
      ,[отчетная_дата]
      ,[отчетный_месяц]
      ,[неделя_в_году]
      ,[бакет_просрочки]
      ,[стадия_взыскания]
      ,[тип_взыскания]
      ,[договор_в_дайлере]
      ,[договор_вне_дайлера]
      ,[кол_во_договоров_на_стадии]
      ,[кол_во_договоров_с_попытками]
      ,[кол_во_попыток]
      ,[кол_во_попыток_звонком]
      ,[кол_во_попыток_интернетом]
      ,[факт_контакта]
      ,[кол_во_контактов]
      ,[кол_во_контактов_с_клиентом]
      ,[кол_во_контактов_с_третьим_лицом]
      ,[кол_во_контактов_звонком]
      ,[кол_во_контактов_звонком_с_клиентом]
      ,[кол_во_контактов_звонком_с_третьим_лицом]
      ,[кол_во_контактов_интернетом]
      ,[кол_во_контактов_интернетом_с_клиентом]
      ,[кол_во_контактов_интернетом_с_третьим_лицом]
      ,[кол_во_контактов_выездом]
      ,[кол_во_контактов_выездом_с_клиентом]
      ,[кол_во_контактов_выездом_с_третьим_лицом]
      ,[факт_обещания]
      ,[кол_во_обещаний]
      ,[кол_во_обещаний_с_клиентом]
      ,[кол_во_обещаний_с_третьим_лицом]
      ,[кол_во_обещаний_звонком]
      ,[кол_во_обещаний_звонком_с_клиентом]
      ,[кол_во_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_обещаний_интернетом]
      ,[кол_во_обещаний_интернетом_с_клиентом]
      ,[кол_во_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_обещаний_выездом]
      ,[кол_во_обещаний_выездом_с_клиентом]
      ,[кол_во_обещаний_выездом_с_третьим_лицом]
      ,[сумма_обещаний]
      ,[сумма_обещаний_с_клиентом]
      ,[сумма_обещаний_с_третьим_лицом]
      ,[факт_исполненного_обещания]
      ,[кол_во_исполненных_обещаний]
      ,[кол_во_исполненных_обещаний_с_клиентом]
      ,[кол_во_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_звонком]
      ,[кол_во_исполненных_обещаний_звонком_с_клиентом]
      ,[кол_во_исполненных_обещаний_звонком_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_интернетом]
      ,[кол_во_исполненных_обещаний_интернетом_с_клиентом]
      ,[кол_во_исполненных_обещаний_интернетом_с_третьим_лицом]
      ,[кол_во_исполненных_обещаний_выездом]
      ,[кол_во_исполненных_обещаний_выездом_с_клиентом]
      ,[кол_во_исполненных_обещаний_выездом_с_третьим_лицом]
      ,[сумма_исполненных_обещаний]
      ,[сумма_исполненных_обещаний_с_клиентом]
      ,[сумма_исполненных_обещаний_с_третьим_лицом]
      ,[кол_во_отложенных_обещаний]
      ,[кол_вот_отказов_от_оплаты]
      ,[кол_во_консультаций]
      ,[сумма_остатка_од]
      ,[сумма_остатка_од_по_обещанию]
      ,[сумма_остатка_од_по_обещанию_от_клиента]
      ,[сумма_остатка_од_по_обещанию_от_третьего_лица]
      ,[сумма_остатка_од_по_исполненному_обещанию]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_клиента]
      ,[сумма_остатка_од_по_исполненному_обещанию_от_третьего_лица]
      ,[product_type]


)

	select external_id 'номер_договора'
			,cdate 'отчетная_дата'
			,month_report 'отчетный_месяц'
			,week_report 'неделя_в_году'
			,bucket_overdue 'бакет_просрочки'
			,stage_collection 'стадия_взыскания'
			,type_strategy 'тип_взыскания'
			,deal_calllist 'договор_в_дайлере'
			,deal_other 'договор_вне_дайлера'
			,amount_deals 'кол_во_договоров_на_стадии'
			,attempt_fact 'кол_во_договоров_с_попытками'
			,attempt_total 'кол_во_попыток'
			,attempt_calls 'кол_во_попыток_звонком'
			,attempt_internet 'кол_во_попыток_интернетом'
			,contacts_fact 'факт_контакта'
			,contacts_total 'кол_во_контактов'
			,contacts_total_rpc 'кол_во_контактов_с_клиентом'
			,contacts_total_tpc 'кол_во_контактов_с_третьим_лицом'
			,contacts_calls 'кол_во_контактов_звонком'
			,contacts_calls_rpc 'кол_во_контактов_звонком_с_клиентом'
			,contacts_calls_tpc 'кол_во_контактов_звонком_с_третьим_лицом'
			,contacts_internet 'кол_во_контактов_интернетом'
			,contacts_internet_rpc 'кол_во_контактов_интернетом_с_клиентом'
			,contacts_internet_tpc 'кол_во_контактов_интернетом_с_третьим_лицом'
			,contacts_visit 'кол_во_контактов_выездом'
			,contacts_visit_rpc 'кол_во_контактов_выездом_с_клиентом'
			,contacts_visit_tpc 'кол_во_контактов_выездом_с_третьим_лицом'
			,promise_fact 'факт_обещания'
			,promise_total 'кол_во_обещаний'
			,promise_total_rpc 'кол_во_обещаний_с_клиентом'
			,promise_total_tpc 'кол_во_обещаний_с_третьим_лицом'
			,promise_calls 'кол_во_обещаний_звонком'
			,promise_calls_rpc 'кол_во_обещаний_звонком_с_клиентом'
			,promise_calls_tpc 'кол_во_обещаний_звонком_с_третьим_лицом'
			,promise_internet 'кол_во_обещаний_интернетом'
			,promise_internet_rpc 'кол_во_обещаний_интернетом_с_клиентом'
			,promise_internet_tpc 'кол_во_обещаний_интернетом_с_третьим_лицом'
			,promise_visit 'кол_во_обещаний_выездом'
			,promise_visit_rpc 'кол_во_обещаний_выездом_с_клиентом'
			,promise_visit_tpc 'кол_во_обещаний_выездом_с_третьим_лицом'
			,promise_total_rur 'сумма_обещаний'
			,promise_total_rpc_rur 'сумма_обещаний_с_клиентом'
			,promise_total_tpc_rur 'сумма_обещаний_с_третьим_лицом'
			,promise_kept_fact 'факт_исполненного_обещания'
			,promise_kept_total 'кол_во_исполненных_обещаний'
			,promise_kept_total_rpc 'кол_во_исполненных_обещаний_с_клиентом'
			,promise_kept_total_tpc 'кол_во_исполненных_обещаний_с_третьим_лицом'
			,promise_kept_calls 'кол_во_исполненных_обещаний_звонком'
			,promise_kept_calls_rpc 'кол_во_исполненных_обещаний_звонком_с_клиентом'
			,promise_kept_calls_tpc 'кол_во_исполненных_обещаний_звонком_с_третьим_лицом'
			,promise_kept_internet 'кол_во_исполненных_обещаний_интернетом'
			,promise_kept_internet_rpc 'кол_во_исполненных_обещаний_интернетом_с_клиентом'
			,promise_kept_internet_tpc 'кол_во_исполненных_обещаний_интернетом_с_третьим_лицом'
			,promise_kept_visit 'кол_во_исполненных_обещаний_выездом'
			,promise_kept_visit_rpc 'кол_во_исполненных_обещаний_выездом_с_клиентом'
			,promise_kept_visit_tpc 'кол_во_исполненных_обещаний_выездом_с_третьим_лицом'
			,promise_kept_total_rur 'сумма_исполненных_обещаний'
			,promise_kept_total_rpc_rur 'сумма_исполненных_обещаний_с_клиентом'
			,promise_kept_total_tpc_rur 'сумма_исполненных_обещаний_с_третьим_лицом'
			,deferred_promise_total 'кол_во_отложенных_обещаний'
			,refusal_to_pay_total 'кол_вот_отказов_от_оплаты'
			,consultation_total 'кол_во_консультаций'
			,principal_rest 'сумма_остатка_од'
			,promise_total_debt_rur 'сумма_остатка_од_по_обещанию'
			,promise_total_rpc_debt_rur 'сумма_остатка_од_по_обещанию_от_клиента'
			,promise_total_tpc_debt_rur 'сумма_остатка_од_по_обещанию_от_третьего_лица'
			,promise_kept_total_debt_rur 'сумма_остатка_од_по_исполненному_обещанию'
			,promise_kept_total_rpc_debt_rur 'сумма_остатка_од_по_исполненному_обещанию_от_клиента'
			,promise_kept_total_tpc_debt_rur 'сумма_остатка_од_по_исполненному_обещанию_от_третьего_лица'
			,product_type
			
	from #report_convers_1_90
	where month_report = @start_dt
	;
	*/

COMMIT TRANSACTION

EXEC [collection].set_debug_info @sp_name
			,'FINISH';

	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch















END
