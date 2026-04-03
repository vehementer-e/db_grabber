
-- =============================================
-- Author:        Shubkin Aleksandr
-- Create date:   09.12.2025
-- Description:   Процедура заполнения таблицы информации о входе по заявкам в ЛК
-- exec [sat].[fill_Заявка_LkIpLogOn] 0
-- =============================================
CREATE   PROCEDURE [sat].[fill_Заявка_LkIpLogOn]
    @mode INT = 1
AS
BEGIN
 BEGIN TRY
        DECLARE
              @spName        NVARCHAR(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','') + OBJECT_NAME(@@PROCID)
            , @lastLogOnDate DATETIME;

        IF OBJECT_ID('sat.Заявка_LkIpLogOn') IS NOT NULL
           and @mode = 1
        BEGIN
            SELECT @lastLogOnDate = DATEADD(mi, -100, MAX(LogOnDate))
            FROM   sat.Заявка_LkIpLogOn;
			--drop index cix on  sat.Заявка_LkIpLogOn
			--create clustered index cix_GuidЗаявки_Ip_LogOnDate on  sat.Заявка_LkIpLogOn(
			--	GuidЗаявки 
			--	,Ip         
			--	,LogOnDate  
			--)
			--create index ix_LogOnDate on sat.Заявка_LkIpLogOn(LogOnDate)
        END
        
		set @lastLogOnDate = isnull(@lastLogOnDate, '2000-01-01')

        DROP TABLE IF EXISTS #t_Заявка_LkIpLogOn;
		
			
		drop table if exists #t_changes
		SELECT 
			  request_id
			, rcip.Id		--stg._lk.request_client_ip.Id
			, Ip           = ip_split.value            -- stg._lk.request_client_ip->ip
			, UserAgent    = rcip.useragent        -- stg._lk.request_client_ip->useragent
			, LogOnDate    = rcip.updated_at       -- stg._lk.request_client_ip->updated_at
			, nRow = ROW_NUMBER () over(partition by request_id,rcip.updated_at, ip_split.value order by rcip.updated_at  desc) 
		into #t_changes
		FROM stg._lk.request_client_ip rcip       with(index =[ix_updated_at]) 
		CROSS APPLY (
			SELECT trim(value) AS value
			FROM STRING_SPLIT(rcip.ip, ',')
		) AS ip_split                                
		where  rcip.updated_at >= @lastLogOnDate
			--and ip_split.value not in ('10.184.5.65') --internal ip

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

        SELECT 
              GuidЗаявки   = h.GuidЗаявки          -- hub.Заявка->GuidЗаявки
            , СсылкаЗаявки = h.СсылкаЗаявки        -- hub.Заявка->СсылкаЗаявки
			, LogOnId	   = rcip.Id
            , Ip           = rcip.ip			-- stg._lk.request_client_ip->ip
            , UserAgent    = rcip.useragent        -- stg._lk.request_client_ip->useragent
            , LogOnDate    = rcip.LogOnDate       -- stg._lk.request_client_ip->updated_at
            , created_at   = GETDATE()
            , updated_at   = GETDATE()
            , spFillName   = @spName
        INTO #t_Заявка_LkIpLogOn
        FROM #t_changes  rcip
        JOIN stg._lk.requests r
            ON rcip.request_id = r.id
           AND NOT EXISTS (
                SELECT TOP(1) 1
                FROM stg._lk.contracts c
                WHERE c.request_id = r.id
				and rcip.LogOnDate>=c.created_at
           )
        JOIN dwh2.hub.Заявка h
            ON h.НомерЗаявки = r.num_1c
			
      
		create clustered index cix on #t_Заявка_LkIpLogOn (GuidЗаявки, Ip, LogOnId)

        BEGIN TRAN;
			if @mode = 0
			begin
				truncate table  sat.Заявка_LkIpLogOn
			end
			  /*
				alter table   sat.Заявка_LkIpLogOn
					add  LogOnId  bigint
			  */
            ;MERGE sat.Заявка_LkIpLogOn AS T
            USING #t_Заявка_LkIpLogOn        AS S
               ON  T.GuidЗаявки = S.GuidЗаявки
                AND T.Ip        = S.Ip
			   and t.LogOnId	= S.LogOnId
            WHEN NOT MATCHED THEN
                INSERT
                (
                      GuidЗаявки
                    , СсылкаЗаявки
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
                      S.GuidЗаявки
                    , S.СсылкаЗаявки
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
                     T.LogOnDate  = s.LogOnDate
					, T.UserAgent  = S.UserAgent
                    , T.updated_at = S.updated_at
                    , T.spFillName = S.spFillName;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
	   IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        

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

     	 THROW;
    END CATCH
END
