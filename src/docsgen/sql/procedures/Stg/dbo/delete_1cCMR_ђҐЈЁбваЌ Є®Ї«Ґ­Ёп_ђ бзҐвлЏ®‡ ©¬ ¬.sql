-- =======================================================
-- Create: 25.11.2025. А.Никитин
-- Description:	DWH-299
-- Удаление записей из РегистрНакопления_РасчетыПоЗаймам
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC dbo.delete_1cCMR_РегистрНакопления_РасчетыПоЗаймам @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create   PROC dbo.delete_1cCMR_РегистрНакопления_РасчетыПоЗаймам
	--@mode int = 1 -- 0 - full, 1 - increment
	@isDebug int = 0
	,@ProcessGUID varchar(36) = NULL -- guid процесса
AS
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	--declare @dt_from date = '2000-01-01'
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	--DECLARE @InsertRows int = 0, @DeleteRows int = 0

	declare @property_type_proc binary(16) -- Процент победителя акции
		,@property_type_reason binary(16) --Причина отказа по акции биг инстоллмент

	SELECT @eventName = 'Stg._1cCMR.delete_РегистрНакопления_РасчетыПоЗаймам', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		--1
		drop table if exists #t_ДоговорЗайма

		select 
			ДоговорЗайма.GuidДоговораЗайма
			,ДоговорЗайма.СсылкаДоговораЗайма
			,ДоговорЗайма.КодДоговораЗайма
			--,ДатаЗакрытияДоговора =cast(ДатаЗакрытияДоговора as datetime)
			--берем на день больше, т.к а дату закрытия еще могут быть операции.
			,ДатаЗакрытияДоговора_1 = dateadd(dd, 1, cast(ДоговорЗайма.ДатаЗакрытияДоговора as datetime))
			,ПлановаяЗакрытияДоговора = Indicators.InitialEndDate
			,ClosedPARTITIONId = stg.$PARTITION.[pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам](ДоговорЗайма.ДатаЗакрытияДоговора)
		--select count(*) --178733
		into #t_ДоговорЗайма
		from dwh2.hub.ДоговорЗайма as ДоговорЗайма
			left join dwh2.dbo.dm_OverdueIndicators as Indicators
				on Indicators.Number = ДоговорЗайма.КодДоговораЗайма
		where ДатаЗакрытияДоговора is not null
			--and GuidДоговораЗайма = '31A0ADBE-BFB0-11E7-814A-00155D01BF07'

		--Найдем данные в РасчетыПоЗаймам после закрытия договора
		drop table if exists #t_РасчетыПоЗаймам
		create table #t_РасчетыПоЗаймам(
			Договор binary(16),
			Период_2000 datetime
		)

		insert #t_РасчетыПоЗаймам(Договор, Период_2000)
		select distinct
			РасчетыПоЗаймам.Договор,
			РасчетыПоЗаймам.Период_2000
		from #t_ДоговорЗайма as t
			inner join stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as РасчетыПоЗаймам
				on РасчетыПоЗаймам.Договор = t.СсылкаДоговораЗайма
				--для оптимизации
				and stg.$PARTITION.[pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам](Период_2000)
					>= t.ClosedPARTITIONId
				--берем на день больше, т.к а дату закрытия еще могут быть операции.
				and РасчетыПоЗаймам.Период_2000 > t.ДатаЗакрытияДоговора_1

		if @isDebug = 1 begin
			--select count(*) from #t_РасчетыПоЗаймам

			if OBJECT_ID('tmp.delete_РегистрНакопления_РасчетыПоЗаймам') is null
			begin
				select top(0) Договор, Период_2000
				into tmp.delete_РегистрНакопления_РасчетыПоЗаймам
				from #t_РасчетыПоЗаймам
			end

			truncate table tmp.delete_РегистрНакопления_РасчетыПоЗаймам

			insert tmp.delete_РегистрНакопления_РасчетыПоЗаймам(Договор, Период_2000)
			select Договор, Период_2000
			from #t_РасчетыПоЗаймам
		end


		-- удалить записи, которые определены в #t_РасчетыПоЗаймам
		declare @dt date, @end_dt date, @partition_id int, @count_rows int, @is_delete int

		select 
			@dt = cast(format(cast(min(d.Период_2000) as date), 'yyyy-MM-01') as date),
			@end_dt = dateadd(month, 1, cast(format(cast(max(d.Период_2000) as date), 'yyyy-MM-01') as date))
		from #t_РасчетыПоЗаймам as d

		while @dt < @end_dt 
		begin
			select @partition_id = Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(@dt)
			select @is_delete = 0

			if exists(
				select top(1) 1
				from Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as r --(nolock)
					inner join #t_РасчетыПоЗаймам as d
						on d.Период_2000 = r.Период_2000
						and d.Договор = r.Договор
				where 1=1
					and @dt <= r.Период_2000 and r.Период_2000 < dateadd(month, 1, @dt)
					and @dt <= d.Период_2000 and d.Период_2000 < dateadd(month, 1, @dt)
					and Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(r.Период_2000)
						= @partition_id
				)
			begin
				select @is_delete = 1	
			end

			--if @count_rows > 0
			if @is_delete = 1	
			begin
				--select count(*)
				--select top 100 *
				delete r
				from Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as r --(nolock)
					inner join #t_РасчетыПоЗаймам as d
						on d.Период_2000 = r.Период_2000
						and d.Договор = r.Договор
				--where @dt <= d.Период_2000 and d.Период_2000 < dateadd(year, 1, @dt)
				where 1=1
					and @dt <= r.Период_2000 and r.Период_2000 < dateadd(month, 1, @dt)
					and @dt <= d.Период_2000 and d.Период_2000 < dateadd(month, 1, @dt)
					and Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(r.Период_2000)
						= @partition_id

				select @count_rows = @@rowcount

				--select dt = @dt, part_id = @partition_id, cnt_rows = @count_rows
				insert Stg.tmp.log_delete_РегистрНакопления_РасчетыПоЗаймам(delete_dt, delete_rows)
				select delete_dt = @dt, delete_rows = @count_rows
			end

			--select @dt = dateadd(year, 1, @dt)
			select @dt = dateadd(month, 1, @dt)

			--select @dt
			--WAITFOR DELAY '00:01:00'
			WAITFOR DELAY '00:00:10'
		end





		/*
		--2 начальное удаление 
		-- удалить записи, которые определены в Stg.tmp.delete_РегистрНакопления_РасчетыПоЗаймам_2
		declare @dt date, @end_dt date, @partition_id int, @count_rows int, @is_delete int

		select 
			@dt = cast(format(cast(min(d.Период_2000) as date), 'yyyy-MM-01') as date),
			@end_dt = dateadd(month, 1, cast(format(cast(max(d.Период_2000) as date), 'yyyy-MM-01') as date))
		from Stg.tmp.delete_РегистрНакопления_РасчетыПоЗаймам_2 as d

		--select @dt, @end_dt
		select @dt = '2020-08-01'

		while @dt < @end_dt 
		begin
			select @partition_id = Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(@dt)
			select @is_delete = 0

			--select @count_rows = count(*)
			--from Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as r --(nolock)
			--	inner join Stg.tmp.delete_РегистрНакопления_РасчетыПоЗаймам_2 as d
			--		on d.Период_2000 = r.Период_2000
			--		and d.Договор = r.Договор
			--where 1=1
			--	and @dt <= r.Период_2000 and r.Период_2000 < dateadd(month, 1, @dt)
			--	and @dt <= d.Период_2000 and d.Период_2000 < dateadd(month, 1, @dt)
			--	and Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(r.Период_2000)
			--		= @partition_id

			--select dt = @dt, part_id = @partition_id, cnt_rows = @count_rows

			if exists(
				select top(1) 1
				from Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as r --(nolock)
					inner join Stg.tmp.delete_РегистрНакопления_РасчетыПоЗаймам_2 as d
						on d.Период_2000 = r.Период_2000
						and d.Договор = r.Договор
				where 1=1
					and @dt <= r.Период_2000 and r.Период_2000 < dateadd(month, 1, @dt)
					and @dt <= d.Период_2000 and d.Период_2000 < dateadd(month, 1, @dt)
					and Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(r.Период_2000)
						= @partition_id
				)
			begin
				select @is_delete = 1	
			end

			--if @count_rows > 0
			if @is_delete = 1	
			begin
				--select count(*)
				--select top 100 *
				delete r
				from Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам as r --(nolock)
					inner join Stg.tmp.delete_РегистрНакопления_РасчетыПоЗаймам_2 as d
						on d.Период_2000 = r.Период_2000
						and d.Договор = r.Договор
				--where @dt <= d.Период_2000 and d.Период_2000 < dateadd(year, 1, @dt)
				where 1=1
					and @dt <= r.Период_2000 and r.Период_2000 < dateadd(month, 1, @dt)
					and @dt <= d.Период_2000 and d.Период_2000 < dateadd(month, 1, @dt)
					and Stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(r.Период_2000)
						= @partition_id
			end

			--select @dt = dateadd(year, 1, @dt)
			select @dt = dateadd(month, 1, @dt)

			--select @dt
			--WAITFOR DELAY '00:01:00'
			WAITFOR DELAY '00:00:10'
		end
		*/


		--EXEC LogDb.dbo.LogAndSendMailToAdmin 
		--	@eventName = @eventName, 
		--	@eventType = @eventType, 
		--	@message = @message, 
		--	@SendEmail = @SendEmail, 
		--	@ProcessGUID = @ProcessGUID
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка удаления записей из _1cCMR.РегистрНакопления_РасчетыПоЗаймам'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Error Stg._1cCMR.delete_РегистрНакопления_РасчетыПоЗаймам',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END