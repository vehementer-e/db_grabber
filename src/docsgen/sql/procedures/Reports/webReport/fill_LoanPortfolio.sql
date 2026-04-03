--/DWH-2377
CREATE   procedure [webReport].[fill_LoanPortfolio]
as
begin
begin try
	declare @today date = getdate()
		
	declare @prev_year_date date = DATEFROMPARTS ( year(@today) - 1, 12, 31 )
		,@prev_month_date date = EOMONTH (@today,-1)
		,@last_OtchetnayaData date = (select max(ОтчетнаяДата) from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных)
	drop table if exists #tResult
	select
		* 
	into #tResult
	from 
		(	select  
				Период = 'Прошлый год'
				,ДатаОтчета = ОтчетнаяДата
				,[Портфель ОД]  =  cast(SUM(ОстатокОДвсего) as money)
				,[Портфель %%] = cast(SUM(ОстатокПроцентовВсего) as money) 
			from 
				stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
			where 
				ОтчетнаяДата = @prev_year_date
			group by 
				ОтчетнаяДата
			
			union all
			
			select 
				Период = 'Прошлый месяц'
				,ДатаОтчета = ОтчетнаяДата
				,[Портфель ОД] = cast(SUM(ОстатокОДвсего) as money)
				,[Портфель %%] = cast(SUM(ОстатокПроцентовВсего) as money)
			from 
				stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
			where 
				ОтчетнаяДата = @prev_month_date
			group by 
				ОтчетнаяДата
			
			union all
		
			select  
				Период = 'Последняя дата'
				,ДатаОтчета = ОтчетнаяДата
				,[Портфель ОД]  =  cast(SUM(ОстатокОДвсего) as money)
				,[Портфель %%] = cast(SUM(ОстатокПроцентовВсего) as money) 
			from 
				stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
			where 
				ОтчетнаяДата = @last_OtchetnayaData
			group by 
				ОтчетнаяДата
		)t 
	
	if object_id('webReport.LoanPortfolio') is null
	begin
		select top(0)
			[Период]
			,[ДатаОтчета]
			,[Портфель ОД]	
			,[Портфель %%]
		into webReport.LoanPortfolio
		from 
			#tResult
	end

	if (
	select DATEDIFF(dd, ДатаОтчета, @today)  from #tResult
	where Период = 'Последняя дата')  >3
	begin
		;throw 51000, 'Данные в РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных не актуальные', 16
	end

	if exists (select top(1)1 from #tResult)
	begin
		begin tran
			merge webReport.LoanPortfolio t
			using #tResult s
				on s.[Период] = t.[Период]
			when matched then update
				set [ДатаОтчета]	= isnull(s.[ДатаОтчета]	, t.[ДатаОтчета])
					,[Портфель ОД]	= isnull(s.[Портфель ОД], t.[Портфель ОД])
					,[Портфель %%]	= isnull(s.[Портфель %%], t.[Портфель %%])
			when not matched then insert
				(
					[Период]
					,[ДатаОтчета]
					,[Портфель ОД]	
					,[Портфель %%]
				)
				values
				(
					[Период]
					,[ДатаОтчета]
					,[Портфель ОД]	
					,[Портфель %%]
				);
		commit tran
	end
	else
	begin
		;throw 51000, 'Не удалось собрать данные', 16
	end
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end