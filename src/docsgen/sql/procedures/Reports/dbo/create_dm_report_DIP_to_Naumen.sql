

--exec [dbo].[create_dm_report_DIP_to_Naumen]

CREATE     procedure [dbo].[create_dm_report_DIP_to_Naumen]
as
begin

set datefirst 1;

--Если была попытка дозвониться в рамках кампаний докреды и повторники за 30 дней
drop table if exists #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней
select client_number Телефон 
into #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней 
from dbo.dm_report_DIP_detail_outbound_sessions 
where attempt_start>=  cast(getdate()-30 as date)


--Если произошел диалог с оператором(дозвон) по лиду Федор за 30 дней
drop table if exists #Номера_с_дозвоном_кампании_федор_30_дней
select Телефон 
into #Номера_с_дозвоном_кампании_федор_30_дней 
from [dbo].[dm_report_DIP_feodor_calls_30_days]


--Временная таблица с лидами СРМ за 90 дней
drop table if exists #Документ_CRM_Заявка_90_дней
select '8'+Телефон                  Телефон
,      dateadd(year, -2000, z.Дата) Дата
,      z.Статус                     СтатусСсылка
,      sl.Наименование              ТекущийСтатус
,      po.НаименованиеПолное        ПричинаОтказа
	into #Документ_CRM_Заявка_90_дней
from      stg.[_1cCRM].[Документ_CRM_Заявка]           z 
left join stg.[_1cCRM].[Справочник_CRM_СостоянияЛидов] sl on sl.Ссылка=z.Статус
left join stg.[_1cCRM].Справочник_CRM_ПричиныОтказов   po on po.Ссылка=z.ПричинаОтказа
where dateadd(year, -2000, z.Дата)>=cast(getdate()-90 as date)

--select * from #Документ_CRM_Заявка_90_дней a join dbo.dm_Report_DIP_to_Naumen b on cast(a.Дата as date)=b.[Дата среза] and a.Телефон=b.mobile_fin
--order by ТекущийСтатус, ПричинаОтказа


--Если телефон среди лидов СРМ у которых статус = Отказ клиента за 30 дней
drop table if exists #Номер_с_лидом_срм_статус_отказ_клиента_30_дней
select Телефон
  into #Номер_с_лидом_срм_статус_отказ_клиента_30_дней 
from #Документ_CRM_Заявка_90_дней 
where ТекущийСтатус like '%Отказ клиента%' 
  and Дата>=cast(getdate()-30 as date)

--Если телефон среди лидов СРМ у которых статус = забраковано а причина отказа - отказ от разговора за 90 дней
drop table if exists #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней
select Телефон into #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней from #Документ_CRM_Заявка_90_дней 
where  ТекущийСтатус like '%Забраковано%' and ПричинаОтказа like '%Отказ от разговора%'


--Если телефон среди лидов СРМ у которых статус содержит в себе "Не подходит под требования"
drop table if exists #Номер_с_лидом_срм_не_подходит_под_требования_90_дней
select  Телефон into #Номер_с_лидом_срм_не_подходит_под_требования_90_дней 
from #Документ_CRM_Заявка_90_дней 
where  ПричинаОтказа like '%Не подходит под требования%'

--select 
--    distinct ПричинаОтказа 
--	
----into #Номер_с_лидом_срм_не_подходит_под_требования_90_дней 
--
--from #Документ_CRM_Заявка_90_дней 
--where  ПричинаОтказа like '%Не подходит под требования%'

--Если номер просился в ЧС

drop table if exists #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней;
with v as (
select v.ссылка                
,      [КонтактноеЛицо]      
,      [ПотенциальныйКлиент] 
,      Дата                  
,      Заявка_Ссылка         
,      do.Наименование         
from stg._1ccrm.Документ_CRM_Взаимодействие v join stg.[_1cCRM].[Справочник_ДеталиОбращений] do on do.Ссылка=v.ДеталиОбращения  and do.Наименование like '%Исключение номера телефона%'
	and dateadd(year, -2000, Дата)>=cast(getdate()-90 as date)
 )

 
select a.*                                                                                                                                
,      ki.НомерТелефонаБезКодов   НомерКонтактноеЛицо                                                                                                         
,      pkki.НомерТелефонаБезКодов НомерПотенциальныйКлиент                                                                                               
,      tz.[АбонентКакСвязаться]   НомерИзЗвонка                                                                                             
,      z.МобильныйТелефон         НомерИзЗаявки                                                                                             
into #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней
from v a
 left join stg._1ccrm.[Справочник_КонтактныеЛицаПартнеров_КонтактнаяИнформация]  ki    on ki.ссылка=a.[КонтактноеЛицо]
 left join stg._1ccrm.Справочник_CRM_ПотенциальныеКлиенты_КонтактнаяИнформация   pkki  on a.ПотенциальныйКлиент=pkki.ссылка
 left join stg._1ccrm.[Документ_ТелефонныйЗвонок]                                tz    on tz.ВзаимодействиеОснование_ссылка=a.Ссылка
 left join stg._1ccrm.[Документ_ЗаявкаНаЗаймПодПТС]                              z     on z.Ссылка=a.Заявка_Ссылка


 
drop table if exists #Номера_просящиеся_в_чс_3_месяца

select * into #Номера_просящиеся_в_чс_3_месяца from (
 select '8'+НомерКонтактноеЛицо      Телефон  from #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней where isnumeric(НомерКонтактноеЛицо)=1      and len(НомерКонтактноеЛицо     )=10 union all
 select '8'+НомерПотенциальныйКлиент Телефон  from #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней where isnumeric(НомерПотенциальныйКлиент)=1 and len(НомерПотенциальныйКлиент)=10 union all
 select '8'+НомерИзЗвонка            Телефон  from #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней where isnumeric(НомерИзЗвонка)=1            and len(НомерИзЗвонка)           =10 union all
 select '8'+НомерИзЗаявки            Телефон  from #Номера_телефонов_по_контактным_лицам_звонкам_и_потенциальным_клиентам_90_дней where isnumeric(НомерИзЗаявки)=1            and len(НомерИзЗаявки)           =10
 ) x


--Если за последние 30 дней клиенту был вынесен отказ или отказ документов клиента
drop table if exists #Номера_с_отказом_или_отказом_документов_клиента_30_дней
select  '8'+z.МобильныйТелефон Телефон into #Номера_с_отказом_или_отказом_документов_клиента_30_дней
from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s 
join stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС sz on sz.Ссылка=s.Статус and sz.Наименование in ('Отказано', 'Отказ документов клиента') 
join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z on s.Заявка=z.Ссылка and Инстолмент=0
where dateadd(year, -2000, s.Период)>=cast(getdate()-30 as date)



----Если номер в ЧС 
--drop table if exists #Номера_в_ЧС
--select '8'+cast(phone as nvarchar(10)) Телефон into #Номера_в_ЧС 
--from stg._1cCRM.BlackPhoneList

--Если номер в ЧС (внесен за последние 90 дней)
drop table if exists #Номера_в_ЧС_90_дней
--select '8'+cast(UF_PHONE as nvarchar(10)) Телефон into #Номера_в_ЧС from stg._loginom.crib_proxy_black_phones
select '8'+cast(phone as nvarchar(10)) Телефон
into #Номера_в_ЧС_90_дней
from stg._1cCRM.BlackPhoneList
where create_at>=cast(getdate()-90 as date) or ReasonAdding_subject='Исключение номера телефона (бессрочно)'


