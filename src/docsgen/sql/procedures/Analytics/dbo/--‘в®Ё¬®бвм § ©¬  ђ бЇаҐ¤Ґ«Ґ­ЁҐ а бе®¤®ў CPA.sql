
CREATE   proc [dbo].[Стоимость займа Распределение расходов CPA]
as																		 
begin


 drop table if exists #crib_request 
select requestnumber, lead_leadgen_name  into #crib_request from (
select requestnumber, lead_leadgen_name, created, row_number() over(partition by requestnumber order by  created )  rn  from stg._crib.dm_crm_requests
where requestnumber is not null
 ) x where rn=1	   and created>='20230701'


drop table if exists #lcrm
select id, UF_ROW_ID, 

isnull( cr.lead_leadgen_name,case  when  try_cast( left('20'+UF_ROW_ID, 8) as date) <'20230701' then UF_SOURCE end)  UF_SOURCE
--case 
--when pb.postback_leadgen_name is not null then postback_leadgen_name 
--when try_cast(  left('20'+UF_ROW_ID, 8) as date) >='20230701' and lcrm_leads_full_channel_request.UF_TYPE='api' then  UF_SOURCE
--when try_cast(  left('20'+UF_ROW_ID, 8) as date) >='20230701' and lcrm_leads_full_channel_request.UF_TYPE<>'api' then  null
--when  try_cast( left('20'+UF_ROW_ID, 8) as date) <'20230701' then UF_SOURCE end UF_SOURCE
--, case 
--when pb.postback_leadgen_name is not null then 'postback ref' 
--when try_cast(  left('20'+UF_ROW_ID, 8) as date) >='20230701' and lcrm_leads_full_channel_request.UF_TYPE='api' then  'api'
--when try_cast(  left('20'+UF_ROW_ID, 8) as date) >='20230701' and lcrm_leads_full_channel_request.UF_TYPE<>'api' then  ''
--when  try_cast( left('20'+UF_ROW_ID, 8) as date) <'20230701' then uf_type end [Postback]

, analytics.[dbo].[lcrm_source_of_cpa_trafic_mp](UF_appmeca_tracker) [CPA трафик в МП источник]  into #lcrm 
from stg._lcrm.lcrm_leads_full_channel_request
left join #crib_request cr on cr.requestnumber= lcrm_leads_full_channel_request.UF_ROW_ID 
;
with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #lcrm ) delete from v where rn>1

drop table if exists #cpa

;

with  [cpa расходы_stg] as
(

SELECT [МесяцГод] [Дата оплаты месяц]
      ,[LCRM ID]
      ,cast(cast([Номер заявки] as bigint) as nvarchar(20)) [Номер заявки]
      ,[Лидген]
      ,[Сумма вознаграждения]
      ,[Комментарий]
      ,case 
	  when [За что платим] is not null then [За что платим] 
	  when cast(cast([Номер заявки] as bigint) as nvarchar(20)) is not null then 'заявку' 
	  else 'лид' end [За что платим]


      ,[created]
	  ,'Ручной расчет' Тип
  FROM stg.[files].[cpa расходы_stg]
  --order by 1
)
,


costs as (
SELECT [id]
      ,[Канал от источника]
      ,[UF_SOURCE]
      ,[UF_TYPE]
      ,[UF_ROW_ID]
	  ,isinstallment
      ,[ПолнаяЗаявка]
      ,[ЗаявкаAPI]
      ,[ЗаявкаAPI_или_API2]
      ,[ЗаявкаAPI2]
      ,[ЛидAPI_или_API2]
      ,[Лид_Дубль]
      ,[ДеньЛида]
      ,[МесяцЛида]
      ,[ДеньЗаявки]
      ,[МесяцЗаявки]
      ,[ДеньЗайма]
      ,[МесяцЗайма]
      ,[СуммаЗайма]
      ,[Регион]
      ,[json_cost_params]
      ,[Стоимость]
      ,[ЗаЧтоПлатим]
      ,[МесяцОплаты]
      ,[ПодлежитОплате]
	  ,case 
	  when a.ЗаЧтоПлатим='Лид'    and nullif(a.UF_ROW_ID , '') is null     and [Стоимость]>0 then [ДеньЛида]
	  when a.ЗаЧтоПлатим='Лид'    and nullif(a.UF_ROW_ID , '') is not null and [Стоимость]>0 then [ДеньЗаявки]
	  when a.ЗаЧтоПлатим='Заявку' and nullif(a.UF_ROW_ID , '') is not null  and [Стоимость]>0 then [ДеньЗаявки]
	  when a.ЗаЧтоПлатим='Займ'   and nullif(a.UF_ROW_ID , '') is not null  and [Стоимость]>0 then [ДеньЗайма]
	  
	  end ДеньОплаты
	  ,b.[Сумма вознаграждения] [Сумма вознаграждения1]
	  ,b1.[Сумма вознаграждения] [Сумма вознаграждения2]
  FROM [Analytics].[dbo].[Стоимость займа лиды с расчетной стоимостью Криб2] a
  left join [cpa расходы_stg] b on a.UF_ROW_ID=b.[Номер заявки] and nullif(a.UF_ROW_ID, '')<>''
  left join [cpa расходы_stg] b1 on a.id=b1.[LCRM ID] 
   where Стоимость >0
 and b.[Сумма вознаграждения] is  null and b1.[Сумма вознаграждения] is  null
  )
  , max_m as (
  select max([Дата оплаты месяц]) max_m from [cpa расходы_stg]
  )
  , data as
  (

SELECT [Дата оплаты месяц]
      ,[LCRM ID] id
      ,[Номер заявки]
      ,[Лидген]
      ,[Сумма вознаграждения]
      ,[Комментарий]
      ,[За что платим]
      ,[created]
	  ,Тип
  FROM [cpa расходы_stg]
  union all
  select cast(format(ДеньОплаты, 'yyyy-MM-01') as date) МесяцОплаты, id, UF_ROW_ID, UF_SOURCE, Стоимость, null, ЗаЧтоПлатим, null, 'Авто расчет' from costs where cast(format(ДеньОплаты, 'yyyy-MM-01') as date)>(select top 1 * from max_m)
  )

  select 
  * 
  into #cpa
  from data


