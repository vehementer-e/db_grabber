

--exec  dbo._Рейтинг_логисты '', 'update'
CREATE     proc [dbo].[sale_rating_logist]
@mode nvarchar(max) = '' ,
@type nvarchar(max) = '' 
as
begin



declare @datefrom date = (select rating_date_from from config) --'20230301'
declare @dateto date   = (select rating_date_to   from config) --'20230401'

if @mode = 'Сотрудники'
begin

select  РГ, Сотрудник from employee where Уволен=0 and Направление='Distance' and Должность not in ('Чатер', 'Начальник смены ')

end

--select * from #oper
--except
--select Сотрудник from employees where --Уволен=0 and
--Направление='Distance' and Должность not in ('Чатер', 'Начальник смены ')


if @mode = ''
begin

if @type='update'
begin
--declare @datefrom date = datefromparts(year(getdate()), month(getdate()), '01')
--declare @dateto date =cast(getdate() as date)

--declare @datefrom date = '20220501'
--declare @dateto date ='20220601'



 --declare @datefrom date = (select rating_date_from from config) --'20230301'
 --declare @dateto date   = (select rating_date_to   from config) --'20230401'

drop table if exists #fa1
select Номер
, ДатаЗаявкиПолная
, Автор
, [Выданная сумма]
, 1-isPts isInstallment
, [Процентная ставка]
, [Контроль данных]
, [Заем выдан]
, Дубль
,[Забраковано]
,[Отказ клиента]
,[Заем аннулирован]
,[Отказано]
,[Отказ документов клиента]
,[Аннулировано]
,[Договор подписан]
,[Договор зарегистрирован]
,[Одобрено]
, [Верификация документов]
, [Одобрены документы клиента]
, [Верификация документов клиента]
, [Встреча назначена]
, [Предварительное одобрение]
, [Верификация КЦ]
, [Сумма одобренная]
, [ПризнакЗаявка]
, [ПризнакПредварительноеОдобрение]
, [ПризнакВстречаНазначена]
, [ПризнакКонтрольДанных]
, Дата
, [Сумма Фарма]
, [Сумма Защита от потери работы]
, [Сумма Помощь бизнесу]
, [Сумма РАТ]
, [Сумма Дополнительных Услуг]
, [Сумма Дополнительных Услуг Carmoney Net]
, [Номер партнера]
, [Сумма Телемедицина]
, [Признак Страховка]
into #fa1 

from v_fa


drop table if exists #fa
select 
  Номер, product, [Место_создания_2], [Группа риска], offer_details, ИспытательныйСрок, СуммаДопУслуг, СуммаДопУслугCarmoneyNet
into #fa 

from reports.dbo.dm_Factor_Analysis 


drop table if exists #communications
select НомерЗаявки, ДатаВремяВзаимодействия ДатаВремяВзаимодействия,  ВремяВзаимодействия, ФИО_оператора, Результат, НомерТелефона into #communications from 
v_communication_crm n
where ДатаВзаимодействия  between @datefrom and @dateto


drop table if exists #oper

select		'Щукина Анна Михайловна' Оператор
into #oper
	union	 select'Ветрова Оксана Анатольевна'
	union	select	'Павлова Анастасия Сергеевна'
	union	select	'Блинова Елена Ивановна'
	union	select	'Борщёва Татьяна Николаевна'
	union	select	'ГРИХ ВАЛЕРИЯ ВИКТОРОВНА'
	union	select	'Крутых Надежда Владимировна'
	union	select	'Кузина Анастасия Олеговна'
	union	select	'Гумерова Ксения Константиновна'
	union	select	'Демина Вера Владимировна'
	union	select	'Платонова Оксана Николаевна'
	union	select	'Лукашова Светлана Александровна'
	union	select	'Борщева Татьяна Николаевна'
	union	select	'Табота Алексей Юрьевич'
union	select	'Бирилкина Татьяна Михайловна'
union	select	'Магомедова Анна Владимировна'
union	select	'Горшенина Кристина Вячеславовна'
union	select	'Мансуров Дмитрий Сергеевич'
union	select	'Каменская Наталия Валентиновна'
union	select	'Орлова Марина Романовна'		  
union 	select Сотрудник from employee where Направление='Distance' and Должность not in ('Чатер', 'Начальник смены ')

