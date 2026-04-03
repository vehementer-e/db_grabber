

/*1.Первый этап.Удалятся все данные за этот месяц, если они были в реестре.
				Данными из отчета 1c за месяц дополняется таблица реестра Reestr20501(в случаи ошибки отменяется транзакция и сообщается об ошибке)
				Изменяются дата в регламенте отчетов в таблице reportReglament.
				В таблице реестра есть дополнительные поля:
				a.	Created поле говорит нам о том когда была добавлена эта запись в таблицу реестра.
				b.	reestr_InSumm, reestr_OutSumm, provod_InSumm, provod_OutSumm поля в которые вносятся данные о суммах Поступлений и Списаний из отчета 1C и проводок
				c.	Рассылка о том что добавлены строки

  2.	Второй этап. 
	a.	Используется процедура calcSumReestr20501 для вычисление сумм проводок по Поступлении и Списанию за определенный период. 
	b.	Далее сравнение сумм Поступлений и Списаний из 1С и сумм из процедуры calcSumReestr20501. 
	c.	Обновление полей reestr_InSumm, reestr_OutSumm, provod_InSumm, provod_OutSumm расчетными данными.
	d.	В случаи если есть расхождение рассылка адресатам

*/
CREATE PROCEDURE [finAnalytics].[addReestr20501_SG] 
    
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	declare @repmonthtemp date = (select min(CONVERT (date, [Отчетный месяц], 104)) from stg.files.Rep20501_sg)
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
	
	declare @subjectHeader  nvarchar(250) ='Реестр 20501 СГ', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Внесение данных в реестр 20501 СГ: ',FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	
	declare @addRow  int -- подсчет добавленных строк в реестр
	declare @maxDateRest NVARCHAR(30) --дата последних данных для Регламента Отчетов

	declare @inSumm float, @outSumm float --переменные для сравнение сумм по реестру и проводкам

	declare @startDate date=@repmonth, @endDate date=(select max(CONVERT (date, [Дата], 104)) from stg.files.Rep20501) --переменные начало конец периода выборки проводок 



  begin try
  --старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

  	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name
-- Первый этап
    delete from finAnalytics.Reestr20501_sg where REPMONTH=@repmonth

	begin tran  
		insert into finAnalytics.Reestr20501_sg (REPDATE,Dt,Kt,inSumm,outSumm,Client,typeClient,innClient,senderPay,purPay,numAcc,nameBank,bikBank,codBank
				,Registar,numDoc,typeOperation,inNumDoc,inDateDoc,itemDDS,itemDDSgroup,typeMoveBR,typeMove,numOrderPay,Comment
				,numZRDS,dateZRDS,beginCost,itemExp,CFO,itemIncExp,allSumm,REPMONTH,created,reestr_InSumm,reestr_OutSumm,provod_InSumm,provod_OutSumm)
	
		  select 
			REPDATE=CONVERT (date, [Дата], 104)
			,Dt=[Счет Дт]
			,Kt=[Счет Кт]
			,inSumm=cast (isnull([Поступление, сумма в рублях],0) as float)
			,outSumm=cast (isnull([Списание, сумма в рублях],0) as float)
			,Client=[Контрагент]
			,typeClient=[Тип контрагента (ФЛ/ИП/ЮЛ)]
			,innClient=[ИНН]
			,senderPay=[Отправитель платежа]
			,purPay=[Назначение платежа]
			,numAcc=[Номер счета]
			,nameBank=[Наименование банка]
			,bikBank=[БИК]
			,codBank=[Код операции по Указанию 4263-У]
			,Registar=[Регистратор]
			,numDoc=[Номер документа]
			,typeOperation=[Вид операции]
			,inNumDoc=[Вх# номер]
			,inDateDoc=CONVERT (date, [Вх# дата], 104)
			,itemDDS=[Статья ДДС]
			,itemDDSgroup=[Статья ДДС группа]
			,typeMoveBR=[Вид движения (Банк России)]
			,typeMove=[Вид движения (реклассификация)]
			,numOrderPay=[Номер платежного поручения]
			,Comment=[Комментарий]
			,numZRDS=[Номер ЗРДС]
			,dateZRDS=convert (date,[Дата ЗРДС],104)
			,beginCost=[Нач затрат]
			,itemExp=[Статья расходов]
			,CFO=[ЦФО]
			,itemIncExp=[Статья доходов и расходов]
			,allSumm=cast(isnull([Общая сумма по документу],0) as float)
			,REPMONTH=@repmonth
			,created=getdate()
			, reestr_InSumm=0.0
			, reestr_OutSumm=0.0
			, provod_InSumm=0.0
			, provod_OutSumm=0.0
		from stg.files.Rep20501_sg
	set @addRow=@@ROWCOUNT
	commit tran

	-- обновление даты в Регламент Отчетов
	set @maxDateRest = cast((select max(repmonth) from finAnalytics.Reestr20501) as varchar)
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDateSG] = @maxDateRest
	where [reportUID]=43
 	

	set @subject=concat('ОK ',@subjectHeader)
	set @message= concat(@message,'Кол-во добавленных строк - ',@addRow,char(10))
	set @message=concat(@msgHeader,@message,@msgFloor)
	exec finAnalytics.sendEmail @subject, @message ,@strRcp = '1'

-- Второй этап
	
	---- проверка сумм по Поступлению и Списанию по проводкам
	--exec finAnalytics.calcSumReestr20501  @startDate, @endDate, @inSumm out, @outSumm out
	--declare  @reestr_InSumm float =(select	sum(inSumm)	from finAnalytics.Reestr20501 where repmonth=@repmonth)
	--		,@reestr_OutSumm float =(select sum(outSumm) from finAnalytics.Reestr20501 where repmonth=@repmonth)
		
	--update finAnalytics.Reestr20501
	--set reestr_InSumm=@reestr_InSumm
	--	,reestr_OutSumm=@reestr_OutSumm
	--	,provod_InSumm=@inSumm
	--	,provod_OutSumm=@outSumm
	--where repmonth=@repmonth
	--set @InSumm=round(@inSumm - @reestr_InSumm ,2)
	--set @OutSumm=round(@outSumm -@reestr_OutSumm ,2)
	
	--if abs(@inSumm)>=100 or abs(@outSumm)>=100
	--	begin
	--		set @subject=concat('Внимание! ',@subjectHeader)
	--		set @message= concat('Найдено расхождение в сумме поступлении: ',format(abs(@inSumm), 'C', 'ru-Ru'),char(10))
	--		set @message= concat(@message,'Найдено расхождение в сумме списаний: ',format(abs(@outSumm), 'C', 'ru-Ru') ,char(10))
	--		set @message= concat(@message,'Подробная информация по ссылке ',(select link from reportReglament where reportUID=43) ,char(10))
	--		set @message=concat(@msgHeader,@message,@msgFloor)
	--		exec finAnalytics.sendEmail @subject, @message ,@strRcp = '1,32,31'
	--	end

	-- обновление даты в Регламент Отчетов
	set @maxDateRest = cast((select max(repmonth) from finAnalytics.Reestr20501) as varchar)
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDateSG] = @maxDateRest
	where [reportUID]=43

	--финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

 end try 

 begin catch
 --кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '1'
    IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
   throw 51000 
			,@message
			,1;    
  end catch

END
