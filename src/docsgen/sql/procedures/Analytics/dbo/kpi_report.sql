CREATE    proc  [dbo].[kpi_report]  @mode nvarchar(max) = 'requests'

--exec  [kpi_report] 'dev'
--exec   [kpi_report] 'prod'

as
  
 /*
if @mode = 'request2'
select  top (select * from _birs_top_N a)  number, call1,  lastCommunicationCreated,  lastLoyalCommunicationCreated, parentGuid

,[hasLeadBankiruDeepapi]       
,[hasLeadBankiruDeepapiPts]	
,[hasLeadBankiruInstallmentCheck]	
from _request with(nolock) where call1 is not null

if @mode = 'prod'
	begin
	drop table if exists _birs_top_N 
	select 1000000000 topN  into _birs_top_N 
	--exec birs 'kpi'
 exec sp_birs_update '117718D2-B489-4D2C-9E4F-3AFDD51F8109'
    end



	
	if @mode = 'dev'
	   begin
	   drop table if exists _birs_top_N 
	   select 100000 topN  into _birs_top_N 
	   end





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
select top (select * from _birs_top_N a) number Номер, [CPA трафик в МП источник], marketingCost [Маркетинговые расходы]
, marketingCostMedia Медийка 
, marketingCostCpa [Расходы на CPA]
, sellTrafficIncomeNet [Продажа трафика net]
into #t1
from v_request_cost
 

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

*/


if @mode = 	   'requestNew'
select top (select * from _birs_top_N a) * from kpi_reportCache


--exec kpi_report 'requestNewRefresh'
--exec kpi_report 'requestNewRefreshRecreate'
if @mode like '%' + 'requestNewRefresh' + '%' 	 
begin



drop table if exists #t23672738829332
select   Номер, [Причина отказа] , productType, interestRate
into #t23672738829332
from v_fa 
			
drop table if exists #t32788238932023
select   number, utmSource
into #t32788238932023--#tt0
from v_request
				
drop table if exists #t334378438498
select   number, case when isdubl =0 then 0 else 1 end isDubl
 ,[hasLeadBankiruDeepapi]       
,[hasLeadBankiruDeepapiPts]	
,[hasLeadBankiruInstallmentCheck]	
 , lastCommunicationCreated,  lastLoyalCommunicationCreated
,case when  parentGuid is not null then ''  end parentGuid	
, expectedCpaCost
, call15
, call15approved

into #t334378438498--#tt0
from  _request with(nolock)
									


drop table if exists #t1239230903
select   number Номер, [CPA трафик в МП источник], marketingCost [Маркетинговые расходы]
, marketingCostMedia Медийка 
, marketingCostCpa [Расходы на CPA]
, sellTrafficIncomeNet [Продажа трафика net]
into #t1239230903
from v_request_cost 
 

drop table if exists #t2322442424242

;


