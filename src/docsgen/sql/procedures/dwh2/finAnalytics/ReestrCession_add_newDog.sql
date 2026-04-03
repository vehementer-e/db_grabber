
/* Процедура добавляет новые договора в таблицу реестр договоров Цессии (ReestrCession)
0.Удяляем все договора за период @dDay
1 Первый этап- создается временная таблица tmpProvod из всех проводок по договрам, по след корреспонденции:
	ДТ 60323 КТ 61217/ Дт 60322  Кт = 61217-это "Выручка"
	ДТ 48810 КТ 61217 -это Резер БУ
	ДТ 61217 КТ 60323  выбраются только с 3-им субконто 'Госпошлина' -это ГП
	ДТ 60324 КТ 61217 -это Резерв по ГП и Пеням
	ДТ 71502 КТ 61217 -это финрез БУ и НУ (устанавливается знак по технич заданию)
	ДТ 61217 КТ 71501 -это финрез БУ и НУ (устанавливается знак по технич заданию)
	У всех этих проводок по 3-им субконто дожно быть имя 'ПередачаПравТребований'
	
	ДТ 48810 КТ 71201 это Резер НУ 'ПередачаПравТребований'
	У этой проводки нет признака 

	Также в эту таблицу помещаются соотвевующие Номенклатруные группы и имена Продуктов

2. Второй этап - 
   А)создание временной таблицы tabRes на основе таблицы tmpProvod,
   путем суммирования(группирования) необходимых значений по дате, корреспонденции
   Кроме того на этом этапе показателю "Резер НУ" определяется признак 'ПередачаПравТребований'
   Б)формирование общего табличного выражения joinPBR на основе dwh2.finAnalytics.pbr_monthly
   с выборкой акктуальных номенклатуных групп для договоров с максимальной датой
3. Третий этап  - добавление новых договор и обновление данных по удаленным договорам  в таблице реестра Цессий(ReestrCession), если такие найдены
	в данных UMFO по цессиям, наполение данными из проводок по Основной сумме долга, Процентам, Пени,Выручка, ГП,Резер БУ,Резер НУ,Резерв по ГП и Пеням,финрез БУ и НУ
	При добавлении новых договоров записывается текущая дата

		
	*/

CREATE PROC [finAnalytics].[ReestrCession_add_newDog] 
	
AS
BEGIN
--0
	

	declare @dDay int =60--2810
	declare @startDelDate date = cast(dateadd(day,-@dDay,getdate()) as date), @endDelDate date =getdate()
	declare @startCountRow int, @endCountRow int,@updateRow int
	set @startCountRow=(select count(*) from finAnalytics.ReestrCession)
	set @updateRow=( select count(*) from finAnalytics.ReestrCession where REPDATE between @startDelDate and @endDelDate)
	--set @delRow=@@ROWCOUNT

	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name
	
	declare @subject  varchar(250) ='Регистр по Цессии-новые договора '
											
	-- переменные для формирования текста сообщения
	declare @msgHeader varchar(max)=''
	declare @msgFloor varchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message varchar(max)=''

begin try	
  begin tran 
  delete from finAnalytics.ReestrCession where REPDATE between @startDelDate and @endDelDate
  
--1
drop table IF EXISTS #tmpProvod
--создаем временная таблица проводок 
create table #tmpProvod (
	datT datetime 
	,numDog varchar(60)
	,dt nvarchar(10) 
	,kt nvarchar(10)
	,od float
	,prc float
	,peni float
	,viruchka float
	,reservBU float
	,reservNU float
	,gp float
	,reservGP_P float
	,finreservBU float
	,finreservNU float
	,mem nvarchar(200)
	)
