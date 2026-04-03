CREATE   proc [dbo].[create_report_naumen_lines2]
as
begin

--declare @start_date date = getdate()-5
--declare @end_date date = getdate()-1
declare @start_date date = '20210701'
declare @end_date date = getdate()-1
--declare @sql nvarchar(max)


drop table if exists #lines
create table #lines
(line nvarchar(10), line_name  nvarchar(100))
insert into #lines   select ('6001'), ('Продажи')
insert into #lines   select ('6002'), ('Сервис')
insert into #lines   select ('6003'), ('Дистанс')

drop table if exists #call_legs
CREATE TABLE #call_legs (
	session_id nvarchar(64),
	leg_id int,
	src_abonent nvarchar(100),
	created datetime2(7),
	ended datetime2(7),
	dst_id nvarchar(200),
	src_id nvarchar(200))
insert into #call_legs
select session_id
,      leg_id
,      src_abonent
,      created
,      ended
,      dst_id
,      src_id --into #call_legs
from NaumenDbReport.dbo.call_legs
where cast(created as date) between @start_date and @end_date


drop table if exists #call_params_QoS
select 
  session_id  = session_id
, param_value = try_cast(param_value as int)
, param_name  = param_name
into #call_params_QoS from 
(
select * from [NaumenDbReport].[dbo].[call_params_QoS]
where param_value not in ('Нет нажатия', 'Положили трубку')
) qos

