

CREATE   proc [dbo].[Подготовка Отчета результаты перехода с ПТС 31 на осн продукт]

as
begin

drop table if exists #t1

select  cast(dateadd(year, -2000, Период) as date) Период, Договор, ИспытательныйСрок, lag(ИспытательныйСрок) over (partition by Договор order by Период)  lag_ИспытательныйСрок 
into #t1
from stg._1cCMR.РегистрСведений_ПараметрыДоговора 

drop table if exists #ПереведенияНаОснПродукт

select Период, Analytics.dbo.get_loan_code(Договор) Код into #ПереведенияНаОснПродукт from #t1
where ИспытательныйСрок =0 and isnull(lag_ИспытательныйСрок,ИспытательныйСрок)=1



--select Период, string_agg(Analytics.dbo.get_loan_code(Договор) , '/') Код from #t1
--where ИспытательныйСрок =0 and isnull(lag_ИспытательныйСрок,ИспытательныйСрок)=1
--group by Период
--order by Период



drop table if exists   #f
select Номер, [Заем выдан], [Заем погашен] into #f  from  mv_dm_Factor_Analysis where ИспытательныйСрок=1 and [Заем выдан]>='20211001'
order by 2 desc


drop table if exists   #b
select Код, dpd, d into #b from v_balance a join #f b on a.Код=b.Номер --and d=cast(getdate() as date)


drop table if exists   #p

select код, ДатаПлатежа, суммаплатежа, ROW_NUMBER() over(partition by код order by ДатаПлатежа) rn
into #p
from dwh2.dm.CMRExpectedRepayments a
join #f b on a.Код=b.Номер
where [ПризнакПоследнийПлатежИспытательныйСрок]=0


--select * from #p where Код='21111500151841'
--
--
--select * from #f a
--left join #p b on a.Номер=b.Код and b.rn=4
--left join #b c on a.Номер=c.Код
--where b.ДатаПлатежа is null and a.[Заем погашен] is  null
--order by [Заем выдан] desc
;

with v as (
select код
, min(case when rn=1 then ДатаПлатежа end) ДатаПлатежа1
, min(case when rn=2 then ДатаПлатежа end) ДатаПлатежа2
, min(case when rn=3 then ДатаПлатежа end) ДатаПлатежа3
, min(case when rn=4 then ДатаПлатежа end) ДатаПлатежа4

from #p a
group by код
)

select код,
ДатаПлатежа1,
case when ДатаПлатежа2 is null then
dateadd(month, 1, 

ДатаПлатежа1

)
else ДатаПлатежа2 end  ДатаПлатежа2



,
case when ДатаПлатежа3 is null then 
dateadd(month, 1, 
--
case when ДатаПлатежа2 is null then
dateadd(month, 1, 

ДатаПлатежа1

)
else ДатаПлатежа2 end
--
)
else ДатаПлатежа3 end  ДатаПлатежа3,
case when ДатаПлатежа4 is null then 
dateadd(month, 1, 
--
case when ДатаПлатежа3 is null then 
dateadd(month, 1, 
--
case when ДатаПлатежа2 is null then
dateadd(month, 1, 

ДатаПлатежа1

)
else ДатаПлатежа2 end
--
)
else ДатаПлатежа3 end
--
)
else ДатаПлатежа4 end  ДатаПлатежа4
into #p_an
from v
order by 5 desc

;

drop table if exists #rez
--select * from  #ПереведенияНаОснПродукт
;
with v as (
select a.*, ДатаПлатежа4, case when ДатаПлатежа4<cast(getdate() as date) then 1 else 0 end [Наступила дата 4 платежа] 
, c.Период
, d.dpd
, d1.dpd [dpd сегодня]
, cast([Заем погашен] as date) [Заем погашен день]
from #f a
left join #p_an b on a.Номер=b.Код 
left join #ПереведенияНаОснПродукт c on a.Номер=c.Код
left join #b d on a.Номер=d.Код and d.d=dateadd(day, 1, ДатаПлатежа4)
left join #b d1 on a.Номер=d1.Код and d1.d=cast(getdate() as date)
--order by 1
)
select *
,  case 

     when  [Наступила дата 4 платежа]=1 and [Заем погашен день]<=ДатаПлатежа4 then  'ПДП до 4 платежа' 
     when  [Наступила дата 4 платежа]=1 and Период is not null  then  'Переведен на ПТС' 
     when  [Наступила дата 4 платежа]=1 and Период is  null and dpd=1  then  'Не внес 4 платеж' 
     when  [Наступила дата 4 платежа]=1 and Период is  null and dpd>1  then  'К 4 платежу был в просрочке' 
     when  [Наступила дата 4 платежа]=1 and Период is  null and dpd=0  then  'Оплатил, но не подписано ДС' 
     --when  [Наступила дата 4 платежа]=1 and [Заем погашен день]=ДатаПлатежа4 then  '(в день 4 платежа)' 
     when  [Наступила дата 4 платежа]=0 and [dpd сегодня]>0  then  'Дата 4 платежа не наступила (Клиент в просрочке)' 
     when  [Наступила дата 4 платежа]=0   then  'Дата 4 платежа не наступила' 
	 else ''
	 end
	 rez
	 into #rez
from v
--where  [Наступила дата 4 платежа]=1 

order by rez desc


--drop table if exists Analytics.dbo.[Отчет результаты перехода с ПТС 31 на осн продукт]
--select * into Analytics.dbo.[Отчет результаты перехода с ПТС 31 на осн продукт] from #rez

--select * from #b
--where код='21111300151410'
--
--order by d
--select * from Analytics.dbo.v_balance
--where код='21111300151410'
--
--order by d
;
with v as (
select *, caST(FORMAT(ДатаПлатежа4, 'yyyy-MM-01') as date) [Месяц 4 платежа], case when [Заем погашен день] is not null then 'Закрыт'  else 'Открыт' end закрыт from #rez
)



select закрыт ,[Месяц 4 платежа], rez, count(*) cnt, getdate() created  from v
group by 
закрыт,[Месяц 4 платежа], rez

--анализ выхода из просрочки
--select a.*, caST(FORMAT(ДатаПлатежа4, 'yyyy-MM-01') as date) [Месяц 4 платежа], case when [Заем погашен день] is not null then 'Закрыт'  else 'Открыт' end закрыт
--, b.ДатаПлатежа
--, ba1.dpd
--, ba.d
--, ba.dpd
--from #rez a
--left join #p b on a.Номер=b.Код and b.rn=5
--left join #b ba on a.Номер=ba.Код and ba.d=cast(getdate() as date)
--left join #b ba1 on a.Номер=ba1.Код and ba1.d=dateadd(day, 1, b.ДатаПлатежа)
--where Период is not null
--order by Период





--grant execute on [dbo].[Подготовка Отчета результаты перехода с ПТС 31 на осн продукт] to ReportViewer

end

--exec   dbo.[Подготовка Отчета результаты перехода с ПТС 31 на осн продукт]