insert into #tmpProvod
	(datT,numDog,dt,kt,od,prc,peni,viruchka,reservBU,reservNU,gp,reservGP_P,finreservBU,finreservNU,mem)
	select
		datT=a.Период
		,numDog=isnull(d.Номер,k.Номер)
		,dt=b.Код 
		,kt=c.Код 
		,od=case when b.Код='61217' and c.Код = '48801' then isnull(a.Сумма,0) else 0 end
		,prc=case when b.Код='61217' and c.Код = '48802' then isnull(a.Сумма,0) else 0 end
		,peni=case when (b.Код='61217' and c.Код = '60323') and (upper(a.Содержание)=upper('Себестоимость по пени по суду (БУ, НУ)')) then isnull(a.Сумма,0) else 0 end
		,viruchka =case when (b.Код='60323' and c.Код = '61217')or(b.Код='60322' and c.Код = '61217') 
						then isnull(a.Сумма,0) else 0 end
		,reservBU =case when b.Код='48810' and c.Код = '61217' then isnull(a.Сумма,0) else 0 end
		,reservNU =case when b.Код='48810' and c.Код = '71201' then isnull(a.СуммаНУДт,0) else 0 end
		,gp = case when (b.Код='61217' and c.Код = '60323') and (upper(sprkt.Наименование)=upper('Госпошлина')) then isnull(a.Сумма,0) else 0 end
		,reservGP_P = case when b.Код='60324' and c.Код = '61217' then isnull(a.Сумма,0) else 0 end
		,finreservBU = case 
							when (b.Код='71502' and c.Код = '61217') then isnull(a.Сумма,0) 
							when (b.Код='61217' and c.Код = '71501') then isnull(a.Сумма,0)*-1 
					   else 0 end
		,finreservNU = case 
							when (b.Код='71502' and c.Код = '61217') then isnull(a.СуммаНУДт,0) 
							when (b.Код='61217' and c.Код = '71501') then isnull(a.СуммаНУДт,0)*-1
					   else 0 end
		,mem=isnull(memKt.Имя,memDt.Имя)
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов d on a.СубконтоDt2_Ссылка=d.Ссылка and d.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов k on a.СубконтоCt2_Ссылка=k.Ссылка and k.ПометкаУдаления=0
	left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomDT on d.АЭ_НоменклатурнаяГруппа=nomDT.Ссылка and nomDT.ПометкаУдаления=0x00
	left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomKT on k.АЭ_НоменклатурнаяГруппа=nomKT.Ссылка and nomKT.ПометкаУдаления=0x00
	left join dwh2.finAnalytics.nomenkGroup ngDt on nomDt.Наименование=ngDt.UMFONames
	left join dwh2.finAnalytics.nomenkGroup ngKt on nomKt.Наименование=ngKt.UMFONames
	left join stg._1cUMFO.Справочник_БНФОСубконто sprkt on a.СубконтоCt3_Ссылка=sprkt.Ссылка
	left join stg._1cUMFO.Справочник_БНФОСубконто sprdt on a.СубконтоDt3_Ссылка=sprdt.Ссылка
	left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов memKt on a.СубконтоCt3_Ссылка=memKt.Ссылка 
	left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов memDt on a.СубконтоDt3_Ссылка=memDt.Ссылка 
	where (((    (b.Код='61217' and c.Код = '48801')--ОД
				or (b.Код='61217' and c.Код = '48802')--проценты
				or ((b.Код='61217' and c.Код = '60323') and (upper(a.Содержание)=upper('Себестоимость по пени по суду (БУ, НУ)')))--Пени
				or((b.Код='60323' and c.Код = '61217')or(b.Код='60322' and c.Код = '61217'))----Выручка
				or (b.Код='48810' and c.Код = '61217')--Резер БУ
				or ((b.Код='61217' and c.Код = '60323') and (sprkt.Наименование='Госпошлина'))--ГП
				or (b.Код='60324' and c.Код = '61217')--Резерв по ГП и Пеням
				or (b.Код='71502' and c.Код = '61217')--финрез БУ и НУ
				or (b.Код='61217' and c.Код = '71501'))--финрез БУ и НУ
				and (upper(memKt.Имя)=upper('ПередачаПравТребований') or upper(memDt.Имя)=upper('ПередачаПравТребований')))
			or ((b.Код='48810' and c.Код = '71201') and d.Номер is not null))--Резер НУ
			and a.Активность=0x01
	--group by
	--	a.Период
	--	,isnull(d.Номер,k.Номер)
	--	,b.Код 
	--	,c.Код 
	--	,a.Сумма
	--	,a.СуммаНУДт
	--	,sprkt.Наименование
	--	,isnull(memKt.Имя,memDt.Имя)

---2
--временная таблица на основе сумм по соответвующим показателям из таблицы Проводок
drop table if exists  #tabRes

create table #tabRes (
	datT datetime 
	,numDog varchar(60)
	,od float
	,prc float
	,peni float
	,viruchka float
	,reservBU float
	,reservNU float
	,gp float
	,reservGP_P float
	,finreservBU float
	,finreservNU float
	,mem nvarchar(200)
	)
