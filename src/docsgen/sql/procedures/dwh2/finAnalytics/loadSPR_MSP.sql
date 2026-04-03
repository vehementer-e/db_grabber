




CREATE PROCEDURE [finAnalytics].[loadSPR_MSP] 
    
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

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры загрузки справочника МСП'
       
    begin try
	begin tran  

		/*добавление данных из Excel файла с сайта налоговой в DWH*/
		merge into dwh2.finAnalytics.MSP_reestr t1
		using (

		select 
		inn = a.[ИНН]
		,client = b.client--[Наименование / ФИО]
		,isZaemshik = b.isZaemshik--[Тип субъекта]
		,reestrInDate = convert(date,a.[Дата включения в реестр],104)
		,reestrOutDate = convert(date,a.[Дата исключения из реестра],104)
		,category = Категория
		,loadDate = a.created

		from stg.[files].[msp_reestr] a
		left join(
		select
		Client
		,isZaemshik
		,inn
		from(
		select
		Client
		,isZaemshik
		,inn
		,rn = row_Number() over (Partition by inn order by repmonth desc)
		from dwh2.finAnalytics.PBR_MONTHLY b
		where isZaemshik != 'ФЛ'
		) l1
		where l1.rn=1
		) b on a.[ИНН] = b.inn

		) t2 on (t1.inn=t2.inn and t1.reestrInDate=t2.reestrInDate)
		when matched then update
		set t1.reestrOutDate=t2.reestrOutDate,
			t1.loadDate= t2.loadDate
		when not matched then insert
		(client, isZaemshik, INN, reestrInDate, reestrOutDate, loadDate, category)
		values
		(t2.client, t2.isZaemshik, t2.INN, t2.reestrInDate, t2.reestrOutDate, t2.loadDate , t2.category);

		/*Обновление данных ПБР месячный*/
		merge into finAnalytics.PBR_MONTHLY t1
		using(
		--select
		--a.ID
		--,a.REPMONTH
		--,a.saleDate
		--,b.reestrInDate
		--,b.reestrOutDate
		--,a.dogNum
		--,a.Client
		--,a.isMSP
		--,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		--,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		--from finAnalytics.PBR_MONTHLY a
		--inner join finAnalytics.MSP_reestr b on 
		--										a.INN=b.INN 
		--										and upper(a.isZaemshik) != 'ФЛ'
		--										and EOMONTH(a.repmonth) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth))
		select
		a.ID
		,a.REPMONTH
		,a.saleDate
		,b1.reestrInDate
		,b1.reestrOutDate
		,a.dogNum
		,a.Client
		,a.isMSP
		,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		from finAnalytics.PBR_MONTHLY a
		left join finAnalytics.MSP_reestr b1 on 
												a.INN=b1.INN 
												and EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth))
		left join finAnalytics.MSP_reestr b2 on 
												a.INN=b2.INN 
												and a.saleDate between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth))
		where 1=1 --a.INN = '690706648816'
		and upper(a.isZaemshik) != 'ФЛ'
		--order by a.REPMONTH
		) t2 on (t1.id=t2.id)
		when matched then update
		set
		t1.isMSPbyDogDate=t2.isMSPbyDogDate,
		t1.isMSPbyRepDate=t2.isMSPbyRepDate;

		/*Обновление данных ПБР недельный*/
		merge into finAnalytics.PBR_weekly t1
		using(
		--select
		--a.ID
		--,a.REPdate
		--,a.saleDate
		--,b.reestrInDate
		--,b.reestrOutDate
		--,a.dogNum
		--,a.Client
		--,a.isMSP
		--,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b.reestrInDate and isnull(b.reestrOutDate,cast(getdate() as date)) then 'Да' else 'Нет' end
		--,isMSPbyRepDate = case when EOMONTH(a.repdate) between b.reestrInDate and isnull(b.reestrOutDate,cast(getdate() as date)) then 'Да' else 'Нет' end
		--from finAnalytics.PBR_weekly a
		--inner join finAnalytics.MSP_reestr b on 
		--										a.INN=b.INN 
		--										and upper(a.isZaemshik) != 'ФЛ'
		--										and EOMONTH(a.repdate) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repdate))
		select
		a.ID
		,a.REPMONTH
		,a.saleDate
		,b1.reestrInDate
		,b1.reestrOutDate
		,a.dogNum
		,a.Client
		,a.isMSP
		,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		from finAnalytics.PBR_MONTHLY a
		left join finAnalytics.MSP_reestr b1 on 
												a.INN=b1.INN 
												and EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth))
		left join finAnalytics.MSP_reestr b2 on 
												a.INN=b2.INN 
												and a.saleDate between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth))
		where 1=1--a.INN = '690706648816'
		and upper(a.isZaemshik) != 'ФЛ'
		--order by a.REPMONTH
		) t2 on (t1.id=t2.id)
		when matched then update
		set
		t1.isMSPbyDogDate=t2.isMSPbyDogDate,
		t1.isMSPbyRepDate=t2.isMSPbyRepDate;

		DECLARE @maxDateRest NVARCHAR(30)
		set @maxDateRest = (select max(loadDate) from finAnalytics.MSP_reestr)--format((select max(loadDate) from finAnalytics.MSP_reestr) ,'dd.MM.yyyy', 'ru-RU')
		--select @maxDateRest 
		/*Фиксация времени расчета*/
		update dwh2.[finAnalytics].[reportReglament]
		set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
		where [reportUID]  in (36)

    commit tran
	
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    
    
    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Справочника МСП.'
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
                ,'Дата обработки: '
                ,@maxDateRest
				,char(10)
                ,char(13)
				,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,(select link from finAnalytics.SYS_SPR_linkReport where repName='Реестр МСП')
				)

 	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,4))
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
