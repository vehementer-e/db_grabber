  
 
 CREATE PROCEDURE [collection].[create_Bankruptcy_effectivelly] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try





drop table if exists #deals_problem_status;
	select deals.number
	into #deals_problem_status
	from [Stg].[_Collection].[CustomerStatus] cust_status
	join stg._Collection.deals deals on deals.IdCustomer = cust_status.CustomerId
	group by deals.number
	;
	EXEC [collection].set_debug_info @sp_name
			,'1';


	drop table if exists #v_balance_cmr_probation;
	select
			balance_cmr.external_id
			,balance_cmr.d cdate --заменил cdate
			,  total_CF = balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) --balance_cmr.total_CF
			,balance_cmr.overdue
			,lag(balance_cmr.[остаток од],1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) principal_rest--заменил cdate
			,case when balance_cmr.dpd_p_coll = 0 
					and balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) > 0  --balance_cmr.total_CF --заменил cdate
					and lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) > 0
					and balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) > lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d)--balance_cmr.total_CF --заменил cdate
					then balance_cmr.dpd_p_coll + 1
					else balance_cmr.dpd_p_coll
					end overdue_days_p_corr
			,max(balance_cmr.d) over (partition by balance_cmr.external_id) max_dt_balance_cmr  --заменил cdate
			,balance_cmr.[Тип Продукта]--добавил тип продукта
	into #v_balance_cmr_probation
	from #deals_problem_status deals_problem_status
	join dbo.dm_cmrstatbalance balance_cmr on balance_cmr.external_id = deals_problem_status.number ---  change dwh_new.dbo.v_balance_cmr 
	;
	EXEC [collection].set_debug_info @sp_name
			,'2';

	
	drop table if exists #summary_table;
	select distinct
			base_bank_confirmed_and_balance.CustomerId 'id должника'
			,fio 'фио должника'
			,month_report 'отчетный месяц'
			,sum(principal_rest) over (partition by base_bank_confirmed_and_balance.CustomerId, fio, month_report) 'общий долг по портфелю'
			,sum(market_price) over (partition by base_bank_confirmed_and_balance.CustomerId, fio, month_report) 'рыночная стоимость залогов'
			,sum(total_CF) over (partition by base_bank_confirmed_and_balance.CustomerId, fio, month_report) 'поступления'
			,1 'факт наличия долга'
			,case when sum(total_CF) over (partition by base_bank_confirmed_and_balance.CustomerId, fio, month_report) > 0 then 1 else 0 end 'факт поступления'
			,base_bank_confirmed_and_balance.[Тип Продукта]--добавил тип продукта
	into #summary_table
	from
	(
		select 
				base_bank_confirmed.*
				,v_balance_cmr.overdue_days_p_corr
				,v_balance_cmr.total_CF
				,v_balance_cmr.cdate
				,cast(dateadd(day,-datepart(day,v_balance_cmr.cdate)+1,v_balance_cmr.cdate) as date) month_report
				,case when min(v_balance_cmr.cdate) over
							(partition by base_bank_confirmed.number,cast(dateadd(day,-datepart(day,v_balance_cmr.cdate)+1,v_balance_cmr.cdate) as date))
					= v_balance_cmr.cdate
						then v_balance_cmr.principal_rest
						else null end principal_rest
				,case when (case when min(v_balance_cmr.cdate) over
							(partition by base_bank_confirmed.number,cast(dateadd(day,-datepart(day,v_balance_cmr.cdate)+1,v_balance_cmr.cdate) as date))
					= v_balance_cmr.cdate
						then v_balance_cmr.principal_rest
						else null end) is not null
					  then item.MarketPrice end market_price
					,cust.LastName+' '+cust.Name+' '+cust.MiddleName fio
					,v_balance_cmr.[Тип Продукта]
		from
		(
			SELECT 
					Bank_confirmed.[ObjectId]
					,cast(min([ChangeDate]) as date) dt_start_Bank_confirmed
					,cast(dateadd(day,-datepart(day,min([ChangeDate]))+1,min([ChangeDate])) as date) mn_start_Bank_confirmed
					,cust_status.CustomerId
					,deals.Number
					,deals.id id_deal
			from 
					Stg._Collection.[BankruptconfirmedHistory] Bank_confirmed --[C2-VSR-CL-SQL].[collection_night00].[dbo].[BankruptconfirmedHistory] 
					join [Stg].[_Collection].[CustomerStatus] cust_status on cust_status.Id = Bank_confirmed.[ObjectId]
					join stg._Collection.deals deals on deals.IdCustomer = cust_status.CustomerId
			where 1=1
					and [Field] = 'Статус назначен'
					and [NewValue] = 'True'
			group by 
					Bank_confirmed.[ObjectId]
					,cust_status.CustomerId
					,deals.Number
					,deals.id
		)base_bank_confirmed
				join #v_balance_cmr_probation v_balance_cmr on v_balance_cmr.external_id = base_bank_confirmed.Number
														   and v_balance_cmr.cdate >= base_bank_confirmed.dt_start_Bank_confirmed
				join stg._Collection.customers cust on cust.Id = CustomerId
				left join (
					select 
							t2.DealId
							,coalesce(coalesce((case when t3.[MarketPrice] = 0 then t3.AssessedPrice else t3.[MarketPrice] end),t3.AssessedPrice),0) MarketPrice
					from
							[Stg].[_Collection].[DealPledgeItem]		t2
							join [Stg].[_Collection].[PledgeItem]		t3 on t3.id = t2.[PledgeItemId]
					group by
							t2.DealId
							,coalesce(coalesce((case when t3.[MarketPrice] = 0 then t3.AssessedPrice else t3.[MarketPrice] end),t3.AssessedPrice),0)
					)item on item.DealId = base_bank_confirmed.id_deal
	)base_bank_confirmed_and_balance
			left join (select customerid
								,cast([BankruptcyFinishDate] as date) dt_Bankruptcy_Finish
						from Stg._Collection.CustomerBankruptcy --[C2-VSR-CL-SQL].[collection_night00].[dbo].CustomerBankruptcy
						where BankruptcyFinishDate is not null)				dbf on dbf.customerid = base_bank_confirmed_and_balance.CustomerId
			
	where 1=1
			and base_bank_confirmed_and_balance.month_report <= coalesce(dbf.dt_Bankruptcy_Finish, '4000-01-01')
	;
	EXEC [collection].set_debug_info @sp_name
			,'3';



	BEGIN TRANSACTION

	delete from collection.Bankruptcy_effectivelly;
	insert collection.Bankruptcy_effectivelly (


	[id должника]
      ,[фио должника]
      ,[отчетный месяц]
      ,[общий долг по портфелю]
      ,[рыночная стоимость залогов]
      ,[поступления]
      ,[факт наличия долга]
      ,[факт поступления]
      ,[максимальное поступление]
      ,[долг по максимальному поступлению]
	  ,[Тип Продукта] --добавил тип продукта


	  )

	 
	 select distinct
			st_1.[id должника]
			,st_1.[фио должника] 
			,st_1.[отчетный месяц]
			,st_1.[общий долг по портфелю]
			,st_1.[рыночная стоимость залогов]
			,st_1.[поступления]
			,st_1.[факт наличия долга]
			,st_1.[факт поступления]
			,case when max(st_1.[поступления]) over (partition by st_1.[отчетный месяц]) = st_1.[поступления] then st_1.[поступления] else 0 end 'максимальное поступление'
			,case when max(st_1.[поступления]) over (partition by st_1.[отчетный месяц]) = st_1.[поступления] 
					   and st_1.[поступления] > 0
				  then st_1.[общий долг по портфелю] else 0 end 'долг по максимальному поступлению'
           ,st_1.[Тип Продукта] --добавил тип продукта
	from
			#summary_table								st_1

	

	;
	

  COMMIT TRANSACTION


  EXEC [collection].set_debug_info @sp_name
			,'Finish';



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
		EXEC msdb.dbo.sp_send_dbmail @recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