drop table if exists #base

select Номер, [Группа каналов], [Канал от источника]
, b.UF_SOURCE
, a.isInstallment
, cast( null  as float) as [Расходы на CPA заявка] 
, cast( null  as float) as [Расходы на CPA займ] 
, cast( null  as float) as [Расходы на CPA лид] 
, cast( null  as float) as [Расходы на CPA траты на заявку без заявки] 
, cast(format([Верификация КЦ] , 'yyyy-MM-01') as date) [Месяц заявки]
, cast(format([Заем выдан] , 'yyyy-MM-01') as date)     [Месяц займа]
, cast(format([Заем выдан] , 'yyyy-MM-dd') as date)     [День займа]
, isnull( cast(format([Заем выдан] , 'yyyy-MM-01') as date), cast(format([Верификация КЦ] , 'yyyy-MM-01') as date))  [Месяц займа заявки]
, b.[CPA трафик в МП источник]
into #base
from reports.dbo.dm_factor_analysis_001 a
left join #lcrm  b on a.Номер=b.UF_ROW_ID


drop table if exists #ТратыCPA
select [Дата оплаты месяц]                                 [Дата оплаты месяц]
,      a.id     id                                          
,      isnull(a.[Номер заявки] , l.UF_ROW_ID)              Номер
,      a.[Лидген]                                          [Лидген]
,      a.[Сумма вознаграждения]                            [Сумма вознаграждения]
,      a.[За что платим]                                   [За что платим]
,      case when b.Номер is not null and a.[За что платим] in ('заявку', 'займ') then 1 else 0 end ПрямаяТрата
--,      ROW_NUMBER() over(order by (select null))           cost_id
	into #ТратыCPA
from      #cpa  a
left join #lcrm l on a.id=l.ID and a.[За что платим] in ('заявку', 'займ')
left join #base b on isnull(a.[Номер заявки] , l.UF_ROW_ID)=b.Номер and a.[За что платим] in ('заявку', 'займ')

	  drop table if exists #ТратыCPAпрямые, #ТратыCPAаллоцируемые

	 select * into #ТратыCPAпрямые from #ТратыCPA where ПрямаяТрата=1
	 select * into #ТратыCPAаллоцируемые from #ТратыCPA where ПрямаяТрата=0


	-- select * from #ТратыCPAаллоцируемые
	-- order by 1 desc

	  update  b
	  set b.[Расходы на CPA заявка] =s.[Сумма вознаграждения]
	  from #base b join (select sum([Сумма вознаграждения]) [Сумма вознаграждения] , Номер from #ТратыCPAпрямые where [За что платим]='заявку' group by Номер ) s on b.Номер=s.Номер
	 
	  update  b
	  set b.[Расходы на CPA займ] =s.[Сумма вознаграждения]
	  from #base b join (select sum([Сумма вознаграждения]) [Сумма вознаграждения] , Номер from #ТратыCPAпрямые where [За что платим]='займ'  group by Номер ) s on b.Номер=s.Номер
	  

	  drop table if exists #ТратыCPAаллоцируемые_по_лидгену_месяцу
	  select 
	   лидген   	  
,      [Дата оплаты месяц]
,      [За что платим]
,      sum([Сумма вознаграждения])/nullif(ЧислоЗаявок, 0)   [Аллоцируемые расходы на CPA на одну заявку]

