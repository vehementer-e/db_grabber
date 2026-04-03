
CREATE PROCEDURE [dbo].[Лиды для отчетов] AS

begin

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	UF_CLID  [VARCHAR](72),
	id numeric(10,0),
	UF_MATCH_ALGORITHM [VARCHAR](26),
	UF_TYPE [VARCHAR](128),
	UF_SOURCE [VARCHAR](128),
	UF_CLB_CHANNEL [VARCHAR](50),
	UF_CLB_TYPE [VARCHAR](128),
	UF_PHONE [VARCHAR](128),
	UF_LOGINOM_STATUS [VARCHAR](128),
	UF_LOGINOM_CHANNEL [VARCHAR](128),
	UF_LOGINOM_GROUP [VARCHAR](128),
	UF_LOGINOM_DECLINE [VARCHAR](128),
	UF_LOGINOM_PRIORITY [int],
	UF_LOAN_MONTH_COUNT [int],
	UF_SUM_ACCEPTED [float],
	UF_SUM_LOAN [float],
	UF_TARGET [int],
	UF_FULL_FORM_LEAD [int],
	UF_FROM_SITE [int],
	UF_STAT_SYSTEM [VARCHAR](16),
	UF_STAT_SOURCE [VARCHAR](128),
	UF_STAT_AD_TYPE [VARCHAR](128),
	UF_STAT_CAMPAIGN [VARCHAR](512),
	UF_STAT_DETAIL_INFO [VARCHAR](1236),
	UF_STAT_TERM [VARCHAR](1070),
	UF_STAT_FIRST_PAGE [VARCHAR](2032),
	UF_STAT_INT_PAGE [VARCHAR](1268),
	UF_REGIONS_COMPOSITE [VARCHAR](128),
	UF_CLT_NAME_FIRST [VARCHAR](128),
	UF_CLT_BIRTH_DAY [date],
	UF_CLT_EMAIL [VARCHAR](60),
	UF_CLT_AVG_INCOME [int],
	UF_CAR_COST_RUB [int],
	UF_CAR_ISSUE_YEAR [float],
	UF_CAR_MARK [VARCHAR](128),
	UF_CAR_MODEL [VARCHAR](128),
	UF_RC_REJECT_CM [VARCHAR](512),
	uf_registered_at [datetime2],
	uf_row_id [VARCHAR](128)
)


DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = dateadd(m,-12,cast(getdate() as date))
, @End_Registered = cast(getdate() as date)

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение


begin tran


truncate table Analytics.[dbo].[Лиды_отчеты]
insert into Analytics.[dbo].[Лиды_отчеты]
select * 
from #TMP_leads
commit tran

exec log_email 'insert into Analytics.[dbo].[Лиды_отчеты] Выполнен' , 'p.ilin@techmoney.ru; a.danicheva@techmoney.ru'

end