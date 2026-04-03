/*
exec hub.fill_СпособыВыдачиДенежныхСредств
*/
create   PROC hub.fill_СпособыВыдачиДенежныхСредств
	@mode int = 1,
	@isDebug int = 0
as
begin
	--truncate table hub.СпособыВыдачиДенежныхСредств
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.СпособыВыдачиДенежныхСредств') is not null
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) - 100 from hub.СпособыВыдачиДенежныхСредств), 0x0)
	end

	drop table if exists #t_СпособыВыдачиДенежныхСредств

	select distinct 
		GuidСпособыВыдачиДенежныхСредств = cast(dbo.getGUIDFrom1C_IDRREF(v.Ссылка) as uniqueidentifier),
		СсылкаСпособыВыдачиДенежныхСредств = v.Ссылка,
		isDelete = cast(v.ПометкаУдаления as bit),
		--
		v.Наименование,
		v.КодСпособаВыдачи,
		v.ИдентификаторСпособаВыдачи,
		v.КодМП,
		v.ДоступенВМП,
		v.Описание,
		v.Сортировка,
		v.Активность,
		v.ПредварительняРегистрацияЗалога,
		--
		ВерсияДанных = cast(v.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_СпособыВыдачиДенежныхСредств
	--SELECT *,v.ВерсияДанных
	from Stg._1cCMR.Справочник_СпособыВыдачиДенежныхСредств AS v
	where v.ВерсияДанных > @rowVersion

	if @isDebug = 1
	begin
		drop table if exists ##t_СпособыВыдачиДенежныхСредств
		SELECT * INTO ##t_СпособыВыдачиДенежныхСредств FROM #t_СпособыВыдачиДенежныхСредств
	end

	if OBJECT_ID('hub.СпособыВыдачиДенежныхСредств') is null
	begin
	
		select top(0)
			GuidСпособыВыдачиДенежныхСредств,
			СсылкаСпособыВыдачиДенежныхСредств,
			isDelete,
			Наименование,
			КодСпособаВыдачи,
			ИдентификаторСпособаВыдачи,
			КодМП,
			ДоступенВМП,
			Описание,
			Сортировка,
			Активность,
			ПредварительняРегистрацияЗалога,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		into hub.СпособыВыдачиДенежныхСредств
		from #t_СпособыВыдачиДенежныхСредств

		alter table hub.СпособыВыдачиДенежныхСредств
			alter column GuidСпособыВыдачиДенежныхСредств uniqueidentifier not null

		ALTER TABLE hub.СпособыВыдачиДенежныхСредств
			ADD CONSTRAINT PK_СпособыВыдачиДенежныхСредств PRIMARY KEY CLUSTERED (GuidСпособыВыдачиДенежныхСредств)
	end
	
	begin tran
		if @mode = 0 begin
			delete v from hub.СпособыВыдачиДенежныхСредств as v
		end

		merge hub.СпособыВыдачиДенежныхСредств t
		using #t_СпособыВыдачиДенежныхСредств s
			on t.GuidСпособыВыдачиДенежныхСредств = s.GuidСпособыВыдачиДенежныхСредств
		when not matched then insert
		(
			GuidСпособыВыдачиДенежныхСредств,
			СсылкаСпособыВыдачиДенежныхСредств,
			isDelete,
			Наименование,
			КодСпособаВыдачи,
			ИдентификаторСпособаВыдачи,
			КодМП,
			ДоступенВМП,
			Описание,
			Сортировка,
			Активность,
			ПредварительняРегистрацияЗалога,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidСпособыВыдачиДенежныхСредств,
			s.СсылкаСпособыВыдачиДенежныхСредств,
			s.isDelete,
			s.Наименование,
			s.КодСпособаВыдачи,
			s.ИдентификаторСпособаВыдачи,
			s.КодМП,
			s.ДоступенВМП,
			s.Описание,
			s.Сортировка,
			s.Активность,
			s.ПредварительняРегистрацияЗалога,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
			OR @mode = 0
		then update SET
			t.СсылкаСпособыВыдачиДенежныхСредств = s.СсылкаСпособыВыдачиДенежныхСредств,
			t.isDelete = s.isDelete,
			t.Наименование = s.Наименование,
			t.КодСпособаВыдачи = s.КодСпособаВыдачи,
			t.ИдентификаторСпособаВыдачи = s.ИдентификаторСпособаВыдачи,
			t.КодМП = s.КодМП,
			t.ДоступенВМП = s.ДоступенВМП,
			t.Описание = s.Описание,
			t.Сортировка = s.Сортировка,
			t.Активность = s.Активность,
			t.ПредварительняРегистрацияЗалога = s.ПредварительняРегистрацияЗалога,
			t.ВерсияДанных = s.ВерсияДанных,
			t.updated_at = s.updated_at
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