into #ТратыCPAаллоцируемые_по_лидгену_месяцу
from #ТратыCPAаллоцируемые a outer apply (select cast(count(*) as float) ЧислоЗаявок from #base b where a.Лидген like  '%'+b.UF_SOURCE+'%' and b.UF_SOURCE <>'' and b.isInstallment=0 and b.[Месяц заявки]=a.[Дата оплаты месяц]) x 
group by лидген,        [Дата оплаты месяц] ,        ЧислоЗаявок ,        [За что платим]



update b
set b.[Расходы на CPA траты на заявку без заявки] = x.[Аллоцируемые расходы на CPA на одну заявку]
from        #base b
cross apply (select top 1 *
	from #ТратыCPAаллоцируемые_по_лидгену_месяцу
	x
	where x.Лидген like '%'+b.UF_SOURCE+'%'
		and b.UF_SOURCE <>''
		and b.[Месяц заявки]=x.[Дата оплаты месяц]
		and b.isInstallment=0
and x.[За что платим]='заявку'
	)             x


	  
	  update  b
	  set b.[Расходы на CPA лид] =x.[Аллоцируемые расходы на CPA на одну заявку]

from        #base b
cross apply (select top 1 *
	from #ТратыCPAаллоцируемые_по_лидгену_месяцу
	x
	where x.Лидген like '%'+b.UF_SOURCE+'%'
		and b.UF_SOURCE <>''
		and b.[Месяц заявки]=x.[Дата оплаты месяц]
		and b.isInstallment=0
		and x.[За что платим]='лид'
	)             x



	--exec   [_gsheets].[load_google_sheet_to_DWH]'Расходы по кликовым офферам'	  




	drop table if exists #clicks_and_other_costs

;
with 		
p as (select *, cast(format(Дата, 'yyyy-MM-01') as date) m from stg.[files].[ContactCenterPlans_buffer])
, rr as (select m, sum(case when Дата <getdate()-1 then [Займы руб] end)/sum([Займы руб]) rr from p group by m ) 


