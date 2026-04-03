
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[CollectionPlan_4Plazma_INST_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC [files].[CollectionPlan_4Plazma_INST_postloader]
as
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	begin try
		declare @lastLoadDate datetime= (select isnull(max(created), '1900-01-01') from dbo.CollectionPlan_4Plazma_INST)

		if not exists(select top(1) 1 from files.CollectionPlan_4Plazma_INST_buffer_stg)
		begin
			;throw 51000, 'в таблице files.CollectionPlan_4Plazma_INST_buffer_stg нет данных', 16
		end 
		else begin
			if @lastLoadDate<(select max(created) from files.CollectionPlan_4Plazma_INST_buffer_stg)
			begin

			begin tran
				truncate table dbo.CollectionPlan_4Plazma_INST

				insert into dbo.CollectionPlan_4Plazma_INST
				(
					Дата,
					Стадия,
					[План (млн.руб.)],
					[Факт (млн.руб.)],
					[Факт %%],
					[Прогноз (млн.руб.)],
					[Прогноз %%],
					[created]
				)
				select 
					Дата,
					Стадия,
					[План (млн.руб.)],
					[Факт (млн.руб.)],
					[Факт %%] = cast(iif(t.[План (млн.руб.)]!=0
						, t.[Факт (млн.руб.)]/	t.[План (млн.руб.)], 0) as smallmoney) ,
					[Прогноз (млн.руб.)],
					[Прогноз %%] = cast(iif([План (млн.руб.)]!=0, 
						[Прогноз (млн.руб.)] / [План (млн.руб.)], 0) as smallmoney),
					[created]

				 from (
				select 
					Дата,
					Стадия,
					[План (млн.руб.)] = isnull([План (млн#руб#)],0),
					[Факт (млн.руб.)] = isnull([Факт (млн#руб#)],0),
					
					[Прогноз (млн.руб.)] = isnull([Прогноз (млн#руб#)], 0),
					[created]
				from files.CollectionPlan_4Plazma_INST_buffer_stg t
				) t
			commit TRAN
            
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
