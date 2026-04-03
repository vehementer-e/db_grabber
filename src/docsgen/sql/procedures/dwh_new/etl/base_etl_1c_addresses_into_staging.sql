-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 27-02-2019
-- Description:	airflow etl 1c_addresses_into_staging 
--
-- exec etl.base_etl_1c_addresses_into_staging  '20190201 00:00:00','20190225 23:59:59'
-- select * from  staging.addresses
--
-- before first run 
--					select *  into dwh_new_dev.staging.addresses from dwh_new.staging.addresses where 1=0

-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_addresses_into_staging]
	 @start_date datetime
	,@end_date datetime
AS
BEGIN
	
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024)
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ') 
									as nvarchar(32))+'<br />'
				+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ') 
								 as nvarchar(32))
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
  

/** etl from airflow*/
begin try
	delete from staging.addresses where request_date >=@start_date ;
	insert into staging.addresses( external_link, external_id, request_date, region,  residence, registration )
	select 
		Ссылка as external_link,    
		Номер as external_id,
		dateadd(yy, -2000, Дата) as request_date,  
		Регион as  region, 
		cast(АдресПроживания as varchar(max)) as residence,
		cast(АдресРегистрации as varchar(max)) as registration
	from [prodsql02].[mfo].dbo.Документ_ГП_Заявка
	Where (cast(АдресРегистрации as varchar(max)) != '' 
			or cast(АдресПроживания as varchar(max)) != '' 
			or cast(Регион as varchar(max)) !='' )
	and Дата  >= dateadd(year,2000,@start_date) and Дата<= dateadd(year,2000,@end_date)



/** etl from airflow*/


--log result
   declare @result nvarchar(100)
   set @result=N' ROWCOUNT='		 +format(@@ROWCOUNT,'0')
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
END
