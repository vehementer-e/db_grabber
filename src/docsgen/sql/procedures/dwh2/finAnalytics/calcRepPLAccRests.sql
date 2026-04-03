

CREATE PROC [finAnalytics].[calcRepPLAccRests] 
    @repmonth date
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
       
  begin try
  	--Проверка на новые счета
	merge INTO dwh2.finanalytics.SPR_PL_ACC t1
	using(
	select
	[accNUM] = l1.accNum
	, [is840calc] = null
	, [isDeclaracCalc] = null
	, [acc1order] = substring(l1.accNum,1,3)
	, [acc2order] = substring(l1.accNum,1,5)
	, [simbol3] = substring(l1.accNum,11,3)
	, [simbol5] = substring(l1.accNum,11,5)
	, [isNeedCheck] = case when substring(l1.accNum,1,3) in 
												(
												'710'
												,'711'
												,'712'
												,'715'
												,'716'
												,'717'
												,'718'
												) then  1 else 0 end
	from(
	select
	distinct accNum
	from dwh2.[finAnalytics].[OSV_MONTHLY] a
	where a.repmonth = @repmonth
	and (substring(a.acc2order,1,3) in
					('106'
					,'109'
					,'710'
					,'711'
					,'712'
					,'715'
					,'716'
					,'717'
					,'718'
					,'719'
					,'720'
					,'721'
					,'722'
					,'725'
					,'726'
					,'727'
					,'728'
					,'729'
					)
		/*Добавление отдельных счетов для анализа*/
		or a.accNum in (
						 '60305810000000000002'
						,'60305810000000000000'
						,'60335810000000000010'
						,'60335810000000000014'
						)
						)
				
	) l1
	) t2 on (t1.[accNUM]=t2.[accNUM])

	when matched then update
		set t1.[isNew] = 'Нет'

	when not matched then insert
	([accNUM], [is840calc], [isDeclaracCalc], [acc1order], [acc2order], [simbol3], [simbol5], [isNeedCheck], [created], [isNew])
	values
	(t2.[accNUM]
	, t2.[is840calc]
	, t2.[isDeclaracCalc]
	, t2.[acc1order]
	, t2.[acc2order]
	, t2.[simbol3]
	, t2.[simbol5]
	, t2.[isNeedCheck] 
	, cast(getdate() as date)
	, 'Да');

	declare @newAcc varchar(300) = null
	set @newAcc = (
	select
	STRING_AGG(accNum,' ; ')
	from dwh2.[finAnalytics].[SPR_PL_ACC]
	where isNew = 'Да'
	and isNeedCheck = 1
	)

	if @newAcc is not null 
	begin
	DECLARE @subject NVARCHAR(2048) = 'Новые счета для контроля отчета PL для публикуемой'
	DECLARE @msg_newAcc NVARCHAR(2048) = CONCAT (
				'При расчете данных для отчет PL для публикуемой найдены новые счета 710 - 718'
                ,char(10)
                ,char(13)
				,'за отчетный месяц: '
				,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
				,char(10)
                ,char(13)
                ,'Список счетов: '
                ,@newAcc
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_newAcc
			,@body_format = 'TEXT'
			,@subject = @subject;

	/*Сохраняем новые найденные счета*/
	UPDATE dwh2.[finAnalytics].[SPR_PL_ACC]
	set isNew = 'Нет'
	where isNew = 'Да'

	end

	begin tran  

    --Очистка таблицы результата за отчетный месяц
    DELETE FROM dwh2.[finAnalytics].[repPLAccRests] where repmonth = @repmonth

	INSERT INTO dwh2.[finAnalytics].[repPLAccRests]
	select
	[repmonth] = a.repmonth 
	,[accUID] = acc.id
	,restIN_BU = sum(isnull(restIN_BU,0))
	,restIN_NU = sum(isnull(restIN_NU,0))	
	,sumDT_BU = sum(isnull(sumDT_BU,0))
	,sumDT_NU = sum(isnull(sumDT_NU,0))
	,sumKT_BU = sum(isnull(sumKT_BU,0))
	,sumKT_NU = sum(isnull(sumKT_NU,0))
	,restOUT_BU = sum(isnull(restOUT_BU,0))
	,restOUT_NU = sum(isnull(restOUT_NU,0))

	from dwh2.[finAnalytics].[OSV_MONTHLY] a
	inner join dwh2.[finAnalytics].SPR_PL_ACC acc on a.accNum=acc.accNum
	where a.repmonth = @repmonth

	group by
	a.repmonth 
	,acc.id
    
commit tran
    /*
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 3
	*/

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой '
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