--drop table if exists #t1 
drop table if exists #logist 

select  --distinct
n.НомерЗаявки, НомерТелефона, o.Оператор, ДатаВремяВзаимодействия--  max(ДатаВзаимодействия) Data, [Заем выдан]
into #logist
--into #t1 
from
#communications n
left join  #fa1 fa on n.НомерЗаявки=fa.Номер
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and ДатаВзаимодействия between @datefrom and @dateto
and ДатаВремяВзаимодействия <= isnull(isnull(isnull(isnull([Заем выдан], [Заем аннулирован] )	 , [Аннулировано]  ), [Отказано] )  ,[Одобрено] )
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
 ;

with v as (
select *, ROW_NUMBER() over(partition by НомерЗаявки order by ДатаВремяВзаимодействия desc) rn from  #logist a
)
delete from v where rn>1
--drop table if exists #t2 
--
--select t1.НомерЗаявки, n.НомерТелефона, Data, max(ВремяВзаимодействия) Min
--into #t2
--from
--#communications n
-- join #t1 t1 on t1.НомерЗаявки=n.НомерЗаявки
-- join #oper o on n.ФИО_оператора  =  o.Оператор
--where Результат!='Недозвон' 
--and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and t1.Data=n.ДатаВзаимодействия
--group by n.НомерТелефона, t1.НомерЗаявки, Data
--
--drop table if exists #t3
--
--select distinct t1.НомерЗаявки, ДатаВзаимодействия, ФИО_оператора, t.НомерТелефона
--into #t3
--from
--#communications n
--left join #t1 t on n.НомерЗаявки=t.НомерЗаявки
--left join #t2 t1 on n.НомерЗаявки=t1.НомерЗаявки
--join #oper o on n.ФИО_оператора  =  o.Оператор
--where ДатаВзаимодействия=t1.data and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and ВремяВзаимодействия=min
--
--drop table if exists #p1 
--
--select  distinct n.НомерЗаявки, НомерТелефона, max(ДатаВзаимодействия) Data, [Заем выдан]
--into #p1 
--from
--#communications n
--left join  #fa1 fa on n.НомерЗаявки=fa.Номер
--join #oper o on n.ФИО_оператора  =  o.Оператор
--where n.Результат!='Недозвон' 
--and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and ДатаВзаимодействия between @datefrom and @dateto
--and [Заем выдан] is NULL
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
--
--drop table if exists #p3 
--
--select t1.НомерЗаявки, n.НомерТелефона, Data, max(ВремяВзаимодействия) Min
--into #p3
--from
--#communications n
-- join #p1 t1 on t1.НомерЗаявки=n.НомерЗаявки
-- join #oper o on n.ФИО_оператора  =  o.Оператор
--where Результат!='Недозвон' 
--and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen')
--and t1.Data=n.ДатаВзаимодействия
--group by n.НомерТелефона, t1.НомерЗаявки, Data
--
--drop table if exists #p2
--
--select distinct t1.НомерЗаявки, ДатаВзаимодействия, ФИО_оператора, t.НомерТелефона
--into #p2
--from
--#communications n
--left join #p1 t on n.НомерЗаявки=t.НомерЗаявки
--left join #p3 t1 on n.НомерЗаявки=t1.НомерЗаявки
--join #oper o on n.ФИО_оператора  =  o.Оператор
--where ДатаВзаимодействия=t1.data and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and ВремяВзаимодействия=min
--
--drop table if exists #logist
--
--SELECT fa.Номер, o.Оператор
--into #logist
--FROM #fa1 fa
----  inner join Reports.dbo.dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
--  left join #t3 t on fa.Номер=t.НомерЗаявки
--  join #oper o on t.ФИО_оператора  =  o.Оператор
--  where
--	fa.Дубль = 0
--	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto) 
--
--union
--
--SELECT fa.Номер, t.ФИО_оператора
--FROM #fa1 fa
--  --inner join Reports.dbo.dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
--  left join #p2 t on fa.Номер=t.НомерЗаявки
--  join #oper o on t.ФИО_оператора  =  o.Оператор
--  where
--	fa.Дубль = 0
--	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto) 
-- and fa.isInstallment=0
--
--	 select * from #t2
--	 where НомерЗаявки='23083101159473'
--
--	 select * from #t3
--	 where НомерЗаявки='23083101159473'


