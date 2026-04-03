
 CREATE proc [dbo].[marketing_infoseti] @mode nvarchar(max) = 'update'
as

if @mode =  'update'

begin

drop table if exists ##infoseti_detail
 

SELECT 
     a.created  AS created,
    a.id AS id,
	 isnull(b.source,  a.source  ) source ,
	isnull( b.productTypeExternal ,  a.productTypeExternal) productTypeExternal ,
    a.isAccepted AS IsAccepted,
	case when a.source like 'infoseti%' then a.linkUrl end linkUrlInfoseti,
    a.isClickThrough AS IsClickThrough,
    b.number AS number,
    b.isPts AS IsPts,
	b.origin,
	b.returntype , 
    b.call1 AS Call1,
    b.declined AS declined,
    b.call1Approved AS Call1Approved,
     b._fullRequestPTS AS _fullRequestPTS,
    b.approved AS Approved,
    b.issued AS Issued,
    b.issuedSum AS IssuedSum  ,
    b.guid AS guid,
_profilePts               Экран_Анкета_ПТС  , 
_docPhotoPts			  Экран_фото_паспорта_ПТС  , 
_docPhotoLoadedPts		  Загрузил_фото_паспорта_ПТС  , 
_pack1Pts				  Экран_подписание_первого_пакета_ПТС  , 
_pack1SignedPts			  Подписал_первый_пакет_ПТС  , 
_clientAndDocPhoto2Pts	  Экран_загрузка_фото_паспорта_и_клиента_ПТС , 
_additionalInfoPTS		  Экран_доп_информация_ПТС , 
_carDocPhotoPTS			  Экран_фото_документов_авто_ПТС , 
b.needBki  , 
offerProofOfIncomeType [Тип оффера подтверждение дохода],
case when eventDesc like '% 9.6%' then 1 else 0 end [Загрузил документ подтверждающий доход],
_payMethodPts			  Экран_способ_выдачи_ПТС , 
_cardLinkedPTS			  Карта_привязана_ПТС , 
_carPhotoPTS			  Экран_фото_авто_ПТС , 
_fullRequestPTS			  Экран_отправлена_полная_заявка_ПТС , 
_approvalPTS			  Экран_одобрена_заявка_ПТС , 
_pack2PTS				  Экран_подписание_второго_пакета_ПТС , 
_pack2SignedPTS			   Подписал_второй_пакет_ПТС,
_profile                   Экран_анкета_Беззалог, 
_passport                   Экран_паспорт_Беззалог,   
firstSum                    Первичная_сумма,
[_upridYes]                 Уприд_Есть,
[abPhotoUprid]              Ветка_Необходимость_Фото_Паспорта,
_photosCnt                   Загрузил_штук_фото_паспорта,
_photos                    Экран_загрузка_фото_Беззалог, 

_pack1                     Экран_подпписание_первого_пакета_Беззалог , 
_call1                     Экран_получение_предв_одобрение_Беззалог , 
_workAndIncome              Экран_о_работе_и_доходе_Беззалог , 
_cardLinked                  Экран_способ_выдачи_Беззалог , 
_approvalWaiting Экран_ожидание_одобрения_Беззалог , 
_offerSelection Экран_выбор_предложения_Беззалог , 
_contractSigning Экран_подписание_договора_Беззалог  ,
reportDate = cast(isnull(isnull(b.issued, b.call1), a.created) as date) 
, cv.week reportWeek
, cv.month reportMonth
 , phone =  isnull(b.phone,  a.phone ) 
