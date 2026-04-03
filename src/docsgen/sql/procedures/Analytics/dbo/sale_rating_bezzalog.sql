

CREATE     proc [dbo].[sale_rating_bezzalog]
@mode nvarchar(max) = '' ,
@type nvarchar(max) = ''                                                                                                                                                                                                                                                   
as 
                                                                                                                                                                                                                                                                            
if @mode ='ssrs'
select * from dbo.[_рейтинг_инст+смартинст_детализация]

declare @datefrom date = (select rating_date_from from config)--'20230301'
declare @dateto date   = (select rating_date_to   from config)--'20230401'

if @mode = 'Сотрудники'
begin
select Сотрудник from analytics.dbo.employee
where Направление = 'Installment' and уволен=0
end
   
if @mode = ''
begin

if @type='update'
begin

--declare @datefrom date = '20230301'
--declare @dateto date ='20230401'



drop table if exists #oper

--select		'Силаева Елена Николаевна' Оператор
--
--	union	 select'Бурмистрова Александра Владимировна'
--	union	select	'Наубетханова Оксана Михайловна'
--	union	select	'Данилова Марина Валерьевна'
--	union	select	'Гумерова Ксения Константиновна'
--	union	select	'Абанина Анна Николаевна'
--	union	select	'АДИЕГА ДЖАКЛИН ДАНИЭЛОВНА'
--	union	select	'Ларцева Николетта Юрьевна'
--union	select	'Моисеева Ирина Юрьевна'
--union	select	'Гришина Полина Артёмовна'
--union 

select Сотрудник Оператор
into #oper
from analytics.dbo.employee
where Направление = 'Installment' 
--
--drop table if exists #t1 
--
--select  distinct n.НомерЗаявки, НомерТелефона, max([ДатаВремяВзаимодействия]) Data, [Заем выдан]
--into #t1 
--from
--v_communication_crm n
--left join  Reports.dbo.dm_Factor_Analysis_001 fa on n.НомерЗаявки=fa.Номер
--join #oper o on n.ФИО_оператора  =  o.Оператор
--where n.Результат!='Недозвон' 
--and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
--and [ДатаВремяВзаимодействия]<=[Заем выдан]
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]
--
--drop table if exists #t2 
--
--select t1.НомерЗаявки, n.НомерТелефона, Data, max(ВремяВзаимодействия) Min
--into #t2
--from
--v_communication_crm n
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
--v_communication_crm n
--left join #t1 t on n.НомерЗаявки=t.НомерЗаявки
--left join #t2 t1 on n.НомерЗаявки=t1.НомерЗаявки
--join #oper o on n.ФИО_оператора  =  o.Оператор
--where ДатаВзаимодействия=t1.data and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and ВремяВзаимодействия=min
--
--
--drop table if exists #p1 
--
--select  distinct n.НомерЗаявки, НомерТелефона, max(ДатаВзаимодействия) Data, [Заем выдан]
--into #p1 
--from
--v_communication_crm n
--left join  Reports.dbo.dm_Factor_Analysis_001 fa on n.НомерЗаявки=fa.Номер
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
--v_communication_crm n
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
--v_communication_crm n
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
--FROM Reports.dbo.dm_Factor_Analysis_001 fa
--  inner join Reports.dbo.dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
--  left join #t3 t on fa.Номер=t.НомерЗаявки
--  join #oper o on t.ФИО_оператора  =  o.Оператор
--  where
--	fa.Дубль = 0
--	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto) 
--
--union
--
--SELECT fa.Номер, t.ФИО_оператора
--FROM Reports.dbo.dm_Factor_Analysis_001 fa
--  inner join Reports.dbo.dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
--  left join #p2 t on fa.Номер=t.НомерЗаявки
--  join #oper o on t.ФИО_оператора  =  o.Оператор
--  where
--	fa.Дубль = 0
--	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto) 
---- and fa.isInstallment=1
--
-- 
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
--		--inner join devDB.[dbo].[employees_with_dept] em on vzaim.Автор = em.Пользователь_CRM
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
--	--inner join devDB.[dbo].[employees_with_dept] em on vzaim.Автор = em.Пользователь_CRM
--	 
--	left join [Stg].[_1cCRM].[Справочник_Пользователи] u with(nolock) on vzaim.Автор = u.Ссылка
--	join #oper o on u.НАименование  =  o.Оператор
--
--
--


