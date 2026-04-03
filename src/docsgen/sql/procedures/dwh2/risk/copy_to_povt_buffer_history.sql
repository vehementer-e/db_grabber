
CREATE PROC [risk].[copy_to_povt_buffer_history]
as
begin try
if OBJECT_ID('risk.povt_buffer_history') is null
begin
	select top(0)
		[cdate] = cast(getdate() as date)
		,t.*
	into risk.[povt_buffer_history]
	from [risk].[povt_buffer] t

	create clustered index cix_cdate_external_id on risk.[povt_buffer_history](cdate, external_id)
end
begin tran
	delete from risk.povt_buffer_history
	where [cdate] = cast(getdate() as date)

	insert into risk.povt_buffer_history(
			[cdate],
			[external_id], [startdate], [category], [TYPE], [main_limit], [Минимальный срок кредитования], [Ставка %], [Сумма платежа], [Рекомендуемая дата повторного обращения], [fio], [birth_date], [Auto], [vin], [pos], [rp], [channel], [doc_ser], [doc_num], [ТелефонМобильный], [region_projivaniya], [Berem_pt], [Nalichie_pts], [not_end], [max_dpd_all], [dod], [was_closed_ago], [flag], [LIMIT], [num_active_days], [market_price], [collateral_id], [price_date], [days], [discount_price], [koeff], [limit_car], [red_lim], [red_age], [red_7days], [red_dpd], [is_red], [is_green], [is_blue], [is_yellow], [is_orange], [score], [score_date], [group], [GUID], [cred_hist_length], [term_from_last_closed], [last_int_rate], [rbp_gr_action], [last_name], [first_name], [middle_name], [CRMClientGUID], [ОсновнойТелефонКлиента], [probation], [probation_povt]
	)
	select --
			[cdate] = cast(getdate() as date)
			,[external_id], [startdate], [category], [TYPE], [main_limit], [Минимальный срок кредитования], [Ставка %], [Сумма платежа], [Рекомендуемая дата повторного обращения], [fio], [birth_date], [Auto], [vin], [pos], [rp], [channel], [doc_ser], [doc_num], [ТелефонМобильный], [region_projivaniya], [Berem_pt], [Nalichie_pts], [not_end], [max_dpd_all], [dod], [was_closed_ago], [flag], [LIMIT], [num_active_days], [market_price], [collateral_id], [price_date], [days], [discount_price], [koeff], [limit_car], [red_lim], [red_age], [red_7days], [red_dpd], [is_red], [is_green], [is_blue], [is_yellow], [is_orange], [score], [score_date], [group], [GUID], [cred_hist_length], [term_from_last_closed], [last_int_rate], [rbp_gr_action], [last_name], [first_name], [middle_name], [CRMClientGUID], [ОсновнойТелефонКлиента], [probation], [probation_povt]
	from [risk].povt_buffer with(nolock)
commit tran

end try
begin catch
	declare @msg nvarchar(255)=  ERROR_MESSAGE()
	if @@TRANCOUNT>0
		rollback tran;
	throw 51000, @msg, 1
end catch
