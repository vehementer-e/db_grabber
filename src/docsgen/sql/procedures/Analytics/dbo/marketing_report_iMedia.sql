 
CREATE   proc [dbo].[marketing_report_iMedia]
@mode nvarchar(max)	  = 'run'
as
begin

if @mode='csv'
begin

set nocount on






drop table if exists #t1
SELECT 
     a.number 
	,cast(a.[Заем выдан] as date)  [Заем выдан дата]
	,a.[Выданная сумма]
	,a.productType Продукт
	,a.[Регион проживания]
	,isnull( b.UF_STAT_CAMPAIGN	   , b1.UF_STAT_CAMPAIGN	)  STAT_CAMPAIGN
	,isnull( b.UF_APPMECA_TRACKER  , b1.UF_APPMECA_TRACKER	)  APPMETRICA
	,isnull( b.UF_STAT_SOURCE	   , b1.UF_STAT_SOURCE		)  STAT_SOURCE
	,isnull( b.UF_STAT_AD_TYPE	   , b1.UF_STAT_AD_TYPE		)  STAT_AD_TYPE	
	,isnull(  b. UF_STAT_SYSTEM	   , b1. STAT_SYSTEM		)  STAT_SYSTEM
	,isnull(  b.UF_STAT_TERM	   , b1.STAT_TERM		    )  STAT_TERM
	,isnull(  b. UF_CLB_CHANNEL	   , ''	)						UF_CLB_CHANNEL
	,b1.STAT_INFO					STAT_INFO
	,a.[Стоимость ТС]
	,c.[Марка тс]
	,c.[Модель тс]
	,c.[Год тс]
	, a.call1 [call1]
	, a.call1approved [call1 одобрено]
	, a.checking [контроль данных]
	, a.approved [одобрено]
	, a.declined [отказано]
	, a.источник
	, lower(a.marketing_lead_id) leadId
	into #t1
FROM v_fa a
left join v_lead2 b1 with(nolock) on a.marketing_lead_id=b1.id
LEFT JOIN _lcrm_requests b with(nolock) ON a.[LCRM ID] = b.id  and 1=0
left join mv_loans c on c.код=a.Номер
WHERE a.[Группа каналов] = 'CPC'
	AND a.call1  >= '20250301'

	insert into #t1 

SELECT 
     a.number 
	,cast(a.[Заем выдан] as date)  [Заем выдан дата]
	,a.[Выданная сумма]
	,a.productType Продукт
	,a.[Регион проживания]
	,isnull( b.UF_STAT_CAMPAIGN	   , b1.UF_STAT_CAMPAIGN	)  STAT_CAMPAIGN
	,isnull( b.UF_APPMECA_TRACKER  , b1.UF_APPMECA_TRACKER	)  APPMETRICA
	,isnull( b.UF_STAT_SOURCE	   , b1.UF_STAT_SOURCE		)  STAT_SOURCE
	,isnull( b.UF_STAT_AD_TYPE	   , b1.UF_STAT_AD_TYPE		)  STAT_AD_TYPE	
	,isnull(  b. UF_STAT_SYSTEM	   , b1. STAT_SYSTEM		)  STAT_SYSTEM
	,isnull(  b.UF_STAT_TERM	   , b1.STAT_TERM		    )  STAT_TERM
	,isnull(  b. UF_CLB_CHANNEL	   , ''	)						UF_CLB_CHANNEL
	,b1.STAT_INFO					STAT_INFO
	,a.[Стоимость ТС]
	,c.[Марка тс]
	,c.[Модель тс]
	,c.[Год тс]
	, a.call1 [call1]
	, a.call1approved [call1 одобрено]
	, a.checking [контроль данных]
	, a.approved [одобрено]
	, a.declined [отказано]
	, a.источник 
	, lower(a.marketing_lead_id) leadId

 FROM v_fa a
left join v_lead2 b1 with(nolock) on a.marketing_lead_id=b1.id
LEFT JOIN _lcrm_requests b with(nolock) ON a.[LCRM ID] = b.id and 1=0
left join mv_loans c on c.код=a.Номер
WHERE a.источник = 'ptsoff'
	AND a.call1  >= '20250301'

	select * from #t1
	order by isnull([Заем выдан дата] , [call1] ) desc,  4 

end


if @mode = 'text'

begin


drop table if exists #ww
drop table if exists #rr
--declare @report_date date = '20221201'
declare @report_date date = getdate()-1
declare @report_month date = cast(format(@report_date, 'yyyy-MM-01') as date)



select cast(date as date) Дата
, cast(format(date, 'yyyy-MM-01') as date) Месяц, ptsSum/nullif((sum(ptsSum) over(partition by cast(format(date, 'yyyy-MM-01') as date))+0.0), 0) [weight of day]
into #ww
from  sale_plan
 select sum([weight of day]) rr into #rr from #ww
where Месяц=@report_month and Дата<=@report_date



--declare @report_date date = getdate()-1

select 
--  sum([Выданная сумма])/(select * from #rr) [Выданная сумма_rr]  
--, sum([Выданная сумма]) [Выданная сумма]
--, avg([Выданная сумма]) Чек
--, count([Выданная сумма]) Количество
--,
text = 
N'📅 <b>'+format(@report_date, 'dd-MMM') +' </b>'+char(10)
+N'ℹ️ <b>CPC: </b>'+char(10)
+'RR: '+format(isnull(sum([Выданная сумма])/(select * from #rr), 0), '0')+' руб.' +char(10)
+'Сумма: '+format(isnull(sum([Выданная сумма]) , 0), '0')+' руб.'+char(10)
+'Чек: '+format(isnull(avg([Выданная сумма]) , 0), '0')+' руб.'+char(10)
+'Кол-во: '+format(isnull(count([Выданная сумма]), 0), '0')+' шт.'+char(10)

from v_fa
where [Группа каналов] ='CPC' 
and productType='pts' and
cast([Заем выдан] as date) <=@report_date  and 
cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = @report_month




end


if @mode = 'chat_id'
begin

--select -420003757
select -680908051	 --prod

end


		if @mode='run'
exec python 'marketing_report_iMedia(debug=0)'   , 1



	end



