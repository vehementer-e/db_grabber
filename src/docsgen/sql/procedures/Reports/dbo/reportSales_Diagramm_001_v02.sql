
--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[reportSales_Diagramm_001_v02] 
	-- Add the parameters for the stored procedure here

@PageNo int
, @ReportMetrika nvarchar(20)
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;

declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255), 
		@Metrika nvarchar(20),
		@Param nvarchar(255),
		@MaxValue int
		--, @PageNo int
		--, @ReportMetrika nvarchar(20)
		, @WeekFrom int
		, @WeekTo int
		, @R decimal(38,2)

--declare @Field

--set @PageNo=1;
--set @ReportMetrika = N'Лиды';
set @R=1000000.00;
set @WeekFrom=case when datepart(dw,getdate())=1 then datepart(ww,dateadd(week,-5,getdate())) else datepart(ww,dateadd(week,-4,getdate())) end;
set @WeekTo=case when datepart(dw,getdate())=1 then datepart(ww,dateadd(day,-1,getdate())) else datepart(ww,getdate()) end;
set @ReportMetrika = case 
						when @ReportMetrika = N'Лиды, шт' then N'Лиды'
						when @ReportMetrika = N'Заявки, шт' then N'Заявки'
						when @ReportMetrika = N'Займы, шт' then N'Займы'
						when @ReportMetrika = N'Объем, млн.руб' then N'Объем'
					 end;
set @Metrika = case when @ReportMetrika = N'Объем' then N'Займы' else @ReportMetrika end;	--N'Займы'	--N'Объемы';	--N'Заявки'; --
set @MaxValue = (select (count(distinct [Номер]) + 100) as [maxValue] from [dbo].[dm_Factor_Analysis_001]
																 where datepart(ww,[ДатаЗаявкиПолная]) between @WeekFrom and @WeekTo 
																		and datepart(yyyy,[ДатаЗаявкиПолная])=datepart(yyyy,getdate())
																		and not [Группа каналов] in (N'Тест')) 


if object_id('tempdb.dbo.#SalesDiagramm') is not null drop table #SalesDiagramm

select *
into #SalesDiagramm 
from dwh_new.[dbo].[dashboard_SalesDiagramm001] d with (nolock)
where d.[Неделя] between @WeekFrom and @WeekTo and d.[Метрика]=@ReportMetrika

--select * from #SalesDiagramm


select * 
into #SalesPlan 
from (select tp0.[Год] ,tp0.[Неделя] ,tp0.[Группа] ,tp0.[Метрика] ,sum(tp0.[Колво]) as [Колво] ,sum(tp0.[Сумма]) as [Сумма] 
	  from (select datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] ,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
			from [Stg].[files].[Sales_DailyPlans] where datepart(ww,[Дата]) between @WeekFrom and @WeekTo --and [Метрика]=@Metrika
			) tp0
	  group by tp0.[Год] ,tp0.[Неделя] ,tp0.[Группа] ,tp0.[Метрика]
	  ) tp
left join (
			select t_cw.[Дата] ,t_cw.[Год] ,t_cw.[Неделя] ,t_cw.[Группа] ,t_cw.[Метрика] ,t_cw.[КолвоПланНакопНед] as [КолвоПланТек] ,t_cw.[СуммаПланНакопНед] as [СуммаПланТек] 
			from (
				  select [Дата] ,datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] 
						,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
						,sum([Колво]) over(partition by datepart(ww,[Дата]) ,[Метрика] ,[Группа] order by [Дата] asc) as [КолвоПланНакопНед]
						,sum(isnull([Сумма],0)) over(partition by datepart(ww,[Дата]) ,[Метрика] ,[Группа] order by [Дата] asc) as [СуммаПланНакопНед]
				  from [Stg].[files].[Sales_DailyPlans] 
				  where datepart(ww,[Дата]) = @WeekTo 
						and [Дата] < dateadd(day,datediff(day,0,Getdate()),0) 
						--and [Метрика]=@Metrika
				--order by [Дата] desc ,[Группа] 
				)t_cw
			where cast(t_cw.[Дата] as date) = cast (dateadd(day,-1,getdate()) as date)
		  ) t2_cw
on tp.[Год]=t2_cw.[Год] and tp.[Неделя]=t2_cw.[Неделя] and tp.[Метрика]=t2_cw.[Метрика] and tp.[Группа]=t2_cw.[Группа]




