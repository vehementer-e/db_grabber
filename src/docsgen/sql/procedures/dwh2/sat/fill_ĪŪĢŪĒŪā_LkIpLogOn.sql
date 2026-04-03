-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--		 [sat].[fill_договор_LkIpLogOn] 0
-- =============================================
CREATE   PROCEDURE [sat].[fill_договор_LkIpLogOn] 
	@mode int = 1
AS
BEGIN
	BEGIN TRY
	DECLARE
      @spName        NVARCHAR(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','') + OBJECT_NAME(@@PROCID)
    , @lastLogOnDate DATETIME2;

    IF OBJECT_ID('sat.договор_LkIpLogOn') IS NOT NULL
       and @mode = 1
    BEGIN
        SELECT @lastLogOnDate = DATEADD(MINUTE, -10, MAX(LogOnDate))
        FROM   sat.договор_LkIpLogOn;
		/*
		create clustered index cix_GuidДоговора_Ip_LogOnDate on
				sat.договор_LkIpLogOn(GuidДоговора,Ip,LogOnDate)
		create index ix_LogOnDate on sat.договор_LkIpLogOn(LogOnDate)
		*/
    END
    SET @lastLogOnDate = isnull(@lastLogOnDate, '2000-01-01')

    -- инкрементальное наполнение
	DROP TABLE IF EXISTS #t_changes
	SELECT
		  request_id
		, rcip.Id			   --stg._lk.request_client_ip.Id
		, Ip             = ip_split.value          -- stg._lk.request_client_ip->ip (разрезанный)
        , UserAgent      = rcip.useragent                -- stg._lk.request_client_ip->useragent
        , LogOnDate      = rcip.updated_at
		, nRow			 = ROW_NUMBER () over(partition by request_id, ip_split.value,rcip.updated_at order by rcip.updated_at  desc) 
	INTO #t_changes
	FROM stg._lk.request_client_ip rcip
	CROSS APPLY (
            SELECT trim(value) AS value
            FROM STRING_SPLIT(rcip.ip, ',')
        ) AS ip_split                                
        where  rcip.updated_at >= @lastLogOnDate
            

	create clustered index ix_request_id on #t_changes( request_id)
            delete from #t_changes
        where nRow>1

		-- @changelog | 17.12.2025 | sh.a.a. | удаление внутренних айпи
		drop table if exists #t_IpPool
		select Ip = Ip
		into #t_IpPool
		from dwh2.dictionary.excludeIp	
		option(maxrecursion 0)

		create clustered index cix_ip on #t_IpPool(Ip)
		delete from #t_changes
		where Ip in (select * from #t_IpPool)
		-- Старая версия: 
		--delete from #t_changes
		--where Ip in ('10.184.5.65') --internal ip

	-- enriched changes 
	DROP TABLE IF EXISTS #t_договор_LkIpLogOn;
    SELECT 
          GuidДоговора   = h.GuidДоговораЗайма          -- hub.ДоговорЗайма->GuidДоговораЗайма
        , СсылкаДоговора = h.СсылкаДоговораЗайма        -- hub.ДоговорЗайма->СсылкаДоговораЗайма
		, LogOnId		 = rcip.Id
        , Ip             = rcip.Ip						-- stg._lk.request_client_ip->ip (разрезанный)
        , UserAgent      = rcip.UserAgent               -- stg._lk.request_client_ip->useragent
        , LogOnDate      = rcip.LogOnDate               -- stg._lk.request_client_ip->updated_at
        , created_at     = GETDATE()
        , updated_at     = GETDATE() 
        , spFillName     = @spName
    INTO #t_договор_LkIpLogOn
    FROM #t_changes rcip
    JOIN stg._lk.contracts c
        ON c.request_id = rcip.request_id
		and rcip.LogOnDate>=c.created_at
    JOIN hub.ДоговорЗайма h 
        ON h.КодДоговораЗайма = c.code
	
	create clustered index cix on #t_договор_LkIpLogOn(GuidДоговора, Ip, LogOnId)

    BEGIN TRAN;
		if @mode = 0
		begin
			truncate table  sat.договор_LkIpLogOn
		end
		
        ;MERGE sat.договор_LkIpLogOn AS T
        USING #t_договор_LkIpLogOn        AS S
           ON  T.GuidДоговора = S.GuidДоговора
		   AND T.Ip         = S.Ip
		   and t.LogOnId	= S.LogOnId
        WHEN NOT MATCHED THEN
            INSERT
            (
                  GuidДоговора
                , СсылкаДоговора
				, LogOnId
                , Ip
                , UserAgent
                , LogOnDate
                , created_at
                , updated_at
                , spFillName
            )
            VALUES
            (
                  S.GuidДоговора
                , S.СсылкаДоговора
				, s.LogOnId
                , S.Ip
                , S.UserAgent
                , S.LogOnDate
                , S.created_at
                , S.updated_at
                , S.spFillName
            )
        WHEN MATCHED THEN
            UPDATE SET
				 t.LogOnDate = s.LogOnDate
				, T.UserAgent  = S.UserAgent
                , T.updated_at = S.updated_at
                , T.spFillName = S.spFillName;
    COMMIT TRAN;
    END TRY
    BEGIN CATCH
        DECLARE 
              @description NVARCHAR(1024)
            , @message     NVARCHAR(1024)
            , @eventType   NVARCHAR(50);

        SET @description = concat(
              'ErrorNumber: '   , CAST(ERROR_NUMBER()   AS NVARCHAR(50)), CHAR(13)
            , 'ErrorSeverity: ' , CAST(ERROR_SEVERITY() AS NVARCHAR(50)), CHAR(13)
            , 'ErrorState: '    , CAST(ERROR_STATE()    AS NVARCHAR(50)) , CHAR(13)
            , 'Procedure: '     , ISNULL(ERROR_PROCEDURE(), '')          , CHAR(13)
            , 'Message: '       , ISNULL(ERROR_MESSAGE(), '')
        );

        SET @message   = 'EXEC ' + @spName;
        SET @eventType = 'Data Vault ERROR';

        EXEC LogDb.dbo.LogAndSendMailToAdmin
              @eventName   = @spName
            , @eventType   = @eventType
            , @message     = @message
            , @description = @description
            , @SendEmail   = 1
            , @SendToSlack = 1;

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END
