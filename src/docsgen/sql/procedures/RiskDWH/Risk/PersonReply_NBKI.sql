

CREATE PROCEDURE [Risk].[PersonReply_NBKI]
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

FROM       OPENXML (@idoc, '/product/preply/report/PersonReply',2)  
with (serialNum nvarchar(10),
fileSinceDt date,
name1 nvarchar(30), -- 2021_06_08
first nvarchar(30),
paternal nvarchar(30),
gender int,
genderText nvarchar(12),
birthDt date,
placeOfBirth nvarchar(50),
lastUpdatedDt date,
freezeFlag int,
suppressFlag int)

END
