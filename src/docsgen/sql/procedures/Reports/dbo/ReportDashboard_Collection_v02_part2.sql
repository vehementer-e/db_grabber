-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-04-10
-- Description:	 Вторая часть. Загрузка планов
--             exec [dbo].[ReportDashboard_Collection_v02_part2]   --1
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_v02_part2
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- part 2


drop table if exists #plan_day;

with plan_day as
(
	select  isnull(([Сумма план]),0)*1000000   as plan_sum, Бакет
	FROM [Stg].[files].[CollectionPlan_buffer]   
	where cast([Дата] as date) = cast(dateadd(day, 0,GetDate()) as date)
)

select * 
into #plan_day
from plan_day

begin

------------------- Таблица 1 Планы ---------------------------------------------
-------------------------------------------------------------------------------
-- планы за сегодня  (обновим показатели)
---------------------------------------------------------------------------------
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_1_1_plan_to_day] = (select plan_sum from #plan_day where Бакет='(2)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_2_1_plan_to_day] = (select plan_sum from #plan_day where Бакет='(3)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_3_1_plan_to_day] = (select plan_sum from #plan_day where Бакет='(4)_61_90'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_4_1_plan_to_day] = (select plan_sum from #plan_day where Бакет='(5)_91_360'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_5_1_plan_to_day] = (select plan_sum from #plan_day where Бакет='(6)_361+' ) where id = 1;

-------------------------------------------------------------------------------
--  планы на сегодня для RR
-------------------------------------------------------------------------------

update [dbo].[stage_dashboard_Collection_v02] SET  [t1_1_9_plan_current_day] = (select plan_sum from #plan_day where Бакет='(2)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_2_9_plan_current_day] = (select plan_sum from #plan_day where Бакет='(3)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_3_9_plan_current_day] = (select plan_sum from #plan_day where Бакет='(4)_61_90'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_4_9_plan_current_day] = (select plan_sum from #plan_day where Бакет='(5)_91_360'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_5_9_plan_current_day] = (select plan_sum from #plan_day where Бакет='(6)_361+' ) where id = 1;

--select * from [dbo].[stage_dashboard_Collection_v02]
end


--- 16.04.2020 Теперь уже не используется, так как не выводим данные по плану до текущего дня. Просто считаем RR
-----------------------------------------------------------------
----посчитаем план на месяц включая текущий день ----- 13.04.2020
-- поправить после загрузки данных
drop table if exists #plan_month;

with plan_month as
(
	select  isnull((Sum([Сумма план])),0)*1000000   as plan_sum, Бакет
	FROM [Stg].[files].[CollectionPlan_buffer]   
	where cast([Дата] as date)  between  cast(dateadd(day,1-day(GetDate()),GetDate()) as date) and cast(GetDate() as date)
	group by Бакет
)

select * 
into #plan_month
from plan_month

--select *,cast(dateadd(day,1-day(GetDate()),GetDate()) as date) , cast(GetDate() as date) from #plan_month

begin

update [dbo].[stage_dashboard_Collection_v02] SET  [t1_1_6_plan_current_date_from_start_month] = (select sum(plan_sum) from #plan_month where Бакет='(2)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_2_6_plan_current_date_from_start_month] = (select sum(plan_sum) from #plan_month where Бакет='(3)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_3_6_plan_current_date_from_start_month] = (select sum(plan_sum) from #plan_month where Бакет='(4)_61_90'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_4_6_plan_current_date_from_start_month] = (select sum(plan_sum) from #plan_month where Бакет='(5)_91_360'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_5_6_plan_current_date_from_start_month] = (select sum(plan_sum) from #plan_month where Бакет='(6)_361+'  ) where id = 1;


end


--- 
-----------------------------------------------------------------
----посчитаем план на месяц ----- 13.04.2020
-- поправить после загрузки данных

declare  @dt_today_away date = cast(dateadd(day,0, dateadd(year,0,getdate())) as date)
declare  @dt_begin_of_month date = cast(format(@dt_today_away,'yyyyMM01') as date)
declare  @dt_next_month date = cast(dateadd(month,1, @dt_begin_of_month) as date)

drop table if exists #plan_month_all;

with plan_month_all as
(
	select  isnull((Sum([Сумма план])),0)*1000000   as plan_sum, Бакет
	FROM [Stg].[files].[CollectionPlan_buffer]   
	where cast([Дата] as date)>= @dt_begin_of_month and cast([Дата] as date)<@dt_next_month
	group by Бакет
)

select * 
into #plan_month_all
from plan_month_all

--select @dt_begin_of_month, @dt_next_month

--select *, @dt_begin_of_month, @dt_next_month from #plan_month_all

begin

update [dbo].[stage_dashboard_Collection_v02] SET  [t1_1_10_plan_current_month] = (select sum(plan_sum) from #plan_month_all where Бакет='(2)_1_30'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_2_10_plan_current_month] = (select sum(plan_sum) from #plan_month_all where Бакет='(3)_31_60'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_3_10_plan_current_month] = (select sum(plan_sum) from #plan_month_all where Бакет='(4)_61_90'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_4_10_plan_current_month] = (select sum(plan_sum) from #plan_month_all where Бакет='(5)_91_360'  ) where id = 1;
update [dbo].[stage_dashboard_Collection_v02] SET  [t1_5_10_plan_current_month] = (select sum(plan_sum) from #plan_month_all where Бакет='(6)_361+'  ) where id = 1;



end



END
