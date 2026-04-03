/*
exec link.fill_ДоговорЗайма_collectingStage @mode = 1
*/
create   PROC link.fill_ДоговорЗайма_collectingStage_SCD2
	@mode int = 1,
	@ObjectId int = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_collectingStage
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @date_from date = '2000-01-01'

	if OBJECT_ID ('link.ДоговорЗайма_collectingStage_SCD2') is not null
		and @mode = 1
		and @ObjectId is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @date_from = isnull((select max(date_from) from link.ДоговорЗайма_collectingStage_SCD2), '2000-01-01')
	end

	drop table if exists #t_ObjectId

	select distinct	h.ObjectId
	into #t_ObjectId
	from Stg._Collection.DealHistory as h
		inner join Stg._Collection.Deals as d
			on d.Id = h.ObjectId
	where h.ChangeDate >= @date_from
		and h.Field = 'Стадия коллектинга договора'
		and (h.ObjectId = @ObjectId or @ObjectId is null)
		and (d.CmrId = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.Number = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1 begin
		drop table if exists ##t_ObjectId
		select * into ##t_ObjectId from #t_ObjectId
	end

	drop table if exists #t_ДоговорЗайма_collectingStage_date
	create table #t_ДоговорЗайма_collectingStage_date
	(
		--GuidДоговораЗайма uniqueidentifier not null,
		КодДоговораЗайма nvarchar(14) not null,
		ChangeDate datetime not null,
		prev_GuidCollection_collectingStage uniqueidentifier null,
		GuidCollection_collectingStage uniqueidentifier not null
	)

	insert #t_ДоговорЗайма_collectingStage_date
	(
		КодДоговораЗайма,
		ChangeDate,
		prev_GuidCollection_collectingStage,
		GuidCollection_collectingStage
	)
	select distinct
		hub.КодДоговораЗайма,
		h.ChangeDate,
		prev_GuidCollection_collectingStage = prev_stage.GuidCollection_collectingStage,
		stage.GuidCollection_collectingStage
	from #t_ObjectId as obj
		inner join Stg._Collection.DealHistory as h
			on h.ObjectId = obj.ObjectId
		inner join Stg._Collection.Deals as d
			on d.Id = h.ObjectId
		inner join hub.ДоговорЗайма as hub
			on hub.КодДоговораЗайма = d.Number
		inner join hub.Collection_collectingStage as stage
			on cast(stage.Id as nvarchar(10)) = h.NewValue
		left join hub.Collection_collectingStage as prev_stage
			on cast(prev_stage.Id as nvarchar(10)) = h.OldValue
	where h.Field = 'Стадия коллектинга договора'

	if @isDebug = 1 begin
		drop table if exists ##t_ДоговорЗайма_collectingStage_date
		select * into ##t_ДоговорЗайма_collectingStage_date from #t_ДоговорЗайма_collectingStage_date
	end

	-- 1-е значение - из 1-го OldValue
	drop table if exists #t_ДоговорЗайма_collectingStage_SCD2_full
	create table #t_ДоговорЗайма_collectingStage_SCD2_full
	(
		КодДоговораЗайма nvarchar(14) not null,
		date_from date not null,
		GuidCollection_collectingStage uniqueidentifier not null
	)

	insert #t_ДоговорЗайма_collectingStage_SCD2_full
	(
		КодДоговораЗайма,
		date_from,
		GuidCollection_collectingStage
	)
	select 
		s.КодДоговораЗайма,
		date_from = m.date_from_1,
		s.prev_GuidCollection_collectingStage
	from (
			select 
				t.КодДоговораЗайма, 
				min_ChangeDate = min(t.ChangeDate),
				--date_from для 1-го значения = ДатаДоговораЗайма
				date_from_1 = isnull(min(d.ДатаДоговораЗайма), '2000-01-01')
			from #t_ДоговорЗайма_collectingStage_date as t
				left join hub.ДоговорЗайма as d
					on d.КодДоговораЗайма = t.КодДоговораЗайма
			group by t.КодДоговораЗайма
		) as m
		inner join #t_ДоговорЗайма_collectingStage_date as s
			on s.КодДоговораЗайма = m.КодДоговораЗайма
			and s.ChangeDate = m.min_ChangeDate
			and s.prev_GuidCollection_collectingStage is not null

	--удалить дубли
	--за каждый день оставить последнюю запись
	;with dup as (
		select 
			t.*, 
			rn = row_number() 
				over(
					partition by t.КодДоговораЗайма, cast(t.ChangeDate as date)
					order by t.ChangeDate desc
				)
		from #t_ДоговорЗайма_collectingStage_date as t
	)
	delete from dup where dup.rn <> 1

	--вставить все остальные записи
	insert #t_ДоговорЗайма_collectingStage_SCD2_full
	(
		КодДоговораЗайма,
		date_from,
		GuidCollection_collectingStage
	)
	select 
		t.КодДоговораЗайма,
		date_from = cast(t.ChangeDate as date),
		t.GuidCollection_collectingStage
	from #t_ДоговорЗайма_collectingStage_date as t

	if @isDebug = 1 begin
		drop table if exists ##t_ДоговорЗайма_collectingStage_SCD2_full
		select * into ##t_ДоговорЗайма_collectingStage_SCD2_full from #t_ДоговорЗайма_collectingStage_SCD2_full
	end


	-------------------------------------------------------------------------
	--схлопнуть одинаковые значения
	drop table if exists #t_ДоговорЗайма_collectingStage_SCD2
	create table #t_ДоговорЗайма_collectingStage_SCD2
	(
		КодДоговораЗайма nvarchar(14) not null,
		date_from date not null,
		GuidCollection_collectingStage uniqueidentifier not null
	)

	insert #t_ДоговорЗайма_collectingStage_SCD2
	(
		КодДоговораЗайма,
		date_from,
		GuidCollection_collectingStage
	)
	select
		s.КодДоговораЗайма,
		s.date_from,
		s.GuidCollection_collectingStage
	from (
		select 
			a.КодДоговораЗайма,
			a.group_id,
			date_from = min(a.date_from)
		from (
			select 
				l.КодДоговораЗайма,
				l.date_from,
				l.GuidCollection_collectingStage,
				group_id = 
					row_number() over(
						partition by l.КодДоговораЗайма
						order by l.date_from
						)
					-
					row_number() over(
						partition by l.КодДоговораЗайма, l.GuidCollection_collectingStage
						order by l.date_from
						)
			from #t_ДоговорЗайма_collectingStage_SCD2_full as l
			) as a
		group by a.КодДоговораЗайма, a.group_id
		) as b
		inner join #t_ДоговорЗайма_collectingStage_SCD2_full as s
			on s.КодДоговораЗайма = b.КодДоговораЗайма
			and s.date_from = b.date_from
	--order by s.КодДоговораЗайма, s.date_from

	if @isDebug = 1 begin
		drop table if exists ##t_ДоговорЗайма_collectingStage_SCD2
		select * into ##t_ДоговорЗайма_collectingStage_SCD2 from #t_ДоговорЗайма_collectingStage_SCD2
	end

	-- удалить то, что не изменилось
	DELETE s
	FROM #t_ДоговорЗайма_collectingStage_SCD2 AS s
		INNER JOIN link.ДоговорЗайма_collectingStage_SCD2 AS t
			ON t.КодДоговораЗайма = s.КодДоговораЗайма
			AND s.date_from BETWEEN t.date_from AND t.date_to
			AND t.GuidCollection_collectingStage = s.GuidCollection_collectingStage

	INSERT link.ДоговорЗайма_stage_SCD2
	(
		КодДоговораЗайма,
		date_from,
		LinkName,
		LinkGuid,
		TargetColName
	)
	SELECT 
		R.КодДоговораЗайма,
		R.date_from,
		LinkName = 'link.ДоговорЗайма_collectingStage_SCD2',
		R.GuidCollection_collectingStage,
		TargetColName = 'GuidCollection_collectingStage'
	FROM #t_ДоговорЗайма_collectingStage_SCD2 AS R

	EXEC link.fill_link_between_ДоговорЗайма_and_other_SCD2
		@LinkName='link.ДоговорЗайма_collectingStage_SCD2'

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
