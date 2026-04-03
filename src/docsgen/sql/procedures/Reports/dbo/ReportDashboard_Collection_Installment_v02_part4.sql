


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2021-12-09
-- Description:	 Четвертая часть. Пишем из витрины сохраненого баланса в витрину дашбоарда
--             exec [dbo].[ReportDashboard_Collection_Installment_v02_part4]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_Installment_v02_part4]
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


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
	select  isnull((Sum(cb.СохрБалансПриведен)),0)   as Principal_rest_sum, [Корзина Просрочки]
	FROM [dbo].[dm_CollectionSavedBalance_Installment] cb  
	where cast(cb.[Дата выхода из стадии] as date)=cast(getdate() as date)
	group by [Корзина Просрочки]
)

select * 
into #fact_day
from fact_day


update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_1_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(1)_1_30'  ) where id = 1;
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_2_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(2)_31_60'  ) where id = 1;
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_3_2_fact_to_day] = (select sum(Principal_rest_sum) from #fact_day where [Корзина Просрочки]='(3)_61_90'  ) where id = 1;

update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_1_3_fact_to_day_percent] = [t1_1_2_fact_to_day]/[t1_1_1_plan_to_day] where id = 1
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_2_3_fact_to_day_percent] = [t1_2_2_fact_to_day]/[t1_2_1_plan_to_day] where id = 1
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_3_3_fact_to_day_percent] = [t1_3_2_fact_to_day]/[t1_3_1_plan_to_day] where id = 1




-------------================================= Факт за месяц по текущий день =================================-----------------
--- выводим данные по балансу, который восстановлен на текущий день по бакету--- 
--  для баланса учитываем сведения на вчерашний день, по договорам, которые на текущий день были с утра в просрочке
-- по 91+ и 361+ выводим кэш рассчитанные выше / необходимо переписать на кэш переменную
-------------==============================================================================================-----------------

drop table if exists #fact_month;

with fact_month as
(
	--select  isnull((Sum(cb.ОД)),0)   as Principal_rest_sum, [Корзина Просрочки]
	select  isnull((Sum(cb.СохрБалансПриведен)),0)   as Principal_rest_sum, [Корзина Просрочки]
	FROM [dbo].[dm_CollectionSavedBalance_Installment] cb  
	where cast(cb.[Дата выхода из стадии] as date) between  cast(dateadd(day,1-day(GetDate()),GetDate()) as date) and cast(GetDate() as date)
	group by [Корзина Просрочки]
)

select * 
into #fact_month
from fact_month


update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_1_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(1)_1_30'  ) where id = 1;
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_2_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(2)_31_60'  ) where id = 1;
update [dbo].[dm_dashboard_Collection_Installment_v02] SET  [t1_3_7_fact_rr_to_end_of_month] = (select sum(Principal_rest_sum) from #fact_month where [Корзина Просрочки]='(3)_61_90'  ) where id = 1;



END
