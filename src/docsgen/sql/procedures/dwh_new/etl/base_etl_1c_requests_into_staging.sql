-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	airflow etl 1c_requests_into_staging
-- exec etl.base_etl_1c_requests_into_staging '20201208','20201218 23:59:59'
-- select * from dwh_new_dev.staging.requests
-- before first run 
--					select *  into dwh_new_dev.staging.requests from dwh_new.staging.requests where 1=0
--					select *  into dwh_new_dev.staging.prelending from dwh_new.staging.prelending
--					select *  into dwh_new_dev.staging.chanels from dwh_new.staging.chanels
-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_requests_into_staging]
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
  --select * from  staging.requests
/** etl from airflow*/
	delete from staging.requests where request_date >=@start_date
	insert into staging.requests(
	   [external_id]
      ,[request_date]
      ,[amount]
      ,[initial_amount]
      ,[product]
      ,[term]
      ,[region]
      ,[point_of_sale]
      ,[prelending]
      ,[passport_number]
      ,[vin]
      ,[leaving_address]
      ,[chanel]
      ,[income]
      ,[LCRM_ID]
      ,[external_link]
      ,[method_of_issuing]
      ,[market_price]
      ,[valuation_price]
      ,[recommend_price]
      ,[risk_criteria]
      ,risk_visa)
      select cast(Номер as nvarchar(20))              as external_id  
       , dateadd(yy, -2000, Дата)                 as request_date 
       , Сумма                                       amount
       , ПервичнаяСумма                           as initial_amount
       , cast(cp.Наименование as nvarchar(100))   as product
       , Срок                                     as term
       , cast(Регион as nvarchar(100))            as region 
       --Статус,
	     , cast(pos.Наименование  as nvarchar(70))  as point_of_sale
	     , dokred.id                                   prelending --нет справочника
	     , cast(concat(СерияПаспорта, ' ',НомерПаспорта ) as nvarchar(11)) passport_number
       , cast(VIN as nvarchar(17)) as vin
       , АдресПроживания as leaving_address
       , chanel.id  as chanel -- нет справочника
	     , СуммаДоходов as income
       , cast(LCRM_ID as nvarchar(10))	
       , r.Ссылка as external_link
       , cast(moi.Имя as varchar(255)) method_of_issuing
       , isnull(cast([РыночнаяСтоимостьАвтоНаМоментОценки] as float),0) as market_price
       , isnull(cast([ОценочнаяCтоимостьАвто]              as float),0) as valuation_price
       , isnull(cast([РекомендСуммаКВыдаче] as float),0) as recommend_price
       , cast(r.[ГП_представлениекритериевриска] as varchar(2000)) as risk_criteria
       , r.[ГП_ПредставлениеКритериевРиска]
    from [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r
   inner join [prodsql02].[mfo].[dbo].Справочник_ГП_КредитныеПродукты cp on cp.Ссылка = r.КредитныйПродукт
    left join (select g1.id
                    , g2.Представление 
                    , g2.Ссылка 
                 from staging.prelending g1 
                left join [prodsql02].[mfo].[dbo].Перечисление_ВидыДокредитования g2 on g1.name = g2.Представление 
              ) dokred on  dokred.Ссылка = r."Докредитование "
    left join (
               select g1.id
                    , g2.Представление 
                    , g2.Ссылка 
                 from staging.chanels g1 
                 left join [prodsql02].[mfo].[dbo].Перечисление_ГП_МестаСозданияЗаявки g2 on g1.name = g2.Представление 
              ) chanel on chanel.Ссылка = r.МестоСозданияЗаявки
    left join [prodsql02].[mfo].[dbo].Справочник_ГП_Офисы pos on pos.Ссылка = r.Точка
    left join [prodsql02].[mfo].dbo.Перечисление_СпособыВыдачиЗаймов moi on r.СпособВыдачиЗайма = moi.Ссылка
   where  r.Дата  >= dateadd(year,2000,@start_date) and r.Дата<=dateadd(year,2000, @end_date)

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
