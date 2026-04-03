
CREATE   proc [dbo].[create_report_kpi_employees]
as
begin

 if DATEPART(hour, getdate())<6
 return

--declare @start_date date = '20200101'
declare @long_update int = case when (
  select top 1 Run_DateAndTime--, * 
  FROM jobh
  where [job_id]='BB2350E0-E616-4508-A8DC-DF0BB838FADF' and [is_Succeeded]=1 and is_today_run=1   and DATEPART(hour, Run_DateAndTime)>=6
  order by Run_DateAndTime desc
  ) is null then 1 else 0 end
declare @start_date date = case when @long_update = 0 then  getdate()-10 else dateadd(month, -6, cast(format(GETDATE() , 'yyyy-MM-01') as date))   end  

select @start_date

drop table if exists #core_Lead
select 
        id
      , idexternal
      , Phone collate Cyrillic_General_CI_AS  Phone
      , IdStatus
      , dateadd(hour, 3, CreatedOn) CreatedOn

into #core_Lead

from 
stg._fedor.core_Lead
where 
dateadd(hour, 3, CreatedOn)>=@start_date 
and isnumeric(idexternal)=1 and IdExternal<>'0'

 
drop table if exists #distinct_id_leads
select distinct cast(idexternal as numeric) idexternal into #distinct_id_leads
from #core_Lead

drop table if exists #core_ClientRequest
select 
a.idlead idlead
, a.number collate Cyrillic_General_CI_AS number
, ClientPhoneMobile collate Cyrillic_General_CI_AS ClientPhoneMobile
, IdProcessingType
, dateadd(hour, 3, a.[CreatedOn]) [CreatedOn]
, case
when a.type in (2,4,5) then 1
when b.ПДЛ =1 then 1
when b.Инстолмент is not null then cast(b.Инстолмент as int)
when IsInstallment=1 then 1 else 0 
end IsInstallment
into #core_ClientRequest
--select top 100 *
from
stg._fedor.core_ClientRequest a
left join stg.[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] b on try_cast(a.number as bigint)=try_cast(b.Номер as bigint) and dateadd(year, -2000, b.Дата)>='20221123'
--join #core_Lead b on a.idlead=b.id
where dateadd(hour, 3, a.[CreatedOn])>=@start_date




 drop table if exists #l_r
select l.id, isnull(r.number, x.number) number--, x.number [Заявка]

into #l_r

from #core_Lead  l
left join #core_ClientRequest r on l.id=r.idlead
outer apply (
select top 1 
* 
from #core_ClientRequest b 
where 
l.Phone=b.ClientPhoneMobile 
and b.CreatedOn between dateadd(hour, 3, l.CreatedOn) and  dateadd(day, 1,  dateadd(hour, 3, l.CreatedOn) )
and l.IdStatus=9
and r.number is null
order by r.CreatedOn

) x


drop table if exists #inst_lead
select [ID лида Fedor] into #inst_lead from feodor.dbo.v_dm_LeadAndSurvey_installment_lids
 



drop table if exists #t1
--declare @start_date date = '20211001'

select  
  НомерЗаявки Номер
, ВыданнаяСумма [Выданная сумма накопительно]
, case when  cast([Заем выдан]  as date) = cast([Верификация КЦ]  as date) then ВыданнаяСумма end [Выданная сумма день в день]
, АвторЗаявки  [Оператор ФИО]
, ДатаЗаявки Дата
, [Верификация КЦ]  [Верификация КЦ]
, [Предварительное одобрение]  [Предварительное одобрение накопительно]
,  case when  cast([Предварительное одобрение]  as date) = cast([Верификация КЦ]  as date) then ВыданнаяСумма end  [Предварительное одобрение день в день]
, [Контроль данных] [Контроль данных накопительно] 
,  case when  cast([Контроль данных]as date) = cast([Верификация КЦ]  as date) then[Контроль данных] end [Контроль данных день в день] 
, [Одобрено]  [Одобрено накопительно] 
, case when  cast([Одобрено]as date) = cast([Верификация КЦ]  as date) then[Одобрено]end   [Одобрено день в день] 
, [Верификация документов клиента]  [Верификация документов клиента накопительно] 
, case when  cast([Верификация документов клиента]as date) = cast([Верификация КЦ]  as date) then[Верификация документов клиента]end   [Верификация документов клиента день в день] 
, [Верификация документов]  [Верификация документов накопительно] 
, case when  cast([Верификация документов]as date) = cast([Верификация КЦ]  as date) then[Верификация документов]end   [Верификация документов день в день] 
, [Заем выдан] [Заем выдан накопительно]
, case when  cast([Заем выдан]as date) = cast([Верификация КЦ]  as date) then[Заем выдан]end  [Заем выдан день в день]
, МестоСоздания  [Место создания] 
, 1-isPts isInstallment
into #t1 from v_request
where ДатаЗаявки >=@start_date and [Верификация КЦ] is not null