;
with v as (select distinct session_id from #call_legs cl join #lines on #lines.line=cl.dst_id)
delete  a from #call_legs a left join v on v.session_id=a.session_id
where v.session_id is null

create clustered index clus_indname on #call_legs
(
session_id, leg_id
)

drop table if exists #cl
drop table if exists #cl_

select session_id					= session_id
,      leg_id						= leg_id
,      src_abonent					= src_abonent
,      created						= created
,      ended						= ended
,      dst_id						= dst_id
,      src_id                       = src_id
,      line                         = #lines.line
,      line_name                    = #lines.line_name
,      [Признак перевод на линию]   = case when #lines.line is not null  then 1 else 0 end                                              
,      [Признак звонок от клиента]  = case when src_abonent is null  then 1 else 0 end                                                  
,      [Время разговора]            = sum(case when leg_id=1 then datediff(second,created , ended ) end) over (partition by session_id) 
,      [Дата начала диалога]        = min(created) over (partition by session_id)                                                       
,      [rn]                         = ROW_NUMBER() over(partition by session_id order by leg_id)                                        
into #cl_
from #call_legs cl
left join #lines on #lines.line=cl.dst_id
;

with v as (
select * 
, [Телефон клиента]            = max(case when [Признак звонок от клиента]=1 then src_id end)  over(partition by session_id)   
, [Входящий звонок от клиента] = case when rn=1 and [Признак звонок от клиента]=1 then 1 else 0 end  
, [rn by session_id, line]     = case when [Признак перевод на линию]=1 then ROW_NUMBER() over (partition by session_id, [Признак перевод на линию] order by leg_id desc) end   
from #cl_ cl
)

select cl.*
into #cl from v cl
join (select session_id  from v where  [Входящий звонок от клиента]=1) x1 on cl.session_id=x1.session_id
order by cl.session_id, leg_id, created

--select * from #cl
--order by session_id, leg_id

drop table if exists #logins_by_calls
select x.*, ROW_NUMBER() over(partition by session_id, line order by leg_id) rn into #logins_by_calls
from (
select line, session_id,  leg_id, lead(dst_id) over(partition by session_id order by leg_id) [login]  from #cl a 
--where line is not null
) x
join NaumenDbReport.dbo.mv_employee e on e.login=x.[login] COLLATE Latin1_General_100_CS_AS  
where line is not null

delete from #logins_by_calls where rn>1

--set datefirst 1 
--DATEADD(wk, DATEDIFF(wk,0,_______), 0)
drop table if exists #final
select session_id                   = a.session_id                                                                    
,      [Дата звонка]                = min(created)
,      [Дата звонка день]           = cast(min(created)      as date)
,      [Дата звонка месяц]          = cast(format(min(created), 'yyyy-MM-01') as date)  
,      [Дата звонка неделя]         = cast(DATEADD(wk, DATEDIFF(wk,0,min(created)  ), 0) as date) 

,      [Время разговора]            = max([Время разговора])
,      [Телефон клиента]            = max(Analytics.dbo.validate_mobile_number([Телефон клиента], default))
,      line                         = max(case when [rn by session_id, line]=1 then a.line end) 
,      line_name                    = max(case when [rn by session_id, line]=1 then line_name end) 
,      line_6001                    = max(case when a.line='6001' then a.line end) 
,      line_6001_login              = max(case when a.line='6001' then lbc_6001.login end) 
,      line_6002                    = max(case when a.line='6002' then a.line end) 
,      line_6002_login              = max(case when a.line='6002' then lbc_6002.login end) 
,      line_6003                    = max(case when a.line='6003' then a.line end) 
,      line_6003_login              = max(case when a.line='6003' then lbc_6003.login end) 
,      [Клиент дождался соединения] = case when max(z.Ссылка) is not null then 1 else 0 end
,      [Ссылка звонок]              = max(z.Ссылка) 
,      [Ссылка взаимодействие]      = max(z.ВзаимодействиеОснование_Ссылка) 
,      [Тематика]                   = max(t.Наименование)                                                                                                    
,      [Подтематика]                = max(ISNULL(IIF(t.Наименование='Консультирование по продукту Выдача займа',v.Результат,d.Наименование),t.Наименование)) 
,      [Оценка звонка]              = max(qos.param_value) 


into #final
from #cl a
left join 
(
select z.Session_id                                                              
,      ВзаимодействиеОснование_Ссылка                                          
,      Ссылка                                          
,      ROW_NUMBER() over(partition by z.Session_id order by ВзаимодействиеОснование_Ссылка desc) rn
from Analytics.[dbo].[v_Документ_ТелефонныйЗвонок] z
) z          on a.session_id = z.Session_id and z.rn=1
left join #logins_by_calls lbc_6001 on lbc_6001.session_id=a.session_id and a.line=lbc_6001.line
left join #logins_by_calls lbc_6002 on lbc_6002.session_id=a.session_id and a.line=lbc_6002.line
left join #logins_by_calls lbc_6003 on lbc_6003.session_id=a.session_id and a.line=lbc_6003.line
left join Stg.[_1cCRM].[Документ_CRM_Взаимодействие]    v  (nolock)  on v.Ссылка     = z.ВзаимодействиеОснование_Ссылка
left join Stg.[_1cCRM].[Справочник_ДеталиОбращений]     d  (nolock)  on d.Ссылка     = v.ДеталиОбращения
left join Stg.[_1cCRM].[Справочник_ТемыОбращений]       t  (nolock)  on t.Ссылка     = v.ТемаСсылка
left join #call_params_QoS       qos  (nolock)  on qos.session_id=a.session_id
group by a.session_id
--order by  2

--select * from #final
--where [Клиент дождался соединения]=1
--select * from #cl
--where session_id='node_0_domain_0_nauss_0_1629126106_172352'
drop table if exists #loans
select  Analytics.dbo.validate_mobile_number([Телефон договор CMR], default) [Телефон договор CMR], [Дата выдачи]  [Дата выдачи], [Дата погашения] , CRMClientGUID into #loans from Analytics.dbo.report_loans


--select * from #loans

drop table if exists #final_for_ins

select 
session_id              
,[Дата звонка]           
,[Дата звонка день]           
,[Дата звонка месяц]
,[Дата звонка неделя]
,null  [Месяц текст]
,null  [Неделя текст]
,[Дата повторного обращения на линию]           
,[Время разговора]       
,datediff(second, [Дата звонка], case when count(*) over(partition by [Дата звонка день], [Телефон клиента], line) >1 and ROW_NUMBER() over(partition by [Дата звонка день], [Телефон клиента], line order by [Дата звонка])=1 then max([Дата звонка]) over(partition by [Дата звонка день], [Телефон клиента], line) end) [Время до последнего обращения клиента на линию]
,sum([Время разговора] ) over(partition by [Дата звонка день], [Телефон клиента], line) [Суммарное время разговора по клиенту в рамках линии и дня]
,count(session_id ) over(partition by [Дата звонка день], [Телефон клиента], line)      [Количество диалогов по клиенту в рамках линии и дня]
,[Телефон клиента]       
,case when  client.[Дата выдачи] is not null then  case when  client_current.[Дата выдачи] is not null then  'Клиент (текущий)'  else 'Клиент (закрытый)' end  else 'Потенциальный клиент' end as [Тип клиента]      
,line                    
,line_name                   
,line_6001               
,line_6001_login               
,line_6002               
,line_6002_login            
,line_6003               
,line_6003_login     
,[Клиент дождался соединения]               
,[Ссылка звонок]         
,[Ссылка взаимодействие] 
,[Тематика]              
,[Подтематика]    
,[Оценка звонка]    
,ROW_NUMBER() over(partition by [Дата звонка день], [Телефон клиента], line order by [Дата звонка]) rn
,case when [Клиент дождался соединения]=1 then ROW_NUMBER() over(partition by [Дата звонка день], [Телефон клиента], line , [Клиент дождался соединения] order by [Клиент дождался соединения] desc, [Дата звонка]) end [rn по дождавшимя соединения]
,getdate() as created    
into #final_for_ins
from #final f 
outer apply (select top 1 [Дата звонка]  [Дата повторного обращения на линию] from #final fx where f.[Телефон клиента]=fx.[Телефон клиента] and f.[Дата звонка]<fx.[Дата звонка]  and fx.Тематика=f.Тематика and fx.[Подтематика]=f.[Подтематика] and f.line=fx.line and f.[Дата звонка день]=fx.[Дата звонка день]) x
outer apply (select top 1 * from  #loans l where f.[Телефон клиента]=l.[Телефон договор CMR] and f.[Дата звонка]>=l.[Дата выдачи] ) client
outer apply (select top 1 * from  #loans l where client.CRMClientGUID=l.CRMClientGUID and f.[Дата звонка]<=isnull(l.[Дата погашения], getdate()+1 ) and  f.[Дата звонка]>=l.[Дата выдачи] ) client_current
--order by [Телефон клиента], [Дата звонка]

--select * from  #final_for_ins

--select * from report_naumen_lines

begin tran

-- drop table if exists Analytics.dbo.report_naumen_lines2
-- select * into Analytics.dbo.report_naumen_lines2 from #final_for_ins
delete from Analytics.dbo.report_naumen_lines2 where [Дата звонка день] between @start_date and @end_date
insert into Analytics.dbo.report_naumen_lines2 
select * from #final_for_ins
commit tran

end