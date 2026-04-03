/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/

CREATE proc [dbo].[create_report_chdp]
as

begin




drop table if exists #chdp
SELECT [Договор] [Договор ссылка]
      ,CRMClientGUID CRMClientGUID
      ,[Дата выдачи] [Дата выдачи]
      ,[код] [код договора]
      ,[Дата заявления на ЧДП] [Дата заявления на ЧДП]
      ,[Дата заявления на ЧДП день] [Дата заявления на ЧДП день]
      ,[Дата заявления на ЧДП месяц] [Дата заявления на ЧДП месяц]
,      case when [Дата заявления на ЧДП день]<=dateadd(day, 14, [Дата выдачи день]) then 1 else 0 end [Признак заявление на ЧДП 14 дней]
, ROW_NUMBER() over(partition by [код], [Дата заявления на ЧДП месяц] order by [Дата заявления на ЧДП]) rn
, ROW_NUMBER() over(order by [Дата заявления на ЧДП]) chdp_id
	  into #chdp
  FROM [Analytics].[dbo].[v_Документ_ЗаявлениеНаЧДП]
where [Дата заявления на ЧДП]>='20210101'



  drop table if exists #t2
  select a.*, x.* into #t2 from #chdp a outer apply 
  
  (select top 1 
 [Дата]
,[Дата платежа день]
,[Дата платежа месяц]
,[Дата платежа месяц номер]
,[Дата платежа год номер]
,[Срок жизни займа к платежу]
,[Дата выдачи месяц номер]
,[Дата выдачи год номер]
,[Дата выдачи месяц]
,[Сумма платежа]
,[ссылка]
,[Договор]
,[Код]
,[Платежная система]
,[Номер платежа]
--,[CRMClientGUID]
,[Комиссия с клиента]
,[Доход с клиента]
,[Комиссия ПШ]
,[Платеж онлайн с комиссией для клиента]
,[Вид платежа]
,[Прибыль]
,[Дата погашения]
,[Платеж в день погашения]
--,[d]
,[Платеж просрочка]
  from report_repayments b where a.CRMClientGUID=b.CRMClientGUID and b.Дата between dateadd(day, 0, a.[Дата заявления на ЧДП] ) and dateadd(day, 31, [Дата заявления на ЧДП]) order by Дата) x


 -- select * from #t2

  drop table if exists #dm_CMRExpectedRepayments
  select * into #dm_CMRExpectedRepayments from reports.dbo.dm_CMRExpectedRepayments r join (select distinct [Договор ссылка] from #chdp) a on r.Договор=a.[Договор ссылка]
  
 -- sp_help 'Analytics.dbo.report_repayments'
  drop table if exists #balance

  select r.* ,ПроцентнаяСтавкаНаТекущийДень/36500 [Проценты в день] into #balance from reports.dbo.dm_CMRStatBalance_2 r join (select distinct [код договора] from #chdp) a on r.external_id=a.[код договора]

  drop table if exists Analytics.dbo.report_chdp
  ;

  with ways as (
   select 1   d_n union all
   select 2	  d_n union all
   select 3	  d_n union all
   select 4	  d_n union all
   select 5	  d_n union all
   select 6	  d_n union all
   select 7	  d_n union all
   select 8	  d_n union all
   select 9	  d_n union all
   select 10  d_n union all
   select 11  d_n union all
   select 12  d_n union all
   select 13  d_n union all
   select 14  d_n union all
   select 15  d_n union all
   select 16  d_n union all
   select 17  d_n union all
   select 18  d_n union all
   select 19  d_n union all
   select 20  d_n union all
   select 21  d_n union all
   select 22  d_n union all
   select 23  d_n union all
   select 24  d_n union all
   select 25  d_n union all
   select 26  d_n union all
   select 27  d_n union all
   select 28  d_n 
   )

 , v as (
select datediff(day, [Дата заявления на ЧДП], Дата )                     [Прошло дней от ЧДП до Платежа]
,      datediff(day, [Дата заявления на ЧДП], [Ближайшая Дата Платежа] ) [За сколько дней до платежа было оставлено заявление]
,      datediff(day, [Дата заявления на ЧДП], balance_d ) [Через сколько дней списали проценты]
,      ways.d_n [Новый продукт параметр]
,      case when ways.d_n-datediff(day, [Дата заявления на ЧДП], balance_d )<0 or [Признак заявление на ЧДП 14 дней]=1 then 0 else ways.d_n-datediff(day, [Дата заявления на ЧДП], balance_d ) end [Экстра дней]

,      a.[Платеж в день погашения]    [Платеж в день погашения]             
,      b.[Закрыт в дату списания процентов]    [Закрыт в дату списания процентов]                             
,      b.balance_d          
,      a.chdp_id          
,		ROW_NUMBER() over(partition by [код договора]   ,  b.balance_d  ,  ways.d_n order by chdp_id desc ) rn_for_check
,      b.[проценты уплачено]                                
,      b.[основной долг уплачено]                                
,      b.[основной долг уплачено]*b.[Проценты в день] [Экстра процентный доход в день]         
,      a.[Признак заявление на ЧДП 14 дней]
,      case when Дата is null then 1 else 0 end  [Не внес]
,      x.[Ближайшая Дата Платежа]   [Ближайшая Дата Платежа]                                    
,      a.[Дата заявления на ЧДП]                                
,      a.[Дата заявления на ЧДП день]                                
,      a.[Дата заявления на ЧДП месяц]                                  
,      a.CRMClientGUID                                
,      a.[код договора]       
,      a.[Дата]
,      a.[Дата платежа день]
,      a.[Дата платежа месяц]
,      a.[Дата платежа месяц номер]
,      a.[Дата платежа год номер]
,      a.[Срок жизни займа к платежу]
,      a.[Дата выдачи месяц номер]
,      a.[Дата выдачи год номер]
,      a.[Дата выдачи месяц]
,      a.[Сумма платежа]
,      a.[ссылка]
,      a.[Договор]
,      a.[Код]
,      a.[Платежная система]
,      a.[Номер платежа]
--,      a.[CRMClientGUID]
,      a.[Комиссия с клиента]
,      a.[Доход с клиента]
,      a.[Комиссия ПШ]
,      a.[Платеж онлайн с комиссией для клиента]
,      a.[Вид платежа]
,      a.[Прибыль]
,      a.[Дата погашения]
,[Платеж просрочка]

from        #t2             a
cross join ways
outer apply (select top 1 ДатаПлатежа [Ближайшая Дата Платежа]
	from #dm_CMRExpectedRepayments r
	where a.[код договора]=r.Код
		and r.ДатаПлатежа >= cast([Дата заявления на ЧДП] as date)
	order by r.ДатаПлатежа) x

outer apply (select top 1 d balance_d, case when d=ContractEndDate then 1 else 0 end [Закрыт в дату списания процентов], [основной долг уплачено] , [проценты уплачено] , [Проценты в день] 
	from #balance r
	where a.[код договора]=r.external_id
		and r.d between cast([Дата заявления на ЧДП] as date) and dateadd(day, 31, cast([Дата заявления на ЧДП] as date))
		and [основной долг уплачено]>0
	order by r.d ) b 
	where b.balance_d is not null
)

