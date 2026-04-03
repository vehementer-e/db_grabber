
/*
exec sat.fill_ЗаявкаНаЗаймПодПТС_ИсточникLCRM @mode = 0
exec sat.fill_ЗаявкаНаЗаймПодПТС_ИсточникLCRM @mode = 1
*/
CREATE   PROC sat.fill_ЗаявкаНаЗаймПодПТС_ИсточникLCRM
	@mode int = 1,
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	declare @request_updated_at bigint = 0
	declare @lead_updated_at bigint = 0

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ИсточникLCRM

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			--@updated_at = isnull(dateadd(HOUR, -2, max(S.lk_updated_at)), '1900-01-01')
			@request_updated_at = isnull(max(request_updated_at) - 100, 0),
			@lead_updated_at = isnull(max(lead_updated_at) - 100, 0)
		FROM sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM AS S
	end


	--1
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки nvarchar(100)) -- uniqueidentifier)

	INSERT #t_Заявки(GuidЗаявки)
	SELECT R.id
	FROM Stg._LF.request AS R
	WHERE R.updated_at >= @request_updated_at
		and (R.id = @RequestGuid OR @RequestGuid IS NULL)

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	--2
	IF @RequestGuid IS NULL BEGIN
		INSERT #t_Заявки(GuidЗаявки)
		SELECT R.id
		FROM Stg._LF.request AS R
			INNER JOIN Stg._LF.lead AS L
				ON L.id = R.marketing_lead_id
		WHERE L.updated_at >= @lead_updated_at
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Заявки AS X
				WHERE X.GuidЗаявки = R.id
			)
	END



	select distinct
		СсылкаЗаявки = Заявка.СсылкаЗаявки,
		GuidЗаявки = Заявка.GuidЗаявки,
		ИсточникLCRM = S.name,
		request_updated_at = R.updated_at,
		lead_updated_at = L.updated_at,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ИсточникLCRM
	FROM #t_Заявки AS T
		INNER JOIN Stg._LF.request AS R
			ON R.id = T.GuidЗаявки
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = T.GuidЗаявки
		INNER JOIN Stg._LF.lead AS L
			ON L.id = R.marketing_lead_id
		LEFT JOIN Stg._LF.source_account AS S
			ON S.id = L.source_id


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			ИсточникLCRM,
			request_updated_at,
			lead_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM
		from #t_ЗаявкаНаЗаймПодПТС_ИсточникLCRM

		alter table sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ИсточникLCRM PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ИсточникLCRM t
		using #t_ЗаявкаНаЗаймПодПТС_ИсточникLCRM s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched 
			AND s.ИсточникLCRM IS NOT NULL
		THEN insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			ИсточникLCRM,
			request_updated_at,
			lead_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.ИсточникLCRM,
			s.request_updated_at,
			s.lead_updated_at,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (
				isnull(t.ИсточникLCRM,'') <> isnull(s.ИсточникLCRM,'')
				OR t.request_updated_at <> s.request_updated_at
				OR t.lead_updated_at <> s.lead_updated_at
			)
			AND s.ИсточникLCRM IS NOT NULL
		then update SET
			t.ИсточникLCRM = s.ИсточникLCRM,
			t.request_updated_at = s.request_updated_at,
			t.lead_updated_at = s.lead_updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
		WHEN MATCHED
			AND s.ИсточникLCRM IS NULL
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
