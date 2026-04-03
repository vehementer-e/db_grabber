

CREATE PROCEDURE [finAnalytics].[loadAkciaVzisk_Monthly] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
       
    begin try

	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name


    declare @repmonthtemp date = (select min(CONVERT (date, a.[Отчетная дата], 104)) from stg.[files].[AkciiVziskan] a)
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    delete from [finAnalytics].akcia_vzisk_MONTHLY where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO [finAnalytics].akcia_vzisk_MONTHLY
	(
	 repMonth, zaim, client, passSeria, passNum, passDate, passIssuer, passCode, addressReg, spisanieText, 
     spisanieReason, accOD, accPRC, accOther, sumRestBegin, sumSpisPRC, sumSpisPenia, sumFogive, sumFogiveOD, 
     sumFogivePRC, sumFogivePenia, sumFogivePeniaSUD, sumFogiveShtraf, sumFogiveZadolg, sumFogiveShtrafSUD, 
     sumFogiveOther, sumFogiveOtherSUD, sumFogiveComiss, sumPogashOD, sumPogashPRC, sumPogashPenia, sumPogashGP, 
     sumOborot, sumReservBackBU, sumReservBackNU, [rest47422], dataLoadDate
	 )
     

	select
   REPMONTH = @REPMONTH
 , zaim = a.[Займ]
 , client = a.[Заемщик]
 , passSeria = a.[Паспорт серия]
 , passNum = a.[Паспорт номер]
 , passDate = convert(date,a.[Паспорт дата выдачи],104)
 , passIssuer = a.[Паспорт кем выдан]
 , passCode = a.[Паспорт код подразделения]
 , addressReg = a.[Адрес регистрации]
 , spisanieText = a.[Ссылка]
 , spisanieReason = a.[Ссылка#Причина]
 , accOD = a.[Счет аналитического учета списания основного долга]
 , accPRC = a.[Счет аналитического учета списания процентов]
 , accOther = a.[Счет учета расчетов с прочими дебиторами]
 , sumRestBegin = case when try_cast(isnull(a.[Сумма начальный остаток],0) as float) is not null 
						then isnull(a.[Сумма начальный остаток],0)
						else cast(replace(isnull(a.[Сумма начальный остаток],0),',','.') as float) end

 , sumSpisPRC = case when try_cast(isnull(a.[Сумма списания при переобслуживании Проценты (Дт# 71001 - Кт# 48],0) as float) is not null
					then isnull(a.[Сумма списания при переобслуживании Проценты (Дт# 71001 - Кт# 48],0)
					else cast(replace(isnull(a.[Сумма списания при переобслуживании Проценты (Дт# 71001 - Кт# 48],0),',','.') as float) end

 , sumSpisPenia = case when try_cast(isnull(a.[Сумма списания при переобслуживании Пени (Дт# 71701 - Кт# 60323)],0) as float) is not null
						then  isnull(a.[Сумма списания при переобслуживании Пени (Дт# 71701 - Кт# 60323)],0)
						else cast(replace(isnull(a.[Сумма списания при переобслуживании Пени (Дт# 71701 - Кт# 60323)],0),',','.') as float) end

 , sumFogive = case when try_cast(isnull(a.[Сумма прощения Сумма задолженности],0) as float) is not null
					then isnull(a.[Сумма прощения Сумма задолженности],0)
					else cast(replace(isnull(a.[Сумма прощения Сумма задолженности],0),',','.') as float) end

 , sumFogiveOD = case when try_cast(isnull(a.[Сумма прощения Основной долг (Дт# 71802 - Кт# 48801)],0) as float) is not null
					then isnull(a.[Сумма прощения Основной долг (Дт# 71802 - Кт# 48801)],0)
					else cast(replace(isnull(a.[Сумма прощения Основной долг (Дт# 71802 - Кт# 48801)],0),',','.') as float) end

 , sumFogivePRC = case when try_cast(isnull(a.[Сумма прощения Проценты (Дт# 71802 - Кт# 48802)],0) as float) is not null
						then isnull(a.[Сумма прощения Проценты (Дт# 71802 - Кт# 48802)],0)
						else cast(replace(isnull(a.[Сумма прощения Проценты (Дт# 71802 - Кт# 48802)],0),',','.') as float) end

 , sumFogivePenia = case when try_cast(isnull(a.[Сумма прощения Пени (Дт# 71802 - Кт# 60323)],0) as float) is not null
							then isnull(a.[Сумма прощения Пени (Дт# 71802 - Кт# 60323)],0)
							else cast(replace(isnull(a.[Сумма прощения Пени (Дт# 71802 - Кт# 60323)],0),',','.') as float) end

 , sumFogivePeniaSUD = case when try_cast(isnull(a.[Сумма прощения Пени (по суду)],0) as float) is not null
								then isnull(a.[Сумма прощения Пени (по суду)],0)
								else cast(replace(isnull(a.[Сумма прощения Пени (по суду)],0),',','.') as float) end

 , sumFogiveShtraf = case when try_cast(isnull(a.[Сумма прощения Штрафы],0) as float) is not null
							then isnull(a.[Сумма прощения Штрафы],0)
							else cast(replace(isnull(a.[Сумма прощения Штрафы],0),',','.') as float) end 

 , sumFogiveZadolg = case when try_cast(isnull(a.[Сумма прощения Сумма задолженности (штрафы, пени,прочие доходы)],0) as float) is not null
							then isnull(a.[Сумма прощения Сумма задолженности (штрафы, пени,прочие доходы)],0)
							else cast(replace(isnull(a.[Сумма прощения Сумма задолженности (штрафы, пени,прочие доходы)],0),',','.') as float) end

 , sumFogiveShtrafSUD = case when try_cast(isnull(a.[Сумма прощения Штрафы (по суду)],0) as float) is not null
								then isnull(a.[Сумма прощения Штрафы (по суду)],0)
								else cast(replace(isnull(a.[Сумма прощения Штрафы (по суду)],0),',','.') as float) end

 , sumFogiveOther = case when try_cast(isnull(a.[Сумма прощения Прочие доходы],0) as float) is not null
							then isnull(a.[Сумма прощения Прочие доходы],0)
							else cast(replace(isnull(a.[Сумма прощения Прочие доходы],0),',','.') as float) end

 , sumFogiveOtherSUD = case when try_cast(isnull(a.[Сумма прощения Прочие доходы (по суду)],0) as float) is not null
								then isnull(a.[Сумма прощения Прочие доходы (по суду)],0)
								else cast(replace(isnull(a.[Сумма прощения Прочие доходы (по суду)],0),',','.') as float) end

 , sumFogiveComiss = case when try_cast(isnull(a.[Сумма прощения Комиссии],0) as float) is not null
							then isnull(a.[Сумма прощения Комиссии],0)
							else cast(replace(isnull(a.[Сумма прощения Комиссии],0),',','.') as float) end

 , sumPogashOD = case when try_cast(isnull(a.[Погашения Сумма погашено ОД],0) as float) is not null
						then isnull(a.[Погашения Сумма погашено ОД],0)
						else cast(replace(isnull(a.[Погашения Сумма погашено ОД],0),',','.') as float) end

 , sumPogashPRC = case when try_cast(isnull(a.[Погашения Сумма погашено проценты],0) as float) is not null
						then isnull(a.[Погашения Сумма погашено проценты],0)
						else cast(replace(isnull(a.[Погашения Сумма погашено проценты],0),',','.') as float) end

 , sumPogashPenia = case when try_cast(isnull(a.[Погашения Сумма погашено пени],0) as float) is not null
							then isnull(a.[Погашения Сумма погашено пени],0)
							else cast(replace(isnull(a.[Погашения Сумма погашено пени],0),',','.') as float) end

 , sumPogashGP = case when try_cast(isnull(a.[Погашения Сумма погашено госпошлина],0) as float) is not null
						then isnull(a.[Погашения Сумма погашено госпошлина],0)
						else cast(replace(isnull(a.[Погашения Сумма погашено госпошлина],0),',','.') as float) end

 , sumOborot = case when try_cast(isnull(a.[Сумма оборот платежи],0) as float) is not null
					then isnull(a.[Сумма оборот платежи],0)
					else cast(replace(isnull(a.[Сумма оборот платежи],0),',','.') as float) end

 , sumReservBackBU = case when try_cast(isnull(a.[Сумма восстанволено резервов],0) as float) is not null
							then isnull(a.[Сумма восстанволено резервов],0)
							else cast(replace(isnull(a.[Сумма восстанволено резервов],0),',','.') as float) end
 
 , sumReservBackNU = case when try_cast(isnull(a.[Сумма восстанволено резервов НУ],0) as float) is not null
							then isnull(a.[Сумма восстанволено резервов НУ],0)
							else cast(replace(isnull(a.[Сумма восстанволено резервов НУ],0),',','.') as float) end

 , rest47422 = case when try_cast(isnull(a.[Остаток на 47422],0) as float) is not null
						then isnull(a.[Остаток на 47422],0)
						else cast(replace(isnull(a.[Остаток на 47422],0),',','.') as float) end

 , dataLoadDate = created
 from stg.[files].[AkciiVziskan] a
    
    commit tran
    
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.akcia_vzisk_MONTHLY) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 19

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Акций взыскания за '
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

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	
	--Запуск процедуры расчета данных по прощениям/переобслуживаниям
	exec finAnalytics.calcRepFogiveAll @repmonth

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

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

	
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem
	
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
