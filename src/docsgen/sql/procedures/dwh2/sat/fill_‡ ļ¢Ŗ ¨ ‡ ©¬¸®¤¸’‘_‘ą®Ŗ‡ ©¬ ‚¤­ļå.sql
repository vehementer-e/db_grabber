/*
drop table sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
exec sat.fill_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях @mode = 0
exec sat.fill_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях @mode = 1
*/
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
	@mode int = 1,
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion_request binary(8) = 0x0
	declare @rowVersion_deal binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях), 0x0)
		SELECT 
			@rowVersion_request = isnull(max(S.ВерсияДанных_cmr_Заявка), 0x0),
			@rowVersion_deal = isnull(max(S.ВерсияДанных_cmr_Договор), 0x0),
			@updated_at = isnull(dateadd(DAY, -1, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(СсылкаЗаявки binary(16), GuidЗаявки uniqueidentifier)

	--1 fedor
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT Заявка.СсылкаЗаявки, Заявка.GuidЗаявки
	FROM Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.СсылкаЗаявки = cmr_Заявка.Ссылка
	WHERE cmr_Заявка.ВерсияДанных > @rowVersion_request
		AND (Заявка.GuidЗаявки = @RequestGuid OR @RequestGuid IS NULL)

	CREATE INDEX IX1
	ON #t_Заявки(СсылкаЗаявки) --GuidЗаявки)

	--2 MFO
	IF @RequestGuid IS NULL BEGIN
		INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
		SELECT Заявка.СсылкаЗаявки, Заявка.GuidЗаявки
		FROM Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.СсылкаЗаявки = cmr_Заявка.Ссылка
			INNER JOIN Stg._1cCMR.Справочник_Договоры AS cmr_Договор
				on cmr_Заявка.Ссылка = cmr_Договор.Заявка
		WHERE cmr_Договор.ВерсияДанных > @rowVersion_deal
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM #t_Заявки AS X
				WHERE X.СсылкаЗаявки = Заявка.СсылкаЗаявки
			)
	END


	select distinct
		СсылкаЗаявки = Заявка.СсылкаЗаявки,
		GuidЗаявки = Заявка.GuidЗаявки,

		СрокЗаймаВднях = cast(A.СрокЗаймаВднях AS int),

		A.ВерсияДанных_cmr_Заявка,
		A.ВерсияДанных_cmr_Договор, 

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
	FROM (
		SELECT 
			T.СсылкаЗаявки,
			T.GuidЗаявки,

			СрокЗаймаВднях = nullif(isnull(cmr_Договор.PDLСрок, cmr_Заявка.PDLСрок), 0),

			ВерсияДанных_cmr_Заявка = cmr_Заявка.ВерсияДанных,
			ВерсияДанных_cmr_Договор = cmr_Договор.ВерсияДанных, 
			rn = row_number() OVER(PARTITION BY cmr_Заявка.Ссылка ORDER BY cmr_Заявка.ВерсияДанных DESC)
		FROM #t_Заявки AS T
			INNER JOIN Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
				ON T.СсылкаЗаявки = cmr_Заявка.Ссылка
			LEFT JOIN Stg._1cCMR.Справочник_Договоры AS cmr_Договор
				on cmr_Заявка.Ссылка = cmr_Договор.Заявка
		) AS A
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = A.GuidЗаявки
	WHERE A.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			СрокЗаймаВднях,
			ВерсияДанных_cmr_Заявка,
			ВерсияДанных_cmr_Договор, 
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
		from #t_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях

		alter table sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях t
		using #t_ЗаявкаНаЗаймПодПТС_СрокЗаймаВднях s
			on t.GuidЗаявки = s.GuidЗаявки
		when not MATCHED
			AND s.СрокЗаймаВднях IS NOT NULL
		THEN insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			СрокЗаймаВднях,
			ВерсияДанных_cmr_Заявка,
			ВерсияДанных_cmr_Договор, 
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.СрокЗаймаВднях,
			s.ВерсияДанных_cmr_Заявка,
			s.ВерсияДанных_cmr_Договор, 
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			AND (
				isnull(t.СрокЗаймаВднях,'') <> isnull(s.СрокЗаймаВднях,'')
				OR t.ВерсияДанных_cmr_Заявка <> s.ВерсияДанных_cmr_Заявка
				OR t.ВерсияДанных_cmr_Договор <> s.ВерсияДанных_cmr_Договор
			)
			AND s.СрокЗаймаВднях IS NOT NULL
		then update SET
			t.СрокЗаймаВднях = s.СрокЗаймаВднях,
			t.ВерсияДанных_cmr_Заявка = s.ВерсияДанных_cmr_Заявка,
			t.ВерсияДанных_cmr_Договор = s.ВерсияДанных_cmr_Договор,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
		WHEN MATCHED
			AND s.СрокЗаймаВднях IS NULL
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
