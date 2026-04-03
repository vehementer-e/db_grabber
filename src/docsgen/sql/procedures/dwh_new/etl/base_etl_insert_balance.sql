-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl insert_balance

--
--  exec etl.base_etl_insert_balance

-- =============================================
CREATE PROCEDURE [etl].[base_etl_insert_balance]

AS
BEGIN
	/* select count(*) from tmp_v_requests
       select count(*) from v_requests
     */
	SET NOCOUNT ON;
	--log
	DECLARE @sp_name nvarchar(128) = isnull(object_schema_name(@@PROCID) + '.', '') + object_name(@@PROCID)
	DECLARE @params nvarchar(1024) = ''
	EXEC logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''

	BEGIN TRY
    /**
     select * into dwh_new_dev.dbo.balance from dwh_new.dbo.balance
     */

	TRUNCATE TABLE dbo.balance;

	insert into dbo.balance

	select b.Ссылка                                                                  external_link
	,      r.Номер                                                                   external_id
	,      cr.ВидДвижения                                                            action_type_id
	,      case when year(cr.Период)>2018 then DATEADD(year,-2000,cr.Период)
	                                      else cr.Период end                      as moment
	,      sum( case when cr.Вид = 0xA3DBD252B629EFDE45312018E2F4C5DF then cr.Сумма
	                                                                  else 0 end) as principal
	,      sum( case when cr.Вид = 0x83862A805ED0E9F042572467ABEA7C11 then cr.Сумма
	                                                                  else 0 end) as percents
	,      sum( case when cr.Вид = 0x8C8F7EFDFE1942A24ACAE8C38B924DDA then cr.Сумма
	                                                                  else 0 end) as fines
	,      sum( case when cr.Вид = 0xBEC58539CF56B2BF47AA3E45AE6172F5 then cr.Сумма
	                                                                  else 0 end) as overpayment
	,      sum( case when cr.Вид = 0x8F256D5874AF89354543DD824E1D4816 then cr.Сумма
	                                                                  else 0 end) as other_payments
	from      [prodsql02].[mfo].[dbo].[РегистрНакопления_ГП_ОстаткиЗаймов] cr
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]                r  on r.ссылка=cr.Договор
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка]                 b  on b.ссылка = r.Заявка
	group by b.Ссылка
	,        r.Номер
	,        cr.ВидДвижения
	,        cr.Период
	;

	-- added 190519 by turabov
	--balance writeoff
	
		--drop table if exists dbo.balance_wtiteoff;
		--DWH-1764
		TRUNCATE TABLE dbo.balance_wtiteoff

	INSERT dbo.balance_wtiteoff
	(
	    external_link,
	    external_id,
	    action_type_id,
	    moment,
	    principal,
	    percents,
	    fines,
	    overpayment,
	    other_payments
	)
	select b.Ссылка                                                                  external_link
	,      r.Номер                                                                   external_id
	,      cr.ВидДвижения                                                            action_type_id
	,      case when year(cr.Период)>2018 then DATEADD(year,-2000,cr.Период)
	                                      else cr.Период end                      as moment
	,      sum( case when cr.Вид = 0xA3DBD252B629EFDE45312018E2F4C5DF then cr.Сумма
	                                                                  else 0 end) as principal
	,      sum( case when cr.Вид = 0x83862A805ED0E9F042572467ABEA7C11 then cr.Сумма
	                                                                  else 0 end) as percents
	,      sum( case when cr.Вид = 0x8C8F7EFDFE1942A24ACAE8C38B924DDA then cr.Сумма
	                                                                  else 0 end) as fines
	,      sum( case when cr.Вид = 0xBEC58539CF56B2BF47AA3E45AE6172F5 then cr.Сумма
	                                                                  else 0 end) as overpayment
	,      sum( case when cr.Вид = 0x8F256D5874AF89354543DD824E1D4816 then cr.Сумма
	                                                                  else 0 end) as other_payments
		--into dbo.balance_wtiteoff
	from      [prodsql02].[mfo].[dbo].[РегистрНакопления_ГП_ОстаткиЗаймов] cr
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]                r  on r.ссылка=cr.Договор
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка]                 b  on b.ссылка = r.Заявка
	where cr.Сумма<0
	group by b.Ссылка
	,        r.Номер
	,        cr.ВидДвижения
	,        cr.Период
	--end of balance writeoff

	;--todo: вынетси в отдельный шаг

	--drop table if exists dbo.stat_v_balance2;
	--DWH-1764
	TRUNCATE TABLE dbo.stat_v_balance2

	DROP INDEX IF EXISTS idx_stvb_overdue_days_p on dbo.stat_v_balance2
	DROP INDEX IF EXISTS idx_stvb_credit_id on dbo.stat_v_balance2
	DROP INDEX IF EXISTS idx_stat_v_balance2_cdate_external_id_principal_cnl_percents_cnl_fines_cnl ON dbo.stat_v_balance2

	INSERT dbo.stat_v_balance2
	(
	    credit_id,
	    external_id,
	    request_id,
	    cdate,
	    generation,
	    grp,
	    agent_pool,
	    credit_date,
	    CreditDays,
	    CreditMonths,
	    default_date,
	    default_date_year,
	    default_date_month,
	    days_from_default,
	    amount,
	    term,
	    principal_cnl,
	    percents_cnl,
	    fines_cnl,
	    overpayments_cnl,
	    otherpayments_cnl,
	    principal_acc,
	    percents_acc,
	    fines_acc,
	    overpayments_acc,
	    otherpayments_acc,
	    principal_wo,
	    percents_wo,
	    fines_wo,
	    otherpayments_wo,
	    principal_acc_run,
	    principal_cnl_run,
	    percents_acc_run,
	    percents_cnl_run,
	    fines_acc_run,
	    fines_cnl_run,
	    overpayments_acc_run,
	    otherpayments_acc_run,
	    overpayments_cnl_run,
	    otherpayments_cnl_run,
	    principal_rest,
	    percents_rest,
	    fines_rest,
	    other_payments_rest,
	    total_rest,
	    principal_rest_wo,
	    percents_rest_wo,
	    fines_rest_wo,
	    total_rest_wo,
	    overdue_days,
	    overdue,
	    overdue_days_p,
	    PaymentSystems_id,
	    Priority_PaymentSystem_id,
	    bucket_id,
	    overdue_days_flowrate,
	    active_credit,
	    end_date,
	    KOEFF_4054U,
	    KOEFF_493P,
	    reserve_4054U,
	    reserve_493P,
	    reserve_493P_v2,
	    real_paymen_amount,
	    total_CF,
	    is_hard,
	    writeoff_status
	)
	select 
		credit_id,
        external_id,
        request_id,
        cdate,
        generation,
        grp,
        agent_pool,
        credit_date,
        CreditDays,
        CreditMonths,
        default_date,
        default_date_year,
        default_date_month,
        days_from_default,
        amount,
        term,
        principal_cnl,
        percents_cnl,
        fines_cnl,
        overpayments_cnl,
        otherpayments_cnl,
        principal_acc,
        percents_acc,
        fines_acc,
        overpayments_acc,
        otherpayments_acc,
        principal_wo,
        percents_wo,
        fines_wo,
        otherpayments_wo,
        principal_acc_run,
        principal_cnl_run,
        percents_acc_run,
        percents_cnl_run,
        fines_acc_run,
        fines_cnl_run,
        overpayments_acc_run,
        otherpayments_acc_run,
        overpayments_cnl_run,
        otherpayments_cnl_run,
        principal_rest,
        percents_rest,
        fines_rest,
        other_payments_rest,
        total_rest,
        principal_rest_wo,
        percents_rest_wo,
        fines_rest_wo,
        total_rest_wo,
        overdue_days,
        overdue,
        overdue_days_p,
        PaymentSystems_id,
        Priority_PaymentSystem_id,
        bucket_id,
        overdue_days_flowrate,
        active_credit,
        end_date,
        KOEFF_4054U,
        KOEFF_493P,
        reserve_4054U,
        reserve_493P,
        reserve_493P_v2,
        real_paymen_amount,
        total_CF,
        is_hard,
        writeoff_status
	--INTO dbo.stat_v_balance2
	from dbo.v_balance3;


/*
create index idx_stvb_cdate
on stat_v_balance2(cdate) ;
  */
	create index idx_stvb_overdue_days_p
	on stat_v_balance2(overdue_days_p);

	create index idx_stvb_credit_id
	on stat_v_balance2(credit_id);

	
	CREATE NONCLUSTERED INDEX idx_stat_v_balance2_cdate_external_id_principal_cnl_percents_cnl_fines_cnl
	ON [dbo].[stat_v_balance2] ([cdate])
	INCLUDE ([external_id],
		[principal_cnl],
		[percents_cnl],
		[fines_cnl],
		[overpayments_cnl],
		[otherpayments_cnl],
		[overpayments_acc],
		[total_rest],
		[overdue_days_p],
		principal_rest
		)



	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      ''

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
end





