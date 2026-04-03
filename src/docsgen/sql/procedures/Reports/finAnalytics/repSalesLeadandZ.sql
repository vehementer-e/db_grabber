

CREATE PROCEDURE [finAnalytics].[repSalesLeadandZ]
    @monthFrom date,
    @monthTo date,
	@selector int

AS
BEGIN

declare @dtFrom datetime =cast(@monthFrom as datetime)
declare @dtToTmp datetime =dateadd(dd,1, EOMONTH(@monthTo))
declare @dtTo datetime =dateadd(SECOND,-1, @dtToTmp)
--select @dtFrom,@dtTo

/*Загрузка данных по Лидам*/

declare @partitionFrom int =  stg.$Partition.[pfn_range_right_date_part__crib2_lead](@dtFrom)
    ,@partitionTo int =stg.$Partition.[pfn_range_right_date_part__crib2_lead](@dtTo)
--select @partitionFrom, @partitionTo

drop table if exists #lead

select
l1.[lDateCreate]
,[productType] = isnull(l1.[zproductType],l1.[productType])
,[lead_channel_group]

into #lead

from(
select

  [lDateCreate] = cast(a.created as date)
 ,[productType] = case 
					when a.product in ('ПТС') then 'ПТС'
					when a.product in ('ВсёПро100') then 'Installment'
					when a.product in ('Автокредит') then 'Автокредит'
					when a.product in ('PDL') then 'PDL'
					else '-' end
 ,[zproductType] = b.productType
 ,[leadUID] = a.id
 ,[zUID] = a.requestGuid
 ,[partner_name] = a.source
 ,[creator_name] = null
 ,[lead_channelz] = a.channel
 ,[lead_channel] = null
 ,[lead_channel_group] =  b.[Группа каналов]

 
from analytics.dbo._lead_request a   ---select * from analytics.dbo._lead_request
left join (
	select
		original_lead_id
		,productType = case when productType = 'PTS' then 'ПТС'
							when productType = 'INST' then 'Installment'
							when productType = 'PDL' then 'PDL'
						else null end
		,[Группа каналов]
	from [Analytics].dbo.[v_fa]) b on b.original_lead_id=a.id   --select * from [Analytics].dbo.[v_fa]
--left join stg._lf.lead l on a.id=l.id
--left join Stg._lf.mms_channel ch on l.mms_channel_id = ch.id
--left join Stg._lf.mms_channel_group chg on l.mms_channel_group_id = chg.id


where a.created between @dtFrom and @dtTo
and a.isdubl is NULL
) l1



drop table if exists #l
select 
[zType] = 'Лиды за отчётный период'
,[rowNum] = 1
,productType
,channel_group = isnull(lead_channel_group,'Канал не определен')
,[zCount] = count(*)

into #l

from #lead 
where lead_channel_group is not NULL
group by 
productType
,isnull(lead_channel_group,'Канал не определен')


--select * from  #l

/*Загрузка данных по Заявкам*/

drop table if exists #z
create table #z(
	[zType] nvarchar(200) not null
	,[rowNum] int not null
	,[productType] nvarchar(100) not null
	,[z_channel_group] nvarchar(100) null
	,[zCount] int null
)

insert into #z
select
[zType]
,[rowNum] = 2
,productType = [prodName]
,z_channel_group = lead_channel_group
,[zCount] = count(*)
from (
select
[zCreateDate] = l1.[Заявка получена]
,[prodName] = l1.[Продукт]
,[lead_channel_group] = isnull(l1.[Группа каналов],'Канал не определен')
,[zType] = 'Заявки полученные в отчётном периоде'
from(
select

[Заявка получена] = cast(a.call1 as date) --заявка получена
,[Заявка одобрена] = cast(a.approved as date)  --одобрили
,[Заявка отказана] = cast(a.declined as date) --отказали

,[Продукт] = case 
					when a.productType = 'PDL' then 'PDL'
					when a.productType = 'PTS' then 'ПТС'
					when a.productType = 'INST' then 'Installment'
					when a.productType = 'AUTOCREDIT' then 'Автокредит'
			else '-' end
,[Группа каналов]
from [Analytics].dbo.[v_fa] a
where cast(call1 as date) between @monthFrom and EOMONTH(@monthTo)
and Дубль = 0
) l1
) l2
where lead_channel_group !='Канал не определен'
group by
zType
,prodName
,lead_channel_group