with v as (
SELECT  
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
	  ,isnull( [Контроль данных] , [Одобрено]) [Контроль данных]

      ,isnull(isnull( [Call2] , [Одобрено]), [Одобрено]) [Call2]
      ,isnull(isnull( [Call2 accept] , [Одобрено]), [Одобрено]) [Call2 accept] 
      , isnull([Верификация документов клиента], [Одобрено]) [Верификация документов клиента]
    
      ,isnull([Одобрены документы клиента], [Одобрено]) [Одобрены документы клиента]
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
      --,[ПроцСтавкаКредит]
      ,[rn]
      ,[fpd0]
      ,[fpd4]
      ,[fpd7]
      ,[fpd30]
      ,[fpd60]
      ,[HR30_4]
      ,[HR90_12]
      ,[HR90_6]
      , case when  a.[Заем выдан] is not null then case when datediff(day, a.[Заем выдан] , a.[Заем погашен] )<=13  then 1  else 0 end end [full_prepayment_14]  
      , case when  a.[Заем выдан] is not null then case when datediff(day, a.[Заем выдан] , a.[Заем погашен] )<=31  then 1  else 0 end end [full_prepayment_30]  
      , case when  a.[Заем выдан] is not null then case when datediff(day, a.[Заем выдан] , a.[Заем погашен] )<=62  then 1  else 0 end end [full_prepayment_60]  
      , case when  a.[Заем выдан] is not null then case when datediff(day, a.[Заем выдан] , a.[Заем погашен] )<=93  then 1  else 0 end end [full_prepayment_90]  
      , case when  a.[Заем выдан] is not null then case when datediff(day, a.[Заем выдан] , a.[Заем погашен] )<=186 then 1  else 0 end end [full_prepayment_180] 
      ,[created]
      ,[fa_created]
      ,[ФИО]
      ,[product]
      ,[user_os]
	  ,case when [Группа каналов] = 'CPA' then [Канал от источника] else [Группа каналов]  end [Группа каналов_2]
	  ,[Вид займа]
	  ,cast( case when a.isPts=1 then  'ПТС' else 'Беззалог' end as varchar(25)) [Тип продукта ПТС/Инст]
	  ,isInstallment
	 ,Источник
	  ,[Тип трафика]
	  ,[Место cоздания]
	 
  FROM  [dm_Factor_Analysis]	a
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
  	 into #t2322442424242
  from v a
  left join v_Calendar c on  cast(a.[Верификация КЦ] as date)=c.Дата
  left join v_Calendar z on  cast(a.[Заем выдан] as date)=z.Дата
   

drop table if exists #t237672722378832
;
with v as (

select *
,case when isnull(dbo.lcrm_is_inst_lead([Тип трафика] , Источник, null), isinstallment)=1 then 'Трафик инст' else 'Трафик ПТС' end [Трафик продукт]
from #t2322442424242 a

)

select 

 ''  [Номер]
, a.[Отчетная дата]
, a.[Дубль]
, cast( a.[ДатаЗаявкиПолная] as date)  [ДатаЗаявкиПолная]
, a.[Место_создания_2]
, a.[Группа каналов]
, a.[Канал от источника]
, cast( a.[Верификация КЦ] as date)  [Верификация КЦ]
, cast( a.[Предварительное одобрение] as date)  [Предварительное одобрение]
, cast( a.[Встреча назначена] as date)  [Встреча назначена]
  
, cast( a.[Контроль данных] as date)  [Контроль данных]
 
, b3.call15
, b3.call15approved
, cast( a.[Call2] as date)  [Call2]
, cast( a.[Call2 accept] as date)  [Call2 accept]
, cast( a.[Верификация документов клиента] as date)  [Верификация документов клиента]
, cast( a.[Одобрены документы клиента] as date)  [Одобрены документы клиента]
, cast( a.[Верификация документов] as date)  [Верификация документов]
     
, a.[Признак не застрял после Call2 accept]
, cast( a.[Одобрено] as date)  [Одобрено]
, cast( a.[Отказано] as date)  [Отказано]
, cast( a.[Отказ документов клиента] as date)  [Отказ документов клиента]
, cast( a.[Отказ клиента] as date)  [Отказ клиента]
    
, cast( a.[Аннулировано] as date)  [Аннулировано]
, cast( a.[Заем выдан] as date)  [Заем выдан]
  
, a.[Выданная сумма]
, a.[Сумма одобренная]
, a.[Первичная сумма]
, a.[Сумма заявки]
, a.[СуммаВыдачиБезКП]
, a.[ПризнакКП]
, a.[СуммаДопУслуг]
, a.[СуммаДопУслугCarmoney]
, a.[СуммаДопУслугCarmoneyNet]
, a.[ПризнакСтраховка]
, a.[ПризнакКаско]
, a.[ПризнакСтрахованиеЖизни]
, a.[ПризнакРАТ]
, a.[ПризнакПозитивНастр]
, a.[ПризнакПомощьБизнесу]
, a.[ПризнакТелемедицина]
, a.[Признак Защита от потери работы]
, a.[SumKasko]
, a.[SumEnsur]
, a.[SumRat]
, a.[SumPositiveMood]
, a.[SumHelpBusiness]
, a.[SumTeleMedic]
, a.[SumCushion]
, b1.interestRate [ПроцСтавкаКредит]
, a.[rn]
, a.[fpd0]
, a.[fpd4]
, a.[fpd7]
, a.[fpd30]
, a.[fpd60]
, a.[HR30_4]
, a.[HR90_12]
, a.[HR90_6]
, a.[full_prepayment_14]    
, a.[full_prepayment_30]
, a.[full_prepayment_60]
, a.[full_prepayment_90]
, a.[full_prepayment_180]
, a.[created]
, a.[fa_created]
, '' [ФИО]
, a.[product]
, a.[user_os]
, a.[Группа каналов_2]
, a.[Вид займа]
, case  when b1.producttype = 'BIG INST' then 'BIG INST'  when b1.producttype = 'AUTOCREDIT' then 'AUTOCREDIT' else  a.[Тип продукта ПТС/Инст] end [Тип продукта ПТС/Инст]
, a.[isInstallment]
, a.[Источник]
, a.[Тип трафика]
, a.[Место cоздания]
, a.[Верификация КЦ Неделя]
, a.[Верификация КЦ Месяц]
, a.[Верификация КЦ квартал]
, a.[Верификация КЦ квартал представление]
, a.[Заем выдан Неделя]
, a.[Заем выдан Месяц]
, a.[Заем выдан квартал]
, a.[Заем выдан квартал представление]
, a.[Трафик продукт] 
,  b.[CPA трафик в МП источник]
, b.[Маркетинговые расходы]
, b.[Медийка]
, b.[Расходы на CPA]
,
case when [Группа каналов_2] in ('CPA нецелевой', 'CPA полуцелевой', 'CPA целевой', 'Банки') 
then 
isnull([CPA трафик в МП источник], Источник) 
else [канал от источника]
end [Источник аналитический]
, b.[Продажа трафика net]
, b1.[Причина отказа]
, b2.utmSource
, b3.[hasLeadBankiruDeepapi]       
, b3.[hasLeadBankiruDeepapiPts]	
, b3.[hasLeadBankiruInstallmentCheck]	
, 
case when b3.[hasLeadBankiruDeepapi]   is not null          then try_cast( ','+ 'bankiru-deepapi'           as varchar(8000)) else '' end  + 
case when b3.[hasLeadBankiruDeepapiPts]   is not null       then try_cast( ','+ 'bankiru-deepapi-pts'       as varchar(8000)) else '' end  + 
case when b3.[hasLeadBankiruInstallmentCheck]   is not null then try_cast( ','+ 'bankiru-installment-check' as varchar(8000)) else '' end  SourceIntersectionDesc
, b3.parentGuid	
, isnull(b3.expectedCpaCost , case when a.[заем выдан]  is not null then 0  end ) expectedCpaCost

 ,cast( b3.lastCommunicationCreated as date)  lastCommunicationCreated
 , b3.lastLoyalCommunicationCreated
into #t237672722378832
from v a
left join #t1239230903 b on a.Номер=b.Номер
left join #t23672738829332 b1 on a.Номер=b1.Номер
left join #t32788238932023 b2 on a.Номер=b2.number
left join #t334378438498 b3 on a.Номер=b3.number


 --;with v  as (select *, row_number() over(partition by номер order by (select null)) rn11 from #t237672722378832  ) delete from v where rn11>1


--exec kpi_report 'requestNewRefreshRecreate'
if @mode like '%' + 'requestNewRefreshRecreate' + '%'  or cast(getdate() as date)='20260330'	 

begin 
drop table if exists kpi_reportCache
select * into kpi_reportCache from #t237672722378832
return
end
delete from kpi_reportCache 
insert into kpi_reportCache
select * from #t237672722378832
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'E5EAE794-D01D-4D5E-A48A-52B41C19C9FA'

 exec sp_birs_update '117718D2-B489-4D2C-9E4F-3AFDD51F8109'
return
end


 --sp_table_granularity 'kpi_reportCache'

-- exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._report KPI at 7:00 each hour'--STOP 
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics._report KPI at 7:00 each hour', @step_name = 'Analytics._report KPI at 7:00 each hour'