
CREATE PROCEDURE [bki].[additional]
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
FROM       OPENXML (@idoc, '/bki_response/response/add_part/attrs/package/section/period/attr',1)
with (c_i nvarchar(30),
n int,v nvarchar(max))

END
