

-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2021-12-09
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_Installment_v02]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_Installment_v02]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	--begin
	--delete from [dbo].[dm_dashboard_Collection_Installment_v02]
	--insert into [dbo].[dm_dashboard_Collection_Installment_v02] ([ДатаОбновления] , id) select GETDATE() as [ДатаОбновления], 1 as id
	--end

	
		---------------------------------------------------------------------------------
		-- только удаление данных и обновление даты обновления -- скрипт от рисковиков временно заменен на свой расчет
		---------------------------------------------------------------------------------
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part1] 

		---------------------------------------------------------------------------------
		-- загрузка плановых показателей за день, месяц
		---------------------------------------------------------------------------------
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part2] 


		---------------------------------------------------------------------------------
		-- расчет сохраненного баланса
		---------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------
		--- третий запрос для расчета текущего дня с учетом ОД на первую дату входа в просрочку(стадию) в прошлом месяце
		--- версия от 20.01.2020
		--------------------------------------------------------------------------------------------------------------------------


		-- дату месяца можно указать для целей расчета за прошлый месяц
		declare  @dt_today_away_old date = cast(dateadd(month,-1, dateadd(year,2000,getdate())) as date)

		declare @hour_morning int = 23
		Set @hour_morning  = datepart(hour, getdate())
		
		--select @hour_morning

		--за вчера считаем только утром
		--if @hour_morning = 7 
		begin
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part3]  @dt_today_away_old
		end

		 ---------------------------------------------------------------------------------------------------------------------------
		--- третий запрос для расчета текущего дня с учетом ОД на первую дату входа в просрочку(стадию) в месяце
		--- версия от 20.01.2020
		-----------------------------------------------------------------------------------------------------------------------------

		-- 
		declare  @dt_today_away date = cast(dateadd(day,0, dateadd(year,2000,getdate())) as date)
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part3]  @dt_today_away

		---------------------------------------------------------------------------------
		-- Четвертая часть. Пишем из витрины сохраненого баланса в витрину дашбоарда
		---------------------------------------------------------------------------------
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part4] 

				---------------------------------------------------------------------------------
		-- CASH для таблица 2 и для 90-360 и 361+
		---------------------------------------------------------------------------------
		--старый вариант кэш не считаем
		--exec [dbo].[ReportDashboard_Collection_v02_part5] 

		-- считаем новый
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part5_new_cash] 
		-- добавили таблицу 3 за месяц
		--exec [dbo].[ReportDashboard_Collection_v02_part5a]

		--старый вариант кэш не считаем
		--exec [dbo].[ReportDashboard_Collection_v02_part5b]
		-- считаем новый
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part5b_new_cash]


		--- новый алгоритм расчета сохраненного баланса 26.06.2020
		-- предварительно заполняем данные и копируем из нового кэша
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part4_new_balance] 

		---------------------------------------------------------------------------------
		-- расчет RR  
		---------------------------------------------------------------------------------
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part6] 
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part6_new_cash] 
		exec [dbo].[ReportDashboard_Collection_Installment_v02_part6_new_saved_balance]
/*

		*/
		-- запишем что обновили данные, чтобы не пересчитывать утренную загрузку
		update [dbo].[dm_dashboard_Collection_Installment_v02] SET [ДатаОбновления] =  GETDATE() where id = 1 
		update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] SET [ДатаОбновления] =  GETDATE() where id = 1 
		update [dbo].[dm_dashboard_Collection_Installment_v02_new_save_balance] SET [ДатаОбновления] =  GETDATE() where id = 1 

END
