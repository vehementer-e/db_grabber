
CREATE PROC collection.say_delivery_email_fixed_deals_hard

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
	where [id] = 1 -- name_procedure = 'collection.say_delivery_email_fixed_deals_hard'
	;

--------------------------------------------------------------------------------------------------------------
-- НАЧАЛО СБОРКИ РЕЕСТРА, КОТОРЫЙ ДОЛЖЕН БЫТЬ ОТПРАВЛЕН
--------------------------------------------------------------------------------------------------------------

	drop table if exists #base_Bankrupt_Confirmed;															
	select id_Customer															
		,dt_Bankrupt_Confirmed														
	into #base_Bankrupt_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Bankrupt_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [Stg].[_Collection].[BankruptConfirmedHistory] t01														
		join [Stg].[_Collection].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
																
	drop table if exists #base_Fraud_Confirmed;															
	select id_Customer															
		,dt_Fraud_Confirmed														
	into #base_Fraud_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Fraud_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [Stg].[_Collection].[FraudConfirmedHistory] t01														
		join [Stg].[_Collection].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
																
	drop table if exists #base_Death_Confirmed;															
	select id_Customer															
		,dt_Death_Confirmed														
	into #base_Death_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Death_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [Stg].[_Collection].[ConfirmedDeathHistory] t01														
		join [Stg].[_Collection].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
																
	drop table if exists #base_HardFraud_Confirmed;															
	select id_Customer															
		,dt_HardFraud_Confirmed														
	into #base_HardFraud_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_HardFraud_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [Stg].[_Collection].[HardFraudHistory] t01														
		join [Stg].[_Collection].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
	drop table if exists #base_in_ka;															
	SELECT [external_id]															
	,st_date dt_st_in_ka															
	,isnull(fact_end_date, plan_end_date) dt_end_in_ka															
	into #base_in_ka
	--DWH-257
	from (
		select 
			d.Number as External_id
			,cat.TransferDate as st_date 
			,cat.ReturnDate as fact_end_date
			,cat.PlannedReviewDate as plan_end_date
		from Stg._collection.CollectingAgencyTransfer as cat
			inner join Stg._collection.Deals as d
				on d.Id = cat.DealId
		) as t



	;															
															
	drop table if exists #base_employee_hard;															
	select 															
			resh.Employeeid employee_id													
			,CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName) fio_claimant													
			,resh.CollectingStageName employee_stage_collection
		--	,CONCAT(e.NaumenUserLogin,'@carmoney.ru') emeil
	into #base_employee_hard															
	--from [Stg].[_Collection].[ReportEmployeeStatisticsHistory]		resh
	FROM Stg._Collection.v_EmployeeCollectingStageHistory AS resh
	left join stg._collection.Employee AS e on e.id = resh.Employeeid
	where 1 = 1															
			and resh.CollectingStageName = 'Hard'													
			and resh.Employeeid != 11												
	group by resh.Employeeid															
			,CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName)													
			,resh.CollectingStageName
			--,CONCAT(e.NaumenUserLogin,'@carmoney.ru')
	union															
	select id															
			,CONCAT_WS(' '
				, e.LastName
				, e.FirstName
				, e.MiddleName)													
			,'Hard'
		--	,CONCAT(e.NaumenUserLogin,'@carmoney.ru') emeil
	from stg._Collection.Employee		e													
	where id = 106															
	;													
																
	drop table if exists #base_claimant_id;															
	select ObjectId															
			,coalesce(NewValue,0) ClaimantId													
			,dt_rt dt_st													
			,lead(dateadd(dd,-1,dt_rt),1,cast(getdate() as date)) over (partition by ObjectId order by ChangeDate) dt_end													
	into #base_claimant_id															
	from (SELECT [ChangeDate]															
					,cast([ChangeDate] as date) dt_rt											
					,[OldValue]											
					,[NewValue]											
					,[ObjectId]											
					,ROW_NUMBER() over (partition by [ObjectId], cast([ChangeDate] as date) order by [ChangeDate] desc) rn											
			FROM [Stg].[_Collection].[CustomerHistory]													
			where 1 = 1													
					and field = 'Ответственный взыскатель')aaa											
	where 1 = 1															
			and rn = 1		
	;
																
	drop table if exists #base_region_customer;															
	SELECT 															
			r.IdCustomer													
			,rp.Name RegionPresence													
			,case 													
				  when r.ActualRegion = 'Хабаровский край        '												
				  then 'Хабаровский край'												
				  when r.ActualRegion = '' 												
				  then rp.Name												
				  when r.ActualRegion is null												
				  then rp.Name												
				  else r.ActualRegion												
				  end ActualRegion												
	into #base_region_customer															
	FROM stg._collection.Registration					r										
	left join stg._collection.RegionPresence			rp on rp.Id = r.RegionPresenceId	
	;
															
															
	drop table if exists #sum_pay;															
	select 															
			d.number external_id													
			,d.Id id_deal_space													
			,cast(p.PaymentDt as date) cdate													
			,sum(p.Amount) sum_pay													
	into #sum_pay															
	from [Stg].[_Collection].[Payment]				p											
	join stg._collection.Deals						d on d.id = p.IdDeal									
	where 1 = 1															
			and p.Amount > 0													
			and cast(p.PaymentDt as date) >= '2020-11-01'													
	group by d.number															
			,d.Id													
			,cast(p.PaymentDt as date)													
	;															
	
	drop table if exists #t1;															
	--drop table if exists collection.say_base_fixed_deals_hard;
	select 															
			cast(getdate() as date) 'дата отчёта'													
			,d.Number 'номер договора'													
			,dbo.customer_fio(d.IdCustomer) 'фио клиента'													
			,d.OverdueDays 'срок просрочки'		
			,brc.ActualRegion 'регион нахождения клиента'
			,cs.name 'стадия коллектинга договора'													
			,beh.employee_id
			,beh.fio_claimant 'фио ответственного сотрудника'											
			,case when bci.ClaimantId = beh.employee_id then bci.dt_st end 'дата закрепления клиента'
			,collection_users.email 'email ответственного сотрудника'
			--,beh.emeil 'emeil ответственного сотрудника'
	into #t1
	--into collection.say_base_fixed_deals_hard
	from stg._Collection.Deals								d									
	left join #base_region_customer							brc 
		on brc.IdCustomer = d.IdCustomer								
	join stg._Collection.collectingStage					cs 
		on cs.id = d.stageid										
	left join #base_Bankrupt_Confirmed						bbc 
		on bbc.id_Customer = d.IdCustomer									
	left join #base_Fraud_Confirmed							bfc 
		on bfc.id_Customer = d.IdCustomer								
	left join #base_Death_Confirmed							bdc 
		on bdc.id_Customer = d.IdCustomer								
	left join #base_HardFraud_Confirmed						bhfc 
		on bhfc.id_Customer = d.IdCustomer									
	left join #base_in_ka									bk 
		on bk.external_id = d.number						
	left join #base_claimant_id								bci 
		on 	bci.ObjectId = d.IdCustomer						
		and cast(getdate() as date) between bci.dt_st and bci.dt_end
	left join #base_employee_hard							beh 
		on beh.employee_id = bci.ClaimantId								
	left join stg._Collection.AspNetUsers					collection_users 
		on collection_users.EmployeeId = beh.employee_id
	where 1 = 1															
			and cs.Name in ('СБ','Hard','Legal','ИП')											
			and (													
						(case when cast(getdate() as date) >= bbc.dt_Bankrupt_Confirmed then 1 else 0 end) = 0										
					and (case when cast(getdate() as date) >= bfc.dt_Fraud_Confirmed then 1 else 0 end) = 0											
					and (case when cast(getdate() as date) >= bdc.dt_Death_Confirmed then 1 else 0 end) = 0											
					and (case when cast(getdate() as date) >= bhfc.dt_HardFraud_Confirmed then 1 else 0 end) = 0										
				)										
			and d.Fulldebt > 0
			and (case when beh.fio_claimant is not null or coalesce(bci.ClaimantId,0) = 0 then 1 else 0 end) = 1
			and (case when bci.ClaimantId = beh.employee_id then bci.dt_st end) >= cast(dateadd(dd,-1,getdate()) as date)
	group by 															
			d.Number												
			,dbo.customer_fio(d.IdCustomer)												
			,d.OverdueDays
			,brc.ActualRegion
			,cs.name												
			,beh.employee_id
			,beh.fio_claimant											
			,case when bci.ClaimantId = beh.employee_id then bci.dt_st end
			,collection_users.email
	having max(case when cast(getdate() as date) between bk.dt_st_in_ka and bk.dt_end_in_ka then 1 else 0 end) = 0														
	;
