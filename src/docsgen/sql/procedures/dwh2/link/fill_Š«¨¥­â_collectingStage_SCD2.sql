/*
exec link.fill_Клиент_collectingStage @mode = 1
*/
create   PROC link.fill_Клиент_collectingStage_SCD2
	@mode int = 1,
	@ObjectId int = null,
	@GuidКлиент uniqueidentifier = null,
	@isDebug int = 0
as
begin
	--truncate table sat.Клиент_collectingStage
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @date_from date = '2000-01-01'

	if OBJECT_ID ('link.Клиент_collectingStage_SCD2') is not null
		and @mode = 1
		and @ObjectId is null
		and @GuidКлиент is null
	begin
		set @date_from = isnull((select max(date_from) from link.Клиент_collectingStage_SCD2), '2000-01-01')
	end

	drop table if exists #t_ObjectId

	select distinct	h.ObjectId
	into #t_ObjectId
	from Stg._Collection.CustomerHistory as h
		inner join Stg._Collection.customers as c
			on c.Id = h.ObjectId
	where h.ChangeDate >= @date_from
		and h.Field = 'Стадия коллектинга'
		and (h.ObjectId = @ObjectId or @ObjectId is null)
		and (c.CrmCustomerId = @GuidКлиент or @GuidКлиент is null)

	if @isDebug = 1 begin
		drop table if exists ##t_ObjectId
		select * into ##t_ObjectId from #t_ObjectId
	end

	drop table if exists #t_Клиент_collectingStage_date
	create table #t_Клиент_collectingStage_date
	(
		GuidКлиент uniqueidentifier not null,
		ChangeDate datetime not null,
		prev_GuidCollection_collectingStage uniqueidentifier null,
		GuidCollection_collectingStage uniqueidentifier not null
	)

	insert #t_Клиент_collectingStage_date
	(
		GuidКлиент,
		ChangeDate,
		prev_GuidCollection_collectingStage,
		GuidCollection_collectingStage
	)
	select distinct
		hub.GuidКлиент,
		h.ChangeDate,
		prev_GuidCollection_collectingStage = prev_stage.GuidCollection_collectingStage,
		stage.GuidCollection_collectingStage
	from #t_ObjectId as obj
		inner join Stg._Collection.CustomerHistory as h
			on h.ObjectId = obj.ObjectId
		inner join Stg._Collection.customers as c
			on c.Id = h.ObjectId
		inner join hub.Клиенты as hub
			on hub.GuidКлиент = c.CrmCustomerId
		inner join hub.Collection_collectingStage as stage
			on cast(stage.Id as nvarchar(10)) = h.NewValue
		left join hub.Collection_collectingStage as prev_stage
			on cast(prev_stage.Id as nvarchar(10)) = h.OldValue
	where h.Field = 'Стадия коллектинга'

	if @isDebug = 1 begin
		drop table if exists ##t_Клиент_collectingStage_date
		select * into ##t_Клиент_collectingStage_date from #t_Клиент_collectingStage_date
	end

	-- 1-е значение - из 1-го OldValue
	drop table if exists #t_Клиент_collectingStage_SCD2
	create table #t_Клиент_collectingStage_SCD2
	(
		GuidКлиент uniqueidentifier not null,
		date_from date not null,
		--prev_GuidCollection_collectingStage uniqueidentifier null,
		GuidCollection_collectingStage uniqueidentifier not null
	)

	insert #t_Клиент_collectingStage_SCD2
	(
		GuidКлиент,
		date_from,
		--prev_GuidCollection_collectingStage,
		GuidCollection_collectingStage
	)
	select 
		s.GuidКлиент,
		date_from = m.date_from_1,
		s.prev_GuidCollection_collectingStage
	from (
			select 
				t.GuidКлиент, 
				min_ChangeDate = min(t.ChangeDate),
				--date_from для 1-го значения = ДатаДоговораЗайма
				date_from_1 = isnull(min(d.ДатаДоговораЗайма), '2000-01-01')
			from #t_Клиент_collectingStage_date as t
				left join link.Клиент_ДоговорЗайма as l
					on l.GuidКлиент = t.GuidКлиент
				left join hub.ДоговорЗайма as d
					on d.КодДоговораЗайма = l.КодДоговораЗайма
			group by t.GuidКлиент
		) as m
		inner join #t_Клиент_collectingStage_date as s
			on s.GuidКлиент = m.GuidКлиент
			and s.ChangeDate = m.min_ChangeDate
			and s.prev_GuidCollection_collectingStage is not null

	--удалить дубли
	--за каждый день оставить последнюю запись
	;with dup as (
		select 
			t.*, 
			rn = row_number() 
				over(
					partition by t.GuidКлиент, cast(t.ChangeDate as date)
					order by t.ChangeDate desc
				)
		from #t_Клиент_collectingStage_date as t
	)
	delete from dup where dup.rn <> 1

	--вставить все остальные записи
	insert #t_Клиент_collectingStage_SCD2
	(
		GuidКлиент,
		date_from,
		GuidCollection_collectingStage
	)
	select 
		t.GuidКлиент,
		date_from = cast(t.ChangeDate as date),
		t.GuidCollection_collectingStage
	from #t_Клиент_collectingStage_date as t

	if @isDebug = 1 begin
		drop table if exists ##t_Клиент_collectingStage_SCD2
		select * into ##t_Клиент_collectingStage_SCD2 from #t_Клиент_collectingStage_SCD2
	end

	-- удалить то, что не изменилось
	DELETE s
	FROM #t_Клиент_collectingStage_SCD2 AS s
		INNER JOIN link.Клиент_collectingStage_SCD2 AS t
			ON t.GuidКлиент = s.GuidКлиент
			AND s.date_from BETWEEN t.date_from AND t.date_to
			AND t.GuidCollection_collectingStage = s.GuidCollection_collectingStage

	INSERT link.Клиент_stage
	(
		GuidКлиент,
		date_from,
		LinkName,
		LinkGuid,
		TargetColName
	)
	SELECT 
		R.GuidКлиент,
		R.date_from,
		LinkName = 'link.Клиент_collectingStage_SCD2',
		R.GuidCollection_collectingStage,
		TargetColName = 'GuidCollection_collectingStage'
	FROM #t_Клиент_collectingStage_SCD2 AS R

	EXEC link.fill_link_between_Клиент_and_other
		@LinkName='link.Клиент_collectingStage_SCD2'

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
