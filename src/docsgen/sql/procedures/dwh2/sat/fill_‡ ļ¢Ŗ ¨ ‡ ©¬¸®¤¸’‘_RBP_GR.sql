/*
exec sat.fill_ЗаявкаНаЗаймПодПТС_RBP_GR @mode = 0
*/
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_RBP_GR
	@mode int = 1,
	@RequestNumber nvarchar(30) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_RBP_GR
begin TRY
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion_loginom binary(8) = 0x0
	--declare @updated_at datetime = '1900-01-01'
	DECLARE @Number bigint = CAST(@RequestNumber AS bigint)

	--if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_RBP_GR') is not null
	--	AND @mode = 1
	--	and @RequestNumber is NULL
	--begin
	--	SELECT 
	--		@rowVersion_loginom = isnull(max(S.ВерсияДанных_loginom), 0x0)
	--		--@updated_at = dateadd(MINUTE, -60, isnull(max(S.updated_at), '1900-01-01'))
	--	FROM sat.ЗаявкаНаЗаймПодПТС_RBP_GR AS S
	--end

	DROP TABLE IF EXISTS #t_RBP_GR

	;with risk_apr_segment as --повтор кода из dbo.tvf_risk_apr_segment
	(
		SELECT --top 10
			a.number
			,RBP_GR = 
				CASE 
					WHEN a.client_type = '1.NEW'
						THEN cast(a.RBP_GR_FOR_SALES as nvarchar(255))
							 ELSE NULL
				END
			--,client_type = a.client_type_for_sales
		FROM risk.applications as a
		where 1=1
			and (a.number = @RequestNumber or @RequestNumber is null)
	)
	select 
		 НомерЗаявки = t.number
		,RBP_GR = isnull(cast(rr.APR_SEGMENT as nvarchar(255)), t.rbp_gr)
		--,client_type = isnull(rr.return_type, t.client_type)
	into #t_RBP_GR
	from risk_apr_segment as t
		left join risk.retro_risk_apr_segment as rr
			on rr.number = t.number
	where isnull(cast(rr.APR_SEGMENT as nvarchar(255)), t.rbp_gr) is not null
	union
	select 
		НомерЗаявки = rr.number
		,RBP_GR = rr.APR_SEGMENT
		--,client_type = rr.return_type
	from risk.retro_risk_apr_segment as rr
	where 1=1
		and rr.APR_SEGMENT is not null
		and (rr.number = @RequestNumber or @RequestNumber is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_RBP_GR
		SELECT * INTO ##t_RBP_GR FROM #t_RBP_GR
	END

	DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС_RBP_GR

	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,
		RBP_GR = nullif(trim(RBP.RBP_GR),''),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		--ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
		ВерсияДанных_loginom = cast(null as binary(8)) --RBP.ВерсияДанных_loginom
	into #t_ЗаявкаНаЗаймПодПТС_RBP_GR
	--SELECT *
	FROM #t_RBP_GR AS RBP
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.НомерЗаявки = RBP.НомерЗаявки

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_RBP_GR
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_RBP_GR FROM #t_ЗаявкаНаЗаймПодПТС_RBP_GR
		--test
		--return 0
	END

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_RBP_GR') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            RBP_GR,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных_loginom
		into sat.ЗаявкаНаЗаймПодПТС_RBP_GR
		from #t_ЗаявкаНаЗаймПодПТС_RBP_GR

		alter table sat.ЗаявкаНаЗаймПодПТС_RBP_GR
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_RBP_GR
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_RBP_GR PRIMARY KEY CLUSTERED (GuidЗаявки)

		CREATE INDEX ix_ВерсияДанных_loginom
		ON sat.ЗаявкаНаЗаймПодПТС_RBP_GR(ВерсияДанных_loginom)
	end

	merge sat.ЗаявкаНаЗаймПодПТС_RBP_GR AS t
	using #t_ЗаявкаНаЗаймПодПТС_RBP_GR AS s
		on t.GuidЗаявки = s.GuidЗаявки
	when not MATCHED
		AND s.RBP_GR IS NOT NULL
	THEN insert
	(
		СсылкаЗаявки,
        GuidЗаявки,
        RBP_GR,
        created_at,
        updated_at,
        spFillName,
        ВерсияДанных_loginom
	) values
	(
		s.СсылкаЗаявки,
        s.GuidЗаявки,
        s.RBP_GR,
        s.created_at,
        s.updated_at,
        s.spFillName,
		s.ВерсияДанных_loginom
	)
	when matched 
		AND (isnull(t.RBP_GR, '') != isnull(s.RBP_GR, '')
			--OR t.ВерсияДанных_loginom != s.ВерсияДанных_loginom
		)
		AND s.RBP_GR IS NOT NULL
	then update SET
		t.RBP_GR = s.RBP_GR,
		t.updated_at = s.updated_at,
		t.spFillName = s.spFillName,
		t.ВерсияДанных_loginom = s.ВерсияДанных_loginom
	WHEN MATCHED
		AND s.RBP_GR IS NULL
	then DELETE
	;


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