, a.decline
, b.productType2
, _profileBI              Экран_Анкета_БИ
, _photoBI                Экран_Фото_БИ
, _pack1BI                Экран_подпписание_первого_пакета_БИ
, _preApprovalWaitingBI   Экран_ожидание_предодобра_БИ
, _incomeOfferSelectionBI Экран_выбор_предложения_БИ
, _proofOfIncomeBI        Экран_подтверждение_дохода_БИ     
, _proofOfIncomeLoadedBI  Загружен_документ_подтверждающий_доход_БИ
, _calculatorBI           Экран_калькулятор_БИ
, _payMetodBI             Экран_способ_выдачи_БИ
, _timerBI                Экран_с_таймером_БИ
, _timerOutBI             Выход_С_экрана_с_таймером_БИ
, _pack2SignedBI          Подписал_2_пакет_БИ
   , cast( b.checking   as date)    AS [Загрузил документы]
   , cast( isnull(b.call15approved , b.call2)  as date)    AS [call15 одобрено]
   , checkingSla + isnull(verificationSla, 0) [SLA проверки]
   , cast( b.[Call2]   as date)    AS [Call2]
   , cast( b.[call2Approved]   as date)    AS [Call2 одобрено]
    , cast( b.call5   as date)    AS call5
   , cast(  b.approved  as date)  AS [Одобрен]
   , cast( b._timerBI   as date)    AS [Экран с таймером БИ]
   , cast( b._timerOutBI   as date)    AS [Экран с таймером выход БИ]
   , cast( b._pack2SignedBI   as date)    AS [Подписал 2 пакет БИ]
	,[срок выданного кредита месяцы] = case when issued  is not null then b.term end 
   , b.interestRate [Процентная ставка]
,  c.sum [Запрошенная сумма в банке] 
   , b.[sumProofOfIncome] [Сумма с подтв. дохода]
   , b.[sumNoProofOfIncome] [Сумма без подтв. дохода]
	,[признак страхования] =  case when b.approved  is not null then b.isAddProductInsurRequest end  

	,   b.cancelled ИстекСрокДействия
	--,
	--isnull(  b.[isDubl] , a.isdubl) isdubl 
 
	INTO ##infoseti_detail
FROM _lead_request a
LEFT JOIN  request b ON a.requestGuid = b.guid 
left join v_request_external c on c.id=a.id

left join calendar_view cv on cv.date = cast( isnull(isnull(b.issued, b.call1), a.created) as date)

WHERE (  isnull(b.source,  a.source  )  IN ('infoseti-deepapi-installment', 'infoseti-deepapi-pts', 'infoseti') 
 
)
AND isnull(isnull(b.issued, b.call1), a.created)  between '20241213' and cast( getdate() +1  as date)  
and isnull(b.isDubl, -2) <>-1
-- and isnull( isnull(  b.[isDubl] , a.isdubl) , 0)=0

 
 --select * from ##infoseti_detail
 order by  1
 
 
drop table if exists #visit
select source,  cast( created  as date) date, count(distinct client_id) visit into #visit  from v_visit 
where source  IN ('infoseti-deepapi-installment', 'infoseti-deepapi-pts', 'infoseti')   and created between '20241213' and cast( getdate()+1  as date) 
group by cast( created  as date) , source

drop table if exists ##infoseti_report

 

