CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_МестоСоздания2
	@mode int = 1
as
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	--truncate table sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	SELECT @mode = isnull(@mode, 1)

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_МестоСоздания2

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2 AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(
		СсылкаЗаявки binary(16),
		GuidЗаявки nvarchar(36)
	)

	--1
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT R.СсылкаЗаявки, R.GuidЗаявки
	FROM dwh2.hub.Заявка AS R
		INNER JOIN dwh2.link.v_СпособОформления_Заявка AS M
			ON M.GuidЗаявки = R.GuidЗаявки
	WHERE M.updated_at > @updated_at

	--2
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT R.СсылкаЗаявки, R.GuidЗаявки
	FROM dwh2.hub.Заявка AS R
		INNER JOIN Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS RS
			ON RS.Заявка = R.СсылкаЗаявки
	WHERE RS.DWHInsertedDate > @updated_at

	--3
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT R.СсылкаЗаявки, R.GuidЗаявки
	FROM dwh2.hub.Заявка AS R
		INNER JOIN dwh2.sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов AS DS
			ON DS.GuidЗаявки = R.GuidЗаявки
	WHERE DS.updated_at > @updated_at

	DROP TABLE IF EXISTS #t_Заявки2
	CREATE TABLE #t_Заявки2(
		СсылкаЗаявки binary(16),
		GuidЗаявки nvarchar(36)
	)

	INSERT #t_Заявки2(СсылкаЗаявки, GuidЗаявки)
	SELECT DISTINCT T.СсылкаЗаявки, T.GuidЗаявки FROM #t_Заявки AS T

	CREATE INDEX IX1 ON #t_Заявки2(СсылкаЗаявки)
	CREATE INDEX IX2 ON #t_Заявки2(GuidЗаявки)


	SELECT DISTINCT
		--F1.СсылкаЗаявки,
		--F1.GuidЗаявки,
		СсылкаЗаявки = isnull(F1.СсылкаЗаявки, S5.СсылкаЗаявки),
		GuidЗаявки = isnull(F1.GuidЗаявки, cast(nullif([dbo].[getGUIDFrom1C_IDRREF](S5.СсылкаЗаявки), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)),
		--F1.МестоСоздания,
		--S5.ВидЗаполнения,
		МестоСоздания2 = 
			cast(
				iif (
					F1.МестоСоздания = 'ЛКК клиента' 
					OR S5.ВидЗаполнения = 'Заполняется в личном кабинете клиента',
					'ЛКК клиента',
					iif (
						F1.МестоСоздания = 'Оформление в мобильном приложении' 
						OR S5.ВидЗаполнения = 'Заполняется в мобильном приложении'
						OR F1.МестоСоздания = 'Оформление на клиентском сайте',
						'МП',
						iif(
							F1.МестоСоздания='Ввод операторами КЦ' 
							OR F1.МестоСоздания ='Ввод операторами LCRM' 
							OR F1.МестоСоздания = 'Ввод операторами FEDOR' 
							OR F1.МестоСоздания ='Ввод операторами стороннего КЦ',
							'КЦ',
							iif(
								F1.МестоСоздания = 'Оформление на партнерском сайте',
								'Партнеры',
								F1.МестоСоздания
							)
						)
					)
				)
				AS varchar(255)
			),
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
		--ВерсияДанных = 
	INTO #t_ЗаявкаНаЗаймПодПТС_МестоСоздания2
	FROM (
		SELECT 
			R.СсылкаЗаявки,
			R.GuidЗаявки,
			МестоСоздания = M.Наименование
		FROM #t_Заявки2 AS R
			INNER JOIN dwh2.link.v_СпособОформления_Заявка AS M
				ON M.GuidЗаявки = R.GuidЗаявки
		--WHERE 1=1
		--	AND R.СсылкаЗаявки = 0x8D23E4AF14B90B46458FBD198EDBF746
	) AS F1

	--LEFT JOIN
	FULL OUTER JOIN

	(
		SELECT
			S4.СсылкаЗаявки,
			S4.ВидЗаполнения
		FROM (
			SELECT 
				S3.СсылкаЗаявки,
                --S3.Флаг,
                --S3.ДатаИзменения,
                S3.ВидЗаполнения,
                --S3.[Контроль данных],
				row_number() OVER(PARTITION BY S3.СсылкаЗаявки ORDER BY S3.ДатаИзменения DESC) as RN
			FROM (
				SELECT 
					СсылкаЗаявки = RS.Заявка,
					Флаг = iif(
						ST.Наименование = 'Контроль данных' 
						OR datediff(mi, dateadd(year, -2000, RS.ДатаИзменения), DS.[Контроль данных]) >= 0 
						OR DS.[Контроль данных] IS NULL,
						1,
						NULL
					),
					ДатаИзменения = dateadd(year, -2000, RS.ДатаИзменения),
					ВидЗаполнения = VIDZ.Наименование,
					DS.[Контроль данных]
				--FROM Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS RS
				FROM #t_Заявки2 AS R
					INNER JOIN Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS RS
						ON RS.Заявка = R.СсылкаЗаявки
					LEFT JOIN Stg._1cCRM.Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС AS VIDZ
						ON VIDZ.Ссылка = RS.ВидЗаполнения
					LEFT JOIN dwh2.sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов AS DS
						ON DS.СсылкаЗаявки = RS.Заявка
					LEFT JOIN Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС as ST
						ON ST.Ссылка = RS.Статус
				--WHERE 1=1
				--	AND RS.Заявка = 0x8D23E4AF14B90B46458FBD198EDBF746
			) AS S3
			WHERE S3.Флаг = 1
		) AS S4
		WHERE S4.RN = 1
	) AS S5
	ON F1.СсылкаЗаявки = S5.СсылкаЗаявки


	CREATE INDEX ix1 ON #t_ЗаявкаНаЗаймПодПТС_МестоСоздания2(GuidЗаявки)

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2') is null
	begin
		select top(0)
			СсылкаЗаявки,
			GuidЗаявки,
			МестоСоздания2,
			created_at,
			updated_at,
			spFillName
            --ВерсияДанных
		INTO sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2
		FROM #t_ЗаявкаНаЗаймПодПТС_МестоСоздания2

		alter table sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2
			alter column СсылкаЗаявки binary(16) not null

		alter table sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_МестоСоздания2 PRIMARY KEY CLUSTERED (GuidЗаявки)

		CREATE INDEX ix_updated_at
		ON sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2(updated_at)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_МестоСоздания2 t
		using #t_ЗаявкаНаЗаймПодПТС_МестоСоздания2 s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			МестоСоздания2,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.МестоСоздания2,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND isnull(t.МестоСоздания2, '') != isnull(s.МестоСоздания2, '')
		then update SET
			t.МестоСоздания2 = s.МестоСоздания2,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
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
