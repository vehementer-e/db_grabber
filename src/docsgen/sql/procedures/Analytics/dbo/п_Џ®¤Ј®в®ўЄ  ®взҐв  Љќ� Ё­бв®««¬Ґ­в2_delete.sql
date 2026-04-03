
CREATE  
 proc   [dbo].[Подготовка отчета КЭШ инстоллмент2] @mode nvarchar(100) = 'update'
as 
begin

set language russian



if @mode='update'
begin


set language russian


drop table if exists #sp

select  a.Код, min(a.[Дата отправки иска в суд]) [Дата отправки иска в суд]
into #sp
from _collection a

group by a.Код


drop table if exists #fa
select Номер, [Дата отправки иска в суд] into #fa from reports.dbo.dm_Factor_Analysis_001 aa 
left join #sp b on aa.Номер=b.Код
where isInstallment=1 and [Заем выдан] is not null--<='20220401'




select * from #fa
where номер='22021120245057'
order by 2

drop table if exists #t2

select d, Код, [Дата выдачи], Срок, sum(case when d>=[Дата отправки иска в суд] then [сумма поступлений] end) [Судебка], sum([сумма поступлений]) [сумма поступлений], max(Сумма) Сумма into #t2 from v_balance
a join #fa b on a.Код=b.Номер
--where     [сумма поступлений]>0
group by d, [Дата выдачи], Срок, Код
order by d desc
 
 


drop table if exists #t3


declare @start_date date = '2021-12-09';



with type_date as (

select 'Месяц' [Период_тип] union all
select 'Неделя' t --union all


)
,pilots as (

select '1) Первый запуск' Пилот, '2021-12-01' date_start, '2022-04-01' date_end union all
select '2) Второй запуск' t           , '2022-11-01' date_start, '2122-11-01' date_end --union all
--select '3) За все время' t         , '2021-12-01' date_start, '2121-12-01' date_end  --union all


)
,
terms as (

select 6 срок, Сроки_займа = '1) 6 месяцев' union all
select 12 term, term_type = '2) 12 месяцев' union all
select 3 term, term_type = '3) 3,6,9,12 месяцев' union all
select 6 term, term_type = '3) 3,6,9,12 месяцев' union all
select 9 term, term_type = '3) 3,6,9,12 месяцев' union all
select 12 term, term_type =  '3) 3,6,9,12 месяцев' --union all


)



select 

type_date.[Период_тип]
,case when type_date.[Период_тип]='Месяц' then a.Месяц else a.Неделя end [Период]
, a.Дата
, a.Месяц
, a.Неделя
, p.Пилот
,case when  cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)='20220301' then '20220201' else cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)
end [Дата_выдачи_Месяц]
, t.срок 
,t.Сроки_займа 
, b.Код
, b.Сумма
, isnull(b.[сумма поступлений], 0)    [сумма поступлений]
, isnull(b.Судебка, 0)    Судебка
, ROW_NUMBER() over (partition by Пилот,  [Период_тип],  case when  cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)='20220301' then '20220201' else cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)
end, Сроки_займа, Код order by (select 1)) rn
into #t3
from v_Calendar a
join pilots p on 1=1 
join terms t on 1=1
left join #t2 b on a.Дата = b.d and t.срок=b.Срок and b.[Дата выдачи] between p.date_start and p.date_end
 join type_date on 1=1
where Дата  between @start_date and getdate()-1



--select * from #t3
--where rn=1
--order by 1, term_type, 2
--where [Поколение выдачи] is null
;

drop table if exists dbo.[Отчет кэш инстоллмент] 
drop table if exists #t4
;

with v as (

select [Дата_выдачи_Месяц],[Период_тип], Пилот, Сроки_займа,  sum(case when rn=1 then Сумма end) Сумма from #t3
where [Дата_выдачи_Месяц] is not null
group by  [Дата_выдачи_Месяц],[Период_тип], Пилот, Сроки_займа
union all

select null [Поколение выдачи] ,[Период_тип], Пилот, Сроки_займа,  sum(case when rn=1 then Сумма end) Сумма from #t3
where [Дата_выдачи_Месяц] is not null

group by  [Период_тип], Пилот, Сроки_займа


)



, a as (
select Пилот,[Период_тип], Период, [Дата_выдачи_Месяц], Сроки_займа, sum([сумма поступлений]) [сумма поступлений], sum(Судебка) Судебка  from #t3 a
where [Дата_выдачи_Месяц] is not null
group by  Пилот,[Период_тип], Период, [Дата_выдачи_Месяц], Сроки_займа

union all

select Пилот,[Период_тип], Период, null, Сроки_займа, sum([сумма поступлений]) [сумма поступлений] , sum(Судебка) Судебка from #t3 a
where [Дата_выдачи_Месяц] is not null
group by  Пилот, [Период_тип], Период,    Сроки_займа
)


select 
* 
into #t4
from (
select 
case 
when [Период_тип]='Месяц' then format(Период, 'MMMM-yyyy') 

else format(Период, 'dd-MMM')+' - '+format(dateadd(day, 6, Период), 'dd-MMM')
end [Период_текст]
,
case 
when [Дата_выдачи_Месяц] is null then 'Итого'
else format([Дата_выдачи_Месяц], 'MMMM-yyyy') end  [Дата_выдачи_Месяц_текст]
,*

, [сумма поступлений накопительно]/Сумма [Доля от ОД] 
, left(Пилот, 1) [Пилот_порядок]
, right(Пилот, len(Пилот)-3) Пилот_текст
, left(Сроки_займа, 1) [Сроки_займа_порядок]
, right(Сроки_займа, len(Сроки_займа)-3) [Сроки_займа_текст]
, ROW_NUMBER() over(partition by   Пилот, [Период_тип], [Дата_выдачи_Месяц],  Сроки_займа order by Период) rn_filter_dates
from (
select 
a.*
, v.Сумма
,[сумма поступлений накопительно] =  sum([сумма поступлений]) over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа order by Период ) 
,[Судебка накопительно] =  sum(Судебка) over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа order by Период ) 
from a
left join v on a.Пилот=v.Пилот and a.Сроки_займа=v.Сроки_займа and a.[Период_тип]=v.[Период_тип] and isnull(a.[Дата_выдачи_Месяц], getdate()+1000)= isnull(v.[Дата_выдачи_Месяц], getdate()+1000)
) x

) x




select a.*, getdate() as created  into dbo.[Отчет кэш инстоллмент] from #t4 a
join ( select * , ROW_NUMBER() over(partition by  Период_тип order by Период desc) rn from (select distinct Период_тип, Период from #t4 b) f_  ) f on f.rn<=7 and a.Период_тип=f.Период_тип and a.Период=f.Период

if cast(getdate() as time) <'11:15:00'
begin
waitfor time '11:15:00'

drop table if exists dbo.[Отчет кэш инстоллмент статус] 
select getdate() dt into  dbo.[Отчет кэш инстоллмент статус] 
--delete from  dbo.[Отчет кэш инстоллмент статус] 
end


end


if @mode='select'
begin
select * from  dbo.[Отчет кэш инстоллмент] 
end

end