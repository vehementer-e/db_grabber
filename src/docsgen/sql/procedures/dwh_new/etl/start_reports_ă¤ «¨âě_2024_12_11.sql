CREATE procedure [etl].[start_reports]
as
begin

 set nocount on
/*
 --new_clients
  EXEC msdb.dbo.sp_start_job N'78A51986-1F5C-42B7-A831-099FF9D1593E' 
  --risk_reestr
  EXEC msdb.dbo.sp_start_job N'A7A9C047-BF48-4C51-A24A-1921D6C90FAC'
  
  -- Выгрузка RiskReestr в сетевую папку с датой в имени файла
  EXEC msdb.dbo.sp_start_job N'D850671F-1F57-420F-823B-F8C0287D22F2'
  --ReportRollRates
  EXEC msdb.dbo.sp_start_job N'C7972555-0CA0-4B0A-9208-6655CBE49C36'
  --recidiv
  EXEC msdb.dbo.sp_start_job N'E9EA5B3E-03DA-4E8F-818D-A5A79291242B'
  -- сообщение что реестры сформированы
  EXEC msdb.dbo.sp_start_job N'16F0D20D-B9EB-4968-8B15-284ED7143D0C'
  */
  -- запуск расчета стратегии
 -- EXEC msdb.dbo.sp_start_job N'Dialer - Create List using strategy'

DECLARE @RunStoredProcSQL VARCHAR(1000);
SET @RunStoredProcSQL = 'EXEC RS_Jobs.dbo.StartRiskReports';
--SELECT @RunStoredProcSQL --Debug
EXEC (@RunStoredProcSQL) AT [c2-vsr-birs];
Print 'Procedure Executed';


end


--select 'RiskReestr_'+format(getdate(),'dd_MM_yyyy') as filename