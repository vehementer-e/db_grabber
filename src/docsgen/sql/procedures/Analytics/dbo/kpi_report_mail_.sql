CREATE    proc  kpi_report_mail_  @mode nvarchar(max)
--ass
as
 
if @mode = 'update'
begin
DECLARE @exists int = 0
DECLARE @exists1 int = 0
DECLARE @exists2 int = 0
DECLARE @exists3 int = 0
DECLARE @exists4 int = 0
DECLARE @exists5 int = 0

;
while @exists=0 
begin
SELECT TOP 1 @exists1 = 1 FROM v_fa WHERE cast([Дата отчета] as date) = cast(getdate() as date)
SELECT TOP 1 @exists2 = 1 FROM [dbo].[report_comissions] WHERE cast([Дата обновления записи по договору с комиссией] as date) = cast(getdate() as date)
SELECT TOP 1 @exists3 = 1 FROM [_birs].product_report_all_Actions WHERE cast([created] as date) = cast(getdate() as date)
SELECT TOP 1 @exists4 = 1 FROM [dbo].[mv_repayments] WHERE cast([created] as date) = cast(getdate() as date)
SELECT TOP 1 @exists5 = 1 FROM [dbo].[v_Отчет стоимость займа опер] WHERE cast([created] as date) = cast(getdate() as date)

IF @exists1+@exists2+@exists3+@exists4+@exists5<>5
begin
waitfor delay '00:00:30'
end


else 
begin

set @exists=1

end

end

drop table if exists  #report
create table #report (
       ТипД  varchar(255),
	   Дата  date,
	   Тип  varchar(255),
	   группа  varchar(255),
	   Значение  float)




--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
 drop table if exists   #loans				
select CRMClientGUID, Код, Сумма, isInstallment, [Дата выдачи] into #loans  from mv_loans a				
				
drop table if exists   #loans_rn				
		
select *				
, ROW_NUMBER() over(partition by CRMClientGUID  order by [Дата выдачи]) rn 				
, ROW_NUMBER() over(partition by CRMClientGUID, [Дата выдачи] order by Код) clean 				
				
into #loans_rn from 	 #loans			
				
delete from   #loans_rn where clean>1				
			 	
				
--select * from #loans_rn				
drop table if exists   #cross			
				
select a.Код   into #cross  from #loans_rn a				
left join #loans_rn b on a.CRMClientGUID=b.CRMClientGUID and a.isInstallment=b.isInstallment and a.[Дата выдачи]>b.[Дата выдачи]				
				
where a.rn>1 and b.код is null  
group by a.Код 


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------















drop table if exists #dm_Factor_Analysis
select Номер, [full_prepayment_30], [ПроцСтавкаКредит] into #dm_Factor_Analysis from reports.dbo.dm_Factor_Analysis with(nolock)


drop table if exists #return_types
select Номер, [Дата следующего займа в рамках продукта] into #return_types from return_types with(nolock)

