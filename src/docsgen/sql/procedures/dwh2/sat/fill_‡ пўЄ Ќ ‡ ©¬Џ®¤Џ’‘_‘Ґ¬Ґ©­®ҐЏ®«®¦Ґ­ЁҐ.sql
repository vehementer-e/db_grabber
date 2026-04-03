/*
exec sat.fill_ЗаявкаНаЗаймПодПТС_СемейноеПоложение @mode = 0
*/
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_СемейноеПоложение
	@mode int = 1,
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_СемейноеПоложение

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.lk_updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки nvarchar(100)) -- uniqueidentifier)

	--1
	INSERT #t_Заявки(GuidЗаявки)
	SELECT LK_Заявка.guid
	FROM Stg._LK.requests AS LK_Заявка
	WHERE LK_Заявка.updated_at >= @updated_at
		and (LK_Заявка.guid = @RequestGuid OR @RequestGuid IS NULL)

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	select distinct
		СсылкаЗаявки = LK_Заявка.СсылкаЗаявки,
		GuidЗаявки = LK_Заявка.GuidЗаявки,

		СемейноеПоложение = LK_Заявка.СемейноеПоложение,
		lk_updated_at = LK_Заявка.lk_updated_at,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_СемейноеПоложение
	FROM (
		SELECT 
			СсылкаЗаявки = Заявка.СсылкаЗаявки,
			GuidЗаявки = LKЗаявка.guid,
			СемейноеПоложение = marital_status.name,
			lk_updated_at = LKЗаявка.updated_at,
			rn = row_number() OVER(
				PARTITION BY LKЗаявка.guid 
				ORDER BY LKЗаявка.updated_at DESC, Заявка.НомерЗаявки DESC
			)
		FROM #t_Заявки AS T
			INNER JOIN Stg._LK.requests AS LKЗаявка
				ON LKЗаявка.guid = T.GuidЗаявки
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.GuidЗаявки = T.GuidЗаявки
			LEFT JOIN Stg._LK.marital_status AS marital_status
				ON marital_status.id = LKЗаявка.client_marital_status_id
		) AS LK_Заявка
	WHERE LK_Заявка.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			СемейноеПоложение,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение
		from #t_ЗаявкаНаЗаймПодПТС_СемейноеПоложение

		alter table sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_СемейноеПоложение PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_СемейноеПоложение t
		using #t_ЗаявкаНаЗаймПодПТС_СемейноеПоложение s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched 
			AND s.СемейноеПоложение IS NOT NULL
		then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			СемейноеПоложение,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.СемейноеПоложение,
			s.lk_updated_at,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.СемейноеПоложение,'') <> isnull(s.СемейноеПоложение,'') 
				OR t.lk_updated_at <> s.lk_updated_at
			)
			AND s.СемейноеПоложение IS NOT NULL
		then update SET
			t.СемейноеПоложение = s.СемейноеПоложение,
			t.lk_updated_at = s.lk_updated_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
		WHEN MATCHED
			AND s.СемейноеПоложение IS NULL
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
