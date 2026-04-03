create         procedure 

[dbo].[get_tg_message_2022-02-28]
(
@period nvarchar(max),
@type nvarchar(max)
)
as

begin

drop table if exists #commision_data

set datefirst 1;
declare @report_date date = case when datepart(hour , getdate()) >=6 then cast(getdate() as date) else cast(getdate()-1 as date) end
declare @report_week date = cast(DATEADD(DD, 1 - DATEPART(DW, @report_date ), @report_date ) as date)
declare @report_yesterday date = dateadd(day, -1, @report_date)
declare @report_month date = cast(format(@report_date   , 'yyyy-MM-01') as date)
declare @report_quarter date = cast(DATEADD(qq, DATEDIFF(qq, 0, @report_date), 0) as date)

declare @message nvarchar(max)
;

if @type = 'comissions'
begin
;
with  sms as (

select 

Прибыль = [Комиссия "СМС информирование": cумма услуги net],
Сумма = null,

Количество = 1, 
день = [Комиссия "СМС информирование": дата оплаты день],
неделя = [Комиссия "СМС информирование": дата оплаты неделя],
месяц = [Комиссия "СМС информирование": дата оплаты месяц],
квартал = [Комиссия "СМС информирование": дата оплаты квартал],
тип = 'СМС'
from v_comissions
where [Комиссия "СМС информирование": cумма услуги] is not null
--order by 3
),
sroch as (
select 

Прибыль    = [Комиссия "Срочное снятие с залога": cумма услуги net],
Сумма = null,
Количество = 1, 
день       =    [Комиссия "Срочное снятие с залога": дата оплаты день],
неделя     =  [Комиссия "Срочное снятие с залога": дата оплаты неделя],
месяц      =   [Комиссия "Срочное снятие с залога": дата оплаты месяц],
квартал    = [Комиссия "Срочное снятие с залога": дата оплаты квартал],
тип = 'Срочное снятие залога'


from v_comissions
where [Комиссия "Срочное снятие с залога": cумма услуги] is not null

)
,
comissions_repaym as (
select 

Прибыль = ПрибыльБезНДС,
Сумма = Сумма,
Количество = 1, 
день =    [ДеньПлатежа],
неделя =  [НеделяПлатежа],
месяц =   [МесяцПлатежа],
квартал = [КварталПлатежа],
тип = N'ПС: '+  case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end

from v_repayments
--where [Платеж онлайн]=1


)
, un as (
select * from sms union all
select * from sroch union all
select * from comissions_repaym

)
, un_ as (
select 
*
,[Текущий день] =  case when день=@report_date then 1 else 0 end 
,[Вчера] =  case when день= @report_yesterday  then 1 else 0 end 
,[Текущий неделя] =  case when неделя= @report_week  then 1 else 0 end 
,[Текущий месяц] =  case when месяц= @report_month then 1 else 0 end 
,[Текущий квартал] =  case when квартал= @report_quarter  then 1 else 0 end 



from un 
)
, data as (
select *  from un_
where case when @period = 'week'    then [Текущий неделя]
           when @period = 'today'     then [Текущий день]
           when @period = 'yesterday'     then [Вчера]
           when @period = 'month'   then [Текущий месяц]
           when @period = 'quarter' then [Текущий квартал] end = 1
)
, agr_data as (
select  distinct тип
, sum(Прибыль) over(partition by тип) sumc
, sum(Сумма)  over(partition by тип) summ
, sum(Сумма)  over(partition by тип)/  sum(Сумма)  over()  perc_summ
, count(*)  over(partition by тип) cnt 
from data
--group by тип
)


  select isnull(format(getdate(), 'dd-MMM HH:mm:ss')+'

'+STRING_AGG(text, '
' ), 'Нет данных') text
into #commision_data

from (
   select top 10000  тип+ ': '+ replace(format(cnt , '#,0'), ',' , ' ')+' шт.
'
+ case when тип like 'ПС:%' then 'Поступило: ' +format(summ , '#,0')+' руб.
' else '' end
+ case when тип like 'ПС:%' then 'Доля: ' +format(perc_summ , '0%')+'
' else '' end 
+'Прибыль (net): ' +format(sumc , '#,0')+' руб.'+'
'
  text
from agr_data
where тип like '%ecomm%' or  тип in ('СМС', 'Срочное снятие залога')
order by left(тип, 2), case when тип like '%ecomm%' then 1 when тип like '%cont%' then 2 when тип like '%расч%' then 3 end
 
) x


--exec generate_create_table_script '#commision_data'
set @message = (select top 1 * from #commision_data)

set @message = @message+'
/'+@type+'_'+@period 

select @message
return
end
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------


if @type = 'channels'
begin
drop table if exists #tmp_dm_sales
;
with t1 as (
    SELECT [ДатаВыдачи]
    ,Код
	, case when ДатаВыдачи=@report_date then 1 else 0 end as Today
	, case when ДатаВыдачи=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, ДатаВыдачи ), ДатаВыдачи ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format(ДатаВыдачи   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, ДатаВыдачи), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
	,cast([Сумма] as bigint)  [Сумма]
    ,СпособОформления
    ,Канал
	,case when IsInstallment=1 then 'Инстоллмент'
	      else  'ПТС'
	end
	
	product
      FROM [Reports].[dbo].[dm_Sales] --with(nolock)
where ishistory=0
union all
    SELECT [Дата выдачи]
    ,Номер
	, case when [Дата выдачи]=@report_date then 1 else 0 end as Today
	, case when [Дата выдачи]=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, [Дата выдачи] ), [Дата выдачи] ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format([Дата выдачи]   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, [Дата выдачи]), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
	,cast([Выданная сумма] as bigint)  [Сумма]
    ,null СпособОформления
    ,null Канал
	,'Бизнес инвест' product
      FROM [Analytics].[dbo].[Бизнес инвест] --with(nolock)




	  )
	  
	 , v as(
      select b.*

      from  t1 b 
	  where 1=1  and
	  case when @period = 'week'    then week
           when @period = 'yesterday'     then Yesterday
           when @period = 'today'     then Today
           when @period = 'month'   then Month 
           when @period = 'quarter'   then Quarter 
		   end = 1
      )

	  select * into #tmp_dm_sales
	  from v
	  
	  drop table if exists #tmp_plans
	  ;

	
