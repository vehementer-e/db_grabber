


create PROCEDURE [finAnalytics].[reportOst_Registr]
	@repmonth date

AS
BEGIN
	--declare @repmonth date='2025-08-31'
    select 
		[Отчетная дата]=dateadd(year,-2000,cast(a.Период as date))
		,Счет=b.Код
		,СуммаНачальныйОстатокДт=sum(a.СуммаНачальныйОстатокДт)
		,СуммаНачальныйОстатокКт=sum(a.СуммаНачальныйОстатокКт)
		,СуммаОборотДт=sum(a.СуммаОборотДт)
		,СуммаОборотКт=sum(a.СуммаОборотКт)
		,СуммаКонечныйОстатокДт=sum(a.СуммаКонечныйОстатокДт)
		,СуммаКонечныйОстатокКт=sum(a.СуммаКонечныйОстатокКт)
	from  Stg._1cUMFO.РегистрСведений_СЗД_ДанныеПоСчетамДляDWH a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетУчета=b.Ссылка
	where eomonth(dateadd(year,-2000,cast(a.Период as date)))=@repmonth
	group by dateadd(year,-2000,cast(a.Период as date)),b.Код
	order by [Отчетная дата],Счет

END
