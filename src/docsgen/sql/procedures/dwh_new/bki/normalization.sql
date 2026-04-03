





-- =============================================
-- Author:		Orlov A.
-- Create date: 2019-07-03
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bki].[normalization]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
  truncate table bki.[n_AccountReply]
insert into bki.[n_AccountReply]
SELECT distinct [serialNum]
      ,[fileSinceDt]
      ,[ownerIndic]
      ,[ownerIndicText]
      ,[openedDt]
      ,[lastPaymtDt]
      ,[closedDt]
      ,[reportingDt]
      ,[acctType]
      ,[acctTypeText]
      ,[currencyCode]
      ,[creditLimit]
      ,[curBalanceAmt]
      ,[amtPastDue]
      ,[termsFrequency]
      ,[guarantorIndicatorCode]
      ,[guaranteeVolumeCode]
      ,[bankGuaranteeIndicatorCode]
      ,[bankGuaranteeVolumeCode]
--	  ,[creditTotalAmt]
      ,case when [creditTotalAmt] in ('', 'IRR','') then 0
		    when  [creditTotalAmt] like '%[%]%' then try_cast(replace(replace([creditTotalAmt],',','.'),'%','') as float)
	  	    when [creditTotalAmt] like '%,%,%' then try_cast(replace([creditTotalAmt],',','') as float)
            else try_cast(replace([creditTotalAmt],',','.') as float) end [creditTotalAmt]
      ,[termsAmt]
      ,[amtOutstanding]
      ,[monthsReviewed]
      ,[numDays30]
      ,[numDays60]
      ,[numDays90]
      ,[paymtPat]
      ,[paymtPatStartDt]
      ,[lastUpdatedDt]
      ,[freezeFlag]
      ,[suppressFlag]
      ,[paymtFreqText]
      ,[accountRating]
      ,[accountRatingText]
      ,[accountRatingDate]
      ,[paymentDueDate]
      ,[interestPaymentDueDate]
      ,[interestPaymentFrequencyCode]
      ,[interestPaymentFrequencyText]
      ,[businessCategory]
      ,[partnerStartDate]
      ,[external_id]
      ,[flag_correct]
      ,[rn]
      ,[response_date]
	  --into [n_AccountReply_norm]
  FROM [bki].[n_AccountReply_tmp]
  
  
  truncate table  bki.[eqv_credits]
  insert into bki.[eqv_credits]
  SELECT  distinct [cred_id]
      , CONVERT(date,RIGHT([cred_first_load],4)+SUBSTRING([cred_first_load],4,2)+LEFT([cred_first_load],2)) [cred_first_load]
      ,[cred_owner]
      ,[cred_partner_type]
      ,[cred_person_num]
      ,[cred_ratio]
      ,case when  [cred_sum] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_sum],',','.') as float) end  [cred_sum]
      ,[cred_currency]
      ,CONVERT(date,RIGHT([cred_date],4)+SUBSTRING([cred_date],4,2)+LEFT([cred_date],2)) [cred_date]
      ,CONVERT(date,RIGHT([cred_enddate],4)+SUBSTRING([cred_enddate],4,2)+LEFT([cred_enddate],2))[cred_enddate]
	  ,case when  [cred_sum_payout] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_sum_payout],',','.') as float) end  [cred_sum_payout]
	  ,CONVERT(date,RIGHT([cred_date_payout],4)+SUBSTRING([cred_date_payout],4,2)+LEFT([cred_date_payout],2)) [cred_date_payout]
	  ,case when  [cred_sum_debt] in ('-', '0,00' ) then 0 else try_cast(replace(cred_sum_debt,',','') as float ) end  [cred_sum_debt]
	  ,case when  [cred_sum_limit] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_sum_limit],',','.') as float) end  [cred_sum_limit]
      ,[delay5]
      ,[delay30]
      ,[delay60]
      ,[delay90]
      ,[delay_more]
	  ,case when  [cred_sum_overdue] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_sum_overdue],',','.') as float) end  [cred_sum_overdue]
      ,cast([cred_day_overdue] as int)
	  ,case when  [cred_max_overdue] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_max_overdue],',','.') as float) end  [cred_max_overdue]
      ,[cred_prolong]
      ,[cred_collateral]
      ,CONVERT(date,RIGHT([cred_update],4)+SUBSTRING([cred_update],4,2)+LEFT([cred_update],2)) [cred_update]
      ,[cred_type]
      ,[cred_active]
	  ,CONVERT(date,RIGHT([cred_active_date],4)+SUBSTRING([cred_active_date],4,2)+LEFT([cred_active_date],2)) [cred_active_date]
      ,[cred_sum_type]
	  ,case when  [cred_full_cost] in ('-', '0,00' ) then 0 else try_cast(REPLACE([cred_full_cost],',','.') as float) end  [cred_full_cost]
      ,[external_id]
      ,[flag_correct]
      ,[rn]
      ,[response_date] --into [eqv_credits]
  FROM dwh_new.bki.[eqv_credits_tmp]
  end