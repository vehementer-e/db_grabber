-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	airflow etl 1c_persons_into_staging
-- exec etl.base_etl_1c_persons_into_staging '20190201','20190225 23:59:59'
-- select * from dwh_new_dev.staging.persons
-- before first run^ select * into dwh_new_dev.staging.persons from dwh_new.staging.persons where 1=0
--					 select * into dwh_new_dev.staging.gender from dwh_new.staging.gender
--					 select * into dwh_new_dev.staging.family_status  from dwh_new.staging.family_status 
--					 select * into dwh_new_dev.staging.education from dwh_new.staging.education
-- =============================================
CREATE   PROCEDURE [etl].[base_etl_1c_persons_into_staging]
	@start_date datetime
	,@end_date datetime
AS
BEGIN
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	SET NOCOUNT ON;
	--log
	declare @text nvarchar(max)=N''
  declare @error_description nvarchar(4000)=N''
  declare @params nvarchar(1024)
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ') 
									as nvarchar(32))+'<br />'
				+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ') 
								 as nvarchar(32))
	exec LogDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
  begin try
  
   delete from staging.persons where request_date >=@start_date ;
   --DWH-1083 Если есть договор, надо брать данные с договора
	insert into staging.persons
	select    
		r.Номер as external_id  ,
	
		isnull(dateadd(yy, -2000, d.Дата), 	dateadd(yy, -2000, r.Дата)) as request_date ,
		last_name = isnull(d.Фамилия, r.Фамилия),
		first_name = isnull(d.Имя, r.Имя) ,
		middle_name =isnull(d.Отчество , r.Отчество),
		birth_date = isnull(
		iif(year(d.ДатаРождения)>3000, dateAdd(year, -2000, d.ДатаРождения), d.ДатаРождения),
	
		iif(year(r.ДатаРождения) >3900, dateadd(yy, -2000, r.ДатаРождения), r.ДатаРождения )),
		r.Регион region ,
		g.id  gender, --проверить перечисление 
		iif(d.СерияПаспорта is not null, concat(d.СерияПаспорта, ' ', d.НомерПаспорта ),
			concat(r.СерияПаспорта, ' ', r.НомерПаспорта )) passport_number,
		f.id family_status,
		e.id education, 
		isnull(d.ТелефонМобильный , r.ТелефонМобильный) mobile_phone ,
		r.Ссылка as external_link
	from [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r
	left join (    
		select g1.id, g2.Представление ,  g2.Ссылка from staging.gender g1 
		left join [prodsql02].[mfo].[dbo].Перечисление_ПолФизическихЛиц g2 on g1.name = g2.Представление 
	) g on r.Пол = g.Ссылка
	left join (
		select g1.id, g2.Представление ,  g2.Ссылка from staging.family_status g1 
		left join [prodsql02].[mfo].[dbo].Перечисление_ГП_СемейноеПоложение g2 on g1.name = g2.Представление 
	)f on r.СемейноеПоложение = f.Ссылка
	left join (    
		select g1.id, g2.Представление ,  g2.Ссылка from staging.education g1 
		left join [prodsql02].[mfo].[dbo].Перечисление_ГП_Образование g2 on g1.name = g2.Представление 
	) e on r.Образование = e.Ссылка
	LEFT JOIN stg._1cMFO.Документ_ГП_Договор d on d.Заявка = r.Ссылка
	where dateadd(yy, -2000, r.Дата)  >= @start_date and dateadd(yy, -2000, r.Дата)<= @end_date

	declare @result nvarchar(100)
	set @result=N' ROWCOUNT='		 +format(@@ROWCOUNT,'0')
	exec LogDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
                   
end try
begin catch
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
--log result

   

END
