-- =============================================
-- Author:		Kurdin Sergey  
-- Create date: 28-01-2020
-- Description:	load tables from P2P
-- exec [_p2p].[p2p2DWHLoader]
-- =============================================

-- Usage: запуск процедуры с параметрами
-- EXEC [_p2p].[p2p2DWHLoader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [_p2p].[p2p2DWHLoader]
AS
BEGIN
	SET NOCOUNT ON;
    --declare @serverName nvarchar(50)=N'prodsql02.cm.carmoney.ru'--N'C1D-VSR-SQLDEV1.dev.carmoney.ru'
    --declare @dbName nvarchar(50)=N'[paymentgateway]'--N'[pg_dev_shubkin00]'

    -- выбираем последнюю загруженную дату из локальной таблицы

    EXECUTE AS LOGIN = 'sa';

    declare @tsql nvarchar(max) = N''

    declare @maxPeriod datetime='2000-01-01 00:00:00'

	declare @selectcount int 

-----------------------------------------
-------------------- requests

drop table if exists #requests_old
 select * into #requests_old from [stg].[_p2p].[requests]

 drop table if exists #requests_new

 begin try
 	select s.* into #requests_new from (select * from openquery(p2p,'select * from requests')) s
	set @selectcount = isnull((select count(*) from #requests_new),0);
 end try
 begin catch
	set @selectcount = 0
 end catch


begin tran
	delete from [stg].[_p2p].[requests]

	if @selectcount > 0
		insert into [stg].[_p2p].[requests] (
											   [guid]
											  ,[number]
											  ,[car_vin]
											  ,[car_brand]
											  ,[car_model]
											  ,[car_price]
											  ,[car_gov_number]
											  ,[date_return]
											  ,[interest_rate]
											  ,[pts_series]
											  ,[pts_number]
											  ,[sum_requested]
											  ,[sum_approved]
											  ,[sum_contract]
											  ,[sum_client]
											  ,[loan_period]
											  ,[last_payment_date]
											  ,[request_status_guid]
											  ,[office_guid]
											  ,[user_guid]
											  ,[partner_guid]
											  ,[account_real_guid]
											  ,[created_at]
											  ,[updated_at]
											  ,[deleted_at])
		select [guid]
			  ,[number]
			  ,[car_vin]
			  ,[car_brand]
			  ,[car_model]
			  ,[car_price]
			  ,[car_gov_number]
			  ,[date_return]
			  ,[interest_rate]
			  ,[pts_series]
			  ,[pts_number]
			  ,[sum_requested]
			  ,[sum_approved]
			  ,[sum_contract]
			  ,[sum_client]
			  ,[loan_period]
			  ,[last_payment_date]
			  ,[request_status_guid]
			  ,[office_guid]
			  ,[user_guid]
			  ,[partner_guid]
			  ,[account_real_guid]
			  ,[created_at]
			  ,[updated_at]
			  ,[deleted_at]	 
		from #requests_new --openquery(p2p,'select * from requests')

	else 
		insert into [stg].[_p2p].[requests] 
		select * from #requests_old

commit tran


/*
----- 2020-02-20
drop table if exists [stg].[_p2p].[requests]
    
BEGIN TRY  
	select * 
	into [stg].[_p2p].[requests]
	from  openquery(p2p,'select * from requests')
END TRY
BEGIN CATCH
        THROW
END CATCH
*/

-----------------------------------------


-----------------------------------------
-------------------- transactions

drop table if exists #transactions_old
select * into #transactions_old from [stg].[_p2p].[transactions]
 
 begin try
	drop table if exists #transactions_new
 	select s.* into #transactions_new from (select * from openquery(p2p,'select * from transactions')) s
	set @selectcount = isnull((select count(*) from #transactions_new),0);
 end try
 begin catch
	set @selectcount = 0;
 end catch


begin tran
	delete from [stg].[_p2p].[transactions]

	if @selectcount > 0
		insert into [stg].[_p2p].[transactions] (  [guid]
												  ,[sum]
												  ,[account_guid]
												  ,[transaction_type_guid]
												  ,[request_guid]
												  ,[transaction_status_guid]
												  ,[payment_method_guid]
												  ,[provider_transaction_type_guid]
												  ,[external_uuid]
												  ,[created_at]
												  ,[updated_at]
												  ,[deleted_at])
		select [guid]
			  ,[sum]
			  ,[account_guid]
			  ,[transaction_type_guid]
			  ,[request_guid]
			  ,[transaction_status_guid]
			  ,[payment_method_guid]
			  ,[provider_transaction_type_guid]
			  ,[external_uuid]
			  ,[created_at]
			  ,[updated_at]
			  ,[deleted_at] 
		from #transactions_new

	else 
		insert into [stg].[_p2p].[transactions] 
		select * from #transactions_old

commit tran

/*
-------2020-02-20
drop table if exists [stg].[_p2p].[transactions]
    
BEGIN TRY   
	select * 
	into [stg].[_p2p].[transactions]
	from  openquery(p2p,'select * from transactions')
END TRY
BEGIN CATCH
        THROW
END CATCH
*/


-----------------------------------------
-------------------- request_statuses

drop table if exists #request_statuses_old
select * into #request_statuses_old from [stg].[_p2p].[request_statuses]
 
 begin try
	drop table if exists #request_statuses_new
 	select s.* into #request_statuses_new from (select * from openquery(p2p,'select * from request_statuses')) s
	set @selectcount = isnull((select count(*) from #request_statuses_new),0);
 end try
 begin catch
	set @selectcount = 0;
 end catch


begin tran
	delete from [stg].[_p2p].[request_statuses]

	if @selectcount > 0
		insert into [stg].[_p2p].[request_statuses] (  [guid]
													  ,[name]
													  ,[code]
													  ,[created_at]
													  ,[updated_at]
													  ,[deleted_at])
		select [guid]
			  ,[name]
			  ,[code]
			  ,[created_at]
			  ,[updated_at]
			  ,[deleted_at]
		from #request_statuses_new

	else 
		insert into [stg].[_p2p].[request_statuses] 
		select * from #request_statuses_old

commit tran

/*
-------2020-02-20

drop table if exists [stg].[_p2p].[request_statuses]
    
BEGIN TRY   
	select * 
	into [stg].[_p2p].[request_statuses]
	from  openquery(p2p,'select * from request_statuses')
END TRY
BEGIN CATCH
        THROW
END CATCH
*/

-----------------------------------------
-------------------- transaction_statuses

drop table if exists #transaction_statuses_old
select * into #transaction_statuses_old from [stg].[_p2p].[transaction_statuses]
 
 begin try
	drop table if exists #transaction_statuses_new
 	select s.* into #transaction_statuses_new from (select * from openquery(p2p,'select * from transaction_statuses')) s
	set @selectcount = isnull((select count(*) from #transaction_statuses_new),0);
 end try
 begin catch
	set @selectcount = 0;
 end catch


begin tran
	delete from [stg].[_p2p].[transaction_statuses]

	if @selectcount > 0
		insert into [stg].[_p2p].[transaction_statuses] (  [guid]
														  ,[name]
														  ,[code]
														  ,[created_at]
														  ,[updated_at]
														  ,[deleted_at])
		select [guid]
			  ,[name]
			  ,[code]
			  ,[created_at]
			  ,[updated_at]
			  ,[deleted_at] 
		from #transaction_statuses_new

	else 
		insert into [stg].[_p2p].[transaction_statuses] 
		select * from #transaction_statuses_old

commit tran

/*
-------2020-02-20

drop table if exists [stg].[_p2p].[transaction_statuses]
    
BEGIN TRY   
	select * 
	into [stg].[_p2p].[transaction_statuses]
	from  openquery(p2p,'select * from transaction_statuses')
END TRY
BEGIN CATCH
        THROW
END CATCH
*/


-----------------------------------------
-------------------- contracts

drop table if exists #contracts_old
select * into #contracts_old from [stg].[_p2p].[contracts]
 
 begin try
	drop table if exists #contracts_new
 	select s.* into #contracts_new from (select * from openquery(p2p,'select * from contracts')) s
	set @selectcount = isnull((select count(*) from #contracts_new),0);
 end try
 begin catch
	set @selectcount = 0;
 end catch


begin tran
	delete from [stg].[_p2p].[contracts]

	if @selectcount > 0
		insert into [stg].[_p2p].[contracts] (
											   [guid]
											  ,[user_guid]
											  ,[request_guid]
											  ,[sum]
											  ,[payment]
											  ,[payment_principal]
											  ,[payment_interest]
											  ,[last_payment]
											  ,[last_payment_principal]
											  ,[last_payment_interest]
											  ,[created_at]
											  ,[updated_at]
											  ,[deleted_at])
		select [guid]
			  ,[user_guid]
			  ,[request_guid]
			  ,[sum]
			  ,[payment]
			  ,[payment_principal]
			  ,[payment_interest]
			  ,[last_payment]
			  ,[last_payment_principal]
			  ,[last_payment_interest]
			  ,[created_at]
			  ,[updated_at]
			  ,[deleted_at] 
		from #contracts_new --openquery(p2p,'select * from requests')

	else 
		insert into [stg].[_p2p].[contracts] 
		select * from #contracts_old

commit tran

/*
-------2020-02-20
drop table if exists [stg].[_p2p].[contracts]
    
BEGIN TRY   
	select * 
	into [stg].[_p2p].[contracts]
	from  openquery(p2p,'select * from contracts')
END TRY
BEGIN CATCH
        THROW
END CATCH
*/



END



--exec [_Collection].[Collection2DWHLoader]