drop table if exists #offer_choosing 

  

select link, min(created) [Выбор предложения] into #offer_choosing from v_request_crm_status
where status = 'Выбор предложения'
group by link 


drop table if exists #odobr 

select n.НомерЗаявки, ФИО_оператора, [ДатаВремяВзаимодействия], Одобрено, 1-isPts isInstallment, [Заем выдан]

into #odobr 
from
v_communication_crm n
join  v_fa fa on n.НомерЗаявки=fa.Номер and Одобрено is not null  and fa.productType in ('inst', 'pdl'--, 'big inst'
)
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
and [ДатаВремяВзаимодействия] >=Одобрено and [ДатаВремяВзаимодействия]<=isnull([Заем выдан], dateadd(day, 10, Одобрено))
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]

insert into #odobr

select n.НомерЗаявки, ФИО_оператора, [ДатаВремяВзаимодействия], oc.[Выбор предложения] Одобрено, 1-isPts isInstallment, [Заем выдан]
 
from
v_communication_crm n
join  v_fa fa on n.НомерЗаявки=fa.Номер    and fa.productType in (  'big inst'
)
join #oper o on n.ФИО_оператора  =  o.Оператор
left join #offer_choosing oc on oc.link = fa.link 
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
--and [ДатаВремяВзаимодействия] between @datefrom and @dateto
and [ДатаВремяВзаимодействия] >=[Выбор предложения] and [ДатаВремяВзаимодействия]<=isnull([Заем выдан], dateadd(day, 10, [Выбор предложения]))
--group by НомерТелефона, n.НомерЗаявки, [Заем выдан]


--select * from #odobr
--where НомерЗаявки='23030420762763'

drop table if exists #odobr_rn 


select НомерЗаявки НомерЗаявки,ФИО_оператора  ФИО_оператора into #odobr_rn from 
(
select 
  *
, ROW_NUMBER() over(partition by НомерЗаявки order by [ДатаВремяВзаимодействия] desc )  rn 
from #odobr
) x
where rn=1

drop table if exists #predodobr

select n.НомерЗаявки, ФИО_оператора, [ДатаВремяВзаимодействия], [Предварительное одобрение],1-isPts isInstallment, [Заем выдан], isnull(isnull(isnull(Одобрено, Отказано), Аннулировано), [Заем аннулирован]) ДатаДо

into #predodobr 
from
v_communication_crm n
join  v_fa fa on n.НомерЗаявки=fa.Номер and fa.productType in ('inst', 'pdl' )
join #oper o on n.ФИО_оператора  =  o.Оператор
where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
and [ДатаВремяВзаимодействия] >=[Предварительное одобрение] and [ДатаВремяВзаимодействия]<=isnull(isnull(isnull(Одобрено, Отказано), Аннулировано), [Заем аннулирован])
 
 insert into #predodobr 
select n.НомерЗаявки, ФИО_оператора, [ДатаВремяВзаимодействия], [Предварительное одобрение],1-isPts isInstallment, [Заем выдан], isnull(isnull(isnull(oc.[Выбор предложения] , Отказано), Аннулировано), [Заем аннулирован]) ДатаДо
 
from
v_communication_crm n
join  v_fa fa on n.НомерЗаявки=fa.Номер and fa.productType in (  'big inst')
join #oper o on n.ФИО_оператора  =  o.Оператор
left join #offer_choosing oc on oc.link = fa.link 

where n.Результат!='Недозвон' 
and (ФИО_оператора is not null and ФИО_оператора!='<Не указан>' and ФИО_оператора!='Naumen') 
and [ДатаВремяВзаимодействия] >=[Предварительное одобрение] and [ДатаВремяВзаимодействия]<isnull(isnull(isnull(oc.[Выбор предложения]  , Отказано), Аннулировано), [Заем аннулирован])
 


drop table if exists #predodobr_rn

select НомерЗаявки НомерЗаявки,ФИО_оператора  ФИО_оператора into #predodobr_rn from 
(
select 
  *
, ROW_NUMBER() over(partition by НомерЗаявки order by [ДатаВремяВзаимодействия] desc )  rn 
from #predodobr
) x
where rn=1

 drop table if exists 	 #sms_op
		   
 SELECT p.Наименование
 ,dateadd(year, -2000, a.Дата)  Дата
 ,a.Комментарий
	,isnull(  pcc.НомерТелефонаБезКодов , pcc2.НомерТелефонаБезКодов )	 НомерТелефонаБезКодов
	into #sms_op
