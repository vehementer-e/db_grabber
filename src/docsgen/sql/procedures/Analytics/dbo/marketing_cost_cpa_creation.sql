CREATE proc [dbo].[marketing_cost_cpa_creation]	  @recreate int = 0 as 

--exec marketing_calc_cost_cpa 1




drop table if exists #lcrm
CREATE TABLE [dbo].[#lcrm]
(
      [id] [NUMERIC]
    , [UF_ROW_ID] [VARCHAR](128)
    , [UF_SOURCE] [VARCHAR](128)
    , [CPA трафик в МП источник] [VARCHAR](128)
);
insert  into #lcrm 
select id, UF_ROW_ID,  UF_SOURCE, analytics.[dbo].[lcrm_source_of_cpa_trafic_mp](UF_appmeca_tracker) [CPA трафик в МП источник] from stg._lcrm.lcrm_leads_full_channel_request
;
with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #lcrm ) delete from v where rn>1


insert into #lcrm
select null, number, source , null  from _request where isnull( issued , call1 ) >='20241201'


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
--  FROM [Analytics].[dbo].[Стоимость займа лиды с расчетной стоимостью Криб] a
  FROM  Analytics.dbo.dm_report_lcrm_cpa_cpc_costs a
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

  ----select * from #cpa
  --insert into #cpa

  --select cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    
  --  case   when a.expectedCpaCostType='заявку'       and a.expectedCpaCost >0 then cast(call1   as date)  
	 -- when a.expectedCpaCostType='займ'          and  a.expectedCpaCost >0 then cast( issued  as date)   
	  
	 -- end), 0) as date) month, null , number, source, expectedCpaCost, '',  a.expectedCpaCostType, getdate(), ''
 
	  
	 -- from _request a
	 -- where expectedCpaCost>0 and 1=0


  --insert into #cpa

  --select cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    
  --  created), 0) as date) month, null , null, source, leadCost, '',  'лид', getdate(), ''
 
	 -- --select *
	 -- from marketing_cost_lead a
	 -- where leadCost >0 and 1=0



drop table if exists #base

select Номер, [Группа каналов], [Канал от источника]
, a.source UF_SOURCE
, 1 - a.isPts isInstallment
, cast( null  as float) as [Расходы на CPA заявка] 
, cast( null  as float) as [Расходы на CPA займ] 
, cast( null  as float) as [Расходы на CPA лид] 
, cast( null  as float) as [Расходы на CPA траты на заявку без заявки] 
, cast(format([Верификация КЦ] , 'yyyy-MM-01') as date) [Месяц заявки]
, cast(format([Заем выдан] , 'yyyy-MM-01') as date)     [Месяц займа]
, cast(format([Заем выдан] , 'yyyy-MM-dd') as date)     [День займа]
, isnull( cast(format([Заем выдан] , 'yyyy-MM-01') as date), cast(format([Верификация КЦ] , 'yyyy-MM-01') as date))  [Месяц займа заявки]
, b.[CPA трафик в МП источник]
, a.returnType3 [Вид займа]
, a.productType2 productType

into #base
from v_fa a
left join #lcrm  b on a.Номер=b.UF_ROW_ID
 

where cast( isnull(issued,  call1 ) as date) <> cast( getdate()  as date)  and a.productType in ('pts', 'inst', 'pdl', 'big inst')


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

--select * from #ТратыCPA
--order by 1 desc

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
from #ТратыCPAаллоцируемые a outer apply (select cast(count(*) as float) ЧислоЗаявок from #base b where a.Лидген like  '%'+b.UF_SOURCE+'%' and b.UF_SOURCE <>'' and  b.productType='PTS' and b.[Месяц заявки]=a.[Дата оплаты месяц]) x 
group by лидген,        [Дата оплаты месяц] ,        ЧислоЗаявок ,        [За что платим]


--select * from #ТратыCPAаллоцируемые_по_лидгену_месяцу


--select * from #ТратыCPAаллоцируемые
--where Лидген like '%bankiru%' 
--order by 1


--select * from #ТратыCPAаллоцируемые_по_лидгену_месяцу
--where Лидген like '%bankiru%' 
--order by 2






