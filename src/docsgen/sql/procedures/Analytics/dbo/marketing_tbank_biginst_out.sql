
 create   proc [dbo].[marketing_tbank_biginst_out] @mode nvarchar(max) = 'update'
as

if @mode =  'update'

begin

drop table if exists ##marketing_tbank_biginst_out_detail
 

SELECT 
     a.created  AS created,
    a.id AS id,
	 isnull(b.source,  a.source  ) source ,
	isnull( b.productTypeExternal ,  a.productTypeExternal) productTypeExternal ,
    a.isAccepted AS IsAccepted,
	case when a.source like 'infoseti%' then a.linkUrl end linkUrlInfoseti,
    a.isClickThrough AS IsClickThrough,
   isnull(  b.number, b.guid) AS number,
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
--reportDate = cast(isnull(isnull(b.issued, b.call1), a.created) as date) 
reportDate =  cast(isnull(isnull( b.call1, b.created), a.created) as date)
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
	, b.checkingRefinement
	, offerProofOfIncomeType
	, b.limitChoise 
	, b.call15
	, case when declined is not null  then declineReason end declineReason
	, case when declined >= call15approved     then declined end declinedAfterCall15Approved
	, case when  declinereason like '%финце%'  then declined end declinedFinCert
	, checkingRefinementSLA as checkingRefinementSLA
	, b.incomeRecommended
	, b.[incomeVerified] [incomeVerified]
	--,
	--isnull(  b.[isDubl] , a.isdubl) isdubl 
 
	INTO ##marketing_tbank_biginst_out_detail
FROM _lead_request a
LEFT JOIN  request b ON a.requestGuid = b.guid 
left join v_request_external c on c.id=a.id

left join calendar_view cv on cv.date =  cast(isnull(isnull( b.call1, b.created), a.created) as date) 

WHERE   b.productsubtype in (  'Big Installment Рыночный'  , 'Big Installment Рыночный - Самозанятый')   
 
AND  cast(isnull(isnull( b.call1, b.created), a.created) as date)   between '20260101' and cast( getdate() +1  as date)  
and isnull(b.isDubl, -2) <>-1
and (isnull(b.source, a.source)  like 'tpokupki%' or
  isnull(b.channel, a.channel)  = 'Т-Банк' )
 and isnull( isnull(  b.[isDubl] , a.isdubl) , 0)=0

  
drop table if exists dbo.marketing_tbank_biginst_out_detail 
select * into dbo.marketing_tbank_biginst_out_detail  from  ##marketing_tbank_biginst_out_detail
  
end








if @mode =  'biginst'

begin




select 
  reportDate
, reportWeek
, reportMonth
,  source
--, [Признак большой инстоллмент]
--, case when [Признак большой инстоллмент]  =1 and rn_lead=1 then case when reportdate >=getdate()-5 then id else '*' end end id
--, case when [Признак большой инстоллмент] = 1 and rn_lead=1  then case when  isnull(decline, '')  <> 'Отказ PreCall1' then 1 end  end [Одобрен лид]
--, case when [Признак большой инстоллмент] = 1 and rn_lead=1  then case when linkUrlInfoseti is not null then 1 end end [Отправлена ссылка]
--, case when [Признак большой инстоллмент]  =1   then decline end [Причина отказа по лиду]
, case when productType2  ='BIG INST' then case when reportdate >=getdate()-5 or approved is not null then number else '*' end end [идентификатор заявки]
, case when productType2  ='BIG INST' then cast(Экран_подпписание_первого_пакета_БИ as date) end [подписание 1 пакета]
, case when productType2  ='BIG INST' then cast(Call1 as date) end [подписан 1 пакет]
, case when productType2  ='BIG INST' then cast(Call1Approved as date) end [Call1 одобрено]
, case when productType2  ='BIG INST' then datediff(second, Call1, Call1Approved) end tty
, case when productType2  ='BIG INST' then  cast([Загрузил документы] as date)  end [Загрузили документы]
, case when productType2  ='BIG INST' then  [SLA проверки]  end [SLA проверки]
, case when productType2  ='BIG INST' and [Загрузил документы] is not null  then  isnull( [call15 одобрено], declined) end [Получено решение на проверках]
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
, case when cw.lastNday   <= 12 then 1 else 0 end   isLastNday
, case when cw.lastNweek  <= 12 then 1 else 0 end   isLastNweek
, case when cw.lastNmonth <= 12 then 1 else 0 end   isLastNmonth

, case when productType2  ='BIG INST' then  A.limitChoise            end [Выбранное предложение]
, case when productType2  ='BIG INST' then  A.offerProofOfIncomeType end [Доступные предложения]
, case when productType2  ='BIG INST' then  A.incomeRecommended      end [Рекомендуемый доход]
, case when productType2  ='BIG INST' then  A.[incomeVerified]       end [Подтвержденный доход]
, case when productType2  ='BIG INST' then  A.declinedFinCert       end [Отказ Финцерт]
, case when productType2  ='BIG INST' then  A.declineReason       end [Причина отказа]
, case when productType2  ='BIG INST' then  A.checkingRefinementSLA       end [SLA на доработках]
, case when productType2  ='BIG INST' then  A.checkingRefinement       end [Кол-во доработок]
, case when productType2  ='BIG INST' then  A.declinedAfterCall15Approved       end [Отказ после верификаторов]
, case when productType2  ='BIG INST' then   case when call15 is not null and [call15 одобрено] is null then call15 end end [Отказ у верификаторов]

 

 

from 
(
select *
--, row_number() over(partition by id order by case when productType2  ='BIG INST' then 1 end desc ) rn_lead 
--, case when productTypeExternal<> 'Автокредит Инфосети' or productType2  ='BIG INST' then 1 else 0 end as [Признак большой инстоллмент]

from
marketing_tbank_biginst_out_detail
--where source =  'infoseti-deepapi-pts'
) a
 left join calendar_view cw on cw.date=a.reportDate
 
 --where created>='20251201' --and   ([Продукт заявки]  ='BIG INST' or [Продукт заявки] is null)
order by created desc






end





 