CREATE   proc [dbo].[logistics]
	   @mode nvarchar(max)	,
	   @external_id nvarchar(max) =''	,
	   @author nvarchar(max) =''	,
	   @approved_date_start date = null,
	   @request_date_start  date = null--,
as

begin
SET FMTONLY OFF

if @mode = 'insert'
begin
 	 
if isnull(@external_id, '') = '' or isnumeric(@external_id)=0
begin
select 'обновление заявки не проведено' result
return
end

if isnull(@external_id, '') <> ''
begin
begin tran
--delete from  [Reports].[ssrsRW].[dm_report_logistics_history] where external_id='23'
insert into [Reports].[ssrsRW].[dm_report_logistics_history]
select @external_id as external_id, cast( null as nvarchar(max)) comments, getdate() as created ,@author author

select 'проведено добавление заявки
'+@external_id result

commit tran
end
end







if @mode = 'unprocessed'
begin


 
drop table if exists #t1  


  select fa.Номер

,fa.ДатаЗаявкиПолная
, fa.ФИО
,case when fa.[Заем выдан] >=cast(format(getdate(), 'yyyy-MM-01') as date) then 1 else 0 end as Urgent_task
,fa.Одобрено  Одобрено
from v_fa fa  with(nolock)
 left join  [Reports].[ssrsRW].[dm_report_logistics_history] c on fa.Номер=c.external_id
 where c.external_id is null and 
 (
 (
 ( fa.Одобрено>=@approved_date_start  ) and fa.ДатаЗаявкиПолная>=@request_date_start
 )
 or 
 fa.[Заем выдан] >=cast(format(getdate(), 'yyyy-MM-01') as date)
 ) and  fa.[Место создания 2]  ='МП'

 end



 
	 if @mode = 'details'
	 begin
												   
SELECT log_req.[external_id]
	,log_req.[comments]
	,log_req.[created]
	,log_req.[author]
	,users.Наименование AS ФиоЛогиста
	,fa.Партнер
	,fa.[Текущий статус] [Текущий статус]
	,CASE 
		WHEN fa.[Текущий статус]
in
(
'Одобрено'
,'Договор зарегистрирован'
,'Назначение встречи'
,'Встреча назначена'
,'Контроль подписания договора'
,'Договор подписан'
,'Контроль получения ДС'
,'Забраковано'
,'Клиент передумал'
,'Заем аннулирован'

)
then
 fa.[Текущий статус]
when 
 fa.[Текущий статус]
in
(
'Заем погашен'
,'Проблемный'
,'Заем выдан'
,'Платеж опаздывает'
,'Оценка качества'
)
then 
'Заем выдан'
	

else
'Другой Статус' end Текущий_статус_эксперты
,
fa.[Выданная сумма] [Выданная сумма],
cast(fa.[Заем выдан] as date) [Заем выдан],
fa.[Сумма одобренная],
fa.Одобрено,
fa.[Процентная ставка] ПроцСтавкаКредит
      ,fa.[Признак Комиссионный Продукт] [ПризнакКП]

      ,nullif(cast(fa.[Сумма страхование жизни Carmoney Net]        as bigint)  , 0) [SumEnsurCarmoneyNet]         
      ,nullif(cast(fa.[Сумма РАТ Carmoney Net]			 as bigint) , 0) [SumRatCarmoneyNet]			 
      ,nullif(cast(fa.[Сумма КАСКО Carmoney Net]		 as bigint) , 0) [SumKaskoCarmoneyNet]		 
--      ,nullif(cast(fa.[SumPositiveMood] as bigint) 	 , 0) [SumPositiveMood]	 
      ,nullif(cast(fa.[Сумма Помощь бизнесу Carmoney Net] as bigint) 	 , 0) [SumHelpBusinessCarmoneyNet]	 
      ,nullif(cast(fa.[Сумма Телемедицина Carmoney Net]    as bigint) 	 , 0) [SumTeleMedicCarmoneyNet]   	 
      ,nullif(cast(fa.[Сумма Защита от потери работы Carmoney Net]		 as bigint) , 0) [SumCushionCarmoneyNet]		 
      ,nullif(cast(fa.[Сумма Фарма Carmoney Net]		 as bigint) , 0) [SumPharmaCarmoneyNet]		 
      ,nullif(cast(fa.[Сумма Спокойная жизнь Carmoney Net]		 as bigint) , 0) [SumQuietLifeCarmoneyNet]		 
,fa.[Сумма Дополнительных Услуг Carmoney Net] СуммаДопУслугCarmoneyNet,
fa.ДатаЗаявкиПолная,
fa.Фио
,fa.RBP rbp_details
,fa.[Вид займа] [Вид займа]


 from [Reports].[ssrsRW].[dm_report_logistics_history] log_req
left join v_fa fa  with(nolock) on fa.Номер=log_req.external_id
left join [Stg].[_1cCRM].[Справочник_Пользователи] users with(nolock) on log_req.author = users.[adLogin] 
where ((ДатаЗаявкиПолная>=@request_date_start  and Одобрено>=@approved_date_start) or       log_req.[created] >=dateadd(hour, -9, getdate()))


  end
 end