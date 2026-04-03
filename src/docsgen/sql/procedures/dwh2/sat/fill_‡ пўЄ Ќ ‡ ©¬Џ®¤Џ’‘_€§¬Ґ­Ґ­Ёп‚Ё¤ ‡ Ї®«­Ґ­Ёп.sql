
--[sat].[fill_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения] 0x96C82D3D529EC75A474506B9ADA6EDAE
CREATE   PROC sat.fill_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
	@СсылкаЗаявки binary(16) = NULL,
	@mode int = 1 -- 0 - full, 1 - increment, 2 - из списка
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at date = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения') is not null
		AND @mode = 1
	begin
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = cast(isnull(dateadd(YEAR, 2000, dateadd(DAY, -10, max(S.updated_at))), '1900-01-01') AS date)
		FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS S
	end


	-- ДатаПоследнейЗаписиСтатуса
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(
		СсылкаЗаявки binary(16),
		GuidЗаявки nvarchar(36)
	)

	DROP TABLE IF EXISTS #t_Deleted
	CREATE TABLE #t_Deleted(GuidЗаявки nvarchar(36))

	--1 
	IF @СсылкаЗаявки IS NOT NULL BEGIN
		INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
		SELECT DISTINCT 
			СсылкаЗаявки = СтатусыЗаявок.Заявка,
			GuidЗаявки = cast(dbo.getGUIDFrom1C_IDRREF(СтатусыЗаявок.Заявка) as uniqueidentifier)
		FROM Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
		WHERE СтатусыЗаявок.Заявка = @СсылкаЗаявки
	END
	ELSE BEGIN
		IF @mode = 2 BEGIN
			--из списка
			INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
			SELECT DISTINCT 
				СсылкаЗаявки = СтатусыЗаявок.Заявка,
				GuidЗаявки = cast(dbo.getGUIDFrom1C_IDRREF(СтатусыЗаявок.Заявка) as uniqueidentifier)
			FROM Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
				INNER JOIN dwh2.dbo.СписокЗаявокДляЗагрузкиВDataVault AS Список
					ON Список.СсылкаЗаявки = СтатусыЗаявок.Заявка
		END
		ELSE BEGIN
			--@mode in (0,1)
			INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
			SELECT DISTINCT 
				СсылкаЗаявки = H.Заявка,
				GuidЗаявки = cast(dbo.getGUIDFrom1C_IDRREF(H.Заявка) as uniqueidentifier)
			FROM Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS H
			WHERE H.ДатаИзменения >= @updated_at
		END
	END

	CREATE INDEX IX1 ON #t_Заявки(СсылкаЗаявки)
	CREATE INDEX IX2 ON #t_Заявки(GuidЗаявки)

	select distinct
		R.СсылкаЗаявки,
		R.GuidЗаявки,
		A.ДатаИзменения,
		GuidВидЗаполненияЗаявокНаЗаймПодПТС = cast(dbo.getGUIDFrom1C_IDRREF(A.ВидЗаполнения) as uniqueidentifier),
		GuidСтатусЗаявкиПодЗалогПТС = cast(dbo.getGUIDFrom1C_IDRREF(A.Статус) as uniqueidentifier),
		GuidОфис = cast(dbo.getGUIDFrom1C_IDRREF(A.Офис) as uniqueidentifier),
		GuidCRMАвтор = cast(dbo.getGUIDFrom1C_IDRREF(A.Автор) as uniqueidentifier),
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
	--SELECT *
	FROM (
		SELECT 
			СсылкаЗаявки = H.Заявка,
			ДатаИзменения = dateadd(YEAR, -2000, H.ДатаИзменения),
			H.ВидЗаполнения,
			H.Статус,
			H.Офис,
			H.Автор,
			rn = row_number() OVER(
				PARTITION BY H.Заявка, H.ДатаИзменения
				ORDER BY getdate()
				)
		FROM #t_Заявки AS T
			INNER JOIN Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS H
				ON H.Заявка = T.СсылкаЗаявки
		WHERE H.ДатаИзменения IS NOT NULL
		) AS A
		INNER JOIN hub.Заявка AS R
			ON R.СсылкаЗаявки = A.СсылкаЗаявки
	WHERE A.rn = 1

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения') is null
	begin
		select top(0)
			СсылкаЗаявки,
			GuidЗаявки,
			ДатаИзменения,
			GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			GuidСтатусЗаявкиПодЗалогПТС,
			GuidОфис,
			GuidCRMАвтор,
			created_at,
			updated_at,
			spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
		from #t_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения

		alter table sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
			alter column GuidЗаявки uniqueidentifier not null

		alter table sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
			alter column ДатаИзменения datetime not null

		--ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
		--	ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения PRIMARY KEY CLUSTERED (GuidЗаявки, СтатусЗаявки)
		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения 
			PRIMARY KEY CLUSTERED (GuidЗаявки, ДатаИзменения)

		CREATE INDEX ix_updated_at
		ON sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения(updated_at) INCLUDE(СсылкаЗаявки)
	end
	
	begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения t
		using #t_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения s
			on t.GuidЗаявки = s.GuidЗаявки
			AND t.ДатаИзменения = s.ДатаИзменения
		when not matched then insert
		(
			СсылкаЗаявки,
			GuidЗаявки,
			ДатаИзменения,
			GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			GuidСтатусЗаявкиПодЗалогПТС,
			GuidОфис,
			GuidCRMАвтор,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.СсылкаЗаявки,
			s.GuidЗаявки,
			s.ДатаИзменения,
			s.GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			s.GuidСтатусЗаявкиПодЗалогПТС,
			s.GuidОфис,
			s.GuidCRMАвтор,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			AND (isnull(t.ДатаИзменения, '1900-01-01') <> isnull(s.ДатаИзменения, '1900-01-01')
			OR t.GuidВидЗаполненияЗаявокНаЗаймПодПТС <> s.GuidВидЗаполненияЗаявокНаЗаймПодПТС
			OR t.GuidСтатусЗаявкиПодЗалогПТС <> s.GuidСтатусЗаявкиПодЗалогПТС
			OR t.GuidОфис <> s.GuidОфис
			OR t.GuidCRMАвтор <> s.GuidCRMАвтор
		)
		then update SET
			t.СсылкаЗаявки = s.СсылкаЗаявки,
			t.ДатаИзменения = s.ДатаИзменения,
			t.GuidВидЗаполненияЗаявокНаЗаймПодПТС = s.GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			t.GuidСтатусЗаявкиПодЗалогПТС = s.GuidСтатусЗаявкиПодЗалогПТС,
			t.GuidОфис = s.GuidОфис,
			t.GuidCRMАвтор = s.GuidCRMАвтор,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
		--WHEN NOT MATCHED BY SOURCE 
		--	--AND t.GuidЗаявки = s.GuidЗаявки
		--	AND EXISTS(
		--		SELECT TOP(1) 1
		--		FROM #t_Заявки AS R
		--		WHERE R.GuidЗаявки = t.GuidЗаявки
		--		)
		--THEN DELETE
			;

		--удаление статусов, удаленных в источнике
		DELETE T
		OUTPUT Deleted.GuidЗаявки INTO #t_Deleted
		FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS T
			INNER JOIN #t_Заявки AS R
				ON R.GuidЗаявки = T.GuidЗаявки
			LEFT JOIN #t_ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS S
				ON T.GuidЗаявки = S.GuidЗаявки
				AND T.ДатаИзменения = S.ДатаИзменения
		WHERE S.GuidЗаявки IS NULL
		
		--актуализировать updated_at для пересчета sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
		IF EXISTS(SELECT TOP(1) 1 FROM #t_Deleted)
		BEGIN
			UPDATE T
			SET T.updated_at = getdate()
			FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияВидаЗаполнения AS T
				INNER JOIN #t_Deleted AS D
					ON D.GuidЗаявки = T.GuidЗаявки
		END

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
