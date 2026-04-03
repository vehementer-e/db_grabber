



CREATE PROC [finAnalytics].[reestr47422]
            @repmonth date
AS
BEGIN

drop table if exists #acc474
select
l1.repMonth
,l1.acc2order
,l1.accNum
,l1.subconto1
,l1.subconto2
,l1.dogNum
,l1.restOUT_BU
,b.Client
,b.isZaemshik
,oborot1Year = isnull(oborot.oborot1Year,0)
,oborot2Year = isnull(oborot.oborot2Year,0)
,oborot3Year = isnull(oborot.oborot3Year,0)

INTO #acc474

from (
select
a.repMonth
,a.acc2order
,a.accNum
,a.subconto1
,a.subconto2
,dogNum = substring(a.subconto2,1,PATINDEX('% от %', a.subconto2))
,restOUT_BU = sum(a.restOUT_BU)
from dwh2.finAnalytics.OSV_MONTHLY a

where a.repMonth=@repmonth and a.acc2order = '47422'
--and substring(a.subconto2,1,PATINDEX('% от %', a.subconto2)) = '24020121725344'
and abs(a.restOUT_BU)>0
group by 
a.repMonth
,a.acc2order
,a.accNum
,a.subconto1
,a.subconto2
) l1

left join dwh2.finAnalytics.PBR_MONTHLY b on l1.repmonth=b.REPMONTH and l1.dogNum=b.dogNum
left join (
select
l1.accNum
,oborot1Year = sum(l1.oborot1Year)
,oborot2Year = sum(l1.oborot2Year)
,oborot3Year = sum(l1.oborot3Year)
from(
select
[accNum] = accKT.Код
,[oborot1Year] = case when dateadd(year,-2000,a.Период) between DATEADD(year,-1,GETDATE()) and GETDATE() then a.Сумма else 0 end 
,[oborot2Year] = case when dateadd(year,-2000,a.Период) between DATEADD(year,-2,GETDATE()) and DATEADD(year,-1,GETDATE()) then a.Сумма else 0 end 
,[oborot3Year] = case when dateadd(year,-2000,a.Период) between DATEADD(year,-3,GETDATE()) and DATEADD(year,-2,GETDATE()) then a.Сумма else 0 end 
--,[oborot1Year] = case when dateadd(year,-2000,a.Период) <= DATEADD(year,-1,GETDATE()) then a.Сумма else 0 end 
--,[oborot2Year] = case when dateadd(year,-2000,a.Период) <= DATEADD(year,-2,GETDATE()) then a.Сумма else 0 end 
--,[oborot3Year] = case when dateadd(year,-2000,a.Период) <= DATEADD(year,-3,GETDATE()) then a.Сумма else 0 end 

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accKT on a.СчетАналитическогоУчетаКт=accKT.Ссылка

where --cast(dateadd(year,-2000,a.Период) as date) between DATEADD(year,-3,eomonth(@repmonth)) and cast(getDate() as date)--eomonth(@repmonth)
a.Период between DATEADD(year,1997,eomonth(@repmonth)) and dateadd(year,2000,cast(getDate() as date))--eomonth(@repmonth)
and a.Активность=01
and Kt.Код ='47422'
--and accKT.Код='47422810000010186973'
) l1

group by l1.accNum
) oborot on l1.accNum=oborot.accNum

where 1=1
--and abs(l1.restOUT_BU) >= 1000
and upper(b.dogStatus)=upper('Закрыт')

--select * from #acc474

drop table if exists #clients
select
l2.client
,isWorked = sum(l2.isWorked)
,isclosed = sum(l2.isclosed)
,dogCount = max (l2.dogCount)

into #clients

from(
select
l1.client
,l1.repmonth
,case when upper(b.dogStatus)=upper('Закрыт') then 1 else 0 end isclosed
,case when upper(b.dogStatus)=upper('Действует') then 1 else 0 end isWorked
,count(*) over (partition by l1.client) dogCount
from (
select 
distinct client, repmonth
from #acc474
--where client='ААСМЕТС МАКСИМ ЭВАЛЬДОВИЧ 28.02.1990'
) l1

left join dwh2.finAnalytics.PBR_MONTHLY b on l1.repmonth=b.REPMONTH and l1.client=b.Client
--where l1.client='ААСМЕТС МАКСИМ ЭВАЛЬДОВИЧ 28.02.1990'
) l2



group by l2.client

--select * from #clients



drop table if exists #clients_group
select 
a.repMonth
,a.acc2order
,a.accNum
,a.client
,a.dogNum
,a.restOUT_BU
,a.isZaemshik
,b.dogCount
,b.isWorked
,b.isclosed
,[clientGroup] = case when b.dogCount=b.isclosed then 'Полностью закрыты'
      when b.dogCount>b.isclosed then 'Есть действующие'
      else 'Не определено'
      end
,a.oborot1Year
,a.oborot2Year
,a.oborot3Year


INTO #clients_group

