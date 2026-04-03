--exec hub.fill_БКИ_НФ_События @mode = 0
--exec hub.fill_БКИ_НФ_События @mode = 1
CREATE   PROC hub.fill_БКИ_НФ_События
	@mode int = 1
as
begin
	--truncate table hub.БКИ_НФ_События
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_БКИ_НФ_События

	if OBJECT_ID ('hub.БКИ_НФ_События') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.БКИ_НФ_События), 0x0)
	end

	select distinct 
		GuidБКИ_НФ_События = cast([dbo].[getGUIDFrom1C_IDRREF](БКИ_НФ_События.Ссылка) as uniqueidentifier),
		ВерсияДанных = cast(БКИ_НФ_События.ВерсияДанных AS binary(8)),
		isDelete = cast(БКИ_НФ_События.ПометкаУдаления as bit),
		БКИ_НФ_События.Код,
		БКИ_НФ_События.Наименование,
		НеУдалятьПриПересчете = cast(БКИ_НФ_События.НеУдалятьПриПересчете as bit),
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP
		,[spFillName]						= @spName
	into #t_БКИ_НФ_События
	from Stg._1cCMR.Справочник_БКИ_НФ_События AS БКИ_НФ_События
	where БКИ_НФ_События.ВерсияДанных > @rowVersion


	-- Добавить вручную события, которых нет в _1cCMR.Справочник_БКИ_НФ_События
	insert #t_БКИ_НФ_События
	select 
		GuidБКИ_НФ_События = cast(hashbytes('SHA2_256', a.Код) AS uniqueidentifier),
		ВерсияДанных = 0x0,
		isDelete = 0,
		a.Код,
		a.Наименование,
		НеУдалятьПриПересчете = 0,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP
		,spFillName = @spName
	from (
		select t.Код, t.Наименование
		from (values
				--('3.1', 'нет описания'),
				('3.4', 'Выгрузка заявок'),
				('4.2', 'нет описания')
				--('3.3', 'нет описания')
			) t(Код, Наименование)
		where 1=1
			--уже не добавлены
			and not exists(
				select top(1) 1
				from hub.БКИ_НФ_События as h
				where h.Код = t.Код
			)
			--не появились в справочнике CRM
			and not exists(
				select top(1) 1
				from #t_БКИ_НФ_События as h
				where h.Код = t.Код
			)
		) as a

	if OBJECT_ID('hub.БКИ_НФ_События') is null
	begin
		select top(0)
			GuidБКИ_НФ_События,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			НеУдалятьПриПересчете,
			created_at,
			updated_at,
			spFillName
		into hub.БКИ_НФ_События
		from #t_БКИ_НФ_События

		alter table hub.БКИ_НФ_События
			alter column GuidБКИ_НФ_События uniqueidentifier not null

		ALTER TABLE hub.БКИ_НФ_События
			ADD CONSTRAINT PK_БКИ_НФ_События PRIMARY KEY CLUSTERED (GuidБКИ_НФ_События)
	end
	
	begin tran
		--удалить события, добавленные вручную в hub.БКИ_НФ_События
		--если в справочнике Stg._1cCMR.Справочник_БКИ_НФ_События
		--появилось описание этих событий
		delete t
		from hub.БКИ_НФ_События as t
			inner join #t_БКИ_НФ_События as s
				on s.Код = t.Код
		where s.Код in ('3.4', '4.2')

		merge hub.БКИ_НФ_События t
		using #t_БКИ_НФ_События s
			on t.GuidБКИ_НФ_События = s.GuidБКИ_НФ_События
		when not matched then insert
		(
			GuidБКИ_НФ_События,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			НеУдалятьПриПересчете,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidБКИ_НФ_События,
			s.ВерсияДанных,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.НеУдалятьПриПересчете,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
			OR @mode = 0
		then update SET
			t.ВерсияДанных = s.ВерсияДанных,
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.НеУдалятьПриПересчете = s.НеУдалятьПриПересчете,
			--t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
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
