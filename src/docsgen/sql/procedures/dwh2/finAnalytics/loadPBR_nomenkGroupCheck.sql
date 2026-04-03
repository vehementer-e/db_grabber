-- процедура поиска соотвествия значений из таблицы stg.[files].[pbr_monthly] либо stg.[files].[pbr_weekly] с
-- таблицей [dwh2].[finAnalytics].nomenkGroup в столбцах [Номенклатурная группа] и [UMFONames]

CREATE   PROCEDURE [finAnalytics].[loadPBR_nomenkGroupCheck]
		@nameData varchar(20)
--@nameData переменная может пренимать значения 'monthly' или 'weekly'
AS
BEGIN

	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc


	set @nameData =trim(@nameData)
	declare @procStr nvarchar(300) = null
	declare @Data table(nomenkGroup nvarchar(300))
	if @nameData='monthly' 
		insert into @Data 
			select distinct nomenkGroup=[Номенклатурная группа] 
			from stg.[files].[pbr_monthly]
			where [Номенклатурная группа] is not null
	if @nameData='weekly' 
		insert into @Data
			select distinct nomenkGroup=[Номенклатурная группа] 
			from stg.[files].[pbr_weekly]
			where [Номенклатурная группа] is not null
		
	set @procStr =
				(
				select
					string_agg(l1.nomenkGroup,char(10))
				from 
					(
						select s.nomenkGroup
						from @Data s
						left join [dwh2].[finAnalytics].nomenkGroup n
						on upper(nomenkGroup)=upper(n.UMFONames)
						where n.UMFONames is null
					) l1
				)
	if @procStr is not null  
		begin
			declare @subject nvarchar(255) ='Найдены новые номенклатурные группы'
			declare @msg_find nvarchar(255) =concat(
						'Коллеги, в ПБР найдены новые номенклатурные группы:'
						,char(10)
						,char(13)
						,@procStr
						,char(10)
						,char(13)
						,'необходимо сообщить: Деткину, Полторан'
						,char(10)
						,char(13)
						,'название Продукта, соответствующего данной группе.')
			declare @emailList varchar(255)=''
			--настройка адресатов рассылки
			set @emailList = (select STRING_AGG(email,';') from [dwh2].[finAnalytics].emailList where emailUID in (1,2,31,34))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
					,@recipients =@emailList
					,@copy_recipients = ''
					,@body = @msg_find
					,@body_format = 'TEXT'
					,@subject = @subject;
		end

		--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc
END
