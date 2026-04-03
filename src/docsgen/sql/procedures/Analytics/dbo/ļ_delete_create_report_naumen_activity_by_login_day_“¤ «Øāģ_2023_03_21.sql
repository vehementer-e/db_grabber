CREATE   PROC dbo.create_report_naumen_activity_by_login_day_Удалить_2023_03_21
as
begin


declare @t datetime = getdate()
declare @start_date date = '20210601'
if datepart(day, getdate())>1
set @start_date = getdate()-2

  drop table if exists #v_
;

with v as (

	SELECT cl.session_id AS SESSION_ID,
 
    sess.case_uuid AS PARENTUUID,
    cl.src_abonent AS LOGIN,
    cl.created AS CREATED,
    'out' AS DIRECTION
   FROM naumendbreport.dbo.call_legs cl
     LEFT JOIN naumendbreport.dbo.detail_outbound_sessions sess ON sess.session_id = cl.session_id
  WHERE cl.src_abonent_type = 'SP' AND cl.intrusion = 0
UNION ALL
 SELECT cl.session_id AS SESSION_ID,
     sess.case_uuid AS PARENTUUID,
    cl.dst_abonent AS LOGIN,
    cl.created AS CREATED,
    'in'  AS DIRECTION
   FROM naumendbreport.dbo.call_legs cl
     LEFT JOIN naumendbreport.dbo.queued_calls p ON p.session_id = cl.session_id AND cl.created >= p.unblocked_time AND cl.created <= p.dequeued_time
     LEFT JOIN naumendbreport.dbo.detail_outbound_sessions sess ON sess.session_id = cl.session_id

  WHERE cl.dst_abonent_type = 'SP' AND cl.intrusion = 0
  )

  , 
  V_
  AS(
select
    op.DIRECTION as DIRECTION,
    op.CREATED as CREATED,                                                                                                                                                                          
    op.SESSION_ID as  SESSION_ID,
    case_.UUID as  UUID,
    emp.login as  login,
	case when isnull(pc.calldispositiontitle, '') not in 
    ('Несуществующий номер (CTI)'
	,'Нет ответа (CTI)'
	,'Отклонен/сброс (CTI)'
	,'Ошибка (CTI)'
	,'Потерянный вызов (CTI)'
	,'Занято (CTI)'
	) then 1 else 0 end successful
 
from
    V op with(nolock)
    join [NaumenDbReport].dbo.mv_employee emp with(nolock)  on (emp.login = op.LOGIN COLLATE Latin1_General_100_CS_AS)
    left outer join [NaumenDbReport].dbo.mv_call_case case_ with(nolock) on (case_.uuid = op.PARENTUUID )  
    left outer join [NaumenDbReport].dbo.mv_phone_call pc with(nolock) on pc.sessionid=op.SESSION_ID

)

