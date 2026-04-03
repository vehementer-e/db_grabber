
CREATE   
proc [dbo].[lead_creation]
@ids 	[CARM\P.Ilin].[leadType]  readonly  	 ,
@start_date date  = null
--create type [CARM\P.Ilin].[leadType] as table (id varchar(36)) --from varchar(36) not null
as
begin

--declare  @ids	leadType    declare  @start_date	date      
-- insert into 	@ids select id from lead where entrypoint='uni_api'
drop table if exists #id
select id into #id from 	@ids
where 1=0

   select count( id) to_update from @ids

if not exists(select top 1 * from @ids where id is not null)
begin



 
--begin tran
--DECLARE @Result_0 INT;
--EXEC @Result_0 = sp_getapplock @Resource = 'MergeLock', @LockMode = 'Exclusive'--, @LockTimeout = 300000; -- 5 минут

--IF @Result_0 >= 0
--BEGIN
--BEGIN TRY
--  select 1 d

--EXEC sp_releaseapplock @Resource = 'MergeLock';

--COMMIT TRANSACTION;								    
--END TRY
--BEGIN CATCH
--        -- Освобождение блокировки в случае ошибки
--        EXEC sp_releaseapplock @Resource = 'MergeLock';
--        exec analytics.dbo.log_email 'lead_creation error доступ к обновленным записям'
--        -- Обработка ошибок
--        ROLLBACK TRANSACTION;
--        THROW;
--END CATCH
--END
--ELSE
--BEGIN
---- Не удалось получить блокировку, обработка ошибки
--PRINT 'Не удалось получить блокировку';
-- exec analytics.dbo.log_email 'lead_creation critical error доступ к обновленным записям'

--ROLLBACK TRANSACTION;
--END



insert into   #id
--declare  @start_date date	 = getdate()-1

 select top 100000 a.id  from	stg._lf.lead a with(nolock)
left join  feodor.dbo.[lead] b  with(nolock)  on a.id=b.id 
WHERE --a.created_at_time >= GETDATE() - 1 and
  a.updated_at>datediff( second, '19700101',  dateadd(hour, -3,  isnull(  b.[ДатаОбновленияСтроки] 	, '20010101')	)) 
and a.updated_at >= datediff( second, '19700101', dateadd(hour, -3,   cast( isnull(@start_date, getdate()+1) as  datetime)))-- and dateadd(minute, -5, getdate())
 
 
 		-- dateadd(second, lead.updated_at   , '19700101'  )
 
 
 
 select '@ids is empty', 'Извлекаем из v_lead обновленные строки' , @@ROWCOUNT , 'извлечено'	, '@start_date=', @start_date


end

else 
select '@ids is not empty'

insert into   #id
select a.id  from 	@ids   a
--left join  feodor.dbo.[lead] b on a.id=b.id 
 WHERE  a.id  is not null--a.created_at_time >= GETDATE() - 1 and
--b.uf_registered_at is null

   --select count( id) to_update from #id

  declare @t datetime = getdate()
 drop table if exists #lead_stg
		  -- Step 1: Select data into a temporary table
SELECT 	 
    a.id AS [ID],
    a.phone AS [UF_PHONE],
    a.created AS [UF_REGISTERED_AT],
    NULL AS [UF_ROW_ID],
    a.type AS [UF_TYPE],
    NULL AS [UF_RC_REJECT_CM],
    a.channel AS [UF_LOGINOM_CHANNEL],
    a.channel_GROUP AS [UF_LOGINOM_GROUP],
    a.mms_priority AS [UF_LOGINOM_PRIORITY],
    a.marketing_status AS [UF_LOGINOM_STATUS],
    a.source AS [UF_SOURCE],
    a.channel AS [Канал от источника],
    a.channel_GROUP AS [Группа каналов],
    a.PARTNER_ID AS [UF_PARTNER_ID],
    a.decline_reason AS [UF_LOGINOM_DECLINE],
    a.STAT_TYPE AS [UF_STAT_AD_TYPE],
    a.appmetrica AS [UF_APPMECA_TRACKER],
    a.stat_source AS [uf_stat_source],
    a.region AS [uf_regions_composite],
    a.STAT_CAMPAIGN AS [UF_STAT_CAMPAIGN],
    a.entrypoint AS [entrypoint] 	,
	a.updated_at 	 AS	 [ДатаОбновленияСтроки]
	, b.id id_for_update
	,A.VISIT_ID
	,A.STAT_SYSTEM
	,A.STAT_TERM
	,A.STAT_INFO
	, a.sum 
	, a.userAgent  userAgent
	, a.product
INTO #lead_stg
FROM #id b left join  Analytics.dbo.v_lead a  with(nolock) 	  on a.id=b.id--	and a.status<>'RECEIVED'  and a. channel is not null 
--where a.created>=isnull(@start_date, getdate()+1)

