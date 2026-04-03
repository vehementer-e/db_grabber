


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-05212
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_JudicialProceeding]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_JudicialProceeding]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	exec [dbo].[ReportDashboard_Collection_JudicialProceeding_part1]

END
