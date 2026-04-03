
--exec [risk].[copy_to_povt_pdl_buffer_history]
CREATE PROC [risk].[copy_to_povt_pdl_buffer_history]
AS
BEGIN TRY
	IF OBJECT_ID('risk.povt_pdl_buffer_history') IS NULL
	BEGIN
		SELECT TOP (0) [cdate] = cast(getdate() AS DATE)
			,t.*
		INTO risk.povt_pdl_buffer_history
		FROM [risk].povt_pdl_buffer t

		CREATE CLUSTERED INDEX cix_cdate_external_id ON risk.povt_pdl_buffer_history (
			cdate
			,external_id
			)
	END

	BEGIN TRAN

	DELETE
	FROM risk.povt_pdl_buffer_history
	WHERE [cdate] = cast(getdate() AS DATE);
	--alter table [risk].[povt_pdl_buffer_history]
	--	add EqxScore int		--DWH-2841
	--			,EqxScore_date	datetime--DWH-2841
	--	alter table   risk.[povt_pdl_buffer_history]
	--add	EqxScore_ByPerson	int		--DWH-2888
	--			,EqxScore_date_ByPerson	datetime	--DWH-2888
	--			,fl_low_EQUIscore_ByPerson	tinyint --DWH-2888
	/*
	alter table   risk.[povt_pdl_buffer_history]
	add pd_ByPerson		float	--DWH-157
		,pd_byExternal	float		--DWH-157
	alter table risk.[povt_pdl_buffer_history]
		add fl_low_PDscore_ByPerson tinyint
		*/
	INSERT INTO [risk].[povt_pdl_buffer_history] (
		[cdate]
		,[external_id]
		,[CMRClientGUID]
		,[person_id]
		,[person_id2]
		,[last_name]
		,[first_name]
		,[patronymic]
		,[birth_date]
		,[passport_series]
		,[passport_number]
		,[okbscore]
		,[okbscore_date]
		,[current_okbscore]
		,[current_okbscore_date]
		,[cnt_closed_inst]
		,[cnt_closed_pts]
		,[lifetime_days]
		,[days_after_close]
		,[approved_limit]
		,[fl_passport_date]
		,[fl_age]
		,[fl_reg_region]
		,[fl_fact_region]
		,[fl_blacklist]
		,[fl_inst_active]
		,[fl_pts_active]
		,[fl_isk_sp_space]
		,[fl_inst_max_overdue]
		,[fl_pts_max_overdue]
		,[fl_delay]
		,[fl_bankruptcy]
		,[fl_CheckPassport]
		,[fl_fssp]
		,[fl_cooling_7]
		,[fl_cooling_30]
		,[fl_low_okbscore]
		,[category]
		,[segment]
		,[factenddate]
		,[fl_override_povt]
		,[MAX_CREDIT_LIMIT_INST]
		,[MAX_CREDIT_LIMIT_PDL]
		,[current_incoming_dti]
		,[current_fl_override]
		,[current_amount]
		,[cnt_closed_pdl]
		,[cnt_active_pdl]
		,EqxScore 		--DWH-2841
		,EqxScore_date
		,EqxScore_ByPerson			--DWH-2888
		,EqxScore_date_ByPerson		--DWH-2888
		,fl_low_EQUIscore_ByPerson	--DWH-2888
		,pd_ByPerson			--DWH-157
		,pd_byExternal			--DWH-157
		,fl_low_PDscore_ByPerson
		)
	SELECT [cdate] = cast(getdate() AS DATE)
		,[external_id]
		,[CMRClientGUID]
		,[person_id]
		,[person_id2]
		,[last_name]
		,[first_name]
		,[patronymic]
		,[birth_date]
		,[passport_series]
		,[passport_number]
		,[okbscore]
		,[okbscore_date]
		,[current_okbscore]
		,[current_okbscore_date]
		,[cnt_closed_inst]
		,[cnt_closed_pts]
		,[lifetime_days]
		,[days_after_close]
		,[approved_limit]
		,[fl_passport_date]
		,[fl_age]
		,[fl_reg_region]
		,[fl_fact_region]
		,[fl_blacklist]
		,[fl_inst_active]
		,[fl_pts_active]
		,[fl_isk_sp_space]
		,[fl_inst_max_overdue]
		,[fl_pts_max_overdue]
		,[fl_delay]
		,[fl_bankruptcy]
		,[fl_CheckPassport]
		,[fl_fssp]
		,[fl_cooling_7]
		,[fl_cooling_30]
		,[fl_low_okbscore]
		,[category]
		,[segment]
		,[factenddate]
		,[fl_override_povt]
		,[MAX_CREDIT_LIMIT_INST]
		,[MAX_CREDIT_LIMIT_PDL]
		,[current_incoming_dti]
		,[current_fl_override]
		,[current_amount]
		,[cnt_closed_pdl]
		,[cnt_active_pdl]
		,EqxScore 		--DWH-2841
		,EqxScore_date
		,EqxScore_ByPerson			--DWH-2888
		,EqxScore_date_ByPerson		--DWH-2888
		,fl_low_EQUIscore_ByPerson	--DWH-2888
		,pd_ByPerson			--DWH-157
		,pd_byExternal			--DWH-157
		,fl_low_PDscore_ByPerson
	FROM [risk].povt_pdl_buffer WITH (NOLOCK)

	COMMIT TRAN
END TRY

BEGIN CATCH
	DECLARE @msg NVARCHAR(255) = ERROR_MESSAGE()

	IF @@TRANCOUNT > 0
		ROLLBACK TRAN;

	throw 51000
		,@msg
		,1
END CATCH
