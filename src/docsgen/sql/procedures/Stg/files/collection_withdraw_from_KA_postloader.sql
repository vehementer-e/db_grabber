-- Usage: запуск процедуры с параметрами
-- EXEC [files].[collection_withdraw_from_KA_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [files].[collection_withdraw_from_KA_postloader]
	
as
begin
	SET NOCOUNT ON
	SET XACT_ABORT ON
begin  try
	declare @emailList nvarchar(255)= 'dwh112@carmoney.ru; yu.cvetkov@carmoney.ru; sa.sharepov@carmoney.ru'
	declare @emailSubject  nvarchar(255)= FORMATMESSAGE('Реузльтат отзыва из КА от %s',format(getdate(), 'dd.MM.yyyy HH:mm:ss'))
	declare @external_id nvarchar(21), @fact_end_date date
	declare cur cursor for
	select distinct cast(
	
	try_cast([Номер КД] as bigint) as nvarchar(30)) as external_id
		,try_cast([Дата отзыва] as date) as fact_end_date
		from files.withdraw_from_KA_buffer
	where [Номер КД] is not NULL

	
	drop table if exists #tResult
	create table #tResult
	(
		 [Договор]		nvarchar(255),
		 [Агент]		nvarchar(255),
		 [Дата_Отзыва]	date,
		 [Статус]		nvarchar(1024)
	 
	)
	OPEN cur

	FETCH NEXT FROM cur
	INTO @external_id, @fact_end_date

	WHILE @@FETCH_STATUS = 0
	BEGIN
		declare @result nvarchar(1024)
		declare @msg nvarchar(255)
		declare @t_result  Table 
		(
			External_id nvarchar(21)
			,fact_end_date  date
			,agent_name nvarchar(255)
		)
	   begin try
		begin tran
		merge dwh_new.[dbo].[agent_credits] t
		using
		(
			select @external_id as external_id
				,@fact_end_date as fact_end_date
		)  s
		on t.[External_id] = s.external_id
			and t.[fact_end_date] is null
		when matched then update
			set [fact_end_date] = @fact_end_date
				,update_at = getdate()
			OUTPUT 
				ISNULL(INSERTED.External_id,  DELETED.[External_id]) as External_id
				,ISNULL(INSERTED.fact_end_date,  DELETED.fact_end_date) as fact_end_date
				,ISNULL(INSERTED.agent_name,  DELETED.agent_name)
			into @t_result
		;
		if @@ROWCOUNT>0
			set @result = 'Ок'
		else 
		begin
			set @msg =	FORMATMESSAGE('Договор %s не найден. либо дата отзыва уже проставлена', @external_id)
			;throw 51000,@msg,1
		end
		commit tran
	   end try
	   begin catch
		if @@TRANCOUNT>0
			rollback tran
	
		set @result =FORMATMESSAGE('Обновление договора %s завершилось с ошибкой %s', @external_id, 	ERROR_MESSAGE())
	   end catch
	   insert into #tResult([Договор], Агент, Дата_Отзыва, Статус)
	   select 
		t.External_id
		,r.agent_name
		,r.fact_end_date
		,@result
		from (select @external_id as External_id) t
		left join @t_result r on r.External_id = t.External_id
		FETCH NEXT FROM cur
		INTO @external_id, @fact_end_date
	end
	CLOSE cur
	DEALLOCATE cur

  
	  declare @html_result nvarchar(max)
	  exec LogDb.[dbo].[ConvertQuery2HTMLTable] 
		@SQLQuery ='select * from #tResult',
		@title ='Отзыв из КА',
		@tableSubject = 'Договора который отозвали из КА',
		@isDebug = 0,
		@html_result  = @html_result out
	
		EXEC msdb.dbo.sp_send_dbmail  
							@profile_name = 'Default',  
							@recipients = @emailList,  
							@body = @html_result,  
							@body_format='HTML', 
							@subject = @emailSubject 
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end