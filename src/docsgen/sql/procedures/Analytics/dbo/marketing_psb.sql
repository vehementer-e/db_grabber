 CREATE   proc [dbo].[marketing_psb] @mode nvarchar(max)  = 'update'
as


if @mode='out_balance'
begin
select * from marketing_psb_balance
order by 2, 1
end




if @mode = 'update'

begin


drop table if exists ##psb_detail

   

SELECT 
  
    a.id AS id,
	 isnull(b.source,  a.source  ) source ,
    a.isAccepted AS IsAccepted,
    a.isClickThrough AS IsClickThrough,
    b.number AS number,
    b.isPts AS IsPts,
	b.origin,
	b.returntype , 
    --b.call1 AS Call1,
   cast( b.declined   as date)    AS declined,
    b.call1Approved AS Call1Approved,
   cast(   b._fullRequestPTS  as date)  AS _fullRequestPTS,
   --cast(  b.issued    as date)  AS Issued,
    --b.issuedSum AS IssuedSum  ,
    b.guid AS guid,
cast( _profilePts            as date)     Экран_Анкета_ПТС  , 
cast( _docPhotoPts			 as date)     Экран_фото_паспорта_ПТС  , 
cast( _docPhotoLoadedPts	 as date) 	  Загрузил_фото_паспорта_ПТС  , 
cast( _pack1Pts				 as date)     Экран_подписание_первого_пакета_ПТС  , 
cast( _pack1SignedPts		 as date) 	  Подписал_первый_пакет_ПТС  , 
cast( _clientAndDocPhoto2Pts as date) 	  Экран_загрузка_фото_паспорта_и_клиента_ПТС , 
cast( _additionalInfoPTS	 as date) 	  Экран_доп_информация_ПТС , 
cast( _carDocPhotoPTS		 as date) 	  Экран_фото_документов_авто_ПТС , 
cast( _payMethodPts			 as date)     Экран_способ_выдачи_ПТС , 
cast( _cardLinkedPTS		 as date) 	  Карта_привязана_ПТС , 
cast( _carPhotoPTS			 as date)     Экран_фото_авто_ПТС , 
cast( _fullRequestPTS		 as date) 	  Экран_отправлена_полная_заявка_ПТС , 
cast( _approvalPTS			 as date)     Экран_одобрена_заявка_ПТС , 
cast( _pack2PTS				 as date)     Экран_подписание_второго_пакета_ПТС , 
cast( _pack2SignedPTS		 as date) 	  Подписал_второй_пакет_ПТС,
cast( _profile               as date)     Экран_анкета_Беззалог, 
cast( _passport              as date)     Экран_паспорт_Беззалог,   
cast([_upridYes]  as date) Уприд_Есть,
[abPhotoUprid] Ветка_Необходимость_Фото_Паспорта,
_photosCnt Загрузил_штук_фото_паспорта,
cast( _photos               as date)     Экран_загрузка_фото_Беззалог, 
cast( _pack1                as date)     Экран_подпписание_первого_пакета_Беззалог , 
cast( _call1                as date)     Экран_получение_предв_одобрение_Беззалог , 
cast( _workAndIncome        as date)      Экран_о_работе_и_доходе_Беззалог , 
cast( _cardLinked           as date)       Экран_способ_выдачи_Беззалог , 
cast( _approvalWaiting      as date)        Экран_ожидание_одобрения_Беззалог , 
cast( _offerSelection       as date)        Экран_выбор_предложения_Беззалог , 
cast( _contractSigning      as date)        Экран_подписание_договора_Беззалог  ,
firstSum                    Первичная_сумма,
reportDate = cast( isnull(isnull(b.issued, b.call1), a.created) as date)
, cv.week reportWeek
, cv.month reportMonth
,	isnull( b.productTypeExternal ,  a.productTypeExternal) productTypeExternal 
,  case when c.isBigInstallment =1 then 1 else 0 end [Признак большой инстоллмент]
,  c.sum [Запрошенная сумма в банке] 
,  c.term termExternal 
,  c.termDay termDayExternal 
 
    ,[идентификатор заявки ПСБ] =  d.requestId --json_value( d.payload, '$[0].requestId')-- [Идентификатор клиента ПСБ (requestId)]
	,[идентификатор клиента ПСБ] = d.appId -- json_value( d.payload, '$[0].appId') -- d.[Идентификатор клиента ПСБ (appId)]
	
	,[дата заявки  (лид)] = a.created
	,[дата заявки  (черновик)] = b.created
	,[дата заявки  (Call1)] = b.call1
	, b.productType [Продукт заявки]
	,[статус заявки] = case 
	when b.declined is not null then 'отказано'
	when b.issued is not null then 'выдан'
	when b.approved is not null then 'одобрен'
	when b.cancelled is not null then 'аннулирован'
	when b.Call1 is not null then 'в работе'
	when b.created is not null then 'черновик'
	end
	,[причина отказа] = case when b.declined is not null then dr.[Classification level 1]  /* b.declineReason */ end
	,[дата принятия предварительного решения] = cast( isnull(call1approved,declined) as date)
	,[дата принятия финального решения] = cast( isnull(approved,declined) as date)
	,[одобренная максимальная сумма кредита] = approvedSum
	,[одобренный продукт] =  case when b.approved  is not null then b.productType end  
	,[одобренный срок] =  case when b.approved  is not null then b.term end  
	,[одобренная ставка] =  case when b.approved  is not null then b.interestRateRecommended end  
	,[признак страхования] =  case when b.approved  is not null then b.isAddProductInsurRequest end  
	,[идентификатор заявки] = number
	,[идентификатор кредита] =  case when issued  is not null then number end  
	,[выданный продукт] = case when issued  is not null then productNameCrm end 
	
	,[сумма выданного кредита] = b.issuedSum
	,[срок выданного кредита месяцы] = case when issued  is not null then b.term end 
	,[срок выданного кредита дни (PDL)]  = case when issued  is not null then b.termDays end 
	,[ПСК выданного кредита] = b.pskRate
	,[Дата выдачи кредита] = cast( b.issued as date)
	,[дата планового окончания кредита] = b.InitialEndDate
	,[дата фактического окончания кредита] = cast(  b.closed as date) 
   , cast( b.checking   as date)    AS [Загрузил документы]
   , cast( isnull(b.call15approved , b.call2)  as date)    AS [call15 одобрено]
   , checkingSla + isnull(verificationSla, 0) [SLA проверки]
   , checkingSlaNet + isnull(verificationSlaNet, 0) [SLA проверки net]
   , cast( b.[Call2]   as date)    AS [Call2]
   , cast( b.[call2Approved]   as date)    AS [Call2 одобрено]
   , cast( b._calculatorBI   as date)    AS [Экран калькулятор БИ]
   , cast( b._payMetodBI   as date)    AS [Экран способ выдачи БИ]
   , cast( b.call5   as date)    AS call5
   , cast(  b.approved  as date)  AS [Одобрен]
   , cast( b._timerBI   as date)    AS [Экран с таймером БИ]
   , cast( b._timerOutBI   as date)    AS [Экран с таймером выход БИ]
   , cast( b._pack2SignedBI   as date)    AS [Подписал 2 пакет БИ]
   , b.[sumProofOfIncome] [Сумма с подтв. дохода]
   , b.[sumNoProofOfIncome] [Сумма без подтв. дохода]
   , b.interestRate [Процентная ставка]
   , b.addProductSumNet [Страховка net]
   , a.decline
   , b.limitChoise
   , b.requiredPhotoCnt
   , c.regionRegistration
   , c.partnerApplicationChannel
   , isnull(b.[callbackPsbCall1Approved], b.call1approved)  [callbackPsbCall1Approved]
   , b.payMethod
   , b.paySbpBank
   , b.status_crm
	--,
	--isnull(  b.[isDubl] , a.isdubl) isdubl 
 
	INTO ##psb_detail
