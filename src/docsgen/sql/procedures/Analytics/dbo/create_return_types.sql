
CREATE   proc [dbo].[create_return_types] 
as

begin
	 
	 


drop table if exists  #t1
select Номер, Телефон
, [Срок займа]
,[Предварительное одобрение]
,[Контроль данных]
, [Выданная сумма], [Верификация КЦ], 1-isPts isInstallment, isPdl, [Заем выдан], [Заем погашен], [Ссылка клиент], dbo.[getGUIDFrom1C_IDRREF]([Ссылка клиент]) [Гуид клиент] into #t1 from reports.dbo.dm_Factor_Analysis_001
					
DROP TABLE

IF EXISTS #loans
	SELECT Код Номер
		,a.isInstallment
		,[Телефон договор CMR] [Телефон]
		,CRMClientGUID [Гуид клиент]
		,isnull(b.[Заем выдан] ,  [Дата выдачи]    ) [Заем выдан]
		,isnull(b.[Заем погашен] ,  [Дата погашения] ) [Заем погашен]
	INTO #loans
	FROM mv_loans  a
	left join  #t1 b on a.код=b.Номер





drop table if exists  #povt_search

select a.Номер, a.[Заем выдан],   b.Номер	 НомерПовт			,   b.[Заем выдан]	 [Заем выдан Повт]  
into #povt_search 
from #t1	a
left join #loans	b on a.Телефон=b.Телефон and b.[Заем выдан]<=a.[Верификация КЦ] and b.[Заем погашен]<=a.[Верификация КЦ] and b.isInstallment=a.isInstallment
 
union all
 
