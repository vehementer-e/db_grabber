
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[ReportKPI_4Plazma_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [files].[ReportKPI_4Plazma_postloader]
as
begin
	begin try
		declare @lastLoadDate datetime= (select isnull(max(created), '1900-01-01') from dbo.KPI_4Plazma)

		if not exists(select top(1) 1 from  files.ReportKPI_4Plazma_buffer_stg)
		begin
			;throw 51000, 'в таблице files.ReportKPI_4Plazma_buffer_stg нет данных', 16
		end 
		else begin
			if @lastLoadDate<(select max(created) from  files.ReportKPI_4Plazma_buffer_stg)
			begin

			begin tran
				truncate table dbo.KPI_4Plazma
				insert into dbo.KPI_4Plazma
				(
					[Месяц]
					,[ОД, руб.]
					,[%%, руб.]
					,created
				)
				select 
				[Показатель]
				,[ОД, руб#]
				,[%%, руб#]
				,created
				from files.ReportKPI_4Plazma_buffer_stg
			commit tran
				select @@ROWCOUNT
			end
		end

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end