drop table if exists [#v_Отчет стоимость займа опер] 
select o.Номер, o.[Заем выдан день], o.isinstallment, o.[Маркетинговые расходы] into [#v_Отчет стоимость займа опер]  from [dbo].[v_Отчет стоимость займа опер] o with(nolock)

drop table if exists #dm_Factor_Analysis_1
select f.[Верификация КЦ],f.[Заем выдан],f.[Заем погашен],f.ispts,f.[Вид займа],f.[Номер],f.[Группа каналов],f.[Канал от источника],f.[Сумма Дополнительных Услуг Carmoney Net],f.RBP,f.[Первичная сумма],f.[Сумма одобренная],f.[Выданная сумма],f.[Предварительное одобрение],f.[Контроль данных],f.[Одобрено],f.[Отказ документов клиента],f.[Отказано],f.[Место создания] [Место cоздания],f.Дубль into #dm_Factor_Analysis_1 from v_fa f with(nolock)

drop table if exists #product_report
select case when [Группа каналов] = 'CPA' then [Канал от источника] else [Группа каналов]  end [Группа каналов_2], День, Лидов, is_pts, [Верификация кц]
into #product_report from [_birs].[product_report_all_actions] c with(nolock) where isnull([Дубль_8_дней любой продукт] , 0) = 0  and  (	 [Как создан]='ref' 	or  id is not null )  --and isnull(Дубль2, 0)<>1	  
and case 
when is_pts=0 and has_pts_request>0 and ISNULL(has_bz_request,  0)=0 then 1 
when is_pts=1 and has_bz_request>0 and ISNULL(has_pts_request,  0)=0 then 1 
else 0 
end	 <>1

drop table if exists #fa_

select 
  dateadd(day, datediff(day, '1900-01-01', f.[Верификация КЦ]) / 7 * 7, '1900-01-01')   [Неделя Заявка]
, dateadd(day, datediff(day, '1900-01-01', f.[Заем погашен]) / 7 * 7, '1900-01-01')   [Неделя Заем погашен]
, dateadd(day, datediff(day, '1900-01-01', f.[Заем выдан]) / 7 * 7, '1900-01-01')   [Неделя Заем выдан]
, dateadd(month, datediff(month, '1900-01-01', f.[Верификация КЦ]), '1900-01-01')   [Месяц Заявка]
, dateadd(month, datediff(month, '1900-01-01', f.[Заем выдан]), '1900-01-01')   [Месяц Заем выдан]
, dateadd(month, datediff(month, '1900-01-01', f.[Заем погашен]), '1900-01-01')   [Месяц Заем погашен]
, dateadd(quarter, datediff(quarter, '1900-01-01', f.[Верификация КЦ]), '1900-01-01')   [Квартал Заявка]
, dateadd(quarter, datediff(quarter, '1900-01-01', f.[Заем выдан]), '1900-01-01')   [Квартал Заем выдан]
, dateadd(quarter, datediff(quarter, '1900-01-01', f.[Заем погашен]), '1900-01-01')   [Квартал Заем погашен]
, case when month(f.[Верификация КЦ])<=6 then cast(format(f.[Верификация КЦ], 'yyyy-01-01')as date) else cast(format(f.[Верификация КЦ], 'yyyy-07-01')as date) end [Полугодие Заявка]
, case when month(f.[Заем выдан])<=6 then cast(format(f.[Заем выдан], 'yyyy-01-01')as date) else cast(format(f.[Заем выдан], 'yyyy-07-01')as date) end [Полугодие Заем выдан]
, case when month(f.[Заем погашен])<=6 then cast(format(f.[Заем погашен], 'yyyy-01-01')as date) else cast(format(f.[Заем погашен], 'yyyy-07-01')as date) end [Полугодие Заем погашен]
, dateadd(year, datediff(year, '1900-01-01', f.[Верификация КЦ]), '1900-01-01')   [Год Заявка]
, dateadd(year, datediff(year, '1900-01-01', f.[Заем выдан]), '1900-01-01')   [Год Заем выдан]
, dateadd(year, datediff(year, '1900-01-01', f.[Заем погашен]), '1900-01-01')   [Год Заем погашен]
, cast(f.[Заем выдан] as date)  [День Заем выдан]
, f.ispts
, f.[Вид займа]
, f.[Верификация КЦ]
, f.[Номер]
, case when f.[Группа каналов] = 'CPA' then f.[Канал от источника] else f.[Группа каналов]  end [Группа каналов_2]
, f.[Сумма Дополнительных Услуг Carmoney Net] Сумма
,case when f.RBP in('RBP - 40', 'RBP - 56', 'RBP - 66', 'RBP - 86') and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP
,case when f.RBP = 'RBP - 40' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP1
,case when f.RBP = 'RBP - 56' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP2
,case when f.RBP = 'RBP - 66' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP3
,case when f.RBP = 'RBP - 86' and f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end RBP4
,case when f.[Вид займа] = 'Первичный' and f.[Заем выдан] is not null then 1 else 0 end [Новых займов]
,case when f.[Вид займа] = 'Повторный' and f.[Заем выдан] is not null then 1 else 0 end [Повторных займов]
,case when f.[Вид займа] = 'Докредитование' or f.[Вид займа] = 'Параллельный' and f.[Заем выдан] is not null then 1 else 0 end [Докред займов]
,case when f.[Вид займа] is not null and f.[Заем выдан] is not null then 1 else 0 end [Займов]
,case when f.[Вид займа] = 'Первичный' then 'Новые' 
      when f.[Вид займа] = 'Повторный' then 'Повторные' 
	  when f.[Вид займа] = 'Докредитование' or f.[Вид займа] = 'Параллельный' then 'Докреды' end [Вид]
,fa.[ПроцСтавкаКредит] Ставка
,f.[Первичная сумма] Запрошенная
,f.[Сумма одобренная] Одобренная
,f.[Выданная сумма] Выданная
,fa.[full_prepayment_30]
,f.[Предварительное одобрение]
,f.[Контроль данных]
,f.[Одобрено]
,f.[Отказ документов клиента]
,f.[Отказано]
,f.[Заем выдан]
,case when f.ispts = 1 then 'ПТС' when f.ispts = 0 then 'Беззалог' end ПТС
,case when f.[Место cоздания] = 'Оформление в мобильном приложении' then 'Воронка ПТС МП' 
      when f.[Место cоздания] = 'Ввод операторами LCRM' then 'Воронка ПТС сайт' end Воронка
,dateadd(day, datediff(day, '1900-01-01', case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end) / 7 * 7, '1900-01-01') [Неделя Маркетинг]
,dateadd(month, datediff(month, '1900-01-01', case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end), '1900-01-01') [Месяц Маркетинг]
,dateadd(quarter, datediff(quarter, '1900-01-01', case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end), '1900-01-01') [Квартал Маркетинг]
,case when month(case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день]end)<=6 then cast(format(case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end, 'yyyy-01-01')as date) else cast(format(case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end, 'yyyy-07-01')as date) end [Полугодие Маркетинг]
,dateadd(year, datediff(year, '1900-01-01', case when o.[Заем выдан день] is null then f.[Верификация КЦ] else o.[Заем выдан день] end), '1900-01-01') [Год Маркетинг]
,case when o.isinstallment=1 then o.[Маркетинговые расходы] end [Маркетинговые расходы Инст]
,case when o.isinstallment=0 then o.[Маркетинговые расходы] end [Маркетинговые расходы ПТС]
,case when o.isinstallment=1 and o.[Заем выдан день] is not null then 1 end [Количество займов Инст]
,case when o.isinstallment=0 and o.[Заем выдан день] is not null then 1 end [Количество займов ПТС]
,f.Дубль
, rt.[Дата следующего займа в рамках продукта]
, case when cross_sale.Код is not null then 1 else 0 end is_cross_sale
into #fa_
from #dm_Factor_Analysis_1 f
left join #dm_Factor_Analysis fa  on fa.Номер = f.Номер
left join #return_types rt  on rt.Номер = f.Номер
left join #cross  cross_sale  on cross_sale.Код = f.Номер
left join [#v_Отчет стоимость займа опер] o on f.[Номер] = o.Номер 

;
with fa_ as(
 select * from #fa_
),

fa as(
select 'Неделя' ТипД, 'Заявка' ТипЗ, [Неделя Заявка] Дата,* from fa_ where Дубль=0 union all
select 'Неделя' ТипД, 'Займ' ТипЗ, [Неделя Заем выдан] Дата,*from fa_ where [Неделя Заем выдан] is not null union all
select 'Неделя' ТипД, 'Маркетинг' ТипЗ, [Неделя Маркетинг] Дата,*from fa_ union all
select 'Месяц' ТипД, 'Заявка' ТипЗ, [Месяц Заявка] Дата,*from fa_ where Дубль=0 union all
select 'Месяц' ТипД, 'Займ' ТипЗ, [Месяц Заем выдан] Дата,*from fa_ where [Месяц Заем выдан] is not null union all
select 'Месяц' ТипД, 'Маркетинг' ТипЗ, [Месяц Маркетинг] Дата,*from fa_ union all
select 'Квартал' ТипД, 'Заявка' ТипЗ, [Квартал Заявка] Дата,*from fa_ where Дубль=0 union all
select 'Квартал' ТипД, 'Займ' ТипЗ, [Квартал Заем выдан] Дата,*from fa_ where [Квартал Заем выдан] is not null union all
select 'Квартал' ТипД, 'Маркетинг' ТипЗ, [Квартал Маркетинг] Дата,*from fa_ union all
select 'Полугодие' ТипД, 'Заявка' ТипЗ, [Полугодие Заявка] Дата,*from fa_ where Дубль=0 union all
select 'Полугодие' ТипД, 'Займ' ТипЗ, [Полугодие Заем выдан] Дата,*from fa_ where [Полугодие Заем выдан] is not null union all
select 'Полугодие' ТипД, 'Маркетинг' ТипЗ, case when month([Полугодие Маркетинг])<=6 then cast(format([Полугодие Маркетинг], 'yyyy-01-01')as date) else cast(format([Полугодие Маркетинг], 'yyyy-07-01')as date) end  Дата,*from fa_ union all
select 'Год' ТипД, 'Заявка' ТипЗ, [Год Заявка] Дата,*from fa_ where Дубль=0 union all
select 'Год' ТипД, 'Маркетинг' ТипЗ, [Год Маркетинг] Дата,*from fa_ union all
select 'Год' ТипД, 'Займ' ТипЗ, [Год Заем выдан] Дата,*from fa_ where [Год Заем выдан] is not null union all

select 'Неделя' ТипД   , 'Закрытие' ТипЗ, [Неделя Заем погашен]    Дата,*from fa_ where [Заем выдан] is not null  union all
select 'Месяц' ТипД    , 'Закрытие' ТипЗ, [Месяц Заем погашен] Дата,*from fa_ where [Заем выдан] is not null union all
select 'Квартал' ТипД  , 'Закрытие' ТипЗ, [Квартал Заем погашен] Дата,*from fa_ where [Заем выдан] is not null union all
select 'Полугодие' ТипД, 'Закрытие' ТипЗ, [Полугодие Заем погашен] Дата,*from fa_ where [Заем выдан] is not null union all
select 'Год' ТипД      , 'Закрытие' ТипЗ, [Год Заем погашен] Дата,*from fa_ where [Заем выдан] is not null  

),

f1 as (
select ТипД = [ТипД], 
       Дата = [Дата],
       Тип = 'Пр. одобрение ПТС',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], 
       Дата = [Дата],
       Тип = 'Пр. одобрение ПТС',
       группа = 'Тотал' ,
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доезд ПТС',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доезд ПТС',
       группа = 'Тотал' ,
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'AR ПТС',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'AR ПТС',
       группа = 'Тотал' ,
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU шт ПТС',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU шт ПТС',
       группа = 'Тотал' ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка' 
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Заявка займ ПТС',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Заявка займ ПТС',
       группа = 'Тотал' ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where [Группа каналов_2] is not null and ispts=1 and ТипЗ='Заявка'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Чек ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Выданная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Чек ПТС',
       группа = 'Тотал' ,
       Значение= avg(Выданная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата--, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Ставка ПТС',
       группа = [Группа каналов_2] ,
       Значение= (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float)/nullif((sum(case when Ставка>0 then Выданная else 0 end)*100),0))*100
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Ставка ПТС',
       группа = 'Тотал' ,
       Значение= (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float) /nullif((sum(case when Ставка>0 then Выданная else 0 end)*100) ,0))*100
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Запрош. сумма ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Запрошенная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Запрош. сумма ПТС',
       группа = 'Тотал' ,
       Значение= avg(Запрошенная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Одобр. сумма ПТС',
       группа = [Группа каналов_2] ,
       Значение= avg(Одобренная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Одобр. сумма ПТС',
       группа = 'Тотал' ,
       Значение= avg(Одобренная) 
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип ='UpSale деньги ПТС',
       группа = [Группа каналов_2] ,
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Запрошенная),0)
	   from fa
	   where isPts=1 and Запрошенная>0 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'UpSale деньги ПТС',
       группа = 'Тотал' ,
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Запрошенная),0)
	   from fa
	   where isPts=1 and Запрошенная>0 and ТипЗ='Займ'
	   group by ТипД,Дата--, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU в деньгах ПТС',
       группа = [Группа каналов_2] ,
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Одобренная),0)
	   from fa
	   where isPts=1 and Одобренная>0 and ТипЗ='Займ'
	   group by ТипД,Дата, [Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU в деньгах ПТС',
       группа = 'Тотал' ,
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Одобренная),0)
	   from fa
	   where isPts=1 and Одобренная>0 and ТипЗ='Займ'
	   group by ТипД,Дата),

