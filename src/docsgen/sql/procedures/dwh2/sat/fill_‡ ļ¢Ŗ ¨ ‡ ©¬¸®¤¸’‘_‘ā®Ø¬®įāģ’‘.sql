/*
drop table sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС
exec sat.fill_ЗаявкаНаЗаймПодПТС_СтоимостьТС @mode = 0
exec sat.fill_ЗаявкаНаЗаймПодПТС_СтоимостьТС @mode = 1
*/
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_СтоимостьТС
	@mode int = 1,
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion_fedor binary(8) = 0x0
	declare @rowVersion_MFO binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_СтоимостьТС

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС), 0x0)
		SELECT 
			@rowVersion_fedor = isnull(max(S.ВерсияДанных_fedor), 0x0),
			@rowVersion_MFO = isnull(max(S.ВерсияДанных_MFO), 0x0),
			@updated_at = isnull(dateadd(DAY, -1, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки uniqueidentifier)

	--1 fedor
	INSERT #t_Заявки(GuidЗаявки)
	SELECT fedor_Заявка.Id 
	FROM Stg._fedor.core_ClientRequest AS fedor_Заявка
	--WHERE fedor_Заявка.DWHInsertedDate >= @updated_at
	WHERE fedor_Заявка.RowVersion > @rowVersion_fedor
		AND (fedor_Заявка.id = @RequestGuid OR @RequestGuid IS NULL)

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	--2 MFO
	IF @RequestGuid IS NULL BEGIN
		INSERT #t_Заявки(GuidЗаявки)
		SELECT Заявка.GuidЗаявки
		FROM stg._1cMFO.Документ_ГП_Заявка AS R
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.НомерЗаявки = R.Номер
		WHERE R.ВерсияДанных >= @rowVersion_MFO
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Заявки AS X
				WHERE X.GuidЗаявки = Заявка.GuidЗаявки
			)
	END


	select distinct
		СсылкаЗаявки = Заявка.СсылкаЗаявки,
		GuidЗаявки = Заявка.GuidЗаявки,

		СтоимостьТС = cast(fedor_Заявка.СтоимостьТС AS money),

		ВерсияДанных_fedor = fedor_Заявка.ВерсияДанных_fedor,
		ВерсияДанных_MFO = fedor_Заявка.ВерсияДанных_MFO,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ЗаявкаНаЗаймПодПТС_СтоимостьТС
	FROM (
		SELECT 
			fedorЗаявка.Id,
			СтоимостьТС = coalesce(
				nullif(fedorЗаявка.TsMarketPrice, 0.00),
				nullif(mfo_заявка.РыночнаяСтоимостьАвтоНаМоментОценки, 0.00)
				--,0.00
			), -- первоначальная стоимость залога, рыночная стоимость авто (код из dbo.create_dm_OverdueIndicators)

			ВерсияДанных_fedor = fedorЗаявка.RowVersion,
			ВерсияДанных_MFO = mfo_заявка.ВерсияДанных,

			rn = row_number() OVER(PARTITION BY fedorЗаявка.Id ORDER BY fedorЗаявка.RowVersion DESC)
		FROM #t_Заявки AS T
			INNER JOIN Stg._fedor.core_ClientRequest AS fedorЗаявка
				ON fedorЗаявка.Id = T.GuidЗаявки
				AND fedorЗаявка.IsNewProcess = 1
				--AND fedorЗаявка.CreatedRequestDate >= '2020-09-01' -- ???
			LEFT JOIN Stg._1cMFO.Документ_ГП_Заявка AS mfo_заявка
				ON mfo_заявка.Номер = fedorЗаявка.Number COLLATE Cyrillic_General_CI_AS
				--AND mfo_заявка.Дата < dateadd(year, 2000, '2021-11-01')
		) AS fedor_Заявка
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = fedor_Заявка.Id
	WHERE fedor_Заявка.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			СтоимостьТС,
			ВерсияДанных_fedor,
			ВерсияДанных_MFO,
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС
		from #t_ЗаявкаНаЗаймПодПТС_СтоимостьТС

		alter table sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_СтоимостьТС PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_СтоимостьТС t
		using #t_ЗаявкаНаЗаймПодПТС_СтоимостьТС s
			on t.GuidЗаявки = s.GuidЗаявки
		when not MATCHED
			AND s.СтоимостьТС IS NOT NULL
		THEN insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			СтоимостьТС,
			ВерсияДанных_fedor,
			ВерсияДанных_MFO,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.СтоимостьТС,
			s.ВерсияДанных_fedor,
			s.ВерсияДанных_MFO,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			AND (
				isnull(t.СтоимостьТС,'') <> isnull(s.СтоимостьТС,'')
				OR t.ВерсияДанных_fedor <> s.ВерсияДанных_fedor
				OR t.ВерсияДанных_MFO <> s.ВерсияДанных_MFO
			)
			AND s.СтоимостьТС IS NOT NULL
		then update SET
			t.СтоимостьТС = s.СтоимостьТС,
			t.ВерсияДанных_fedor = s.ВерсияДанных_fedor,
			t.ВерсияДанных_MFO = s.ВерсияДанных_MFO,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
		WHEN MATCHED
			AND s.СтоимостьТС IS NULL
		then DELETE
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
