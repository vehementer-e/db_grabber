-- Usage: запуск процедуры с параметрами
-- EXEC _1cCRM.merge_РегистрСведений_СтатусыЗаявокНаЗаймПодПТС @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create   PROC _1cCRM.merge_РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
as
begin
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @min_period date, @ProcessGUID nvarchar(36)

	--в _upd всегда загружаются данные, начиная  с некоторого периода (date)
	select @min_period = cast(min(u.Период) as date)
	from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС_upd as u

	if @min_period is not null
	begin

		drop table if exists #t_Заявка
		create table #t_Заявка(Заявка binary(16))

		insert #t_Заявка(Заявка)
		select distinct a.Заявка
		from (
			--новые записи: они есть в _upd и нет в целевой таблице
			select
				Период, Заявка, Статус, Ответственный, ПричинаОтказа, 
				ДатаЗаписиСтатуса, ДатаПоследнейЗаписиСтатуса
			from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС_upd as u
			except
			select
				Период, Заявка, Статус, Ответственный, ПричинаОтказа, 
				ДатаЗаписиСтатуса, ДатаПоследнейЗаписиСтатуса
			from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС as t
			where t.Период >= @min_period
		) a
		union
		select distinct b.Заявка
		from (
			--записи, отсутствующие в _upd
			select
				Период, Заявка, Статус, Ответственный, ПричинаОтказа, 
				ДатаЗаписиСтатуса, ДатаПоследнейЗаписиСтатуса
			from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС as t
			where t.Период >= @min_period
			except
			select
				Период, Заявка, Статус, Ответственный, ПричинаОтказа, 
				ДатаЗаписиСтатуса, ДатаПоследнейЗаписиСтатуса
			from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС_upd as u
		) b

		if exists(select top(1) 1 from #t_Заявка)
		begin
			create unique index ix1 on #t_Заявка(Заявка)

			select top(1) @ProcessGUID = ProcessGUID
			from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС_upd as u
			order by u.Период, u.Заявка, u.Статус

			begin tran
				delete t
				from #t_Заявка as r
					inner join _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС as t
						on t.Заявка = r.Заявка
				where t.Период >= @min_period

				insert _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС
				(
					Период,
					Заявка,
					Статус,
					Ответственный,
					ПричинаОтказа,
					ДатаЗаписиСтатуса,
					ДатаПоследнейЗаписиСтатуса,
					ОбластьДанныхОсновныеДанные,
					DWHInsertedDate,
					ProcessGUID
				)
				select
					t.Период,
					t.Заявка,
					t.Статус,
					t.Ответственный,
					t.ПричинаОтказа,
					t.ДатаЗаписиСтатуса,
					t.ДатаПоследнейЗаписиСтатуса,
					t.ОбластьДанныхОсновныеДанные,
					DWHInsertedDate = getdate(),
					t.ProcessGUID
				from #t_Заявка as r
					inner join _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС_upd as t
						on t.Заявка = r.Заявка

				insert tmp.log_merge_РегистрСведений_СтатусыЗаявокНаЗаймПодПТС(Заявка, ProcessGUID)
				select t.Заявка, @ProcessGUID
				from #t_Заявка as t
			commit tran
		end
		--//exists(select top(1) 1 from #t_Заявка)
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