f2 as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Ставка ПТС',
       группа = [Вид],
       Значение = (try_cast(sum(case when Ставка>0 then Выданная*Ставка else 0 end)as float) /nullif((sum(case when Ставка>0 then Выданная else 0 end)*100),0))*100
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Запрош. сумма ПТС',
       группа = [Вид],
       Значение = avg(Запрошенная)
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Одобр. сумма ПТС',
       группа = [Вид],
       Значение = avg(Одобренная)
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Чек ПТС',
       группа = [Вид],
       Значение = avg(Выданная)
	   from fa
	   where isPts=1 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'UpSale деньги ПТС',
       группа = [Вид],
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Запрошенная),0)
	   from fa
	   where isPts=1 and Запрошенная>0 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU в деньгах ПТС',
       группа = [Вид],
       Значение = try_cast(sum(Выданная)as float)/nullif(sum(Одобренная),0)
	   from fa
	   where isPts=1 and Одобренная>0 and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = '% ПДП 30д. ПТС шт',
       группа = [Вид],
       Значение = try_cast(sum([full_prepayment_30])as float)/nullif(count([full_prepayment_30]),0)
	   from fa
	   where ispts=1 and [full_prepayment_30] is not null and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = '% ПДП 30д. ПТС шт',
       группа = 'Тотал',
       Значение = try_cast(sum([full_prepayment_30])as float)/nullif(count([full_prepayment_30]),0)
	   from fa
	   where ispts=1 and [full_prepayment_30] is not null and ТипЗ='Займ'
	   group by ТипД,Дата--, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = '% ПДП 30д. ПТС руб',
       группа = [Вид],
       Значение = try_cast(sum(case when full_prepayment_30=1 then Выданная end)as float)/nullif(sum(Выданная),0)
	   from fa
	   where ispts=1 and [full_prepayment_30] is not null and ТипЗ='Займ'
	   group by ТипД,Дата, [Вид]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = '% ПДП 30д. ПТС руб',
       группа = 'Тотал',
       Значение = try_cast(sum(case when full_prepayment_30=1 then Выданная end)as float)/nullif(sum(Выданная),0)
	   from fa
	   where ispts=1 and [full_prepayment_30] is not null and ТипЗ='Займ'
	   group by ТипД,Дата),

