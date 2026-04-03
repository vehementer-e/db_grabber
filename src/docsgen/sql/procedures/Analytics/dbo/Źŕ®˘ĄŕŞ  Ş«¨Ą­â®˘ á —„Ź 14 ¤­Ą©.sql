
create   proc dbo.[Проверка клиентов с ЧДП 14 дней]
as

begin


drop table if exists #REZ													
													
select * INTO #REZ													
from v_balance													
where datediff(day, [Дата выдачи] , d) <=14													
and [сумма поступлений  нарастающим итогом]> [ОСТАТОК %]													
AND [Дата выдачи]>=DATEADD(DAY, -14, '20220702')													
and d between '20220702' and cast(getdate()-1 as date)
and [Дата закрытия] is null													
order by d													
													
drop table if exists #ЗаявлениеНаЧДП													
select код, [Дата заявления на ЧДП] into #ЗаявлениеНаЧДП  from v_Документ_ЗаявлениеНаЧДП	

drop table if exists #ЕП
;
with v as (select g.Договор, dg.СуммаПлатежа, ROW_NUMBER() over(partition by g.[Договор] order by g.Дата,  [ДатаПлатежа] ) rn from [Stg].[_1cCMR].[Документ_ГрафикПлатежей] g join stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей]  dg on g.Ссылка=dg.Регистратор where g.Проведен=1 and g.ПометкаУдаления=0 )
select [Договор],  [Размер платежа первоначальный] = СуммаПлатежа  into #ЕП from v where rn=1

drop table if exists #ЕП_договор
select d.Код, a.[Размер платежа первоначальный], ТелефонМобильный, Фамилия+' '+Имя+' '+Отчество ФИО into #ЕП_договор
from stg._1cCMR.Справочник_Договоры d 
left join #ЕП a on a.[Договор]=d.Ссылка

drop table if exists #t1
													
select  a.Код	[Номер договора]												
, [Дата выдачи]													
, case when x1.[Признак был ранее] is null then '1' else '' end [Замечен впервые]													
, d		[Отчетная дата]											
, [Прошло дней с выдачи]													
, cast([сумма поступлений  нарастающим итогом]	as bigint)	[сумма поступлений  нарастающим итогом]											
, cast([остаток %]								as bigint)	[остаток %]				
,  cast([сумма поступлений  нарастающим итогом]	as bigint) -												
cast([остаток %]								as bigint)  [Превышение]					
, cast([остаток од]								as bigint)	[остаток од]				
, cast([основной долг начислено]				as bigint)	[основной долг начислено]								
, cast([основной долг уплачено]					as bigint)	[основной долг уплачено]							
, cast([Проценты начислено]						as bigint)	[Проценты начислено]						
, cast([Проценты уплачено]						as bigint)	[Проценты уплачено]						
, cast(ПереплатаНачислено						as bigint)	ПереплатаНачислено						
, cast(ПереплатаУплачено						as bigint)	ПереплатаУплачено						
, chdp.[Дата заявления на ЧДП]										
, cast(b.[Размер платежа первоначальный] as bigint) [Размер платежа первоначальный]
, ТелефонМобильный
, ФИО
,GETDATE() as created
,cast(GETDATE() as date) as created_date

into #t1
from #REZ		a		
left join #ЕП_договор b on a.Код=b.Код
outer apply (select top 1 * from #ЗаявлениеНаЧДП ch where ch.Код=a.Код and cast(ch.[Дата заявления на ЧДП] as date) between dateadd(day, -28,a.d ) and  a.d order by ch.[Дата заявления на ЧДП] desc) chdp													
outer apply (select top 1 1 [Признак был ранее] from #REZ b where a.Код=b.Код and a.d>b.d ) x1													
outer apply (select top 1 1 [Признак сумма не изменилась] from #REZ b where a.Код=b.Код and b.d=dateadd(day, -1, a.d) and a.[сумма поступлений  нарастающим итогом]=b.[сумма поступлений  нарастающим итогом] ) x12													
where isnull(x12.[Признак сумма не изменилась], 0)<>1													
order by d, a.Код													




begin tran

--drop table if exists dbo.[Отчет ЧДП 14 дней]
--select * into dbo.[Отчет ЧДП 14 дней]
--from #t1

delete from  dbo.[Отчет ЧДП 14 дней]
insert into  dbo.[Отчет ЧДП 14 дней]
select * from #t1

commit tran

begin tran

--drop table if exists dbo.[Отчет ЧДП 14 дней история]
--select * into dbo.[Отчет ЧДП 14 дней история]
--from #t1
delete from  dbo.[Отчет ЧДП 14 дней история] where created_date=cast(getdate() as date)
insert into  dbo.[Отчет ЧДП 14 дней история]
select * from #t1


commit tran


if cast(getdate() as time) < '10:00'
	WAITFOR TIME '10:00';  


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'D05639A1-0A4C-4B45-843E-82663EDAA141'


end