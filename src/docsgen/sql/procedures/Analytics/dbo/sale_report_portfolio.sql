create      proc sale_kpi_portfolio_report @mode nvarchar(max) = ''
as
begin

drop table if exists #t1

select Дата into #t1 from v_Calendar where Дата=Месяц
and Дата between '20230101' and getdate()


if @mode = 'Клиенты текущие и накопительно статистика'

begin


select 'накопительно с любым продуктом' тип, DATEADD(DAY, -1, a.Дата) Дата, ''   Продукт, count(distinct b.CRMClientGUID) cnt_dst_clients from #t1 a
left join mv_loans b on b.[Дата выдачи день]<a.Дата 
group by a.Дата 
--order by 2, 1

union all

select 'накопительно' тип, DATEADD(DAY, -1, a.Дата) Дата, case when b.isInstallment=0 then 'ПТС' else 'Беззалог' end Продукт, count(distinct b.CRMClientGUID) cnt_dst_clients from #t1 a
left join mv_loans b on b.[Дата выдачи день]<a.Дата 
group by a.Дата, b.isInstallment
--order by 2, 1

union all


select 'активные' тип, DATEADD(DAY, -1, a.Дата) Дата, case when b.isInstallment=0 then 'ПТС' else 'Беззалог' end Продукт, count(distinct b.CRMClientGUID) cnt_dst_clients from #t1 a
left join mv_loans b on b.[Дата выдачи день]<a.Дата and isnull(b.[Дата погашения день], getdate()+1)>=a.Дата
group by a.Дата, b.isInstallment
--order by 2, 1


end 

if @mode = 'Займы текущие и накопительно статистика'

begin


select 'накопительно' тип, DATEADD(DAY, -1, a.Дата) Дата, case when b.isInstallment=0 then 'ПТС' else 'Беззалог' end Продукт, count(b.CRMClientGUID) cnt_dst_clients from #t1 a
left join mv_loans b on b.[Дата выдачи день]<a.Дата 
group by a.Дата, b.isInstallment
--order by 2, 1

union all


select 'активные' тип, DATEADD(DAY, -1, a.Дата) Дата, case when b.isInstallment=0 then 'ПТС' else 'Беззалог' end Продукт, count(b.CRMClientGUID) cnt_dst_clients from #t1 a
left join mv_loans b on b.[Дата выдачи день]<a.Дата and isnull(b.[Дата погашения день], getdate()+1)>=a.Дата
group by a.Дата, b.isInstallment
--order by 2, 1


end 



if @mode = 'ОД'

begin


select DATEADD(DAY, -1, a.Дата) Дата, b.[Тип Продукта]  Продукт, sum([остаток од])/1000000.0 [остаток од млн] from #t1 a
left join v_balance b on b.d= DATEADD(DAY, -1, a.Дата)
group by  DATEADD(DAY, -1, a.Дата), b.[Тип Продукта]
--order by 2, 1




end 




end