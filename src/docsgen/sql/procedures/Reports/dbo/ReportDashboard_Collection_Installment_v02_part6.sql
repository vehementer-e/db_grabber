


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-04-10
-- Description:	 Шестая часть. Расчеты RR по часам дня и по дням месяца
--             exec [dbo].[ReportDashboard_Collection_Installment_v02_part6]   --1
-- =============================================
CREATE PROCEDURE [dbo].[ReportDashboard_Collection_Installment_v02_part6]
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--- ===== расчет коэфициентов по часам =============---------------
	declare @to_previous_week date
	set @to_previous_week = getdate()
	--select @to_previous_week, dateadd(week,-1, @to_previous_week), dateadd(week,-2, @to_previous_week), dateadd(week,-3, @to_previous_week), dateadd(week,-4, @to_previous_week)

	drop table if exists #t
	select sum(ОД)                   сохбаланс
	,      datepart(hour,ДатаОплаты) Час
		into #t
	from dbo.dm_CollectionSavedBalance_Installment
	where [Дата выхода из стадии] in (dateadd(week,-1, @to_previous_week), dateadd(week,-2, @to_previous_week), dateadd(week,-3, @to_previous_week), dateadd(week,-4, @to_previous_week))
	group by datepart(hour,ДатаОплаты)
	--, [Корзина Просрочки][Корзина Просрочки],

	--получим часы
	drop table if exists #t_hour
	SELECT TOP (24) number_hour = (-1+ROW_NUMBER() OVER (ORDER BY (select 1)))
		into #t_hour
	FROM dbo.dm_CollectionSavedBalance_Installment
	

	--получим весы
	drop table if exists #t_weight
	select h.number_hour                                                             
	,      isnull(сохбаланс,0)                                                        Сумма
	,      sum_all = sum(isnull(сохбаланс,0)) over(partition by null)                
	,      вес = isnull(сохбаланс,0)/sum(nullif(сохбаланс,0)) over(partition by null)
		into #t_weight
	from      #t_hour h
	left join #t      t on t.Час = h.number_hour

	-- посчитаем количество весов до текущего часа включительно
	declare @current_hour int
	select @current_hour = datepart(hour, GetDate())

	--select Sum(вес) from #t_weight where number_hour <= @current_hour
	--- ===== Конец расчета коэфициентов по часам =============---------------

	-- для расчета процентов найдем текущий час из расчета 24 часа.

	Declare @current_minute float
	,       @ratio          float
	--Set @current_hour = isnull(
	--select @current_hour = datepart(hour, GetDAte())
	--select @current_minute = datediff(minute, cast(GetDate() as date), GetDate())
	--select @current_minute
	--Set @ratio = 1 +  (24*60-@current_minute)/(@current_minute)

	--select @ratio = 1+(1-Sum(вес)) from #t_weight where number_hour <= @current_hour

	select @ratio = 1/Sum(nullif(вес,0))
	from #t_weight
	where number_hour <= @current_hour

	--select @ratio, @current_hour --  @current_minute,  (24*60-@current_minute)/60,  (24*60-@current_minute)/(@current_minute)
	-- посчитаем RR
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_1_4_rr_to_day] = [t1_1_2_fact_to_day]*(@ratio)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_2_4_rr_to_day] = [t1_2_2_fact_to_day]*(@ratio)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_3_4_rr_to_day] = [t1_3_2_fact_to_day]*(@ratio)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_4_4_rr_to_day] = [t1_4_2_fact_to_day]*(@ratio)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_5_4_rr_to_day] = [t1_5_2_fact_to_day]*(@ratio)
	where id = 1
	--select * from [dbo].[dm_dashboard_Collection_Installment_v02]


	-- посчитаем проценты RR
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_1_5_rr_to_day_percent] = [t1_1_4_rr_to_day]/[t1_1_1_plan_to_day]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_2_5_rr_to_day_percent] = [t1_2_4_rr_to_day]/[t1_2_1_plan_to_day]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_3_5_rr_to_day_percent] = [t1_3_4_rr_to_day]/[t1_3_1_plan_to_day]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_4_5_rr_to_day_percent] = [t1_4_4_rr_to_day]/[t1_4_1_plan_to_day]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_5_5_rr_to_day_percent] = [t1_5_4_rr_to_day]/[t1_5_1_plan_to_day]
	where id = 1
	--select * from [dbo].[dm_dashboard_Collection_Installment_v02]



	-- для расчета процентов найдем текущий день из расчета числа дней месяца.
	Declare @current_day float
	,       @ratio_day   float
	,       @last_day    float

	select @current_day = datepart(day, GetDate()) -- datediff(minute, cast(GetDate() as date), GetDate())

	select @last_day = datepart(day, eomonth(GetDate()))
	Set @ratio_day = 1 + (@last_day-@current_day)/(@current_day)
	--select @current_day, @ratio_day,  (31-@current_day),  (@last_day-@current_day)/(@current_day)
	-- посчитаем RR
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_1_11_rr_month] = [t1_1_7_fact_rr_to_end_of_month]*(@ratio_day)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_2_11_rr_month] = [t1_2_7_fact_rr_to_end_of_month]*(@ratio_day)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_3_11_rr_month] = [t1_3_7_fact_rr_to_end_of_month]*(@ratio_day)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_4_11_rr_month] = [t1_4_7_fact_rr_to_end_of_month]*(@ratio_day)
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_5_11_rr_month] = [t1_5_7_fact_rr_to_end_of_month]*(@ratio_day)
	where id = 1
	--select * from [dbo].[dm_dashboard_Collection_Installment_v02]


	-- посчитаем проценты RR
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_1_12_rr_month_percent] = [t1_1_11_rr_month]/[t1_1_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_2_12_rr_month_percent] = [t1_2_11_rr_month]/[t1_2_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_3_12_rr_month_percent] = [t1_3_11_rr_month]/[t1_3_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_4_12_rr_month_percent] = [t1_4_11_rr_month]/[t1_4_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_5_12_rr_month_percent] = [t1_5_11_rr_month]/[t1_5_10_plan_current_month]
	where id = 1
	--select * from [dbo].[dm_dashboard_Collection_Installment_v02]


	-- посчитаем проценты
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_1_8_fact_rr_to_end_of_month_percent] = [t1_1_7_fact_rr_to_end_of_month]/[t1_1_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_2_8_fact_rr_to_end_of_month_percent] = [t1_2_7_fact_rr_to_end_of_month]/[t1_2_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_3_8_fact_rr_to_end_of_month_percent] = [t1_3_7_fact_rr_to_end_of_month]/[t1_3_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_4_8_fact_rr_to_end_of_month_percent] = [t1_4_7_fact_rr_to_end_of_month]/[t1_4_10_plan_current_month]
	where id = 1
	update [dbo].[dm_dashboard_Collection_Installment_v02]
	SET [t1_5_8_fact_rr_to_end_of_month_percent] = [t1_5_7_fact_rr_to_end_of_month]/[t1_5_10_plan_current_month]
	where id = 1
--select * from [dbo].[dm_dashboard_Collection_Installment_v02]



END