FROM _lead_request a
LEFT JOIN  request b ON a.requestGuid = b.guid 
left join v_request_external c on c.id = a.id
left join (select d.externalRequestId 
,cast('' as nvarchar(max)) requestId-- STRING_AGG(json_value( d.payload, '$[0].requestId') , ',') requestId
--, STRING_AGG(json_value( d.payload, '$[0].appId') , ',') appId
, max(json_value( d.payload, '$[0].appId')  ) appId
from

stg._lf.v1_core_external_request_partner_params_to_return_permanent d 
group by d.externalRequestId ) d

on d.externalRequestId=c.request_id
left join dwh2.risk.v_refusereasons dr on dr.Номер=b.number
left join calendar_view cv on cv.date = cast( isnull(isnull(b.issued, b.call1), a.created) as date)
WHERE (  isnull(b.source,  a.source  )  IN ('psb-deepapi', 'psb-deepapi-pts') 
--or b.number in (
--'24121522859603' ,
--'24121402855708')  

)
AND isnull(isnull(b.issued, b.call1), a.created)  between '20250528' and cast( getdate() +1  as date)  
AND isnull(a.channel, '')<>'Тест'

-- and isnull( isnull(  b.[isDubl] , a.isdubl) , 0)=0

 
 
 --select * from ##psb_detail
 order by  1
 
