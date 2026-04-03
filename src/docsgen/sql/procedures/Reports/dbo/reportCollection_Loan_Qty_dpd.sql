
--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[reportCollection_Loan_Qty_dpd] 
	-- Add the parameters for the stored procedure here

@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255)
		--, @PageNo int 
set @dtFrom = cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date);	--'20190815';   
set @dtTo = cast(getdate() as date)

drop table if exists #struct_table
create table #struct_table (col int null ,title nvarchar(50))
insert into #struct_table
values 
(1 ,'<1'),
(2 ,'1-30'),
(3 ,'31-60'),
(4 ,'61-90'),
(5 ,'91-120'),
(6 ,'121-150'),
(7 ,'151-180'),
(8 ,'181+'),
(9 ,'Общий итог'),
(10 ,'кол-во договоров с DPD>0')


drop table if exists #loan_dpd_startdate
select --distinct
	   [external_id]
	   ,datepart(d,[ContractStartDate]) as [ДеньПлатежа]
	   ,isnull(dpd,0) dpd
	   ,(case
			when isnull(dpd,0)=0 then '<1'
			when isnull(dpd,0) between 1 and 30 then '1-30'
			when isnull(dpd,0) between 31 and 60 then '31-60'
			when isnull(dpd,0) between 61 and 90 then '61-90'
			when isnull(dpd,0) between 91 and 120 then '91-120'
			when isnull(dpd,0) between 121 and 150 then '121-150'
			when isnull(dpd,0) between 151 and 180 then '151-180'
			when isnull(dpd,0) > 180 then '181+'
		end) as dpd_backet
	   ,'Общий итог' as res1
	   ,case when isnull(dpd,0) <> 0 then 'кол-во договоров с DPD>0' else '' end as res2
into #loan_dpd_startdate
from [dbo].[dm_CMRStatBalance_2]
where [d]=cast(dateadd(day,-1,getdate()) as date) and [ContractEndDate] is null

--select * from #loan_dpd_startdate where dpd_backet= '61-90'


drop table if exists #loan_product
select 
		d.[Код] as [external_id]
		,p.[Наименование] as [Кредитный продукт]
into #loan_product --select *
from (select [Код] ,[КредитныйПродукт] from [Stg].[_1cCMR].[Справочник_Договоры] where [Код] in (select external_id from #loan_dpd_startdate)) d
left join [Stg].[_1cCMR].[Справочник_КредитныеПродукты] p on d.[КредитныйПродукт]=p.[Ссылка]


drop table if exists #cred_prod
select 
		p.[Наименование] as [КредитныйПродукт]
		,t.[Представление] as [ТипПродукта]
into #cred_prod
from [Stg].[_1cMFO].[Справочник_ГП_КредитныеПродукты] p 
left join [Stg].[_1cMFO].[Перечисление_ТипыКредитныхПродуктов] t on p.[ТипПродукта]=t.[Ссылка]


drop table if exists #res_tab
select 
		l.[external_id]
	   ,l.[ДеньПлатежа]
	   ,l.dpd
	   ,l.dpd_backet
	   ,l.res1
	   ,l.res2
	   ,p.[Кредитный продукт]
	   ,cp.[ТипПродукта] 
into #res_tab
from #loan_dpd_startdate l 
left join #loan_product p on l.external_id=p.external_id 
left join #cred_prod cp on p.[Кредитный продукт]=cp.[КредитныйПродукт]
where not l.external_id is null and cp.[ТипПродукта] = 'Залог ПТС' 
--select * from #res_tab

drop table if exists #result
select 
	   s.col [numColumn] 
	   ,[ДеньПлатежа] 
	   ,dpd_backet indicator 
	   ,count([external_id]) Qty 
into #result 
from #res_tab r 
left join #struct_table s on r.[dpd_backet]=s.[title] 
group by s.col ,[ДеньПлатежа] ,dpd_backet
-- select * from #res_tab

union all
select 
		s.col [numColumn] 
		,[ДеньПлатежа] 
		,res1  
		,count([external_id]) Qty 
from #res_tab r 
left join #struct_table s on r.[res1]=s.[title] 
group by s.col ,[ДеньПлатежа] ,res1

union all
select 
		s.col [numColumn] 
		,[ДеньПлатежа] 
		,res2  
		,count([external_id]) Qty 
from #res_tab r 
left join #struct_table s on r.[res2]=s.[title]
where res2<>''
group by s.col ,[ДеньПлатежа] ,res2


if @PageNo = 1

select * from #result where not numColumn is null order by 1 ,2

if @PageNo = 2

select 
		[№ договора]						= [external_id]
		,[День по графику]					= [ДеньПлатежа]
		,[Кол-во дней просрочки ЦМР-УМФО]	= dpd 
from #res_tab
 
 END
