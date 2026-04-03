


CREATE     proc dbo.finance_loan_report

@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin

declare @start_date date = @start_date_ssrs
declare @end_date date = @end_date_ssrs


select  
код
      ,[CRMClientGUID]
      ,[Дата договора]
      ,[Сумма]
,[Адрес проживания CRM]
      ,[Срок]
,[Агент партнер]
,product
,[Сумма комиссионных продуктов снижающих ставку]
      ,[Вид займа]
      ,[Дата выдачи]
      ,[Сумма расторжений по КП]
, [ПСК текущая]
, [ПСК первоначальная]
      ,[Текущая процентная ставка]
      ,[Первая процентная ставка]
 ,канал
,[Признак КП снижающий ставку]

      ,[Сумма комиссионных продуктов]
      ,[Сумма комиссионных продуктов Carmoney]
      ,[Сумма комиссионных продуктов Carmoney Net]
      ,[CP_info]
,[Дата обновления записи по займу]
,case 
     when [Способ оформления займа] in ('Лкк клиента', 'МП') or [Признак ПЭП3]=1 then 1 
	 else 0 
end [Дистанционная выдача]




 from analytics.dbo.mv_loans
 where [Дата Выдачи месяц] between isnull(cast(format(cast(@start_date as date), 'yyyy-MM-01') as date) ,  [Дата Выдачи месяц]) and isnull(cast(format(cast(@end_date as date), 'yyyy-MM-01') as date) ,  [Дата Выдачи месяц])

 end
