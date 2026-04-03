/*
--drop table hub.Офисы
exec hub.fill_Офисы @mode = 0
exec hub.fill_Офисы
*/
CREATE PROC hub.fill_Офисы
	@mode int = 1
as
begin
	--truncate table hub.Офисы
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Офисы

	if OBJECT_ID ('hub.Офисы') is not null
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.Офисы), 0x0)
	end

	select distinct 
		СсылкаОфис = Офисы.Ссылка,
		GuidОфис = cast([dbo].[getGUIDFrom1C_IDRREF](Офисы.Ссылка) as uniqueidentifier),
		isDelete = cast(Офисы.ПометкаУдаления as bit),
		--Офисы.ИмяПредопределенныхДанных,
		Офисы.Код,
		Офисы.Наименование,
		GuidРодитель = cast([dbo].[getGUIDFrom1C_IDRREF](Офисы.Родитель) as uniqueidentifier),
		Офисы.ТипОфиса,
		ДатаОткрытия = iif(Офисы.ДатаОткрытия > '2001-01-01', dateadd(year, -2000, Офисы.ДатаОткрытия), NULL),
		ДатаЗакрытия = iif(Офисы.ДатаЗакрытия > '2001-01-01', dateadd(year, -2000, Офисы.ДатаЗакрытия), NULL),
		--Офисы.ОбластьДанныхОсновныеДанные,
		--Офисы.DWHInsertedDate,
		--Офисы.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(Офисы.ВерсияДанных AS binary(8))
	into #t_Офисы
	--SELECT *
	from Stg._1cCRM.Справочник_Офисы AS Офисы
	where Офисы.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.Офисы') is null
	begin
		select top(0)
			СсылкаОфис,
			GuidОфис,
            isDelete,
            Код,
            Наименование,
            GuidРодитель,
            ТипОфиса,
            ДатаОткрытия,
            ДатаЗакрытия,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into hub.Офисы
		from #t_Офисы

		alter table hub.Офисы
			alter column GuidОфис uniqueidentifier not null

		ALTER TABLE hub.Офисы
			ADD CONSTRAINT PK_Офисы PRIMARY KEY CLUSTERED (GuidОфис)
	end
	
	--begin tran
		merge hub.Офисы t
		using #t_Офисы s
			on t.GuidОфис = s.GuidОфис
		when not matched then insert
		(
			СсылкаОфис,
			GuidОфис,
            isDelete,
            Код,
            Наименование,
            GuidРодитель,
            ТипОфиса,
            ДатаОткрытия,
            ДатаЗакрытия,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаОфис,
			s.GuidОфис,
            s.isDelete,
            s.Код,
            s.Наименование,
            s.GuidРодитель,
            s.ТипОфиса,
            s.ДатаОткрытия,
            s.ДатаЗакрытия,
            s.created_at,
            s.updated_at,
            s.spFillName,
            s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
            t.isDelete = s.isDelete,
            t.Код = s.Код,
            t.Наименование = s.Наименование,
            t.GuidРодитель = s.GuidРодитель,
            t.ТипОфиса = s.ТипОфиса,
            t.ДатаОткрытия = s.ДатаОткрытия,
            t.ДатаЗакрытия = s.ДатаЗакрытия,
            --s.created_at,
            t.updated_at = s.updated_at,
            t.spFillName = s.spFillName,
            t.ВерсияДанных = s.ВерсияДанных
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
