  
 
 CREATE PROCEDURE [collection].[create_list_for_report_timing_bankrupt] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try




drop table if exists #base_dt_closed;
select d.number
		,cast(coalesce(d.LastPaymentDate,dt_closed) as date) dt_closed
into #base_dt_closed
from stg._Collection.deals AS d
left join (select dt_closed
					,dealid
			from
			(
				select cast(dh.changedate as date) dt_closed
						,dh.ObjectId dealid
						,ROW_NUMBER() over (partition by dh.ObjectId order by dh.changedate) rn
				from stg._Collection.DealHistory dh
				where 1 = 1
						and field = 'Стадия коллектинга договора'
						and newvalue = '9'
			)aa
			where rn = 1) AS 	aa on aa.dealid = d.Id

where 1 = 1
		and d.StageId = 9
;
--00:00:14
--60565




drop table if exists #t_BankruptconfirmedHistory;
SELECT * 
INTO #t_BankruptconfirmedHistory
FROM Stg._Collection.[BankruptconfirmedHistory]---[c2-vsr-cl-sql].[collection_night00].[dbo].[BankruptconfirmedHistory]
--18219
;


drop table if exists #deals;
SELECT IdCustomer, Number 
INTO #deals
FROM stg._Collection.deals  

; ---дополнительная временная таблица так как при не дает джойнить с таблицей  #t_CustomerBankruptcy  поля с одинаковыми названиями



drop table if exists #t_CustomerBankruptcy;
SELECT * 
INTO #t_CustomerBankruptcy
FROM Stg._Collection.CustomerBankruptcy cb---[c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy
left join #deals  d on  cb.CustomerId = d.IdCustomer
--2517
;









	EXEC [collection].set_debug_info @sp_name
			,'1';

drop table if exists #cmr_sum_pay;
/*
select
		cmr.external_id
		,cmr.cdate
		,cmr.total_CF sum_pay
into #cmr_sum_pay
from dwh_new.dbo.v_balance_cmr		cmr
where 1 = 1
		and cmr.total_CF > 0
;
*/
SELECT 
	b.external_id ,
	dt_min_pay = min(b.d) 
	--total_CF =[Сумма поступлений]--total_CF = b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
into #cmr_sum_pay
FROM dbo.dm_cmrstatbalance AS b --Reports.dbo.dm_CMRStatBalance_2
WHERE b.[Сумма поступлений]>0/*b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
	> 0*/ and exists(Select top(1)  1 from #t_CustomerBankruptcy cb
	where cb.Number = b.external_id
		and b.d >=cast(cb.[DateResultOfCourtsDecisionBankrupt] as date)
	)
group by b.external_id
;








	EXEC [collection].set_debug_info @sp_name
			,'2';
--00:00:55
--873849

CREATE NONCLUSTERED INDEX ix_external_id
ON #cmr_sum_pay(external_id)
;

CREATE NONCLUSTERED INDEX ix_number
ON #base_dt_closed(number)
INCLUDE (dt_closed)
;

/*drop table if exists #t_BankruptconfirmedHistory;
SELECT * 
INTO #t_BankruptconfirmedHistory
FROM Stg._Collection.[BankruptconfirmedHistory]---[c2-vsr-cl-sql].[collection_night00].[dbo].[BankruptconfirmedHistory]
--18219
;

drop table if exists #t_CustomerBankruptcy;
SELECT * 
INTO #t_CustomerBankruptcy
FROM Stg._Collection.CustomerBankruptcy ---[c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy
--2517
;*/


/*
drop table if exists #cmr_sum_pay_min;
 select 
				d1.number
				,min(csp1.cdate) dt_min_pay
			--from [c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy		cb1
			into #cmr_sum_pay_min
			FROM #t_CustomerBankruptcy											 AS cb1
			join stg._Collection.deals												d1 on cb1.CustomerId = d1.IdCustomer
			join #cmr_sum_pay														csp1 on csp1.external_id = d1.number
			where 1 = 1
					and csp1.cdate >= 
						cast(cb1.[DateResultOfCourtsDecisionBankrupt] as date)
			group by d1.number*/



	EXEC [collection].set_debug_info @sp_name
			,'3';



begin transaction 

    delete from [collection].[list_for_report_timing_bankrupt];
	insert [collection].[list_for_report_timing_bankrupt] 
	
	(

	   [ID клиента в Спейсе]
      ,[ФИО клиента]
      ,[Договор]
      ,[Месяц заявление о банкротстве]
      ,[Дата заключение договора займа]
      ,[Дата заявление о банкротстве]
      ,[Дата признание банкротом]
      ,[Первая дата поступления ден.средств после банкротства]
      ,[Дата завершение процедуры банкротства]
      ,[Дней от выдачи кредита до заявления о банкротстве]
      ,[Дней от  заявления о банкротстве до признания банкротом]
      ,[Дней от признания банкротом до первого платежа]
      ,[Дней от первого платежа до завершения банкротства]

	  )



SELECT 
		cs.CustomerId 'ID клиента в Спейсе'

		--,devdb.dbo.customer_fio(cs.CustomerId) 'ФИО клиента'
		,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName) 'ФИО клиента'

		,d.Number 'Договор'

		--,reports.dbo.dt_st_month(cb.[BankruptcyFilingDate]) 'Месяц заявление о банкротстве'
		,dateadd(mm,-1,dateadd(dd,1,eomonth(cast(cb.[BankruptcyFilingDate] as date)))) 'Месяц заявление о банкротстве'

		,cast(d.date as date) 'Дата заключение договора займа'
		,cast(cb.[BankruptcyFilingDate] as date) 'Дата заявление о банкротстве'
		,cast(cb.[DateResultOfCourtsDecisionBankrupt] as date) 'Дата признание банкротом'
		,csp.dt_min_pay 'Первая дата поступления ден.средств после банкротства'
		,cast(cb.[BankruptcyFinishDate] as date) 'Дата завершение процедуры банкротства'
		,datediff(dd,d.date,cb.[BankruptcyFilingDate]) 'Дней от выдачи кредита до заявления о банкротстве'
		,datediff(dd,cb.[BankruptcyFilingDate],cb.[DateResultOfCourtsDecisionBankrupt]) 'Дней от  заявления о банкротстве до признания банкротом'
		,datediff(dd,cb.[DateResultOfCourtsDecisionBankrupt],csp.dt_min_pay) 'Дней от признания банкротом до первого платежа'
		,datediff(dd,csp.dt_min_pay,cb.[BankruptcyFinishDate]) 'Дней от первого платежа до завершения банкротства'
