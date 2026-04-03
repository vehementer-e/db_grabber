

CREATE   proc  [_birs].[kpi_report]  @mode nvarchar(max) = 'requests'

as
 
begin 
 
if @mode = 'request2'
select  top (select * from _birs_top_N a)  number, call1,  lastCommunicationCreated, parentGuid from _request with(nolock) where call1 is not null

if @mode = 'prod'
	begin
	drop table if exists _birs_top_N 
	select 1000000000 topN  into _birs_top_N 
	--exec birs 'kpi'
	exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'E5EAE794-D01D-4D5E-A48A-52B41C19C9FA'
    end



	
	if @mode = 'dev'
	   begin
	   drop table if exists _birs_top_N 
	   select 1000 topN  into _birs_top_N 
	   end

--exec   [_birs].[kpi_report] 'dev'
--exec   [_birs].[kpi_report] 'prod'





if @mode = 	   'requests'
begin



drop table if exists #t0
select top (select * from _birs_top_N a) Номер, [Причина отказа] 
into #t0
from v_fa 
			
drop table if exists #tt0
select top (select * from _birs_top_N a) number, utmSource
into #tt0
from v_request
									


drop table if exists #t1
select top (select * from _birs_top_N a) Номер, [CPA трафик в МП источник], [Маркетинговые расходы]
, Медийка 
, [Расходы на CPA]
, [Продажа трафика net]
into #t1
from v_request_costs

--select Номер, isPTS  into #products from reports.dbo.dm_factor_analysis_001


drop table if exists #t2

;


with v as (
SELECT top (select * from _birs_top_N a)
--SELECT top 2
       a.[Номер]
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
      ,[Call2 accept]
      ,[Одобрены документы клиента]
      ,[Верификация документов]
      ,case when ([Call2 accept] is not null or [Одобрено] is not null) and isnull(isnull(Отказано, [Отказ документов клиента]), [Одобрено]) is not null then 1 else 0 end [Признак не застрял после Call2 accept]

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
	  ,case when a.isPts=1 then  'ПТС' else 'Инстоллмент' end [Тип продукта ПТС/Инст]
	  ,isInstallment
	 ,Источник
	  ,[Тип трафика]
	  ,[Место cоздания]
	 
  FROM reports.[dbo].[dm_Factor_Analysis]	a
 -- left join #products p on a.Номер=p.Номер
 -- where дубль=0 and [группа каналов]<>'Тест'-- and isinstallment=0
 --order by Номер desc
  )



  select a.*
  , c.Неделя [Верификация КЦ Неделя]
  , c.Месяц [Верификация КЦ Месяц]
  , c.Квартал [Верификация КЦ квартал]
  , c.[Квартал представление] [Верификация КЦ квартал представление]
  
  , z.Неделя [Заем выдан Неделя]
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

select a.*,  b.[CPA трафик в МП источник]
, b.[Маркетинговые расходы]
, b.[Медийка]
, b.[Расходы на CPA]
,
case when [Группа каналов_2] in ('CPA нецелевой', 'CPA полуцелевой', 'CPA целевой') 
then 
isnull([CPA трафик в МП источник], Источник) 
else [канал от источника]
end [Источник аналитический]
, b.[Продажа трафика net]
, b1.[Причина отказа]
, b2.utmSource

from v a
left join #t1 b on a.Номер=b.Номер
left join #t0 b1 on a.Номер=b1.Номер
left join #tt0 b2 on a.Номер=b2.number


end




end
