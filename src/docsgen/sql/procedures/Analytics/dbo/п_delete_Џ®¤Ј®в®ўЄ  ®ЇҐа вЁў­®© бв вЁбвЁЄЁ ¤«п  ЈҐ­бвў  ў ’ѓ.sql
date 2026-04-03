
create   proc dbo.[Подготовка оперативной статистики для агенства в ТГ]
as 

begin


drop table if exists #ww
drop table if exists #rr
--declare @report_date date = '20221201'
declare @report_date date = getdate()-1
declare @report_month date = cast(format(@report_date, 'yyyy-MM-01') as date)



select cast(Дата as date) Дата
, cast(format(Дата, 'yyyy-MM-01') as date) Месяц, [Займы руб]/(sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0) [weight of day]
into #ww
from  stg.files.contactcenterplans_buffer_stg 


select sum([weight of day]) rr into #rr from #ww
where Месяц=@report_month and Дата<=@report_date



--declare @report_date date = getdate()-1

select 
--  sum([Выданная сумма])/(select * from #rr) [Выданная сумма_rr]  
--, sum([Выданная сумма]) [Выданная сумма]
--, avg([Выданная сумма]) Чек
--, count([Выданная сумма]) Количество
--,
text = 
N'📅 <b>'+format(@report_date, 'dd-MMM') +' </b>'+char(10)
+N'ℹ️ <b>CPC: </b>'+char(10)
+'RR: '+format(isnull(sum([Выданная сумма])/(select * from #rr), 0), '0')+' руб.' +char(10)
+'Сумма: '+format(isnull(sum([Выданная сумма]) , 0), '0')+' руб.'+char(10)
+'Чек: '+format(isnull(avg([Выданная сумма]) , 0), '0')+' руб.'+char(10)
+'Кол-во: '+format(isnull(count([Выданная сумма]), 0), '0')+' шт.'+char(10)

from reports.dbo.dm_factor_analysis_001 
where [Группа каналов] ='CPC' 
and isInstallment=0 and
cast([Заем выдан] as date) <=@report_date  and 
cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_month


end