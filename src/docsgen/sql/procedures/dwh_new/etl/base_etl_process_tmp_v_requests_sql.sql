-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [etl].[base_etl_process_tmp_v_requests_sql]

AS
BEGIN
	SET NOCOUNT ON;
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''
	begin try
	declare @updatedRows int=0
	declare @insertedRows int=0
	declare @result nvarchar(max)=''


	--begin tran
	--drop table if exists tmp_v_requests;
	--DWH-1764
	TRUNCATE TABLE dbo.tmp_v_requests

	INSERT dbo.tmp_v_requests
	(
	    id,
	    person_id,
	    collateral_id,
	    request_date,
	    initial_amount,
	    accepted_amount,
	    product,
	    term,
	    point_of_sale,
	    prelending,
	    income,
	    chanel,
	    external_id,
	    lcrm_id,
	    created,
	    updated,
	    is_active,
	    request_date_num,
	    external_link,
	    status,
	    reject_reason,
	    accepted_amount_cohort,
	    top_rejects,
	    request_number,
	    request_year,
	    request_month,
	    request_day,
	    request_week,
	    age_cohort,
	    age,
	    base_cohort,
	    generation,
	    diff_amount,
	    rejects,
	    approve,
	    is_repeated,
	    is_prelending,
	    new_approve,
	    new_reject_reason,
	    new_status,
	    new_status_group,
	    return_type,
	    score_group,
	    is_credit,
	    otb_agent,
	    olap_duplicate_algo,
	    new_duplicates_algo,
	    sales_chanel,
	    [percent],
	    percent_group,
	    marketing_channel_id,
	    is_fraud,
	    approved,
	    issued,
	    recommend_price,
	    verifier,
	    credit_committee,
	    credit_committee_mfo,
	    loginom_stage,
	    risk_visa
	)
	select 
		id,
        person_id,
        collateral_id,
        request_date,
        initial_amount,
        accepted_amount,
        product,
        term,
        point_of_sale,
        prelending,
        income,
        chanel,
        external_id,
        lcrm_id,
        created,
        updated,
        is_active,
        request_date_num,
        external_link,
        status,
        reject_reason,
        accepted_amount_cohort,
        top_rejects,
        request_number,
        request_year,
        request_month,
        request_day,
        request_week,
        age_cohort,
        age,
        base_cohort,
        generation,
        diff_amount,
        rejects,
        approve,
        is_repeated,
        is_prelending,
        new_approve,
        new_reject_reason,
        new_status,
        new_status_group,
        return_type,
        score_group,
        is_credit,
        otb_agent,
        olap_duplicate_algo,
        new_duplicates_algo,
        sales_chanel,
        [percent],
        percent_group,
        marketing_channel_id,
        is_fraud,
        approved,
        issued,
        recommend_price,
        verifier,
        credit_committee,
        credit_committee_mfo,
        loginom_stage,
        risk_visa
	--INTO tmp_v_requests
	from v_requests
	--commit tran


	set @insertedRows=@@ROWCOUNT

	set @result=N' Results:<br /><br />'

	set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'




	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      @result
	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch

END
