
CREATE PROCEDURE [bki].[credits]
	-- Add the parameters for the stored procedure here
	@idoc int, @doc xml, @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

    SELECT    *,@external_id external_id ,@flag_correct flag_correct, @rn rn, @response_date response_date --into credits
		FROM       OPENXML (@idoc, '/bki_response/response/base_part/credit',2)
		with   (cred_id  nvarchar(15),
		cred_first_load  varchar(10),
		cred_owner  int,
		cred_partner_type  int,
		cred_person_num  int,
		cred_ratio  int,
		cred_sum  nvarchar(15),
		cred_currency  varchar(3),
		cred_date  varchar(10),
		cred_enddate  varchar(10),
		cred_sum_payout  nvarchar(15),
		cred_date_payout  varchar(10),
		cred_sum_debt  nvarchar(15),
		cred_sum_limit  nvarchar(15),
		delay5  int,
		delay30  int,
		delay60  int,
		delay90  int,
		delay_more  int,
		cred_sum_overdue  nvarchar(15),
		cred_day_overdue  nvarchar(15),
		cred_max_overdue  nvarchar(15),
		cred_prolong  int,
		cred_collateral  int,
		cred_update  varchar(10),
		cred_type  int,
		cred_active  int,
		cred_active_date  varchar(10),
		cred_sum_type  int,
		cred_full_cost  nvarchar(15) ) 

END
