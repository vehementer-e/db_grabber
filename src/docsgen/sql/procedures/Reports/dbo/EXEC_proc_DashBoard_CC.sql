-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE    PROCEDURE [dbo].[EXEC_proc_DashBoard_CC] 
	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>

 AS
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	print getdate()

	print N'-------------------------------------------------'
	exec [Stg].[dbo].[p_Aux_DashBoard_CallCentr];
	print N'Таблица [aux_DashBoard_CallCentr] на STG обновлена'
	print N'-------------------------------------------------'

	exec [dbo].[Report_dm_dashboard_CallCentr];
	print N'Таблица [dm_dashboard_CallCentr]  на REPORTS обновлена'
	print N'-------------------------------------------------'			


	print getdate()

 END
