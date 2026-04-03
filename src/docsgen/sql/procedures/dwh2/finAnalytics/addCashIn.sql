


/*

*/
CREATE PROCEDURE [finAnalytics].[addCashIn] 
    
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
	drop table if exists #mainPrc
	create table #mainPrc (sp_name nvarchar(255))
	insert into #mainPrc (sp_name)
		values(@sp_name)
	declare @log_IsError bit=0
	declare @log_Mem nvarchar(2000)	='Ok'
	exec dwh2.finAnalytics.sys_log @sp_name,0,@sp_name
	---
	declare @subjectHeader  nvarchar(250) ='Cash-In', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Внесение данных в таблицу Cash-In: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	
	

	declare @dDay int =84
	declare @startDate date = dateadd(day,-@dDay,getdate()), @endDate date =getdate()

 begin try	
  begin tran 
	--set @startDate ='2025-08-16'
	--set  @endDate ='2025-10-30'
	delete from dwh2.finAnalytics.CashIn where repdate between @startDate and @endDate
	--------


	
	-------------
	set @startDate =dateadd(year,2000,@startDate)
	set @endDate =dateadd(year,2000,@endDate)
	

	drop table if exists #dogClient
	create table #dogClient (
		Ссылка binary(16)
		,Дата datetime
		,Номер nvarchar(200)
		,Код nvarchar(50)
		,АЭ_РазделУчета binary(16)
		,БНФОГруппаФинансовогоУчета binary(16)
		,АЭ_ГруппаФинансовогоУчетаДополнительная binary(16)
		)
	insert into #dogClient(Ссылка,Дата,Номер,Код,АЭ_РазделУчета,БНФОГруппаФинансовогоУчета,АЭ_ГруппаФинансовогоУчетаДополнительная)
		select 
		Ссылка=a.Ссылка
		,Дата=a.Дата
		,Номер=a.Номер
		,Код=substring(c.Код,1,3)
		,АЭ_РазделУчета=a.АЭ_РазделУчета
		,БНФОГруппаФинансовогоУчета=a.БНФОГруппаФинансовогоУчета
		,АЭ_ГруппаФинансовогоУчетаДополнительная=a.АЭ_ГруппаФинансовогоУчетаДополнительная
		from  Stg._1cUMFO.Справочник_ДоговорыКонтрагентов a
		left join stg._1cUMFO.РегистрСведений_АЭ_РегламентированныйУчетЗаймовПредоставленных b on a.АЭ_ДокументОснование_Ссылка=b.Займ
		left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета c on b.СчетУчетаОсновногоДолга=c.Ссылка
		where a.ПометкаУдаления=0x00
		union all
		select 
		Ссылка=a.Ссылка
		,Дата=a.Дата
		,Номер=a.Номер
		,Код=substring(c.Код,1,3)
		,АЭ_РазделУчета=a.АЭ_РазделУчета
		,БНФОГруппаФинансовогоУчета=null
		,АЭ_ГруппаФинансовогоУчетаДополнительная=null
		from  stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов a
		left join stg._1cUMFO.РегистрСведений_АЭ_РегламентированныйУчетЗаймовПредоставленных b on a.АЭ_ДокументОснование_Ссылка=b.Займ
		left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета c on b.СчетУчетаОсновногоДолга=c.Ссылка
		where a.ПометкаУдаления=0x00

	drop table if exists #Registor
	create table #Registor (
		dat date
		,dt varchar(5)
		,kt varchar(5)
		,numdog varchar(200)
		,beginDate date
		,summ float
		,mem varchar(200)
		,rzd varchar(200)
		,fin varchar(200)
		,findop varchar(200)
		,plat varchar(200)
		,prichClose varchar(200)
		,reg binary(16)
		,regNum int
		,checkSubKonto int
		,aKt int
		,aDt int

		)

	--для дополнительной проводки 62101-47422 необходимо что бы причина была Закрытие залогом
	-- в таблице stg._1cUMFO.Документ_АЭ_СписаниеЗаймовПредоставленных есть дубли на дату как с одинаковой причиной закрытия так и с разной
	;with cte_dogZalog
	as (
	select
		distinct
		dat=cast(sdok.Дата as date)
		,agent=sdok.ОтборКонтрагент
		,mem=sprich.Наименование
	from stg._1cUMFO.Документ_АЭ_СписаниеЗаймовПредоставленных sdok 
	left join stg._1cUMFO.Справочник_АЭ_ПричиныЗакрытияДоговоров sprich on sdok.ПричинаЗакрытия=sprich.Ссылка and sprich.ПометкаУдаления=0x00
	where sdok.ПометкаУдаления=0x00 and sdok.Проведен=0x01
		and sdok.ОтборКонтрагент!=0x00000000000000000000000000000000 
	and upper(sprich.Наименование)=upper('Закрытие долга залоговым имуществом')
	)
	--------
	insert into #Registor(dat,dt,kt,numdog,beginDate,summ,mem,rzd,fin,findop,plat,prichClose,reg,regNum,checkSubKonto,aKt,aDt)
	select
		dat=cast(a.Период as date)
		,dt=b.Код	
		,kt=c.Код
		,numDog= case 
					when (b.Код ='47422'and c.Код='60322')or(b.Код ='61217' and c.Код ='60323') then dog2.Номер --цессия
					when (b.Код ='47422'and c.Код='60332') then dog2.Номер --доп продукты
					else isnull(dog1.Номер,dog2.Номер) end
			--iif((b.Код ='47422'and c.Код='60322')or(b.Код ='61217' and c.Код ='60323') ,dog2.Номер,isnull(dog1.Номер,dog2.Номер)) --цессия
		,beginDate=case 
						when (b.Код ='47422'and c.Код='60322')or(b.Код ='61217' and c.Код ='60323') then cast(dog2.Дата as date) --цессия
						when (b.Код ='47422'and c.Код='60332') then dog2.Дата --доп продукты
						else cast(isnull(dog1.Дата,dog2.Дата) as date) end
			--iif((b.Код ='47422'and c.Код='60322')or(b.Код ='61217' and c.Код ='60323'),cast(dog2.Дата as date),cast(isnull(dog1.Дата,dog2.Дата) as date)) --цессия
		,summ=a.Сумма
		,mem= iif (b.Код ='60323' and c.Код ='47422',isnull(memDt.Наименование,a.Содержание),isnull(memCt.Наименование,a.Содержание))
		,rzd=rzd.Имя
		,fin=fin.Наименование
		,findop=findop.Наименование
		,plat=cl.Наименование
		,prichClose=zlg.mem
		,Reg=a.Регистратор_Ссылка
		,RegNum=a.НомерСтроки
		,checkSubKonto =iif(a.СубконтоCt2_Ссылка!=0 and a.СубконтоCt1_Ссылка!=0,1,0)
		,aKt=iif(substring(dog1.Код,1,3) in ('488','487','494'),1,0)
		,aDt=iif(substring(dog2.Код,1,3) in ('488','487','494'),1,0)
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a 
			left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
			left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
			left join #dogClient dog1 on a.СубконтоCt2_Ссылка=dog1.Ссылка 
			left join #dogClient dog2 on a.СубконтоDt2_Ссылка=dog2.Ссылка
			left join stg._1cUMFO.Справочник_БНФОСубконто memCt on a.СубконтоCt3_Ссылка=memCt.Ссылка and memCt.ПометкаУдаления=0x00
			left join stg._1cUMFO.Справочник_БНФОСубконто memDt on a.СубконтоDt3_Ссылка=memDt.Ссылка and memDt.ПометкаУдаления=0x00
			left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов vvz on a.СубконтоDt3_Ссылка=vvz.Ссылка
			left join stg._1cUMFO.Перечисление_АЭ_РазделыУчета rzd on dog1.АЭ_РазделУчета=rzd.Ссылка
			left join stg._1cUMFO.Справочник_БНФОГруппыФинансовогоУчетаРасчетов fin on dog1.БНФОГруппаФинансовогоУчета=fin.Ссылка and fin.ПометкаУдаления=0x00
			left join stg._1cUMFO.Справочник_БНФОГруппыФинансовогоУчетаРасчетов findop on dog1.АЭ_ГруппаФинансовогоУчетаДополнительная=findop.Ссылка and findop.ПометкаУдаления=0x00
			--для проводки 62101-47422
			left join cte_dogZalog zlg on a.СубконтоCt1_Ссылка=zlg.agent and zlg.dat=cast(a.Период as date)
			---
			left join (select Ссылка,Наименование,'Платежная системы' as Тип from stg._1cUMFO.Справочник_Контрагенты where 
								(trim(Код)='00-006777' or Родитель=0x810300155D01C00511E80657309F8165) and 	ПометкаУдаления=0x00)	cl on a.СубконтоDt1_Ссылка=cl.Ссылка
	where cast(a.Период as date) between @startDate and @endDate
				and a.Активность=0x01
				
				
				---------------------
				and (upper(isnull(memCt.Наименование,a.Содержание))!=upper('Выдача займа'))
				and	(
						(substring(dog1.Код,1,3) in  ('488','487','494')	
							and (
									(b.Код in ('20501','47423')and c.Код ='47422' )-- поступления на счет клиента
									or
									((b.Код ='47422'and c.Код in('48801','49401'))or(b.Код ='61217'and c.Код ='48801'and upper(vvz.Имя) not in (upper('ПередачаПравТребований'),upper('ЧастичноеПрощение')))) --сумма в счет погашения ОД
									or
									((b.Код ='47422'and c.Код in('48809','49409'))or(b.Код ='61217'and c.Код ='48809' and upper(vvz.Имя)!=upper('ЧастичноеПрощение')))--сумма в счет погашения процентов
									or
									((b.Код ='47422'and c.Код ='60323') or (b.Код ='61217'and c.Код ='60323'and upper(vvz.Имя)not in (upper('ПередачаПравТребований'),upper('ЧастичноеПрощение')) ))--сумма в счет погашения пеней и штрафов, ГП
									or
									(b.Код ='60332' and c.Код ='47422') --возврат доп услуг
									or 
									(b.Код ='61217' and c.Код ='60323' and ((upper(rzd.Имя)in (upper('УступкаПраваТребования'),upper('ПередачаПравТребованийЗаймов'))
																					or
																					(upper(fin.Наименование)=upper('60322,60323_Расчеты с прочими дебиторами и кредиторами') and upper(findop.Наименование)=upper('прочие ДЛЯ_60323 (цессия)'))
																					)))											--поступление цессионарию
									or
									(b.Код ='62101'and c.Код ='47422')--для погашение залогом
								)
						  )
						  or
						  (substring(dog2.Код,1,3) in  ('488','487','494')	
							  and (
									(b.Код ='47422'and c.Код ='60323') -- нестандартных проводок сумма в счет погашения пеней и штрафов, ГП
									or 
									(b.Код ='47422'and c.Код='60322' )--поступление цессионарию
									or
									(b.Код ='47422'and c.Код='20501') --возвраты поступления на счет клиента
									or
									(b.Код in('48801','49401') and c.Код ='47422') --возвраты ОД
									or
									(b.Код in('48809','49409') and c.Код ='47422' )--возврат процентов
									or
									(b.Код ='60323' and c.Код ='47422') -- возврат пеней и госпошлины
									or
									(b.Код ='47422' and c.Код ='60332') --дополнительные услуги 
								   )
							)
						)
 	drop table if exists #Provodki
	create table #Provodki (
			dat date
			,dt varchar(5)
			,kt varchar(5)
			,numdog varchar(200)
			,beginDate date
			,mem varchar(200)
			,summIn float
			,summCes float
			,summOD float
			,summPRC float
			,summPeni float
			,summGP float
			,summDop float
			,plat varchar(200)
			,summZalog float
			,reg binary(16)
			,regNum int
			)
	
	insert into	#Provodki 
			(dat,dt,kt,numdog,beginDate,mem,summIn,summCes,summOD,summPRC,summPeni,summGP,summDop,plat,summZalog,reg,regNum)
	
		select 
			dat=a.dat
			,dt=a.dt
			,kt=a.kt
			,numDog=a.numdog
			,beginDate=a.beginDate
			,mem=a.mem
			--поступления/возраты клиента
			,summIn=case 
							when a.dt in ('20501','47423') and a.kt ='47422' 	then a.summ 
							when (a.dt ='47422'and a.kt='20501') then a.summ*-1 
							else 0 end
			--поступление по цессиионарию
			,summCes=case when ((a.dt  ='47422'and a.kt ='60322') or (a.dt ='61217' and a.kt ='60323') and 
								(upper(a.rzd) in (upper('УступкаПраваТребования'),upper('ПередачаПравТребованийЗаймов')) or (upper(a.fin)=upper('60322,60323_Расчеты с прочими дебиторами и кредиторами') and upper(a.findop)=upper('прочие ДЛЯ_60323 (цессия)'))))
							then a.summ else 0 end
			--сумма/возрат в счет погашения ОД
			,summOD=case 
							when a.dt  in('47422','61217')and a.kt  in ('48801','49401') then a.summ 
							when (a.dt in('48801','49401')and a.kt='47422') then a.summ*-1 
							else 0 end
			--сумма/возрат в счет погашения процентов
			,summPRC=case 
							when a.dt  in('47422','61217')and a.kt  in('48809','49409') then a.summ 
							when (a.dt in('48809','49409') and a.kt ='47422' ) then a.summ*-1 
							else 0 end
			--сумма/возрат в счет погашения пеней
			,summPeni=case 
							when (a.dt  in ('47422','61217')and a.kt  ='60323') and (upper(a.mem) in (upper('Пени'),upper('Погашение пени')))	then a.summ
							when (a.dt ='60323' and a.kt ='47422') and (upper(a.mem) in (upper('Пени'),upper('Погашение пени'))) then a.summ*-1
							else 0 end
			--сумма/возрат погашения ГП
			,summGP=case 
							when (a.dt  in('61217','47422')and a.kt  ='60323') and upper(a.mem)=upper('Госпошлина') then a.summ
							when (a.dt ='60323' and a.kt ='47422') and upper(a.mem)=upper('Госпошлина') then a.summ*-1
							else 0 end
			--сумма/возрат дополнительных услуг
			,summDop=case 
						   when a.dt  ='47422'and a.kt  ='60332' then a.summ
						   when a.dt ='60332' and a.kt ='47422' then a.summ*-1
						   else 0 end

			,plat=case 
						  when (a.dt  ='20501' and a.kt  ='47422') or (a.dt ='47422' and a.kt ='20501') or (a.dt ='47422'and a.kt='60322')or(a.dt ='61217' and a.kt ='60323')
						  then 'Расчетный счет'
						  when a.dt  ='47423' and a.kt  ='47422' 
						  then a.plat
						  else '' end
			--погашение залогом
			,summZalog=case
						when  a.dt  ='62101'and a.kt  ='47422' then a.summ
						else 0 end
			,reg=a.reg
			,regNum=a.regNum
		from #Registor a
		where a.checkSubKonto=1
				and (
						(a.dt in ('20501','47423')and a.kt ='47422' and a.aKt=1)-- поступления на счет клиента
						or
						((a.dt ='47422'and a.kt in('48801','49401') and a.aKt=1)or(a.dt ='61217'and a.kt ='48801' and a.aKt=1)) --сумма в счет погашения ОД
		
						or
						((a.dt ='47422'and a.kt in('48809','49409')and a.aKt=1)or((a.dt ='61217'and a.kt ='48809' and a.aKt=1)))--сумма в счет погашения процентов
		
						or
						(a.dt in('47422','61217')and a.kt ='60323'--сумма в счет погашения пеней и штрафов, ГП
								and upper(a. mem) in (upper('Погашение пени'),upper('Пени'),upper('Госпошлина'))
								and a.aKt=1)
				
						or
						(a.dt ='47422' and a.kt ='60332' and upper(a.rzd)=upper('ДополнительныеПродуктыУслуги') and a.aDt=1) --дополнительные услуги 
						or
						((a.dt ='47422'and a.kt='60322'and a.aDt=1 ) or (a.dt ='61217' and a.kt ='60323'and a.aKt=1
							and (upper(a.rzd)in (upper('УступкаПраваТребования'),upper('ПередачаПравТребованийЗаймов'))
								or (upper(a.fin)=upper('60322,60323_Расчеты с прочими дебиторами и кредиторами') and upper(a.findop)=upper('прочие ДЛЯ_60323 (цессия)')))
								))	--цессионарии
						or
						(a.dt ='47422'and a.kt='20501'and a.aDt=1) --возвраты поступления на счет клиента
						or
						(a.dt in('48801','49401') and a.kt ='47422'and a.aDt=1) --and (upper(isnull(mem.Наименование,a.Содержание))!=upper('Выдача займа')))--возвраты ОД
						or
						(a.dt in('48809','49409') and a.kt ='47422'and a.aDt=1 )--возврат процентов
						or
						(a.dt ='60323' and a.kt ='47422' and upper(a. mem) in(upper('Погашение пени'),upper('Пени'),upper('Госпошлина'))and a.aDt=1) -- возврат пеней и госпошлины
						or
						(a.dt ='60332' and a.kt ='47422'and a.aKt=1)-- upper(a.rzd)=upper('ДополнительныеПродуктыУслуги')) --возврат дополнительные услуги 
						or
						(a.dt ='62101'and a.kt ='47422'  and upper(a.prichClose)=upper('Закрытие долга залоговым имуществом'))--погашение залогом
					)
	
	drop table if exists #tmp
	create table #tmp (
			dat date
			,dat1 date
			,numdog varchar(200)
			,beginDate date
			,summIn float
			,summCes float
			,summOD float
			,summPRC float
			,summPeni float
			,summGP float
			,summDop float
			,plat varchar(200)
			,summZalog float
			);
	create index ix_tmp_dat1_mumdog on #tmp(dat1, numdog) 


	insert into #tmp (dat,dat1, numdog,beginDate,summIn,summCes,summOD,summPRC,summPeni,summGP,summDop,plat,summZalog)
		select 
			dat
			,convert(date, dateadd(year, -2000, dat))
			,numdog
			,beginDate
			,sum(summIn) summIn
			,sum(summCes) summCes
			,sum(summOD) summOD
			,sum(summPRC) summPRC
			,sum(summPeni) summPeni
			,sum(summGP) summGP
			,sum(summDop) summDop
			,plat
			,sum(summZalog) summZalog
		from #Provodki
		group by 
			dat 
			,numdog
		    ,beginDate
			,plat

	drop table if exists #bucket
	create table #bucket (
		id int
		,bucket_name varchar(20)
		,beginDay int
		,endDay int)
	insert into #bucket
		values
		  (1,'0',0,0)
		 ,(2,'1-3',1,3)
		 ,(3,'4-30',4,30)
		 ,(4,'31-60',31,60)
		 ,(5,'61-90',61,90)
		 ,(6,'91-120',91,120)
		 ,(7,'121-150',121,150)
		 ,(8,'151-180',151,180)
		 ,(9,'181-210',181,210)
		 ,(10,'211-240',211,240)
		 ,(11,'241-270',241,270)
		 ,(12,'271-300',271,300)
		 ,(13,'301-330',301,330)
		 ,(14,'331-360',331,360)
		 ,(15,'360+',361,999999)
 
	--остатки из регистра по всем договорам на дату по микрозаймам
	drop table if exists #ost
	select
	      repdate=cast(a.период as date)
	      ,beginOst=sum(isnull(a.СуммаНачальныйОстатокКт,0))
		  ,endOst=sum(isnull(a.СуммаКонечныйОстатокКт,0))
	into #ost
	from  Stg._1cUMFO.РегистрСведений_СЗД_ДанныеПоСчетамДляDWH a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетУчета=b.Ссылка
	left join stg._1cUMFO.Справочник_Контрагенты c on a.Субконто1_Ссылка=c.Ссылка
	left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов d on a.Субконто2_Ссылка=d.Ссылка
	left join stg._1cUMFO.Документ_АЭ_ДоговорЗалога dz on d.АЭ_ДокументОснование_Ссылка=dz.Ссылка
	left join stg._1cUMFO.РегистрСведений_АЭ_РегламентированныйУчетЗаймовПредоставленных rz on (d.АЭ_ДокументОснование_Ссылка=rz.Займ or dz.Займ=rz.Займ)
	left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета k on rz.СчетУчетаОсновногоДолга=k.Ссылка
	where b.Код='47422'
	and cast(a.период as date) between @startDate and @endDate
	and substring(isnull(k.Код,''),1,3) in ('488','487','494')
	group by cast(a.период as date)
	
	--считаем сохраняем данные по общему погашению за время жизни займа 
	drop table if exists #lastSummInAll
	select
      numDog
      ,summInAll=sum(summIn)
	into #lastSummInAll
	from dwh2.finAnalytics.CashIn
	group by numdog
	

	insert into dwh2.finAnalytics.CashIn (
		repdate,numDog,client,beginDate,dpdBeginDay,dpdEndDay,produkt,bucketBeginDay
		,summInAll,summIn,summCes,summIn_Ces,summOD,summPRC,summPeni,summGP,summDop,summOut,bucketEndDay,plat,pp,pdp,pdp14,pdp1,chdp
		,ostBeginDayUMFO,ostEndDayUMFO
		,summZalog)
	select 
		[отчетная дата]=cast(dateadd(year,-2000,a.dat) as date)
		,[номер договора]=a.numdog
		,[заемщик]=z.НаименованиеЗаемщика
		,[дата начала договора]=dateadd(year,-2000,a.beginDate)
		,[количество дней просрочки (на начало дня)]=isnull(cmr.dpd_begin_day,0)
		,[количество дней просрочки (на конец дня)]=isnull(cmr.dpd,0)
		,[Продукт]=dwh2.finAnalytics.nomenk2prod (nom.Наименование)
		,[бакет просрочки (на начало дня)]=isnull((select bucket_name from #bucket where cmr.dpd_begin_day between beginDay and endDay),(select bucket_name from #bucket where id=1))
		,[суммарный платеж (за все врем жизни займа)]=sum(a.summIn)over (partition by a.numdog order by a.dat desc rows between current row and unbounded following)
														+isnull(s.summInAll,0)--сумма которая накопилась за предыдущие периоды
		,[поступления на счет клиента]=a.summIn
		,[перечисление цессионарию]=a.summCes
		,[итого поступило на счета клиента]=a.summIn-a.summCes
		,[сумма в счет погашения ОД]=a.summOD
		,[сумма в счет погашения процентов]=a.summPRC
		,[сумма в счет погашения пеней]=a.summPeni
		,[сумма в счет погашения ГП]=a.summGP
		,[доп.услуги оплачиваемые клиентом]=a.summDop
		,[списание суммы планового платежа со счета клиента]=a.summOD+a.summPRC+a.summPeni+a.summGP
		,[бакет просрочки (на конец дня)]=isnull((select bucket_name from #bucket where cmr.dpd between beginDay and endDay),(select bucket_name from #bucket where id=1))
		,[Платежная cистема]=a.plat
		,[Полное погашение]=iif(
				(a.summOD>0 or a.summPRC>0 or a.summPeni>0)and(z.ОстатокОДвсего+z.ОстатокПроцентовВсего+z.ОстатокПени)<=0
				,1
				,0
				)

		,[ПДП (1/0)]=iif(
				(a.summOD>0 or a.summPRC>0 or a.summPeni>0)and(z.ОстатокОДвсего+z.ОстатокПроцентовВсего+z.ОстатокПени)<=0 and a.dat<cast(z.ДатаОкончанияДоговора as date)
				,1
				,0
				)
		,[ПДП14 (1/0)]=iif(
				(datediff(day,z.ДатаДоговора,a.dat)<=14)
				and
				(a.summOD>0 or a.summPRC>0 or a.summPeni>0)and(z.ОстатокОДвсего+z.ОстатокПроцентовВсего+z.ОстатокПени)<=0 and a.dat<cast(z.ДатаОкончанияДоговора as date)
				,1
				,0
					)
		,[ПДП до первой даты погашения по графику (1/0) (Кроме PDL)]=iif(
				a.dat<=dateadd(day,day(eomonth(z.ДатаДоговора)),z.ДатаДоговора)--если дата погашения меньше даты платежа
				and 
				(a.summOD>0 and a.summPRC>0 and a.summPeni>0)and(z.ОстатокОДвсего+z.ОстатокПроцентовВсего+z.ОстатокПени)<=0 and a.dat<cast(z.ДатаОкончанияДоговора as date)
				and
				dwh2.finAnalytics.nomenk2prod (nom.Наименование)<>'PDL'
				,1
				,0
				)
		,[ЧДП (1/0)]=0
		--остатки из регистра по всем договорам на дату
		,ost.beginOst
		,ost.endOst
		--погашение залогом добавил 03.03.26
		,[Поступление на переплату по внесудебной реализации]=isnull(a.summZalog,0)
	from #tmp a
		--Только за отчетную дату
	left join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных z on z.ОтчетнаяДата=a.dat1 and a.numdog=z.номерДоговора
	--выбираем те записи, для определ номен группы, которые соотетвстуют дате начало договора 
	left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный nz on a.numdog=nz.номерДоговора and nz.ПометкаУдаления=0x00
															and nz.Проведен=0x01 and	nz.ДополнительноеСоглашение=0x00
															--and	a.beginDate=cast(nz.ДатаДоговора as date)
	left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nom on nz.НоменклатурнаяГруппа=nom.Ссылка and nom.ПометкаУдаления=0x00

	left join dwh2.dbo.dm_cmrstatbalance  cmr on a.numdog=cmr.external_id and dateadd(year,-2000,a.dat) =cmr.d

	left join #ost ost on cast(a.dat as date)=ost.repdate
	left join #lastSummInAll s on a.numdog=s.numDog 

	
	
	
  commit tran
	exec dwh2.finAnalytics.addCashIn_Check @startDate,@endDate
	exec dwh2.finAnalytics.addCashIn_CHDP @startDate,@endDate
	
	set @subject=concat('OK! ',@subjectHeader) 
	set @message=concat('Данные за ',@dDay,' дней обновлены')
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1,104,106'
	
	--делаем запись реестре отчетов
	---/Определение наличия данных/
    declare @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repdate) from [dwh2].[finAnalytics].[CashIn]) as varchar)

    ---/Фиксация времени расчета/
    update dwh2.[finAnalytics].[reportReglament]
    set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
    where [reportUID] in (56)
	----финиш лог
	exec dwh2.finAnalytics.sys_log @sp_name,1,@sp_name
 end try 

 begin catch
    -- финиш лог
	set @log_IsError =1
	set @log_Mem =ERROR_MESSAGE()
	exec finAnalytics.sys_log @sp_name,1,@sp_name,@log_IsError,@log_Mem
	---
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

