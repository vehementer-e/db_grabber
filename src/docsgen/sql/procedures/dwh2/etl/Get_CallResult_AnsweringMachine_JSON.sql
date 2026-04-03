--exec etl.[Get_CallResult_AnsweringMachine_JSON] @env = 'prod'
/*
exec sp_executesql N'etl.Get_CallResult_AnsweringMachine_JSON @env = @P1',N'@P1 varchar(8000)','prod'
update NaumenDbReport.dbo.dm_call_auto_answer 
	set communication_id = null
where communication_id is NOT null
select COUNT(1) from NaumenDbReport.dbo.dm_call_auto_answer t 
where t.communication_id is NOT null
*/
CREATE PROC [etl].[Get_CallResult_AnsweringMachine_JSON]
	@env  nvarchar(255)= 'uat'
	,@isDebug int = 0
	WITH EXECUTE AS OWNER
as
begin
	set nocount ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)
	--declare @env  nvarchar(255)= 'uat'
	declare @batchRow int
		=	case @env 
			when 'uat' then 1e5
			when 'prod' then 1e5
			else 1 
		end
	,@type nvarchar(255) = 'interactions' --'callAnswerings'
	,@answeringType nvarchar(255) = 'answeringMachine'
	,@eventName nvarchar(255) = '3202 - Звонок завершился с результатом авто-ответчик'
	drop table if exists #t_data
	
	select top(0) 
		client_number
		,attempt_start
		,answeringType
		
		,communication_id
	into #t_data
	from NaumenDbReport.dbo.dm_call_auto_answer

	if  @env = 'prod'
	begin
		insert into #t_data
		(
			client_number
			,attempt_start
			,answeringType
			,communication_id
		)
		select 
			client_number
			,attempt_start
			,answeringType
		
			,communication_id = NEWID()
		from (
		--select top(1) --test
		select top(@batchRow) 
			client_number
			,attempt_start
			,nRow = ROW_NUMBER() over(partition by client_number order by attempt_start  desc)
			,answeringType =answeringType
			from NaumenDbReport.dbo.dm_call_auto_answer
			where (attempt_start >= dateadd(DAY, -90, cast(getdate() AS date)) --исправили с 30дней 
				or updated_at >= dateadd(DAY, -90, cast(getdate() AS date)) --испавили с 30дней
				)
			and lcrm_channel = 'CPA нецелевой'
			and answeringType = @answeringType
			and (
				(communication_id is  null)
				)
			--and answeringType = 'answeringMachine'
			--дата attempt_start не более 30 дней
		
			order by attempt_start desc
			) t
		where nRow = 1
	end
	if  @env = 'uat'
	begin
		insert into #t_data
		(
			client_number
			,attempt_start
			,answeringType
			,communication_id
		)
		select 
			client_number
			,attempt_start
			,answeringType
			,communication_id = NEWID()
		from (
		select top(@batchRow) 
			client_number
			,attempt_start
			,nRow = ROW_NUMBER() over(partition by client_number order by attempt_start  desc)
			,answeringType =answeringType
		from NaumenDbReport.dbo.dm_call_auto_answer
		where (attempt_start >= dateadd(DAY, -90, cast(getdate() AS date)) --исправили с 30дней 
			or updated_at >= dateadd(DAY, -90, cast(getdate() AS date)) --испавили с 30дней
			)
		and lcrm_channel = 'CPA нецелевой'
		and answeringType = @answeringType
			and client_number in (
				'9272617639'
				,'9536719170'
				,'9961219316'
				,'9969428079'
			)
			) t
		where t.nRow = 1
		union
		select 	client_number
			,attempt_start
			,answeringType
			,communication_id = NEWID()
		from (
		select top(@batchRow) 
			client_number
			,attempt_start
			,nRow = ROW_NUMBER() over(partition by client_number order by attempt_start  desc)
			,answeringType =answeringType
		from NaumenDbReport.dbo.dm_call_auto_answer
		where (attempt_start >= dateadd(DAY, -90, cast(getdate() AS date)) --исправили с 30дней 
			or updated_at >= dateadd(DAY, -90, cast(getdate() AS date)) --испавили с 30дней
			)
		and lcrm_channel = 'CPA нецелевой'
		and answeringType = @answeringType
		) t
		where nRow = 1
	end



	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_data
		SELECT * INTO ##t_data FROM #t_data AS D
	END

	select json = (
		SELECT
			m.meta
			,'data.id'							= t.call_id
			,'data.type'						= @type
			,'data.relationships.event'			= [relationships.events].json
			,'data.relationships.resultCall'	= [relationships.resultCalls].json
			,'included'				= 
			JSON_QUERY(concat('['
				, CONCAT_WS(','
					, [included.resultCalls].json
					, [included.events].json
				)
				,']'
				))

		FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
		)
	from (
		SELECT 
			call_id = cast(hashbytes('SHA2_256', D.client_number) as uniqueidentifier)
			,*
		FROM #t_data AS D
		) AS t
	outer apply Stg.etl.tvf_GetInteractionsEvents(@eventName) AS InteractionsEvent
	OUTER APPLY
		(
				select meta = JSON_QUERY((select 
					'guid'							= cast(t.communication_id as nvarchar(36))
					,'time.publish'					=  DATEDIFF(s, '1970-01-01 00:00:00', getdate())
					,'publisher.code'				= 'DWH'
					,'links.documentation.contract' = 'https://wiki.carmoney.ru/x/rsguB'
					,'links.documentation.jsonAPI'	= 'https://wiki.carmoney.ru/x/tUo6Ag'
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES 
				))
		) AS M
	outer apply
	(
		select json=JSON_QUERY((select 
					'data.type'	= 'events'
					,'data.id'	= InteractionsEvent.Id
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER,  INCLUDE_NULL_VALUES 
				))
	) [relationships.events]

	outer apply
	(
		select json=JSON_QUERY((select 
					'data.type'	= 'resultCalls'
					,'data.id'	= t.call_id
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER,  INCLUDE_NULL_VALUES 
				))
	) [relationships.resultCalls]

	OUTER APPLY (
		select json = JSON_QUERY((select 
			'id'								= t.call_id
			,'type'								= 'resultCalls'
			,'attributes.phone'					= cast(t.client_number as nvarchar(10))
			,'attributes.date'					= cast(t.attempt_start as smalldatetime)
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER,  INCLUDE_NULL_VALUES 
	))) [included.resultCalls]

	OUTER APPLY (
		select json = JSON_QUERY((select 
			'id'								= InteractionsEvent.Id
			,'type' 							= 'events'
			,'attributes.name'					= InteractionsEvent.name
			,'attributes.code'					= InteractionsEvent.code
			,'attributes.description'			= InteractionsEvent.description
			,'attributes.isActive'				= 1
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER,  INCLUDE_NULL_VALUES 
	))) [included.events]

	/*	
	select json = (select  			
			m.meta
			,'data.type'						= @type
			,'data.id'							= cast(hashbytes('SHA2_256',client_number) as uniqueidentifier)
			,'data.attributes.phone'			= cast(client_number as nvarchar(10))
			,'data.attributes.date'				= attempt_start
			,'data.attributes.answeringType'	= answeringType
			FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
	from (select * from #t_data
	) t
	OUTER APPLY
		(
				select meta = JSON_QUERY((select 
					'guid'							= cast(communication_id as nvarchar(36))
					,'time.publish'					=  DATEDIFF(s, '1970-01-01 00:00:00', getdate())
					,'publisher.code'				= 'DWH'
					,'links.documentation.contract' = 'https://wiki.carmoney.ru/x/rsguB'
					,'links.documentation.jsonAPI'	= 'https://wiki.carmoney.ru/x/tUo6Ag'
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES 
				))
		) AS M
	*/
	--if @env = 'prod'
	

	IF @isDebug = 1 BEGIN
		RETURN 0
	END
	
	if @env = 'prod'
	begin
	begin tran
		update t	
			set	t.communication_id = s.communication_id
				,communication_send_date = getdate()
		from #t_data s
		inner join NaumenDbReport.dbo.dm_call_auto_answer t 
			on t.client_number =  s.client_number
			and t.communication_id is null
	commit tran
	end
	
	
	/*
	
	*/

	
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback
	 ;throw
end catch
end