
	CREATE PROC [collection].[say_delivery_email_hard_deals_no_payments]

	as
	begin
begin try
--------------------------------------------------------------------------------------------------------------
	-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set flag_start_procedure = 1
	,start_procedure = getdate()
	,step_realization_procedure = 1
	--,flag_finish_procedure = 0
	--,finish_procedure = null
	--,error_realization_procedure = null
	where [id] = 2 -- name_procedure = 'collection.say_delivery_email_hard_deals_no_payments'
	;

--------------------------------------------------------------------------------------------------------------
-- НАЧАЛО СБОРКИ РЕЕСТРА, КОТОРЫЙ ДОЛЖЕН БЫТЬ ОТПРАВЛЕН
--------------------------------------------------------------------------------------------------------------
  -- база клиентов с проблемными статусам
	drop table if exists #base_problem_client;
	select
			customerId
	into #base_problem_client
	from 
			[Stg].[_Collection].[CustomerStatus] t1
			join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
	where 1=1
			and t1.[IsActive] = 1 
			and t2.[Name] in ('Смерть подтвержденная',
							'Банкрот подтверждённый',
							'Fraud подтвержденный'
							,'HardFraud'
							,'КА')
	group by 
			customerId
	;

------------------------------------------------------------------------------------------------------------------------
  -- база сотрудников взыскания зоны hard	
	drop table if exists #base_employee_hard;
	select 
			resh.Employeeid employee_id
			,fio_claimant = CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName) 
			,resh.CollectingStageName employee_stage_collection
	into #base_employee_hard
	--from stg._collection.[ReportEmployeeStatisticsHistory]		resh
	FROM Stg._Collection.v_EmployeeCollectingStageHistory AS resh
	left join stg._collection.Employee														e on e.id = resh.Employeeid
	where 1 = 1
			and resh.CollectingStageName = 'Hard'
			and resh.Employeeid != 11 -- исключен сотрудник Лебедев Александр Дмитриевич, который давно был на hard, но сейчас работает на prelegal
	group by resh.Employeeid
			,CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName)
			,resh.CollectingStageName
	union
	select id
			,CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName)
			,'Hard'
	from stg._Collection.Employee		e
	where id = 106 -- добавлен сотрудник Батнасунов Надбит Николаевич, который работает на розыске в ИП/hard и не имеет закрепленных договоров и скила
	;

------------------------------------------------------------------------------------------------------------------------
  -- база истории закрепления ответственных сотрудников за клиентами	
	drop table if exists #base_claimant_id;
	select 
			ObjectId id_customer
			,coalesce(NewValue,0) id_claimant
			,dt_rt dt_st_claimant
	into #base_claimant_id
	from 
	(
			SELECT 
					cast([ChangeDate] as date) dt_rt
					,[NewValue]
					,[ObjectId]
					,ROW_NUMBER() over (partition by [ObjectId] order by [ChangeDate] desc) rn
			FROM
					[Stg].[_Collection].[CustomerHistory]
			where 1 = 1
					and field = 'Ответственный взыскатель'
	)aaa
	where 1 = 1
			and rn = 1
	;