--drop table if exists #expert_issues
--select
--	distinct
--		u.Наименование as [Фио],
--		e.external_id			  ,
--		e.expert_fio 
--into #expert_issues
--from		  select * from 
--	[Reports].[ssrsRW].[v_dm_report_experts_calls_on_requests] e
--	order by created desc
--	left join [Stg].[_1cCRM].[Справочник_Пользователи] u with(nolock) on e.expert_fio = u.[adLogin]  
--	
--	   CM\Vetrova_O_A
--
--	   select * from [Stg]._fedor.core_user
--	   where domainlogin like '%vetro%'
--
--
--	   select * from [Stg].[_1cCRM].[Справочник_Пользователи] 
--	   where adlogin like '%vetro%'
--
--	   select * from columns_dwh where table_schema='_fedor'
--
--	select distinct expert_fio from 	 #expert_issues
--	where фио is null
--	order by 2 desc
--	order

drop table if exists #logistic_issues
select
	distinct
		u.Наименование as [Фио],
		external_id
into #logistic_issues
from
	[Reports].[ssrsRW].[dm_report_logistics_history] l
	left join [Stg].[_1cCRM].[Справочник_Пользователи] u with(nolock) on l.author = u.[adLogin]


	insert into #logistic_issues
		select distinct
  a.[ФИО логиста ]  ,   a.[Номер заявки ]
from sale_rating_logist_request  a






--drop table if exists #exp_log_issues
--select
--	z.номер,
--	u.НАименование as [ФИО эксперта/логиста 1С]
--into #exp_log_issues
--from
--	(select 
--		max (vzaim.Дата) as Дата,
--		z.номер
--	from 
--		stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z with(nolock)
--		inner join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие] vzaim (nolock) on z.Ссылка=vzaim.Заявка_Ссылка
--		inner join devDB.[dbo].[employees_with_dept] em on vzaim.Автор = em.Пользователь_CRM
--		left join [Stg].[_1cCRM].[Справочник_Пользователи] u with(nolock) on vzaim.Автор = u.Ссылка
--		 join #oper o on u.НАименование  =  o.Оператор
--	
--	where
--		dateadd(yy,-2000,z.Дата) between dateadd(mm,-1,@datefrom) and @dateto
--	group by
--		z.номер)d
--	inner join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z (nolock) on z.номер= d.номер
--	
--	inner join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие] vzaim (nolock) on z.Ссылка=vzaim.Заявка_Ссылка
--		and vzaim.Дата = d.Дата		
--	inner join devDB.[dbo].[employees_with_dept] em on vzaim.Автор = em.Пользователь_CRM
--	 
--	left join [Stg].[_1cCRM].[Справочник_Пользователи] u with(nolock) on vzaim.Автор = u.Ссылка
--	join #oper o on u.НАименование  =  o.Оператор

	drop table if exists #logisti_reiting


