-- exec [dbo].[Create_dm_LCMR_LaunchControl_Unique]
CREATE PROC [dbo].[Create_dm_LCMR_LaunchControl_Unique] 
AS
BEGIN
	SET NOCOUNT ON;


	---23.03.2020 заменил загрузкой из БД, а не из очереди. Так как данные в БД обновляются из очереди

	-- 19 06 2020 добавили загрузку  тайп из таблицы федор

  declare  @dt_lastweek date = cast(dateadd(day,-14, getdate()) as date)
  --declare  @dt_lastweek date = '2023-03-01' --временно

    if object_id('tempdb.dbo.#t')  is not null drop table #t
	CREATE TABLE #t
	(
	[UF_LCRM_ID] [int] NULL,
	[UF_TYPE] [int] NULL,
	[UF_UPDATED_AT] [datetime2] (0) NULL
	)
	INSERT #t(UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT)
	select UF_LCRM_ID, UF_TYPE , UF_UPDATED_AT 
	--into #t 
	from (
		select 
		UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT , -- a2.id, a2.value,
		ROW_NUMBER() over(partition by UF_LCRM_ID order by UF_UPDATED_AT desc) RN
        FROM [Stg].[_LCRM].[carmoney_light_crm_launch_control] a1 (nolock)
		  where ([UF_TYPE] in (
							  '107',
							  '205'
							  --,
							  --'216',
							  --'217',
							  --'218',
							  --'219',
							  --'222',
							  --'223'
							  )
				or [UF_TYPE] in (select [LaunchControlID] from [Feodor].[dbo].[dm_feodor_projects])
				)
							  and UF_UPDATED_AT > @dt_lastweek
	) aa
	where rn=1

	CREATE INDEX ix1 ON #t(UF_LCRM_ID)

	DROP TABLE IF EXISTS #t_UF_LCRM_ID
	CREATE TABLE #t_UF_LCRM_ID([UF_LCRM_ID] [int] NOT NULL PRIMARY KEY)
	
	INSERT #t_UF_LCRM_ID(UF_LCRM_ID)
	SELECT DISTINCT T.UF_LCRM_ID
	FROM #t AS T
	WHERE T.UF_LCRM_ID IS NOT NULL

	
	--if object_id('tempdb.dbo.#t')  is not null drop table #t

	--select UF_LCRM_ID, UF_TYPE , UF_UPDATED_AT 
	--into #t 
	--from (
	--	select 
	--	UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT , -- a2.id, a2.value,
	--	ROW_NUMBER() over(partition by UF_LCRM_ID order by UF_UPDATED_AT desc) RN
	--	FROM [Stg].[_LCRM].[lcrm_queue_launch_control] a1 (nolock)
	--	  where [UF_TYPE] in (
	--						  '107',
	--						  '205',
	--						  '216',
	--						  '217',
	--						  '218',
	--						  '219'
	--						  )
	--) aa
	--where rn=1

begin tran

	/*
  delete U
 -- select * 
  from dbo.dm_LCMR_LaunchControl_Unique AS U
  --WHERE UF_LCRM_ID in (select UF_LCRM_ID from #t)
  WHERE EXISTS(
	SELECT TOP 1 1
	FROM #t_UF_LCRM_ID AS T
	WHERE T.UF_LCRM_ID = U.UF_LCRM_ID
	)
	*/

	delete U
	from dbo.dm_LCMR_LaunchControl_Unique AS U
		INNER JOIN #t_UF_LCRM_ID AS T
			ON T.UF_LCRM_ID = U.UF_LCRM_ID


	insert into dbo.dm_LCMR_LaunchControl_Unique 
	select * from #t

commit tran

 ------первичная загрузка данных (2 минуты)
 ------drop table dbo.dm_LCMR_LaunchControl_Unique 

 ------  truncate table dbo.dm_LCMR_LaunchControl_Unique 
 ------ insert into dbo.dm_LCMR_LaunchControl_Unique

 --declare  @dt_last2week date = cast(dateadd(day,-14, getdate()) as date)

 -- select UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT 
 -- --into dbo.dm_LCMR_LaunchControl_Unique
 -- from (
 -- select 
 -- UF_LCRM_ID, UF_TYPE, UF_UPDATED_AT, -- a2.id, a2.value,
 -- ROW_NUMBER() over(partition by UF_LCRM_ID order by UF_UPDATED_AT desc) RN
 -- --count(distinct UF_LCRM_ID)
 --    FROM [Stg].[_LCRM].[carmoney_light_crm_launch_control] a1
	--where [UF_TYPE] in (
	--				'107',
	--				'205',
	--				'216',
	--				'217',
	--				'218',
	--				'219'
	--				)
	--	--and UF_UPDATED_AT > @dt_last2week
	--) aa
	--where rn=1
END
