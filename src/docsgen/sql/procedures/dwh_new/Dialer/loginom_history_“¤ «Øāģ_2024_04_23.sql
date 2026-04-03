CREATE    procedure  [Dialer].[loginom_history]
as
/*
insert into dwh_new.dialer.[ActionID_history]
SELECT logdatetime=getdate(), Stage, CRMClientGUID, external_id, fio, StrategyDate, ActionID
  FROM STG._loginom.ActionID
 union all
select  logdatetime=getdate(),
      [Stage] 
      ,[CRMClientGUID]
      ,[external_id]
      ,[fio]
      ,[StrategyDate]
      
      ,[Email]
from  STG._loginom.ActionEmail
union all
SELECT  logdatetime=getdate(),
       [Stage]
      ,[CRMClientGUID]
      ,[external_id]
      ,[fio]
      ,[StrategyDate]
      ,[SMS]
  FROM STG._loginom.ActionSMS
  */
insert into dwh_new.dialer.[Client_Stage_history]
SELECT logdatetime=getdate(), CRMClientGUID, fio, birth_date, Client_Stage 
from
 STG._loginom.Client_Stage 

