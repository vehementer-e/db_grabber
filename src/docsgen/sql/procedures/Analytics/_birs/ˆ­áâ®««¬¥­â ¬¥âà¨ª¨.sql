

CREATE     proc [_birs].[Инстоллмент метрики]	  @mode nvarchar(max)  = 'select'
as
begin


  if @mode = 	'update'
  begin

drop table if exists #oper

select Сотрудник Оператор
into #oper
from analytics.dbo.employees 
where Направление = 'Installment' 



drop table if exists #odobr 

select n.НомерЗаявки 

into #odobr 
from
v_communication_crm n
join  Reports.dbo.dm_Factor_Analysis_001 fa on n.НомерЗаявки=fa.Номер and Одобрено is not null --and isInstallment=1
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
and [ДатаВремяВзаимодействия] >=Одобрено and [ДатаВремяВзаимодействия]<=isnull([Заем выдан], dateadd(day, 10, Одобрено))
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
		  group by n.НомерЗаявки 



drop table if exists #inst

SELECT
       Номер
	  ,case when [Верификация документов клиента] is not null and [Отказ Carmoney] is not null then isnull( [Причина отказа], 'Другое') end [Причина отказа андеры]
	  ,Телефон
	  ,cast(dbo.to_md5( Телефон, 1) as nvarchar(100))  Телефон_md5
	  ,[Ссылка клиент]
	  ,[Выданная сумма]
	  ,[Первичная сумма]
	  ,case
	  when [Первичная сумма]<=10000 then '1) 0..10k]'
	  when [Первичная сумма]<=15000 then '2) (10..15k]'
	  when [Первичная сумма]<=30000 then '3) (15..30k]'
	  when [Первичная сумма]<=100000 then '4) (30..100k]'
	  when [Первичная сумма]>=100000 then '5) (100k+'	    end 		   [Первичная сумма бакет]
 																			 
	  ,case
	  when [Выданная сумма]<=10000 then '1) 0..10k]'
	  when [Выданная сумма]<=15000 then '2) (10..15k]'
	  when [Выданная сумма]<=30000 then '3) (15..30k]'
	  when [Выданная сумма]<=100000 then '4) (30..100k]'
	  when [Выданная сумма]>=100000 then '5) (100k+'	    end 		   [Выданная сумма бакет]
	  ,[Признак заявки]
	  ,[Признак Предварительное одобрение]
	  ,[Признак Контроль данных]
	  ,[Признак Call2]
	  ,[Признак Call2 accept]
	  ,[Признак Одобрено]
	  ,[Признак Заем выдан]
	  , [Отказ Carmoney]
	  ,Срок
	  ,case when [Группа каналов]='cpa' then case when [Тип трафика] Like 'api%'  then 'CPA api' else 'CPA ref' end	  else [Группа каналов] end Канал
	  ,[Канал от источника]
	  ,[Верификация КЦ]
	  ,[Заем выдан]
	  ,case when [Заем выдан] is not null then [Заем погашен] end [Заем погашен]

	  ,isnull([Заем выдан день] , [Верификация КЦ день]) День
	  ,isnull([Заем выдан месяц] , [Верификация КЦ месяц]) Месяц
	  ,[Маркетинговые расходы]
	  --,case when [Признак Заем выдан]=1 then  ROW_NUMBER() over(partition by [Признак Заем выдан], [Ссылка клиент] order by [Заем выдан]) end			 rn
		, case when Одобрено is not null then case when o.НомерЗаявки is not null then 1 else 0 end end	 [Признак ручное доведение на TU]
into #inst
FROM mv_dm_Factor_Analysis	   a
left join (select number  number2, marketingCosts [Маркетинговые расходы] from  v_request_costs ) b on a.Номер=b.number2
left join #odobr o on a.Номер=o.НомерЗаявки

WHERE isPts = 0
and Дубль=0								 