delete from #t1 
 where [Верификация КЦ] is null
--declare @start_date date = '20211001'

CREATE INDEX ix_idexternal ON #distinct_id_leads(idexternal)
DROP table if exists #lcrm_new
select a.id
, a.[Группа каналов]
, a.[Канал от источника]
into #lcrm
from stg._LCRM.lcrm_leads_full_calculated AS a
join #distinct_id_leads x on a.ID=x.IdExternal

drop table if exists #lcrm_request
 select x.Номер, a.[Группа каналов], a.[Канал от источника]
 into #lcrm_request 
 from stg._LCRM.lcrm_leads_full_channel_request a
 join #t1 x on a.UF_ROW_ID=x.Номер


--select * from [PRODSQL02].[Fedor.Core].dictionary.ProcessingType

drop table if exists #dictionary_LeadStatus
select *
into #dictionary_LeadStatus
from
--Feodor.dbo.dm_Lead
stg._fedor.dictionary_LeadStatus a

--declare @start_date date = '20210101'
drop table if exists #core_LeadCommunication
select a.id, idlead , dateadd(hour, 3, CreatedOn)CreatedOn, IdOwner
into #core_LeadCommunication
from
stg._fedor.core_LeadCommunication a
where dateadd(hour, 3, CreatedOn)>=@start_date
--join #core_Lead b on a.idlead=b.id

drop table if exists #core_LeadCommunicationCall
select a.id
, a.NaumenProjectId  collate Cyrillic_General_CI_AS NaumenProjectId
into #core_LeadCommunicationCall
from
--Feodor.dbo.dm_Lead
stg._fedor.core_LeadCommunicationCall a 
join #core_LeadCommunication b on a.Id=b.id
--where cre


drop table if exists #core_user
select Id
, LastName+' '+FirstName+' '+MiddleName  collate Cyrillic_General_CI_AS  [Оператор ФИО]
into #core_user
from
stg._fedor.core_user a


drop table if exists #Projects
select  
 id
, max(NaumenProjectId)   NaumenProjectId
into #Projects
from
 #core_LeadCommunicationCall group by id


create nonclustered index ix on #core_LeadCommunication
(idlead , createdon)

create clustered index ix on #Projects
(id)

drop table if exists #leadcommunication
select * 
into #leadcommunication
from(
select a.IdLead
, ROW_NUMBER() over(partition by idlead order by a.createdon) rn
, max(x.NaumenProjectId) over(partition by idlead  )      [NaumenProjectId]
, min(a.createdon) over(partition by idlead  )      [FirstCall]
, max(a.createdon) over(partition by idlead  )      [LastCall]
, first_value(a.idowner) over(partition by idlead  order by a.createdon)       [FirstIdOwner]
, first_value(a.idowner) over(partition by idlead  order by a.createdon desc)  [LastIdOwner]
from
#core_LeadCommunication a 
left join #Projects x on x.id=a.Id
)x
where rn=1




drop table if exists #final

select 
  l.IdExternal
