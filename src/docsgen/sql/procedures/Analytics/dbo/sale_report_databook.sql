CREATE proc [dbo].[sale_report_databook]
as



 declare @date  date = '20251231' -- 0331 0630 0930


 declare @startDate date =  (select min (year) from calendar_view where date= @date )

-- select @startDate

--select [Тип продукта]
--,  replace( cast( sum([Остаток ОД])/1000000.0 as nvarchar(max)) , '.', ',') [Остаток ОД]
--from v_balance a
--left join _request b on a.number=b.number
--where d= @date --and [Дата выдачи]<d
--group by [Тип продукта]
-- order by 1 desc


 
select  case when [Тип продукта]='Большой инстоллмент' then  'Инстоллмент' else  [Тип продукта] end [Тип продукта]
,  replace( cast( sum([Остаток ОД])/1000000.0 as nvarchar(max)) , '.', ',') [Остаток ОД]
from v_balance a
--left join _request b on a.number=b.number and  b.productType='autocredit'
where d= @date --and [Дата выдачи]<d
group by case when [Тип продукта]='Большой инстоллмент' then  'Инстоллмент' else  [Тип продукта] end
 order by 1 desc




 --select distinct [Тип продукта] from v_balance
 --where d='20251231'


 select case when productType2 = 'BIG INST' then 'BEZZALOG' else productType2 end  productType2
 , replace( cast( sum(issuedSum)/1000000.0 as nvarchar(max)) , '.', ',') СуммаМЛН
 , replace( cast( count(issuedSum)/1000.0 as nvarchar(max)) , '.', ',') ШтукиТЫС
 
 
 from v_fa a join calendar_view b on a.issuedDate = b.date and b.quarterEnd  between @startDate and   @date
 --and a.productType2<>'autocredit'
 group by case when productType2 = 'BIG INST' then 'BEZZALOG' else productType2 end
 order by 1 desc

  
 
 select  replace( cast( count(distinct Код)/1000.0 as nvarchar(max)) , '.', ',') АктивныхЗаймовНаКонецПериода from mv_loans 
 where [Дата выдачи день] <= @date and isnull( [Дата погашения день], getdate()+1) > @date
  

 select  replace( cast( count(distinct client_Id)/1000.0 as nvarchar(max)) , '.', ',') ОбщееКолВоУникальных from mv_loans 
 where [Дата выдачи день] <= @date  


  select replace(format( count(case when returnType<>'Первичный' then 1 end)/    (0.0+  count(   1  ) ) , '0.00000%') , '.', ',') ДоляПовторных
  , replace( cast( avg(issuedSum)/1000.0 as nvarchar(max)) , '.', ',') СреднийЧекАвтозайма
   
 ,replace(format( count(case when origin2 in ('МП', 'ЛКК клиента', 'UNIAPI') then 1 end )/    (0.0+  count(   1  ) ) , '0.00000%') , '.', ',') ДоляОнлайнШт 
    
 
 from v_fa a join calendar_view b on a.issuedDate = b.date and b.quarterEnd  between @startDate and  @date
 --and a.ispts=1
 and a.producttype ='PTS'
 group by isPts 
 order by 1 desc



 
  select replace( cast( avg(a.[Стоимость ТС])/1000.0 as nvarchar(max)) , '.', ',') [Стоимость ТС]
 from v_fa a join calendar_view b on a.issuedDate = b.date and b.quarterEnd between @startDate and  @date
 
 where a.producttype ='PTS'
 group by a.isPts 
 order by 1 desc



 

  select 
  replace(format(   sum(case when a.interestRate >0 then a.interestRate*a.issuedSum end)/ (sum(case when a.interestRate >0 then  a.issuedSum end) +0.0)/100.0 , '0.00000%') , '.', ',') СредняяСтавкаАвтозаймы
  ,
  replace(format(    sum(case when returnType='Первичный' and dbo.lcrm_is_inst_lead([Тип трафика] , Источник, null) =1  then issuedSum end)/
   (0.0+  sum(  case when returnType='Первичный' then issuedSum end  ) ) , '0.00000%') , '.', ',') ДоляИнстТрафикаВОбъемахНовых

 
 from v_fa a join calendar_view b on a.issuedDate = b.date and b.quarterEnd between @startDate and  @date
 and  a.producttype ='PTS'
 group by isPts 
 order by 1 desc




 select case when  [Тип продукта] like '%инстолл%' then 'Беззалог' else  'Залог' end  [Тип продукта]
, replace(format(  sum( case when  [Тип продукта] like '%инстолл%'    then [Остаток ОД] end)-- [Остаток ОД]
/ sum(case when 1=1 then [Остаток ОД] end) , '0.00000%') , '.', ',') ДоляБеззалог
from v_balance
where d=@date  
group by case when  [Тип продукта] like '%инстолл%' then 'Беззалог' else  'Залог' end 
with  rollup


 
  select 
 returnType2
  , replace(format(    count( issued)/    (0.0+  count( call1) ) , '0.00000%') , '.', ',') ЗаявкаЗайм

 
 from v_fa a join calendar_view b on  isnull(a.issuedDate , a.call1Date) = b.date                           and b.quarterEnd between @startDate and  @date
 and  a.producttype ='PTS' and a.isdubl=0
 group by  returnType2