f3 as (
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС RBP шт',
       группа = 'RBP1',
       Значение = try_cast(sum(RBP1) as float)/nullif(sum(RBP), 0)
	   from fa where ТипЗ='Займ' and RBP is not null  and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС RBP шт',
       группа = 'RBP2',
       Значение = try_cast(sum(RBP2) as float)/nullif(sum(RBP), 0)
	   from fa where ТипЗ='Займ' and RBP is not null and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС RBP шт',
       группа = 'RBP3',
       Значение = try_cast(sum(RBP3) as float)/nullif(sum(RBP), 0)
	   from fa where ТипЗ='Займ' and RBP is not null  and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС RBP шт',
       группа = 'RBP4',
       Значение = try_cast(sum(RBP4) as float)/nullif(sum(RBP), 0)
	   from fa where ТипЗ='Займ' and RBP is not null  and isPts=1
	   group by ТипД, Дата),

f4 as (
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа шт',
       группа = 'Новые',
       Значение = try_cast(sum([Новых займов]) as float)/nullif(sum([Займов]), 0)
	   from fa where ТипЗ='Займ'   and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа шт',
       группа = 'Повторные',
       Значение = try_cast(sum([Повторных займов]) as float)/nullif(sum([Займов]), 0)
	   from fa where ТипЗ='Займ' and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа шт',
       группа = 'Докреды',
       Значение = try_cast(sum([Докред займов]) as float)/nullif(sum([Займов]), 0)
	   from fa where ТипЗ='Займ'  and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа руб',
       группа = 'Новые',
       Значение = try_cast(sum(case when Вид = 'Новые' then Выданная end) as float)/sum(Выданная) 
	   from fa where ТипЗ='Займ'  and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа руб',
       группа = 'Повторные',
       Значение = try_cast(sum(case when Вид = 'Повторные' then Выданная end) as float)/sum(Выданная)
	   from fa where ТипЗ='Займ' and isPts=1
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = '% ПТС вид займа руб',
       группа = 'Докреды',
       Значение = try_cast(sum(case when Вид = 'Докреды' then Выданная end) as float)/sum(Выданная)
	   from fa where ТипЗ='Займ'   and isPts=1
	   group by ТипД, Дата
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Предв. одобрение',
       группа = ПТС,
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and ПТС is not null
	   group by ТипД,Дата, ПТС
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доезд',
       группа = ПТС,
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and ПТС is not null
	   group by ТипД,Дата, ПТС
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'AR',
       группа = ПТС,
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0) 
	   from fa
	   where ТипЗ='Заявка' and ПТС is not null
	   group by ТипД,Дата, ПТС
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU',
       группа = ПТС,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and ПТС is not null
	   group by ТипД,Дата, ПТС
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Заявка займ',
       группа = ПТС,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and ПТС is not null
	   group by ТипД,Дата, ПТС),

