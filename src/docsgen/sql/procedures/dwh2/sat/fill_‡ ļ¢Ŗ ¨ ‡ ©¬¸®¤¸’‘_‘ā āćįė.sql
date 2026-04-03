
--[sat].[fill_ЗаявкаНаЗаймПодПТС_Статусы] 0x96C82D3D529EC75A474506B9ADA6EDAE
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_Статусы
	@mode int = 1, -- 0 - full, 1 - increment, 2 - из списка
	@СсылкаЗаявки binary(16) = NULL
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_Статусы
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at date = '1900-01-01'
	declare @min_status_dt date, @max_status_dt date

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_Статусы
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_Статусы') is not null
		AND @mode = 1
	begin
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = cast(isnull(dateadd(YEAR, 2000, dateadd(DAY, -100, max(S.updated_at))), '1900-01-01') AS date)
		FROM sat.ЗаявкаНаЗаймПодПТС_Статусы AS S
	end


	-- ДатаПоследнейЗаписиСтатуса
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(
		СсылкаЗаявки binary(16),
		GuidЗаявки nvarchar(36)
	)

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
				СсылкаЗаявки = СтатусыЗаявок.Заявка,
				GuidЗаявки = cast(dbo.getGUIDFrom1C_IDRREF(СтатусыЗаявок.Заявка) as uniqueidentifier)
			FROM Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
			WHERE СтатусыЗаявок.ДатаПоследнейЗаписиСтатуса >= @updated_at
		END
	END

	CREATE INDEX IX1 ON #t_Заявки(СсылкаЗаявки)
	CREATE INDEX IX2 ON #t_Заявки(GuidЗаявки)

	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,
		A.ДатаСтатуса,
		GuidСтатусаЗаявки					= cast([dbo].[getGUIDFrom1C_IDRREF](A.Статус) as uniqueidentifier),
		A.СтатусЗаявки,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ЗаявкаНаЗаймПодПТС_Статусы
	--SELECT *
	FROM (
		SELECT 
			СсылкаЗаявки = СтатусыЗаявок.Заявка,
			ДатаСтатуса = dateadd(YEAR, -2000, СтатусыЗаявок.Период),
			СтатусыЗаявок.Статус,
			СтатусЗаявки = СправочникСтатусы.Наименование,
			rn = row_number() OVER(
				PARTITION BY СтатусыЗаявок.Заявка, СправочникСтатусы.Наименование
				ORDER BY СтатусыЗаявок.Период --время статусов нужно брать минимальное --DESC
				)
		FROM #t_Заявки AS T
			INNER JOIN Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
				ON СтатусыЗаявок.Заявка = T.СсылкаЗаявки
			INNER JOIN Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS СправочникСтатусы
				ON СправочникСтатусы.Ссылка = СтатусыЗаявок.Статус
		) AS A
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.СсылкаЗаявки = A.СсылкаЗаявки
	WHERE A.rn = 1

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_Статусы') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			ДатаСтатуса,
			GuidСтатусаЗаявки,
			СтатусЗаявки,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_Статусы
		from #t_ЗаявкаНаЗаймПодПТС_Статусы

		alter table sat.ЗаявкаНаЗаймПодПТС_Статусы
			alter column GuidЗаявки uniqueidentifier not null

		alter table sat.ЗаявкаНаЗаймПодПТС_Статусы
			alter column GuidСтатусаЗаявки uniqueidentifier not null

		--ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_Статусы
		--	ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_Статусы PRIMARY KEY CLUSTERED (GuidЗаявки, СтатусЗаявки)
		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_Статусы
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_Статусы PRIMARY KEY CLUSTERED (GuidЗаявки, GuidСтатусаЗаявки)

		CREATE INDEX ix_updated_at
		ON sat.ЗаявкаНаЗаймПодПТС_Статусы(updated_at) INCLUDE(СсылкаЗаявки)
	end
	
	begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_Статусы t
		using #t_ЗаявкаНаЗаймПодПТС_Статусы s
			on t.GuidЗаявки = s.GuidЗаявки
			AND t.GuidСтатусаЗаявки = s.GuidСтатусаЗаявки
			--AND t.СтатусЗаявки = s.СтатусЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			ДатаСтатуса,
			GuidСтатусаЗаявки,
			СтатусЗаявки,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.ДатаСтатуса,
			s.GuidСтатусаЗаявки,
			s.СтатусЗаявки,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.ДатаСтатуса, '1900-01-01') <> isnull(s.ДатаСтатуса, '1900-01-01')
				OR t.СтатусЗаявки <> s.СтатусЗаявки
				--OR t.ВерсияДанных != s.ВерсияДанных
			)
		then update SET
			t.СсылкаЗаявки = s.СсылкаЗаявки,
			t.ДатаСтатуса = s.ДатаСтатуса,
			t.СтатусЗаявки = s.СтатусЗаявки,
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
		--DWH-374 только если произошло обновление за большой период
		select 
			@min_status_dt = min(t.ДатаСтатуса),
			@max_status_dt = max(t.ДатаСтатуса)
		from #t_ЗаявкаНаЗаймПодПТС_Статусы as t

		--if datediff(day, @min_status_dt, @max_status_dt) >= 5
		--begin 
			DROP TABLE IF EXISTS #t_Deleted
			CREATE TABLE #t_Deleted(GuidЗаявки nvarchar(36), GuidСтатусаЗаявки nvarchar(36))

			DELETE T
			OUTPUT Deleted.GuidЗаявки, Deleted.GuidСтатусаЗаявки INTO #t_Deleted
			FROM sat.ЗаявкаНаЗаймПодПТС_Статусы AS T
				INNER JOIN #t_Заявки AS R
					ON R.GuidЗаявки = T.GuidЗаявки
				LEFT JOIN #t_ЗаявкаНаЗаймПодПТС_Статусы AS S
					ON T.GuidЗаявки = S.GuidЗаявки
					AND T.GuidСтатусаЗаявки = S.GuidСтатусаЗаявки
			WHERE S.GuidСтатусаЗаявки IS NULL
		
			--актуализировать updated_at для пересчета sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
			IF EXISTS(SELECT TOP(1) 1 FROM #t_Deleted)
			BEGIN
				UPDATE T
				SET T.updated_at = getdate()
				FROM sat.ЗаявкаНаЗаймПодПТС_Статусы AS T
					INNER JOIN #t_Deleted AS D
						ON D.GuidЗаявки = T.GuidЗаявки

				insert tmp.log_sat_ЗаявкаНаЗаймПодПТС_Статусы(
					log_event, GuidЗаявки, GuidСтатусаЗаявки
				)
				select 
					log_event = 'D', 
					D.GuidЗаявки, 
					D.GuidСтатусаЗаявки
				FROM #t_Deleted AS D
			END
		--end

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