-- alter table Analytics.dbo._request alter column productTypeExternal varchar(255)
-- alter table Analytics.dbo._request_log alter column productTypeExternal varchar(255)
 
drop table if exists #visit
select cast( created  as date) date, count(distinct client_id) visit into #visit  from v_visit 
where source  IN ('psb-deepapi', 'psb-deepapi-pts')   and created between '20241213' and cast( getdate()+1  as date) 
group by cast( created  as date) 

drop table if exists ##psb_report
 

;
with v as (
select isnull(isnull( cast( a.reportDate  as date) , b.date ), c.date ) date,  a.* , b.visit    
, c.лидов
, c.ar
, c.заявок
, c.[выдано руб]
, c.[заем выдан]
, c.[расходы руб]
, c.заявок_беззалог
, c.[выдано руб_беззалог]
, c.[заем выдан_беззалог]
, c.[расходы руб_беззалог]
, type
from ##psb_detail a
full outer join #visit b on 1=0
full outer join (

--select '20250501' date,'план' type, 31362 лидов,408 заявок, 47 [заем выдан], ar = 0, 18789730 [выдано руб] ,185080	 [расходы руб],1573 заявок_беззалог, 37 [заем выдан_беззалог] ,1087890    [выдано руб_беззалог]    ,53993    [расходы руб_беззалог]   union all
select '20250601' date,'план' type, 30827 лидов,401 заявок, 81 [заем выдан], ar = 0,  32102540 [выдано руб]  , 273570   	 [расходы руб]  ,6991   заявок_беззалог, 353   [заем выдан_беззалог]  ,10360146    [выдано руб_беззалог]      ,503367   [расходы руб_беззалог]   union all
select '20250701' date,'план' type, 24967 лидов,905 заявок, 199 [заем выдан], ar = 0, 78489189 [выдано руб]  , 651594   [расходы руб]  ,10672  заявок_беззалог, 579   [заем выдан_беззалог]       ,17006757	 [выдано руб_беззалог]        ,815874   [расходы руб_беззалог]   union all
select '20250801' date,'план' type, 23939 лидов,808 заявок, 178 [заем выдан], ar = 0, 69775392 [выдано руб]  , 552441   [расходы руб]  ,9591  заявок_беззалог,  541   [заем выдан_беззалог]       ,15849145     [выдано руб_беззалог]     ,732923   [расходы руб_беззалог]   union all
select '20250901' date,'план' type, 24378 лидов,731 заявок, 161 [заем выдан], ar = 0, 62625067 [выдано руб]  , 476818   	 [расходы руб]  ,8744  заявок_беззалог,  511   [заем выдан_беззалог]  ,14940212     [выдано руб_беззалог]     ,667956   [расходы руб_беззалог]   union all
select '20251001' date,'план' type, 25528 лидов,766 заявок, 168 [заем выдан], ar = 0, 64903205 [выдано руб]  , 593281   	 [расходы руб]  ,9195  заявок_беззалог,  549   [заем выдан_беззалог]  ,16005587     [выдано руб_беззалог]     ,702270   [расходы руб_беззалог]   union all
select '20251101' date,'план' type, 21017 лидов,631 заявок, 139 [заем выдан], ar = 0, 53240986 [выдано руб]  , 459997   	 [расходы руб]  ,7652  заявок_беззалог,  482   [заем выдан_беззалог]  ,13995739     [выдано руб_беззалог]     ,584029   [расходы руб_беззалог]   union all
select '20251201' date,'план' type, 25204 лидов,756 заявок, 166 [заем выдан], ar = 0, 64114401 [выдано руб]  , 551101      [расходы руб] ,9147  заявок_беззалог, 567   [заем выдан_беззалог]     ,  16494456     [выдано руб_беззалог]    ,698305   [расходы руб_беззалог]   -- union all









) c on 1=0
)

