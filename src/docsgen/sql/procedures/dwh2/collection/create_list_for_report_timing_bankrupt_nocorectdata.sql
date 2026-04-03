  
 
 CREATE PROCEDURE [collection].[create_list_for_report_timing_bankrupt_nocorectdata] 

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
			where rn = 1)																				aa on aa.dealid = d.Id

where 1 = 1
		and d.StageId = 9
;




	EXEC [collection].set_debug_info @sp_name
			,'1';


/*drop table if exists #cmr_sum_pay;
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
/*SELECT 
	b.external_id,
	cdate = b.d,
	total_CF = b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
into #cmr_sum_pay
FROM Reports.dbo.dm_CMRStatBalance_2 AS b
WHERE b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
	> 0
;*/

SELECT 
	b.external_id,
	cdate = b.d,
	total_CF =[Сумма поступлений]--total_CF = b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
into #cmr_sum_pay
FROM dbo.dm_cmrstatbalance AS b --Reports.dbo.dm_CMRStatBalance_2
WHERE b.[Сумма поступлений]>0/*b.[основной долг уплачено] + b.[Проценты уплачено] + b.[ПениУплачено] + ( b.[ПереплатаУплачено]*(-1))+ b.[ГосПошлинаУплачено] - (b.[ПереплатаНачислено]*(-1))
	> 0*/
;
*/













	EXEC [collection].set_debug_info @sp_name
			,'2';



CREATE NONCLUSTERED INDEX ix_number
ON #base_dt_closed(number)
INCLUDE (dt_closed)
;

drop table if exists #t_BankruptconfirmedHistory;
SELECT * 
INTO #t_BankruptconfirmedHistory
FROM Stg._Collection.[BankruptconfirmedHistory]
--18219
;

/*drop table if exists #t_CustomerBankruptcy;
SELECT * 
INTO #t_CustomerBankruptcy
FROM Stg._Collection.CustomerBankruptcy
--2517
;*/



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


CREATE NONCLUSTERED INDEX ix_external_id
ON #cmr_sum_pay(external_id)
;









	EXEC [collection].set_debug_info @sp_name
			,'3';

begin transaction 

    delete from [collection].[list_for_report_timing_bankrupt_nocorectdata];
	insert [collection].[list_for_report_timing_bankrupt_nocorectdata] 
	
	(
	[ID клиента в Спейсе]
      ,[ФИО клиента]
      ,[Договор]
      ,[Дата заключение договора займа]
      ,[Дата заявление о банкротстве]
      ,[Дата признание банкротом]
      ,[Первая дата поступления ден.средств после банкротства]
      ,[Дата завершение процедуры банкротства]
      ,[Флаг ошибки в дате заявления о банкротстве]
      ,[Флаг ошибки в дате признание банкротом]
      ,[Флаг ошибки в дате поступления ден.средств после банкротства]
      ,[Флаг ошибки в дате завершение процедуры банкротства]
)

SELECT 
		cs.CustomerId 'ID клиента в Спейсе'
		--,devdb.dbo.customer_fio(cs.CustomerId) 'ФИО клиента'
		,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName) 'ФИО клиента'
		,d.Number 'Договор'
		,cast(d.date as date) 'Дата заключение договора займа'
		,cast(cb.[BankruptcyFilingDate] as date) 'Дата заявление о банкротстве'
		,cast(cb.[DateResultOfCourtsDecisionBankrupt] as date) 'Дата признание банкротом'
		,csp.dt_min_pay 'Первая дата поступления ден.средств после банкротства'
		,cast(cb.[BankruptcyFinishDate] as date) 'Дата завершение процедуры банкротства'
		,case when cb.[BankruptcyFilingDate] is null or coalesce(cb.[BankruptcyFilingDate],'2000-01-01') < d.[date]
					then 'ошибка в дате заявления о банкротстве' end 'Флаг ошибки в дате заявления о банкротстве'
		,case when cb.[DateResultOfCourtsDecisionBankrupt] is null or coalesce(cb.[DateResultOfCourtsDecisionBankrupt],'2000-01-01') < cb.[BankruptcyFilingDate]
					then 'ошибка в дате признание банкротом' end 'Флаг ошибки в дате признание банкротом'
		,case when csp.dt_min_pay is null or coalesce(csp.dt_min_pay,'2000-01-01') < cb.[DateResultOfCourtsDecisionBankrupt]
					then 'ошибка в датепоступления ден.средств после банкротства' end 'Флаг ошибки в дате поступления ден.средств после банкротства'
		,case when cb.[BankruptcyFinishDate] is null or coalesce(cb.[BankruptcyFinishDate],'2000-01-01') < csp.dt_min_pay
					then 'ошибка в дате завершение процедуры банкротства' end 'Флаг ошибки в дате завершение процедуры банкротства'
