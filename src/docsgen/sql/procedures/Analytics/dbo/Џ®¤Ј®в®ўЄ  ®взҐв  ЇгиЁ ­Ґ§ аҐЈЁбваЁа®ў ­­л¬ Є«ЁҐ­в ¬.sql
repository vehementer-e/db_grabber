
create   proc dbo.[Подготовка отчета пуши незарегистрированным клиентам] @mode nvarchar(max)
as
begin

if @mode = 'update'
begin

drop table if exists #T1

select cast(ВремяСтрокиНаСайте as date) Дата ,* INTO #T1
from mv_woopra_mp-- WHERE ВремяСтрокиНаСайте >='20220101'

--select * from #T1
--order by ВремяСтрокиНаСайте desc
--
drop table if exists #r

select client_id, num_1c, created_at into #r from stg._LK.requests
drop table if exists #f

select Номер, [Верификация кц] , [Предварительное одобрение] , [контроль данных] , [Одобрено] , [Заем выдан] ,  [выданная сумма] into #f from reports.dbo.dm_factor_analysis_001

drop table if exists #r_f

select  client_id, num_1c, created_at, Номер, [Верификация кц] , [Предварительное одобрение] , [контроль данных] , [Одобрено] , [Заем выдан], [выданная сумма] into #r_f from #r a
left join #f b on a.num_1c=b.Номер



drop table if exists #final


select a.Дата,
case 
when a.[Action Name] in ('feature_unregistered_push_1_sent' ,'feature_unregistered_push_2_sent') then 'push'
when a.[Action Name] in ('feature_open_after_unregistered_push' ) then 'open'
when a.[Action Name] in ('feature_registration_after_push_complete' ) then 'register'
end  type
,a.client_id client_id_woopra
,a.ВремяСтрокиНаСайте
, a.[Action Name], a.[user id mp] , a.[Телефон клиента] 
, x.*
into #final
from #t1 a 
outer apply (select top 1 * from #r_f b where a.[user id mp]=b.client_id and  b.created_at between ВремяСтрокиНаСайте and dateadd(day, 1, ВремяСтрокиНаСайте) and [Action Name] = 'feature_registration_after_push_complete'
order by 
[Заем выдан] desc
,[Одобрено] desc
,[контроль данных] desc
,[Предварительное одобрение] desc
,[Верификация кц] desc
) x
where a.[Action Name] in (
'feature_open_after_unregistered_push'
,'feature_registration_after_push_complete'
,'feature_unregistered_push_1_sent'
,'feature_unregistered_push_2_sent'
)
order by a.[Action Name], a.ВремяСтрокиНаСайте

drop table if exists #final_agr

select Дата
, count(distinct case when type='push' then client_id_woopra end) [Отправили пуш]
, count(distinct case when type='open' then client_id_woopra end) [Открыли пуш]
, count(distinct case when type='register' then [user id mp] end) [Зарегистрировались]
, count(distinct case when type='register' and created_at is not null then [user id mp] end) [Начали заполнять заявку]
, count(distinct case when type='register' and [Предварительное одобрение] is not null then [user id mp] end) [Предварительное одобрение]
, count(distinct case when type='register' and [Контроль данных] is not null then [user id mp] end) [Контроль данных]
, count(distinct case when type='register' and Одобрено is not null then [user id mp] end) Одобрено
, count(distinct case when type='register' and [Заем выдан] is not null then [user id mp] end) [Заем выдан]
, sum ( case when type='register' and [Заем выдан] is not null then [Выданная сумма] end) [Выданная сумма]
, getdate() as created
into #final_agr
from #final
group by Дата


begin tran

--drop table if exists dbo.[Отчет пуши незарегистрированным клиентам]
--
--select * into dbo.[Отчет пуши незарегистрированным клиентам]
--from #final_agr

delete from dbo.[Отчет пуши незарегистрированным клиентам]
insert into dbo.[Отчет пуши незарегистрированным клиентам]
select * from #final_agr

commit tran

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '3E26F9A7-0294-429C-9764-1F99B9A49295'

end

if @mode ='select'
begin

select * from dbo.[Отчет пуши незарегистрированным клиентам]
--where [Action Name]='feature_registration_after_push_complete'
--order by 4

end
--select distinct [Action Name] from #T1 where [Action Name] like '%push%'
--where [Action Name] ='feature_open_after_unregistered_push'
--
--Верх воронки - отправлено пушей - пуш1 пуш2
--Сколько открыли пуш
--Сколько зарегались
--Сколько сделали хотя бы один шаг1
--Дальше по воронке
--Савельев Даня

end