f5 as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = Воронка,
       группа = 'Предв. одобрение',
       Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and Воронка is not null and isPts=1
	   group by ТипД,Дата, Воронка
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = Воронка,
       группа = 'Доезд',
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and Воронка is not null and isPts=1
	   group by ТипД,Дата, Воронка
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = Воронка,
       группа = 'AR',
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0) 
	   from fa
	   where ТипЗ='Заявка' and Воронка is not null and isPts=1
	   group by ТипД,Дата, Воронка
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = Воронка,
       группа = 'TU',
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and Воронка is not null and isPts=1 
	   group by ТипД,Дата, Воронка
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = Воронка,
       группа = 'Заявка займ',
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and Воронка is not null and isPts=1
	   group by ТипД,Дата, Воронка
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доля КП net',
       группа = [Группа каналов_2] ,
       Значение= try_cast(sum(Сумма) as float)/sum(Выданная)
	   from fa
	   where [Группа каналов_2] is not null and Выданная is not null and ТипЗ='Займ' 	and isPts=1
	   group by ТипД,Дата,[Группа каналов_2]
union all	   
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доля КП net',
       группа = 'Тотал' ,
       Значение= try_cast(sum(Сумма) as float)/sum(Выданная)
	   from fa
	   where [Группа каналов_2] is not null and Выданная is not null and ТипЗ='Займ'  and isPts=1
	   group by ТипД,Дата),

f6 as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Стоимость займа',
       группа = 'Беззалог' ,
       Значение= try_cast(sum([Маркетинговые расходы Инст]) as float)/sum([Количество займов Инст])
	   from fa
	   where ТипЗ='Маркетинг'
	   group by ТипД,Дата
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Стоимость займа',
       группа = 'ПТС' ,
       Значение= try_cast(sum([Маркетинговые расходы ПТС]) as float)/sum([Количество займов ПТС])
	   from fa
	   where ТипЗ='Маркетинг'
	   group by ТипД,Дата
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Продажи руб',
       группа = 'ПТС' ,
       Значение= sum(Выданная)
	   from fa
	   where ТипЗ='Займ' and ispts=1 
	   group by ТипД,Дата
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Продажи руб',
       группа = 'Беззалог' ,
       Значение= sum(Выданная)
	   from fa
	   where ТипЗ='Займ' and ispts=0 
	   group by ТипД,Дата)