select
	fa.Дата,
	fa.Номер,
	fa.Автор
	,cast(fa.[Процентная ставка] as real) as [Ставка по кредиту]
	,fa.[Сумма одобренная],
	fa.[Выданная сумма],
	cast(fa.[Выданная сумма] * fa.[Процентная ставка]  as real)/100 as ВыдачаНаСтавку,
	convert(nvarchar(10),fa.[Верификация КЦ],104) as [Верификация КЦ],
	convert(nvarchar(10),fa.[Предварительное одобрение],104) as [Предварительное одобрение],
	convert(nvarchar(10),fa.[Встреча назначена],104) as [Встреча назначена],
	convert(nvarchar(10),fa.[Контроль данных],104) as [Контроль данных],
	convert(nvarchar(10),fa.[Верификация документов клиента],104) as [Верификация документов клиента],
	convert(nvarchar(10),fa.[Одобрены документы клиента],104) as [Одобрены документы клиента],
	convert(nvarchar(10),fa.[Верификация документов],104) as [Верификация документов],
	convert(nvarchar(10),fa.[Одобрено],104) as [Одобрено],
	convert(nvarchar(10),fa.[Договор зарегистрирован],104) as [Договор зарегистрирован],
	convert(nvarchar(10),fa.[Договор подписан],104) as [Договор подписан],
	convert(nvarchar(10),fa.[Заем выдан],104) as [Заем выдан],
	convert(nvarchar(10),fa.[Аннулировано],104) as [Аннулировано],
	convert(nvarchar(10),fa.[Отказ документов клиента],104) as [Отказ документов клиента],
	convert(nvarchar(10),fa.[Отказано],104) as [Отказано],
	convert(nvarchar(10),fa.[Отказ клиента],104) as [Отказ клиента],
	convert(nvarchar(10),fa.[Забраковано],104) as [Забраковано],
	fa.[ПризнакЗаявка] as [Признак заявка],
	fa.[ПризнакПредварительноеОдобрение] as [Признак предварительное одобрение],
	fa.[ПризнакВстречаНазначена] as [Встреча назначена факт],
	fa.[ПризнакКонтрольДанных] as [Признак Контроль данных ]	
	,iif(f.[Место_создания_2] = 'КЦ', 'Партнеры',f.[Место_создания_2]) Column1,
	case 
		when f.[Группа риска]=50 or f.offer_details='RBP - 40'  then 'Ставка 40-50'
		when f.ИспытательныйСрок=1  then 'ПТС31'
		when fa.[Номер партнера] = 3645 then 'Рефинансирование'
		else 'Основной продукт'
	end as [Тип продукта]
	,f.СуммаДопУслуг as [Сумма КП, gross],
	f.СуммаДопУслугCarmoneyNet as [Сумма КП, net]
	--,ISNULL(e.Фио,l.Фио) as [ФИО эксперта/логиста],
	, isnull( l.Фио, lt.Оператор ) as [ФИО эксперта/логиста]
	--el.[ФИО эксперта/логиста 1С]
	, null [ФИО эксперта/логиста 1С]
  -- ,IIF(ISNULL(ISNULL(e.Фио,l.Фио),lt.Оператор) is not NULL, ISNULL(ISNULL(e.Фио,l.Фио),lt.Оператор), el.[ФИО эксперта/логиста 1С]) as [ФИО эксперта/логиста ИТОГ]
   , l.Фио  as [ФИО эксперта/логиста ИТОГ]
	,fa.isInstallment
	,fa.[Сумма РАТ] [SumRat],
		fa.[Сумма Помощь бизнесу] [SumHelpBusiness],
		fa.[Сумма Телемедицина] [SumTeleMedic],
		fa.[Сумма Защита от потери работы] [SumCushion],
		fa.[Сумма Фарма] [SumPharma],
	case 
	     when f.product = 'Исп. срок' then 'Первичные: RBP - 86'
		 else f.product
	end product
	, fa.[Признак Страховка]

		into #logisti_reiting
from
	#fa1 fa (nolock)
	left join #fa f (nolock) on fa.Номер = f.Номер
	--left join #expert_issues e on e.external_id = fa.Номер 
	left join #logistic_issues l on l.external_id =	 fa.Номер  
	--left join #exp_log_issues el on el.номер =	fa.Номер
	left join #logist lt on lt.НомерЗаявки =	fa.Номер
where
	fa.Дубль = 0
	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto)
	
order by fa.ДатаЗаявкиПолная


	--select   *, count(*) over(partition by Номер) from #logist

	--drop table if exists dbo.[_рейтинг_логисты_детализация]
	delete from dbo.[_рейтинг_логисты_детализация]
	insert into dbo.[_рейтинг_логисты_детализация]
	select *  from #logisti_reiting

--	select * into dbo.[_рейтинг_логисты_детализация] from #logisti_reiting
	--select *    from #logisti_reiting

	end

	select * from dbo.[_рейтинг_логисты_детализация]
	--where номер='25032503147250'


