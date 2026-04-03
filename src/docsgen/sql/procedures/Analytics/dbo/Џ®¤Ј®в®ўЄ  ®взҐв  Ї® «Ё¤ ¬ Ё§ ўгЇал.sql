create   proc dbo.[Подготовка отчета по лидам из вупры]
as
begin

drop table if exists #uf_clid
select id, UF_CLID into #uf_clid from stg._LCRM.lcrm_leads_full with(nolock)

drop table if exists #woopra_lcrm_id


select a.*, b.id  into #woopra_lcrm_id  from stg.files.[все лиды cpc cpm из woopra] a
left join #uf_clid b on a.crib_lead_id=b.UF_CLID
order by 4

--select * from #woopra_lcrm_id

--drop table if exists analytics.dbo.[отчет по лидам из вупры]
--select * into  analytics.dbo.[отчет по лидам из вупры] from #woopra_lcrm_id

begin tran
delete from analytics.dbo.[отчет по лидам из вупры]
insert into analytics.dbo.[отчет по лидам из вупры]
select * from #woopra_lcrm_id

commit tran



--select distinct action from analytics.dbo.[отчет по лидам из вупры]
--
--drop table if exists #f
--select [lcrm id], Номер, isInstallment , [Заем выдан] into #f from reports.dbo.dm_factor_analysis_001 
--
--select a.*, case when f.isInstallment =0 then 1 else 0 end [Заявка ПТС],  case when f.[Заем выдан] is not null then 1 else 0 end [Заем выдан] from analytics.dbo.[отчета по лидам из вупры] a 
--left join #f f on f.[lcrm id]=a.id
--
--


end
