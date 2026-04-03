
CREATE PROCEDURE [bki].[collaterals]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

SELECT    * ,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date
FROM       OPENXML (@idoc, '/bki_response/response/base_part/collateral',2)
with (cred_id  nvarchar(30),
subject  int,
collateral_id  nvarchar(30),
collateral_no  nvarchar(30),
collateral_date  nvarchar(30),
collateral_enddate  varchar(10),
assessment  nvarchar(30),
assessment_date  varchar(10))

END
