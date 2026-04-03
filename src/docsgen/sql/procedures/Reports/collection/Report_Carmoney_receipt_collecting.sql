-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Отчет о займах и действующих процентных ставках по данным МФО 

-- =============================================

create   PROCEDURE [collection].[Report_Carmoney_receipt_collecting]
	-- Add the parameters for the stored procedure here

@PageNo int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if object_id('tempdb.dbo.#Tstruct') is not null drop table #Tstruct;
create table #Tstruct(rws int null ,dpd nvarchar(255) null);

insert into #Tstruct (rws ,dpd)
values 	(1 ,'0'),
		(2 ,'Портфель в просрочке'),
		(3 ,'Софт всего') ,(4 ,N'1-3') ,(5 ,N'4-30'),
		(6 ,N'Хард всего'),	(7 ,N'31-60'), (8 ,N'61-90'), (9 ,N'91-120') ,(10 ,N'121-150') ,(11 ,N'151-180') ,(12 ,N'181-210') 
		,(13 ,N'211-240') ,(14 ,N'241-270') ,(15 ,N'271-300') ,(16 ,N'301-330') ,(17 ,N'331-360') ,(18 ,N'360+') ,(19 ,N'ВСЕГО')


drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 


/*
drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2

drop table if exists #hist
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] ,m.[dpd]  
into #hist
from collection.[mt_reciept_period_dpd] m with (nolock)
right join #tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(year,datediff(year,0,Getdate()),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0)

--select * from #hist

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(year,datediff(year,0,Getdate()),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) and not [dpd] in (N'0')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(year,datediff(year,0,Getdate()),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) and [dpd] in (N'1-3' ,N'4-30')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(year,datediff(year,0,Getdate()),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) and not [dpd] in (N'0' ,N'1-3' ,N'4-30')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(year,datediff(year,0,Getdate()),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0)
group by [cdate] ,[Indicator] ,[Факт/План]

--select * from #hist order by 1



drop table if exists #curr

select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join #tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate()

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30')
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate()
group by [cdate] ,[Indicator] ,[Факт/План]
*/

--select * from #curr

-----------------------------------------------------------
-------------------------- N'Платежи по ОД'


if @PageNo = 1

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

