--sat.fill_lf_request @Guids = '681239AC-ABDE-4FF9-8C6D-000033CD1B90'
CREATE PROC sat.fill_lf_request
	@mode int = 1 -- 0 - full, 1 - increment
	,@Guids nvarchar(max) = null 
	,@isDebug int = 0
as
begin
	--truncate table sat.lf_request
	SELECT @isDebug = isnull(@isDebug, 0)
	set @Guids = nullif(@Guids, '')
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0
	DECLARE @int_int_updated_at int 

	-- updated_at = -30 дней назад
	SELECT @int_int_updated_at = datediff(SECOND, '1970-01-01', getdate()) - 30*24*60*60

	--declare @rowVersion binary(8) = 0x0
	--DECLARE @ВерсияДанных_CRM binary(8) = 0x0, @int_updated_at_LK datetime = '2000-01-01', @RowVersion_FEDOR binary(8) = 0x0

	if OBJECT_ID ('sat.lf_request') is not NULL
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from sat.lf_request AS H
	END

	-- список id заявок для загрузки
	drop table if exists #t_lf_request_id

	SELECT TOP(0)
		СсылкаЗаявки = dbo.get1CIDRREF_FromGUID(try_cast(R.id AS uniqueidentifier))
		,НомерЗаявки = R.number
		,GuidЗаявки = try_cast(R.id AS uniqueidentifier)
	INTO #t_lf_request_id
	from Stg._LF.request AS R

	CREATE INDEX ix_GuidЗаявки ON #t_lf_request_id(GuidЗаявки)

	IF @Guids is NOT NULL BEGIN
		INSERT #t_lf_request_id(СсылкаЗаявки, НомерЗаявки, GuidЗаявки)
		SELECT
			СсылкаЗаявки = dbo.get1CIDRREF_FromGUID(try_cast(R.id AS uniqueidentifier))
			,НомерЗаявки = R.number
			,GuidЗаявки = try_cast(R.id AS uniqueidentifier)
		from Stg._LF.request AS R
		where R.id in (select trim(value) from string_split(@Guids, ','))
	END
	ELSE BEGIN
		INSERT #t_lf_request_id(СсылкаЗаявки, НомерЗаявки, GuidЗаявки)
		SELECT
			СсылкаЗаявки = dbo.get1CIDRREF_FromGUID(try_cast(R.id AS uniqueidentifier))
			,НомерЗаявки = R.number
			,GuidЗаявки = try_cast(R.id AS uniqueidentifier)
		from Stg._LF.request AS R
		where R.updated_at >= @int_updated_at

		--добавить заявки, которых нет в sat.lf_request
		INSERT #t_lf_request_id(СсылкаЗаявки, НомерЗаявки, GuidЗаявки)
		SELECT
			СсылкаЗаявки = dbo.get1CIDRREF_FromGUID(try_cast(R.id AS uniqueidentifier))
			,НомерЗаявки = R.number
			,GuidЗаявки = try_cast(R.id AS uniqueidentifier)
		from Stg._LF.request AS R
			INNER JOIN (
				SELECT id from Stg._lf.request --WHERE updated_at > @int_int_updated_at 
				EXCEPT
				SELECT GuidЗаявки from sat.lf_request --WHERE int_updated_at > @int_int_updated_at 
			) AS X
			ON R.id = X.id
		WHERE NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_lf_request_id T
				WHERE T.GuidЗаявки = R.id
			)
	END

	drop table if exists #t_lf_request

	select distinct 
		СсылкаЗаявки = I.СсылкаЗаявки
		,НомерЗаявки = I.НомерЗаявки
		,GuidЗаявки = I.GuidЗаявки
		--,R.original_lead_id
		--,R.marketing_lead_id
		,request_date = cast(R.date as datetime2(0))
		,R.requested_sum
		,R.approved_sum
		,R.sum_contract
		,R.days
		--,R.status_id --hub dwh2.hub.СтатусыЗаявокПодЗалогПТС
		,status_date = cast(R.status_date as datetime2(0))
		--,R.product_type_id --hub ?
		,R.mobile_phone
		,R.last_name
		,R.first_name
		,R.second_name
		,FIO = concat(R.last_name, ' ', R.first_name, ' ', R.second_name)
		--,R.credit_product_id --hub
		,R.source
		,int_created_at = R.created_at
		,int_updated_at = R.updated_at
		,R.created_at_time
		,R.updated_at_time
		--,R.UPDATED_BY
		--,R.UPDATED_DT
		,R.publishTime
		,R.publishDateTime
		--
		,created_at = CURRENT_TIMESTAMP
		,updated_at = CURRENT_TIMESTAMP
		,spFillName = @spName

		,Link_Guid_original_lead = try_cast(nullif(R.original_lead_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_marketing_lead = try_cast(nullif(R.marketing_lead_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_status = try_cast(nullif(R.status_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_product_type = try_cast(nullif(R.product_type_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_credit_product = try_cast(nullif(R.credit_product_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
	into #t_lf_request
	from #t_lf_request_id AS I
		INNER JOIN Stg._LF.request AS R
			ON R.id = I.GuidЗаявки

	CREATE INDEX ix1 ON #t_lf_request(GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_lf_request
		SELECT * INTO ##t_lf_request FROM #t_lf_request AS T
		--RETURN 0
	END

	--deduplicate
	;with cte_duplicate as  (
		select nRow =  Row_Number() over(partition by GuidЗаявки order by updated_at desc), *
		from #t_lf_request
	)
	delete from cte_duplicate
	where nRow>1


	if OBJECT_ID('link.lf_request_stage') is null
	begin
		create table link.lf_request_stage(
			Id					uniqueidentifier not null primary key default newid(),
			GuidЗаявки			uniqueidentifier not null,
			updated_at_time		datetime,
			LinkName			nvarchar(255),
			LinkGuid			uniqueidentifier,
			TargetColName		nvarchar(255),
			created_at			datetime not null default getdate()
		)
		create index ix_LinkName on link.lf_request_stage(LinkName)

		ALTER TABLE link.lf_request_stage
		ADD CONSTRAINT PK_lf_request_stage
		PRIMARY KEY CLUSTERED (Id)
	END
    
	--линки из lf_request
	insert into link.lf_request_stage(
		GuidЗаявки
		,updated_at_time
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidЗаявки,
		updated_at_time,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_lf_request
	CROSS APPLY (
    VALUES 
          (Link_Guid_original_lead, 'link.lf_request_original_lead', 'guid_original_lead')
          ,(Link_Guid_marketing_lead, 'link.lf_request_marketing_lead', 'guid_marketing_lead')
          ,(Link_Guid_product_type, 'link.lf_request_product_type', 'guid_product_type')
		  ,(Link_Guid_status, 'link.lf_request_status', 'guid_status')
		  ,(Link_Guid_credit_product, 'link.lf_request_credit_product', 'guid_credit_product')
		) t(LinkGuid, LinkName, TargetColName)
		where LinkGuid is not null

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_lf_request_stage
		SELECT * INTO ##t_lf_request_stage FROM link.lf_request_stage
	END

	--заполнение таблиц с линками
	BEGIN TRY
		--последовательный запуск
		EXEC link.exec_fill_link_between_lf_request_and_other

		--параллельный запуск
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_lf_request_and_other'
	END TRY
	BEGIN CATCH
		--??
	END CATCH



	--drop table sat.lf_request
	--create clustered index cix on #t_Заявка(GuidЗаявки)
	if OBJECT_ID('sat.lf_request') is null
	begin
	
		select top(0)
			СсылкаЗаявки,
			НомерЗаявки,
			GuidЗаявки,
			--original_lead_id,
			--marketing_lead_id,
			request_date,
			requested_sum,
			approved_sum,
			sum_contract,
			days,
			status_date,
			mobile_phone,
			last_name,
			first_name,
			second_name,
			FIO,
			source,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			publishTime,
			publishDateTime,
			created_at,
			updated_at,
			spFillName
		into sat.lf_request
		from #t_lf_request

		alter table sat.lf_request
			alter column СсылкаЗаявки binary(16) not null

		--alter table  sat.lf_request
		--	alter column НомерЗаявки nvarchar(14) not null

		alter table sat.lf_request
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.lf_request
			ADD CONSTRAINT PK_sat_lf_request PRIMARY KEY CLUSTERED (GuidЗаявки)

		CREATE INDEX ix_int_updated_at
		ON sat.lf_request(int_updated_at)
	end 
	
	--begin tran
		merge sat.lf_request AS t
		using #t_lf_request AS s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
			НомерЗаявки,
			GuidЗаявки,
			--original_lead_id,
			--marketing_lead_id,
			request_date,
			requested_sum,
			approved_sum,
			sum_contract,
			days,
			status_date,
			mobile_phone,
			last_name,
			first_name,
			second_name,
			FIO,
			source,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			publishTime,
			publishDateTime,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.СсылкаЗаявки,
			s.НомерЗаявки,
			s.GuidЗаявки,
			--s.original_lead_id,
			--s.marketing_lead_id,
			s.request_date,
			s.requested_sum,
			s.approved_sum,
			s.sum_contract,
			s.days,
			s.status_date,
			s.mobile_phone,
			s.last_name,
			s.first_name,
			s.second_name,
			s.FIO,
			s.source,
			s.int_created_at,
			s.int_updated_at,
			s.created_at_time,
			s.updated_at_time,
			s.publishTime,
			s.publishDateTime,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				isnull(t.int_updated_at, 0) <> isnull(s.int_updated_at, 0)
				OR @mode = 0
			)
		then update SET
			t.СсылкаЗаявки = s.СсылкаЗаявки,
			t.НомерЗаявки = s.НомерЗаявки,
			--t.original_lead_id = s.original_lead_id,
			--t.marketing_lead_id = s.marketing_lead_id,
			t.request_date = s.request_date,
			t.requested_sum = s.requested_sum,
			t.approved_sum = s.approved_sum,
			t.sum_contract = s.sum_contract,
			t.days = s.days,
			t.status_date = s.status_date,
			t.mobile_phone = s.mobile_phone,
			t.last_name = s.last_name,
			t.first_name = s.first_name,
			t.second_name = s.second_name,
			t.FIO = s.FIO,
			t.source = s.source,
			t.int_created_at = s.int_created_at,
			t.int_updated_at = s.int_updated_at,
			t.created_at_time = s.created_at_time,
			t.updated_at_time = s.updated_at_time,
			t.publishTime = s.publishTime,
			t.publishDateTime = s.publishDateTime,
			--t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			;
	--commit tran

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch


end
