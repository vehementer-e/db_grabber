
-- =============================================
-- Author:		Anton Sabanin
-- Create date: 11.03.2021
-- Description:	dwh-812
-- exec [dbo].[Create_dm_DashboardJira_Status] null, null, null
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_DashboardJira_Status]
	 @BeginDate as date = '2021-01-01'
	,@EndDate as date = '2021-02-28'
	,@report_num as int  = 0
	
	
AS
BEGIN
	

	SET NOCOUNT ON;

	-- первый день недели
	SET datefirst 1

	Declare @begin_date nvarchar(20)
	       ,@end_date nvarchar(20)

Set @begin_date = format(isnull(@BeginDate,cast('2021-01-01' as date)), 'yyyy-MM-dd')
Set @end_date = format(isnull(@EndDate,cast('2021-02-28' as date)), 'yyyy-MM-dd')


--select @begin_date, @end_date
	
	DECLARE @idRequest uniqueidentifier
		 ,  @OUTSTATUS VARCHAR(1000) 
		 --,  @report_num int = 0
	SET @idRequest = NEWID()  

	exec [dwh-ex].[bot].[dbo].[Get_Jira_List_Status]  @idRequest, @report_num, @begin_date, @end_date, @OUTSTATUS OUTPUT

	--select @OUTSTATUS

	drop table if exists #t
	select original_data.*
	, Длительность =  datediff(day, createdStatus_begin, createdStatus_end)  - reports.dbo.GetHolidayInPeriod(createdStatus_begin, createdStatus_end)
	, holydays =reports.dbo.GetHolidayInPeriod(createdStatus_begin, createdStatus_end)
	, rn = row_number() over(partition by id, toString order by createdStatus_begin )
	, first_status = row_number() over(partition by id order by createdStatus_begin)
	, first_status_date = first_value(createdStatus_begin) over(partition by id order by createdStatus_begin)
	into #t
	From(
	select id
	, idStatus
	, key_issue
	, cast(LEFT(createdStatus ,19) as datetime) createdStatus_begin
	, isnull(cast(LEFT(lead(createdStatus) over (partition by id order by idStatus ) ,19) as datetime), GetDate()) createdStatus_end
	, fromString
	, toString

	 from [DWH-EX].[Bot].[dbo].[dm_Jira_List_Status]
	where field = 'status'
	and @idRequest = idRequest

	) original_data

	order by id, idstatus desc


	if (@report_num = -1)
	begin
	select * from #t
	end

	--select '[' + tostring + '],'
	----, min(first_status)  
	--from #t group by tostring
	--order by min(first_status) 

	--'B4B',
	--'Бизнес-анализ',
	--'Инициация',
	--'Анализ ИБ',
	--'Ожидание спринта / разработки',
	--'Рассмотрение / Экспресс оценка',
	--'Приоритизация',
	--'Разработка',
	--'Архитектура',
	--'Ожидание разработки',
	--'Отложенная приоритизация',
	--'Формирование релиза',
	--'Тестирование',
	--'UAT',
	--'Готово к релизу',
	--'Приемка заказчиком',
	--'Закрыто'


	--[B4B],
	--[Бизнес-анализ],
	--[Инициация],
	--[Анализ ИБ],
	--[Ожидание спринта / разработки],
	--[Рассмотрение / Экспресс оценка],
	--[Приоритизация],
	--[Разработка],
	--[Архитектура],
	--[Ожидание разработки],
	--[Отложенная приоритизация],
	--[Формирование релиза],
	--[Тестирование],
	--[UAT],
	--[Готово к релизу],
	--[Приемка заказчиком],
	--[Закрыто],

	 select * from(
	 select id,key_issue, toString, first_status_date, rn,  Длительность


	 from #t 
	 ) t

	-- pivot (sum(Длительность) for toString in ([B4B],
	--[Бизнес-анализ],
	--[Инициация],
	--[Анализ ИБ],
	--[Ожидание спринта / разработки],
	--[Рассмотрение / Экспресс оценка],
	--[Приоритизация],
	--[Разработка],
	--[Архитектура],
	--[Ожидание разработки],
	--[Отложенная приоритизация],
	--[Формирование релиза],
	--[Тестирование],
	--[UAT],
	--[Готово к релизу],
	--[Приемка заказчиком],
	--[Закрыто])) as pvt 
	--order by id, key_issue, rn

pivot (sum(Длительность) for toString in (
	[Бизнес-анализ], 
	[Анализ ИБ],
	[Рассмотрение / Экспресс оценка],
	[Отложенная приоритизация],
	[Приоритизация],
	[Ожидание разработки], 
	[Архитектура], 
	[Ожидание спринта / разработки],
	[Разработка], 
	[Тестирование],
	[UAT],
	[Формирование релиза], 
	[Готово к релизу],
	[Приемка заказчиком],
	[Закрыто] 
)) as pvt 
	order by id, key_issue, rn

 

END