select 

date, cast(format(date, 'yyyy-MM-01') as date) month , 
 [Лид]= count(distinct a.id)  
,type= isnull( type, 'факт')
,[ЛидПлан]= sum(лидов)  
,[Принятный лид (заявка)]= count(distinct case when isAccepted=1 then a.id end) 
,[Переход по ссылке (клик)]= ( isnull( sum(a.visit) , 0) + count(IsClickThrough))
, [% лид одобрен - клик] =   ( isnull( sum(a.visit) , 0) + count(IsClickThrough)) / nullif( ( count(distinct case when isAccepted=1 then a.id end)  +0.0 ), 0) 
, [% Клик - Загрузил паспорт(Call1) ПТС] =    nullif( (count(distinct case when [дата заявки  (Call1)]  is not null and a.isPts =1 then a.guid end)   +0.0 ), 0)/ nullif(   (  isnull( max(a.visit), 0) + count(IsClickThrough)), 0)
,[Черновик ПТС]= count(distinct case when guid  is not null and a.isPts =1 then a.guid end) 
,[Загружено фото паспорта ПТС]= count(distinct case when [дата заявки  (Call1)]  is not null and a.isPts =1 then a.guid end) 
,[Загружено фото паспорта ПТС план]= sum(заявок)  

,[Предварительное одобрение ПТС]= count(distinct case when call1approved  is not null and a.isPts =1 then a.guid end)  
,[Загружены фото авто и документов на авто]= count(distinct case when (_fullRequestPTS  is not null or a.Одобрен is not null)  and a.isPts =1 then a.guid end)  
,[Заявка отказ ПТС]= count(distinct case when declined  is not null and a.isPts =1 then a.guid end)  
,[Заявка одобрена ПТС]= count(distinct case when Одобрен  is not null and a.isPts =1 then a.guid end)  
,[Количество займов ПТС]= count(distinct case when [Дата выдачи кредита]  is not null and a.isPts =1 then a.guid end)  
,[Количество займов ПТС план]= sum([заем выдан])  
,[arPlan]= sum(ar)  

,[Сумма займов ПТС]= isnull( sum( case when [Дата выдачи кредита]  is not null and a.isPts =1 then a.[сумма выданного кредита] end)  , 0.0)
,[Сумма займов ПТС план]= sum([выдано руб])  
,[Вознаграждение ПТС]=   count( case when [Дата выдачи кредита]  is not null and a.isPts =1 and a.returnType='Первичный' then a.[сумма выданного кредита] end)  *4000.0 
,[Вознаграждение ПТС план]= sum([расходы руб])  
,[Черновик беззалог]= count(distinct case when guid  is not null and a.isPts =0 then a.guid end) 

,[Загружено фото паспорта(Call1) беззалог]= count(distinct case when [дата заявки  (Call1)]  is not null and a.isPts =0 then a.guid end) 
,[Загружено фото паспорта(Call1) беззалог план]=  sum(заявок_беззалог)
,[Заявка отказ беззалог]= count(distinct case when declined  is not null and a.isPts =0 then a.guid end)  