,	hist as 
(
--drop table if exists #hist
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,m.[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,m.[dpd]  
--into #hist
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and m.[Indicator] =N'Платежи по ОД'
group by (tr.[tabl]+'_'+tr.[rws]) ,cast(dateadd(month,datediff(month,0,cdate),0) as date) ,m.[Indicator] ,[Факт/План] ,m.[dpd]
--order by 2 desc ,1 
--select distinct
--		cast(dateadd(month,datediff(month,0,cdate),0) as date) 
--from collection.[mt_reciept_period_dpd] tr
--order by 1 desc

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_02' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and not [dpd] in (N'0') and [Indicator] =N'Платежи по ОД'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_03' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and [dpd] in (N'1-3' ,N'4-30') and [Indicator] =N'Платежи по ОД'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_06' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] =N'Платежи по ОД'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select (case when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end) +'_19' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0)
		and [Indicator] =N'Платежи по ОД'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join #tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по ОД'

union all
select N'1_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]
)
,	te as
(
select tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[Сумма] ,[dpd] from hist

union all
select tabl_rows ,dateadd(month,datediff(month,0,dt),0) dt ,[Indicator] ,[Факт/План] ,sum([Сумма]) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dateadd(month,datediff(month,0,dt),0) ,[Indicator] ,[Факт/План] ,[dpd]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по ОД' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te on s.dpd=te.dpd
order by 1


--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te on s.dpd=te.dpd
--order by 1


-----------------------------------------------------------
-------------------------- N'Платежи по процентам'
if @PageNo = 2


with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)
,	hist as
(
--drop table if exists #hist
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,m.[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,m.[dpd]  
--into #hist
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and m.[Indicator] = N'Платежи по процентам'
group by (tr.[tabl]+'_'+tr.[rws]) ,cast(dateadd(month,datediff(month,0,cdate),0) as date) ,m.[Indicator] ,[Факт/План] ,m.[dpd]

union all
select N'2_02' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and not [dpd] in (N'0') and [Indicator] = N'Платежи по процентам'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'2_03' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') and [Indicator] = N'Платежи по процентам'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'2_06' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] = N'Платежи по процентам'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'2_19' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
		and [Indicator] = N'Платежи по процентам'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по процентам'

union all
select N'2_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te2 as
(
select tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[Сумма] ,[dpd] from hist

union all
select tabl_rows ,dateadd(month,datediff(month,0,dt),0) dt ,[Indicator] ,[Факт/План] ,sum([Сумма]) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dateadd(month,datediff(month,0,dt),0) ,[Indicator] ,[Факт/План] ,[dpd]
)

--select * from te2 order by tabl_rows asc

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te2 on s.dpd=te2.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te2 on s.dpd=te2.dpd
----order by rws asc


-----------------------------------------------------------
-------------------------- N'Платежи по пеням'
if @PageNo = 3

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

,	hist as
(
--drop table if exists #hist
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,m.[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,m.[dpd]  
--into #hist
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and m.[Indicator] = N'Платежи по пеням'
group by (tr.[tabl]+'_'+tr.[rws]) ,cast(dateadd(month,datediff(month,0,cdate),0) as date) ,m.[Indicator] ,[Факт/План] ,m.[dpd]

union all
select N'3_02' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'3_03' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0)  
			and [dpd] in (N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'3_06' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0)  
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'3_19' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по пеням'

union all
select N'3_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te3 as
(
select tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[Сумма] ,[dpd] from hist

union all
select tabl_rows ,dateadd(month,datediff(month,0,dt),0) dt ,[Indicator] ,[Факт/План] ,sum([Сумма]) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dateadd(month,datediff(month,0,dt),0) ,[Indicator] ,[Факт/План] ,[dpd]
)

--select rws as tabl_rows ,s.dpd as [dpd] 
--		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt
--		,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
--		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
--		,[Сумма] 
--from #Tstruct s
--left join te2 on s.dpd=te2.dpd
--order by 1

select * from te3 order by 1


-----------------------------------------------------------
-------------------------- N'Платежи ВСЕГО'
if @PageNo = 4

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'4' 
			when [Indicator] =N'Платежи по процентам' then N'4'
			when [Indicator] =N'Платежи по пеням' then N'4'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

,	hist as
(
--drop table if exists #hist
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,m.[Indicator] 
		,[Факт/План] 
		,sum([Value]) [Сумма] 
		,m.[dpd]  
--into #hist
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) --and m.[Indicator] = N'Платежи по пеням'
group by (tr.[tabl]+'_'+tr.[rws]) ,cast(dateadd(month,datediff(month,0,cdate),0) as date) ,m.[Indicator] ,[Факт/План] ,m.[dpd]

union all
select N'4_02' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum(isnull([Value],0)) [Сумма] 
		,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_03' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum(isnull([Value],0)) [Сумма] 
		,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'4_06' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum(isnull([Value],0)) [Сумма] 
		,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]

union all
select N'4_19' as tabl_rows 
		,cast(dateadd(month,datediff(month,0,cdate),0) as date) dt 
		,[Indicator] 
		,[Факт/План] 
		,sum(isnull([Value],0)) [Сумма] 
		,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateadd(year,-1,Getdate())),0)
		and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			 --and [Indicator] = N'Платежи по пеням'
group by cast(dateadd(month,datediff(month,0,cdate),0) as date) ,[Indicator] ,[Факт/План]
)
------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,isnull([Value],0) as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() --and m.[Indicator] = N'Платежи по пеням'

union all
select N'4_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te4 as
(
select tabl_rows ,dt ,[Факт/План] ,[Сумма] ,[dpd] from hist

union all
select tabl_rows ,dateadd(month,datediff(month,0,dt),0) dt ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dateadd(month,datediff(month,0,dt),0) ,[Факт/План] ,[dpd]
)

select tabl_rows ,dt ,N'' as [Indicator] ,[Факт/План] ,[Сумма] ,[dpd] from te4 order by tabl_rows asc


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

---------------------ТЕКУЩИЙ МЕСЯЦ
--select * from #curr


-----------------------------------------------------------
-------------------------- N'Платежи по ОД'

if @PageNo = 5


with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по ОД'

