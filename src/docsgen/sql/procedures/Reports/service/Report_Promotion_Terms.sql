/*
exec service.Report_Promotion_Terms
	@dt_report = null,
	@dt_close = null,
	@isDebug = 1 

--Отчет по выполнению условий акции
*/
create   PROC service.Report_Promotion_Terms
	--отчетная дата	дата, на которую строится отчет. В отчет должны попасть все договоры, действующие на эту дату
	@dt_report date = null,
	--дата закрытия	закрытые договоры, которые были закрыты за период с "дата закрытия" по "отчетная дата" включительно
	@dt_close date = null,
	@isDebug int = 0 
as
begin

	SELECT @isDebug = isnull(@isDebug, 0)
	--Отчетная дата - дата, на которую строится отчет. В отчет должны попасть все договоры, действующие на эту дату
	select @dt_report = isnull(@dt_report, cast(getdate() as date))
	--Дата закрытия	- закрытые договоры, которые были закрыты за период с "дата закрытия" по "отчетная дата" включительно
	select @dt_close = isnull(@dt_close, cast(getdate() as date))


	select *
	from service.dm_Promotion_Terms as t
	where 1=1
		and (
			(
				t.[Дата выдачи] <= @dt_report 
				and @dt_report < isnull(t.[Факт. дата закрытия], '2100-01-01')
			)
			or 
			(
				@dt_close <= isnull(t.[Факт. дата закрытия], '2100-01-01') 
				and isnull(t.[Факт. дата закрытия], '2100-01-01') <= @dt_report
			)
		)
	--and t.[Статус договора]
	
end