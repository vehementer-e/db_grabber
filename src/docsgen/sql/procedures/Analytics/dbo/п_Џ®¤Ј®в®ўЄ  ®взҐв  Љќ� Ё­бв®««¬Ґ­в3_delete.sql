
CREATE    
 proc   [dbo].[Подготовка отчета КЭШ инстоллмент3] @mode nvarchar(100) = 'update'
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
select Номер, [Дата отправки иска в суд], [вид займа] into #fa from reports.dbo.dm_Factor_Analysis_001 aa 
left join #sp b on aa.Номер=b.Код
where isInstallment=1 and [Заем выдан] is not null--<='20220401'




--select * from #fa
--where номер='22021120245057'
--order by 2

drop table if exists #t2
SELECT d
	,Код
	,[Дата выдачи]
	,Срок
	,sum(CASE 
			WHEN d >= [Дата отправки иска в суд]
				THEN [сумма поступлений]
			END) [Судебка]
	,sum([сумма поступлений]) [сумма поступлений]
	,max(Сумма) Сумма
	,max([Вид займа]) [Вид займа]
	,max(case when month(d)<>month(dateadd(day, 1, d))	or d=cast(getdate()-1 as date) then case when dpd<=30 then [остаток од] else 0 end  end	 ) od_active
	,max(case when month(d)<>month(dateadd(day, 1, d))	or d=cast(getdate()-1 as date) then [остаток од]  end	 ) od
INTO #t2
FROM v_balance a
JOIN #fa b ON a.Код = b.Номер
--where     [сумма поступлений]>0
GROUP BY d
	,[Дата выдачи]
	,Срок
	,Код
ORDER BY d DESC




drop table if exists #t3


declare @start_date date = '2021-12-09';



with type_date as (

select 'Месяц' [Период_тип] --union all
--select 'Неделя' t --union all


)
,pilots as (

select '1) Первый запуск' Пилот, '2021-12-01' date_start, '2022-04-01' date_end union all
select '2) Второй запуск' t           , '2022-11-01' date_start, '2122-11-01' date_end union all
select '3) Total' t         , '2021-12-01' date_start, '2121-12-01' date_end  --union all


)
,
return_types as (
select 'Первичный' [Вид займа],'Первичный' return_type, 1.2 target_plan union all
select 'Повторный' [Вид займа],'Повторный' return_type, 1.3 target_plan  union all
select 'Первичный' [Вид займа],'Первичный + Повторный' return_type, null target_plan  union all
select 'Повторный' [Вид займа],'Первичный + Повторный' return_type, null target_plan -- union all


),
checks as (
select '0) До 10к' Чек, 0 from_, 9999.99999 to_ union all
select '1) До 15к' Чек, 0 from_, 14999.99999 to_ union all
select '2) Больше 15к' Чек, 15000 from_, 100000000 to_ union all
select '3) Total' Чек, 0 from_, 100000000 to_ --union all


)
,
terms as (

select 3 срок, Сроки_займа = '2) 3 месяца' union all
select 6 срок, Сроки_займа = '3) 6 месяцев' union all
select 6 срок, Сроки_займа = '4) 9 месяцев' union all
select 12 term, term_type = '5) 12 месяцев' union all
select 3 term, term_type = '1) 3,6,9,12 месяцев' union all
select 6 term, term_type = '1) 3,6,9,12 месяцев' union all
select 9 term, term_type = '1) 3,6,9,12 месяцев' union all
select 12 term, term_type =  '1) 3,6,9,12 месяцев' --union all


)



select 

type_date.[Период_тип]
,case when type_date.[Период_тип]='Месяц' then a.Месяц else a.Неделя end [Период]
, a.Дата
, a.Месяц
, a.Неделя
, p.Пилот
, c.Чек
, r.return_type
,case when  cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)='20220301' then '20220201' else cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)
end [Дата_выдачи_Месяц]
, t.срок 
, t.Сроки_займа 
, b.Код
, b.Сумма
, isnull(b.[сумма поступлений], 0)    [сумма поступлений]
, isnull(b.Судебка, 0)    Судебка
, ROW_NUMBER() over (partition by Пилот,  [Период_тип],  case when  cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)='20220301' then '20220201' else cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)
end, Сроки_займа, c.Чек,r.return_type, Код order by (select 1)) rn

, sum(b.[сумма поступлений]) over (partition by Пилот,  [Период_тип],  case when  cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)='20220301' then '20220201' else cast(format(b.[Дата выдачи], 'yyyy-MM-01') as date)
end, Сроки_займа, c.Чек,r.return_type, Код order by (select 1)) [Сумма поступлений по поколению за все время]
,  b.od
,  b.od_active
into #t3
from v_Calendar a
join pilots p on 1=1 
join terms t on 1=1
join checks c on 1=1
join return_types r on 1=1
left join #t2 b on a.Дата = b.d and t.срок=b.Срок and b.[Дата выдачи] between p.date_start and p.date_end	and b.Сумма between c.from_ and c.to_	and b.[Вид займа] = r.[Вид займа]
 join type_date on 1=1
where Дата  between @start_date and getdate()-1



--select * from #t3
--where rn=1
--order by 1, term_type, 2
--where [Поколение выдачи] is null
;

drop table if exists dbo.[Отчет кэш инстоллмент3] 
drop table if exists #t4
;