with plans as (
  select * from (
  SELECT 
       [День]
      ,[Месяц]
      ,[Год]
      ,[Неделя]
      ,[Квартал]
      ,[Сумма] [Сумма]
      ,[Сумма инстоллмент] [Сумма инстоллмент]
    , case when [День]=@report_date then 1 else 0 end as Today
	, case when [День]=@report_yesterday then 1 else 0 end as Yesterday
	, case when cast(DATEADD(DD, 1 - DATEPART(DW, [День] ), [День] ) as date) = @report_week then 1 else 0 end as Week
	, case when cast(format([День]   , 'yyyy-MM-01') as date)  = @report_month then 1 else 0 end as  Month
	, case when cast(DATEADD(qq, DATEDIFF(qq, 0, [День]), 0) as date)  = @report_quarter then 1 else 0 end as  Quarter
  FROM [Analytics].[dbo].[v_plans] with(nolock)
  )pl
   where 1=1  and
	  case when @period = 'week'    then week
           when @period = 'yesterday'     then Yesterday
           when @period = 'today'     then Today
           when @period = 'month'   then Month 
           when @period = 'quarter'   then Quarter 
		   end = 1

)
select * into #tmp_plans from plans
;


        with for_text_pts as(
      select Канал, count(*) Займов, sum([Сумма]) Выдано, avg([Сумма]) Чек from #tmp_dm_sales where product='ПТС' group by Канал union all
   select 'Всего',  count(*) Займов, sum([Сумма]) Выдано, avg([Сумма]) Чек from #tmp_dm_sales where product='ПТС' 
   

      ) , for_text_inst as(
      select Канал, count(*) Займов, sum([Сумма]) Выдано, avg([Сумма]) Чек from #tmp_dm_sales where product='Инстоллмент' group by Канал union all
   select 'Всего',  count(*) Займов, sum([Сумма]) Выдано, avg([Сумма]) Чек from #tmp_dm_sales where product='Инстоллмент'
   
      ), for_text_BI as(
   select 'Всего' Канал,  count(*) Займов, sum([Сумма]) Выдано, avg([Сумма]) Чек from #tmp_dm_sales where product='Бизнес инвест'
   
      )

