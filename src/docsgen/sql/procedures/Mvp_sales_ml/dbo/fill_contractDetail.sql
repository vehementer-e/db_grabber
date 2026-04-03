CREATE procedure [dbo].[fill_contractDetail]
	@monthAgo smallint = 3
	,@dayAfter smallint = 0
as
begin
begin try 
	declare @validStatus binary(16) = (select top(1) Ссылка from stg._1cCMR.Справочник_СтатусыДоговоров
	where Наименование  ='Действует')


	select [leadId]
		,lastContractDate	= max(ДатаДоговораЗайма)
		,totalValidContract = count(distinct дз.КодДоговораЗайма) --Кол. выданных займов
	into #contractDetail
	from [dbo].[dm_lead_ml] l
	inner join dwh2.sat.Клиент_Телефон кт  on кт.НомерТелефонаБезКодов = l.leadPhone
	inner join dwh2.link.v_Клиент_ДоговорЗайма Клиент_ДоговорЗайма on 
		Клиент_ДоговорЗайма.GuidКлиент = кт.GuidКлиент
		inner join dwh2.hub.ДоговорЗайма дз on дз.КодДоговораЗайма = Клиент_ДоговорЗайма.КодДоговораЗайма
		and exists(Select top(1) 1
			from stg._1cCMR.РегистрСведений_СтатусыДоговоров сд where сд.Договор = дз.СсылкаДоговораЗайма
			and сд.Статус = @validStatus)
		and дз.ДатаДоговораЗайма between 
			DATEADD(mm,-@monthAgo, l.leadCreated_at_time) and dateadd(dd,@dayAfter, l.leadCreated_at_time)
	group by [leadId]
	option (recompile)
	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastContractDate') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastContractDate datetime
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalValidContract') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalValidContract int
	END

	begin tran
		update t
			set lastContractDate = cd.lastContractDate
				,totalValidContract = cd.totalValidContract
		from [dbo].[dm_lead_ml]  t
		left join #contractDetail cd on cd.leadId = t.leadId
	commit tran
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end