update b
set b.[Расходы на CPA траты на заявку без заявки] = x.[Аллоцируемые расходы на CPA на одну заявку]
from        #base b
cross apply (select sum([Аллоцируемые расходы на CPA на одну заявку]) [Аллоцируемые расходы на CPA на одну заявку] --top 1 * top 1 *
	from #ТратыCPAаллоцируемые_по_лидгену_месяцу
	x
	where x.Лидген like '%'+b.UF_SOURCE+'%'
		and b.UF_SOURCE <>''
		and b.[Месяц заявки]=x.[Дата оплаты месяц]
		and b.productType='PTS'
and x.[За что платим]='заявку'
	)             x


	  
	  update  b
	  set b.[Расходы на CPA лид] =x.[Аллоцируемые расходы на CPA на одну заявку]

from        #base b
cross apply (select  sum([Аллоцируемые расходы на CPA на одну заявку]) [Аллоцируемые расходы на CPA на одну заявку] --top 1 *
	from #ТратыCPAаллоцируемые_по_лидгену_месяцу
	x
	where x.Лидген like '%'+b.UF_SOURCE+'%'
		and b.UF_SOURCE <>''
		and b.[Месяц заявки]=x.[Дата оплаты месяц]
		and b.productType='PTS'
		and x.[За что платим]='лид'
	)             x


	 

	drop table if exists #clicks_and_other_costs

;
with 		

p as (select *, cast(format(date, 'yyyy-MM-01') as date) m from sale_plan)
, rr as (select m,   sum(case when date <getdate()-1 then ptsSum end)/nullif(sum(ptsSum), 0) rr  from p
group by m


)

