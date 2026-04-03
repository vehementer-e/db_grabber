


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2021-12-09
-- Description:	 Первая часть. Расчеты от рисков
--             exec [dbo].[ReportDashboard_Collection_Installment_v02_part1]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_Installment_v02_part1]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- проверим что данных за вчера уже посчитали

declare @is_new bigint
set @is_new=cast(isnull((select (iif(cast([ДатаОбновления] as date) = cast(Getdate() as date),1,0)) as is_new  from [dbo].[dm_dashboard_Collection_Installment_v02]),'0') as bigint)

---- Запрос--
declare @month_days int;

--- Если уже считали планы и историю за месяц, то не считаем
-- part 1
if (@is_new=0)
begin

	-----------------------------------------------
	-- удаляем данные из витрины. Обновляем дату
	-----------------------------------------------
	begin
	delete from [dbo].[dm_dashboard_Collection_Installment_v02]
	insert into [dbo].[dm_dashboard_Collection_Installment_v02] ([ДатаОбновления] , id) select GETDATE() as [ДатаОбновления], 1 as id
	end


end


END
