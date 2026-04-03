CREATE proc [dbo].[dq_issued] as


--alter table dq_issued_log alter column source varchar(100)
--sp_create_job 'Analytics._dq_issued each min' , 'dq_issued',  '1', '60000'  , '1'

insert into dq_issued_log
select *, getdate() rowCreated from (

select number, issued dt, 'v_fa' source  from v_fa where issued>=getdate()-1
except 
select number,   dt,  source   from dq_issued_log  
) x


insert into dq_issued_log
select *, getdate() rowCreated from (
select код, ДатаВыдачи dt, 'dm_sales' source  from reports.dbo.dm_sales where ДатаВыдачи>=getdate()-1
except 
select number,   dt,  source   from dq_issued_log  
) x


insert into dq_issued_log
select *, getdate() rowCreated from (
select number, issued dt, 'v_request' source  from v_request where issued>=getdate()-1
except 
select number,   dt,  source   from dq_issued_log  
) x


insert into dq_issued_log
select *, getdate() rowCreated from (
select number, issued dt, 'request' source  from  request where issued>=getdate()-1
except 
select number,   dt,  source   from dq_issued_log  
) x

--drop table dq_issued_sum_log
--select a.date, b.ДатаВыдачи, b.Код, b.Сумма, getdate() dt  into dq_issued_sum_log from calendar_view a 
--left join  reports.dbo.dm_sales b on a.date = b.ДатаВыдачи
--where a.lastNday between 0 and 7


insert into    dq_issued_sum_log 
select a.date, b.ДатаВыдачи, b.Код, b.Сумма, getdate() dt from calendar_view a 
left join  reports.dbo.dm_sales b on a.date = b.ДатаВыдачи
where a.lastNday between 0 and 7


delete from dq_issued_sum_log where dt<=getdate()-1

--insert into dq_issued_log
--select *, getdate() rowCreated from (
--select number, created dt, 'request' source  from v_request_status where created>=getdate()-1 and status = 'Заем выдан'
--except 
--select number,   dt,  source   from dq_issued_log  
--) x






