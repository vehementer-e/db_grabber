CREATE   PROCEDURE [dbo].[functions]
AS
BEGIN


/*

declare @counter int = 10
while exists(
select * from [v_Запущенные джобы]
where 
job_name='%____%'
and job_name like '%____%'
and current_executed_step_id=1
) and @counter>=0
begin
select 'waiting',  getdate()
exec message 'message' 
waitfor delay '00:00:01'
set @counter = @counter-1
end 

select 'finally',  getdate()




*/




--   select Path, a.ScheduleID
--FROM 
--   ReportServer.dbo.ReportSchedule a 
--   JOIN ReportServer.dbo.Catalog e ON a.ReportID = e.itemid
--   where path like '%кэш%'

-- exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'AB4CE3FF-7B5F-4FD8-B7D7-5F84B9F38270'








declare @a date 

select 
1
,dateadd(day, datediff(day, '1900-01-01', @a) / 7 * 7, '1900-01-01')   Неделя
,cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, @a), 0) as date) Месяц
,cast(DATEADD(qq   , DATEDIFF(qq   , 0, @a), 0) as date) Квартал


drop table if exists ##t11

DECLARE @ReturnCode int, @ReturnMessage varchar(8000)
EXEC Stg.dbo.ExecLoadExcel
	@PathName = '\\10.196.41.14\DWHFiles\Analytics\AdHoc\',
	@FileName = '____________________.xlsx',
	@SheetName = 'Лист1$',
	@TableName = '##t11', --'files.TestFile1',
	@isMoveFile = 0,
	@ReturnCode = @ReturnCode OUTPUT,
	@ReturnMessage = @ReturnMessage OUTPUT
SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage
select * from ##t11

declare @a1 nvarchar(max) = format( getdate(), 'yyyy-MM-dd HH:mm:ss')+' шаг 1'
--set @a1 =  format( getdate(), 'yyyy-MM-dd HH:mm:ss')+ 'шаг x'
--RAISERROR(@a1,0,0)  waitfor delay '00:00:01'
RAISERROR(@a1,0,0) WITH NOWAIT

waitfor delay '00:00:01'

--collate Cyrillic_General_CI_AS

--ssrs quarter DatePart(DateInterval.Quarter,Fields!date_var.Value)
--ssrs link on textbox ReportItems!______________.Value
--ssrs new line expression Environment.NewLine
--ssrs me value =IIF(Me.Value < 0,"Red","Green")



--Извлечь лиды по айди
/*
DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
	[UF_UPDATED_AT] [datetime2](7) NULL,
	[UF_ROW_ID] [varchar](128) NULL,
	[UF_NAME] [varchar](512) NULL,
	[UF_AGENT_NAME] [varchar](128) NULL,
	[UF_STAT_CAMPAIGN] [varchar](512) NULL,
	[UF_STAT_CLIENT_ID_YA] [varchar](128) NULL,
	[UF_STAT_CLIENT_ID_GA] [varchar](128) NULL,
	[UF_TYPE] [varchar](128) NULL,
	[UF_SOURCE] [varchar](128) NULL,
	[UF_ACTUALIZE_AT] [datetime2](7) NULL,
	[UF_CAR_MARK] [varchar](128) NULL,
	[UF_CAR_MODEL] [varchar](128) NULL,
	[UF_PHONE_ADD] [varchar](128) NULL,
	[UF_PARENT_ID] [int] NULL,
	[UF_GROUP_ID] [varchar](128) NULL,
	[UF_PRIORITY] [int] NULL,
	[UF_RC_REJECT_CM] [varchar](512) NULL,
	[UF_APPMECA_TRACKER] [varchar](128) NULL,
	[UF_LOGINOM_CHANNEL] [varchar](128) NULL,
	[UF_LOGINOM_GROUP] [varchar](128) NULL,
	[UF_LOGINOM_PRIORITY] [int] NULL,
	[UF_LOGINOM_STATUS] [varchar](128) NULL,
	[UF_LOGINOM_DECLINE] [varchar](128) NULL,
	[Канал от источника] [nvarchar](255) NULL,
	[Группа каналов] [nvarchar](255) NULL,
	[UF_CLID] [nvarchar](72) NULL,
	[UF_MATCH_ALGORITHM] [nvarchar](26) NULL,
	[UF_CLB_CHANNEL] [nvarchar](50) NULL,
	[UF_LOAN_MONTH_COUNT] [int] NULL,
	[UF_STAT_SYSTEM] [nvarchar](16) NULL,
	[UF_STAT_DETAIL_INFO] [nvarchar](1236) NULL,
	[UF_STAT_TERM] [nvarchar](1070) NULL,
	[UF_STAT_FIRST_PAGE] [nvarchar](2032) NULL,
	[UF_STAT_INT_PAGE] [nvarchar](1268) NULL,
	[UF_CLT_NAME_FIRST] [nvarchar](36) NULL,
	[UF_CLT_BIRTH_DAY] [date] NULL,
	[UF_CLT_EMAIL] [nvarchar](60) NULL,
	[UF_CLT_AVG_INCOME] [int] NULL,
	[UF_CAR_COST_RUB] [int] NULL,
	[UF_CAR_ISSUE_YEAR] [float] NULL,
	[UF_STAT_AD_TYPE] [varchar](128) NULL,
	[UF_STAT_SOURCE] [varchar](128) NULL,
	[UF_FROM_SITE] [int] NULL,
	[UF_VIEWED] [int] NULL,
	[UF_PARTNER_ID] [nvarchar](128) NULL,
	[UF_SUM_ACCEPTED] [float] NULL,
	[UF_SUM_LOAN] [float] NULL,
	[UF_REGIONS_COMPOSITE] [nvarchar](128) NULL,
	[UF_ISSUED_AT] [datetime2](7) NULL,
	[UF_TARGET] [int] NULL,
	[UF_FULL_FORM_LEAD] [int] NULL,
	[UF_STEP] [int] NULL,
	[UF_SOURCE_SHADOW] [nvarchar](128) NULL,
	[UF_TYPE_SHADOW] [nvarchar](128) NULL,
	[UF_CLB_TYPE] [nvarchar](128) NULL
)


DECLARE @start_id numeric(10, 0), @depth_id numeric(10, 0)
DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)


DROP TABLE IF EXISTS #ID_List
CREATE TABLE #ID_List(ID numeric(10, 0))

--название таблицы со списком ID
SELECT @ID_Table_Name = '#ID_List'
--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message
*/

