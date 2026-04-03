-- exec [dbo].[report_dashboard_001_CC] 
CREATE  PROCEDURE [dbo].[report_CreditPortf_Delta_MfoSpaceCMR] 

@pageNo int

AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

if @pageNo =1

with 
CredPortf_cmr0 as
(
select [ДатаОбновленияЗаписи]
      ,[ПериодУчета]
      ,[ДатаОперации]
      ,[ДоговорНомер] as [ДоговорНомер_cmr]
      ,[ДатаВыдачиДоговора]
      ,[СуммаДоговора] as [СуммаДоговора_cmr]
      --,[СуммаДопПродуктов]
      --,[СуммаБезДопУслуг]
      ,isnull([СуммаОДОплачено],0) as [СуммаОДОплачено_cmr]
      ,[ОстатокОД] as [ОстатокОД_cmr]
      ,[Колво] as [Колво_cmr]
	  ,[КолвоПолнДнПроср] as [КолвоПолнДнПроср_cmr]
	  ,[НаименованиеПараметра] 
	  ,case
			when [НаименованиеПараметра] = N'Непросроченный' then N'без просрочки'
			when [НаименованиеПараметра] in (N'_1-3' ,N'_4-30' ,N'31-60' ,N'61-90') then N'просрочка 1-90 дней' --N'd' -- N'61-90' --
			when [НаименованиеПараметра] in (N'91-120' ,N'121-150' ,N'151-180' ,N'181-210' ,N'211-240' ,N'241-270' ,N'271-300' ,N'301-330' ,N'331-360') then N'просрочка 90+ дней'
			when [НаименованиеПараметра] in (N'361-390' ,N'391-420' ,N'421-450' ,N'451-480' ,N'481-510' ,N'511-540' ,N'541-570' ,N'571-600' ,N'601-630' ,N'631-660' ,N'661-690' ,N'691-720' ,N'Более 720') then N'просрочка 360+ дней'
		end as [Бакет_cmr]

	  ,[СтатусНаим] as [СтатусНаим_cmr]
      ,[ИсточникДанных] as [CMR]

from [dwh_new].[dbo].[mt_credit_portfolio_cmr]
where [ДатаОбновленияЗаписи]=dateadd(day,datediff(day,0,Getdate()),0)
)

,	CredPortf_Space00 as	
(
select * 
from (
		select cp.[Id] ,[Number] ,[Date] ,[Sum] ,[Term]
			  ,[ProductType] ,[StageId] ,[LastPaymentDate] ,[LastPaymentSum] ,[CurrentAmountOwed] ,[DebtSum]
			  ,[CreditAgencyStatus] ,[CreditAgencyName] ,[IdStatus] 
			  ,case when st.[Name] is null and [OverdueDays] is null and ([Fulldebt]=0 or [Fulldebt] is null) then N'Действует' else st.[Name] end as [СтатусНаим] 
			  ,[IdCustomer] 
			  ,case when [OverdueDays] is null then 0 else [OverdueDays] end as [КолвоПолнДнПроср_spc]
			  ,case
					when isnull([OverdueDays],0)=0 then N'без просрочки'
					when isnull([OverdueDays],0)>0 and isnull([OverdueDays],0)<91 then N'просрочка 1-90 дней' --N'd' -- N'61-90' --
					when isnull([OverdueDays],0)>90 and isnull([OverdueDays],0)<361 then N'просрочка 90+ дней'
					when isnull([OverdueDays],0)>360 then N'просрочка 360+ дней'
			  end as [Бакет_spc]
			  --,case when [OverdueDays]=0 or [OverdueDays] is null then 0 else ([OverdueDays]-1) end as [OverdueDays]
			  ,[PlaceOfContract] ,[RequestDate] ,[RequestNumber] ,[Phone] ,[CmrCustomerId] ,[CmrId] ,[InterestRate]
			  ,[CmrRequestId] ,[CmrPublishDate] ,[OverdueStartDate] ,[Fulldebt]
			  ,rank() over(partition by [Number] order by [CmrPublishDate] desc) as [rank_num] 
		from [Stg].[_Collection].[Deals] cp with (nolock) --[C1-VSR-SQL05].[collection_NIGHT00].[dbo].[Deals] cp
			left join [Stg].[_Collection].[DealStatus] st with (nolock) on cp.[IdStatus]=st.[Id] -- [C1-VSR-SQL05].[collection_NIGHT00].[dbo].[DealStatus] st	on cp.[IdStatus]=st.[Id]
	) cps
where cps.[rank_num]=1 --dateadd(day,datediff(day,0,[CmrPublishDate]),0)=dateadd(day,datediff(day,0,dateadd(day,-1,getdate())),0)
--order by [CmrPublishDate] desc
)

