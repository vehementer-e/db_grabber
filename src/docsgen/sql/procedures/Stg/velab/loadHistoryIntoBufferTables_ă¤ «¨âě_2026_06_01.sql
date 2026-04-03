--exec [velab].[loadHistoryIntoBufferTables]

-- Usage: запуск процедуры с параметрами
-- EXEC [velab].[loadHistoryIntoBufferTables] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC [velab].[loadHistoryIntoBufferTables]
WITH EXECUTE AS 'dbo'
as
begin
set nocount on 


EXECUTE AS LOGIN = 'sa';
--EXECUTE AS LOGIN = 'CM\sqlservice'
--SELECT SUSER_NAME(), USER_NAME();  
    
-------------------------------
   
  -------------------------------
  --перенесли в процедуру -  [velab].[loadHistoryInto_dwh_ka_Buffer_Table] и в задание 
  /*
  delete from  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT *
  FROM collection.dbo.dwh_ka_buffer') 

  insert into OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT *
  FROM collection.dbo.dwh_ka_buffer') 
  select * from dwh_new.dbo.v_ka
  */




  --- CRMClientGUID справочник
  
--DWH-1990 Остановить загрузку данных в space
/*
  -------------------------------
  delete from  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT *
  FROM collection.dbo.CRMClient_references') 


     insert into OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT *
  FROM collection.dbo.CRMClient_references') 
  select*
  from dwh_new.staging.CRMClient_references 
*/


  ---


  -----------------------MFO------------


  exec stg.[velab].[MFOCallResultsHistory] 

 declare @dt datetime


  select @dt=a.dt from  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT max(dt) dt
  FROM collection.dbo.mfo_buffer')  as a
 -- select @dt
  
  insert into OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT *
  FROM collection.dbo.mfo_buffer') 
  
  select  *  from stg.velab.mfo_buffer where dt>@dt and ContractNo is not null


  ------------------ CRM 
  exec STG.velab.[CRMCallResultsHistory] 
 -- declare @dt datetime


  select @dt=a.dt from  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT max(dt) dt
  FROM collection.dbo.crm_buffer')  as a
  --select @dt
  insert into OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT [ContractNo]
             ,[MFOContractGUID]
             ,[dt]
             ,[Comment]
             ,[UserFIO]
             ,[UserEmail]
             ,[CRM_ClientFIO]
             ,[CRM_ClientPassportSerial]
             ,[CRM_ClientOassportNo]
             ,[CRM_ClientPassportIssueDate]
             ,[CRM_ClientPassportIssueCode]
             ,[CRM_ClientPassportIssuePlace]
             ,[phoneNo]
             ,[CRM_ClientMobilePhone]
             ,[CRM_ClientContactPhone]
             ,[CMRContractGUID]
             ,[CRMRequestGUID]
             ,[CRMClientGUID]
             ,[crm_код]
             ,[crm_успешный]
             ,[Содержание]
  FROM collection.dbo.crm_buffer') 
  select cast([ContractNo] as nvarchar(14))
             ,cast([MFOContractGUID]  as nvarchar(100))
             ,cast([dt] as datetime)
             ,cast([Comment]  as nvarchar(max))
             ,cast([UserFIO]  as nvarchar(100))
             ,cast([UserEmail]  as nvarchar(255))
             ,cast([CRM_ClientFIO]  as nvarchar(150))
             ,cast([CRM_ClientPassportSerial]  as nvarchar(5))
             ,cast([CRM_ClientOassportNo]  as nvarchar(6))
             ,cast([CRM_ClientPassportIssueDate] as datetime)
             ,cast([CRM_ClientPassportIssueCode]  as nvarchar(10))
             ,cast([CRM_ClientPassportIssuePlace]  as nvarchar(500))
             ,cast([phoneNo]  as nvarchar(100))
             ,cast([CRM_ClientMobilePhone]  as nvarchar(16))
             ,try_cast([CRM_ClientContactPhone]  as int)
             ,cast([CMRContractGUID]  as nvarchar(100))
             ,cast([CRMRequestGUID]  as nvarchar(100))
             ,cast([CRMClientGUID]  as nvarchar(100))
             ,cast([crm_код]  as nvarchar(20))
             ,cast([crm_успешный] as binary )
             ,cast([Содержание]   as nvarchar(max))
 --select count(*)
     from stg.velab.crm_buffer where dt>---'20191031'
     @dt



