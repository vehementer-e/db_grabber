
CREATE   proc   [dbo].[Подготовка отчета исследование по клиентам]
as

begin

--select * from ##t2
----where rn_for_call<=250
--return

select * from ##t4
where rn_for_call<=250
return

drop table if exists #t2
drop table if exists #t3
drop table if exists #loans	

drop table if exists #bl
select * into #bl from stg._1cCRM.BlackPhoneList
select * into #loans from mv_loans

drop table if exists #tvr
select external_id, accepted_amount, initial_amount into #tvr from [dwh_new].[dbo].[tmp_v_requests] a

drop table if exists #dpd

select CRMClientGUID, max([Текущая просрочка]) [Текущая просрочка] into #dpd from #loans group by CRMClientGUID

drop table if exists #employments		
select * into #employments from openquery (lkprod, 'select * from employments') 

drop table if exists #t1

select num_1c, client_employment_id, e.name [Тип занятости]  into #t1 from stg._LK.requests a
left join #employments e on a.client_employment_id=e.id

drop table if exists #fa
select Номер,[Первичная сумма], [Сумма заявки],[Сумма одобренная], РегионПроживания,   [СуммарныйМесячныйДоход_CRM]  into #fa from reports.dbo.dm_Factor_Analysis

drop table if exists #t2

select 
  a.[Дата выдачи]
, year(a.[Дата выдачи]) [Год выдачи]
, a.CRMClientGUID
, a.код
, a.[Пользовался МП]
, a.[Список договоров клиента]
, a.[Список открытых договоров клиента]
, a.Пол
, null [СуммарныйМесячныйДоход_CRM]
, a.[Дата рождения]
, b.[Тип занятости]
--, tz.Наименование  [Тип занятости мфо]
, a.Должность
, a.[Марка тс аналитическая]+' '+a.[Модель тс аналитическая] [Марка модель тс аналитическая]
, a.[Марка тс]
, a.[Модель тс]
, a.[Год тс] 
, a.[Стоимость ТС] 
--, a.[Цель займа]
, isnull(a.[Цель займа аналитическая], 'Другое') [Цель займа аналитическая]
, a.product
, a.[Текущая процентная ставка]
, a.[Срок жизни займа]
, a.[Текущая просрочка]
, a.[Вид займа]
, a.[Список транспортных средств клиента]
, a.[Дата погашения день]
, isnull(c.[Первичная сумма], tvr.initial_amount) [Первичная сумма]
, null [Сумма заявки]
, isnull(c.[Сумма одобренная], tvr.accepted_amount) [Сумма одобренная]
, case when dateadd(year, 3, try_cast(cast( [Год тс] as varchar(4))+'-07-01' as date))>=[Дата выдачи день] then 'Авто до 3 лет' else 'Старое авто' end [Новое авто]
, Analytics.dbo.get_age(try_cast(cast( [Год тс] as varchar(4))+'-07-01' as date), [Дата выдачи день]) ВозрастАвто
, analytics.dbo.fullAge(case when year([Дата рождения])>1800 then [Дата рождения] end , cast(a.[Дата выдачи] as date)) [Возраст на дату выдачи] 

, try_cast(cast( [Год тс] as varchar(4))+'-07-01' as date) ДатаРожденияАвто
, [Дата выдачи день]
, a.Сумма [Выданная сумма]
, a.Регион РегионПроживания
, a.Фамилия+' '+a.Имя+' '+a.Отчество [ФИО]
, g.gmt
, a.CP_info
, a.comissions_info
, a.[Основной телефон клиента CRM]
, a.[Телефон договор CMR]
,case when a.[Список открытых договоров клиента]is null then 1 else 0 end [Признак погашен]
,case when  Должность in 
(
'ИП','ГЕНЕРАЛЬНЫЙ ДИРЕКТОР','ИНДИВИДУАЛЬНЫЙ ПРЕДПРИНИМАТЕЛЬ','ПРЕДПРИНИМАТЕЛЬ'--,'',
) or [Тип занятости]='Владелец бизнеса/ИП' then 'Предприниматель' else 'Найм + остальные' end [Тип занятости на основании должности и занятости]
into #t2
from #loans a
left join #t1 b on a.[Номер заявки]=b.num_1c
left join #fa c on a.[Номер заявки]=c.Номер
left join v_gmt g on g.region=c.РегионПроживания
left join #tvr tvr on a.[Номер заявки]=tvr.external_id
--left join stg._1cMFO.Документ_ГП_Заявка z on z.Номер=a.[Номер заявки]
--left join stg._1cMFO.Справочник_ТипыЗанятости tz on tz.Ссылка=z.ТипЗанятости
--left join #bl bl on bl.Phone=a.[Основной телефон клиента CRM]
where a.isInstallment=0-- and year([Дата выдачи день])>=2020
--and bl.Phone is null
--order by 1