,v AS (
	select 
    r.[Месяц] 											[Месяц] 
,   rr.rr*r.[Прочие расходы CPA ПТС]						    [Прочие CPA ПТС]
,   rr.rr*r.[Прочие расходы CPA Инстоллмент]						    [Прочие CPA Инстоллмент]
,   isnull(o.[Клики Bankiru-ref ПТС]                             ,   rr.rr*r.[Клики Bankiru-ref ПТС] 						)	        [Клики Bankiru-ref ПТС] 
,   isnull(o.[Клики bankiru_businesszaim ПТС]                    ,   rr.rr*r.[Клики bankiru_businesszaim ПТС] 						)	        [Клики bankiru_businesszaim ПТС] 
,   isnull(o.[Клики Bankiru-installment-ref Инстоллмент]         ,   rr.rr*r.[Клики Bankiru-installment-ref Инстоллмент] 	)	        [Клики Bankiru-installment-ref Инстоллмент] 
,   isnull(o.[Клики Bankiru-installment-context Инстоллмент]     ,   rr.rr*r.[Клики Bankiru-installment-context Инстоллмент] 	)	[Клики Bankiru-installment-context Инстоллмент] 
,   isnull(o.[Клики leadssu-installment-ref Инстоллмент]         ,   rr.rr*r.[Клики leadssu-installment-ref Инстоллмент] 	    )	[Клики leadssu-installment-ref Инстоллмент] 
,   isnull(o.[Клики gidfinance-installment-click Инстоллмент]    ,   rr.rr*r.[Клики gidfinance-installment-click Инстоллмент] 	)	[Клики gidfinance-installment-click Инстоллмент] 
 

,   rr.rr*r.[МП mobishark ПТС] 								    [МП mobishark ПТС] 
,   rr.rr*r.[МП mobishark_Nozalog Инстоллмент] 								    [МП mobishark_Nozalog Инстоллмент] 
,   rr.rr*r.[МП appska ПТС] 									[МП appska ПТС] 
,   rr.rr*r.[МП appska_Nozalog Инстоллмент] 					[МП appska_Nozalog Инстоллмент] 
,   rr.rr*r.[МП Trafficshark ПТС] 							    [МП Trafficshark ПТС] 
,   rr.rr*r.[МП Trafficshark_Nozalog Инстоллмент] 				[МП Trafficshark_Nozalog Инстоллмент] 
,   rr.rr*r.[МП Zenmobile ПТС] 								    [МП Zenmobile ПТС] 
,   rr.rr*r.[МП WhiteLeads ПТС] 								[МП WhiteLeads ПТС] 
,   rr.rr*r.[МП MobUpps ПТС] 									[МП MobUpps ПТС] 
,   rr.rr*r.[МП 2Leads ПТС] 									[МП 2Leads ПТС] 
,   rr.rr*r.[МП MobZilla ПТС] 									[МП MobZilla ПТС] 
,   rr.rr*r.[МП Huntermob ПТС] 								[МП Huntermob ПТС] 

--select *
from 
	 

stg.files.[расходы по месяцам от подразделений_stg] r
left join dbo.[Стоимость займа Расходы по кликовым офферам_view]   o on r.[Месяц]=o.[Месяц] 
	left join rr on cast( r.Месяц as date)=rr.m
WHERE r.[Месяц]  IS NOT NULL

)
 
   , unpvt as (
SELECT Месяц, COST_NAME, RUBS  
FROM   
   (SELECT Месяц
      , [Прочие CPA ПТС] 
	  ,[Прочие CPA Инстоллмент] 
      , [Клики Bankiru-ref ПТС] 
	  ,[Клики bankiru_businesszaim ПТС] 
	  ,[Клики Bankiru-installment-ref Инстоллмент] 
	  ,[Клики Bankiru-installment-context Инстоллмент] 
	  ,[Клики leadssu-installment-ref Инстоллмент] 
	  ,[Клики gidfinance-installment-click Инстоллмент]
	  ,[МП mobishark ПТС] 
	  ,[МП mobishark_Nozalog Инстоллмент] 
	  ,[МП appska ПТС] 
	  ,[МП appska_Nozalog Инстоллмент] 
	  ,[МП Trafficshark ПТС] 
	  ,[МП Trafficshark_Nozalog Инстоллмент] 
	  ,[МП Zenmobile ПТС] 
	  ,[МП WhiteLeads ПТС] 
	  ,[МП MobUpps ПТС] 
	  ,[МП 2Leads ПТС] 
	  ,[МП MobZilla ПТС] 
	  ,[МП Huntermob ПТС] 
   FROM V) p  
UNPIVOT  
   (RUBS FOR COST_NAME IN   
      (
	   [Прочие CPA ПТС] 				 
	  ,[Прочие CPA Инстоллмент] 
	  ,[Клики Bankiru-ref ПТС] 
	  ,[Клики bankiru_businesszaim ПТС] 
	  ,[Клики Bankiru-installment-ref Инстоллмент] 
	  ,[Клики Bankiru-installment-context Инстоллмент] 
	  ,[Клики leadssu-installment-ref Инстоллмент] 
	  ,[Клики gidfinance-installment-click Инстоллмент]
	  ,[МП mobishark ПТС] 
	  ,[МП mobishark_Nozalog Инстоллмент] 
	  ,[МП appska ПТС] 
	  ,[МП appska_Nozalog Инстоллмент] 
	  ,[МП Trafficshark ПТС] 
	  ,[МП Trafficshark_Nozalog Инстоллмент] 
	  ,[МП Zenmobile ПТС] 
	  ,[МП WhiteLeads ПТС] 
	  ,[МП MobUpps ПТС] 
	  ,[МП 2Leads ПТС] 
	  ,[МП MobZilla ПТС] 
	  ,[МП Huntermob ПТС] 
	  
	  )  
)AS unpvt

)
select Месяц, COST_NAME, Rubs
, REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 1))  TYPE
, REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 2))  SOURCE
, case REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 3))  when 'ПТС' then 0 when 'Инстоллмент' then 1 end 	 isInstallment
  into #clicks_and_other_costs
from unpvt
where RUBS>0

drop table if exists #clicks_and_other_costs2

select a.Месяц
, a.COST_NAME
, isnull( b.Номер,c.Номер) Номер 
, isnull(rubs/ nullif( count(b.Номер) over(partition by Месяц, COST_NAME)+0.0, 0)  
, rubs/ nullif( count(c.Номер) over(partition by Месяц, COST_NAME)+0.0, 0) ) Распределение
, case when   b.Номер is null then 1 end [Распределение на все]

into #clicks_and_other_costs2  

