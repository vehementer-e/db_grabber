
/*

*/
 CREATE PROCEDURE [finAnalytics].[addCashIn_check] 
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
	declare @subjectHeader  nvarchar(250) ='Проверка Cash-In', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Проверка проводок Cash-In: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''

 begin try	
  begin tran 
	delete from dwh2.finAnalytics.CashIn_CheckList where REPDATE between dateadd(year,-2000,@startDate) and dateadd(year,-2000,@endDate)

	declare @addRowNotIdent int, @addRowError int

	insert into  dwh2.finAnalytics.CashIn_CheckList(repdate,dt,kt,numDog,client,beginDate,summ,mem,rzd,fin,findop,plat,choice)
	select 
			
			repdate=dateadd(year,-2000,cast(a.Период as date))
			,dt=b.Код 
			,kt=c.Код 
			,numDog= isnull(dog1.Номер,dog2.Номер)
			,client=z.НаименованиеЗаемщика
			,beginDate=dateadd(year,-2000,cast(isnull(dog1.Дата,dog2.Дата) as date))
			,summ=a.Сумма
			,mem=isnull(mem.Наименование,a.Содержание)
			,rzd=''
			,fin=''
			,findop=''
			,plat=''
			,choice=0
		from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
		left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
		left join #dogClient dog1 on a.СубконтоCt2_Ссылка=dog1.Ссылка 
		left join #dogClient dog2 on a.СубконтоDt2_Ссылка=dog2.Ссылка
		left join stg._1cUMFO.Справочник_БНФОСубконто mem on a.СубконтоCt3_Ссылка=mem.Ссылка and mem.ПометкаУдаления=0x00
		left join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных z on isnull(dog1.Номер,dog2.Номер)=z.номерДоговора
						and convert(date, dateadd(year, -200, a.Период)) = z.ОтчетнаяДата
		left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов vvz on a.СубконтоDt3_Ссылка=vvz.Ссылка	
		left join (select distinct dt,kt from #Provodki where dt='47422' or kt='47422') d on b.Код =d.dt and c.Код =d.kt
		 where cast(a.Период as date) between @startDate and @endDate
	 		and ((d.dt is null and d.kt is null) 
						and (
							(b.Код ='47422' or c.Код ='47422')
							or
							--здесь вносим проводки которые нужно отразить в нестандартные
							(b.Код ='61217' and c.Код ='71501'and upper(vvz.Имя)=upper('ПолноеДосрочноеПогашение'))
							) 
				)
			and (upper(isnull(mem.Наименование,a.Содержание))!=upper('Выдача займа'))
			and not (b.Код ='47422' and c.Код ='61217')
			and substring(isnull(dog1.Код,dog2.Код),1,3) in  ('488','487','494')
			and a.Активность=0x01


	insert into dwh2.finAnalytics.CashIn_CheckList(repdate,dt,kt,numDog,client,beginDate,summ,mem,rzd,fin,findop,plat,choice)
		select 
			repdate=dateadd(year,-2000,a.dat)
			,dt=a.dt
			,kt=a.kt 
			,numDog=a.numdog
			,client=z.НаименованиеЗаемщика
			,beginDate=a.beginDate
			,summ=a.summ
			,mem=a.mem
			,rzd=a.rzd
			,fin=a.fin
			,findop=a.findop
			,plat=a.plat
			,choice=1
		from #Registor a
		left join stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных z on a.numdog=z.номерДоговора 
					and convert(date, dateadd(year, -2000, a.dat)) = z.ОтчетнаяДата
		left join #Provodki  d on a.reg=d.reg and a.regNum=d.regNum and a.dt=d.dt
		 where (d.reg is null and d.regNum is null) 

	
  commit tran
	set @addRowNotIdent=(select count(*) from dwh2.finAnalytics.CashIn_CheckList where choice=0  and repdate between dateadd(year,-2000,@startDate) and dateadd(year,-2000,@endDate))
	set @addRowError=(select count(*) from dwh2.finAnalytics.CashIn_CheckList where choice=1  and repdate between dateadd(year,-2000,@startDate) and dateadd(year,-2000,@endDate))
	if @addRowNotIdent>0 or @addRowError>0
		begin
			set @subject=concat('Внимание!Проверка Cash_In ',@subjectHeader) 
			set @message=concat('Нестандартные проводки: ',@addRowNotIdent,char(10))
			set @message=concat(@message,'Ошибочные проводки: ',@addRowError,char(10))
		end
	else 
		begin
		set @subject=concat('ОК!Нестандартные проводки ',@subjectHeader) 
		set @message='В отчете НЕТ нестандартных или ошибочных проводок'
		end
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
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

