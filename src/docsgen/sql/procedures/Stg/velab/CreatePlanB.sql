
  -- exec velab.CreatePlanB
-- Usage: запуск процедуры с параметрами
-- EXEC [velab].[CreatePlanB] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
  CREATE   procedure [velab].[CreatePlanB]
  as

  begin

  set nocount on 
  ---
  -- CRM
  ---

 drop table if exists #crm_info  

 SELECT CRMClientIDRREF=s.ссылка,
        НомерЗаявки=Док.НомерЗаявки
      , Стат_Наименование=Стат.Наименование
      , DATEADD(YEAR,-2000,Док.ДатаРождения)  ДатаРождения
      , [timeZoneGMT+]= CRM_ВремяПоГринвичу_GMT--чп.ОтклонениеОтМосковскогоВремени + 3 
      , видыКи_Наименование=видыКи.Наименование

      , CRMClientGUID= cast(dwh2.dbo.getGUIDFrom1C_IDRREF(s.Ссылка)  as nvarchar(100))
	    , CRMRequestGUID=cast(dwh2.dbo.getGUIDFrom1C_IDRREF(Док.Ссылка)  as nvarchar(100))
	    , CRMRequestDate=dateadd(year,-2000,Док.Дата)
      , fio=Док.Фамилия+ N' '+Док.Имя+N' '+Док.Отчество
	    , FamilyStatus=MFO_FamilyStatus.Имя

	    , VIN=MFO_Requests.vin
	    , MFO_CarMarkIDRREF=MFO_Requests.Марка
	    , MFO_CarModelIDRREF=MFO_Requests.Модель
	    , MFOContractIDRREF = MFO_Contracts.ССылка
      , Док.РыночнаяОценкаСтоимости
      , br. нАИМЕНОВАНИЕ РегионФактическогоПроживания
        into #crm_info   
 --select *      
   FROM _1ccrm.Документ_ЗаявкаНаЗаймПодПТС Док
   
   join _1cMfo.[Документ_ГП_Заявка] MFO_Requests on Док.Ссылка=MFO_Requests.Ссылка--CMR_Contracts.заявка
   join _1cMfo.[Документ_ГП_Договор] MFO_Contracts on MFO_Requests.Ссылка=MFO_Contracts.Заявка
   left join  _1ccrm.[Справочник_Партнеры] s on  s.Ссылка=Док.Партнер
   left join _1ccrm.[Справочник_БизнесРегионы] br on br.Ссылка=s.РегионФактическогоПроживания
   inner join _1ccrm.Справочник_СтатусыЗаявокПодЗалогПТС Стат on Док.Статус = Стат.Ссылка --and Стат.Наименование = 'Проблемный' 
   left join  _1ccrm.Справочник_КонтактныеЛицаПартнеров_КонтактнаяИнформация ки on ки.Ссылка = док.КонтактноеЛицо
   left join  _1ccrm.Справочник_ВидыКонтактнойИнформации видыКи  on видыКи.Ссылка = ки.Вид
   left join _1cMfo.Перечисление_ГП_СемейноеПоложение MFO_FamilyStatus on MFO_Requests.СемейноеПоложение=MFO_FamilyStatus.ссылка
      
  where Док.НомерЗаявки<>'' and Стат.Наименование not in
    ('Заем погашен'
    ,'Отказ документов клиента'
    ,'Отказано'
    ,'Аннулировано'
    ,'Черновик'
    ,'Забраковано'
    ,'Клиент передумал'
    ,'Назначение встречи'
    ,'Встреча назначена'
    ,'Предварительное одобрение'
    ,'Заем аннулирован'
    ,'Отказ клиента'
    ,'Верификация КЦ'
    ,'Черновик из ЛК'
    ,'Контроль подписания договора'
    )
  --order by Док.НомерЗаявки


     if object_id ('tempdb.dbo.#mfo_contracts') is not null drop table #mfo_contracts