select [Экстра процентный доход в день]*[Экстра дней] [Экстра процентный доход]
,      *                                               
	into Analytics.dbo.report_chdp

from v
where rn_for_check=1

select * from Analytics.dbo.report_chdp 
where rn_for_check=2 and [Новый продукт параметр]=28
order by [код договора], balance_d,  [Дата заявления на ЧДП], [Новый продукт параметр]




  drop table if exists #balance

 -- select r.* , into #balance_pdp from reports.dbo.dm_CMRStatBalance_2 r 
 -- where ContractEndDate=d and d>='20210101'
 




 drop table if exists #ExpectedRepayments
  ;
with ExpectedRepayments
as
(
	select a.[Код]              
	,      a.[Договор]          
	,      a.[Регистратор]      
	,      v.[Дата графика]      [Дата графика]
	,      a.[НомерПлатежа]     
	,      a.[ДатаПлатежа]      
	,      a.[СуммаПлатежа]     
	,      a.[ИспытательныйСрок]
	,      a.[create_at]        
	,      v.[ОД]                [ОД]
	,      v.[Процент]           [Процент]
	,      v.[ОстатокОД]         [ОстатокОД]


	from      reports.dbo.dm_CMRExpectedRepayments                  a
	left join Analytics.dbo.v_РегистрСведений_ДанныеГрафикаПлатежей v on a.Регистратор=v.Регистратор and a.ДатаПлатежа=v.[Дата платежа]
	left join Analytics.dbo.v_Справочник_Договоры d on d.[Ссылка договор CMR]=a.Договор
--where case when ДатаПлатежа<Погашен or Погашен is null then 1 else 0 end = 1
)

select * into #ExpectedRepayments from ExpectedRepayments

select * from 
#ExpectedRepayments
where Код='21040600095019'








drop table if exists #chdp1


