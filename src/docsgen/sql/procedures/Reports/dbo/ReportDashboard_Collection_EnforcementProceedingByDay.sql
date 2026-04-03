


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-05-27
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_EnforcementProceedingByDay]  
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_EnforcementProceedingByDay]
	
	-- Add the parameters for the stored procedure here
	--@DateReport date
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)

/*
declare @ii int = 45
Declare  @DateReport date

while @ii>-1
begin 
 declare  @dt date = cast(dateadd(day,-@ii, getdate()) as date)
Select @ii, @dt
set @ii=@ii-1
exec [dbo].[ReportDashboard_Collection_EnforcementProceeding]   @dt
end
*/
exec [dbo].[ReportDashboard_Collection_EnforcementProceeding]   @DateReport

END
