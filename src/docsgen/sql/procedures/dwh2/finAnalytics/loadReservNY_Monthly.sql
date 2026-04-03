
CREATE PROCEDURE [finAnalytics].[loadReservNY_Monthly] 
    
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

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
    
    DECLARE @MSPCheck varchar(MAX) = ''

    set @MSPCheck =(
    select
    [dogError] = STRING_AGG(l2.[Номер договора],', ')
    
    from(
    select
    l1.*

    ,[checkMSP] = case when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
           and l1.[Группа займа (обеспеченный, необеспеченный)] not like '%субъекту малого и среднего%' then 'Ошибка'
          when l1.[Отчетная дата] not between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
           and l1.[Группа займа (обеспеченный, необеспеченный)] like '%субъекту малого и среднего%' then 'Ошибка'
        else 'ОК' end

    from(
    select
    [Отчетная дата] = convert(date, a.[Отчетная дата],104)
    ,a.[Номер договора]
    ,a.[Наименование заемщика]
    ,a.[Группа займа (обеспеченный, необеспеченный)]
    ,b.reestrInDate
    ,b.reestrOutDate

    from stg.[files].[ReservNU_MONTHLY] a
    inner join finAnalytics.MSP_reestr b on a.[Наименование заемщика]=b.client

    --where 1=1
    ) l1
    ) l2
    where l2.checkMSP='Ошибка' 
    )

    if @MSPCheck is not null 
    begin
        DECLARE @MSPCheck_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры загрузки Резервов НУ - есть расхождения с Реестром МСП по договорам: '
				,char(10)
                ,char(13)
                ,@MSPCheck
                ,char(10)
                ,char(13)
                ,'Произведена замена групп.'
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,4))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
			    ,@copy_recipients = ''
			    ,@body = @MSPCheck_bad
			    ,@body_format = 'TEXT'
			    ,@subject = @subject;
    /*  ---Не прерываем загрузку - в процессе загрузки будет подмена групп    
        throw 51000 
			    ,@MSPCheck_bad
			    ,1;
    */
    end

    begin try

    declare @repmonthtemp date = (select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[ReservNU_MONTHLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    delete from [finAnalytics].Reserv_NU where REPMONTH=@repmonth

  begin tran  
    
    INSERT INTO [finAnalytics].Reserv_NU
	(
	 REPMONTH, dogNum, isRestrukt, isRefinance, isBunkrupt, clientType, zaymType, client, nomenklGroup, 
     isAkcia0, restAll, restOD, restPRC, restPenia, restGosposhl, srokDolg, historicPros, allPros, zaymGroup, 
     untervalName, reservPRC, reservSum, sumOD, sumPRC, sumPenia, reservADD, reservDelete, dataLoadDate, PSK_prc,
	 isNotTarget
	 )
     

	select
   REPMONTH = @REPMONTH
 , dogNum = a.[Номер договора]
 , isRestrukt = isnull(a.[ Признак  реструктуризации договора],'-')
 , isRefinance = isnull(a.[ Признак  рефинансирования договора],'-')
 , isBunkrupt = isnull(b.isBankrupt,'Нет')
 , clientType = isnull(b.isZaemshik,'ФЛ')
 , zaymType = case when substring(b.AccODNum,1,5) = '48501' THEN 'Займ' else 'Микрозайм' end 
 , client = a.[Наименование заемщика]
 , nomenklGroup = a.[Номенклатурная группа]
 , isAkcia0 = a.[Акция 0%]
 , restAll = isnull(a.[Сумма задолженности по микрозайму, всего (руб# коп#)],0)
 , restOD = isnull(a.[Сумма основного долга на отчетную дату],0)
 , restPRC = isnull(a.[Сумма требований по начисленным процентнам на отчетную дату],0)
 , restPenia = isnull(a.[Сумма пени на отчетную дату],0)
 , restGosposhl = isnull(a.[Сумма госпошлины на отчетную дату],0)
 , srokDolg = cast(isnull(a.[Срок  задолженности  (дней)],0) as int)
 , historicPros = cast(isnull(a.[Историческая просрочка_ (дней)],0) as int)
 , allPros = case when cast(isnull(a.[Сумма основного долга на отчетную дату],0) as money)=0 
                   and cast(isnull(a.[Сумма требований по начисленным процентнам на отчетную дату],0) as money)=0 
                   and cast(isnull(a.[Сумма пени на отчетную дату],0) as money)=0 
                   and cast(isnull(a.[Сумма госпошлины на отчетную дату],0) as money)!=0 
                   and cast(isnull(a.[Итого дней просрочки],0) as int)=0 
                  then abs(DATEDIFF(day,EOMONTH(@repmonth),r60323.prosDateBegin))
                  else cast(isnull(a.[Итого дней просрочки],0) as int) end
 --Корректировка группы займа при контроле МСП
 , zaymGroup = case when upGr.dogNum is not null then upGr.correctZaimGroup else a.[Группа займа (обеспеченный, необеспеченный)] end
 , untervalName = a.[Наименование интервала в соответствии с 4054-у]
 , reservPRC = isnull(a.[Резерв  на возможные потери (%)],0)
 , reservSum = isnull(a.[Всего Сумма резерва на возможные потери  по состоянию на конец п],0)
 , sumOD = isnull(a.[Основной долг Сумма резерва на возможные потери  по состоянию на],0)
 , sumPRC = isnull(a.[Проценты начисленные Сумма резерва на возможные потери  по состо],0)
 , sumPenia = isnull(a.[Пени Сумма резерва на возможные потери  по состоянию на конец пе],0)
 , reservADD = cast(isnull(a.[Создание резерва на возможные потери],0) as money)
 , reservDelete = cast(isnull(a.[Восстановление  резерва на возможные потери],0) as money)
 , dataLoadDate = created
 , PSK_prc = cast(isnull(a.[ПСК для РВПЗ],0) as float)
 ,isNotTarget = a.[Признак использование не по целевому назначению]

 from stg.[files].[ReservNU_MONTHLY] a
 
 left join (
 select
    a.dogNum
    ,a.isZaemshik
    ,a.isBankrupt
    ,AccODNum
    ,row_number() over (Partition by a.dogNum order by a.repmonth desc) rn
 from finAnalytics.PBR_MONTHLY a
 Where a.REPMONTH<=@repmonth
 ) b on a.[Номер договора]=b.dogNum and b.rn=1

 left join (
 select
    [dogNum] = l1.[Номер договора]
    ,[zaymGroup] = l1.[Группа займа (обеспеченный, необеспеченный)]
    ,[correctZaimGroup] = case --Если относится к МСП
                                 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ индивидуальному предпринимателю необеспеченный') then 'Займ субъекту малого и среднего предпринимательства необеспеченный'
                                 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ индивидуальному предпринимателю обеспеченный') then 'Займ субъекту малого и среднего предпринимательства обеспеченный'
                                 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ юридическому лицу необеспеченный') then 'Займ субъекту малого и среднего предпринимательства необеспеченный'
                                 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ юридическому лицу обеспеченный') then 'Займ субъекту малого и среднего предпринимательства обеспеченный'
    							 
								 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ физическому лицу необеспеченный') 
									and  upper(l1.[isZaemshik]) = 'ИП' then 'Займ субъекту малого и среднего предпринимательства необеспеченный'
								 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ физическому лицу обеспеченный')  
									and  upper(l1.[isZaemshik]) = 'ИП' then 'Займ субъекту малого и среднего предпринимательства обеспеченный'
								 /*
								 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ физическому лицу необеспеченный') 
									then 'Займ субъекту малого и среднего предпринимательства необеспеченный'
								 when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ физическому лицу обеспеченный')  
									then 'Займ субъекту малого и среднего предпринимательства обеспеченный'
								*/
                                 --Если не относится к МСП
                                 when l1.[Отчетная дата] not between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ субъекту малого и среднего предпринимательства необеспеченный') then 'Займ индивидуальному предпринимателю необеспеченный'
                                 when l1.[Отчетная дата] not between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
                                    and upper(l1.[Группа займа (обеспеченный, необеспеченный)]) = upper('Займ субъекту малого и среднего предпринимательства обеспеченный') then 'Займ индивидуальному предпринимателю обеспеченный'
                            else l1.[Группа займа (обеспеченный, необеспеченный)]
                            end
                            
    ,[checkMSP] = case when l1.[Отчетная дата] between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
           and l1.[Группа займа (обеспеченный, необеспеченный)] not like '%субъекту малого и среднего%' then 'Ошибка'
          when l1.[Отчетная дата] not between l1.reestrInDate and isnull(l1.reestrOutDate,cast(getdate() as date)) 
           and l1.[Группа займа (обеспеченный, необеспеченный)] like '%субъекту малого и среднего%' then 'Ошибка'
        else 'ОК' end
    from(
    select
    [Отчетная дата] = convert(date, a.[Отчетная дата],104)
    ,a.[Номер договора]
    ,a.[Наименование заемщика]
    ,a.[Группа займа (обеспеченный, необеспеченный)]
    ,b.reestrInDate
    ,b.reestrOutDate
	,c.isZaemshik
    from stg.[files].[ReservNU_MONTHLY] a
    inner join finAnalytics.MSP_reestr b on a.[Наименование заемщика]=b.client
	left join dwh2.finAnalytics.PBR_MONTHLY c on a.[Номер договора] = c.dogNum and c.REPMONTH = @repmonth

    --where 1=1
    
    ) l1
 ) upGr on a.[Номер договора]=upGr.dogNum and upGr.checkMSP='Ошибка'
 
 left join (
        select
        a.repMonth
        ,a.dogNum
        ,prosDateBegin = min(a.prosDateBegin)
        from finAnalytics.rests60323 a
        --where dogNum='17102010380001'
        group by a.repMonth
        ,a.dogNum
    ) r60323 on a.[Номер договора]=r60323.dogNum and r60323.repmonth=@repmonth

	/* отменено с 25.09.2025
	-----------Добавление данных по ПСК от Рисков
	select 
	q1.external_id
	,q1.ПСК as psk_int

	into #stg_psk

	from(
	select
	d.код AS external_id
	, p.Период
	, p.ПСК
	, row_number() over (partition by d.код order by p.Период) rnn
	from stg._1cCMR.Справочник_Договоры d
	inner join stg._1cCMR.РегистрСведений_ИнформацияПоДоговору as p on d.Ссылка = p.Договор
	) q1

	where rnn = 1

	merge into finAnalytics.Reserv_NU t1
	using
	(
	select 
	external_id
	,psk_int
	from #stg_psk
	) t2 on (t1.dogNum=t2.external_id and t1.repmonth=@repmonth)

	when matched then update
	set t1.PSK_prc = t2.psk_int;
	-----------------------
	*/
    
    commit tran
    
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.PBR_MONTHLY ) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 17

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка Резервы НУ за '
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