---
---   PlanB
---
exec STG.velab.CreatePlanB

--select * from  stg.velab.Clients_PlanB   
delete from 
 OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT 
       
       [GUID клиента]
      ,[ФИО клиента]
      ,[GUID заявки]
      ,[Номер заявки]
      ,[Дата заявки]
      ,[Семейное положение]
      ,[Сумма доходов]
      ,[Сумма расходов]
      ,[Адрес (сведения о работе)]
      ,[Рабочий телефон (сведения о работе)]
      ,[ФИО руководителя (сведения о работе)]
      ,[VIN TC]
      ,[Дисконт ]
      ,[Ликвидность]
      ,[Оценочная стоимость]
      ,[Стат_Наименование]
      ,[СтатусОрганизации]
      ,[ЮридическийАдресОрганизации]
      ,[АдресРаботы]
      ,[РегионФактическогоПроживания]
      ,[ДоходПоСправке]
      ,[ДоходРосстат]
      ,[ДоходИзКИ]
      ,[РасходИзКИ]
      ,[ДоходПодтвержденныйПоТелефону]
      ,[ДоходРаботаЯндекс]
      ,[Должность]
      ,[РыночнаяОценкаСтоимости]
       from collection.dbo.Clients_PlanB')



insert into  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
       'SELECT 
       
       [GUID клиента]
      ,[ФИО клиента]
      ,[GUID заявки]
      ,[Номер заявки]
      ,[Дата заявки]
      ,[Семейное положение]
      ,[Сумма доходов]
      ,[Сумма расходов]
      ,[Адрес (сведения о работе)]
      ,[Рабочий телефон (сведения о работе)]
      ,[ФИО руководителя (сведения о работе)]
      ,[VIN TC]
      ,[Дисконт ]
      ,[Ликвидность]
      ,[Оценочная стоимость]
      ,[Стат_Наименование]
      ,[СтатусОрганизации]
      ,[ЮридическийАдресОрганизации]
      ,[АдресРаботы]
      ,[РегионФактическогоПроживания]
      ,[ДоходПоСправке]
      ,[ДоходРосстат]
      ,[ДоходИзКИ]
      ,[РасходИзКИ]
      ,[ДоходПодтвержденныйПоТелефону]
      ,[ДоходРаботаЯндекс]
      ,[Должность]
      ,[РыночнаяОценкаСтоимости]
      ,officeAddress
       from collection.dbo.Clients_PlanB')



  select [GUID клиента]
      ,[ФИО клиента]
      ,[GUID заявки]
      ,[Номер заявки]
      ,[Дата заявки]
      ,[Семейное положение]
      ,[Сумма доходов]
      ,[Сумма расходов]
      ,[Адрес (сведения о работе)]
      ,[Рабочий телефон (сведения о работе)]
      ,[ФИО руководителя (сведения о работе)]
      ,[VIN TC]
      ,[Дисконт ]
      ,[Ликвидность]
      ,[Оценочная стоимость]
      ,[Стат_Наименование]
      ,[СтатусОрганизации]
      ,[ЮридическийАдресОрганизации]
      ,[АдресРаботы]
      ,[РегионФактическогоПроживания]
      ,[ДоходПоСправке]
      ,[ДоходРосстат]
      ,[ДоходИзКИ]
      ,[РасходИзКИ]
      ,[ДоходПодтвержденныйПоТелефону]
      ,[ДоходРаботаЯндекс]
      ,[Должность]
      ,[РыночнаяОценкаСтоимости]
      ,officeAddress
      --select * 
     from stg.velab.Clients_PlanB
     

end
