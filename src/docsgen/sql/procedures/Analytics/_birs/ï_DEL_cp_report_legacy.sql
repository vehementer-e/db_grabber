
CREATE   PROC [_birs].[cp_report_legacy]
@mode nvarchar(max) = '',
@start_date_ssrs date = null
as 
 return
 set  @start_date_ssrs = (select min(Год) from v_Calendar where Дата=dateadd(year, -1, cast(getdate() as date)))

 
IF 	@mode =  'AgreementBezzalog'

begin

with ref_hardcode as (
  select cast(format([Дата_расторжения], 'yyyy-MM-01') as date) m
, sum([сумма_коммиссии]) n
, sum([сумма_коммиссии]) n_net
, count(distinct [Договор]) o
  from
(
 

SELECT [Дата_договора]
      ,[Дата расторжения]	[Дата_расторжения]
      ,[Дата расторжения месяц]
      ,number   [Договор]
      ,[Код продукта]
      ,[Продукт]
      ,[сумма услуги]
      ,[сумма коммиссии]  [сумма_коммиссии]
 
  FROM [dbo].[v_refuses_CP]
  where 1=0
 


  )b
  group by cast(format([Дата_расторжения], 'yyyy-MM-01') as date)
 
)

select 
ДоговорНомер = Номер,
[Вид займа_2] = case [Вид займа] when 'Первичный' then 'Первичный' else 'Повторный' end,
[Группа каналов_2] = case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end,
Признак4050 = case when product = 'Первичные: RBP - 40' then 1 else 0 end,
product,
case 
		when [Место создания 2]='МП' then 'МП'
		when [Место создания 2]='КЦ' then 'Офисы: КЦ'
		when [Место создания 2]='Партнеры' then 'Офисы: партнеры'
		end as КаналОформления ,
case when product='Исп. срок' Then 1 else 0 end ИспытательныйСрок,
cast( [Заем выдан] as date) ДатаВыдачи,
cast(format( [Заем выдан]  , 'yyyy-MM-01') as date) МесяцВыдачи,
cast([Выданная сумма] as float) СуммаВыдачи,
[Выданная сумма]-[Сумма Дополнительных Услуг] [СуммаВыдачиБезКП],
[Сумма Дополнительных Услуг] СуммаДопУслуг,
[Сумма Дополнительных Услуг Carmoney] СуммаДопУслугCarmoney ,
[Сумма Дополнительных Услуг Carmoney Net] СуммаДопУслугCarmoneyNet ,
[Признак Комиссионный Продукт] ПризнакКП,
[Признак Страховка] ПризнакСтраховка,
   [Признак Безопасность семьи] [Признак Безопасность семьи] ,
   [Сумма Безопасность семьи] ,
   [Сумма Безопасность семьи carmoney] ,
   [Сумма Безопасность семьи carmoney Net] ,
ref_hardcode.n,
ref_hardcode.n_net,
ref_hardcode.o--,

from v_fa agr
left join ref_hardcode on cast(format( [Заем выдан]  , 'yyyy-MM-01') as date)=ref_hardcode.m 

--where cast( [Заем выдан] as date) >=@start_date_ssrs  and isPts=1
where cast( [Заем выдан] as date) >=@start_date_ssrs  and isPts=0
and cast( [Заем выдан] as date) >='20250101'

end


 
IF 	@mode =  'PlansBezzalog'

begin

with  cc_plans as (

SELECT  
       cast(a.День as date) [Дата]
      ,cast(format(a.День, 'yyyy-MM-01') as date) Месяц
      ,Сумма   [Займы руб]
      , 1 [Факт/План]
      ,[КП net] [План КП]
      ,[КП net]  [План КП аналитический по дням]
      ,getdate() [created]
  FROM  sale_plan_view a 

  
  
  )

  select 
  sum([Займы руб]) ПланВыдачи,
  sum([План КП аналитический по дням]) ПланКП,
  sum(case when Дата<cast(getdate() as date) then [План КП аналитический по дням] end) ПланКППоВчерашнийДень,
  Месяц
  from cc_plans
  where Месяц is not null and 1=0
  group by Месяц





end


 

IF 	@mode =  'Agreement'

begin

with ref_hardcode as (
  select cast(format([Дата_расторжения], 'yyyy-MM-01') as date) m
, sum([сумма_коммиссии]) n
, sum([сумма_коммиссии]) n_net
, count(distinct [Договор]) o
  from
(
 

SELECT [Дата_договора]
      ,[Дата расторжения]	[Дата_расторжения]
      ,[Дата расторжения месяц]
      ,number   [Договор]
      ,[Код продукта]
      ,[Продукт]
      ,[сумма услуги]
      ,[сумма коммиссии]  [сумма_коммиссии]
 
  FROM [dbo].[v_refuses_CP]
 


  )b
  group by cast(format([Дата_расторжения], 'yyyy-MM-01') as date)
 
)

select 
ДоговорНомер = Номер,
[Вид займа_2] = case [Вид займа] when 'Первичный' then 'Первичный' else 'Повторный' end,
[Группа каналов_2] = case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end,
Признак4050 = case when product = 'Первичные: RBP - 40' then 1 else 0 end,
product,
case 
		when [Место создания 2]='МП' then 'МП'
		when [Место создания 2]='КЦ' then 'Офисы: КЦ'
		when [Место создания 2]='Партнеры' then 'Офисы: партнеры'
		end as КаналОформления ,