------------------------------------------------------------------------------------------------------------------------
  -- база договоров с кк и заморозкой	
	drop table if exists #date;
	create table #date (dt date);
	insert #date VALUES ('4021-04-30');
	while (select max(dt) from #date) < '4030-01-01'
		begin 
			insert #date (dt)
			select distinct eomonth(dateadd(mm,1,(select max(dt) from #date)))
			from #date
		END
	;

	drop table if exists #deals	;
	select 
			id
			,number
			,CreditVacationDateEnd
			,IsCreditVacation
			,'2000-01-01' mn_end_kk
			,'2000-01-01' dt_pay_schedule
	into #deals
	from 
			stg._Collection.deals								d
			left join (
							SELECT
									[CustomerId]
							FROM 
									[Stg].[_Collection].[CustomerStatus] t1
							where 1=1
									and t1.[IsActive] = 1 
									and t1.[CustomerStateId] = 16 -- 'Банкрот подтверждённый'
							group by
									CustomerId
							)									b on b.CustomerId = d.IdCustomer
			where 1=1
			and (case when b.CustomerId is not null and d.[OverdueDays] > 0 then 1 else 0 end) = 0 -- это договора фактически без КК, потому что заёмщики признаны банкротами и им откатили каникулы
			and dbo.customer_fio(d.IdCustomer) != 'ТЕСТ ТЕСТ ТЕСТ'
	;

	delete from #deals
	where number in (select t1.external_id
					from dwh2.[dm].[Collection_StrategyDataMart] t1
					left join (select external_id
								from dwh2.[dm].[Collection_StrategyDataMart]
								where strategydate = '2021-06-18'
										and HasFreezing = 1)	t2 on t2.external_id = t1.external_id
					left join stg._collection.deals				d on d.number = t1.external_id
					where t1.strategydate = '2021-06-19'
							and t1.HasFreezing = 1
							and t2.external_id is null
							and coalesce(d.IsCreditVacation,0) != 1)
	;

	update #deals
	set 
			 IsCreditVacation = (case when d.IsCreditVacation = 1 then 1
									  else f.HasFreezing
									  end)
			,CreditVacationDateEnd = (case when f.HasFreezing = 1 then a.CreditVacationDateEnd
										   else d.CreditVacationDateEnd
										   end)
			,dt_pay_schedule = (case when datepart(yyyy,p.NextPaymentDate) >= 2000 then cast(p.NextPaymentDate as date) else '2000-01-01'
										end)
	from #deals																		d
	left join (select s.external_id
						,s.HasFreezing
				from dwh2.[dm].[Collection_StrategyDataMart] s
				where 1 = 1
						and s.HasFreezing = 1
						and cast(s.strategydate as date) = cast(getdate() as date)
				group by s.external_id
						,s.HasFreezing)													f on f.external_id = d.number
	left join (select s.код number
						,max(cast(dateadd(yy,-2000,g.ДатаПлатежа) as date)) CreditVacationDateEnd
				from [Stg].[_1cCMR].[РегистрСведений_ДанныеГрафикаПлатежей]	g
				left join [Stg].[_1cCMR].Справочник_Договоры						s on g.Договор=s.Ссылка
				where 1 = 1
						and cast(g.[Период] as date) in (select dt from #date where dt <= dateadd(yy,2000,cast(getdate() as date)))
						and g.ОстатокОД > 0
						and g.СуммаПлатежа = 0
				group by s.код)														a on a.number = d.number
	left join [Stg].[_Collection].[NextPaymentInfo]									p on p.[DealId] = d.Id
	;

	
	drop table if exists #base_kk;
	select 
			number
			,dbo.dt_st_month(CreditVacationDateEnd) mn_end_kk
			,dt_pay_schedule
	into #base_kk
	from 
			#deals 
	where 1=1
			and IsCreditVacation = 1
	;

------------------------------------------------------------------------------------------------------------------------
  -- база платежей	
	drop table if exists #base_payment;	
	select
			id_deal
			,dt_pay
			,sum_pay
	into #base_payment
	from
	(
		select
				id_deal
				,dt_pay
				,sum_pay
				,row_number() over (partition by id_deal order by dt_pay desc) rn
		from
		(
			select
					iddeal id_deal
					,cast(paymentdt as date) dt_pay
					,sum(amount) sum_pay
			from
					stg._collection.payment
			group by
					iddeal
					,cast(paymentdt as date)
		)t1
	)t2
	where 1=1
			and rn = 1
			and sum_pay >= 1000
	;

------------------------------------------------------------------------------------------------------------------------
  -- итоговая таблица
	--drop table if exists collection.say_hard_deals_no_payments
--begin tran
	--DWH-1764
--	drop table if exists #t_result
	/*
	TRUNCATE TABLE collection.say_hard_deals_no_payments

	INSERT collection.say_hard_deals_no_payments
	(
	    договор,
	    [фио клиента],
	    [фио сотрудника],
	    [дата закрепления],
	    [дата последнего платежа],
	    [сумма последнего платежа],
	    [флаг КК или Заморозка],
	    [флаг первого платежа после Заморозки],
	    [флаг поступления платежа в предыдущий день],
	    [сумма платежа в предыдущий день],
	    [флаг поступления платежа в предыдущий день по заморозке],
	    [сумма платежа в предыдущий день по заморозке],
	    [флаг поступления платежа в предыдущий день по вышедшим из заморозки в текущем месяце],
	    [сумма платежа в предыдущий день по вышедшим из заморозки в текущем месяце],
	    [флаг отсутствия оплаты в hard за 90 последних дней],
	    [од, отсутствие оплаты в hard за 90 последних дней],
	    [флаг отсутствия оплаты в hard за 60 последних дней],
	    [од, отсутствие оплаты в hard за 60 последних дней],
	    [флаг отсутствия оплаты в hard за 30 последних дней],
	    [од, отсутствие оплаты в hard за 30 последних дней],
	    employee_id,
	    [email ответственного сотрудника]
	)
	*/
	select
			d.number 'договор'
			,dbo.customer_fio(d.IdCustomer) 'фио клиента'
			,beh.fio_claimant 'фио сотрудника'
			,bcid.dt_st_claimant 'дата закрепления'
			,bpm.dt_pay 'дата последнего платежа'
			,bpm.sum_pay 'сумма последнего платежа'
			,case when bkk.mn_end_kk is null
				  then null
				  when bkk.mn_end_kk <= '2021-05-01'
				  then '2.КК'
				  when bkk.mn_end_kk > '2021-05-01'
				  then '1.Заморозка' 
				  end 'флаг КК или Заморозка'
			,case when eomonth(bkk.mn_end_kk) = eomonth(dateadd(mm,-1,getdate())) and bkk.dt_pay_schedule < getdate()
				  then '1.вышел из заморозки в текущем месяце, дат платежа наступила'
				  end 'флаг первого платежа после Заморозки'
			,case when coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date) 
				  then 1 else 0 end 'флаг поступления платежа в предыдущий день'
			,case when coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date)
				  then coalesce(bpm.sum_pay,0)
				  else 0 end 'сумма платежа в предыдущий день'
			,case when bkk.number is not null and coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date) 
				  then 1 else 0 end 'флаг поступления платежа в предыдущий день по заморозке'
			,case when bkk.number is not null and coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date) 
				  then coalesce(bpm.sum_pay,0) 
				  else 0 end 'сумма платежа в предыдущий день по заморозке'
			,case when eomonth(bkk.mn_end_kk) = eomonth(dateadd(mm,-1,getdate())) and bkk.dt_pay_schedule < getdate() and coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date)
				  then 1 
				  else 0 end 'флаг поступления платежа в предыдущий день по вышедшим из заморозки в текущем месяце'
			,case when eomonth(bkk.mn_end_kk) = eomonth(dateadd(mm,-1,getdate())) and bkk.dt_pay_schedule < getdate() and coalesce(bpm.dt_pay,'2000-01-01') >= cast(dateadd(dd,-1,getdate()) as date)
				  then coalesce(bpm.sum_pay,0) 
				  else 0 end 'сумма платежа в предыдущий день по вышедшим из заморозки в текущем месяце'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 90
				  then 1 else 0 end 'флаг отсутствия оплаты в hard за 90 последних дней'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 90
				  then d.debtsum else 0 end 'од, отсутствие оплаты в hard за 90 последних дней'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 60
				  then 1 else 0 end 'флаг отсутствия оплаты в hard за 60 последних дней'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 60
				  then d.debtsum else 0 end 'од, отсутствие оплаты в hard за 60 последних дней'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 30
				  then 1 else 0 end 'флаг отсутствия оплаты в hard за 30 последних дней'
			,case when datediff(dd,(case when bcid.dt_st_claimant >= coalesce(bpm.dt_pay,'2000-01-01') then bcid.dt_st_claimant else bpm.dt_pay end),getdate()) > 30
				  then d.debtsum else 0 end 'од, отсутствие оплаты в hard за 30 последних дней'
			,beh.employee_id
			,collection_users.email 'email ответственного сотрудника'
	
	into #t_result
	from
			stg._Collection.Deals									d
			join stg._Collection.customers							c 
				on c.id = d.IdCustomer
			join #base_employee_hard								beh 
				on beh.employee_id = c.ClaimantId -- в выборке остаются только договора закреплённые за сотрудниками хард
			left join #base_problem_client							bpc 
				on bpc.CustomerId = d.IdCustomer
			left join #base_kk										bkk 
				on bkk.number = d.number
			left join #base_payment									bpm 
				on bpm.id_deal = d.id
			left join #base_claimant_id								bcid 
				on bcid.id_claimant = beh.employee_id
				and bcid.id_customer = d.IdCustomer
			left join stg._Collection.AspNetUsers					collection_users 
				on collection_users.EmployeeId = beh.employee_id
	where 1=1
			and bpc.CustomerId is null -- из выборки исключаются клиенты с проблемными статусами
	;