--select cast('' as nvarchar(36)) id ,  cast('' as nvarchar(300)) description , getdate() created into lead_failed_creation
insert into   lead_failed_creation
select 	id_for_update, '', @t  from 	 #lead_stg where id is null
select @@ROWCOUNT, 'не было в v_lead сохранены в lead_failed_creation'

 drop table if exists #lead 

   select 
             id = source.id,
             [ДатаОбновленияСтроки] = source.[ДатаОбновленияСтроки],
             [ДатаЛидаЛСРМ] = CAST(source.[UF_REGISTERED_AT] AS DATE),
             [UF_PHONE] = source.[UF_PHONE],
             [UF_REGISTERED_AT] = source.[UF_REGISTERED_AT],
             [UF_TYPE] = source.[UF_TYPE],
             [UF_LOGINOM_CHANNEL] = source.[UF_LOGINOM_CHANNEL],
             [UF_LOGINOM_GROUP] = source.[UF_LOGINOM_GROUP],
             [UF_LOGINOM_PRIORITY] = source.[UF_LOGINOM_PRIORITY],
             [UF_LOGINOM_STATUS] = source.[UF_LOGINOM_STATUS],
             [Канал от источника] = source.[Канал от источника],
             [Группа каналов] = source.[Группа каналов],
             [UF_PARTNER_ID аналитический] = case when source.[UF_SOURCE] ='finkort-api' then '*' else  source.[UF_PARTNER_ID] end ,
             [UF_LOGINOM_DECLINE] = source.[UF_LOGINOM_DECLINE],
             [UF_STAT_AD_TYPE] = source.[UF_STAT_AD_TYPE],
             [UF_APPMECA_TRACKER] = source.[UF_APPMECA_TRACKER],
             [uf_stat_source] = source.[uf_stat_source],
             [UF_SOURCE] = source.[UF_SOURCE],
             [uf_regions_composite] = source.[uf_regions_composite],
             [UF_STAT_CAMPAIGN] = source.[UF_STAT_CAMPAIGN],
             [entrypoint] = source.[entrypoint],
             [is_inst_lead] = analytics.[dbo].[lcrm_is_inst_lead] (source.[UF_TYPE], source.[UF_SOURCE], NULL),
             [IsInstallment] = analytics.[dbo].[lcrm_is_inst_lead] (source.[UF_TYPE], source.[UF_SOURCE], NULL)		 
	,source.VISIT_ID
	,source.STAT_SYSTEM
	,source.STAT_TERM
	,source.STAT_INFO
	,source.sum
	,source.userAgent
	,source.product
  
	into 	#lead
	from #lead_stg source
	where id is not null
	
	;

	with v as (select *, row_number() over(partition by id order by [ДатаОбновленияСтроки] desc) rn  from #lead ) insert into  lead_failed_creation
select 	id, 'dubl', @t  from 	 v where rn=2

	;

	with v as (select *, row_number() over(partition by id order by [ДатаОбновленияСтроки] desc) rn from #lead ) delete from v where rn>1
 ;

begin tran
DECLARE @Result INT;
EXEC @Result = sp_getapplock @Resource = 'MergeLock', @LockMode = 'Exclusive'--, @LockTimeout = 300000; -- 5 минут

IF @Result >= 0
BEGIN
    BEGIN TRY

	  --declare    @Result INT = 0
--if @Result>0 begin
--declare @sql nvarchar(max) 
--set @sql =  'exec analytics.dbo.log_email ''lead_creation start @result='+format(@Result,'0')+'''	' 
--exec  (@sql)	  end

--declare @a leadtype  insert into  @a select a.id from  lead a   join  Analytics.dbo.v_lead b on a.id=b.id and isnull(a.[uf_stat_source], '') <>isnull( b.stat_source	, '') 
 		    MERGE feodor.dbo.[lead] AS target
    USING (SELECT * FROM #lead ) AS source
    ON target.ID = source.ID
    WHEN MATCHED THEN
        UPDATE SET
            target.[ДатаОбновленияСтроки] = source.[ДатаОбновленияСтроки],
            target.[ДатаЛидаЛСРМ] = source.[ДатаЛидаЛСРМ],
            target.[UF_PHONE] = source.[UF_PHONE],
            target.[UF_REGISTERED_AT] = source.[UF_REGISTERED_AT],
            target.[UF_TYPE] = source.[UF_TYPE],
            target.[UF_LOGINOM_CHANNEL] = source.[UF_LOGINOM_CHANNEL],
            target.[UF_LOGINOM_GROUP] = source.[UF_LOGINOM_GROUP],
            target.[UF_LOGINOM_PRIORITY] = source.[UF_LOGINOM_PRIORITY],
            target.[UF_LOGINOM_STATUS] = source.[UF_LOGINOM_STATUS],
            target.[Канал от источника] = source.[Канал от источника],
            target.[Группа каналов] = source.[Группа каналов],
            target.[UF_PARTNER_ID аналитический] = source.[UF_PARTNER_ID аналитический],
            target.[UF_LOGINOM_DECLINE] = source.[UF_LOGINOM_DECLINE],
            target.[UF_STAT_AD_TYPE] = source.[UF_STAT_AD_TYPE],
            target.[UF_APPMECA_TRACKER] = source.[UF_APPMECA_TRACKER],
            target.[uf_stat_source] = source.[uf_stat_source],
            target.[UF_SOURCE] = source.[UF_SOURCE],
            target.[uf_regions_composite] = source.[uf_regions_composite],
            target.[UF_STAT_CAMPAIGN] = source.[UF_STAT_CAMPAIGN],
            target.[entrypoint] = source.[entrypoint],
            target.[is_inst_lead] = source.[is_inst_lead] ,
           -- target.[IsInstallment] = source.[IsInstallment] ,
		    target.VISIT_ID		=source.VISIT_ID  ,
		    target.STAT_SYSTEM	=source.STAT_SYSTEM	   ,
		    target.STAT_TERM	=	source.STAT_TERM   ,
		    target.STAT_INFO	=	source.STAT_INFO   ,
            target.row_updated = getdate() ,
			target.sum = case when target.sum is  null  then  source.sum  else target.sum end ,
			target.userAgent = case when target.userAgent is  null  then  source.userAgent  else target.userAgent end ,
			target.product = case when target.product is  null  then  source.product  else target.product end 
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            [ДатаОбновленияСтроки],
            [ДатаЛидаЛСРМ],
            [ID],
            [UF_PHONE],
            [UF_REGISTERED_AT],
            [UF_TYPE],
            [UF_LOGINOM_CHANNEL],
            [UF_LOGINOM_GROUP],
            [UF_LOGINOM_PRIORITY],
            [UF_LOGINOM_STATUS],
            [Канал от источника],
            [Группа каналов],
            [UF_PARTNER_ID аналитический],
            [UF_LOGINOM_DECLINE],
            [UF_STAT_AD_TYPE],
            [UF_APPMECA_TRACKER],
            [uf_stat_source],
            [UF_SOURCE],
            [uf_regions_composite],
            [UF_STAT_CAMPAIGN],
            [entrypoint],
            [is_inst_lead],
            [IsInstallment]	  ,
            row_created	  ,
            row_updated	,
			 VISIT_ID	,
		     STAT_SYSTEM 	   ,
		     STAT_TERM	 ,
		     STAT_INFO	 ,
			 sum ,
			 userAgent,
			 product
        )
        VALUES (
            source.[ДатаОбновленияСтроки],
            source.[ДатаЛидаЛСРМ],
            source.[ID],
            source.[UF_PHONE],
            source.[UF_REGISTERED_AT],
            source.[UF_TYPE],
            source.[UF_LOGINOM_CHANNEL],
            source.[UF_LOGINOM_GROUP],
            source.[UF_LOGINOM_PRIORITY],
            source.[UF_LOGINOM_STATUS],
            source.[Канал от источника],
            source.[Группа каналов],
            source.[UF_PARTNER_ID аналитический],
            source.[UF_LOGINOM_DECLINE],
            source.[UF_STAT_AD_TYPE],
            source.[UF_APPMECA_TRACKER],
            source.[uf_stat_source],
            source.[UF_SOURCE],
            source.[uf_regions_composite],
            source.[UF_STAT_CAMPAIGN],
            source.[entrypoint],
            source.[is_inst_lead],
            source.[IsInstallment] 	,
			getdate(),
			getdate()		 ,
			 VISIT_ID	,
		     STAT_SYSTEM 	   ,
		     STAT_TERM	 ,
		     STAT_INFO	 ,
		     sum	  ,
		     userAgent	 ,
		     product	  
        );

		declare @rc bigint = @@ROWCOUNT
		select @rc, 'updated rows lead creation'


		EXEC sp_releaseapplock @Resource = 'MergeLock';

        COMMIT TRANSACTION;
      --  exec analytics.dbo.log_email 'lead_creation ok'

	    END TRY
    BEGIN CATCH
        -- Освобождение блокировки в случае ошибки
        EXEC sp_releaseapplock @Resource = 'MergeLock';
        exec analytics.dbo.log_email 'lead_creation error transaction'
        -- Обработка ошибок
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
ELSE
BEGIN
    -- Не удалось получить блокировку, обработка ошибки
    PRINT 'Не удалось получить блокировку';
     exec analytics.dbo.log_email 'lead_creation critical error Не удалось получить блокировку'

    ROLLBACK TRANSACTION;
END
-- Optional: Drop the temporary table if no longer needed
-- DROP TABLE #lead;
--if @rc=10000000
--begin
--drop table if exists #id
--select 'again', getdate()
--exec lead_creation   default, @start_date
--end
--end

--alter  table [lead] add   row_created datetime2
--alter  table [lead] add   row_updated datetime2
--alter  table [lead] add   VISIT_ID NVARCHAR(36)
--alter  table [lead] add   STAT_SYSTEM NVARCHAR(255)
--alter  table [lead] add   STAT_TERM NVARCHAR(255)
--alter  table [lead] add   STAT_INFO NVARCHAR(255)
--alter  table [lead] add   product NVARCHAR(10)


	
 

end