,	CredPortf_Space0 as
(
select	[Number] as [ДоговорНомер_spc]
		,[Sum] as [СуммаДоговора_spc]
		,[Sum]-[DebtSum] as [СуммаОДОплачено_spc]
		--,[CurrentAmountOwed]
		,[DebtSum] as [ОстатокОД_spc]
		,[Fulldebt] as [ПолнЗадолж_spc]
		,1 as [Колво_spc]
		,[КолвоПолнДнПроср_spc]
		,[Бакет_spc]
		,[СтатусНаим] as [СтатусНаим_spc]
		,N'Space' as [Spc]
from CredPortf_Space00
where not [СтатусНаим] in (N'Аннулирован' ,N'Погашен' ,N'Продан' ,N'Зарегистрирован')
)
--select * from CredPortf_Space0
,	CredPortf_MFO0 as
(
select [ДатаОбновленияЗаписи]
      ,[ПериодУчета]
      ,[ДатаОперации]
      ,[ДоговорНомер] as [ДоговорНомер_мфо]
      ,[ДатаВыдачиДоговора]
      ,[СуммаДоговора] as [СуммаДоговора_мфо]
      --,[СуммаДопПродуктов]
      --,[СуммаБезДопУслуг]
      ,isnull([СуммаОДОплачено],0) as [СуммаОДОплачено_мфо]
      ,[ОстатокОД] as [ОстатокОД_мфо]
      ,[Колво] as [Колво_мфо]
	  ,[КолвоПолнДнПроср] as [КолвоПолнДнПроср_мфо]
	  ,[НаименованиеПараметра] 
	  ,case
			when [НаименованиеПараметра] = N'Непросроченный' then N'без просрочки'
			when [НаименованиеПараметра] in (N'_1-3' ,N'_4-30' ,N'31-60' ,N'61-90') then N'просрочка 1-90 дней' --N'd' -- N'61-90' --
			when [НаименованиеПараметра] in (N'91-120' ,N'121-150' ,N'151-180' ,N'181-210' ,N'211-240' ,N'241-270' ,N'271-300' ,N'301-330' ,N'331-360') then N'просрочка 90+ дней'
			when [НаименованиеПараметра] in (N'361-390' ,N'391-420' ,N'421-450' ,N'451-480' ,N'481-510' ,N'511-540' ,N'541-570' ,N'571-600' ,N'601-630' ,N'631-660' ,N'661-690' ,N'691-720' ,N'Более 720') then N'просрочка 360+ дней'
		end as [Бакет_мфо]

	  ,[СтатусНаим] as [СтатусНаим_мфо]
      ,[ИсточникДанных] as [MFO]

from [dwh_new].[dbo].[mt_credit_portfolio_mfo]
where [ДатаОбновленияЗаписи]=dateadd(day,datediff(day,0,Getdate()),0)
--order by [ДатаОбновленияЗаписи] desc
)
,	sum_CMR_MFO_Space as
(select [CMR] as [DB]
	,sum(isnull([ОстатокОД_cmr],0)) as [ОстатокОД_cmr],0 as [ОстатокОД_мфо] ,0 as [ОстатокОД_spc] 
	,sum(isnull([Колво_cmr],0)) as [Колво_cmr] ,0 as [Колво_мфо] ,0 as [Колво_spc]
	,N'Портфель всего, в .ч' as [Показатель] ,N'Активные займы всего, в т.ч.' as [Показатель2]
from CredPortf_cmr0
group by [CMR]
union all
select [MFO] as [DB]
	,0 as [ОстатокОД_cmr],sum(isnull([ОстатокОД_мфо],0)) as [ОстатокОД_мфо] ,0 as [ОстатокОД_spc] 
	,0 as [Колво_cmr] ,sum(isnull([Колво_мфо],0)) as [Колво_мфо] ,0 as [Колво_spc] 
	,N'Портфель всего, в .ч' as [Показатель] ,N'Активные займы всего, в т.ч.' as [Показатель2]
from CredPortf_MFO0
where [MFO]=N'МФО'
group by [MFO]
union all
select [Spc] as [DB]
	,0 as [ОстатокОД_cmr],0 as [ОстатокОД_мфо] ,sum(isnull([ОстатокОД_spc],0)) as [ОстатокОД_spc] 
	,0 as [Колво_cmr] ,0 as [Колво_мфо],sum(isnull([Колво_spc],0)) as [Колво_spc]
	,N'Портфель всего, в .ч' as [Показатель] 
	,N'Активные займы всего, в т.ч.' as [Показатель2]
from CredPortf_Space0
group by [Spc]
)
,	sum_CMR_MFO_Space_baket as
(select [CMR] as [DB]
	,sum(isnull([ОстатокОД_cmr],0)) as [ОстатокОД_cmr],0 as [ОстатокОД_мфо] ,0 as [ОстатокОД_spc] 
	,sum(isnull([Колво_cmr],0)) as [Колво_cmr] ,0 as [Колво_мфо] ,0 as [Колво_spc]
	,[Бакет_cmr] as [Показатель] 
	,case 
		when [Бакет_cmr] = N'без просрочки' then N'Активные займы без просрочки'
		when [Бакет_cmr] = N'просрочка 1-90 дней' then N'Активные займы просрочка 1-90 дней' 
		when [Бакет_cmr] = N'просрочка 90+ дней' then N'Активные займы просрочка 90+ дней'  
		when [Бакет_cmr] = N'просрочка 360+ дней' then N'Активные займы просрочка 360+ дней'
	end as [Показатель2]
from CredPortf_cmr0
group by [CMR] ,[Бакет_cmr]
union all
select [MFO] as [DB]
	,0 as [ОстатокОД_cmr],sum(isnull([ОстатокОД_мфо],0)) as [ОстатокОД_мфо] ,0 as [ОстатокОД_spc] 
	,0 as [Колво_cmr] ,sum(isnull([Колво_мфо],0)) as [Колво_мфо] ,0 as [Колво_spc] 
	,[Бакет_мфо] as [Показатель] 
	,case 
		when [Бакет_мфо] = N'без просрочки' then N'Активные займы без просрочки'
		when [Бакет_мфо] = N'просрочка 1-90 дней' then N'Активные займы просрочка 1-90 дней' 
		when [Бакет_мфо] = N'просрочка 90+ дней' then N'Активные займы просрочка 90+ дней'  
		when [Бакет_мфо] = N'просрочка 360+ дней' then N'Активные займы просрочка 360+ дней'
	end as [Показатель2]
from CredPortf_MFO0
where [MFO]=N'МФО'
group by [MFO] ,[Бакет_мфо]
union all
select [Spc] as [DB]
	,0 as [ОстатокОД_cmr],0 as [ОстатокОД_мфо] ,sum(isnull([ОстатокОД_spc],0)) as [ОстатокОД_spc] 
	,0 as [Колво_cmr] ,0 as [Колво_мфо],sum(isnull([Колво_spc],0)) as [Колво_spc]
	,[Бакет_spc] as [Показатель] 
	,case 
		when [Бакет_spc] = N'без просрочки' then N'Активные займы без просрочки'
		when [Бакет_spc] = N'просрочка 1-90 дней' then N'Активные займы просрочка 1-90 дней' 
		when [Бакет_spc] = N'просрочка 90+ дней' then N'Активные займы просрочка 90+ дней'  
		when [Бакет_spc] = N'просрочка 360+ дней' then N'Активные займы просрочка 360+ дней'
	end as [Показатель2]
from CredPortf_Space0
group by [Spc] ,[Бакет_spc]
)
--select * from sum_CMR_MFO_Space union all select * from sum_CMR_MFO_Space_baket
,	CredPortf_res as
(
select 1 as [Порядок] 
	   ,sum([ОстатокОД_cmr]) as [CMR] ,sum([ОстатокОД_мфо]) as [МФО] ,sum([ОстатокОД_spc]) as [Space]
	   --,sum([Колво_cmr]) as [Колво_cmr] ,sum([Колво_мфо]) as [Колво_мфо],sum([Колво_spc]) as [Колво_spc]
	   ,[Показатель] as [Показатель]
from sum_CMR_MFO_Space 
group by [Показатель]
union all 
select
	   case 
			when [Показатель]=N'без просрочки' then 2 
			when [Показатель]=N'просрочка 1-90 дней' then 3 
			when [Показатель]=N'просрочка 90+ дней' then 4 
			when [Показатель]=N'просрочка 360+ дней' then 5 
	   end as [Порядок]
	   ,sum([ОстатокОД_cmr]) as [CMR] ,sum([ОстатокОД_мфо]) as [МФО] ,sum([ОстатокОД_spc]) as [Space]
	   --,sum([Колво_cmr]) as [Колво_cmr] ,sum([Колво_мфо]) as [Колво_мфо],sum([Колво_spc]) as [Колво_spc]
	   ,[Показатель] as [Показатель] 
from sum_CMR_MFO_Space_baket
group by [Показатель]
union all 
select 6 as [Порядок] 
	   --,sum([ОстатокОД_cmr]) as [ЦМР] ,sum([ОстатокОД_мфо]) as [МФО] ,sum([ОстатокОД_spc]) as [Space]
	   ,sum([Колво_cmr]) as [CMR] ,sum([Колво_мфо]) as [МФО] ,sum([Колво_spc]) as [Space]
	   ,[Показатель2] as [Показатель]
from sum_CMR_MFO_Space 
group by [Показатель2]
union all 
select
	   case 
			when [Показатель2]=N'Активные займы без просрочки' then 7 
			when [Показатель2]=N'Активные займы просрочка 1-90 дней' then 8 
			when [Показатель2]=N'Активные займы просрочка 90+ дней' then 9 
			when [Показатель2]=N'Активные займы просрочка 360+ дней' then 10 
	   end as [Порядок]
	   --,sum([ОстатокОД_cmr]) as [ЦМР] ,sum([ОстатокОД_мфо]) as [МФО] ,sum([ОстатокОД_spc]) as [Space]
	   ,sum([Колво_cmr]) as [CMR] ,sum([Колво_мфо]) as [МФО],sum([Колво_spc]) as [Space]
	   ,[Показатель2] as [Показатель] 
from sum_CMR_MFO_Space_baket
where [Показатель2]<>N'Активные займы всего, в т.ч.'
group by [Показатель2]
)
select [Показатель] ,[Порядок] as [Строка] ,[CMR] ,[МФО] ,[Space] 
	   ,(isnull([МФО],0)-isnull([CMR],0)) as [Дельта_MFO_CMR]
	   ,(isnull([Space],0)-isnull([МФО],0)) as [Дельта_Space_MFO] 
	   ,(isnull([Space],0)-isnull([CMR],0)) as [Дельта_Space_CMR]
