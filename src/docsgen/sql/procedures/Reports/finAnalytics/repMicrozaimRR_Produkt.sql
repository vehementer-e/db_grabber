
CREATE PROCEDURE [finAnalytics].[repMicrozaimRR_Produkt]

AS
BEGIN
    drop table if exists #sortProdukt
	create table #sortProdukt (id int,produkt varchar(50))
	insert into #sortProdukt (id,produkt)
		values
			(1,'ПТС'),
			(2,'Автокредит'),
			(3,'Big Installment'),
			(4,'Installment'),
			(5,'PDL')
			


	drop table if exists #kfRR
	select
		l1.repmonth
		,kfRR=max(l1.kfRR)
		,sales=sum(l1.sales)
	into #kfRR
	from 
	(
		select
			repmonth=eomonth(repdate)
			,sales=sales
			,kfRR=isnull(
					cast(sum(sales)over(partition by eomonth(repdate)  order by repdate rows unbounded preceding) as decimal)/nullif(salesRR,0)
					,1)
		from dwh2.finAnalytics.repMicrozaim
		--where repdate<='2026-01-25'
	)l1
	group by l1.repmonth

	--select * from #kfRR

select
		[Отчетный месяц]=eomonth(a.repdate)
		,[Отчетна дата]=a.repdate
		,[Продукт]=a.produkt
		,[Сумма продукта в выдачи]=a.produktInSales
		,[Проверка]=sum(a.produktInSales)over(partition by a.repdate)-first_value(b.sales)over(partition by a.repdate order by a.repdate)
		,[Доля]=a.produktInSales/b.sales
		,[Cумма продукта в RR выдачи]=sum(a.produktInSales)over(partition by a.produkt,eomonth(a.repdate))/c.kfRR
		,[Выдачи]=b.sales
		,[Выдача в месяц]=c.sales
		,[RR выдачи]=b.salesRR
		,[Коэффициент RR]=c.kfRR
		,[Сортировка Продуктов]=iif(d.produkt is null,100,d.id)
		
from dwh2.finAnalytics.repMicrozaim_Produkt a
left join dwh2.finAnalytics.repMicrozaim b on a.repdate=b.REPDATE
left join #kfRR c on eomonth(a.repdate)=c.repmonth
left join #sortProdukt d on a.produkt=d.produkt
--where a.repdate<='2026-01-25'
order by a.repdate desc

	
END
