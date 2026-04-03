-- =======================================================
-- Created: 30.05.2023. А.Никитин
-- Description:	
-- exec dbo.fill_РегистрСведений_АналитическиеПоказателиМФО  @contractGuids = 'B0838374-6E5E-11EE-B812-C8B19D7A5302,1B45A6AC-E989-11E7-814E-00155D01BF07,B0838374-6E5E-11EE-B812-C8B19D7A5302,5D4A2748-6379-11EE-B812-C8B19D7A5302'
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[fill_РегистрСведений_АналитическиеПоказателиМФО] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC [dbo].[fill_РегистрСведений_АналитическиеПоказателиМФО]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0,
	@contractGuid nvarchar(36) = null, --guid договора
	@contractGuids nvarchar(max) = null  --guids договоров
with recompile
AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(255), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @LastPartitionID int
	DECLARE @Rowversion_Lead binary(8), @Rowversion_LeadAndSurvey binary(8)
	DECLARE @DeleteRows int = 0, @InsertRows int = 0, @CountRows int = 0
	DECLARE @DurationSec int, @StartDate_1 datetime = getdate(), @StartDate datetime = getdate()

	SELECT @eventName = 'dbo.fill_РегистрСведений_АналитическиеПоказателиМФО', @eventType = 'info', @SendEmail = 0
	
	set @contractGuids = CONCAT_WS(',', @contractGuid, @contractGuids )
	set @contractGuids = nullif(@contractGuids, '')

	declare @contractS int

	declare @t_contracts table(contractId binary(16) primary key, contractGuid nvarchar(36))
	insert into @t_contracts(contractId, contractGuid)
	
	select distinct 
		contractId = [dbo].[get1CIDRREF_FromGUID](trim(value))
		, contractGuid = trim(value)
	from string_split(@contractGuids, ',')
		select @contractS =count(contractId) from  @t_contracts
				WHERE 1=1
	print @contractS


	BEGIN TRY

		--1
		DROP TABLE IF EXISTS #t_РегистрСведений_АналитическиеПоказателиМФО_temp
		SELECT TOP(0)
			cmr.*,
			Период_date = cast(cmr.Период AS date)
		INTO #t_РегистрСведений_АналитическиеПоказателиМФО_temp
  		FROM _1cCMR.РегистрСведений_АналитическиеПоказателиМФО_temp AS cmr
		
		INSERT #t_РегистрСведений_АналитическиеПоказателиМФО_temp
		SELECT --TOP 100
			cmr.*,
			Период_date = cast(cmr.Период AS date)
  		FROM _1cCMR.РегистрСведений_АналитическиеПоказателиМФО_temp AS cmr 
			--WITH(TablockX)
		where (exists (select top(1) 1 from @t_contracts t where t.contractId = cmr.Договор)
			or @contractGuids is null)

		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_РегистрСведений_АналитическиеПоказателиМФО_temp', @InsertRows, @DurationSec
		END

		CREATE INDEX IX1 ON #t_РегистрСведений_АналитическиеПоказателиМФО_temp(Договор, Период_date)

		--SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INDEX #t_РегистрСведений_АналитическиеПоказателиМФО_temp', @DurationSec
		END




		--2
		DROP TABLE IF EXISTS #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма
		SELECT TOP(0)
			m.[Период]
			, [Договор]
			, [ДатаВозникновенияПросрочки]
			, [КоличествоПолныхДнейПросрочки]
			, [ПросроченнаяЗадолженность]
			, [ДатаПоследнегоПлатежа]
			, [СуммаПоследнегоПлатежа]
			, [Период_date]
		INTO #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма
  		FROM _1cMFO.РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m

		INSERT #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма
		SELECT --TOP 100
			m.[Период]
			, [Договор]
			, [ДатаВозникновенияПросрочки]
			, [КоличествоПолныхДнейПросрочки]
			, [ПросроченнаяЗадолженность]
			, [ДатаПоследнегоПлатежа]
			, [СуммаПоследнегоПлатежа]
			, [Период_date]
		--	Период_date = cast(m.Период AS date)
  		FROM _1cMFO.РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m 
			--WITH(TablockX)
		where 
		(exists (select top(1) 1 from @t_contracts t where t.contractId = m.Договор )
			or @contractGuids is null)
		--(m.Договор =  dbo.get1CIDRREF_FromGUID(@contractGuid) or @contractGuid is null)
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма', @InsertRows, @DurationSec
		END

		CREATE INDEX IX1 ON #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма(Договор, Период_date)

		--SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INDEX #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма', @DurationSec
		END


		--3
		DROP TABLE IF EXISTS #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика
		SELECT TOP(0)
			cmr_new.*,
			Период_date = cast(cmr_new.Период AS date)
		INTO #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика
  		FROM _1cCMR.РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика AS cmr_new
		
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		INSERT #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика
		SELECT --TOP 100
			cmr_new.*,
			Период_date = cast(cmr_new.Период AS date)
  		FROM _1cCMR.РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика AS cmr_new 
			--WITH(TablockX)
		
		where 
		(exists (select top(1) 1 from @t_contracts t where t.contractId = cmr_new.Договор )
			or @contractGuids is null)
	
		

		SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика', @InsertRows, @DurationSec
		END

		CREATE INDEX IX1 ON #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика(Договор, Период_date)

		--SELECT @InsertRows = @@ROWCOUNT
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @StartDate = getdate()

		IF @isDebug = 1 BEGIN
			SELECT 'INDEX #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика', @DurationSec
		END

		--IF @isDebug = 1 BEGIN
		--	RETURN 0
		--END
		if(@contractGuids is null)
		begin
			DROP INDEX IF EXISTS Cl_РегистрСведений_АналитическиеПоказателиМФО_Договор 
			ON _1cCMR.РегистрСведений_АналитическиеПоказателиМФО
		end
		BEGIN TRAN
		if(@contractGuids is null)
			begin
				TRUNCATE TABLE _1cCMR.РегистрСведений_АналитическиеПоказателиМФО
			end
			else
			begin
				delete from _1cCMR.РегистрСведений_АналитическиеПоказателиМФО
				where 
				exists (select top(1) 1 from @t_contracts t where t.contractId = Договор )
			
				--Договор =  dbo.get1CIDRREF_FromGUID(@contractGuid) 
			end
			INSERT INTO _1cCMR.РегистрСведений_АналитическиеПоказателиМФО 
			--WITH(TablockX) -- WITH(TABLOCK)
			(
				[Период]
				,[Регистратор_ТипСсылки]
				,[Регистратор_Ссылка]
				,[НомерСтроки]
				,[Активность]
				,[Договор]
				,[ДатаВозникновенияПросрочки]
				,[ДатаПоследнегоПлатежа]
				,[КоличествоПолныхДнейПросрочки]
				,[ПросроченнаяЗадолженность]
				,[СуммаПоследнегоПлатежа]
				,[РегистраторМФО]
				,[ДатаВозникновенияПросрочкиУМФО]
				,[КоличествоПолныхДнейПросрочкиУМФО]
				,[ОбластьДанныхОсновныеДанные]
			)
			SELECT --TOP 100
				cmr.[Период]
				, cmr.[Регистратор_ТипСсылки]
				, cmr.[Регистратор_Ссылка]
				, cmr.[НомерСтроки]
				, cmr.[Активность]
				, cmr.[Договор]
				, ДатаВозникновенияПросрочки = COALESCE (cmr_new.[ДатаВозникновенияПросрочкиНоваяМетодика], cmr.[ДатаВозникновенияПросрочки]		)
				, cmr.[ДатаПоследнегоПлатежа]
				, [КоличествоПолныхДнейПросрочки]  = COALESCE(cmr_new.[КоличествоПолныхДнейПросрочкиНоваяМетодика], cmr.КоличествоПолныхДнейПросрочки)
				, cmr.[ПросроченнаяЗадолженность]
				, cmr.[СуммаПоследнегоПлатежа]
				, cmr.[РегистраторМФО]
				, ДатаВозникновенияПросрочкиУМФО = 
					CASE 
						WHEN cmr.[Период] >='40190923' 
							THEN cmr.[ДатаВозникновенияПросрочкиУМФО] 
						ELSE isnull(m.ДатаВозникновенияПросрочки,cmr.[ДатаВозникновенияПросрочкиУМФО])
					END
				, КоличествоПолныхДнейПросрочкиУМФО =
					CASE 
						WHEN cmr.[Период] >='40190923' 
							THEN cmr.[КоличествоПолныхДнейПросрочкиУМФО] 
						ELSE isnull(m.КоличествоПолныхДнейПросрочки,cmr.[КоличествоПолныхДнейПросрочкиУМФО]) 
					END
				, cmr.[ОбластьДанныхОсновныеДанные]
  		--	FROM _1cCMR.РегистрСведений_АналитическиеПоказателиМФО_temp AS cmr
				--LEFT JOIN _1cMFO.РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m 
				--	ON cmr.Договор=m.Договор 
				--	AND cast(cmr.Период as date) = cast(m.Период as date)
				--LEFT JOIN _1cCMR.РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика AS cmr_new
				--	ON cmr.Договор=cmr_new.Договор 
				--	AND cast(cmr.Период as date) = cast(cmr_new.Период as date)
  			FROM #t_РегистрСведений_АналитическиеПоказателиМФО_temp AS cmr
				LEFT JOIN #t_РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m 
					ON cmr.Договор=m.Договор 
					AND cmr.Период_date = m.Период_date
				LEFT JOIN #t_РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика AS cmr_new
					ON cmr.Договор=cmr_new.Договор 
					AND cmr.Период_date = cmr_new.Период_date
			OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

			SELECT @InsertRows = @@ROWCOUNT
			SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
			SELECT @StartDate = getdate()

		COMMIT TRAN

		IF @isDebug = 1 BEGIN
			SELECT 'INSERT _1cCMR.РегистрСведений_АналитическиеПоказателиМФО', @InsertRows, @DurationSec
		END
		if not exists(select top(1) 1 from sys.indexes
		where name = 'Cl_РегистрСведений_АналитическиеПоказателиМФО_Договор'
		and object_id= OBJECT_ID('_1cCMR.РегистрСведений_АналитическиеПоказателиМФО'))
		begin
			CREATE CLUSTERED INDEX Cl_РегистрСведений_АналитическиеПоказателиМФО_Договор 
			ON _1cCMR.РегистрСведений_АналитическиеПоказателиМФО([Договор]) 
			ON [_1cCMR]
		end
		
		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		IF @isDebug = 1 BEGIN
			SELECT 'INDEX  _1cCMR.РегистрСведений_АналитическиеПоказателиМФО', @InsertRows, @DurationSec
		END


		SELECT @DurationSec = datediff(SECOND, @StartDate_1, getdate())

		SELECT @message = 
			concat(
				'Заполнение _1cCMR.РегистрСведений_АналитическиеПоказателиМФО. ',
				--'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
		END

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = @eventType, 
			@message = @message, 
			@SendEmail = @SendEmail, 
			@ProcessGUID = @ProcessGUID
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Ошибка заполнения _1cCMR.РегистрСведений_АналитическиеПоказателиМФО. ',
				--'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END
