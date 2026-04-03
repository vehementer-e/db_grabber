
-- процедура поиска соотвествия значений из таблицы stg.[files].[pbr_monthly] либо stg.[files].[pbr_weekly] с
-- таблицей [dwh2].[finAnalytics].nomenkGroup в столбцах [Номенклатурная группа] и [UMFONames]

CREATE   PROCEDURE [finAnalytics].[loadPBR_zamozanyatCheck]
		@nameData varchar(20)
--@nameData переменная может пренимать значения 'monthly' или 'weekly'

AS
BEGIN
	set @nameData =trim(@nameData)
	declare @procStr nvarchar(300) = null
	declare @Data table(dogNum nvarchar(50), nomenkGroup nvarchar(300), prodFromZayavka nvarchar(300))

	if @nameData='monthly' 

		insert into @Data 
		select
		a.[Номер договора]
		,a.[Номенклатурная группа] 
		,b.подТипКредитногоПродукта
		from stg.[files].[pbr_monthly] a 
		left join dwh2.dm.v_ЗаявкаНаЗаймПодПТС_и_СтатусыИСобытия b on a.[Номер договора]=b.номерзаявки
		where upper(b.подТипКредитногоПродукта) like upper('%самозанят%')
				and a.[Номенклатурная группа]  != b.подТипКредитногоПродукта
			
	if @nameData='weekly' 
		insert into @Data
		select
		a.[Номер договора]
		,a.[Номенклатурная группа] 
		,b.подТипКредитногоПродукта
		from stg.[files].[pbr_weekly] a 
		left join dwh2.dm.v_ЗаявкаНаЗаймПодПТС_и_СтатусыИСобытия b on a.[Номер договора]=b.номерзаявки
		where upper(b.подТипКредитногоПродукта) like upper('%самозанят%')
				and a.[Номенклатурная группа]  != b.подТипКредитногоПродукта

	set @procStr =
				(
				select
					string_agg(nomenkGroup,char(10))
				from @Data
				)

				declare @subject nvarchar(255) = ''
				declare @msg_find nvarchar(255) = ''
				declare @emailList varchar(255)=''

	if @procStr is not null  
		begin
			set @subject = 'Проверка номенклатурных групп в отчете ПБР по Самозанятым.'
			set @msg_find =concat(
						'Коллеги, в ПБР найдены ошибочные номенклатурные группы по займам для Самозанятых:'
						,char(10)
						,char(13)
						,@procStr
						,char(10)
						,char(13)
						,'будет осуществлена замена номенклатурных групп в DWH.')
			
			
			--настройка адресатов рассылки
			set @emailList = (select STRING_AGG(email,';') from [dwh2].[finAnalytics].emailList where emailUID in (1,2,31))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
					,@recipients =@emailList
					,@copy_recipients = ''
					,@body = @msg_find
					,@body_format = 'TEXT'
					,@subject = @subject;
		end

		if @procStr is null  
		begin
			set @subject ='Проверка номенклатурных групп в отчете ПБР по Самозанятым.'
			set @msg_find =concat(
						'В ПБР отсутсвуют ошибочные номенклатурные группы по займам для Самозанятых:'
						,char(10)
						,char(13)
						)
			
			--настройка адресатов рассылки
			set @emailList = (select STRING_AGG(email,';') from [dwh2].[finAnalytics].emailList where emailUID in (1))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
					,@recipients =@emailList
					,@copy_recipients = ''
					,@body = @msg_find
					,@body_format = 'TEXT'
					,@subject = @subject;
		end

END
