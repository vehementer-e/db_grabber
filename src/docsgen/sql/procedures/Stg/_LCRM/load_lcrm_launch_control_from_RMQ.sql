--exec [_LCRM].[[load_lcrm_launch_control_from_RMQ]
-- Usage: запуск процедуры с параметрами
-- EXEC [_LCRM].[load_lcrm_launch_control_from_RMQ] @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROC [_LCRM].[load_lcrm_launch_control_from_RMQ]
	@isDebug int = 0
as
begin

SET XACT_ABORT ON
set nocount on 

-- Обновление из очереди launch_control

DECLARE @StartDate datetime, @row_count int
DECLARE @min_UF_UPDATED_AT datetime2

SELECT @isDebug = isnull(@isDebug, 0)


-- из stg таблицы
Declare @dt datetime = getdate()

-- утром грузим с вечера 
select @dt = dateadd(hour, 21, cast(dateadd(day,-1,cast(@dt as date)) as datetime2) ) 
select @dt

if ( datepart(hour,getdate()) > 6)
	begin
		Select @dt= dateadd(minute, -10, isnull(max(receivedate),@dt))  from _LCRM.RMQ_Read_Logs
		where queue_name = 'LAUNC'
		select @dt
	end 
else
	begin 
		select @dt
	end




--*****************************************
-- Пакет из JSON из очереди
--*****************************************

if object_id('tempdb.dbo.#t')  is not null drop table #t

SELECT @StartDate = getdate(), @row_count = 0

select 
	unit
	,type
	,before
	,after
	, after_code
	, after_id
	, after_lcrmId
	,after_type
	,after_updatedAt
	,[ReceiveDate]
into #t

--from [RMQ].[ReceivedMessages]  RM with(nolock)
FROM RMQ.ReceivedMessages_LCRM_GOEST_Sync_LaunchControlTable RM with(nolock)
 outer apply  OPENJSON(ReceivedMessage, '$')
  with (
         unit nvarchar(100) '$.unit'
        ,type  nvarchar(100) '$.type'
        ,before  nvarchar(100) '$.before'
        ,after nvarchar(max) '$.after' as JSOn
       ) l 
       outer apply OPENJSON(l.after, '$')

with(

         after_code nvarchar(100) '$.code'
        ,after_id  nvarchar(100) '$.id'
        ,after_lcrmId  nvarchar(100) '$.lcrmId'
        ,after_type nvarchar(100) '$.type'
        ,after_updatedAt nvarchar(100) '$.updatedAt'       
) m

where
RM.[ReceiveDate] > @dt
and 
FromQueue = 'dwh.LCRM.GOEST.Sync.LaunchControlTable'

SELECT @row_count = @@ROWCOUNT
IF @isDebug = 1 BEGIN
	SELECT 'INSERT #t', @row_count, datediff(SECOND, @StartDate, getdate())
END

--select top 100 * from #t
--**************************************************
-- Маппинг в таблицу требуемого формата БД mySQL
--**************************************************

--drop table if exists  _lcrm.lcrm_queue_launch_control

--CREATE TABLE [_LCRM].[lcrm_queue_launch_control](
--	[ID] [numeric](10, 0) NULL,
--	[UF_LCRM_ID] [int] NULL,
--	[UF_TYPE] [int] NULL,
--	[UF_UPDATED_AT] [datetime2](7) NULL
--) ON [PRIMARY]


SELECT @StartDate = getdate(), @row_count = 0

truncate table _lcrm.lcrm_queue_launch_control
insert into [_LCRM].[lcrm_queue_launch_control] with(TablockX) (ID, UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT)
SELECT 
	cast(RMQ.after_id as numeric) [ID]	 
	, try_cast(RMQ.after_lcrmId as int) [UF_LCRM_ID]
	, try_cast(RMQ.after_type as int) [UF_TYPE]
	, try_convert(datetime, RMQ.after_updatedAt,120) [UF_UPDATED_AT]
FROM #t as RMQ;

SELECT @row_count = @@ROWCOUNT
IF @isDebug = 1 BEGIN
	SELECT 'INSERT _LCRM.lcrm_queue_launch_control', @row_count, datediff(SECOND, @StartDate, getdate())
END

--ID
--202093589

-- добавление данных в БД

--begin tran

	--ver.1
	/*
	insert into [_LCRM].[carmoney_light_crm_launch_control] 
	select 
		  a1.id as [ID]
		, a1.[UF_LCRM_ID] as [UF_LCRM_ID]
		, a1.[UF_TYPE] as [UF_TYPE]
		, a1.[UF_UPDATED_AT] as [UF_UPDATED_AT]
	from  [_LCRM].[lcrm_queue_launch_control] a1
	left join [_LCRM].[carmoney_light_crm_launch_control]  a2 --(nolock)
	on a1.id= a2.id
	where a2.id is  null
	*/

	--1. удалить записи в таблице _queue, с имеющимися id
	SELECT @StartDate = getdate(), @row_count = 0

	SELECT @min_UF_UPDATED_AT = min(a1.UF_UPDATED_AT)
	FROM _LCRM.lcrm_queue_launch_control AS a1

	IF @isDebug = 1 BEGIN
		SELECT '@min_UF_UPDATED_AT = ', @min_UF_UPDATED_AT
	END

	DELETE a1
	FROM _LCRM.lcrm_queue_launch_control AS a1
		INNER JOIN _LCRM.carmoney_light_crm_launch_control AS a2 (nolock)
			ON a2.id = a1.id
			AND a2.UF_UPDATED_AT >= a1.UF_UPDATED_AT -- данные в RMQ более старые или такие же
			AND a2.UF_UPDATED_AT >= @min_UF_UPDATED_AT

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'DELETE _LCRM.lcrm_queue_launch_control', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	--2. обновить данные
	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_update
	CREATE TABLE #t_update(ID numeric(10, 0))

	UPDATE a2
	SET a2.UF_LCRM_ID = a1.UF_LCRM_ID,
		a2.UF_TYPE = a1.UF_TYPE,
		a2.UF_UPDATED_AT = a1.UF_UPDATED_AT
	OUTPUT Inserted.ID INTO #t_update
	FROM _LCRM.lcrm_queue_launch_control AS a1
		INNER JOIN _LCRM.carmoney_light_crm_launch_control AS a2 (nolock)
			ON a2.id= a1.id
			AND a2.UF_UPDATED_AT < a1.UF_UPDATED_AT -- данные в RMQ новее
			AND a2.UF_UPDATED_AT >= @min_UF_UPDATED_AT

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'UPDATE _LCRM.lcrm_queue_launch_control', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	DELETE Q
	FROM _LCRM.lcrm_queue_launch_control AS Q
		INNER JOIN #t_update AS U
			ON U.id= Q.id

	--3. добавить новые id
	SELECT @StartDate = getdate(), @row_count = 0

	insert _LCRM.carmoney_light_crm_launch_control(ID, UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT)
	select 
		  Q.ID
		, Q.UF_LCRM_ID
		, Q.UF_TYPE
		, Q.UF_UPDATED_AT
	from _LCRM.lcrm_queue_launch_control AS Q

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT _LCRM.carmoney_light_crm_launch_control', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	--select id from [_LCRM].[lcrm_queue_launch_control]
	--except
	--select id from [_LCRM].[carmoney_light_crm_launch_control] 

--commit tran


begin tran
	delete from  _LCRM.RMQ_Read_Logs where  'LAUNC' = queue_name  
	insert into _LCRM.RMQ_Read_Logs(ReceiveDate, queue_name)
	select max(ReceiveDate) as ReceiveDate,  'LAUNC' as queue_name  
	from #t
commit


end