,f7 as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Закрытые новые займы',
       группа = 'Беззалог' ,
       Значение= count(*)
	   from fa	 where isPts=0	and [Вид займа]='Первичный'
	   and ТипЗ='Закрытие'
	   group by ТипД,Дата
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = '% новых вернулись',
       группа = 'Беззалог' ,
       Значение= count([Дата следующего займа в рамках продукта])/ nullif(count(*)+0.0, 0)
	   from fa	 where isPts=0	and [Вид займа]='Первичный'
	   and ТипЗ='Закрытие'
	   group by ТипД,Дата
							 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'CROSS SALE шт.',
       группа = ПТС ,
       Значение= sum(case when is_cross_sale=1 then 1 end) 
	   from fa	 where 
	    ТипЗ='Займ'
	   group by ТипД,Дата  , ПТС 							 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'CROSS SALE руб.',
       группа = ПТС ,
       Значение= sum(case when is_cross_sale=1 then Выданная end) 
	   from fa	 where 
	    ТипЗ='Займ'
	   group by ТипД,Дата  , ПТС
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Чек Беззалог',
       группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
       Значение= avg(Выданная) 
	   from fa
	   where isPts=0 and ТипЗ='Займ'
	   group by ТипД,Дата , case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
union all

select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Предв. одобрение Беззалог',
        группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
      Значение= try_cast(sum(case when [Предварительное одобрение] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and isPts=0 
	   group by ТипД,Дата, ПТС	, case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Доезд Беззалог',
       группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
       Значение= try_cast(sum(case when [Контроль данных] is not null then 1 else 0 end)as float)/nullif(sum(case when [Предварительное одобрение] is not null then 1 else 0 end),0) 
	   from fa
	   where ТипЗ='Заявка' and isPts=0 
	   group by ТипД,Дата, ПТС	, case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'AR Беззалог',
       группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
       Значение= try_cast(sum(case when [Одобрено] is not null then 1 else 0 end)as float)/nullif((sum(case when [Одобрено] is not null then 1 else 0 end)+sum(case when [Отказ документов клиента] is not null then 1 else 0 end)+sum(case when [Отказано] is not null then 1 else 0 end)),0) 
	   from fa
	   where ТипЗ='Заявка' and isPts=0 
	   group by ТипД,Дата, ПТС	, case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'TU Беззалог',
       группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Одобрено] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and isPts=0 
	   group by ТипД,Дата, ПТС	, case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Заявка займ Беззалог',
       группа = case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end ,
       Значение= try_cast(sum(case when [Заем выдан] is not null then 1 else 0 end)as float)/nullif(sum(case when [Верификация КЦ] is not null then 1 else 0 end),0)
	   from fa
	   where ТипЗ='Заявка' and   isPts=0 
	   group by ТипД,Дата, ПТС , case when [Вид займа]='Первичный' then 'Первичный' else 'Повторный' end 
	  
union all
 

select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Стоимость займа новые',
       группа = 'Беззалог' ,
       Значение= try_cast(sum([Маркетинговые расходы Инст]) as float)/sum([Количество займов Инст])
	   from fa
	   where ТипЗ='Маркетинг' and [Вид займа]='Первичный'
	   group by ТипД,Дата	

union all

select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Стоимость займа повторные',
       группа = 'Беззалог' ,
       Значение= try_cast(sum([Маркетинговые расходы Инст]) as float)/sum([Количество займов Инст])
	   from fa
	   where ТипЗ='Маркетинг' and [Вид займа]='Повторный'
	   group by ТипД,Дата	  
	  
	  
	  
	  )


insert into #report
select * from f1
union all select*from f2
union all select*from f3
union all select*from f4
union all select*from f5
union all select*from f6
union all select*from f7
;

with plans as (
select 'Неделя' ТипД, dateadd(day, datediff(day, '1900-01-01', Дата) / 7 * 7, '1900-01-01')Дата, [Займы руб],[Сумма займов инстоллмент план] from stg.files.ContactCenterPlans_buffer with(nolock) union all
select 'Месяц' ТипД,dateadd(month, datediff(month, '1900-01-01', Дата), '1900-01-01')   Дата, [Займы руб],[Сумма займов инстоллмент план] from stg.files.ContactCenterPlans_buffer with(nolock) union all
select 'Квартал' ТипД ,dateadd(quarter, datediff(quarter, '1900-01-01', Дата), '1900-01-01')   Дата, [Займы руб],[Сумма займов инстоллмент план] from stg.files.ContactCenterPlans_buffer with(nolock) union all
select 'Полугодие' ТипД, case when month(Дата)<=6 then cast(format(Дата, 'yyyy-01-01')as date) else cast(format(Дата, 'yyyy-07-01')as date) end Дата, [Займы руб],[Сумма займов инстоллмент план] from stg.files.ContactCenterPlans_buffer with(nolock) union all
select 'Год' ТипД,dateadd(year, datediff(year, '1900-01-01', Дата), '1900-01-01')   Дата, [Займы руб],[Сумма займов инстоллмент план] from stg.files.ContactCenterPlans_buffer with(nolock)
),