insert into #z
select
[zType]
,[rowNum] = 3
,productType = [prodName]
,z_channel_group = lead_channel_group
,[zCount] = count(*)
from (
select
[zCreateDate] = l1.[Заявка получена]
,[prodName] = l1.[Продукт]
,[lead_channel_group] = isnull(l1.[Группа каналов],'Канал не определен')
,[zType] = 'Заявки одобренные в отчётном периоде'
from(
select

[Заявка получена] = cast(a.call1 as date) --заявка получена
,[Заявка одобрена] = cast(a.approved as date)  --одобрили
,[Заявка отказана] = cast(a.declined as date) --отказали

,[Продукт] = case 
					when a.productType = 'PDL' then 'PDL'
					when a.productType = 'PTS' then 'ПТС'
					when a.productType = 'INST' then 'Installment'
					when a.productType = 'AUTOCREDIT' then 'Автокредит'
			else '-' end
,[Группа каналов]
from [Analytics].dbo.[v_fa] a
where cast(a.approved as date) between @monthFrom and EOMONTH(@monthTo)
and Дубль = 0
) l1
) l2
where lead_channel_group !='Канал не определен'
group by
zType
,prodName
,lead_channel_group



insert into #z
select
[zType]
,[rowNum] = 4
,productType = [prodName]
,z_channel_group = lead_channel_group
,[zCount] = count(*)
from (
select
[zCreateDate] = l1.[Заявка получена]
,[prodName] = l1.[Продукт]
,[lead_channel_group] = isnull(l1.[Группа каналов],'Канал не определен')
,[zType] = 'Заявки выданные в отчётном периоде'
from(
select

[Заявка получена] = cast(a.call1 as date) --заявка получена
,[Заявка одобрена] = cast(a.approved as date)  --одобрили
,[Заявка отказана] = cast(a.declined as date) --отказали
,[Кредит выдан] = cast(a.issued as date) --выдали

,[Продукт] = case 
					when a.productType = 'PDL' then 'PDL'
					when a.productType = 'PTS' then 'ПТС'
					when a.productType = 'INST' then 'Installment'
					when a.productType = 'AUTOCREDIT' then 'Автокредит'
			else '-' end
,[Группа каналов]
from [Analytics].dbo.[v_fa] a
where cast(a.issued as date) between @monthFrom and EOMONTH(@monthTo)
and Дубль = 0
) l1
) l2
where lead_channel_group !='Канал не определен'
group by
zType
,prodName
,lead_channel_group


insert into #z
select
[zType]
,[rowNum] = 5
,productType = [prodName]
,z_channel_group = lead_channel_group
,[zCount] = count(*)
from (
select
[zCreateDate] = l1.[Заявка получена]
,[prodName] = l1.[Продукт]
,[lead_channel_group] = isnull(l1.[Группа каналов],'Канал не определен')
,[zType] = 'Заявки отказанные в отчётном периоде'
from(
select

[Заявка получена] = cast(a.call1 as date) --заявка получена
,[Заявка одобрена] = cast(a.approved as date)  --одобрили
,[Заявка отказана] = cast(a.declined as date) --отказали
,[Кредит выдан] = cast(a.issued as date) --выдали

,[Продукт] = case 
					when a.productType = 'PDL' then 'PDL'
					when a.productType = 'PTS' then 'ПТС'
					when a.productType = 'INST' then 'Installment'
					when a.productType = 'AUTOCREDIT' then 'Автокредит'
			else '-' end
,[Группа каналов]
from [Analytics].dbo.[v_fa] a
where cast(a.declined as date) between @monthFrom and EOMONTH(@monthTo)
and Дубль = 0
) l1
) l2
where lead_channel_group !='Канал не определен'
group by
zType
,prodName
,lead_channel_group

if @selector = 1
begin

--Лиды по каналам
--p1
select 
zType	
,rowNum	
,channel_group	
,zCount = sum(isnull(zCount,0))
from #l
group by
zType	
,rowNum	
,channel_group	

union all

--Лиды всего
--p1 Itog
select 
zType	
,rowNum	
,channel_group = '!ИТОГО'
,zCount = sum(isnull(zCount,0))
from #l
group by
zType	
,rowNum	
--,channel_group	

union all

--Заявки по каналам
--p2
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group

union all

--Заявки всего
--p2 Itog
select 
zType	
,rowNum	
,z_channel_group = '!ИТОГО'
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group