create nonclustered index t on #inst
(
	  [Ссылка клиент], 	Телефон_md5

)


				drop table if exists 	  #inst_an
				  select  * into #inst_an from #inst a
				  --outer apply (select count(*) cnt_povt from #inst b where (  (a.[Ссылка клиент]=b.[Ссылка клиент] and a.[Ссылка клиент]<>0) /*or a.Телефон_md5=b.Телефон_md5*/) and isnull(b.[Заем погашен], GETDATE() ) <= a.[Верификация КЦ]   	 )  [povt]
				  outer apply (select count(*) cnt_povt from #inst b where (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон_md5=b.Телефон_md5) and isnull(b.[Заем погашен], GETDATE() ) <= a.[Верификация КЦ]   	 )  [povt_tel]
				  --outer apply (select count(*) cnt_dcr from #inst b where (  (a.[Ссылка клиент]=b.[Ссылка клиент] and a.[Ссылка клиент]<>0) /*or a.Телефон_md5=b.Телефон_md5*/) and b.[Заем выдан]<=a.[Верификация КЦ] and isnull(b.[Заем погашен], GETDATE() ) > a.[Верификация КЦ]  )    [docr]
				  outer apply (select count(*) cnt_dcr from #inst b where (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон_md5=b.Телефон_md5) and b.[Заем выдан]<=a.[Верификация КЦ] and isnull(b.[Заем погашен], GETDATE() ) > a.[Верификация КЦ]  )    [docr_tel]	 
				  --outer apply (select min([Заем выдан]) min_Заем_выдан from #inst b where (  (a.[Ссылка клиент]=b.[Ссылка клиент] and a.[Ссылка клиент]<>0) /*or a.Телефон_md5=b.Телефон_md5*/) and b.[Заем выдан]>=a.[Заем погашен]  )    [conv_loan]
				  outer apply (select min([Заем выдан]) min_Заем_выдан from #inst b where (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон_md5=b.Телефон_md5) and b.[Заем выдан]>=a.[Заем погашен]  )    [conv_loan_tel]
				  --outer apply (select min([Верификация КЦ]) min_Верификация_КЦ from #inst b where (  (a.[Ссылка клиент]=b.[Ссылка клиент] and a.[Ссылка клиент]<>0) /*or a.Телефон_md5=b.Телефон_md5*/) and b.[Верификация КЦ]>=a.[Заем погашен] and [conv_loan].min_Заем_выдан is null    )    [conv_request]
				  outer apply (select min([Верификация КЦ]) min_Верификация_КЦ from #inst b where (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон_md5=b.Телефон_md5) and b.[Верификация КЦ]>=a.[Заем погашен]    )    [conv_request_tel]
				  
				drop table if exists 	  #inst_ana
				  
				  
				  SELECT
				  
				  Телефон_md5
				  
				  , [Верификация КЦ], [Отказ Carmoney]
				  , Номер
				  , [Маркетинговые расходы]
				  , Срок
				  , Месяц
				  , День
				  , Канал
				  , [Первичная сумма бакет]
				  , [Причина отказа андеры]
				  , [Заем выдан]
				  , [Заем погашен]
				  , [Выданная сумма]
				  , [Выданная сумма бакет]
	  ,[Признак Предварительное одобрение]
	  ,[Признак Контроль данных]
	  ,[Признак Call2]
	  ,[Признак Call2 accept]
	  ,[Признак Одобрено]
	  ,[Признак ручное доведение на TU]
				  , case 
				  when  cnt_dcr>0 then 'Докредитование'
				  when  cnt_povt>0 then 'Повторный'
				  else 'Первичный' end [Вид займа в рамках продукта]
				  
				  , cnt_povt		 [Закрыто займов на дату заявки]
				  , cnt_dcr													   
				  ,case when 	 
				  cast(format(min_Заем_выдан, 'yyyy-MM-01' ) as date) 
				  <=
				  b.[Месяц для конверсий] then 1 else 0 end [Conv povt loan]
				  ,case when 	 
				  cast(format(min_Верификация_КЦ, 'yyyy-MM-01' ) as date) 
				  <=
				  b.[Месяц для конверсий] then 1 else 0 end [Conv povt request]
				  , b.[Месяц для конверсий]
				  , isnull( datediff(month,  a.Месяц,b.[Месяц для конверсий] ), -1) [Разница мес]
				  , min_Заем_выдан
				  , min_Верификация_КЦ
	,case when [Признак Заем выдан]=1 then ROW_NUMBER() OVER (
		PARTITION BY Телефон_md5
		,[Месяц для конверсий],[Признак Заем выдан] ORDER BY [Заем выдан]
		)  end [Порядковый номер займа]
	--,sum([Признак Заем выдан]) OVER (PARTITION BY Телефон_md5) cnt_cred
	into #inst_ana
FROM #inst_an			   a
left join (
select distinct Месяц [Месяц для конверсий] from v_Calendar
)			 b on  b.[Месяц для конверсий]>=a.Месяц and b.[Месяц для конверсий]<=getdate()		and a.[Заем выдан] is not null
--ORDER BY --cnt_cred DESC
	--,Телефон_md5
	--,[Верификация КЦ]


	--select * from #inst_ana
				drop table if exists 	  #inst_anal


	select a.*, b.Дата,b.ДеньПлатежа,b.МесяцПлатежа, b.Сумма, b.ПлатежнаяСистема, b.[Прибыль расчетная екомм] , b.[Прибыль расчетная екомм без НДС] 
	into #inst_anal
	from #inst_ana a
	left join mv_repayments b on a.Номер=b.Код	   and a.[Разница мес]=0


	--select *from #inst_anal
--where Телефон_md5='9038234422'
--order by Номер 			 , [Разница мес], ДеньПлатежа

drop table if exists 	  #inst_analytics2
select 

--Телефон_md5  ,
[Верификация КЦ],
[Отказ Carmoney],
--[Номер],
[Маркетинговые расходы],
[Срок],
[Месяц],
День,
[Канал],
[Первичная сумма бакет],
[Причина отказа андеры],
[Заем выдан],
[Заем погашен],
[Выданная сумма],
[Выданная сумма бакет],
[Признак Предварительное одобрение],
[Признак Контроль данных],
[Признак Call2],
[Признак Call2 accept],
[Признак Одобрено],
[Признак ручное доведение на TU],
[Вид займа в рамках продукта],
[Закрыто займов на дату заявки],
[cnt_dcr],
[Conv povt loan],
[Conv povt request],
[Месяц для конверсий],
[Разница мес],
[min_Заем_выдан],
[min_Верификация_КЦ],
[Порядковый номер займа],
[Дата],
[ДеньПлатежа],
[МесяцПлатежа],
[Сумма],
[ПлатежнаяСистема],
[Прибыль расчетная екомм] 
[Прибыль расчетная екомм без НДС] 
,case when  [Разница мес]=0 
then ROW_NUMBER() over (partition by [Разница мес], Номер order by Дата)  end rn into #inst_analytics2 

from #inst_anal

--drop table if exists _birs.[Инстоллмент метрики таблица]
--select * into _birs.[Инстоллмент метрики таблица] from #inst_analytics2



delete from _birs.[Инстоллмент метрики таблица]
insert into _birs.[Инстоллмент метрики таблица]
select * from #inst_analytics2


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '9E615AF0-85E4-4561-B56D-8623E7985840', 1



end


if @mode='select'

select * from _birs.[Инстоллмент метрики таблица]
   
end