;
with v as (
select isnull(isnull( cast( a.reportDate  as date) , b.date ), c.date ) date, a.[created]
, a.[id]
, isnull(isnull(a.[source] , b.source), c.source) source
, a.[productTypeExternal]
, a.[IsAccepted]
, a.[linkUrlInfoseti]
, a.[IsClickThrough]
, a.[number]
, a.[IsPts]
, a.[origin]
, a.[returntype]
, a.[Call1]
, a.[declined]
, a.[Call1Approved]
, a.[_fullRequestPTS]
, a.[Approved]
, a.[Issued]
, a.[IssuedSum]
, a.[guid]
, a.[Экран_Анкета_ПТС]
, a.[Экран_фото_паспорта_ПТС]
, a.[Загрузил_фото_паспорта_ПТС]
, a.[Экран_подписание_первого_пакета_ПТС]
, a.[Подписал_первый_пакет_ПТС]
, a.[Экран_загрузка_фото_паспорта_и_клиента_ПТС]
, a.[Экран_доп_информация_ПТС]
, a.[Экран_фото_документов_авто_ПТС]

,  [Тип оффера подтверждение дохода]
, [Загрузил документ подтверждающий доход] 


, a.[Экран_способ_выдачи_ПТС]
, a.[Карта_привязана_ПТС]
, a.[Экран_фото_авто_ПТС]
, a.[Экран_отправлена_полная_заявка_ПТС]
, a.[Экран_одобрена_заявка_ПТС]
, a.[Экран_подписание_второго_пакета_ПТС]
, a.[Подписал_второй_пакет_ПТС]
, a.[Экран_анкета_Беззалог]
, a.[Экран_паспорт_Беззалог]
, a.[Первичная_сумма]
, a.[Уприд_Есть]
, a.[Ветка_Необходимость_Фото_Паспорта]
, a.[Загрузил_штук_фото_паспорта]
, a.[Экран_загрузка_фото_Беззалог]
, a.[Экран_подпписание_первого_пакета_Беззалог]
, a.[Экран_получение_предв_одобрение_Беззалог]
, a.[Экран_о_работе_и_доходе_Беззалог]
, a.[Экран_способ_выдачи_Беззалог]
, a.[Экран_ожидание_одобрения_Беззалог]
, a.[Экран_выбор_предложения_Беззалог]
, a.[Экран_подписание_договора_Беззалог]
, a.[reportDate]
, a.[phone]
, a.[decline]

, b.visit    , c.лидов, c.заявок
, c.[выдано руб]
, c.[заем выдан]
, c.ar
, c.[расходы руб]
, type
, productType2
from ##infoseti_detail a
full outer join #visit b on 1=0
full outer join (

select 'infoseti-deepapi-pts' source,  '20241201' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
select 'infoseti-deepapi-pts' source,  '20250101' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
select 'infoseti-deepapi-pts' source,  '20250201' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
select 'infoseti-deepapi-pts' source,  '20250301' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
select 'infoseti-deepapi-pts' source,  '20250401' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
select 'infoseti-deepapi-pts' source,  '20250501' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20250601' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20250701' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20250801' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20250901' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20251001' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20251101' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'infoseti-deepapi-pts' source,  '20251201' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] -- union all


) c on 1=0
)

select 

date, 
cast(format(a.date, 'yyyy-MM-01') as date) month, 
 [Лид]= count(distinct a.id)  
,type= isnull( type, 'факт')
,[ЛидПлан]= sum(лидов)  
,[Принятный лид (заявка)]= count(distinct case when isAccepted=1 then a.id end) 
,[Переход по ссылке (клик)]= ( isnull( sum(a.visit) , 0) + count(IsClickThrough))
, [% лид одобрен - клик] =   ( isnull( sum(a.visit) , 0) + count(IsClickThrough)) / nullif( ( count(distinct case when isAccepted=1 then a.id end)  +0.0 ), 0) 
, [% Клик - Загрузил паспорт(Call1) ПТС] =    nullif( (count(distinct case when call1  is not null and a.productType2 ='PTS' then a.guid end)   +0.0 ), 0)/ nullif(   (  isnull( max(a.visit), 0) + count(IsClickThrough)), 0)
,[Загружено фото паспорта ПТС]= count(distinct case when call1  is not null and  a.productType2 ='PTS'  then a.guid end) 
,[Загружено фото паспорта ПТС план]= sum(заявок)  

,[Предварительное одобрение ПТС]= count(distinct case when call1approved  is not null and  a.productType2 ='PTS'  then a.guid end)  
,[Загружены фото авто и документов на авто]= count(distinct case when (_fullRequestPTS  is not null or a.approved is not null)  and  a.productType2 ='PTS'  then a.guid end)  
,[Заявка отказ ПТС]= count(distinct case when declined  is not null and  a.productType2 ='PTS'  then a.guid end)  
,[Заявка одобрена ПТС]= count(distinct case when approved  is not null and  a.productType2 ='PTS'  then a.guid end)  
,[Количество займов ПТС]= count(distinct case when issued  is not null and  a.productType2 ='PTS'  then a.guid end)  
,[Количество займов ПТС план]= sum([заем выдан])  
,[arPlan]= sum(ar)  

