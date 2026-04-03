	CREATE      proc [dbo].[Продажа заявок Европейскому]
	as

begin
	
drop table if exists #fa								
								
select Номер,  case when [Причина отказа]= 'UW. Негатив по ФССП' then 1 else 0 end [Отказ ФССП],  [Первичная сумма],  Телефон, [Вид займа], [Группа каналов], Источник, Отказано, [Регион проживания] , [Ссылка заявка], isInstallment, isPts , Дубль , ДатаЗаявкиПолная , Аннулировано  , Одобрено , [Заем выдан]  , [Заем аннулирован] into #fa								
from reports.dbo.dm_Factor_Analysis_001  a								
								
create nonclustered index t on #fa								
(								
Телефон, ДатаЗаявкиПолная, Номер								
)								
								
drop table if exists #t1								
select  Номер, [Первичная сумма], Телефон, [Вид займа], [Группа каналов], Источник , z.Марка , z.Модель, Отказано, [Регион проживания], z.ГодВыпуска	, [Отказ ФССП]			, a.isInstallment				
into #t1								
from #fa  a								
left join								
(								
select a.Ссылка, b.Наименование Марка, c.Наименование Модель, year(dateadd(year, -2000, ГодВыпуска)) ГодВыпуска from								
stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС a								
left join stg._1cCRM.Справочник_МаркиАвтомобилей b on a.МаркаМашины=b.Ссылка								
left join stg._1cCRM.Справочник_МоделиАвтомобилей c on a.Модель=c.ссылка ) z on z.Ссылка=a.[Ссылка заявка]								
								
where Отказано between cast(getdate()-1 as date) and cast(getdate()+1 as date)								
--and Дубль=1								
and isPts=1							
and [Вид займа] = 'Первичный'								
and [Группа каналов] <> 'Партнеры'								
and isnull(Источник, '') not in (								
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
--,'avtolombard-credit'						
)						
and [Регион проживания]
in
('Москва г'
,'Московская обл'
,'Краснодарский край'
,'Ростовская обл'
,'Нижегородская обл'
,'Самарская обл'
,'Татарстан Респ'
,'Санкт-Петербург г'
,'Ленинградская обл'
)
--select distinct [Регион проживания] from   #t1
					



drop table if exists #feodor
  SELECT [Дата лида], [Причина непрофильности], Телефон, id, isinstallment into #feodor
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

  delete from #feodor where len(Телефон)<>10

  DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[UF_REGIONS_COMPOSITE] [nvarchar](128) NULL
)


DECLARE @start_id numeric(10, 0), @depth_id numeric(10, 0)
DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)


DROP TABLE IF EXISTS #ID_List
CREATE TABLE #ID_List(ID numeric(10, 0))

--название таблицы со списком ID
SELECT @ID_Table_Name = '#ID_List'
--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'

TRUNCATE TABLE #TMP_leads

insert into #ID_List
select id from #feodor

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение




  drop table if exists #feodor_lcrm

  select a.*, c.UF_REGIONS_COMPOSITE into #feodor_lcrm from #feodor a
  join stg._LCRM.lcrm_leads_full_calculated b on a.id=b.id
  join #TMP_leads c on c.ID=a.id
  where isnull(b.UF_SOURCE, '') not in (								
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
--,'avtolombard-credit'						

)	and b.[Группа каналов]<>'Партнеры'
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
  join #feodor_lcrm b on try_cast(a.[ID LCRM] as numeric) =b.id
  group by b.id


 ---- {"id":"fee76045-fe22-43a4-ad58-ad99e903bd58","text":"г Ульяновск","data":{"region_fias_id":"fee76045-fe22-43a4-ad58-ad99e903bd58","area_fias_id":null,"city_fias_id":"bebfd75d-a0da-4bf9-8307-2e2c85eac463","city_district_fias_id":null,"settlement_fias_id":null},"selected":true}
 -- select top 100 Answer, json_value(Answer, '$.id' ) from Feodor.dbo.dm_LeadAndSurvey a
 -- join v_feodor_leads b on try_cast(a.[ID LCRM] as numeric) =b.id and b.[Дата лида]>getdate()-1
 -- where Question='В каком городе Вы проживаете?'
 ---- group by Question
 -- order by 1
--select * from 	#t1		

insert into #t1
select
Номер = null 
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
, [Отказ ФССП]= case when [Причина непрофильности]='Задолженность ФССП' then 1 else 0 end
, IsInstallment = a.IsInstallment
from #feodor_lcrm a
left join #feodor_survey b on a.id=b.id
left join stg.[_fedor].[dictionary_region] r on r.[FiasCode]=b.[Регион id]
where a.Телефон is not null --and b.Марка is not null and b.[Год выпуска] is not null and b.Модель is not null 
and 
 isnull(r.name, a.UF_REGIONS_COMPOSITE) in (

'Москва'
,'Московская область'
,'Московская'
,'Краснодарский край'
,'Краснодарский'
,'Ростовская область'
,'Ростовская'
,'Нижегородская область'
,'Нижегородская'
,'Самарская область'
,'Самарская'
,'Республика Татарстан'
,'Татарстан'
,'Санкт-Петербург'
,'Ленинградская область'
,'Ленинградская'


 )