union all
--Конверсии
--Lead Conversion Rate, Коэффициент конверсии лидов (Лиды → Заявки полученные)
--p6
Select
[zType] = 'Lead Conversion Rate, (Лиды > Заявки полученные)'
,rowNum = 6
,a.channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group
) b on a.channel_group = b.z_channel_group and b.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.channel_group	
,b.zCount

--select distinct channel_group from #l
--select distinct z_channel_group from #z
--'Партнеры'

union all
--Конверсии
--Lead Conversion Rate, Коэффициент конверсии лидов (Лиды → Заявки полученные) ИТОГО
--p6 Itog
Select
[zType] = 'Lead Conversion Rate, (Лиды > Заявки полученные)'
,rowNum = 6
,channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
--,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group
) b on /*a.channel_group = b.z_channel_group and*/ b.[zType] = 'Заявки полученные в отчётном периоде'

group by
--a.channel_group	
b.zCount

union all
--Approval Rate (Заявки полученные → Заявки одобренные)
--p7
Select
[zType] = 'Approval Rate (Заявки полученные > Заявки одобренные)'
,rowNum = 7
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and b.[zType] = 'Заявки одобренные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.z_channel_group	
,b.zCount

union all
--Approval Rate (Заявки полученные → Заявки одобренные)
--p7 ITOG
Select
[zType] = 'Approval Rate (Заявки полученные > Заявки одобренные)'
,rowNum = 7
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
--,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group
) b on /*a.z_channel_group = b.z_channel_group and*/ b.[zType] = 'Заявки одобренные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
--a.z_channel_group	
b.zCount


union all
--Take Rate (Заявки одобренные → Займы выданные)
--p8
Select
[zType] = 'Take Rate (Заявки одобренные > Займы выданные)'
,rowNum = 8
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.z_channel_group	
,b.zCount

union all
--Take Rate (Заявки одобренные → Займы выданные)
--p8 ITOG
Select
[zType] = 'Take Rate (Заявки одобренные > Займы выданные)'
,rowNum = 8
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
--,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group
) b on /*a.z_channel_group = b.z_channel_group and*/ b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
--a.z_channel_group	
b.zCount

union all
--Лиды в займы (Лиды → Займы выданные)
--p9
Select
[zType] = 'Лиды в займы (Лиды > Займы выданные)'
,rowNum = 9
,a.channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group
) b on a.channel_group = b.z_channel_group and b.[zType] = 'Заявки выданные в отчётном периоде'

--where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.channel_group	
,b.zCount

union all
--Лиды в займы (Лиды → Займы выданные)
--p9 ITOG
Select
[zType] = 'Лиды в займы (Лиды > Займы выданные)'
,rowNum = 9
,channel_group	= '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
--,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group
) b on /*a.channel_group = b.z_channel_group and*/ b.[zType] = 'Заявки выданные в отчётном периоде'

--where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
--a.channel_group	
b.zCount

union all
--Заявки в займы (Заявки полученные → Займы выданные)
--p10
Select
[zType] = 'Заявки в займы (Заявки полученные > Займы выданные)'
,rowNum = 10
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.z_channel_group	
,b.zCount

union all
--Заявки в займы (Заявки полученные → Займы выданные)
--p10 ITOG
Select
[zType] = 'Заявки в займы (Заявки полученные > Займы выданные)'
,rowNum = 10
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
--,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
--,z_channel_group
) b on /*a.z_channel_group = b.z_channel_group and*/ b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
--a.z_channel_group	
b.zCount

end



if @selector = 2
begin

--Лиды по каналам
--p1
select 
zType	
,rowNum	
,productType
,channel_group	
,zCount = sum(isnull(zCount,0))
from #l
group by
zType	
,rowNum	
,productType
,channel_group	

union all

--Лиды всего
--p1 Itog
select 
zType	
,rowNum	
,productType
,channel_group = '!ИТОГО'
,zCount = sum(isnull(zCount,0))
from #l
group by
zType	
,rowNum	
,productType


union all

--Заявки по каналам
--p2
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
,z_channel_group

union all

--Заявки всего
--p2 Itog
select 
zType	
,rowNum	
,productType
,z_channel_group = '!ИТОГО'
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType

