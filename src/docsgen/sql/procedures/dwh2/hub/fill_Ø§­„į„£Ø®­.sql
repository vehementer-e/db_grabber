CREATE PROC hub.fill_БизнесРегион
	@mode int = 0
as
begin
	--truncate table hub.БизнесРегион
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_БизнесРегион

	if OBJECT_ID ('hub.БизнесРегион') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных)-1000 from hub.БизнесРегион), 0x0)
	end

	select distinct 
		--GuidБизнесРегион = cast([dbo].[getGUIDFrom1C_IDRREF](БизнесРегионы.Ссылка) as uniqueidentifier),
		GuidБизнесРегион = БизнесРегионы.КодФИАС,
		БизнесРегионы.Ссылка,
		ВерсияДанных = cast(БизнесРегионы.ВерсияДанных AS binary(8)),
		isDelete = cast(БизнесРегионы.ПометкаУдаления as bit),
		--БизнесРегионы.ИмяПредопределенныхДанных,
		БизнесРегионы.Родитель,
		БизнесРегионы.Наименование,
		БизнесРегионы.CRM_КодГорода,
		БизнесРегионы.CRM_КодКЛАДР,
		БизнесРегионы.CRM_КодСтраны,
		БизнесРегионы.CRM_Платежеспособность,
		БизнесРегионы.CRM_ЧисленностьНаселения,
		БизнесРегионы.CRM_КодПоКлассификатору,
		БизнесРегионы.CRM_КодОКАТО,
		БизнесРегионы.CRM_ВремяПоГринвичу_GMT,
		--БизнесРегионы.ОбластьДанныхОсновныеДанные,
		БизнесРегионы.КодРегиона,
		НовыйРегион = isnull(cast(MDS_Регионы.ЭтоНовыйРегион as int), 0),
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName						= @spName
	into #t_БизнесРегион
	from Stg._1cCRM.Справочник_БизнесРегионы AS БизнесРегионы
		left join Stg._1cMDS.Справочник_Регионы as MDS_Регионы
			on MDS_Регионы.КодРегиона = БизнесРегионы.КодРегиона
			and MDS_Регионы.ПометкаУдаления = 0x00
			and MDS_Регионы.Активность = 0x01
	where 1=1
		AND БизнесРегионы.ВерсияДанных >= @rowVersion
		AND nullif(trim(БизнесРегионы.КодФИАС),'') IS NOT NULL
		AND try_cast(БизнесРегионы.КодФИАС AS uniqueidentifier) IS NOT NULL
		and БизнесРегионы.ПометкаУдаления = 0x00

	if OBJECT_ID('hub.БизнесРегион') is null
	begin
		select top(0)
			GuidБизнесРегион,
			Ссылка,
			ВерсияДанных,
			isDelete,
			Родитель,
			Наименование,
			CRM_КодГорода,
			CRM_КодКЛАДР,
			CRM_КодСтраны,
			CRM_Платежеспособность,
			CRM_ЧисленностьНаселения,
			CRM_КодПоКлассификатору,
			CRM_КодОКАТО,
			CRM_ВремяПоГринвичу_GMT,
			КодРегиона,
			НовыйРегион,
			created_at,
			updated_at,
			spFillName
		into hub.БизнесРегион
		from #t_БизнесРегион

		alter table hub.БизнесРегион
			alter column GuidБизнесРегион uniqueidentifier not null

		ALTER TABLE hub.БизнесРегион
			ADD CONSTRAINT PK_БизнесРегион PRIMARY KEY CLUSTERED (GuidБизнесРегион)
	end
	
	--begin tran
		merge hub.БизнесРегион t
		using #t_БизнесРегион s
			on t.GuidБизнесРегион = s.GuidБизнесРегион
		when not matched then insert
		(
			GuidБизнесРегион,
			Ссылка,
			ВерсияДанных,
			isDelete,
			Родитель,
			Наименование,
			CRM_КодГорода,
			CRM_КодКЛАДР,
			CRM_КодСтраны,
			CRM_Платежеспособность,
			CRM_ЧисленностьНаселения,
			CRM_КодПоКлассификатору,
			CRM_КодОКАТО,
			CRM_ВремяПоГринвичу_GMT,
			КодРегиона,
			НовыйРегион,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidБизнесРегион,
			s.Ссылка,
			s.ВерсияДанных,
			s.isDelete,
			s.Родитель,
			s.Наименование,
			s.CRM_КодГорода,
			s.CRM_КодКЛАДР,
			s.CRM_КодСтраны,
			s.CRM_Платежеспособность,
			s.CRM_ЧисленностьНаселения,
			s.CRM_КодПоКлассификатору,
			s.CRM_КодОКАТО,
			s.CRM_ВремяПоГринвичу_GMT,
			s.КодРегиона,
			s.НовыйРегион,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных <> s.ВерсияДанных
			OR @mode = 0
		then update SET
			--t.GuidБизнесРегион = s.GuidБизнесРегион,
			t.Ссылка = s.Ссылка,
			t.ВерсияДанных = s.ВерсияДанных,
			t.isDelete = s.isDelete,
			t.Родитель = s.Родитель,
			t.Наименование = s.Наименование,
			t.CRM_КодГорода = s.CRM_КодГорода,
			t.CRM_КодКЛАДР = s.CRM_КодКЛАДР,
			t.CRM_КодСтраны = s.CRM_КодСтраны,
			t.CRM_Платежеспособность = s.CRM_Платежеспособность,
			t.CRM_ЧисленностьНаселения = s.CRM_ЧисленностьНаселения,
			t.CRM_КодПоКлассификатору = s.CRM_КодПоКлассификатору,
			t.CRM_КодОКАТО = s.CRM_КодОКАТО,
			t.CRM_ВремяПоГринвичу_GMT = s.CRM_ВремяПоГринвичу_GMT,
			t.КодРегиона = s.КодРегиона,
			t.НовыйРегион = s.НовыйРегион,
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
