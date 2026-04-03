
CREATE
  proc [dbo].[Подготовка отчета по заявкам лидгенов для оплаты]
as
begin
declare @month date = dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01')  as date))

--select @month

drop table if exists #t1

;

with v  as (
select 	 --top 100
  b.ID [LCRM ID]
, b.UF_CLID [CRIB лид ID]
, b.UF_TYPE [Тип]
, b.UF_TYPE_SHADOW [Тип (теневой)]
, b.UF_SOURCE [Источник]
, b.UF_SOURCE_SHADOW [Источник (теневой)]
, b.UF_CLB_TYPE [Канал - подтип]
, b.PhoneNumber [Телефон]
, b.UF_PHONE_ADD [Телефон доп.]
, a.Номер [Номер заявки]
, cast( b.UF_REGISTERED_AT as smalldatetime)  [Дата создания]
, cast(a.ДатаЗаявкиПолная as smalldatetime) [Дата актуализации (Дата Заявки)] 
, b.UF_PARTNER_ID [ID партнера]
, null [ID клика партнера]
, a.[Выданная сумма]  [Одобренная сумма займа (Выданная сумма)]
, b.UF_SUM_LOAN  [Желаемая сумма займа]
, cast(a.[Заем выдан] as smalldatetime) [Дата выдачи займа]
, null [Заявка - Статус Новый]
, b.UF_FULL_FORM_LEAD [Создан как заявка?]
, b.UF_REGIONS_COMPOSITE  [Регион (итоговый)]
, b.UF_STEP  [Шаг подтверждения]
, null [Комментарий]
, case when a.isinstallment =1 then 1 else 0 end [Заявка инстоллмент]
, a.Дата [День Заявки]
, cast(a.[Заем выдан] as date) [День выдачи займа]
, b.UF_REGISTERED_AT_date [День создания]
, case when a.[Группа каналов] in ('Партнеры', 'Банки')  then 1 else  0 end as [Оплата за привлечение по партнерскому каналу]
, isnull(a.[Группа каналов] , b.[Группа каналов])  [Группа каналов]
, isnull(a.[Канал от источника] , b.[Канал от источника])  [Канал от источника]
--,  sz.[Партнеры привлечение]
, a.[ВИд займа]
, cpa2.Стоимость   Стоимость_Расчетная_Для_Сверки
, cast(a.[Заем погашен] as smalldatetime) [Заем погашен]

from  reports.dbo.dm_factor_analysis_001 a  
join stg.[_LCRM].[lcrm_leads_full_channel_request] b on a.Номер=b.UF_ROW_ID
--left join Analytics.dbo.[v_Отчет стоимость займа опер] sz on sz.Номер=a.Номер
--left join Analytics.dbo.[Отчет аллоцированные расходы CPA] cpa on cpa.Номер=a.Номер
left join [dbo].[dm_report_lcrm_cpa_cpc_costs] cpa2 on cpa2.UF_ROW_ID=a.Номер
where   ( cast(format(  a.ДатаЗаявкиПолная , 'yyyy-MM-01')  as date)=@month or   cast(format(a.[Заем выдан], 'yyyy-MM-01')  as date) =@month)
 
)

select * into #t1 from v 


;with v  as (select *, row_number() over(partition by [Номер заявки] order by [LCRM ID]) rn from #t1 ) delete from v where rn>1


select a.*, x.[Номер заявки] [Номер заявки ПТС тот же лидген] , x.Источник [Источник заявки ПТС тот же лидген], GETDATE() ДатаОтчета from #t1 a
outer apply (select top 1 [Номер заявки], Источник from #t1 b where a.[Заявка инстоллмент]=1 and a.[День выдачи займа] is not null and b.[Заявка инстоллмент]=0 and b.Телефон=a.Телефон 
and 
b.Источник<>''
and 
a.Источник<>''
and 
(
a.Источник like '%'+b.Источник+'%' or
b.Источник like '%'+a.Источник+'%'  )

) x
--where a.[Заявка инстоллмент]=1 and [День выдачи займа] is not null


end