select * into #v_ from V_
where  CREATED>=@start_date
;with v  as (select *, row_number() over(partition by created, LOGIN COLLATE Latin1_General_100_CS_AS order by successful desc) rn from #v_ ) delete from v where rn>1



drop table if exists #pc_by_login_day
select 
	   login = pc.login                                                         
--,      creationdate_h = cast(format(pc.creationdate, 'yyyy-MM-dd HH:00:00') as datetime) 
,      creationdate_d = cast(pc.CREATED as date) 
,      [Звонков совершено] = count(*)                                                          
,      [Кейсов Обработано] = count(distinct pc.UUID)            
into #pc_by_login_day
from      #v_                  pc 
where  CREATED>=@start_date and successful=1
group by pc.login,  cast(pc.CREATED as date)  



drop table if exists #sc
--declare @start_date date = '20210601'

select 

ENTERED_d ENTERED_d,
LOGIN LOGIN,
status status,
DURATION DURATION

into #sc
from 

(
select cast(ENTERED as date) ENTERED_d
,LOGIN
,status

,sum(DURATION )  DURATION
from
 NaumenDbReport.dbo.status_changes
where entered>=@start_date and CHARINDEX('#', status)=0 and STATUS not in ('offline', 'notavailable'  )
group by cast(ENTERED as date) , LOGIN, status
 
) x


									
  drop table if exists #status_changes_by_login_day ;


select ENTERED_d
, LOGIN
, isnull(sum(CASE WHEN status= 'away' THEN DURATION end     )/(24*60.0*60.0), 0)    Перерыв
, isnull(sum(CASE WHEN status= 'normal' THEN DURATION end   )/(24*60.0*60.0), 0)	Готов
, isnull(sum(CASE WHEN status= 'wrapup' THEN DURATION end   )/(24*60.0*60.0), 0)	Постобработка
, isnull(sum(CASE WHEN status= 'speaking' THEN DURATION end )/(24*60.0*60.0), 0)	[Время диалога]
, isnull(sum(CASE WHEN status= 'online' THEN DURATION end   )/(24*60.0*60.0), 0)	[В сети]
, isnull(sum(CASE WHEN status= 'ringing' THEN DURATION end  )/(24*60.0*60.0), 0)	[Звонит]
, isnull(sum(CASE WHEN status= 'online' THEN DURATION end   )/(24*60.0*60.0), 0)	    [Онлайн]
, isnull(sum(DURATION                                       )/(24*60.0*60.0), 0)    [Всего]
into #status_changes_by_login_day

from #sc a 
group by ENTERED_d, LOGIN

--select * from #sc

drop table if exists #final

select 

groups.d,
groups.LOGIN
,isnull(e.title,groups.LOGIN ) title


,st.Перерыв
,st.Готов
,st.Постобработка
,st.[Время диалога]
,st.[В сети]
,st.[Звонит]
,st.Онлайн
,st.[Всего]

,pc.[Звонков совершено]
,pc.[Кейсов Обработано]
,getdate() as created




into #final
from 
(
select distinct ENTERED_d d, LOGIN from #status_changes_by_login_day union
select distinct creationdate_d d, LOGIN from #pc_by_login_day --union
) 
groups 
left join NaumenDbReport.dbo.mv_employee e on e.login=groups.LOGIN COLLATE Latin1_General_100_CS_AS

left join #status_changes_by_login_day  st on st.ENTERED_d=groups.d and st.LOGIN=groups.login COLLATE Latin1_General_100_CS_AS
left join #pc_by_login_day              pc on pc.creationdate_d=groups.d and pc.LOGIN=groups.login COLLATE Latin1_General_100_CS_AS

--   RAISERROR('ШАГ 5 ок',0,0) WITH NOWAIT



if  OBJECT_ID('analytics.dbo.report_naumen_activity_by_login_day') is  null
begin


CREATE TABLE Analytics.dbo.report_naumen_activity_by_login_day(
	[d] [date] NULL,
	[LOGIN] [nvarchar](256) NULL,
	[title] [nvarchar](4000) NULL,
	[Перерыв] [numeric](32, 11) NULL,
	[Готов] [numeric](32, 11) NULL,
	[Постобработка] [numeric](32, 11) NULL,
	[Время диалога] [numeric](32, 11) NULL,
	[В сети] [numeric](32, 11) NULL,
	[Звонит] [numeric](32, 11) NULL,
	Онлайн [numeric](32, 11) NULL,
	[Всего] [numeric](32, 11) NULL,
	[Звонков совершено] [int] NULL,
	[Кейсов Обработано] [int] NULL,
	[created] [datetime] NOT NULL
) 

end



begin tran
delete from Analytics.dbo.report_naumen_activity_by_login_day where d>=@start_date
insert into Analytics.dbo.report_naumen_activity_by_login_day
select *  from #final
delete from Analytics.dbo.report_naumen_activity_by_login_day where d>=cast(getdate() as date)


commit tran

--drop table if exists #final
--
--declare @sql nvarchar(max) = N'exec [dbo].[Подготовка Отчет по тематикам]'
--EXEC  (@sql)
--
-- 
--
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'AD256032-749B-4828-8F4C-E82C512A2C5E'


end