--SELECT *
--from [c2-vsr-cl-sql].[collection_night00].[dbo].[BankruptconfirmedHistory]			bc
from #t_BankruptconfirmedHistory													AS bc
join [Stg].[_Collection].[CustomerStatus]											cs on cs.Id = bc.[ObjectId]
join stg._Collection.deals															d on d.IdCustomer = cs.CustomerId
LEFT JOIN stg._Collection.customers													AS c ON c.Id = cs.CustomerId
left join #base_dt_closed															bdtc on bdtc.Number = d.Number
--left join [c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy				cb on cb.CustomerId = d.IdCustomer
left join #t_CustomerBankruptcy														AS cb on cb.CustomerId = d.IdCustomer
left join /*(select 
				d1.number
				,min(csp1.cdate) dt_min_pay
			--from [c2-vsr-cl-sql].[collection_night00].[dbo].CustomerBankruptcy		cb1
			from #t_CustomerBankruptcy												AS cb1
			join stg._Collection.deals												d1 on cb1.CustomerId = d1.IdCustomer
			join #cmr_sum_pay														csp1 on csp1.external_id = d1.number
			where 1 = 1
					and csp1.cdate >= 
						cast(cb1.[DateResultOfCourtsDecisionBankrupt] as date)
			group by d1.number
			)	*/ #cmr_sum_pay																csp on csp.external_id = d.Number --number	csp on csp.number = d.Number
where 1 = 1
		and [Field] = 'Статус назначен'
		and [NewValue] = 'True'
		and cb.[BankruptcyFinishDate] is not null
		and ((case when cb.[BankruptcyFilingDate] is not null and coalesce(cb.[BankruptcyFilingDate],'2000-01-01') >= d.[date]
					then 1 else 0 end) != 1
		or (case when cb.[DateResultOfCourtsDecisionBankrupt] is not null and coalesce(cb.[DateResultOfCourtsDecisionBankrupt],'2000-01-01') >= cb.[BankruptcyFilingDate]
					then 1 else 0 end) != 1
		or (case when csp.dt_min_pay is not null and coalesce(csp.dt_min_pay,'2000-01-01') >= cb.[DateResultOfCourtsDecisionBankrupt]
					then 1 else 0 end) != 1
		or (case when cb.[BankruptcyFinishDate] is not null and coalesce(cb.[BankruptcyFinishDate],'2000-01-01') >= csp.dt_min_pay
					then 1 else 0 end) != 1)
group by cs.CustomerId
		,d.Number
		--,devdb.dbo.customer_fio(cs.CustomerId)
		,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName)
		,bdtc.dt_closed
		,cast(d.date as date)
		,cast(cb.[BankruptcyFilingDate] as date)
		,cast(cb.[DateResultOfCourtsDecisionBankrupt] as date)
		,csp.dt_min_pay
		,cast(cb.[BankruptcyFinishDate] as date)
		,case when cb.[BankruptcyFilingDate] is null or coalesce(cb.[BankruptcyFilingDate],'2000-01-01') < d.[date]
					then 'ошибка в дате заявления о банкротстве' end
		,case when cb.[DateResultOfCourtsDecisionBankrupt] is null or coalesce(cb.[DateResultOfCourtsDecisionBankrupt],'2000-01-01') < cb.[BankruptcyFilingDate]
					then 'ошибка в дате признание банкротом' end
		,case when csp.dt_min_pay is null or coalesce(csp.dt_min_pay,'2000-01-01') < cb.[DateResultOfCourtsDecisionBankrupt]
					then 'ошибка в датепоступления ден.средств после банкротства' end
		,case when cb.[BankruptcyFinishDate] is null or coalesce(cb.[BankruptcyFinishDate],'2000-01-01') < csp.dt_min_pay
					then 'ошибка в дате завершение процедуры банкротства' end
having cast(min(bc.ChangeDate) as date) > coalesce(bdtc.dt_closed,'2000-01-01')
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