from #acc474 a
left join #clients b on a.client=b.client
--where a.client = 'АБИЕВА МАРИЯ СЕРГЕЕВНА 29.07.1987'
--select * from #clients_group where client='ААСМЕТС МАКСИМ ЭВАЛЬДОВИЧ 28.02.1990'


select 
a.repMonth
,a.client	
,accNum = case when  b.dogNum = a.dogNum then a.accNum else '' end
,restOUT_BU = case when  b.dogNum = a.dogNum then abs(a.restOUT_BU) else 0 end
,[oborot1Year] = a.oborot1Year
,[oborot2Year] = a.oborot1Year + a.oborot2Year
,[oborot3Year] = a.oborot1Year + a.oborot2Year + a.oborot3Year

,a.dogCount	
,a.isWorked	
,a.isclosed	
,a.clientGroup

,b.dogNum
,b.saleDate
,b.dogStatus
,b.CloseDate
,b.prosDaysTotal
,[restAll] = b.zadolgOD + b.zadolgPrc + b.penyaSum + b.gosposhlSum
,[restOD] = b.zadolgOD 
,[restPRC] = b.zadolgPrc 
,[restPenya] = b.penyaSum
,[restGP] = b.gosposhlSum
,[rest47422Sort] = sum(a.restOUT_BU) over (Partition by a.client)
,dogSort = case when b.dogNum = a.dogNum then 1 else 2 end
,a.isZaemshik
from #clients_group a
left join dwh2.finAnalytics.PBR_MONTHLY b on a.repmonth=b.REPMONTH and a.client=b.Client and a.dognum=b.dogNum

where 1=1
and a.clientGroup='Полностью закрыты'
--and a.client='ААСМЕТС МАКСИМ ЭВАЛЬДОВИЧ 28.02.1990'--'АКСЕНОВ ДЕНИС ДМИТРИЕВИЧ 18.11.1984' --КОМКОВ АНДРЕЙ ВЛАДИМИРОВИЧ 19.02.1980
and a.restOUT_BU is not null

union all


select 
a.repMonth
,a.client	

,accNum = case when b.dogNum = a.dogNum then a.accNum else '' end
,restOUT_BU = case when b.dogNum = a.dogNum then abs(a.restOUT_BU) else 0 end
,[oborot1Year] = case when b.dogNum = a.dogNum then a.oborot1Year else 0 end
,[oborot2Year] = case when b.dogNum = a.dogNum then a.oborot1Year + a.oborot2Year else 0 end
,[oborot3Year] = case when b.dogNum = a.dogNum then a.oborot1Year + a.oborot2Year + a.oborot3Year else 0 end

,a.dogCount	
,a.isWorked	
,a.isclosed	
,a.clientGroup


,b.dogNum
,b.saleDate
,b.dogStatus
,b.CloseDate
,b.prosDaysTotal
,[restAll] = b.zadolgOD + b.zadolgPrc + b.penyaSum + b.gosposhlSum
,[restOD] = b.zadolgOD 
,[restPRC] = b.zadolgPrc 
,[restPenya] = b.penyaSum
,[restGP] = b.gosposhlSum
,[rest47422Sort] = sum(a.restOUT_BU*-1) over (Partition by a.client)
,dogSort = case when b.dogNum = a.dogNum then 1 else 2 end
,a.isZaemshik
from #clients_group a
left join dwh2.finAnalytics.PBR_MONTHLY b on a.repmonth=b.REPMONTH and a.client=b.Client and a.dogNum=b.dogNum

where 1=1
and a.clientGroup='Есть действующие'
--and a.client='АБДУЛЛИН РАНЕЛЬ РИНАТОВИЧ 14.11.1995'
and abs(a.restOUT_BU) > =1000
--select * from #clients_group where client='АБДУЛЛИН РАНЕЛЬ РИНАТОВИЧ 14.11.1995'

union ALL

select
repMonth = @repmonth
,b.client	

,accNum = ''
,restOUT_BU = ''
,[oborot1Year] = 0
,[oborot2Year] = 0
,[oborot3Year] = 0

,dogCount	= 0
,isWorked	= 0
,isclosed	= 0
,clientGroup = 'Есть действующие'

,b.dogNum
,b.saleDate
,b.dogStatus
,b.CloseDate
,b.prosDaysTotal
,[restAll] = b.zadolgOD + b.zadolgPrc + b.penyaSum + b.gosposhlSum
,[restOD] = b.zadolgOD 
,[restPRC] = b.zadolgPrc 
,[restPenya] = b.penyaSum
,[restGP] = b.gosposhlSum
,[rest47422Sort] = 0
,dogSort = 2
,b.isZaemshik
from dwh2.finAnalytics.PBR_MONTHLY b
inner join (select distinct client from #clients_group where clientGroup='Есть действующие' and abs(restOUT_BU) > =1000) b1 on b1.Client=b.Client 

where 1=1
and b.REPMONTH=@repmonth
--and b.client='АВЕДЯН АИШЕН МУХАРРЕМОВНА 07.11.2002'
and b.dogStatus='Действует'
--and b1.restOUT_BU > =1000

 
END
