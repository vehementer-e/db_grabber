/*
--drop table hub.СпособВыдачиЗайма
select * from hub.СпособВыдачиЗайма
--TRUNCATE TABLE hub.СпособВыдачиЗайма
exec hub.fill_СпособВыдачиЗайма @mode = 0
exec hub.fill_СпособВыдачиЗайма
*/
CREATE PROC hub.fill_СпособВыдачиЗайма
	@mode int = 1
as
begin
	--truncate table hub.СпособВыдачиЗайма
begin try
	--SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_СпособВыдачиЗайма

	if OBJECT_ID ('hub.СпособВыдачиЗайма') is not null
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.СпособВыдачиЗайма), 0x0)
	end

	select distinct 
		СсылкаСпособВыдачиЗайма = СпособВыдачиЗайма.Ссылка,
		GuidСпособВыдачиЗайма = cast([dbo].[getGUIDFrom1C_IDRREF](СпособВыдачиЗайма.Ссылка) as uniqueidentifier),
		СпособВыдачиЗайма.Код,
		СпособВыдачиЗайма.Наименование,
		СпособВыдачиЗайма.Описание,
		isActive = cast(СпособВыдачиЗайма.Активен as bit),
		isDelete = cast(СпособВыдачиЗайма.ПометкаУдаления as bit),
		ВерсияДанных = cast(СпособВыдачиЗайма.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_СпособВыдачиЗайма
	--SELECT *
	from Stg._1cCRM.Справочник_СпособыВыдачи AS СпособВыдачиЗайма
	--where СпособВыдачиЗайма.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.СпособВыдачиЗайма') is null
	begin
		select top(0)
			СсылкаСпособВыдачиЗайма,
			GuidСпособВыдачиЗайма,
			Код,
			Наименование,
			Описание,
			isActive,
			isDelete,
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into hub.СпособВыдачиЗайма
		from #t_СпособВыдачиЗайма

		alter table hub.СпособВыдачиЗайма
			alter column GuidСпособВыдачиЗайма uniqueidentifier not null

		ALTER TABLE hub.СпособВыдачиЗайма
			ADD CONSTRAINT PK_СпособВыдачиЗайма PRIMARY KEY CLUSTERED (GuidСпособВыдачиЗайма)
	end
	
	--begin tran
		merge hub.СпособВыдачиЗайма t
		using #t_СпособВыдачиЗайма s
			on t.GuidСпособВыдачиЗайма = s.GuidСпособВыдачиЗайма
		when not matched then insert
		(
			СсылкаСпособВыдачиЗайма,
			GuidСпособВыдачиЗайма,
			Код,
			Наименование,
			Описание,
			isActive,
			isDelete,
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаСпособВыдачиЗайма,
			s.GuidСпособВыдачиЗайма,
			s.Код,
			s.Наименование,
			s.Описание,
			s.isActive,
			s.isDelete,
			s.ВерсияДанных,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			AND t.ВерсияДанных <> s.ВерсияДанных
		then update SET
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.Описание = s.Описание,
			t.isActive = s.isActive,
			t.isDelete = s.isDelete,
			t.ВерсияДанных = s.ВерсияДанных,
            --s.created_at,
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
