CREATE PROC sat.fill_ДоговорЗайма_ПДН
	@mode int = 1, -- 0 - full, 1 - increment
	@DealNumber nvarchar(30) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_ПДН
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime2(0) = '1900-01-01'
	DECLARE @cmr_vid_pdn binary(16) --ВидДополнительнойИнформации

	SELECT @cmr_vid_pdn = S.Ссылка
	FROM Stg._1cCMR.Справочник_ВидыДополнительнойИнформацииДоговоры AS S
	WHERE S.Наименование = 'ПДН'



	if OBJECT_ID ('sat.ДоговорЗайма_ПДН') is not NULL
		AND @mode = 1
		--AND @DealNumber IS NULL
	begin
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(DAY, -5, max(S.updated_at)), '1900-01-01')
		FROM sat.ДоговорЗайма_ПДН AS S
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
		--1 новые заявки
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT D.СсылкаДоговораЗайма
		FROM hub.ДоговорЗайма AS D
		WHERE D.updated_at >= @updated_at

		--2. CMR
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT DISTINCT СсылкаДоговораЗайма = P.ДоговорЗайма
		FROM Stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров AS P
		WHERE P.ВидДополнительнойИнформации = @cmr_vid_pdn
			AND P.ДатаЗаписи >= dateadd(YEAR, 2000,dateadd(mm,-4, dateadd(dd,1,eomonth(@updated_at))))
			
		--3. риски
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT DISTINCT D.СсылкаДоговораЗайма
		FROM (
				SELECT distinct КодДоговораЗайма = cast(P.Number AS nvarchar(255))
				FROM dwh2.risk.pdn_calculation_2gen AS P
				WHERE P.request_date >= @updated_at
			) AS A
			INNER JOIN hub.ДоговорЗайма AS D
				ON D.КодДоговораЗайма = A.КодДоговораЗайма

		--4. УМФО - РегистрСведений_СЗД_КоэффициентыПДН
		INSERT #t_ДоговорЗайма_0(СсылкаДоговораЗайма)
		SELECT DISTINCT СсылкаДоговораЗайма = P.Займ
		FROM Stg._1cUMFO.РегистрСведений_СЗД_КоэффициентыПДН AS P
		WHERE P.Период >= dateadd(YEAR, 2000,dateadd(mm,-4, dateadd(dd,1,eomonth(@updated_at))))
		 
	END

	CREATE INDEX ix1 ON #t_ДоговорЗайма_0(СсылкаДоговораЗайма)


	DROP TABLE IF EXISTS #t_ДоговорЗайма
	CREATE TABLE #t_ДоговорЗайма(
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14),
		КодДоговораЗайма_int bigint
	)

	INSERT #t_ДоговорЗайма(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма, КодДоговораЗайма_int)
	SELECT 
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма,
		int_КодДоговораЗайма = try_cast(D.КодДоговораЗайма AS bigint)
	FROM (
			SELECT DISTINCT T.СсылкаДоговораЗайма 
			FROM #t_ДоговорЗайма_0 AS T
		) A
		INNER JOIN hub.ДоговорЗайма AS D
			ON D.СсылкаДоговораЗайма = A.СсылкаДоговораЗайма

	CREATE INDEX ix1 ON #t_ДоговорЗайма(СсылкаДоговораЗайма)
	CREATE INDEX ix2 ON #t_ДоговорЗайма(КодДоговораЗайма_int)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	END


	DROP TABLE IF EXISTS #t_ДоговорЗайма_ПДН_0
	CREATE TABLE #t_ДоговорЗайма_ПДН_0
	(
		row_id int NOT NULL IDENTITY(1,1),
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14),
		Система nvarchar(30),
		Дата_с datetime,
		PDN numeric(15, 7),
		Система_Договор_row_id int
	)

	--1. CMR
	INSERT #t_ДоговорЗайма_ПДН_0(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма, Система, Дата_с, PDN)
	SELECT DISTINCT
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма,
		Система = 'CMR',
		--Дата_с = cast(dateadd(YEAR, -2000, P.Период) AS date),
		Дата_с = dateadd(YEAR, -2000, P.Период),
		PDN = P.Значение_Число
	FROM #t_ДоговорЗайма AS D
		INNER JOIN Stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров AS P
			ON P.ДоговорЗайма = D.СсылкаДоговораЗайма
	WHERE P.ВидДополнительнойИнформации = @cmr_vid_pdn

	--2. риски
	/*
	INSERT #t_ДоговорЗайма_ПДН_0(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма, Система, Дата_с, PDN)
	SELECT DISTINCT
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма,
		Система = 'risk',
		--Дата_с = cast(P.request_date AS date),
		--Дата_с = P.request_date,
		Дата_с = H.ДатаДоговораЗайма,
		PDN = P.pdn
	FROM #t_ДоговорЗайма AS D
		INNER JOIN hub.ДоговорЗайма AS H
			ON H.КодДоговораЗайма = D.КодДоговораЗайма
		INNER JOIN dwh2.risk.pdn_calculation_2gen AS P
			ON D.КодДоговораЗайма_int = P.Number
	*/
	-- если в dwh2.risk.pdn_calculation_2gen
	-- есть дубли по номеру договора (Number)
	INSERT #t_ДоговорЗайма_ПДН_0(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма, Система, Дата_с, PDN)
	SELECT 
		t.СсылкаДоговораЗайма,
		t.GuidДоговораЗайма,
		t.КодДоговораЗайма,
		Система = 'risk',
		--Дата_с = cast(P.request_date AS date),
		--Дата_с = P.request_date,
		t.Дата_с,
		t.PDN
	from (
		SELECT
			D.СсылкаДоговораЗайма,
			D.GuidДоговораЗайма,
			D.КодДоговораЗайма,
			--Система = 'risk',
			--Дата_с = cast(P.request_date AS date),
			--Дата_с = P.request_date,
			Дата_с = H.ДатаДоговораЗайма,
			PDN = P.pdn,
			rn = row_number() over(
				partition by D.КодДоговораЗайма
				order by P.InsertedDate desc
			)
		FROM #t_ДоговорЗайма AS D
			INNER JOIN hub.ДоговорЗайма AS H
				ON H.КодДоговораЗайма = D.КодДоговораЗайма
			INNER JOIN dwh2.risk.pdn_calculation_2gen AS P
				ON D.КодДоговораЗайма_int = P.Number
		) as t
		where t.rn = 1



	--3. УМФО - РегистрСведений_СЗД_КоэффициентыПДН
	INSERT #t_ДоговорЗайма_ПДН_0(СсылкаДоговораЗайма, GuidДоговораЗайма, КодДоговораЗайма, Система, Дата_с, PDN)
	SELECT DISTINCT
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма,
		Система = 'УМФО',
		--Дата_с = cast(dateadd(YEAR, -2000, P.Период) AS date),
		Дата_с = dateadd(YEAR, -2000, P.Период),
		PDN = P.ПДН
	FROM #t_ДоговорЗайма AS D
		INNER JOIN Stg._1cUMFO.РегистрСведений_СЗД_КоэффициентыПДН AS P
			ON P.Займ = D.СсылкаДоговораЗайма

	--Система_Договор_row_id
	UPDATE T
	SET T.Система_Договор_row_id = A.rn
	FROM #t_ДоговорЗайма_ПДН_0 AS T
		INNER JOIN (
			SELECT 
				P.row_id,
				rn = row_number() OVER(PARTITION BY P.Система, P.КодДоговораЗайма ORDER BY P.Дата_с)
			FROM #t_ДоговорЗайма_ПДН_0 AS P
			) AS A
			ON A.row_id = T.row_id

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_ПДН_0
		SELECT * INTO ##t_ДоговорЗайма_ПДН_0 FROM #t_ДоговорЗайма_ПДН_0
	END


	DROP TABLE IF EXISTS #t_ДоговорЗайма_ПДН
	CREATE TABLE #t_ДоговорЗайма_ПДН
	(
		row_id int NOT NULL,
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14),
		Система nvarchar(30),
		nRow int,
		Дата_с datetime,
		Дата_по datetime,
		PDN numeric(15, 7),
		Система_Договор_row_id int,
		created_at datetime,
		updated_at datetime,
		spFillName nvarchar(255)
	)

	INSERT #t_ДоговорЗайма_ПДН
	(
		row_id,
	    СсылкаДоговораЗайма,
	    GuidДоговораЗайма,
	    КодДоговораЗайма,
	    Система,
	    Дата_с,
	    --Дата_по,
	    PDN,
	    Система_Договор_row_id,
		created_at,
		updated_at,
		spFillName
	)
	SELECT 
		D.row_id,
		D.СсылкаДоговораЗайма,
		D.GuidДоговораЗайма,
		D.КодДоговораЗайма,
		D.Система,
		D.Дата_с,
		D.PDN,
		D.Система_Договор_row_id,
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	FROM (
		SELECT 
			B.Система, B.КодДоговораЗайма,	B.group_id,
			Система_Договор_row_id = min(B.Система_Договор_row_id)
		FROM (
			SELECT 
				A.КодДоговораЗайма, A.Система, A.Система_Договор_row_id,
				group_id = A.Система_Договор_row_id - A.rn2
			FROM (
					SELECT 
						P.КодДоговораЗайма, P.Система, P.Система_Договор_row_id,
						rn2 = row_number() OVER(PARTITION BY P.Система, P.КодДоговораЗайма, P.PDN ORDER BY P.Дата_с)
					FROM #t_ДоговорЗайма_ПДН_0 AS P
				) AS A
		) AS B
		GROUP BY B.Система, B.КодДоговораЗайма,	B.group_id
	) AS C
		INNER JOIN #t_ДоговорЗайма_ПДН_0 AS D
			ON D.Система = C.Система
			AND D.КодДоговораЗайма = C.КодДоговораЗайма
			AND D.Система_Договор_row_id = C.Система_Договор_row_id


	UPDATE B
	SET nRow = A.nRow,
		Дата_по = dateadd(MILLISECOND, -10, A.Дата_по)
	FROM (
		SELECT 
			P.row_id,
			nRow = row_number() OVER(PARTITION BY P.Система, P.КодДоговораЗайма ORDER BY P.Дата_с),
			Дата_по = lead(P.Дата_с, 1, '3000-01-01') OVER(PARTITION BY P.Система, P.КодДоговораЗайма ORDER BY P.Дата_с)
		FROM #t_ДоговорЗайма_ПДН AS P
		) AS A
		INNER JOIN #t_ДоговорЗайма_ПДН AS B
			ON B.row_id = A.row_id


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_ПДН
		SELECT * INTO ##t_ДоговорЗайма_ПДН FROM #t_ДоговорЗайма_ПДН
	END


	if OBJECT_ID('sat.ДоговорЗайма_ПДН') is null
	begin
		select top(0)
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,
			Система,
			nRow,
			Дата_с,
			Дата_по,
			PDN,
			created_at,
			updated_at,
			spFillName
		into sat.ДоговорЗайма_ПДН
		from #t_ДоговорЗайма_ПДН

		alter table sat.ДоговорЗайма_ПДН
			alter column GuidДоговораЗайма uniqueidentifier not NULL

		alter table sat.ДоговорЗайма_ПДН
			alter column КодДоговораЗайма nvarchar(14) not NULL

		alter table sat.ДоговорЗайма_ПДН
			alter column Система nvarchar(30) not null

		alter table sat.ДоговорЗайма_ПДН
			alter column Дата_с datetime not NULL
            
		alter table sat.ДоговорЗайма_ПДН
			alter column nRow int not NULL

		ALTER TABLE sat.ДоговорЗайма_ПДН
			ADD CONSTRAINT PK_ДоговорЗайма_ПДН PRIMARY KEY CLUSTERED (КодДоговораЗайма, Система, Дата_с)
	end


	
	begin TRAN
		DELETE T
		FROM sat.ДоговорЗайма_ПДН AS T
			INNER JOIN #t_ДоговорЗайма_ПДН AS A
				ON A.КодДоговораЗайма = T.КодДоговораЗайма

		INSERT sat.ДоговорЗайма_ПДН
		(
			СсылкаДоговораЗайма,
			GuidДоговораЗайма,
			КодДоговораЗайма,
			Система,
			nRow,
			Дата_с,
			Дата_по,
			PDN,
			created_at,
			updated_at,
			spFillName
		)
		SELECT 
			T.СсылкаДоговораЗайма,
			T.GuidДоговораЗайма,
			T.КодДоговораЗайма,
			T.Система,
			T.nRow,
			T.Дата_с,
			T.Дата_по,
			T.PDN,
			T.created_at,
			T.updated_at,
			T.spFillName
		FROM #t_ДоговорЗайма_ПДН AS T
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
