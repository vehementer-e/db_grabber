
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_FedorЗаявка
	@mode int = 1
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'
	SELECT @mode = isnull(@mode, 1)
	drop table if exists #t_ЗаявкаНаЗаймПодПТС_FedorЗаявка

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка') is not null
		and @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка), 0x0)
		SELECT 
			@rowVersion = isnull(max(S.ВерсияДанных) - 1000, 0x0),
			@updated_at = isnull(dateadd(DAY, -1, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки uniqueidentifier)

	--1
	INSERT #t_Заявки(GuidЗаявки)
	SELECT fedor_Заявка.Id 
	FROM Stg._fedor.core_ClientRequest AS fedor_Заявка
	--WHERE fedor_Заявка.DWHInsertedDate >= @updated_at
	WHERE fedor_Заявка.RowVersion > @rowVersion

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	--2
	INSERT #t_Заявки(GuidЗаявки)
	SELECT A.Id 
	FROM (
		SELECT Id from stg._fedor.core_ClientRequest 
		except
		select GuidЗаявки from sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка
		) A
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_Заявки AS T WHERE T.GuidЗаявки = A.Id)

	--DROP TABLE IF EXISTS #t_Заявки_2
	--CREATE TABLE #t_Заявки_2(GuidЗаявки uniqueidentifier)
	--INSERT #t_Заявки_2(GuidЗаявки)
	--SELECT DISTINCT Заявки.GuidЗаявки 
	--FROM #t_Заявки AS Заявки

	--CREATE INDEX IX1
	--ON #t_Заявки_2(GuidЗаявки)


	select distinct
		СсылкаЗаявки = Заявка.СсылкаЗаявки,
		GuidЗаявки = Заявка.GuidЗаявки,
		--feodor_request_id = fedor_Заявка.Id,
		feodor_lead_id = fedor_Заявка.IdLead,
		РекомендованнаяСтавка = isnull(fedor_Заявка.AprRecommended, fedor_Заявка.PercentApproved),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(fedor_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_FedorЗаявка
	FROM (
		SELECT 
			fedorЗаявка.Id,
			fedorЗаявка.IdLead,
			fedorЗаявка.AprRecommended, 
			fedorЗаявка.PercentApproved,
			fedorЗаявка.RowVersion,
			rn = row_number() OVER(PARTITION BY fedorЗаявка.Id ORDER BY fedorЗаявка.RowVersion DESC)
		FROM #t_Заявки AS T
			INNER JOIN Stg._fedor.core_ClientRequest AS fedorЗаявка
				ON fedorЗаявка.Id = T.GuidЗаявки
		) AS fedor_Заявка
	INNER JOIN hub.Заявка AS Заявка
		ON Заявка.GuidЗаявки = fedor_Заявка.Id
	WHERE fedor_Заявка.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			--feodor_request_id,
			feodor_lead_id,
            РекомендованнаяСтавка,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка
		from #t_ЗаявкаНаЗаймПодПТС_FedorЗаявка

		alter table sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_FedorЗаявка PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_FedorЗаявка t
		using #t_ЗаявкаНаЗаймПодПТС_FedorЗаявка s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			--feodor_request_id,
			feodor_lead_id,
            РекомендованнаяСтавка,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			--s.feodor_request_id,
			s.feodor_lead_id,
            s.РекомендованнаяСтавка,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched 
			AND t.ВерсияДанных != s.ВерсияДанных
		then update SET
			--t.feodor_request_id = s.feodor_request_id,
			t.feodor_lead_id = s.feodor_lead_id,
			t.РекомендованнаяСтавка = s.РекомендованнаяСтавка,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных
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
