 
CREATE   proc [dbo].[sale_rating_main]
@mode nvarchar(max)=''
as
/*

   declare @month date = cast(format(getdate(), 'yyyy-MM-01') as date)

update config
set 				  rating_date_from= 	 @month ,
  				  rating_date_to=dateadd(month, 1, 	 @month) 



*/
declare @report_date date =  (select rating_date_from from config)--cast('20230301' as date)
						--	 (select rating_date_to   from config)
if @mode='Сотрудники'


begin

--drop table if exists sale_employee
--exec python 'df = gs2df("1XVVHn4vJvjriKN0Xy6kgQ4SAY6F75q7mGKVcmqPYTFI", "Сотрудники!A:E")
--insert_into_table(df, "sale_employee")' , 1

--select * from analytics.dbo.employees


select Сотрудник, РГ   from analytics.dbo.employee 
where Направление = 'Telesales' and Должность not in  ('Стажер','Руководитель группы')
and РГ != 'Аутсорс Кедров' and РГ != 'Аутсорс Onecta' and уволен=0
order by 1

end				

if @mode='Сотрудники контроль регистрации'


begin

select Сотрудник, РГ from analytics.dbo.employee
where Направление = 'Installment reg'  and уволен=0
order by 1



end				

if @mode='Выпадающие'


begin

select Сотрудник, Должность, РГ, Качество, Депремация, isnull(Ставок, 1) Ставок, Направление, Выработка, [Заявок в час t-1]  from analytics.dbo.employee
where  уволен=0	   and Направление in ('Telesales' , 'Installment reg')
order by 1



end
if @mode='Стажеры'


begin
select Сотрудник, РГ from analytics.dbo.employee--s 
where Направление = 'Telesales' and Должность = 'Стажер' and уволен=0
order by 1



end

if @mode='План по заявкам'


begin	 

   select СОтрудник, Значение, Дата, case when Дата<getdate()-1 then 1 else 0 end [До вчера] from stg.files.[План по заявкам рейтинг_stg]
where  cast(format( Дата , 'yyyy-MM-01' ) as date)= @report_date  
    

end

if @mode='Коммуникации по лидам'


begin
--declare @report_date date = cast('20230901' as date)



select * from sale_rating_communication_cache


end

 if @mode='Контроль регистрации'


begin


   --declare @report_date date = cast(format(getdate(), 'yyyy-MM-01') as date)

drop table if exists #creg


--select right('89999999999', 10) Телефон, 'uuid' uuid, 'fio'  operatortitle, getdate() creationdate into #creg
--where 1=0

select right(phonenumbers, 10) Телефон, uuid,  operatortitle, creationdate into #creg  from NaumenDbReport.dbo.mv_call_case where projectuuid
in (

'corebo00000000000palm14mi2ltmekc',
'corebo00000000000palm0cu9n4jo2q4')   

and   cast(format( creationdate , 'yyyy-MM-01' ) as date)= @report_date  
			   	  and operatortitle is not null
				  and 1=0


  select uuid,  operatortitle, creationdate,  max(iif(b.Номер is null,0,1))  ПризнакЗаявка ,  max( b.Номер) Заявка, max(a.Телефон) Телефон from #creg a

left join v_fa b on b.Телефон=a.Телефон and b.[Верификация КЦ] between creationdate and dateadd(day, 5, creationdate) and 1=0

group by uuid,  operatortitle, creationdate
  end
--order by creationdate


if @mode='stat'



begin


select * from sale_rating_stat_cache


end

if @mode='Проф лид заявка входящие'
begin

drop table if exists #t1

select Телефон, [Дата лида] into #t1 from Analytics.dbo.v_feodor_leads
where [Дата лида]>=dateadd(day, -1, @report_date)


drop table if exists #comm_incoming

;