from  #clicks_and_other_costs a
left join (
	select a.Номер, 'МП' type, a.[Месяц займа заявки], isinstallment, [CPA трафик в МП источник] source from #base	 a where [Группа каналов]='cpa' union all--group by [Месяц займа], isinstallment, [CPA трафик в МП источник] union all
	--select Номер, 'Клики' type, [Месяц займа заявки], isinstallment, uf_source source               from #base	 a where [Группа каналов]='cpa' and [Месяц займа] is not null                --group by [Месяц займа], isinstallment, uf_source --union all
	
	--select b.Номер, 'Клики' type, b.[Месяц займа заявки], b.isinstallment, b.uf_source source    from #base	  b	 join 
	--	(
	--
	--
	--
	--
	--	select '20221118' since, '20221125' till , 0 isinstallment, 'bankiru-ref'                  source union all
	--	select '20230419' since, '20230430' till , 0 isinstallment, 'bankiru-ref'                  source union all
	--	select '20230503' since, '20230531' till , 0 isinstallment, 'bankiru-ref'                  source union all
	--	select '20230601' since, '20230731' till , 0 isinstallment, 'bankiru-ref'                  source union all
	--	select '20230503' since, '20230623' till , 1 isinstallment, 'bankiru-installment-ref'      source union all
	--	select '20230625' since, '20230731' till , 1 isinstallment, 'bankiru-installment-ref'      source union all
	--	select '20230701' since, '20230731' till , 1 isinstallment, 'bankiru-installment-context'      source union all
	--	select '20230526' since, '20230606' till , 1 isinstallment, 'leadssu-installment-ref'      source union all
	--	select '20230518' since, '20230531' till , 1 isinstallment, 'gidfinance-installment-click' source union all
	--	select '20230622' since, '20230630' till , 1 isinstallment, 'gidfinance-installment-click' source --union all
	--	) a on	b.[День займа] between a.since and a.till and a.source=b.uf_source and a.isinstallment=b.isinstallment
select b.Номер, 'Клики' type, b.[Месяц займа заявки], b.isinstallment, b.uf_source source    from #base	  b	 join (
select Дата, 0 isinstallment, 'bankiru-ref'                   uf_source from stg.files.[расходы по кликовым офферам] where [Клики bankiru-ref ПТС] >0			    union all
select Дата, 0 isinstallment, 'bankiru_businesszaim'          from stg.files.[расходы по кликовым офферам] where [Клики bankiru_businesszaim ПТС] >0			    union all
select Дата, 1 isinstallment, 'bankiru-installment-ref'       from stg.files.[расходы по кликовым офферам] where [Клики bankiru-installment-ref Инстоллмент] >0  union all
select Дата, 1 isinstallment, 'bankiru-installment-context'   from stg.files.[расходы по кликовым офферам] where [Клики bankiru-installment-context Инстоллмент] >0  union all
select Дата, 1 isinstallment, 'leadssu-installment-ref'       from stg.files.[расходы по кликовым офферам] where [Клики leadssu-installment-ref Инстоллмент] >0  union all
select Дата, 1 isinstallment, 'gidfinance-installment-click'  from stg.files.[расходы по кликовым офферам] where [Клики gidfinance-installment-click Инстоллмент] >0  union all
select Дата, 1 isinstallment, 'gidfinance-installment-click'  from stg.files.[расходы по кликовым офферам] where [Клики gidfinance-installment-click Инстоллмент] >0 
	) a on b.[День займа] = a.Дата and 	   a.isinstallment=b.isinstallment and 	 a.uf_source=b.uf_source 


) b on a.TYPE=b.TYPE and 	a.isInstallment=b.isInstallment and a.Месяц=b.[Месяц займа заявки]	 and a.source=b.source
left join 
(
select Номер, 'CPA' type, [Месяц займа заявки], isinstallment, 'CPA' source, 1 [Заявок] from #base	 a where [Группа каналов]='cpa'	and [Месяц займа] is not null   
) c on b.Номер is null and c.isInstallment=	a.isInstallment and a.Месяц=c.[Месяц займа заявки]
 --order by 1, 2

--		   select * from   #base where uf_source = 'bankiru-installment-context'
-- select * from #clicks_and_other_costs2
-- order by 1

-- select Месяц, cost_name, sum(Распределение) from #clicks_and_other_costs2
-- group by Месяц, cost_name
-- order by 1, 2


