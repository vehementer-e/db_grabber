

CREATE   proc [dbo].[Подготовка отчета возвращаемость инстоллмент]		@m nvarchar(max) = 's'
as
begin

	if @m='u' begin
					 return
				  end
				  if @m = 's'


				  begin
				  drop table if exists  #t1


select Номер, [Заем выдан],[Выданная сумма], [Заем выдан месяц],  [Заем выдан день], [Заем погашен месяц], [Заем погашен день], [Ссылка клиент] into #t1 from mv_dm_Factor_Analysis
where ispts=0	and [Заем выдан] is not null
drop table if exists  #t2


select *, ROW_NUMBER() over(partition by [Ссылка клиент] order by [Заем выдан]) rn into #t2 from #t1
  drop table if exists 	##T1

select a.*
, b.[Заем выдан месяц] [Заем выдан месяц след]
, b.[Выданная сумма] [Выданная сумма след]
, isnull( datediff(month, a.[Заем выдан месяц], b.[Заем выдан месяц] )	   , -999) [Мес после выдачи]
, isnull( datediff(day, a.[Заем выдан день], b.[Заем выдан день] )	   , -999) [Дней после выдачи]
, isnull( datediff(month, a.[Заем погашен месяц], b.[Заем выдан месяц] )   , -999) [Мес после погашения]
, isnull( datediff(day, a.[Заем погашен день], b.[Заем выдан день] )   , -999) [Дней после погашения]
,getdate() created
  into ##T1
from 	#t2	a
left join #t2 b on a.[Ссылка клиент]=b.[Ссылка клиент] and b.rn=1+a.rn
--where a.[Ссылка клиент]=0xB81900155D4D1C4211EA4D27064AFEB5



				  select  * from ##t1

				  end

end
