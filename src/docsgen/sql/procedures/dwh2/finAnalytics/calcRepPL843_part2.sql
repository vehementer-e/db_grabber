




CREATE PROC [finAnalytics].[calcRepPL843_part2] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. Часть 2.'
    declare @emailList varchar(255)=''
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	begin try
	begin tran  
	
	
/*Очистка таблицы от старых данных за отчетный месяц*/
delete from dwh2.[finAnalytics].[repPLf843_part2] where repmonth = @repmonth

/*Добавление новых данных за отчетный месяц*/
INSERT INTO dwh2.[finAnalytics].[repPLf843_part2]


SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 1
	,[pokazatel] = 'Амортизация ОС и НМА'
	,[symbolName1] = '55301'
	,[symbolName2] = '55303'
	,[amount] = sum([restOUT_BU]) *-1
	,created = getdate()
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth = @repmonth
	and b.[acc1order] like '71%' 
	and simbol5 in ('55301','55303')
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 2
	,[pokazatel] = 'Резервы по пене и госпошлине, всего'
	,[symbolName1] = '522'
	,[symbolName2] = '533'
	,[amount] = sum([restOUT_BU]) *-1
	,created = getdate()
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth = @repmonth
	and b.[acc1order] like '71%' 
	and simbol3 in ('522','533')
	group by a.[repmonth]

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 3
	,[pokazatel] = 'Резервы по пене и госпошлине (мошенники)'
	,[symbolName1] = '522'
	,[symbolName2] = '533'
	,[amount] = sum([restOUT_BU]) *-1
	,created = getdate()
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth = @repmonth
	and b.[accNUM] ='71702810005330400002' 
	and simbol3 in ('522','533')
	group by a.[repmonth]
	
	commit tran
    --финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

	end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой  '
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
