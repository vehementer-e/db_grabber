CREATE   PROCEDURE [finAnalytics].[loadTermPaiment_Monthly] 
    
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

	declare @repmonthtemp date = (select min(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[TermPaiment_MONTHLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    ----Проверка на ошибки 1
	declare @dogNumsError1 nvarchar(300) = null
	declare @dogNumsError2 nvarchar(300) = null

	set @dogNumsError1 = (	select
			[Номер договора] = STRING_AGG (l2.[Номер договора], ' ; ')
			from(
			select distinct 
			[Номер договора] = l1.[Номер договора]
			from (
			select
			[Номер договора]
			,[Суммы погашения ОД До востребования или на 1 день] = 
										case when try_cast(isnull([Суммы погашения ОД До востребования или на 1 день],0) as float) is not null
										then isnull([Суммы погашения ОД До востребования или на 1 день],0)
										else cast(replace(isnull([Суммы погашения ОД До востребования или на 1 день],0) , ',', '.')  as float) end
			,[Суммы погашения ОД До 30 дней] =
										case when try_cast(isnull([Суммы погашения ОД До 30 дней],0) as float) is not null
										then isnull([Суммы погашения ОД До 30 дней],0)
										else cast(replace(isnull([Суммы погашения ОД До 30 дней],0) , ',', '.')  as float) end
			,[Суммы погашения ОД От 30 дней ≤ 90 дней] = 
										case when try_cast(isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0) as float) is not null
										then isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0)
										else cast(replace(isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end
			,[Суммы погашения ОД От 90 дней ≤ 360 дней] = 
										case when try_cast(isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0) as float) is not null
										then isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0)
										else cast(replace(isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end
			,[Суммы погашения ОД От 360 дней ≤ 1800 дней] = 
										case when try_cast(isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0) as float) is not null
										then isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0)
										else cast(replace(isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end
			,[Суммы погашения ОД От > 1800 дней] = 
										case when try_cast(isnull([Суммы погашения ОД От > 1800 дней],0) as float) is not null
										then isnull([Суммы погашения ОД От > 1800 дней],0)
										else cast(replace(isnull([Суммы погашения ОД От > 1800 дней],0) , ',', '.')  as float) end
			,[Суммы погашения ОД Просроченная часть] = 
										case when try_cast(isnull([Суммы погашения ОД Просроченная часть],0) as float) is not null
										then isnull([Суммы погашения ОД Просроченная часть],0)
										else cast(replace(isnull([Суммы погашения ОД Просроченная часть],0) , ',', '.')  as float) end
			,[Сумма погашения процентов До востребования или на 1 день] = 
										case when try_cast(isnull([Сумма погашения процентов До востребования или на 1 день],0) as float) is not null
										then isnull([Сумма погашения процентов До востребования или на 1 день],0)
										else cast(replace(isnull([Сумма погашения процентов До востребования или на 1 день],0) , ',', '.')  as float) end
			,[Сумма погашения процентов До 30 дней] = 
										case when try_cast(isnull([Сумма погашения процентов До 30 дней],0) as float) is not null
										then isnull([Сумма погашения процентов До 30 дней],0)
										else cast(replace(isnull([Сумма погашения процентов До 30 дней],0) , ',', '.')  as float) end
			,[Сумма погашения процентов От 30 дней ≤ 90 дней] = 
										case when try_cast(isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0) as float) is not null
										then isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0)
										else cast(replace(isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end
			,[Сумма погашения процентов От 90 дней ≤ 360 дней] = 
										case when try_cast(isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0) as float) is not null
										then isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0)
										else cast(replace(isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end
			,[Сумма погашения процентов От 360 дней ≤ 1800 дней] = 
										case when try_cast(isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0) as float) is not null
										then isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0)
										else cast(replace(isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end
			,[Сумма погашения процентов От > 1800 дней] = 
										case when try_cast(isnull([Сумма погашения процентов От > 1800 дней],0) as float) is not null
										then isnull([Сумма погашения процентов От > 1800 дней],0)
										else cast(replace(isnull([Сумма погашения процентов От > 1800 дней],0) , ',', '.')  as float) end
			,[Сумма погашения процентов Просроченная часть] = 
										case when try_cast(isnull([Сумма погашения процентов Просроченная часть],0) as float) is not null
										then isnull([Сумма погашения процентов Просроченная часть],0)
										else cast(replace(isnull([Сумма погашения процентов Просроченная часть],0) , ',', '.')  as float) end
			from stg.[files].[TermPaiment_MONTHLY]
			) l1
			where 

			[Суммы погашения ОД До востребования или на 1 день] <0
			or [Суммы погашения ОД До 30 дней] <0
			or [Суммы погашения ОД От 30 дней ≤ 90 дней] <0
			or [Суммы погашения ОД От 90 дней ≤ 360 дней] <0
			or [Суммы погашения ОД От 360 дней ≤ 1800 дней] <0
			or [Суммы погашения ОД От > 1800 дней] <0
			or [Суммы погашения ОД Просроченная часть] <0
			or [Сумма погашения процентов До востребования или на 1 день] <0
			or [Сумма погашения процентов До 30 дней] <0
			or [Сумма погашения процентов От 30 дней ≤ 90 дней] <0
			or [Сумма погашения процентов От 90 дней ≤ 360 дней] <0
			or [Сумма погашения процентов От 360 дней ≤ 1800 дней] <0
			or [Сумма погашения процентов От > 1800 дней] <0
			or [Сумма погашения процентов Просроченная часть] <0
			) l2
			)
	
	set @dogNumsError2 = (select
						[Номер договора] = STRING_AGG (l2.[Номер договора], ' ; ')
						from(
						select
						*
						from (
						select 
						[Номер договора] = l1.[Номер договора]
						,[Проверка ОД] = round([Остаток ОД в размере остатка на счете]
										- [Суммы погашения ОД До востребования или на 1 день]
										- [Суммы погашения ОД До 30 дней]
										- [Суммы погашения ОД От 30 дней ≤ 90 дней]
										- [Суммы погашения ОД От 90 дней ≤ 360 дней]
										- [Суммы погашения ОД От 360 дней ≤ 1800 дней]
										- [Суммы погашения ОД От > 1800 дней]
										- [Суммы погашения ОД Просроченная часть] ,2)
						,[Проверка Проценты] = round([Остаток % в размере остатка на счете]
												- [Сумма погашения процентов До востребования или на 1 день]
												- [Сумма погашения процентов До 30 дней]
												- [Сумма погашения процентов От 30 дней ≤ 90 дней]
												- [Сумма погашения процентов От 90 дней ≤ 360 дней]
												- [Сумма погашения процентов От 360 дней ≤ 1800 дней]
												- [Сумма погашения процентов От > 1800 дней]
												- [Сумма погашения процентов Просроченная часть],2)

						from (
						select
						[Номер договора]
						, [Остаток ОД в размере остатка на счете] = case when try_cast(isnull([Остаток ОД в размере остатка на счете],0) as float) is not null
											then isnull([Остаток ОД в размере остатка на счете],0)
											else cast(replace(isnull([Остаток ОД в размере остатка на счете],0), ',', '.') as float) end

						 , [Остаток % в размере остатка на счете] = case when try_cast(isnull([Остаток % в размере остатка на счете],0) as float) is not null
												then isnull([Остаток % в размере остатка на счете],0)
												else cast(replace(isnull([Остаток % в размере остатка на счете],0), ',', '.') as float) end
						,[Суммы погашения ОД До востребования или на 1 день] = 
													case when try_cast(isnull([Суммы погашения ОД До востребования или на 1 день],0) as float) is not null
													then isnull([Суммы погашения ОД До востребования или на 1 день],0)
													else cast(replace(isnull([Суммы погашения ОД До востребования или на 1 день],0) , ',', '.')  as float) end
						,[Суммы погашения ОД До 30 дней] =
													case when try_cast(isnull([Суммы погашения ОД До 30 дней],0) as float) is not null
													then isnull([Суммы погашения ОД До 30 дней],0)
													else cast(replace(isnull([Суммы погашения ОД До 30 дней],0) , ',', '.')  as float) end
						,[Суммы погашения ОД От 30 дней ≤ 90 дней] = 
													case when try_cast(isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0) as float) is not null
													then isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0)
													else cast(replace(isnull([Суммы погашения ОД От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end
						,[Суммы погашения ОД От 90 дней ≤ 360 дней] = 
													case when try_cast(isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0) as float) is not null
													then isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0)
													else cast(replace(isnull([Суммы погашения ОД От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end
						,[Суммы погашения ОД От 360 дней ≤ 1800 дней] = 
													case when try_cast(isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0) as float) is not null
													then isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0)
													else cast(replace(isnull([Суммы погашения ОД От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end
						,[Суммы погашения ОД От > 1800 дней] = 
													case when try_cast(isnull([Суммы погашения ОД От > 1800 дней],0) as float) is not null
													then isnull([Суммы погашения ОД От > 1800 дней],0)
													else cast(replace(isnull([Суммы погашения ОД От > 1800 дней],0) , ',', '.')  as float) end
						,[Суммы погашения ОД Просроченная часть] = 
													case when try_cast(isnull([Суммы погашения ОД Просроченная часть],0) as float) is not null
													then isnull([Суммы погашения ОД Просроченная часть],0)
													else cast(replace(isnull([Суммы погашения ОД Просроченная часть],0) , ',', '.')  as float) end
						,[Сумма погашения процентов До востребования или на 1 день] = 
													case when try_cast(isnull([Сумма погашения процентов До востребования или на 1 день],0) as float) is not null
													then isnull([Сумма погашения процентов До востребования или на 1 день],0)
													else cast(replace(isnull([Сумма погашения процентов До востребования или на 1 день],0) , ',', '.')  as float) end
						,[Сумма погашения процентов До 30 дней] = 
													case when try_cast(isnull([Сумма погашения процентов До 30 дней],0) as float) is not null
													then isnull([Сумма погашения процентов До 30 дней],0)
													else cast(replace(isnull([Сумма погашения процентов До 30 дней],0) , ',', '.')  as float) end
						,[Сумма погашения процентов От 30 дней ≤ 90 дней] = 
													case when try_cast(isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0) as float) is not null
													then isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0)
													else cast(replace(isnull([Сумма погашения процентов От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end
						,[Сумма погашения процентов От 90 дней ≤ 360 дней] = 
													case when try_cast(isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0) as float) is not null
													then isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0)
													else cast(replace(isnull([Сумма погашения процентов От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end
						,[Сумма погашения процентов От 360 дней ≤ 1800 дней] = 
													case when try_cast(isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0) as float) is not null
													then isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0)
													else cast(replace(isnull([Сумма погашения процентов От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end
						,[Сумма погашения процентов От > 1800 дней] = 
													case when try_cast(isnull([Сумма погашения процентов От > 1800 дней],0) as float) is not null
													then isnull([Сумма погашения процентов От > 1800 дней],0)
													else cast(replace(isnull([Сумма погашения процентов От > 1800 дней],0) , ',', '.')  as float) end
						,[Сумма погашения процентов Просроченная часть] = 
													case when try_cast(isnull([Сумма погашения процентов Просроченная часть],0) as float) is not null
													then isnull([Сумма погашения процентов Просроченная часть],0)
													else cast(replace(isnull([Сумма погашения процентов Просроченная часть],0) , ',', '.')  as float) end
						from stg.[files].[TermPaiment_MONTHLY]


						) l1
						) l2

						where l2.[Проверка ОД] != 0 or l2.[Проверка Проценты] !=0
						) l2
						)
	if (@dogNumsError1 is not null or @dogNumsError2 is not null)
	begin
	DECLARE @subjectErr NVARCHAR(255) = 'Выявлены ошибки в "Отчет по срокам погашений БУ"'
	DECLARE @msg_checkErr NVARCHAR(2048) = CONCAT (
				'Ошибки проверки Отчета по срокам погашений БУ за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,'Договора с отрицательными суммами погашения: '
                ,@dogNumsError1
                ,char(10)
                ,char(13)
                ,'Договора с нестыковкой сумм с разбивкой: '
                ,@dogNumsError2
                ,char(10)
                ,char(13)
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,4,5))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_checkErr
			,@body_format = 'TEXT'
			,@subject = @subjectErr;

	end

	
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
       
    begin try

    

    delete from finAnalytics.termpayment_MONTHLY where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO finAnalytics.termpayment_MONTHLY
	(
	repMonth, accNum, dogNum, prosBeginDate, dogStatus, prosAll, isBunkrupt, reservOD_BU, reservPRC_BU, reservStavka_BU, lastDatePlatGR1, 
	lastDatePlatGR2, lastDatePlatGR3, lastDatePlatGR4, lastDatePlatGR5, lastDatePlatGR6, restOD_Acc, restPRC_Acc, returnOD_1, returnOD_30, 
	returnOD_90, returnOD_360, returnOD_1800, returnOD_1801, returnOD_pros, returnPRC_1, returnPRC_30, returnPRC_90, returnPRC_360, returnPRC_1800,
	returnPRC_1801, returnPRC_pros, reservOD_BU_1, reservOD_BU_30, reservOD_BU_90, reservOD_BU_360, reservOD_BU_1800, reservOD_BU_1801, reservOD_BU_pros, 
	reservPRC_BU_1, reservPRC_BU_30, reservPRC_BU_90, reservPRC_BU_360, reservPRC_BU_1800, reservPRC_BU_1801, reservPRC_BU_pros, isZamorozkaReserv, 
	isZamorozkaReservDate, isZamorozka1, isZamorozka1Date, isKKEvac, isKKEvacDate, isKK, isKKDate, isKK377, isKK377Date, isKK377Cancel, isKK377CancelDate, 
	dataLoadDate, isProlongPDL, isProlongPDLDate, isKKEvacStop, isKKEvacStopDate, isKKEvacCancel, isKKEvacCancelDate, isKK377Stop, isKK377StopDate, isKK353, 
	isKK353Date, isKK353Stop, isKK353StopDate, isKK353Cancel, isKK353CancelDate, isKKMaxCHPD, isKKMaxCHPDDate
	 )
   
	select
	repMonth, accNum, dogNum, prosBeginDate, dogStatus, prosAll, isBunkrupt, reservOD_BU, reservPRC_BU, reservStavka_BU, lastDatePlatGR1, 
	lastDatePlatGR2, lastDatePlatGR3, lastDatePlatGR4, lastDatePlatGR5, lastDatePlatGR6, restOD_Acc, restPRC_Acc, returnOD_1, returnOD_30, 
	returnOD_90, returnOD_360, returnOD_1800, returnOD_1801, returnOD_pros, returnPRC_1, returnPRC_30, returnPRC_90, returnPRC_360, returnPRC_1800,
	returnPRC_1801, returnPRC_pros, reservOD_BU_1, reservOD_BU_30, reservOD_BU_90, reservOD_BU_360, reservOD_BU_1800, reservOD_BU_1801, reservOD_BU_pros, 
	reservPRC_BU_1, reservPRC_BU_30, reservPRC_BU_90, reservPRC_BU_360, reservPRC_BU_1800, reservPRC_BU_1801, reservPRC_BU_pros, isZamorozkaReserv, 
	isZamorozkaReservDate, isZamorozka1, isZamorozka1Date, isKKEvac, isKKEvacDate, isKK, isKKDate, isKK377, isKK377Date, isKK377Cancel, isKK377CancelDate, 
	dataLoadDate, isProlongPDL, isProlongPDLDate, isKKEvacStop, isKKEvacStopDate, isKKEvacCancel, isKKEvacCancelDate, isKK377Stop, isKK377StopDate, isKK353, 
	isKK353Date, isKK353Stop, isKK353StopDate, isKK353Cancel, isKK353CancelDate, isKKMaxCHPD, isKKMaxCHPDDate
	from(
	select
   REPMONTH = @REPMONTH
 , accNum = a.[Счет аналитического учета]
 , dogNum = a.[Номер договора]
 , prosBeginDate = convert(date,a.[Дата начала просрочки],104)
 , dogStatus = a.[Статус договора]
 , prosAll = isnull(a.[Итого дней просрочки общая],0)
 , isBunkrupt = a.[Банкротство]
 , reservOD_BU = case when try_cast(isnull(a.[Сумма резерва БУ ОД],0) as float) is not null
						then isnull(a.[Сумма резерва БУ ОД],0)
						else cast(replace(isnull(a.[Сумма резерва БУ ОД],0), ',', '.') as float) end

 , reservPRC_BU = case when try_cast(isnull(a.[Сумма резерва БУ проценты],0) as float) is not null
						then isnull(a.[Сумма резерва БУ проценты],0)
						else cast(replace(isnull(a.[Сумма резерва БУ проценты],0), ',', '.') as float) end

 , reservStavka_BU = a.[Ставка резервирования БУ]
 , lastDatePlatGR1 = convert(date,a.[Последняя дата платежа группы 1],104)
 , lastDatePlatGR2 = convert(date,a.[Последняя дата платежа группы 2],104)
 , lastDatePlatGR3 = convert(date,a.[Последняя дата платежа группы 3],104)
 , lastDatePlatGR4 = convert(date,a.[Последняя дата платежа группы 4],104)
 , lastDatePlatGR5 = convert(date,a.[Последняя дата платежа группы 5],104)
 , lastDatePlatGR6 = convert(date,a.[Последняя дата платежа группы 6],104)
 
 , restOD_Acc = case when try_cast(isnull(a.[Остаток ОД в размере остатка на счете],0) as float) is not null
					then isnull(a.[Остаток ОД в размере остатка на счете],0)
					else cast(replace(isnull(a.[Остаток ОД в размере остатка на счете],0), ',', '.') as float) end

 , restPRC_Acc = case when try_cast(isnull(a.[Остаток % в размере остатка на счете],0) as float) is not null
						then isnull(a.[Остаток % в размере остатка на счете],0)
						else cast(replace(isnull(a.[Остаток % в размере остатка на счете],0), ',', '.') as float) end
 
 , returnOD_1 = case when try_cast(isnull(a.[Суммы погашения ОД До востребования или на 1 день],0) as float) is not null
						then isnull(a.[Суммы погашения ОД До востребования или на 1 день],0)
						else cast(replace(isnull(a.[Суммы погашения ОД До востребования или на 1 день],0), ',', '.') as float) end

 , returnOD_30 = case when try_cast(isnull(a.[Суммы погашения ОД До 30 дней],0) as float) is not null
						then isnull(a.[Суммы погашения ОД До 30 дней],0)
						else cast(replace(isnull(a.[Суммы погашения ОД До 30 дней],0) , ',', '.')  as float) end

 , returnOD_90 = case when try_cast(isnull(a.[Суммы погашения ОД От 30 дней ≤ 90 дней],0) as float) is not null
						then isnull(a.[Суммы погашения ОД От 30 дней ≤ 90 дней],0)
						else cast(replace(isnull(a.[Суммы погашения ОД От 30 дней ≤ 90 дней],0) , ',', '.') as float) end

 , returnOD_360 = case when try_cast(isnull(a.[Суммы погашения ОД От 90 дней ≤ 360 дней],0) as float) is not null
						then isnull(a.[Суммы погашения ОД От 90 дней ≤ 360 дней],0)
						else cast(replace(isnull(a.[Суммы погашения ОД От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end

 , returnOD_1800 = case when try_cast(isnull(a.[Суммы погашения ОД От 360 дней ≤ 1800 дней],0) as float) is not null
							then isnull(a.[Суммы погашения ОД От 360 дней ≤ 1800 дней],0)
							else cast(replace(isnull(a.[Суммы погашения ОД От 360 дней ≤ 1800 дней],0), ',', '.')  as float) end

 , returnOD_1801 = case when try_cast(isnull(a.[Суммы погашения ОД От > 1800 дней],0) as float) is not null
						then isnull(a.[Суммы погашения ОД От > 1800 дней],0)
						else cast(replace(isnull(a.[Суммы погашения ОД От > 1800 дней],0) , ',', '.')  as float) end

 , returnOD_pros = case when try_cast(isnull(a.[Суммы погашения ОД Просроченная часть],0) as float) is not null
						then isnull(a.[Суммы погашения ОД Просроченная часть],0)
						else cast(replace(isnull(a.[Суммы погашения ОД Просроченная часть],0) , ',', '.')  as float) end
 
 , returnPRC_1 = case when try_cast(isnull(a.[Сумма погашения процентов До востребования или на 1 день],0) as float) is not null
						then isnull(a.[Сумма погашения процентов До востребования или на 1 день],0)
						else cast(replace(isnull(a.[Сумма погашения процентов До востребования или на 1 день],0)  , ',', '.')  as float) end

 , returnPRC_30 = case when try_cast(isnull(a.[Сумма погашения процентов До 30 дней],0) as float) is not null
						then isnull(a.[Сумма погашения процентов До 30 дней],0)
						else cast(replace(isnull(a.[Сумма погашения процентов До 30 дней],0)  , ',', '.')  as float) end

 , returnPRC_90 = case when try_cast(isnull(a.[Сумма погашения процентов От 30 дней ≤ 90 дней],0) as float) is not null
						then isnull(a.[Сумма погашения процентов От 30 дней ≤ 90 дней],0)
						else cast(replace(isnull(a.[Сумма погашения процентов От 30 дней ≤ 90 дней],0)  , ',', '.')  as float) end

 , returnPRC_360 = case when try_cast(isnull(a.[Сумма погашения процентов От 90 дней ≤ 360 дней],0) as float) is not null
						then isnull(a.[Сумма погашения процентов От 90 дней ≤ 360 дней],0)
						else cast(replace(isnull(a.[Сумма погашения процентов От 90 дней ≤ 360 дней],0)  , ',', '.')  as float) end

 , returnPRC_1800 = case when try_cast(isnull(a.[Сумма погашения процентов От 360 дней ≤ 1800 дней],0) as float) is not null
							then isnull(a.[Сумма погашения процентов От 360 дней ≤ 1800 дней],0)
							else cast(replace(isnull(a.[Сумма погашения процентов От 360 дней ≤ 1800 дней],0)  , ',', '.')  as float) end

 , returnPRC_1801 = case when try_cast(isnull(a.[Сумма погашения процентов От > 1800 дней],0) as float) is not null
							then isnull(a.[Сумма погашения процентов От > 1800 дней],0)
							else cast(replace(isnull(a.[Сумма погашения процентов От > 1800 дней],0) , ',', '.')  as float) end

 , returnPRC_pros = case when try_cast(isnull(a.[Сумма погашения процентов Просроченная часть],0) as float) is not null
							then isnull(a.[Сумма погашения процентов Просроченная часть],0)
							else cast(replace(isnull(a.[Сумма погашения процентов Просроченная часть],0) , ',', '.')  as float) end
 
 , reservOD_BU_1 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД До востребования или на 1 день],0) as float) is not null
						then isnull(a.[Сумма резерва БУ по суммам ОД До востребования или на 1 день],0)
						else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД До востребования или на 1 день],0) , ',', '.')  as float) end

 , reservOD_BU_30 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД До 30 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД До 30 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД До 30 дней],0) , ',', '.')  as float) end

 , reservOD_BU_90 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД От 30 дней ≤ 90 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД От 30 дней ≤ 90 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end

 , reservOD_BU_360 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД От 90 дней ≤ 360 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД От 90 дней ≤ 360 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end

 , reservOD_BU_1800 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД От 360 дней ≤ 1800 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД От 360 дней ≤ 1800 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end

 , reservOD_BU_1801 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД От > 1800 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД От > 1800 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД От > 1800 дней],0) , ',', '.')  as float) end
 
 , reservOD_BU_pros = case when try_cast(isnull(a.[Сумма резерва БУ по суммам ОД Просроченная часть],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам ОД Просроченная часть],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам ОД Просроченная часть],0) , ',', '.')  as float) end
 
 , reservPRC_BU_1 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов До востребования или на 1 д],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам процентов До востребования или на 1 д],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов До востребования или на 1 д],0) , ',', '.')  as float) end

 , reservPRC_BU_30 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов До 30 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам процентов До 30 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов До 30 дней],0) , ',', '.')  as float) end

 , reservPRC_BU_90 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов От 30 дней ≤ 90 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам процентов От 30 дней ≤ 90 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов От 30 дней ≤ 90 дней],0) , ',', '.')  as float) end

 , reservPRC_BU_360 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов От 90 дней ≤ 360 дней],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам процентов От 90 дней ≤ 360 дней],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов От 90 дней ≤ 360 дней],0) , ',', '.')  as float) end

 , reservPRC_BU_1800 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов От 360 дней ≤ 1800 дней],0) as float) is not null
								then isnull(a.[Сумма резерва БУ по суммам процентов От 360 дней ≤ 1800 дней],0)
								else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов От 360 дней ≤ 1800 дней],0) , ',', '.')  as float) end

 , reservPRC_BU_1801 = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов От > 1800 дней],0) as float) is not null
								then isnull(a.[Сумма резерва БУ по суммам процентов От > 1800 дней],0)
								else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов От > 1800 дней],0) , ',', '.')  as float) end
 
 , reservPRC_BU_pros = case when try_cast(isnull(a.[Сумма резерва БУ по суммам процентов Просроченная часть],0) as float) is not null
							then isnull(a.[Сумма резерва БУ по суммам процентов Просроченная часть],0)
							else cast(replace(isnull(a.[Сумма резерва БУ по суммам процентов Просроченная часть],0) , ',', '.')  as float) end

 , isZamorozkaReserv = a.[Заморозка (для резервов 30#06#21)]
 , isZamorozkaReservDate = convert(date,a.[Дата ДС],104)
 , isZamorozka1 = a.[Заморозка 1#0]
 , isZamorozka1Date = convert(date,a.[Дата ДС1],104)
 , isKKEvac = a.[КК по эвакуированным/ЧС (ФЗ-106)]
 , isKKEvacDate = convert(date,a.[Дата ДС3],104)
 , [isKKEvacStop] = a.[Остановка КК по эвакуированным/ЧС (ФЗ-106)]
 , [isKKEvacStopDate] = convert(date,a.[Дата ДС4],104)
 , [isKKEvacCancel] = a.[Отмена КК по эвакуированным/ЧС (ФЗ-106)]
 , [isKKEvacCancelDate] = convert(date,a.[Дата ДС5],104)
 , isKK = a.[Кредитные каникулы]
 , isKKDate = convert(date,a.[Дата ДС6],104)
 , isKK377 = a.[Кредитные каникулы по 377-ФЗ]
 , isKK377Date = convert(date,a.[Дата ДС7],104)
 , [isKK377Stop] = a.[Остановка Кредитных каникул по 377-ФЗ]
 , [isKK377StopDate] = convert(date,a.[Дата ДС8],104)
 , isKK377Cancel = a.[Отмена Кредитных каникул по 377-ФЗ]
 , isKK377CancelDate = convert(date,a.[Дата ДС9],104)

 , dataLoadDate = a.created

 , [isProlongPDL] = a.[Пролонгация PDL]
 , [isProlongPDLDate] = convert(date,a.[Дата ДС2],104) 
 , [isKK353] = a.[Кредитные каникулы по 353-ФЗ]
 , [isKK353Date] =  convert(date,a.[Дата ДС10],104)
 , [isKK353Stop] = a.[Остановка Кредитных каникул по 353-ФЗ]
 , [isKK353StopDate] = convert(date,a.[Дата ДС11],104)
 , [isKK353Cancel] = a.[Отмена Кредитных каникул по 353-ФЗ]
 , [isKK353CancelDate] = convert(date,a.[Дата ДС12],104)
 , [isKKMaxCHPD] = a.[Завершение КК# Максимальное ЧДП]
 , [isKKMaxCHPDDate] =  convert(date,a.[Дата ДС13],104)
 
 from stg.[files].[TermPaiment_MONTHLY] a
 ) l1
    
    
    commit tran
    
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.termpayment_MONTHLY) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 15

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Отчета по срокам погашений БУ за '
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

	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
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
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2))
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