SELECT a.[Договор] [Договор ссылка]
      ,a.CRMClientGUID CRMClientGUID
      ,a.[Дата выдачи] [Дата выдачи]
      ,a.[код] [код договора]
      ,a.[Дата заявления на ЧДП] [Дата заявления на ЧДП]
      ,a.[Дата заявления на ЧДП день] [Дата заявления на ЧДП день]
      ,a.[Дата заявления на ЧДП месяц] [Дата заявления на ЧДП месяц]
--,      case when a.[Дата заявления на ЧДП день]<=dateadd(day, 14, [Дата выдачи день]) then 1 else 0 end [Признак заявление на ЧДП 14 дней]
--, ROW_NUMBER() over(partition by [код], [Дата заявления на ЧДП месяц] order by [Дата заявления на ЧДП]) rn
--, ROW_NUMBER() over(order by [Дата заявления на ЧДП]) chdp_id


	  into #chdp1
  FROM [Analytics].[dbo].[v_Документ_ЗаявлениеНаЧДП] a


  
  drop table if exists #balance1
 

select r.*                                
,      ПроцентнаяСтавкаНаТекущийДень/36500 [Проценты в день] 
,      er.[Дата графика]
--,      er_next.[Дата графика] [Дата следующего графика]
,      isnull(er.ДатаПлатежа, x.ДатаПлатежа) ДатаПлатежа 
,      er.[Процент]
,      r.[Проценты начислено] [Проценты начислено1]
,      er.[ОД]
,      r.[основной долг начислено] [основной долг начислено1]


,  r.[основной долг начислено]-isnull(er.[ОД], x.[ОД]) [ОД дельта]
,  r.[Проценты начислено]-er.[Процент] [Процент дельта]

