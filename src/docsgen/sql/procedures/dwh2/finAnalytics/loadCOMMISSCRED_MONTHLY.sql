

CREATE PROCEDURE [finAnalytics].[loadCOMMISSCRED_MONTHLY] 
    
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name

    declare @repmonthtemp date = (select min([Отчетная дата]) from stg.[files].[comissCred])
	declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth
	declare @emailList varchar(255)=''

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

    begin try

  begin tran  
	
	delete from dwh2.[finAnalytics].[CommissCred_Monthly] where [repmonth] = @repmonth

	insert into dwh2.[finAnalytics].[CommissCred_Monthly]
	([repmonth], [dognum], [dogSaleDate], [nomenkGroup], [finprod], [client], [dogSum], [restOD], [isCredDogLink], [isMain]
	, [CBName], [usluga], [uslugaSub], [isCredIncl], [isRetrack], [paymentMethod], [beginDate], [endDate], [uslugaPrice]
	, [isPSKIncl], [incomeType], [incomePRC], [incomeAcceptDate], [allPeriod], [periodTilEnd], [periodReject], [paymentType]
	, [paymentPeriod], [rejectDate], [incomeDesperse30], [incomeDesperseAfter], [incomeDesperseDPD], [paymentOD], [clearIncomeSale]
	, [clearIncomeReject], [created])

	select
	[repmonth], [dognum], [dogSaleDate], [nomenkGroup], [finprod], [client], [dogSum], [restOD], [isCredDogLink], [isMain]
	, [CBName], [usluga], [uslugaSub], [isCredIncl], [isRetrack], [paymentMethod], [beginDate], [endDate], [uslugaPrice]
	, [isPSKIncl], [incomeType], [incomePRC], [incomeAcceptDate], [allPeriod], [periodTilEnd], [periodReject], [paymentType]
	, [paymentPeriod], [rejectDate], [incomeDesperse30], [incomeDesperseAfter], [incomeDesperseDPD], [paymentOD], [clearIncomeSale]
	, [clearIncomeReject], [created]
	from(
	select
	[repmonth] = @repmonth
	,[dognum] = [Займ]
	,[dogSaleDate] = [Дата выдачи]
	,[nomenkGroup] = [Номенклатурная группа]
	,[finprod] = [Финансовый продукт]
	,[client] = [Заемщик ФИО]
	,[dogSum] = [Сумма займа]
	,[restOD] = [Остаток ОД]
	,[isCredDogLink] = [Связь с договором займа]
	,[isMain] = [Общее]
	,[CBName] = [Наименование банка россии]
	,[usluga] = [Услуга]
	,[uslugaSub] = [Часть услуги (для составных)]
	,[isCredIncl] = [Включена в сумму займа]
	,[isRetrack] = [Возможность отказа от услуги]
	,[paymentMethod] = [Расчет стоимости услуги]
	,[beginDate] = [Период с]
	,[endDate] = case when try_cast([Период по] as date) is null then null else [Период по] end
	,[uslugaPrice] = [Стоимость услуги (руб# или %)]
	,[isPSKIncl] = [Включение в ПСК]
	,[incomeType] = [Вид дохода]
	,[incomePRC] = [Расчет дохода (%)]
	,[incomeAcceptDate] = [Дата признания дохода от услуги]
	,[allPeriod] = [Общий срок действия для предоставления услуги]
	,[periodTilEnd] = [Остаток срока до окончания услуги]
	,[periodReject] = [Период отказа от услуги]
	,[paymentType] = [Способ оплаты]
	,[paymentPeriod] = [Период оплаты/погашения]
	,[rejectDate] = [Дата отказа от услуги]
	,[incomeDesperse30] = [Распределение дохода при отказе от услуги до 30 дней]
	,[incomeDesperseAfter] =[Распределение после срока охлаждения]
	,[incomeDesperseDPD] = [Распределение дохода при ПДП]
	,[paymentOD] = [Сумма погашений ОД из графика]
	,[clearIncomeSale] = [Чистый доход при продаже]
	,[clearIncomeReject] = [Чистый доход при расторжении]
	,[created]

	from stg.[files].[comissCred]
	) l1

    commit tran
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

	/*Определение наличия данных*/
    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from [finAnalytics].[CommissCred_Monthly]) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID] in (59)

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Отчета по Комиссиям за доп продукты за '
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

	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,3))
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