pl as (
select ТипД = p.[ТипД], Дата = p.[Дата],
       Тип = 'План факт',
       группа = 'ПТС',
       Значение = try_cast(f.Значение as float)/nullif(sum([Займы руб]),0)
	   from plans p 
	   left join #report f on p.ТипД=f.ТипД and p.Дата=f.Дата
	   where f.Тип = 'Продажи руб' and f.группа = 'ПТС'
	   group by p.ТипД,p.Дата,f.Значение
union all
select ТипД = p.[ТипД], Дата = p.[Дата],
       Тип = 'План факт',
       группа = 'Беззалог',
       Значение = try_cast(f.Значение as float)/nullif(sum([Сумма займов инстоллмент план]),0)
	   from plans p 
	   left join #report f on p.ТипД=f.ТипД and p.Дата=f.Дата
	   where Тип = 'Продажи руб' and группа = 'Беззалог'
	   group by p.ТипД,p.Дата,f.Значение)

insert into #report select*from pl
;

with weeks_rr as (
  select Неделя
, min(Месяц) Месяц
, max(case when Дата<getdate()-1 and month(Неделя)=month(Дата) then Дата end) ДатаRR
from v_Calendar a
where Неделя<getdate()-1
group by	Неделя
),

rr_weeks as (
select Неделя
,Месяц
,ДатаRR	 
, sum(case when b.isPts=1 then b.[Выданная сумма] end)	/max([Доля месяца ПТС])	        [RR_По_Неделям_ПТС] 	      
, sum(case when b.isPts=0 then b.[Выданная сумма] end)	/max([Доля месяца Инстоллмент])	[RR_По_Неделям_Инстоллмент]
from (
select 
    a.Неделя 

,a.Месяц 
,a.ДатаRR 
,   sum(try_cast(b.[Доля месяца ПТС] 		 as float) ) [Доля месяца ПТС]
,   sum(try_cast(b.[Доля месяца Инстоллмент] as float)  ) [Доля месяца Инстоллмент]
 from 	weeks_rr a left join 
 stg.files.ContactCenterPlans_buffer_stg b with(nolock) on b.Дата between a.Месяц and a.ДатаRR
group by 
a.Неделя 

,a.Месяц 
,a.ДатаRR 	)
a left join  #dm_Factor_Analysis_1 b on cast(b.[Заем выдан] as date) between a.Месяц and a.ДатаRR
group by Неделя
,Месяц
,ДатаRR
),
rr as (
select ТипД = 'Неделя', Дата = Неделя,
       Тип = 'RR по неделям',
       группа = 'ПТС',
       Значение = RR_По_Неделям_ПТС
	   from rr_weeks
union all
select ТипД = 'Неделя', Дата = Неделя,
       Тип = 'RR по неделям',
       группа = 'Беззалог',
       Значение = RR_По_Неделям_Инстоллмент
	   from rr_weeks)


insert into #report select*from rr

;
with profit as(
select 'Неделя' ТипД, dateadd(day, datediff(day, '1900-01-01', [ДеньПлатежа]) / 7 * 7, '1900-01-01') Дата_,* from mv_repayments union all
select 'Месяц' ТипД,dateadd(month, datediff(month, '1900-01-01', [ДеньПлатежа]), '1900-01-01') Дата_,* from mv_repayments union all
select 'Квартал' ТипД,dateadd(quarter, datediff(quarter, '1900-01-01', [ДеньПлатежа]), '1900-01-01') Дата_,* from mv_repayments union all
select 'Полугодие' ТипД,case when month([ДеньПлатежа])<=6 then cast(format([ДеньПлатежа], 'yyyy-01-01')as date) else cast(format([ДеньПлатежа], 'yyyy-07-01')as date) end Дата_,* from mv_repayments  union all
select 'Год' ТипД,dateadd(year, datediff(year, '1900-01-01', [ДеньПлатежа]), '1900-01-01') Дата_,* from mv_repayments 
),

pr as(
select ТипД = ТипД, Дата = Дата_,
       Тип = 'Комиссия платежи',
       группа = 'Тотал',
       Значение = sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))
	   from profit
	   group by ТипД, Дата_
union all 	  
select ТипД = ТипД, Дата = Дата_,
       Тип = 'Комиссия платежи',
       группа = 'Беззалог',
       Значение = sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))
	   from profit
	   where IsInstallment=1
	   group by ТипД, Дата_
	   
	   
	   
	   
	   )

insert into #report select*from pr
--select * from #report
;

with sms as(
select 'Неделя' ТипД, [дата оплаты неделя] Дата, * from v_comissions_sales union all
select 'Месяц' ТипД, [дата оплаты месяц] Дата, * from v_comissions_sales union all
select 'Квартал' ТипД, [дата оплаты квартал] Дата, * from v_comissions_sales union all
select 'Полугодие' ТипД, case when month([дата оплаты день])<=6 then cast(format([дата оплаты день], 'yyyy-01-01')as date) else cast(format([дата оплаты день], 'yyyy-07-01')as date) end Дата, * from v_comissions_sales union all
select 'Год' ТипД, dateadd(year, datediff(year, '1900-01-01', [дата оплаты день]), '1900-01-01') Дата,* from v_comissions_sales 
),