--select * from rr
,v AS (
	select 
    r.[Месяц] 											[Месяц] 
,   rr.rr*r.[Прочие расходы CPA ПТС]						    [Прочие CPA ПТС]
,   rr.rr*r.[Прочие расходы CPA Беззалог]						    [Прочие CPA Беззалог]
--,      rr.rr*r.[Клики sravniru ПТС] 					         [Клики sravniru ПТС] 
,   isnull(o.[Клики sravniru ПТС]                             ,   rr.rr*r.[Клики sravniru ПТС] 						)	        [Клики sravniru ПТС] 
,   isnull(o.[Клики Bankiru-ref ПТС]                             ,   rr.rr*r.[Клики Bankiru-ref ПТС] 						)	        [Клики Bankiru-ref ПТС] 
,   isnull(o.[Клики bankiru_businesszaim ПТС]                    ,   rr.rr*r.[Клики bankiru_businesszaim ПТС] 						)	        [Клики bankiru_businesszaim ПТС] 
,   isnull(o.[Клики Bankiru-installment-ref Инстоллмент]         ,   rr.rr*r.[Клики Bankiru-installment-ref Беззалог] 	)	        [Клики Bankiru-installment-ref Беззалог] 
,   isnull(o.[Клики Bankiru-installment-context Инстоллмент]     ,   rr.rr*r.[Клики Bankiru-installment-context Беззалог] 	)	[Клики Bankiru-installment-context Беззалог] 
,   isnull(o.[Клики leadssu-installment-ref Инстоллмент]         ,   rr.rr*r.[Клики leadssu-installment-ref Беззалог] 	    )	[Клики leadssu-installment-ref Беззалог] 
,   isnull(o.[Клики gidfinance-installment-click Инстоллмент]    ,   rr.rr*r.[Клики gidfinance-installment-click Беззалог] 	)	[Клики gidfinance-installment-click Беззалог] 
 

,   rr.rr*r.[МП mobishark ПТС] 								    [МП mobishark ПТС] 
,   rr.rr*r.[МП mobishark_Nozalog Беззалог] 								    [МП mobishark_Nozalog Беззалог] 
,   isnull(o.[МП appska ПТС]     ,   rr.rr*r.[МП appska ПТС]  	)	[МП appska ПТС]  
,   rr.rr*r.[МП appska_Nozalog Беззалог] 					[МП appska_Nozalog Беззалог] 
,   isnull(o.[МП Trafficshark ПТС]     ,   rr.rr*r.[МП Trafficshark ПТС]  	)	[МП Trafficshark ПТС]  
,   rr.rr*r.[МП Trafficshark_Nozalog Беззалог] 				[МП Trafficshark_Nozalog Беззалог] 
,   rr.rr*r.[МП Zenmobile ПТС] 								    [МП Zenmobile ПТС] 
,   rr.rr*r.[МП WhiteLeads ПТС] 								[МП WhiteLeads ПТС] 
,   rr.rr*r.[МП MobUpps ПТС] 									[МП MobUpps ПТС] 
,   rr.rr*r.[МП 2Leads ПТС] 									[МП 2Leads ПТС] 
,   isnull(o.[МП MobZilla ПТС]     ,   rr.rr*r.[МП MobZilla ПТС]  	)	[МП MobZilla ПТС]  
,   rr.rr*r.[МП Huntermob ПТС] 								[МП Huntermob ПТС] 
,   isnull(o.[МП Zorka ПТС]  ,   rr.rr*r.[МП Zorka ПТС]  	)	[МП Zorka ПТС]  
,   rr.rr*r.[Займы psb ПТС]           [Займы psb ПТС]
,   rr.rr*r.[Займы psb Беззалог]	  [Займы psb Беззалог]
,   rr.rr*r.[Займы infoseti ПТС]	  [Займы infoseti ПТС]
,   rr.rr*r.[Займы infoseti Беззалог] [Займы infoseti Беззалог]
,   rr.rr*r.[Займы t-bank ПТС]     [Займы t-bank ПТС]
,   rr.rr*r.[Займы t-bank Беззалог][Займы t-bank Беззалог]
,   rr.rr*r.[Займы psb BIGINST]    [Займы psb BIGINST]



 




--select *
from 
	 

--stg.files.[расходы по месяцам от подразделений_stg] r
dbo.v_costs_by_months r
left join dbo.[Стоимость займа Расходы по кликовым офферам_view]   o on r.[Месяц]=o.[Месяц] 
	left join rr on cast( r.Месяц as date)=rr.m
WHERE r.[Месяц]  IS NOT NULL
--select * from  dbo.[Стоимость займа Расходы по кликовым офферам_view]
)
 
   , unpvt as (
SELECT Месяц, COST_NAME, RUBS  
FROM   
   (SELECT Месяц
      , [Прочие CPA ПТС] 
	  , [Прочие CPA Беззалог] 
      , [Клики sravniru ПТС] 
      , [Клики Bankiru-ref ПТС] 
	  ,[Клики bankiru_businesszaim ПТС] 
	  ,[Клики Bankiru-installment-ref Беззалог] 
	  ,[Клики Bankiru-installment-context Беззалог] 
	  ,[Клики leadssu-installment-ref Беззалог] 
	  ,[Клики gidfinance-installment-click Беззалог]
	  ,[МП mobishark ПТС] 
	  ,[МП mobishark_Nozalog Беззалог] 
	  ,[МП appska ПТС] 
	  ,[МП appska_Nozalog Беззалог] 
	  ,[МП Trafficshark ПТС] 
	  ,[МП Trafficshark_Nozalog Беззалог] 
	  ,[МП Zenmobile ПТС] 
	  ,[МП WhiteLeads ПТС] 
	  ,[МП MobUpps ПТС] 
	  ,[МП 2Leads ПТС] 
	  ,[МП MobZilla ПТС] 
	  ,[МП Huntermob ПТС] 
	  ,[МП Zorka ПТС] 
	  	  , [Займы psb ПТС]
	  , [Займы psb Беззалог]
	  , [Займы infoseti ПТС]
	  , [Займы infoseti Беззалог]
	 , [Займы t-bank ПТС]
	 , [Займы t-bank Беззалог]
	 , [Займы psb BIGINST]
   FROM V) p  
UNPIVOT  
   (RUBS FOR COST_NAME IN   
      (
	   [Прочие CPA ПТС] 				 
	  ,[Прочие CPA Беззалог] 
	  ,[Клики sravniru ПТС] 
	  ,[Клики Bankiru-ref ПТС] 
	  ,[Клики bankiru_businesszaim ПТС] 
	  ,[Клики Bankiru-installment-ref Беззалог] 
	  ,[Клики Bankiru-installment-context Беззалог] 
	  ,[Клики leadssu-installment-ref Беззалог] 
	  ,[Клики gidfinance-installment-click Беззалог]
	  ,[МП mobishark ПТС] 
	  ,[МП mobishark_Nozalog Беззалог] 
	  ,[МП appska ПТС] 
	  ,[МП appska_Nozalog Беззалог] 
	  ,[МП Trafficshark ПТС] 
	  ,[МП Trafficshark_Nozalog Беззалог] 
	  ,[МП Zenmobile ПТС] 
	  ,[МП WhiteLeads ПТС] 
	  ,[МП MobUpps ПТС] 
	  ,[МП 2Leads ПТС] 
	  ,[МП MobZilla ПТС] 
	  ,[МП Huntermob ПТС] 
	  ,[МП Zorka ПТС] 


	  , [Займы psb ПТС]
	  , [Займы psb Беззалог]
	  , [Займы infoseti ПТС]
	  , [Займы infoseti Беззалог]
	 , [Займы t-bank ПТС]
	 , [Займы t-bank Беззалог]
	 , [Займы psb BIGINST]
	  
	  )  
)AS unpvt

)
select Месяц, COST_NAME, Rubs
, REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 1))  TYPE
, REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 2))  SOURCE
, case REVERSE(PARSENAME(REPLACE(REVERSE(COST_NAME), ' ', '.'), 3))  when 'ПТС' then 'PTS' when  'Беззалог' then 'BEZZALOG' when 'BIGINST' then 'BIG INST'   end 	 producttype
  into #clicks_and_other_costs
