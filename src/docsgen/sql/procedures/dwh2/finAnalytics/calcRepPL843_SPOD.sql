



CREATE PROC [finAnalytics].[calcRepPL843_SPOD] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных СПОД для PL для публикуемой'
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
		acc2order nvarchar(5)
			)
	INSERT INTO @accList values ('72001')
	INSERT INTO @accList values ('72002')
	INSERT INTO @accList values ('72003')
	INSERT INTO @accList values ('72004')
	INSERT INTO @accList values ('72005')
	INSERT INTO @accList values ('72006')
	INSERT INTO @accList values ('72101')
	INSERT INTO @accList values ('72102')
	INSERT INTO @accList values ('72103')
	INSERT INTO @accList values ('72104')
	INSERT INTO @accList values ('72802')
	INSERT INTO @accList values ('72201')
	INSERT INTO @accList values ('72202')
	INSERT INTO @accList values ('72501')
	INSERT INTO @accList values ('72503')
	INSERT INTO @accList values ('72505')
	INSERT INTO @accList values ('72507')
	INSERT INTO @accList values ('72509')
	INSERT INTO @accList values ('72502')
	INSERT INTO @accList values ('72504')
	INSERT INTO @accList values ('72506')
	INSERT INTO @accList values ('72510')
	INSERT INTO @accList values ('72508')
	INSERT INTO @accList values ('72701')
	INSERT INTO @accList values ('72702')
	INSERT INTO @accList values ('72511')
	INSERT INTO @accList values ('72512')
	INSERT INTO @accList values ('72801')
	INSERT INTO @accList values ('72513')
	INSERT INTO @accList values ('72514')
	INSERT INTO @accList values ('72601')
	INSERT INTO @accList values ('72602')
	INSERT INTO @accList values ('72901')
	INSERT INTO @accList values ('72903')
	INSERT INTO @accList values ('72902')
	--INSERT INTO @accList values ('60329')

	drop table if exists #spod

select
[Отчетный месяц] = DATEFROMPARTS(year([Дата операции]),month([Дата операции]),1)
,[СчетКод] = isnull([СчетДтКод],[СчетКтКод])
,[Символ3] = isnull([simbol3DT],[simbol3KT])
,[Символ5] = isnull([simbol5DT],[simbol5KT])

,[Сумма БУ] = sum([Сумма БУ])

into #spod

from(


SELECT 

[Дата операции] = cast(dateadd(year,-2000,a.ДатаСПОД/*a.Период*/) as date)
,[СчетДтКод] = case when substring(Dt.Код,1,1)='7' then Dt.Код else null end
,[СчетКтКод] = case when substring(Kt.Код,1,1)='7' then Kt.Код else null end
,[СчетАналитическогоУчетаДтНомер] = accDT.Код
,[simbol3DT] = case when substring(Dt.Код,1,1)='7' then substring(accDT.Код,11,3) else null end
,[simbol5DT] = case when substring(Dt.Код,1,1)='7' then substring(accDT.Код,11,5) else null end
,[СчетАналитическогоУчетаДтНазвание] = accDT.Наименование
,[СчетАналитическогоУчетаКтНомер] = accKT.Код
,[simbol3KT] = case when substring(kt.Код,1,1)='7' then substring(acckT.Код,11,3) else null end
,[simbol5KT] = case when substring(kt.Код,1,1)='7' then substring(acckT.Код,11,5) else null end
,[СчетАналитическогоУчетаКтНазвание] = accKT.Наименование
,[Сумма БУ] = isnull(case when substring(Dt.Код,1,1)='7' then a.Сумма *- 1 else a.Сумма end,0)
,[СуммаНУ_Дт] = a.СуммаНУДт
,[СуммаНУ_Кт] = a.СуммаНУКт
,[СуммаПР_Дт] = a.СуммаПРДт
,[СуммаПР_Кт] = a.СуммаПРКт
,[СуммаВР_Дт] = a.СуммаВРДт
,[СуммаВР_Кт] = a.СуммаВРКт
,[Содержание] = a.Содержание
,[НомерМемориальногоОрдера] = a.НомерМемориальногоОрдера
,[СПОД] = a.СПОД
,[ДатаСПОД] = a.ДатаСПОД

,a.Регистратор_Ссылка

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accDT on a.СчетАналитическогоУчетаДт=accDT.Ссылка
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accKT on a.СчетАналитическогоУчетаКт=accKT.Ссылка
--inner join @accList acclDt on Dt.Код = acclDt.acc2order
--inner join @accList acclKt on Kt.Код = acclKt.acc2order
inner join @accList accl on Dt.Код = accl.acc2order or Kt.Код = accl.acc2order
--where a.Период between @dateFrom and @dateTo
where a.ДатаСПОД between @dateFrom and @dateTo
--and a.Активность=01

--and a.СПОД = 0x01
) l1
group by 
DATEFROMPARTS(year([Дата операции]),month([Дата операции]),1)
,isnull([СчетДтКод],[СчетКтКод])
,isnull([simbol3DT],[simbol3KT])
,isnull([simbol5DT],[simbol5KT])



	/*Очистка таблицы от старых данных за отчетный месяц*/
	delete from dwh2.[finAnalytics].[repPLf843SPODfact] where year(repmonth) = year(@repmonth)

	/*Добавление новых данных за отчетный месяц*/
	INSERT INTO dwh2.[finAnalytics].[repPLf843SPODfact]
	([repmonth], [accCode], [simbol3], [simbol5], [sumAmount], [created])

	select
	[Отчетный месяц]
	,[СчетКод]
	,[Символ3]
	,[Символ5]
	,[Сумма БУ]
	,getdate()

	from #spod
	
	commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных СПОД для отчета PL для публикуемой '
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