union all
select N'1_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	itog as 
(
select [dpd] 
		,cast(dateadd(day,-1,dateadd(month,datediff(month,0,dateadd(month,1,Getdate())),0)) as date) dt 
		,sum(isnull([Сумма],0)) [Сумма] 
from curr 
group by [dpd]
)

,	te5 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)


select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,Getdate()),0) as date) else dt end as dt
		/*,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt*/
		,case when [Indicator] is null then N'Платежи по ОД' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te5 on s.dpd=te5.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te5 on s.dpd=te5.dpd
--order by 1



-----------------------------------------------------------
-------------------------- N'Платежи по процентам'
if @PageNo = 6

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по процентам'

union all
select N'2_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te6 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,Getdate()),0) as date) else dt end as dt
		/*,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt*/
		,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te6 on s.dpd=te6.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te6 on s.dpd=te6.dpd
--order by 1


-----------------------------------------------------------
-------------------------- N'Платежи по пеням'
if @PageNo = 7

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and m.[Indicator] = N'Платежи по пеням'

union all
select N'3_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te7 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по пеням' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te7 on s.dpd=te7.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] 
--		,case when dt is null then cast(dateadd(day,-1,Getdate()) as date) else dt end as dt
--		,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te7 on s.dpd=te7.dpd 
--order by 1

-----------------------------------------------------------
-------------------------- N'Платежи по ВСЕГО'
if @PageNo = 8

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'' 
			when [Indicator] =N'Платежи по процентам' then N'4'
			when [Indicator] =N'Платежи по пеням' then N'4'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() --and m.[Indicator] = N'Платежи по пеням'

union all
select N'4_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and [dpd] in (N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() and not [dpd] in (N'0' ,N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,Getdate()),0) and cdate <= Getdate() --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te8 as
(
select tabl_rows , dt  ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] --,[Indicator]
from curr 
group by tabl_rows ,dt  ,[Факт/План] ,[dpd]--,[Indicator]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,Getdate()),0) as date) else dt end as dt
		/*,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,Getdate())),0) as date) else dt end as dt*/
		--,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te8 on s.dpd=te8.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Факт/План] ,[Сумма] --,[Indicator] 
--from #Tstruct s
--left join te8 on s.dpd=te8.dpd
--order by 1



-----------------------------------------------------------
-------------------------- N'Платежи по ОД' ПРЕДЫДУЩИЙ МЕСЯЦ

if @PageNo = 50

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) and m.[Indicator] = N'Платежи по ОД'

union all
select N'1_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'1_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [Indicator]  = N'Платежи по ОД'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	itog as 
(
select [dpd] 
		,cast(dateadd(day,-1,dateadd(month,datediff(month,0,Getdate()),0)) as date) dt 
		,sum(isnull([Сумма],0)) [Сумма] 
from curr 
group by [dpd]
)

,	te50 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)


select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,dateadd(month,-1,Getdate()))),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по ОД' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te50 on s.dpd=te50.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te5 on s.dpd=te5.dpd
--order by 1


-----------------------------------------------------------
-------------------------- N'Платежи по процентам' ПРЕДЫДУЩИЙ МЕСЯЦ
if @PageNo = 60

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and m.[Indicator] = N'Платежи по процентам'

union all
select N'2_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'2_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [Indicator]  = N'Платежи по процентам'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te60 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,dateadd(month,-1,Getdate()))),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te60 on s.dpd=te60.dpd
order by 1

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te6 on s.dpd=te6.dpd
--order by 1


-----------------------------------------------------------
-------------------------- N'Платежи по пеням' ПРЕДЫДУЩИЙ МЕСЯЦ
if @PageNo = 70

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'1' 
			when [Indicator] =N'Платежи по процентам' then N'2'
			when [Indicator] =N'Платежи по пеням' then N'3'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

------------------------------------------------------
,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and m.[Indicator] = N'Платежи по пеням'

union all
select N'3_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'3_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te70 as
(
select tabl_rows , dt ,[Indicator] ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] 
from curr 
group by tabl_rows ,dt ,[Indicator] ,[Факт/План] ,[dpd]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,dateadd(month,-1,Getdate()))),0) as date) else dt end as dt
		,case when [Indicator] is null then N'Платежи по пеням' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te70 on s.dpd=te70.dpd
