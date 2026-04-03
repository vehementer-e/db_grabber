-- Usage: запуск процедуры с параметрами
-- EXEC _1cCMR.merge_РегистрНакопления_АктивныеАкции @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create   PROC _1cCMR.merge_РегистрНакопления_АктивныеАкции
as
begin
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @min_period date, @ProcessGUID nvarchar(36)

	--в _upd всегда загружаются данные, начиная  с некоторого периода (date)
	select @min_period = cast(min(u.Период) as date)
	from _1cCMR.РегистрНакопления_АктивныеАкции_upd as u

	if @min_period is not null
	begin

		drop table if exists #t_Договор
		create table #t_Договор(Договор binary(16))

		insert #t_Договор(Договор)
		select distinct a.Договор
		from (
			--новые записи: они есть в _upd и нет в целевой таблице
			select
				Период,
				Регистратор_ТипСсылки,
				Регистратор_Ссылка,
				НомерСтроки,
				Активность,
				ВидДвижения,
				Договор,
				Акция,
				Удалить_ДатаНачала,
				Удалить_ДатаОкончания,
				Активна
			from _1cCMR.РегистрНакопления_АктивныеАкции_upd as u
			except
			select
				Период,
				Регистратор_ТипСсылки,
				Регистратор_Ссылка,
				НомерСтроки,
				Активность,
				ВидДвижения,
				Договор,
				Акция,
				Удалить_ДатаНачала,
				Удалить_ДатаОкончания,
				Активна
			from _1cCMR.РегистрНакопления_АктивныеАкции as t
			where t.Период >= @min_period
		) a
		union
		select distinct b.Договор
		from (
			--записи, отсутствующие в _upd
			select
				Период,
				Регистратор_ТипСсылки,
				Регистратор_Ссылка,
				НомерСтроки,
				Активность,
				ВидДвижения,
				Договор,
				Акция,
				Удалить_ДатаНачала,
				Удалить_ДатаОкончания,
				Активна
			from _1cCMR.РегистрНакопления_АктивныеАкции as t
			where t.Период >= @min_period
			except
			select
				Период,
				Регистратор_ТипСсылки,
				Регистратор_Ссылка,
				НомерСтроки,
				Активность,
				ВидДвижения,
				Договор,
				Акция,
				Удалить_ДатаНачала,
				Удалить_ДатаОкончания,
				Активна
			from _1cCMR.РегистрНакопления_АктивныеАкции_upd as u
		) b

		if exists(select top(1) 1 from #t_Договор)
		begin
			create unique index ix1 on #t_Договор(Договор)

			select top(1) @ProcessGUID = ProcessGUID
			from _1cCMR.РегистрНакопления_АктивныеАкции_upd as u
			order by u.[Период] desc, u.[Договор]

			begin tran
				delete t
				from #t_Договор as r
					inner join _1cCMR.РегистрНакопления_АктивныеАкции as t
						on t.Договор = r.Договор
				where t.Период >= @min_period

				insert _1cCMR.РегистрНакопления_АктивныеАкции
				(
					Период,
					Регистратор_ТипСсылки,
					Регистратор_Ссылка,
					НомерСтроки,
					Активность,
					ВидДвижения,
					Договор,
					Акция,
					Удалить_ДатаНачала,
					Удалить_ДатаОкончания,
					Активна,
					ОбластьДанныхОсновныеДанные,
					DWHInsertedDate,
					ProcessGUID
				)
				select
					t.Период,
					t.Регистратор_ТипСсылки,
					t.Регистратор_Ссылка,
					t.НомерСтроки,
					t.Активность,
					t.ВидДвижения,
					t.Договор,
					t.Акция,
					t.Удалить_ДатаНачала,
					t.Удалить_ДатаОкончания,
					t.Активна,
					t.ОбластьДанныхОсновныеДанные,
					DWHInsertedDate = getdate(),
					t.ProcessGUID
				from #t_Договор as r
					inner join _1cCMR.РегистрНакопления_АктивныеАкции_upd as t
						on t.Договор = r.Договор

				insert tmp.log_merge_РегистрНакопления_АктивныеАкции
				(
					Договор, 
					ProcessGUID
				)
				select t.Договор, @ProcessGUID
				from #t_Договор as t
			commit tran
		end
		--//exists(select top(1) 1 from #t_Договор)
	end
	--// @min_period is not null

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'ETL ERROR'

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