,[Заявка одобрена беззалог]= count(distinct case when Одобрен  is not null and a.isPts =0 then a.guid end)  
,[Количество займов беззалог]= count(distinct case when [Дата выдачи кредита]  is not null and a.isPts =0 then a.guid end)  
,[Количество займов беззалог план]= sum([заем выдан_беззалог])
,[Сумма займов беззалог]=  isnull(sum( case when [Дата выдачи кредита]  is not null and a.isPts =0 then a.[сумма выданного кредита] end)  , 0.0)
,[Сумма займов беззалог план]=   sum([выдано руб_беззалог])
,[Вознаграждение беззалог]= ( count( case when [Дата выдачи кредита]  is not null and a.isPts =0 and a.returnType='Первичный' then a.[сумма выданного кредита] end)  *1500 +
count( case when [Дата выдачи кредита]  is not null and a.isPts =0 and a.returnType<>'Первичный' then a.[сумма выданного кредита] end)  *200)

,[Вознаграждение беззалог план]= sum([расходы руб_беззалог])
,[Суммарное вознаграждение]= ( count( case when [Дата выдачи кредита]  is not null and a.isPts =0 and a.returnType='Первичный' then a.[сумма выданного кредита] end)  *1500 +
count( case when [Дата выдачи кредита]  is not null and a.isPts =0 and a.returnType<>'Первичный' then a.[сумма выданного кредита] end)  *200)  + count( case when [Дата выдачи кредита]  is not null and a.isPts =1 and a.returnType='Первичный' then a.[сумма выданного кредита] end)  *4000.0
, b.rr_pts runRate
, b.month  reportMonth
, case when cast(format(date, 'yyyy-MM-01') as date) = b.month then 1 end isReportMonth
, case when  date >=getdate()-31   then 1 end isLast30day
,  a.productTypeExternal

into ##psb_report
from v a
left join v_rr b on 1=1
 
group by date, a.type
, b.rr_pts
 , b.month 
 , a.productTypeExternal

--select * from ##psb_report
--


drop table if exists dbo.marketing_psb_detail 
select * into dbo.marketing_psb_detail  from  ##psb_detail 
--delete from dbo.marketing_psb_detail 
--insert into dbo.marketing_psb_detail 
--select * from ##psb_detail 


drop table if exists dbo.marketing_psb_report
select * into dbo.marketing_psb_report from  ##psb_report
--delete from dbo.marketing_psb_report
--insert into dbo.marketing_psb_report
--select * from ##psb_report 

drop table if exists ##psb_balance

	select dateadd(second, -1, dateadd(day, 1, cast(d as datetime2(0))))  [Отчетная дата], a.external_id [идентификатор кредита]
	
	,  [остаток задолженности (не просроченный+просроченный осн долг)]= [остаток од] 
	,[сумма просрочки основного долга] =  [основной долг начислено нарастающим итогом]- [основной долг уплачено нарастающим итогом]  

	, dpd [количество дней просрочки]
	into ##psb_balance
	from dwh2.[dbo].[dm_CMRStatBalance]
 a 
	--from v_balance a 
join ##psb_detail b on a.external_id	=b.number
where

dateadd(day, -1, cast(DATEADD(MONTH, 1+DATEDIFF(MONTH, 0,           d), 0) as date)) =d


	drop table if exists marketing_psb_balance
	select * into marketing_psb_balance from  ##psb_balance
	--delete from psb_deepapi_balance
	--insert into psb_deepapi_balance
	--select * from ##psb_deepapi_balance 


--exec python 'sql2gs("select * from marketing_psb_report    order by 1", "1K538rWVzQpkj2G-jvuM_VkYeOPGhQCvbKR9rqFJeJOw", sheet_name="report" , make_sheet=False , fillna = True)', 1



--exec python 'sql2gs("select * from marketing_psb_detail   order by 1", "1K538rWVzQpkj2G-jvuM_VkYeOPGhQCvbKR9rqFJeJOw", sheet_name="details" , make_sheet=False , fillna = True)', 1








end