--select * from 	   #clicks_and_other_costs2
--where номер='23052620952465'
--where cost_name like '%клики%'
--order by 1,2

 drop table if exists #clicks_and_other_costs3
 SELECT Номер  
      ,sum(case when COST_NAME = 'Прочие CPA ПТС' 					                   then Распределение end )   [Прочие CPA ПТС] 					               
      ,sum(case when COST_NAME = 'Прочие CPA Инстоллмент' 					   then Распределение end )   [Прочие CPA Инстоллмент] 					               
	  ,sum(case when COST_NAME = 'Клики Bankiru-ref ПТС' 							   then Распределение end )   [Клики Bankiru-ref ПТС] 							   
	  ,sum(case when COST_NAME = 'Клики bankiru_businesszaim ПТС' 					   then Распределение end )   [Клики bankiru_businesszaim ПТС] 							   
	  ,sum(case when COST_NAME = 'Клики Bankiru-installment-ref Инстоллмент' 		   then Распределение end )   [Клики Bankiru-installment-ref Инстоллмент] 		   
	  ,sum(case when COST_NAME = 'Клики bankiru-installment-context Инстоллмент' 	   then Распределение end )   [Клики bankiru-installment-context Инстоллмент] 	   
	  ,sum(case when COST_NAME = 'Клики leadssu-installment-ref Инстоллмент' 		   then Распределение end )   [Клики leadssu-installment-ref Инстоллмент] 		   
	  ,sum(case when COST_NAME = 'Клики gidfinance-installment-click Инстоллмент'	   then Распределение end )   [Клики gidfinance-installment-click Инстоллмент]	   
	  ,sum(case when COST_NAME = 'МП mobishark ПТС' 								   then Распределение end )   [МП mobishark ПТС] 								   
	  ,sum(case when COST_NAME = 'МП mobishark_Nozalog Инстоллмент' 				   then Распределение end )   [МП mobishark_Nozalog Инстоллмент] 								   
	  ,sum(case when COST_NAME = 'МП appska ПТС' 									   then Распределение end )   [МП appska ПТС] 									   
	  ,sum(case when COST_NAME = 'МП appska_Nozalog Инстоллмент' 					   then Распределение end )   [МП appska_Nozalog Инстоллмент] 					   
	  ,sum(case when COST_NAME = 'МП Trafficshark ПТС' 							       then Распределение end )   [МП Trafficshark ПТС] 							   
	  ,sum(case when COST_NAME = 'МП Trafficshark_Nozalog Инстоллмент' 			       then Распределение end )   [МП Trafficshark_Nozalog Инстоллмент] 			   
	  ,sum(case when COST_NAME = 'МП Zenmobile ПТС' 								   then Распределение end )   [МП Zenmobile ПТС] 								   
	  ,sum(case when COST_NAME = 'МП WhiteLeads ПТС' 								   then Распределение end )   [МП WhiteLeads ПТС] 								   
	  ,sum(case when COST_NAME = 'МП MobUpps ПТС' 								       then Распределение end )   [МП MobUpps ПТС] 								   
	  ,sum(case when COST_NAME = 'МП 2Leads ПТС' 									   then Распределение end )   [МП 2Leads ПТС] 									   
	  ,sum(case when COST_NAME = 'МП MobZilla ПТС'   							       then Распределение end )   [МП MobZilla ПТС]   							   
	  ,sum(case when COST_NAME = 'МП Huntermob ПТС'   							       then Распределение end )   [МП Huntermob ПТС]   							   
	   into #clicks_and_other_costs3
FROM #clicks_and_other_costs2  
group by  Номер

;


  drop table if exists #base2
select 
  a.Номер
, a.[Группа каналов]
, a.[Канал от источника]
, a.UF_SOURCE
, a.isInstallment
, a.[CPA трафик в МП источник]
 , [Месяц заявки] [Месяц заявки]
 , [Месяц займа]   [Месяц займа]
 , [Месяц займа заявки]


 ,[Расходы на CPA заявка]   
 ,[Расходы на CPA займ]  
 ,[Расходы на CPA лид]   
 ,[Расходы на CPA траты на заявку без заявки]  
 ,[Прочие CPA ПТС] 
 ,[Прочие CPA Инстоллмент] 
 ,[Клики Bankiru-ref ПТС] 
 ,[Клики bankiru_businesszaim ПТС] 
 ,[Клики bankiru-installment-context Инстоллмент] 
 ,[Клики Bankiru-installment-ref Инстоллмент] 
 ,[Клики leadssu-installment-ref Инстоллмент] 
 ,[Клики gidfinance-installment-click Инстоллмент]
 ,[МП mobishark ПТС] 
 ,[МП mobishark_Nozalog Инстоллмент] 
 ,[МП appska ПТС] 
 ,[МП appska_Nozalog Инстоллмент] 
 ,[МП Trafficshark ПТС] 
 ,[МП Trafficshark_Nozalog Инстоллмент] 
 ,[МП Zenmobile ПТС] 
 ,[МП WhiteLeads ПТС] 
 ,[МП MobUpps ПТС] 
 ,[МП 2Leads ПТС] 
 ,[МП MobZilla ПТС] 
 ,[МП Huntermob ПТС]   
 
 ,nullif(isnull([Расходы на CPA заявка]   	                        , 0)+
  isnull([Расходы на CPA займ]  							, 0)+
  isnull([Расходы на CPA лид]   							, 0)+
  isnull([Расходы на CPA траты на заявку без заявки]  		, 0)+
  isnull([Прочие CPA ПТС] 									, 0)+
  isnull([Прочие CPA Инстоллмент] 									, 0)+
  isnull([Клики Bankiru-ref ПТС] 							, 0)+
  isnull([Клики bankiru_businesszaim ПТС] 							, 0)+
  isnull([Клики bankiru-installment-context Инстоллмент] 		, 0)+
  isnull([Клики Bankiru-installment-ref Инстоллмент] 		, 0)+
  isnull([Клики leadssu-installment-ref Инстоллмент] 		, 0)+
  isnull([Клики gidfinance-installment-click Инстоллмент]	, 0)+
  isnull([МП mobishark ПТС] 								, 0)+
  isnull([МП mobishark_Nozalog Инстоллмент] 								, 0)+
  isnull([МП appska ПТС] 									, 0)+
  isnull([МП appska_Nozalog Инстоллмент] 					, 0)+
  isnull([МП Trafficshark ПТС] 								, 0)+
  isnull([МП Trafficshark_Nozalog Инстоллмент] 				, 0)+
  isnull([МП Zenmobile ПТС] 								, 0)+
  isnull([МП WhiteLeads ПТС] 								, 0)+
  isnull([МП MobUpps ПТС] 									, 0)+
  isnull([МП 2Leads ПТС] 									, 0)+
  isnull([МП MobZilla ПТС] 									, 0)+
  isnull([МП Huntermob ПТС]   								, 0)	  , 0)	[Расходы на CPA]
