CREATE    proc [_birs].[sales_funnel_kpi_day_to_day]
as
begin

declare @now_dt datetime = getdate()




drop table if exists #t2


select Номер, [Вид займа] 
,case when cast([Отказано]				   as date)=cast([Верификация КЦ] as date) then  [Отказано]				   	end [Отказано]				   
,case when cast([Верификация КЦ]		   as date)=cast([Верификация КЦ] as date) then  [Верификация КЦ]		   	end [Верификация КЦ]		   
,case when cast([Отказ документов клиента] as date)=cast([Верификация КЦ] as date) then  [Отказ документов клиента] end [Отказ документов клиента] 
,case when cast([Заем выдан]			   as date)=cast([Верификация КЦ] as date) then  [Заем выдан]			   	end [Заем выдан]			   
,case when cast([Заем погашен]			   as date)=cast([Верификация КЦ] as date) then  [Заем погашен]			   	end [Заем погашен]			   
,case when cast(Аннулировано			   as date)=cast([Верификация КЦ] as date) then  Аннулировано			   	end Аннулировано			   
,case when cast([Заем аннулирован]		   as date)=cast([Верификация КЦ] as date) then  [Заем аннулирован]		   	end [Заем аннулирован]		   
,case when cast([Встреча назначена]		   as date)=cast([Верификация КЦ] as date) then  [Встреча назначена]		end [Встреча назначена]		     
,case when cast([Предварительное одобрение]		   as date)=cast([Верификация КЦ] as date) then  [Предварительное одобрение]		end [Предварительное одобрение]		     
,case when cast([Отказ клиента]			   as date)=cast([Верификация КЦ] as date) then  [Отказ клиента]			end [Отказ клиента]			     
,case when cast(Одобрено				   as date)=cast([Верификация КЦ] as date) then  Одобрено				   	end Одобрено				   
,case when cast([Контроль данных]				   as date)=cast([Верификация КЦ] as date) then  [Контроль данных]				   	end [Контроль данных]				   



,[Верификация КЦ] ДатаЗаявки
,row_number() over(partition by fa.[Телефон], cast(fa.[Верификация КЦ] as date) order by [ПризнакЗаймДеньВДень] desc, 
case when cast(Одобрено				   as date)=cast([Верификация КЦ] as date) then  Одобрено  end desc,
case when cast([Верификация документов]				   as date)=cast([Верификация КЦ] as date) then  [Верификация документов]  end desc,
case when cast([Одобрены документы клиента]				   as date)=cast([Верификация КЦ] as date) then  [Одобрены документы клиента]  end desc,
case when cast([Контроль данных]				   as date)=cast([Верификация КЦ] as date) then  [Контроль данных]  end desc,
case when cast([Предварительное одобрение]				   as date)=cast([Верификация КЦ] as date) then  [Предварительное одобрение]  end desc,
[Верификация КЦ]) Дубль



into #t2
from 
reports.dbo.dm_Factor_Analysis_001 fa with(nolock)
where [Верификация КЦ] is not null 		 and cast([Верификация КЦ] as date)>=cast(getdate()-30 as date) --and @d_v_d=1
and ispts=1
--
--
--
--insert into #t2
--
--
--select Номер, [Вид займа] 
--, [Отказано]				   
--, [Верификация КЦ]		   
--, [Отказ документов клиента] 
--, [Заем выдан]			   
--, [Заем погашен]			   
--, Аннулировано			   
--, [Заем аннулирован]		   
--, [Встреча назначена]		     
--, [Предварительное одобрение]		     
--, [Отказ клиента]			     
--, Одобрено				   
--, [Контроль данных]				   
--
--
--
--,ДатаЗаявкиПолная
--,row_number() over(partition by fa.[Телефон], cast(fa.ДатаЗаявкиПолная as date) order by [ПризнакЗаймДеньВДень] desc, 
--Одобрено			desc	   ,[Верификация документов]				  desc,
--[Одобрены документы клиента] desc ,
--[Контроль данных]		desc,
--[Предварительное одобрение]	desc,
--ДатаЗаявкиПолная) Дубль
--
--
--
--from 
--reports.dbo.dm_Factor_Analysis_001 fa
--where [Верификация КЦ] is not null 		 and cast(ДатаЗаявкиПолная as date)>=cast(getdate()-30 as date) and @d_v_d=0
--

drop table if exists #t1

 select cast(ДатаЗаявки  as date) ДатаЗ, 
         @now_dt as ДатаОбновленияСтроки,
         count(Номер) ЧислоЗаявок, 
		 count(case when [Вид займа]='Первичный' then номер end) ЧислоНовыхЗаявок,
		 count(case when [Предварительное одобрение] is not null then номер end) ПредварительноОдобреноЗаявок,
		 count(case when [Контроль данных] is not null then номер end) ПрошедшиеКД,
		 
		 count(case when  [Отказ документов клиента] is not null or [Отказано] is not null then номер end) ЧислоОтказов,
		 count(case when fa.Отказано is  null and
		                 fa.[Отказ документов клиента]  is  null and
						 fa.[Заем выдан] is  null and
						 fa.[Заем погашен] is  null and
						 fa.Аннулировано is  null and
						 fa.[Заем аннулирован] is  null and
						 fa.[Отказ клиента] is  null                  then номер end) ЧилоВРаботе,
		 count(case when [Встреча назначена] is not null and [Контроль данных] is null then номер end) НазначениеВстречи,
		 count(case when [Отказ клиента] is not null  then номер end) ОтказКлиента,
		 count(case when [Заем выдан] is not null   then номер end) ВыданоЗаймов,
		 count(case when Одобрено is not null  then номер end) Одобрено,
		 count(case when Одобрено is not null and [Заем выдан] is null then номер end) ОдобреноНоНЕВыданоДеньВДень,
		 max([Верификация КЦ]) as ДатаПоследнейУчтеннойЗаявки,
		 min([Верификация КЦ]) as ДатаПервойУчтеннойЗаявки
		into #t1
		 from #t2 fa
		 where Дубль=1  
group by cast(ДатаЗаявки as date) 
select * from #t1
order by 1

end