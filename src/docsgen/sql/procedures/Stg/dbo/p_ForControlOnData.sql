
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[p_ForControlOnData];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[p_ForControlOnData] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Убрали вызов в рамках задачи - DWH-1123
	--exec [dbo].[p_Aux_ListCommentRequestMFO_1c];

--	print N'Основная вспом.таблица "СПИСОК КОММЕНТАРИЕВ К ЗАЯВКЕ" обновлена'

	exec [dbo].[p_aux_ListRequestOnStatusesMFO_1c];
--	print N'Основная таблица "ЗАЯВКИ ПО СТАТУСАМ" обновлена'	

	exec [dbo].[P_Aux_UserRoleMFO_1c];


	


END