from CredPortf_res
order by [Порядок]
--select * from CredPortf_res order by [Строка] asc

--------------------------------------------------------
---------- ЧАСТЬ 2
if @pageNo =2

with 
 	CredPortf_CMR0 as
(
select [ДатаОбновленияЗаписи]
      ,[ПериодУчета]
      ,[ДатаОперации]
      ,[ДоговорНомер] as [ДоговорНомер_cmr]
      ,[ДатаВыдачиДоговора]
      ,[СуммаДоговора] as [СуммаДоговора_cmr]
      --,[СуммаДопПродуктов]
      --,[СуммаБезДопУслуг]
      ,isnull([СуммаОДОплачено],0) as [СуммаОДОплачено_cmr]
      ,[ОстатокОД] as [ОстатокОД_cmr]
      ,[Колво] as [Колво_cmr]
	  ,[КолвоПолнДнПроср] as [КолвоПолнДнПроср_cmr]
	  ,[НаименованиеПараметра] as [Бакет_cmr]
	  ,[СтатусНаим] as [СтатусНаим_cmr]
      ,[ИсточникДанных] as [CMR]

from [dwh_new].[dbo].[mt_credit_portfolio_cmr]
where [ДатаОбновленияЗаписи]=dateadd(day,datediff(day,0,Getdate()),0)
)
,	CredPortf_Space0 as	
(
select * 
from (
		select cp.[Id] ,[Number] ,[Date] ,[Sum] ,[Term]
			  ,[ProductType] ,[StageId] ,[LastPaymentDate] ,[LastPaymentSum] ,[CurrentAmountOwed] ,[DebtSum]
			  ,[CreditAgencyStatus] ,[CreditAgencyName] ,[IdStatus] 
			  ,case when st.[Name] is null and [OverdueDays] is null and ([Fulldebt]=0 or [Fulldebt] is null) then N'Действует' else st.[Name] end as [СтатусНаим] 
			  ,[IdCustomer] 
			  ,case when [OverdueDays] is null then 0 else [OverdueDays] end as [КолвоПолнДнПроср_spc]
			  ,case when [OverdueDays] is null then 0 else [OverdueDays] end as [OverdueDays]
			  --,case
					--when isnull([OverdueDays],0)=0 then N'без просрочки'
					--when isnull([OverdueDays],0)>0 and isnull([OverdueDays],0)<91 then N'просрочка 1-90 дней' --N'd' -- N'61-90' --
					--when isnull([OverdueDays],0)>90 and isnull([OverdueDays],0)<361 then N'просрочка 90+ дней'
					--when isnull([OverdueDays],0)>360 then N'просрочка 360+ дней'
			  --end as [Бакет_spc]
			  --,case when [OverdueDays]=0 or [OverdueDays] is null then 0 else ([OverdueDays]-1) end as [OverdueDays]
			  ,[PlaceOfContract] ,[RequestDate] ,[RequestNumber] ,[Phone] ,[CmrCustomerId] ,[CmrId] ,[InterestRate]
			  ,[CmrRequestId] ,[CmrPublishDate] ,[OverdueStartDate] ,[Fulldebt]
			  ,rank() over(partition by [Number] order by [CmrPublishDate] desc) as [rank_num] 
		from [Stg].[_Collection].[Deals] cp with (nolock) --[C1-VSR-SQL05].[collection_NIGHT00].[dbo].[Deals] cp
			left join [Stg].[_Collection].[DealStatus] st with (nolock) on cp.[IdStatus]=st.[Id] -- [C1-VSR-SQL05].[collection_NIGHT00].[dbo].[DealStatus] st	on cp.[IdStatus]=st.[Id]
	) cps
where cps.[rank_num]=1 --dateadd(day,datediff(day,0,[CmrPublishDate]),0)=dateadd(day,datediff(day,0,dateadd(day,-1,getdate())),0)
--order by [CmrPublishDate] desc
)