begin tran
	truncate table  collection.say_base_fixed_deals_hard;
	insert into collection.say_base_fixed_deals_hard 
	(
		[дата отчёта]
			, [номер договора]
			, [фио клиента]
			, [срок просрочки]
			, [регион нахождения клиента]
			, [стадия коллектинга договора]
			, [employee_id]
			, [фио ответственного сотрудника]
			, [дата закрепления клиента]
			, [email ответственного сотрудника]
	)
		select 
			[дата отчёта]
			, [номер договора]
			, [фио клиента]
			, [срок просрочки]
			, [регион нахождения клиента]
			, [стадия коллектинга договора]
			, [employee_id]
			, [фио ответственного сотрудника]
			, [дата закрепления клиента]
			, [email ответственного сотрудника]
		
		from #t1;
commit tran
-------------------------------------------------------------------------------------------------------------
-- ОКОНЧАНИЕ СБОРКИ РЕЕСТРА, КОТОРЫЙ ДОЛЖЕН БЫТЬ ОТПРАВЛЕН
--------------------------------------------------------------------------------------------------------------
-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set step_realization_procedure = 2
	where [id] = 1 -- name_procedure = 'collection.say_delivery_email_fixed_deals_hard'
	;

--------------------------------------------------------------------------------------------------------------
-- НАЧАЛО ПРОЦЕДУРЫ ОТПРАВКИ РЕЕСТРОВ СОТРУДНИКАМ
--------------------------------------------------------------------------------------------------------------	
	DECLARE @employee_id int -- id сотрудников, которым нужно отправить письмо

	DECLARE cursor_base_deliver CURSOR 
	FOR 
	select distinct
			employee_id
	from
			collection.say_base_fixed_deals_hard
	
	OPEN cursor_base_deliver  
	FETCH NEXT FROM cursor_base_deliver INTO @employee_id

	WHILE @@FETCH_STATUS = 0  -- Проверить состояние курсора

	BEGIN

	drop table if exists #t_for_deliver;
	select * 
	into #t_for_deliver -- создание таблицы, которая будет отправлена сотруднику
	from collection.say_base_fixed_deals_hard
	where coalesce(employee_id,0) = @employee_id;