ss as (
select ТипД = ТипД, Дата = Дата,
       Тип = 'Комиссии ПДП и СМС',
       группа = 'Тотал',
       Значение = sum(case when оплачено = 'СМС информирование' then [cумма услуги net] else 0 end)+sum(case when оплачено = 'Срочное снятие с залога' then [cумма услуги net] else 0 end)
	   from sms
	   group by ТипД, Дата)

insert into #report select*from ss
;

with conversion as(
select 'Неделя' ТипД, dateadd(day, datediff(day, '1900-01-01', День) / 7 * 7, '1900-01-01')  Дата, * from #product_report union all
select 'Месяц' ТипД, dateadd(month, datediff(month, '1900-01-01', День), '1900-01-01') Дата, * from #product_report union all
select 'Квартал' ТипД, dateadd(quarter, datediff(quarter, '1900-01-01', День), '1900-01-01') Дата, * from #product_report union all
select 'Полугодие' ТипД, case when month(День)<=6 then cast(format(День, 'yyyy-01-01')as date) else cast(format(День, 'yyyy-07-01')as date) end Дата, * from #product_report union all
select 'Год' ТипД,dateadd(YEAR, datediff(YEAR, '1900-01-01', День), '1900-01-01') Дата, * from #product_report
),

conv as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Реф. лиды',
       группа = [Группа каналов_2] ,
       Значение= nullif(sum(Лидов),0)
	   from conversion
	   where [Группа каналов_2] is not null	 and is_pts=1
	   group by ТипД,Дата, [Группа каналов_2]
union all
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Реф. лиды',
       группа = 'Тотал' ,
       Значение= nullif(sum(Лидов),0) 
	   from conversion
	   where [Группа каналов_2] is not null	  and is_pts=1  
	   group by ТипД,Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = 'Лиды ref трафик',
       группа = 'ПТС',
       Значение = sum(case when is_pts=1 then 1 else 0 end)
	   from conversion
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = 'Лид заявка ref',
       группа = 'ПТС',
       Значение = try_cast(sum(case when [Верификация кц] is not null and is_pts=1 then 1 else 0 end) as float) /nullif(sum(case when is_pts=1 then 1 else 0 end),0)
	   from conversion
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = 'Лиды ref трафик',
       группа = 'Беззалог',
       Значение = sum(case when is_pts=0 then 1 end)
	   from conversion
	   group by ТипД, Дата
union all
select ТипД = ТипД, Дата = Дата,
       Тип = 'Лид заявка ref',
       группа = 'Беззалог',
       Значение = try_cast(sum(case when [Верификация кц] is not null and is_pts=0 then 1 else 0 end) as float) /nullif(sum(case when is_pts=0 then 1 else 0 end),0)
	   from conversion
	   group by ТипД, Дата)

insert into #report select*from conv
;

with connect_ as(
select 'Неделя' ТипД, dateadd(day, datediff(day, '1900-01-01', attempt_start_date) / 7 * 7, '1900-01-01')  Дата, Стоимость from _birs.cost_of_calls union all
select 'Месяц' ТипД, dateadd(month, datediff(month, '1900-01-01', attempt_start_date), '1900-01-01')  Дата, Стоимость from _birs.cost_of_calls union all
select 'Квартал' ТипД, dateadd(quarter, datediff(quarter, '1900-01-01', attempt_start_date), '1900-01-01')  Дата, Стоимость from _birs.cost_of_calls union all
select 'Полугодие' ТипД, case when month(attempt_start_date)<=6 then cast(format(attempt_start_date, 'yyyy-01-01')as date) else cast(format(attempt_start_date, 'yyyy-07-01')as date) end Дата, Стоимость from _birs.cost_of_calls union all
select 'Год' ТипД, dateadd(year, datediff(year, '1900-01-01', attempt_start_date), '1900-01-01')  Дата, Стоимость from _birs.cost_of_calls
),

con as (
select ТипД = [ТипД], Дата = [Дата],
       Тип = 'Расходы на связь',
       группа = 'Тотал',
       Значение= sum(Стоимость)
	   from connect_
	   group by ТипД,Дата)

insert into #report select*from con


drop table if exists kpi_report_mail
select * into kpi_report_mail from #report

exec exec_python 'weekly_report_mail()' , 1


--exec exec_python 'by_date_report_mail()' , 1



--select * from 	_birs.kpi_report_by_date
--where ТипД='Месяц'	   and Дата>=getdate()-380
--order by Тип, группа, Дата

end

if @mode = 'select'
begin


select Дата Неделя, Тип, группа, значение from kpi_report_mail
where типд='Неделя' 


end
 