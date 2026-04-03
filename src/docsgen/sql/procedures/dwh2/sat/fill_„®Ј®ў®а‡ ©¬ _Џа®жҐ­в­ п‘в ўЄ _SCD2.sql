--exec sat.fill_ДоговорЗайма_ПроцентнаяСтавка_SCD2
CREATE PROC sat.fill_ДоговорЗайма_ПроцентнаяСтавка_SCD2
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @date_from date = '2000-01-01'

	if object_id('sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2') is not null
		AND @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		select @date_from = isnull(dateadd(day,-30, max(date_from)), '2000-01-01')
		from sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
	end

	--Договора
	drop table if exists #t_ДоговорЗайма

	select distinct
		h.КодДоговораЗайма,
		h.СсылкаДоговораЗайма
	into #t_ДоговорЗайма
	from Stg._1cCMR.РегистрСведений_ПараметрыДоговора AS p
		inner join hub.ДоговорЗайма as h
			on h.СсылкаДоговораЗайма = p.Договор
	where p.Период > dateadd(year, 2000, @date_from)
		and (h.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (h.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (h.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		DROP TABLE IF EXISTS ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	end

	create index ix1 on #t_ДоговорЗайма(КодДоговораЗайма, СсылкаДоговораЗайма)
	create index ix2 on #t_ДоговорЗайма(СсылкаДоговораЗайма, КодДоговораЗайма)


	DROP TABLE if EXISTS #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2

	select
		t.КодДоговораЗайма,
		t.date_from,
		date_to = t.date_from,
		t.ПроцентнаяСтавка,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		rn2 = row_number() over(
			partition by t.КодДоговораЗайма
			order by t.date_from
			)
	into #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2
	from (
		select
			d.КодДоговораЗайма,
			date_from = dateadd(year, -2000, cast(p.Период AS date)),
			ПроцентнаяСтавка = coalesce(nullif(p.ПроцентнаяСтавка, 0), p.НачисляемыеПроценты),
			--последнее значение в день
			rn = row_number() over(
				partition by d.КодДоговораЗайма, dateadd(year, -2000, cast(p.Период AS date))
				order by p.Период desc
				)
		FROM #t_ДоговорЗайма as d
			inner join Stg._1cCMR.РегистрСведений_ПараметрыДоговора AS p
				on p.Договор = d.СсылкаДоговораЗайма
				and p.Регистратор_ТипСсылки = 0x0000005E --График платежей
				and p.Активность = 0x01
		) as t
	where 1=1
		and t.ПроцентнаяСтавка is not null
		and t.rn = 1

	create index ix1
	on #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2(КодДоговораЗайма, date_from)
	include(ПроцентнаяСтавка)

	create index ix2
	on #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2(КодДоговораЗайма, rn2)
	include(ПроцентнаяСтавка)

	--удалить дубли
	/*
	delete b
	from #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 as a
		--следующее значение с той же ставкой
		inner join #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 as b
			on b.КодДоговораЗайма = a.КодДоговораЗайма
			and b.rn2 = a.rn2 + 1
			and b.ПроцентнаяСтавка = a.ПроцентнаяСтавка
	*/

	delete b
	from #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 as b
	--есть предыдущее значение с той же ставкой
	where exists(
			select top(1) 1
			from #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 as a
			where 1=1
				and a.КодДоговораЗайма = b.КодДоговораЗайма
				and a.rn2 + 1 = b.rn2
				and a.ПроцентнаяСтавка = b.ПроцентнаяСтавка
		)


	if @isDebug = 1
	begin
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_ПроцентнаяСтавка_SCD2
		SELECT * INTO ##t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 FROM #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2
	end


	if OBJECT_ID('sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2') is null
	begin
		select top(0)
			КодДоговораЗайма,
			date_from,
			date_to,
			ПроцентнаяСтавка,

            created_at,
            updated_at,
            spFillName
		into sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
		from #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2

		alter table sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
			alter column КодДоговораЗайма nvarchar(14) not null

		alter table sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
			alter column date_from date not null

		alter table sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
			alter column date_to date not null

		ALTER TABLE sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
			ADD CONSTRAINT PK_ДоговорЗайма_ПроцентнаяСтавка_SCD2 
			PRIMARY KEY CLUSTERED (КодДоговораЗайма, date_from)
	end
	
	-- удалить то, что не изменилось
	--DELETE s
	--FROM #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS s
	--	INNER JOIN sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS t
	--		ON t.КодДоговораЗайма = s.КодДоговораЗайма
	--		AND s.date_from BETWEEN t.date_from AND t.date_to
	--		AND isnull(t.ПроцентнаяСтавка, -9999) = isnull(s.ПроцентнаяСтавка,-9999)

	-- удалить существующие показатели для t.date_from >= s.date_from
	DELETE t
	FROM #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS s
		INNER JOIN sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS t
			ON t.КодДоговораЗайма = s.КодДоговораЗайма
			AND t.date_from >= s.date_from

	begin tran
		if @mode = 0 begin
			truncate table sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2
		end

		merge sat.ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS t
		using #t_ДоговорЗайма_ПроцентнаяСтавка_SCD2 AS s
			on t.КодДоговораЗайма = s.КодДоговораЗайма
			AND t.date_from = s.date_from
		when not matched then insert
		(
			КодДоговораЗайма,
			date_from,
			date_to,
			ПроцентнаяСтавка,

            created_at,
            updated_at,
            spFillName
		) values
		(
			s.КодДоговораЗайма,
			s.date_from,
			s.date_to,
			s.ПроцентнаяСтавка,

            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched and (
			isnull(t.ПроцентнаяСтавка, -9999) <> isnull(s.ПроцентнаяСтавка,-9999)
			)
		then update SET
			t.ПроцентнаяСтавка = s.ПроцентнаяСтавка,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
		;
	commit tran

END try
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
