CREATE   PROC sat.fill_Клиент_ПаспортныеДанные
	@mode int = 1 -- 0 - full, 1 - increment
	,@GuidКлиент nvarchar(36) = null
as
begin
	--truncate table sat.Клиент_ПаспортныеДанные
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	DECLARE @maxDate datetime2(0) = '0001-01-01'

	drop table if exists #t_Клиент_ПаспортныеДанные

	if OBJECT_ID ('sat.Клиент_ПаспортныеДанные') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.Клиент_ПаспортныеДанные), 0x0)
		SELECT @maxDate = isnull((SELECT max(ДатаЗаписи) FROM sat.Клиент_ПаспортныеДанные), '0001-01-01')
	end

	IF @maxDate <> '0001-01-01'
	BEGIN
		SELECT @maxDate = dateadd(DAY, -10, @maxDate)
	END

	SELECT DISTINCT 
		Клиенты.GuidКлиент,
		Клиенты.СсылкаКлиент
	INTO #t_Клиент
	FROM hub.Клиенты AS Клиенты
		INNER JOIN Stg._1cCRM.РегистрСведений_ДокументыФизическихЛиц AS R
			ON R.Физлицо_Ссылка = Клиенты.СсылкаКлиент
	WHERE 1=1
		AND (R.Период >= dateadd(YEAR, 2000, @maxDate) or Клиенты.GuidКлиент = @GuidКлиент)
		AND R.Физлицо_ТипСсылки = 0x0000008B
		--test
		--AND Клиенты.GuidКлиент IN ('6BC8D256-6702-40FF-9444-D9EE7F6C6614','C9886493-DCE5-4EBF-9445-35FA3CF90717')

	SELECT 
		Инф.GuidКлиент,
		Инф.СсылкаКлиент,
		Инф.Серия,
		Инф.Номер,
		Инф.ДатаВыдачи,
		Инф.КемВыдан,
		Инф.КодПодразделения,
		Инф.ДатаЗаписи,
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	INTO #t_Клиент_ПаспортныеДанные
	FROM (
			SELECT
				Клиент.GuidКлиент,
				Клиент.СсылкаКлиент,
				R.Серия,
				R.Номер,
				ДатаВыдачи = dateadd(YEAR, -2000, cast(R.ДатаВыдачи AS date)),
				--R.СрокДействия
				R.КемВыдан,
				R.КодПодразделения,
				ДатаЗаписи = dateadd(YEAR, -2000, cast(R.Период AS datetime2(0))),
				rn = row_number() OVER(PARTITION BY R.Физлицо_Ссылка ORDER BY R.ДатаВыдачи DESC, R.Период DESC) --при одинаковой дате паспорта берерм последнию по дате  записи
			FROM #t_Клиент AS Клиент
				INNER JOIN Stg._1cCRM.РегистрСведений_ДокументыФизическихЛиц AS R
					ON R.Физлицо_Ссылка = Клиент.СсылкаКлиент
			WHERE 1=1
				AND R.Физлицо_ТипСсылки = 0x0000008B
				AND R.ВидДокумента = 0xA81400155D94190011E80796F0352643
				AND nullif(trim(R.Серия),'') IS NOT NULL
				AND nullif(trim(R.Номер),'') IS NOT NULL
				and year(dateadd(YEAR, -2000, cast(R.ДатаВыдачи AS date)))<=year(getdate()) --год выдачи должен быть меньше текущего
		) AS Инф
	WHERE 1=1
		AND Инф.rn = 1

	if OBJECT_ID('sat.Клиент_ПаспортныеДанные') is null
	begin
		select top(0)
			GuidКлиент,
			СсылкаКлиент,
			Серия,
			Номер,
			ДатаВыдачи,
			КемВыдан,
			КодПодразделения,
			ДатаЗаписи,
			created_at,
			updated_at,
			spFillName
		into sat.Клиент_ПаспортныеДанные
		from #t_Клиент_ПаспортныеДанные

		alter table sat.Клиент_ПаспортныеДанные
			alter column GuidКлиент uniqueidentifier not null

		alter table sat.Клиент_ПаспортныеДанные
			alter column Серия nvarchar(14) not null

		alter table sat.Клиент_ПаспортныеДанные
			alter column Номер nvarchar(14) not null

		ALTER TABLE sat.Клиент_ПаспортныеДанные
			ADD CONSTRAINT PK_Клиент_ПаспортныеДанные PRIMARY KEY CLUSTERED (GuidКлиент)
	end
	
	BEGIN TRAN
		-- обновить данные по всем выбранным клиентам
		--1. 
		DELETE T 
		FROM sat.Клиент_ПаспортныеДанные AS T
			INNER JOIN #t_Клиент AS Клиент
				ON T.GuidКлиент = Клиент.GuidКлиент

		--2
		INSERT sat.Клиент_ПаспортныеДанные
		(
			GuidКлиент,
			СсылкаКлиент,
			Серия,
			Номер,
			ДатаВыдачи,
			КемВыдан,
			КодПодразделения,
			ДатаЗаписи,
			created_at,
			updated_at,
			spFillName
		)
		select 
			S.GuidКлиент,
			S.СсылкаКлиент,
			S.Серия,
			S.Номер,
			S.ДатаВыдачи,
			S.КемВыдан,
			S.КодПодразделения,
			S.ДатаЗаписи,
			S.created_at,
			S.updated_at,
			S.spFillName
		from #t_Клиент_ПаспортныеДанные AS S

	COMMIT TRAN

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