order by 3

--select rws as tabl_rows ,s.dpd as [dpd] 
--		,case when dt is null then cast(dateadd(day,-1,Getdate()) as date) else dt end as dt
--		,[Indicator] ,[Факт/План] ,[Сумма] 
--from #Tstruct s
--left join te7 on s.dpd=te7.dpd 
--order by 1


-----------------------------------------------------------
-------------------------- N'Платежи по ВСЕГО' ПРЕДЫДУШИЙ МЕСЯЦ
if @PageNo = 80

with tabl_rows as
(
--drop table if exists #tabl_rows
select 	[Indicator]
		,case 
			when [Indicator] =N'Платежи по ОД' then N'' 
			when [Indicator] =N'Платежи по процентам' then N'4'
			when [Indicator] =N'Платежи по пеням' then N'4'
		end as [tabl] 
		,[dpd]
		,case 
			when [dpd]=N'0' then N'01'
			when [dpd]=N'1-3' then N'04'
			when [dpd] = N'4-30' then N'05'
			when [dpd] = N'31-60' then N'07'
			when [dpd] = N'61-90' then N'08'
			when [dpd] = N'91-120' then N'09'
			when [dpd] = N'121-150' then N'10'
			when [dpd] = N'151-180' then N'11'
			when [dpd] = N'181-210' then N'12'
			when [dpd] = N'211-240' then N'13'
			when [dpd] = N'241-270' then N'14'
			when [dpd] = N'271-300' then N'15'
			when [dpd] = N'301-330' then N'16'
			when [dpd] = N'331-360' then N'17'
			when [dpd] = N'360+' then N'18'
		end as [rws]
--into #tabl_rows
from collection.[mt_reciept_period_dpd]
group by [Indicator]  ,[dpd] 
--select * from #tabl_rows order by 1,2
)

,	curr as
(
--drop table if exists #curr
select (tr.[tabl]+'_'+tr.[rws]) tabl_rows, cast([cdate] as date) dt ,m.[Indicator] ,[Факт/План] ,[Value] as [Сумма] ,m.[dpd]   
--into #curr
from collection.[mt_reciept_period_dpd] m with (nolock)
right join tabl_rows tr on tr.dpd=m.dpd and tr.Indicator=m.Indicator
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0)  --and m.[Indicator] = N'Платежи по пеням'

union all
select N'4_02' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Портфель в просрочке' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_03' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Софт всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and [dpd] in (N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_06' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'Хард всего' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0) 
			and not [dpd] in (N'0' ,N'1-3' ,N'4-30') --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]

union all
select N'4_19' as tabl_rows 
		,cast([cdate] as date) dt ,[Indicator] ,[Факт/План] ,sum([Value]) [Сумма] ,N'ВСЕГО' as [dpd]  
from collection.[mt_reciept_period_dpd]
where cdate >= dateadd(month,datediff(month,0,dateAdd(month,-1,Getdate())),0) and cdate < dateadd(month,datediff(month,0,Getdate()),0)  --and [Indicator] = N'Платежи по пеням'
group by [cdate] ,[Indicator] ,[Факт/План]
)

,	te80 as
(
select tabl_rows , dt  ,[Факт/План] ,sum(isnull([Сумма],0)) [Сумма] ,[dpd] --,[Indicator]
from curr 
group by tabl_rows ,dt  ,[Факт/План] ,[dpd]--,[Indicator]
)

select rws as tabl_rows ,s.dpd as [dpd] 
		,case when dt is null then cast(dateadd(month,datediff(month,0,dateadd(day,-1,dateadd(month,-1,Getdate()))),0) as date) else dt end as dt
		--,case when [Indicator] is null then N'Платежи по процентам' else [Indicator] end as [Indicator] 
		,case when [Факт/План] is null then N'Факт' else [Факт/План] end as [Факт/План] 
		,[Сумма] 
from #Tstruct s
left join te80 on s.dpd=te80.dpd
order by 3 desc

--select rws as tabl_rows ,s.dpd as [dpd] ,dt ,[Факт/План] ,[Сумма] --,[Indicator] 
--from #Tstruct s
--left join te8 on s.dpd=te8.dpd
--order by 1




END