FROM stg._1cCRM.Документ_CRM_Взаимодействие a
left join stg._1cCRM.[СПравочник_Пользователи]	 p on p.ссылка=a.Автор

left join stg._1cCRM.Задача_ЗадачаИсполнителя b on a.Задача=b.Ссылка
left join stg._1cCRM.БизнесПроцесс_CRM_БизнесПроцесс bp on bp.Ссылка=b.Предмет_Ссылка
left join stg._1cCRM.Документ_CRM_Интерес c on c.Ссылка=a.ДокументОснование_Ссылка								    

left join stg._1cCRM.Справочник_CRM_ПотенциальныеКлиенты pc on pc.Ссылка=c.ПотенциальныйКлиент
--left join stg._1cCRM.Справочник_CRM_ПотенциальныеКлиенты_КонтактнаяИнформация	   pcc0 on pcc0.ссылка=pc.Ссылка			  
left join stg._1cCRM.Справочник_CRM_ПотенциальныеКлиенты_КонтактнаяИнформация	   pcc on pcc.ссылка=pc.Ссылка			    and len( pcc.НомерТелефонаБезКодов) =10
left join stg._1cCRM.Справочник_КонтактныеЛицаПартнеров_КонтактнаяИнформация	   pcc2 on pcc2.ссылка=a.КонтактноеЛицо	    and len( pcc2.НомерТелефонаБезКодов) =10
where  a.Комментарий='СМС с предложением скачать МП и оформить займ' and 	Результат='Выполнено'

drop table if exists #sms_op_req
SELECT 
 Номер , 
 Наименование
 
	into #sms_op_req
FROM (
	SELECT cast(format(b.[Заем выдан], 'yyyy-MM-01') AS DATE) МесяцВыдачи
		,b.[Вид займа]
		,a.*
		,b.Номер
		,b.[Автор]
	FROM #sms_op a
	JOIN v_fa b ON a.НомерТелефонаБезКодов = b.Телефон
		AND b. productType in ('inst', 'pdl', 'big inst')
		AND b.[Заем выдан] >= a.Дата
		AND b.[Верификация КЦ] BETWEEN a.Дата
			AND dateadd(day, 1, a.Дата)
		
	) x


 


drop table if exists #детализация

select
	fa.Дата,
	fa.Номер,
	fa.Автор
	,cast(f.ПроцСтавкаКредит as real) as [Ставка по кредиту]
	,fa.[Сумма одобренная],
	fa.[Выданная сумма],
	cast(fa.[Выданная сумма] * f.ПроцСтавкаКредит as real)/100 as ВыдачаНаСтавку,
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
	,iif(f.[Место_создания_2] = 'КЦ', 'Партнеры',f.[Место_создания_2]) [Место_создания_2 кц=партнеры],
	  fa. productType as [Тип продукта]
	,   f.СуммаДопУслуг   as [Сумма КП, gross],
	     f.СуммаДопУслугCarmoneyNet  as [Сумма КП, net]
	,'' [ФИО эксперта/логиста]
	,''[ФИО эксперта/логиста 1С]
	,isnull(b.ФИО_оператора , '') as [ФИО ИТОГ]
	,1-fa.isPts isInstallment
	,f.[SumRat],
		f.[SumHelpBusiness],
		f.[SumTeleMedic],
		f.[SumCushion],
		f.[SumPharma],
		isnull(b1.ФИО_оператора, '') [ФИО предодобрение - фин решение] ,
		'' [Признак принудительного учета заявки оператору],
		fa.[Первичная сумма]
		into #детализация
from
	v_fa fa (nolock)
	left join dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
	left join #odobr_rn b on fa.Номер=b.НомерЗаявки
	left join #predodobr_rn b1 on fa.Номер=b1.НомерЗаявки
	--left join _request r on r.number = fa.number and r.issued is not null and r.productType= 'big inst'
	--left join #logist lt on lt.номер =	fa.Номер
	--	left join #exp_log_issues el on el.номер =	fa.Номер
	--	left join stg.files.channelrequestexceptions_buffer_stg ex on format(ex.[Номер заявки], '0')=FA.Номер
where
	fa.Дубль = 0
	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto)
	and   fa.productType in ('inst', 'pdl', 'big inst')