;
with v as (select *, row_number() over(partition by Код order by (select 1)) rn from #t2)
delete from v where rn>1


drop table if exists #agr
select [Марка модель тс аналитическая]
, [Год выдачи]
,   cnt
, ROW_NUMBER() over(partition by   [Год выдачи] order by cnt desc ) rn 
into #agr  
from (
select [Марка модель тс аналитическая], [Год выдачи], count(*)  cnt from #t2
group by [Марка модель тс аналитическая], [Год выдачи]
)x

drop table if exists #agr1
select [Марка модель тс аналитическая]
, [Тип занятости на основании должности и занятости]
, [Год выдачи]
,   cnt
, ROW_NUMBER() over(partition by   [Год выдачи], [Тип занятости на основании должности и занятости] order by cnt desc ) rn 
into #agr1  
from (
select [Марка модель тс аналитическая], [Год выдачи],[Тип занятости на основании должности и занятости], count(*)  cnt from #t2
group by [Марка модель тс аналитическая], [Год выдачи], [Тип занятости на основании должности и занятости]
)x

--select * from #agr


drop table if exists ##t2
select a.*,
case when [Первичная сумма]<=250000 then '1) ..250т]'
     when [Первичная сумма]<=500000 then '2) (250т..500т]'
     when [Первичная сумма]<=750000 then '3) (500т..750т]'
     when [Первичная сумма]>750000 then '4) (750+..' end
	 [Первичная сумма Бакет],
case when [Сумма одобренная]<=250000 then '1) ..250т]'
     when [Сумма одобренная]<=500000 then '2) (250т..500т]'
     when [Сумма одобренная]<=750000 then '3) (500т..750т]'
     when [Сумма одобренная]>750000 then '4) (750+..' end
	 [Сумма одобренная Бакет],
	 agr.rn rn_Модель_ТС,
	 agr1.rn [rn_Тип занятости на основании должности и занятости_Модель_ТС]
	into ##t2
from #t2 a
left join #agr agr on agr.[Год выдачи]=a.[Год выдачи] and agr.[Марка модель тс аналитическая]=a.[Марка модель тс аналитическая]
left join #agr1 agr1 on agr1.[Год выдачи]=a.[Год выдачи] and agr1.[Марка модель тс аналитическая]=a.[Марка модель тс аналитическая] and agr1.[Тип занятости на основании должности и занятости]=a.[Тип занятости на основании должности и занятости]
where [Дата выдачи] between '20160301' and '20230301'



return

drop table if exists #t3

delete from #t2 where [Основной телефон клиента CRM] in (select Phone from #bl)

select * into #t3 from (
select a.*, row_number() over(partition by a.CRMClientGUID order by [Дата выдачи]) rn , dpd.[Текущая просрочка] [Текущая макс просрочка по клиенту] from #t2 a
left join #dpd dpd on dpd.CRMClientGUID=a.CRMClientGUID
) x
where isnull([Текущая просрочка], 0)=0 and isnull([Текущая макс просрочка по клиенту], 0)=0 and rn=1  
order by 1 desc


drop table if exists ##t4
select *
, analytics.dbo.fullAge(case when year([Дата рождения])>1800 then [Дата рождения] end , cast(getdate() as date)) [Возраст текущий] 
,ROW_NUMBER() over(partition by [Признак погашен] order by [Дата выдачи] desc) rn_for_call
into ##t4
from #t3
where year([Дата выдачи])>=2021 and [Дата выдачи]<'20230301'
and Должность in 
(
'ИП','ГЕНЕРАЛЬНЫЙ ДИРЕКТОР','ИНДИВИДУАЛЬНЫЙ ПРЕДПРИНИМАТЕЛЬ','ПРЕДПРИНИМАТЕЛЬ'--,'',
)
--select Номер, [Сумма заявки], [Сумма одобренная], [Выданная сумма], [Верификация КЦ месяц], [Вид займа],  from mv_dm_Factor_Analysis
--where isInstallment=0


--select * from (
--select номер from stg._1cMFO.Документ_ГП_Заявка
--where типзанятости<>0
--union
--select num_1c from #t1 where [Тип занятости]<>''
--) x
--intersect
--select Номер from mv_dm_Factor_Analysis
--where [Заем выдан] >='20210101' and isinstallment=0  
--order by 1 desc


end