case when product='Исп. срок' Then 1 else 0 end ИспытательныйСрок,
cast( [Заем выдан] as date) ДатаВыдачи,
cast(format( [Заем выдан]  , 'yyyy-MM-01') as date) МесяцВыдачи,
cast([Выданная сумма] as float) СуммаВыдачи,
[Выданная сумма]-[Сумма Дополнительных Услуг] [СуммаВыдачиБезКП],
[Сумма Дополнительных Услуг] СуммаДопУслуг,
[Сумма Дополнительных Услуг Carmoney] СуммаДопУслугCarmoney ,
[Сумма Дополнительных Услуг Carmoney Net] СуммаДопУслугCarmoneyNet ,
[Признак Комиссионный Продукт] ПризнакКП,
[Признак Страховка] ПризнакСтраховка,
[Признак Страхование Жизни] ПризнакСтрахованиеЖизни,
[Сумма страхование жизни] SumEnsur,
[Сумма страхование жизни Carmoney] SumEnsurCarmoney ,
[Сумма страхование жизни Carmoney Net] SumEnsurCarmoneyNet ,
[Признак Защита от потери работы],
[Сумма Защита от потери работы] SumCushion,
[Сумма Защита от потери работы Carmoney Net] SumCushionCarmoneyNet,
[Сумма Защита от потери работы Carmoney] SumCushionCarmoney ,
[Признак Каско] ПризнакКаско,
[Сумма КАСКО] SumKasko,
[Сумма КАСКО Carmoney] SumKaskoCarmoneyNet,
[Сумма КАСКО Carmoney Net] SumKaskoCarmoney ,
[Признак Помощь Бизнесу] ПризнакПомощьБизнесу,
[Сумма Помощь бизнесу] SumHelpBusiness,
[Сумма Помощь бизнесу Carmoney] SumHelpBusinessCarmoney ,
[Сумма Помощь бизнесу Carmoney Net]  SumHelpBusinessCarmoneyNet,
[Признак РАТ] ПризнакРАТ,
[Сумма РАТ] SumRat,
[Сумма РАТ Carmoney] SumRatCarmoney ,
[Сумма РАТ Carmoney Net] SumRatCarmoneyNet ,
[Признак Телемедицина] ПризнакТелемедицина,
[Сумма Телемедицина]    SumTeleMedic ,
[Сумма Телемедицина Carmoney] SumTeleMedicCarmoney ,
[Сумма Телемедицина Carmoney Net] SumTeleMedicCarmoneyNet ,
[Признак Фарма] ПризнакФарма,
[Сумма Фарма] SumPharma,
[Сумма Фарма Carmoney] SumPharmaCarmoney ,
[Сумма Фарма Carmoney Net] SumPharmaCarmoneyNet,
[Сумма Спокойная Жизнь] SumQuietLife ,
[Сумма Спокойная Жизнь Carmoney] SumQuietLifeCarmoney ,
[Сумма Спокойная Жизнь Carmoney Net] SumQuietLifeCarmoneyNet ,
[Признак Спокойная Жизнь] ПризнакСпокойнаяЖизнь,	  
[Сумма РАТ Юруслуги] [Сумма РАТ Юруслуги] ,
 [Сумма РАТ Юруслуги Carmoney] [Сумма РАТ Юруслуги Carmoney] ,
 [Сумма РАТ Юруслуги Carmoney net] [Сумма РАТ Юруслуги Carmoney net] ,
 [Признак РАТ Юруслуги]  [Признак РАТ Юруслуги],   	  
[Сумма Автоспор]              [Сумма Автоспор] ,
 [Сумма Автоспор Carmoney]    [Сумма Автоспор Carmoney] ,
 [Сумма Автоспор Carmoney net] [Сумма Автоспор Carmoney net] ,
 [Признак Автоспор]           [Признак Автоспор],
ref_hardcode.n,
ref_hardcode.n_net,
ref_hardcode.o--,

from v_fa agr
left join ref_hardcode on cast(format( [Заем выдан]  , 'yyyy-MM-01') as date)=ref_hardcode.m

--where cast( [Заем выдан] as date) >=@start_date_ssrs  and isPts=1
where cast( [Заем выдан] as date) >=@start_date_ssrs  and isPts=1

end


IF 	@mode =  'Plans'

begin

with  cc_plans as (

SELECT  
       cast(a.День as date) [Дата]
      ,cast(format(a.День, 'yyyy-MM-01') as date) Месяц
      ,Сумма   [Займы руб]
      , 1 [Факт/План]
      ,[КП net] [План КП]
      ,[КП net]  [План КП аналитический по дням]
      ,getdate() [created]
  FROM  sale_plan_view a 

  
  
  )

  select 
  sum([Займы руб]) ПланВыдачи,
  sum([План КП аналитический по дням]) ПланКП,
  sum(case when Дата<cast(getdate() as date) then [План КП аналитический по дням] end) ПланКППоВчерашнийДень,
  Месяц
  from cc_plans
  where Месяц is not null
  group by Месяц





end

 