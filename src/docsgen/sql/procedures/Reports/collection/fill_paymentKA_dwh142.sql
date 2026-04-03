
--exec [Collection].[fill_paymentKA_dwh142]
CREATE PROC [collection].[fill_paymentKA_dwh142] 
AS
BEGIN
	SET NOCOUNT ON;

----- создаём сет с фактами отправки договоров в агентства
drop table if exists #sent_to_agencies;
select  
	ac.External_id,
	ac.reestr,
	ac.st_date,
	ac.agent_name,
	COALESCE(fact_end_date, getdate()) AS fact_end_date,
	cast(isnull(bal.[Расчетный остаток всего], 0) as money) as total_rest
into #sent_to_agencies
from 
	--DWH-257
	(
	select
		agent_name = a.AgentName
		,reestr = RegistryNumber
		,external_id = d.Number
		,st_date  = cat.TransferDate
		,fact_end_date = cat.ReturnDate
		,plan_end_date = cat.PlannedReviewDate
		,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
	) as ac
	inner join
	dwh2.[dbo].[dm_CMRStatBalance] bal on bal.external_id=ac.External_id and ac.st_date=bal.d;

-----------  создаём сет с фактами поступления средств НО только когда количество дней просрочки больше нуля
drop table if exists #balances_with_payments;
select 
	bal.d as pdate,
	bal.external_id as contract_id,
	bal.[остаток всего] as debt_rest,
	bal.[сумма поступлений] as payment_amount,
	bal.dpd_begin_day as number_of_days_overdue
into #balances_with_payments
from 
	dwh2.[dbo].[dm_CMRStatBalance] bal 
where
    exists(select 1 from #sent_to_agencies a where a.External_id=bal.External_id and bal.d between a.st_date and a.fact_end_date)
	and
	[сумма поступлений]>0
	and 
	bal.dpd_begin_day>0

------------- мёрджим первый и второй сет и джойним со справочником клиентов, а так же даём полям названия как в отчёте
drop table if exists #paymentKA_dwh142_ds2;
SELECT
    p.pdate as dt,
	concat(spdog.[Фамилия], ' ', spdog.[Имя], ' ', spdog.[Отчество]) as [ФИО клиента],
    a.External_id as [Номер договора],
    a.total_rest as [Сумма долга, переданная в КА],
    p.debt_rest as [Сумма баланса по договору],
    a.agent_name [Наименование КА],
    p.payment_amount as [Сумма платежа],
	a.st_date as [Дата передачи в КА],
    p.number_of_days_overdue as [Количество дней задолженности на дату оплаты],
    a.reestr as [№ реестра передачи в работу КА]
into #paymentKA_dwh142_ds2
FROM #sent_to_agencies  AS a
     left join 
	 #balances_with_payments  AS p ON a.External_id = p.contract_id AND p.pdate between a.st_date AND a.fact_end_date
	 left join
	 dwh2.dm.ДоговорЗайма spdog on spdog.[КодДоговораЗайма] = p.contract_id;

begin try

	if OBJECT_ID('Collection.paymentKA_dwh142_heap') is null
	begin
		select top(0)
			*
		into [Collection].[paymentKA_dwh142_heap]
		from #paymentKA_dwh142_ds2
		CREATE NONCLUSTERED INDEX IX_paymentKA_dwh142_heap_dt 
		ON [Collection].[paymentKA_dwh142_heap](dt);
	end

	begin tran
		delete t from [Collection].[paymentKA_dwh142_heap] t
				
		insert into [Collection].[paymentKA_dwh142_heap]
		select
			*
		from #paymentKA_dwh142_ds2
	commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

END
