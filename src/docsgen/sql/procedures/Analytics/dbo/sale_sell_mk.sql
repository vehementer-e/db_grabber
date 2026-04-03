
	CREATE        proc [dbo].[Продажа трафика Московский капитал]
	as
	 
drop table if exists #fa

select number
 ,      productType
,      phone  
,      declined
,      region  
,      link

 ,      created
,      cancelled
,      approved
,      issued
, firstSum
, returnType
, source
, carBrand, carModel, carYear, call1approved, channel
, fio fio
   into #fa
from _request a

where created>=getdate()-60 or issued is not null



create nonclustered index t on #fa
(
phone , created  , number
)

drop table if exists #t1
select number Номер
,      firstSum [Первичная сумма]
,      phone Телефон
,      returnType  [Вид займа]
,      b.channelGroup [Группа каналов]
,      a.source Источник
,     carBrand Марка
,      carModel Модель
,      declined Отказано
,      region [Регион проживания]
,      carYear ГодВыпуска
--,      a.isInstallment
	into #t1
from      #fa a
                                      
left join channel b on a.channel=b.channel

where declined between cast(getdate()-1 as date) and cast(getdate()+1 as date)								
--and Дубль=1								
--and isInstallment=0								
and producttype='PTS'								
and returnType = 'Первичный'								
and b.channelGroup <> 'Партнеры'								
and a.source not in (								
'devtek'								
,'gidfinance-installment'								
,'bankiru-installment'								
,'bankiru-installment-ref'								
,'gidfinance'								
,'leadcraft-installment-ref'								
,'leadcraft-ref'								
,'unicom24r'								
,'unicom24'								
,'unicom24-installment-ref'								
,'sravniru'								
,'sravniru-installment-ref'	
, 'avtolombard-credit'
,'avtolombard-credit-ref'

,'psb-ref'
,'vtb-ref'
,'infoseti-deepapi-pts' 
,'infoseti-deepapi-installment' 
,'infoseti'
,'psb-deepapi'


)		
and  source  not like '%bankiru%'
and  source  not in (select [Источник трафика] from source_block_sell where [Источник трафика] is not null)

--and [Регион проживания]
--in
--('Москва г'
--,'Московская обл'
--,'Санкт-Петербург г'
--,'Ленинградская обл'
--)
--select distinct [Регион проживания] from   #t1
				
  and declined>='2025-04-15 17:00:00'