from unpvt
where RUBS>0


--select * from #clicks_and_other_costs
--order by 1 desc




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
					select a.Номер, 'МП' type, a.[Месяц займа заявки], productType, [CPA трафик в МП источник] source from #base	 a where [Группа каналов]='cpa' 
					and isnull(UF_SOURCE, '') not like 'tpokupki%'
					and isnull(UF_SOURCE, '') not like 'infoseti%'
					and isnull(UF_SOURCE, '') not like 'psb%'
					union all 

					select a.Номер, 'Займы' type, a.[Месяц займа заявки], productType, case 
					when  isnull(UF_SOURCE, '')   like 'tpokupki%' then 't-bank' 
					when  isnull(UF_SOURCE, '')   like 'infoseti%' then 'infoseti' 
					when  isnull(UF_SOURCE, '')   like 'psb%' then 'psb' end
					source from #base	 a where  
					(   isnull(UF_SOURCE, '')   like 'infoseti%'
					or isnull(UF_SOURCE, '')   like 'psb%'
					or isnull(UF_SOURCE, '')   like 'tpokupki%'
					)
					and [Месяц займа] is not null 
					
					
					
					union all 



					select b.Номер, 'Клики' type, b.[Месяц займа заявки], b.productType, b.uf_source source    from #base	  b	
						join (
						select Дата, 'PTS' productType, 'sravniru'                      uf_source from stg.files.[расходы по кликовым офферам] where [Клики sravniru ПТС] >0			    union all
						select Дата, 'PTS'  , 'bankiru-ref'                   uf_source from stg.files.[расходы по кликовым офферам] where [Клики bankiru-ref ПТС] >0			    union all
						select Дата, 'PTS'  , 'bankiru_businesszaim'          from stg.files.[расходы по кликовым офферам] where [Клики bankiru_businesszaim ПТС] >0			    union all
						select Дата, 'BEZZALOG'  , 'bankiru-installment-ref'       from stg.files.[расходы по кликовым офферам] where [Клики bankiru-installment-ref Инстоллмент] >0  union all
						select Дата, 'BEZZALOG'  , 'bankiru-installment-context'   from stg.files.[расходы по кликовым офферам] where [Клики bankiru-installment-context Инстоллмент] >0  union all
						select Дата, 'BEZZALOG'  , 'leadssu-installment-ref'       from stg.files.[расходы по кликовым офферам] where [Клики leadssu-installment-ref Инстоллмент] >0  union all
						select Дата, 'BEZZALOG'  , 'gidfinance-installment-click'  from stg.files.[расходы по кликовым офферам] where [Клики gidfinance-installment-click Инстоллмент] >0  union all
						select Дата, 'BEZZALOG'  , 'gidfinance-installment-click'  from stg.files.[расходы по кликовым офферам] where [Клики gidfinance-installment-click Инстоллмент] >0 
							) a on b.[День займа] = a.Дата and 	   a.productType=b.productType and 	 a.uf_source=b.uf_source 
							where isnull(b.UF_SOURCE, '') not like 'infoseti%'
					and isnull(b.UF_SOURCE, '') not like 'psb%'
					and isnull(b.UF_SOURCE, '') not like 'tpokupki%'
					
					
					) b on a.TYPE=b.TYPE and 	a.producttype=b.producttype and a.Месяц=b.[Месяц займа заявки]	 and a.source=b.source
