CREATE     proc [_birs].[interest_rates_legacy_report]

@now_t date = null


as
begin


drop table if exists #t1

select cast([Заем выдан] as date)                        ДатаВыдачи
,      cast(format([Заем выдан] , 'yyyy-MM-01') as date) МесяцВыдачи
,      cast(format([Заем выдан] , 'yyyy-01-01') as date) ГодВыдачи
,      cast(ПроцСтавкаКредит*[Выданная Сумма] as float)/100 СуммаНаСтавку              
,      ПроцСтавкаКредит                
,      [ПризнакСтраховка]  as [Страховка]                
,      1-isPts isinstallment                
,      product                
,      cast([Выданная Сумма]                 as  float) [Выданная Сумма]
,      case when [группа каналов] = 'cpa' then     [Канал от источника] else      [группа каналов] end Канал      
into #t1
from analytics.dbo.mv_dm_Factor_Analysis
where ПроцСтавкаКредит>0 and [Заем выдан] is not null


declare @report_date date = @now_t
--declare @report_date date = getdate()
declare @report_month date = cast(format( @report_date  , 'yyyy-MM-01') as date) 
declare @report_year date = cast(format( @report_date  , 'yyyy-01-01') as date) 
declare @report_last_year date = dateadd(year, -1, @report_year)




select столбец1 ,столбец2 , СтавкаОтчетныйДень, СтавкаОтчетныйМесяц, СтавкаОтчетныйГод,СтавкаПредыдущийГод,ROW_NUMBER() over(order by (select 1)) rn from (

select 'Инстоллмент Итого: '                                                                                                                              столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод

from #t1 
where isinstallment=1

union all
select null, null, null, null, null, null
union all

select 'ПТС Со страховкой'                                                                                                                         столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод

from #t1
where Страховка=1 and isinstallment=0
union all
select 'ПТС Без страховки'                                                                                                                         столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод


from #t1
where Страховка=0 and isinstallment=0
union all
select 'ПТС Итого: '                                                                                                                              столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод


from #t1 
where isinstallment=0

union all
select null, null, null, null, null, null
union all
select 'ПТС', null, null, null, null, null
union all
select * from 
(
select top 1000 product                                                                                                                              столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод


from #t1
where isinstallment=0
group by product
order by product
) x
union all
select null, null, null, null, null, null
union all
select * from 
(
select top 1000 Канал                                                                                                                              столбец1
,      null                                                                                                                               as столбец2
,      sum(case when ДатаВыдачи=@report_date then СуммаНаСтавку end )/sum(case when ДатаВыдачи=@report_date then [Выданная Сумма] end )      СтавкаОтчетныйДень
,      sum(case when МесяцВыдачи=@report_month then СуммаНаСтавку end )/sum(case when МесяцВыдачи=@report_month then [Выданная Сумма] end )    СтавкаОтчетныйМесяц
,      sum(case when ГодВыдачи=@report_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_year then [Выданная Сумма] end )    СтавкаОтчетныйГод
,      sum(case when ГодВыдачи=@report_last_year then СуммаНаСтавку end )/sum(case when ГодВыдачи=@report_last_year then [Выданная Сумма] end )    СтавкаПредыдущийГод


from #t1
where isinstallment=0
group by Канал
order by Канал
) x





) all1


end