into #balance1
from      reports.dbo.dm_CMRStatBalance_2 r 
outer apply (select top 1 er_.[ОД], er_.ДатаПлатежа from #ExpectedRepayments              er_ where er_.Код=r.external_id and er_.ДатаПлатежа>=r.d and (d=ContractEndDate) order by er_.ДатаПлатежа  ) x
left join #ExpectedRepayments              er on er.Код=r.external_id and er.ДатаПлатежа=r.d and (d<>ContractEndDate or ContractEndDate is null)
--left join #ExpectedRepayments er_next on er_next.Код =er.Код and er.НомерПлатежа+1=er_next.НомерПлатежа and (d<>ContractEndDate or ContractEndDate is null)
where (
		 [основной долг уплачено]>0)
	and d >= '20201101'-- and '20210430'
	and ContractStartDate>='20200901' 
	and (
		ПереплатаУплачено>0 or [сумма поступлений]>0)


		select * from #balance1





drop table if exists #t1

select count(*) over (partition by external_id) [cnt]
--,      [Договор ссылка]
--,      [CRMClientGUID]
,      [Дата выдачи]
,      [код договора]
--,      case when [Дата следующего графика]=[Дата графика] then 1 end as [График не сдвинулся]
--,      СуммаПоступлений
,      case when d = ContractEndDate and ContractEndDate between ContractStartDate and dateadd(day, 14, ContractStartDate) then 1 else null end as [zero_profit]
,      datediff(day, [Дата графика], [Дата заявления на ЧДП]) [[Дата графика -  [Дата заявления на ЧДП]
,      datediff(day, [Дата заявления на ЧДП], [d]) [[Дата заявления на ЧДП -  [d]
--,      datediff(day, [d], [Дата следующего графика]) [d -  [Дата следующего графика]
,      [Дата заявления на ЧДП день]
,      [СуммаПоступлений].[СуммаПоступлений]
,      [СуммаПоступлений].[Дата первого платежа день]
,      d
,      [Дата заявления на ЧДП]

, case when ContractEndDate=d then 1 else 0 end as [ПДП]

,      [ContractStartDate]
,      ContractEndDate
,      [external_id]
,      [Сумма]
,      [основной долг начислено]
,      [основной долг уплачено]
,      [Проценты начислено]
,      [Проценты уплачено]
--,      [ПениНачислено]
--,      [ПениУплачено]
--,      [ГосПошлинаНачислено]
--,      [ГосПошлинаУплачено]
,      [ПереплатаНачислено]
,      [ПереплатаУплачено]
--,      [остаток од]
--,      [остаток %]
--,      [остаток пени]
--,      [остаток иное (комиссии, пошлины и тд)]
--,      [остаток всего]
,      [сумма поступлений]
,      [ПлатежнаяСистема]
,      [сумма поступлений  нарастающим итогом]
--,      [основной долг начислено нарастающим итогом]
--,      [основной долг уплачено нарастающим итогом]
--,      [Проценты начислено  нарастающим итогом]
--,      [ПениНачислено  нарастающим итогом]
--,      [ГосПошлинаНачислено  нарастающим итогом]
--,      [Проценты уплачено  нарастающим итогом]
--,      [ПениУплачено  нарастающим итогом]
--,      [ГосПошлинаУплачено  нарастающим итогом]
--,      [ПереплатаНачислено нарастающим итогом]
--,      [ПереплатаУплачено нарастающим итогом]
,      [ПроцентыПоГрафику]
,      [Дата графика]
,      [ДатаПлатежа]
,      [Процент]
,      [Проценты начислено1]
,      [ОД]
,      [основной долг начислено1]
,      [ОД дельта]*case when d = ContractEndDate and ContractEndDate between ContractStartDate and dateadd(day, 14, ContractStartDate) then null else 1 end [ОД дельта]
,      [Процент дельта]
,      [Проценты в день]
into #t1
from #balance1 b
outer apply (select top 1 * from #chdp1 chdp where chdp.[Дата заявления на ЧДП день]<=d and cast( devdb.[dbo].[FullMonthsSeparation_pi] ([Дата заявления на ЧДП день] , d) as int) =0  and chdp.[код договора]=b.external_id order by case when [Дата заявления на ЧДП день]=d then 1 else 0 end desc, [Дата заявления на ЧДП день] desc )  chdp
outer apply(select sum(r.[Сумма платежа])  СуммаПоступлений, min(r.[Дата платежа день])  [Дата первого платежа день] from report_repayments r where r.Код=b.external_id and  r.[Дата платежа день] between [Дата заявления на ЧДП день] and b.d ) СуммаПоступлений
where (ДатаПлатежа is not null  or ContractEndDate=d) and ( [Дата заявления на ЧДП день] is not null or ContractEndDate=d)
and ([dpd day-1] is null or [dpd day-1]=0)

and (СуммаПоступлений.СуммаПоступлений>0 or ContractEndDate=d)
and ([ОД дельта]>0 or ContractEndDate=d)


  
  --select * from #t1
  --order by external_id, d
  ;
  with v as (

select       [cnt]
,            [Дата выдачи]
,            [код договора]
,            [СуммаПоступлений] 
,            case   when  [zero_profit]=1 then 0 
                     when [ПДП]=1  then datediff(day, ContractEndDate, ДатаПлатежа)
                       when [Дата заявления на ЧДП] is null then 30
                       when 28-[[Дата заявления на ЧДП -  [d]<0  then 0 
                       else 30                                             end [Экстра дней]
					   , case when  [ПДП] =0 then  datediff(day, [Дата первого платежа день], d) end [Экстра дней чдп]
,            [Дата заявления на ЧДП]
       ,[Дата первого платежа день]


,            [d]
,            cast(format(  [d] , 'yyyy-MM-01') as date) Месяц  
,            cast(format(  [ContractStartDate] , 'yyyy-MM-01') as date) [Дата выдачи Месяц]
,            [ContractStartDate]
,            [ContractEndDate]
,            [ПДП]
,            [external_id]
,            [Сумма]
,            [основной долг начислено]
,            [основной долг уплачено]
,            [Проценты начислено]
,            [Проценты уплачено]
,            [ПереплатаНачислено]
,            [ПереплатаУплачено]
,            [сумма поступлений]
,            [ПлатежнаяСистема]
,            [сумма поступлений  нарастающим итогом]
,            [ПроцентыПоГрафику]
,            [Дата графика]
,            [ДатаПлатежа]
,            [Процент]
,            [Проценты начислено1]
,            [Проценты в день]
,            [ОД]
,            [основной долг начислено1]
,            [ОД дельта]
,            [Процент дельта]
from #t1


)

, profit as (
select [ОД дельта]*[Проценты в день]*[Экстра дней] profit ,[ОД дельта]*[Проценты в день]*[Экстра дней чдп] profit2 , * 

from v
--where [Новый продукт параметр]=28
)
, profit_clean  as (select *, row_number() over(partition by  [external_id] order by profit desc) rn from profit ) 


--select * from profit_clean
----where rn=1
----53234012,27
--
--\
--


select [ПДП] , Месяц, --[Дата выдачи Месяц], 

sum(profit) profit , sum(profit2) profit2 from profit_clean
group by [ПДП], Месяц--, [Дата выдачи Месяц]
order by  [ПДП], Месяц--, [Дата выдачи Месяц]

select * from #chdp1



  ;

--  with  v as ( 
--  select 
--  case when isnull([dpd day-1], 0)>0                                                           then '0) Платеж из просрочки'
--       when ContractEndDate>=dateadd(month, 12, ContractStartDate)   and ContractEndDate=d     then '1) Погашение (срок жизни >12 мес.)'
--       when x.[Дата заявления на ЧДП] is not null and ContractEndDate=d                        then '2) Полное досрочное погашение c заявлением на ЧДП - без просрочки'
--       when x.[Дата заявления на ЧДП] is null     and ContractEndDate=d                        then '3) Полное досрочное погашение без заявления на ЧДП - без просрочки'
--       when x.[Дата заявления на ЧДП] is not null  and [Признак заявление на ЧДП 14 дней]=1    then '5) ЧДП - заявление до 14 дней'
--       when x.[Дата заявления на ЧДП] is not null                                              then '6) ЧДП'
--       when x.[Дата заявления на ЧДП] is null                                                  then '7) Обычный платеж'
--	   end Тип
--     
--  ,
--    case when isnull([dpd day-1], 0)>0                                                              then  null                                                      -- '0) Платеж из просрочки' 
--         when ContractEndDate>=dateadd(month, 12, ContractStartDate)   and ContractEndDate=d        then DATEDIFF(day, [Дата заявления на ЧДП], d )			      -- '1) Погашение (срок жизни >12 мес.)'
--         when x.[Дата заявления на ЧДП] is not null and ContractEndDate=d                           then null												          -- '2) Полное досрочное погашение c заявлением на ЧДП - без просрочки'
--         when x.[Дата заявления на ЧДП] is null     and ContractEndDate=d                           then null												          -- '3) Полное досрочное погашение без заявления на ЧДП - без просрочки'
--         when x.[Дата заявления на ЧДП] is not null  and [Признак заявление на ЧДП 14 дней]=1       then null												          -- '5) ЧДП - заявление до 14 дней'
--         when x.[Дата заявления на ЧДП] is not null                                                 then DATEDIFF(day, [Дата заявления на ЧДП], d )			      -- '6) ЧДП'
--         when x.[Дата заявления на ЧДП] is null                                                     then null												          -- '7) Обычный платеж'
--	   end   [Дельта дней] 
--  , case when ContractEndDate=d then 1 else 0 end as [День закрытия] 
--  , [основной долг начислено]-[основной долг уплачено]
--  ,ways.d_n [Новый продукт параметр]
--   , *
--
--  from #balance1 b
--cross join (
--   select 1   d_n
--   --union all
--   --select 2	  d_n union all
--   --select 3	  d_n union all
--   --select 4	  d_n union all
--   --select 5	  d_n union all
--   --select 6	  d_n union all
--   --select 7	  d_n union all
--   --select 8	  d_n union all
--   --select 9	  d_n union all
--   --select 10  d_n union all
--   --select 11  d_n union all
--   --select 12  d_n union all
--   --select 13  d_n union all
--   --select 14  d_n union all
--   --select 15  d_n union all
--   --select 16  d_n union all
--   --select 17  d_n union all
--   --select 18  d_n union all
--   --select 19  d_n union all
--   --select 20  d_n union all
--   --select 21  d_n union all
--   --select 22  d_n union all
--   --select 23  d_n union all
--   --select 24  d_n union all
--   --select 25  d_n union all
--   --select 26  d_n union all
--   --select 27  d_n union all
--   --select 28  d_n 
--   )
--ways
--
--  outer apply (select top 1 * from #chdp1 c where b.external_id=c.[код договора] and c.[Дата заявления на ЧДП день] between dateadd(day, - 31, d) and d order by [Дата заявления на ЧДП день] desc ) x
--
--  )
--
--  , v_v as (
--  select *
--,      (case when cast(left(Тип, 1) as int) in (2, 6)
--														 then    case when [Новый продукт параметр]-[Дельта дней]<0  then 0  else [Новый продукт параметр]-[Дельта дней] end
--			 when cast(left(Тип, 1) as int) in (3)
--														 then    [Новый продукт параметр] 
--		end	 
--			 
--			 )*[основной долг уплачено]*[Проценты в день] [Экстра профит]
--
--  from  v
--
--
--  )
--
--
--  select  [Новый продукт параметр], Тип,  sum([Экстра профит]) [Экстра профит] from  v_v
--  group by [Новый продукт параметр], Тип
--  order by [Новый продукт параметр], Тип

end