insert into #Номера_в_ЧС_90_дней
values ('89099819898') --17.01.2022 Не звонить по этому номеру.

--Номера паспортов тех, у кого есть ПЭП
drop table if exists #ПаспортаПэп
select СерияПаспорта+НомерПаспорта Паспорт  into #ПаспортаПэп from [dbo].[dm_report_DIP_pep]

--Очищаем таблицы от дублей для left join
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_с_дозвоном_кампании_федор_30_дней                          ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номер_с_лидом_срм_статус_отказ_клиента_30_дней                    ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней   ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_просящиеся_в_чс_3_месяца                                   ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_с_отказом_или_отказом_документов_клиента_30_дней           ) delete from v where rn>1
--;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_в_ЧС                                                       ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_в_ЧС_90_дней                                               ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номер_с_лидом_срм_не_подходит_под_требования_90_дней              ) delete from v where rn>1

;with v as (select *, ROW_NUMBER() over(partition by Паспорт order by (select 1)) rn from #ПаспортаПэп) delete from v where rn>1

---Выгружаем реестры докреды и повторники за сегодня
drop table if exists #bfs

select category                        category
,      main_limit                      main_limit
,      '8'+mobile_fin                  mobile_fin
,      region_projivaniya              region_projivaniya
,      [Паспорт серия]+[Паспорт номер] Паспорт
,      [CRMClientFIO]                  crmfioo
--,      [Type]                          [Type]
,      cast(getdate() as date)           [Дата Среза]
,      crmClientGUID
,      birth_date birth_date
,      external_id [Номер договора]
,      [Тип предложения] = case 
                                when type= 'Докредитование' then 'Докредитование'
                                when type= 'Повторный заём с известным залогом' then 'Повторный заём'
                                when type= 'Повторный заём с новым залогом' then 'Повторный заём'
								end
	into #bfs
from dwh_new.[dbo].[CRM_loyals_buffer_for_sales]
where cast(created as date) =cast(getdate() as date)
--select * from #bfs order by [Тип предложения]
--Убеждаемся что на сегодня база создана


--Сбор информации по последнему займу клиента

drop table if exists #loans
;
with d as (
select d.ссылка                       [Ссылка договор CMR]
,      d.код                          [Код]
,      d.Сумма                        [Сумма]
,      d.Срок                         [Срок]
,       dwh_new.[dbo].[getGUIDFrom1C_IDRREF](d.Клиент) CRMClientGUID
,       cast(case when d.isInstallment = 1 then 1 else 0 end as int) isInstallment
from stg._1cCMR.Справочник_Договоры d left join stg._1cCMR.Справочник_Заявка z on d.Заявка=z.Ссылка
)
, statuses as (

select Договор                           Договор
,      Статус                            Статус
,      dateadd(year, -2000, min(Период)) Период
from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
group by Договор
,        Статус

)
select d.*
,v000000002.Период as [Действует]
into #loans
from  d
join statuses v000000002 on v000000002.Статус=0x80D900155D64100111E78663D3A87B80 and v000000002.Договор=d.[Ссылка договор CMR] 
and isInstallment=0

;

--select * from #loans
  
--drop table if exists #first_percent
--; with r as (select pd.Договор 
--                  , min(Период) min_p
--               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
--               join #loans d on  d.[Ссылка договор CMR]=pd.Договор
--              group by  pd.Договор--,Код
--            )
--    select pd.договор договор
--		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end [Первая процентная ставка]
--      into #first_percent
--      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
--      join r on r.Договор=pd. Договор and r.min_p=pd.Период
  
drop table if exists #current_percent
; with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
               join #loans d on  d.[Ссылка договор CMR]=pd.Договор
              group by  pd.Договор--,Код
            )
    select pd.договор договор
		 , case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end [Текущая процентная ставка]
      into #current_percent
      from stg._1ccmr.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период

--drop table if exists #gr
--
--select   g.Договор Договор, g.Ссылка, g.Дата, dg.СуммаПлатежа, dg.ДатаПлатежа into #gr
--from [Stg].[_1cCMR].[Документ_ГрафикПлатежей] g join stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей]  dg on g.ссылка=dg.Регистратор
--where g.Проведен=1 and g.ПометкаУдаления=0
--drop table if exists #gr_rn
--
--select *
----,row_number() over(partition by Договор order by Дата desc, case when СуммаПлатежа>0 then 1 end desc, ДатаПлатежа) rn_desc 
--,row_number() over(partition by Договор order by Дата , case when СуммаПлатежа>0 then 1 end desc, ДатаПлатежа) rn 
--into #gr_rn from #gr

--drop table if exists #month_payments
--
--  select Договор
--  , max(case when rn=1 then СуммаПлатежа end )      [Сумма платежа первый график]
----  , max(case when rn_desc=1 then СуммаПлатежа end ) [Сумма платежа последний график]
--  into #month_payments
--  from #gr_rn a 
--  group by Договор

  drop table if exists #fa
  select Номер,
  case 
  when SumKasko >0 then 'КАСКО' 
  when SumQuietLife >0 then 'СЖ' 
  when SumEnsur >0 then 'НС' 
  end Страховки
  
  
  into #fa from dbo.dm_Factor_Analysis
  where [Заем выдан] is not null


  drop table if exists #cmr_last_issued_pts_loan_info
  select 
    CRMClientGUID
  , Срок [Срок последнего займа]
  , Сумма [Сумма последнего займа]
  --, [Сумма платежа первый график]  [Сумма платежа последнего займа первый график]
  , [Текущая процентная ставка] [Текущая процентная ставка последнего займа]
 -- , [Первая процентная ставка]  [Первая процентная ставка последнего займа]
  , Страховки
  into #cmr_last_issued_pts_loan_info
  from 
  (
  select 
  a.CRMClientGUID
  , a.Срок
  , a.Сумма
 -- , b.[Сумма платежа первый график]
  , c.[Текущая процентная ставка]
  --, f.[Первая процентная ставка]
  , ROW_NUMBER() over(partition by a.CRMCLientGUID order by Действует desc) rn
  , fa.Страховки
  from #loans a
 -- left join #month_payments b on a.[Ссылка договор CMR]=b.договор
  left join #current_percent c on a.[Ссылка договор CMR]=c.договор
 -- left join #first_percent f on a.[Ссылка договор CMR]=f.договор
  join  #bfs  bfs on bfs.CRMClientGuid=a.CRMClientGUID 
  left join #fa fa on fa.Номер=a.Код
  ) x where rn=1


;