if @mode = 'detailed'
begin
select case when a.[reportDate] >=getdate()-30 then  a.[id] else '*' end    id
, a.[source]
, a.[IsAccepted]
, a.[IsClickThrough]
, a.[number]
, a.[IsPts]
, a.[origin]
, a.[returntype]
--, a.[Call1]
, a.[declined]
, a.[Call1Approved]
, a.[_fullRequestPTS]
 --, a.[Issued]
--, a.[IssuedSum]
, a.[guid]
, cast( a.[Экран_Анкета_ПТС]                             as date) [Экран_Анкета_ПТС]
, cast( a.[Экран_фото_паспорта_ПТС]						 as date) [Экран_фото_паспорта_ПТС]
, cast( a.[Загрузил_фото_паспорта_ПТС]					 as date) [Загрузил_фото_паспорта_ПТС]
, cast( a.[Экран_подписание_первого_пакета_ПТС]			 as date) [Экран_подписание_первого_пакета_ПТС]
, cast( a.[Подписал_первый_пакет_ПТС]					 as date) [Подписал_первый_пакет_ПТС]
, cast( a.[Экран_загрузка_фото_паспорта_и_клиента_ПТС]	 as date) [Экран_загрузка_фото_паспорта_и_клиента_ПТС]
, cast( a.[Экран_доп_информация_ПТС]					 as date) [Экран_доп_информация_ПТС]
, cast( a.[Экран_фото_документов_авто_ПТС]				 as date) [Экран_фото_документов_авто_ПТС]
, cast( a.[Экран_способ_выдачи_ПТС]						 as date) [Экран_способ_выдачи_ПТС]
, cast( a.[Карта_привязана_ПТС]							 as date) [Карта_привязана_ПТС]
, cast( a.[Экран_фото_авто_ПТС]							 as date) [Экран_фото_авто_ПТС]
, cast( a.[Экран_отправлена_полная_заявка_ПТС]			 as date) [Экран_отправлена_полная_заявка_ПТС]
, cast( a.[Экран_одобрена_заявка_ПТС]					 as date) [Экран_одобрена_заявка_ПТС]
, cast( a.[Экран_подписание_второго_пакета_ПТС]			 as date) [Экран_подписание_второго_пакета_ПТС]
, cast( a.[Подписал_второй_пакет_ПТС]					 as date) [Подписал_второй_пакет_ПТС]
, cast( a.[Экран_анкета_Беззалог]						 as date) [Экран_анкета_Беззалог]
, cast( a.[Экран_паспорт_Беззалог]						 as date) [Экран_паспорт_Беззалог]
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
, a.[productTypeExternal]
, a.[Признак большой инстоллмент]
, a.[Запрошенная сумма в банке]
, a.[termExternal]
, a.[termDayExternal]
, case when a.[reportDate] >=getdate()-30 then  a.[идентификатор заявки ПСБ]   	else '*' end [идентификатор заявки ПСБ] 
, case when a.[reportDate] >=getdate() then  a.[идентификатор клиента ПСБ]	else '*' end [идентификатор клиента ПСБ]
, cast(a.[дата заявки  (лид)]           as date) [дата заявки  (лид)]       
, cast(a.[дата заявки  (черновик)]		as date) [дата заявки  (черновик)]	
, cast(a.[дата заявки  (Call1)]			as date) [дата заявки  (Call1)]		
, a.[Продукт заявки]
, a.[статус заявки]
, a.[причина отказа]
, a.[дата принятия предварительного решения]
, a.[дата принятия финального решения]
, a.[одобренная максимальная сумма кредита]
, a.[одобренный продукт]
, a.[одобренный срок]
, a.[одобренная ставка]
, a.[признак страхования]
, a.[идентификатор заявки]
, a.[идентификатор кредита]
, a.[выданный продукт]
, a.[сумма выданного кредита]
, a.[срок выданного кредита месяцы]
, a.[срок выданного кредита дни (PDL)]
, a.[ПСК выданного кредита]
, a.[Дата выдачи кредита]
, a.[дата планового окончания кредита]
, a.[дата фактического окончания кредита]

