-- Usage: запуск процедуры с параметрами
-- EXEC [files].[collection_to_KA_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [files].[collection_to_KA_postloader]
	
as
begin
	SET NOCOUNT ON
	SET XACT_ABORT ON
begin  try
select getdate()
	declare @emailList nvarchar(255)= 'dwh112@carmoney.ru; yu.cvetkov@carmoney.ru; sa.sharepov@carmoney.ru'
	declare @emailSubject  nvarchar(255)= FORMATMESSAGE('Результат передачи в КА от %s',format(getdate(), 'dd.MM.yyyy HH:mm:ss'))
	declare @external_id nvarchar(21), @st_date date, @agent_name nvarchar(255)
	declare cur cursor for
	select cast(try_cast([№ договора] as bigint) as nvarchar(30)) as external_id
		,try_cast([Дата передачи] as date) as st_date
		,isnull(ca.AgentName,[КА])  as AgentName 
	
		from files.collection_to_KA_buffer	  t
		left join Stg.[_Collection].[CollectorAgencies] ca
			on (ca.Name = t.[КА]
			or ca.AgentName = t.[КА]
			)
	where [№ договора] is not NULL
	drop table if exists #tResult
	declare @reestrNum int = (select max(reestr) from dwh_new.[dbo].[agent_credits])+1
	create table #tResult
	(
		 [Договор]		nvarchar(255),
		 [Агент]		nvarchar(255),
		 [Дата_передачи]	date,
		 [Статус]		nvarchar(1024)
	 
	)
	OPEN cur

	FETCH NEXT FROM cur
	INTO @external_id, @st_date, @agent_name
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		declare @result nvarchar(1024)
		declare @msg nvarchar(255)
		if not exists(select top(1) 1 from Stg.[_Collection].[CollectorAgencies] t
		where t.AgentName = @agent_name)
		begin
			set @msg = FORMATMESSAGE('Не удалось найти агенство %s в Stg.[_Collection].[CollectorAgencies]', @agent_name)
			;throw 51000, @msg, 16
		end

		declare @t_result  Table 
		(
			External_id nvarchar(21)
			,st_date  date
			,agent_name nvarchar(255)
		)


	   begin try
		begin tran
--		select * from dwh_new.[dbo].[agent_credits] t
		merge dwh_new.[dbo].[agent_credits] t
		using
		(
			select @external_id as external_id
				,@st_date as st_date
				,@agent_name as agent_name
				,@reestrNum	 as reestr
				,dateadd(mm, 3, @st_date) as plan_end_date
		)  s
		on t.[External_id] = s.external_id
			and t.agent_name = s.agent_name
			and t.fact_end_date is null
		when not matched then insert 
		(
			External_id	
			,reestr	
			,st_date	
			,agent_name	
			,plan_end_date	
		)
		values
		(
			External_id	
			,reestr	
			,st_date	
			,agent_name	
			,plan_end_date	
		)
		when matched then update
			set update_at	   = getdate()
		OUTPUT 
				ISNULL(INSERTED.External_id,  DELETED.[External_id]) as External_id
				,ISNULL(INSERTED.st_date,  DELETED.st_date) as st_date
				,ISNULL(INSERTED.agent_name,  DELETED.agent_name)
			into @t_result
		;
		if @@ROWCOUNT>0
			set @result = 'Ок'
		commit tran
	   end try
	   begin catch
		if @@TRANCOUNT>0
			rollback tran
	
		set @result =FORMATMESSAGE('Не удалось добавить договор %s в реест - ошибка %s', @external_id, 	ERROR_MESSAGE())
	   end catch
	   insert into #tResult([Договор], Агент, [Дата_передачи], Статус)
	   select 
		t.External_id
		,r.agent_name
		,r.st_date
		,@result
		from (select @external_id as External_id) t
		left join @t_result r on r.External_id = t.External_id
		FETCH NEXT FROM cur
			INTO @external_id, @st_date, @agent_name
	end
	CLOSE cur
	DEALLOCATE cur

  
	  declare @html_result nvarchar(max)
	  exec LogDb.[dbo].[ConvertQuery2HTMLTable] 
		@SQLQuery ='select * from #tResult',
		@title ='Передача в КА',
		@tableSubject = 'Договора которые передали в КА',
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