drop table if exists [#отзыв пд]
select * into [#отзыв пд] from [Stg].[files].[отзыв пд] where [Номер телефона]<>'Тест'

DECLARE @err_message nvarchar(255)
set @err_message = 'Отсутствуют телефонные номоера '

IF
(select count([Номер телефона]) [Counter] from [#отзыв пд] where len([Номер телефона])=10) =0
raiserror(@err_message,11,1)
ELSE
select 0


delete from #bfs where mobile_fin in (select '8'+[Номер телефона] from [#отзыв пд] where isnull('8'+[Номер телефона], '')<>'')
delete a
from #bfs a
join [#отзыв пд] b on b.[Номер договора] like '%'+a.[Номер договора]+'%'  
--select * from [#отзыв пд]


--Оставляем наилучшее предложение по каждому клиенту
;with v as (select *, ROW_NUMBER() over(partition by crmClientGUID order by main_limit desc) rn from #bfs) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by mobile_fin order by main_limit desc) rn from #bfs) delete from v where rn>1

----------------------------------Проверка на контактность за последний год. Если за последний год мы пытались дозвониться (и не дозвонились) клиенту в 10 различных последних неделях (как минимум), то берем такие номера не более 20% от контактной базы
declare @доля_неконтактных_в_обзвоне float = 0.2
drop table if exists #dos

select mobile, [attempt_start_week], max([succ]) [succ] 
into #dos
from (
select 

	   mobile = client_number                         
,      [attempt_start]                      
,      cast(DATEADD(wk, DATEDIFF(wk,0,[attempt_start]), 0) as date)     [attempt_start_week]                  
,      case when login is not null then 1 else 0 end as [succ]

from [dbo].[dm_report_DIP_detail_outbound_sessions]
where len(client_number)=11 and  attempt_start>=getdate()-365
) dos
group by mobile , [attempt_start_week]

drop table if exists #неконтактные_номера_телефонов
;
with v as(
select *, ROW_NUMBER() over(partition by mobile order by [attempt_start_week] desc) rn, count(*) over(partition by mobile) cnt  from #dos
)
select mobile, sum(succ) succ
into #неконтактные_номера_телефонов
from v
where rn<=10 and cnt>=10
group by mobile
having sum(succ)=0
order by mobile--, attempt_start_week

--select * from #неконтактные_номера_телефонов

drop table if exists #bfs_for_segmentation


select 



bfs.category                                                              
,      bfs.main_limit                                                            
,      bfs.region_projivaniya                                                    
,      bfs.[Дата Среза]                                                               
,      bfs.crmfioo
+ case when #ПаспортаПэп.Паспорт is not null then ' ПЭП' else '' end 
+ case when Страховки is not null            then ' '+Страховки+'' else ' Без кп' end 
+ case when [Текущая процентная ставка последнего займа] >0 then ' '+format([Текущая процентная ставка последнего займа], '0.0')+'%' else '' 
end crmfioo
,      bfs.mobile_fin       
, case 
when len(bfs.mobile_fin)<>11 or isnumeric(bfs.mobile_fin)=0                                            then 'Некорректный телефонный номер'
when category='Красный'                                                                                then 'Красная зона'
--when #Номера_в_ЧС.Телефон is not null                                                                then 'Black list'
when #Номера_с_отказом_или_отказом_документов_клиента_30_дней.Телефон is not null                      then 'Отказ по заявке 30 дней'
--when #Номера_в_ЧС_90_дней.Телефон is not null                                                        then 'Black list'
when #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней.Телефон is not null              then 'Забраковано: отказ от разговора 90 дней (CRM лид)'
when #Номер_с_лидом_срм_статус_отказ_клиента_30_дней.Телефон is not null                               then 'Отказ клиента 30 дней (CRM лид)'
when #Номер_с_лидом_срм_не_подходит_под_требования_90_дней.Телефон is not null                         then 'Не подходит под ограничения 90 дней'
--when #Номера_с_дозвоном_кампании_федор_30_дней.Телефон is not null  then 'Дозвон Федор 30 дней'	   
when #Номера_просящиеся_в_чс_3_месяца.Телефон is not null  or #Номера_в_ЧС_90_дней.Телефон is not null then 'Просился в ЧС 90 дней'
when #Номера_с_дозвоном_кампании_федор_30_дней.Телефон is not null and bfs.[Тип предложения]<>'Докредитование'    then 'Дозвон Федор 30 дней'
when #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней.Телефон is not null            then 'Попытка дозвониться 30 дней'
when isnull(FLOOR((CAST (try_cast(getdate() as datetime) AS INTEGER) - CAST(try_cast(birth_date as datetime) AS INTEGER)) / 365.25) , 0)   >=66         then 'Возраст 66+'
--when [Тип предложения]='Докредитование' then 'Докреды'												           
when #неконтактные_номера_телефонов.mobile is not null                                                 then 'Неконтактный'
else 'Подходит' 
end [status]
, bfs.crmClientGUID 
, [Тип предложения]
into #bfs_for_segmentation
from #bfs bfs

--left join #Номера_в_ЧС                                                         on #Номера_в_ЧС.Телефон                                                       =bfs.mobile_fin
left join #Номера_в_ЧС_90_дней                                                 on #Номера_в_ЧС_90_дней.Телефон                                               =bfs.mobile_fin
left join #Номера_с_отказом_или_отказом_документов_клиента_30_дней             on #Номера_с_отказом_или_отказом_документов_клиента_30_дней.Телефон           =bfs.mobile_fin
left join #Номера_просящиеся_в_чс_3_месяца                                     on #Номера_просящиеся_в_чс_3_месяца.Телефон                                   =bfs.mobile_fin
left join #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней     on #Номер_с_лидом_срм_статус_забраковано_отказ_от_разговора_90_дней.Телефон   =bfs.mobile_fin
left join #Номер_с_лидом_срм_статус_отказ_клиента_30_дней                      on #Номер_с_лидом_срм_статус_отказ_клиента_30_дней.Телефон                    =bfs.mobile_fin
left join #Номера_с_дозвоном_кампании_федор_30_дней                            on #Номера_с_дозвоном_кампании_федор_30_дней.Телефон                          =bfs.mobile_fin
left join #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней   on #Номера_с_попыткой_дозвона_в_рамках_докредов_и_повторников_30_дней.Телефон =bfs.mobile_fin
left join #Номер_с_лидом_срм_не_подходит_под_требования_90_дней                on #Номер_с_лидом_срм_не_подходит_под_требования_90_дней.Телефон              =bfs.mobile_fin

left join #ПаспортаПэп on #ПаспортаПэп.Паспорт=bfs.Паспорт

left join #неконтактные_номера_телефонов on #неконтактные_номера_телефонов.mobile=bfs.mobile_fin
left join #cmr_last_issued_pts_loan_info on #cmr_last_issued_pts_loan_info.CRMClientGUID=bfs.CRMClientGuid
--select status, count(*) from #bfs_for_segmentation
--group by status
--select * from #bfs_for_segmentation

declare @число_контактных bigint = (select count(*) from #bfs_for_segmentation where status='Подходит')
declare @число_неконтактных_в_обзвон bigint = @число_контактных*@доля_неконтактных_в_обзвоне
;
--select @число_неконтактных_в_обзвон
--select @число_контактных;
with v as (select top (@число_неконтактных_в_обзвон) * from #bfs_for_segmentation where status='Неконтактный' )
update v
set status = 'Подходит (неконтактный)'
--окончание проверки на контактность

--set @число_контактных = (select count(*) from #bfs_for_segmentation where status='Подходит')
--select @число_контактных
-- Справочник ГМТ по регионам

drop table if exists #gmts_on_region

 select 'Калининградская'                               region_projivaniya ,  'GMT+02:00' GMT into #gmts_on_region union all
 select 'Севастополь'                                   region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Белгородская'                                  region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Владимирская'                                  region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Вологодская'                                   region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ивановская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Калужская'                                     region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Кировская'                                     region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Краснодарский край'                            region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ленинградская'                                 region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Московская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ненецкий автономный округ'                     region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Новгородская'                                  region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Пензенская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Адыгея'                                        region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ингушетия'                                     region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Карелия'                                       region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Крым'                                          region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Мордовия'                                      region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ростовская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Саратовская'                                   region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Смоленская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Тамбовская'                                    region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Тульская'                                      region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Чувашская - Чувашия'                           region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Ярославская'                                   region_projivaniya ,  'GMT+03:00' GMT union all
 select 'Самарская'                                     region_projivaniya ,  'GMT+04:00' GMT union all
 select 'Ульяновская'                                   region_projivaniya ,  'GMT+04:00' GMT union all
 select 'Оренбургская'                                  region_projivaniya ,  'GMT+05:00' GMT union all
 select 'Башкортостан'                                  region_projivaniya ,  'GMT+05:00' GMT union all
 select 'Тюменская'                                     region_projivaniya ,  'GMT+05:00' GMT union all
 select 'Челябинская'                                   region_projivaniya ,  'GMT+05:00' GMT union all
 select 'Омская'                                        region_projivaniya ,  'GMT+06:00' GMT union all
 select 'Новосибирская'                                 region_projivaniya ,  'GMT+06:00' GMT union all
 select 'Красноярский край'                             region_projivaniya ,  'GMT+07:00' GMT union all
 select 'Кемеровская - Кузбасс'                         region_projivaniya ,  'GMT+07:00' GMT union all
 select 'Тыва'                                          region_projivaniya ,  'GMT+07:00' GMT union all
 select 'Иркутская'                                     region_projivaniya ,  'GMT+08:00' GMT union all
 select 'Амурская'                                      region_projivaniya ,  'GMT+09:00' GMT union all
 select 'Саха-Якутия'                                   region_projivaniya ,  'GMT+09:00' GMT union all
 select 'Приморский край'                               region_projivaniya ,  'GMT+10:00' GMT union all
 select 'Магаданская'                                   region_projivaniya ,  'GMT+10:00' GMT union all
 select 'Сахалинская'                                   region_projivaniya ,  'GMT+11:00' GMT union all
 select 'Чукотский автономный округ'                    region_projivaniya ,  'GMT+12:00' GMT union all
 select  'Москва'                                       region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Архангельская'                                region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Брянская'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Волгоградская'                                region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Воронежская'                                  region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Кабардино-Балкария'                           region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Карачаево-Черкесия'                           region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Костромская'                                  region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Курская'                                      region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Липецкая'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Мурманская'                                   region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Нижегородская'                                region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Орловская'                                    region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Псковская'                                    region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Дагестан'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Калмыкия'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Коми'                                         region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Марий Эл'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Северная Осетия'                              region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Рязанская'                                    region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Саратов'                                      region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Ставропольский край'                          region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Тверская'                                     region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Чеченская Республика'                         region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Чувашская Чувашия'                            region_projivaniya ,  'GMT+03:00' gmt union all
 select  'Астраханская'                                 region_projivaniya ,  'GMT+04:00' gmt union all
 select  'Удмуртская'                                   region_projivaniya ,  'GMT+04:00' gmt union all
 select  'Курганская'                                   region_projivaniya ,  'GMT+05:00' gmt union all
 select  'Пермский край'                                region_projivaniya ,  'GMT+05:00' gmt union all
 select  'Свердловская'                                 region_projivaniya ,  'GMT+05:00' gmt union all
 select  'Ханты-Мансийский Автономный округ - Югра АО'  region_projivaniya ,  'GMT+05:00' gmt union all
 select  'Ямало-Ненецкий АО'                            region_projivaniya ,  'GMT+05:00' gmt union all
 select  'Томская'                                      region_projivaniya ,  'GMT+06:00' gmt union all
 select  'Алтайский край'                               region_projivaniya ,  'GMT+07:00' gmt union all
 select  'Кемеровская'                                  region_projivaniya ,  'GMT+07:00' gmt union all
 select  'Алтай'                                        region_projivaniya ,  'GMT+07:00' gmt union all
 select  'Хакасия'                                      region_projivaniya ,  'GMT+07:00' gmt union all
 select  'Бурятия'                                      region_projivaniya ,  'GMT+08:00' gmt union all
 select  'Забайкальский край'                           region_projivaniya ,  'GMT+09:00' gmt union all
 select  'Еврейская Авт. обл.'                          region_projivaniya ,  'GMT+10:00' gmt union all
 select  'Хабаровский край'                             region_projivaniya ,  'GMT+10:00' gmt union all
 select  'Камчатский край'                              region_projivaniya ,  'GMT+12:00' gmt union all
 select  'Татарстан'                                    region_projivaniya ,  'GMT+03:00' gmt



--Подготовка таблиц для сегментации



--Получившие отказ или отказ доков 90 дней

drop table if exists #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней
select  '8'+z.МобильныйТелефон Телефон into #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней
from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s 
join stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС sz on sz.Ссылка=s.Статус and sz.Наименование in ('Отказано', 'Отказ документов клиента') 
join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z on s.Заявка=z.Ссылка
where dateadd(year, -2000, s.Период)>=cast(getdate()-90 as date)

--Закрытые за предыдущий день. Если сегодня пондельник то за 3 предыдущих дня.


declare @порядковыйНомерДняНедели int = datepart(dw, getdate())
declare @ЗаПоследниеСколькоДнейИскатьПогашенных int = case when @порядковыйНомерДняНедели =1 then 3 else 1 end

--select @ЗаПоследниеСколькоДнейИскатьПогашенных
--select НомерДоговора, ДатаФактическогоЗакрытия from stg._1cMFO.Отчет_СписокКредитныхДоговоров where dateadd(year, -2000, ДатаФактическогоЗакрытия) between cast(getdate()-@ЗаПоследниеСколькоДнейИскатьПогашенных as date) and cast(getdate() as date)



drop table if exists #ПогашеныеДоговорыЗаПериод
select НомерДоговора into #ПогашеныеДоговорыЗаПериод from stg._1cMFO.Отчет_СписокКредитныхДоговоров where dateadd(year, -2000, ДатаФактическогоЗакрытия) between cast(getdate()-@ЗаПоследниеСколькоДнейИскатьПогашенных as date) and cast(getdate() as date)


drop table if exists #НомераПогашеных

select '8'+ТелефонМобильный Телефон 

into #НомераПогашеных

from #ПогашеныеДоговорыЗаПериод a join stg._1cMFO.Документ_ГП_Договор d on a.НомерДоговора=d.Номер union all
select '8'+MobilePhone 
from #ПогашеныеДоговорыЗаПериод a join stg._Collection.Deals d on a.НомерДоговора=d.Number join stg._Collection.customers c on d.IdCustomer=c.id 


--КЛиенты получавшие займ РБП 40-50

--drop table if exists #40_50_номера_договоров
--select distinct skd.НомерДоговора
--into #40_50_номера_договоров
--from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z 
--left join Stg._loginom.Dm_risk_groups rg on cast(rg.number as varchar)=z.Номер
--join stg._1cMFO.Отчет_СписокКредитныхДоговоров skd on z.Номер=skd.НомерЗаявки
--left join dbo.dm_Sales s on s.Код=skd.НомерДоговора
--where (rg.fin_gr=50 or z.ВариантПредложенияСтавки in (0xB81400155DFABA2A11E9F8551BC95254, 0xB82800505683CF4D11EBAEAE5ABFA6A0, 0xB82800505683CF4D11EBC4A9F0F286A8, 0xB82800505683CF4D11EBC4A9F0F286A7))
--and s.ПроцентнаяСтавка<=60
--
--
--
--	drop table if exists #Номера_40_50
--
--select '8'+ТелефонМобильный Телефон 
--
--into #Номера_40_50
--
--from #40_50_номера_договоров a join stg._1cMFO.Документ_ГП_Договор d on a.НомерДоговора=d.Номер union all
--select '8'+MobilePhone 
--from #40_50_номера_договоров a join stg._Collection.Deals d on a.НомерДоговора=d.Number join stg._Collection.customers c on d.IdCustomer=c.id 




--Впервые в обзвоне

drop table if exists #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов
select bfs.mobile_fin Телефон into #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов from #bfs_for_segmentation bfs left join dbo.dm_report_DIP_mv_call_case cc on bfs.mobile_fin=cc.phonenumbers
where cc.uuid is null --and bfs.status in ('Подходит', 'Подходит (неконтактный)')

;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов   ) delete from v where rn>1
--;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #Номера_40_50                                                       ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #НомераПогашеных                                                    ) delete from v where rn>1
;with v as (select *, ROW_NUMBER() over(partition by Телефон order by (select 1)) rn from #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней                  ) delete from v where rn>1



drop table if exists #final_table_with_all_clients
;
with v as (
select bfs.[Дата Среза]                                                                     
,      bfs.mobile_fin                                                                  
,      bfs.crmfioo                                                                          
,      bfs.region_projivaniya                                                           
,      bfs.category                                                                            
,      bfs.main_limit                                                                       
,      bfs.status                                                                       
,      case 
            --when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа] >=84                             then 'Высокая ставка'--corebo00000000000n25qftft0i6nq2s
            --when main_limit>=500000                                                                                           then 'Большая сумма'--corebo00000000000n25qfiqhjjmogcg
            --when #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов.Телефон is not null                        then 'Впервые попали в обзвон'--corebo00000000000n25qfiqhjjmogcg
            --when #Номера_40_50.Телефон is not null                                                                            then '40-50%'--corebo00000000000n25qfiqhjjmogcg
			when bfs.[Тип предложения]='Докредитование'                                                                       then 'Докреды'--corebo00000000000n25qgnvfnogtjf8
            --when #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней.Телефон is not null and category in ('Желтый', 'Зеленый') then 'Отказано'--corebo00000000000niqoje3j0hnrbr0
            --when #НомераПогашеных.Телефон is not null                                                                         then 'Погашенные'--corebo00000000000niqoqsgh2tui8k0
            --when category='Оранжевый'                                                                                         then 'Оранжевая категория'--corebo00000000000n25qftft0i6nq2s
                                                                                                                              else 'Повторные' --corebo00000000000mm1tts6og6rs2fk
end                                                                                     
Комментарий

,      case 
            --when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа] >=84                             then 'corebo00000000000n25qftft0i6nq2s'--Высокая ставка
			--when main_limit>=500000                                                                                           then 'corebo00000000000n25qfiqhjjmogcg' --'Большая сумма'
            --when #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов.Телефон is not null                        then 'corebo00000000000n25qfiqhjjmogcg' --'Впервые попали в обзвон'
            --when #Номера_40_50.Телефон is not null                                                                            then 'corebo00000000000n25qfiqhjjmogcg' --'40-50%'
			when bfs.[Тип предложения]='Докредитование'                                                                       then 'corebo00000000000n25qgnvfnogtjf8' --'Докреды'
            
			--when #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней.Телефон is not null and category in ('Желтый', 'Зеленый') then 'corebo00000000000niqoje3j0hnrbr0' --'Отказано'
            --when #НомераПогашеных.Телефон is not null                                                                         then 'corebo00000000000niqoqsgh2tui8k0' --'Погашенные'
            --when category='Оранжевый'                                                                                         then 'corebo00000000000n25qftft0i6nq2s' --'Оранжевая категория'
                                                                                                                              else 'corebo00000000000mm1tts6og6rs2fk' --'Повторные'
end        
project_id

,      isnull(#gmts_on_region.gmt, 'GMT+03:00')     GMT
,      --case 
       --     when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа] >=84                                              then 99
       --     when main_limit>=500000                                                                                           then 99
       --     when #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов.Телефон is not null                        then 99
       --     when #Номера_40_50.Телефон is not null                                                                            then 99
       --     when bfs.[Тип предложения]='Докредитование'                                                                          then 99
       --     --when #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней.Телефон is not null and category in ('Желтый', 'Зеленый') then 99
       --     --when #НомераПогашеных.Телефон is not null                                                                         then 99
       --     --when category='Оранжевый'                                                                                         then 99
       --                                                                                                                       else 
		--																													  case 
		--																													  when category = 'Зеленый' then 99
		--																													  when category = 'Желтый' then 66
		--																													  else 33
		--																													  end
       --end                                                                                     
	   case when #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов.Телефон is not null                        then 99 else 0 end 
	   +
	   case 
	   when main_limit>=800000                       then 50 
	   when main_limit>=600000                       then 40 
	   when main_limit>=400000                       then 30 
	   when main_limit>=200000                       then 20 
	   else 10
	  
	   end 
	   +
	   case 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа] <60                
	   or #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа] is null       
	   then 10 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]  <70                      then 20 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]  <80                      then 30 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]  <90                      then 40 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]  <=100                      then 50 
	   when #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]  >100                      then 60 
	   else 10
	   end 


Приоритет
, bfs.crmClientGUID
, [Тип предложения]
, #cmr_last_issued_pts_loan_info.[Текущая процентная ставка последнего займа]
--, #cmr_last_issued_pts_loan_info.[Сумма платежа последнего займа первый график]
, #cmr_last_issued_pts_loan_info.[Срок последнего займа]
, #cmr_last_issued_pts_loan_info.[Сумма последнего займа]



from      #bfs_for_segmentation                                             bfs

left join #cmr_last_issued_pts_loan_info                                        on #cmr_last_issued_pts_loan_info.CRMClientGUID =                              bfs.CRMClientGUID
left join #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней                    on #ПолучившиеОтказИлиОтказДокументовКлиентов_90_дней.Телефон =                bfs.mobile_fin
left join #НомераПогашеных                                                      on #НомераПогашеных.Телефон =                                                  bfs.mobile_fin
--left join #Номера_40_50                                                         on #Номера_40_50.Телефон =                                                     bfs.mobile_fin
left join #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов     on #Телефоны_без_созданных_кейсов_по_проектам_повторников_и_докредов.Телефон = bfs.mobile_fin


left join #gmts_on_region                                                       on #gmts_on_region.region_projivaniya = bfs.region_projivaniya
)
select 
 [Дата Среза]            
,mobile_fin              
,crmfioo                 
,region_projivaniya      
,category                
,main_limit              
,status  
, Комментарий
, project_id
, GMT
, case when Приоритет between 1 and 99 then Приоритет when Приоритет>99 then 99 when Приоритет<1 then 1 else 1 end Приоритет
, CRMClientGuid
, [Тип предложения]
, [Текущая процентная ставка последнего займа]
--, [Сумма платежа последнего займа первый график]
, [Срок последнего займа]
, [Сумма последнего займа]
--, Приоритет Приоритет_old


into #final_table_with_all_clients
from v

--select * from #final_table_with_all_clients

--begin tran
--
--delete from  [dbo].[dm_Report_DIP_to_Naumen_clients_info]
--insert into  [dbo].[dm_Report_DIP_to_Naumen_clients_info]
--select 
--  [Дата Среза]
--, CRMClientGuid
--, [mobile_fin]
--, crmfioo
--, category
--, [Тип предложения]
--, project_id
--, Комментарий
--, [Сумма последнего займа]
--, [Текущая процентная ставка последнего займа]
--, [Сумма платежа последнего займа первый график] 
--, [Срок последнего займа] 
--, status
--
--from #final_table_with_all_clients
--where status in ('Подходит', 'Подходит (неконтактный)') and project_id='corebo00000000000n25qftft0i6nq2s'
--
--commit tran

--select * from #final_table_with_all_clients order by status

--select * into devdb.[dbo].[dm_Report_DIP_to_Naumen_history] from #final_table_with_all_clients
--drop table if exists devdb.[dbo].[dm_Report_DIP_to_Naumen_history]

--if   OBJECT_ID(N'devdb.[dbo].[dm_Report_DIP_to_Naumen_history_20210521]') is  null
--
--begin
--
--CREATE TABLE devdb.[dbo].[dm_Report_DIP_to_Naumen_history_20210521](
--	[Дата Среза] [date] NULL,
--	[mobile_fin] [nvarchar](255) NULL,
--	[crmfioo] [nvarchar](255) NULL,
--	[region_projivaniya] [nvarchar](4000) NULL,
--	[category] [varchar](255) NULL,
--	[main_limit] [int] NULL,
--	[status] [varchar](49) NOT NULL,
--	[Комментарий] [varchar](35) NULL,
--	[project_id] [varchar](32) NULL,
--	[GMT] [varchar](9) NULL,
--	[Приоритет] [int] NULL
--)  

--insert into [dbo].[dm_Report_DIP_to_Naumen_history]
--select * from devdb.[dbo].[dm_Report_DIP_to_Naumen_history_20210520]
--
--insert into [dbo].[dm_Report_DIP_to_Naumen]
--select * from devdb.[dbo].[dm_Report_DIP_to_Naumen_history_20210520]
	
--end

--select * from devdb.dbo.[dm_Report_DIP_to_Naumen_history]
--order by status desc
--select * from devdb.dbo.[dm_Report_DIP_to_Naumen]
--order by 1 desc


begin tran
delete from [dbo].[dm_Report_DIP_to_Naumen_history] where [Дата Среза] = cast(getdate() as date)
insert into [dbo].[dm_Report_DIP_to_Naumen_history]
select [Дата Среза]
      ,[mobile_fin]
      ,[crmfioo]
      ,[region_projivaniya]
      ,[category]
      ,[main_limit]
      ,[status]
      ,[Комментарий]
      ,[project_id]
      ,[GMT]
      ,[Приоритет]
      ,[crmClientGUID]
      ,[Тип предложения]

from #final_table_with_all_clients
commit tran

--use reports
--go
--exec sp_help '[dbo].[dm_Report_DIP_to_Naumen_history]'
--exec sp_help '[dbo].[dm_Report_DIP_to_Naumen]'

--alter table [dbo].[dm_Report_DIP_to_Naumen_history] add crmClientGUID nvarchar(36)
--alter table [dbo].[dm_Report_DIP_to_Naumen_history] add [Тип предложения] nvarchar(36)
--if   OBJECT_ID(N'devdb.[dbo].[dm_Report_DIP_to_Naumen_20210521]') is  null
--
--begin
--
--CREATE TABLE devdb.[dbo].[dm_Report_DIP_to_Naumen_20210521](
--	[Дата среза] [date] NULL,
--	[crmfioo] [nvarchar](473) NULL,
--	[mobile_fin] [nvarchar](81) NULL,
--	[Комментарий] [varchar](35) NULL,
--	[Приоритет] [float] NULL,
--	[GMT] [varchar](9) NOT NULL,
--	[created_at] [date] NULL,
--	[project_id] [nvarchar](32) NULL
--) 
--
--
--
--
--	
--end







begin tran

delete from [dbo].[dm_Report_DIP_to_Naumen] where created_at = cast(getdate() as date)


  insert into [dbo].[dm_Report_DIP_to_Naumen]
  select 
  [Дата Среза],
  crmfioo,
  mobile_fin,
  [Комментарий],
  [Приоритет],
  [GMT],
  cast(getdate() as date) [created_at],
  project_id
  ,crmClientGUID
  ,[Тип предложения]
  from #final_table_with_all_clients
  where status in ('Подходит', 'Подходит (неконтактный)') 
  
  commit tran

--alter table [dbo].[dm_Report_DIP_to_Naumen] add crmClientGUID nvarchar(36)
--alter table [dbo].[dm_Report_DIP_to_Naumen] add [Тип предложения] nvarchar(36)
--declare @prod int =1
--declare @loayals_load_date date = (SELECT max(cast(created as date)) as loayals_load_date FROM [dwh_new].[dbo].CRM_loyals_buffer_for_sales )
--
----drop table if exists dbo.dm_Report_DIP_to_Naumen
--declare @created_at date = getdate()
--
--delete from dbo.dm_Report_DIP_to_Naumen where created_at = @created_at
--
--   drop table if exists 
--    #bl
--   ,#docripovtcrazm
--   ,#vnutr_trig_today
--   ,#vnesh_trig_today_equi
--   ,#vnesh_trig_today_nbki
--   ,#tmp1_CRM_loyals
--
--
--  select distinct cast(UF_PHONE as nvarchar(max)) UF_PHONE into #bl from STG._Loginom.crib_proxy_black_phones
--  
--
--
--
--  select distinct tr.mobile_phone
--  into #vnutr_trig_today
--  from  stg._loginom.[triggers_base] tr 
--  where cast(call_date as date)>=cast(getdate()-7 as date) and base='T1'
-- 
--
--  select distinct tr.mobile_phone
--  into #vnesh_trig_today_equi
--  from  stg._loginom.[triggers_base] tr 
--  where cast(call_date as date)>=cast(getdate()-7 as date) and base='T2'
--
--
--
--  select null as mobile_phone
--  into #vnesh_trig_today_nbki
--  from  stg._loginom.[triggers_base] tr 
--  where null<>null
--
--
-- 
--  select  *
--into #tmp1_CRM_loyals
--from dwh_new.dbo.CRM_loyals_buffer_for_sales
--
--
--   CREATE CLUSTERED INDEX [Cl_Idx_id1] ON #tmp1_CRM_loyals
--(
--	[mobile_fin] ASC
--)
--
-- delete from #tmp1_CRM_loyals
-- where  mobile_fin is null or len(mobile_fin)<>10 
--  
-- 
-- delete from #tmp1_CRM_loyals
-- where mobile_fin in ('', '9193999788','9192610444','9163680101') 
-- 
--  delete from #tmp1_CRM_loyals
-- where [mobile_fin] in (select * from #bl)
--
--
--select 
--cast(getdate() as date) as [Дата среза],
--case when [type] in ('Повторный заём с новым залогом', 'Повторный заём с известным залогом') then 'Повторный' else 'Докред' end  as [Тип], 
--max(main_limit) over(partition by mobile_fin) as [Лимит],
--			   choose(min(НомерЦвета) OVER(PARTITION by mobile_fin), 
--			   'Зеленый',
--			   'Желтый',
--			   'Синий',
--			   'Оранжевый',
--			   'Красный')
--			   as [Категория],
--case 
--when (category not in ('Зеленый', 'Желтый', 'Синий', 'Оранжевый')) 
--or (naumen14days6comp.phonenumber1 is not null)
--or (naumen14days2comp.phonenumber1 is not null)
--or ((factoranalysis14days.Телефон is not null) and (vnutr_trig_today.mobile_phone is null ))
--or ((factoranalysis14days_fio.ФИО is not null) and (vnutr_trig_today.mobile_phone is null ))
--or (otkazniki30dneycrm.Телефон is not null)
--
--then 0 else 1 end as [Берём],
--
--case 
--when (category not in ('Зеленый', 'Желтый', 'Синий', 'Оранжевый'))
--then 1 else 0 end as [Не проходит по категории],
--
--case 
--when naumen14days6comp.phonenumber1 is not null
--then 1 else 0 end as [Не проходит по факту попадания в Наумен докред по Телефону],
--
--case 
--when naumen14days2comp.phonenumber1 is not null
--then 1 else 0 end as [Не проходит по факту попадания в Наумен ТЛС или аинф],
--
--case 
--when factoranalysis14days.Телефон is not null
--then 1 else 0 end as [Не проходит по факту отказа или отказа док в Факторном],
--
--case 
--when factoranalysis14days_fio.ФИО is not null
--then 1 else 0 end as [Не проходит по факту отказа или отказа док в Факторном по ФИО]
--,
--
--0 as [Не проходит по факту попадания в ЧС]
--
--,
--case 
--when otkazniki30dneycrm.Телефон is not null
--then 1 else 0 end as [Не проходит по факту попадания в отказники за 30 дней]
--
--,
--case 
--when vnutr_trig_today.mobile_phone is not null 
--then 1 else 0 end as [Внутренний триггер]
--
--,
--case 
--when vnesh_trig_today_equi.mobile_phone is not null
--then 1 else 0 end as [Внешний триггер (Эквифакс)]
--
--,
--case 
--when null<>null
--then 1 else 0 end as [Внешний триггер (НБКИ)]
--
--
--
--,[external_id]	
--,[category]	
--,[Type]	
--,[fio]
--,[CRMClientFIO]	+(case when Pep is null then '' else ' '+Pep  end)  [crmfioo]
--,[Паспорт серия]	
--,[Паспорт номер]	
--,[mobile_fin]	
--,[region_projivaniya]	
--,[Berem_pt]
--,[Nalichie_pts]
--,[Pep]
--, case when isnull([В скольких днях ему звонили], 0)<4 then 1
--		        when isnull([В скольких днях ему звонили], 0)<7 then 2
--		        when isnull([В скольких днях ему звонили], 0)<9 then 3
--		        when isnull([В скольких днях ему звонили], 0)<13 then 4 
--				when isnull([В скольких днях ему звонили], 0)>=13 then 5
--				end
--		   as [Группы законтактированности за 90 дней],
--		   case when max(main_limit) over(partition by mobile_fin)<50001 then 5
--		        when max(main_limit) over(partition by mobile_fin)<100001 then 4
--		        when max(main_limit) over(partition by mobile_fin)<200001 then 3
--		        when max(main_limit) over(partition by mobile_fin)<300001 then 2
--		        when max(main_limit) over(partition by mobile_fin)>=300001 then 1 end
--		   as [Группы лимитов]
--		   ,(cast(case 
--		        when        isnull([В скольких днях ему звонили], 0)<4 then 1
--		        when        isnull([В скольких днях ему звонили], 0)<7 then 2
--		        when        isnull([В скольких днях ему звонили], 0)<9 then 3
--		        when        isnull([В скольких днях ему звонили], 0)<13 then 4 
--				when        isnull([В скольких днях ему звонили], 0)>=13 then 5
--				end as float)
--				+
--				cast(case when max(main_limit) over(partition by mobile_fin)<50001 then 5
--		        when max(main_limit) over(partition by mobile_fin)<100001 then 4
--		        when max(main_limit) over(partition by mobile_fin)<200001 then 3
--		        when max(main_limit) over(partition by mobile_fin)<300001 then 2
--		        when max(main_limit) over(partition by mobile_fin)>=300001 then 1 
--				end as float))/2 as [range]
--into #docripovtcrazm
--
--from #tmp1_CRM_loyals as unionedpid 
--     left join [dbo].[dm_report_DIP_pep] as PEP1 on unionedpid.[Паспорт номер]=pep1.НомерПаспорта and unionedpid.[Паспорт серия]=pep1.СерияПаспорта
--	 left join [dbo].[dm_report_DIP_naumen14days6comp] naumen14days6comp on naumen14days6comp.phonenumber1=unionedpid.[mobile_fin]
--	 left join [dbo].[dm_report_DIP_naumen14days2comp] naumen14days2comp on naumen14days2comp.phonenumber1=unionedpid.[mobile_fin]
--	 left join [dbo].[dm_report_DIP_factoranalysis14days] factoranalysis14days on factoranalysis14days.телефон=unionedpid.[mobile_fin]
--	 left join [dbo].[dm_report_DIP_factoranalysis14days_fio] factoranalysis14days_fio on factoranalysis14days_fio.ФИО=unionedpid.[CRMClientFIO]
--	 left join (select distinct * from [dbo].[dm_report_DIP_otkazniki30dneycrm]) otkazniki30dneycrm on otkazniki30dneycrm.Телефон=unionedpid.[mobile_fin]
--	 left join #vnutr_trig_today vnutr_trig_today on vnutr_trig_today.mobile_phone=unionedpid.[mobile_fin]
--	 left join #vnesh_trig_today_equi vnesh_trig_today_equi on vnesh_trig_today_equi.mobile_phone=unionedpid.[mobile_fin]
--	 left join [dbo].[dm_report_DIP_obzvonennost] a2  on a2.phonenumbers=unionedpid.[mobile_fin]
--
--				   
--	drop table if exists #40_50
--select distinct loyals.mobile_fin
--into #40_50
--from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z 
--left join Stg._loginom.Dm_risk_groups rg on cast(rg.number as varchar)=z.Номер
--join #tmp1_CRM_loyals loyals on loyals.external_id=z.Номер
--where rg.fin_gr=50 or z.ВариантПредложенияСтавки=0xB81400155DFABA2A11E9F8551BC95254
--
--	drop table if exists #not_first_time
--
--SELECT distinct  l.mobile_fin not_first_time_phone  into #not_first_time
--  FROM [Reports].[dbo].[dm_report_DIP_mv_call_case]  cc join #tmp1_CRM_loyals l on '8'+l.mobile_fin=case when cc.phonenumbers like '8%' then cc.phonenumbers else '8'+cc.phonenumbers end
--
--  	drop table if exists #orange
--
--  select distinct mobile_fin into #orange from #tmp1_CRM_loyals where category='Оранжевый'
--
--
--
--
--
--;
--
--with cte as (
--select [Дата среза], crmfioo, mobile_fin, Комментарий, Приоритет, [GMT], row_number() over(partition by mobile_fin order by [Приоритет] desc) as rn
--from (
--select  [Дата среза], [crmfioo], '8'+a1.mobile_fin as mobile_fin, 
--case 
--when region_projivaniya = 'Калининградская'                             then 'GMT+02:00' when region_projivaniya = 'Москва'                                      then 'GMT+03:00' 
--when region_projivaniya = 'Севастополь'                                 then 'GMT+03:00' when region_projivaniya = 'Архангельская'                               then 'GMT+03:00'
--when region_projivaniya = 'Белгородская'                                then 'GMT+03:00' when region_projivaniya = 'Брянская'                                    then 'GMT+03:00'
--when region_projivaniya = 'Владимирская'                                then 'GMT+03:00' when region_projivaniya = 'Волгоградская'                               then 'GMT+03:00'
--when region_projivaniya = 'Вологодская'                                 then 'GMT+03:00' when region_projivaniya = 'Воронежская'                                 then 'GMT+03:00'
--when region_projivaniya = 'Ивановская'                                  then 'GMT+03:00' when region_projivaniya = 'Кабардино-Балкария'                          then 'GMT+03:00'
--when region_projivaniya = 'Калужская'                                   then 'GMT+03:00' when region_projivaniya = 'Карачаево-Черкесия'                          then 'GMT+03:00'
--when region_projivaniya = 'Кировская'                                   then 'GMT+03:00' when region_projivaniya = 'Костромская'                                 then 'GMT+03:00'
--when region_projivaniya = 'Краснодарский край'                          then 'GMT+03:00' when region_projivaniya = 'Курская'                                     then 'GMT+03:00'
--when region_projivaniya = 'Ленинградская'                               then 'GMT+03:00' when region_projivaniya = 'Липецкая'                                    then 'GMT+03:00'
--when region_projivaniya = 'Московская'                                  then 'GMT+03:00' when region_projivaniya = 'Мурманская'                                  then 'GMT+03:00'
--when region_projivaniya = 'Ненецкий автономный округ'                   then 'GMT+03:00' when region_projivaniya = 'Нижегородская'                               then 'GMT+03:00'
--when region_projivaniya = 'Новгородская'                                then 'GMT+03:00' when region_projivaniya = 'Орловская'                                   then 'GMT+03:00'
--when region_projivaniya = 'Пензенская'                                  then 'GMT+03:00' when region_projivaniya = 'Псковская'                                   then 'GMT+03:00'
--when region_projivaniya = 'Адыгея'                                      then 'GMT+03:00' when region_projivaniya = 'Дагестан'                                    then 'GMT+03:00'
--when region_projivaniya = 'Ингушетия'                                   then 'GMT+03:00' when region_projivaniya = 'Калмыкия'                                    then 'GMT+03:00'
--when region_projivaniya = 'Карелия'                                     then 'GMT+03:00' when region_projivaniya = 'Коми'                                        then 'GMT+03:00'
--when region_projivaniya = 'Крым'                                        then 'GMT+03:00' when region_projivaniya = 'Марий Эл'                                    then 'GMT+03:00'
--when region_projivaniya = 'Мордовия'                                    then 'GMT+03:00' when region_projivaniya = 'Северная Осетия'                             then 'GMT+03:00' 
--when region_projivaniya = 'Ростовская'                                  then 'GMT+03:00' when region_projivaniya = 'Рязанская'                                   then 'GMT+03:00'
--when region_projivaniya = 'Саратовская'                                 then 'GMT+03:00' when region_projivaniya = 'Саратов'                                     then 'GMT+03:00'
--when region_projivaniya = 'Смоленская'                                  then 'GMT+03:00' when region_projivaniya = 'Ставропольский край'                         then 'GMT+03:00'
--when region_projivaniya = 'Тамбовская'                                  then 'GMT+03:00' when region_projivaniya = 'Тверская'                                    then 'GMT+03:00'
--when region_projivaniya = 'Тульская'                                    then 'GMT+03:00' when region_projivaniya = 'Чеченская Республика'                        then 'GMT+03:00'
--when region_projivaniya = 'Чувашская - Чувашия'                         then 'GMT+03:00' when region_projivaniya = 'Чувашская Чувашия'                           then 'GMT+03:00'
--when region_projivaniya = 'Ярославская'                                 then 'GMT+03:00' when region_projivaniya = 'Астраханская'                                then 'GMT+04:00'
--when region_projivaniya = 'Самарская'                                   then 'GMT+04:00' when region_projivaniya = 'Удмуртская'                                  then 'GMT+04:00'
--when region_projivaniya = 'Ульяновская'                                 then 'GMT+04:00' when region_projivaniya = 'Курганская'                                  then 'GMT+05:00'
--when region_projivaniya = 'Оренбургская'                                then 'GMT+05:00' when region_projivaniya = 'Пермский край'                               then 'GMT+05:00'
--when region_projivaniya = 'Башкортостан'                                then 'GMT+05:00' when region_projivaniya = 'Свердловская'                                then 'GMT+05:00'
--when region_projivaniya = 'Тюменская'                                   then 'GMT+05:00' when region_projivaniya = 'Ханты-Мансийский Автономный округ - Югра АО' then 'GMT+05:00'
--when region_projivaniya = 'Челябинская'                                 then 'GMT+05:00' when region_projivaniya = 'Ямало-Ненецкий АО'                           then 'GMT+05:00'
--when region_projivaniya = 'Омская'                                      then 'GMT+06:00' when region_projivaniya = 'Томская'                                     then 'GMT+06:00'
--when region_projivaniya = 'Новосибирская'                               then 'GMT+06:00' when region_projivaniya = 'Алтайский край'                              then 'GMT+07:00'
--when region_projivaniya = 'Красноярский край'                           then 'GMT+07:00' when region_projivaniya = 'Кемеровская'                                 then 'GMT+07:00'
--when region_projivaniya = 'Кемеровская - Кузбасс'                       then 'GMT+07:00' when region_projivaniya = 'Алтай'                                       then 'GMT+07:00'
--when region_projivaniya = 'Тыва'                                        then 'GMT+07:00' when region_projivaniya = 'Хакасия'                                     then 'GMT+07:00'
--when region_projivaniya = 'Иркутская'                                   then 'GMT+08:00' when region_projivaniya = 'Бурятия'                                     then 'GMT+08:00'
--when region_projivaniya = 'Амурская'                                    then 'GMT+09:00' when region_projivaniya = 'Забайкальский край'                          then 'GMT+09:00'
--when region_projivaniya = 'Саха-Якутия'                                 then 'GMT+09:00' when region_projivaniya = 'Еврейская Авт. обл.'                         then 'GMT+10:00'
--when region_projivaniya = 'Приморский край'                             then 'GMT+10:00' when region_projivaniya = 'Хабаровский край'                            then 'GMT+10:00'
--when region_projivaniya = 'Магаданская'                                 then 'GMT+10:00' when region_projivaniya = 'Саха-Якутия'                                 then 'GMT+11:00'
--when region_projivaniya = 'Сахалинская'                                 then 'GMT+11:00' when region_projivaniya = 'Камчатский край'                             then 'GMT+12:00'
--when region_projivaniya = 'Чукотский автономный округ'                  then 'GMT+12:00' when region_projivaniya = 'Татарстан'                                   then 'GMT+03:00'
--else 'GMT+03:00' end as [GMT], 
--		 
--			case 
--					when a1.mobile_fin in (select * from #orange) then 'Оранжевая категория'
--					when a1.mobile_fin not in (select * from #not_first_time) then 'Впервые попали в обзвон'
--					when a1.mobile_fin  in (select * from #40_50) then '40-50%'
--					else 'Остальное' end
--			
--			
--			as [Комментарий]
--				,
--				case 
--				     when [Внутренний триггер]=1 then 90 
--				     when [Внутренний триггер]<>1 and [Внешний триггер (Эквифакс)]=1 then 80
--				     when [Внутренний триггер]<>1 and [Внешний триггер (Эквифакс)]<>1 then 
--					 
--					 80- (10*range)  end as [Приоритет]
--
--
--		   from #docripovtcrazm a1
--
--		   where [Берём]=1 
--) n1_for_rn 
--) 
--
--
--
--
--insert into dbo.dm_Report_DIP_to_Naumen
--select [Дата среза]                         
--,      crmfioo                              
--,      mobile_fin
--,      Комментарий                          
--,      Приоритет                            
--,      [GMT]                                
--,      created_at = @created_at             
--
----into dbo.dm_Report_DIP_to_Naumen
--from cte                                          
--,    (SELECT @loayals_load_date loayals_load_date) x1
--where rn=1
--	and (
--		cast(getdate() as date)= x1.loayals_load_date
--		or @prod=0)
--
--




end