from marketing_psb_detail   a
where reportDate>=getdate()-60
order by isnull(isnull([дата заявки  (Call1)], [дата заявки  (черновик)]), [дата заявки  (лид)]) desc

end

if @mode='out'
begin

SELECT  
    a.[идентификатор заявки ПСБ] 
,   a.[идентификатор клиента ПСБ] 
,   a.[Признак большой инстоллмент]
,   a.[дата заявки  (лид)] 
,   a.[дата заявки  (черновик)] 
,   a.[дата заявки  (Call1)] 
,   a.[статус заявки] 
,   a.[Продукт заявки]
,   a.[причина отказа] 
,   a.[дата принятия предварительного решения] 
,   a.[дата принятия финального решения] 
,   a.[одобренная максимальная сумма кредита] 
,   a.[одобренный продукт] 
,   a.[одобренный срок]
,   a.[одобренная ставка]
,   a.[признак страхования]
,   a.[идентификатор заявки] 
,   a.[идентификатор кредита] 
,   a.[выданный продукт] 
,   a.[сумма выданного кредита] 
,   a.[срок выданного кредита месяцы] 
,   a.[срок выданного кредита дни (PDL)] 
,   a.[ПСК выданного кредита] 
,   a.[Дата выдачи кредита] 
,   a.[дата планового окончания кредита] 
,   a.[дата фактического окончания кредита] 

        FROM 

        Analytics.dbo.[marketing_psb_detail] a
		--where [Признак большой инстоллмент]=1
		order by isnull([дата заявки  (лид)] , [дата заявки  (черновик)])
end





if @mode = 'biginst'
begin
select 
  reportDate
, reportWeek
, reportMonth
, case when rn_lead=1 then  source end source
, case when   [Признак большой инстоллмент]  =1 or  [Продукт заявки]  ='BIG INST' and  reportDate >=getdate()-0  then   [идентификатор заявки ПСБ]      end  [идентификатор заявки ПСБ] 
--, case when   [Признак большой инстоллмент]  =1 or  [Продукт заявки]  ='BIG INST' then   [идентификатор клиента ПСБ]	   end  [идентификатор клиента ПСБ]
--, case when   [Признак большой инстоллмент]  =1 then case when reportDate >=getdate()-5    or ([Дата выдачи кредита] is not null and [Продукт заявки]  ='BIG INST') then [идентификатор клиента ПСБ]	end  end  [идентификатор клиента ПСБ]
, [Признак большой инстоллмент]
, case when [Признак большой инстоллмент]  =1 and rn_lead=1 then case when		 [Дата выдачи кредита] is not null then id else '*' end end id
, case when  [Продукт заявки]  ='BIG INST'  then case when   [дата заявки  (Call1)] is not null then cast( [дата заявки  (Call1)] as date) end  end [Одобрен лид]
, case when [Признак большой инстоллмент]  =1 then decline end [Причина отказа по лиду]
, case when  [Продукт заявки]  ='BIG INST' and [идентификатор заявки] is not null then   case when reportDate >=getdate()-2 or [Загрузил документы]>=getdate()-5
or [Дата выдачи кредита] is not null then [идентификатор заявки] else '*' end end [идентификатор заявки]
, case when [Продукт заявки]  ='BIG INST' then cast(Call1Approved as date) end [Call1 одобрено]
, case when [Продукт заявки]  ='BIG INST' then case when datediff(second, [дата заявки  (лид)],[callbackPsbCall1Approved] ) <=500 then datediff(second, [дата заявки  (лид)], [callbackPsbCall1Approved] ) else 100*(  datediff(second, [дата заявки  (лид)], [callbackPsbCall1Approved] )/100 )  end end tty
, case when [Продукт заявки]  ='BIG INST' then  cast([Загрузил документы] as date)  end [Загрузили документы]
, case when [Продукт заявки]  ='BIG INST' then  CAST(ROUND([SLA проверки]     * 86400 / 10.0, 0) * 10 / 86400.0 AS FLOAT)    end [SLA проверки]
, case when [Продукт заявки]  ='BIG INST' then  CAST(ROUND([SLA проверки net] * 86400 / 10.0, 0) * 10 / 86400.0 AS FLOAT)    end [SLA проверки net]
, case when [Продукт заявки]  ='BIG INST' and [Загрузил документы] is not null  then  cast( isnull( [call15 одобрено], declined) as date) end [Получено решение на проверках]

