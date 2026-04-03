/* Процедура обновляет данные в таблице реестр Цессии (ReestrCession) 
	по возвратным договорам и измением цен договоров цессии 
1. Первый этап - создается временная таблица Tmp в которую выбираютя все проводки по шаблону:
	ДТ 48801 КТ 61217 - это Возврат
	ДТ 48802 КТ 61217 - это Возврат
	ДТ 71502 КТ 61217 - это Изменение цены
	Общее условие для проводок это признак 'ПередачаПравТребований'

2. Второй этап- 
	А) Создается обобщенное табличное выражение backRes в которую выбираются только 
	проводки тип "Возврат" с максимальной датой
	Б) На основании этого выражения(backRes) вносятся  изменения в таблицу реестра цессий
	в соответствующие поля.Данные берутся из таблицы Tmp
	При обновлении данных по договорам записывается текущая дата
	
3. Треьий этап- 
	А) Создается обобщенное табличное выражение priceRes в которую выбираются только 
	проводки тип "Изменение цены" с максимальной датой
	Б) На основании этого выражения(priceRes) вносятся  изменения в таблицу реестра цессий
	Часть данных берется из таблицы Tmp, друга - расчитывается
	При обновлении данных по договорам записывается текущая дата
	

*/
CREATE PROC [finAnalytics].[ReestrCession_update_dogBackPrice] 
	
AS
BEGIN
	--дополнительные ограничения на обновление данных
	declare @limitDateChangePrice date = '2025-08-01'--ограниение на обновление измения цены 
	drop table if exists #numDogChangePrice
	create table #numDogChangePrice (numdog varchar(100))-- таблица договоров по которым возможно измения цены

	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

	
	declare @subject  varchar(250) ='Регистр по Цессии-возвраты и измение цены '
											
	-- переменные для формирования текста сообщения
	declare @msgHeader varchar(max)=concat('Кол-во обновленных полей : ',char(10))
	declare @msgFloor varchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message varchar(max)=''
begin try	
  begin tran 
	--1
	drop table if exists #tmp
	create table #tmp(
		datT datetime
		,numdog varchar(100)
		,dt varchar(50)
		,kt varchar(50)
		,summ float
		,mem varchar(100)
		,descr varchar(max))

	insert into #tmp
		select 
			[Дата]=a.Период
			,[Номер договора]=isnull(d.Номер,k.Номер)
			,[Дебет]=b.Код 
			,[Кредит]=c.Код 
			,[Cумма]=a.Сумма
			,mem = isnull(memKt.Имя,memDt.Имя)
			,a.Содержание
		from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка
		left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов d on a.СубконтоDt2_Ссылка=d.Ссылка
		left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов k on a.СубконтоCt2_Ссылка=k.Ссылка
		left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов memKt on a.СубконтоCt3_Ссылка=memKt.Ссылка 
		left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов memDt on a.СубконтоDt3_Ссылка=memDt.Ссылка 
		where  ((b.Код='71502' and c.Код = '61217') -- изменение цены
				or (b.Код='48801' and c.Код = '61217') or (b.Код='48802' and c.Код = '61217')--возврат
				or (b.Код='61217' and c.Код = '60322'))--для контроля измения цены -проводка спутник 71502-61217
			and (memKt.Имя='ПередачаПравТребований' or memDt.Имя='ПередачаПравТребований')
	
		order by b.Код, c.Код
	---2
	;with backRes
	as
		(select 
			[dt], [kt],[numdog], [summ],cast(dateadd(year,-2000,[datT]) as date)as datT 
		from (select [datT], [dt], [kt], [summ], [numdog], [mem], [descr] 
			, rn =ROW_NUMBER() over (partition by numdog order by datT desc) 	
			from #tmp
			where ((dt='48801' and kt = '61217') or (dt='48802' and kt = '61217')))l1
		where l1.rn=1)
	merge finAnalytics.ReestrCession as trg
	using backRes as src
	on trg.dogClient=src.numDog 
		when matched and (isnull(trg.[dateBack],'2000-01-01')<src.datT and src.datT>trg.repdate) then
			update set trg.[numDogBack]=src.numDog,trg.[dateBack]=src.datT
			,trg.updateDate=getdate();

	set @message= concat(@message,'Возвратов - ',@@ROWCOUNT,char(10))

	-- формируем таблицу договоров по которым возможно измение цены
	insert into #numDogChangePrice
		select 
			distinct numdog
		from #tmp  as a
		left join finAnalytics.ReestrCession as res on a.numDog=res.numDogBack
		where res.numDogBack is null

	--3
	;with priceRes
	as( select a.*
		from (select 
					[dt], [kt], [numdog], [summ],cast(dateadd(year,-2000,[datT]) as date) as datT
				from (select a.datT, a.dt, a.kt, a.summ, a.numdog, a.mem, a.descr 
							, rn =ROW_NUMBER() over (partition by a.numdog order by a.datT desc) 	
					  from #tmp a
					  where  a.dt='71502' and a.kt = '61217'
					  )l1
				where l1.rn=1) a
		--отсеиваем те которые на имеют проводок спутников
		inner join (select * from #tmp where dt='61217' and kt = '60322') b on  a.numdog=b.numdog
		--where a.datT>='2025-08-01'
	)
	merge finAnalytics.ReestrCession as tgt
	using priceRes as src
	on tgt.dogClient=src.numDog 
		when matched and (	--только не нулевыми суммами
							(src.summ<>0 and isnull(tgt.summChangePrice,0)<>src.summ)
							-- выбираем только договора которые не попали в возвраты
							and src.numDog in(select * from #numDogChangePrice)
							-- выбираем договора с ограничением на дату @limitDateChangePrice 
							and (src.datT>=@limitDateChangePrice )
							) then 
			update set tgt.[numDogBackChangePrice]=src.numDog,tgt.[summChangePrice]=src.summ ,tgt.[dateChangePrice]=src.datT
			,tgt.[newPriceDogCession]=tgt.viruchka-src.summ
			,tgt.[newFinreservBU]=tgt.[finreservBU]-src.summ
			,tgt.[newFinreservNU]=tgt.[finreservNU]-src.summ
			,tgt.[newProcPriceBalans]=(tgt.viruchka-src.summ)/nullif((tgt.[ZadolgOsnovDolg]+tgt.[ZadolgProc]),0)
			,tgt.updateDate=getdate();
		commit tran
		set @message= concat(@message,'Измение цены - ',@@ROWCOUNT,char(10))

		set @message=concat(@msgHeader,@message,@msgFloor)
		exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'

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

