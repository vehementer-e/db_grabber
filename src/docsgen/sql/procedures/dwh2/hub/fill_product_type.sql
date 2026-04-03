--EXEC hub.fill_product_type @mode = 0
CREATE   PROC hub.fill_product_type
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.product_type
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--DECLARE @int_updated_at int = 0
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_product_type
	if OBJECT_ID ('hub.product_type') is not null
		AND @mode = 1
	begin
		SELECT 
			--@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
			@rowVersion = isnull(max(H.row_version), 0x0)
		from hub.product_type AS H
	end

	select --distinct 
		guid_product_type = try_cast(T.ВнешнийGUID  AS uniqueidentifier),
		binary_id_product_type = T.Ссылка,
		product_type_name = T.Наименование,
		product_type_code = T.Идентификатор,
		is_need_pts = cast(T.НеобходимостьПТС AS bit),
		min_sum = T.МинимальнаяСумма,
		max_sum = T.МаксимальнаяСумма,
		is_active = cast(T.Активность AS bit),

		--T.ДатаИзменения,
		--T.ДатаИзмененияМиллисекунды,
		--T.ДатаСоздания,
		--T.ДатаСозданияМиллисекунды,
		product_type_desc = T.Описание,
		--T.РеквизитДопУпорядочивания,
		--T.DWHInsertedDate,
		--T.ProcessGUID
		--
		row_version = cast(T.ВерсияДанных AS binary(8)),
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_product_type
	from Stg._1cMDS.Справочник_типыПродуктов AS T
	where T.ВерсияДанных >= @rowVersion
		--AND T.updated_at >= @int_updated_at
		AND try_cast(T.ВнешнийGUID  AS uniqueidentifier) IS NOT NULL

	if OBJECT_ID('hub.product_type') is null
	begin
	
		select top(0)
			guid_product_type,
			binary_id_product_type,
			product_type_name,
			product_type_code,
			is_need_pts,
			min_sum,
			max_sum,
			is_active,
			product_type_desc,
			row_version,
			created_at,
			updated_at,
			spFillName
		into hub.product_type
		from #t_product_type

		alter table hub.product_type
			alter column guid_product_type uniqueidentifier not null

		ALTER TABLE hub.product_type
			ADD CONSTRAINT PK_product_type PRIMARY KEY CLUSTERED (guid_product_type)
	end
	
	--begin tran
		merge hub.product_type t
		using #t_product_type s
			on t.guid_product_type = s.guid_product_type
		when not matched then insert
		(
			guid_product_type,
			binary_id_product_type,
			product_type_name,
			product_type_code,
			is_need_pts,
			min_sum,
			max_sum,
			is_active,
			product_type_desc,
			row_version,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.guid_product_type,
			s.binary_id_product_type,
			s.product_type_name,
			s.product_type_code,
			s.is_need_pts,
			s.min_sum,
			s.max_sum,
			s.is_active,
			s.product_type_desc,
			s.row_version,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				isnull(t.row_version, 0) <> isnull(s.row_version, 0)
				OR @mode = 0
			)
		then update SET
			t.binary_id_product_type = s.binary_id_product_type,
			t.product_type_name = s.product_type_name,
			t.product_type_code = s.product_type_code,
			t.is_need_pts = s.is_need_pts,
			t.min_sum = s.min_sum,
			t.max_sum = s.max_sum,
			t.is_active = s.is_active,
			t.product_type_desc = s.product_type_desc,
			t.row_version = s.row_version,
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
