

CREATE PROCEDURE [bki].[AddressReply]
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
FROM       OPENXML (@idoc, '/xml/product/preply/report/AddressReply',2)  
with (serialNum nvarchar(10),
fileSinceDt date,
houseNumber nvarchar(10),
district nvarchar(200),
street nvarchar(200),
postal nvarchar(10),
addressType int,
block  nvarchar(200),
building nvarchar(10),
prov int,
 provText nvarchar(200),
countryCode nvarchar(3),
countryCodeText  nvarchar(200),
addressTypeText nvarchar(200),
lastUpdatedDt date,
freezeFlag int,
suppressFlag int)

END
