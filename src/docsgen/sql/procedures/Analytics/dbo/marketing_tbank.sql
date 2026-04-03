
 CREATE   proc [dbo].[marketing_tbank]
as



--select * from _lead_request where source like 'tpokupki%'
--order by created desc





 select  a.created, a.sendingStatus, a.status, a.request_number, count(*) over(partition by a.request_number) cnt  into #pb from postback a
  where lead_leadgen_name = 'tpokupki-deepapi' and eventName='request.status.changed'
 
 


;with v as (select *, row_number() over(partition by request_number order by case when sendingStatus = 'sent' then 1 end desc ) rnDelete  from #pb)
delete from v where rnDelete>1

drop table if exists ##tbank_detail
 

SELECT 
     a.created  AS created,
    a.id AS id,
	 isnull(b.source,  a.source  ) source ,
	 
	isnull( b.productTypeExternal ,  a.productTypeExternal) productTypeExternal ,
	
    a.isAccepted AS IsAccepted,
	case when a.source like 'tpokupki%' then isnull(a.linkUrl, 'no link') end linkUrlTBank,
    a.isClickThrough AS IsClickThrough,
    b.number AS number,
	b.originaLentrypoint entrypoint  ,
 	b.origin ,
	b.productType ,
	b.productSubType ,
	e.applicantOwnerCar, 
    b.requiredPhotoCnt ,
 	b.returntype , 
    b.call1 AS Call1,
    b.declined AS declined,
    b.call1Approved AS Call1Approved,
    b._fullRequestPTS AS _fullRequestPTS,
    b.approved AS Approved,
    b.issued AS Issued,
    b.issuedSum AS IssuedSum  ,
	pb.created callbackCreated,
	pb.sendingStatus callbackStatus,
	pbm.[responseResult] manualCallbackStatus ,
	datediff(day, pbm.leadCreated,  b.issued) Дней_от_лида_ЮНИАПИ_до_выдачи,
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
firstSum Первичная_сумма,
[_upridYes] Уприд_Есть,
[abPhotoUprid] Ветка_Необходимость_Фото_Паспорта,
_photosCnt Загрузил_штук_фото_паспорта,
_photos                    Экран_загрузка_фото_Беззалог, 

_pack1                     Экран_подпписание_первого_пакета_Беззалог , 
_call1                     Экран_получение_предв_одобрение_Беззалог , 
_workAndIncome              Экран_о_работе_и_доходе_Беззалог , 
_cardLinked                  Экран_способ_выдачи_Беззалог , 
_approvalWaiting Экран_ожидание_одобрения_Беззалог , 
_offerSelection Экран_выбор_предложения_Беззалог , 
_contractSigning Экран_подписание_договора_Беззалог  ,
reportDate = isnull(isnull(b.issued, b.call1), a.created),
phone =  isnull(b.phone,  a.phone ) 
, 	b.isPts AS IsPts 
, a.decline


	--,
	--isnull(  b.[isDubl] , a.isdubl) isdubl 
 
	INTO ##tbank_detail
FROM _lead_request a
LEFT JOIN _request b ON a.requestGuid = b.guid 
left join v_request_external e on e.id = a.id
left join #pb pb on pb.request_number = b.number
left join marketing_tbank_postback_log pbm on pbm.number=b.number
WHERE (  isnull(b.source,  a.source  )  IN ('tpokupki-deepapi') 
--or b.number in (
--'24121522859603' ,
--'24121402855708')  

)
AND isnull(isnull(b.issued, b.call1), a.created)  between '2025-10-21 16:29:42' and cast( getdate() +1  as date)  
-- and isnull( isnull(  b.[isDubl] , a.isdubl) , 0)=0

 
 --select a.*, b.source from v_request_external a
 --left join v_lead2 b on a.id=b.id
 --where applicantOwnerCar is not null

 ----select * from ##tbank_detail
 --order by  1
 
 
drop table if exists #visit
select source,  cast( created  as date) date, count(distinct client_id) visit into #visit  from v_visit 
where source  IN ('tpokupki-deepapi')   and created between '2025-10-21 16:29:42' and cast( getdate()+1  as date) 
group by cast( created  as date) , source

drop table if exists ##tbank_report

 

;
with v as (
select isnull(isnull( cast( a.reportDate  as date) , b.date ), c.date ) date, a.[created]
, a.[id]
, isnull(isnull(a.[source] , b.source), c.source) source
, a.[productTypeExternal]
, a.[IsAccepted]
, a.[linkUrlTBank]
, a.[IsClickThrough]
, a.[number]
, a.productType
, a.productSubType
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

,  [Тип оффера подтверждение дохода], [Загрузил документ подтверждающий доход] 


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
from ##tbank_detail a
full outer join #visit b on 1=0
full outer join (

--select 'tpokupki-deepapi' source,  '20241201' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
--select 'tpokupki-deepapi' source,  '20250101' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
--select 'tpokupki-deepapi' source,  '20250201' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
--select 'tpokupki-deepapi' source,  '20250301' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
--select 'tpokupki-deepapi' source,  '20250401' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб]  union all
--select 'tpokupki-deepapi' source,  '20250501' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
--select 'tpokupki-deepapi' source,  '20250601' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
--select 'tpokupki-deepapi' source,  '20250701' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
--select 'tpokupki-deepapi' source,  '20250801' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
--select 'tpokupki-deepapi' source,  '20250901' date,'план' type, 12000 лидов,1200 заявок, 330 [заем выдан], ar = 0.51, 173440394 [выдано руб] , 13875232 [расходы руб] union all
select 'tpokupki-deepapi' source,  '20251001' date,'план' type, cast( null as int) лидов, 1009.4290  заявок,  461.82781  [заем выдан], ar =cast( null as int), 244768741.5533  [выдано руб] , 5317422 [расходы руб] union all
select 'tpokupki-deepapi' source,  '20251101' date,'план' type, cast( null as int) лидов, 1135.6076  заявок,  461.82781  [заем выдан], ar =cast( null as int), 244768741.5533  [выдано руб] , 5254357 [расходы руб] union all
select 'tpokupki-deepapi' source,  '20251201' date,'план' type, cast( null as int) лидов, 1465.0740  заявок,  487.48492  [заем выдан], ar =cast( null as int), 258367004.9729  [выдано руб] , 5592868 [расходы руб] -- union all


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
, [% Клик - Загрузил паспорт(Call1) ПТС] =    nullif( (count(distinct case when call1  is not null and a.isPts =1 then a.guid end)   +0.0 ), 0)/ nullif(   (  isnull( max(a.visit), 0) + count(IsClickThrough)), 0)
,[Загружено фото паспорта ПТС]= count(distinct case when call1  is not null and a.isPts =1 then a.guid end) 
,[Загружено фото паспорта ПТС план]= sum(заявок)  

,[Предварительное одобрение ПТС]= count(distinct case when call1approved  is not null and a.isPts =1 then a.guid end)  
,[Загружены фото авто и документов на авто]= count(distinct case when (_fullRequestPTS  is not null or a.approved is not null)  and a.isPts =1 then a.guid end)  
,[Заявка отказ ПТС]= count(distinct case when declined  is not null and a.isPts =1 then a.guid end)  
,[Заявка одобрена ПТС]= count(distinct case when approved  is not null and a.isPts =1 then a.guid end)  
,[Количество займов ПТС]= count(distinct case when issued  is not null and a.isPts =1 then a.guid end)  
,[Количество займов ПТС план]= sum([заем выдан])  
,[arPlan]= sum(ar)  

,[Сумма займов ПТС]= isnull( sum( case when issued  is not null and a.isPts =1 then a.issuedSum end)  , 0.0)
,[Сумма займов ПТС план]= sum([выдано руб])  
-- Изменение комм вознаграждения птс с сентября 
,[Вознаграждение ПТС]= isnull( sum( case when issued  is not null and a.isPts =1 then a.issuedSum end)  * case when a.date >= '2025-09-01' then 0.03 else 0.08 end, 0.0)
,[Вознаграждение ПТС план]= sum([расходы руб])  
,[Загружено фото паспорта(Call1) беззалог]= count(distinct case when call1  is not null and a.isPts =0 then a.guid end) 
,[Заявка отказ беззалог]= count(distinct case when declined  is not null and a.isPts =0 then a.guid end)  

,[Заявка одобрена беззалог]= count(distinct case when approved  is not null and a.isPts =0 then a.guid end)  
,[Количество займов беззалог]= count(distinct case when issued  is not null and a.isPts =0 then a.guid end)  
,[Сумма займов беззалог]=  isnull(sum( case when issued  is not null and a.isPts =0 then a.issuedSum end)  , 0.0)
,[Вознаграждение беззалог]= count( case when issued  is not null and a.isPts =0 then a.issuedSum end)  *1500
,[Суммарное вознаграждение]= isnull( count( case when issued  is not null and a.isPts =0 then a.issuedSum end), 0.0)  *1500 + isnull(sum( case when issued  is not null and a.isPts =1 then a.issuedSum end)  *0.03 , 0.0)
, b.rr_pts runRate
, b.month  reportMonth
, case when cast(format(date, 'yyyy-MM-01') as date) = b.month then 1 end isReportMonth
, case when  date >=getdate()-31   then 1 end isLast30day
,  a.productTypeExternal
, source

into ##tbank_report
from v a
left join v_rr b on 1=1
 
group by date, a.type
, b.rr_pts
 , b.month 
 , a.productTypeExternal
 , source

--select * from ##tbank_report
--


drop table if exists dbo.marketing_tbank_detail 
select * into dbo.marketing_tbank_detail  from  ##tbank_detail 
where reportDate>=getdate()-60
--delete from dbo.marketing_tbank_detail 
--insert into dbo.marketing_tbank_detail 
--select * from ##tbank_detail 


drop table if exists dbo.marketing_tbank_report
select * into dbo.marketing_tbank_report from  ##tbank_report
--delete from dbo.marketing_tbank_report
--insert into dbo.marketing_tbank_report
--select * from ##tbank_report 




