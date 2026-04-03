create procedure etl.DataReconciliation
as
begin
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,					''
begin try
		 --Отправка уведомлений если есть расхождение по паспортным данным между мфо и dwh
		 --DWH-756
	drop table if exists #mfo_requests
	select 
		distinct  cast(concat(СерияПаспорта, ' ', НомерПаспорта ) as nvarchar(11)) passport_number, 
		Номер  as external_id  , 
		cast(dateadd(yy, -2000, Дата) as date) as request_date, 
		r.Фамилия last_name, 
		r.Имя first_name, 
		r.Отчество middle_name, 
		case when year(ДатаРождения) <=3900  or year(ДатаРождения)>=4030 then null else  dateadd(yy, -2000, ДатаРождения) end birth_date, 
		r.Ссылка as external_link
		into #mfo_requests
		from [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r
	
	drop table if exists #t_result
	select  ROW_NUMBER() over(partition by p.Id order by r.request_date desc) nRow, 
		p.id as PersonId, 
		p.external_id, 
		(p.first_name + ' ' + p.middle_name + ' ' + p.last_name) as fio, 
		p.passport_number as person_passport_number, 
		r.passport_number as request_passport_number, 
		p.created as person_created, 
		p.birth_date, 
		r.request_date
	into #t_result
	from #mfo_requests r
	inner join [dbo].[persons] p on p.external_link = r.external_link 
		and r.passport_number != p.passport_number

	
	if exists (select top(1) 1 from #t_result )
	  begin
		DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
		SET @tableHTML =  
    
			N'<H1>В БД DWH_NEW есть персоны, укоторых отличаются паспортные данные от данных в [mfo].[dbo].[Документ_ГП_Заявка]</H1>' +  
			N'<H4>Необходимо исправить данные в таблице  [dbo].[persons] Обратить внимание на уникальный ключ по полю passport_number. </H4>' +  
			N'<table border="1">' +  
			N'<tr><th>PersonId</th><th>external_id</th>' +  
			N'<th>fio</th><th>person_passport_number</th><th>request_passport_number</th>' +  
			N'<th>person_created</th><th>birth_date</th><th>request_date</th></tr>' +  
			CAST ( ( SELECT td = PersonId,       '',  
							td = external_id, '',  
							td = fio, '',  
							td = person_passport_number, '',
							td = request_passport_number, '',
							td = person_created, '',
							td = birth_date, '',
							td = request_date
                   
					  from #t_result
					  FOR XML PATH('tr'), TYPE   
			) AS NVARCHAR(MAX) ) +  
			N'</table>' ;  
  
		  select @tableHTML

			EXEC msdb.dbo.sp_send_dbmail @recipients='dwh112@carmoney.ru',  --; Krivotulov@carmoney.ru
				@profile_name = 'Default',  
				@subject = 'Расхождение паспортных данных между DWH_NEW.dbo.persons и [mfo].[dbo].[Документ_ГП_Заявка]',  
				@body = @tableHTML,  
			@body_format = 'HTML' ;  
		end
	drop table if exists #t_result
	drop table if exists #mfo_requests
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