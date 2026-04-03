-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl credit_portfolio

--
--  exec etl.base_etl_credit_portfolio

-- =============================================
CREATE procedure [etl].[base_etl_credit_portfolio]

as
begin
	/* select count(*) from tmp_v_requests
       select count(*) from v_requests
     */
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''
	begin try
    /**
    select * from dwh_new.dbo.PaymentSystems
    select * into dwh_new_dev.dbo.PaymentSystems from dwh_new.dbo.PaymentSystems
    select * into dbo.PaymentSystems_payments from dwh_new.dbo.PaymentSystems_payments
    */

	truncate table dbo.PaymentSystems_payments;

	insert into dbo.PaymentSystems_payments

	select a.ссылка                                                                    as External_link
	,      case when year(a.Дата)>2018 then dateadd(year,-2000,a.Дата)
	                                   else a.Дата end                                 as Date
	,      case when year(a.ДатаПлатежнойСистемы)>2018 then dateadd(year,-2000,a.ДатаПлатежнойСистемы)
	                                                   else a.ДатаПлатежнойСистемы end as PaymentSystem_date
	,      a.НомерПлатежа                                                              as Payment_number
	,      a.СуммаДокумента                                                            as Amount
	,      r.номер                                                                     As external_id
	,      ps.id                                                                       as PaymentSystems_id
	from      [prodsql02].[mfo].[dbo].Документ_ГП_ПлатежЧерезПлатежнуюСистему a 
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]                   r  on r.ссылка=a.Договор
	left join dbo.PaymentSystems                                              ps on ps.External_id = a.ПлатежнаяСистема

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





