
CREATE PROCEDURE [bki].[requests]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--requests
SELECT    *  ,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date
FROM       OPENXML (@idoc, '/bki_response/response/add_part/info_requests/request',2)
with (timeslot  nvarchar(15),
request_reason int,
cred_type  int,
cred_currency  varchar(3),
cred_sum  nvarchar(15),
cred_duration  nvarchar(15),
cred_partner_type  int)

END
