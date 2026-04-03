
CREATE proc  [dbo].[_birs_create_report_kpi_requests_pts]

as


begin


drop table if exists #t1
select Номер, [CPA трафик в МП источник], [Маркетинговые расходы] into #t1
from [v_Отчет стоимость займа опер]


drop table if exists #t2

;


with v as (
SELECT top (select * from _birs_top_N a)
--SELECT top 2
       [Номер]
	   ,cast(isnull([Заем выдан], [Верификация КЦ])  as date) [Отчетная дата]
      ,[Дубль]
      ,[ДатаЗаявкиПолная]
      ,[Место_создания_2]
      ,[Группа каналов]
      ,[Канал от источника]
      ,[Верификация КЦ]
      ,[Предварительное одобрение]
      ,[Встреча назначена]
      ,[Контроль данных]
      ,[Верификация документов клиента]
      ,[Call2]
      ,[Одобрены документы клиента]
      ,[Верификация документов]
      ,[Одобрено]
      ,[Отказано]
      ,[Отказ документов клиента]
      ,[Отказ клиента]
      ,[Аннулировано]
      ,[Заем выдан]
      ,[Выданная сумма]
      ,[Сумма одобренная]
      ,[Первичная сумма]
      ,[Сумма заявки]
      ,[СуммаВыдачиБезКП]
      ,[ПризнакКП]
      ,[СуммаДопУслуг]
      ,[СуммаДопУслугCarmoney]
      ,[СуммаДопУслугCarmoneyNet]
      ,ПризнакСтраховка
      ,[ПризнакКаско]
      ,[ПризнакСтрахованиеЖизни]
      ,[ПризнакРАТ]
      ,[ПризнакПозитивНастр]
      ,[ПризнакПомощьБизнесу]
      ,[ПризнакТелемедицина]
      ,[Признак Защита от потери работы]
      ,[SumKasko]
      ,[SumEnsur]
      ,[SumRat]
      ,[SumPositiveMood]
      ,[SumHelpBusiness]
      ,[SumTeleMedic]
      ,[SumCushion]
      ,[ПроцСтавкаКредит]
      ,[rn]
      ,[fpd0]
      ,[fpd4]
      ,[fpd7]
      ,[fpd30]
      ,[fpd60]
      ,[HR30_4]
      ,[HR90_12]
      ,[HR90_6]
      ,[full_prepayment_30]
      ,[full_prepayment_60]
      ,[full_prepayment_90]
      ,[full_prepayment_180]
      ,[created]
      ,[fa_created]
      ,[ФИО]
      ,[product]
      ,[user_os]
	  ,case when [Группа каналов] = 'CPA' then [Канал от источника] else [Группа каналов]  end [Группа каналов_2]
	  ,[Вид займа]
	  ,case when isInstallment=0 then 'ПТС' else 'Инстоллмент' end [Тип продукта ПТС/Инст]
	  ,isInstallment
	  ,Источник
	  ,[Тип трафика]
	  ,[Место cоздания]
  FROM reports.[dbo].[dm_Factor_Analysis]
 -- where дубль=0 and [группа каналов]<>'Тест'-- and isinstallment=0
 --order by Номер desc
  )



  select a.*
  , c.Месяц [Верификация КЦ Месяц]
  , c.Квартал [Верификация КЦ квартал]
  , c.[Квартал представление] [Верификация КЦ квартал представление]
  
  , z.Месяц [Заем выдан Месяц]
  , z.Квартал [Заем выдан квартал]
  , z.[Квартал представление] [Заем выдан квартал представление]
  	 into #t2
  from v a
  left join v_Calendar c on  cast(a.[Верификация КЦ] as date)=c.Дата
  left join v_Calendar z on  cast(a.[Заем выдан] as date)=z.Дата
   


;
with v as (

select *
,case when isnull(dbo.lcrm_is_inst_lead([Тип трафика] , Источник, null), isinstallment)=1 then 'Трафик инст' else 'Трафик ПТС' end [Трафик продукт]
from #t2 a

)

select a.*,  b.[CPA трафик в МП источник], b.[Маркетинговые расходы],
case when [Группа каналов_2] in ('CPA нецелевой', 'CPA полуцелевой', 'CPA целевой') 
then 
isnull([CPA трафик в МП источник], Источник) 
else [канал от источника]
end [Источник аналитический]


from v a
left join #t1 b on a.Номер=b.Номер

end