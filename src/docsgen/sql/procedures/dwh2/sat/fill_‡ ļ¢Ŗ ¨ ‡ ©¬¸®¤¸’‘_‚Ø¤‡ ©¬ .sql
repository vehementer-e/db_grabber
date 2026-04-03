CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ВидЗайма
	@mode int = 1,
	@RequestNumber nvarchar(30) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ВидЗайма
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ВидЗайма
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ВидЗайма') is not null
		AND @mode = 1
		and @RequestNumber is NULL
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ВидЗайма), 0x0)
		SELECT 
			@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(max(S.updated_at), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_ВидЗайма AS S
	end

	DROP TABLE IF EXISTS #t_ВидЗайма
	CREATE TABLE #t_ВидЗайма(
		--СсылкаЗаявки binary(16),
		НомерЗаявки nvarchar(20),
		--GuidЗаявки nvarchar(36),
		ВидЗайма nvarchar(50),
		ПриоритетИсточника smallint
	)

	/*
	-- ПриоритетИсточника = 1
	INSERT #t_ВидЗайма
	(
	    НомерЗаявки,
	    ВидЗайма,
	    ПриоритетИсточника
	)
	SELECT DISTINCT
		НомерЗаявки = cast(R.number as nvarchar(20)),
		ВидЗайма = R.return_type,
		ПриоритетИсточника = 1
	--select count(*) --839330
	--select TOP 100 *
	FROM dwh_new.dbo.risk_apr_segment AS R
	WHERE isnumeric(R.number) = 1


	-- ПриоритетИсточника = 2
	INSERT #t_ВидЗайма
	(
	    НомерЗаявки,
	    ВидЗайма,
	    ПриоритетИсточника
	)
	SELECT DISTINCT
		НомерЗаявки = external_id,
		ВидЗайма = R.return_type,
		ПриоритетИсточника = 2
	--select count(*) --17789 / 1209745
	--select TOP 100 *
	FROM dwh_new.dbo.tmp_v_requests AS R
	WHERE 1=1
		AND R.updated >= dateadd(DAY, -2, @updated_at)
	*/

	-- risk.retro_risk_apr_segment - ПриоритетИсточника = 1
	-- risk.applications - ПриоритетИсточника = 2
	-- поскольку вычисления в одном скрипте, 
	-- пишем ПриоритетИсточника = 1
	;with risk_apr_segment as --повтор кода из dbo.tvf_risk_apr_segment
	(
		SELECT --top 10
			a.number
			--,RBP_GR = 
			--	CASE 
			--		WHEN a.client_type = '1.NEW'
			--			THEN cast(a.RBP_GR_FOR_SALES as nvarchar(255))
			--				 ELSE NULL
			--	END
			,client_type = a.client_type_for_sales
		FROM risk.applications as a
		where 1=1
			and (a.number = @RequestNumber or @RequestNumber is null)
	)
	INSERT #t_ВидЗайма
	(
	    НомерЗаявки,
	    ВидЗайма,
	    ПриоритетИсточника
	)
	select 
		 НомерЗаявки = t.number
		--,RBP_GR = isnull(cast(rr.APR_SEGMENT as nvarchar(255)), t.rbp_gr)
		,ВидЗайма = isnull(rr.return_type, t.client_type)
	    ,ПриоритетИсточника = 1
	from risk_apr_segment as t
		left join risk.retro_risk_apr_segment as rr
			on rr.number = t.number
	where isnull(rr.return_type, t.client_type) is not null
	union
	select 
		НомерЗаявки = rr.number
		--,RBP_GR = rr.APR_SEGMENT
		,ВидЗайма = rr.return_type
	    ,ПриоритетИсточника = 1
	from risk.retro_risk_apr_segment as rr
	where 1=1
		and rr.return_type is not null
		and (rr.number = @RequestNumber or @RequestNumber is null)


	-- ПриоритетИсточника = 3
	INSERT #t_ВидЗайма
	(
	    НомерЗаявки,
	    ВидЗайма,
	    ПриоритетИсточника
	)
	SELECT DISTINCT
		НомерЗаявки = ЗаявкаНаЗаймПодПТС.Номер,
		ВидЗайма = 
			CASE 
				WHEN Докредитование=0xB3603565B63EB9B14723A40BFBC73122 then N'Докредитование'  -- Докредитование
				WHEN Докредитование=0xA8424EE85197CF54453F1F80BDC849D5 then N'Параллельный' -- Параллельный заем
				WHEN [ВидЗайма]=0x974A656AFB7A557B48A6B58E3DECA593     then N'Первичный' -- Новый
				WHEN [ВидЗайма]=0xB201F1B23D6AB42947A9828895F164FE     then N'Повторный'
				ELSE N'' 
			END,
		ПриоритетИсточника = 3
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
	WHERE ЗаявкаНаЗаймПодПТС.ВерсияДанных >= @rowVersion
		and (ЗаявкаНаЗаймПодПТС.Номер = @RequestNumber or @RequestNumber is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ВидЗайма
		SELECT * INTO ##t_ВидЗайма FROM #t_ВидЗайма
	END


	DROP TABLE IF EXISTS #t_ВидЗайма_2
	CREATE TABLE #t_ВидЗайма_2(
		НомерЗаявки nvarchar(20),
		ВидЗайма nvarchar(50)
	)

	INSERT #t_ВидЗайма_2
	(
	    НомерЗаявки,
	    ВидЗайма
	)
	SELECT 
		A.НомерЗаявки,
        A.ВидЗайма
	FROM (
		SELECT 
			V.НомерЗаявки,
			V.ВидЗайма,
			V.ПриоритетИсточника,
			rn = row_number() over(partition BY V.НомерЗаявки order by V.ПриоритетИсточника)
		FROM #t_ВидЗайма AS V
		) AS A
	WHERE A.rn = 1

	CREATE NONCLUSTERED INDEX IX_НомерЗаявки
	ON #t_ВидЗайма_2(НомерЗаявки) INCLUDE (ВидЗайма)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ВидЗайма_2
		SELECT * INTO ##t_ВидЗайма_2 FROM #t_ВидЗайма_2
	END

	select distinct
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.GuidЗаявки,
		ВидЗайма = ВидЗайма.ВидЗайма,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных_CRM AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ВидЗайма
	--SELECT *
	FROM #t_ВидЗайма_2 AS ВидЗайма
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.НомерЗаявки =  ВидЗайма.НомерЗаявки


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ВидЗайма') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            ВидЗайма,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ВидЗайма
		from #t_ЗаявкаНаЗаймПодПТС_ВидЗайма

		alter table sat.ЗаявкаНаЗаймПодПТС_ВидЗайма
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ВидЗайма
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ВидЗайма PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ВидЗайма t
		using #t_ЗаявкаНаЗаймПодПТС_ВидЗайма s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            ВидЗайма,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.ВидЗайма,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.ВидЗайма, '') != isnull(s.ВидЗайма, '')
				OR t.ВерсияДанных != s.ВерсияДанных
			)
			AND s.ВидЗайма IS NOT NULL
		then update SET
			t.ВидЗайма = s.ВидЗайма,
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
