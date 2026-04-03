-- exec [dbo].[report_dashboard_001_CC] 
CREATE PROCEDURE [dbo].[report_maintable_update_krdn] 
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

-- сообщим о начале работы процеедуры по формированию отчетов
begin try
exec logdb.dbo.[LogAndSendMailToAdminRep] 'report_maintable_update_krdn','Info','procedure started',N'Начало формирования первых таблиц отчетов'
end try
begin catch
end catch


-- обновление таблицы переходов заявки по статусам
begin try
exec  [etl].[base_etl_mt_requests_transition_mfo] 1
end try
begin catch
	;throw
end catch

-- обновление таблицы переходов договоров по статусам
begin try
exec [etl].[base_etl_mt_loans_transition_mfo] 
end try
begin catch
	;throw
end catch

-- обновление таблицы заявки и займы из мфо
begin try
exec  [etl].[base_etl_mt_requests_loans_mfo]
end try
begin catch
	;throw
end catch


-- обновление таблицы платежей по договорам
begin try
exec  [etl].[base_etl_mt_payments_receipt_cmr_umfo]
end try
begin catch
	;throw
end catch

-- обновление таблицы кредитного портфеля
begin try
exec [etl].[base_etl_mt_credit_portfolio_mfo]
end try
begin catch
	;throw
end catch
/*
begin try
exec [etl].[base_etl_mt_credit_portfolio_cmr]
end try
begin catch
end catch
*/
-- сообщим о завершении работы процедур обновления исходных таблиц
begin try
exec logdb.dbo.[LogAndSendMailToAdminRep] 'report_maintable_update_krdn','Info','procedure work' ,N'Заполнение исходных таблиц завершено'
end try
begin catch
end catch
--------------------------------------------------
------- ТАБЛИЦЫ ДЛЯ ОТЧЕТОВ

-- обновление таблицы для отчета поступление коллектинг
begin try
exec [etl].[base_etl_report_collecting_receipt_cmr]
end try
begin catch
	;throw
end catch

-- обновление таблицы для отчета KPI
--2021_05_11
/*
begin try
exec [etl].[base_etl_report_kpi]
end try
begin catch
end catch
*/

-- обновление таблицы для отчета по дням и месяцам
begin try
exec [etl].[base_etl_report_on_days_months_mfo]
end try
begin catch
	;throw
end catch

-- обновление таблицы для отчета по Верификации
begin try
exec [etl].[base_etl_report_Verification_mfo]
end try
begin catch
	;throw
end catch

-- обновление таблицы для детального отчета по Верификации
begin try
exec [etl].[base_etl_report_Verification_mfo_Details]
end try
begin catch
	;throw
end catch


exec logdb.dbo.[LogAndSendMailToAdminRep] 'report_maintable_update_krdn','Info','procedure finished' ,'Заполнение витрин отчетов завершено' --,@rowcount


END

