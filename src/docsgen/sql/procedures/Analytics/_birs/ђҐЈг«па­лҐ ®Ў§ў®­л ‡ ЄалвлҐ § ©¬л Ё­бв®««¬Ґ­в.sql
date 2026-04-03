

CREATE   proc [_birs].[Регулярные обзвоны Закрытые займы инстоллмент]

@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin

	 -- return
drop table if exists #t1, #zastr, #bl

select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList



declare @start_date date = @start_date_ssrs 
declare @end_date date = @end_date_ssrs

 --declare @start_date date = '20220101' 
 --declare @end_date date = '20230201'
 
drop table if exists #t1

select cast([Заем погашен] as date) [Заем погашен] , a.Телефон, a.Фио, gmt.gmt into #t1
from      reports.dbo.dm_Factor_Analysis  a 
left join #bl bl on bl.UF_PHONE=A.Телефон
left join Analytics.dbo.v_gmt gmt on gmt.region=a.[РегионПроживания]
where cast([Заем погашен] as date) between @start_date and @end_date
	and bl.UF_PHONE is null
	and a.isPts=0

	;

	with v as (

	select *, ROW_NUMBER() over(partition by Телефон order by (select 1 )) rn from #t1


	)

	delete from v where rn>1

	select * from #t1
	
	end