, case when [Продукт заявки]  ='BIG INST' then cast( [call15 одобрено]  as date) end [call15 одобрено]

, case when [Продукт заявки]  ='BIG INST' then cast( Call2  as date) end call2
, case when [Продукт заявки]  ='BIG INST' then cast( [Call2 одобрено]  as date) end [Call2 одобрено]
, case when [Продукт заявки]  ='BIG INST' then cast( [Экран калькулятор БИ] as date)  end [Экран калькулятор БИ]
, case when [Продукт заявки]  ='BIG INST' then cast( [Экран способ выдачи БИ]  as date)  end [Экран способ выдачи БИ]
, case when [Продукт заявки]  ='BIG INST' then cast( Одобрен  as date)  end Одобрен
, case when [Продукт заявки]  ='BIG INST' then cast( [Подписал 2 пакет БИ]  as date) end [Подписал 2 пакет БИ]
, case when [Продукт заявки]  ='BIG INST' then cast( [Экран с таймером БИ]  as date) end [Экран с таймером БИ]
, case when [Продукт заявки]  ='BIG INST' then cast( [Экран с таймером выход БИ]  as date) end [Экран с таймером выход БИ]
, case when [Продукт заявки]  ='BIG INST' then cast( [Дата выдачи кредита]  as date) end [Дата выдачи кредита]
, case when [Продукт заявки]  ='BIG INST' then  [сумма выданного кредита] end [сумма выданного кредита]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [срок выданного кредита месяцы] end [срок выданного кредита месяцы]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [Процентная ставка] end [Процентная ставка]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [Запрошенная сумма в банке] end [Запрошенная сумма в банке]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [Сумма без подтв. дохода] end [Сумма без подтв. дохода]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [Сумма с подтв. дохода] end [Сумма с подтв. дохода]
, case when [Продукт заявки]  ='BIG INST' and [Дата выдачи кредита] is not null then  [признак страхования] end [признак страхования]
, case when cw.lastNday   <= 12 then 1 else 0 end   isLastNday
, case when cw.lastNweek  <= 12 then 1 else 0 end   isLastNweek
, case when cw.lastNmonth <= 12 then 1 else 0 end   isLastNmonth
 
, case when [Продукт заявки]  ='BIG INST' and Call1Approved is not null  then  isnull(requiredPhotoCnt, 0) end [Кол-во фотографий]
, case when [Продукт заявки]  ='BIG INST' and Call1Approved is not null  then  limitChoise end [Выбранное предложение]
, regionRegistration [Регион регистрации]
, partnerApplicationChannel [Канал]
, case when regionRegistration  like '%луганс%' 
or regionRegistration  like '%донец%' 
or regionRegistration  like '%херсон%' 
or regionRegistration  like '%запорож%' then 'НС РФ' else 'ИС РФ' end [Территории НС/ИС РФ]
, case when [Продукт заявки]  ='BIG INST'    then  status_crm end [Текущий статус заявки]
, case when [Продукт заявки]  ='BIG INST'    then  payMethod end  [Способ выдачи]
, case when [Продукт заявки]  ='BIG INST'    then  paySbpBank end [Банк СБП]
  

--select distinct regionRegistration from marketing_psb_detail
  --into granularity_marketing_psb_detail3

from 
(
select *, row_number() over(partition by id order by case when [Продукт заявки]  ='BIG INST' then 1 end desc ) rn_lead from
marketing_psb_detail

) a
 left join calendar_view cw on cw.date=a.reportDate
 where [дата заявки  (лид)]>='20251020' --and   ([Продукт заявки]  ='BIG INST' or [Продукт заявки] is null)
order by isnull(isnull([дата заявки  (Call1)], [дата заявки  (черновик)]), [дата заявки  (лид)]) desc



--exec sp_table_granularity 'granularity_marketing_psb_detail3'
end


