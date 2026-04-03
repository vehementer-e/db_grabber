create   PROC _1cCMR.merge_Документ_ВыдачаДенежныхСредств
	@isDebug int = 0
as
begin
begin try
	select @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @min_period date, @ProcessGUID nvarchar(36)

	--подразумеваем, что в _upd загружены все данные,
	--начиная с некоторого периода (Дата)
	select @min_period = cast(min(u.Дата) as date)
	from _1cCMR.Документ_ВыдачаДенежныхСредств_upd as u

	if @min_period is not null
	begin

		drop table if exists #t_Договор
		create table #t_Договор(Договор binary(16))

		insert #t_Договор(Договор)
		select distinct a.Договор
		from (
			--новые записи: они есть в _upd и нет в целевой таблице
			select
				Ссылка,
				ВерсияДанных,
				ПометкаУдаления,
				Дата,
				Номер,
				Проведен,
				Договор,
				Сумма,
				Основание,
				СпособВыдачи,
				Статус,
				Ответственный,
				Комментарий,
				ПервичныйДокумент,
				ДатаВыдачи,
				ПлатежнаяСистема,
				Клиент,
				ИдентификаторПС,
				DOC_ID,
				ОбластьДанныхОсновныеДанные
			from _1cCMR.Документ_ВыдачаДенежныхСредств_upd as u
			except
			select
				Ссылка,
				ВерсияДанных,
				ПометкаУдаления,
				Дата,
				Номер,
				Проведен,
				Договор,
				Сумма,
				Основание,
				СпособВыдачи,
				Статус,
				Ответственный,
				Комментарий,
				ПервичныйДокумент,
				ДатаВыдачи,
				ПлатежнаяСистема,
				Клиент,
				ИдентификаторПС,
				DOC_ID,
				ОбластьДанныхОсновныеДанные
			from _1cCMR.Документ_ВыдачаДенежныхСредств as t
			where t.Дата >= @min_period
		) a
		union
		select distinct b.Договор
		from (
			--записи, отсутствующие в _upd
			select
				Ссылка,
				ВерсияДанных,
				ПометкаУдаления,
				Дата,
				Номер,
				Проведен,
				Договор,
				Сумма,
				Основание,
				СпособВыдачи,
				Статус,
				Ответственный,
				Комментарий,
				ПервичныйДокумент,
				ДатаВыдачи,
				ПлатежнаяСистема,
				Клиент,
				ИдентификаторПС,
				DOC_ID,
				ОбластьДанныхОсновныеДанные
			from _1cCMR.Документ_ВыдачаДенежныхСредств as t
			where t.Дата >= @min_period
			except
			select
				Ссылка,
				ВерсияДанных,
				ПометкаУдаления,
				Дата,
				Номер,
				Проведен,
				Договор,
				Сумма,
				Основание,
				СпособВыдачи,
				Статус,
				Ответственный,
				Комментарий,
				ПервичныйДокумент,
				ДатаВыдачи,
				ПлатежнаяСистема,
				Клиент,
				ИдентификаторПС,
				DOC_ID,
				ОбластьДанныхОсновныеДанные
			from _1cCMR.Документ_ВыдачаДенежныхСредств_upd as u
		) b

		if exists(select top(1) 1 from #t_Договор)
		begin
			create unique index ix1 on #t_Договор(Договор)

			select top(1) @ProcessGUID = ProcessGUID
			from _1cCMR.Документ_ВыдачаДенежныхСредств_upd as u
			order by u.Дата desc, u.Договор

			begin tran
				insert tmp.log_merge_Документ_ВыдачаДенежныхСредств
				(
					action, 

					Ссылка,
					ВерсияДанных,
					ПометкаУдаления,
					Дата,
					Номер,
					Проведен,
					Договор,
					Сумма,
					Основание,
					СпособВыдачи,
					Статус,
					Ответственный,
					--Комментарий,
					ПервичныйДокумент,
					ДатаВыдачи,
					ПлатежнаяСистема,
					Клиент,
					ИдентификаторПС,
					DOC_ID,
					--ОбластьДанныхОсновныеДанные

					ProcessGUID
					)
				select
					action = 'D',

					t.Ссылка,
					t.ВерсияДанных,
					t.ПометкаУдаления,
					t.Дата,
					t.Номер,
					t.Проведен,
					t.Договор,
					t.Сумма,
					t.Основание,
					t.СпособВыдачи,
					t.Статус,
					t.Ответственный,
					--t.Комментарий,
					t.ПервичныйДокумент,
					t.ДатаВыдачи,
					t.ПлатежнаяСистема,
					t.Клиент,
					t.ИдентификаторПС,
					t.DOC_ID,
					--t.ОбластьДанныхОсновныеДанные

					@ProcessGUID
				from #t_Договор as r
					inner join _1cCMR.Документ_ВыдачаДенежныхСредств as t
						on t.Договор = r.Договор

				if @isDebug = 0 begin
					delete t
					from #t_Договор as r
						inner join _1cCMR.Документ_ВыдачаДенежныхСредств as t
							on t.Договор = r.Договор
					where t.Дата >= @min_period

					insert _1cCMR.Документ_ВыдачаДенежныхСредств
					(
						Ссылка,
						ВерсияДанных,
						ПометкаУдаления,
						Дата,
						Номер,
						Проведен,
						Договор,
						Сумма,
						Основание,
						СпособВыдачи,
						Статус,
						Ответственный,
						Комментарий,
						ПервичныйДокумент,
						ДатаВыдачи,
						ПлатежнаяСистема,
						Клиент,
						ИдентификаторПС,
						DOC_ID,
						ОбластьДанныхОсновныеДанные,

						DWHInsertedDate,
						ProcessGUID
					)
					select
						t.Ссылка,
						t.ВерсияДанных,
						t.ПометкаУдаления,
						t.Дата,
						t.Номер,
						t.Проведен,
						t.Договор,
						t.Сумма,
						t.Основание,
						t.СпособВыдачи,
						t.Статус,
						t.Ответственный,
						t.Комментарий,
						t.ПервичныйДокумент,
						t.ДатаВыдачи,
						t.ПлатежнаяСистема,
						t.Клиент,
						t.ИдентификаторПС,
						t.DOC_ID,
						t.ОбластьДанныхОсновныеДанные,

						DWHInsertedDate = getdate(),
						t.ProcessGUID
					from #t_Договор as r
						inner join _1cCMR.Документ_ВыдачаДенежныхСредств_upd as t
							on t.Договор = r.Договор

					--после merge обновлять данные в таблице PredicateValue для данной таблицы
					exec Stg.etl.UpdatePredicateValue
						@TableName = '_1cCMR.Документ_ВыдачаДенежныхСредств_upd',
						@DataBaseName = 'Stg',
						@ProcessGUID = @ProcessGUID
				end
				--//if @isDebug = 0

				insert tmp.log_merge_Документ_ВыдачаДенежныхСредств
				(
					action, 

					Ссылка,
					ВерсияДанных,
					ПометкаУдаления,
					Дата,
					Номер,
					Проведен,
					Договор,
					Сумма,
					Основание,
					СпособВыдачи,
					Статус,
					Ответственный,
					--Комментарий,
					ПервичныйДокумент,
					ДатаВыдачи,
					ПлатежнаяСистема,
					Клиент,
					ИдентификаторПС,
					DOC_ID,
					--ОбластьДанныхОсновныеДанные

					ProcessGUID
					)
				select
					action = 'I',

					t.Ссылка,
					t.ВерсияДанных,
					t.ПометкаУдаления,
					t.Дата,
					t.Номер,
					t.Проведен,
					t.Договор,
					t.Сумма,
					t.Основание,
					t.СпособВыдачи,
					t.Статус,
					t.Ответственный,
					--t.Комментарий,
					t.ПервичныйДокумент,
					t.ДатаВыдачи,
					t.ПлатежнаяСистема,
					t.Клиент,
					t.ИдентификаторПС,
					t.DOC_ID,
					--t.ОбластьДанныхОсновныеДанные

					@ProcessGUID
				from #t_Договор as r
					inner join _1cCMR.Документ_ВыдачаДенежныхСредств_upd as t
						on t.Договор = r.Договор
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