left join 
(
					select Номер, 'CPA' type, [Месяц займа заявки], productType, 'CPA' source, 1 [Заявок] from #base	 a where [Группа каналов]='cpa'	and [Месяц займа] is not null 
					and isnull(UF_SOURCE, '') not like 'infoseti%'
					and isnull(UF_SOURCE, '') not like 'psb%'
					and isnull(UF_SOURCE, '') not like 'tpokupki%'
) c on b.Номер is null and c.productType=	a.productType and a.Месяц=c.[Месяц займа заявки]
 --order by 1, 2



 drop table if exists #clicks_and_other_costs3
 SELECT Номер  
      ,sum(case when COST_NAME = 'Прочие CPA ПТС' 					                   then Распределение end )   [Прочие CPA ПТС] 					               
      ,sum(case when COST_NAME = 'Прочие CPA Беззалог' 					   then Распределение end )   [Прочие CPA Инстоллмент] 					               
	  ,sum(case when COST_NAME = 'Клики sravniru ПТС' 							   then Распределение end )   [Клики sravniru ПТС] 							   
	  ,sum(case when COST_NAME = 'Клики Bankiru-ref ПТС' 							   then Распределение end )   [Клики Bankiru-ref ПТС] 							   
	  ,sum(case when COST_NAME = 'Клики bankiru_businesszaim ПТС' 					   then Распределение end )   [Клики bankiru_businesszaim ПТС] 							   
	  ,sum(case when COST_NAME = 'Клики Bankiru-installment-ref Беззалог' 		   then Распределение end )   [Клики Bankiru-installment-ref Инстоллмент] 		   
	  ,sum(case when COST_NAME = 'Клики bankiru-installment-context Беззалог' 	   then Распределение end )   [Клики bankiru-installment-context Инстоллмент] 	   
	  ,sum(case when COST_NAME = 'Клики leadssu-installment-ref Беззалог' 		   then Распределение end )   [Клики leadssu-installment-ref Инстоллмент] 		   
	  ,sum(case when COST_NAME = 'Клики gidfinance-installment-click Беззалог'	   then Распределение end )   [Клики gidfinance-installment-click Инстоллмент]	   
	  ,sum(case when COST_NAME = 'МП mobishark ПТС' 								   then Распределение end )   [МП mobishark ПТС] 								   
	  ,sum(case when COST_NAME = 'МП mobishark_Nozalog Беззалог' 				   then Распределение end )   [МП mobishark_Nozalog Инстоллмент] 								   
	  ,sum(case when COST_NAME = 'МП appska ПТС' 									   then Распределение end )   [МП appska ПТС] 									   
	  ,sum(case when COST_NAME = 'МП appska_Nozalog Беззалог' 					   then Распределение end )   [МП appska_Nozalog Инстоллмент] 					   
	  ,sum(case when COST_NAME = 'МП Trafficshark ПТС' 							       then Распределение end )   [МП Trafficshark ПТС] 							   
	  ,sum(case when COST_NAME = 'МП Trafficshark_Nozalog Беззалог' 			       then Распределение end )   [МП Trafficshark_Nozalog Инстоллмент] 			   
	  ,sum(case when COST_NAME = 'МП Zenmobile ПТС' 								   then Распределение end )   [МП Zenmobile ПТС] 								   
	  ,sum(case when COST_NAME = 'МП WhiteLeads ПТС' 								   then Распределение end )   [МП WhiteLeads ПТС] 								   
	  ,sum(case when COST_NAME = 'МП MobUpps ПТС' 								       then Распределение end )   [МП MobUpps ПТС] 								   
	  ,sum(case when COST_NAME = 'МП 2Leads ПТС' 									   then Распределение end )   [МП 2Leads ПТС] 									   
	  ,sum(case when COST_NAME = 'МП MobZilla ПТС'   							       then Распределение end )   [МП MobZilla ПТС]   							   
	  ,sum(case when COST_NAME = 'МП Huntermob ПТС'   							       then Распределение end )   [МП Huntermob ПТС]   							   
	  ,sum(case when COST_NAME = 'МП Zorka ПТС'   							           then Распределение end )   [МП Zorka ПТС]   							   
	  ,sum(case when COST_NAME = 'Займы psb BIGINST'   							           then Распределение end )               [Займы psb BIGINST]   							   
	  ,sum(case when COST_NAME = 'Займы psb ПТС'   							           then Распределение end )               [Займы psb ПТС]   							   
	  ,sum(case when COST_NAME = 'Займы psb Беззалог'   							           then Распределение end )       [Займы psb Беззалог]   							   
	  ,sum(case when COST_NAME = 'Займы infoseti ПТС'   							           then Распределение end )       [Займы infoseti ПТС]   							   
	  ,sum(case when COST_NAME = 'Займы infoseti Беззалог'   							           then Распределение end )   [Займы infoseti Беззалог]   							   
	  ,sum(case when COST_NAME = 'Займы t-bank Беззалог'   							           then Распределение end )   [Займы t-bank Беззалог]   							   
	  ,sum(case when COST_NAME = 'Займы t-bank ПТС'   							           then Распределение end )       [Займы t-bank ПТС]   							   


 

	   into #clicks_and_other_costs3