into #base2
   
from #base a
left join  #clicks_and_other_costs3 b on a.Номер=b.Номер


-- select * from (
--select [Месяц заявки]	, sum([Расходы на CPA]) [Расходы на CPA] from #base2
--group by [Месяц заявки]
--) a 
--left join (
--
--select [Месяц заявки]	, sum([Расходы на CPA]) [Расходы на CPA] from [Отчет аллоцированные расходы CPA]
--group by [Месяц заявки]
--)	  b on a.[Месяц заявки] = b.[Месяц заявки]
--order by 1

--select * from #base2
--where [Расходы на CPA]>0



--		drop table if exists #costs_from_departments_ole
--		;
--with 		
--p as (select *, cast(format(Дата, 'yyyy-MM-01') as date) m from stg.[files].[ContactCenterPlans_buffer])
--, rr as (select m, sum(case when Дата <getdate()-1 then [Займы руб] end)/sum([Займы руб]) rr from p group by m )
--
--
--
--SELECT  cast(Месяц as date) month 
--	   ,[Расходы на трафик CPA Zenmobile в МП]           = cast([Расходы на трафик CPA Zenmobile в МП]   as float)*rr.rr
--	   ,[Расходы на трафик CPA Trafficshark в МП]           = cast([Расходы на трафик CPA Trafficshark в МП]   as float)*rr.rr
--	   ,[Расходы на трафик CPA appska в МП]           = cast([Расходы на трафик CPA appska в МП]   as float)*rr.rr
--	   ,[Расходы на трафик CPA mobishark в МП]           = cast([Расходы на трафик CPA mobishark в МП]   as float)*rr.rr
--	   ,[Расходы на трафик CPA MobUpps в МП]           = cast([Расходы на трафик CPA MobUpps в МП]   as float)*rr.rr
--	   ,[Безвозратные потери CPA_ПТС]                        = cast([Безвозратные потери CPA]				  as float)*rr.rr
--	   ,[Расходы на CPA опер_ПТС]                            = cast([Расходы на CPA опер]				  as float)*rr.rr
--	   ,[Прочие расходы CPA ПТС]                            = cast([Прочие расходы CPA ПТС]				  as float)*rr.rr
--	   ,rr.rr
--	   into #costs_from_departments_ole
--    --select *
--	from stg.files.[расходы по месяцам от подразделений_stg] r 
--	left join rr on cast( r.Месяц as date)=rr.m
--	where  cast(Месяц as date) is not null
--
--	--select * from #costs_from_departments_ole
--
--	drop table if exists #costs_from_departments
--	select 
--	
--			month        
--			, [Расходы CPA appska на одну заявку] = [Расходы на трафик CPA appska в МП]/[Трафик CPA appska в МП].[Трафик CPA appska в МП]           
--			, [Расходы CPA mobishark на одну заявку] = [Расходы на трафик CPA mobishark в МП]/[Трафик CPA mobishark в МП].[Трафик CPA mobishark в МП]           
--			, [Расходы CPA Trafficshark на одну заявку] = [Расходы на трафик CPA Trafficshark в МП]/[Трафик CPA Trafficshark в МП].[Трафик CPA Trafficshark в МП]           
--			, [Расходы CPA Zenmobile на одну заявку] = [Расходы на трафик CPA Zenmobile в МП]/[Трафик CPA Zenmobile в МП].[Трафик CPA Zenmobile в МП]           
--			, [Расходы CPA MobUpps на одну заявку] = [Расходы на трафик CPA MobUpps в МП]/[Трафик CPA MobUpps в МП].[Трафик CPA MobUpps в МП]           
--			, [Безвозратные потери CPA на одну заявку_ПТС] = [Безвозратные потери CPA_ПТС]/[Заявок CPA_ПТС].[Заявок CPA_ПТС]           
--			, [Прочие расходы CPA на один займ CPA_ПТС] = [Прочие расходы CPA ПТС]/[Займов CPA_ПТС].[Займов CPA_ПТС] 
--			, [Расходы на CPA опер на один CPA займ_ПТС]   = ([Расходы на CPA опер_ПТС])/[Займов CPA_ПТС]
--
--	into #costs_from_departments 
--			
--from #costs_from_departments_ole  costs_from_departments
--	outer apply( select nullif(cast(count(*) as float), 0) [Заявок CPA_ПТС]                 from #base b where isinstallment=0 and b.[Месяц заявки]= costs_from_departments.month and [Группа каналов]='CPA') [Заявок CPA_ПТС]
--	outer apply( select nullif(cast(count(*) as float), 0) [Займов CPA_ПТС]                 from #base b where isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Группа каналов]='CPA') [Займов CPA_ПТС]
--	outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA mobishark в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='Mobishark' and b.isInstallment=0) [Трафик CPA mobishark в МП]
--	outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA appska в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='Appska' and b.isInstallment=0) [Трафик CPA appska в МП]
--	outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA Trafficshark в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='Trafficshark' and b.isInstallment=0) [Трафик CPA Trafficshark в МП]
--	outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA MobUpps в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='MobUpps' and b.isInstallment=0) [Трафик CPA MobUpps в МП]
--	outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA Zenmobile в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='Zenmobile' and b.isInstallment=0) [Трафик CPA Zenmobile в МП]
--
----	select * from #costs_from_departments
--	
--		  update  b
--	  set b.[Расходы на CPA прочие] =x.[Прочие расходы CPA на один займ CPA_ПТС]
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц займа]=x.month
--		and [Группа каналов]='CPA'
--		and b.isInstallment=0
--
--	)             x
--
--
--		  update  b
--	  set b.[Безвозратные потери CPA] =x.[Безвозратные потери CPA на одну заявку_ПТС]
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [Группа каналов]='CPA'
--		and b.isInstallment=0
--
--	)             x
--	
--		  update  b
--	  set b.[Расходы на CPA mobishark трафик в МП] =x.[Расходы CPA mobishark на одну заявку]--, 1500)
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [CPA трафик в МП источник]='Mobishark'
--		and b.isInstallment=0
--		and [Месяц заявки]>='20210901'
--	)             x
--		
--		  update  b
--	  set b.[Расходы на CPA appska трафик в МП] =x.[Расходы CPA appska на одну заявку]--, 1500)
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [CPA трафик в МП источник]='Appska'
--		and b.isInstallment=0
--		and [Месяц заявки]>='20220901'
--	)             x
--		
--		  update  b
--	  set b.[Расходы на CPA Trafficshark трафик в МП] =x.[Расходы CPA Trafficshark на одну заявку]--, 1500)
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [CPA трафик в МП источник]='Trafficshark'
--		and b.isInstallment=0
--		and [Месяц заявки]>='20221001'
--	)             x
--	
--		  update  b
--	  set b.[Расходы на CPA Zenmobile трафик в МП] =x.[Расходы CPA Zenmobile на одну заявку]--, 1500)
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [CPA трафик в МП источник]='Zenmobile'
--		and b.isInstallment=0
--		and [Месяц заявки]>='20221001'
--	)             x
--		
--		  update  b
--	  set b.[Расходы на CPA MobUpps трафик в МП] =x.[Расходы CPA MobUpps на одну заявку]--, 1500)
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц заявки]=x.month
--		and [CPA трафик в МП источник]='MobUpps'
--		and b.isInstallment=0
--		and [Месяц заявки]>='20230201'
--	)             x

