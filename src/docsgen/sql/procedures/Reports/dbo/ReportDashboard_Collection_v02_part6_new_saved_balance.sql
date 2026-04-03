-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-05-22
-- Description:	 Шестая часть. Расчеты RR по часам дня и по дням месяца
--             exec [dbo].[ReportDashboard_Collection_v02_part6_new_saved_balance]  --1
-- =============================================
CREATE PROC [dbo].[ReportDashboard_Collection_v02_part6_new_saved_balance]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
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
select sum([остаток од]) сохбаланс, datepart(hour,ДатаВремяПоследнегоПлатежа) Час
into #t
from [dwh2].[dbo].[dm_BucketMigration]
where [Дата] in (dateadd(week,-1, @to_previous_week), dateadd(week,-2, @to_previous_week), dateadd(week,-3, @to_previous_week), dateadd(week,-4, @to_previous_week))
group by   datepart(hour,ДатаВремяПоследнегоПлатежа)
--, [Корзина Просрочки][Корзина Просрочки],

--получим часы 
drop table if exists #t_hour
SELECT TOP (24)
  number_hour = (-1+ROW_NUMBER() OVER (ORDER BY (select 1)))
into  #t_hour
FROM [dwh2].[dbo].[dm_BucketMigration]

--получим весы
drop table if exists #t_weight
select 
    h.number_hour,
    isnull(сохбаланс, 0) as сумма,
    sum_all = sum(isnull(сохбаланс, 0)) over (partition by null),
    вес = case 
            when sum(isnull(сохбаланс, 0)) over (partition by null) = 0 then 0
            else isnull(сохбаланс, 0) / sum(isnull(сохбаланс, 0)) over (partition by null)
          end
into #t_weight
from #t_hour h
left join #t t on t.час = h.number_hour;

--select h.number_hour, isnull(сохбаланс,0) Сумма, sum_all = sum(isnull(сохбаланс,0)) over(partition by null), вес = isnull(сохбаланс,0)/sum(isnull(сохбаланс,0)) over(partition by null)  
--into #t_weight
--from  #t_hour h
--left join #t t on t.Час = h.number_hour

-- посчитаем количество весов до текущего часа включительно
declare @current_hour int
select @current_hour = datepart(hour, GetDate())

--select Sum(вес) from #t_weight where number_hour <= @current_hour
--- ===== Конец расчета коэфициентов по часам =============---------------

-- для расчета процентов найдем текущий час из расчета 24 часа.

Declare @current_minute float,
		@ratio float
--Set @current_hour = isnull(
--select @current_hour = datepart(hour, GetDAte())
--select @current_minute = datediff(minute, cast(GetDate() as date), GetDate())
--select @current_minute
--Set @ratio = 1 +  (24*60-@current_minute)/(@current_minute)

--select @ratio = 1+(1-Sum(вес)) from #t_weight where number_hour <= @current_hour
select @ratio = case
					when Sum(вес) = 0 then 0
					else 1/Sum(вес) 
				end
from #t_weight where number_hour <= @current_hour
--select @ratio = 1/Sum(вес) from #t_weight where number_hour <= @current_hour

--select @ratio, @current_hour --  @current_minute,  (24*60-@current_minute)/60,  (24*60-@current_minute)/(@current_minute)
-- посчитаем RR
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_4_rr_to_day] = [t1_1_2_fact_to_day]*(@ratio) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_4_rr_to_day] = [t1_2_2_fact_to_day]*(@ratio) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_4_rr_to_day] = [t1_3_2_fact_to_day]*(@ratio)  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_4_4_rr_to_day] = [t1_4_2_fact_to_day]*(@ratio)  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_5_4_rr_to_day] = [t1_5_2_fact_to_day]*(@ratio)  where id = 1
--select * from [dbo].[stage_dashboard_Collection_v02_new_save_balance]