union all
--Конверсии
--Lead Conversion Rate, Коэффициент конверсии лидов (Лиды → Заявки полученные)
--p6
select
l1.[zType]
,l1.rowNum
,l1.productType
,l1.channel_group	
,zCount = case when isnull(l1.zCount,0) != 0 then round(cast(isnull(l2.zCount,0) as float) / cast(isnull(l1.zCount,0) as float),3) else 0 end
from(
Select
[zType] = 'Lead Conversion Rate, (Лиды > Заявки полученные)'
,rowNum = 6
,a.productType
,a.channel_group	
,zCount = sum(isnull(a.zCount,0))
from #l a
group by
a.channel_group	
,a.productType
)l1
left join (
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
where [zType] = 'Заявки полученные в отчётном периоде'
group by 
zType	
,rowNum	
,productType
,z_channel_group
) l2 on l1.channel_group = l2.z_channel_group and l1.productType=l2.productType




union all
--Конверсии
--Lead Conversion Rate, Коэффициент конверсии лидов (Лиды → Заявки полученные) ИТОГО
--p6 Itog
Select
[zType] = 'Lead Conversion Rate, (Лиды > Заявки полученные)'
,rowNum = 6
,a.productType
,channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
,productType
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
) b on a.productType = b.productType and b.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.productType
,b.zCount

union all
--Approval Rate (Заявки полученные → Заявки одобренные)
--p7
Select
[zType] = 'Approval Rate (Заявки полученные > Заявки одобренные)'
,rowNum = 7
,a.productType
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and a.productType = b.productType and b.[zType] = 'Заявки одобренные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.z_channel_group
,a.productType
,b.zCount

union all
--Approval Rate (Заявки полученные → Заявки одобренные)
--p7 ITOG
Select
[zType] = 'Approval Rate (Заявки полученные > Заявки одобренные)'
,rowNum = 7
,a.productType
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
) b on a.productType = b.productType and b.[zType] = 'Заявки одобренные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.productType
,b.zCount


union all
--Take Rate (Заявки одобренные → Займы выданные)
--p8
Select
[zType] = 'Take Rate (Заявки одобренные > Займы выданные)'
,rowNum = 8
,a.productType
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.z_channel_group	
,a.productType
,b.zCount

union all
--Take Rate (Заявки одобренные → Займы выданные)
--p8 ITOG
Select
[zType] = 'Take Rate (Заявки одобренные > Займы выданные)'
,rowNum = 8
,a.productType
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
) b on a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.productType
,b.zCount

union all
--Лиды в займы (Лиды → Займы выданные)
--p9
Select
[zType] = 'Лиды в займы (Лиды > Займы выданные)'
,rowNum = 9
,a.productType
,a.channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
,z_channel_group
) b on a.channel_group = b.z_channel_group and a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

--where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.channel_group	
,a.productType
,b.zCount

union all
--Лиды в займы (Лиды → Займы выданные)
--p9 ITOG
Select
[zType] = 'Лиды в займы (Лиды > Займы выданные)'
,rowNum = 9
,a.productType
,channel_group	= '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #l a
left join (
select 
zType	
,rowNum	
,productType
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
) b on a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

--where a.[zType] = 'Заявки одобренные в отчётном периоде'

group by
a.productType
,b.zCount

union all
--Заявки в займы (Заявки полученные → Займы выданные)
--p10
Select
[zType] = 'Заявки в займы (Заявки полученные > Займы выданные)'
,rowNum = 10
,a.productType
,a.z_channel_group	
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,z_channel_group	
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
,z_channel_group
) b on a.z_channel_group = b.z_channel_group and a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.z_channel_group	
,a.productType
,b.zCount

union all
--Заявки в займы (Заявки полученные → Займы выданные)
--p10 ITOG
Select
[zType] = 'Заявки в займы (Заявки полученные > Займы выданные)'
,rowNum = 10
,a.productType
,z_channel_group = '!ИТОГО'
,zCount = case when sum(isnull(a.zCount,0)) != 0 then round(cast(isnull(b.zCount,0) as float) / cast(sum(isnull(a.zCount,0)) as float),3) else 0 end
from #z a
left join (
select 
zType	
,rowNum	
,productType
,zCount = sum(isnull(zCount,0))

from #z
group by 
zType	
,rowNum	
,productType
) b on a.productType = b.productType and b.[zType] = 'Заявки выданные в отчётном периоде'

where a.[zType] = 'Заявки полученные в отчётном периоде'

group by
a.productType
,b.zCount

end


END
