/*
exec sat.fill_ЗаявкаНаЗаймПодПТС_Должность @mode = 0
exec sat.fill_ЗаявкаНаЗаймПодПТС_Должность @mode = 1
*/
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_Должность
	@mode int = 1,
	@RequestGuid nvarchar(100) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_Должность
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_Должность

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_Должность') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_Должность), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.lk_updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_Должность AS S
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

		Должность = LK_Заявка.Должность,
		lk_updated_at = LK_Заявка.lk_updated_at,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_Должность
	FROM (
		SELECT 
			СсылкаЗаявки = Заявка.СсылкаЗаявки,
			GuidЗаявки = LKЗаявка.guid,
			Должность = nullif(trim(LKЗаявка.client_work_position), ''),
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
		) AS LK_Заявка
	WHERE LK_Заявка.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_Должность') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			Должность,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_Должность
		from #t_ЗаявкаНаЗаймПодПТС_Должность

		alter table sat.ЗаявкаНаЗаймПодПТС_Должность
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_Должность
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_Должность PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_Должность t
		using #t_ЗаявкаНаЗаймПодПТС_Должность s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched 
			AND s.Должность IS NOT NULL
		THEN insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			Должность,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.Должность,
			s.lk_updated_at,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND (
				isnull(t.Должность,'') <> isnull(s.Должность,'')
				OR t.lk_updated_at <> s.lk_updated_at
			)
			AND s.Должность IS NOT NULL
		then update SET
			t.Должность = s.Должность,
			t.lk_updated_at = s.lk_updated_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
		WHEN MATCHED
			AND s.Должность IS NULL
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
