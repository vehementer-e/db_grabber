-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2019-12-12
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_v02]   --1
-- =============================================
CREATE PROC [dbo].[ReportDashboard_Collection_v02]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

begin try
	--DWH-1919
	--весь расчет происходит в stage-таблицах, в конце расчета происходит запись в основные таблицы

	--DWH-2119
	--print 'truncate dbo.stage_dashboard_Collection_v02'
	TRUNCATE TABLE dbo.stage_dashboard_Collection_v02
	INSERT dbo.stage_dashboard_Collection_v02
	SELECT * FROM dbo.dm_dashboard_Collection_v02

	print 'truncate dbo.stage_dashboard_Collection_v02_new_cash'
	TRUNCATE TABLE dbo.stage_dashboard_Collection_v02_new_cash
	INSERT dbo.stage_dashboard_Collection_v02_new_cash
	SELECT * FROM dbo.dm_dashboard_Collection_v02_new_cash
	print 'truncate dbo.stage_dashboard_Collection_v02_new_save_balance'
	TRUNCATE TABLE dbo.stage_dashboard_Collection_v02_new_save_balance
	INSERT dbo.stage_dashboard_Collection_v02_new_save_balance
	SELECT * FROM dbo.dm_dashboard_Collection_v02_new_save_balance



	--begin
	--delete from [dbo].[dm_dashboard_Collection_v02]
	--insert into [dbo].[dm_dashboard_Collection_v02] ([ДатаОбновления] , id) select GETDATE() as [ДатаОбновления], 1 as id
	--end


		---------------------------------------------------------------------------------
		-- только удаление данных и обновление даты обновления -- скрипт от рисковиков временно заменен на свой расчет
		---------------------------------------------------------------------------------
	print 'run - ReportDashboard_Collection_v02_part1'
	exec [dbo].[ReportDashboard_Collection_v02_part1] 

	---------------------------------------------------------------------------------
	-- загрузка плановых показателей за день, месяц
	---------------------------------------------------------------------------------
	print 'run - ReportDashboard_Collection_v02_part2'
	exec [dbo].[ReportDashboard_Collection_v02_part2] 


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
	if @hour_morning = 7 
	begin
		print 'run - ReportDashboard_Collection_v02_part3 @hour_morning'
		exec [dbo].[ReportDashboard_Collection_v02_part3]  @dt_today_away_old
	end

		 ---------------------------------------------------------------------------------------------------------------------------
		--- третий запрос для расчета текущего дня с учетом ОД на первую дату входа в просрочку(стадию) в месяце
		--- версия от 20.01.2020
		-----------------------------------------------------------------------------------------------------------------------------

		-- 
	print 'run - ReportDashboard_Collection_v02_part3'
	declare  @dt_today_away date = cast(dateadd(day,0, dateadd(year,2000,getdate())) as date)
	exec [dbo].[ReportDashboard_Collection_v02_part3]  @dt_today_away

		---------------------------------------------------------------------------------
		-- Четвертая часть. Пишем из витрины сохраненого баланса в витрину дашбоарда
		---------------------------------------------------------------------------------
	print 'run - ReportDashboard_Collection_v02_part4'	
	exec [dbo].[ReportDashboard_Collection_v02_part4] 

				---------------------------------------------------------------------------------
		-- CASH для таблица 2 и для 90-360 и 361+
		---------------------------------------------------------------------------------
		--старый вариант кэш не считаем
		--exec [dbo].[ReportDashboard_Collection_v02_part5] 

		-- считаем новый
	print 'run - ReportDashboard_Collection_v02_part5_new_cash'	
	exec [dbo].[ReportDashboard_Collection_v02_part5_new_cash] 
		-- добавили таблицу 3 за месяц
		--exec [dbo].[ReportDashboard_Collection_v02_part5a]

		--старый вариант кэш не считаем
		--exec [dbo].[ReportDashboard_Collection_v02_part5b]
		-- считаем новый
	print 'run - ReportDashboard_Collection_v02_part5b_new_cashf'
		exec [dbo].[ReportDashboard_Collection_v02_part5b_new_cash]


	--- новый алгоритм расчета сохраненного баланса 26.06.2020
	-- предварительно заполняем данные и копируем из нового кэша
	print 'run - ReportDashboard_Collection_v02_part4_new_balance'
	exec [dbo].[ReportDashboard_Collection_v02_part4_new_balance] 

		---------------------------------------------------------------------------------
		-- расчет RR  
		---------------------------------------------------------------------------------
	print 'run - ReportDashboard_Collection_v02_part6'
	exec [dbo].[ReportDashboard_Collection_v02_part6] 
	print 'run - ReportDashboard_Collection_v02_part6_new_cash'
	exec [dbo].[ReportDashboard_Collection_v02_part6_new_cash] 
	print 'run - ReportDashboard_Collection_v02_part6_new_saved_balance'
	exec [dbo].[ReportDashboard_Collection_v02_part6_new_saved_balance]
	print  'insert into dm_dashboard'
		BEGIN TRAN
			--DWH-1919
			--весь расчет происходит в stage-таблицах, в конце расчета происходит запись в основные таблицы

			--DWH-2119
			TRUNCATE TABLE dbo.dm_dashboard_Collection_v02
			INSERT dbo.dm_dashboard_Collection_v02
			SELECT * FROM dbo.stage_dashboard_Collection_v02

			TRUNCATE TABLE dbo.dm_dashboard_Collection_v02_new_cash
			INSERT dbo.dm_dashboard_Collection_v02_new_cash
			SELECT * FROM dbo.stage_dashboard_Collection_v02_new_cash

			TRUNCATE TABLE dbo.dm_dashboard_Collection_v02_new_save_balance
			INSERT dbo.dm_dashboard_Collection_v02_new_save_balance
			SELECT * FROM dbo.stage_dashboard_Collection_v02_new_save_balance

			-- запишем что обновили данные, чтобы не пересчитывать утренную загрузку
			DECLARE @getdate datetime = getdate()
			update [dbo].[dm_dashboard_Collection_v02] SET [ДатаОбновления] = @getdate where id = 1 
			update [dbo].[dm_dashboard_Collection_v02_new_cash] SET [ДатаОбновления] = @getdate where id = 1 
			update [dbo].[dm_dashboard_Collection_v02_new_save_balance] SET [ДатаОбновления] = @getdate where id = 1 
		COMMIT TRAN

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
END