FROM #clicks_and_other_costs2  
group by  Номер

;

--select * from #clicks_and_other_costs2
--ord


  drop table if exists #base2
select 
  a.Номер number
, a.[Группа каналов]
, a.[Канал от источника]
, a.UF_SOURCE
, a.isinstallment
, a.productType
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
 ,[Клики sravniru ПТС] 
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
 , [Займы psb ПТС]   				
 , [Займы psb Беззалог]   	
 , [Займы psb BIGINST]
 , [Займы infoseti ПТС]   			
 , [Займы infoseti Беззалог] 
 , [Займы t-bank ПТС]
 , [Займы t-bank Беззалог]
 
 ,nullif(isnull([Расходы на CPA заявка]   	                        , 0)+
  isnull([Расходы на CPA займ]  							, 0)+
  isnull([Расходы на CPA лид]   							, 0)+
  isnull([Расходы на CPA траты на заявку без заявки]  		, 0)+
  isnull([Прочие CPA ПТС] 									, 0)+
  isnull([Прочие CPA Инстоллмент] 									, 0)+
  isnull([Клики sravniru ПТС] 							, 0)+
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
  isnull([МП Huntermob ПТС]   								, 0)+	  
  isnull([МП Zorka ПТС]   							     	, 0)+	  
  isnull( [Займы psb ПТС]   		  							     	, 0)+	  
  isnull( [Займы psb Беззалог]   	  							     	, 0)+	  
  isnull( [Займы psb BIGINST]   	  							     	, 0)+	  
  isnull( [Займы infoseti ПТС]   	  							     	, 0)+	  
  isnull( [Займы infoseti Беззалог]   							     	, 0)+	  
  isnull( [Займы t-bank ПТС]   							     	, 0)+	  
  isnull( [Займы t-bank Беззалог]   							     	, 0)	
  
 


  , 0)	[Расходы на CPA]
  , [Вид займа]
into #base2
   
from #base a
left join  #clicks_and_other_costs3 b on a.Номер=b.Номер

 --drop table if exists base2
 --select * into  base2 from #base2

 --select top 1000 a.number, a.[Расходы на CPA], b.number from #base2 a
 --left join request_costs_cpa b on a.number=b.number

--	select *   from #base2
--	where [Расходы на CPA]>0
--order by 1 desc


--select * from marketing_cost_lead

--	select *   from #base2 where UF_SOURCE = 'Trafficshark'
--	and [Расходы на CPA]>0
--order by 1 desc
if @recreate = 1
begin

drop table if exists request_costs_cpa
select *  into request_costs_cpa	 from #base2


 return
end


	begin tran 
	delete from request_costs_cpa
	insert into request_costs_cpa
	select *   from #base2 
	
	commit tran

 
