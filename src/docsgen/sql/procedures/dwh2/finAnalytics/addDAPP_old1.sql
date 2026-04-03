



/*

*/
CREATE PROCEDURE [finAnalytics].[addDAPP_old1] 
    @repmonth date
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	
	declare @subjectHeader  nvarchar(250) ='ДАПП массив', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Обновление данных в ДАПП массиве: ',FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	
	declare @dateStart date ='4021-01-01'
	set @repmonth =eomonth (dateadd(year,2000, @repmonth))
							
	--договора у которых в dwh2.finAnalytics.credClients нет информации по региону выдачи
	drop table if exists #mainRegion
	create table #mainRegion (numdog nvarchar(50),nameRegion nvarchar(100))
	insert into #mainRegion (nameRegion,numdog)
		values ('Чувашская Республика - Чувашия','18021509890001'), 
			   ('Ханты-Мансийский Автономный округ - Югра АО','21060700112450'),
			   ('Ханты-Мансийский Автономный округ - Югра АО','21030100084215'), 
			   ('Кемеровская обл','21020100075435'), 
			   ('Ханты-Мансийский Автономный округ - Югра АО','21021400079255'),
			   ('Кемеровская обл','21031900089480') 

 begin try	
  begin tran 
	truncate table dwh2.finAnalytics.DAPP

	drop table if exists #bnfo
	select 
		dat=cast(a.Период as date)
		,dt=b.Код 
		,kt=c.Код
		,summ=a.Сумма
		,СубконтоCt1_Ссылка= case 
								when a.СубконтоCt1_Ссылка=0xB0A7F99596A21E9711F041272273974C then  0xB0A7F99596A21E9711F040502EBC4C1F
								when a.СубконтоCt1_Ссылка=0xA2E80050568397CF11ED33F2AB90129E then 0xA3010050568397CF11EEFD5905B46E04
								else a.СубконтоCt1_Ссылка end
		,СубконтоCt2_Ссылка=a.СубконтоCt2_Ссылка
		,СубконтоCt3_Ссылка=a.СубконтоCt3_Ссылка
		,СубконтоDt1_Ссылка=case 
								when a.СубконтоDt1_Ссылка=0xB0A7F99596A21E9711F041272273974C then  0xB0A7F99596A21E9711F040502EBC4C1F
								when a.СубконтоDt1_Ссылка=0xA2E80050568397CF11ED33F2AB90129E then 0xA3010050568397CF11EEFD5905B46E04
								else a.СубконтоDt1_Ссылка end
		,СубконтоDt2_Ссылка=a.СубконтоDt2_Ссылка
		,СубконтоDt3_Ссылка=a.СубконтоDt3_Ссылка
		,Регистратор=a.Регистратор_Ссылка
		,Содержание
	into #bnfo
	from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
	left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00 
	where cast(a.Период as date) between @dateStart and @repmonth
		and a.Активность=0x01 
		and	(
			-- на баланс
			(b.Код ='62001'and c.Код= '62101')
			--договора
			or
			(b.Код ='62101'and c.Код= '61215')
			--погашения
			or
			(b.Код ='61215'and c.Код= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
			or
			(b.Код ='61215'and c.Код= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
			or
			(b.Код ='61215'and c.Код= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
			or
			(b.Код ='71502'and c.Код= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")
			or
		
			(b.Код ='62101'and c.Код= '60322')--перечисление средств  ФССП (сумма проводок Д62101/ К60322)
			or
			(b.Код ='62101'and c.Код= '60323')--перечисление в конкурсную массу (сумма проводок Д62101/ К60323)
			or 
			(b.Код ='62101'and c.Код= '60312')--перечисление в конкурсную массу (сумма проводок Д62101/ К60312)
			or
			(b.Код ='62101'and c.Код= '71701')--возмещение понесенных расходов (сумма проводок  62101/ К71701)
			or
			--сторно
			(c.Код ='61215'and b.Код= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
			or
			(c.Код ='61215'and b.Код= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
			or
			(c.Код ='61215'and b.Код= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
			or
			(c.Код ='71502'and b.Код= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")
			--- переоценка
			or 
			(b.Код ='62001'and c.Код= '71701') -- переоценка +
			or
			(c.Код ='62001'and b.Код= '71701')--сторно переоценка + 
			or
			(b.Код ='71702'and c.Код= '62001') -- переоценка -
			or
			(c.Код ='71702'and b.Код= '62001') --сторно переоценка -
			-- статус авто
			or
			(b.Код in ('60331','60332')and c.Код= '61209') -- реализация
			or 
			(b.Код ='60415'and c.Код= '61209') -- ОС
			or 
			(b.Код ='62101'and c.Код= '61209') -- отмена
			---НДС
			or
			(b.Код ='61209'and c.Код= '60309') --ндс
			or 
			(c.Код ='61209'and b.Код= '60309') --сторно ндс
			or 
			(b.Код ='61209'and c.Код= '60302')--фнс
			or
			(c.Код ='61209'and b.Код= '60302')--сторно фнс
			--ФР+ ФР-
			or
			(b.Код ='61209'and c.Код= '71702') --ФР+	
			or 
			(b.Код ='61209'and c.Код= '71701')--ФР+
			or
			(b.Код ='71702'and c.Код= '61209')--ФР- 	
			or
			(b.Код ='71701'and c.Код= '61209')--ФР-
			or
			--дополнительные проводки 
			(b.Код ='62101'and c.Код= '48801')--погашение залогом задолженности ОД
			or
			(b.Код ='62101'and c.Код= '48802')--погашение залогом задолженности %
			or
			(b.Код ='62101'and c.Код= '47422')--остаток стоимости а/м после погашения просроченной задолженности при внесудебной реализации
			)
	--- 1.блок определения автомобилей которые поступили на баланс
	drop table if exists #balance
	create table #balance (dat date,nom nvarchar(1000),nomLink binary(16),summ float, vin varchar(20),nameAuto nvarchar(500))
	;with cte_62001 as(
		select
			 dat=a.dat
			,nomlink=a.СубконтоCt1_Ссылка
			,nom=nom.Наименование
			,summ=a.summ
			,rnS=row_number()over(partition by nom.Наименование order by a.dat desc)
			,rnD=row_number()over(partition by nom.Наименование order by a.dat )
		from #bnfo a
		left join stg._1cumfo.Справочник_Номенклатура nom on a.СубконтоCt1_Ссылка=nom.Ссылка and nom.ПометкаУдаления=0x00
		where  (dt ='62001'and kt= '62101')
    			and nom.Наименование is not null
				and a.СубконтоCt1_Ссылка!=0xA2E80050568397CF11ED33F2AB90129E -- Исключаем у Круглик Василий задвоенное наименованование авто в спарвочнике Номенклатуры 
		
		--хард-код для Автомобиль CHEVROLET AVEO, г/в 2008, цвет серебристый (VIN KL1SF69DJB296848) нет проводки о принятии на баланс 
		union all
		select
			 dat=cast('4021-11-17' as date)
			,nomlink=0xA2E10050568397CF11EC4B9204243F85
			,nom='Автомобиль CHEVROLET AVEO, г/в 2008, цвет серебристый (VIN KL1SF69DJB296848)'
			,summ=160000.00
			,rnS=1
			,rnD=1	
		
		------------------
	)

	insert into #balance (dat,nom,nomLink,summ,vin,nameAuto)
		select
		 b.dat
		 ,a.nom
		 ,a.nomlink
		 ,a.summ
		 ,vin=trim(iif(PATINDEX('%[,:]%',substring (trim(concat(char(44),char(32)) from a.nom),
							len(trim(concat(char(44),char(32)) from a.nom))-17,18))=0
							,substring (trim(concat(char(44),char(32)) from a.nom)
							,len(trim(concat(char(44),char(32)) from a.nom))-17,18)
							,substring (trim(concat(char(44),char(32)) from a.nom)
							,len(trim(concat(char(44),char(32)) from a.nom))-9,10)))
		,nameAuto=trim(concat(char(160),char(32)) from substring(trim(a.nom),12,len(trim(a.nom))-11))
		from cte_62001 a
		left join (select * from cte_62001 where rnD=1) b on a.nomlink=b.nomlink
		where a.rnS=1


	--select * from #balance where nom='Автомобиль NISSAN X-TRAIL, 2012, VIN: Z8NTBNT31CS054435'
	------------

	--- 2. Блок определения договоров по автомобилям на балансе
	--declare @repmonth date ='4025-08-31'
	drop table if exists #balanceIn 
	create table #balanceIn (dat date,numdog varchar(200),client nvarchar(500),summ float,nom nvarchar(1000),nomLink binary(16), reg binary(16))

	insert into #balanceIn (dat,numdog,client,summ,nom,nomLink,reg)
		select
			dat=l1.dat
			,numdog=l1.numdog
			,client=l1.client
			,summ=l1.summ
			,nom=l1.nom
			,nomLink=l1.nomlink
			,reg=l1.reg
		from (

				select
				 dat=a.dat
				 ,numdog=dog.Номер
				 ,client=cl.Наименование
				 ,summ=bal.summ
				 ,nom=bal.nom
				 ,nomLink=a.СубконтоDt1_Ссылка
				 ,reg=a.Регистратор
				 ,rn=row_number()over(partition by dog.Номер,a.СубконтоDt1_Ссылка order by a.dat desc)
				from #balance bal
				left join #bnfo a on bal.nomLink=a.СубконтоDt1_Ссылка
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog on a.СубконтоCt2_Ссылка=dog.Ссылка and dog.ПометкаУдаления=0x00
				left join stg._1cumfo.Справочник_Контрагенты cl on a.СубконтоCt1_Ссылка=cl.Ссылка
				where (dt ='62101'and kt= '61215') and a.summ>0
				)l1
		where l1.rn=1
		--хард-код
		union all
			select
			dat=cast('4022-09-30' as date)
			,numdog='22031200297202' 
			,client='МАЛЮКОВА ЛЮБОВЬ ВИКТОРОВНА 20.04.1962'
			,summ=1000000.00
			,nom='Автомобиль MERCEDES-BENZ S 350D 4MATIC, 2009, VIN: WDD2211871A285089'
			,nomLink=0xA2E80050568397CF11ED4301C0A8AA23
			,reg=0xA2E80050568397CF11ED43E926E699B5
		union all
			select
				 dat=cast('4021-11-17' as date)
				,nomdog='1712085900001'
				,client='ГОРОХОВ ДМИТРИЙ ВАДИМОВИЧ 01.08.1976'
				,summ=160650.00
				,nom='Автомобиль CHEVROLET AVEO, г/в 2008, цвет серебристый (VIN KL1SF69DJB296848)'
				,nomlink=0xA2E10050568397CF11EC4B9204243F85
				,reg=0xA2E60050568397CF11ECF922A181FEA8
	
	-----------

	--- 3. Блок определения статуса и задолжности по всем договорам для авто на отчетную дату и на дату погашения залогом
	--declare @repmonth date ='4025-08-31'
	drop table if exists #infoDog 
	create table #infoDog (nomLink binary(16),zalogLink binary(16),clientLink binary(16), numdogStr nvarchar(200),region nvarchar(100),countDog int
							,summAll float,dolgAllPoga float,dolgODPoga float,dolgPRCPoga float,dolgPeniPoga float
							,dolgAllRepdate float,dolgODRepdate float,dolgPRCRepdate float,dolgPeniRepdate float
							,statusDogStr nvarchar(100))
	;with cte_Документ_АЭ_ДоговорЗалога as(
		select
		 l1.*
		from (
			select 
			rn=row_number()over(partition by Займ order by Дата desc)
			,*

			from stg._1cumfo.Документ_АЭ_ДоговорЗалога
			where Проведен=0x01 --Только проведенные
				and ПометкаУдаления=0x00 
			) l1
		where l1.rn=1 
	),
	cte_StatusDogovor as (
		select
		 l1.*
		from (
			select 
			rn=row_number()over(partition by a.Документ_Ссылка order by a.ДатаЗакрыт desc)
			,a.*
			,b.Представление
			from stg._1cUMFO.РегистрСведений_АЭ_СостояниеДоговоров a
			left join stg._1cUMFO.Перечисление_АЭ_СостоянияДоговоров b on a.Состояние=b.Ссылка 
			where a.ДатаЗакрыт<=@repmonth

			) l1
		where l1.rn=1 
	)
	insert into #infoDog (nomLink,zalogLink,clientLink,numdogStr,region,countDog,summAll,dolgAllPoga,dolgODPoga,dolgPRCPoga,dolgPeniPoga,
							dolgAllRepdate,dolgODRepdate,dolgPRCRepdate,dolgPeniRepdate,statusDogStr)
	select
			nomlink=nomlink
			,zalogLink=zalogLink
			,client=clientLink
			,numDogAll=string_agg(numDog,char(44))
			,region=region
			,countDog=count(*)
			,summAll =SUM(summAll)
		
			,dolgAllPoga=sum(dolgAllPoga)
			,dolgODPoga=sum(dolgODPoga)
			,dolgPRCPoga=sum(dolgPRCPoga)
			,dolgPeniPoga=sum(dolgPeniPoga)

			,dolgAllRepdate=sum(dolgAllRepdate)
			,dolgODRepdate=sum(dolgODRepdate)
			,dolgPRCRepdate=sum(dolgPRCRepdate)
			,dolgPeniRepdate=sum(dolgPeniRepdate)

			,statusDogStr=string_agg(statusDog,char(44))

	from ( 
		select
				nomLink=bal.nomLink
				,zalogLink=b1.ОбъектЗалога
				,clientLink=a.Контрагент
				,numDog=bal.numdog
				,region=isnull(isnull(cc.[regionFact],cc.[regionReg]),dopR.nameRegion)
				,summAll =isnull(a.СуммаЗайма,0)
		
				,dolgAllPoga=isnull(z1.ОстатокОДвсего,0)+isnull(z1.ОстатокПроцентовВсего,0)+isnull(z1.ОстатокПени,0)
				,dolgODPoga=isnull(z1.ОстатокОДвсего,0)
				,dolgPRCPoga=isnull(z1.ОстатокПроцентовВсего,0)
				,dolgPeniPoga=isnull(z1.ОстатокПени,0)

				,dolgAllRepdate=isnull(z2.ОстатокОДвсего,0)+isnull(z2.ОстатокПроцентовВсего,0)+isnull(z2.ОстатокПени,0)
				,dolgODRepdate=isnull(z2.ОстатокОДвсего,0)
				,dolgPRCRepdate=isnull(z2.ОстатокПроцентовВсего,0)
				,dolgPeniRepdate=isnull(z2.ОстатокПени,0)

				,statusDog=isnull(st.Представление,'Действует')
		from  #balanceIn bal 
		left join stg._1cumfo.Документ_АЭ_ЗаймПредоставленный  a on bal.numdog=a.НомерДоговора
		left join cte_Документ_АЭ_ДоговорЗалога b on a.ссылка=b.займ
		left join stg._1cumfo.Документ_АЭ_ДоговорЗалога_ОбъектыЗалога b1 on b.ссылка=b1.ссылка
		left join dwh2.finAnalytics.credClients cc on bal.numdog = cc.dogNum
		--задолжность на момент передачи на баланс
		left join stg._1cumfo.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных z1 on bal.numdog=z1.НомерДоговора and  bal.dat=cast(z1.ДатаОтчета as date)
		--задолность на отчетную дату
		left join stg._1cumfo.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных z2 on bal.numdog=z2.НомерДоговора and  cast(z2.ДатаОтчета as date)=@repmonth
		--состояние договра
		left join cte_StatusDogovor st on a.Ссылка=st.Документ_Ссылка
		left join #mainRegion dopR on bal.numdog=dopR.numdog
		where a.Проведен=0x01 
				and a.ДополнительноеСоглашение = 0x00 --Только основные договора без ДС
				--and c.ПометкаУдаления=0x00 
		)l1
	group by nomLink,region,zalogLink,clientLink



	-- 4. блок определение даты погашения залогом и распределения сумм 

	--declare @repmonth date ='4025-08-31'
	---выбираем дату погашения залогом из проводок (дату берем из последней проводки по времени), также из сиутации с одним договором и 2 мя авто определять какие проводки относятся к какому авто
	drop table if exists #dPZ
	select
		datePogaZalog=l1.dat
		,nomlink=l1.nomLink
	into #dPZ
	from (	
			select 
				dat=a.dat
				,nomlink=bal.nomLink
				,a.Содержание
			from #bnfo a
			left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog1 on a.СубконтоCt2_Ссылка=dog1.Ссылка
			left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов vvz on a.СубконтоDt3_Ссылка=vvz.Ссылка
			inner join #balanceIn bal on dog1.Номер=bal.numdog and a.Регистратор=bal.reg
			where 
				(
				(dt ='61215'and kt= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
				or
				(dt ='61215'and kt= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
				or
				--дополнительные проводки
				(dt ='62101'and kt= '48801')--погашение залогом задолженности ОД
				or
				(dt ='62101'and kt= '48802')--погашение залогом задолженности %

				)
			--and bal.numdog='22031200297202'

			)l1
	group by l1.dat,l1.nomlink

	
	drop table if exists #provodki
	create table #provodki (nomlink binary(16),datePogaZalog date,summODPogaZalog float,summPRCPogaZalog float,summPeniPogaZalog float,summSpisRashod float,summSpisZadolODPRC float,summFSSP float,summAK float,summBK float,summVozmRashod float,flag int)
	
	-- распределние сумм формируется в 2 этапа сначало для авто к которым привязано несколько договоров, потом для когда несколько авто привязан к одному договору
	------для договоров на которых одно авто
	;with cte_oneVin_someDog as (
		select 
		 *
		from (select 
				*
				,countVin=count(numdog)over(partition by numdog)
			from #balanceIn	)l1
		where l1.countVin=1

	)

	insert into #provodki (nomlink,datePogaZalog,summODPogaZalog,summPRCPogaZalog,summPeniPogaZalog,summSpisRashod,summSpisZadolODPRC,summFSSP,summAK,summBK,summVozmRashod,flag)
	select 
	 nomlink=l1.nomLink
	 ,datePogaZalog=l1.datePogaZalog
	 ,summODPogaZalog=sum(l1.summODPogaZalog) --[сумма ОД погашенная залогом]
	 ,summPRCPogaZalog=sum(l1.summPRCPogaZalog)-- [сумма % погашенная залогом]
	 ,summPeniPogaZalog=sum(l1.summPeniPogaZalog)-- [сумма пени и госпошлины погашенная залогом]
	 ,summSpisRashod=sum(l1.summSpisRashod) --[сумма списания на расходы]
	 ,summSpisZadolODPRC=sum(l1.summODPogaZalog)+sum(l1.summPRCPogaZalog)	+sum(l1.summPeniPogaZalog)+sum(l1.summSpisRashod)-- [списание задолженности (ОД и %) на авто]
	 ,summFSSP=sum(l1.summFSSP)--[сумма перечисление средств  ФССП]
	 ,summAK=sum(l1.summAK)-- [сумма перечисление в конкурсную массу 60323]
	 ,summBK=sum(l1.summBK) --[сумма перечисление в конкурсную массу 60312]
	 ,summVozmRashod=sum(l1.summVozmRashod)-- [сумма возмещение понесенных расходов]
	 ,flag=0
	from (
		select 
			nomLink=bal.nomLink
			,datePogaZalog=dzp.datePogaZalog
			,summODPogaZalog=case
								when dt ='61215'and kt= '48801' then a.summ
								when kt ='61215'and dt= '48801' then a.summ*-1
								--
								when dt ='62101'and kt= '48801' then a.summ
								else 0 end
			,summPRCPogaZalog=case
								when dt ='61215'and kt= '48802' then a.summ
								when kt ='61215'and dt= '48802' then a.summ*-1
								--
								when dt ='62101'and kt= '48802' then a.summ
								else 0 end
			,summPeniPogaZalog=case
								when dt ='61215'and kt= '60323' then a.summ
								when kt ='61215'and dt= '60323' then a.summ*-1
								else 0 end
			,summSpisRashod=case
								when dt ='71502'and kt= '61215' then a.summ*-1
								when kt ='71502'and dt= '61215' then a.summ
								else 0 end
			,summFSSP=0
			,summAK=0
			,summBK=0
			,summVozmRashod=0
		from #bnfo a
		left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog1 on a.СубконтоCt2_Ссылка=dog1.Ссылка
		left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog2 on a.СубконтоDt2_Ссылка=dog2.Ссылка
		inner join cte_oneVin_someDog bal on isnull(dog1.Номер,dog2.Номер)=bal.numdog 
		left join #dPZ dzp on bal.nomLink=dzp.nomLink
		where
			(
			(dt ='61215'and kt= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
			or
			(dt ='61215'and kt= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
			or
			(dt ='61215'and kt= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
			or
			(dt ='71502'and kt= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")
			or
			(kt ='61215'and dt= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
			or
			(kt ='61215'and dt= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
			or
			(kt ='61215'and dt= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
			or
			(kt ='71502'and dt= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")
			--дополнительные проводки
			or
			(dt ='62101'and kt= '48801' and upper(a.Содержание)=upper('Себестоимость по основному долгу (БУ, НУ)'))--погашение залогом задолженности ОД	сумма ОД погашенная залогом
			or
			(dt ='62101'and kt= '48802'and upper(a.Содержание)=upper('Себестоимость по процентам (БУ, НУ)'))--погашение залогом задолженности %	сумма % погашенная залогом
			)
	
		union all
		select 
			nomLink=bal.nomLink
			,datePogaZalog=dzp.datePogaZalog
			,summODPogaZalog=0
			,summPRCPogaZalog=0
			,summPeniPogaZalog=0
			,summSpisRashod=0
			,summFSSP=iif(dt ='62101'and kt= '60322',a.summ,0)
			,summAK=iif(dt ='62101'and kt= '60323',a.summ,0)
			,summBK=iif(dt ='62101'and kt= '60312',a.summ,0)
			,summVozmRashod=iif(dt ='62101'and kt= '71701',a.summ,0)
		from #bnfo a
		inner join (select distinct nomlink from cte_oneVin_someDog) bal on a.СубконтоDt1_Ссылка=bal.nomLink
		left join #dPZ dzp on bal.nomLink=dzp.nomLink
		where 
			(
			(dt ='62101'and kt= '60322')--перечисление средств  ФССП (сумма проводок Д62101/ К60322)
			or
			(dt ='62101'and kt= '60323')--перечисление в конкурсную массу (сумма проводок Д62101/ К60323)
			or 
			(dt ='62101'and kt= '60312')--перечисление в конкурсную массу (сумма проводок Д62101/ К60312)
			or
			(dt ='62101'and kt= '71701')--возмещение понесенных расходов (сумма проводок  62101/ К71701)
			)
		) l1
	group by
		 l1.nomLink
		 ,l1.datePogaZalog
	--хард-код для Автомобиль CHEVROLET AVEO, г/в 2008, цвет серебристый (VIN KL1SF69DJB296848) проводки не подходят под ТЗ
	union all
	select 
	 nomlink=0xA2E10050568397CF11EC4B9204243F85
	 ,datePogaZalog=cast('4021-11-17' as date)
	 ,summODPogaZalog=92523.46
	 ,summPRCPogaZalog=68126.54
	 ,summPeniPogaZalog=0
	 ,summSpisRashod=0
	 ,summSpisZadolODPRC=160650.00
	 ,summFSSP=0
	 ,summAK=0
	 ,summBK=0
	 ,summVozmRashod=0
	 ,flag=0


	------для договоров на которых несколько авто
	;with cte_someVin_oneDog as (
		select 
		 *
		from (select 
				*
				,countVin=count(numdog)over(partition by numdog)
			from #balanceIn	)l1
		where l1.countVin>1

	)

	insert into #provodki (nomlink,datePogaZalog,summODPogaZalog,summPRCPogaZalog,summPeniPogaZalog,summSpisRashod,summSpisZadolODPRC,summFSSP,summAK,summBK,summVozmRashod,flag)
	select 
	 nomlink=l1.nomLink
	 ,datePogaZalog=l1.datePogaZalog
	 ,summODPogaZalog=sum(l1.summODPogaZalog) --[сумма ОД погашенная залогом]
	 ,summPRCPogaZalog=sum(l1.summPRCPogaZalog)-- [сумма % погашенная залогом]
	 ,summPeniPogaZalog=sum(l1.summPeniPogaZalog)-- [сумма пени и госпошлины погашенная залогом]
	 ,summSpisRashod=sum(l1.summSpisRashod) --[сумма списания на расходы]
	 ,summSpisZadolODPRC=sum(l1.summODPogaZalog)+sum(l1.summPRCPogaZalog)	+sum(l1.summPeniPogaZalog)+sum(l1.summSpisRashod)-- [списание задолженности (ОД и %) на авто]
	 ,summFSSP=sum(l1.summFSSP)--[сумма перечисление средств  ФССП]
	 ,summAK=sum(l1.summAK)-- [сумма перечисление в конкурсную массу 60323]
	 ,summBK=sum(l1.summBK) --[сумма перечисление в конкурсную массу 60312]
	 ,summVozmRashod=sum(l1.summVozmRashod)-- [сумма возмещение понесенных расходов]
	 ,flag=1
	from (
		 select
	  		nomLink=a.nomLink
			,datePogaZalog=dzp.datePogaZalog
			,summODPogaZalog=a.summODPogaZalog
			,summPRCPogaZalog=a.summPRCPogaZalog
			,summPeniPogaZalog=a.summPeniPogaZalog
			,summSpisRashod=a.summSpisRashod
			,summFSSP=a.summFSSP
			,summAK=a.summAK
			,summBK=a.summAK
			,summVozmRashod=a.summVozmRashod
		 from(
				select 
					nomLink=bal.nomLink
					,summODPogaZalog=case
										when dt ='61215'and kt= '48801' then a.summ
										when kt ='61215'and dt= '48801' then a.summ*-1
										--
										when dt ='62101'and kt= '48801' then a.summ
										else 0 end
					,summPRCPogaZalog=case
										when dt ='61215'and kt= '48802' then a.summ
										when kt ='61215'and dt= '48802' then a.summ*-1
										--
										when dt ='62101'and kt= '48802' then a.summ
										else 0 end
					,summPeniPogaZalog=case
										when dt ='61215'and kt= '60323' then a.summ
										when kt ='61215'and dt= '60323' then a.summ*-1
										else 0 end
					,summSpisRashod=case
										when dt ='71502'and kt= '61215' then a.summ*-1
										when kt ='71502'and dt= '61215' then a.summ
										else 0 end
					,summFSSP=0
					,summAK=0
					,summBK=0
					,summVozmRashod=0
				from #bnfo a
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog1 on a.СубконтоCt2_Ссылка=dog1.Ссылка
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов dog2 on a.СубконтоDt2_Ссылка=dog2.Ссылка
				inner join cte_someVin_oneDog bal on isnull(dog1.Номер,dog2.Номер)=bal.numdog and a.Регистратор=bal.reg
				
				where
					(
					(dt ='61215'and kt= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
					or
					(dt ='61215'and kt= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
					or
					(dt ='61215'and kt= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
					or
					(dt ='71502'and kt= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")
					or
					(kt ='61215'and dt= '48801')--погашение залогом задолженности ОД	сумма ОД погашенная залогом
					or
					(kt ='61215'and dt= '48802')--погашение залогом задолженности %	сумма % погашенная залогом
					or
					(kt ='61215'and dt= '60323')--погашение залогом прочей задолженности	сумма пени и госпошлины погашенная залогом 
					or
					(kt ='71502'and dt= '61215')--списание задолженности на расходы	сумма списания (отражается со знаком "минус")

					--дополнительные проводки
					or
					(dt ='62101'and kt= '48801' and upper(a.Содержание)=upper('Себестоимость по основному долгу (БУ, НУ)'))--погашение залогом задолженности ОД	сумма ОД погашенная залогом
					or
					(dt ='62101'and kt= '48802'and upper(a.Содержание)=upper('Себестоимость по процентам (БУ, НУ)'))--погашение залогом задолженности %	сумма % погашенная залогом
					)
			) a 
		left join #dPZ dzp on a.nomLink=dzp.nomLink
		union all
			select 
				nomLink=bal.nomLink
				,datePogaZalog=dzp.datePogaZalog
				,summODPogaZalog=0
				,summPRCPogaZalog=0
				,summPeniPogaZalog=0
				,summSpisRashod=0
				,summFSSP=iif(dt ='62101'and kt= '60322',a.summ,0)
				,summAK=iif(dt ='62101'and kt= '60323',a.summ,0)
				,summBK=iif(dt ='62101'and kt= '60312',a.summ,0)
				,summVozmRashod=iif(dt ='62101'and kt= '71701',a.summ,0)
			from #bnfo a
			inner join (select distinct nomlink from cte_someVin_oneDog) bal on a.СубконтоDt1_Ссылка=bal.nomLink
			left join #dPZ dzp on bal.nomLink=dzp.nomLink
			where 
				(
				(dt ='62101'and kt= '60322')--перечисление средств  ФССП (сумма проводок Д62101/ К60322)
				or
				(dt ='62101'and kt= '60323')--перечисление в конкурсную массу (сумма проводок Д62101/ К60323)
				or 
				(dt ='62101'and kt= '60312')--перечисление в конкурсную массу (сумма проводок Д62101/ К60312)
				or
				(dt ='62101'and kt= '71701')--возмещение понесенных расходов (сумма проводок  62101/ К71701)
				)
		) l1
	group by
		 l1.nomLink
		 ,l1.datePogaZalog

	--- 5. блок определение даты выхода на дефолт 90+
	--declare @repmonth date ='4025-08-31'

		drop table if exists #stg;
		--Надо ограничивать списком договоров - иначе очень долго работает
		select a.external_id, a.d, a.dpd
		into #stg
		from dwh2.dbo.dm_CMRStatBalance as a
		inner join #balanceIn bal on a.external_id=bal.numdog
		-- создаем индекс для усокрения
		create index ix_stg_external_id_d ON #stg (external_id, d)
		-- тут определяем на каждую отчётную дату кредиты которые уже в дефолте
		drop table if exists #rep_date_dpd90;
		select 	* 
		into #rep_date_dpd90
		from #stg as a
		where a.d = eomonth(a.d) and a.dpd >90
		-- ищем последнюю дата входа в непрерывную просрочку по этим кредитам в дефолте
		drop table if exists #dpd_start;
		select 	a.d, a.external_id, max(b.d) as dlq_start
		into #dpd_start
		from #rep_date_dpd90 as a
		inner join #stg as b on a.external_id = b.external_id and b.d < a.d and b.dpd = 0
		group by a.d, a.external_id
		-- ищем первую точку входа в 90+ (потому что вдруг человек долго барахтался и переходил несколько раз через 90 дней)
		-- и еще тут легко устраняется вероятность ошибки если 91 по кредиту пропущен изза качества данных ( поэтому я не ставлю b.dpd=90)
		drop table if exists #tableDefolt
		select
		 *
		into #tableDefolt
		from(
			select
			  l2.nomLink
			 ,l2.dat
			from(
				select  
					l1.dat
					,bal.nomLink
					,rn=row_number()over(partition by bal.nomLink order by l1.dat)
				from (
						select a.external_id dogNum, eomonth(min(b.d)) dat
						from #dpd_start as a
						inner join #stg as b on a.external_id = b.external_id and b.d < a.d and b.dpd >90
						group by a.external_id 
					) l1
				left join  #balanceIn bal on l1.dogNum=bal.numdog)l2
			where l2.rn=1
			)l3

	--------
	--- 6. блок Переоценки авто
	--declare @repmonth date ='4025-08-31'
		--таблица всех переоценок для свода
		drop table if exists #changePriceAll
		create	table #changePriceAll (nomlink binary(16),dat date,summ float,st varchar(6),rn int)
		insert into #changePriceAll (nomlink ,dat,summ,st,rn)	
		select
			  nomlink=l1.nomlink
			 ,dat=l1.dat
			 ,summ=l1.summ
			 ,st=l1.st
			 ,rn=row_number()over(partition by l1.nomlink,dt order by l1.dat desc)
		from (
		 	select 
				dt=a.dt
				,kt=a.kt
				,nomlink=iif(dt='62001',a.СубконтоDt1_Ссылка,a.СубконтоCt1_Ссылка)
				,dat=a.dat
				,summ=iif(dt='62001',a.summ,a.summ*-1)
				,st=iif(dt='62001','plus','minus')
			from #bnfo a
			left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы vd1 on a.СубконтоDt1_Ссылка=vd1.Ссылка and vd1.ПометкаУдаления=0x00
			left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы vd2 on a.СубконтоCt1_Ссылка=vd2.Ссылка and vd2.ПометкаУдаления=0x00
			where (a.СубконтоDt1_Ссылка is not null or a.СубконтоCt1_Ссылка is not null)
			and ((dt ='62001'and kt= '71701') -- переоценка +
				or
				(dt ='71702'and kt= '62001'))-- переоценка -
				
			and upper(isnull(vd1.Наименование,vd2.Наименование)) in (upper('Доходы от переоценки ДАПП (сч. 71701 символ 52602)'),upper('Расходы по переоценке ДАПП (сч. 71702 символ 53602)'))
					
			)l1
		inner join #balance bal on l1.nomlink=bal.nomLink
		union all
		select
			nomlink=l1.nomlink
			,dat=l1.dat
			,summ=l1.summ
			,st=l1.st
			,rn=0
		from (
			select 
				nomlink=iif(dt='71701',a.СубконтоCt1_Ссылка,a.СубконтоDt1_Ссылка)
				,dat=a.dat
				,summ=iif(dt='71701',a.summ*-1,a.summ)
				,st=iif(dt='71701','plus','minus')
			from #bnfo a
			where (a.СубконтоDt1_Ссылка is not null or a.СубконтоCt1_Ссылка is not null)
				and ((dt= '71701' and kt ='62001') --сторно переоценка +
					or
					(dt= '62001' and kt ='71702'))--сторно переоценка -
					
			)l1
		inner join #balance bal on l1.nomlink=bal.nomLink
		--------------------хард код 
		--Основание - это Документ: Реализация (акт, накладная, УПД) 00БП-001568 от 13.02.2023 23:59:59
				--Переоценка: Соглашение о расторжении сделки по передаче нереализованного имущества должника Кругликова Василия Александровича
				--Дт 71702 (Расходы по переоценке ДАПП (сч. 71702 символ 53602) Кт 61209 Автомобиль NISSAN X-TRAIL, 2012, VIN Z8NTBNT31CS054435)
		insert into #changePriceAll (nomlink ,dat,summ,st,rn)
			values(0xA3010050568397CF11EEFD5905B46E04,'4023-02-13',-8009.78,'minus',2)
		-- Новиков MAZDA 3, 2005, VIN: JMZBK14Z251250645 
		insert into #changePriceAll (nomlink ,dat,summ,st,rn)
			values(0xA2FB0050568397CF11EE749499886A37,'4023-12-11',-2050,'minus',2)
	
		---------------------------
		drop table if exists #changePrice
		create	table #changePrice (nomlink binary(16),dat date,summ float,st varchar(6))
		insert into #changePrice (nomlink ,dat,summ,st)
		select 
			nomLink=l1.nomlink
			,dat=l1.dat
			,summ=l1.summ
			,st=l1.st
		from (
			select
				nomLink
				,dat
				,summ=sum(summ)over(partition by nomlink,st)
				,st
				,rn
			from #changePriceAll) l1

			where l1.rn=1
	----------
	--- 7. Блок определения статуса авто, суммы продажи авто, НДС и выполоты ФНС
	--declare @repmonth date ='4025-08-31'
	drop table if exists #statusAuto
	create table #statusAuto (nomlink binary(16),dat date,summ float ,status nvarchar(30),summNDS float,summFNS float)
	;with cte_statusAuto as(
	
		select 
			l1.nomlink
			,l1.dat
			,l1.summ
			,l1.status
			,l1.nom

		from (
		select
			nomlink=a.СубконтоCt1_Ссылка
			,dat=case 
					when dt in ('60331','60332')and kt= '61209' then a.dat
					when dt ='60415'and kt= '61209' then a.dat
					else null end
			,dt=dt
			,kt=kt
			,summ=iif(dt in ('60331','60332')and kt= '61209',a.summ,0)
			,nom=nom.Наименование
			,status= case
						when dt in ('60331','60332')and kt= '61209' then 'реализован'
						when dt ='60415'and kt= '61209' then 'ОС'
						when dt ='62101'and kt= '61209' then 'отмена'
						else null end
			,rn=row_number()over(partition by a.СубконтоCt1_Ссылка order by a.dat desc)
			from #bnfo a
			left join stg._1cumfo.Справочник_Номенклатура nom on a.СубконтоCt1_Ссылка=nom.Ссылка and nom.ПометкаУдаления=0x00
			where (СубконтоDt1_Ссылка is not null or СубконтоCt1_Ссылка is not null) 
			and ( (dt in ('60331','60332')and kt= '61209') -- реализация
					or (dt ='60415'and kt= '61209') -- ОС
					or (dt ='62101'and kt= '61209') -- отмена
					)
			
			)l1
		where l1.rn=iif(l1.nomlink in (0xA2FC0050568397CF11EE8AA331963532,0xA2E10050568397CF11EC38B00253B1DA),2,1) 
			-- LIFAN 214801, 2010, VIN: X9W214801A0004962 в отношении этого авто выбрана дата первой продажи(нарушен метод выбора даты -метод из ТЗ не работает)
			-- Автомобиль МАЗ 5440А5-330-031, 2011 г.в.,  (VIN) Y3M5440A5B0001068 в отношении этого авто выбрана дата первой продажи(нарушен метод выбора даты -метод из ТЗ не работает)
	)
	insert into #statusAuto(nomlink,dat,summ,status,summNDS,summFNS)
	select
	 st.nomlink 		
	 ,st.dat
	 ,st.summ
	 ,st.status
	 --,st.nom
	 ,a.summNDS
	 ,a.summFNS

	from cte_statusAuto st
	left join 
		(
			select 
			 nomlink=l1.nomlink
			 ,summNDS=sum(l1.summNDS)
			 ,summFNS=sum(l1.summFNS)
			from (
				select 
					nomlink=iif(dt='61209',a.СубконтоDt1_Ссылка,a.СубконтоCt1_Ссылка)
					,summNDS=iif(dt ='61209'and kt= '60309',a.summ,iif(dt ='60309',a.summ*-1,0))
					,summFNS=iif(dt ='61209'and kt= '60302',a.summ,iif(dt ='60302',a.summ*-1,0))
				from #bnfo a 
				where  ((dt ='61209'and kt= '60309') --ндс
							or 
							--сторно ндс
							(kt ='61209'and dt= '60309'))
						or 
						((dt ='61209'and kt= '60302')--фнс
							or
							--сторно фнс
							(kt ='61209'and dt= '60302'))
				 )l1
			 group by l1.nomlink
		 ) a on st.nomlink=a.nomlink 
	----------

	--- 8. Блок определния суммы и даты ФР+ и ФР-
	--declare @repmonth date ='4025-08-31'
	drop table if exists #frAll
	create	table #frAll (dt varchar(5),kt varchar(5),nomlink binary(16),dat date,summ float,st varchar(6),rn int,rnS int)
	insert into #frAll(dt ,kt,nomlink ,dat,summ,st,rn,rnS)		
	select
		dt=l1.dt
		,kt=l1.kt
		,nomlink=l1.nomlink
		,dat=l1.dat
		,summ=l1.summ
		,st=l1.st
		,rn=row_number()over(partition by l1.nomlink,l1.st order by l1.dat desc)
		,rnS=0

	from (
			select 
				dt=a.dt
				,kt=a.kt
				,nomlink=a.СубконтоDt1_Ссылка
				,dat=a.dat
				,summ=a.summ
				,st=iif(kt ='71702','minus','plus')
			from #bnfo a
			left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы b on a.СубконтоCt1_Ссылка=b.Ссылка
			where (a.СубконтоDt1_Ссылка is not null or a.СубконтоCt1_Ссылка is not null)
				and ((dt ='61209'and kt= '71702') -- ФР -
						or
						(dt ='61209'and kt= '71701')) -- ФР +
				and upper(b.Наименование)=upper('Реализация залогов (ДАПП) - доходы (убытки) (52601,53601; сч.71701,71702)')
		)l1
	inner join (select distinct nomlink from #balanceIn ) bal on l1.nomlink=bal.nomLink	--ограничиваем выборку авто только с проводкой 61215
	union all
	select
		dt=l1.dt
		,kt=l1.kt
		,nomlink=l1.nomlink
		,dat=l1.dat
		,summ=l1.summ
		,st=l1.st
		,rn=0
		,rnS=row_number()over(partition by l1.nomlink,l1.st order by l1.dat asc)
	from (
			select 
				dt=a.dt
			   ,kt=a.kt
	           ,nomlink=a.СубконтоCt1_Ссылка
			   ,dat=a.dat
			   ,summ=a.summ*-1
               ,st=iif(dt ='71702','minus','plus')
			from #bnfo a
			left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы b on a.СубконтоDt1_Ссылка=b.Ссылка
			where (a.СубконтоDt1_Ссылка is not null or a.СубконтоCt1_Ссылка is not null)
				and ((dt= '71702'and kt ='61209') --сторно ФР-
						or 
						(dt= '71701'and kt ='61209')) --сторно ФР+
				and upper(b.Наименование)=upper('Реализация залогов (ДАПП) - доходы (убытки) (52601,53601; сч.71701,71702)')

		)l1
	inner join (select distinct nomlink from #balanceIn ) bal on l1.nomlink=bal.nomLink	--ограничиваем выборку авто только с проводкой 61215
	
	-------------хардкод
	-- Новиков MAZDA 3, 2005, VIN: JMZBK14Z251250645 
	insert into #frAll (dt ,kt,nomlink ,dat,summ,st,rn,rnS)		
		values ('71702','61209',0xA2FB0050568397CF11EE749499886A37,'4023-12-11',2050,'minus',0,3)
	---------------
	--таблица ФР только для массива 
	drop table if exists #fr
	create	table #fr (nomlink binary(16),dat date,summ float,st varchar(6))
	insert into #fr (nomlink ,dat,summ,st)
		select 
			nomLink=l1.nomlink
			,dat=iif(l1.summ!=0,l1.dat,null)
			,summ=l1.summ
			,st=l1.st
		from (
			
					select
						nomLink
						,dat
						,summ=sum(isnull(summ,0))over(partition by nomlink,st)
						,st
						,rn=row_number()over(partition by nomlink,st order by dat asc)
					from #frAll
					
			) l1
				where l1.rn=1

	------------------------------------------
	--хард-код
	--мемориальные ордера (для корректировочных проводок которые были сделаны по авто после продажи 60309-71702)
	drop table if exists #order
	create table #order (dateOrder date,summ float,nomlink binary(16))
		insert into #order (dateOrder,summ,nomlink)
		select
			dateorder='2025-12-31'
			,summ=4000
			,nomLink
		from #balance
		where vin='JMBSRCS3A7U023526'
	-----------------------------------------
	----------
	---9. Блок дополнительного столбца по новой проводке 62101 47422 
	--остаток стоимости а/м после погашения просроченной задолженности при внесудебной реализации
	drop table if exists #st29_1
	create table #st29_1 (nomLink binary(16),summ float)
	insert into #st29_1 (nomlink,summ)
		select
			nomlink=a.СубконтоDt1_Ссылка
			,summ=a.summ
		from #bnfo a
		left join stg._1cumfo.Справочник_Номенклатура nom on a.СубконтоDt1_Ссылка=nom.Ссылка and nom.ПометкаУдаления=0x00
		where  (dt ='62101'and kt= '47422')
	
	--- 10. Блок сборки всех блоков в единую таблицу, внутри блока определям также статус банкротства
	--declare @repmonth date ='4025-08-31'


	;with cte_Bankrot as(
			select
				dat=l2.Дата
				,clientLink=l2.clientLink
			from (
				select 
					l1.*
				from (
					select 
				
						Контрагент= b.Наименование
						,clientLink=a.Контрагент
						,Дата=cast(a.Дата as date)
						,rn=row_number()over(partition by a.Контрагент order by a.Дата)
						,Исключение=iif(c.client is null,0,1)
					from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
					left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
					left join dwh2.finAnalytics.SPR_notBunkrupt c on b.Наименование = c.client 
													and dateadd(year,-2000,@repmonth)between c.nonBunkruptStartDate and isnull(c.nonBunkruptEndDate,getdate())
					where cast(a.Дата as date)<=@repmonth
					and a.ПометкаУдаления=0x00
					and a.Проведен=0x01)l1
				where l1.rn=1)l2
			where l2.Исключение=0
	)

	insert into dwh2.finAnalytics.DAPP
			(VIN,nameAuto,client,region,countDog,numDog,summAll,dolgAllPoga,dolgODPoga,dolgPRCPoga,dolgPeniPoga,statusDog
			,dolgAllRepdate,dolgODRepdate,dolgPRCRepdate,dolgPeniRepdate,isBankrot,isBankrotDate,isDefoltDate,datePogaZalog,summODPogaZalog,summPRCPogaZalog
			,summPeniPogaZalog,summSpisRashod,summSpisZadolODPRC,summFSSP,summAK,summBK,summVozmRashod,ostPriceItogAfterZadol
			,dateBalance,priceBalance,datePriceChangePlus,changePricePlus,datePriceChangeMinus,changePriceMinus
			,statusAuto,dateSale,priceItog,priceSale,NDS,FNS,dateFRMinus,frMinus,dateFRPlus,frPlus
			,itogFR,periodSale,ndsPRC,moneyNDSManager,minusPRCZalog,minusODZalog,periodDefoltZalog,periodDefoltSale,ratioPriceSalePriceBalanceIn,ratioPriceSalePriceBalanceOut
			,checkPriceBalance
			 ,dateOrderFRMinus,sumOrderFRMinus)
	select 
			VIN=iif (pr.flag=1 or inf.zalogLink=0xA2CF00155D4D084E11E909A93D4010B1,bal.vin,c.ТранспортноеСредствоНомерVin)
			,[машина]=iif (pr.flag=1 or inf.zalogLink=0xA2CF00155D4D084E11E909A93D4010B1,bal.nameAuto,c.Наименование)
			,[Клиент]=cl.Наименование
			,[Регион выдачи]=inf.region
			,[Кол-во договоров займа] =inf.countDog
			,[Номер договора]=inf.numdogStr
		
			,[Сумма займов по всем договорам] =inf.summAll
			,[задолженность на дату погашения залогом (Всего)]=inf.dolgAllPoga
			,[задолженность на дату погашения залогом (ОД)]=inf.dolgODPoga
			,[задолженность на дату погашения залогом (%)]=inf.dolgPRCPoga
			,[задолженность на дату погашения залогом (прочее)]=inf.dolgPeniPoga
		
			,[Состояние договора]=inf.statusDogStr
		
			,[задолженность на отчетную дату (Всего)]=inf.dolgAllRepdate
			,[задолженность на отчетную дату (ОД)]=inf.dolgODRepdate
			,[задолженность на отчетную дату (%)]=inf.dolgPRCRepdate
			,[задолженность на отчетную дату (прочее)]=inf.dolgPeniRepdate
			---
			,[наличие банкротства на отчетную дату]=iif(bnk.clientLink is not null,'банкрот','небанкрот')
			,[дата учета банкротства]=dateadd(year,-2000,bnk.dat)
			---
			,[дата выхода в дефолт (90+)]=df.dat
			-- 
	
			,[дата погашения залогом]=dateadd(year,-2000,pr.datePogaZalog)
			,[сумма ОД погашенная залогом]=isnull(pr.summODPogaZalog,0)
			,[сумма % погашенная залогом]=isnull(pr.summPRCPogaZalog,0)
			,[сумма пени и госпошлины погашенная залогом]=isnull(pr.summPeniPogaZalog,0)
			,[сумма списания на расходы]=isnull(pr.summSpisRashod,0)
			,[списание задолженности (ОД и %) на авто]=isnull(pr.summSpisZadolODPRC,0)
			,[сумма перечисление средств  ФССП]=isnull(pr.summFSSP,0)
			,[сумма перечисление в конкурсную массу 60323]=isnull(pr.summAK,0)
			,[сумма перечисление в конкурсную массу 60312]=isnull(pr.summBK,0)
			,[сумма возмещение понесенных расходов]=isnull(pr.summVozmRashod,0)
			,[остаток стоимости после погашения задолж]=isnull(st29.summ,0)
			--
			,[Дата принятия на баланс]=dateadd(year,-2000,bal.dat)
			,[Цена принятия на баланс]=isnull(bal.summ,0)

			--
			,[дата переоценки +]=dateadd(year,-2000,chp1.dat)
			,[переоценка +]=isnull(chp1.summ,0)
			,[дата переоценки -]=dateadd(year,-2000,chp2.dat)
			,[переоценка -]=isnull(chp2.summ,0)
		
			--
			,[статус авто]=iif(stauto.status is null,'нереализован',stauto.status)
			,[дата продажи]=dateadd(year,-2000,stauto.dat)
			,[балансовая стоимость с учетом переценки]=isnull(bal.summ,0)+isnull(chp1.summ,0)+isnull(chp2.summ,0)
			,[цена продажи (расчеты с покупателем)]=isnull(stauto.summ,0)
			,[НДС]=isnull(stauto.summNDS,0)-isnull(ord.summ,0)
			,[Взнос в ФНС]=isnull(stauto.summFNS,0)
			--
			,[дата формирования ФР -]=dateadd(year,-2000,frM.dat)
			,[ФР -]=isnull(frM.summ,0)+isnull(ord.summ,0)
			,[дата формирования ФР +]=dateadd(year,-2000,frP.dat)
			,[ФР -]=isnull(frP.summ,0)
			--
			,[ИТОГО ФР]=isnull(frM.summ,0)+isnull(frP.summ,0)+isnull(ord.summ,0)
			,[срок реализации]=isnull(iif(bal.dat=stauto.dat
										,1
										,datediff(day,dateadd(year,-2000,bal.dat),dateadd(year,-2000,stauto.dat))
										)
									,0)+1
			--показатель расчитывается если авто реализован
			,[ставка НДС]=iif(iif(stauto.status is null,'нереализован',stauto.status)='реализован',
								((isnull(stauto.summNDS,0)-isnull(ord.summ,0))-isnull(stauto.summFNS,0))/isnull(stauto.summ,0)
							,0)

			,[деньги - НДС - расходы на управляющего]=isnull(stauto.summ,0)-(isnull(stauto.summNDS,0)-isnull(ord.summ,0))-isnull(pr.summFSSP,0)-isnull(pr.summAK,0)-isnull(pr.summBK,0)
			,[минус % погашенные залогом]=isnull(stauto.summ,0)-(isnull(stauto.summNDS,0)-isnull(ord.summ,0))-isnull(pr.summFSSP,0)-isnull(pr.summAK,0)-isnull(pr.summBK,0)-isnull(pr.summPRCPogaZalog,0)-isnull(pr.summPeniPogaZalog,0)
			,[минус ОД погашенная залогом]=isnull(stauto.summ,0)-isnull(stauto.summNDS,0)-isnull(pr.summFSSP,0)-isnull(pr.summAK,0)-isnull(pr.summBK,0)-isnull(pr.summPRCPogaZalog,0)-isnull(pr.summPeniPogaZalog,0)
											-isnull(pr.summODPogaZalog,0)
			,[срок между выходом в дефолт и погашения ОД залогом]=isnull(datediff(day,df.dat,dateadd(year,-2000,pr.datePogaZalog)),0)
			,[срок между выходом в дефолт и реализацией залога]=isnull(datediff(day,df.dat,dateadd(year,-2000,stauto.dat)),0)

			,[соотношение цены реализации без НДС к цене принятия на баланс]=iif(isnull(bal.summ,0)>0,
												(isnull(stauto.summ,0)-(isnull(stauto.summNDS,0)-isnull(ord.summ,0)))
												/isnull(bal.summ,0)
											,0)

			,[соотношение цены реализации без НДС к балансовой стоимости на момент реализации]=	iif(isnull(bal.summ,0)>0,
												(isnull(stauto.summ,0)-(isnull(stauto.summNDS,0)-isnull(ord.summ,0)))
												/(isnull(bal.summ,0)+isnull(chp1.summ,0)+isnull(chp2.summ,0))
											,0)
			,[Проверка цены принятия на баланс]=isnull(bal.summ,0)-isnull(pr.summSpisZadolODPRC,0)-isnull(pr.summFSSP,0)-isnull(pr.summAK,0)-isnull(pr.summBK,0)-isnull(pr.summVozmRashod,0)
												-isnull(st29.summ,0)
			 ,dateOrderFRMinus=ord.dateOrder
			 ,sumOrderFRMinus=ord.summ
		from  #balance bal 
		--все договора регион статусы задолжности
		left join #infoDog inf on bal.nomLink=inf.nomLink
		left join stg._1cUMFO.Справочник_Контрагенты cl on inf.clientLink=cl.Ссылка
		left join stg._1cumfo.Справочник_АЭ_ОбъектыЗалога c on inf.zalogLink=c.ссылка 
		--банкроты
		left join cte_Bankrot bnk on inf.clientLink=bnk.clientLink
		--дефолт
		left join #tableDefolt df on bal.nomLink=df.nomLink
		--суммы по проводкам
		left join #provodki pr on bal.nomLink=pr.nomLink
		--переоценка
		left join (select nomlink,dat,summ from #changePrice where st='plus') chp1 on bal.nomLink=chp1.nomlink
		left join (select nomlink,dat,summ from #changePrice where st='minus') chp2 on bal.nomLink=chp2.nomlink
		--статус авто
		left join #statusAuto stauto on bal.nomLink=stauto.nomLink
		--ФР
		left join (select nomlink,dat,summ from #fr where st='minus') frM on bal.nomLink=frM.nomlink
		left join (select nomlink,dat,summ from #fr where st='plus') frP on bal.nomLink=frP.nomlink
		--доп столбец 29.1
		left join #st29_1 st29 on bal.nomLink=st29.nomLink
		--------мемориальный ордер
		left join #order ord on bal.nomLink=ord.nomlink

		where  c.ПометкаУдаления=0x00 





	
  commit tran
	-- костыль КРУГЛИКОВ ВАСИЛИЙ АЛЕКСАНДРОВИЧ 09.05.1979 Z8NTBNT31CS054435
	  update dwh2.finAnalytics.DAPP
			set summAK=358066.64
				,dateBalance='2024-04-17'
				,changePricePlus=132009.78+8009.78
				--Основание - это Документ: Реализация (акт, накладная, УПД) 00БП-001568 от 13.02.2023 23:59:59
				--Переоценка: Соглашение о расторжении сделки по передаче нереализованного имущества должника Кругликова Василия Александровича
				--Дт 71702 (Расходы по переоценке ДАПП (сч. 71702 символ 53602) Кт 61209 Автомобиль NISSAN X-TRAIL, 2012, VIN Z8NTBNT31CS054435)
				,datePriceChangeMinus='2023-02-13'
				,changePriceMinus=-8009.78
				,periodSale=66
				,moneyNDSManager=209933.36
				,minusPRCZalog=81761.96
				,minusODZalog=-139990.22
				,ratioPriceSalePriceBalanceIn=0.8023
				,ratioPriceSalePriceBalanceOut=0.6698
				,checkPriceBalance=0

		where VIN='Z8NTBNT31CS054435'
	-- костыль для НОВИКОВ ЮРИЙ АЛЕКСАНДРОВИЧ 07.04.1983 JMZBK14Z251250645
	update dwh2.finAnalytics.DAPP
		set datePriceChangeMinus='2023-12-11'
			,changePriceMinus=-2050
			,dateFRMinus='2024-02-02'
			--,frMinus=-113666.66
			--,itogFR=-113666.66+frPlus
			,priceBalance=164666.25
			,priceItog=209666.66
	where VIN='JMZBK14Z251250645'

		

	declare @rowCount int =(select count(*) from dwh2.finAnalytics.DAPP) 
	declare @checkSum int =(select sum(round(checkPriceBalance,0,1)) from dwh2.finAnalytics.DAPP) 
	
	set @subject=concat(iif (@checkSum=0,'OK! ','Внимание! '),@subjectHeader) 
	set @message=concat('Данные обновлены',char(10),'Кол-во записей в массиве ',@rowCount,char(10),'Контрольная сумма ',@checkSum,char(10))
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1,101'

	exec dwh2.finAnalytics.addDAPP_svod
	exec dwh2.finAnalytics.addDAPP_region

	--делаем запись реестре отчетов
	---/Определение наличия данных/
    declare @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(dateBalance) from [dwh2].[finAnalytics].[DAPP]) as varchar)
    ---/Фиксация времени расчета/
    update dwh2.[finAnalytics].[reportReglament]
    set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
    where [reportUID] in (54)
----
 end try 

 begin catch
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