--union		all
--select
--	fa.Дата,
--	fa.Номер,
--	fa.Автор
--	,cast(f.ПроцСтавкаКредит as real) as [Ставка по кредиту]
--	,fa.[Сумма одобренная],
--	fa.[Выданная сумма],
--	cast(fa.[Выданная сумма] * f.ПроцСтавкаКредит as real)/100 as ВыдачаНаСтавку,
--	convert(nvarchar(10),fa.[Верификация КЦ],104) as [Верификация КЦ],
--	convert(nvarchar(10),fa.[Предварительное одобрение],104) as [Предварительное одобрение],
--	convert(nvarchar(10),fa.[Встреча назначена],104) as [Встреча назначена],
--	convert(nvarchar(10),fa.[Контроль данных],104) as [Контроль данных],
--	convert(nvarchar(10),fa.[Верификация документов клиента],104) as [Верификация документов клиента],
--	convert(nvarchar(10),fa.[Одобрены документы клиента],104) as [Одобрены документы клиента],
--	convert(nvarchar(10),fa.[Верификация документов],104) as [Верификация документов],
--	convert(nvarchar(10),fa.[Одобрено],104) as [Одобрено],
--	convert(nvarchar(10),fa.[Договор зарегистрирован],104) as [Договор зарегистрирован],
--	convert(nvarchar(10),fa.[Договор подписан],104) as [Договор подписан],
--	convert(nvarchar(10),fa.[Заем выдан],104) as [Заем выдан],
--	convert(nvarchar(10),fa.[Аннулировано],104) as [Аннулировано],
--	convert(nvarchar(10),fa.[Отказ документов клиента],104) as [Отказ документов клиента],
--	convert(nvarchar(10),fa.[Отказано],104) as [Отказано],
--	convert(nvarchar(10),fa.[Отказ клиента],104) as [Отказ клиента],
--	convert(nvarchar(10),fa.[Забраковано],104) as [Забраковано],
--	fa.[ПризнакЗаявка] as [Признак заявка],
--	fa.[ПризнакПредварительноеОдобрение] as [Признак предварительное одобрение],
--	fa.[ПризнакВстречаНазначена] as [Встреча назначена факт],
--	fa.[ПризнакКонтрольДанных] as [Признак Контроль данных ]	
--	,iif(f.[Место_создания_2] = 'КЦ', 'Партнеры',f.[Место_создания_2]) [Место_создания_2 кц=партнеры],
--	case 
--		when f.[Группа риска]=50 or f.offer_details='RBP - 40'  then 'Ставка 40-50'
--		when f.ИспытательныйСрок=1  then 'ПТС31'
--		when fa.[Номер партнера] = 3645 then 'Рефинансирование'
--		else 'Основной продукт'
--	end as [Тип продукта]
--	,f.СуммаДопУслуг as [Сумма КП, gross],
--	f.СуммаДопУслугCarmoneyNet as [Сумма КП, net]
--	,'' [ФИО эксперта/логиста]
--	,''[ФИО эксперта/логиста 1С]
--	, ex.[ФИО ОП]   as [ФИО ИТОГ]												   
--	,1-fa.isPts isInstallment
--	,f.[SumRat],
--		f.[SumHelpBusiness],
--		f.[SumTeleMedic],
--		f.[SumCushion],
--		f.[SumPharma],
--		'' [ФИО предодобрение - фин решение],
--		'да' [Признак принудительного учета заявки оператору],
--		fa.[Первичная сумма]
	 
--from
--	v_fa fa (nolock)
--	left join  dm_Factor_Analysis f (nolock) on fa.Номер = f.Номер
--	--left join #logist lt on lt.номер =	fa.Номер
--	--	left join #exp_log_issues el on el.номер =	fa.Номер
--	join (select distinct format( [номер заявки], '0') [номер заявки], [ФИО ОП]  from stg.files.[учет выдач инстолмент_stg] 
--		union all 
--		select  Номер,	Наименование	 from  #sms_op_req
--	) ex on ex.[номер заявки]=FA.Номер-- and  ex.[ФИО инстоллмент рейтинг]  is not null
--where	
--	fa.Дубль = 0
--	and (fa.ДатаЗаявкиПолная between @datefrom and @dateto or fa.[Заем выдан] between  @datefrom and @dateto)

	 --select * from stg.files.[учет выдач инстолмент_stg]
