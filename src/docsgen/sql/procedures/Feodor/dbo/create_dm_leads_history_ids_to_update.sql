CREATE   PROC [dbo].[create_dm_leads_history_ids_to_update]
	@ProcessGUID uniqueidentifier = NULL,
	@isDebug int = 0
AS
BEGIN

return
				  
insert into feodor.dbo.lead_for_update
select  a.id, 'нет в lead_tbl', getdate() from stg._lf.lead a 
left join Feodor.dbo.lead_tbl b on a.id=b.id
left join feodor.dbo.lead_for_update c on a.id=c.id
where 	  b.[Канал от источника] is null and a.mms_channel_id  is not null and c.id is null
--order by 1


insert into Feodor.dbo.lead_for_update
select a.lead_id, 'feodor_lead', getdate()  from analytics.dbo.v_feodor_leads 
a
left join
Feodor.dbo.lead_tbl b on  a.lead_id  =b.id

left join
Feodor.dbo.lead_for_update c on  a.lead_id =c.id 
where b.id is null and c.id is null and   b.fedorДатаЛида  is null  and a.[Дата лида]  >='20240425'




return
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_description nvarchar(1024)
	DECLARE @StartDate datetime, @ExceptRows int, @ExeptDurationSec int
	DECLARE @InsertRows int, @InsertDurationSec int
	DECLARE @DiffRows int, @DiffDurationSec int
	DECLARE @UpdateRows int = 0, @UpdateDurationSec int
	DECLARE @InsertCalcRows int, @InsertCalcDurationSec int
	DECLARE @LastLogDate datetime

	SELECT @isDebug = isnull(@isDebug, 0)
	SET @ProcessGUID = isnull(@ProcessGUID, newid())

	BEGIN TRY

		SELECT @LastLogDate = max(L.logDateTime) 
		FROM LogDb.dbo._log AS L
		WHERE L.logEventName = 'create_dm_leads_history_ids_to_update'

		--SELECT @LastLogDate = cast(@LastLogDate AS date)
		SELECT @LastLogDate = dateadd(DAY, -3, @LastLogDate)

		IF @LastLogDate IS NULL BEGIN
			SELECT @LastLogDate = cast(dateadd(DAY, -3, getdate()) AS date)
		END

		SELECT @StartDate = getdate()

		DROP TABLE IF EXISTS #t_calculated

		SELECT TOP 0
			C.ID,
			C.[Канал от источника],
			C.UF_LOGINOM_PRIORITY,
			C.UF_LOGINOM_STATUS,
			C.UF_LOGINOM_GROUP,
			C.UF_LOGINOM_CHANNEL,
			C.UF_ROW_ID--,
		INTO #t_calculated
		FROM stg._LCRM.lcrm_leads_full_calculated AS C WITH(nolock)

		INSERT #t_calculated
		SELECT 
			C.ID,
			C.[Канал от источника],
			C.UF_LOGINOM_PRIORITY,
			C.UF_LOGINOM_STATUS,
			C.UF_LOGINOM_GROUP,
			C.UF_LOGINOM_CHANNEL,
			C.UF_ROW_ID--,
		FROM stg._LCRM.lcrm_leads_full_calculated AS C WITH(nolock)
		WHERE C.DWHInsertedDate >= @LastLogDate

		SELECT @InsertCalcRows = @@ROWCOUNT
		SELECT @InsertCalcDurationSec = datediff(SECOND, @StartDate, getdate())
		IF @isDebug = 1 BEGIN
			SELECT InsertCalcRows = @InsertCalcRows, InsertCalcDurationSec = @InsertCalcDurationSec
		END

		CREATE CLUSTERED INDEX clix ON #t_calculated(ID)

		SELECT @StartDate = getdate()

		--select id, [Канал от источника] 
		--INTO #t1 
		--FROM stg._LCRM.lcrm_leads_full_calculated with(nolock)
		--except
		--select id, [Канал от источника]
		--from [Feodor].[dbo].[dm_leads_history] lh with(nolock)

		DROP TABLE IF EXISTS #t1

		SELECT TOP 0 ID, [Канал от источника] ,
			 UF_ROW_ID--,
		INTO #t1
		FROM #t_calculated

		INSERT #t1(ID, [Канал от источника],
			 UF_ROW_ID--,
			 )
		SELECT id, [Канал от источника] ,  
			 UF_ROW_ID--,
		FROM #t_calculated
		except
		select id, [Канал от источника],  
			 UF_ROW_ID
		from Feodor.dbo.dm_leads_history AS lh with(nolock)

		SELECT @ExceptRows = @@ROWCOUNT
		SELECT @ExeptDurationSec = datediff(SECOND, @StartDate, getdate())
		IF @isDebug = 1 BEGIN
			SELECT ExceptRows = @ExceptRows, ExeptDurationSec = @ExeptDurationSec
		END

		SELECT @StartDate = getdate()

		--delete a
		--FROM #t1 AS a
		--	LEFT join Feodor.dbo.dm_leads_history_ids_to_update AS b
		--		ON a.id=b.id
		--where b.id is not null

		delete a
		FROM #t1 AS a
			INNER JOIN Feodor.dbo.dm_leads_history_ids_to_update AS b
				ON a.id=b.id

		insert into Feodor.dbo.dm_leads_history_ids_to_update
		select id from #t1

		SELECT @InsertRows = @@ROWCOUNT
		SELECT @InsertDurationSec = datediff(SECOND, @StartDate, getdate())
		declare @InsertRows_text  nvarchar(max) = 'leads_history dif channel, uf_row_id @@ROWCOUNT = '+format(@InsertRows, '0')+' , @ExeptDurationMin = '+format(@ExeptDurationSec/60, '0')
		
	--	exec Analytics.dbo.log_email @InsertRows_text

		IF @isDebug = 1 BEGIN
			SELECT InsertRows = @InsertRows, InsertDurationSec = @InsertDurationSec
		END


		--	drop table if exists ##id_wrong_inst
		--
		--	select distinct a.[ID LCRM] into ##id_wrong_inst from Feodor.dbo.dm_Lead a
		--left join stg._fedor.core_ClientRequest b on a.[Номер заявки (договор)]=b.Number collate Cyrillic_General_CI_AS
		--where a.IsInstallment<>b.IsInstallment
		--
		--insert into dm_leads_history_ids_to_update
		--select try_cast([ID LCRM] as numeric) from ##id_wrong_inst a
		--left join Feodor.dbo.dm_leads_history_ids_to_update b on try_cast([ID LCRM] as numeric) =b.id
		--where  try_cast([ID LCRM] as numeric) is not null and b.id is null


		/*
		select id, UF_LOGINOM_PRIORITY, UF_LOGINOM_STATUS, UF_LOGINOM_GROUP, UF_LOGINOM_CHANNEL
		into #t2
		from stg._LCRM.lcrm_leads_full with(nolock)
		*/


		--select top 100 a.id, b.UF_LOGINOM_PRIORITY, a.UF_LOGINOM_PRIORITY, b.UF_LOGINOM_STATUS, a.UF_LOGINOM_STATUS from Feodor.dbo.dm_leads_history a
		--join #t2 b on a.id=b.id
		--and (isnull(b.UF_LOGINOM_PRIORITY, 0)<>isnull(a.UF_LOGINOM_PRIORITY, 0)
		--or isnull(b.UF_LOGINOM_STATUS, 0)<>isnull(a.UF_LOGINOM_STATUS, 0))

		SELECT @StartDate = getdate()

		drop table if exists #t3

		--select a.id, b.UF_LOGINOM_STATUS,b.UF_LOGINOM_PRIORITY, B.UF_LOGINOM_GROUP, B.UF_LOGINOM_CHANNEL  into #t3
		--from Feodor.dbo.dm_leads_history a  with(nolock)
		--join #t2 b on a.id=b.id
		--and (isnull(b.UF_LOGINOM_PRIORITY, 0)<>isnull(a.UF_LOGINOM_PRIORITY, 0)
		--or isnull(b.UF_LOGINOM_STATUS, 0)<>isnull(a.UF_LOGINOM_STATUS, 0)
		--or isnull(b.UF_LOGINOM_GROUP, 0)<>isnull(a.UF_LOGINOM_GROUP, 0)
		--or isnull(b.UF_LOGINOM_CHANNEL, 0)<>isnull(a.UF_LOGINOM_CHANNEL, 0)
		--)

		drop table if exists #t_history

		SELECT TOP 0
			a.ID, a.UF_LOGINOM_STATUS, a.UF_LOGINOM_PRIORITY, a.UF_LOGINOM_GROUP, a.UF_LOGINOM_CHANNEL
		INTO #t_history
		FROM Feodor.dbo.dm_leads_history a with(nolock)

		INSERT #t_history
		SELECT a.ID, a.UF_LOGINOM_STATUS, a.UF_LOGINOM_PRIORITY, a.UF_LOGINOM_GROUP, a.UF_LOGINOM_CHANNEL
		FROM Feodor.dbo.dm_leads_history a with(nolock)
			INNER JOIN #t_calculated AS b
				ON a.id = b.id

		CREATE CLUSTERED INDEX clix ON #t_history(ID)

		SELECT TOP 0
			b.ID, b.UF_LOGINOM_STATUS, b.UF_LOGINOM_PRIORITY, b.UF_LOGINOM_GROUP, b.UF_LOGINOM_CHANNEL
		INTO #t3
		FROM #t_calculated AS b

		INSERT #t3
		select a.id, b.UF_LOGINOM_STATUS, b.UF_LOGINOM_PRIORITY, B.UF_LOGINOM_GROUP, B.UF_LOGINOM_CHANNEL
		from #t_history AS a
			INNER JOIN #t_calculated AS b
				ON a.id=b.id
			and (isnull(b.UF_LOGINOM_PRIORITY, 0)<>isnull(a.UF_LOGINOM_PRIORITY, 0)
				or isnull(b.UF_LOGINOM_STATUS, '')<>isnull(a.UF_LOGINOM_STATUS, '')
				or isnull(b.UF_LOGINOM_GROUP, '')<>isnull(a.UF_LOGINOM_GROUP, '')
				or isnull(b.UF_LOGINOM_CHANNEL, '')<>isnull(a.UF_LOGINOM_CHANNEL, '')
			)

		SELECT @DiffRows = @@ROWCOUNT
		SELECT @DiffDurationSec = datediff(SECOND, @StartDate, getdate())
		IF @isDebug = 1 BEGIN
			SELECT DiffRows = @DiffRows, DiffDurationSec = @DiffDurationSec

			--DROP TABLE IF EXISTS ##t_history
			--SELECT * INTO ##t_history FROM #t_history

			--DROP TABLE IF EXISTS ##t_calculated
			--SELECT * INTO ##t_calculated FROM #t_calculated
		END


		--AND A.ДатаЛидаЛСРМ<'20220801'
		--and b.UF_LOGINOM_STATUS<>'unknown'

		--delete from #t3 where UF_LOGINOM_STATUS='unknown'
		--select * from #t3

		SELECT @StartDate = getdate()

		drop table if exists #t4
		select top 0 * into #t4
		from #t3

		declare @a bigint = 1
		declare @a1 bigint = 1

		declare @b nvarchar(100) = '1'
		declare @b1 nvarchar(100) = '1'

		while @a >0 and @a1<=40
		begin

			insert into #t4
			select top 1000000 * from #t3

