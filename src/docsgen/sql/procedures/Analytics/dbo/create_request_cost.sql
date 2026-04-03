
CREATE   proc [dbo].[create_request_cost]
as
begin


drop table if exists #call2
select cast(number as varchar(20)) Номер, cast(format( Call_date  , 'yyyy-MM-01') as date) [Call2 месяц проверки] into #call2 from stg._loginom.Originationlog where Stage='call 2'

;with v  as (select *, row_number() over(partition by Номер order by (select null)) rn from #call2 ) delete from v where rn>1

drop table if exists #fa
select Номер                                                
,      cast(format(ДатаЗаявкиПолная , 'yyyy-MM-01') as date) [Месяц заявки]
,      cast(ДатаЗаявкиПолная as date)     [День заявки]
,      cast(format([Заем выдан] , 'yyyy-MM-01') as date)     [Месяц займа]
--,      ДатаЗаявкиПолная                                     
,      case when [Заем выдан] is not null then 1 end         ПризнакЗайм
,      1         ПризнакЗаявка
,      [Верификация КЦ]                                     
,      [Группа каналов]                                     
,      [Канал от источника]                                 
,      [Вид займа]                                 
,      product         
,      [Выданная сумма]       
,      [Контроль данных]       
,      [Верификация документов клиента]       
,      [Верификация документов]       
,      Одобрено       
,      [Одобрены документы клиента]       
,      Аннулировано       
,      [Отказ клиента]       
,      Отказано       
,      [Отказ документов клиента]       
,      isInstallment       

into #fa
from reports.dbo.dm_factor_analysis



drop table if exists #base
select fa.Номер

,     [Выданная сумма]
,     [Отчет аллоцированные расходы CPA].[Расходы на CPA заявка]
,     [Отчет аллоцированные расходы CPA].[Расходы на CPA займ]
,     [Отчет аллоцированные расходы CPA].[Расходы на CPA лид]
,      [Отчет аллоцированные расходы CPA].[Расходы на CPA траты на заявку без заявки]
,      [Отчет аллоцированные расходы CPA].[Расходы на CPA mobishark трафик в МП]
,      [Отчет аллоцированные расходы CPA].[Безвозратные потери CPA]
,      [Отчет аллоцированные расходы CPA].[Расходы на CPA прочие]
,      [Отчет аллоцированные расходы CPA].[Расходы на CPA]


,      cast(null as float)            as [Расходы на CPA: не на займ]

,      cast(null as float)            as [Расходы на CPC (на первичные займы CPC)]
,      cast(null as float)            as [Расходы на CPC (на все займы CPC)]
,      cast(null as float)            as [Расходы на CPC (на все заявки CPC)]


,      cast(null as float)            as [Расходы на Медийку (на первичный займ)]
,      cast(null as float)            as [Расходы на Прочие маркетинговые (на первичный займ)]

,      cast(null as float)            as [Расходы на Партнеров: привлечение]
,      cast(null as float)            as [Расходы на Партнеров: оформление]

,      cast(null as float)            as [Расходы на риск-сервисы и верификацию: не на займ]
,      cast(null as float)            as [Расходы на постановку залога]
,      cast(null as float)            as [Расходы на проверки Call1]
,      cast(null as float)            as [Расходы на проверки Call1 по подписке]
,      cast(null as float)            as [Расходы на проверки Call2]
,      cast(null as float)            as [Расходы на проверки Call2 по подписке]
,      cast(null as float)            as [Расходы на верификаторов]
,      cast(null as float)            as [Расходы на верификаторов по подписке]
,      cast(null as float)            as [Расходы на чекеров]
,      cast(null as float)            as [Расходы на проверки]
,      cast(ps.Комиссия as float)     as [Расходы на ПШ (выдача)]
,      cast(null as float)            as [Расходы на КЦ (фот)]
,      cast(null as float)            as [Расходы на КЦ (it)]
,      cast(null as float)            as [Расходы на CPA: затраты на заявки без займа аллоцированные на займы]
,      cast(null as float)            as [Расходы на риск-сервисы и верификацию: затраты на заявки без займа аллоцированные на займы]

,      [Отчет аллоцированные расходы CPA].UF_SOURCE       
,      ПризнакЗайм
,      fa.[День заявки]
,      fa.[Месяц займа]
,      fa.[Месяц заявки]
,      fa.isInstallment
,      fa.product
,      fa.[Вид займа]
,      fa.[Группа каналов]                                     
,      fa.[Канал от источника] 
,      cast(format( [Верификация КЦ]  , 'yyyy-MM-01') as date)  [Call1 месяц проверки]
,      [Контроль данных] 

,      case when fa.[Контроль данных] is not null and (call2.[Call2 месяц проверки] is not null or [Верификация документов клиента] is not null or [Верификация документов] is not null)                       then 'Чекеры: одобренная заявка'
            when fa.[Контроль данных] is not null and (call2.[Call2 месяц проверки] is null    and [Верификация документов клиента] is null     and Отказано is not null)                                      then 'Чекеры: отказная заявка'
            when fa.[Контроль данных] is not null and (call2.[Call2 месяц проверки] is null    and [Верификация документов клиента] is null     and (Аннулировано is not null or [Отказ клиента] is not null)) then 'Чекеры: Аннулирование'
            when fa.[Контроль данных] is not null  then 'Чекеры: ?' end as [Результат проверки чекеров]

, cast(format( fa.[Верификация документов клиента]   , 'yyyy-MM-01') as date) [Верификация документов клиента месяц] 

,      call2.[Call2 месяц проверки] [Call2 месяц проверки]
, case when [Верификация документов клиента] is not null and ([Верификация документов] is not null or Одобрено is not null)  then 'Верификаторы (клиент): Одобрение клиента'
       when [Верификация документов клиента] is not null and [Верификация документов] is null and ([Отказ документов клиента] is not null or Отказано is not null)  then 'Верификаторы (клиент): Отказ клиента'
       when [Верификация документов клиента] is not null and  Аннулировано is not null and [Верификация документов] is null  then 'Верификаторы (клиент): Аннулирование' 
       when [Верификация документов клиента] is not null   then '?'  end [Результат верификаторов по клиенту]

, case when [Верификация документов] is not null and Одобрено is not null  then 'Верификаторы (авто): Полное одобрение'
       when [Верификация документов] is not null and Одобрено is null and  Аннулировано is not null  then 'Верификаторы (авто): Аннулирование' 
       when [Верификация документов] is not null and Одобрено is null and  Отказано is not null  then 'Верификаторы (авто): Отказано' 
       when [Верификация документов] is not null   then '?'  end [Результат верификаторов по авто]

, fa.[Одобрены документы клиента] 
, fa.Отказано 
, fa.Аннулировано 
into #base
from      #fa fa
left join #call2                              call2  on call2.Номер=fa.Номер
left join Analytics.dbo.v_payments ps on ps.Код=fa.Номер and fa.[Месяц займа]>='20200101'
left join Analytics.dbo.[Отчет аллоцированные расходы CPA] on [Отчет аллоцированные расходы CPA].Номер=fa.Номер

create clustered index clus_indname on #base
(
UF_SOURCE,
[Месяц займа],
[Месяц заявки]
)

---------------------------------------------------------------------
---------------------------------------------------------------------
--Партнеры
---------------------------------------------------------------------
---------------------------------------------------------------------
drop table if exists #Партнерские_расходы
SELECT r.Сумма Сумма, r.Заявка Заявка, 'Привлечение' [Тип трат]   into #Партнерские_расходы  
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 12.0; Database=D:\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx ', Партнеры_привлечение$)  r
--from Analytics.dbo.[_openrowset_Стоимость займа Партнеры_привлечение] r
from stg.files.[партнеры расходы на привлечение_stg] r
insert into    #Партнерские_расходы 
SELECT r.Сумма Сумма, r.Заявка Заявка, 'Оформление' [Тип трат]  
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 12.0; Database=D:\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx ', Партнеры_Оформление$)  r
--from Analytics.dbo.[_openrowset_Стоимость займа Партнеры_оформление] r
from stg.files.[партнеры расходы на оформление_stg] r
--select * from #Партнерские_расходы

	  update  b
	  set b.[Расходы на Партнеров: привлечение] =s.Сумма
	  from #base b join (select sum(Сумма) Сумма , Заявка from #Партнерские_расходы where [Тип трат]='Привлечение' group by Заявка ) s on b.Номер=s.Заявка
	  update  b
	  set b.[Расходы на Партнеров: оформление] =s.Сумма
	  from #base b join (select sum(Сумма) Сумма , Заявка from #Партнерские_расходы where [Тип трат]='Оформление' group by Заявка ) s on b.Номер=s.Заявка


	
	--------------------------------------
	--------------------------------------
	---Рисковые траты
	--------------------------------------
	--------------------------------------

	------------------подписочные сервисы

--СЕРВИС	Плата за месяц, руб.
--МОБАЙЛ СКОРИНГ (Call 1)	360 000
--ФССП (Call 1)	5 600


drop table if exists #Call1_по_подписке_на_одну_заявку
select [Call1 месяц проверки], (360000+5600)/cast(count(*) as float) [Расходы на проверки Call1 по подписке на 1 заявку] into #Call1_по_подписке_на_одну_заявку from #base 
where [Call1 месяц проверки] is not null and isInstallment=0
group by [Call1 месяц проверки]
	  update  b
	  set b.[Расходы на проверки Call1 по подписке] = a.[Расходы на проверки Call1 по подписке на 1 заявку]

from        #base b join #Call1_по_подписке_на_одну_заявку a on a.[Call1 месяц проверки]=b.[Call1 месяц проверки]
where b.[Call1 месяц проверки] is not null and isInstallment=0

--ГИБДД - Call 2	14 000
--ФНП - Call 2	2 800
--ФЕДРЕСУРС - Call 2	2 800


drop table if exists #Call2_по_подписке_на_одну_заявку
select [Call2 месяц проверки], (14000+2800+2800)/cast(count(*) as float) [Расходы на проверки Call2 по подписке на 1 заявку] into #Call2_по_подписке_на_одну_заявку from #base 
where [Call2 месяц проверки] is not null   
and isInstallment=0
group by [Call2 месяц проверки]
	  update  b
	  set b.[Расходы на проверки Call2 по подписке] = a.[Расходы на проверки Call2 по подписке на 1 заявку]

from        #base b join #Call2_по_подписке_на_одну_заявку a on a.[Call2 месяц проверки]=b.[Call2 месяц проверки]
where b.[Call2 месяц проверки] is not null
and isInstallment=0


--КРОНОС (UW)	83 334
--СПАРК (UW)	124 667



drop table if exists #Верификаторы_по_подписке_на_одну_заявку
select [Верификация документов клиента месяц], (83334+124667)/cast(count(*) as float) [Расходы на верификаторов по подписке на одну заявку] into #Верификаторы_по_подписке_на_одну_заявку from #base 
where [Верификация документов клиента месяц] is not null  and isInstallment=0
group by [Верификация документов клиента месяц]
	  update  b
	  set b.[Расходы на верификаторов по подписке] = a.[Расходы на верификаторов по подписке на одну заявку]

from        #base b join #Верификаторы_по_подписке_на_одну_заявку a on a.[Верификация документов клиента месяц]=b.[Верификация документов клиента месяц]
where b.[Верификация документов клиента месяц] is not null
and isInstallment=0


	------------------затраты по конкретной заявке


update  b
set b.[Расходы на проверки Call1] = case when b.[Вид займа]='Первичный' then 46.65648944 else 47.43232252 end
from #base b
where b.[Call1 месяц проверки] is not null  and b.isInstallment=0



update  b
set b.[Расходы на проверки Call2] = case when b.[Вид займа]='Первичный' then 12.82873872 else 12.91837589 end


from        #base b
where b.[Call2 месяц проверки] is not null and b.isInstallment=0





	  update  b
	  set b.[Расходы на чекеров] = case when [Результат проверки чекеров]='Чекеры: одобренная заявка' then case when b.[Вид займа]='Первичный' then 32.4883333333333 else 28.6283333333333 end
                                          when [Результат проверки чекеров]='Чекеры: отказная заявка' then   case when b.[Вид займа]='Первичный' then 12.545 else 13.8316666666667 end
                                          when [Результат проверки чекеров]='Чекеры: Аннулирование' then     case when b.[Вид займа]='Первичный' then 18.9783333333333 else 21.23 end end

from        #base b 
where isInstallment=0



	  update  b
	  set b.[Расходы на верификаторов] = case      when [Результат верификаторов по авто]=     'Верификаторы (авто): Полное одобрение' then case when b.[Вид займа]='Первичный' then 127.476666666667 else 113.736666666667 end
                                                              when [Результат верификаторов по авто]=     'Верификаторы (авто): Отказано'         then case when b.[Вид займа]='Первичный' then 157.628333333333 else 122.133333333333 end 
                                                              when [Результат верификаторов по авто]=     'Верификаторы (авто): Аннулирование'    then case when b.[Вид займа]='Первичный' then 143.125          else 124.041666666667 end
                                                                 when [Результат верификаторов по клиенту]='Верификаторы (клиент): Аннулирование'  then case when b.[Вид займа]='Первичный' then 125.5697165315   else 116.372688185667 end 
                                                                 when [Результат верификаторов по клиенту]='Верификаторы (клиент): Отказ клиента'  then case when b.[Вид займа]='Первичный' then 64.5016666666667 else 58.0133333333333 end
																 end

from        #base b
where isInstallment=0



	  update  b
	  set b.[Расходы на постановку залога] = 600

from        #base b
where b.[Месяц займа] is not null  and b.isInstallment=0

	--------------------------------------
	--------------------------------------
	---Расходы от департаментов
	--------------------------------------
	--------------------------------------

	drop table if exists #costs_from_departments_ole
SELECT  cast(Месяц as date) month 
       ,Медийка_ПТС =                                       cast([Медийка ПТС]                          as float)  
       ,Медийка_Инстоллмент =                                       cast([Медийка инстоллмент]                          as float)  
       ,Контекст_ПТС =                                      cast(Контекст						  as float) 
       ,[Прочие маркетинговые расходы_ПТС] =                cast(ПрочиеМаркетинговыеРасходы		  as float) 
       ,[Расходы на КЦ_ПТС] =                               cast(ИТКц							  as float)*(1-cast(ДоляИнстоллмент				  as float)) + cast(ФОТКц							  as float)*(1-cast(0				  as float)) 
       ,[Расходы на КЦ (it)_ПТС] =                          cast(ИТКц							  as float)*(1-cast(ДоляИнстоллмент				  as float)) 
       ,[Расходы на КЦ (фот)_ПТС] =                         cast(ФОТКц							  as float)*(1-cast(0				  as float)) 
       ,[Расходы на КЦ_инстоллмент] =                               cast(ИТКц							  as float)*(cast(ДоляИнстоллмент				  as float)) +cast(ФОТКц							  as float)*(cast(0				  as float)) 
       ,[Расходы на КЦ (it)_инстоллмент] =                          cast(ИТКц							  as float)*(cast(ДоляИнстоллмент				  as float)) 
       ,[Расходы на КЦ (фот)_инстоллмент] =                         cast(ФОТКц							  as float)*(cast(0				  as float)) 
       ,[Доля трат на повторных (фот)]                   = cast(ДоляПовторныхФОТ				  as float) 
       ,[Доля трат на повторных (it)]                    = cast(ДоляПовторныхИТ				  as float) 
	   ,[Расходы на трафик CPA mobishark в МП]           = cast([Расходы на трафик CPA mobishark в МП]   as float)
	   ,[Безвозратные потери CPA_ПТС]                        = cast([Безвозратные потери CPA]				  as float)
	 --  ,[Расходы на CPA опер_ПТС]                            = cast([Расходы на CPA опер]				  as float)
	   ,[Прочие расходы CPA ПТС]                            = cast([Прочие расходы CPA ПТС]				  as float)
	   ,ДоляИнстоллмент                                  = cast(ДоляИнстоллмент				  as float)
	   ,[Расходы на 1 займ инстоллмент проверки]                                  = cast([Расходы на 1 займ инстоллмент проверки]				  as float)
	   into #costs_from_departments_ole
  --  FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 12.0; Database=D:\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx ', Агрегированные_Данные$)  r
   -- from Analytics.dbo.[_openrowset_Стоимость займа Агрегированные_Данные] r
    from stg.files.[расходы по месяцам от подразделений_stg] r

	where  cast(Месяц as date) is not null

	--	select * from #costs_from_departments_ole

	drop table if exists #costs_from_departments
	select 
	
			month
			, Контекст_ПТС
			, [Контекст на один первичный займ CPC_ПТС] = Контекст_ПТС/Займов_CPC_первичных_ПТС.Займов_CPC_первичных_ПТС
			, [Контекст на один займ CPC_ПТС] = Контекст_ПТС/Займов_CPC_ПТС.Займов_CPC_ПТС           
		--	, [Расходы CPA mobishark на одну заявку] = [Расходы на трафик CPA mobishark в МП]/[Трафик CPA mobishark в МП].[Трафик CPA mobishark в МП]           
		--	, [Безвозратные потери CPA на одну заявку_ПТС] = [Безвозратные потери CPA_ПТС]/[Заявок CPA_ПТС].[Заявок CPA_ПТС]           
			, [Контекст на одну заявку CPC_ПТС] = Контекст_ПТС/Заявок_CPC_ПТС.Заявок_CPC_ПТС 
		--	, [Прочие расходы CPA на один займ CPA_ПТС] = [Прочие расходы CPA ПТС]/Займов_CPA_ПТС.Займов_CPA_ПТС 

			, Медийка_ПТС
			, [Медийка на один займ_ПТС]          = Медийка_ПТС/Займов_всего_ПТС.Займов_всего_ПТС 
			, [Медийка на один первичный займ_ПТС] = Медийка_ПТС/Первичных_займов_ПТС.Первичных_займов_ПТС 
			, [Медийка на один первичный займ_инстоллмент] = Медийка_Инстоллмент/Первичных_займов_инстоллмент.Первичных_займов_инстоллмент
			, [Прочие маркетинговые расходы_ПТС]
			, [Прочие маркетинговые расходы на один займ_ПТС]       = [Прочие маркетинговые расходы_ПТС]/Займов_всего_ПТС.Займов_всего_ПТС 
			, [Прочие маркетинговые расходы на один первичный займ_ПТС] = [Прочие маркетинговые расходы_ПТС]/Первичных_займов_ПТС.Первичных_займов_ПТС

			, [Расходы на КЦ (фот)_ПТС]
			, [Доля трат на повторных (фот)]
			, [Расходы на КЦ (IT)_ПТС]
			, [Доля трат на повторных (it)]

			, [Расходы на КЦ (фот) на один первичный займ_ПТС] = ([Расходы на КЦ (фот)_ПТС]*(1-[Доля трат на повторных (фот)]))/Первичных_займов_ПТС.Первичных_займов_ПТС 
			, [Расходы на КЦ (it) на один первичный займ_ПТС] =  ([Расходы на КЦ (it)_ПТС]*(1-[Доля трат на повторных (it)]))/Первичных_займов_ПТС.Первичных_займов_ПТС
			 
			, [Расходы на КЦ (фот) на один повторный займ_ПТС] = ([Расходы на КЦ (фот)_ПТС]*([Доля трат на повторных (фот)]))/Повторных_займов_ПТС.Повторных_займов_ПТС
			, [Расходы на КЦ (it) на один повторный займ_ПТС] = ([Расходы на КЦ (it)_ПТС]*([Доля трат на повторных (it)]))/Повторных_займов_ПТС.Повторных_займов_ПТС 
			 
			, [Расходы на КЦ (фот) на один займ_инстоллмент] = ([Расходы на КЦ (фот)_инстоллмент])/Займов_всего_инстоллмент.Займов_всего_инстоллмент
			, [Расходы на КЦ (it) на один займ_инстоллмент]  = ([Расходы на КЦ (it)_инстоллмент]) /Займов_всего_инстоллмент.Займов_всего_инстоллмент

		--	, [Расходы на CPA опер на один CPA займ_ПТС]   = ([Расходы на CPA опер_ПТС])/[Займов CPA_ПТС]
			, [Расходы на 1 займ инстоллмент проверки]   = [Расходы на 1 займ инстоллмент проверки]
		--	, [Расходы на CPA: не на займ аллоцированные на первичный займ] = [Расходы на CPA: не на займ первичные]/Первичных_займов.Первичных_займов 
		--	, [Расходы на CPA: не на займ аллоцированные на повторный займ] = [Расходы на CPA: не на займ повторные]/Повторных_займов.Повторных_займов 
		--	
		--	, [Расходы на риск-сервисы и верификацию: не на займ аллоцированные на первичный займ] = [Расходы на риск-сервисы и верификацию: не на займ первичные]/Первичных_займов.Первичных_займов 
		--	, [Расходы на риск-сервисы и верификацию: не на займ аллоцированные на повторный займ] = [Расходы на риск-сервисы и верификацию: не на займ повторные]/Повторных_займов.Повторных_займов 


		--	, ФОТКц/ВыдачВсего.ВыдачВсего ФОТКцНаОднуВыдачу
		--	, RoboIVR/ВыдачВсего.ВыдачВсего RoboIVRНаОднуВыдачу
		--	, ИсходящиеКампанииКромеRoboIVR/ВыдачВсего.ВыдачВсего ИсходящиеКампанииКромеRoboIVRНаОднуВыдачу
		--	, ПрочиеРасходыКЦ/ВыдачВсего.ВыдачВсего ПрочиеРасходыКЦНаОднуВыдачу
			


			into #costs_from_departments 
			
from #costs_from_departments_ole
	costs_from_departments
	outer apply( select nullif(cast(count(*) as float), 0) Заявок_CPC_ПТС                   from #base b where isinstallment=0 and b.[Месяц заявки]=costs_from_departments.month and [Группа каналов]='CPC' ) Заявок_CPC_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Займов_CPC_первичных_ПТС         from #base b where isinstallment=0 and b.[Месяц займа]=costs_from_departments.month and [Группа каналов]='CPC' and [Вид займа]='Первичный'  ) Займов_CPC_первичных_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Займов_CPA_ПТС                   from #base b where isinstallment=0 and b.[Месяц займа]=costs_from_departments.month and [Группа каналов]='CPA'   ) Займов_CPA_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Займов_CPC_ПТС                   from #base b where isinstallment=0 and b.[Месяц займа]=costs_from_departments.month and [Группа каналов]='CPC'   ) Займов_CPC_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Займов_всего_ПТС                 from #base b where isinstallment=0 and b.[Месяц займа]= costs_from_departments.month ) Займов_всего_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Первичных_займов_ПТС             from #base b where isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]='Первичный') Первичных_займов_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) Повторных_займов_ПТС             from #base b where isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]<>'Первичный') Повторных_займов_ПТС
	outer apply( select nullif(cast(count(*) as float), 0) [Заявок CPA_ПТС]                 from #base b where isinstallment=0 and b.[Месяц заявки]= costs_from_departments.month and [Группа каналов]='CPA') [Заявок CPA_ПТС]
	outer apply( select nullif(cast(count(*) as float), 0) [Займов CPA_ПТС]                 from #base b where isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Группа каналов]='CPA') [Займов CPA_ПТС]

	--outer apply( select nullif(cast(count(*) as float), 0) Заявок_CPC_инстоллмент                   from #base b where isinstallment=1 and b.[Месяц заявки]=costs_from_departments.month and [Группа каналов]='CPC' ) Заявок_CPC_инстоллмент
	--outer apply( select nullif(cast(count(*) as float), 0) Займов_CPC_первичных_инстоллмент         from #base b where isinstallment=1 and b.[Месяц займа]=costs_from_departments.month and [Группа каналов]='CPC' and [Вид займа]='Первичный'  ) Займов_CPC_первичных_инстоллмент
	--outer apply( select nullif(cast(count(*) as float), 0) Займов_CPC_инстоллмент                   from #base b where isinstallment=1 and b.[Месяц займа]=costs_from_departments.month and [Группа каналов]='CPC'   ) Займов_CPC_инстоллмент
	outer apply( select nullif(cast(count(*) as float), 0) Займов_всего_инстоллмент                 from #base b where isinstallment=1 and b.[Месяц займа]= costs_from_departments.month ) Займов_всего_инстоллмент
	outer apply( select nullif(cast(count(*) as float), 0) Первичных_займов_инстоллмент             from #base b where isinstallment=1 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]='Первичный') Первичных_займов_инстоллмент
	outer apply( select nullif(cast(count(*) as float), 0) Повторных_займов_инстоллмент             from #base b where isinstallment=1 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]<>'Первичный') Повторных_займов_инстоллмент
	--outer apply( select nullif(cast(count(*) as float), 0) [Заявок CPA_инстоллмент]                 from #base b where isinstallment=1 and b.[Месяц заявки]= costs_from_departments.month and [Группа каналов]='CPA') [Заявок CPA_инстоллмент]
	--outer apply( select nullif(cast(count(*) as float), 0) [Займов CPA_инстоллмент]                 from #base b where isinstallment=1 and b.[Месяц займа]= costs_from_departments.month and [Группа каналов]='CPA') [Займов CPA_инстоллмент]

	--outer apply( select nullif(cast(count(*) as float), 0) [Трафик CPA mobishark в МП]  from #base b where  b.[Месяц заявки]= costs_from_departments.month and [CPA трафик в МП источник]='Mobishark') [Трафик CPA mobishark в МП]

--	select * from #costs_from_departments
	
	  update  b
	  set b.[Расходы на проверки] =x.[Расходы на 1 займ инстоллмент проверки]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month
		and b.isInstallment=1
	)             x	


--	  update  b
--	  set b.[Расходы на CPA опер] =x.[Расходы на CPA опер на один CPA займ_ПТС]
--
--from        #base b
--cross apply (select top 1 *
--	from #costs_from_departments
--	x
--	where  b.[Месяц займа]=x.month
--		and b.[Группа каналов]='CPA'
--		and b.isInstallment=0
--	)             x
	
	  update  b
	  set b.[Расходы на CPC (на все заявки CPC)] =x.[Контекст на одну заявку CPC_ПТС]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц заявки]=x.month
		and b.[Группа каналов]='CPC'
		and b.isInstallment=0

	)             x



	
	  update  b
	  set b.[Расходы на CPC (на первичные займы CPC)]  =x.[Контекст на один первичный займ CPC_ПТС]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month
		and b.[Группа каналов]='CPC'
		 and [Вид займа]='Первичный'
		and b.isInstallment=0

	)             x

	
	
	
	  update  b
	  set b.[Расходы на CPC (на все займы CPC)] =x.[Контекст на один займ CPC_ПТС]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month
		and b.[Группа каналов]='CPC'
		and b.isInstallment=0

	)             x

	
	  update  b
	  set b.[Расходы на Медийку (на первичный займ)] =x.[Медийка на один первичный займ_ПТС],
	      b.[Расходы на Прочие маркетинговые (на первичный займ)] =x.[Прочие маркетинговые расходы на один первичный займ_ПТС]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month
		and b.[Вид займа]='Первичный'
		and b.isInstallment=0

	)             x


	
	  update  b
	  set b.[Расходы на Медийку (на первичный займ)] =x.[Медийка на один первичный займ_инстоллмент]

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month
		and b.[Вид займа]='Первичный'
		and b.isInstallment=1

	)             x


	
	  update  b
	  set b.[Расходы на КЦ (фот)] =case when b.[Вид займа] = 'Первичный' and b.isInstallment=0 then  x.[Расходы на КЦ (фот) на один первичный займ_ПТС]
	                                    when b.[Вид займа] <> 'Первичный' and b.isInstallment=0 then x.[Расходы на КЦ (фот) на один повторный займ_ПТС] 
	                                    when  b.isInstallment=1 then x.[Расходы на КЦ (фот) на один займ_инстоллмент] 
									
										end  ,
	      b.[Расходы на КЦ (it)]  =case when b.[Вид займа] = 'Первичный' and b.isInstallment=0 then  x.[Расходы на КЦ (it) на один первичный займ_ПТС]
	                                    when b.[Вид займа] <> 'Первичный' and b.isInstallment=0 then x.[Расходы на КЦ (it) на один повторный займ_ПТС] 
	                                    when  b.isInstallment=1 then x.[Расходы на КЦ (it) на один займ_инстоллмент] 
									
										end  

from        #base b
cross apply (select top 1 *
	from #costs_from_departments
	x
	where  b.[Месяц займа]=x.month --and b.[Вид займа]='Первичный'
	)             x

--Просьба Баранова. Риски.
	  update  b
	  set b.[Расходы на CPA: не на займ] = case when ПризнакЗайм is null then nullif(isnull([Безвозратные потери CPA], 0)+isnull([Расходы на CPA mobishark трафик в МП], 0)+isnull([Расходы на CPA займ], 0)+isnull([Расходы на CPA заявка], 0)+isnull([Расходы на CPA лид], 0)+isnull([Расходы на CPA прочие], 0)+isnull([Расходы на CPA траты на заявку без заявки], 0) , 0) end 

from        #base b

	  update  b
	  set b.[Расходы на риск-сервисы и верификацию: не на займ] =  case when ПризнакЗайм is null then nullif(
        isnull([Расходы на проверки Call1]                    , 0) +
        isnull([Расходы на проверки Call2]                    , 0) +
        isnull([Расходы на проверки Call1 по подписке]		 , 0) +
        isnull([Расходы на проверки Call2 по подписке]		 , 0) +
        isnull([Расходы на верификаторов]		             , 0) +
        isnull([Расходы на верификаторов по подписке]		 , 0) +
        isnull([Расходы на чекеров]     	                     , 0) +
        isnull([Расходы на постановку залога]		         , 0) 
, 0) end 
from        #base b

--Просьба Баранова. Риски.

drop table if exists #requests_without_loan_info ;

select costs_from_departments.month
	    	, [Расходы на CPA: не на займ аллоцированные на первичный займ_ПТС] = [Расходы на CPA: не на займ первичные_ПТС]/Первичных_займов_ПТС.Первичных_займов_ПТС 
			, [Расходы на CPA: не на займ аллоцированные на повторный займ_ПТС] = [Расходы на CPA: не на займ повторные_ПТС]/Повторных_займов_ПТС.Повторных_займов_ПТС 
			, [Расходы на CPA: не на займ аллоцированные на все займы_инстоллмент] = [Расходы на CPA: не на займ_инстоллмент]/Займов_Инстоллмент.Займов_Инстоллмент 
			
			, [Расходы на риск-сервисы и верификацию: не на займ аллоцированные на первичный займ_ПТС] = [Расходы на риск-сервисы и верификацию: не на займ первичные_ПТС]/Первичных_займов_ПТС.Первичных_займов_ПТС 
			, [Расходы на риск-сервисы и верификацию: не на займ аллоцированные на повторный займ_ПТС] = [Расходы на риск-сервисы и верификацию: не на займ повторные_ПТС]/Повторных_займов_ПТС.Повторных_займов_ПТС 
			, [Расходы на риск-сервисы и верификацию: не на займ аллоцированные на все займы_инстоллмент] = [Расходы на риск-сервисы и верификацию: не на займ_инстоллмент]/Займов_Инстоллмент.Займов_Инстоллмент 
into #requests_without_loan_info
from 
#costs_from_departments_ole  costs_from_departments
outer apply( select nullif(cast(count(*) as float), 0) Первичных_займов_ПТС from #base b where b.isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]='Первичный') Первичных_займов_ПТС
outer apply( select nullif(cast(count(*) as float), 0) Повторных_займов_ПТС from #base b where b.isinstallment=0 and b.[Месяц займа]= costs_from_departments.month and [Вид займа]<>'Первичный') Повторных_займов_ПТС
left join (select  [Месяц заявки] , sum([Расходы на CPA: не на займ]) [Расходы на CPA: не на займ первичные_ПТС] , sum ([Расходы на риск-сервисы и верификацию: не на займ]) [Расходы на риск-сервисы и верификацию: не на займ первичные_ПТС] from #base b where isinstallment=0 and [Вид займа]='Первичный' group by [Месяц заявки] ) Траты_не_на_займ_первичные_ПТС on Траты_не_на_займ_первичные_ПТС.[Месяц заявки]=costs_from_departments.month
left join (select  [Месяц заявки] , sum([Расходы на CPA: не на займ]) [Расходы на CPA: не на займ повторные_ПТС] , sum ([Расходы на риск-сервисы и верификацию: не на займ]) [Расходы на риск-сервисы и верификацию: не на займ повторные_ПТС] from #base b where isinstallment=0 and [Вид займа]<>'Первичный' group by [Месяц заявки] ) Траты_не_на_займ_повторные_ПТС on Траты_не_на_займ_повторные_ПТС.[Месяц заявки]=costs_from_departments.month

outer apply( select nullif(cast(count(*) as float), 0) Займов_Инстоллмент from #base b where b.isinstallment=1 and b.[Месяц займа]= costs_from_departments.month ) Займов_Инстоллмент
left join (select  [Месяц заявки] , sum([Расходы на CPA: не на займ]) [Расходы на CPA: не на займ_инстоллмент] , sum ([Расходы на риск-сервисы и верификацию: не на займ]) [Расходы на риск-сервисы и верификацию: не на займ_инстоллмент] from #base b where isinstallment=1  group by [Месяц заявки] ) Траты_не_на_займ_инстоллмент on Траты_не_на_займ_инстоллмент.[Месяц заявки]=costs_from_departments.month

		
	  update  b
	  set b.[Расходы на CPA: затраты на заявки без займа аллоцированные на займы] =case     when b.[Вид займа] = 'Первичный'  and isInstallment=0  then  x.[Расходы на CPA: не на займ аллоцированные на первичный займ_ПТС] 
	                                                                                        when b.[Вид займа] <> 'Первичный' and isInstallment=0  then x.[Расходы на CPA: не на займ аллоцированные на повторный займ_ПТС] 
	                                                                                        when  isInstallment=1                                  then x.[Расходы на CPA: не на займ аллоцированные на все займы_инстоллмент] 
																							end  ,
	      b.[Расходы на риск-сервисы и верификацию: затраты на заявки без займа аллоцированные на займы]  =case when b.[Вид займа] = 'Первичный' and isInstallment=0  then  x.[Расходы на риск-сервисы и верификацию: не на займ аллоцированные на первичный займ_ПТС] 
		                                                                                                        when b.[Вид займа] = 'Первичный' and isInstallment=0  then x.[Расходы на риск-сервисы и верификацию: не на займ аллоцированные на повторный займ_ПТС] 
													                                                            when  isInstallment=1                                then x.[Расходы на риск-сервисы и верификацию: не на займ аллоцированные на все займы_инстоллмент]
																												end


from        #base b
cross apply (select top 1 *
	from #requests_without_loan_info
	x
	where  b.[Месяц займа]=x.month --and b.[Вид займа]='Первичный'
	)             x



	--select * from request_cost2
	--where isInstallment=0
	--order by [Отчетная дата] desc

;
drop table if exists request_cost2 ;
with v as(

select Номер                 
,      case when [Месяц займа] is not null then [Месяц займа] else [Месяц заявки] end as [Отчетная дата]
,      [Расходы на Партнеров: привлечение]                                                                                                          
,      [Расходы на Партнеров: оформление]

,      [Расходы на CPA займ]                                                                                                          
,      [Расходы на CPA заявка]                                                                                                        
,      [Расходы на CPA лид] 
,      [Расходы на CPA mobishark трафик в МП] 
,      [Безвозратные потери CPA] 
,      [Расходы на CPA: затраты на заявки без займа аллоцированные на займы]
,      [Расходы на CPA прочие]
,      [Расходы на CPA]
,      UF_SOURCE     
,      [Расходы на CPC (на все займы CPC)]
,      [Расходы на CPC (на все заявки CPC)]
,      [Расходы на CPC (на первичные займы CPC)]


,      [Расходы на Медийку (на первичный займ)]
,      [Расходы на Прочие маркетинговые (на первичный займ)]

,      [Расходы на Медийку и Прочие маркетинговые (на первичный займ)] = nullif(isnull([Расходы на Медийку (на первичный займ)], 0)+isnull([Расходы на Прочие маркетинговые (на первичный займ)], 0) , 0) 



,        [Верификация документов клиента месяц]
,        [Результат верификаторов по авто]
,        [Результат верификаторов по клиенту]
,        [Результат проверки чекеров]
,        [Call1 месяц проверки]
,        [Call2 месяц проверки]
,        [Расходы на проверки Call1]
,        [Расходы на проверки Call2]
,        [Расходы на проверки Call1 по подписке]
,        [Расходы на проверки Call2 по подписке]
,        [Расходы на верификаторов]
,        [Расходы на верификаторов по подписке]
,        [Расходы на чекеров]
,        [Расходы на постановку залога]

,       

nullif(
        isnull([Расходы на проверки]                    , 0) +
        isnull([Расходы на проверки Call1]                    , 0) +
        isnull([Расходы на проверки Call2]                    , 0) +
        isnull([Расходы на проверки Call1 по подписке]		 , 0) +
        isnull([Расходы на проверки Call2 по подписке]		 , 0) +
        isnull([Расходы на верификаторов]		             , 0) +
        isnull([Расходы на верификаторов по подписке]		 , 0) +
        isnull([Расходы на чекеров]     	                     , 0) +
        isnull([Расходы на постановку залога]		         , 0) 
, 0) [Расходы на риск-сервисы и верификацию],   
[Расходы на риск-сервисы и верификацию: затраты на заявки без займа аллоцированные на займы], 

nullif(
        isnull( [Расходы на Партнеров: привлечение]                                  , 0) +
        isnull( [Расходы на Партнеров: оформление]                                  , 0) +
        isnull( [Расходы на CPA]                                  , 0) +
    
        isnull( [Расходы на CPC (на первичные займы CPC)]                                  , 0) +
        isnull( [Расходы на Медийку (на первичный займ)]                                  , 0) +
        isnull( [Расходы на Прочие маркетинговые (на первичный займ)]                                  , 0) +
        isnull( [Расходы на проверки]                                  , 0) +
        isnull( [Расходы на проверки Call1]                                  , 0) +
        isnull( [Расходы на проверки Call2]                                  , 0) +
        isnull( [Расходы на проверки Call1 по подписке]					 , 0) +
        isnull( [Расходы на проверки Call2 по подписке]			 , 0) +
        isnull( [Расходы на верификаторов]								 , 0) +
        isnull( [Расходы на верификаторов по подписке]	         	 , 0) +
        isnull( [Расходы на чекеров]							 , 0) +
        isnull( [Расходы на постановку залога]							 , 0) +
        isnull( [Расходы на ПШ (выдача)]							 , 0) +
        isnull( [Расходы на КЦ (фот)]							 , 0) +
        isnull( [Расходы на КЦ (it)]							 , 0) 
, 0) [Расходы]
,       [Расходы на заявки без выдачи] = nullif(isnull([Расходы на риск-сервисы и верификацию: затраты на заявки без займа аллоцированные на займы], 0)+isnull([Расходы на CPA: затраты на заявки без займа аллоцированные на займы],0) , 0) ,

nullif(
        isnull( [Расходы на КЦ (фот)]							 , 0) +
        isnull( [Расходы на КЦ (it)]							 , 0) 
, 0) [Расходы на КЦ]

,        [Расходы на ПШ (выдача)]

,        [Расходы на КЦ (фот)]
,        [Расходы на КЦ (it)]


,       ПризнакЗайм                                                                                                             
,       [Месяц заявки]                                                                                                        
,       [Месяц займа]                                                                                                             
,       product                                                                                                             
,       [Выданная сумма]                                                                                                             
,       [Вид займа]                                                                                                             
,       case when [Группа каналов]   ='cpa'    then  [Канал от источника] else     [Группа каналов] end Канал                                                                                     
,	     [Группа каналов]
,	     [Канал от источника]
,       isInstallment    
,       [День заявки]    
,       GETDATE() created
from #base 
--left join  Analytics.dbo.[Каналы ЛСРМ по новой методологии] on [Каналы ЛСРМ по новой методологии].UF_ROW_ID=#base.Номер
)


select * into request_cost2 from v 
where [Отчетная дата] between '20200101' and '20220331'

create clustered index clus_Номер on request_cost2
(
Номер
)

--select * from  request_cost2
--where [Расходы на CPA mobishark трафик в МП] is not null

--select * from stg.files.[cpa расходы_stg] where МесяцГод='2021-12-01 00:00:00.000' and Лидген like'%bankiru%'
--
--select sum([Расходы на CPA опер]), sum([Расходы на CPA mobishark трафик в МП]) from request_cost
--where [Месяц заявки]='20211101'

end