with v as (

select [Дата_выдачи_Месяц],[Период_тип], Пилот, Сроки_займа, чек, return_type,  sum(case when rn=1 then Сумма end) Сумма, sum(case when rn=1 then [Сумма поступлений по поколению за все время] end) [Сумма поступлений по поколению за все время]  from #t3
where [Дата_выдачи_Месяц] is not null
group by  [Дата_выдачи_Месяц],[Период_тип], Пилот, Сроки_займа , чек  , return_type
union all

select null [Поколение выдачи] ,[Период_тип], Пилот, Сроки_займа, чек, return_type,  sum(case when rn=1 then Сумма end) Сумма, sum(case when rn=1 then [Сумма поступлений по поколению за все время] end) [Сумма поступлений по поколению за все время] from #t3
where [Дата_выдачи_Месяц] is not null

group by  [Период_тип], Пилот, Сроки_займа , чек , return_type


)



, a as (
select Пилот,[Период_тип], Период, [Дата_выдачи_Месяц], Сроки_займа, чек , return_type, sum([сумма поступлений]) [сумма поступлений], sum(Судебка) Судебка, sum(od) od , sum(od_active) od_active  from #t3 a
where [Дата_выдачи_Месяц] is not null
group by  Пилот,[Период_тип], Период, [Дата_выдачи_Месяц], Сроки_займа , чек , return_type

union all

select Пилот,[Период_тип], Период, null, Сроки_займа, чек , return_type, sum([сумма поступлений]) [сумма поступлений] , sum(Судебка) Судебка, sum(od) od , sum(od_active) od_active  from #t3 a
where [Дата_выдачи_Месяц] is not null
group by  Пилот, [Период_тип], Период,    Сроки_займа	 , чек , return_type
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
, [% выполнения] = [сумма поступлений накопительно]/(Сумма*case when return_type = 'Первичный' then 1.2 when return_type = 'Повторный' then 1.3 end)
, od_active/(nullif(od, 0)+0.0)  perc_active
--, [Доля периода] = [сумма поступлений]/([Сумма поступлений по поколению за все время]*1.0)
, [Доля для Recovery] = [сумма поступлений]/(Сумма)
, left(Пилот, 1) [Пилот_порядок]
, right(Пилот, len(Пилот)-3) Пилот_текст
, left(Сроки_займа, 1) [Сроки_займа_порядок]
, right(Сроки_займа, len(Сроки_займа)-3) [Сроки_займа_текст]
, ROW_NUMBER() over(partition by   Пилот, [Период_тип], [Дата_выдачи_Месяц],  Сроки_займа , чек , return_type order by Период) rn_filter_dates
from (
select 
a.*
, v.Сумма
, v.[Сумма поступлений по поколению за все время]
,[сумма поступлений накопительно] =  sum([сумма поступлений]) over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа , a.чек , a.return_type order by Период ) 
,[Судебка накопительно]           =  sum(Судебка)             over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа , a.чек , a.return_type order by Период ) 
--, sum_active_sum = sum(sum_active)	  over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа , a.чек , a.return_type , a.Период  )
--, sum_active_count = sum(count_active)	    over(partition by a.Пилот,a.[Период_тип], a.[Дата_выдачи_Месяц], a.Сроки_займа , a.чек , a.return_type , a.Период  )
from a
left join v on                                                                  a.Пилот=v.Пилот and a.Сроки_займа=v.Сроки_займа and a.[Период_тип]=v.[Период_тип] and isnull(a.[Дата_выдачи_Месяц], getdate()+1000)= isnull(v.[Дата_выдачи_Месяц], getdate()+1000)	  and a.чек=v.чек  and a.return_type=v.return_type  --, return_type
 
) x

) x




select a.*, getdate() as created ,
colour_plan = case 
when [% выполнения] is null   then 'Transparent'   
when [% выполнения]<0.2       then '#ff1500'
when [% выполнения]<0.4       then '#ff4400'
when [% выполнения]<0.5       then '#ff7200'
when [% выполнения]<0.6       then '#ffa500'
when [% выполнения]<0.7       then '#ffc700'
when [% выполнения]<0.8       then '#ffdd00'
when [% выполнения]<0.85      then '#fffa00'
when [% выполнения]<0.90      then '#e9ff00'
when [% выполнения]<0.95      then '#88ff00'
when [% выполнения]<0.97      then '#04ff00'
when [% выполнения]<1         then '#00ffb2'
when [% выполнения]>=1        then '#00f6ff'
end

into dbo.[Отчет кэш инстоллмент3] from #t4 a
--join ( select * , ROW_NUMBER() over(partition by  Период_тип order by Период desc) rn from (select distinct Период_тип, Период from #t4 b) f_  ) f on f.rn<=7 and a.Период_тип=f.Период_тип and a.Период=f.Период


--select *  from #t4 a
if cast(getdate() as time) <'11:15:00'
begin
waitfor time '11:15:00'
--update  config set   cash_inst_report_status	 = null
--
--drop table if exists dbo.[Отчет кэш инстоллмент статус] 
--select getdate() dt into  dbo.[Отчет кэш инстоллмент статус] 
----delete from  dbo.[Отчет кэш инстоллмент статус] 
end
update  config set   cash_inst_report_status	 = getdate()


end


if @mode='select'
begin

select * from  dbo.[Отчет кэш инстоллмент3] 
--where Чек='0) До 10к' and 	Дата_выдачи_Месяц='2022-12-01'		   and Сроки_займа='3) 6 месяцев'	and return_type='Повторный'
order by Период

end

end