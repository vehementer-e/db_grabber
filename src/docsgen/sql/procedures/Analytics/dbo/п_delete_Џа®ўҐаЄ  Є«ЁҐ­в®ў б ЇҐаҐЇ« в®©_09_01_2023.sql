
CREATE   proc
-- 
--analytics.
--exec 
[dbo].[Проверка клиентов с переплатой]

as

begin

--drop table if exists #dm_CMRExpectedRepayments
--
--select *
--	  
--
----	  , lag(ДатаПлатежа) over(partition by Код order by ДатаПлатежа)  [Дата прошлого платежа] 
--into #dm_CMRExpectedRepayments
--from reports.dbo.dm_CMRExpectedRepayments
--where ДатаПлатежа between cast(getdate()-1 as date) and cast(getdate() as date)


--select * from #dm_CMRExpectedRepayments


--drop table if exists #t1
--select a.* into #t1 from v_repayments a join (select distinct Код from #dm_CMRExpectedRepayments) b on a.Код=b.Код
--where ДеньПлатежа between '20220112' and '20220113'



--drop table if exists #договоры
--
--select Договор, Погашен, код into #договоры from v_Справочник_Договоры a join (select distinct Договор from #dm_CMRExpectedRepayments) b on a.[Ссылка договор CMR]=b.Договор



drop table if exists #v_balance

select a.[Проценты уплачено],   a.[сумма поступлений],a.d,   a.ПереплатаНачислено ,   a.Код  ,   a.is_dpd, a.[is_dpd начало дня] into #v_balance from v_balance a --join (select distinct Код from #договоры) b on a.Код=b.Код
where d between cast(getdate()-1 as date) and cast(getdate() as date) and a.[Дата закрытия] is null
--exec generate_select_table_script 'analytics.dbo.v_repayments'
--select 
--[Дата] 
--,[ДеньПлатежа] 
--,[МесяцПлатежа] 
--,[КварталПлатежа] 
--,[НеделяПлатежа] 
--,[ДатаОтражения] 
--,[ДатаСозданияДокумента] 
--,[Сумма] 
--,[Сумма в счет погашения займа] 
--,[СуммаОплатыДопПродуктов] 
--,[ссылка] 
--,[Договор] 
--,[Код] 
--,[ПлатежнаяСистема] 
--,[Проведен] 
--,[ПометкаУдаления] 
--,[НомерПлатежа] 
--,[CRMClientGUID] 
--,[КомиссияCКлиента] 
--,[ДоходСКлиента] 
--,[КомиссияПШ] 
--,[Платеж через еком с комиссией для клиента] 
--,[Вид платежа] 
--,[created] 
--,[Платеж онлайн] 
--,[Прибыль] 
--,[ПрибыльБезНДС] 

--into #t1

--from 

--analytics.dbo.v_repayments

drop table if exists #ЗаявлениеНаЧДП

select код, [Дата заявления на ЧДП] into #ЗаявлениеНаЧДП  from v_Документ_ЗаявлениеНаЧДП

drop table if exists #final

select 

  b.Код Код
--, a.[Признак Фиктивный платеж Испытательный срок]
, b.d d
, b.[сумма поступлений] [сумма поступлений]
, b.ПереплатаНачислено ПереплатаНачислено
, b.[Проценты уплачено] [Проценты уплачено]
, case when b.[is_dpd начало дня]=1 then 1 else 0 end as [Платеж от просрочника]
, chdp.[Дата заявления на ЧДП] [ЧДП оставлен за 28 дней до платежа]
into #final
from 
#v_balance b  

--left join #v_balance b1 on b.d=dateadd(day, 1, b1.d) and b.Код=b1.Код
--left join #договоры д on д.Код=a.Код
--outer apply (select sum([Сумма в счет погашения займа]) [Сумма в счет погашения займа] from #t1 c where c.Код=a.Код  ) x
outer apply (select top 1 * from #ЗаявлениеНаЧДП ch where ch.Код=b.Код and cast(ch.[Дата заявления на ЧДП] as date) between dateadd(day, -28,b.d ) and  b.d order by ch.[Дата заявления на ЧДП] desc) chdp



select Код,  d [Дата платежа],   [Сумма поступлений], ПереплатаНачислено Переплата  from #final a
where ПереплатаНачислено>0 and [ЧДП оставлен за 28 дней до платежа]is null

order by ПереплатаНачислено desc


--select * from #ЗаявлениеНаЧДП
--where код='21011500070305'



--смотрим на тех, у кого был платеж сегодня или вчера
--нет заявления ЧДП
--добавить номер телефона
end