/*
EXEC sat.fill_ДоговорЗайма_Статусы
	--@mode = 1, -- 0 - full, 1 - increment
	@DealNumber = '25011522989859',
	@isDebug = 1
*/
CREATE PROC sat.fill_ДоговорЗайма_Статусы
	@mode int = 1, -- 0 - full, 1 - increment
	@DealNumber nvarchar(30) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_Статусы
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime2(0) = '1900-01-01'

	if OBJECT_ID ('sat.ДоговорЗайма_Статусы') is not NULL
		AND @mode = 1
		--AND @DealNumber IS NULL
	begin
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(DAY, -15, max(S.updated_at)), '1900-01-01')
		FROM sat.ДоговорЗайма_Статусы AS S
	end

	DROP TABLE IF EXISTS #t_ДоговорЗайма_0
	CREATE TABLE #t_ДоговорЗайма_0(
		СсылкаДоговораЗайма binary(16)
	)


	IF @DealNumber IS NOT NULL BEGIN
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT D.СсылкаДоговораЗайма
		FROM hub.ДоговорЗайма AS D
		WHERE D.КодДоговораЗайма = @DealNumber
	END
	ELSE BEGIN
		/*
		--1 новые заявки
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT D.СсылкаДоговораЗайма
		FROM hub.ДоговорЗайма AS D
		WHERE D.updated_at >= @updated_at

		--2 новые статусы
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT DISTINCT R.Договор
		FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS R (NOLOCK)
		WHERE R.Период >= dateadd(YEAR, 2000, @updated_at)
		*/
		IF @mode = 1 BEGIN
			--3 EXCEPT
			-- новые статусы из источника
			INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
			SELECT DISTINCT T.Договор 
			FROM (
					SELECT R.Договор, S.Наименование
					FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS R
						INNER JOIN Stg._1cCMR.Справочник_СтатусыДоговоров AS S
							ON S.Ссылка = R.Статус
					EXCEPT
					SELECT DS.СсылкаДоговораЗайма, DS.СтатусДоговора 
					FROM sat.ДоговорЗайма_Статусы AS DS
				) AS T
				INNER JOIN hub.ДоговорЗайма AS D
					ON D.СсылкаДоговораЗайма = T.Договор

			-- если в источнике удалены статусы
			INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
			SELECT DISTINCT T.СсылкаДоговораЗайма
			FROM (
					SELECT DS.СсылкаДоговораЗайма, DS.СтатусДоговора 
					FROM sat.ДоговорЗайма_Статусы AS DS
					EXCEPT
					SELECT R.Договор, S.Наименование
					FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS R
						INNER JOIN Stg._1cCMR.Справочник_СтатусыДоговоров AS S
							ON S.Ссылка = R.Статус
				) AS T

		END
		ELSE BEGIN
			--все статусы
			INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
			SELECT DISTINCT R.Договор
			FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS R (NOLOCK)
			--WHERE R.Период >= dateadd(YEAR, 2000, @updated_at)
	     END
	END

	CREATE INDEX ix1 ON #t_ДоговорЗайма_0(СсылкаДоговораЗайма)


	DROP TABLE IF EXISTS #t_ДоговорЗайма
	CREATE TABLE #t_ДоговорЗайма(
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14)
		--КодДоговораЗайма_int bigint
	)

	INSERT #t_ДоговорЗайма(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма)
	SELECT 
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма
		--int_КодДоговораЗайма = try_cast(D.КодДоговораЗайма AS bigint)
	FROM (
			SELECT DISTINCT T.СсылкаДоговораЗайма 
			FROM #t_ДоговорЗайма_0 AS T
		) A
		INNER JOIN hub.ДоговорЗайма AS D
			ON D.СсылкаДоговораЗайма = A.СсылкаДоговораЗайма

	CREATE INDEX ix1 ON #t_ДоговорЗайма(СсылкаДоговораЗайма)
	CREATE INDEX ix2 ON #t_ДоговорЗайма(КодДоговораЗайма)
	--CREATE INDEX ix2 ON #t_ДоговорЗайма(КодДоговораЗайма_int)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	END



	-- история статусов по договору
	DROP TABLE IF EXISTS #t_ДоговорЗайма_Статусы
	
	select distinct
		A.СсылкаДоговораЗайма,
        A.GuidДоговораЗайма,
        A.КодДоговораЗайма,
		A.ДатаСтатуса,
		GuidСтатусаДоговора					= cast([dbo].[getGUIDFrom1C_IDRREF](A.Статус) as uniqueidentifier),
		A.СтатусДоговора,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ДоговорЗайма_Статусы
	--SELECT *
	FROM (
		SELECT 
			T.СсылкаДоговораЗайма,
			T.GuidДоговораЗайма,
			T.КодДоговораЗайма,

			ДатаСтатуса = dateadd(YEAR, -2000, СтатусыДоговоров.Период),
			СтатусыДоговоров.Статус,
			СтатусДоговора = СправочникСтатусы.Наименование,
			--rn = row_number() OVER(
			--	PARTITION BY СтатусыДоговоров.Договор, СправочникСтатусы.Наименование
			--	ORDER BY СтатусыДоговоров.Период --время статусов нужно брать минимальное --DESC
			--	)
			rn = row_number() OVER(
				PARTITION BY 
					СтатусыДоговоров.Договор,
					СправочникСтатусы.Наименование,
					cast(СтатусыДоговоров.Период as datetime2(0))
				ORDER BY getdate()
				)
		FROM #t_ДоговорЗайма AS T
			INNER JOIN Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS СтатусыДоговоров
				ON СтатусыДоговоров.Договор = T.СсылкаДоговораЗайма
			INNER JOIN Stg._1cCMR.Справочник_СтатусыДоговоров AS СправочникСтатусы
				ON СправочникСтатусы.Ссылка = СтатусыДоговоров.Статус
		) AS A
		INNER JOIN hub.ДоговорЗайма AS ДоговорЗайма
			ON ДоговорЗайма.КодДоговораЗайма = A.КодДоговораЗайма
	WHERE A.rn = 1

	CREATE INDEX ix1
	ON #t_ДоговорЗайма_Статусы(КодДоговораЗайма, GuidСтатусаДоговора)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_Статусы
		SELECT * INTO ##t_ДоговорЗайма_Статусы FROM #t_ДоговорЗайма_Статусы
	END


	if OBJECT_ID('sat.ДоговорЗайма_Статусы') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,
			ДатаСтатуса,
			GuidСтатусаДоговора,
			СтатусДоговора,
			created_at,
			updated_at,
			spFillName
		into sat.ДоговорЗайма_Статусы
		from #t_ДоговорЗайма_Статусы

		alter table sat.ДоговорЗайма_Статусы
			alter column GuidДоговораЗайма uniqueidentifier not null

		alter table sat.ДоговорЗайма_Статусы
			alter column КодДоговораЗайма nvarchar(14) not null

		alter table sat.ДоговорЗайма_Статусы
			alter column GuidСтатусаДоговора uniqueidentifier not null

		alter table sat.ДоговорЗайма_Статусы
			alter column ДатаСтатуса datetime2(0) not null

		ALTER TABLE sat.ДоговорЗайма_Статусы
			ADD CONSTRAINT PK_ДоговорЗайма_Статусы PRIMARY KEY CLUSTERED (
				КодДоговораЗайма, 
				GuidСтатусаДоговора, 
				ДатаСтатуса
			)

		CREATE INDEX ix_updated_at
		ON sat.ДоговорЗайма_Статусы(updated_at) INCLUDE(СсылкаДоговораЗайма)
	end


	DROP TABLE IF EXISTS #t_Deleted
	CREATE TABLE #t_Deleted(КодДоговораЗайма nvarchar(14))


	begin tran
		merge sat.ДоговорЗайма_Статусы t
		using #t_ДоговорЗайма_Статусы s
			on t.КодДоговораЗайма = s.КодДоговораЗайма
			AND t.GuidСтатусаДоговора = s.GuidСтатусаДоговора
			and t.ДатаСтатуса = s.ДатаСтатуса
		when not matched then insert
		(
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,
			ДатаСтатуса,
			GuidСтатусаДоговора,
			СтатусДоговора,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.СсылкаДоговораЗайма,
			s.GuidДоговораЗайма,
			s.КодДоговораЗайма,
			s.ДатаСтатуса,
			s.GuidСтатусаДоговора,
			s.СтатусДоговора,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			AND (
				--isnull(t.ДатаСтатуса, '1900-01-01') <> isnull(s.ДатаСтатуса, '1900-01-01')
				--OR t.СтатусДоговора <> s.СтатусДоговора
				--OR t.ВерсияДанных != s.ВерсияДанных
				t.СтатусДоговора <> s.СтатусДоговора
				or @mode = 0
			)
		then update SET
			t.СсылкаДоговораЗайма = s.СсылкаДоговораЗайма,
			t.GuidДоговораЗайма = s.GuidДоговораЗайма,
			--s.КодДоговораЗайма,
			t.ДатаСтатуса = s.ДатаСтатуса,
			--s.GuidСтатусаДоговора,
			t.СтатусДоговора = s.СтатусДоговора,
			--s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
		;

		--удаление статусов, удаленных в источнике
		DELETE T
		OUTPUT Deleted.КодДоговораЗайма INTO #t_Deleted
		FROM sat.ДоговорЗайма_Статусы AS T
			INNER JOIN #t_ДоговорЗайма AS D
				ON D.КодДоговораЗайма = T.КодДоговораЗайма
			LEFT JOIN #t_ДоговорЗайма_Статусы AS S
				ON T.КодДоговораЗайма = S.КодДоговораЗайма
				AND T.GuidСтатусаДоговора = S.GuidСтатусаДоговора
		WHERE S.GuidСтатусаДоговора IS NULL
		
		--актуализировать updated_at для пересчета sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
		IF EXISTS(SELECT TOP(1) 1 FROM #t_Deleted)
		BEGIN
			UPDATE T
			SET T.updated_at = getdate()
			FROM sat.ДоговорЗайма_Статусы AS T
				INNER JOIN #t_Deleted AS D
					ON D.КодДоговораЗайма = T.КодДоговораЗайма
		END

	commit tran




	--Текущий статус по договору
	DROP TABLE IF EXISTS #t_ДоговорЗайма_ТекущийСтатус

	SELECT 
		T.СсылкаДоговораЗайма,
		T.GuidДоговораЗайма,
		T.КодДоговораЗайма,
		ДатаТекущегоСтатуса = T.ДатаСтатуса,
		GuidТекущегоСтатусаДоговора = T.GuidСтатусаДоговора,
		ТекущийСтатусДоговора = T.СтатусДоговора,
		T.created_at,
		T.updated_at,
		T.spFillName 
	INTO #t_ДоговорЗайма_ТекущийСтатус
	FROM (
		SELECT 
			S.КодДоговораЗайма,
			ДатаСтатуса = max(S.ДатаСтатуса)
		FROM #t_ДоговорЗайма_Статусы AS S
		GROUP BY S.КодДоговораЗайма
		) AS M
		INNER JOIN #t_ДоговорЗайма_Статусы AS T
			ON T.КодДоговораЗайма = M.КодДоговораЗайма
			AND T.ДатаСтатуса = M.ДатаСтатуса

	CREATE INDEX ix1
	ON #t_ДоговорЗайма_ТекущийСтатус(КодДоговораЗайма)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_ТекущийСтатус
		SELECT * INTO ##t_ДоговорЗайма_ТекущийСтатус FROM #t_ДоговорЗайма_ТекущийСтатус
	END

	if OBJECT_ID('sat.ДоговорЗайма_ТекущийСтатус') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,
			ДатаТекущегоСтатуса,
			GuidТекущегоСтатусаДоговора,
			ТекущийСтатусДоговора,
			created_at,
			updated_at,
			spFillName
		into sat.ДоговорЗайма_ТекущийСтатус
		from #t_ДоговорЗайма_ТекущийСтатус

		alter table sat.ДоговорЗайма_ТекущийСтатус
			alter column GuidДоговораЗайма uniqueidentifier not null

		alter table sat.ДоговорЗайма_ТекущийСтатус
			alter column КодДоговораЗайма nvarchar(14) not null

		alter table sat.ДоговорЗайма_ТекущийСтатус
			alter column GuidТекущегоСтатусаДоговора uniqueidentifier not null

		ALTER TABLE sat.ДоговорЗайма_ТекущийСтатус
			ADD CONSTRAINT PK_ДоговорЗайма_ТекущийСтатус PRIMARY KEY CLUSTERED (КодДоговораЗайма)

		CREATE INDEX ix_updated_at
		ON sat.ДоговорЗайма_ТекущийСтатус(updated_at) INCLUDE(СсылкаДоговораЗайма)

		CREATE INDEX ix_СсылкаДоговораЗайма
		ON sat.ДоговорЗайма_ТекущийСтатус(СсылкаДоговораЗайма) INCLUDE(ТекущийСтатусДоговора)
	end

	merge sat.ДоговорЗайма_ТекущийСтатус t
	using #t_ДоговорЗайма_ТекущийСтатус s
		on t.КодДоговораЗайма = s.КодДоговораЗайма
	when not matched then insert
	(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма,
		ДатаТекущегоСтатуса,
		GuidТекущегоСтатусаДоговора,
		ТекущийСтатусДоговора,
		created_at,
		updated_at,
		spFillName
	) values
	(
		s.СсылкаДоговораЗайма,
		s.GuidДоговораЗайма,
		s.КодДоговораЗайма,
		s.ДатаТекущегоСтатуса,
		s.GuidТекущегоСтатусаДоговора,
		s.ТекущийСтатусДоговора,
		s.created_at,
		s.updated_at,
		s.spFillName
	)
	when matched 
		AND (isnull(t.ДатаТекущегоСтатуса, '1900-01-01') <> isnull(s.ДатаТекущегоСтатуса, '1900-01-01')
			or @mode = 0
		)
	then update SET
		t.СсылкаДоговораЗайма = s.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма = s.GuidДоговораЗайма,
		--s.КодДоговораЗайма,

		t.ДатаТекущегоСтатуса = s.ДатаТекущегоСтатуса,
		t.GuidТекущегоСтатусаДоговора = s.GuidТекущегоСтатусаДоговора,
		t.ТекущийСтатусДоговора = s.ТекущийСтатусДоговора,

		--s.created_at,
		t.updated_at = s.updated_at,
		t.spFillName = s.spFillName
	;



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