drop table if exists #feodor
  SELECT [Дата лида], [Причина непрофильности], Телефон, lead_id id, isinstallment into #feodor
  FROM Analytics.dbo.v_feodor_leads
  where [Статус лида]='Непрофильный' and IsInstallment=0
  --and [Причина непрофильности]='Задолженность ФССП'
  and [Причина непрофильности] in 

  (
-- 'Нет прописки', 
--'Категория авто', 
--'Отказ паспорта', 
--'Отказ от разговора', 
--'Плохие отзывы', 
--'Оставлял заявку давно', 
--'Ищет в банке', 
--'Большой платеж', 
--'Необходима конкретная компания', 
--'Деньги потребуются позднее', 
--'Не хочет оформляться в МФК', 
--'Нужны наличные', 
--'Хочу под другой залог', 
--'Нужен бОльший срок', 
--'Авто в залоге', 
--'Документы оформлены на разные фамилии', 
--'Нужна бОльшая сумма', 
--'Не хочет под залог', 
--'Далеко ехать к агенту', 
--'Хочу дискретный график', 
--'Нужна меньшая сумма', 
--'Высокий %', 
--'Хочет сдать авто в лизинг', 
--'Планирует продать авто', 
--'Не подходит ни один способ оформления', 
--'Отказ о ПД', 
--'Не оставлял заявку', 
--'Неудобен платеж 2 раза в месяц', 
--'Подумаю/Посоветуюсь', 
--'Ищет лизинг', 
--'Дубликат в замен утраченного менее 45 дней', 
--'Не РФ, не зарегистрирвоано авто на территории РФ', 
--'Нет СТС', 
--'Отказывается предоставлять данные по анкете', 
--'Задолженность ФССП', 
--'Не подходит по возрасту', 
--'Авто не на ходу', 
--'Нет авто', 
--'Нужен трейд-ин', 
--'Не подходит авто по году выпуска', 
--'В кредите (более 15%)', 
--'Нет паспорта (перевыпуск, замена)', 
--'Авто не в собственности не готов переоформить', 
--'Авто на юр лице'
'Нет прописки',
'Категория авто',
'Отказ паспорта',
'Отказ от разговора',
'Плохие отзывы',
'Оставлял заявку давно',
'Большой платеж',
'Необходима конкретная компания',
'Деньги потребуются позднее',
'Не хочет оформляться в МФК',
'Нужны наличные',
'Нужен бОльший срок',
'Авто в залоге',
'Нужна бОльшая сумма',
'Далеко ехать к агенту',
'Хочу дискретный график',
'Нужна меньшая сумма',
'Высокий %',
'Отказ о ПД',
'Неудобен платеж 2 раза в месяц',
'Подумаю/Посоветуюсь',
'Ищет лизинг',
'Дубликат в замен утраченного  менее 45 дней',
'Отказывается предоставлять данные по анкете',
'Задолженность ФССП',
'Не подходит по возрасту',
'Нужен трейд-ин',
'Не подходит авто по году выпуска',
'В кредите (более 15%)',
'Авто не в собственности не готов переоформить',
'Авто на юр лице'--,
  )
 -- and len(Телефон)=10
  and [Дата лида]  between cast(getdate()-1 as date) and cast(getdate()+1 as date)	
  and cast([Дата лида] as date)>='20231002'
  and 1=0

  delete from #feodor where len(Телефон)<>10

 


  drop table if exists #feodor_lcrm

  select a.*, b.region  UF_REGIONS_COMPOSITE into #feodor_lcrm
  from #feodor a
  join v_lead b on a.id=b.id
  --join #TMP_leads c on c.ID=a.id
  where isnull(b.source, '') not in (								
'devtek'								
,'gidfinance-installment'								
,'bankiru-installment'								
,'bankiru-installment-ref'								
,'gidfinance'								
,'leadcraft-installment-ref'								
,'leadcraft-ref'								
,'unicom24r'								
,'unicom24'								
,'unicom24-installment-ref'								
,'sravniru'								
,'sravniru-installment-ref'				
,'avtolombard-credit'						
,'avtolombard-credit-ref'			
					
,'psb-ref'						
,'vtb-ref'			

)	and b.channel_group<>'Партнеры'
--and [dbo].[lcrm_is_inst_lead](UF_TYPE, UF_SOURCE, null)=0

  drop table if exists #feodor_survey
  
  select b.id
  , try_cast( max(case when Question='Сумма кредита' then Answer end)                                                          as bigint      ) [Сумма кредита]
  , try_cast( max(case when Question='Марка'       then case when ISJSON(Answer)=1 then json_value(Answer, '$.text') end end)  as nvarchar(50)) [Марка]      
  , try_cast( max(case when Question='Модель'      then case when ISJSON(Answer)=1 then json_value(Answer, '$.text') end end)  as nvarchar(50)) [Модель]     
  , try_cast( max(case when Question='Год выпуска' then Answer end)                                                            as int         ) [Год выпуска]
  ,  max(case when Question='В каком городе Вы проживаете?' and isjson(Answer)=1 then json_value(Answer, '$.id' ) end)                                                     [Регион id]
  into #feodor_survey
  from Feodor.dbo.dm_LeadAndSurvey 
  a
  join #feodor_lcrm b on try_cast(a.[ID LCRM] as nvarchar(36)) =b.id   collate Cyrillic_General_CI_AS
  group by b.id


 ---- {"id":"fee76045-fe22-43a4-ad58-ad99e903bd58","text":"г Ульяновск","data":{"region_fias_id":"fee76045-fe22-43a4-ad58-ad99e903bd58","area_fias_id":null,"city_fias_id":"bebfd75d-a0da-4bf9-8307-2e2c85eac463","city_district_fias_id":null,"settlement_fias_id":null},"selected":true}
 -- select top 100 Answer, json_value(Answer, '$.id' ) from Feodor.dbo.dm_LeadAndSurvey a
 -- join v_feodor_leads b on try_cast(a.[ID LCRM] as numeric) =b.id and b.[Дата лида]>getdate()-1
 -- where Question='В каком городе Вы проживаете?'
 ---- group by Question
 -- order by 1
--select * from 	#t1		
--select * from 	#feodor_survey