,	CredPortf_Space_Baket as
(
select	[Number] as [ДоговорНомер_spc]
		,[Sum] as [СуммаДоговора_spc]
		,[Sum]-[DebtSum] as [СуммаОДОплачено_spc]
		--,[CurrentAmountOwed]
		,[DebtSum] as [ОстатокОД_spc]
		,[Fulldebt] as [ПолнЗадолж_spc]
		,1.00 as [Колво_spc]
		,[OverdueDays] as [КолвоПолнДнПроср_spc]
		,case
			when isnull([OverdueDays],0)=0 then N'Непросроченный'
			when isnull([OverdueDays],0)>0 and isnull([OverdueDays],0)<4 then N'_1-3' --N'a' -- N'_1-3' --
			when isnull([OverdueDays],0)>3 and isnull([OverdueDays],0)<31 then N'_4-30' --N'b' -- N'_4-30' --
			when isnull([OverdueDays],0)>30 and isnull([OverdueDays],0)<61 then N'31-60' --N'c' -- N'31-60' --
			when isnull([OverdueDays],0)>60 and isnull([OverdueDays],0)<91 then N'61-90' --N'd' -- N'61-90' --
			when isnull([OverdueDays],0)>90 and isnull([OverdueDays],0)<121 then N'91-120' --N'f' -- N'91-120' --
			when isnull([OverdueDays],0)>120 and isnull([OverdueDays],0)<151 then N'121-150' --N'g' -- N'121-150' --
			when isnull([OverdueDays],0)>150 and isnull([OverdueDays],0)<181 then N'151-180' --N'h' -- N'151-180' --
			when isnull([OverdueDays],0)>180 and isnull([OverdueDays],0)<211 then N'181-210' --N'' -- N'181-210' --
			when isnull([OverdueDays],0)>210 and isnull([OverdueDays],0)<241 then N'211-240'
			when isnull([OverdueDays],0)>240 and isnull([OverdueDays],0)<271 then N'241-270' --N'' -- N'241-270' --
			when isnull([OverdueDays],0)>270 and isnull([OverdueDays],0)<301 then N'271-300' --
			when isnull([OverdueDays],0)>300 and isnull([OverdueDays],0)<331 then N'301-330' --
			when isnull([OverdueDays],0)>330 and isnull([OverdueDays],0)<361 then N'331-360'
			when isnull([OverdueDays],0)>360 and isnull([OverdueDays],0)<391 then N'361-390'
			when isnull([OverdueDays],0)>390 and isnull([OverdueDays],0)<421 then N'391-420'
			when isnull([OverdueDays],0)>420 and isnull([OverdueDays],0)<451 then N'421-450'
			when isnull([OverdueDays],0)>450 and isnull([OverdueDays],0)<481 then N'451-480'
			when isnull([OverdueDays],0)>480 and isnull([OverdueDays],0)<511 then N'481-510'
			when isnull([OverdueDays],0)>510 and isnull([OverdueDays],0)<541 then N'511-540'
			when isnull([OverdueDays],0)>540 and isnull([OverdueDays],0)<571 then N'541-570'
			when isnull([OverdueDays],0)>570 and isnull([OverdueDays],0)<601 then N'571-600'
			when isnull([OverdueDays],0)>600 and isnull([OverdueDays],0)<631 then N'601-630'
			when isnull([OverdueDays],0)>630 and isnull([OverdueDays],0)<661 then N'631-660'
			when isnull([OverdueDays],0)>660 and isnull([OverdueDays],0)<691 then N'661-690'
			when isnull([OverdueDays],0)>690 and isnull([OverdueDays],0)<721 then N'691-720'
			when isnull([OverdueDays],0)>720 then N'Более 720'
		end as [Бакет_spc]
		,[СтатусНаим] as [СтатусНаим_spc]
		,N'Space' as [Spc]
from CredPortf_Space0
where not [СтатусНаим] in (N'Аннулирован' ,N'Погашен' ,N'Продан')
)
--select * from CredPortf_Space_Baket
,	CredPortf_MFO0 as
(
select [ДатаОбновленияЗаписи]
      ,[ПериодУчета]
      ,[ДатаОперации]
      ,[ДоговорНомер] as [ДоговорНомер_мфо]
      ,[ДатаВыдачиДоговора]
      ,[СуммаДоговора] as [СуммаДоговора_мфо]
      --,[СуммаДопПродуктов]
      --,[СуммаБезДопУслуг]
      ,isnull([СуммаОДОплачено],0) as [СуммаОДОплачено_мфо]
      ,[ОстатокОД] as [ОстатокОД_мфо]
      ,[Колво] as [Колво_мфо]
	  ,[КолвоПолнДнПроср] as [КолвоПолнДнПроср_мфо]
	  ,[НаименованиеПараметра] as [Бакет_мфо]
	  ,[СтатусНаим] as [СтатусНаим_мфо]
      ,[ИсточникДанных] as [MFO]

from [dwh_new].[dbo].[mt_credit_portfolio_mfo]
where [ДатаОбновленияЗаписи]=dateadd(day,datediff(day,0,Getdate()),0)
--order by [ДатаОбновленияЗаписи] desc
)
,	CP_MFO_SPC as
(
select  case when [ДоговорНомер_мфо] is null then [ДоговорНомер_spc] else [ДоговорНомер_мфо] end as [Договор_мфо_spc]
		,[ДоговорНомер_мфо] ,[ДоговорНомер_spc]
		,[СуммаДоговора_мфо] ,[СуммаДоговора_spc] 
		,[СуммаОДОплачено_мфо] ,[СуммаОДОплачено_spc] 
		,[ОстатокОД_мфо] ,[ОстатокОД_spc] 
		,[Колво_мфо] ,[Колво_spc]
		,[КолвоПолнДнПроср_мфо] ,[Бакет_мфо] 
		,[КолвоПолнДнПроср_spc] ,[Бакет_spc] 
		,case 
			when not [Бакет_мфо] is null and [Бакет_spc] is null then [Бакет_мфо]
			when [Бакет_мфо] is null and not [Бакет_spc] is null then [Бакет_spc]
			when [Бакет_мфо] = [Бакет_spc] then [Бакет_мфо]
			else null
		end as [Бакет_свод]
		,[СтатусНаим_мфо] ,[СтатусНаим_spc] 
		,[MFO] ,[Spc]

from CredPortf_MFO0 mf
--inner 
full outer join CredPortf_Space_Baket sp
on  mf.[ДоговорНомер_мфо]=sp.[ДоговорНомер_spc]
)
,	CP_MFO_SPC_CMR as
(
select  case when [Договор_мфо_spc] is null then [ДоговорНомер_cmr] else [Договор_мфо_spc] end as [ДоговорНомер]
		--[Договор_мфо_spc]
		,[ДоговорНомер_мфо] ,[ДоговорНомер_spc] ,[ДоговорНомер_cmr]

		,[СуммаДоговора_мфо] ,[СуммаДоговора_spc] ,[СуммаДоговора_cmr]
		,[СуммаОДОплачено_мфо] ,[СуммаОДОплачено_spc] ,[СуммаОДОплачено_cmr] 
		,[ОстатокОД_мфо] ,[ОстатокОД_spc] ,[ОстатокОД_cmr]
		,[Колво_мфо] ,[Колво_spc] ,[Колво_cmr]
		,[КолвоПолнДнПроср_мфо] ,[Бакет_мфо] 
		,[КолвоПолнДнПроср_spc] ,[Бакет_spc]
		,[КолвоПолнДнПроср_cmr] ,[Бакет_cmr]
		,case 
			when not [Бакет_свод] is null and [Бакет_cmr] is null then [Бакет_свод]
			when [Бакет_свод] is null and not [Бакет_cmr] is null then [Бакет_spc]
			when [Бакет_свод] = [Бакет_cmr] then [Бакет_свод]
			else null
		end as [Бакет_свод2]
		,[СтатусНаим_мфо] ,[СтатусНаим_spc] ,[СтатусНаим_cmr]  
		,[MFO] ,[Spc] ,[CMR]

from CP_MFO_SPC ms
full outer join (select distinct * from CredPortf_cmr0) cm
on ms.[Договор_мфо_spc]=cm.[ДоговорНомер_cmr]
)
select * from CP_MFO_SPC_CMR order by [Бакет_свод2] asc

END

