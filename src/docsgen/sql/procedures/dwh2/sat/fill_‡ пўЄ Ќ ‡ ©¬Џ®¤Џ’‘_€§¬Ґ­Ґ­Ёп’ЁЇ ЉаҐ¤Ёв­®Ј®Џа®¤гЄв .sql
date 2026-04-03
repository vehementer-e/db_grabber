
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
	@RequestNumber nvarchar(30) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime2(0) = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта') is not NULL
		AND @RequestNumber IS NULL
	begin
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(СсылкаЗаявки binary(16), GuidЗаявки uniqueidentifier) -- uniqueidentifier)

	--1 новые заявки
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT Заявка.СсылкаЗаявки, Заявка.GuidЗаявки 
	FROM hub.Заявка AS Заявка
	WHERE Заявка.updated_at > @updated_at
		AND (@RequestNumber IS NULL OR Заявка.НомерЗаявки = @RequestNumber)

	CREATE UNIQUE INDEX ix1 ON #t_Заявки(GuidЗаявки)

	--2 новые ИзмененияРеквизитовОбъектов
	IF @RequestNumber IS NULL BEGIN
		INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
		SELECT DISTINCT 
			H.СсылкаЗаявки,
			H.GuidЗаявки
		FROM hub.Заявка AS H
			INNER JOIN Stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов AS R
				ON R.Период >= dateadd(YEAR, 2000, @updated_at)
				AND R.Объект_Ссылка = H.СсылкаЗаявки
				AND R.Реквизит IN ('Инстолмент', 'ПДЛ')
				AND R.ЗначениеРеквизитаПослеПредставление = 'Да'
		WHERE 1=1
			AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_Заявки AS X WHERE X.GuidЗаявки = H.GuidЗаявки)
	END
	
	CREATE INDEX ix2 ON #t_Заявки(СсылкаЗаявки)


	DROP TABLE IF EXISTS #t_ТипКредитногоПродукта
	CREATE TABLE #t_ТипКредитногоПродукта
	(
		СсылкаЗаявки binary(16),
		GuidЗаявки uniqueidentifier,
		ДатаИзменения datetime2(0),
		КодТипаКредитногоПродукта varchar(100),
		ТипКредитногоПродукта varchar(100),
		nRow int
	)

	--1 ПТС из Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
	INSERT #t_ТипКредитногоПродукта
	(
	    СсылкаЗаявки,
	    GuidЗаявки,
		ДатаИзменения,
		КодТипаКредитногоПродукта,
	    ТипКредитногоПродукта,
	    nRow
	)
	SELECT 
		Заявки.СсылкаЗаявки,
		Заявки.GuidЗаявки,
		ДатаИзменения = H.ДатаЗаявки,
		КодТипаКредитногоПродукта = cast(ТипыКредитногоПродукта.Код AS varchar(100)),
		ТипКредитногоПродукта = cast(ТипыКредитногоПродукта.Наименование AS varchar(100)),
		nRow = 1
	FROM #t_Заявки AS Заявки
		INNER JOIN hub.Заявка AS H
			ON H.GuidЗаявки = Заявки.GuidЗаявки
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON Заявки.СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка
		INNER JOIN Stg._1cCRM.Справочник_тмТипыКредитногоПродукта AS ТипыКредитногоПродукта
			ON ТипыКредитногоПродукта.Ссылка = ЗаявкаНаЗаймПодПТС.ТипКредитногоПродукта
			AND ТипыКредитногоПродукта.Код = 'pts'

	CREATE INDEX ix ON #t_ТипКредитногоПродукта(GuidЗаявки)


	--2 ('Инстолмент', 'ПДЛ') из Stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
	INSERT #t_ТипКредитногоПродукта
	(
	    СсылкаЗаявки,
	    GuidЗаявки,
		ДатаИзменения,
		КодТипаКредитногоПродукта,
	    ТипКредитногоПродукта,
	    nRow
	)
	SELECT 
		Заявки.СсылкаЗаявки,
		Заявки.GuidЗаявки,
		ДатаИзменения = dateadd(year,-2000, R.Период),
		КодТипаКредитногоПродукта =
			CASE R.Реквизит 
				WHEN 'Инстолмент' THEN 'installment'
				WHEN 'ПДЛ' THEN 'pdl'
			END,
		ТипКредитногоПродукта = 
			CASE R.Реквизит 
				WHEN 'Инстолмент' THEN 'Installment'
				WHEN 'ПДЛ' THEN 'PDL'
			END,
		nRow = row_number() OVER(PARTITION BY R.Объект_Ссылка ORDER BY R.Период)
			+ iif(X.GuidЗаявки IS NOT NULL, 1, 0)
	FROM #t_Заявки AS Заявки
		INNER JOIN Stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов AS R
			ON R.Объект_Ссылка = Заявки.СсылкаЗаявки
			AND R.Реквизит IN ('Инстолмент', 'ПДЛ')
			AND R.ЗначениеРеквизитаПослеПредставление = 'Да'
		LEFT JOIN #t_ТипКредитногоПродукта AS X
			ON X.GuidЗаявки = Заявки.GuidЗаявки

	CREATE INDEX ix1 ON #t_ТипКредитногоПродукта(GuidЗаявки)


	--3 ('Инстолмент', 'ПДЛ') из Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
	--для тех, которых нет в _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
	INSERT #t_ТипКредитногоПродукта
	(
	    СсылкаЗаявки,
	    GuidЗаявки,
		ДатаИзменения,
		КодТипаКредитногоПродукта,
	    ТипКредитногоПродукта,
	    nRow
	)
	SELECT 
		Заявки.СсылкаЗаявки,
		Заявки.GuidЗаявки,
		ДатаИзменения = H.ДатаЗаявки,
		КодТипаКредитногоПродукта = cast(ТипыКредитногоПродукта.Код AS varchar(100)),
		ТипКредитногоПродукта = cast(ТипыКредитногоПродукта.Наименование AS varchar(100)),
		nRow = 1
	FROM #t_Заявки AS Заявки
		INNER JOIN hub.Заявка AS H
			ON H.GuidЗаявки = Заявки.GuidЗаявки
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON Заявки.СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка
		INNER JOIN Stg._1cCRM.Справочник_тмТипыКредитногоПродукта AS ТипыКредитногоПродукта
			ON ТипыКредитногоПродукта.Ссылка = ЗаявкаНаЗаймПодПТС.ТипКредитногоПродукта
			AND ТипыКредитногоПродукта.Код <> 'pts'
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ТипКредитногоПродукта AS T WHERE T.GuidЗаявки = Заявки.GuidЗаявки)


	--4 ПТС 
	--для старых заявок, у которых не заполнен _1cCRM.Документ_ЗаявкаНаЗаймПодПТС.ТипКредитногоПродукта
	INSERT #t_ТипКредитногоПродукта
	(
	    СсылкаЗаявки,
	    GuidЗаявки,
		ДатаИзменения,
		КодТипаКредитногоПродукта,
	    ТипКредитногоПродукта,
	    nRow
	)
	SELECT 
		Заявки.СсылкаЗаявки,
		Заявки.GuidЗаявки,
		ДатаИзменения = H.ДатаЗаявки,
		КодТипаКредитногоПродукта = 'pts',
		ТипКредитногоПродукта = 'PTS',
		nRow = 1
	FROM #t_Заявки AS Заявки
		INNER JOIN hub.Заявка AS H
			ON H.GuidЗаявки = Заявки.GuidЗаявки
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON Заявки.СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка
		LEFT JOIN Stg._1cCRM.Справочник_тмТипыКредитногоПродукта AS ТипыКредитногоПродукта
			ON ТипыКредитногоПродукта.Ссылка = ЗаявкаНаЗаймПодПТС.ТипКредитногоПродукта
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ТипКредитногоПродукта AS T WHERE T.GuidЗаявки = Заявки.GuidЗаявки)
		AND ТипыКредитногоПродукта.Ссылка IS NULL


	select distinct
		T.СсылкаЗаявки,
		T.GuidЗаявки,
		T.ДатаИзменения,
		T.КодТипаКредитногоПродукта,
		T.ТипКредитногоПродукта,
		T.nRow,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
	FROM #t_ТипКредитногоПродукта AS T

	CREATE INDEX ix1 ON #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта(GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта FROM #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
	END


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			ДатаИзменения,
			КодТипаКредитногоПродукта,
			ТипКредитногоПродукта,
			nRow,
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
		from #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта

		alter table sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
			alter column GuidЗаявки uniqueidentifier not null

		alter table sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
			alter column nRow int not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта PRIMARY KEY CLUSTERED (GuidЗаявки, nRow)
	end

	--определить только те заявки, по которым поменялись данные
	drop table if exists #t_request
	create table #t_request(GuidЗаявки uniqueidentifier)

	insert #t_request(GuidЗаявки)
	select distinct a.GuidЗаявки
	from #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта as a

	create index ix1 on #t_request(GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_request
		SELECT * INTO ##t_request FROM #t_request
	END


	drop table if exists #t_change
	create table #t_change(GuidЗаявки uniqueidentifier)

	insert #t_change(GuidЗаявки)
	select distinct x.GuidЗаявки
	from (
		select 
			--a.СсылкаЗаявки,
			a.GuidЗаявки,
			a.ДатаИзменения,
			a.КодТипаКредитногоПродукта,
			a.ТипКредитногоПродукта,
			a.nRow
		from #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта as a
		except
		select 
			--T.СсылкаЗаявки,
			T.GuidЗаявки,
			T.ДатаИзменения,
			T.КодТипаКредитногоПродукта,
			T.ТипКредитногоПродукта,
			T.nRow
		FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS T
			INNER JOIN #t_request AS A
				ON A.GuidЗаявки = T.GuidЗаявки
		) as x
	union
	select distinct y.GuidЗаявки
	from (
		select 
			--T.СсылкаЗаявки,
			T.GuidЗаявки,
			T.ДатаИзменения,
			T.КодТипаКредитногоПродукта,
			T.ТипКредитногоПродукта,
			T.nRow
		FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS T
			INNER JOIN #t_request AS A
				ON A.GuidЗаявки = T.GuidЗаявки
		except
		select 
			--a.СсылкаЗаявки,
			a.GuidЗаявки,
			a.ДатаИзменения,
			a.КодТипаКредитногоПродукта,
			a.ТипКредитногоПродукта,
			a.nRow
		from #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта as a
		) as y

	create index ix1 on #t_change(GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_change
		SELECT * INTO ##t_change FROM #t_change
		--test
		--return 0
	END

	if exists(select top(1) 1 from #t_change)
	begin
		begin TRAN
			DELETE T
			FROM sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS T
				--INNER JOIN #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS A
				inner join #t_change as A
					ON A.GuidЗаявки = T.GuidЗаявки

			INSERT sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта
			(
				СсылкаЗаявки,
				GuidЗаявки,
				ДатаИзменения,
				КодТипаКредитногоПродукта,
				ТипКредитногоПродукта,
				nRow,
				created_at,
				updated_at,
				spFillName
			)
			SELECT 
				T.СсылкаЗаявки,
				T.GuidЗаявки,
				T.ДатаИзменения,
				T.КодТипаКредитногоПродукта,
				T.ТипКредитногоПродукта,
				T.nRow,
				T.created_at,
				T.updated_at,
				T.spFillName 
			FROM #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта AS T
				inner join #t_change as A
					ON A.GuidЗаявки = T.GuidЗаявки

			--merge sat.ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта t
			--using #t_ЗаявкаНаЗаймПодПТС_ИзмененияТипаКредитногоПродукта s
			--	on t.GuidЗаявки = s.GuidЗаявки
			--when not matched then insert
			--(
			--	СсылкаЗаявки,
			--    GuidЗаявки,
			--	ТипКредитногоПродукта,
			--	nRow,
			--    created_at,
			--    updated_at,
			--    spFillName
			--) values
			--(
			--	s.СсылкаЗаявки,
			--    s.GuidЗаявки,
			--	s.ТипКредитногоПродукта,
			--	s.nRow,
			--    s.created_at,
			--    s.updated_at,
			--    s.spFillName
			--)
			--when matched and t.ВерсияДанных != s.ВерсияДанных
			--then update SET
			--	t.ТипКредитногоПродукта = s.ТипКредитногоПродукта,
			--	t.updated_at = s.updated_at,
			--	t.spFillName = s.spFillName,
			--	t.ВерсияДанных = s.ВерсияДанных
			--	;
		commit tran
	end
	--//exists(select top(1) 1 from #t_change)

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
