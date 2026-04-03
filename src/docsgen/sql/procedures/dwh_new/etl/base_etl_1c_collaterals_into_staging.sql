-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	airflow etl 1c_collaterals_into_staging
-- exec etl.base_etl_1c_collaterals_into_staging '2021.12.07','2021.12.17 23:59:59'
-- select * from dwh_new_dev.staging.collaterals
-- before first run 
--					select *  into dwh_new_dev.staging.collaterals from dwh_new.staging.collaterals where 1=0
-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_collaterals_into_staging]
	 @start_date datetime
	,@end_date datetime
AS
BEGIN
	
	SET NOCOUNT ON;
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	--log
	declare @params nvarchar(1024)
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ') 
									as nvarchar(32))+'<br />'
				+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ') 
								 as nvarchar(32))
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
  
begin try

/** etl from airflow*/

	delete from staging.collaterals where request_date >=@start_date


	drop table if exists #rq


	select-- top 100
		Номер external_id,
		dateadd(yy, -2000, Дата) as request_date ,
		ma.Наименование brand,
		mo.Наименование model,

		ts.Наименование vehicle_type,
		Год year,
		concat(СерияПТС , ' ',
		НомерПТС) pts ,
		РыночнаяСтоимостьАвтоНаМоментОценки market_price,
		r.VIN vin,
		li.Наименование liquidity,
		concat(СерияПаспорта, ' ',
		НомерПаспорта ) passport_number,
		 r.Ссылка as external_link
		 into #rq
	from [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r 
	left join [prodsql02].[mfo].[dbo].Справочник_ГП_МаркаАвтомобиля ma on r.Марка = ma.Ссылка
	left join [prodsql02].[mfo].[dbo].Справочник_ГП_МодельАвтомобиля mo on r.Модель = mo.Ссылка
	left join [prodsql02].[mfo].[dbo].Справочник_ГП_ЛиквидностьТС li on r.ЛиквидностьТС = li.Ссылка
	left join [prodsql02].[mfo].[dbo].Справочник_ВидТСнаПечать ts on r.ВидТС_НаПечать = ts.Ссылка
	where  r.Дата  >= dateadd(year,2000,@start_date) and r.Дата<= dateadd(year,2000,@end_date)
	and  r.ПометкаУдаления<>0x01 /**добавлено 07-05-2019 */



	insert into staging.collaterals

	select 

	external_id,
		 request_date ,
		 brand,
		 model,

		isnull(vehicle_type, f_ts.Name) vehicle_type,
		r.year,
		 pts ,
		 market_price,
		 r.vin,
		liquidity,
		passport_number,
	  external_link
	 from #rq r
	--DWH-943
	left join stg.[_fedor].[core_ClientRequest] f_cr on f_cr.Number = r.external_id COLLATE SQL_Latin1_General_CP1_CI_AS
	left join stg._fedor.core_ClientAssetTs f_cats on f_cats.Id = f_cr.IdAsset
	left join stg.[_fedor].[dictionary_TsCategory] f_ts on f_ts.Id = f_cats.IdTsCategory


	
/** etl from airflow*/

-- удаляем дубли
	;with collaterals as (
	SELECT  [external_id]
		  ,[request_date]
		  ,[brand]
		  ,[model]
		  ,[vehicle_type]
		  ,[year]
		  ,[pts]
		  ,[market_price]
		  ,[vin]
		  ,[liquidity]
		  ,[passport_number]
		  ,[external_link]
		  ,rn=row_number() over (partition by [external_id]
											  ,[request_date]
											  ,[brand]
											  ,[model]
											  ,[vehicle_type]
											  ,[year]
											  ,[pts]
											  ,[market_price]
											  ,[vin]
											  ,[liquidity]
											  ,[passport_number]
											  ,[external_link]
											  order by (select null))
	  FROM [dwh_new].[staging].[collaterals]
	  ) delete from collaterals where rn>1


--log result
   declare @result nvarchar(100)
   set @result=N' ROWCOUNT='		 +format(@@ROWCOUNT,'0')
	exec LogDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
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