-- посчитаем проценты RR
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_5_rr_to_day_percent] =case when isnull([t1_1_1_plan_to_day],0)<>0 then  [t1_1_4_rr_to_day]/[t1_1_1_plan_to_day] else 0 end  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_5_rr_to_day_percent] =case when isnull([t1_2_1_plan_to_day],0)<>0 then  [t1_2_4_rr_to_day]/[t1_2_1_plan_to_day] else 0 end  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_5_rr_to_day_percent] =case when isnull([t1_3_1_plan_to_day],0)<>0 then  [t1_3_4_rr_to_day]/[t1_3_1_plan_to_day] else 0 end  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_4_5_rr_to_day_percent] =case when isnull([t1_4_1_plan_to_day],0)<>0 then  [t1_4_4_rr_to_day]/[t1_4_1_plan_to_day] else 0 end  where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_5_5_rr_to_day_percent] =case when isnull([t1_5_1_plan_to_day],0)<>0 then  [t1_5_4_rr_to_day]/[t1_5_1_plan_to_day] else 0 end  where id = 1
--select * from [dbo].[stage_dashboard_Collection_v02_new_save_balance]



-- для расчета процентов найдем текущий день из расчета числа дней месяца.
Declare @current_day float,
		@ratio_day float,
		@last_day float

select @current_day = datepart(day, GetDate()) -- datediff(minute, cast(GetDate() as date), GetDate())

select @last_day = datepart(day, eomonth(GetDate()))
Set @ratio_day = 1 +  (@last_day-@current_day)/(@current_day)
--select @current_day, @ratio_day,  (31-@current_day),  (@last_day-@current_day)/(@current_day)
-- посчитаем RR
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_11_rr_month] = [t1_1_7_fact_rr_to_end_of_month]*(@ratio_day) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_11_rr_month] = [t1_2_7_fact_rr_to_end_of_month]*(@ratio_day) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_11_rr_month] = [t1_3_7_fact_rr_to_end_of_month]*(@ratio_day) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_4_11_rr_month] = [t1_4_7_fact_rr_to_end_of_month]*(@ratio_day) where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_5_11_rr_month] = [t1_5_7_fact_rr_to_end_of_month]*(@ratio_day) where id = 1
--select * from [dbo].[stage_dashboard_Collection_v02_new_save_balance]


-- посчитаем проценты RR
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_12_rr_month_percent] = case when isnull([t1_1_10_plan_current_month],0)<>0 then [t1_1_11_rr_month]/[t1_1_10_plan_current_month]  else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_12_rr_month_percent] = case when isnull([t1_2_10_plan_current_month],0)<>0 then [t1_2_11_rr_month]/[t1_2_10_plan_current_month]  else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_12_rr_month_percent] = case when isnull([t1_3_10_plan_current_month],0)<>0 then [t1_3_11_rr_month]/[t1_3_10_plan_current_month]  else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_4_12_rr_month_percent] = case when isnull([t1_4_10_plan_current_month],0)<>0 then [t1_4_11_rr_month]/[t1_4_10_plan_current_month]  else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_5_12_rr_month_percent] = case when isnull([t1_5_10_plan_current_month],0)<>0 then [t1_5_11_rr_month]/[t1_5_10_plan_current_month]  else 0 end where id = 1
--select * from [dbo].[stage_dashboard_Collection_v02_new_save_balance]


-- посчитаем проценты
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_8_fact_rr_to_end_of_month_percent] =case when isnull([t1_1_10_plan_current_month],0)<>0 then  [t1_1_7_fact_rr_to_end_of_month]/[t1_1_10_plan_current_month] else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_8_fact_rr_to_end_of_month_percent] =case when isnull([t1_2_10_plan_current_month],0)<>0 then  [t1_2_7_fact_rr_to_end_of_month]/[t1_2_10_plan_current_month] else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_8_fact_rr_to_end_of_month_percent] =case when isnull([t1_3_10_plan_current_month],0)<>0 then  [t1_3_7_fact_rr_to_end_of_month]/[t1_3_10_plan_current_month] else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_4_8_fact_rr_to_end_of_month_percent] =case when isnull([t1_4_10_plan_current_month],0)<>0 then  [t1_4_7_fact_rr_to_end_of_month]/[t1_4_10_plan_current_month] else 0 end where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_5_8_fact_rr_to_end_of_month_percent] =case when isnull([t1_5_10_plan_current_month],0)<>0 then  [t1_5_7_fact_rr_to_end_of_month]/[t1_5_10_plan_current_month] else 0 end where id = 1
--select * from [dbo].[stage_dashboard_Collection_v02_new_save_balance]



END
