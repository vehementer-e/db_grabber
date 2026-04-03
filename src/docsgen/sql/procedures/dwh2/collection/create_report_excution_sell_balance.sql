  
 
 CREATE PROCEDURE [collection].[create_report_excution_sell_balance] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try









drop table if exists #base_deals_closed;
	select
			number
			,dt_rep
	into #base_deals_closed
	from
	(
	select
			d.number
			,cast(dh.changedate as date) dt_rep
			,row_number()  over (partition by d.number order by dh.changedate desc) rn
	from
			stg._collection.dealhistory						dh
			join stg._Collection.Deals						d on d.id = dh.objectid
	where 1=1
			and dh.field = 'Стадия коллектинга договора'
			and dh.newvalue = 9
	)a
	where 1=1
			and rn = 1
	;

EXEC [collection].set_debug_info @sp_name
			,'1';

	drop table if exists #base_deals_sold;
	select
			number
			,dt_rep
	into #base_deals_sold
	from
	(
	select
			d.number
			,cast(dh.changedate as date) dt_rep
			,row_number()  over (partition by d.number order by dh.changedate desc) rn
	from
			stg._collection.dealhistory						dh
			join stg._Collection.Deals						d on d.id = dh.objectid
	where 1=1
			and dh.field = 'Стадия коллектинга договора'
			and dh.newvalue = 14
	)a
	where 1=1
			and rn = 1
	;

	EXEC [collection].set_debug_info @sp_name
			,'2';


	drop table if exists #base_customers_bankrupt;
	select
			CustomerId
	into #base_customers_bankrupt
	from
			stg._collection.CustomerStatus
	where 1=1
			and CustomerStateId = 16
			and IsActive = 1
	group by
			CustomerId
	;

	EXEC [collection].set_debug_info @sp_name
			,'3';

	drop table if exists #deals;
	select 
			number
			,IsCreditVacation
	into #deals
	from 
			stg._Collection.deals								d
			left join Stg._Collection.customers								c on c.Id = d.IdCustomer --добавил чтобы убрать функцию
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
			and concat(c.LastName, ' ', c.Name, ' ', c.MiddleName)!= 'ТЕСТ ТЕСТ ТЕСТ' -- concat(d.LastName, ' ', d.Name, ' ', d.MiddleName) reports.dbo.customer_fio(d.IdCustomer)
	
	
	
	
	
	
	
	;

	/*delete from #deals --не актуально
	where number in (select t1.external_id
					from [dm].[Collection_StrategyDataMart] t1 --dwh_new.dialer.strategyDataMart2_CMR t1
					left join (select external_id
								from [dm].[Collection_StrategyDataMart] --dwh_new.dialer.strategyDataMart2_CMR
								where strategydate = '2021-06-18'
										and HasFreezing = 1)	t2 on t2.external_id = t1.external_id
					left join stg._collection.deals				d on d.number = t1.external_id
					where t1.strategydate = '2021-06-19'
							and t1.HasFreezing = 1
							and t2.external_id is null
							and coalesce(d.IsCreditVacation,0) != 1)
	;*/

	update #deals
	set 
			 IsCreditVacation = (case when d.IsCreditVacation = 1 then 1
									  else f.IsFreeze
									  end)
	from #deals																		d
	left join (select s.Number
						,s.IsFreeze
				from stg._Collection.deals  s --- dwh_new.dialer.strategyDataMart2_CMR s  [dm].[Collection_StrategyDataMart]
				where 1 = 1
						and s.IsFreeze = 1
						--and cast(s.strategydate as date) = cast(getdate() as date)
				group by s.Number
						,s.IsFreeze)													f on f.Number = d.number
	;


	EXEC [collection].set_debug_info @sp_name
			,'4';



	drop table if exists #base_kk;
	select 
			number
	into #base_kk
	from 
			#deals 
	where 1=1
			and IsCreditVacation = 1
	group by
			number
	;

