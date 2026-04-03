CREATE procedure [etl].[start_reports_carmoney]
as
begin

 set nocount on

 --Отчет Поступление платежей из просрочки (тест мой)
  EXEC msdb.dbo.sp_start_job N'F6921D1A-5842-4584-AD0B-9ABF52AA2F5C'

  --Отчет Ежедневные отчеты по заявкам и займам (тест мой)
  EXEC msdb.dbo.sp_start_job N'A9DA59B4-6E74-4415-8B9F-4ACB651E01ED'
  /*
  -- Выгрузка RiskReestr в сетевую папку с датой в имени файла
  EXEC msdb.dbo.sp_start_job N'D850671F-1F57-420F-823B-F8C0287D22F2'
  --ReportRollRates
  EXEC msdb.dbo.sp_start_job N'C7972555-0CA0-4B0A-9208-6655CBE49C36'
  --recidiv
  EXEC msdb.dbo.sp_start_job N'E9EA5B3E-03DA-4E8F-818D-A5A79291242B'
  -- сообщение что реестры сформированы
  EXEC msdb.dbo.sp_start_job N'16F0D20D-B9EB-4968-8B15-284ED7143D0C'

  -- запуск расчета стратегии
 -- EXEC msdb.dbo.sp_start_job N'Dialer - Create List using strategy'

 */

end


--select 'RiskReestr_'+format(getdate(),'dd_MM_yyyy') as filename