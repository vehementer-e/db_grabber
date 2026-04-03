




CREATE PROCEDURE [finAnalytics].[repCheckNew_ACCandEntries]
	@repmonth date
	,@selector int
with recompile	

AS
BEGIN
		--1
		declare @monthStartTmp date=@repmonth
		declare @monthStart date=dateadd(year,2000,@monthStartTmp )
		declare @monthEnd date = eomonth(@monthStart)
		--2
		declare @repmonthStartTmp date = dateadd(year,2000,@repmonth)
		declare @repmonthEndTmp date = eomonth(dateadd(year,2000,@repmonth))

 if @selector = 1 --выборка новых счетов
	begin
		select 
		[Код] = Код
		,[Наименование] = Наименование
		,[Дата открытия] =cast(dateadd(year,-2000,ДатаОткрытия) as date)
		from 
		(
		select 
			Код
			,Наименование
			,ДатаОткрытия
		from stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета
		where cast(ДатаОткрытия as date) between @monthStart and @monthEnd
			and SUBSTRING(Код,1,1)='7'
		) l1
	end
 if @selector = 2 --выборка новых коореспонденций
	begin
		select
		[ДТ]
		,[КТ]
		,[Дата]
		,[НомерМемориальногоОрдера]
		,[Содержание]
		,[ТипПроверки]
		from
			dwh2.finAnalytics.spr_DTKT	
		where
			repmonth = @repmonth
	end
END
