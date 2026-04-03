
-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	airflow etl 1c_credits_into_staging 
-- exec etl.base_etl_1c_credits_into_staging  '20190201','20190225 23:59:59'
-- select * from dwh_new_dev.staging.requests
-- before first run 
--					select *  into dwh_new_dev.staging.credits from dwh_new.staging.credits where 1=0

-- =============================================
CREATE PROCEDURE [etl].[base_etl_1c_credits_into_staging]
	 @start_date datetime
	,@end_date datetime
AS
BEGIN
	  --new comment
	SET NOCOUNT ON
  ;
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
	delete from  staging.credits where credit_date  >=@start_date
	insert into staging.credits
	select
		Номер external_id, 
		dateadd(yy, -2000, Дата) as credit_date, 
		--dateadd(yy, -2000, ДатаПодписания) as sign_date, 
		Сумма amount,
		Срок term ,
		cp.Наименование as product,
		dokred.id prelending,
		concat(СерияПаспорта, ' ',
		НомерПаспорта ) passport_number,
		c.Заявка as external_link,
		insurance_value = c.[СуммаДополнительныхУслуг]
	from [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] c
	left join (
		select g1.id, g2.Представление ,  g2.Ссылка from staging.prelending g1 
		left join [prodsql02].[mfo].[dbo].Перечисление_ВидыДокредитования g2 on g1.name = g2.Представление
	) dokred on  dokred.Ссылка = c."Докредитование "
	inner join [prodsql02].[mfo].[dbo].Справочник_ГП_КредитныеПродукты cp on cp.Ссылка = c.КредитныйПродукт
	where dateadd(yy, -2000, Дата)  >= @start_date and dateadd(yy, -2000, Дата)<= @end_date
	-- добавлено 15-04-2019
	and c.[ПометкаУдаления]<>0x01

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
