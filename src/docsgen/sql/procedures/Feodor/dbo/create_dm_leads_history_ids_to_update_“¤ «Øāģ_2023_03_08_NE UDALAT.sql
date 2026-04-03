CREATE   PROC dbo.create_dm_leads_history_ids_to_update_Удалить_2023_03_08
as
begin

	select id, [Канал от источника] into #t1 from stg._LCRM.lcrm_leads_full_calculated with(nolock)
	except
	select id, [Канал от источника]  from [Feodor].[dbo].[dm_leads_history] lh with(nolock)
	;

delete a from #t1 a
left join Feodor.dbo.dm_leads_history_ids_to_update b on a.id=b.id
where b.id is not null


    insert into Feodor.dbo.dm_leads_history_ids_to_update
	select id from #t1


--	drop table if exists ##id_wrong_inst
--
--	select distinct a.[ID LCRM] into ##id_wrong_inst from Feodor.dbo.dm_Lead a
--left join stg._fedor.core_ClientRequest b on a.[Номер заявки (договор)]=b.Number collate Cyrillic_General_CI_AS
--where a.IsInstallment<>b.IsInstallment
--
--insert into dm_leads_history_ids_to_update
--select try_cast([ID LCRM] as numeric) from ##id_wrong_inst a
--left join Feodor.dbo.dm_leads_history_ids_to_update b on try_cast([ID LCRM] as numeric) =b.id
--where  try_cast([ID LCRM] as numeric) is not null and b.id is null


select id, UF_LOGINOM_PRIORITY, UF_LOGINOM_STATUS, UF_LOGINOM_GROUP, UF_LOGINOM_CHANNEL
into #t2
from stg._LCRM.lcrm_leads_full with(nolock)



--select top 100 a.id, b.UF_LOGINOM_PRIORITY, a.UF_LOGINOM_PRIORITY, b.UF_LOGINOM_STATUS, a.UF_LOGINOM_STATUS from Feodor.dbo.dm_leads_history a
--join #t2 b on a.id=b.id
--and (isnull(b.UF_LOGINOM_PRIORITY, 0)<>isnull(a.UF_LOGINOM_PRIORITY, 0)
--or isnull(b.UF_LOGINOM_STATUS, 0)<>isnull(a.UF_LOGINOM_STATUS, 0))


drop table if exists #t3
select a.id, b.UF_LOGINOM_STATUS,b.UF_LOGINOM_PRIORITY, B.UF_LOGINOM_GROUP, B.UF_LOGINOM_CHANNEL  into #t3
from Feodor.dbo.dm_leads_history a  with(nolock)
join #t2 b on a.id=b.id
and (isnull(b.UF_LOGINOM_PRIORITY, 0)<>isnull(a.UF_LOGINOM_PRIORITY, 0)
or isnull(b.UF_LOGINOM_STATUS, 0)<>isnull(a.UF_LOGINOM_STATUS, 0)
or isnull(b.UF_LOGINOM_GROUP, 0)<>isnull(a.UF_LOGINOM_GROUP, 0)
or isnull(b.UF_LOGINOM_CHANNEL, 0)<>isnull(a.UF_LOGINOM_CHANNEL, 0)


)
--AND A.ДатаЛидаЛСРМ<'20220801'
--and b.UF_LOGINOM_STATUS<>'unknown'

--delete from #t3 where UF_LOGINOM_STATUS='unknown'
--select * from #t3

drop table if exists #t4
select top 0 * into #t4
from #t3

declare @a bigint = 1
declare @a1 bigint = 1

declare @b nvarchar(100) = '1'
declare @b1 nvarchar(100) = '1'

while @a >0 and @a1<=40
begin


insert into #t4
select top 1000000 * from #t3


update top (1000000) a
set a.UF_LOGINOM_PRIORITY=b.UF_LOGINOM_PRIORITY,
a.UF_LOGINOM_STATUS=b.UF_LOGINOM_STATUS,
a.UF_LOGINOM_GROUP=b.UF_LOGINOM_GROUP,
a.UF_LOGINOM_CHANNEL=b.UF_LOGINOM_CHANNEL
from Feodor.dbo.dm_leads_history a
join #t4 b on a.id=b.id

set @a = @@ROWCOUNT
select @a
set @a1 = @a1+1

set @b = cast(@a as nvarchar(max))
set @b1 = 'UPDATE PRIORITY, _STATUS, GROUP, CHANNEL. Цикл - '+cast(@a1 as nvarchar(max)) +' Кол-во строк - '+@b

delete a from #t3 a
join #t4 b on a.id=b.id
delete from #t4
if @a >0
begin
exec Analytics.dbo.log_email @b1, 'p.ilin@techmoney.ru'
end
end


end