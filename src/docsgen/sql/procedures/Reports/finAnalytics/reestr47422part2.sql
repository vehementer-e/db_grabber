



CREATE PROC [finAnalytics].[reestr47422part2]
            @repmonth date
AS
BEGIN

drop table if exists #acc474
select
l1.repMonth
,l1.acc2order
,l1.accNum
,l1.subconto2
,l1.dogNum2
,l1.dogRef
,l1.restOUT_BU
,[PBRStatus] = case when b.Client is null then 'Нет в ПБР' else 'ПБР' end
,Client = isnull(b.Client,l1.subconto1)
,isZaemshik = isnull(b.isZaemshik,'-')
,dogStatus = isnull(case when b.repmonth<@repmonth then 'Закрыт' else b.dogStatus end,'-')
,dogSale = b.saleDate
,dogClose = b.CloseDate
,allPros = b.prosDaysTotal
,restAll = b.restAll
,isWorked = case when cl.Client is not null then 'Да' 
                 --when cl.Client is null and b.Client is not null then 'Нет'
                 --else '-' end
                 else 'Нет' end
INTO #acc474

from (
select
a.repMonth
,a.acc2order
,a.accNum
,a.subconto1
,a.subconto2
--,dogNum = trim(substring(a.subconto2,1,PATINDEX('% от %', a.subconto2)))
,dogNum2 = dog.Номер
,dogRef = a.subconto2UID
,restOUT_BU = sum(a.restOUT_BU)
from dwh2.finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog on a.subconto2UID=dog.ДоговорКонтрагента and dog.ПометкаУдаления=0x00

where a.repMonth=@repmonth 
and a.acc2order = '47422'
--and substring(a.subconto2,1,PATINDEX('% от %', a.subconto2)) = '24020121725344'
and abs(a.restOUT_BU)>0
group by 
a.repMonth
,a.acc2order
,a.accNum
,a.subconto1
,a.subconto2
,a.subconto2UID
,dog.Номер
) l1

left join (
select
dogNum
,dogStatus
,Client
,isZaemshik
,saleDate
,CloseDate
,prosDaysTotal
,[restAll] = zadolgOD + zadolgPrc + penyaSum + gosposhlSum
,rn = ROW_NUMBER() over (Partition by dogNum order by repmonth desc)
,repmonth
from dwh2.finAnalytics.PBR_MONTHLY
where REPMONTH<=@repmonth

) b on l1.dogNum2=b.dogNum and b.rn=1

left join (
select distinct 
Client
from dwh2.finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@repmonth
and upper(a.dogStatus)=upper('Действует')
) cl on b.Client=cl.client

where 1=1
and abs(l1.restOUT_BU) > 1
--and upper(b.dogStatus)=upper('Закрыт')

select 
a.accNum
,a.subconto2
,a.dogNum2	
,restOUT_BU	= ABS(a.restOUT_BU)
,a.PBRStatus	
,a.Client	
,a.isZaemshik	
,a.dogStatus	
,a.dogSale	
,a.dogClose	
,a.allPros	
,a.restAll	
,a.isWorked
,clOrder = SUM(abs(a.restOUT_BU)) over (Partition by a.Client)
,isRestsonClosed = case when b.client is not null then 'Да' else 'Нет' end
from #acc474 a

left join (
select
distinct client
from #acc474 
where upper(dogStatus)=upper('Закрыт')
) b on a.client=b.client

where 1=1
--dogNum!=dogNum2
--PBRStatus ='Нет в ПБР'--'ПБР' 
--and dogNum2 is not null
--order by 6

 
END