/*

if object_id('tempdb.dbo.#SalesPlan') is not null drop table #SalesPlan

select tp.[Год] ,tp.[Неделя] 
	  ,case when @ReportMetrika = N'Объем' and tp.[Метрика] = N'Займы' then N'Объем' else tp.[Метрика] end as [Метрика]
	  ,tp.[Группа] as [Группа каналов] 
	  ,case when @ReportMetrika = N'Объем' and tp.[Метрика] = N'Займы' then isnull(tp.[Сумма],0)*1.00/@R else tp.[Колво]*1.00 end as [КолвоПланRR] 

	  ,case
			when @ReportMetrika = N'Объем' and tp.[Метрика] = N'Займы' then case when t2_cw.[СуммаПланТек]*1.00 is null then isnull(tp.[Сумма],0)*1.00/@R else t2_cw.[СуммаПланТек]*1.00/@R end
			else case when t2_cw.[КолвоПланТек] is null then tp.[Колво]*1.00 else t2_cw.[КолвоПланТек]*1.00 end
	  end [КолвоПланТек]
	  --,case when t2_cw.[КолвоПланТек] is null then sum(tp.[Колво]) else t2_cw.[КолвоПланТек] end [КолвоПланТек]
	  ,case when t2_cw.[СуммаПланТек] is null then isnull(tp.[Сумма],0)/@R else t2_cw.[СуммаПланТек]/@R end [СуммаПланТек]

into #SalesPlan 

from (select tp0.[Год] ,tp0.[Неделя] ,tp0.[Группа] ,tp0.[Метрика] ,sum(tp0.[Колво]) as [Колво] ,sum(tp0.[Сумма]) as [Сумма] 
	  from (select datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] ,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
			from [Stg].[files].[Sales_DailyPlans] where datepart(ww,[Дата]) between @WeekFrom and @WeekTo --and [Метрика]=@Metrika
			) tp0
	  group by tp0.[Год] ,tp0.[Неделя] ,tp0.[Группа] ,tp0.[Метрика]
	  ) tp
left join (
			select t_cw.[Дата] ,t_cw.[Год] ,t_cw.[Неделя] ,t_cw.[Группа] ,t_cw.[Метрика] ,t_cw.[КолвоПланНакопНед] as [КолвоПланТек] ,t_cw.[СуммаПланНакопНед] as [СуммаПланТек] 
			from (
				  select [Дата] ,datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] 
						,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
						,sum([Колво]) over(partition by datepart(ww,[Дата]) ,[Метрика] ,[Группа] order by [Дата] asc) as [КолвоПланНакопНед]
						,sum(isnull([Сумма],0)) over(partition by datepart(ww,[Дата]) ,[Метрика] ,[Группа] order by [Дата] asc) as [СуммаПланНакопНед]
				  from [Stg].[files].[Sales_DailyPlans] 
				  where datepart(ww,[Дата]) = @WeekTo 
						and [Дата] < dateadd(day,datediff(day,0,Getdate()),0) 
						--and [Метрика]=@Metrika
				--order by [Дата] desc ,[Группа] 
				)t_cw
			where cast(t_cw.[Дата] as date) = cast (dateadd(day,-1,getdate()) as date)
		  ) t2_cw
on tp.[Год]=t2_cw.[Год] and tp.[Неделя]=t2_cw.[Неделя] and tp.[Метрика]=t2_cw.[Метрика] and tp.[Группа]=t2_cw.[Группа]
--group by tp.[Год] ,tp.[Неделя] ,tp.[Метрика] ,tp.[Группа] ,t2_cw.[КолвоПланТек] ,t2_cw.[СуммаПланТек]

--select * from #SalesPlan


--if object_id('tempdb.dbo.#MinMAx') is not null drop table #MinMAx

--select [Метрика]
--	  ,min(s.[КолвоПланRR]) as [КолвоПланRR_Мин]
--	  ,max(s.[КолвоПланRR]) as [КолвоПланRR_Макс]  
--	  --,min(s.[СуммаПланRR]) as [СуммаПланRR_Мин]
--	  --,max(s.[СуммаПланRR]) as [СуммаПланRR_Макс]
--	  --,case when t2_cw.[КолвоПланТек] is null then sum(tp.[Колво]) else t2_cw.[КолвоПланТек] end [КолвоПланТек]
--	  --,case when t2_cw.[СуммаПланТек] is null then sum(isnull(tp.[Сумма],0)) else t2_cw.[СуммаПланТек] end [СуммаПланТек]

--into #MinMAx 

--from (select sum([КолвоПланRR]) as [КолвоПланRR] ,[Метрика] ,[Неделя] from #SalesPlan group by [Метрика] ,[Неделя])  s
--group by [Метрика]


select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   --,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) 
				  end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  


from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) --where [Группа каналов] = N'CPA'
	  ) sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										--and [Группа каналов]=N'CPA'
		   ) sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
--left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
--	on sd.[Метрика]=mmx.[Метрика]

*/

 -------------------------------------------------------
 /*
 -------------------------------------------------------
 ------- для CPA
 --set @PageNo=1

if @PageNo=1

--if @Metrika = N'Займы' --or @Metrika = N'Объемы'
select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) 
				  end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  


from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) where [Группа каналов] = N'CPA') sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										and [Группа каналов]=N'CPA') sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
;
 
 -------------------------------------------------------
 
 -------------------------------------------------------
 ------- для CPC
 
if @PageNo=2

select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  

from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) where [Группа каналов] = N'CPC') sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										and [Группа каналов]=N'CPC') sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
;

 -------------------------------------------------------
 
 -------------------------------------------------------
 ------- для Партнеры // Партнеры
 
if @PageNo=3

select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  

from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) where [Группа каналов] = N'Партнеры') sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										and [Группа каналов]=N'Партнеры') sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
;

 -------------------------------------------------------
 
 -------------------------------------------------------
 ------- для Органика	// Органика
 --set @PageNo=4
 
if @PageNo=4

select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  

from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) where [Группа каналов] = N'Органика') sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										and [Группа каналов]=N'Органика') sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
;

 -------------------------------------------------------
 
 -------------------------------------------------------
 ------- для Прочего	// 
 --set @PageNo=5

if @PageNo=5

select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else sd.[КолвоФакт] end as [Факт]  

from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт] end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock) where [Группа каналов] =N'Другое' --in (N'CPA' ,N'CPC' ,N'Партнеры' ,N'Органика') 
	  ) sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika 
										and  [Группа каналов] =N'Другое' --not [Группа каналов] in (N'CPA' ,N'CPC' ,N'Партнеры' ,N'Органика')
		  ) sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
;

 -------------------------------------------------------
 
 -------------------------------------------------------
 ------- ВСЕГО
 --set @PageNo=6
  
if @PageNo=6

select sd.[Метрика] ,sd.[Год] ,sd.[Неделя] ,sd.[Группа каналов] 
	   --,case when @ReportMetrika=N'Объем' then round(sp.[КолвоПланRR]/@R,0,0) else sp.[КолвоПланRR] end as [КолвоПланRR]
	   --,round(sp.[КолвоПланRR],0,0) as [КолвоПланRR]
	   --,round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as [КолвоПланRR2]  
	   --,sd.[КолвоФакт] 
	   --,sp.[КолвоПланRR]
	   --,sp.[КолвоПланТек]
	   ,round(mmx.[КолвоПланRR_Макс],0,0) as [MaxValue]

	   ,case when @ReportMetrika=N'Объем' then cast(sp.[КолвоПланRR] as decimal(15,1)) else round(sp.[КолвоПланRR],0,0) end as [План]
	   ,case when datepart(dw,getdate())=1 and sd.[Неделя] = datepart(ww,dateadd(week,-1,getdate())) 
				then  case 
						when @ReportMetrika=N'Объем' then  cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
						else round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0)
					  end
			 when datepart(dw,getdate())<>1 and sd.[Неделя] < datepart(ww,dateadd(week,0,getdate())) then 0.00
			 else case when @ReportMetrika=N'Объем' 
						then cast((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]) as decimal(15,1))
					    else cast(round((isnull(sd.[КолвоФакт],0)*isnull(sp.[КолвоПланRR],0)/sp.[КолвоПланТек]),0,0) as numeric(15,0)) end
	   end as [RR]  
	   ,case when @ReportMetrika=N'Объем' then sd.[КолвоФакт] else cast(sd.[КолвоФакт] as numeric(15,0)) end as [Факт]  

from (select [Метрика] ,[Год] ,[Неделя] ,[Группа каналов] ,case when @ReportMetrika=N'Объем' then [КолвоФакт]/@R else [КолвоФакт]*1.00 end as [КолвоФакт] 
		from #SalesDiagramm sd with (nolock)  where [Группа каналов] <> N'Тест' ) sd
left join (select * from #SalesPlan where [Метрика]=@ReportMetrika --@ReportMetrika --@Metrika and [Группа каналов]=N'Другое'
		   ) sp 
	on sd.[Год]=sp.[Год] and sd.[Неделя]=sp.[Неделя] and sd.[Группа каналов]=sp.[Группа каналов] and sd.[Метрика]=sp.[Метрика]
left join (select ([КолвоПланRR_Макс]*1.25) as [КолвоПланRR_Макс] ,[Метрика] from #MinMAx) mmx
	on sd.[Метрика]=mmx.[Метрика]
*/


 END
