
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- exec [dbo].[Monitoring_FilesLoader] 
-- =============================================
CREATE PROCEDURE [dbo].[Monitoring_FilesLoader] 
	-- Add the parameters for the stored procedure here
	--@p int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	begin try
	Declare @isError int = 0
	set @isError = cast(isnull((SELECT TOP (1)   iif([created]>dateadd(minute,-120,GetDate()),0,1) as isError   FROM [Stg].[files].[Test_buffer]),'1') as int)

	select 1/(@isError-1)
	end try
	begin catch
	THROW 51000, 'Files loader error.', 1;
	end catch

END