,[Сумма займов ПТС]= isnull( sum( case when issued  is not null and  a.productType2 ='PTS'  then a.issuedSum end)  , 0.0)
,[Сумма займов ПТС план]= sum([выдано руб])  
-- Изменение комм вознаграждения птс с сентября 
,[Вознаграждение ПТС]= isnull( sum( case when issued  is not null and  a.productType2 ='PTS'  then a.issuedSum end)  * case when a.date >= '2025-09-01' then 0.09 else 0.08 end, 0.0)
,[Вознаграждение ПТС план]= sum([расходы руб])  
,[Загружено фото паспорта(Call1) беззалог]= count(distinct case when call1  is not null and  a.productType2 ='BEZZALOG'  then a.guid end) 
,[Заявка отказ беззалог]= count(distinct case when declined  is not null and  a.productType2 ='BEZZALOG'  then a.guid end)  

,[Заявка одобрена беззалог]= count(distinct case when approved  is not null and  a.productType2 ='BEZZALOG'  then a.guid end)  
,[Количество займов беззалог]= count(distinct case when issued  is not null and  a.productType2 ='BEZZALOG'  then a.guid end)  
,[Сумма займов беззалог]=  isnull(sum( case when issued  is not null and  a.productType2 ='BEZZALOG'  then a.issuedSum end)  , 0.0)
,[Вознаграждение беззалог]= count( case when issued  is not null and  a.productType2 ='BEZZALOG'  then a.issuedSum end)  *1500

,[Загружено фото паспорта(Call1) БИ]= count(distinct case when call1     is not null and  a.productType2 ='BIG INST'  then a.guid end) 
,[Заявка отказ БИ]                  = count(distinct case when declined  is not null and  a.productType2 ='BIG INST'  then a.guid end)  
,[Заявка одобрена БИ]               = count(distinct case when approved  is not null and  a.productType2 ='BIG INST'  then a.guid end)  
,[Количество займов БИ]             = count(distinct case when issued    is not null and  a.productType2 ='BIG INST'  then a.guid end)  
,[Сумма займов БИ]                  = isnull(sum( case when issued       is not null and  a.productType2 ='BIG INST'  then a.issuedSum end)  , 0.0)
,[Вознаграждение БИ]                = sum( case when issued              is not null and  a.productType2 ='BIG INST'  then a.issuedSum end)  *0.04





,[Суммарное вознаграждение]= isnull( count( case when issued  is not null and  a.productType2 ='BEZZALOG'  then a.issuedSum end), 0.0)  *1500 + isnull(sum( case when issued  is not null and  a.productType2 ='PTS'  then a.issuedSum end)  *0.08 , 0.0)
+ isnull( sum( case when issued              is not null and  a.productType2 ='BIG INST'  then a.issuedSum end)  *0.04, 0)
, b.rr_pts runRate
, b.month  reportMonth
, case when cast(format(date, 'yyyy-MM-01') as date) = b.month then 1 end isReportMonth
, case when  date >=getdate()-31   then 1 end isLast30day
,  a.productTypeExternal
, source

into ##infoseti_report
from v a
left join v_rr b on 1=1
 
group by date, a.type
, b.rr_pts
 , b.month 
 , a.productTypeExternal
 , source

--select * from ##infoseti_report
--


drop table if exists dbo.marketing_infoseti_detail 
select * into dbo.marketing_infoseti_detail  from  ##infoseti_detail 
where reportDate>=getdate()-60
--delete from dbo.marketing_infoseti_detail 
--insert into dbo.marketing_infoseti_detail 
--select * from ##infoseti_detail 


drop table if exists dbo.marketing_infoseti_report
select * into dbo.marketing_infoseti_report from  ##infoseti_report
--delete from dbo.marketing_infoseti_report
--insert into dbo.marketing_infoseti_report
--select * from ##infoseti_report 



--exec python 'sql2gs("select * from marketing_infoseti_report    order by 1", "1K538rWVzQpkj2G-jvuM_VkYeOPGhQCvbKR9rqFJeJOw", sheet_name="report" , make_sheet=False , fillna = True)', 1