--select * from #base
--order by [CPA трафик в МП источник] desc, [Месяц заявки]

drop table if exists Analytics.dbo.[Стоимость займа Распределенные расходы CPA]
select *  into Analytics.dbo.[Стоимость займа Распределенные расходы CPA]	 from #base2

	begin tran
	--drop table if exists Analytics.dbo.[Стоимость займа Распределенные расходы CPA]
	--select *  into Analytics.dbo.[Стоимость займа Распределенные расходы CPA]	 from #base2

	delete from Analytics.dbo.[Стоимость займа Распределенные расходы CPA]
	insert into Analytics.dbo.[Стоимость займа Распределенные расходы CPA]
	select *   from #base2
	--where [МП Mobzilla ПТС]>0
	--order by 1
	--
	
	commit tran

	--select * from #base
	--where [Расходы на CPA Zenmobile трафик в МП]>0

	--select [Месяц заявки],[CPA трафик в МП источник], isInstallment, count(*), sum([Расходы на CPA mobishark трафик в МП]) from Analytics.dbo.[Отчет аллоцированные расходы CPA] 
	--where  [CPA трафик в МП источник]='Mobishark' and isInstallment=0
	--group by  [CPA трафик в МП источник], isInstallment, [Месяц заявки]
	--order by 1 desc
	--select * from Analytics.dbo.[Отчет аллоцированные расходы CPA]
	--where [CPA трафик в МП источник] = 'Trafficshark'
	--order by [Месяц заявки]
end