


CREATE PROC [finAnalytics].[updatePBI] 
    @repNum int
	--0 все
	--1 Отчет по ПДН месячный
	--2 Остановка начисления Процентов
	--3 Отчет Резервы ОД для руководства
	--4 Отчет по продажам
	--5 Отчет по Цессии
	--6 Отчет по ДАППам
AS
BEGIN

Declare @repID nvarchar(max)='' 
Declare @repName nvarchar(300)='' 
Declare @refreshResult nvarchar(300)=''

DECLARE @subject NVARCHAR(255)=''
declare @emailList varchar(255)=''
DECLARE	@return_value int
DECLARE @msg_good NVARCHAR(max)=''

--------1----------
if @repNum = 0 or @repnum = 1
begin

set @repID = '6d5ed7ad-0727-4303-9213-7a29e3724874'
set @repName = 'Отчет по ПДН месячный'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 0

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end

--------2----------
if @repNum = 0 or @repnum = 2
begin
set @repID = 'e5c59e3f-d9ee-46a9-b496-1779c0536a04'
set @repName = 'Остановка начисления Процентов'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 0

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end

--------3----------
if @repNum = 0 or @repnum = 3
begin
set @repID = '83078029-5ad5-4512-aad5-76bb01802f19'
set @repName = 'Отчет Резервы ОД для руководства'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 0

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end


--------4----------
if @repNum = 0 or @repnum = 4
begin
set @repID = '1c86260a-374b-4667-b58d-ad00151bf457'
set @repName = 'Отчет по продажам'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 0

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end

--------5----------
if @repNum = 0 or @repnum = 5
begin
set @repID = 'fbae8ff5-bea2-4aa9-9e07-44827c151105'
set @repName = 'Отчет по Цессии'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 1

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end

--------6----------
if @repNum = 0 or @repnum = 6
begin
set @repID = '42968432-c739-4d19-9425-e5159ed7ce7f'
set @repName = 'Отчет по ДАППам'
set @subject = CONCAT (
				'Обновление данных отчета PBI: '
				,@repName
				)
EXEC @return_value = [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
@subscription_id = @repID,
@await_success = 1

set @msg_good = CONCAT (
				'Обновление данных отчета начато. Результат проверить в BI.'
                ,@repName
                ,char(10)
                ,char(13)
				,@return_value
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from dwh2.finAnalytics.emailList where emailUID in (1/*,2*/))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
end

END
