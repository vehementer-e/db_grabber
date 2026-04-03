--[sat].[fill_Клиент_Телефон] 0 
CREATE PROC sat.fill_Клиент_Телефон
	@mode int = 1 -- 0 - full, 1 - increment
	,@GuidClient uniqueidentifier = null
AS
BEGIN
	--truncate table sat.Клиент_Телефон
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	--DECLARE @maxDate datetime2(0) = '0001-01-01'

	drop table if exists #t_Клиент_Телефон

	/*
	if OBJECT_ID ('sat.Клиент_Телефон') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.Клиент_Телефон), 0x0)
		SELECT @maxDate = isnull((SELECT dateadd(dd,-2, max(ДатаЗаписи)) FROM sat.Клиент_Телефон), '0001-01-01')
	end
	*/

	drop table if exists #t_Клиент

	/*
	SELECT DISTINCT 
		Клиенты.GuidКлиент,
		Клиенты.СсылкаКлиент
	INTO #t_Клиент
	FROM hub.Клиенты AS Клиенты
		INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
			ON Инф.Ссылка = Клиенты.СсылкаКлиент
	WHERE 1=1
		AND Инф.ДатаЗаписи >= dateadd(YEAR, 2000, @maxDate)
		AND Инф.CRM_ОсновнойДляСвязи = 0x01
		AND Инф.Актуальный = 0x01
		AND Инф.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
		--test
		--AND Клиенты.GuidКлиент = '267A3681-122E-11E8-814E-00155D01BF07' --'594EC58E-DED5-11E9-B818-00155D03492D'
	*/

	SELECT DISTINCT 
		Клиенты.GuidКлиент,
		Клиенты.СсылкаКлиент,
		НомерТелефонаБезКодов
	INTO #t_Клиент
	FROM hub.Клиенты AS Клиенты
		INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
			ON Инф.Ссылка = Клиенты.СсылкаКлиент
	WHERE 1=1
		--AND Инф.ДатаЗаписи >= dateadd(YEAR, 2000, @maxDate)
		AND (Инф.CRM_ОсновнойДляСвязи = 0x01 or 
			--временное исправление ошибки в CRM
			Клиенты.GuidКлиент in ('38153597-E4BE-45AD-965A-F05D1A64F36C')
			)
		AND Инф.Актуальный = 0x01
		AND Инф.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
		and (Клиенты.GuidКлиент = @GuidClient or @GuidClient is null)
	EXCEPT 
	SELECT 
		Клиенты.GuidКлиент,
		Клиенты.СсылкаКлиент,
		t.НомерТелефонаБезКодов
	FROM hub.Клиенты AS Клиенты
		INNER JOIN sat.Клиент_Телефон AS T
			ON T.GuidКлиент = Клиенты.GuidКлиент
	where @mode = 1 --increment





	SELECT --TOP 10
		Телефон.GuidКлиент,
		Телефон.СсылкаКлиент,
		Телефон.НомерТелефонаБезКодов,
		Телефон.ДатаЗаписи,
		Телефон.nRow,
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	INTO #t_Клиент_Телефон
	FROM (
		select 
			КонтИнф.GuidКлиент
			,КонтИнф.СсылкаКлиент
			,КонтИнф.НомерТелефонаБезКодов
			,КонтИнф.ДатаЗаписи
			,nRow = Row_Number() OVER (
				PARTITION BY КонтИнф.СсылкаКлиент
				ORDER BY КонтИнф.ДатаЗаписи DESC, КонтИнф.НомерСтроки DESC
				)
		FROM (
				SELECT 
					Клиент.GuidКлиент,
					Клиент.СсылкаКлиент,
					Инф.НомерТелефонаБезКодов,
					ДатаЗаписи = max(dateadd(YEAR, -2000, cast(Инф.ДатаЗаписи AS datetime2(0)))),
					НомерСтроки = max(Инф.НомерСтроки)
				from #t_Клиент AS Клиент
					INNER JOIN Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация AS Инф
						ON Инф.Ссылка = Клиент.СсылкаКлиент
				where 1=1
					AND (Инф.CRM_ОсновнойДляСвязи = 0x01 or 
						--временное исправление ошибки в CRM
						Клиент.GuidКлиент in ('38153597-E4BE-45AD-965A-F05D1A64F36C')
						)
					AND Инф.Актуальный = 0x01
					AND Инф.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
					and NULLIF(Инф.НомерТелефонаБезКодов,'') is not null
				GROUP BY 
					Клиент.GuidКлиент,
					Клиент.СсылкаКлиент,
					Инф.НомерТелефонаБезКодов
			) AS КонтИнф
		where 1=1
		) AS Телефон
	WHERE 1=1
		--AND Телефон.nRow = 1
		--AND Телефон.nRow > 1


	if OBJECT_ID('sat.Клиент_Телефон') is null
	begin
		select top(0)
			GuidКлиент,
			СсылкаКлиент,
			НомерТелефонаБезКодов,
			ДатаЗаписи,
			nRow,
			created_at,
			updated_at,
			spFillName
		into sat.Клиент_Телефон
		from #t_Клиент_Телефон

		alter table sat.Клиент_Телефон
			alter column GuidКлиент uniqueidentifier not null

		alter table sat.Клиент_Телефон
			alter column nRow int not null

		ALTER TABLE sat.Клиент_Телефон
			ADD CONSTRAINT PK_Клиент_Телефон PRIMARY KEY CLUSTERED (GuidКлиент, nRow)
	END
	
	BEGIN TRAN
		-- обновить данные по всем телефонам выбранных клиентов
		--1. 
		
		if @mode = 0
			truncate table  sat.Клиент_Телефон
		else
			DELETE T 
		FROM sat.Клиент_Телефон AS T
			INNER JOIN #t_Клиент AS Клиент
				ON T.GuidКлиент = Клиент.GuidКлиент
		--2
		INSERT sat.Клиент_Телефон
		(
			GuidКлиент,
			СсылкаКлиент,
			НомерТелефонаБезКодов,
			ДатаЗаписи,
			nRow,
			created_at,
			updated_at,
			spFillName
		)
		SELECT 
			S.GuidКлиент,
			S.СсылкаКлиент,
			S.НомерТелефонаБезКодов,
			S.ДатаЗаписи,
			S.nRow,
			S.created_at,
			S.updated_at,
			S.spFillName
		FROM #t_Клиент_Телефон AS S

		--merge sat.Клиент_Телефон t
		--using #t_Клиент_Телефон s
		--	on t.GuidКлиент = s.GuidКлиент
		--when not matched then insert
		--(
		--	GuidКлиент,
		--    СсылкаКлиент,
		--	РегионРегистрации,
		--	GMTРегионРегистрации,
		--    created_at,
		--    updated_at,
		--    spFillName,
		--    ВерсияДанных
		--) values
		--(
		--	s.GuidКлиент,
		--    s.СсылкаКлиент,
		--	s.РегионРегистрации,
		--	s.GMTРегионРегистрации,
		--    s.created_at,
		--    s.updated_at,
		--    s.spFillName,
		--    s.ВерсияДанных
		--)
		--when matched and t.ВерсияДанных != s.ВерсияДанных
		--then update SET
		--	t.РегионРегистрации = s.РегионРегистрации,
		--	t.GMTРегионРегистрации = s.GMTРегионРегистрации,
		--	t.updated_at = s.updated_at,
		--	t.spFillName = s.spFillName,
		--	t.ВерсияДанных = s.ВерсияДанных
		--	;

	COMMIT TRAN

END TRY
BEGIN CATCH
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

	IF @@TRANCOUNT>0
		ROLLBACK TRAN;
	;THROW
END CATCH

END
