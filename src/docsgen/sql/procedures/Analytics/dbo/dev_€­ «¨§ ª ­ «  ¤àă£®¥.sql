create proc dbo.[Анализ канала другое]

as

begin



select top 100 * from v_leads where [Группа каналов] ='Другое'
select  [Группа каналов], [Канал от источника], count(*) cnt, min(id) min_id, max(id) max_id into #t111 from v_leads 
group by [Группа каналов], [Канал от источника]
exec log_email 'ok' , 'p.ilin@carmoney.ru'



drop table if exists #all_gr
select  [Группа каналов], [Канал от источника], uf_source, uf_type, count(*) cnt, min(id) min_id, max(id) max_id into #all_gr from v_leads 
group by [Группа каналов], [Канал от источника], uf_source, uf_type
exec log_email 'ok' , 'p.ilin@carmoney.ru'








select * from #t111
order by 1,2


drop table if exists #Elecsnet
select * into #Elecsnet from v_leads
where UF_SOURCE='Elecsnet' --Другое

select * from #Elecsnet


drop table if exists #Другое
select * into #Другое from v_leads
where [Группа каналов] ='Другое' --Другое


select * from (

select distinct UF_TYPE from #Другое a
) a left join (select uf_type, [Канал от источника], sum(cnt) cnt from #all_gr b group by uf_type, [Канал от источника]) b on a.UF_TYPE=b.UF_TYPE
order by 1, 2, 3


select * from v_leads
where id=318192180 --Другое

select * from v_leads
where id=318153490 --тест


end