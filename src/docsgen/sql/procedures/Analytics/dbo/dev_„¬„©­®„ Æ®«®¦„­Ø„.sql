
create proc dbo.[Семейное положение] 
as

begin

select * from Analytics.dbo._v_information_schema_linked
where is_feodor=1 and [table & column names] like '%famil%'



select top 100 * from [PRODSQL02].[fedor.core].core.PersonInfoPhysical
select id, createdon, idowner, idfamilystatus, idperson into #t1 from [PRODSQL02].[fedor.core].core.PersonInfoPhysical

select * from #t1

select idperson, count(distinct idfamilystatus) x from #t1
group by idperson
order by x desc
--order by 6 desc


select 
  a.number
, a.IdClient --, b.client_marital_status_id 
, a.CreatedOn --, b.client_marital_status_id 
, a.IdFamilyStatus --, b.client_marital_status_id 
, c.[Ссылка клиент]
, row_number() over(partition by   c.[Ссылка клиент] order by a.createdon) rn
, x.createdon
, x.idfamilystatus
, x1.createdon
, x1.idfamilystatus
, [Вид займа]
from stg._fedor.core_clientrequest a
left join stg._LK.requests b on a.Number collate Cyrillic_General_CI_AS=b.num_1c
join reports.dbo.dm_factor_analysis c on c.Номер=a.Number collate Cyrillic_General_CI_AS and c.[Заем выдан] is not null
outer apply (select top 1 * from #t1 b where b.idperson=a.IdClient and a.CreatedOn>=b.createdon) x
outer apply (select top 1 * from #t1 b where b.idperson=a.IdClient and a.CreatedOn<b.createdon) x1
--where [Ссылка клиент]=0xB82000505683780511EA6D8A1CE24B99
order by 1 desc

select top 1000 * from [PRODSQL02].[fedor.core].dictionary.FamilyStatus


end