--------------------------------------------------------------------------------
	--сбор письма на отправку
	
	BEGIN TRY
	
	DECLARE 
	@tableHTML NVARCHAR(MAX),
	@recipients NVARCHAR(MAX);

	set @recipients = (select distinct coalesce([email ответственного сотрудника],'d.korablev@carmoney.ru') from #t_for_deliver);

	SET @tableHTML =  
		N'<H1>Договора, которые распределены в работу за вчера и сегодня</H1>' +  
		N'<table border="1">' +  
		N'<tr><th>номер договора</th>' +  
		N'<th>фио клиента</th><th>регион нахождения клиента</th><th>срок просрочки</th>' +  
		N'<th>стадия коллектинга договора</th><th>фио ответственного сотрудника</th>' +  
		N'<th>дата закрепления клиента</th></tr>' +
		CAST ( ( SELECT 
						td = 	[номер договора]	,       '', 
						td = 	[фио клиента]	,       '', 
						td = 	[срок просрочки]	,       '', 
						td = 	[регион нахождения клиента]	,       '', 
						td = 	[стадия коллектинга договора]	,       '', 
						td = 	[фио ответственного сотрудника]	,       '', 
						td = 	[дата закрепления клиента]
				  FROM #t_for_deliver  
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 

		EXEC msdb.dbo.sp_send_dbmail 
		@recipients = @recipients,  
		@subject = 'Распределены в работу новые договора',  
		@body = @tableHTML,  
		@body_format = 'HTML';
	
	END TRY
	
	BEGIN CATCH
	-- логирование отработки процедуры
	update collection.say_stored_procedures_monitoring
	set error_realization_procedure = ERROR_MESSAGE()
	,flag_finish_procedure = 0
	,finish_procedure = getdate()
	where [id] = 1 -- name_procedure = 'collection.say_delivery_email_fixed_deals_hard'
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
			and [id] = 1 -- name_procedure = 'collection.say_delivery_email_fixed_deals_hard'
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