, case when l.IdExternal is not null then 'Feodor' else 'CRM' end [Source]
, isnull(b.[Верификация КЦ],  c.[LastCall]) Date
, isnull(u.[Оператор ФИО], b.[Оператор ФИО]) [Оператор ФИО]
, isnull(lcrm.[Группа каналов], lcrm_request.[Группа каналов]) [Группа каналов]
, isnull(lcrm.[Канал от источника], lcrm_request.[Канал от источника]) [Канал от источника]
, [Признак заявка] = case when b.Номер is not null then 1 else 0 end
, [Признак профильный] = case when l.IdExternal is not null  then 
case when s.Name in  ('Отправлен в ЛКК','Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) or b.Номер  is not null  then 1 else 0 end end
, [Признак отказ клиента] = case when l.IdExternal is not null  then case when s.Name in  ('Отказ клиента с РСВ', 'Отказ клиента без РСВ')  then 1 else 0 end end
, [Место создания]
--, u_1.DomainLogin DomainLogin1
, l.Phone
, l.CreatedOn
, l.Id
, c.FirstCall
, c.FirstIdOwner
, c.LastIdOwner
, c.NaumenProjectId
, r.number
, r.IdProcessingType
, s.Name
, fp.LaunchControlName CompanyNaumen
, b.[Верификация КЦ]
, b.[Предварительное одобрение накопительно]
, b.[Предварительное одобрение день в день]
, b.[Контроль данных накопительно]
, b.[Контроль данных день в день]
, b.[Одобрено накопительно]
, b.[Одобрено день в день]
, b.[Заем выдан накопительно]
, b.[Заем выдан день в день]
, b.[Выданная сумма накопительно]
, b.[Выданная сумма день в день]
, b.[Верификация документов накопительно]
, b.[Верификация документов день в день]
, b.[Верификация документов клиента накопительно]
, b.[Верификация документов клиента день в день]
, case when r.IsInstallment is not null then r.IsInstallment
       when b.IsInstallment is not null then b.IsInstallment
       when il.[ID лида Fedor] is not null then 1 else 0 end
	    IsInstallment
into #final

from #core_Lead l
left join #leadcommunication c on c.IdLead=l.id
left join #l_r l_r on l_r.id=l.id
left join #core_ClientRequest r on l_r.number=r.number
left join #dictionary_LeadStatus s on s.id=l.IdStatus
left join #lcrm lcrm on lcrm.id=l.IdExternal
full outer join #t1 b on b.Номер=r.number
left join #lcrm_request lcrm_request on lcrm_request.Номер=b.Номер
left join #core_user u on u.id=c.LastIdOwner
left join #core_user u_1 on u_1.id=c.FirstIdOwner
left join Feodor.dbo.dm_feodor_projects fp on fp.IdExternal=c.NaumenProjectId
left join #inst_lead il on il.[ID лида Fedor]=l.Id
where-- isnull(r.IdProcessingType, 0) in (0, 7) and
isnull(c.FirstCall, b.[Верификация КЦ]) is not null
--order by  isnull(b.Дата,  l.CreatedOn) 

--select * from #final 
--except
--select * from #final1
--
--
--select * from #final1
--except
--select * from #final


--select * from #final
--order by Date desc
drop table if exists #final_agr

select 
    cast(b.date as date) Date_d
  , Source
  , [Оператор ФИО] [Оператор ФИО]
  , [Группа каналов]
  , [Канал от источника]
  , CompanyNaumen
  , [Признак заявка]
  , [Признак профильный]
  , [Место создания]
, IsInstallment

, count(distinct Phone)                                    [Обработано уникальных лидов]
, count(case when [Признак профильный] = 1 then Id end)    [Профильных лидов]
, count(case when [Признак отказ клиента] = 1 then Id end) [Лидов с отказом клиента]
, count([Верификация КЦ]) [Верификация КЦ]
, count([Предварительное одобрение накопительно]) [Предварительное одобрение накопительно]
, count([Предварительное одобрение день в день]) [Предварительное одобрение день в день]
, count([Контроль данных накопительно]) [Контроль данных накопительно]
, count([Контроль данных день в день]) [Контроль данных день в день]
, count([Одобрено накопительно]) [Одобрено накопительно]
, count([Одобрено день в день]) [Одобрено день в день]
, count([Заем выдан накопительно]) [Заем выдан накопительно]
, count([Заем выдан день в день])  [Заем выдан день в день]
, count([Верификация документов накопительно]) [Верификация документов накопительно]
, count([Верификация документов день в день]) [Верификация документов день в день]
, count([Верификация документов клиента накопительно]) [Верификация документов клиента накопительно]
, count([Верификация документов клиента день в день]) [Верификация документов клиента день в день]
, sum([Выданная сумма накопительно])  [Выданная сумма накопительно]
, sum([Выданная сумма день в день]) [Выданная сумма день в день]
into #final_agr
from  
#final b 
group by 
  cast(b.date as date) 
, Source
, CompanyNaumen
, [Оператор ФИО]
, [Группа каналов]
, [Канал от источника]
, [Признак заявка]
, [Признак профильный]
, [Место создания]
, IsInstallment

--drop table if exists analytics.dbo.report_kpi_employees 
--
--select * into analytics.dbo.report_kpi_employees 
--from #final_agr



begin tran


declare @report_date datetime  = (select max(CreatedOn) CreatedOn from #core_Lead)

if (select OBJECT_ID('analytics.dbo.report_kpi_employees')) is null
begin
drop table if exists analytics.dbo.report_kpi_employees 
select *, @report_date created into analytics.dbo.report_kpi_employees 
from #final_agr
end
else
begin

delete from  analytics.dbo.report_kpi_employees where Date_d between @start_date and getdate()
insert into analytics.dbo.report_kpi_employees 
select *, @report_date as created from #final_agr
end
commit tran
--alter table analytics.dbo.report_kpi_employees alter column [CompanyNaumen] varchar(100)


delete from analytics.dbo.report_kpi_employees where Date_d<dateadd(month, -6, cast(format(GETDATE() , 'yyyy-MM-01') as date)	 )

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'B1154789-AEAF-4D46-ACCA-4CE456E2562A'


end