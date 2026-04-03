-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-04-10
-- Description:	 Четвертая часть. Пишем из витрины сохраненого баланса в витрину дашбоарда
--             exec [dbo].[ReportDashboard_Collection_v02_part4_new_balance]   --1
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_v02_part4_new_balance
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- part 5 new cash
--26.06.2020
delete from [dbo].[stage_dashboard_Collection_v02_new_save_balance] 
insert into [dbo].[stage_dashboard_Collection_v02_new_save_balance] 
select * from [dbo].[stage_dashboard_Collection_v02_new_cash] 

-- part 4


-------------================================= Факт за день =================================-----------------
--- выводим данные по балансу, который восстановлен на текущий день по бакету--- 
--  для баланса учитываем сведения на вчерашний день, по договорам, которые на текущий день были с утра в просрочке
-- по 91+ и 361+ выводим кэш t1_4_4_rr_to_day  [t1_5_4_rr_to_day]- рассчитанные выше / необходимо переписать на кэш переменную
-------------==============================================================================================-----------------

-- 28/04/2020 добавим приведенный баланс

drop table if exists #fact_day;

with fact_day as
(
	--select  isnull((Sum(cb.ОД)),0)   as Principal_rest_sum, [Корзина Просрочки]
	select  isnull((Sum(cb.СохрБалансПриведен)),0)   as Principal_rest_sum, BucketFirst as [Корзина Просрочки]
	FROM [dwh2].[dbo].[dm_BucketMigration] cb  
	where cast(cb.[Дата] as date)=cast(getdate() as date)
	group by BucketFirst
)

select * 
into #fact_day
from fact_day


update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(1)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(2)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(3)_61_90'  ) where id = 1;

update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_3_fact_to_day_percent] = [t1_1_2_fact_to_day]/[t1_1_1_plan_to_day] where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_3_fact_to_day_percent] = [t1_2_2_fact_to_day]/[t1_2_1_plan_to_day] where id = 1
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_3_fact_to_day_percent] = [t1_3_2_fact_to_day]/[t1_3_1_plan_to_day] where id = 1




-------------================================= Факт за месяц по текущий день =================================-----------------
--- выводим данные по балансу, который восстановлен на текущий день по бакету--- 
--  для баланса учитываем сведения на вчерашний день, по договорам, которые на текущий день были с утра в просрочке
-- по 91+ и 361+ выводим кэш рассчитанные выше / необходимо переписать на кэш переменную
-------------==============================================================================================-----------------

drop table if exists #fact_month;

with fact_month as
(
	--select  isnull((Sum(cb.ОД)),0)   as Principal_rest_sum, [Корзина Просрочки]
	select  isnull((Sum(cb.СохрБалансПриведен)),0)   as Principal_rest_sum, BucketFirst as [Корзина Просрочки]
	FROM [dwh2].[dbo].[dm_BucketMigration] cb  
	where cast(cb.[Дата] as date) between  cast(dateadd(day,1-day(GetDate()),GetDate()) as date) and cast(GetDate() as date)
	group by BucketFirst
)

select * 
into #fact_month
from fact_month

--select *,cast(dateadd(day,1-day(GetDate()),GetDate()) as date) , cast(GetDate() as date) from #fact_month

update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(1)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(2)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(3)_61_90'  ) where id = 1;

--update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_1_8_fact_rr_to_end_of_month_percent] = [t1_1_7_fact_rr_to_end_of_month]/[t1_1_6_plan_current_date_from_start_month] where id = 1
--update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_2_8_fact_rr_to_end_of_month_percent] = [t1_2_7_fact_rr_to_end_of_month]/[t1_2_6_plan_current_date_from_start_month] where id = 1
--update [dbo].[stage_dashboard_Collection_v02_new_save_balance] SET  [t1_3_8_fact_rr_to_end_of_month_percent] = [t1_3_7_fact_rr_to_end_of_month]/[t1_3_6_plan_current_date_from_start_month] where id = 1




END