--	select * from 
--	#детализация
--order by
-- 1

	 ;with v  as (select *, row_number() over(partition by Номер, [ФИО ИТОГ]  order by (select null)) rn from #детализация ) delete from v where rn>1

	drop table if exists dbo.[_рейтинг_инст+смартинст_детализация]
	
	select * into dbo.[_рейтинг_инст+смартинст_детализация] from #детализация

	end

 select   * from dbo.[_рейтинг_инст+смартинст_детализация] 



end


if @mode='stat'
begin



--select * from v_fa where issued between '20251101' and '20251201'
--and producttype in ('INST', 'PDL')
--order by Продукт


--declare @datefrom date = (select rating_date_from from config) declare @dateto date   = (select rating_date_to   from config)--'20230401'



select '1) Выданная сумма' Показатель,
sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock)
WHERE [Заем выдан] between @datefrom and @dateto    and producttype in ('INST', 'PDL', 'BIG INST')
union


select '2) Выданная сумма план' Показатель,
isnull( sum(bezzalogSumMonth) , 0) + isnull( sum(longInstSumMonth) , 0) 'Выдано'
FROM sale_plan (nolock)
WHERE date = cast(format(@datefrom  , 'yyyy-MM-01') as date)

union
 

select '3) Доля КП' Показатель,
 sum (  fa.[Сумма Дополнительных Услуг Carmoney Net] )   /sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock) fa 
	--left join _request r on r.number = fa.number and r.issued is not null and r.productType= 'big inst'

WHERE [Заем выдан] between @datefrom and @dateto    and fa.producttype in ('INST', 'PDL', 'BIG INST')

union
 
select '4) Доля КП план' Показатель,  ( isnull( sum(bezzalogAddProductSumMonth) , 0) + isnull( sum(longInstAddProductSumMonth) , 0) )/  (
   isnull( sum(bezzalogSumMonth) , 0) + isnull( sum(longInstSumMonth) , 0)  ) 'Выдано'
FROM sale_plan (nolock)
WHERE date = cast(format(@datefrom  , 'yyyy-MM-01') as date)



order by 1

end



if @mode='stat big inst'
begin



select 'Выданная сумма' Показатель,
sum([Выданная сумма]) 'Выдано'
FROM v_fa (nolock)
WHERE [Заем выдан] between @datefrom and @dateto    and producttype in ('big INST')
union


select 'Выданная сумма план' Показатель,
sum(longInstSum) 'Выдано'
FROM sale_plan (nolock)
WHERE date = cast(format(@datefrom  , 'yyyy-MM-01') as date)
order by 1

end



if @mode ='Постобработка'
begin


drop table if exists #Постобработка_t1

select n1.LOGIN,(iif(n2.reason is not null and n1.DURATION!=n2.DURATION,n1.DURATION-n2.DURATION,n1.duration))/(24*60.0*60.0) Время, cast(n1.ENTERED as date) Дата
into #Постобработка_t1
from NaumenDbReport.dbo.status_changes n1
left join NaumenDbReport.dbo.status_changes n2 on n1.LOGIN = n2.LOGIN and n1.STATUS != n2.STATUS and n1.ENTERED = n2.ENTERED and n1.duration != n2.DURATION
where n1.entered between @datefrom and @dateto and n1.STATUS = 'wrapup' and (n2.STATUS = 'wrapup#voice' or n2.STATUS is null) --and n2.DURATION is not null 
--group by n1.LOGIN
drop table if exists #Постобработка_t2
select n.title, t.Дата,sum(t.Время) Время,n.[Звонков совершено] into #Постобработка_t2 from #Постобработка_t1 t join Analytics.dbo.report_naumen_activity_by_login_day  n on t.Дата = n.d and n.LOGIN = t.LOGIN group by n.title, t.Дата,n.[Звонков совершено]
drop table if exists #Постобработка_t3
select title,  sum(Время) Постобработка, sum([Звонков совершено]) 'Звонков совершено' into  #Постобработка_t3 from #Постобработка_t2 group by title

select title
	,SUm(Постобработка) Постобработка
	,SUM([Звонков совершено]) Звонков
	,round(SUm(Постобработка)*3600*24/SUM([Звонков совершено]),0) ПостобработкаСР
from   #Постобработка_t3
group by title


end 
 