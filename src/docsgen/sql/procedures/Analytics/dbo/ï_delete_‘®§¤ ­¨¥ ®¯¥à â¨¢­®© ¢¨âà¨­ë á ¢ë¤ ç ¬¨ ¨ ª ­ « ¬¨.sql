CREATE proc  [dbo].[Создание оперативной витрины с выдачами и каналами]
as
begin
--select dateadd(month, -13, getdate())

drop table if exists #fa
select Номер, case when [Группа каналов] ='cpa' then [Канал от источника] else [Группа каналов] end Канал, [Вид займа]  into #fa from reports.dbo.dm_Factor_Analysis_001
where cast([Заем выдан]   as date ) between dateadd(month, -14, getdate()) and getdate()

drop table if exists #t1
select ДатаВыдачи, Сумма, СтавкаНаСумму, код, Канал, IsInstallment, [Вид займа], [СуммаДопУслуг_without_partner_bounty_net] into #t1 from [Reports].[dbo].[dm_Sales] where ДатаВыдачи between dateadd(month, -14, getdate()) and getdate()
and ishistory=0

drop table if exists #re

select a.[Номер заявки], a.[Канал от источника], case when b.[Группа каналов] ='cpa' then a.[Канал от источника] else b.[Группа каналов] end Канал
into #re
from stg.files.channelrequestexceptions_buffer_stg a  join stg.files.leadRef1_buffer b on a.[Канал от источника]=b.[Канал от источника]


drop table if exists #f


select ДатаВыдачи, cast(Сумма as bigint) Сумма, СтавкаНаСумму, код, isnull(isnull(b.канал, f.Канал), a.Канал) Канал, IsInstallment, ISNULL(ISNULL(f.[Вид займа], a.[Вид займа]), 'Первичный') [Вид займа], [СуммаДопУслуг_without_partner_bounty_net]  into #f from #t1 a
left join #re b on a.Код=b.[Номер заявки]
left join #fa f on a.Код=f.Номер




--drop table if exists [оперативная витрина с выдачами и каналами]
--select * into [оперативная витрина с выдачами и каналами]
--from #f




--if 1 = 1
--begin
--	drop table if exists  [оперативная витрина с выдачами и каналами]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами]
--	from #f
--
--	drop table if exists  [оперативная витрина с выдачами и каналами_staging]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами_staging]
--	from #f
--
--
--	drop table if exists  [оперативная витрина с выдачами и каналами_to_del]
--	select top(0) * 
--		into  [оперативная витрина с выдачами и каналами_to_del]
--	from #f
--
--end




if exists(select top(1) 1 from #f)
begin
	--Отчистим таблицу - хотя после пред операции она и так будет пустая
	delete from [оперативная витрина с выдачами и каналами_to_del] with(tablockx)
	delete from [оперативная витрина с выдачами и каналами_staging] with(tablockx)
	insert into [оперативная витрина с выдачами и каналами_staging]  with(tablockx)
	SELECT * 
	from #f

	begin tran
		alter table [оперативная витрина с выдачами и каналами]
			switch to [оперативная витрина с выдачами и каналами_to_del]

		alter table [оперативная витрина с выдачами и каналами_staging] 
			switch  to [оперативная витрина с выдачами и каналами]
	commit tran
end

--select * from [оперативная витрина с выдачами и каналами]

--insert into  analytics.dbo.dm_sales_мониторинг
--select *, getdate() dt from (
--select код, [Вид займа]   from reports.dbo.dm_Sales --where ДатаВыдачи>getdate()-2
--except 
--select код, [Вид займа]   from analytics.dbo.dm_sales_мониторинг
--) x

end