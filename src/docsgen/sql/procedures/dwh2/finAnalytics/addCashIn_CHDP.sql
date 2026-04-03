


/*

*/
CREATE PROCEDURE [finAnalytics].[addCashIn_CHDP] 
		@startDate date
		,@endDate date
AS
BEGIN

	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
	declare @log_IsError bit=0
	declare @log_Mem nvarchar(2000)	='Ok'
	declare @mainPrc nvarchar(255)=''
	if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
		set @mainPrc=(select top(1) sp_name from #mainPrc)
	exec finAnalytics.sys_log @sp_name,0,@mainPrc
	-----
	declare @subjectHeader  nvarchar(250) ='', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Анализ ЧДП для Cash-In: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''

 begin try	
  begin tran 
	declare @row int=0
	
	-------расчет ЧДП по текущим договорам----------------
	--declare @startDate date='4025-07-24'
	--declare @endDate date='4025-09-22'
	set @startDate =dateadd(year,-2000,@startDate)
	set @endDate =dateadd(year,-2000,@endDate)

--1. создаем таблицу графиков платежей по интересующим договорам-------------- 
	--таблица договоров 
	drop table if exists #dogchdp
	create table #dogchdp (numdog nvarchar(28), dateDog date,linkDog binary(16))
	insert into #dogchdp
		select 
			distinct 
			numdog=cash.numDog
			,dateDog=dog.Дата
			,linkDog=dog.Ссылка
			from dwh2.finAnalytics.CashIn cash
			left join stg._1cCMR.Справочник_Договоры dog on cash.numdog=dog.Код and dog.ПометкаУдаления=0x00
			where cash.repdate between @startDate and @endDate
	-- приведенный график платжей в нормальный вид с учетом даты погашения очередного платежа
	drop table if exists #Grafik
	create table #Grafik(dateNewGrafik date,linkDog binary(16),numDog nvarchar(28),dateDogPlat date,startPeriod date,endPeriod date,dateDog date)
	insert into #Grafik(dateNewGrafik,linkDog,numDog,dateDogPlat,startPeriod,endPeriod,dateDog)
	select
		dateNewGrafik=l1.dateNewGrafik
		,linkDog=l1.linkDog
		,numDog=l1.numDog
		,dateDogPlat=l1.dateDogPlat
		,startPeriod=isnull(lag(l1.dateDogPlat)over(partition by l1.numdog, l1.dateNewGrafik order by l1.dateDogPlat), iif(l1.dateNewGrafik=l1.dateDog,null,l1.dateNewGrafik))
		,endPeriod=l1.dateDogPlat
		,dateDog=l1.dateDog

	from
		(
		select 
			dateNewGrafik= iif(datediff(day,cast(dog.Дата as date),cast(a.Период as date))<=14 and a.НомерСтроки=1
							,cast(a.Период as date)
							,first_value(cast(a.Период as date))over(partition by nd.numdog,format(a.ДатаПлатежа,'yy MM', 'ru-ru') order by cast(a.Период as date) desc)
							)
			,dateDogPlat=cast(a.ДатаПлатежа as date)
			,linkDog=a.Договор
			,numDog=nd.numdog
			,dateDog=cast(dog.Дата as date)
		from #dogchdp nd
		left join stg._1cCMR.Справочник_Договоры dog on nd.linkDog=dog.Ссылка and dog.ПометкаУдаления=0x00
		left join stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей a on nd.linkDog=a.Договор
		inner join stg._1cCMR.Документ_ГрафикПлатежей b on a.Регистратор_Ссылка=b.Ссылка and b.Основание_Ссылка!=convert(binary (16),0)and b.ПометкаУдаления=0x00 and b.Проведен=0x01
		where a.Действует=0x01 
		)l1
	group by
		l1.linkDog
		,l1.numDog
		,l1.dateNewGrafik
		,l1.dateDogPlat
		,l1.dateDog

	-- таблица итогов с флагами ЧДП и ЧДП 14
	drop table if exists #flagCHDPTable
	create table #flagCHDPTable(numDog nvarchar(28),repdate date,flag int,flag14 int)

-- 2. сопоставляем данные графика платежей, заявление на ЧДП и изменеия в сумме ОД, далее формируем флаг ЧДП
	-- представление по договорам в разрезе измения ОД
	;with cte_OD
	as (
	select 
		linkDog=a.Договор
		,dateNewGrafik=cast(a.Период as date)
		,od=sum(a.ОД)
	from stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей a
	inner join #dogchdp chd on a.Договор=chd.linkDog
	where a.Активность=0x01 and a.Действует=0x01
	group by
		a.Договор
		,cast(a.Период as date)
		),
	--представление для допол столбца заявок ЧДП чтобы заявка попадала в нужный период по графику 
	cte_Zayv 
	as(
		select 
			l1.*
			,dateRefZayv=iif(datediff(day,chd.dateDog,l1.Дата)>14,dateadd(month,1,l1.Дата),l1.Дата)
		from (
			--группировкой исключаем несколько заявлений в одно и тоже число
			select 
				Дата=cast(Дата as  date)
				,Договор=Договор
			from stg._1cCMR.Документ_ЗаявлениеНаЧДП 
			where ПометкаУдаления=0x00
			group by 
				cast(Дата as  date)
				,Договор
			) l1
		inner join #dogchdp chd on l1.Договор=chd.linkDog
	 )
	-- 	
	insert into #flagCHDPTable (numDog,repdate,flag,flag14)
		select 
			numdog=l1.numdog
			,repdate=dateadd(year,-2000,l1.dateNewGrafik)
			,flag=iif(	 	
						 iif(lag(l1.dateNewGrafik)over(partition by l1.numdog order by l1.dateNewGrafik)!=l1.dateNewGrafik,1,0) --фиксируем измение графика
						 +iif(l1.dateZayv is not null,1,0)--фиксируем наличия заявления ЧДП
						 +iif(lag(l1.od)over(partition by l1.numdog order by l1.dateNewGrafik)>l1.od,1,0) --фиксируем измение ОД
						 =3
						 ,1
						 ,0
					 )
			,flag14=iif(	 	
						iif(lag(l1.dateNewGrafik)over(partition by l1.numdog order by l1.dateNewGrafik)!=l1.dateNewGrafik,1,0) --фиксируем измение графика
						+iif(l1.dateZayv is not null,1,0)--фиксируем наличия заявления ЧДП
						+iif(lag(l1.od)over(partition by l1.numdog order by l1.dateNewGrafik)>l1.od,1,0) --фиксируем измение ОД
						+iif(datediff(day,l1.dateDog,l1.dateNewGrafik)<=14,1,0) --фиксируем если заявление в течении 14дней
						=4
						,1
						,0)
						
						
		from (
			select 
				a.* 
				,dateZayv=zayv.Дата
				,od=od.od
			from #Grafik a
			--сопоставляем дата начала графика платежа и дату заявления на ЧДП
			left join cte_Zayv zayv on a.linkDog=zayv.Договор 
						and ((a.startPeriod<zayv.dateRefZayv and a.endPeriod>=zayv.dateRefZayv)
							or (a.startPeriod<=zayv.dateRefZayv and a.endPeriod>zayv.dateRefZayv))
			--сопоставляем дата начала графика платежа и значение ОД на эту дату
			left join cte_OD od on a.linkDog=od.linkDog and a.dateNewGrafik=od.dateNewGrafik
			) l1
		where l1.dateZayv is not null or (l1.dateNewGrafik =l1.dateDog and l1.startPeriod is null)

	delete from #flagCHDPTable where flag=0

--3. Обновляем данные по ЧДП для таблицы CashIn
	merge into dwh2.finAnalytics.CashIn tgt
	using #flagCHDPTable src
		on tgt.numdog=src.numdog and tgt.repdate=src.repdate and tgt.summIn=0.0
		when matched  then update set tgt.chdp=src.flag;
	
  commit tran
	set @row=(select count(*)from #flagCHDPTable)
	if @row>0 
		begin
			set @subject=concat('Обновлены данные по ЧДП ',@subjectHeader) 
			set @message='Обновлены данные по ЧДП'
			set @message=concat(@msgHeader,@message,@msgFloor)
			exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
		end
	--финиш лог
	exec dwh2.finAnalytics.sys_log @sp_name,1,@mainPrc		
	
 end try 

 begin catch
	-- финиш лог
	set @log_IsError =1
	set @log_Mem =ERROR_MESSAGE()
	exec finAnalytics.sys_log @sp_name,1,@mainPrc,@log_IsError,@log_Mem
    --
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

