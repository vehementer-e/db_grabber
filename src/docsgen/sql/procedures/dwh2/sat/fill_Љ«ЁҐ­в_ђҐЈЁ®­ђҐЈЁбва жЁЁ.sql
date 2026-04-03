
CREATE PROC sat.fill_Клиент_РегионРегистрации
	@mode int = 1
as
begin
	--truncate table sat.Клиент_РегионРегистрации
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	DECLARE @portion_id uniqueidentifier = newid()

	drop table if exists #t_Клиент_РегионРегистрации

	if OBJECT_ID ('sat.Клиент_РегионРегистрации') is not null
		and @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) - 1000 from sat.Клиент_РегионРегистрации), 0x0)
	end

	select distinct
		GuidКлиент = cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Ссылка) as uniqueidentifier),
		СсылкаКлиент = Партнеры.Ссылка,
		РегионРегистрации = РегионРегистрации.Наименование,
		GMTРегионРегистрации = РегионРегистрации.CRM_ВремяПоГринвичу_GMT,
		НовыйРегион = isnull(cast(MDS_Регионы.ЭтоНовыйРегион as int), 0),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(Партнеры.ВерсияДанных AS binary(8))
	into #t_Клиент_РегионРегистрации
	--SELECT *
	from Stg._1cCRM.Справочник_Партнеры AS Партнеры
		LEFT JOIN Stg._1cCRM.Справочник_БизнесРегионы AS РегионРегистрации
			ON РегионРегистрации.Ссылка = Партнеры.БизнесРегион
		left join Stg._1cMDS.Справочник_Регионы as MDS_Регионы
			on MDS_Регионы.КодРегиона = РегионРегистрации.КодРегиона
			and MDS_Регионы.ПометкаУдаления = 0x00
			and MDS_Регионы.Активность = 0x01
	where Партнеры.ВерсияДанных >= @rowVersion
		AND РегионРегистрации.Наименование IS NOT NULL

	if OBJECT_ID('sat.Клиент_РегионРегистрации') is null
	begin
		select top(0)
			GuidКлиент,
            СсылкаКлиент,
			РегионРегистрации,
			GMTРегионРегистрации,
			НовыйРегион,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.Клиент_РегионРегистрации
		from #t_Клиент_РегионРегистрации

		alter table sat.Клиент_РегионРегистрации
			alter column GuidКлиент uniqueidentifier not null

		ALTER TABLE sat.Клиент_РегионРегистрации
			ADD CONSTRAINT PK_Клиент_РегионРегистрации PRIMARY KEY CLUSTERED (GuidКлиент)
	end

	begin tran
		merge sat.Клиент_РегионРегистрации t
		using #t_Клиент_РегионРегистрации s
			on t.GuidКлиент = s.GuidКлиент
		when not matched then insert
		(
			GuidКлиент,
            СсылкаКлиент,
			РегионРегистрации,
			GMTРегионРегистрации,
			НовыйРегион,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.GuidКлиент,
            s.СсылкаКлиент,
			s.РегионРегистрации,
			s.GMTРегионРегистрации,
			s.НовыйРегион,
            s.created_at,
            s.updated_at,
            s.spFillName,
            s.ВерсияДанных
		)
		when matched and (
				t.ВерсияДанных != s.ВерсияДанных
				or @mode = 0
			)
		then update SET
			t.РегионРегистрации = s.РегионРегистрации,
			t.GMTРегионРегистрации = s.GMTРегионРегистрации,
			t.НовыйРегион = s.НовыйРегион,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных
			;

		--DWH-2923
		/*
		INSERT sat.Клиент_РегионРегистрации_SCD2_stg
		(
			portion_id,
			GuidКлиент,
			СсылкаКлиент,
			date_from,
			date_to,
			РегионРегистрации,
			GMTРегионРегистрации,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных 
		)
		SELECT 
			portion_id = @portion_id,
			R.GuidКлиент,
			R.СсылкаКлиент,
			date_from = cast(getdate() AS date),
			date_to = cast(getdate() AS date),
			R.РегионРегистрации,
			R.GMTРегионРегистрации,
			R.created_at,
			R.updated_at,
			R.spFillName,
			R.ВерсияДанных 
		FROM #t_Клиент_РегионРегистрации AS R

		EXEC sat.fill_Клиент_РегионРегистрации_SCD2
			@portion_id = @portion_id
		*/

		drop table if exists #t_Клиент_РегионРегистрации_SCD2
		SELECT 
			R.GuidКлиент,
			date_from = cast(getdate() AS date),
			B.GuidБизнесРегион
		INTO #t_Клиент_РегионРегистрации_SCD2
		FROM #t_Клиент_РегионРегистрации AS R
			INNER JOIN hub.БизнесРегион AS B
				ON B.Наименование = R.РегионРегистрации

		-- удалить то, что не изменилось
		DELETE s
		FROM #t_Клиент_РегионРегистрации_SCD2 AS s
			INNER JOIN link.v_Клиент_РегионРегистрации_SCD2 AS t
				ON t.GuidКлиент = s.GuidКлиент
				AND s.date_from BETWEEN t.date_from AND t.date_to
				AND t.GuidБизнесРегион = s.GuidБизнесРегион

		-- date_from = дата первой заявки
		-- для новых клиентов, у которых нет записей в link
		UPDATE s
		SET date_from = isnull(T.date_from, '2000-01-01')
		FROM #t_Клиент_РегионРегистрации_SCD2 AS s
			INNER JOIN (
				SELECT 
					H.GuidКлиент,
					date_from = cast(min(R.ДатаЗаявки) AS date)
				FROM #t_Клиент_РегионРегистрации_SCD2 AS H
					LEFT JOIN link.Клиент_Заявка AS L
						ON L.GuidКлиент = H.GuidКлиент
					LEFT JOIN hub.Заявка AS R
						ON R.GuidЗаявки = L.GuidЗаявки
				WHERE NOT EXISTS(
					SELECT TOP(1) 1
					FROM link.v_Клиент_РегионРегистрации_SCD2 AS X
					WHERE X.GuidКлиент = H.GuidКлиент
					)
				GROUP BY H.GuidКлиент
			) AS T
			ON T.GuidКлиент = s.GuidКлиент

		INSERT link.Клиент_stage
		(
			GuidКлиент,
			date_from,
			LinkName,
			LinkGuid,
			TargetColName
		)
		SELECT 
			R.GuidКлиент,
			R.date_from,
			LinkName = 'link.Клиент_РегионРегистрации_SCD2',
			R.GuidБизнесРегион,
			TargetColName = 'GuidБизнесРегион'
		FROM #t_Клиент_РегионРегистрации_SCD2 AS R

		EXEC link.fill_link_between_Клиент_and_other
			@LinkName='link.Клиент_РегионРегистрации_SCD2'
		--// DWH-2923

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
