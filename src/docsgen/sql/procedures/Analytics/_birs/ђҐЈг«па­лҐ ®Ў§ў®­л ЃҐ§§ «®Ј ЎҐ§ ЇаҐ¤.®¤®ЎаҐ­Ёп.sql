

CREATE   proc [_birs].[Регулярные обзвоны Беззалог без пред.одобрения]

@datefrom date = null,
@dateto date = null

as

begin

		--return

--declare @datefrom as date = '20221201'
--declare @dateto as date = '20221230'

drop table if exists #t1			
				
	select fa.Телефон			
		,fa.ФИО		
		,f.gmt timezone		
		,fa.[Верификация КЦ] ДатаЗаявкиПолная		
				
		into #t1		
	from Reports.dbo.dm_Factor_Analysis_001 fa		
	join Reports.dbo.dm_Factor_Analysis fa1	on fa.Номер = fa1.Номер
	left join [Analytics].[dbo].[v_gmt] f on fa1.[РегионПроживания] = f.region	
	where cast(fa.[Верификация КЦ] as date) between @datefrom and @dateto			
		and fa.[Предварительное одобрение] is null 		
		and fa.isPts = 0
		and fa.ДатаЗаявкиПолная>='20220101'		
		and fa.Телефон not in (select fa1.Телефон 		
			from Reports.dbo.dm_Factor_Analysis_001 fa1	
			left join Reports.dbo.dm_Factor_Analysis_001 fa2 on fa1.Телефон = fa2.Телефон	
			where fa1.ДатаЗаявкиПолная < fa2.ДатаЗаявкиПолная	
				and fa1.isPts = 0
				and fa2.isPts = 1
				and fa1.ДатаЗаявкиПолная>='20220101')
		and fa.Телефон not in (select fa1.Телефон 		
			from Reports.dbo.dm_Factor_Analysis_001 fa1	
			left join Reports.dbo.dm_Factor_Analysis_001 fa2 on fa1.Телефон = fa2.Телефон	
			where fa2.[Заем выдан] is not null	
				and fa1.ДатаЗаявкиПолная < fa2.ДатаЗаявкиПолная
				and fa1.ДатаЗаявкиПолная>='20220101')
				
				
				;
				
				with v as (
				
				select *, row_number() over(partition by Телефон order by case when timezone is not null then 1 end desc, ДатаЗаявкиПолная desc) rn from #t1 )
				
				delete from v where rn>1 or Телефон in (select cast(Phone  as nvarchar(10)) Телефон
from stg._1ccrm.BlackPhoneList)
				
				select Телефон, ФИО, isnull(timezone, '') timezone, cast(ДатаЗаявкиПолная as smalldatetime) ДатаЗаявкиПолная from 
				#t1
				order by 4

end