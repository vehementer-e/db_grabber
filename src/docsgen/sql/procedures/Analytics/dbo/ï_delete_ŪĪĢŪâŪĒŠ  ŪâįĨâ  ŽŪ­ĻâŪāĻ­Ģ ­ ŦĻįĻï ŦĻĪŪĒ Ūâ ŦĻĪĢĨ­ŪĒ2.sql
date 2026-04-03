
CREATE     proc [dbo].[Подготовка отчета мониторинг наличия лидов от лидгенов2]
as
begin

set datefirst 1



--DROP TABLE IF EXISTS #TMP_leads
--CREATE TABLE #TMP_leads
--(
--	[ID] numeric(10,0),
--	[UF_REGISTERED_AT] [datetime2] NULL,
--	[UF_REGISTERED_AT_date] [date] NULL,
--	[UF_SOURCE] [NVARCHAR](255),
--	[UF_PARTNER_ID] [NVARCHAR](255),
--	[UF_TYPE] [NVARCHAR](255),
--	[Группа каналов] [nvarchar](255) NULL,
--	[Канал от источника] [nvarchar](255) NULL,
--	[UF_APPMECA_TRACKER] [varchar](128) NULL,
--	[UF_LOGINOM_STATUS] [NVARCHAR](255)
--)
--
---- 
--DECLARE @Return_Table_Name varchar(100)
--DECLARE @Return_Number int, @Return_Message varchar(1000)
--DECLARE	@Begin_Registered date, @End_Registered date
--
--declare @report_d date = getdate()-1
--declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
--declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end
--
--
----название таблицы, которая будет заполнена
--SELECT @Return_Table_Name = '#TMP_leads'
--SELECT @Begin_Registered = @last_month_start, @End_Registered = @report_d
--
--
--EXEC Stg._LCRM.get_leads
--	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
--	@Begin_Registered = @Begin_Registered, -- начальная дата
--	@End_Registered = @End_Registered, -- конечная дата
--	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
--	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
--	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение
--


declare @report_d date = getdate()-1
declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

--declare @report_d date = getdate()-1
--declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
--declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end

select id, uf_source uf_source
, [UF_APPMECA_TRACKER]  [UF_APPMECA_TRACKER]
, [Группа каналов]  [Группа каналов]
, UF_PARTNER_ID  UF_PARTNER_ID
, [UF_REGISTERED_AT_date]  [UF_REGISTERED_AT_date]
, UF_LOGINOM_STATUS  UF_LOGINOM_STATUS
, [Канал от источника]  [Канал от источника]
, UF_TYPE  UF_TYPE
into #TMP_leads from dbo.dm_lcrm_leads_for_report where
[UF_REGISTERED_AT_date]>=@last_month_start


--select  dateadd(day, -31, @report_d)
--select  dateadd(day, -8, @report_d)
--select  dateadd(day, -1, @report_d)
--;

drop table if exists #t
select *, dbo.lcrm_source_of_cpa_trafic_mp([UF_APPMECA_TRACKER]) [Трафик в МП источник] into #t
from #TMP_leads

/*
declare @report_d date = getdate()-1
declare @last_month_start date = dateadd(month, -1, cast(format(@report_d, 'yyyy-MM-01') as date))
declare @report_d_work_day int = case when datepart(dw, @report_d) <=5 then 1 else 0 end
set datefirst 1
*/


drop table if exists #t1
drop table if exists #agr
--select datepart(dw, @report_d)
;

with  

