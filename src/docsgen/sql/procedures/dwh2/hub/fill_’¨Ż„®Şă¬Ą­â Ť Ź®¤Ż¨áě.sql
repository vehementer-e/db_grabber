create   PROC hub.fill_ТипДокументаНаПодпись
	@mode int = 1
as
begin
	--truncate table hub.ТипДокументаНаПодпись
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ТипДокументаНаПодпись

	if OBJECT_ID ('hub.ТипДокументаНаПодпись') is not NULL
		AND @mode = 1
	begin
		select @rowVersion = isnull((select max(ВерсияДанных)-100 from hub.ТипДокументаНаПодпись), 0x0)
	end

	select distinct 
		GuidТипДокументаНаПодпись = Stg.dbo.getGUIDFrom1C_IDRREF(d.Ссылка)
		,СсылкаТипДокументаНаПодпись = d.Ссылка
		,isDelete = cast(d.ПометкаУдаления as bit)
		,d.Владелец
		,d.Родитель
		,d.ЭтоГруппа
		,d.Наименование
		,d.ВерсияДанных
		--,d.*
		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,spFillName						= @spName
	into #t_ТипДокументаНаПодпись
	from Stg._1cDCMNT.Справочник_ЗначенияСвойствОбъектов as d
	where 1=1
		--and d.ПометкаУдаления = 0x00
		and d.ВерсияДанных >= @rowVersion
		and exists(
			select top(1) 1 
			from  Stg._1cDCMNT.ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения as dop
			where d.Владелец = dop.Ссылка
				and dop.Наименование = N'Тип печатной формы (Файлы)'
		)
		and (
			d.Родитель in (
				0xB81100155D4D107C11E9AFA565EECD62 -- Заем
			)
			or (
					d.Родитель = 0x00
					--эти документы есть в Stg._LK.[file]
				and d.Наименование in (
					'Информация об условиях предоставления микрозайма',
					'Общие условия договора микрозайма'
				)
			)
		)

	if OBJECT_ID('hub.ТипДокументаНаПодпись') is null
	begin
		select top(0)
			GuidТипДокументаНаПодпись,
			СсылкаТипДокументаНаПодпись,
			isDelete,
			Владелец,
			Родитель,
			ЭтоГруппа,
			Наименование,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		into hub.ТипДокументаНаПодпись
		from #t_ТипДокументаНаПодпись

		alter table hub.ТипДокументаНаПодпись
			alter column GuidТипДокументаНаПодпись uniqueidentifier not null

		ALTER TABLE hub.ТипДокументаНаПодпись
			ADD CONSTRAINT PK_ТипДокументаНаПодпись PRIMARY KEY CLUSTERED (GuidТипДокументаНаПодпись)
	end
	
	--begin tran
		merge hub.ТипДокументаНаПодпись t
		using #t_ТипДокументаНаПодпись s
			on t.GuidТипДокументаНаПодпись = s.GuidТипДокументаНаПодпись
		when not matched then insert
		(
			GuidТипДокументаНаПодпись,
			СсылкаТипДокументаНаПодпись,
			isDelete,
			Владелец,
			Родитель,
			ЭтоГруппа,
			Наименование,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidТипДокументаНаПодпись,
			s.СсылкаТипДокументаНаПодпись,
			s.isDelete,
			s.Владелец,
			s.Родитель,
			s.ЭтоГруппа,
			s.Наименование,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных <> s.ВерсияДанных
			OR @mode = 0
		then update SET
			--t.GuidТипДокументаНаПодпись = s.GuidТипДокументаНаПодпись,
			t.СсылкаТипДокументаНаПодпись = s.СсылкаТипДокументаНаПодпись,
			t.isDelete = s.isDelete,
			t.Владелец = s.Владелец,
			t.Родитель = s.Родитель,
			t.ЭтоГруппа = s.ЭтоГруппа,
			t.Наименование = s.Наименование,
			t.ВерсияДанных = s.ВерсияДанных,
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
