
-- =============================================
-- Author:		Petr Ilin
-- Create date: 20200410
-- Description:	Данные по возвратам для Product review
-- =============================================
CREATE PROCEDURE [dbo].[create_dm_report_vozvrati]
	-- Add the parameters for the stored procedure here
--	@DateBegin datetime
--	@DateEnd datetime
AS
BEGIN
	SET NOCOUNT ON;


declare @DateBegin datetime
set @DateBegin='40180101'
select @DateBegin
while @DateBegin<dateadd(yy, 2000, getdate())
begin
	declare @DateEnd datetime
	set @DateEnd=dateadd(s, -1, dateadd(mm,1, @DateBegin))



Delete FROM [dbo].[dm_report_vozvrati]
Where [Срез]= datename(yy, DATEADD(YY,-2000, @DateBegin)) +'-' + CHOOSE(month(@DateBegin), N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь',N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь')

INSERT INTO dbo.[dm_report_vozvrati]
(
	[GUID1] ,
	[Срез]  ,
	[ПериодНачало] ,
	[ПериодКонец] ,
	[НомерМаксВыдан]  ,
	[ДатаМаксВыдан]  ,
	[НомерМаксПогашен] ,
	[ДатаМаксПогашен] ,
	[НомерВозврат]  ,
	[ДатаВозврат]  ,
	[ДействуетСрезе] ,
	[ПогашенСрезе]  ,
	[ВозвратЗаСрезом]  ,
	[Дельта]  ,
	[СрокПогашения]  ,
	[СрокПогашенияБакет]  ,
	[НомерПогашенПослеСреза]  ,
	[ДатаПогашенПослеСреза] ,
	[ПогашенПослеСреза]  ,
	[УникальныйКлиент]  ,
	[НомерДействуюещего]  ,
	[ДатаМаксДействующего] ,
	[НомерВыданПогашенПослеСреза]  ,
	[ДатаВыданПогашенПослеСреза]
)





SELECT 	[GUID1] ,
	[Срез]  ,
	[ПериодНачало] ,
	[ПериодКонец] ,
	[НомерМаксВыдан]  ,
	[ДатаМаксВыдан]  ,
	[НомерМаксПогашен] ,
	[ДатаМаксПогашен] ,
	[НомерВозврат]  ,
	[ДатаВозврат]  ,
	[ДействуетСрезе] ,
	[ПогашенСрезе]  ,
	[ВозвратЗаСрезом]  ,
	[Дельта]  ,
	[СрокПогашения]  ,
	[СрокПогашенияБакет]  ,
	[НомерПогашенПослеСреза]  ,
	[ДатаПогашенПослеСреза] ,
	[ПогашенПослеСреза]  ,
	[УникальныйКлиент]  ,
	[НомерДействуюещего]  ,
	[ДатаМаксДействующего] ,
	[НомерВыданПогашенПослеСреза]  ,
	[ДатаВыданПогашенПослеСреза]

