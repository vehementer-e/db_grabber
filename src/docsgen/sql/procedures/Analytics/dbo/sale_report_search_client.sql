CREATE  proc		[dbo].sale_report_search_client
@string nvarchar(max) = '',
@mode nvarchar(max) = '' --,
--@matched_id  nvarchar(36) output
as
 
declare @id nvarchar(36)





if @mode = 'dt'
begin

select top 1 [Дата обновления записи по займу] from analytics.dbo.report_loans

end


if @mode = 'balance'
begin



declare @external_id2 nvarchar(36) = @string
declare @CRMClientGUID2 nvarchar(100) = (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  код=@external_id2)											   
																																										 
set @CRMClientGUID2  = isnull(@CRMClientGUID2,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [CRMClientGUID]=@external_id2))						   
																																										 
set @CRMClientGUID2  = isnull(@CRMClientGUID2,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [Основной телефон клиента CRM]=@external_id2))		   
																																										 
set @CRMClientGUID2  = isnull(@CRMClientGUID2,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [Телефон договор CMR]=@external_id2))					 
																																										 
set @CRMClientGUID2  = isnull(@CRMClientGUID2,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  Фамилия+' '+Имя+' '+Отчество=@external_id2))			   
																																										 
set @CRMClientGUID2  = isnull(@CRMClientGUID2,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  CAST([id клиента Спейс] AS VARCHAR(50))=@external_id2)) 
 


 drop table if exists #l
 select код код_ into #l from analytics.dbo.v_loans where CRMClientGUID=@CRMClientGUID2


 select  top 100000  d,  код , клиент, [остаток од], [остаток всего], dpd, [dpd начало дня] 


   ,[сумма поступлений]
      ,[ПлатежнаяСистема]
      ,[сумма поступлений  нарастающим итогом] 
	  from analytics.dbo.v_balance a with(nolock) join #l b on a.Код=b.код_
	  




 end


if @mode = 'loan'
begin


declare @external_id1 nvarchar(36) = @string
declare @CRMClientGUID1 nvarchar(100) = (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  код=@external_id1)											   
																																										 
set @CRMClientGUID1  = isnull(@CRMClientGUID1,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [CRMClientGUID]=@external_id1))						   
																																										 
set @CRMClientGUID1  = isnull(@CRMClientGUID1,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [Основной телефон клиента CRM]=@external_id1))		   
																																										 
set @CRMClientGUID1  = isnull(@CRMClientGUID1,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  [Телефон договор CMR]=@external_id1))					 
																																										 
set @CRMClientGUID1  = isnull(@CRMClientGUID1,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  Фамилия+' '+Имя+' '+Отчество=@external_id1))			   
																																										 
set @CRMClientGUID1  = isnull(@CRMClientGUID1,  (select top 1 [CRMClientGUID]  from analytics.dbo.v_loans where  CAST([id клиента Спейс] AS VARCHAR(50))=@external_id1)) 



SELECT            [Ссылка договор CMR]
,                 [код]
, [url Спейс]
,                 [CRMClientGUID]
,                 [Фамилия]+' '+[Имя]+' '+[Отчество] ФИО
,                 [Дата договора]
,                 [Вид займа]
,                 [Дата договора месяц]
,                 [Сумма]
,                 [Сумма клиенту на руки]
,                 [Срок]
,                 [product]
,                 [Канал]
,                 [Повторность займа]
,                 [Признак погашен]
,                 [Сумма комиссионных продуктов]
,                 [Сумма комиссионных продуктов Carmoney]
,                 [Сумма комиссионных продуктов Carmoney Net]
,[Сумма комиссионных продуктов Carmoney Net cash]
,                 [Признак КП снижающий ставку]
,                 [Текущая процентная ставка]
,                 [Дата выдачи]
,                 [Дата погашения]
,                 [Дата следующего платежа]
,                 [Сумма следующего платежа]
,                 [Срок жизни займа]
,                 [Срок жизни займа полные месяцы]
,                 [ПДП 30 дней]
,                 [Расходы на выдачу конкретного займа]
,                 [Признак стоимость займа]
,                 [Признак расторжение КП]
,                 [Сумма расторжений по КП]
,                 [Проценты уплачено итого]
,                 [Сумма поступлений итого]
,                 [Основной долг уплачено итого]
,                 [Дата займ впервые прибыльный]
,                 [Через сколько дней займ стал прибыльным]
,                 [Текущая прибыль] 
      ,[Прибыль комиссия при платеже]
      ,[Прибыль от дополнительных комиссий]
,                 [Признак прибыльный займ]
,                 [Признак клиент прибыльный на момент выдачи отчетного займа]
,                 [Прибыль по клиенту к дате выдачи отчетного займа]
,                 [Текущая прибыль по клиенту]
,                 [Фондирование итого]
,                 [Дата первого заявления на ЧДП]   
,                 [Дата последнего заявления на ЧДП]
,                 [Заявлений на ЧДП]  



,      [Дата начала КК]   
,      [Дата окончания КК]
,      [Текущие КК]       
,      [Предоставлены КК] 

, [Пользовался МП]
, [Текущая просрочка]
, [Максимальная просрочка]
, cp_info
, comissions_info
,                 [Дата обновления записи по займу]
FROM analytics.[dbo].v_loans 

where CRMClientGUID=@CRMClientGUID1


end


if @mode = 'get_id'
begin



 select 1

--select @CRMClientGUID

end