--exec python 'sql2gs("select * from marketing_infoseti_detail   order by 1", "1K538rWVzQpkj2G-jvuM_VkYeOPGhQCvbKR9rqFJeJOw", sheet_name="details" , make_sheet=False , fillna = True)', 1


end








if @mode =  'biginst'

begin




select 
  reportDate
, reportWeek
, reportMonth
, case when rn_lead=1 then  source end source
, [Признак большой инстоллмент]
, case when [Признак большой инстоллмент]  =1 and rn_lead=1 then id end id
, case when [Признак большой инстоллмент] = 1 and rn_lead=1  then case when  isnull(decline, '')  <> 'Отказ PreCall1' then 1 end  end [Одобрен лид]
, case when [Признак большой инстоллмент] = 1 and rn_lead=1  then case when linkUrlInfoseti is not null then 1 end end [Отправлена ссылка]
, case when [Признак большой инстоллмент]  =1   then decline end [Причина отказа по лиду]
, case when productType2  ='BIG INST' then number end [идентификатор заявки]
, case when productType2  ='BIG INST' then Экран_подпписание_первого_пакета_БИ end [подписание 1 пакета]
, case when productType2  ='BIG INST' then Call1 end [подписан 1 пакет]
, case when productType2  ='BIG INST' then cast(Call1Approved as date) end [Call1 одобрено]
, case when productType2  ='BIG INST' then datediff(second, Call1, Call1Approved) end tty
, case when productType2  ='BIG INST' then  cast([Загрузил документы] as date)  end [Загрузили документы]
, case when productType2  ='BIG INST' then  [SLA проверки]  end [SLA проверки]
, case when productType2  ='BIG INST' then  [call15 одобрено] end [call15 одобрено]

, case when productType2  ='BIG INST' then  Call2 end call2
, case when productType2  ='BIG INST' then  [Call2 одобрено] end [Call2 одобрено]
, case when productType2  ='BIG INST' then  Экран_калькулятор_БИ end [Экран калькулятор БИ]
, case when productType2  ='BIG INST' then  Экран_способ_выдачи_БИ end [Экран способ выдачи БИ]
, case when productType2  ='BIG INST' then  Одобрен end Одобрен
, case when productType2  ='BIG INST' then  [Подписал 2 пакет БИ] end [Подписал 2 пакет БИ]
, case when productType2  ='BIG INST' then  [Экран с таймером БИ] end [Экран с таймером БИ]
, case when productType2  ='BIG INST' then  [Экран с таймером выход БИ] end [Экран с таймером выход БИ]
, case when productType2  ='BIG INST' then  Issued end [Дата выдачи кредита]
, case when productType2  ='BIG INST' then  IssuedSum end [сумма выданного кредита]
, case when productType2  ='BIG INST' and Issued is not null then  [срок выданного кредита месяцы] end [срок выданного кредита месяцы]
, case when productType2  ='BIG INST' and Issued is not null then  [Процентная ставка] end [Процентная ставка]
, case when productType2  ='BIG INST' and Issued is not null then  [Запрошенная сумма в банке] end [Запрошенная сумма в банке]
, case when productType2  ='BIG INST' and Issued is not null then  [Сумма без подтв. дохода] end [Сумма без подтв. дохода]
, case when productType2  ='BIG INST' and Issued is not null then  [Сумма с подтв. дохода] end [Сумма с подтв. дохода]
, case when productType2  ='BIG INST' and Issued is not null then  [признак страхования] end [признак страхования]
, case when productType2  ='BIG INST' then  ИстекСрокДействия end [Истек срок действия]

 

from 
(
select *, row_number() over(partition by id order by case when productType2  ='BIG INST' then 1 end desc ) rn_lead 
, case when productTypeExternal<> 'Автокредит Инфосети' then 1 else 0 end as [Признак большой инстоллмент]

from
marketing_infoseti_detail
where source =  'infoseti-deepapi-pts'
) a
 
 where created>='20251201' --and   ([Продукт заявки]  ='BIG INST' or [Продукт заявки] is null)
order by created desc






end