end


if @mode='stat'
begin

--declare @datestart as date = @datefrom
--declare @dateend as date = @dateto


select 'Выданная сумма' Показатель,
sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock)
WHERE [Заем выдан] between @datefrom and @dateto  and Дубль=0 and ispts=1

union

select 
 'КП NET' Показатель,
SUM([сумма дополнительных услуг carmoney net]) 'КП NET'
FROM v_fa (nolock)
WHERE [Заем выдан] between @datefrom and @dateto  and Дубль=0 and ispts=1

union 

select 'План ПТС RR' Показатель,
sum(ptsSum) 'План'
from sale_plan
where date between @datefrom and dateadd(d,-1,cast(@dateto as date)) and
date<@dateto

union 

select 'План КП RR' Показатель,
sum(ptsAddProductSum) 'План'
from sale_plan
where date between @datefrom and dateadd(d,-1,cast(getdate() as date)) and
date<@dateto

union 

select 'План ПТС' Показатель,
sum(ptsSum) 'План'
from sale_plan
where date between @datefrom and dateadd(d,-1, @dateto) and
date<@dateto

union 

select 'План КП' Показатель,
sum(ptsAddProductSumMonth) 'План'
from sale_plan
where date between @datefrom and dateadd(d,-1, @dateto) and
date<@dateto

union 

select 'План Ставка' Показатель,
min(ptsInterestRate) 'План'
from sale_plan
where date between @datefrom and dateadd(d,-1, @dateto) and
date<@dateto

union

SELECT 'Ставка факт' Значение,
	sum(cast(d.[Выданная сумма] * d.[Процентная ставка] as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM v_fa  d
where  format(d.[Заем выдан]   , 'yyyy-MM-01') =  format( @datefrom  , 'yyyy-MM-01') 
and isPts = 1

union

SELECT 'Ставка повторные' Значение,
	sum(cast(d.[Выданная сумма] * d.[Процентная ставка] as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM v_fa  d
where  format(d.[Заем выдан]   , 'yyyy-MM-01') =  format( @datefrom  , 'yyyy-MM-01') 

	and ispts = 1
	and [Вид займа] != 'Первичный'

union 

SELECT 'Заявок' Значение,
	count(Номер) Факт
 FROM v_fa d
where  format(d.[Заем выдан]   , 'yyyy-MM-01') =  format( @datefrom  , 'yyyy-MM-01') 
		and ispts = 1

	and Дубль = 0 
	
union 

SELECT 'План ставка' Значение,
	avg(ptsInterestRate) Месяц
 FROM sale_plan d
 where  format(date   , 'yyyy-MM-01') =  format( @datefrom  , 'yyyy-MM-01') 



end


if @mode ='Постобработка'
begin

select title
	,РГ
	,SUm(Постобработка) Постобработка
	,SUM([Звонков совершено]) Звонков
	,round(SUm(Постобработка)*3600*24/SUM([Звонков совершено]),0) ПостобработкаСР
	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
	--,round(((sum([Время диалога])+sum([Постобработка]))/nullif(sum([Время диалога])+sum([Готов])+sum([Постобработка]),0)),2) [%эффективности]
from  [dbo].[sale_rating_acitivity_view]
 where format( d  , 'yyyy-MM-01')=@datefrom
--'2023-01-01' 
group by title
	,РГ

end

--if @mode ='Поствызов'
--begin

--select Сотрудник ФИО
--    , РГ
--	,round(((sum([Время диалога])+sum([Постобработка]))/(sum([Время диалога])+sum([Готов])+sum([Постобработка]))),2) [% эффективности]

--from analytics.dbo._birs_report_naumen_activity_by_login_day
--where d between @datefrom and @dateto
--and Направление='Distance' 
--and Должность not in ('Чатер', 'Начальник смены ')
--group by Сотрудник, РГ

--end

if @mode = 'Выпадающие'
begin

select  Сотрудник as ФИО, РГ, Качество, Депремация from employee  where Уволен=0 and Направление='Distance' and Должность not in ('Чатер', 'Начальник смены ')

end

end
