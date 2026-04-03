


CREATE PROCEDURE [risk].[InquiryReply_NBKI]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--additional
SELECT    *   ,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date
FROM       OPENXML (@idoc, '/product/preply/report/InquiryReply',2)  
with (inqControlNum nvarchar(15),
inquiryPeriod nvarchar(100),
inqPurpose int,
inqPurposeText nvarchar(100),
inqAmount nvarchar(15),
currencyCode varchar(3),
userReference nvarchar(15),
freezeFlag int,
suppressFlag int )

END
