
CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
	@mode int = 1 -- 0 - full, 1 - increment, 2 - from dbo.СписокЗаявокДляПересчетаDataVault
	--,@Guids nvarchar(max) = null 
	,@request_bin_id binary(16) = null
	,@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма') is not null
		AND @mode in (1, 2)
		and @request_bin_id is null
	begin
		SELECT 
			@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(max(S.updated_at), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма AS S
	end

	DROP TABLE IF EXISTS #t_requests_with_cp
	CREATE TABLE #t_requests_with_cp(
		СсылкаЗаявки binary(16)
	)

	INSERT #t_requests_with_cp(СсылкаЗаявки)
	SELECT DISTINCT a.Ссылка
	--SELECT count(*) --166565
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги AS a 
		INNER JOIN Stg._1cCRM.Справочник_ДополнительныеУслуги AS b
			ON a.ДопУслуга = b.Ссылка
			AND b.СнижаетСтавку = 1
			AND a.Включена = 1
	where 1=1
		and (a.Ссылка = @request_bin_id or @request_bin_id is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_requests_with_cp
		SELECT * INTO ##t_requests_with_cp FROM #t_requests_with_cp
	END

	DROP TABLE IF EXISTS #t_loginom_sum_apr
	CREATE TABLE #t_loginom_sum_apr(
		СсылкаЗаявки binary(16),
		[Одобренная сумма Логином] numeric(10, 2)
	)

	INSERT #t_loginom_sum_apr(
		СсылкаЗаявки,
		[Одобренная сумма Логином]
	)
	select 
		a.Ссылка, 
		[Одобренная сумма Логином] =
			CASE 
				WHEN r_wcp.СсылкаЗаявки is not null THEN z_s_kp.Сумма 
				ELSE z_bez_kp.Сумма 
			END 
	--SELECT count(*), count(DISTINCT a.Ссылка) --46251	46098
	from Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS a
		LEFT join stg._1ccrm.Справочник_КредитныеПродукты b 
			ON a.КредитныйПродукт=b.Ссылка
		LEFT join stg._1ccrm.РегистрСведений_ВариантыСуммЛогином AS z_bez_kp
			ON z_bez_kp.Заявка=a.Ссылка 
			AND z_bez_kp.СнижаетСтавку=0 
			AND b.КодДлительностиПродукта=z_bez_kp.Срок
			and z_bez_kp.ПодТипКредитногоПродукта = a.ПодТипКредитногоПродукта
		LEFT join stg._1ccrm.РегистрСведений_ВариантыСуммЛогином AS z_s_kp 
			ON z_s_kp.Заявка=a.Ссылка 
			AND z_s_kp.СнижаетСтавку=1
			AND b.КодДлительностиПродукта=z_s_kp.Срок
			and z_s_kp.ПодТипКредитногоПродукта = a.ПодТипКредитногоПродукта
		LEFT join #t_requests_with_cp AS r_wcp
			ON r_wcp.СсылкаЗаявки = a.Ссылка
	where isnull(z_s_kp.Сумма , z_bez_kp.Сумма ) is not null
		and (a.Ссылка = @request_bin_id or @request_bin_id is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_loginom_sum_apr_0
		SELECT * INTO ##t_loginom_sum_apr_0 FROM #t_loginom_sum_apr
	END

	;with v as (
		SELECT *, row_number() over(partition by СсылкаЗаявки order by (select 1)) rn
		FROM #t_loginom_sum_apr
	)
	DELETE from v where rn > 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_loginom_sum_apr
		SELECT * INTO ##t_loginom_sum_apr FROM #t_loginom_sum_apr
	END

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(СсылкаЗаявки binary(16))

	--1 все заявки из #t_loginom_sum_apr
	INSERT #t_Заявки(СсылкаЗаявки)
	SELECT СсылкаЗаявки FROM #t_loginom_sum_apr

	--2 новые заявки из Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
	INSERT #t_Заявки(СсылкаЗаявки)
	SELECT DISTINCT ЗаявкаНаЗаймПодПТС.Ссылка
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
	WHERE ЗаявкаНаЗаймПодПТС.ВерсияДанных > @rowVersion
		and (ЗаявкаНаЗаймПодПТС.Ссылка = @request_bin_id or @request_bin_id is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявки
		SELECT * INTO ##t_Заявки FROM #t_Заявки
	END

	DROP TABLE IF EXISTS #t_Заявки_2
	CREATE TABLE #t_Заявки_2(СсылкаЗаявки binary(16))

	INSERT #t_Заявки_2(СсылкаЗаявки)
	SELECT DISTINCT Заявки.СсылкаЗаявки
	FROM #t_Заявки AS Заявки

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявки_2
		SELECT * INTO ##t_Заявки_2 FROM #t_Заявки_2
	END


	DROP TABLE IF EXISTS #t_Одобрено
	CREATE TABLE #t_Одобрено(СсылкаЗаявки binary(16))

	INSERT #t_Одобрено(СсылкаЗаявки)
	SELECT DISTINCT СтатусыЗаявок.Заявка
	FROM #t_Заявки_2 AS Заявки
		INNER JOIN Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
			ON СтатусыЗаявок.Заявка = Заявки.СсылкаЗаявки
			AND СтатусыЗаявок.Статус = 0xA81400155D94190011E80784923C609B -- Одобрено

	CREATE INDEX IX1 ON #t_Одобрено(СсылкаЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Одобрено
		SELECT * INTO ##t_Одобрено FROM #t_Одобрено
	END

	select distinct
		hubЗаявка.СсылкаЗаявки,
		hubЗаявка.GuidЗаявки,
		ОдобреннаяСумма = 
			nullif(
				CASE
					WHEN Одобрено.СсылкаЗаявки is not null THEN 
						CASE 
							WHEN lsa.[Одобренная сумма Логином] IS NOT NULL
								THEN lsa.[Одобренная сумма Логином]
							WHEN ЗаявкаНаЗаймПодПТС.ОдобреннаяСуммаВерификаторами = 0 
								THEN iif(ЗаявкаНаЗаймПодПТС.СуммаРекомендуемая > 1000000, 1000000, ЗаявкаНаЗаймПодПТС.СуммаРекомендуемая) 
							WHEN ЗаявкаНаЗаймПодПТС.ОдобреннаяСуммаВерификаторами > 0
								THEN iif(ЗаявкаНаЗаймПодПТС.ОдобреннаяСуммаВерификаторами > 1000000, 1000000, ЗаявкаНаЗаймПодПТС.ОдобреннаяСуммаВерификаторами) 
							ELSE NULL --0
						END
						ELSE NULL --0 
				END,
				0
			),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных = cast(ЗаявкаНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
	--SELECT *
	FROM #t_Заявки_2 AS T
		INNER JOIN hub.Заявка AS hubЗаявка
			ON hubЗаявка.СсылкаЗаявки = T.СсылкаЗаявки
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.Ссылка = T.СсылкаЗаявки
		LEFT JOIN #t_Одобрено AS Одобрено
			ON Одобрено.СсылкаЗаявки = T.СсылкаЗаявки
		LEFT JOIN #t_loginom_sum_apr AS lsa
			ON lsa.СсылкаЗаявки = T.СсылкаЗаявки

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма_0
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма_0 FROM #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
	END

	;WITH dup AS (
		SELECT
			rn = row_number() OVER(PARTITION BY GuidЗаявки ORDER BY ВерсияДанных DESC),
			T.* 
		FROM #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма AS T
		)
	--SELECT * FROM dup WHERE dup.rn > 1
	DELETE dup
	WHERE dup.rn > 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма FROM #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
	END

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            ОдобреннаяСумма,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
		from #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма

		alter table sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма t
		using #t_ЗаявкаНаЗаймПодПТС_ОдобреннаяСумма s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            ОдобреннаяСумма,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.ОдобреннаяСумма,
            s.created_at,
            s.updated_at,
            s.spFillName,
			s.ВерсияДанных
		)
		when matched 
			AND (isnull(t.ОдобреннаяСумма, 0) != isnull(s.ОдобреннаяСумма, 0)
				OR t.ВерсияДанных != s.ВерсияДанных
				or @mode in (0)
			)
		then update SET
			t.ОдобреннаяСумма = s.ОдобреннаяСумма,
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