;
with max_dates as 
(
	select договор,count(*) с,min(Период) mn,max(Период) mx
	from _1cMfo.[РегистрСведений_ГП_СписокДоговоров] 
	group by договор
)

	select  MFO_Contracts.ссылка MFOContractIDRREF ,MFO_Contracts.Дата,MFO_Requests.VIN,MFO_Requests.Марка,MFO_requests.Модель,ref.CRMClientIDRREF 
	, ОценочнаяCтоимостьАвто estimationPrice
	, ДисконтАвто discount
	, li.Ликвидность liquidity
	, СтажРаботы experience
	, ТелРабочийРуководителя workplacePhone
	, cast(НазваниеОрганизации as nvarchar(200)) +N' '+ cast(Должность  as nvarchar(200)) +N' '+ cast(tz.Наименование as nvarchar(200)) workplace 
	, СуммаДоходов monthlyIncome
	, СуммаРасходов monthlyOutcome
	,MFO_Requests.ТелефонАдресаПроживания homePhone
	, АдресРаботы workplaceAddres
	, ФИОКонтактногоЛица  FIO_ContactPerson

  , MFO_Requests.[КЛСтатус]        ContactPerson_Status
  , MFO_Requests.[КЛДатаРождения]  ContactPerson_BirthDate
  , MFO_Requests.[КЛТелМобильный]  ContactPerson_MobilePhone
  , MFO_Requests.[КЛТелКонтактный] ContactPerson_ContactPhone

 ,[ИНН_Организации]
,СтатусОрганизации
,ЮридическийАдресОрганизации= cast(ЮридическийАдресОрганизации as nvarchar(2048))
,АдресРаботы= cast(АдресРаботы as nvarchar(2048))
,РегионФактическогоПроживания= cast(РегионФактическогоПроживания as nvarchar(2048))
,ДоходПоСправке
,pv.ДоходРосстат
,pv.ДоходИзКИ
,pv.РасходИзКИ
,ДоходПодтвержденныйПоТелефону
,ДоходРаботаЯндекс
,Должность
,cast(o.Адрес as nvarchar(512)) OfficeAddress
	into #mfo_contracts
	from      _1cMfo.[РегистрСведений_ГП_СписокДоговоров] rs
	join max_dates on rs.Период=max_dates.mx and rs.Договор=max_dates.Договор
	join      _1cMfo.[Справочник_ГП_СтатусыДоговоров] MFO_Contracts_statuses on  rs.Статус=MFO_Contracts_statuses.Ссылка
	join      _1cMfo.[Документ_ГП_Договор] MFO_Contracts on MFO_Contracts.ссылка=rs.Договор
  left join _1cMfo.Справочник_ГП_Офисы o on MFO_Contracts.Точка=o.Ссылка
	left join _1cMfo.[Документ_ГП_Заявка] MFO_Requests  on MFO_Requests.Ссылка=MFO_Contracts.Заявка
left join   _1cMfo.РегистрСведений_ПрограммаВерификации pv on MFO_Requests.ссылка=pv.Заявка


join dwh_new.staging.CRMClient_references ref on ref.MFOContractIDRREF=MFO_Contracts.ссылка
left join _1cMfo.Справочник_ГП_МаркаАвтомобиля ma on MFO_Requests.Марка = ma.Ссылка
left join _1cMfo.Справочник_ГП_МодельАвтомобиля mo on MFO_Requests.Модель = mo.Ссылка
left join _1cMfo.Справочник_ГП_ЛиквидностьТС li on MFO_Requests.ЛиквидностьТС = li.Ссылка
left join _1cMfo.[Справочник_ТипыЗанятости] tz on tz.ссылка=MFO_Requests.ТипЗанятости
where MFO_Contracts_statuses.Наименование not  in ('аннулирован', 'зарегистрирован')

if object_id('tempdb.dbo.#cars') is not null drop table #cars

;
with clients as (
select distinct CRMClientIDRREF,vin from #crm_info c 
)
,max_dates as
(
select m.CRMClientIDRREF,max(Дата) md
from clients c  join  #mfo_contracts m on m.CRMClientIDRREF=c.CRMClientIDRREF and m.vin=c.vin
group by 
m.CRMClientIDRREF
)

select m.* 
into #cars
from  #mfo_contracts m join max_dates  on max_dates.CRMClientIDRREF=m.CRMClientIDRREF and max_dates.md=m.дата 