--from [c2-vsr-cl-sql].[collection_night00].[dbo].[BankruptconfirmedHistory]			bc
FROM #t_BankruptconfirmedHistory												 AS bc
join [Stg].[_Collection].[CustomerStatus]											cs on cs.Id = bc.[ObjectId]
join stg._Collection.deals															d on d.IdCustomer = cs.CustomerId
LEFT JOIN stg._Collection.customers												 AS c ON c.Id = cs.CustomerId
left join #base_dt_closed															bdtc on bdtc.Number = d.Number
--left join [c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy				cb on cb.CustomerId = d.IdCustomer
LEFT JOIN #t_CustomerBankruptcy													 AS cb on cb.CustomerId = d.IdCustomer
left join /*(select 
				d1.number
				,min(csp1.cdate) dt_min_pay
			--from [c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy		cb1
			FROM #t_CustomerBankruptcy											 AS cb1
			join stg._Collection.deals												d1 on cb1.CustomerId = d1.IdCustomer
			join #cmr_sum_pay														csp1 on csp1.external_id = d1.number
			where 1 = 1
					and csp1.cdate >= 
						cast(cb1.[DateResultOfCourtsDecisionBankrupt] as date)
			group by d1.number
			)*/		#cmr_sum_pay																csp on csp.external_id = d.Number --number
where 1 = 1
		and [Field] = 'Статус назначен'
		and [NewValue] = 'True'
		and cb.[BankruptcyFinishDate] is not null
		and (case when cb.[BankruptcyFilingDate] is not null and coalesce(cb.[BankruptcyFilingDate],'2000-01-01') >= d.[date]
					then 1 else 0 end) = 1
		and (case when cb.[DateResultOfCourtsDecisionBankrupt] is not null and coalesce(cb.[DateResultOfCourtsDecisionBankrupt],'2000-01-01') >= cb.[BankruptcyFilingDate]
					then 1 else 0 end) = 1
		and (case when csp.dt_min_pay is not null and coalesce(csp.dt_min_pay,'2000-01-01') >= cb.[DateResultOfCourtsDecisionBankrupt]
					then 1 else 0 end) = 1
		and (case when cb.[BankruptcyFinishDate] is not null and coalesce(cb.[BankruptcyFinishDate],'2000-01-01') >= csp.dt_min_pay
					then 1 else 0 end) = 1
group by cs.CustomerId
		,d.Number

		--,devdb.dbo.customer_fio(cs.CustomerId)
		,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName)

		,bdtc.dt_closed

		--,reports.dbo.dt_st_month(cb.[BankruptcyFilingDate])
		,dateadd(mm,-1,dateadd(dd,1,eomonth(cast(cb.[BankruptcyFilingDate] as date))))

		,cast(d.date as date)
		,cast(cb.[BankruptcyFilingDate] as date)
		,cast(cb.[DateResultOfCourtsDecisionBankrupt] as date)
		,csp.dt_min_pay
		,cast(cb.[BankruptcyFinishDate] as date)
		,datediff(dd,d.date,cb.[BankruptcyFilingDate])
		,datediff(dd,cb.[BankruptcyFilingDate],cb.[DateResultOfCourtsDecisionBankrupt])
		,datediff(dd,cb.[DateResultOfCourtsDecisionBankrupt],csp.dt_min_pay)
		,datediff(dd,csp.dt_min_pay,cb.[BankruptcyFinishDate])
having cast(min([ChangeDate]) as date) > coalesce(bdtc.dt_closed,'2000-01-01')
;




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
