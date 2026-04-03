
CREATE   proc [dbo].[Подготовка отчета мониторинг наличия лидов от лидгенов]
as
begin

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] numeric(10,0),
	[UF_REGISTERED_AT] [datetime2] NULL,
	[UF_REGISTERED_AT_date] [date] NULL,
	[UF_SOURCE] [NVARCHAR](255),
	[UF_LOGINOM_STATUS] [NVARCHAR](255)
)

-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

declare @report_d date = getdate()-1
declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end


--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = @last_month_start, @End_Registered = @report_d


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение



--declare @report_d date = getdate()-1
--declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
--declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

set datefirst 1
--select  dateadd(day, -31, @report_d)
--select  dateadd(day, -8, @report_d)
--select  dateadd(day, -1, @report_d)
--;

drop table if exists #t1
--select datepart(dw, @report_d)
;

with tmp_leads as (

select *
, case when isnull(UF_LOGINOM_STATUS, '') <> 'declined' then 1 else 0 end as [Признак одобренный лид]
, case when datepart(dw, [UF_REGISTERED_AT_date]) <=5 then 1 else 0 end lead_work_day
from #TMP_leads a

),
tmp_leads_sum as (
select 
uf_source,
[UF_REGISTERED_AT_date],
cast(sum(case when [Признак одобренный лид]=1 then 1 end)                     as float) [Лидов accepted],
cast(sum(case when [Признак одобренный лид]=1 and lead_work_day=1 then 1 end) as float) [Лидов accepted рабочие дни],
cast(sum(case when [Признак одобренный лид]=1 and lead_work_day=0 then 1 end) as float) [Лидов accepted выходные]
from tmp_leads
group by uf_source,
[UF_REGISTERED_AT_date]
)

, v as (
select uf_source
, isnull(avg(case when  [UF_REGISTERED_AT_date] between @last_month_start and dateadd(day, -1, @report_d) then [Лидов accepted рабочие дни] end), null) [Лидов accepted будние среднее с начала прошлого месяца] 
, isnull(avg(case when  [UF_REGISTERED_AT_date] between @last_month_start and dateadd(day, -1, @report_d) then [Лидов accepted выходные] end)   , null) [Лидов accepted выходные среднее с начала прошлого месяца] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then [Лидов accepted] end) , 0) [Лидов accepted 30 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -7, @report_d) and dateadd(day, -1, @report_d)  then [Лидов accepted] end) , 0) [Лидов accepted 7 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -1 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-1] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -2 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-2] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -3 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-3] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -4 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-4] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -5 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-5] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -6 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-6] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -7 ,@report_d  ) then [Лидов accepted] end)                                      , 0) [Лидов accepted t-7] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d  then [Лидов accepted] end)                                                         , 0) [Лидов accepted вчера] 

from tmp_leads_sum a

group by uf_source
)

select *
, 
case 
when @report_d_work_day=1 then ([Лидов accepted вчера]-[Лидов accepted будние среднее с начала прошлого месяца])/  [Лидов accepted будние среднее с начала прошлого месяца] --else 
when @report_d_work_day=0 then ([Лидов accepted вчера]-[Лидов accepted выходные среднее с начала прошлого месяца])/[Лидов accepted выходные среднее с начала прошлого месяца] --else 
end
[Дельта %]
, @report_d_work_day [Признак рабочий день]
, case when @report_d_work_day = 1 then [Лидов accepted будние среднее с начала прошлого месяца] else [Лидов accepted выходные среднее с начала прошлого месяца] end [Лидов accepted будние/выходные среднее с начала прошлого месяца]
into #t1 
from v 
where [Лидов accepted 30 дней]>100
order by [Лидов accepted 30 дней] desc

drop table if exists #f

select *, getdate() as created into #f 
from #t1 a cross apply (select top 1 1 d from   stg.[files].[leadref2_buffer_stg] b where b.[Тип-Источник] like '%'+a.UF_SOURCE  and [Канал от источника] like '%cpa%') x
where a.UF_SOURCE not in ('', ' ')
order by [Лидов accepted 30 дней] desc

select * from #f

begin tran
--drop table if exists dbo.[Отчет мониторинг наличия лидов от лидгенов]
--select * into dbo.[Отчет мониторинг наличия лидов от лидгенов]
--from #f
delete from dbo.[Отчет мониторинг наличия лидов от лидгенов]
insert into  dbo.[Отчет мониторинг наличия лидов от лидгенов]
select * from #f

commit tran
--select * from Analytics.dbo.[Отчет мониторинг наличия лидов от лидгенов]



if cast(getdate() as time) < '10:00'
	WAITFOR TIME '10:00';  
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'D775BEE3-C836-4B8C-BD65-CC0E38FAFD2F'
end