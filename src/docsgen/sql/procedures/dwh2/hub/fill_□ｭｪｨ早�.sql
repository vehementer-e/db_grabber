/*
exec hub.fill_БанкиСБП
*/
CREATE   PROC [hub].[fill_БанкиСБП]
	@mode int = 1,
	@isDebug int = 0
as
begin
	--truncate table hub.БанкиСБП
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.БанкиСБП') is not null
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) - 100 from hub.БанкиСБП), 0x0)
	end

	drop table if exists #t_БанкиСБП

	select distinct 
		GuidБанкиСБП = cast(dbo.getGUIDFrom1C_IDRREF(v.Ссылка) as uniqueidentifier),
		СсылкаБанкиСБП = v.Ссылка,
		isDelete = cast(v.ПометкаУдаления as bit),
		--
		Наименование,
		ИдентификаторEcomPay,
		ПорядковыйНомер,
		Аббревиатура,
		НациональноеНаименование,
		Активность,
		ВнешнийGUID,
		ДатаИзменения,
		ДатаИзмененияМиллисекунды,
		ДатаСоздания,
		ДатаСозданияМиллисекунды,
		Описание,
		ИдентификаторУчастникаСБП = isnull(ИдентификаторУчастникаСБП, ''),
		--
		ВерсияДанных = cast(v.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_БанкиСБП
	--SELECT *,v.ВерсияДанных
	from Stg._1cMDS.Справочник_БанкиСБП AS v
	where v.ВерсияДанных > @rowVersion

	if @isDebug = 1
	begin
		drop table if exists ##t_БанкиСБП
		SELECT * INTO ##t_БанкиСБП FROM #t_БанкиСБП
	end

	if OBJECT_ID('hub.БанкиСБП') is null
	begin
	
		select top(0)
			GuidБанкиСБП,
			СсылкаБанкиСБП,
			isDelete,
			Наименование,
			ИдентификаторEcomPay,
			ПорядковыйНомер,
			Аббревиатура,
			НациональноеНаименование,
			Активность,
			ВнешнийGUID,
			ДатаИзменения,
			ДатаИзмененияМиллисекунды,
			ДатаСоздания,
			ДатаСозданияМиллисекунды,
			Описание,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName,
			ИдентификаторУчастникаСБП
		into hub.БанкиСБП
		from #t_БанкиСБП

		alter table hub.БанкиСБП
			alter column GuidБанкиСБП uniqueidentifier not null

		ALTER TABLE hub.БанкиСБП
			ADD CONSTRAINT PK_БанкиСБП PRIMARY KEY CLUSTERED (GuidБанкиСБП)

		create index ix_СсылкаБанкиСБП
		on hub.БанкиСБП(СсылкаБанкиСБП)
	end
	
	begin tran
		if @mode = 0 begin
			delete v from hub.БанкиСБП as v
		end
	
		merge hub.БанкиСБП t
		using #t_БанкиСБП s
			on t.GuidБанкиСБП = s.GuidБанкиСБП
		when not matched then insert
		(
			GuidБанкиСБП,
			СсылкаБанкиСБП,
			isDelete,
			Наименование,
			ИдентификаторEcomPay,
			ПорядковыйНомер,
			Аббревиатура,
			НациональноеНаименование,
			Активность,
			ВнешнийGUID,
			ДатаИзменения,
			ДатаИзмененияМиллисекунды,
			ДатаСоздания,
			ДатаСозданияМиллисекунды,
			Описание,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName,
			ИдентификаторУчастникаСБП
		) values
		(
			s.GuidБанкиСБП,
			s.СсылкаБанкиСБП,
			s.isDelete,
			s.Наименование,
			s.ИдентификаторEcomPay,
			s.ПорядковыйНомер,
			s.Аббревиатура,
			s.НациональноеНаименование,
			s.Активность,
			s.ВнешнийGUID,
			s.ДатаИзменения,
			s.ДатаИзмененияМиллисекунды,
			s.ДатаСоздания,
			s.ДатаСозданияМиллисекунды,
			s.Описание,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ИдентификаторУчастникаСБП
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
			OR @mode = 0
		then update SET
			t.СсылкаБанкиСБП = s.СсылкаБанкиСБП,
			t.isDelete = s.isDelete,
			t.Наименование = s.Наименование,
			t.ИдентификаторEcomPay = s.ИдентификаторEcomPay,
			t.ПорядковыйНомер = s.ПорядковыйНомер,
			t.Аббревиатура = s.Аббревиатура,
			t.НациональноеНаименование = s.НациональноеНаименование,
			t.Активность = s.Активность,
			t.ВнешнийGUID = s.ВнешнийGUID,
			t.ДатаИзменения = s.ДатаИзменения,
			t.ДатаИзмененияМиллисекунды = s.ДатаИзмененияМиллисекунды,
			t.ДатаСоздания = s.ДатаСоздания,
			t.ДатаСозданияМиллисекунды = s.ДатаСозданияМиллисекунды,
			t.Описание = s.Описание,
			t.ВерсияДанных = s.ВерсияДанных,
			t.updated_at = s.updated_at,
			t.ИдентификаторУчастникаСБП = s.ИдентификаторУчастникаСБП
			;
	commit tran
	

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