select a.Номер, a.[Заем выдан],   b.Номер	 НомерПовт 	,   b.[Заем выдан]	 [Заем выдан Повт]  
--into #vid
from #t1	a
left join #loans	b on a.[Гуид клиент]=b.[Гуид клиент] and b.[Заем выдан]<=a.[Верификация КЦ] and b.[Заем погашен]<=a.[Верификация КЦ] and  b.isInstallment=a.isInstallment


										   
	 ;
  with v as (
select *, row_number() over(partition by  Номер, НомерПовт order by (select 1) ) rn   from #povt_search	) 

delete from v where rn>1




drop table if exists  #povt

select *
into 	#povt
from (

select distinct Номер, count(НомерПовт) over(partition by Номер ) [Кол-во закрытых займов], 
FIRST_VALUE(НомерПовт) over(partition by Номер order by case when НомерПовт is not null then 1 end desc, [Заем выдан Повт] desc ) fv

from #povt_search 
) x
where 	[Кол-во закрытых займов]>0



drop table if exists  #next_povt

select *
into 	#next_povt
from (

select distinct НомерПовт , 
FIRST_VALUE(Номер) over(partition by НомерПовт order by case when НомерПовт is not null then 1 end desc, [Заем выдан]  ) fv

from #povt_search 
where НомерПовт is not null	 and   [Заем выдан] is not null
) x									 

--select * from 	#next_povt
--select * from 	#povt

--select Номер
--, count(distinct НомерПовт) [Кол-во закрытых займов]
--
--
--into #povt from #povt_search 
--group by Номер
--having count(distinct НомерПовт)>0




  
drop table if exists  #next_search

select a.Номер,   b.Номер	 НомерСлед, b.[Заем выдан]
into #next_search 
from #t1	a
left join #loans	b on a.Телефон=b.Телефон and b.[Заем выдан]>a.[Заем выдан] and b.isInstallment=a.isInstallment  and b.Номер<>a.Номер
 
union all
 
select  a.Номер,   b.Номер	 НомерСлед, b.[Заем выдан]
--into #vid
from #t1	a
left join #loans	b on a.[Гуид клиент]=b.[Гуид клиент]  and b.[Заем выдан]>a.[Заем выдан] and b.isInstallment=a.isInstallment  and b.Номер<>a.Номер


;with v  as (select *, row_number() over(partition by Номер order by case when [Заем выдан] is not null then 1 end desc,  [Заем выдан] ) rn from #next_search ) delete from v where rn>1





drop table if exists  #docr_search

select a.Номер,a.[Заем выдан],   b.Номер	 НомерДокр	, b.[Заем выдан] [Заем выдан Докр]
into #docr_search 
from #t1	a
left join #loans	b on a.Телефон=b.Телефон and b.[Заем выдан]<=a.[Верификация КЦ] and isnull(b.[Заем погашен], getdate()+1) >=a.[Верификация КЦ] and  b.isInstallment=a.isInstallment
  
union all
 
select a.Номер,a.[Заем выдан],   b.Номер	 НомерДокр , b.[Заем выдан] [Заем выдан Докр]
from #t1	a
left join #loans	b on a.[Гуид клиент]=b.[Гуид клиент] and b.[Заем выдан]<=a.[Верификация КЦ] and isnull(b.[Заем погашен], getdate()+1) >=a.[Верификация КЦ] and  b.isInstallment=a.isInstallment
 
  ;
with v as (
select *, row_number() over(partition by  Номер, НомерДокр order by (select 1) ) rn   from #docr_search	) 

delete from v where rn>1



drop table if exists  #docr
select * 
into 	#docr

from ( 
select distinct Номер, count(НомерДокр) over(partition by Номер ) [Кол-во открытых займов], 
FIRST_VALUE(НомерДокр) over(partition by Номер order by case when НомерДокр is not null then 1 end desc, [Заем выдан Докр] ) fv

from #docr_search 

	 ) x
	 where 	[Кол-во открытых займов]>0
		  --select * from #docr

		  

--select * from #docr_search
--where Номер ='19020523470001'
--
--select * from #loans			  
--where Номер ='19020523470001'
--
--select * from #t1
--where Номер ='19020523470001'




drop table if exists  #next_docr

select *
into 	#next_docr
from (

select distinct НомерДокр , 
FIRST_VALUE(Номер) over(partition by НомерДокр order by case when Номер is not null then 1 end desc, [Заем выдан] desc ) fv

from #docr_search 
where НомерДокр is not null		   and 	   [Заем выдан] is  not null
) x						


--select * from #next_docr



--select * from #next_docr
--where НомерДокр='19020523470001'

drop table if exists #t2

select a.Номер,
a.[Заем выдан],  
a.[Заем погашен],  
a.isInstallment,  
a.isPdl,  
a.Телефон,  
case 
when d.Номер is not null then 'Докредитование' 
when p.Номер is not null then 'Повторный' 
else 'Первичный' end [Вид займа в рамках продукта]
, d.fv docred_parent_product													   
, d.[Кол-во открытых займов] [Кол-во открытых займов в рамках продукта]													   
, ns.[Заем выдан] [Дата следующего займа в рамках продукта]		
, ns.НомерСлед next_product
, np.fv next_povt_product
, nd.fv next_docr_product
, p.fv 	  povt_parent_product
, 
p.[Кол-во закрытых займов] [Кол-во закрытых займов в рамках продукта] 
, isnull(a.[Заем выдан], a.[Верификация КЦ])    Отчетная_Дата
, 1 [Признак заявки]
, case when  a.[Предварительное одобрение]   is not null then 1 else 0 end [Признак Предварительное одобрение]
, case when  a.[Контроль данных]   is not null then 1 else 0 end [Признак Контроль данных]
, case when  a.[заем выдан]   is not null then 1 else 0 end [Признак заем выдан]
, [Выданная сумма] [Выданная сумма]
, a.[Срок займа] Срок


into #t2

from #t1 a
left join #docr d on a.Номер=d.Номер
left join #povt p on a.Номер=p.Номер
left join #next_search ns on ns.Номер=a.Номер
left join #next_povt np on np.НомерПовт=a.Номер
left join #next_docr nd on nd.НомерДокр=a.Номер
where cast(isnull(a.[Заем выдан], a.[Верификация КЦ]) as date) < cast( getdate() as date)


--select * from 	 #t2
--where телефон='9513418830'
--order by Отчетная_Дата

--select * from 	 #t2
				-- dm_return_types
drop table if exists  return_types
select * into  return_types from #t2
delete from return_types
insert into  return_types
select * from #t2


   


--select * from  return_types
--where Номер='19011023470001'


--select * from 	return_types a
--left join 	  #t2 b on a.Номер=b.Номер
--where a.[Кол-во закрытых займов в рамках продукта]=b.[Кол-во закрытых займов в рамках продукта]

		  --select * from #docr
		  --select * from return_types
		  --order by 1 desc

end
