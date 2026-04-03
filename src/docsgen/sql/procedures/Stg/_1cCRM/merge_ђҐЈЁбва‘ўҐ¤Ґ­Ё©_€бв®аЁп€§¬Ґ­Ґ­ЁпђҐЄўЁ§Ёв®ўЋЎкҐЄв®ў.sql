-- Usage: запуск процедуры с параметрами
-- EXEC _1cCRM.merge_РегистрСведений_ИсторияИзмененияРеквизитовОбъектов @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create   PROC _1cCRM.merge_РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
as
begin
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @min_period date, @ProcessGUID nvarchar(36)

	--в _upd всегда загружаются данные, начиная  с некоторого периода (date)
	select @min_period = cast(min(u.Период) as date)
	from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов_upd as u

	if @min_period is not null
	begin

		drop table if exists #t_Объект_Ссылка
		create table #t_Объект_Ссылка(Объект_Ссылка binary(16))

		insert #t_Объект_Ссылка(Объект_Ссылка)
		select distinct a.Объект_Ссылка
		from (
			--новые записи: они есть в _upd и нет в целевой таблице
			select
				[Период],
				[Объект_Тип],
				[Объект_ТипСсылки],
				[Объект_Ссылка],
				[НомерВерсии],
				[Реквизит],
				[ЗначениеРеквизитаДо],
				[ЗначениеРеквизитаДоПредставление],
				[ЗначениеРеквизитаПосле],
				[ЗначениеРеквизитаПослеПредставление],
				[ОбменДаннымиЗагрузка],
				[НомерСтрокиТабличнойЧасти],
				[Событие],
				[Пользователь]
			from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов_upd as u
			except
			select
				[Период],
				[Объект_Тип],
				[Объект_ТипСсылки],
				[Объект_Ссылка],
				[НомерВерсии],
				[Реквизит],
				[ЗначениеРеквизитаДо],
				[ЗначениеРеквизитаДоПредставление],
				[ЗначениеРеквизитаПосле],
				[ЗначениеРеквизитаПослеПредставление],
				[ОбменДаннымиЗагрузка],
				[НомерСтрокиТабличнойЧасти],
				[Событие],
				[Пользователь]
			from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов as t
			where t.Период >= @min_period
		) a
		union
		select distinct b.Объект_Ссылка
		from (
			--записи, отсутствующие в _upd
			select
				[Период],
				[Объект_Тип],
				[Объект_ТипСсылки],
				[Объект_Ссылка],
				[НомерВерсии],
				[Реквизит],
				[ЗначениеРеквизитаДо],
				[ЗначениеРеквизитаДоПредставление],
				[ЗначениеРеквизитаПосле],
				[ЗначениеРеквизитаПослеПредставление],
				[ОбменДаннымиЗагрузка],
				[НомерСтрокиТабличнойЧасти],
				[Событие],
				[Пользователь]
			from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов as t
			where t.Период >= @min_period
			except
			select
				[Период],
				[Объект_Тип],
				[Объект_ТипСсылки],
				[Объект_Ссылка],
				[НомерВерсии],
				[Реквизит],
				[ЗначениеРеквизитаДо],
				[ЗначениеРеквизитаДоПредставление],
				[ЗначениеРеквизитаПосле],
				[ЗначениеРеквизитаПослеПредставление],
				[ОбменДаннымиЗагрузка],
				[НомерСтрокиТабличнойЧасти],
				[Событие],
				[Пользователь]
			from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов_upd as u
		) b

		if exists(select top(1) 1 from #t_Объект_Ссылка)
		begin
			create unique index ix1 on #t_Объект_Ссылка(Объект_Ссылка)

			select top(1) @ProcessGUID = ProcessGUID
			from _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов_upd as u
			order by u.[Период] desc, u.[Объект_Ссылка], u.[Реквизит]

			begin tran
				delete t
				from #t_Объект_Ссылка as r
					inner join _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов as t
						on t.Объект_Ссылка = r.Объект_Ссылка
				where t.Период >= @min_period

				insert _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
				(
					[Период],
					[Объект_Тип],
					[Объект_ТипСсылки],
					[Объект_Ссылка],
					[НомерВерсии],
					[Реквизит],
					[ЗначениеРеквизитаДо],
					[ЗначениеРеквизитаДоПредставление],
					[ЗначениеРеквизитаПосле],
					[ЗначениеРеквизитаПослеПредставление],
					[ОбменДаннымиЗагрузка],
					[НомерСтрокиТабличнойЧасти],
					[Событие],
					[Пользователь],
					ОбластьДанныхОсновныеДанные,
					DWHInsertedDate,
					ProcessGUID
				)
				select
					t.[Период],
					t.[Объект_Тип],
					t.[Объект_ТипСсылки],
					t.[Объект_Ссылка],
					t.[НомерВерсии],
					t.[Реквизит],
					t.[ЗначениеРеквизитаДо],
					t.[ЗначениеРеквизитаДоПредставление],
					t.[ЗначениеРеквизитаПосле],
					t.[ЗначениеРеквизитаПослеПредставление],
					t.[ОбменДаннымиЗагрузка],
					t.[НомерСтрокиТабличнойЧасти],
					t.[Событие],
					t.[Пользователь],
					t.ОбластьДанныхОсновныеДанные,
					DWHInsertedDate = getdate(),
					t.ProcessGUID
				from #t_Объект_Ссылка as r
					inner join _1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов_upd as t
						on t.Объект_Ссылка = r.Объект_Ссылка

				insert tmp.log_merge_РегистрСведений_ИсторияИзмененияРеквизитовОбъектов
				(
					Объект_Ссылка, 
					ProcessGUID
				)
				select t.Объект_Ссылка, @ProcessGUID
				from #t_Объект_Ссылка as t
			commit tran
		end
		--//exists(select top(1) 1 from #t_Объект_Ссылка)
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