--select cast(getdate()-2 as date)								
								
drop table if exists #for_sale
								
;								
								
with v as (								
select a.Телефон, a.[Первичная сумма],a.[Регион проживания], a.Марка, a.Модель, a.ГодВыпуска, a.Номер,  a.Отказано, ROW_NUMBER() over(partition by a.Телефон order by a.Отказано desc) rn
, a.[Отказ ФССП]
, a.isInstallment

from #t1 a								
outer apply (select top 1 *     from #fa b where b.ДатаЗаявкиПолная between dateadd(day, -5, a.Отказано ) and  dateadd(day, 5, a.Отказано ) and a.Номер<>b.Номер and  a.Телефон=b.Телефон and b.Аннулировано is null and b.[Заем аннулирован] is null and b.Отказано is null ) x								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.[Заем выдан] is not null ) x1								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.Одобрено >=dateadd(day, -30 , a.Отказано) ) x2								
left join Analytics.dbo.mv_loans b on a.Телефон=b.[Основной телефон клиента CRM]								
left join Analytics.dbo.mv_loans b1 on a.Телефон=b1.[Телефон договор CMR]			
left join Analytics.dbo.[Продажа заявок Европейскому история] p on p.Телефон=a.Телефон and p.report_d>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.Номер is  null and								
x2.Номер is  null and								
x1.Номер is  null 	and								
p.Телефон is  null 							
								
)								
select Телефон, [Первичная сумма], [Регион проживания], Марка, Модель, ГодВыпуска, Номер, Отказано, rn, getdate() as report_dt, cast(getdate() as date) report_d, [Отказ ФССП], isinstallment into #for_sale from v where rn=1								
order by Отказано	


--delete a from  #for_sale a
--join [log_telegrams_long dt>='20230624'	and dt<='2023-06-26 12:00:00'] b on a.Телефон=b.value


--select * from dbo.[Продажа заявок Европейскому история]
--where report_d>=cast(getdate()-1 as date)
--order by Отказано desc

if (select count(*) from #for_sale)>0
begin

begin tran
--delete from dbo.[Продажа заявок Европейскому история]
--drop table if exists dbo.[Продажа заявок Европейскому история]
--select * into  dbo.[Продажа заявок Европейскому история] from #for_sale

insert into dbo.[Продажа заявок Европейскому история]
select * from #for_sale

commit tran

--alter table dbo.[Продажа заявок Европейскому история]
--add  [Отказ ФССП] int

--alter table dbo.[Продажа заявок Европейскому история]
--  add  isInstallment smallint

begin tran
--delete from dbo.[Продажа заявок Европейскому буфер]
--drop table if exists dbo.[Продажа заявок Европейскому буфер]
--select * into  dbo.[Продажа заявок Европейскому буфер] from #for_sale
delete from dbo.[Продажа заявок Европейскому буфер]
insert into dbo.[Продажа заявок Европейскому буфер]
select * from #for_sale

commit tran

--alter table dbo.[Продажа заявок Европейскому буфер]
--add  [Отказ ФССП] int
--alter table dbo.[Продажа заявок Европейскому буфер]
--add  isInstallment smallint

--select * from dbo.[Продажа заявок Европейскому буфер]
--select * from dbo.[Продажа заявок Европейскому история]

--/SalesDepartment/Продажа трафика/Sales. Продажа заявок Европейскому
--Рассылка отчета
--da2dbcc3-6003-4a2a-938b-6d06b3d5568b
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'DA2DBCC3-6003-4A2A-938B-6D06B3D5568B'
--/SalesDepartment/Продажа трафика/Sales. Продажа заявок Европейскому
--Публикация в sftp
--749fa3cb-95fe-4a75-bf5f-c238c2365f16
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '749FA3CB-95FE-4A75-BF5F-C238C2365F16'




declare @tg_message nvarchar(max) = (select string_agg(cast(Телефон as nvarchar(max))+case when [Регион проживания]<>'' then ' - '+[Регион проживания]else '' end +' - '+case when IsInstallment=1 then 'Инст' else 'ПТС' end, '
') from #for_sale)
exec [log_telegram] @tg_message, '-1001842900912'

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'DA2DBCC3-6003-4A2A-938B-6D06B3D5568B'
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '749FA3CB-95FE-4A75-BF5F-C238C2365F16'


end



if (select count(*) from #for_sale)=0
begin
exec log_email  'Продажа заявок Европейскому - не было трафика' , 'P.Ilin@techmoney.ru'	, 	  'gmail_evropeyskiy'
end


end