drop table if exists #t 
select distinct
 [GUID клиента]=                                      c.CRMClientGUID
,[ФИО клиента]=                                       c.FIO
,[GUID заявки]=                                       c.CRMRequestGUID
,[Номер заявки]=                                      c.НомерЗаявки
,[Дата заявки]=                                       c.CRMRequestDate
,[Семейное положение]=                                c.FamilyStatus
,[Сумма доходов]=                                     cars.monthlyIncome
,[Сумма расходов]=                                    cars.monthlyOutcome
,[Адрес (сведения о работе)]=                          cast( cars.workplaceAddres as nvarchar(1024))
,[Рабочий телефон (сведения о работе)]=                cast( workplacePhone as nvarchar(20))
,[ФИО руководителя (сведения о работе)]=               cars.FIO_ContactPerson
,[VIN TC]=                                            cars.VIN
,[Дисконт ]=                                          cars.discount
,[Ликвидность]=                                       isnull(cars.liquidity,-1)
,[Оценочная стоимость]=                               cars.estimationPrice
,Стат_Наименование
,СтатусОрганизации
,ЮридическийАдресОрганизации
,АдресРаботы
,C.РегионФактическогоПроживания
,ДоходПоСправке
,ДоходРосстат
,ДоходИзКИ
,РасходИзКИ
,ДоходПодтвержденныйПоТелефону
,ДоходРаботаЯндекс
,Должность
,РыночнаяОценкаСтоимости
 ,OfficeAddress
--,*
into #t
from  
(select distinct c.CRMClientGUID
                 ,c.FIO
                 ,c.CRMRequestGUID
                 ,c.НомерЗаявки
                 ,c.CRMRequestDate
                 ,c.FamilyStatus
                 --,c.VIN
                 ,c.CRMClientIDRREF
                 ,Стат_Наименование
                 ,РыночнаяОценкаСтоимости
                 , РегионФактическогоПроживания
 from #crm_info c)
 
  c 
   LEFT join #cars  cars on cars.crmClientIDRREF=c.crmClientIDRREF

   
   --drop table if exists velab.Clients_PlanB   
   delete from velab.Clients_PlanB   
insert into velab.Clients_PlanB([GUID клиента], [ФИО клиента], [GUID заявки], [Номер заявки], [Дата заявки], [Семейное положение], [Сумма доходов], [Сумма расходов], [Адрес (сведения о работе)], [Рабочий телефон (сведения о работе)], [ФИО руководителя (сведения о работе)], [VIN TC], [Дисконт ], [Ликвидность], [Оценочная стоимость], [Стат_Наименование], [СтатусОрганизации], [ЮридическийАдресОрганизации], [АдресРаботы], [РегионФактическогоПроживания], [ДоходПоСправке], [ДоходРосстат], [ДоходИзКИ], [РасходИзКИ], [ДоходПодтвержденныйПоТелефону], [ДоходРаботаЯндекс], [Должность], [РыночнаяОценкаСтоимости], [OfficeAddress])
select [GUID клиента], [ФИО клиента], [GUID заявки], [Номер заявки], [Дата заявки], [Семейное положение], [Сумма доходов], [Сумма расходов], [Адрес (сведения о работе)], [Рабочий телефон (сведения о работе)], [ФИО руководителя (сведения о работе)], [VIN TC], [Дисконт ], [Ликвидность], [Оценочная стоимость], [Стат_Наименование], [СтатусОрганизации], [ЮридическийАдресОрганизации], [АдресРаботы], [РегионФактическогоПроживания], [ДоходПоСправке], [ДоходРосстат], [ДоходИзКИ], [РасходИзКИ], [ДоходПодтвержденныйПоТелефону], [ДоходРаботаЯндекс], [Должность], [РыночнаяОценкаСтоимости], [OfficeAddress]
from #t --order by 1

--select count(1) from velab.Clients_PlanB
end



/*    
 select * from #t
 where [GUID заявки] in (
select [GUID заявки] from #t
group by [GUID заявки] having count(*)>1
)
*/
