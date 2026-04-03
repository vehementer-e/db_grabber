-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 27-02-2019
-- Description:	airflow etl 1c_crm_req_into_staging 
--
-- exec etl.base_etl_1c_crm_req_into_staging 
-- select * from  staging.crm_leads
--
-- before first run 
--					select *  into dwh_new_dev.staging.crm_requests from dwh_new.staging.crm_requests where 1=0

-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_crm_req_into_staging]

AS
BEGIN
	
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024)=''

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
  

/** etl from airflow*/
begin try
	truncate table staging.crm_requests

	insert into staging.crm_requests
	select  
		r.Номер external_id,
		dateadd(yy, -2000, r.Дата)as request_date, 
		r.Лид as external_lead_link,
		s.Наименование as status, 
		rr.Наименование as reject_reason , 
		r.Ссылка as external_link 
	from ----[C1-VSR-SQL04].[crm].[dbo].[Документ_ЗаявкаНаЗаймПодПТС] r
	stg._1cCRM.[Документ_ЗаявкаНаЗаймПодПТС] r
	left join 
	----[C1-VSR-SQL04].[crm].[dbo].Справочник_СтатусыЗаявокПодЗалогПТС 
	stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС 
	s on s.ссылка = r.статус

	left join 
	----[C1-VSR-SQL04].[crm].[dbo].Справочник_CRM_ПричиныОтказов 
	stg._1cCRM.Справочник_CRM_ПричиныОтказов 
	rr on rr.Ссылка = r.ПричинаОтказа

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
