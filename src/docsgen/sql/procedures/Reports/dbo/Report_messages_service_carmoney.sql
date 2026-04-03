-- =============================================
-- Author:		А.Никитин
-- Create date: 12.04.2022
-- Description:	DWH-1621 Отчет по сообщениям из service.carmoney.ru
-- =============================================
CREATE PROC dbo.Report_messages_service_carmoney
	@Mode nvarchar(100) = 'verify',
	@dtFrom date = NULL,
	@dtTo date = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @c1310 char(2) = char(13)+char(10)

	IF @Mode IS NULL BEGIN
		SELECT @Mode = 'verify' -- тексты обращения, отправленные через сервис Carmoney https://service.carmoney.ru/ с учетной записи verify.
	END

	IF @dtFrom IS NULL BEGIN
		--Начало прошлого месяца
		SELECT @dtFrom = dateadd(DAY, 1, eomonth(dateadd(MONTH, -2, cast(getdate() as date))))
	END

	IF @dtTo IS NULL BEGIN
		SELECT @dtTo = cast(getdate() as date)
	END

	IF @Mode IN ('verify')
	BEGIN
		SELECT
			request_id = R.id,
			message_id = M.id,
			message_type_id = M.type_id,
			message_type_name = MT.name,
			--
			[ДатаВремя сообщения] = M.created_at,
			[Дата сообщения] = cast(M.created_at AS date),
			[Время сообщения] =  cast(M.created_at AS time),
			[Номер заявки] = R.num_1c,
			[ФИО клиента] = concat(R.client_last_name, ' ', R.client_first_name, ' ', R.client_patronymic),
			[Номер ID Site] = R.num,
			--[Текст сообщения] = M.message
			[Текст сообщения] = trim(replace(convert(varchar(MAX), M.message), @c1310, ' '))
		--SELECT count(*)
		FROM Stg._LK.message_type AS MT 
			INNER JOIN Stg._LK.message AS M
				ON M.type_id = MT.id
			INNER JOIN Stg._LK.requests AS R
				ON R.id = M.order_id
		WHERE 1=1
			AND cast(M.created_at AS date) BETWEEN @dtFrom AND @dtTo
			--AND M.type_id = (SELECT TOP(1) MT.id FROM _LK.message_type AS MT WHERE MT.name = 'ver')
			AND MT.name = 'ver'
			AND NOT EXISTS(SELECT TOP(1) 1 FROM Stg._LK.message_message AS MM WHERE M.id = MM.child_message_id)
	END

END