FROM
(

   Select  distinct
    ВыданыДоговора.GUID1
	
   ,  datename(yy, DATEADD(YY,-2000, Срез)) +'-' + CHOOSE(month(Срез), N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь',N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь') as 'Срез'
   , @DateBegin ПериодНачало
   , @DateEnd ПериодКонец
   , НомерМаксВыдан
   , ДатаМаксВыдан, НомерМаксПогашен, ДатаМаксПогашен, НомерВозврат, ДатаВозврат
    -- Проверим, что есть действующий
   , IIF(ДатаМаксДействующего is not null,1, 0) 'ДействуетСрезе'   
   , IIF(ДатаМаксПогашен is null,0, 1) 'ПогашенСрезе'
   , IIF(ДатаВозврат is null,0, 1) 'ВозвратЗаСрезом'
   , IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксПогашен, Срез)-1,NULL)  'Дельта' 
   , IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) 'СрокПогашения'
   , 'СрокПогашенияБакет' = CASE 
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) is null then null
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) =0 then '[0]'
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) >0 and 
		IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) <=3
		then '[1-3]'
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) >3 and 
		IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) <=6
		then '[4-6]'
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) >6 and 
		IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) <=9
		then '[7-9]'
		when IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) >9 and 
		IIF(ДатаМаксДействующего is null, DATEDIFF(month, ДатаМаксВыдан, ДатаМаксПогашен), NULL) <=12
		then '[10-12]'
		else '[>12]'
    end 
	, НомерПогашенПослеСреза
	, ДатаПогашенПослеСреза
	, IIF(ДатаПогашенПослеСреза is null,0, 1) 'ПогашенПослеСреза'
	, RTRIM(Фамилия) + ' ' + [Имя] + ' ' + [Отчество] + ' ' + FORMAT(DATEADD(YY,-2000, [ДатаРождения]),'dd.MM.yyyy')  as 'УникальныйКлиент'
	, НомерДействуюещего
	, ДатаМаксДействующего
	, НомерВыданПогашенПослеСреза
	, ДатаВыданПогашенПослеСреза
	--, СтатусДействующегоДоговора
   
   FROM 
   (
		SELECT distinct 
		@DateBegin 'Срез'
		, Клиент.[GUIDКлиента] 'GUID1'
		,(first_value([НомерДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаОткрытияДоговора] desc ROWS UNBOUNDED PRECEDING ))  as 'НомерМаксВыдан'
		,(first_value([ДатаОткрытияДоговора])  over (PARTITION BY [GUIDКлиента]  order by [ДатаОткрытияДоговора] desc ROWS UNBOUNDED PRECEDING ))  as 'ДатаМаксВыдан'
		FROM  stg._1cMFO.[Отчет_СписокКредитныхДоговоров] Клиент   
		where Клиент.ДатаОткрытияДоговора < @DateBegin  and Клиент.ДатаОткрытияДоговора >= '4016-03-01T00:00:00.000'
		and СтатусДоговора<>N'Продан'

  ) ВыданыДоговора

   left join (	
   SELECT 
		distinct @DateBegin 'Срез2'
		, Клиент.[GUIDКлиента] 'GUID1'
		,(first_value([НомерДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаФактическогоЗакрытия] desc ROWS UNBOUNDED PRECEDING ))  as 'НомерМаксПогашен'
		,(first_value([ДатаФактическогоЗакрытия])  over (PARTITION BY [GUIDКлиента]  order by [ДатаФактическогоЗакрытия] desc ROWS UNBOUNDED PRECEDING ))  as 'ДатаМаксПогашен'
		FROM  stg._1cMFO.[Отчет_СписокКредитныхДоговоров] Клиент   
		where Клиент.[ДатаФактическогоЗакрытия] < @DateBegin  and Клиент.[ДатаФактическогоЗакрытия] >= '4016-03-01T00:00:00.000'
	  )   ПогашеныДоговора
	on ВыданыДоговора.GUID1 = ПогашеныДоговора.GUID1

	left join
	(
		select distinct [GUIDКлиента] 'GUID1'
		,@DateBegin 'ПериодВозврат'
		, (first_value([НомерДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаОткрытияДоговора] desc ROWS UNBOUNDED PRECEDING ))  as 'НомерВозврат' 
		, (first_value([ДатаОткрытияДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаОткрытияДоговора] desc ROWS UNBOUNDED PRECEDING ))  as 'ДатаВозврат'  
		from  stg._1cMFO.[Отчет_СписокКредитныхДоговоров]
		where ([ДатаОткрытияДоговора] between @DateBegin and @DateEnd)
  ) ДоговораВозврат
   on ВыданыДоговора.GUID1 = ДоговораВозврат.GUID1 

      left join (	
   SELECT 
		distinct 
		--top 1
		@DateBegin 'Срез3'
		, Клиент.[GUIDКлиента] 'GUID1'
		, СтатусДоговора 'СтатусДействующегоДоговора'
		,(first_value([НомерДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаОткрытияДоговора ] desc ROWS UNBOUNDED PRECEDING ))  as 'НомерДействуюещего'
		,(first_value([ДатаОткрытияДоговора ])  over (PARTITION BY [GUIDКлиента]  order by [ДатаОткрытияДоговора ] desc ROWS UNBOUNDED PRECEDING ))  as 'ДатаМаксДействующего'
		FROM  stg._1cMFO.[Отчет_СписокКредитныхДоговоров] Клиент   
		where (
		Клиент.[ДатаФактическогоЗакрытия] is null or 
		Клиент.[ДатаФактическогоЗакрытия] >= @DateBegin) and Клиент.ДатаОткрытияДоговора < @DateBegin  and Клиент.ДатаОткрытияДоговора >= '4016-03-01T00:00:00.000'
		 --and Клиент.[ДатаФактическогоЗакрытия] >= '4016-03-01T00:00:00.000'
		 and СтатусДоговора<>N'Продан'
	  )   ДействующиеДоговора
	on ВыданыДоговора.GUID1 = ДействующиеДоговора.GUID1

   	left join
	(
		select distinct [GUIDКлиента] 'GUID1'
		,@DateBegin 'ПериодПослеСреза'
		, (first_value([НомерДоговора])  over (PARTITION BY [GUIDКлиента]   order by [ДатаФактическогоЗакрытия] desc ROWS UNBOUNDED PRECEDING ))  as 'НомерПогашенПослеСреза' 
		, (first_value([ДатаФактическогоЗакрытия])  over (PARTITION BY [GUIDКлиента]   order by [ДатаФактическогоЗакрытия] desc ROWS UNBOUNDED PRECEDING ))  as 'ДатаПогашенПослеСреза'  
		from  stg._1cMFO.[Отчет_СписокКредитныхДоговоров]
		where ([ДатаФактическогоЗакрытия] between @DateBegin and @DateEnd)
  ) ДоговораПогашенПослеСреза
   on ВыданыДоговора.GUID1 = ДоговораПогашенПослеСреза.GUID1 

      	left join
	(
		select top 1 [GUIDКлиента] 'GUID1'
		,@DateBegin 'ПериодПослеСреза'
		, [НомерДоговора]  as 'НомерВыданПогашенПослеСреза' 
		, [ДатаФактическогоЗакрытия] as 'ДатаВыданПогашенПослеСреза'  
		from  stg._1cMFO.[Отчет_СписокКредитныхДоговоров]
		where ([ДатаФактическогоЗакрытия] between @DateBegin and @DateEnd)
		and ([ДатаОткрытияДоговора ] between @DateBegin and @DateEnd)
  ) ДоговораВыданПогашенПослеСреза
   on ВыданыДоговора.GUID1 = ДоговораВыданПогашенПослеСреза.GUID1 

   left join 
   stg._1cMFO.Отчет_Клиенты Клиент
   on Клиент.[GUID] = ВыданыДоговора.GUID1

   	 ) a1

	 	set @DateBegin=dateadd(mm, 1, @DateBegin)
	end
END
