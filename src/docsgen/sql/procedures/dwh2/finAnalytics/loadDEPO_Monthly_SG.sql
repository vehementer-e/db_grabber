

CREATE PROCEDURE [finAnalytics].[loadDEPO_Monthly_SG] 
    
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

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

    declare @repmonthtemp date = (select min(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[DEPO_MONTHLY_SG])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth
	declare @emailList varchar(255)=''

	
    DECLARE @checkRest varchar(300)

    --SET @checkRest = (
    --                select
    --                clients = STRING_AGG(l1.client,' , ')
    --                from (

    --                select

    --                [client] = a.[Наименование заимодавца]
    --                ,[sumODSource] = sum(isnull(a.[Остаток по ОД],0))
    --                ,[sumPrivlSource] = sum(isnull(a.[В том числе Привлечено (за весь период действия договора до указ],0))

    --                ,[sumODDest] = sum(b.[restOD])
    --                ,[sumPrivlDest] = sum(b.[privlech])

    --                ,[checkOD] = sum(isnull(a.[Остаток по ОД],0)) - sum(b.[restOD])
    --                ,[checkPrivl] = sum(isnull(a.[В том числе Привлечено (за весь период действия договора до указ],0)) - sum(b.[privlech])


    --                from stg.[files].[DEPO_MONTHLY] a
    --                inner join finAnalytics.SPR_DEPO_errClients b on a.[Наименование заимодавца]=b.client and a.[Номер договора]=b.dogNum and b.actualToDate >=@repmonth

    --                where a.[Наименование заимодавца]!='Тымчак Светлана Андреевна 27.09.1972'
    --                group by a.[Наименование заимодавца]

    --                ) l1
    --                where l1.checkOD != 0 or l1.checkPrivl!=0
    --)

  --  if @checkRest is not null 
  --  begin
  --  declare @body_text2 nvarchar(MAX) = CONCAT(
  --                                                  'В отчете по привлечению 2.0 за '
  --                                                  , FORMAT( eoMONTH(@repmonth), 'MMMM yyyy', 'ru-RU' )
  --                                                  ,char(10)
  --                                                  ,char(13)
  --                                                  ,'изменились остатки по клиентам:'
  --                                                  ,char(10)
  --                                                  ,char(13)
  --                                                  ,@checkRest
  --                                                  ,char(10)
  --                                                  ,char(13)
  --                                                  ,'Необходимо актуализировать справочник. Загрузка прервана.'
  --                                                  )
  --      declare @subject2  nvarchar(200)  = CONCAT('Изменились остатки по клиентам из справочника исключений: ',FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' ))
		
		----настройка адресатов рассылки
		--set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
		--EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
		--	,@recipients = @emailList
		--	,@copy_recipients = ''
		--	,@body = @body_text2
		--	,@body_format = 'TEXT'
		--	,@subject = @subject2;

  --          throw 51000 
		--	,''
		--	,1;

  --  end
	

    
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)

       
    begin try

    delete from finAnalytics.DEPO_MONTHLY_SG where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO finAnalytics.DEPO_MONTHLY_SG
	(
	[repMonth], [client], [INN], [dogNum], [dogDSNum], [isMainDog], [mainDogNum], [mainDogDate], [dogDate], [zaimSum]
	, [zaimVal], [prodName], [StavkaDogDate], [StavkaRepDate], [dogSaleDate], [dogEndDate], [firstDogEndDate], [restOD]
	, [addOD], [returnOD], [restPRC], [addPRC], [returnPRC], [incNDFL], [isMSP], [capitalType], [daysToClose], [daysDog]
	, [passport], [birthDay], [addressFact], [addressReg], [branchAddress], [accOD], [accPRC], [dataLoadDate], [clientType]
	, [stavkaRepDateType], [closeDate], [dogState]
	 )
     
	 select
	 [repMonth], [client], [INN], [dogNum], [dogDSNum], [isMainDog], [mainDogNum], [mainDogDate], [dogDate], [zaimSum]
	, [zaimVal], [prodName], [StavkaDogDate], [StavkaRepDate], [dogSaleDate], [dogEndDate], [firstDogEndDate], [restOD]
	, [addOD], [returnOD], [restPRC], [addPRC], [returnPRC], [incNDFL], [isMSP], [capitalType], [daysToClose], [daysDog]
	, [passport], [birthDay], [addressFact], [addressReg], [branchAddress], [accOD], [accPRC], [dataLoadDate], [clientType]
	, [stavkaRepDateType], [closeDate], [dogState]
	from (

        select
        REPMONTH = @REPMONTH
        , client = a.[Наименование заимодавца]
		, INN = a.[ИНН]
		, dogNum = a.[Номер договора]
		, dogDSNum = a.[Номер ДС]
		, isMainDog = a.[Признак основного договора]
		, mainDogNum = a.[Номер основного договора]
		, mainDogDate = convert(date,a.[Дата основного договора],104)
		, dogDate = convert(date,a.[Дата договора / ДС],104)
		, zaimSum = a.[Сумма займа (сбережения)]
		, zaimVal = a.[Валюта займа]
		, prodName = a.[Вид займа / Продукт]
		, StavkaDogDate = a.[Ставка по договору]
		, StavkaRepDate = a.[Процентная ставка на отчетную дату]
		, dogSaleDate = convert(date,a.[Дата привлечения],104)
		, dogEndDate = convert(date,a.[Дата окончания договора],104)
		, firstDogEndDate = convert(date,a.[Первоначальная дата окончания договора],104)
		, restOD = a.[Остаток по ОД]--case when b.client IS not null  and a.[Состояние] != 'Закрыт' then b.restOD else a.[Остаток по ОД] end
		, addOD = a.[В том числе Привлечено (за весь период действия договора до указ]--case when b.client IS not null and a.[Состояние] != 'Закрыт' then b.privlech else  a.[В том числе Привлечено (за весь период действия договора до указ] end
		, returnOD = a.[В том числе Выплачено (за весь период действия договора до указа]
		, restPRC = a.[Остаток по %]
		, addPRC = a.[В том числе Начислено]
		, returnPRC = a.[В том числе Выплачено]
		, incNDFL = a.[В том числе НДФЛ]
		, isMSP = a.[Признак Субъекта МСП (Да/Нет)]
		, capitalType = a.[Капитализация выплата в конце срока]
		, daysToClose = a.[Количество дней до погашения]
		, daysDog = a.[Срок договора, дн#]
		, passport = a.[Паспортные данные]
		, birthDay = convert(date,a.[Дата рождения],104)
		, addressFact = a.[Адрес физ лица проживания]
		, addressReg = a.[Адрес физ лица регистрация]
		, branchAddress = a.[Адрес подразделения]

		, accOD = null--a.[Счет ОД]
		, accPRC = null--a.[Счет %]
		, dataLoadDate = a.created
		, clientType = a.[Вид контрагента]
        , stavkaRepDateType = a.[Вид процентной ставки на отчетную дату]
		, closeDate = convert(date,a.[Дата закрыт],104)
		, dogState = a.[Состояние]

        from stg.[files].[DEPO_MONTHLY_SG] a
        --left join finAnalytics.SPR_DEPO_errClients b on a.[Наименование заимодавца]=b.client and a.[Номер договора]=b.dogNum  and @repmonth >= b.actualToDate 
    ) l1

	/*Расчет средних остатков ОД*/
		declare @dateFrom datetime = dateadd(year,2000,@repmonth)
		declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repmonth)))
		declare @dateTo datetime = dateadd(second,-1,@dateToTmp)
		declare @daysInMonth int = day(eomonth(@repmonth))

		DROP TABLE IF EXISTS #avgRests

		select
		[repmonth] = l1.[repmonth]
		,[Контрагент] = l1.[Контрагент]
		,[Договор] = l1.[Договор]
		,[AVGRestOD] = round(sum(l1.[restOD]) / @daysInMonth, 2)

		into #avgRests

		from(

		SELECT 
		[repmonth] = @repmonth
		,[Отчетная дата] = dateadd(year,-2000,cast(a.Период as date))
		,[Контрагент] = b.Наименование
		,[Договор] = c.Номер
		,[restOD] = a.СуммаНачальныйОстатокКт	
		FROM [Stg].[_1cSH].[РегистрСведений_СЗД_ДанныеПоСчетамДляDWH] a
		left join [Stg].[_1cSH].[ПланСчетов_Хозрасчетный] e on a.СчетУчета = e.Ссылка
		left join [Stg].[_1cSH].Справочник_Контрагенты b on a.Субконто1_Ссылка =b.ссылка
		left join [Stg].[_1cSH].[Справочник_ДоговорыКонтрагентов] c on Субконто2_Ссылка =c.ссылка
		inner join [dwh2].[finAnalytics].[DEPO_MONTHLY_SG] d on c.Номер = d.dogNum and b.Наименование=d.client and d.repmonth = @repmonth
		where a.период between @dateFrom and @dateTo
		and e.Код in ('66.03','67.03','66.01','67.01')
		) l1

		group by
		l1.[repmonth]
		,l1.[Контрагент]
		,l1.[Договор]


		merge into dwh2.finAnalytics.DEPO_MONTHLY_SG t1
		using(
		select * from #avgRests
		) t2 on (t1.repmonth = t2.repmonth and t1.client = T2.[Контрагент] and t1.dogNum = t2.[Договор])
		when matched then update
		set t1.AVGRestOD = t2.AVGRestOD;
	    
	commit tran
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from [finAnalytics].[DEPO_MONTHLY_SG]) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDateSG] = @maxDateRest
	where [reportUID] in (20)

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Отчета по привлечению СГ за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                ,'Максимальная дата остатков: '
                ,@maxDateRest
				)

	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
