



CREATE PROCEDURE [risk].[IdReply_NBKI]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--additional
SELECT    *  ,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date
FROM       OPENXML (@idoc, '/product/preply/report/IdReply',2)  
with (idNum nvarchar(10),
idType int,
idTypeText nvarchar(10),
fileSinceDt date,
seriesNumber nvarchar(20),
issueCountry nvarchar(100),
issueDate date,
issueAuthority nvarchar(10),
lastUpdatedDt date,
freezeFlag int,
suppressFlag int)

END