select 
text = format(getdate(), 'dd-MMM HH:mm:ss') + '
______________
ПТС : 
'+
pts.text_pts+'
______________
'
+'Installment:
'
+inst.text_inst 
+'
______________
Бизнес инвест:
'
+[бизнес инвест].text_BI
+'
______________
Total:
План: '+(select format(isnull(sum(Сумма), 0) + isnull(sum([Сумма инстоллмент]), 0),'#,0')  from #tmp_plans )+'
Факт: '+(select format(isnull(sum([Сумма]), 0) ,'#,0') from #tmp_dm_sales )+'
% выполнения: ' + format(
                  
				  case when (select isnull(sum(Сумма), 0) + isnull(sum([Сумма инстоллмент]), 0)  from #tmp_plans )>0 then
                            (select isnull(sum([Сумма]), 0) from #tmp_dm_sales )/(select isnull(sum(Сумма), 0) + isnull(sum([Сумма инстоллмент]), 0)  from #tmp_plans ) else 0 end
				, '0%')
into #sales_data
from 
(
 select isnull('
'+STRING_AGG(text, '

' ), 'Нет данных') text_pts

from (
      select Канал+ ': '+ format(Займов , '0')+' шт.
'+ 'Выдано: ' +format(Выдано , '#,0')+' руб.
' +'Чек: ' + format(Чек , '#,0')+' руб.' text
from for_text_pts
      ) x
)pts 

cross join
(
 select isnull('
'+STRING_AGG(text, '

' ), 'Нет данных') text_inst

from (
      select Канал+ ': '+ format(Займов , '0')+' шт.
'+ 'Выдано: ' +format(Выдано , '#,0')+' руб.
' +'Чек: ' + format(Чек , '#,0')+' руб.' text
from for_text_inst
      ) x
)inst


cross join
(
 select isnull('
'+STRING_AGG(text, '

' ), 'Нет данных') text_BI

from (
      select Канал+ ': '+ format(Займов , '0')+' шт.
'+ 'Выдано: ' +format(Выдано , '#,0')+' руб.
' +'Чек: ' + format(Чек , '#,0')+' руб.' text
from for_text_BI
      ) x
) [бизнес инвест]


set @message = (select top 1 * from #sales_data)


set @message = @message+'
/'+@type+'_'+@period 
select @message
return

end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------


if @type = 'result'
begin

drop table if exists #result_data
;
with  v as(
      SELECT [Text]
  FROM [Reports].[dbo].[v_dm_Telegram]
  where p = @period
      )
	


      select isnull([Text], 'Нет данных') text
into #result_data

from v

	  set @message = (select top 1 * from #result_data)

	  
set @message = @message+'
/'+@type+'_'+@period 
select @message
return
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------


if @type = 'start'
begin
	  set @message = '
Список доступных команд - /help
'

select @message
return
end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------


if @type = 'help'
begin
	  set @message = '
Продажи по каналам:

/channels_today
/channels_yesterday   
/channels_week        
/channels_month   
/channels_quarter

Результаты дня/недели/месяца:
/result_today 
/result_yesterday     
/result_week          
/result_month

Статистика по комиссиям
/comissions_today     
/comissions_yesterday 
/comissions_week      
/comissions_month     
/comissions_quarter   

По любым вопросам @petyaaaaaaaa
'


select @message
return

end

--exec Analytics.dbo.get_tg_message 'yesterday', 'comissions'
--exec Analytics.dbo.get_tg_message1 'month', 'channels'
--
end

--