waitfor delay '00:00:01'
			

while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin

waitfor delay '00:00:20'

end
			update Analytics.dbo.config
			set lh_lock_dt=getdate()



			begin tran 


			update top (1000000) a
			set a.UF_LOGINOM_PRIORITY=b.UF_LOGINOM_PRIORITY,
				a.UF_LOGINOM_STATUS=b.UF_LOGINOM_STATUS,
				a.UF_LOGINOM_GROUP=b.UF_LOGINOM_GROUP,
				a.UF_LOGINOM_CHANNEL=b.UF_LOGINOM_CHANNEL
			from Feodor.dbo.dm_leads_history a
				JOIN #t4 b on a.id=b.id

			commit tran





			set @a = @@ROWCOUNT
			
			update Analytics.dbo.config
			set lh_lock_dt=null


			select @a
			set @a1 = @a1+1

			set @b = cast(@a as nvarchar(max))
			set @b1 = 'UPDATE PRIORITY, _STATUS, GROUP, CHANNEL. Цикл - '+cast(@a1 as nvarchar(max)) +' Кол-во строк - '+@b

			SELECT @UpdateRows = @UpdateRows + @a

			delete a from #t3 a
			join #t4 b on a.id=b.id

			delete from #t4

			if @a >0
			begin
				exec Analytics.dbo.log_email @b1, 'p.ilin@techmoney.ru'
			end
		end

		SELECT @UpdateDurationSec = datediff(SECOND, @StartDate, getdate())
		IF @isDebug = 1 BEGIN
			SELECT UpdateRows = @UpdateRows, UpdateDurationSec = @UpdateDurationSec
		END

		SELECT @message = concat(
			'INSERT dm_leads_history_ids_to_update, UPDATE dm_leads_history. ',
			'Записей в _calculated с новым значением [Канал от источника]: ', convert(varchar(10), @ExceptRows), '. ',
			'Время except: ', convert(varchar(10), @ExeptDurationSec), '. ',
			'Добавлено в dm_leads_history_ids_to_update: ', convert(varchar(10), @InsertRows), '. ',
			'Время insert: ', convert(varchar(10), @InsertDurationSec), '. ',
			'Записей в _calculated с новыми значениями 4-х полей: ', convert(varchar(10), @DiffRows), '. ',
			'Время diff: ', convert(varchar(10), @DiffDurationSec), '. ',
			'Записей изменено в dm_leads_history: ', convert(varchar(10), @UpdateRows), '. ',
			'Время update: ', convert(varchar(10), @UpdateDurationSec)
		)

		SELECT @description =
			(
			SELECT
				'InsertCalcRows' = @InsertCalcRows,
				'InsertCalcDurationSec' = @InsertCalcDurationSec,
				'ExceptRows' = @ExceptRows,
				'ExeptDurationSec' = @ExeptDurationSec,
				'InsertRows' = @InsertRows,
				'InsertDurationSec' = @InsertDurationSec,
				'DiffRows' = @DiffRows,
				'DiffDurationSec' = @DiffDurationSec,
				'UpdateRows' = @UpdateRows,
				'UpdateDurationSec' = @UpdateDurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'create_dm_leads_history_ids_to_update',
			@eventType = 'Info',
			@message = @message,
			@description = @description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
					
		update Analytics.dbo.config
		set lh_lock_dt=null

		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = concat(
			'Ошибка INSERT dm_leads_history_ids_to_update, UPDATE dm_leads_history. ',
			'Записей в _calculated с новым значением [Канал от источника]: ', convert(varchar(10), @ExceptRows), '. ',
			'Время except: ', convert(varchar(10), @ExeptDurationSec), '. ',
			'Добавлено в dm_leads_history_ids_to_update: ', convert(varchar(10), @InsertRows), '. ',
			'Время insert: ', convert(varchar(10), @InsertDurationSec), '. ',
			'Записей в _calculated с новыми значениями 4-х полей: ', convert(varchar(10), @DiffRows), '. ',
			'Время diff: ', convert(varchar(10), @DiffDurationSec), '. ',
			'Записей изменено в dm_leads_history: ', convert(varchar(10), @UpdateRows), '. ',
			'Время update: ', convert(varchar(10), @UpdateDurationSec)
		)

		SELECT @description =
			(
			SELECT
				'InsertCalcRows' = @InsertCalcRows,
				'InsertCalcDurationSec' = @InsertCalcDurationSec,
				'ExceptRows' = @ExceptRows,
				'ExeptDurationSec' = @ExeptDurationSec,
				'InsertRows' = @InsertRows,
				'InsertDurationSec' = @InsertDurationSec,
				'DiffRows' = @DiffRows,
				'DiffDurationSec' = @DiffDurationSec,
				'UpdateRows' = @UpdateRows,
				'UpdateDurationSec' = @UpdateDurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Error create_dm_leads_history_ids_to_update',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END