--	commit tran
-------------------------------------------------------------------------------------------------------------
-- ОКОНЧАНИЕ СБОРКИ РЕЕСТРА, КОТОРЫЙ ДОЛЖЕН БЫТЬ ОТПРАВЛЕН
--------------------------------------------------------------------------------------------------------------
-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set step_realization_procedure = 2
	where [id] = 2 -- name_procedure = 'collection.say_delivery_email_hard_deals_no_payments'
	;

--------------------------------------------------------------------------------------------------------------
-- НАЧАЛО ПРОЦЕДУРЫ ОТПРАВКИ РЕЕСТРОВ СОТРУДНИКАМ
--------------------------------------------------------------------------------------------------------------	
	
	DECLARE @employee_id int -- id сотрудников, которым нужно отправить письмо

	DECLARE cursor_base_deliver CURSOR 
	FOR 
	select distinct
			employee_id
	from  #t_result
		--	collection.say_hard_deals_no_payments
	
	OPEN cursor_base_deliver  
	FETCH NEXT FROM cursor_base_deliver INTO @employee_id

	WHILE @@FETCH_STATUS = 0  -- Проверить состояние курсора

	BEGIN

	drop table if exists #t_for_deliver;
	select 
	[договор]
	,[email ответственного сотрудника]
	,[фио клиента]
	,[фио сотрудника]	
	,[сумма платежа в предыдущий день]	
	,[дата последнего платежа]
	,employee_id
	--* 
	into #t_for_deliver -- создание таблицы, которая будет отправлена сотруднику
	from #t_result
	--collection.say_hard_deals_no_payments
	where coalesce(employee_id,0) = @employee_id and [флаг поступления платежа в предыдущий день] = 1;

