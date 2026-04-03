
CREATE   procedure [webReport].[fill_finance_incoming]
as
begin
declare @startDate date , @endDate date = EOMONTH(getdate())
set @startDate = dateadd(dd, 1, EOMONTH(getdate(), -13))
declare @firstDayMonth date = dateadd(dd,1, EOMONTH(getdate(),-1))

begin try
	if OBJECT_ID('webReport.dm_finance_incoming_by_month') is null
	begin
		create table webReport.dm_finance_incoming_by_month
		(
			Тип nvarchar(255),
			dt date,
			Прибыль money
		)
	
	end

	
	if OBJECT_ID('webReport.dm_finance_incoming_by_month_stage') is null
	begin
		select top(0)
			Тип,
			dt ,
			Прибыль
		into webReport.dm_finance_incoming_by_month_stage
		from  webReport.dm_finance_incoming_by_month
	end

	if exists(select top(1) 1 from webReport.dm_finance_incoming_by_month_stage)
	begin
		truncate table webReport.dm_finance_incoming_by_month_stage
	end
	;with cte_repayments as
	(
		select
			Тип = 'Доход с погашений'
			,dt = [ДеньПлатежа]
			--iif(
			--	[ДеньПлатежа]>=@firstDayMonth,[ДеньПлатежа]
			--	,EOMONTH([ДеньПлатежа])
			--	)
			,Прибыль =sum(isnull(case 
				when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0) )
		from Analytics.dbo.v_repayments
		where [ДеньПлатежа] between @startDate and @endDate
		group by  [ДеньПлатежа]
				
	), cte_comissions	as
	(
		select
			Тип = 'Комиссии'
			,dt =  [Комиссия "Срочное снятие с залога": дата оплаты день]
			,Прибыль = sum(isnull([Комиссия "Срочное снятие с залога": cумма услуги],0))
		from  Analytics.dbo.v_comissions
		where [Комиссия "Срочное снятие с залога": cумма услуги] is not null
		 and [Комиссия "Срочное снятие с залога": дата оплаты день] 
			between @startDate and @endDate
		group by  [Комиссия "Срочное снятие с залога": дата оплаты день]
		 union all
		select
			Тип = 'Комиссии'
			,dt= [Комиссия "СМС информирование": дата оплаты день]
			,Прибыль = sum(isnull([Комиссия "СМС информирование": cумма услуги],0))
		from Analytics.dbo.v_comissions
		where [Комиссия "СМС информирование": cумма услуги] is not null
			and [Комиссия "СМС информирование": дата оплаты день] between @startDate and @endDate

		group by [Комиссия "СМС информирование": дата оплаты день]
	), cte_partner_bounty as 
	(
		select
			Тип = 'КП'
			,dt =  ДатаВыдачи
			,Прибыль = sum(isnull([СуммаДопУслуг_without_partner_bounty_net],0))
		from dbo.dm_sales
		where ishistory=0
		and ДатаВыдачи between @startDate and @endDate
		group by ДатаВыдачи
	)
	
	insert into webReport.dm_finance_incoming_by_month_stage(
		Тип,
		dt,
		Прибыль
		
	)
	select  
		Тип,
		dt ,
		Прибыль = sum(Прибыль)

	from 
	(
		select Тип,
			dt ,
			Прибыль 
		from cte_repayments
		union all
		select 
			Тип,
			dt ,
			Прибыль
		from cte_comissions
		union all
		select 
			Тип,
			dt ,
			Прибыль
		from cte_partner_bounty

	) t
	group by Тип, dt

	if exists(select top(1) 1 from webReport.dm_finance_incoming_by_month_stage)
	begin
		begin tran
			truncate table webReport.dm_finance_incoming_by_month

			alter table webReport.dm_finance_incoming_by_month_stage
				SWITCH to webReport.dm_finance_incoming_by_month

		commit tran
	end
	else
	begin
		;throw 51000, 'В dm_finance_incoming_by_month_stage не данных', 16
	end



end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