insert into #t1
select
Номер = a.id 
, [Первичная сумма] = b.[Сумма кредита]
, Телефон = a.Телефон
, [Вид займа] = null
, [Группа каналов] = null
, Источник = null 
, Марка = b.Марка
, Модель = b.Модель
, Отказано = [Дата лида]
, [Регион проживания] = isnull(r.name, a.UF_REGIONS_COMPOSITE)
, ГодВыпуска		 = b.[Год выпуска]
--, [Отказ ФССП]= case when [Причина непрофильности]='Задолженность ФССП' then 1 else 0 end
--, IsInstallment = a.IsInstallment
from #feodor_lcrm a
left join #feodor_survey b on a.id=b.id
left join stg.[_fedor].[dictionary_region] r on r.[FiasCode]=b.[Регион id]
where a.Телефон is not null --and b.Марка is not null and b.[Год выпуска] is not null and b.Модель is not null 
--and 
-- isnull(r.name, a.UF_REGIONS_COMPOSITE) in (

--  'Москва г'
--,'г. Москва'
--,'Московская обл'
--,'Санкт-Петербург г'
--,'Ленинградская обл'
----,
----,'Иркутская обл'
------,'Ростовская обл'
----,'Рязанская обл'
----,'Тюменская обл'
----,'Челябинская обл'
----,'Бурятия Респ'
----,'Нижегородская обл'
------,'Свердловская обл'
------,'Воронежская обл'
------,'Самарская обл'
------,'Тульская обл'
------,'Чувашская Республика - Чувашия'
------,'Краснодарский край'
----,'Башкортостан Респ'
----------------------
----------------------
-- , 'Москва'
--,'Московская область'
--,'Санкт-Петербург'
--,'Ленинградская область'
----,'Иркутская область'
------,'Ростовская область'
----,'Рязанская область'
----,'Тюменская область'
----,'Челябинская область'
----,'Республика Бурятия'
----,'Нижегородская область'
------,'Свердловская область'
------,'Воронежская область'
------,'Самарская область'
------,'Тульская область'
------,'Чувашская Республика'
------,'Краснодарский край'
----,'Республика Башкортостан'
--)


--select cast(getdate()-2 as date)								
								
drop table if exists #for_sale
								
;								
								
with v as (								
select a.Телефон , a.[Первичная сумма],a.[Регион проживания], a.Марка, a.Модель, a.ГодВыпуска, a.Номер,  a.Отказано, ROW_NUMBER() over(partition by a.Телефон order by a.Отказано desc) rn
--, a.isInstallment

from #t1 a								
outer apply (select top 1 b.number     from #fa b where b.created between dateadd(day, -8, a.Отказано ) and  dateadd(day, 8, a.Отказано ) and a.Номер<>b.number and  a.Телефон=b.phone and b.cancelled is null and b.cancelled is null and b.declined is null ) x								
outer apply (select top 1 b.number from #fa b where a.Телефон=b.phone and  b.issued is not null ) x1								
outer apply (select top 1 b.number from #fa b where a.Телефон=b.phone and  b.approved >=dateadd(day, -30 , a.Отказано) ) x2								
left join Analytics.dbo.mv_loans b on a.Телефон=b.[Основной телефон клиента CRM]								
left join Analytics.dbo.mv_loans b1 on a.Телефон=b1.[Телефон договор CMR]			
left join Analytics.dbo.[Продажа трафика Московский капитал история] p on p.Телефон=a.Телефон and p.report_d>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.number is  null and								
x2.number is  null and								
x1.number is  null 	and								
p.Телефон is  null 							
								
)								
select Телефон,  getdate() as report_dt, cast(getdate() as date) report_d, Номер  into #for_sale from v where rn=1								
order by Отказано								

--delete a from  #for_sale a
--join [Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] b on a.Телефон=b.phonenumber and uf_registered_at>=getdate()-7


--delete a from  #for_sale a
--join [log_telegrams_long dt>='20230624'	and dt<='2023-06-26 12:00:00'] b on a.Телефон=b.value

--select * from #for_sale a
--left join request b on a.Номер=b.number

if (select count(*) from #for_sale)>0
begin

begin tran
--delete from dbo.[Продажа трафика Московский капитал история]
--drop table if exists dbo.[Продажа трафика Московский капитал история]
--select * into  dbo.[Продажа трафика Московский капитал история] from #for_sale

insert into dbo.[Продажа трафика Московский капитал история]
select * from #for_sale

commit tran

declare @tg_message nvarchar(max) = (select string_agg(Телефон, '
') from #for_sale)
if @tg_message<>''
exec [log_telegram] @tg_message, '-1001794100850'

begin tran
--delete from dbo.[Продажа трафика Московский капитал буфер]
--drop table if exists dbo.[Продажа трафика Московский капитал буфер]
--select * into  dbo.[Продажа трафика Московский капитал буфер] from #for_sale
delete from dbo.[Продажа трафика Московский капитал буфер]
insert into dbo.[Продажа трафика Московский капитал буфер]
select * from #for_sale

commit tran

--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '3C81EE85-2673-49F4-9DCE-DD8E72F55D27'

end



--if (select count(*) from #for_sale)=0
--begin
--exec log_email 'Продажа трафика Московский капитал - не было трафика' , 'P.Ilin@techmoney.ru', 'gmail_moskovskiy_kapital'
--end

 