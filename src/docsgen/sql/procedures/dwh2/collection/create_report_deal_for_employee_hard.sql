  
 
CREATE PROC collection.create_report_deal_for_employee_hard 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try






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
															
		EXEC [collection].set_debug_info @sp_name
			,'1';
			
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
															
		EXEC [collection].set_debug_info @sp_name
			,'2';
	
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
		
			EXEC [collection].set_debug_info @sp_name
			,'3';

	drop table if exists #base_in_ka;															
	SELECT [external_id]
	,[Дата передачи в КА] dt_st_in_ka
	,isnull([Дата отзыва],[Плановая дата отзыва]) dt_end_in_ka
	into #base_in_ka															
	--DWH-257
	from (
	select
		[Наименование КА] = a.AgentName
		,[№ реестра передачи] = RegistryNumber
		,external_id = d.Number
		,[Дата передачи в КА]  = cat.TransferDate
		,[Дата отзыва] = cat.ReturnDate
		,[Плановая дата отзыва] = cat.PlannedReviewDate
		,[Текущий статус] = cat.CurrentStatus
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
	) as t
	;															
															
															
	drop table if exists #base_employee_hard;															
	select 															
			resh.Employeeid employee_id													
			,e.LastName+' '+e.FirstName+' '+e.MiddleName fio_claimant													
			,resh.CollectingStageName employee_stage_collection													
	into #base_employee_hard															
	--from [Stg].[_Collection].[ReportEmployeeStatisticsHistory]		resh
	from Stg._Collection.v_EmployeeCollectingStageHistory AS resh
	left join stg._collection.Employee														e on e.id = resh.Employeeid	
	where 1 = 1															
			and resh.CollectingStageName = 'Hard'													
			and resh.Employeeid != 11												
	group by resh.Employeeid															
			,(e.LastName+' '+e.FirstName+' '+e.MiddleName)													
			,resh.CollectingStageName													
	union															
	select id															
			,e.LastName+' '+e.FirstName+' '+e.MiddleName													
			,'Hard'													
	from stg._Collection.Employee		e													
	where id = 106															
	;															
		
			EXEC [collection].set_debug_info @sp_name
			,'4';

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
															
		EXEC [collection].set_debug_info @sp_name
			,'5';		
			
	drop table if exists #sum_pay;															
	select 															
			d.number external_id													
			,d.Id id_deal_space													
			,cast(p.PaymentDt as date) cdate													
			,sum(p.Amount) sum_pay													
	into #sum_pay															
	from [Stg].[_Collection].[Payment]				p											
	join stg._collection.Deals						d on d.id = p.IdDeal	
	--left join dbo.dm_cmrstatbalance s_1 on d.number=s_1.external_id
	where 1 = 1															
			and p.Amount > 0													
			and cast(p.PaymentDt as date) >= '2020-11-01'													
	group by d.number															
			,d.Id													
			,cast(p.PaymentDt as date)													
	;	
	
		EXEC [collection].set_debug_info @sp_name
			,'6';

 --drop table if exists #type_product; --для присоединения поля тип продукта
 drop table if exists #Final_table;
 with  type_product as (
 select 	 external_id,
			[Тип Продукта]
 from dbo.dm_cmrstatbalance
 group by external_id,
		[Тип Продукта] ),


															
 general as (	select 															
			cast(getdate() as date) 'дата отчёта'													
			,d.Number 'номер договора'													
			,reports.dbo.customer_fio(d.IdCustomer) 'фио клиента'													
			,cs.name 'стадия коллектинга договора'													
			,d.OverdueDays 'срок просрочки'													
			,devdb.dbo.bucket_dpd(d.OverdueDays) 'бакет просрочки'													
			,beh.fio_claimant 'фио ответственного сотрудника'
			,case when bci.ClaimantId = beh.employee_id then bci.dt_st end 'дата закрепления клиента'
			,case when beh.fio_claimant is null then 0 else 1 end 'флаг закрепления договоа за сотрудником'													
			,brc.ActualRegion 'регион нахождения клиента'
			--[Тип Продукта]
	from stg._Collection.Deals								d	
	left join #base_region_customer							brc on brc.IdCustomer = d.IdCustomer								
	join stg._Collection.collectingStage					cs on cs.id = d.stageid										
	left join #base_Bankrupt_Confirmed						bbc on bbc.id_Customer = d.IdCustomer									
	left join #base_Fraud_Confirmed							bfc on bfc.id_Customer = d.IdCustomer								
	left join #base_Death_Confirmed							bdc on bdc.id_Customer = d.IdCustomer								
	left join #base_HardFraud_Confirmed						bhfc on bhfc.id_Customer = d.IdCustomer									
	left join #base_in_ka									bk on bk.external_id = d.number						
	left join #base_claimant_id								bci on 	bci.ObjectId = d.IdCustomer						
																and cast(getdate() as date) between bci.dt_st and bci.dt_end
	left join #base_employee_hard							beh on beh.employee_id = bci.ClaimantId								
	left join devdb.dbo.say_sprav_field_actual_region		far on far.employee_id = bci.ClaimantId													
																and far.Field_Actual_Region = brc.ActualRegion
   --left join #type_product s_1 on d.number=s_1.external_id
      

  

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
				group by 															
			d.Number													
			,reports.dbo.customer_fio(d.IdCustomer)													
			,cs.name													
			,d.OverdueDays													
			,devdb.dbo.bucket_dpd(d.OverdueDays)													
			,bci.ClaimantId													
			,beh.fio_claimant													
			,case when bci.ClaimantId = beh.employee_id then bci.dt_st end
			,case when beh.fio_claimant is null then 0 else 1 end													
			,brc.ActualRegion
			--,[Тип Продукта]
	having max(case when cast(getdate() as date) between bk.dt_st_in_ka and bk.dt_end_in_ka then 1 else 0 end) = 0														
	)



	select 															
			cast(getdate() as date) 'дата отчёта'													
			,g.[номер договора] 																							
			,g.[фио клиента] 												
			,g.[стадия коллектинга договора]													
			,g.[срок просрочки]												
			,g.[бакет просрочки]												
			,g.[фио ответственного сотрудника]
			,g.[дата закрепления клиента]
			,g.[флаг закрепления договоа за сотрудником]												
			,g.[регион нахождения клиента]
			,[Тип Продукта]
			into #Final_table
			from general g 
			left join type_product t on g.[номер договора]=t.external_id
				


begin transaction 

    delete from [collection].[report_deal_for_employee_hard];
	insert [dwh2].[collection].[report_deal_for_employee_hard] (

	   [дата отчёта]
      ,[номер договора]
      ,[фио клиента]
      ,[стадия коллектинга договора]
      ,[срок просрочки]
      ,[бакет просрочки]
      ,[фио ответственного сотрудника]
      ,[дата закрепления клиента]
      ,[флаг закрепления договоа за сотрудником]
      ,[регион нахождения клиента]
      ,[Тип Продукта]

)



 select 
       [дата отчёта]
      ,[номер договора]
      ,[фио клиента]
      ,[стадия коллектинга договора]
      ,[срок просрочки]
      ,[бакет просрочки]
      ,[фио ответственного сотрудника]
      ,[дата закрепления клиента]
      ,[флаг закрепления договоа за сотрудником]
      ,[регион нахождения клиента]
      ,[Тип Продукта]


 from #Final_table

  
  commit transaction 

				
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
END;