--------------------------------------------------------------------------------
	--сбор письма на отправку
	
	BEGIN TRY
	
	DECLARE 
	@tableHTML NVARCHAR(MAX),
	@recipients NVARCHAR(MAX);

	set @recipients = 
						(select distinct 
								coalesce([email ответственного сотрудника],'d.korablev@carmoney.ru') 
						from  #t_result
							--	collection.say_hard_deals_no_payments
						where 1=1
								and employee_id = @employee_id)
	;

	SET @tableHTML =  
		N'<H1>Договора, по которым вчера были поступления</H1>' +  
		N'<table border="1">' +  
		N'<tr><th>номер договора</th>' +  
		N'<th>фио клиента</th>' +  
		N'<th>фио ответственного сотрудника</th>' +  
		N'<th>сумма платежа в предыдущий день</th></tr>' +
		N'<th>дата платежа</th></tr>' +
		CAST ( ( SELECT 
						td = 	[договор]	,       '', 
						td = 	[фио клиента]	,       '', 
						td = 	[фио сотрудника]	,       '', 
						td = 	[сумма платежа в предыдущий день]	,       '',
						td =	[дата последнего платежа]
				  FROM #t_for_deliver  
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 

		EXEC msdb.dbo.sp_send_dbmail 
		@recipients = @recipients,  
		@subject = 'Платежи за предыдущий день',  
		@body = @tableHTML,  
		@body_format = 'HTML';
	
	END TRY
	
	BEGIN CATCH
	-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set error_realization_procedure = ERROR_MESSAGE()
	,flag_finish_procedure = 0
	,finish_procedure = getdate()
	where [id] = 2 -- name_procedure = 'collection.say_delivery_email_hard_deals_no_payments'
	;
	END CATCH
	;

	-------------------------------------------------------------
 	FETCH NEXT FROM cursor_base_deliver INTO @employee_id -- извлечь следующую запись из курсора
	
	END -- закрытие цикла

	CLOSE cursor_base_deliver  

	DEALLOCATE cursor_base_deliver

	--------------------------------------------------------------------------------
	-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set step_realization_procedure = 3
		,flag_finish_procedure = 1
		,finish_procedure = getdate()
		,error_realization_procedure = null
	where 1=1
			and [id] = 2 -- name_procedure = 'collection.say_delivery_email_hard_deals_no_payments'
			and flag_finish_procedure != 0
			and cast(finish_procedure as date) != cast(getdate() as date)
	;
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
	end -- закрытие процедуры
