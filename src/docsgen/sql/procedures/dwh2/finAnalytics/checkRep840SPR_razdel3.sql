

CREATE PROCEDURE [finAnalytics].[checkRep840SPR_razdel3] 
    @repmonth date
AS
BEGIN

--	declare @repmonth date ='2024-10-01'

	DECLARE @SPRErrorCount int = 0
	
	/*
	DECLARE @obligacAccResult varchar(300)
    -----Проверка на актуальную дату Справочник аналитических Счетов Облигаций
    declare @obligacAccDate date = (select max(repmonth) from finAnalytics.SPR_obligacACC)
    if (@obligacAccDate < eomonth(@repmonth) or @obligacAccDate is null) 
	begin
	set @SPRErrorCount = @SPRErrorCount +1
	set @obligacAccResult = concat(
									  'Справочник лицевых счетов Облигаций: '
									, 'Ошибка - Дата данных справочника '
									, FORMAT( eomonth(@obligacAccDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	end
	else
	set @obligacAccResult = concat(
									  'Справочник лицевых счетов Облигаций: '
									, 'OK - Дата данных справочника '
									, FORMAT( eomonth(@obligacAccDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	*/

	DECLARE @obligacGraficResult varchar(300)
    -----Проверка на актуальную дату Справочник графиков погашений Облигаций
    declare @obligacGraficDate date = (select max(repmonth) from finAnalytics.SPR_ObligacGrafic)
    if (eomonth(@obligacGraficDate) < eomonth(@repmonth) or @obligacGraficDate is null) 
	begin
	set @SPRErrorCount = @SPRErrorCount +1
	set @obligacGraficResult = concat(
									  'Справочник графиков погашений Облигаций: '
									, 'Ошибка - Дата данных справочника '
									, FORMAT( eomonth(@obligacGraficDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	end
	else
	set @obligacGraficResult = concat(
									  'Справочник графиков погашений Облигаций: '
									, 'OK - Дата данных справочника '
									, FORMAT( eomonth(@obligacGraficDate), 'dd.MM.yyyy', 'ru-RU')
								  )

	DECLARE @arendaResult varchar(300)
    -----Проверка на актуальную дату Справочник Аренды
    declare @arendaDate date = (select max(repmonth) from finAnalytics.SPR_Arenda)
    if (eomonth(@arendaDate) < eomonth(@repmonth) or @arendaDate is null) 
	begin
	set @SPRErrorCount = @SPRErrorCount +1
	set @arendaResult = concat(
									  'Справочник Аренды: '
									, 'Ошибка - Дата данных справочника '
									, FORMAT( eomonth(@arendaDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	end
	else
	set @arendaResult = concat(
									  'Справочник Аренды: '
									, 'OK - Дата данных справочника '
									, FORMAT( eomonth(@arendaDate), 'dd.MM.yyyy', 'ru-RU')
								  )


	DECLARE @bankWOLicenseResult varchar(300)
    -----Проверка на актуальную дату Справочник Банков с отозванной лицензией
    declare @bankWOLicenseDate date = (select max(repmonth) from finAnalytics.SPR_BanksWOLicense)
    if (eomonth(@bankWOLicenseDate) < eomonth(@repmonth) or @bankWOLicenseDate is null) 
	begin
	set @SPRErrorCount = @SPRErrorCount +1
	set @bankWOLicenseResult = concat(
									  'Справочник Банков с отозванной лицензией: '
									, 'Ошибка - Дата данных справочника '
									, FORMAT( eomonth(@bankWOLicenseDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	end
	else
	set @bankWOLicenseResult = concat(
									  'Справочник Банков с отозванной лицензией: '
									, 'OK - Дата данных справочника '
									, FORMAT( eomonth(@bankWOLicenseDate), 'dd.MM.yyyy', 'ru-RU')
								  )

	DECLARE @affilageResult varchar(300)
    -----Проверка на актуальную дату Справочник Аффилированных лиц
    declare @affilageDate date = (select max(repmonth) from finAnalytics.SPR_Affilage)
    if (eomonth(@affilageDate) < eomonth(@repmonth) or @affilageDate is null) 
	begin
	set @SPRErrorCount = @SPRErrorCount +1
	set @affilageResult = concat(
									  'Справочник Аффилированных лиц: '
									, 'Ошибка - Дата данных справочника '
									, FORMAT( eomonth(@affilageDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	end
	else
	set @affilageResult = concat(
									  'Справочник Аффилированных лиц: '
									, 'OK - Дата данных справочника '
									, FORMAT( eomonth(@affilageDate), 'dd.MM.yyyy', 'ru-RU')
								  )
	



		declare @checkResult nvarchar(MAX)
		if @SPRErrorCount =0 
		set @checkResult = 'Проверка Успешна. Ошибок нет'
		else 
		set @checkResult = 'Расчет 3-го раздела отменен. Необходимо актуализировать справочники.'

        declare @body_text2 nvarchar(MAX) = CONCAT(
                                                    'Статус проверки актуальности справочников для расчета 3-го раздела 840 формы: '
                                                    ,char(10)
                                                    ,char(13)
													,'Кол-во ошибок: '
													,@SPRErrorCount 
                                                    /*
													,char(10)
                                                    ,char(13)
                                                    ,@obligacAccResult
													*/
                                                    ,char(10)
                                                    ,char(13)
													,@obligacGraficResult
                                                    ,char(10)
                                                    ,char(13)
													,@arendaResult
                                                    ,char(10)
                                                    ,char(13)
													,@bankWOLicenseResult
                                                    ,char(10)
                                                    ,char(13)
													,@affilageResult
                                                    ,char(10)
                                                    ,char(13)
                                                    ,@checkResult
                                                    )
        declare @subject2  nvarchar(200)  = CONCAT('Актуальность справочников для 3-го раздела 840 на дату расчета: ',FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' ))
		declare @emailList varchar(255)=''
		--настройка адресатов рассылки
		set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,5))
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @body_text2
			,@body_format = 'TEXT'
			,@subject = @subject2;
     
     return @SPRErrorCount



    
END
