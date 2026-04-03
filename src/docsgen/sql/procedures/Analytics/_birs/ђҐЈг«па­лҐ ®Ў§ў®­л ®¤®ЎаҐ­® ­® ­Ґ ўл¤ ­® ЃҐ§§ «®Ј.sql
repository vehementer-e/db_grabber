

CREATE      proc [_birs].[Регулярные обзвоны одобрено но не выдано Беззалог]

@datefrom date = null,
@dateto date = null

as

begin



--declare @datefrom as date = getdate()-10
--declare @dateto as date = '20221230'

drop table if exists #t1			
				
	select fa.Телефон			
		,fa.[Вид займа]		
		,fa.Номер		
		,fa.ФИО		
		,f.gmt timezone		
		,fa.[Текущий статус] [Текущий статус] 
		,fa.Одобрено Одобрено		
		,fa.[Регион Проживания]	[Регион Проживания]
		,f.capital  capital
		,f.gmt  gmt
		--,fa.[Регион Проживания] [Регион Проживания]		
				
		into #t1		
	from Reports.dbo.dm_Factor_Analysis_001 fa		
	--join Reports.dbo.dm_Factor_Analysis fa1	on fa.Номер = fa1.Номер
	left join [Analytics].[dbo].[v_gmt] f on fa.[Регион Проживания] = f.region	
	where cast(fa.Одобрено as date) between @datefrom and @dateto		and fa.[Заем выдан] is null	
 	   and isnull(fa.Партнер, '')<> 'Партнер №0200 Москва'
		and fa.isPts = 0


		--select * from  [Analytics].[dbo].[v_gmt] 
		--select * from  #t1

drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 

		

		drop table if exists #t2

		select a.* into #t2 from #t1 a
		left join  Reports.dbo.dm_Factor_Analysis_001 b on a.Телефон=b.Телефон and b.[Заем выдан] >=a.Одобрено
		left join  #bl bl on bl.UF_PHONE=a.Телефон
 		where b.Номер is null		  and bl.UF_PHONE is null
		
				
				
				;
			WITH v
AS (
	SELECT *
		,row_number() OVER (
			PARTITION BY Телефон ORDER BY CASE 
					WHEN timezone IS NOT NULL
						THEN 1
					END DESC
				,Одобрено DESC
			) rn
	FROM #t2
	)
DELETE
FROM v
WHERE rn > 1

SELECT Телефон
	,[Вид займа]		 
	,[Текущий статус] 
	,[Регион Проживания]
	,capital
	,gmt
	,Номер
	,ФИО
	,isnull(timezone, '') timezone
	,cast(Одобрено AS DATETIME) Одобрено
	--into #t3
FROM #t2

--exec create_table '#t3'

				--order by 4

end