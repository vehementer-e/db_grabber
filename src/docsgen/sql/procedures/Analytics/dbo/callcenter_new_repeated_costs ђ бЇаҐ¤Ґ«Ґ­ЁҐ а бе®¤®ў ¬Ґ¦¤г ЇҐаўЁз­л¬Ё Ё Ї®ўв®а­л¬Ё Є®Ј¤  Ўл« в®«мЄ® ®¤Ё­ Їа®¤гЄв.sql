
CREATE   proc [dbo].[callcenter_new_repeated_costs] --@month date
as 


begin

drop table if exists #t1

declare @month date  = 	cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()-30), 0) as date)
select @month
;
with v as(

SELECT [session_id]			
      ,[attempt_start]			
      ,Месяц = cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, attempt_start), 0) as date)	
      ,[client_number]			
      ,[Разговор и постобработка] = nullif(isnull(speaking_time, 0) +isnull([wrapup_time] , 0), 0 )			
      ,Траффик = nullif(isnull(pickup_time, 0) +isnull(queue_time , 0) +isnull(operator_pickup_time , 0) +isnull(speaking_time , 0), 0 )			
      ,[project_id]			
	
  FROM [NaumenDbReport].[dbo].[detail_outbound_sessions] a with(nolock )			

	)		


SELECT [session_id]
,      [attempt_start]
,      Месяц
,      [client_number]
,      [Разговор и постобработка]
,      Траффик
,      [project_id]
	into #t1
FROM v

where Месяц = @month

drop table if exists #not_sales_projects  			

select * into  #not_sales_projects
from (
select 'Collection (Middle)'	                          project union all	
select 'Collection (Middle)'							   union all
select 'Collection ve-lab (hard mobile)'				   union all
select 'Collection PreLegal'		 					   union all
select 'Collection ve-lab (hard)'						   union all
select 'Collection (Soft)'								   union all
select 'Pre-del Испытательный срок'						   union all
select 'Pre-del КК'										   union all
select 'Pre-del Обзвон'									   union all
select 'Soft KK'										   union all
select 'Soft Испытательный срок'						   union all
select 'Обработка обращений клиентов'					   union all
select 'Обзвон погашенных'								   union all
select 'Pre-del Sales'									   union all
select 'Автоинформатор PRE-DEL'							   union all
select 'Сдвиг даты платежа'								   union all
select 'СКИП'											   union all
select 'Тест'											   union all
select 'Обзвон колбэков группы сервиса'					   union all
select 'Автоинформатор по портфелю с дисконтами'		   union all
select 'Коллекшн'		   union all
select 'Обзвон выданных'								   --union all

union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%collec%'

union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%Soft%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%legal%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%hard%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%pre-del%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%middle%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%исполнительного%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%Обзвон колбэков группы сервиса Zaprosto%'
union
select distinct projecttitle from reports.dbo.dm_naumenprojects where projecttitle like  '%Согласование перехода на P2P%'
) x

select distinct projecttitle  from reports.dbo.dm_naumenprojects
except
select * from   	#not_sales_projects  		
;with v  as (select *, row_number() over(partition by project order by (select null)) rn from #not_sales_projects ) delete from v where rn>1 			
			
			
 drop table if exists #first_loan;					
 with v as (			
select код = код                                                                               
,      [Телефон] = '8'+isnull(nullif([Телефон договор CMR] , '') , lh.[Основной телефон клиента CRM]) 
,      [Дата выдачи день] = lh.[Дата выдачи день]                                                              
from Analytics.dbo.v_loans lh
where len([Телефон договор CMR])=10
)				
select [Телефон]     
,      min([Дата выдачи день]) [Дата выдачи день] into #first_loan
from v
group by [Телефон]

			
;			
with a as (			
select *                                                                                      			
,      case when a.attempt_start>=cast(dateadd(day, 1, fl.[Дата выдачи день]) as date) then 'Повторный' else 'Новый' end [признак звонок повторному]
from      #t1                           a 			
left join #first_loan                   fl on a.client_number=fl.[Телефон]			
)			
		

select 			
projecttitle = projecttitle,			
[признак звонок повторному] = [признак звонок повторному],			
[Число Звонков] = isnull([Число Звонков], 0) ,			
[Разговор И Постобработка] = isnull([Разговор И Постобработка], 0) , 			
Траффик = isnull(Траффик, 0) ,			
Месяц,			
case when nsp.project  is not null then 1 else 0 end non_sales_project		
, getdate() as created
from 			
(			
select projecttitle = Analytics.dbo.get_naumen_projectname(project_id) 			
,      [признак звонок повторному]			
,      [Разговор И Постобработка] =  sum([Разговор и постобработка]) 			
,      [Траффик]                  =  sum(Траффик) 			
,      [Число Звонков]            =  count(*) 			
, Месяц			
from      a			
group by project_id, [признак звонок повторному], Месяц			
			
)  a			
--left join reports.dbo.dm_naumenprojects np on np.projectuuid=a.project_id			
left join #not_sales_projects nsp on nsp.project=a.projecttitle
		
		end