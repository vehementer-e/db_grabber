
CREATE   proc [dbo].[Подготовка отчета Инстоллмент общение с оператором]		 @m nvarchar(max) = 's'
as

begin

if @m = 'u'


begin

drop table if exists #t1
SELECT [Тип трафика]
	,'8'+Телефон  Телефон8
	,Номер
	,[Место cоздания]
	,[Выданная сумма]
	,[Верификация КЦ]   [Верификация КЦ]
	,[Предварительное одобрение]    [Предварительное одобрение]
	,[Контроль данных]	  [Контроль данных]
	,[Аннулировано]	  [Аннулировано]
	,[Заем аннулирован]	   [Заем аннулирован]
	,Одобрено	   Одобрено
	,Отказано	  Отказано
	,[Заем выдан]  [Заем выдан]
	into #t1
FROM reports.dbo.dm_factor_analysis_001
WHERE ispts = 0
	AND [Верификация КЦ] >= '20230101' and Дубль=0
ORDER BY [Верификация КЦ]


drop table if exists #phones

select distinct Телефон8  into #phones from #t1
 

drop table if exists #calls

select try_cast(phonenumbers as nvarchar(11)) Телефон8, attempt_start dt  into #calls from Feodor.dbo.dm_calls_history	  a
join 		#phones b on  b.Телефон8	  =a.phonenumbers and a.attempt_start>='20221231'	  and a.login is not null


drop table if exists #crm


select ДатаВремяВзаимодействия dt, '8'+НомерТелефона	    Телефон8
 
   into   #crm
from
v_communication_crm n
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
	  and ДатаВремяВзаимодействия		 >='20221231'

drop table if exists #all_calls
						   

select dt, try_cast(Телефон8 as nvarchar(11))  Телефон8
into #all_calls						

from   #crm
union all
select 	  dt, Телефон8 
from 	 #calls





	create nonclustered index noncl_indname on #calls
	(
	dt,   Телефон8
	)

	create nonclustered index noncl_indname on #all_calls
	(
	dt,   Телефон8
	)





						
drop table if exists #t2

SELECT a.* 

 , case when x1.dt is not null then 'Звонок (пока активна заявка)' else 'Нет' end [Оформление]
 , case when x_predodobr_kd.dt is not null then 'Звонок (доезд)' else 'Нет' end [Оформление доезд]
 , case when x_tu.dt is not null then 'Звонок (TU)' else 'Нет' end [Оформление TU]
 , case when x.dt is not null then 'Звонок TLS в теч дня' else 'Нет' end [Привлечение]

 , case when x.dt  is not null or x1.dt is not null then 'Звонок'  else 'Нет' end [Контакт с оператором]
  , isnull([Заем выдан], [Верификация КЦ])				[Отчетная дата]
 , cast(format(isnull([Заем выдан], [Верификация КЦ])   , 'yyyy-MM-01') as date)  [Отчетная дата месяц]
into #t2
FROM #t1 a
OUTER APPLY (
	SELECT TOP 1  dt,  Телефон8
	FROM #calls b
	WHERE  a.Телефон8 = b.Телефон8
		AND b.dt <= a.[Верификация КЦ]
		AND b.dt >= dateadd(day, - 1, cast(a.[Верификация КЦ] AS DATE))
	)  x
  
OUTER APPLY (
	SELECT TOP 1 dt,  Телефон8
	FROM #all_calls b
	WHERE   a.Телефон8 = b.Телефон8
		AND b.dt  between a.[Верификация КЦ] and isnull( isnull(isnull(a.Отказано, a.[Заем выдан])	, a.Аннулировано), a.[Заем аннулирован])
	)  x1

OUTER APPLY (
	SELECT TOP 1 dt,  Телефон8
	FROM #all_calls b
	WHERE   a.Телефон8 = b.Телефон8
		AND b.dt  between a.[Предварительное одобрение] and isnull( isnull(isnull(a.[Контроль данных], a.Аннулировано)	, a.[Заем аннулирован]), a.Отказано)
	)  x_predodobr_kd
			
OUTER APPLY (
	SELECT TOP 1 dt,  Телефон8
	FROM #all_calls b
	WHERE   a.Телефон8 = b.Телефон8
		AND b.dt  between a.Одобрено and isnull( isnull( a.[Заем выдан]	, a.[Заем аннулирован]), a.Аннулировано)
	)  x_tu
							
					

					drop table if exists ##t2

 select *
 into ##t2
 
 from #t2

	end


	if @m = 's'

	begin

	   select * from ##t2


	end

if @m = 'bankiru-installment-context'

	begin	

drop table if exists  [#bankiru-installment-context]

select    phonenumber, id, uf_source , UF_REGISTERED_AT into [#bankiru-installment-context] from stg._LCRM.lcrm_leads_full_calculated
where uf_source = 'bankiru-installment-context'	and  UF_REGISTERED_AT_date>='20230717'


												  
drop table if exists  [#bankiru-installment-context_finall]
			  

SELECT  x.UF_REGISTERED_AT, x.uf_source, x. phonenumber phonenumber,  b.*
, ROW_NUMBER() over(partition by phonenumber order by [Заем выдан] desc, Одобрено desc, [Контроль данных] desc, [Предварительное одобрение] desc, [Верификация КЦ] desc) rn
into [#bankiru-installment-context_finall]
FROM (
	SELECT '8'+phonenumber	phonenumber
		,min(UF_REGISTERED_AT) UF_REGISTERED_AT
		,min(uf_source) uf_source
	FROM [#bankiru-installment-context]
	GROUP BY phonenumber
		--order by 
	) x
	left  join ##t2 b on x.phonenumber=b.Телефон8	 and b.[Верификация КЦ]>=x.UF_REGISTERED_AT



	select * from  [#bankiru-installment-context_finall]


	end


 end