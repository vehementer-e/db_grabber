-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	airflow etl 1c_rh_into_staging
-- exec etl.base_etl_1c_rh_into_staging  '20190301','20190324 23:59:59'
-- select * from dwh_new_dev.staging.requests_history
-- before first run 
--					select *  into dwh_new_dev.staging.requests_history from dwh_new.staging.requests_history where 1=0

-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_rh_into_staging]
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
  
begin try
	/** etl from airflow*/
	insert into staging.requests_history(
		   [external_id]
		  ,[creation_date]
		  ,[verifier]
		  ,[status]
		  ,[reject_reason]
		  ,[external_link]
		  ,[position]
	)
	select --top 100   
		r.Номер external_id ,
		dateadd(yy, -2000, rh.Период) creation_date ,
		u.Наименование verifier,
		s.Наименование status,
		rr.Наименование reject_reason,
		 r.Ссылка as external_link,
		 d.Наименование position
	from [prodsql02].[mfo].[dbo].РегистрСведений_ГП_СписокЗаявок rh
	inner join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r on rh.Заявка = r.Ссылка
	inner join [prodsql02].[mfo].[dbo].Справочник_ГП_СтатусыЗаявок s on  rh.Статус = s.Ссылка
	left join [prodsql02].[mfo].[dbo].Справочник_ПричиныОтказа rr on rr.Ссылка = rh.ПричинаОтказа
	left join [prodsql02].[mfo].[dbo].Справочник_Пользователи u on rh.Исполнитель = u.Ссылка
	left join [prodsql02].[mfo].[dbo].[Справочник_ДолжностиОрганизаций] d on d.Ссылка = u.Должность
	where rh.Период >= dateadd(year,2000,@start_date)--'{{params.start_date | replace("201", "401")}}' 
	and r.Дата<=dateadd(year,2000,@end_date)--'{{params.end_date | replace("201", "401")}}'
	and rh.Период<= dateadd(year,2000,@end_date)--'{{params.end_date | replace("201", "401")}}'
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