leads as (
          select 1 as order_num,  type = 'Источник (> 1 з. 30д.)' , gr = UF_SOURCE , *  from #t  a            where      UF_SOURCE <>''
union all select 2 as order_num,  type = 'Вебмастер (> 1 з. 30д.)' , gr = UF_SOURCE+' - '+UF_PARTNER_ID, * from #t  a  where isnull(UF_SOURCE, '')  <>'' and isnull(UF_PARTNER_ID, '')  <>''
union all select 3 as order_num,  type = 'Партнерские лиды по лендингами' , gr = 'Партнерские лиды'+' - '+UF_TYPE, * from #t  a  where [Канал от источника]='Партнерские лиды'
union all select 4 as order_num,  type = 'Партнерские лиды итого' , gr = '', * from #t  a  where [Канал от источника]='Партнерские лиды'
union all select 5 as order_num,  type = 'CPC итого' , gr = 'CPC итого', * from #t  a  where [Группа каналов]='CPC'
union all select 6 as order_num,  type = 'CPC' , gr = [Канал от источника] , * from #t  a  where [Группа каналов]='CPC'
union all select 7 as order_num,  type = 'Трафик в МП источник' , gr = [Трафик в МП источник] , * from #t  a  where  [Трафик в МП источник] is not null


)
,  tmp_leads as (

select *
, [type_group] = 'all (accepted + declined)'
--, case when isnull(UF_LOGINOM_STATUS, '') <> 'declined' then 1 else 0 end as [Признак одобренный лид]
, case when datepart(dw, [UF_REGISTERED_AT_date]) <=5 then 1 else 0 end lead_work_day
from leads a 
union all
select *
, [type_group] = 'accepted'
--, case when isnull(UF_LOGINOM_STATUS, '') <> 'declined' then 1 else 0 end as [Признак одобренный лид]
, case when datepart(dw, [UF_REGISTERED_AT_date]) <=5 then 1 else 0 end lead_work_day
from leads a 
where isnull(UF_LOGINOM_STATUS, '') = 'accepted'
)

select 
b.type ,
b.gr,
b.order_num,
b.[type_group],
b.[UF_REGISTERED_AT_date],
cast(sum(case when 1=1 then 1 end)                     as float) [Лидов],
cast(sum(case when 1=1 and lead_work_day=1 then 1 end) as float) [Лидов рабочие дни], 
cast(sum(case when 1=1 and lead_work_day=0 then 1 end) as float) [Лидов выходные]
into #agr
from tmp_leads b
group by
b.type ,
b.gr,
b.order_num,
b.[type_group],
b.[UF_REGISTERED_AT_date]

;

with
tmp_leads_sum as (
select 
a.type ,
a.gr,
a.order_num,
t.[type_group],
c.Дата [UF_REGISTERED_AT_date],
isnull([Лидов]               , 0) [Лидов],
isnull([Лидов рабочие дни]   , 0) [Лидов рабочие дни],
isnull([Лидов выходные]      , 0) [Лидов выходные]
from 
(select distinct 
type ,
gr,
order_num
from 
#agr ) a
cross join (select distinct [type_group]  from 
#agr ) t
join v_Calendar c on c.Дата between @last_month_start and @report_d
left join #agr b on a.gr=b.gr and a.order_num=b.order_num and a.type=b.type and t.type_group=b.type_group and b.UF_REGISTERED_AT_date=c.Дата
)

, v as (
select gr
, type
, order_num
, [type_group]
, isnull(avg(case when  [UF_REGISTERED_AT_date] between @last_month_start and dateadd(day, -1, @report_d) then [Лидов рабочие дни] end), null) [Лидов будние среднее с начала прошлого месяца] 
, isnull(avg(case when  [UF_REGISTERED_AT_date] between @last_month_start and dateadd(day, -1, @report_d) then [Лидов выходные] end)   , null) [Лидов выходные среднее с начала прошлого месяца] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -30, @report_d) and dateadd(day, -1, @report_d) then [Лидов] end) , 0) [Лидов 30 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] between dateadd(day, -7, @report_d) and dateadd(day, -1, @report_d)  then [Лидов] end) , 0) [Лидов 7 дней] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -1 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-1] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -2 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-2] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -3 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-3] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -4 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-4] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -5 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-5] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -6 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-6] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = dateadd(day, -7 ,@report_d  ) then [Лидов] end)                                      , 0) [Лидов t-7] 
, isnull(sum(case when  [UF_REGISTERED_AT_date] = @report_d  then [Лидов] end)                                                         , 0) [Лидов вчера] 

