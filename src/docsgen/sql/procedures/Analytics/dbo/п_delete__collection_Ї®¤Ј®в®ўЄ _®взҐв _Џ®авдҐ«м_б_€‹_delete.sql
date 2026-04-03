
CREATE   proc  [dbo].[_collection_подготовка_отчета_Портфель_с_ИЛ]

as

begin


  drop table if exists #ils
  select код, min( case when [Тип ИЛ]<>'Обеспечительные меры' then isnull( isnull([Дата ИЛ] , [Дата получения ИЛ]), [Дата принятия ИЛ в работу] ) end) [Первая дата ИЛ] into #ils from
  [Analytics].[dbo].[_collection]
  group by код


  drop table if exists #t2

  ;
  with v as (
  select a.External_id, a.st_date, isnull(a.fact_end_date,'4444-01-01') fact_end_date, a.agent_name
from dwh_new.dbo.agent_credits a

  )



  select a.d,a.[d Месяц], a.Клиент, a.Код, a.[остаток од], a.[Дата закрытия], b.[Первая дата ИЛ], case when v.agent_name is not null then 'КА' else 'Кармани' end [КА / Кармани], [сумма поступлений]
  into #t2
  from v_balance a
  join #ils b on a.Код=b.Код and a.d >= b.[Первая дата ИЛ] 
  left join v on v.External_id=a.Код and a.d between st_date and fact_end_date


  drop table if exists #t3

  select [d Месяц],[КА / Кармани], sum(case when d=[d Месяц] then [остаток од] end)/1000000.0 [остаток од млн] , sum([сумма поступлений])/1000000.0 [сумма поступлений млн]
  --into #t3
  from #t2
  where [d Месяц] between  dateadd(month, -12, getdate()) and dateadd(month, -1, getdate())
  group by [d Месяц],[КА / Кармани]


 --drop table if exists dbo._collection_отчет_Портфель_с_ИЛ
 --select * into  dbo._collection_отчет_Портфель_с_ИЛ
 --from  #t3

  end