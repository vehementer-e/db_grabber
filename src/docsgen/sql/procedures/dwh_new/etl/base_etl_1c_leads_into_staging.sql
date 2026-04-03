-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 27-02-2019
-- Description:	airflow etl 1c_leads_into_staging 
--
-- exec etl.base_etl_1c_leads_into_staging  
-- select * from  staging.crm_leads;
--
-- before first run 
--					select *  into dwh_new_dev.staging.crm_leads from dwh_new.staging.crm_leads where 1=0

-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_leads_into_staging]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	--log
	declare @params nvarchar(1024)=''
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
  
begin try
/** etl from airflow*/
	truncate table staging.crm_leads;
	insert into staging.crm_leads
	select 
		Ссылка external_link, 
		dateadd(yy, -2000, Дата) lead_date, 
		КаналПервичногоИнтереса primary_interest_chanel,
		ИсточникПервичногоИНтереса_Тип primary_interest_source_type,
		ИсточникПервичногоИНтереса_ТипСсылки primary_interest_source_link_type,
		ИсточникПервичногоИНтереса_Ссылка primary_interest_source_link,
		UTMМетка utm_label,
		ИмяДомена domain,
		КаналПривлеченияСтрокой attraction_chanel_str,
		Метка_utm_source utm_source,
		Метка_utm_medium utm_medium ,
		Метка_utm_campaign utm_campaign,
		Метка_utm_content utm_content,
		Метка_utm_term utm_term,
		Метка_gclid gclid,
		Метка_yclid yclid,
		Метка_Yandex_CID yandex_cid,
		Метка_Google_CID google_cid,
		Метка_openstat openstat,
		Метка_http_referrer http_referrer,
		Метка_Start_URL start_url,
		Метка_Form_URL form_url,
		Метка_pm_source pm_source,
		Метка_pm_position pm_position,
		Метка_LeadId lead_id,
		ПотенциальныйКлиент potentional_client
	from---- [C1-VSR-SQL04].[crm].[dbo].[Документ_CRM_Заявка] r 
	stg._1cCRM.[Документ_CRM_Заявка] r 


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
