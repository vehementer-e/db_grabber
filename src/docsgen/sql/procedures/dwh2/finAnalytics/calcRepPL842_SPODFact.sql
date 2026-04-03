




CREATE PROC [finAnalytics].[calcRepPL842_SPODFact] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных СПОД для 842'
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
	
	declare @repdateFrom date = dateFromParts(year(@repmonth),1,1)
	declare @repdateTo date = dateFromParts(year(@repmonth),12,1)

	declare @dateFrom datetime = dateadd(year,2000,@repdateFrom)
	declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repdateTo)))
	declare @dateTo datetime = dateadd(second,-1,@dateToTmp)

	declare @accList table (
		rowName nvarchar(10),
		acc2order nvarchar(5)
			)
	INSERT INTO @accList values ('12.1','60329')
	INSERT INTO @accList values ('19.1','60328')
	INSERT INTO @accList values ('20.1','61701')
	INSERT INTO @accList values ('29.21','72001')
	INSERT INTO @accList values ('29.22','72201')
	INSERT INTO @accList values ('29.23','72507')
	INSERT INTO @accList values ('29.24','72601')
	INSERT INTO @accList values ('29.25','72701')
	INSERT INTO @accList values ('29.26','72801')
	INSERT INTO @accList values ('29.27','72501')
	INSERT INTO @accList values ('29.28','72101')
	INSERT INTO @accList values ('29.29','72102')
	INSERT INTO @accList values ('29.30','72202')
	INSERT INTO @accList values ('29.31','72502')
	INSERT INTO @accList values ('29.32','72508')
	INSERT INTO @accList values ('29.33','72702')
	INSERT INTO @accList values ('29.34','72802')
	INSERT INTO @accList values ('29.35','72901')
	INSERT INTO @accList values ('29.36','72902')
	INSERT INTO @accList values ('29.37','72903')

	drop table if exists #spod

select
[Отчетный месяц] = @repmonth
,[Номер строки] = l1.[rowName]
,[СчетКод] = l1.acc2order
,[Сумма ДТ] = sum(isnull(l1.[Сумма ДТ],0))
,[Сумма КТ] = sum(isnull(l1.[Сумма КТ],0))
,[Остаток] = case 
				when l1.acc2order = '60329' then sum(isnull(l1.[Сумма ДТ],0))
				when l1.acc2order = '60328' then sum(isnull(l1.[Сумма КТ],0))
				when l1.acc2order = '61701' then sum(isnull(l1.[Сумма КТ],0))
				else sum(isnull(l1.[Сумма КТ],0)) - sum(isnull(l1.[Сумма ДТ],0))
			end
into #spod

from(

select
[rowName] = a.rowName
,[acc2order] = a.acc2order
,b.[Дата операции]
,[СчетДТКод] = b.СчетКод
,[СчетKТКод] = null
,[Сумма ДТ] = isnull(b.[Сумма БУ],0)
,[Сумма КТ] = 0

from @accList a
left join(
SELECT 

[Дата операции] = cast(dateadd(year,-2000,a.ДатаСПОД/*a.Период*/) as date)
,[СчетКод] = Dt.Код
--,[СчетАналитическогоУчетаНомер] = accDT.Код
--,[СчетАналитическогоУчетаНазвание] = accDT.Наименование
,[Сумма БУ] = isnull(a.Сумма,0)
--,[Содержание] = a.Содержание
--,[НомерМемориальногоОрдера] = a.НомерМемориальногоОрдера
--,[СПОД] = a.СПОД
--,[ДатаСПОД] = a.ДатаСПОД
--,a.Регистратор_Ссылка

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
--left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accDT on a.СчетАналитическогоУчетаДт=accDT.Ссылка
inner join @accList accl on Dt.Код = accl.acc2order
where a.ДатаСПОД between @dateFrom and @dateTo
and a.Активность=01
and a.СПОД = 0x01
) b on a.acc2order=b.СчетКод

union all

select
[rowName] = a.rowName
,[acc2order] = a.acc2order
,b.[Дата операции]
,[СчетДТКод] = null
,[СчетKТКод] = b.СчетКод
,[Сумма ДТ] = 0
,[Сумма КТ] = isnull(b.[Сумма БУ],0)

from @accList a
left join(
SELECT 

[Дата операции] = cast(dateadd(year,-2000,a.ДатаСПОД/*a.Период*/) as date)
,[СчетКод] = Kt.Код
--,[СчетАналитическогоУчетаНомер] = accDT.Код
--,[СчетАналитическогоУчетаНазвание] = accDT.Наименование
,[Сумма БУ] = isnull(a.Сумма,0)
--,[Содержание] = a.Содержание
--,[НомерМемориальногоОрдера] = a.НомерМемориальногоОрдера
--,[СПОД] = a.СПОД
--,[ДатаСПОД] = a.ДатаСПОД
--,a.Регистратор_Ссылка

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and Kt.ПометкаУдаления=0
--left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accDT on a.СчетАналитическогоУчетаДт=accDT.Ссылка
inner join @accList accl on Kt.Код = accl.acc2order
where a.ДатаСПОД between @dateFrom and @dateTo
and a.Активность=01
and a.СПОД = 0x01
) b on a.acc2order=b.СчетКод
) l1

group by 
l1.acc2order,l1.[rowName]


	/*Очистка таблицы от старых данных за отчетный месяц*/
	delete from dwh2.[finAnalytics].[repPLf842SPODfact] where year([Отчетный год]) = year(@repmonth)

	/*Добавление новых данных за отчетный месяц*/
	INSERT INTO dwh2.[finAnalytics].[repPLf842SPODfact]
	([Отчетный год], [Номер строки], [СчетКод], [Сумма ДТ], [Сумма КТ], [Остаток], [created])

	select
	[Отчетный месяц]
	, [Номер строки]
	, [СчетКод]
	, [Сумма ДТ]
	, [Сумма КТ]
	, [Остаток]
	,getdate()

	from #spod
	
	commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных СПОД для 842 '
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
