-- =============================================
-- Author: Shubkin Aleksandr
-- Create date: 09.12.2025
-- DEscription:   Процедура заполненния таблицы информаицей о входе клиентов в лк?
-- 	 [sat].[fill_Клиент_LkIpLogOn] 0 
-- =============================================
CREATE   PROCEDURE [sat].[fill_Клиент_LkIpLogOn]
    @mode INT = 1
AS
BEGIN
BEGIN TRY
DECLARE
	@spName        NVARCHAR(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','') + OBJECT_NAME(@@PROCID)
  , @lastLogOnDate DATETIME;
	
	IF OBJECT_ID('sat.Клиент_LkIpLogOn') IS NOT NULL
       and @mode = 1
    BEGIN
        SELECT @lastLogOnDate = DATEADD(MINUTE, -100, MAX(LogOnDate))
        FROM   sat.Клиент_LkIpLogOn;

	
    END
	SET @lastLogOnDate = isnull(@lastLogOnDate, '2000-01-01')

    -- изменения
	DROP TABLE IF EXISTS #t_changes;
	SELECT 
		ui.user_id
		, ui.Id
        , Ip           = ip_split.value                        -- stg._lk.user_ip->ip (разрезанный)
        , UserAgent    = ui.useragent                                -- stg._lk.user_ip->useragent
        , LogOnDate    = ui.updated_at
		, nRow = ROW_NUMBER () over(partition by ui.user_id, ip_split.value, ui.updated_at order by ui.updated_at  desc)
    INTO #t_changes
    FROM stg._lk.user_ip ui
    CROSS APPLY (
		SELECT TRIM(value) AS value
		FROM STRING_SPLIT(ui.ip, ',')
	) AS ip_split
	where  ui.updated_at >= @lastLogOnDate
	  
	create clustered index ix_request_id on #t_changes(user_id)
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

    DROP TABLE IF EXISTS #t_Клиент_LkIpLogOn;
    SELECT
          GuidКлиент   = h.GuidКлиент                                -- hub.Клиенты->GuidКлиент
        , СсылкаКлиент = h.СсылкаКлиент                              -- hub.Клиенты->СсылкаКлиент
		, LogOnId	   = ui.Id
        , Ip           = ui.Ip                        -- stg._lk.user_ip->ip (разрезанный)
        , UserAgent    = ui.useragent                                -- stg._lk.user_ip->useragent
        , LogOnDate    = ui.LogOnDate                               -- stg._lk.user_ip->updated_at
        , created_at   = getdate()
        , updated_at   = getdate()
        , spFillName   = @spName
    INTO #t_Клиент_LkIpLogOn
    FROM #t_changes ui
    JOIN stg._lk.users u
        ON u.id = ui.user_id
       AND NULLIF(u.external_guid, '') IS NOT NULL
    JOIN hub.Клиенты h
        ON CAST(h.GuidКлиент AS NVARCHAR(36)) = u.external_guid;

		create clustered index cix on #t_Клиент_LkIpLogOn (GuidКлиент, Ip, LogOnId)
	BEGIN TRAN;
		if @mode = 0
		begin
			truncate table  sat.Клиент_LkIpLogOn

			/*
				alter table   sat.Клиент_LkIpLogOn
					add	LogOnId bigint
				 drop index cix_GuidКлиент_Ip_LogOnDate on [sat].[Клиент_LkIpLogOn]
				create clustered index cix_GuidКлиент_Ip_LogOnId on [sat].[Клиент_LkIpLogOn]
				(GuidКлиент,Ip,LogOnId)
				 
			*/
		end
		;MERGE sat.Клиент_LkIpLogOn AS T
		USING #t_Клиент_LkIpLogOn   AS S
           ON  T.GuidКлиент = S.GuidКлиент
           AND T.Ip         = S.Ip
		   and t.LogOnId	= s.LogOnId
           
        WHEN NOT MATCHED THEN
            INSERT
            (
                  GuidКлиент
                , СсылкаКлиент
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
                  S.GuidКлиент
                , S.СсылкаКлиент
				, S.LogOnId
                , S.Ip
                , S.UserAgent
                , S.LogOnDate
                , S.created_at
                , S.updated_at
                , S.spFillName
            )
        WHEN MATCHED THEN
			UPDATE SET
				 t.LogOnDate =  s.LogOnDate
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
            , 'Line: '          , CAST(ERROR_LINE()     AS NVARCHAR(50)) , CHAR(13)
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
