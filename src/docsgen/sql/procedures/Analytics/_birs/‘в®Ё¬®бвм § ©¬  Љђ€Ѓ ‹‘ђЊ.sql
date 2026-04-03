CREATE   proc [_birs].[Стоимость займа КРИБ ЛСРМ]  @mode nvarchar(max) ='CPA'
as
begin
   

if @mode='CPA'
begin

	select 
    a.[id] 
,   a.[Канал от источника] 
,   a.[UF_SOURCE] 
,   a.[UF_TYPE] 
,   a.[UF_ROW_ID] 
,   a.[isInstallment] 
,   a.[ПолнаяЗаявка] 
,   a.[ЗаявкаAPI] 
,   a.[ЗаявкаAPI_или_API2] 
,   a.[ЗаявкаAPI2] 
,   a.[ЛидAPI_или_API2] 
,   a.[Лид_Дубль] 
,   a.[ДеньЛида] 
,   a.[МесяцЛида] 
,   a.[ДеньЗаявки] 
,   a.[МесяцЗаявки] 
,   a.[ДеньЗайма] 
,   a.[МесяцЗайма] 
,   a.[СуммаЗайма] 
,   a.[Регион] 
,   a.[json_cost_params] 
,   a.[Стоимость] 	
+ isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0)  [Стоимость]
,   a.[ЗаЧтоПлатим] 	+ case when  -- a.[ЗаЧтоПлатим] <>'Клик' and 

 isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0) 
>0 then '+Распределены клики'	 else '' end  [ЗаЧтоПлатим]

,   a.[МесяцОплаты] 
,   a.[created] 
,   a.[ПодлежитОплате] 
,   a.[UF_PARTNER_ID] 
,   case when b.[Вид займа]<>'Первичный' then 	'Повторный'  else 	'Первичный'  end 	[Вид займа]
, isnull(isnull(isnull(a.МесяцОплаты, a.МесяцЗайма), a.МесяцЗаявки), a.МесяцЛида)  Месяц
, type = 'ALL CRIB'

from 

Analytics.dbo.[Стоимость займа лиды с расчетной стоимостью Криб2] a
left join reports.dbo.dm_factor_analysis_001 b on a.[UF_ROW_ID]=b.Номер
left join Analytics.dbo.[Стоимость займа Распределенные расходы CPA] c on c.Номер=a.UF_ROW_ID
   --exec select_table'Analytics.dbo.[Стоимость займа лиды с расчетной стоимостью Криб]'
																								
	union all																							
																								

select 
    a.[id] 
,   a.[Канал от источника] 
,   a.[UF_SOURCE] 
,   a.[UF_TYPE] 
,   a.[UF_ROW_ID] 
,   a.[isInstallment] 
,   a.[ПолнаяЗаявка] 
,   a.[ЗаявкаAPI] 
,   a.[ЗаявкаAPI_или_API2] 
,   a.[ЗаявкаAPI2] 
,   a.[ЛидAPI_или_API2] 
,   a.[Лид_Дубль] 
,   a.[ДеньЛида] 
,   a.[МесяцЛида] 
,   a.[ДеньЗаявки] 
,   a.[МесяцЗаявки] 
,   a.[ДеньЗайма] 
,   a.[МесяцЗайма] 
,   a.[СуммаЗайма] 
,   a.[Регион] 
,   a.[json_cost_params] 
,   a.[Стоимость] 	
+ isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0)  [Стоимость]
,   a.[ЗаЧтоПлатим] 	+ case when --  a.[ЗаЧтоПлатим] <>'Клик' and 

 isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0) 
>0 then '+Распределены клики'	 else '' end  [ЗаЧтоПлатим]


,   a.[МесяцОплаты] 
,   a.[created] 
,   a.[ПодлежитОплате] 
,   a.[UF_PARTNER_ID] 
,   case when b.[Вид займа]<>'Первичный' then 	'Повторный'  else 	'Первичный'  end 	[Вид займа]
, isnull(isnull(isnull(a.МесяцОплаты, a.МесяцЗайма), a.МесяцЗаявки), a.МесяцЛида)  Месяц
, type = 'ПОСТБЭКИ + ЛСРМ АПИ'

from 

Analytics.dbo.[Стоимость займа лиды с расчетной стоимостью Криб] a
left join reports.dbo.dm_factor_analysis_001 b on a.[UF_ROW_ID]=b.Номер
left join request_costs_cpa c on c.number=a.UF_ROW_ID
   --exec select_table'Analytics.dbo.[Стоимость займа лиды с расчетной стоимостью Криб]'


union all

	select 
    a.[id] 
,   a.[Канал от источника] 
,   a.[UF_SOURCE] 
,   a.[UF_TYPE] 
,   a.[UF_ROW_ID] 
,   a.[isInstallment] 
,   a.[ПолнаяЗаявка] 
,   a.[ЗаявкаAPI] 
,   a.[ЗаявкаAPI_или_API2] 
,   a.[ЗаявкаAPI2] 
,   a.[ЛидAPI_или_API2] 
,   a.[Лид_Дубль] 
,   a.[ДеньЛида] 
,   a.[МесяцЛида] 
,   a.[ДеньЗаявки] 
,   a.[МесяцЗаявки] 
,   a.[ДеньЗайма] 
,   a.[МесяцЗайма] 
,   a.[СуммаЗайма] 
,   a.[Регион] 
,   a.[json_cost_params] 
,   a.[Стоимость] 	
+ isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0)  [Стоимость]
,   a.[ЗаЧтоПлатим] 	+ case when  -- a.[ЗаЧтоПлатим] <>'Клик' and 

 isnull(c.[Клики bankiru_businesszaim ПТС], 0)
+ isnull(c.[Клики bankiru-installment-context Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-installment-ref Инстоллмент], 0)
+ isnull(c.[Клики Bankiru-ref ПТС], 0)
+ isnull(c.[Клики gidfinance-installment-click Инстоллмент], 0)
+ isnull(c.[Клики leadssu-installment-ref Инстоллмент], 0) 
>0 then '+Распределены клики'	 else '' end  [ЗаЧтоПлатим]

,   a.[МесяцОплаты] 
,   a.[created] 
,   a.[ПодлежитОплате] 
,   a.[UF_PARTNER_ID] 
,   case when b.[Вид займа]<>'Первичный' then 	'Повторный'  else 	'Первичный'  end 	[Вид займа]
, isnull(isnull(isnull(a.МесяцОплаты, a.МесяцЗайма), a.МесяцЗаявки), a.МесяцЛида)  Месяц
, type = 'ЛСРМ (как раньше)'

from 

Analytics.dbo.dm_report_lcrm_cpa_cpc_costs a
left join reports.dbo.dm_factor_analysis_001 b on a.[UF_ROW_ID]=b.Номер
left join request_costs_cpa c on c.number=a.UF_ROW_ID

   --exec select_table'Analytics.dbo.[Стоимость займа лиды с расчетной стоимостью Криб]'




   end

   



end