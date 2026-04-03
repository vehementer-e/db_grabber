





-- =============================================
-- Author:		Orlov A.
-- Create date: 2019-07-03
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [bki].[AccountReply]
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
FROM       OPENXML (@idoc, '/xml/product/preply/report/AccountReply',2)  
with (serialNum nvarchar(10),
fileSinceDt date,
ownerIndic int,
ownerIndicText nvarchar(100),
openedDt date,
lastPaymtDt date,
closedDt date,
reportingDt date,
acctType int,
acctTypeText nvarchar(100),
currencyCode varchar(3),
creditLimit float,
curBalanceAmt float,
amtPastDue float,
termsFrequency int,
guarantorIndicatorCode nvarchar(100),
guaranteeVolumeCode nvarchar(100),
bankGuaranteeIndicatorCode nvarchar(100),
bankGuaranteeVolumeCode nvarchar(100),
creditTotalAmt nvarchar(50),
termsAmt int,
amtOutstanding  float,
monthsReviewed int,
numDays30 int,
numDays60 int,
numDays90 int, 
paymtPat varchar(max),
paymtPatStartDt date,
lastUpdatedDt date,
freezeFlag int,
suppressFlag int,
paymtFreqText nvarchar(100),
accountRating int,
accountRatingText nvarchar(100),
accountRatingDate date,
paymentDueDate date,
interestPaymentDueDate date,
interestPaymentFrequencyCode int,
interestPaymentFrequencyText nvarchar(100),
businessCategory nvarchar(100),
partnerStartDate date)

END
