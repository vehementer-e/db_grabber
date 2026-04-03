--drop table dm.ДоговорЗайма
-- =======================================================
-- Create: 11.03.2026. А.Никитин
-- Description:	
-- =======================================================
CREATE PROC dm.Create_dm_ДоговорЗайма
	@mode int = 1, -- 1-increment, 0-full
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
as
begin
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	DECLARE @DurationSec int, @StartDate datetime = getdate()
	DECLARE @DeleteRows int, @InsertRows int

	SELECT @eventName = 'dwh2.dm.Create_dm_ДоговорЗайма', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.ДоговорЗайма') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.ДоговорЗайма
			FROM dm.v_ДоговорЗайма

			alter table dm.ДоговорЗайма
				alter COLUMN СсылкаДоговораЗайма binary(16) not null

			alter table dm.ДоговорЗайма
				alter column КодДоговораЗайма nvarchar(14) not null

			alter table dm.ДоговорЗайма
				alter column GuidДоговораЗайма uniqueidentifier not null

			ALTER TABLE dm.ДоговорЗайма
				ADD CONSTRAINT PK_dm_ДоговорЗайма 
				PRIMARY KEY CLUSTERED (КодДоговораЗайма)

			CREATE NONCLUSTERED INDEX ix_GuidДоговораЗайма
				ON dm.ДоговорЗайма(GuidДоговораЗайма, КодДоговораЗайма)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.КодДоговораЗайма, id
		INTO #t_change
		FROM link.ДоговорЗайма_change AS C

		create clustered index cix_id on #t_change(id)
		create index cix_КодДоговораЗайма on #t_change(КодДоговораЗайма)

		DROP TABLE IF EXISTS #t_ДоговорЗайма

		SELECT TOP(0) *
		INTO #t_ДоговорЗайма
		FROM dm.v_ДоговорЗайма

		IF @mode = 0
		BEGIN
			INSERT #t_ДоговорЗайма
			SELECT R.* 
			FROM dm.v_ДоговорЗайма AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_ДоговорЗайма
			SELECT distinct R.* 
			FROM dm.v_ДоговорЗайма AS R
			where exists(select top(1) 1 FROM #t_change AS T
			where R.КодДоговораЗайма = T.КодДоговораЗайма)
		END

		--дубли могут быть из-за нескольких выдачДС
		;with del as (
			select 
				t.*,
				rn = row_number() over(
					partition by t.КодДоговораЗайма
					order by 
						case when t.ДатаВыдачи is not null then 1 else 2 end, 
						t.ДатаВыдачи desc, 
						getdate()
				)
			from #t_ДоговорЗайма as t
		)
		delete d
		from del as d
		where d.rn <> 1



		BEGIN TRAN

			IF @mode = 0
			BEGIN
				DELETE R 
				FROM dm.ДоговорЗайма AS R
			END
			else begin
				DELETE R 
				FROM dm.ДоговорЗайма AS R
					INNER JOIN #t_ДоговорЗайма AS T
						ON T.КодДоговораЗайма = R.КодДоговораЗайма
			END

			SELECT @DeleteRows = @@ROWCOUNT
	
			INSERT dm.ДоговорЗайма
			(
				created_at,

				СсылкаДоговораЗайма, 
				GuidДоговораЗайма, 
				КодДоговораЗайма, 

				ДоговорЗайма_isDelete,
				ДатаДоговораЗайма,
				Фамилия,
				Имя,
				Отчество,
				ДатаРождения,
				Сумма,
				СуммаЗапрошенная,
				СуммаВыдачи,
				Срок,
				IsInstallment,
				IsSmartInstallment,
				ВерсияДанных,
				УникальныйИдентификаторОбъектаБКИ,
				ТипПродукта,
				ПодТипПродукта,
				ДатаЗакрытияДоговора,
				ТипПродукта_Code,
				ТипПродукта_Наименование,
				ГруппаПродуктов_Code,
				ГруппаПродуктов_Наименование,
				ПодТипПродукта_Code,
				Заявка_ВерсияДанных,
				НачальнаяПроцентнаяСтавка,
				GuidКлиент,
				СсылкаКлиент,
				ДатаЗаявки,
				ДатаВыдачи,
				ОфисВыдачи,
				ТекущийСтатусДоговора,
				ДатаТекущегоСтатуса,
				КредитныйПродукт_Наименование,
				ТекущаяПроцентнаяСтавка,
				КоличествоДнейПросрочкиНаНачалоДня,
				КоличествоДнейПросрочкиНаКонецДня
			)
			SELECT distinct 
				created_at,

				СсылкаДоговораЗайма, 
				GuidДоговораЗайма, 
				КодДоговораЗайма, 

				ДоговорЗайма_isDelete,
				ДатаДоговораЗайма,
				Фамилия,
				Имя,
				Отчество,
				ДатаРождения,
				Сумма,
				СуммаЗапрошенная,
				СуммаВыдачи,
				Срок,
				IsInstallment,
				IsSmartInstallment,
				ВерсияДанных,
				УникальныйИдентификаторОбъектаБКИ,
				ТипПродукта,
				ПодТипПродукта,
				ДатаЗакрытияДоговора,
				ТипПродукта_Code,
				ТипПродукта_Наименование,
				ГруппаПродуктов_Code,
				ГруппаПродуктов_Наименование,
				ПодТипПродукта_Code,
				Заявка_ВерсияДанных,
				НачальнаяПроцентнаяСтавка,
				GuidКлиент,
				СсылкаКлиент,
				ДатаЗаявки,
				ДатаВыдачи,
				ОфисВыдачи,
				ТекущийСтатусДоговора,
				ДатаТекущегоСтатуса,
				КредитныйПродукт_Наименование,
				ТекущаяПроцентнаяСтавка,
				КоличествоДнейПросрочкиНаНачалоДня,
				КоличествоДнейПросрочкиНаКонецДня
			FROM #t_ДоговорЗайма AS T

			SELECT @InsertRows = @@ROWCOUNT

			insert tmp.log_link_ДоговорЗайма_change(spFillName, row_count)
			select C.spFillName, row_count = count(*)
			FROM link.ДоговорЗайма_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
			group by C.spFillName

			DELETE C
			FROM link.ДоговорЗайма_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		COMMIT

		--SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		--SELECT @message = 
		--	concat(
		--		'Заполнение dwh2.dm.ДоговорЗайма. ',
		--		'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
		--		'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
		--		'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		--	)

		--IF @isDebug = 1 BEGIN
		--	SELECT @message
		--	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		--		@eventName = @eventName, 
		--		@eventType = @eventType, 
		--		@message = @message, 
		--		@SendEmail = @SendEmail, 
		--		@ProcessGUID = @ProcessGUID
		--END
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
				'Ошибка заполнения dwh2.dm.ДоговорЗайма. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
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