with  rollup

 order by case when returnType2 is not null then 1 end   , returnType2



 drop table if exists [#t3737734]

 CREATE TABLE [dbo].[#t3737734]
(
      [Месяц] [DATETIME]
    , [Расчетная прибыль net] [FLOAT]
    , [Расчетная прибыль] [FLOAT]
    , [IsInstallment] [INT]
    , [t] [VARCHAR](21)
) 

insert into [#t3737734]

exec [dbo].[sale_report_add_product_agr] 


 --declare @date  date = '20250331'

 ;
 with v as (

 select *, case
 when t in ('КП') then '1) КП' 
 when t in ('Срочное снятие залога', 'СМС') then '2) Услуги' 
 when t in ('Платежи') then '3) Платежи' 
end type
 
 from [#t3737734]
where t<>'Продажа трафика'

 )
select type
, sum([Расчетная прибыль net])/1000000.0 [Расчетная прибыль net]
, sum([Расчетная прибыль])/1000000.0 [Расчетная прибыль]


from v a
join calendar_view b on  a.[Месяц] = b.date and b.quarterEnd between @startDate and  @date
 group by type
with  rollup

order by 1






 --declare @date  date = '20250331'


 select t
, sum([Расчетная прибыль net])/1000000.0 [Расчетная прибыль net]
 
from [#t3737734] a
join calendar_view b on  a.[Месяц] = b.date and b.quarterEnd between @startDate and  @date
where t='Продажа трафика'
group by t
order by 1




 --declare @date  date = '20240331'


  select 
 replace( format(   sum(case when 
	carBrand in (
	 'LIFAN'
,'GEELY'
,'CHERY'
,'GREAT WALL'
,'HAVAL'
,'FAW'
,'ЛИФАН'
,'DFM'
,'CHANGAN'
,'HOWO'
,'ДЖИЛИ'
,'ЧЕРРИ'
,'HAIMA'
,'SHACMAN'
,'SUV T11'
,'BRILLIANCE'
,'DONGFENG'
,'SDLG'
,'ХОВО'
,'БАВ'
,'SHAANQI'
,'SHAANXI'
,'DONG FENG'
,'BYD'
,'A21 VORTEX'
,'ДЖАК'
,'ДОНГ ФЕНГ'
,'YUTONG'
,'YANGZI'
,'ХОВЕР'
,'ЧАНГАН'
,'ШАКМАН'
,'ШАНКСИ'
,'ФОТОН'
,'ФАВ'
,'YUEJIN'
,'XGMA'
,'ZX'
,'БЕЙФАН БЕНЧИ'
,'ВОРТЕКС'
,'БИД'
,'ГРЕАТ WALL'
,'ГРЕЙТВОЛЛ'
,'МАКСУС'
,'TIEMA'
,'SUV T11 VORTEX'
,'SНАСМАN'
,'HAWTAI'
,'HIGER'
,'45422'
,'BEIFANG BENCHI'
,'KINGLONG'
,'LIUGONG'
,'ТUNLАND'
,'ТЯНЬЕ'
,'ХАВАЛ'
,'JMC'
,'NORTH BENZ'
,'ДЖЕЛИ'
,'СЫДА СЫТАЙЕР'
,'ШААНКСИ'
,'37026-0000010'
,'SINOTRUK'
,'ХАЙМА'
,'НОРТС БЕНЦ'
,'JAC'
,'CAMC'
,'FOTON'
,'ГРЕЙТ ВОЛЛ'
,'ЧЕРИ') then 1 end)/ (0.0+  sum(  1 ) )                                                                            , '0.00000%')  , '.', ',')  ДоляКитайскихАвто
 ,replace( format(sum(case when f.РегионПроживания in ('Московская', 'Москва') then 1 end  )/   (0.0+  sum(  1 ) )  , '0.00000%')  , '.', ',')  ДоляЦЕнтральногоРегиона
 ,replace( format( avg(age+0.0)                                                                                     , '0.000000' ) , '.', ',')  СреднийВозраст
 ,replace( cast( cast(  avg(monthlyIncome)    as bigint)/1000.0 as nvarchar(max))                                                  , '.', ',')  СреднийДоход
 ,replace( cast( cast(  avg(firstSchedulePay) as bigint)/1000.0  as nvarchar(max))                                                         , '.', ',')  СреднийЕжемесПлатеж

 from v_fa a 
 join calendar_view b on a.issuedDate = b.date and b.quarterEnd between @startDate and  @date  and a.producttype ='PTS'
 join _request r on a.number=r.number
 left join dm_factor_analysis f on f.Номер=a.number

  order by 1 desc


  ;


  
 with v as(
 
  select *, ROW_NUMBER() over(partition by recordlink order by calltime ) rn, cast(calltime as date) date from   sale_kpi_csi
  where isnumeric(mark)=1

 )

  select avg(cast(mark as float)) CSI from   v a 
 join calendar_view b on a.date = b.date and b.quarterEnd between @startDate and  @date

  where rn=1



--https://drive.google.com/open?id=1HWA7kZJ8EsUVld_ZWp-I8Of8BbFcwq_K&usp=drive_fs


  --select 100*0.0005549389567


  --select distinct region from request
  --order by 1