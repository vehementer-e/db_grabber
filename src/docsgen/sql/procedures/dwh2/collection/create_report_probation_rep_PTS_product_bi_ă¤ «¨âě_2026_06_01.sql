  
 
 CREATE PROCEDURE [collection].[create_report_probation_rep_PTS_product_bi] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try








	drop table if exists #crutch_NextPaymentInfo;
	select *
	into #crutch_NextPaymentInfo
	from stg._collection.[NextPaymentInfo];
	update #crutch_NextPaymentInfo
	set nextpaymentdate = getdate()
	where datepart(yyyy,nextpaymentdate) = 0001
	;
	

	EXEC [collection].set_debug_info @sp_name
			,'1';


	drop table if exists #deals_probation;
	select t1.number
	into #deals_probation
	from  stg._collection.deals t1
	left join stg._collection.customers t2 on t2.Id = t1.IdCustomer
	where t1.probation = 1
			and (t2.LastName+' '+t2.Name+' '+t2.MiddleName) != 'ТЕСТ ТЕСТ ТЕСТ'
	group by t1.number
	;

	drop table if exists #v_balance_cmr_probation;
	select
			balance_cmr.external_id
			,balance_cmr.d cdate  --cdate
			,total_CF = balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) --balance_cmr.total_CF 
			,balance_cmr.overdue
			,balance_cmr.[остаток од] total_rest --total_rest
			,case when balance_cmr.dpd_p_coll = 0  --overdue_days_p
					and  balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) > 0  --balance_cmr.total_CF
					and lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) > 0 --cdate
					and  balance_cmr.[основной долг уплачено] + balance_cmr.[Проценты уплачено] + balance_cmr.[ПениУплачено] + ( balance_cmr.[ПереплатаУплачено]*(-1))+ balance_cmr.[ГосПошлинаУплачено] - (balance_cmr.[ПереплатаНачислено]*(-1)) > lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) --balance_cmr.total_CF --cdate
					then balance_cmr.dpd_p_coll  + 1 --overdue_days_p
					else balance_cmr.dpd_p_coll --overdue_days_p
					end overdue_days_p_corr
	into #v_balance_cmr_probation
	from #deals_probation deals_probation
	join dbo.dm_cmrstatbalance balance_cmr on balance_cmr.external_id = deals_probation.number ---  change dwh_new.dbo.v_balance_cmr 
	where balance_cmr.d >= '2022-01-01' --cdate
	;


	EXEC [collection].set_debug_info @sp_name
			,'2';



	drop table if exists #base_contact;							
	with base_1 ([id_deal]							
				,[number]				
				,date_number				
				,id_communication				
				,date_communication				
				,communication_type				
				,communication_resul				
				,сontact_person_type				
				,сommentary				
				,type_contact				
				,attemp				
				,contact) as				
	(select t1.id id_deal							
			,t1.number					
			,cast(t1.date as date) date_number					
			,t2.id id_communication					
			,cast(t2.[Date] as date) date_communication					
			,t3.name communication_type					
			,t4.Name communication_resul					
			,t5.Name contact_person_type					
			,t2.Commentary					
			,case when t4.Name = 'Консультация' then 1				
				  when t4.Name = 'Просит перезвонить' then 2			
				  when t4.Name in ('Автоответчик','Нет ответа','Ошибка','Потерянный вызов') then 3			
				  else null end type_contact				
			,1 attemp					
			,case when t6.CommunicationResultContacr is not null then 1 else 0 end contact					
	from Stg._Collection.Deals t1							
	join [Stg].[_Collection].[Communications] t2 on t2.IdDeal = t1.Id							
	join [Stg].[_Collection].[communicationType] t3 on t3.Id = t2.CommunicationType							
	join [Stg].[_Collection].[CommunicationResult] t4 on t4.Id = t2.CommunicationResultId							
	join [Stg].[_Collection].[ContactPersonType] t5 on t5.Id = t2.ContactPersonType							
	left join [collection].say_sprav_result_contact t6 on t6.CommunicationResultContacr = t4.Name							
	where t1.Probation = 1							
			and t3.Name in ('Исходящий звонок',					
								'Мессенджеры',
								'Входящий звонок',
								'Мобильное приложение',
								'Выезд',
								'Соц. сети',
								'Личная встреча в офисе'))
	select distinct t1.[number]							
			,max(t1.attemp) over (partition by t1.[number]) attemp_fact					
			,sum(t1.attemp) over (partition by t1.[number]) attemp_kolvo					
			,max(t1.contact) over (partition by t1.[number]) contact_fact					
			,case when t2.aa = 1 then '1.обещание оплаты'					
				  when t2.aa = 2 then '2.контакт без результата'				
				  when t2.aa = 3 then '3.нет контакта'				
				  end type_contact				
	into #base_contact							
	from base_1 t1							
	left join (select distinct [number]							
			,FIRST_VALUE(type_contact) over (partition by [number] order by [date_communication] desc) aa					
			from base_1)t2 on t2.[number] = t1.[number]
	;



	EXEC [collection].set_debug_info @sp_name
			,'3';


	drop table if exists #base_communication_result;
	select t01.*
	into #base_communication_result
	from
			(
			select 
					t2.number
					,cast(t1.date as datetime) date_communication
					,t1.manager
					,t4.name communication_type_name
					,t5.Name communication_result_name
					,t1.commentary
					,ROW_NUMBER() over (partition by t2.number order by t1.date desc) rn
			FROM [Stg].[_Collection].[Communications] t1
			join [Stg].[_Collection].[Deals] t2 on t2.id = t1.IdDeal
			join [Stg].[_Collection].[communicationType] t4 on t1.CommunicationType = t4.Id
			join [Stg].[_Collection].[CommunicationResult] t5 on t5.Id = t1.CommunicationResultId
			where 1 = 1
					and t4.Name in ('Исходящий звонок','Мессенджеры','Входящий звонок','Мобильное приложение','Выезд','Соц. сети','Личная встреча в офисе')
					and t5.Name not in ('Отклонен/Cброс','Автоответчик','Нет ответа')
					and t1.Manager not in ('Система','Administrator Admin Adminovich')
					and t2.Probation = 1
										)t01
	where t01.rn = 1
	group by number,date_communication,manager,communication_type_name,communication_result_name,commentary,rn
	;

	EXEC [collection].set_debug_info @sp_name
			,'4';



		BEGIN TRANSACTION

	delete from  [collection].[report_probation_rep_PTS_product_bi];
	insert [collection].[report_probation_rep_PTS_product_bi] (


 [r_date]
      ,[number]
      ,[cnt]
      ,[Дата выдачи]
      ,[Сумма кредита]
      ,[ФИО]
      ,[Стадия коллекшин]
      ,[Срок просрочки]
      ,[Бакет просрочки]
      ,[Остаток ОД]
      ,[Сумма для ПДП]
      ,[Сумма просрочки]
      ,[Сумма платежей за всё время]
      ,[Сумма последнего платежа]
      ,[Дата последнего платежа]
      ,[Дата платежа по графику]
      ,[Месяц платежа по графику]
      ,[Сумма платежа по графику]
      ,[Флаг достаточности средств на счете для платежа]
      ,[Brand]
      ,[Model]
      ,[YearOfIssue]
      ,[MarketPrice]
      ,[Адрес]
      ,[Регион]
      ,[Факт наличия попытки]
      ,[Колво попыток]
      ,[Факт наличия контакта]
      ,[Дата последней результативной коммуникации]
      ,[ФИО сотрудника коммуникации]
      ,[Тип коммуникации]
      ,[Результат коммуникации]
      ,[Комментарий по результату коммуникации]


)




	select getdate() r_date
			,t1.number							
			,1 cnt					
			,cast(tmp_v_credits.StartDate as date) 'Дата выдачи' --start_date
			,t1.sum 'Сумма кредита'					
			,t2.LastName+' '+t2.Name+' '+t2.MiddleName 'ФИО'					
			,coalesce(t3.Name,'Current') 'Стадия коллекшин'					
			,coalesce(balance_cmr_td.overdue_days_p_corr,0) 'Срок просрочки'	
			,case when coalesce(balance_cmr_td.overdue_days_p_corr,0) = 0 then '[01.0]'
				  when coalesce(balance_cmr_td.overdue_days_p_corr,0) between 1 and 9 then '[02.1-9]'
				  when coalesce(balance_cmr_td.overdue_days_p_corr,0) >= 10 then '[03.10+]'
				  end 'Бакет просрочки'
			,t1.DebtSum 'Остаток ОД'
			,t1.Fulldebt 'Сумма для ПДП'
			,case when coalesce(t1.CurrentAmountOwed,0) <= 0 then 0
				  when coalesce(balance_cmr_td.overdue_days_p_corr,0) = 0 then 0
				  else t1.CurrentAmountOwed end 'Сумма просрочки'
			,coalesce(pay.total_sum_pay,0) 'Сумма платежей за всё время'	
			,coalesce(pay.last_sum_pay,0) 'Сумма последнего платежа'
			,pay.last_date_pay 'Дата последнего платежа'					
			,case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)					
					end 'Дата платежа по графику'			
			,dateadd(day,- datepart(day, (case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)					
					end)) + 1, 			
			convert(date, (case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)					
					end))) 'Месяц платежа по графику'			
			,coalesce(t5.NextPaymentSum,0) 'Сумма платежа по графику'					
			,case when coalesce(t3.Name,'Current') = 'Closed'
				  then 1
				  when coalesce(balance_cmr_td.overdue_days_p_corr,0) > 0
				  then 0
				  when datepart(yyyy,t5.NextPaymentDate) >= 2000 
					   and cast(t5.NextPaymentDate as date) < cast(getdate() as date)
					   and coalesce(balance_cmr_td.overdue_days_p_corr,0) = 0
				  then 1
				  when datepart(yyyy,t5.NextPaymentDate) >= 2000 
					   and cast(t5.NextPaymentDate as date) = cast(getdate() as date)
					   and coalesce(pay.total_sum_pay,0) >= payment_schedule.total_plan_sum_pay
				  then 1
				  when balance_cmr_td.current_free_balance > 0
					   and balance_cmr_td.current_free_balance >= coalesce(t5.NextPaymentSum,0)
				  then 1 
				  else 0 end 'Флаг достаточности средств на счете для платежа'				
			  ,t8.[Brand]					
			  ,t8.[Model]					
			  ,t8.[YearOfIssue]					
			  ,t8.[MarketPrice]					
			  ,coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) [Адрес]					
			,case when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Москва%' then '01. Москва и область'					
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Московская%обл%' then '01. Москва и область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Ленинградская%обл%' then '02. Санкт-Петербург и область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Санкт-Петербург%' then '02. Санкт-Петербург и область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Краснодарский%край%' then '03. Краснодарский край'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Ростовская%обл%' then '04. Ростовская область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Нижегородская%обл%' then '05. Нижегородская область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Воронежская%обл%' then '06. Воронежская область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Башкортостан%Респ%' then '07. Башкортостан рес'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Татарстан%Респ%' then '08. Татарстан рес'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Волгоградская%обл%' then '09. Волгоградская область'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%Югра%' then '10. ХМАО'			
					when coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress) like '%ОРЕНБУРГСКАЯ%ОБЛ%' then '11. Оренбургская область'	
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%ЧЕЛЯБИНСКАЯ%ОБЛ%' then '12. Челябинская область'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%БЕЛГОРОДСКАЯ%ОБЛ%' then '13. Белгородская область'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%САМАРСКАЯ%ОБЛ%' then '14. Самарская область'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%УДМУРТСКАЯ%РЕСП%' then '15. Удмурская республика'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%АДЫГЕЯ%РЕСП%' then '16. Адыгея республика'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%САРАТОВСКАЯ%ОБЛ%' then '17. Саратовская область'
					when upper(coalesce(t9.ActualAddress,t9.PermanentRegisteredAddress)) like '%СВЕРДЛОВСКАЯ%ОБЛ%' then '18. Свердловская область'
					else '99. Прочие' end [Регион]			
			,coalesce(t6.attemp_fact,0) 'Факт наличия попытки'					
			,coalesce(t6.attemp_kolvo,0) 'Колво попыток'					
			,coalesce(t6.contact_fact,0) 'Факт наличия контакта'					
			,t10.date_communication 'Дата последней результативной коммуникации'
			,t10.manager 'ФИО сотрудника коммуникации'
			,t10.communication_type_name 'Тип коммуникации'
			,t10.communication_result_name 'Результат коммуникации'
			,t10.commentary 'Комментарий по результату коммуникации'
	from stg._collection.deals t1							
	left join stg._collection.customers t2 on t2.Id = t1.IdCustomer							
	left join stg._Collection.collectingStage t3 on t3.Id = t1.StageId							
	left join (  select
						pay_prom_1.external_id
						,pay_prom_1.cdate last_date_pay
						,pay_prom_1.total_CF last_sum_pay
						,pay_prom_1.total_sum_pay
				  from
				  (
					  select 
							balance_cmr.cdate
							,balance_cmr.external_id
							,balance_cmr.total_CF
							,sum(balance_cmr.total_CF) over (partition by balance_cmr.external_id) total_sum_pay
							,ROW_NUMBER() over (partition by balance_cmr.external_id order by balance_cmr.cdate desc) rn
					  from #v_balance_cmr_probation balance_cmr
					  where balance_cmr.total_CF > 0
				  )pay_prom_1
				  where pay_prom_1.rn = 1
				  )pay on pay.external_id = t1.Number						
	left join #crutch_NextPaymentInfo t5 on t5.[DealId] = t1.Id							
	left join #base_contact t6 on t6.number = t1.Number							
	join [Stg].[_Collection].[DealPledgeItem] t7 on t7.[DealId] = t1.id							
	join [Stg].[_Collection].[PledgeItem] t8 on t8.id = t7.[PledgeItemId]							
	left join [Stg].[_Collection].[registration] t9 on t9.IdCustomer = t1.IdCustomer
	left join #base_communication_result t10 on t10.Number = t1.Number
	left join ( select 
					external_id, overdue_days_p_corr
					,case when coalesce(overdue,0) < 0
							then coalesce(overdue,0) * -1
							else 0 end current_free_balance
				 from #v_balance_cmr_probation 
				 where cdate = cast(getdate() as date)
				 )balance_cmr_td on balance_cmr_td.external_id = t1.Number
	left join ( select distinct
						payment_schedule_prom_1.number
						,sum(payment_schedule_prom_1.[СуммаПлатежа]) over (partition by payment_schedule_prom_1.number) total_plan_sum_pay
				from
				(
					select distinct
							d.код number
							,dateadd(yy,-2000,cast(dateadd(day,- datepart(day, [ДатаПлатежа]) + 1, convert(date, [ДатаПлатежа])) as date)) 'Месяц платежа'
							,ROW_NUMBER() over 
							(partition by d.код
							,cast(dateadd(day,- datepart(day, [ДатаПлатежа]) + 1, convert(date, [ДатаПлатежа])) as date)
							order by cast([ДатаПлатежа] as date)) rn
							,g.[СуммаПлатежа]
					from [Stg].[_1cCMR].[РегистрСведений_ДанныеГрафикаПлатежей] g
					join [Stg].[_1cCMR].Справочник_Договоры d on g.Договор=d.Ссылка
					where g.[Действует] = 0x01
				)payment_schedule_prom_1
				where payment_schedule_prom_1.rn = 1
				)payment_schedule on payment_schedule.number = t1.Number
	left join dbo.dm_overdueindicators 					tmp_v_credits on tmp_v_credits.Number = t1.Number --dwh_new.dbo.tmp_v_credits
	where t1.probation = 1							
			and (case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)					
					end) is not null		
			and devdb.dbo.customer_fio(t2.id) not in (
													  'ТЕСТ ТЕСТ ТЕСТ'
													  ,'ХЭШ МП ТЕСТ'
														)
													
	
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
END	;
