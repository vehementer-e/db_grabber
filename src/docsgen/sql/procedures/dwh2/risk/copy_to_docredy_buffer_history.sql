CREATE PROC [risk].[copy_to_docredy_buffer_history]
as
begin try
if OBJECT_ID('risk.docredy_buffer_history') is null
begin
	select top(0)
		[cdate] = cast(getdate() as date)
		,t.*
	into risk.[docredy_buffer_history]
	from [risk].[docredy_buffer] t

	create clustered index cix_cdate_external_id on risk.[docredy_buffer_history](cdate, external_id)
end
begin tran
	delete from risk.[docredy_buffer_history]
	where [cdate] = cast(getdate() as date)

	insert into risk.[docredy_buffer_history](
			 [cdate] 
			,[external_id] 
			,[category] 
			,[Type] 
			,[main_limit] 
			,[Минимальный срок кредитования] 
			,[Ставка %] 
			,[Сумма платежа] 
			,[Рекомендуемая дата повторного обращения] 
			,[fio] 
			,[birth_date] 
			,[Auto] 
			,[vin] 
			,[pos] 
			,[rp] 
			,[channel] 
			,[doc_ser] 
			,[doc_num] 
			,[ТелефонМобильный] 
			,[region_projivaniya] 
			,[Berem_pts] 
			,[Nalichie_pts] 
			,[not_end] 
			,[flag_good] 
			,[max_dpd_all] 
			,[max_dpd_now] 
			,[overdue_days] 
			,[dod] 
			,[num_active_days] 
			,[market_price] 
			,[collateral_id] 
			,[price_date] 
			,[discount_price] 
			,[col_rest] 
			,[pers_rest] 
			,[koeff] 
			,[num_closed] 
			,[limit_car] 
			,[limit_client] 
			,[red_visa] 
			,[red_dod] 
			,[red_dpd] 
			,[red_limit] 
			,[is_red] 
			,[is_green] 
			,[is_yellow] 
			,[score] 
			,[score_date] 
			,[has_bureau] 
			,[scoring] 
			,[group] 
			,[GUID] 
			,[max_delta_active] 
			,[max_dpd_da] 
			,[RED_CAR] 
			,[RED_CHD] 
			,[is_orange] 
			,[red_velocity] 
			,[red_pmt_delay]
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,last_name
			,first_name
			,patronymic
	)
	select --
			[cdate] = cast(getdate() as date)
			,[external_id] 
			,[category] 
			,[Type] 
			,[main_limit] 
			,[Минимальный срок кредитования] 
			,[Ставка %] 
			,[Сумма платежа] 
			,[Рекомендуемая дата повторного обращения] 
			,[fio] 
			,[birth_date] 
			,[Auto] 
			,[vin] 
			,[pos] 
			,[rp] 
			,[channel] 
			,[doc_ser] 
			,[doc_num] 
			,[ТелефонМобильный] 
			,[region_projivaniya] 
			,[Berem_pts] 
			,[Nalichie_pts] 
			,[not_end] 
			,[flag_good] 
			,[max_dpd_all] 
			,[max_dpd_now] 
			,[overdue_days] 
			,[dod] 
			,[num_active_days] 
			,[market_price] 
			,[collateral_id] 
			,[price_date] 
			,[discount_price] 
			,[col_rest] 
			,[pers_rest] 
			,[koeff] 
			,[num_closed] 
			,[limit_car] 
			,[limit_client] 
			,[red_visa] 
			,[red_dod] 
			,[red_dpd] 
			,[red_limit] 
			,[is_red] 
			,[is_green] 
			,[is_yellow] 
			,[score] 
			,[score_date] 
			,[has_bureau] 
			,[scoring] 
			,[group] 
			,[GUID] 
			,[max_delta_active] 
			,[max_dpd_da] 
			,[RED_CAR] 
			,[RED_CHD] 
			,[is_orange] 
			,[red_velocity] 
			,[red_pmt_delay]
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,last_name
			,first_name
			,patronymic
	from [risk].[docredy_buffer] with(nolock)
commit tran

end try
begin catch
	declare @msg nvarchar(255)=  ERROR_MESSAGE()
	if @@TRANCOUNT>0
		rollback tran;
	throw 51000, @msg, 1
end catch