--Извлечь лиды по дате лида

/*


DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
	[UF_UPDATED_AT] [datetime2](7) NULL,
	[UF_ROW_ID] [varchar](128) NULL,
	[UF_NAME] [varchar](512) NULL,
	[UF_AGENT_NAME] [varchar](128) NULL,
	[UF_STAT_CAMPAIGN] [varchar](512) NULL,
	[UF_STAT_CLIENT_ID_YA] [varchar](128) NULL,
	[UF_STAT_CLIENT_ID_GA] [varchar](128) NULL,
	[UF_TYPE] [varchar](128) NULL,
	[UF_SOURCE] [varchar](128) NULL,
	[UF_ACTUALIZE_AT] [datetime2](7) NULL,
	[UF_CAR_MARK] [varchar](128) NULL,
	[UF_CAR_MODEL] [varchar](128) NULL,
	[UF_PHONE_ADD] [varchar](128) NULL,
	[UF_PARENT_ID] [int] NULL,
	[UF_GROUP_ID] [varchar](128) NULL,
	[UF_PRIORITY] [int] NULL,
	[UF_RC_REJECT_CM] [varchar](512) NULL,
	[UF_APPMECA_TRACKER] [varchar](128) NULL,
	[UF_LOGINOM_CHANNEL] [varchar](128) NULL,
	[UF_LOGINOM_GROUP] [varchar](128) NULL,
	[UF_LOGINOM_PRIORITY] [int] NULL,
	[UF_LOGINOM_STATUS] [varchar](128) NULL,
	[UF_LOGINOM_DECLINE] [varchar](128) NULL,
	[Канал от источника] [nvarchar](255) NULL,
	[Группа каналов] [nvarchar](255) NULL,
	[UF_CLID] [nvarchar](72) NULL,
	[UF_MATCH_ALGORITHM] [nvarchar](26) NULL,
	[UF_CLB_CHANNEL] [nvarchar](50) NULL,
	[UF_LOAN_MONTH_COUNT] [int] NULL,
	[UF_STAT_SYSTEM] [nvarchar](16) NULL,
	[UF_STAT_DETAIL_INFO] [nvarchar](1236) NULL,
	[UF_STAT_TERM] [nvarchar](1070) NULL,
	[UF_STAT_FIRST_PAGE] [nvarchar](2032) NULL,
	[UF_STAT_INT_PAGE] [nvarchar](1268) NULL,
	[UF_CLT_NAME_FIRST] [nvarchar](36) NULL,
	[UF_CLT_BIRTH_DAY] [date] NULL,
	[UF_CLT_EMAIL] [nvarchar](60) NULL,
	[UF_CLT_AVG_INCOME] [int] NULL,
	[UF_CAR_COST_RUB] [int] NULL,
	[UF_CAR_ISSUE_YEAR] [float] NULL,
	[UF_STAT_AD_TYPE] [varchar](128) NULL,
	[UF_STAT_SOURCE] [varchar](128) NULL,
	[UF_FROM_SITE] [int] NULL,
	[UF_VIEWED] [int] NULL,
	[UF_PARTNER_ID] [nvarchar](128) NULL,
	[UF_SUM_ACCEPTED] [float] NULL,
	[UF_SUM_LOAN] [float] NULL,
	[UF_REGIONS_COMPOSITE] [nvarchar](128) NULL,
	[UF_ISSUED_AT] [datetime2](7) NULL,
	[UF_TARGET] [int] NULL,
	[UF_FULL_FORM_LEAD] [int] NULL,
	[UF_STEP] [int] NULL,
	[UF_SOURCE_SHADOW] [nvarchar](128) NULL,
	[UF_TYPE_SHADOW] [nvarchar](128) NULL,
	[UF_CLB_TYPE] [nvarchar](128) NULL
)

-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = '2022-02-01', @End_Registered = '2022-02-01'


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message


*/


--проверка наступления события
--use Analytics
--
--go
--
--while 1 =1
--
--begin
--
--if (select count(*) from Feodor.dbo.dm_leads_history_monitoring where  dm_leads_history_monitoring.start_creating_lh>'20220504 14:03:00' )>0
--begin
--exec log_email 'ok', 'p.ilin@techmoney.ru'
--select 1/0
--end
--
--
--waitfor delay '00:00:10'
--RAISERROR('1',0,0) WITH NOWAIT
--select 1
--
--
--end



end