with v as (

SELECT Направление
	  ,ФИО_оператора
	  ,НомерТелефона
	  ,ТипОбращения
	  ,ДатаВзаимодействия
	  ,case when Результат in ('Создана заявка на займ под ПТС.', 'Отказ клиента')  then 1 else 0 end as [Профильный]
	  ,Результат
	  ,Описание
	  ,cast(format(ДатаВзаимодействия, 'yyyy-MM-01' ) as date)  Месяц
  FROM [Reports].[dbo].[dm_Все_коммуникации_На_основе_отчета_из_crm]
  where Направление='Входящее' and ТипОбращения='Консультирование по продукту Выдача займа' and  cast(format(ДатаВзаимодействия, 'yyyy-MM-01' ) as date) = @report_date
  and len(НомерТелефона)=10 and isnumeric(НомерТелефона)=1
  )

  select * into #comm_incoming from v


  ;

  with v as (

  select a.*, x.is_recall, ROW_NUMBER() over(partition by Месяц, НомерТелефона order by [Профильный] desc) rn from #comm_incoming a
  outer apply (select 1 is_recall from #t1 b where a.НомерТелефона=b.Телефон and cast(b.[Дата лида] as date) between dateadd(day, -1, a.ДатаВзаимодействия) and dateadd(day, 0, a.ДатаВзаимодействия) ) x 
  where x.is_recall is null


  )
  
  select Направление
	,ФИО_оператора
	,НомерТелефона
	,ДатаВзаимодействия
	,Профильный
	,Результат
	,Описание
  from v
  where Месяц=@report_date
 -- where rn=1


end

if @mode='Постобработка'
begin


select title
	,РГ
	,SUm(Постобработка) Постобработка
	,SUM([Звонков совершено]) Звонков
	,round(SUm(Постобработка)*3600*24/SUM([Звонков совершено]),0) ПостобработкаСР
	,(SUm(Постобработка) + SUm(Готов) + SUm([Время диалога]))*24 ВремяОператор
	--select *
from  [dbo].[sale_rating_acitivity_view]
where cast(format(d, 'yyyy-MM-01') as date)=  @report_date -- Месяц= 'Текущий месяц'
--'2022-12-01' 
group by title
	,РГ
end

if @mode='Аналитические выдачи'
begin

--declare @report_date date =  (select rating_date_from from config)--cast('20230301' as date)


SELECT t.[Номер]
      ,t.[НомерАналитическойЗаявки]
      ,ISNULL(IIF(f.[Группа каналов]='CPA',f.[Канал от источника],f.[Группа каналов]),'Другое') as [Канал для рейтинга_с_учетом_перезаведенных Новый]
      ,t.[CRM_АвторНаименование]
	  ,t.[МобильныйТелефон]
      ,t.[ФИОТЕЛЕФОН]
	  ,t.ДатаЗаявки
      ,t.[ИтоговаяСуммаВыдачиАналитическая]
      ,t.[ИтоговаяСуммаВыдачи]
	  ,t.[Предварительное одобрение]
	  ,t.[аналитический_Предварительное одобрение]
	  ,t.[Контроль данных]
      ,t.[аналитический_Контроль данных]
,t.[аналитический_Заем выдан] 
	  ,isnull(f1.ПризнакЗаймДеньВДень, f.ПризнакЗаймДеньВДень) as ДеньвДень
--,iif(cast(t.[аналитический_Контроль данных] as date) = cast(t.[аналитический_Предварительное одобрение] as date), 1, 0) as ДеньвДень
,cast(t.ДатаЗаявки as date) ДатаЗаявкиДень
,isnull(1-f1.ispts,1-f.ispts) 'Признак Инст'
,isnull(f1.product,f.product) 'Продукт'
, e.РГ
  FROM analytics.[dbo].[dm_report_requests_after_month_with_doubles] t
    left join v_fa f on t.Номер = f.Номер
	left join v_fa f1 on t.[НомерАналитическойЗаявки] = f1.Номер
  left join employee e on e.seller = t.CRM_АвторНаименование

	--left join Reports.dbo.dm_Factor_Analysis fa on t.Номер = fa.Номер
	--left join Reports.dbo.dm_Factor_Analysis fa1 on t.[НомерАналитическойЗаявки] = fa1.Номер
  WHERE cast(format(t.[аналитический_Заем выдан], 'yyyy-MM-01') as date)=  @report_date  and t.[аналитический_Заем аннулирован] is null

end

if @mode='Аналитические заявки'
begin

SELECT   t.[Номер]
      ,t.[НомерАналитическойЗаявки]
      ,ISNULL(IIF(fa.[Группа каналов]='CPA',fa.[Канал от источника],fa.[Группа каналов]),'Другое') as [Канал для рейтинга_с_учетом_перезаведенных Новый]
      ,t.[CRM_АвторНаименование]
	  ,t.[МобильныйТелефон]
      ,t.[ФИОТЕЛЕФОН]
	  ,t.ДатаЗаявки
      ,t.[ИтоговаяСуммаВыдачиАналитическая]
      ,t.[ИтоговаяСуммаВыдачи]
	  ,t.[Предварительное одобрение]
	  ,t.[аналитический_Предварительное одобрение]
	  ,t.[Контроль данных]
      ,t.[аналитический_Контроль данных]
	  ,isnull(fa1.returnType2,fa.returnType2) ВидЗайма
	  , e.РГ
  FROM analytics.[dbo].[dm_report_requests_after_month_with_doubles] t
  left join v_fa fa on t.Номер = fa.Номер
  left join v_fa fa1 on t.[НомерАналитическойЗаявки] = fa1.Номер
  left join employee e on e.seller = t.CRM_АвторНаименование
  WHERE t.МесяцЗаявки=@report_date and 1-fa.isPts=0 and (1-fa1.isPts=0 or fa1.isinstallment is null)
 -- and 1=0
end

if @mode='Профильный лид заявка'
begin


select   a.[Дата]
, a.[Номер]
, a.[ФИОоператора]
, a.[Канал для рейтинга_с_учетом_перезаведенных Новый]
, a.[МобильныйТелефон]
, a.[Проект]
, a.[Длительность]
, a.[Причина отказа]
, e.РГ
from sale_rating_prof_lead_request_cache a 
  left join employee e on e.seller = a.[ФИОоператора]


/*
--	--select top 100 * from  analytics.dbo.[Профильный лид - заявка] t 
--declare @report_date date =  (select rating_date_from from config)--cast('20230301' as date)


drop table if exists #f1

select fa.Номер, fa.[Канал от источника] [Канал от источника_перезаведение],fa.[Группа каналов] [Группа каналов_перезаведение],  1-fa.ispts isInstallment
into #f1
from v_fa fa
where fa.ДатаЗаявкиПолная>=@report_date  and  fa.productType='pts'


select
	t.Дата,
	t.Номер,
	t.ФИОоператора
	,ISNULL(IIF(fa.[Группа каналов_перезаведение]='CPA',fa.[Канал от источника_перезаведение],fa.[Группа каналов_перезаведение]),'Другое') as [Канал для рейтинга_с_учетом_перезаведенных Новый]
	--отказы по черновикам получат канал другое
	,t.МобильныйТелефон
	, t.[Проект] 
	, t.Длительность 
	, t.[Причина отказа] 
from
	analytics.dbo.[Профильный лид - заявка] t (nolock)
	left join #f1 fa on t.Номер = fa.Номер
where
	LEFT(t.Номер,14)!='отказ по лиду ' and месяц=@report_date  --and fa.isInstallment=0 в витрине и так только инст
union all
select
	t.Дата,
	t.Номер,
	t.ФИОоператора
	--, IIF( st.[Группа каналов]= 'unknown' or st.[Группа каналов] is NULL,'Другое', IIF(st.[Группа каналов]='CPA',st.[Канал от источника],st.[Группа каналов]))
	, IIF(t.[Канал для отчета] is NULL, 'Другое', t.[Канал для отчета])
	--отказы по лидам по которым канал не определился (сегодняшние) получат канал другое
	,t.МобильныйТелефон
	, t.[Проект] 
	, t.Длительность 
	, t.[Причина отказа] 
from
	 analytics.dbo.[Профильный лид - заявка] t  (nolock)
	 --[Reports].[dbo].[dm_report_requests_and_refuses_after_month_for_rating] t  (nolock)
	--left join #f2 st with(nolock) on TRY_CAST(SUBSTRING(t.Номер,15,len(t.Номер) -14) AS INT)=st.id
where
	LEFT(t.Номер,14)='отказ по лиду ' and месяц=@report_date  -- and st.IsInstallment=0 там и так только инст
--	order by 4


*/
/*
declare @report_date date = cast('20221001' as date)
declare @show_detail int = 1

drop table if exists #f1

select fa.Номер, fa.[Канал от источника_перезаведение],fa.[Группа каналов_перезаведение], fa.isInstallment
into #f1
from Reports.dbo.dm_Factor_Analysis fa
where fa.ДатаЗаявкиПолная>=@report_date  and fa.IsInstallment=0


drop table if exists #f2

select st.id, st.[Группа каналов], st.[Канал от источника],st.IsInstallment
into #f2
from feodor.dbo.dm_leads_history  st (nolock)
where st.[UF_REGISTERED_At]>=@report_date and st.IsInstallment=0 


select
	t.Дата,
	t.Номер,
	t.ФИОоператора,
	ISNULL(IIF(fa.[Группа каналов_перезаведение]='CPA',fa.[Канал от источника_перезаведение],fa.[Группа каналов_перезаведение]),'Другое') as [Канал для рейтинга_с_учетом_перезаведенных Новый]
	,t.МобильныйТелефон
from
	[Reports].[dbo].[dm_report_requests_and_refuses_after_month_for_rating] t (nolock)
	left join #f1 fa on t.Номер = fa.Номер
where
	LEFT(t.Номер,14)!='отказ по лиду ' and месяц=@report_date and 1=@show_detail and fa.isInstallment=0
union all
select
	t.Дата,
	t.Номер,
	t.ФИОоператора,
	IIF( st.[Группа каналов]= 'unknown' or st.[Группа каналов] is NULL,'Другое', IIF(st.[Группа каналов]='CPA',st.[Канал от источника],st.[Группа каналов]))
	,t.МобильныйТелефон
from
	 [Reports].[dbo].[dm_report_requests_and_refuses_after_month_for_rating] t  (nolock)
	left join #f2 st with(nolock) on TRY_CAST(SUBSTRING(t.Номер,15,len(t.Номер) -14) AS INT)=st.id
where
	LEFT(t.Номер,14)='отказ по лиду ' and месяц=@report_date and 1=@show_detail and st.IsInstallment=0
*/


end



if @mode='Дозвон заявка докреды и повторники'
begin


select * from dbo.[Дозвон заявка докреды и повторники]
where [Месяц звонка]=@report_date 
and 1=0

end 
 
