

-- Usage: запуск процедуры с параметрами
-- EXEC [files].[pep3_findostavka_report_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [files].[pep3_findostavka_report_postloader]
as
begin
	if exists(select top(1) 1 from files.pep3_findostavka_report_buffer_stg b)
	begin
		delete from files.pep3_findostavka_report_buffer
		insert into files.pep3_findostavka_report_buffer
		select [номер заказа]
			  ,[дата создания]
			  ,[дата доставки]
			  ,[регион]
			  ,[город]
			  ,[имя клиента]
			  ,[код продукта]
			  ,[пак-код]
			  ,[статус]
			  ,[статус-2]
			  ,[комментарий]
			  ,[курьер]
			  ,[created]
		from files.pep3_findostavka_report_buffer_stg b
		
		insert into files.pep3_findostavka_report_history
		select  [номер заказа]
			  ,[дата создания]
			  ,[дата доставки]
			  ,[регион]
			  ,[город]
			  ,[имя клиента]
			  ,[код продукта]
			  ,[пак-код]
			  ,[статус]
			  ,[статус-2]
			  ,[комментарий]
			  ,[курьер]
			  ,[created] 
		from files.pep3_findostavka_report_buffer_stg b

	end

return	
end