EXEC [collection].set_debug_info @sp_name
			,'5';




			
			BEGIN TRANSACTION

	delete from [collection].[report_excution_sell_balance];
	insert [collection].[report_excution_sell_balance] (


	[номер договора]
      ,[ФИО клиента]
      ,[идентификатор ИЛ]
      ,[номер ИЛ]
      ,[тип ИЛ]
      ,[куратор ИП]
      ,[росп наименование]
      ,[регион уфссп]
      ,[дата получения ИЛ]
      ,[месяц получения ИЛ]
      ,[год получения ИЛ]
      ,[квартал получения ИЛ]
      ,[порядковый месяц получения ИЛ]
      ,[номер ИП]
      ,[дата возбуждения ИП]
      ,[кол-во дней между получением ИЛ и возбуждением ИП]
      ,[флаг выполнения норматива по возбуждению ИП]
      ,[кол-во ИЛ подходящих под возбуждение ИП]


	  )

	select
			d.number 'номер договора'
			,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName) 'ФИО клиента'
			--,reports.dbo.customer_fio(d.IdCustomer) 'фио клиента'
			,eo.id 'идентификатор ИЛ'
			,coalesce(eo.Number,'не указан') 'номер ИЛ'
			,case when eo.Type = 1 then 'Обеспечительные меры'
				  when eo.Type = 2 then 'Денежное требование' 
				  when eo.Type = 3 then 'Обращение взыскания' 
				  when eo.Type = 4 then 'Взыскание и обращение взыскания' 
				  else 'Не указан' end 'тип ИЛ'
				  ,concat(e.LastName, ' ', e.FirstName, ' ', e.MiddleName) 'куратор ИП'
				  /*'куратор ИП' = (select e.LastName+' '+e.FirstName+' '+e.MiddleName
												from stg._Collection.Employee e
												where e.id = c.ClaimantExecutiveProceedingId)*/
			--,reports.dbo.employee_fio(c.ClaimantExecutiveProceedingId) 'куратор ИП'
			,fssp.name	'росп наименование'
			,concat(fssp.NameRegion, '',  '', fssp.TypeRegion) 'регион уфссп'
			--,coalesce(fssp.NameRegion,'')+' '+coalesce(fssp.TypeRegion,'') 'регион уфссп'
			,cast(eo.ReceiptDate as date) 'дата получения ИЛ'
			,dateadd(dd,1, EOMONTH(eo.ReceiptDate, -1)) 'месяц получения ИЛ'
			--,reports.dbo.dt_st_month(eo.ReceiptDate) 'месяц получения ИЛ'
			,datepart(yyyy,eo.ReceiptDate) 'год получения ИЛ'
			,datepart(qq,eo.ReceiptDate) 'квартал получения ИЛ'
			,datepart(mm,eo.ReceiptDate) 'порядковый месяц получения ИЛ'
			,epe.casenumberinfssp 'номер ИП'
			,cast(epe.ExcitationDate as date) 'дата возбуждения ИП'
			,datediff(dd,eo.ReceiptDate,epe.ExcitationDate) 'кол-во дней между получением ИЛ и возбуждением ИП'
			,case when epe.ExcitationDate is null then 0  
				  when datediff(dd,eo.ReceiptDate,epe.ExcitationDate) < 71 then 1 
				  else 0 end 'флаг выполнения норматива по возбуждению ИП'
			,1 'кол-во ИЛ подходящих под возбуждение ИП'
	from
			stg._collection.deals											d
			left join Stg._Collection.customers								c on c.Id = d.IdCustomer
            left join Stg._Collection.JudicialProceeding					jp on jp.DealId = d.Id
            left join Stg._Collection.JudicialClaims						jc on jc.JudicialProceedingId = jp.Id
            left join Stg._Collection.EnforcementOrders						eo on eo.JudicialClaimId = jc.Id
			left join Stg._Collection.EnforcementProceeding					ep on ep.EnforcementOrderId = eo.Id
			left join Stg._Collection.EnforcementProceedingExcitation		epe on epe.EnforcementProceedingId = ep.Id
			left join Stg._Collection.DepartamentFSSP						fssp on fssp.Id = epe.DepartamentFSSPId
			left join #base_deals_closed									bdc on bdc.number = d.number
			left join #base_deals_sold										bds on bds.number = d.number
			left join #base_customers_bankrupt								bcb on bcb.CustomerId = d.IdCustomer
			left join #base_kk												bkk on bkk.Number = d.Number
			join stg._Collection.Employee                              e  on e.id = c.ClaimantExecutiveProceedingId --перенес из селекта
	where 1=1
			and eo.id is not null -- по договору есть ИЛ
			and eo.ReceiptDate is not null -- известна дата получения ИЛ
			and (case when epe.ExcitationDate <= eo.ReceiptDate then 0 else 1 end) = 1 -- дата возбуждения ИП не меньше даты получения ИЛ
			and eo.ReceiptReturnDate is null -- нет даты возврата листа на доработку
			and bdc.dt_rep is null -- нет даты закрытия договора
			and bds.dt_rep is null -- нет даты продажи договора
			and bcb.CustomerId is null -- клиент не банкрот
			and bkk.Number is null -- договор не был на кк или в заморозке
			and concat(c.LastName, ' ', c.Name, ' ', c.MiddleName)  != 'ТЕСТ ТЕСТ ТЕСТ' --reports.dbo.customer_fio(d.IdCustomer) 
	
	
	
	
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