from tmp_leads_sum a

group by gr
, type
, order_num
, [type_group]
)

select *
, 
case 
when @report_d_work_day=1 then ([Лидов вчера]-[Лидов будние среднее с начала прошлого месяца])/  nullif([Лидов будние среднее с начала прошлого месяца]  , 0) --else 
when @report_d_work_day=0 then ([Лидов вчера]-[Лидов выходные среднее с начала прошлого месяца])/nullif([Лидов выходные среднее с начала прошлого месяца], 0) --else 
end
[Дельта %]
, @report_d_work_day [Признак рабочий день]
, case when @report_d_work_day = 1 then [Лидов будние среднее с начала прошлого месяца] else [Лидов выходные среднее с начала прошлого месяца] end [Лидов будние/выходные среднее с начала прошлого месяца]
into #t1 
from v 
--where [Лидов accepted 30 дней]>100
order by [Лидов 30 дней] desc

drop table if exists #stat
select Источник, Вебмастер, [Заем выдан] into #stat from reports.dbo.dm_Factor_Analysis_001
where [Заем выдан] >=cast(getdate()-30 as date)

drop table if exists #f

select a.*
, getdate() as created
,x.cnt0 
,x1.cnt1

into #f 
from #t1 a
cross apply (select count(*)  cnt0
from   
#stat b where 
b.Источник  = a.gr 
and a.type='Источник (> 1 з. 30д.)'
) x
cross apply (select count(*)  cnt1
from   
#stat b where 
b.Источник+' - '+b.Вебмастер  = a.gr 
and a.type= 'Вебмастер (> 1 з. 30д.)'
) x1
--order by [Лидов accepted 30 дней] desc

if (select count(*) from #f)=0
begin

exec log_email 'Мониторинг наличия лидов от лидгенов - нет записей в таблице для вставки'
select 1/0

end

begin tran
--drop table if exists dbo.[Отчет мониторинг наличия лидов от лидгенов2]
--select * into dbo.[Отчет мониторинг наличия лидов от лидгенов2]
--from #f
--where 
--case
--when type = 'Вебмастер' then case when cnt1>0 then 1 else 0 end 
--when type = 'Источник' then case when cnt0>0 then 1 else 0 end 
--else 1 end =1
--order by order_num, type_group, [Лидов 30 дней] desc
delete from dbo.[Отчет мониторинг наличия лидов от лидгенов2]
insert into  dbo.[Отчет мониторинг наличия лидов от лидгенов2]
select *  
from #f
 where 
 case
 when type = 'Вебмастер (> 1 з. 30д.)' then case when cnt1>1  and [Лидов будние/выходные среднее с начала прошлого месяца]>40 then 1 else 0 end 
 when type = 'Источник (> 1 з. 30д.)' then case when cnt0>1   and [Лидов будние/выходные среднее с начала прошлого месяца]>40 then 1 else 0 end 
 when type = 'Трафик в МП источник' and type_group='accepted' then 0 
 else 1 end =1
 and ([Дельта %]<=0 or [Дельта %] is null)

order by order_num, type_group, [Лидов 30 дней] desc

commit tran
--select * from Analytics.dbo.[Отчет мониторинг наличия лидов от лидгенов2]
--order by 2, 1

--drop table if exists dbo.[Отчет мониторинг поступления лидов статус]
--select getdate()dt into  dbo.[Отчет мониторинг поступления лидов статус]
--select * into dbo.[Отчет мониторинг наличия лидов от лидгенов2]

	
if cast(getdate() as time) < '09:59'
WAITFOR TIME '09:59';   

exec exec_python 'send_report_leads_monitoring()', 1

--if cast(getdate() as time) < '10:00'
--	WAITFOR TIME '10:00';  
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'D775BEE3-C836-4B8C-BD65-CC0E38FAFD2F'
end