insert into #tabRes
select 
	datT
	,numDog
	,sum(isnull(od,0))
	,sum(isnull(prc,0))
	,sum(isnull(peni,0))
	,sum(isnull(viruchka,0))
	,sum(isnull(reservBU,0))
	,sum(isnull(reservNU,0))
	,sum(isnull(gp,0))
	,sum(isnull(reservGP_P,0))
	,sum(isnull(finreservBU,0))
	,sum(isnull(finreservNU,0))
	,max(isnull(mem,'')) -- для показателей(Резервов НУ) устанавливаем значение 'ПередачаПравТребований'
from #tmpProvod
where numDog is not null
group by datT,numDog

-- таблица договоров цессии по которым был возврата
--это необходимо чтобы пропустить договора по которым был возврат а потом повторная цессия
delete [dwh2].[finAnalytics].[ReestrCession] where numDogBack is not null



------
;with cte_joinPBR
as
(select dognum ,nomenkgroup ,rn=row_number() over(partition by dognum order by repmonth desc)
from dwh2.finAnalytics.pbr_monthly)

--3 
--заполняем новыми значениями
insert into [finAnalytics].[ReestrCession]
	(REPDATE,REPDATETIME,Num,Comment,Cesionary,dogCesionary,dogCesionaryDate,dogCesionaryNum,
	SummDok,ProcZadolg1,SummUchRaschAvans,SummUchRaschContragent,MinChisloDayProsrochki,
	OnCommisInZadolg,OnShtrafInZadolg,OnPeniInZadolg,OnOtherDohodInZadolg,Client,dogClient,
	dogClientDate,NomenkGroup,DayPros,ZadolgOsnovDolg,ZadolgProc,ZadolgComm,ZadolgShtraf,
	ZadolgPeni,ZadolgOtherDohod,ZadolgShtrafPeniOtherDohod,ZadolgAll,ProcZadolg2,Summ,
	SchetAnalVib,SchetAnalVibShtrafPeniOtherDohod,SummShtrafPeniOtherDohod,ZadolgShtrafSud,
	ZadolgPeniSud,ZadolgOtherDohodSud,
	produkt,viruchka,reservBU,reservNU,gp,reservGP_P,finreservBU,finreservNU,procPriceBalans,
	procReservBU,procReservNU,checkFinreservBU,checkFinreservNU,numDogBack,dateBack,numDogBackChangePrice,
	summChangePrice,dateChangePrice,newPriceDogCession,newFinreservBU,newFinreservNU,newProcPriceBalans,
	insertDate, updateDate,OdInReservBU,PrcInReservBU)	
	select
	REPDATE	= cast(DATEADD(year,-2000,a.Дата) as date) --Дата
	,REPDATETIME	 = DATEADD(year,-2000,a.Дата) --ДатаВремя
	,Num	 = a.Номер --Номер
	,Comment	 = a.Комментарий --Комментарий
	,Cesionary	 = cl1.Наименование --Цессионарий
	,dogCesionary	 = dog1.Наименование --ДоговорЦессионария
	,dogCesionaryDate	 = cast(dateadd(year,-2000,iif(dog1.Дата='2001-01-01',a.Дата,dog1.Дата)) as date) --ДоговорЦессионарияДата
	,dogCesionaryNum	 = dog1.Номер --ДоговорЦессионарияНомер
	,SummDok	 = isnull(a.СуммаДокумента,0) --СуммаДокумента
	,ProcZadolg1	 = isnull(a.ПроцентЗадолженность,0) --ПроцентЗадолженность
	,SummUchRaschAvans	 = acc1.Код --СчетУчетаРасчетовПоАвансам
	,SummUchRaschContragent	 = acc2.Код --СчетУчетаРасчетовСКонтрагентом
	,MinChisloDayProsrochki	 = a.МинимальноеЧислоДнейПросрочки --МинимальноеЧислоДнейПросрочки
	,OnCommisInZadolg	 = case when a.ВключатьКомиссииВЗадолженность =0x01 then 'Да' else 'Нет' end --ВключатьКомиссииВЗадолженность 
	,OnShtrafInZadolg	 = case when a.ВключатьШтрафыВЗадолженность =0x01 then 'Да' else 'Нет' end --ВключатьШтрафыВЗадолженность
	,OnPeniInZadolg	 = case when a.ВключатьПениВЗадолженность =0x01 then 'Да' else 'Нет' end --ВключатьПениВЗадолженность
	,OnOtherDohodInZadolg 	 = case when a.ВключатьПрочиеДоходыВЗадолженность =0x01 then 'Да' else 'Нет' end --ВключатьПрочиеДоходыВЗадолженность
	,Client	 = cl2.Наименование --Клиент
	,dogClient	 = dog2.НомерДоговора --КлиентДоговорНомер
	,dogClientDate	 = cast(dateadd(year,-2000,dog2.ДатаДоговора) as date) --КлиентДоговорДата
	,NomenkGroup	 = acc5.nomenkGroup --Номенклатурная группа
	,DayPros	 = isnull(b.ДнейПросрочки,0) --ДнейПросрочки
	,ZadolgOsnovDolg	 = isnull(dop.od,0)--b.ЗадолженностьОсновнойДолг --ЗадолженностьОсновнойДолг
	,ZadolgProc	 =isnull(dop.prc,0) --b.ЗадолженностьПроценты --ЗадолженностьПроценты
	,ZadolgComm	 = isnull(b.ЗадолженностьКомиссии,0) --ЗадолженностьКомиссии
	,ZadolgShtraf	 = isnull(b.ЗадолженностьШтрафы,0) --ЗадолженностьШтрафы
	,ZadolgPeni	 =isnull(dop.peni,0) --b.ЗадолженностьПени --ЗадолженностьПени
	,ZadolgOtherDohod	 =isnull( b.ЗадолженностьПрочиеДоходы,0) --ЗадолженностьПрочиеДоходы
	,ZadolgShtrafPeniOtherDohod	 = isnull(b.ЗадолженностьШтрафыПениПрочиеДоходы,0) --ЗадолженностьШтрафыПениПрочиеДоходы
	,ZadolgAll	 = isnull(b.ЗадолженностьОбщая,0) --ЗадолженностьОбщая
	,ProcZadolg2	 = isnull(b.ПроцентЗадолженность,0) --ПроцентЗадолженность
	,Summ	 = isnull(b.Сумма,0) --Сумма
	,SchetAnalVib	 = acc3.Код --СчетАналитическогоУчетаВыбытия
	,SchetAnalVibShtrafPeniOtherDohod	 = acc4.Код --СчетАналитическогоУчетаВыбытияШтрафыПениПрочиеДоходы
	,SummShtrafPeniOtherDohod	 = isnull(b.СуммаШтрафыПениПрочиеДоходы,0) --СуммаШтрафыПениПрочиеДоходы
	,ZadolgShtrafSud	 = isnull(b.ЗадолженностьШтрафыПоСуду,0) --ЗадолженностьШтрафыПоСуду
	,ZadolgPeniSud	 = isnull(b.ЗадолженностьПениПоСуду,0) --ЗадолженностьПениПоСуду
	,ZadolgOtherDohodSud	 = isnull(b.ЗадолженностьПрочиеДоходыПоСуду,0) --ЗадолженностьПрочиеДоходыПоСуду
	,produkt	 = ng.groupName --Продукт
	,viruchka	 = isnull(dop.viruchka,0) --Выручка
	,reservBU	 = isnull(dop.reservBU,0) --Резерв БУ
	,reservNU	 = isnull(dop.reservNU,0) --Резерв НУ
	,gp	 = isnull(dop.gp,0) --ГП
	,reservGP_P	 = isnull(dop.reservGP_P,0) --Резерв по ГП и Пеням
	,finreservBU	 = isnull(dop.finreservBU,0) --Финрез БУ
	,finreservNU	 = isnull(dop.finreservNU,0) --Финрез НУ
	,procPriceBalans	 = round(isnull(dop.viruchka,0)/nullif((isnull(dop.od,0)+isnull(dop.prc,0)),0),2) --Цена в % от балансовой стоимости (ОД+%%)
	,procReservBU	 = round(isnull(dop.reservBU,0)/nullif(isnull(dop.od,0)+isnull(dop.prc,0),0),2) --Резерв БУ%
	,procReservNU	 =round(isnull(dop.reservNU,0)/nullif(isnull(dop.od,0)+isnull(dop.prc,0),0),2) --Резерв НУ%
	,checkFinreservBU	 = round(isnull(dop.od,0)+isnull(dop.prc,0)-isnull(dop.viruchka,0)-isnull(dop.reservBU,0)+isnull(dop.gp,0)+isnull(dop.peni,0)-isnull(dop.reservGP_P,0)-isnull(dop.finreservBU,0),2) --Проверка финреза БУ
	,checkFinreservNU	 = round(isnull(dop.od,0)+isnull(dop.prc,0)+isnull(dop.gp,0)+isnull(dop.peni,0)-isnull(dop.viruchka,0)-isnull(dop.finreservNU,0),2) --Проверка финреза НУ
	,numDogBack	 = null --Номер договора займа Возврат
	,dateBack	 = null --Дата возврата
	,numDogBackChangePrice	 = null --Номер договора займа Изменение цены
	,summChangePrice	 = 0 --Сумма корректировки по перерасчету цены прав требования
	,dateChangePrice	 = null --Дата изменения цены договора цессии
	,newPriceDogCession	 = 0 --Новая цена договора цессии
	,newFinreservBU	 = 0 --Новый Финрез БУ
	,newFinreservNU	 = 0 --Новый Финрез НУ
	,newProcPriceBalans	 = 0 --Новая Цена в % от балансовой стоимости (ОД+%%)
	,insertDate	 = getdate() --Дата добавления договора
	,updateDate	 = null --Дата обновление данных по Мемориальным ордерам
	,OdInReservBU=round(isnull(dop.od,0)/nullif( isnull(dop.od,0)+isnull(dop.prc,0) ,0)
												*isnull(dop.reservBU,0)
												,2)
    ,PrcInReservBU=round(isnull(dop.prc,0)/nullif( isnull( dop.od,0)+isnull(dop.prc,0) ,0)
												*isnull(dop.reservBU,0)
												,2)

	from Stg._1cUMFO.Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного a
	inner join Stg._1cUMFO.Документ_АЭ_ПередачаПравТребованийЗаймаПредоставленного_Займы b on a.Ссылка = b.Ссылка
	left join Stg._1cUMFO.Справочник_Контрагенты cl1 on a.Контрагент=cl1.Ссылка
	left join Stg._1cUMFO.Справочник_Контрагенты cl2 on b.Контрагент=cl2.Ссылка
	left join Stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog1 on a.ДоговорКонтрагента=dog1.Ссылка
	left join Stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный dog2 on b.Займ=dog2.Ссылка
	left join Stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acc1 on a.СчетУчетаРасчетовПоАвансам = acc1.Ссылка
	left join Stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acc2 on a.СчетУчетаРасчетовСКонтрагентом= acc2.Ссылка
	left join Stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acc3 on b.СчетАналитическогоУчетаВыбытия= acc3.Ссылка
	left join Stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета acc4 on b.СчетАналитическогоУчетаВыбытияШтрафыПениПрочиеДоходы= acc4.Ссылка
	left join cte_joinPBR acc5 on dog2.НомерДоговора = acc5.dogNum and acc5.rn=1
	left join dwh2.finAnalytics.nomenkGroup ng on acc5.nomenkGroup=ng.UMFONames
	left join #tabRes  dop on dog2.НомерДоговора=dop.numDog and a.Дата=dop.datT
	left join [dwh2].[finAnalytics].[ReestrCession] ces on dog2.НомерДоговора=ces.dogClient
	
	where 
		a.ПометкаУдаления=0x00 and a.Проведен=0x01
		and ces.dogClient is null
--	set @endCountRow=(select count(*) from finAnalytics.ReestrCession)

commit tran
set @endCountRow=(select count(*) from finAnalytics.ReestrCession)
set @message= concat(@message,'Кол-во новых договоров: ',@endCountRow-@startCountRow,char(10))


set @message= concat(@message,'Кол-во обновленных договоров: ',@updateRow,char(10))

set @message=concat(@msgHeader,@message,@msgFloor)
exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'

--делаем запись реестре отчетов
	---/Определение наличия данных/
    declare @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(insertDate) from [dwh2].[finAnalytics].[ReestrCession]) as varchar)
    
    ---/Фиксация времени расчета/
    update dwh2.[finAnalytics].[reportReglament]
    set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
    where [reportUID] in (48)
----
--заполняем обновленными данными Расчет предельной суммы убытков
 exec dwh2.finAnalytics.updateCessionUbt @maxDateRest

 --финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

end try 

 begin catch
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
   ;throw 51000 
			,@message
			,1;    
  end catch
END
