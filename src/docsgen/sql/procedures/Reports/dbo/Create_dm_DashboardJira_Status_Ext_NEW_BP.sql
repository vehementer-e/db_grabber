

-- =============================================
-- Author:		Anton Sabanin
-- Create date: 11.03.2021
-- Description:	dwh-812
-- exec [dbo].[Create_dm_DashboardJira_Status_Ext_NEW_BP] null, null, null
-- exec [dbo].[Create_dm_DashboardJira_Status_Ext_NEW_BP] '2020-02-10', null, 2
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_DashboardJira_Status_Ext_NEW_BP]
	 @BeginDate as date = '2021-01-01'
	,@EndDate as date = '2021-12-31'
	,@report_num as int  = 0
	
	
AS
BEGIN
	

	SET NOCOUNT ON;

	-- первый день недели
	SET datefirst 1

	Declare @begin_date nvarchar(20)
	       ,@end_date nvarchar(20)
		   , @begin_date_first_status date
		   , @end_date_first_status date

Set @begin_date = format(cast('2010-01-01' as date), 'yyyy-MM-dd')
Set @end_date = format(cast('2050-12-31' as date), 'yyyy-MM-dd')

Set @begin_date_first_status = format(isnull(@BeginDate,cast('2010-01-01' as date)), 'yyyy-MM-dd')
Set @end_date_first_status = format(isnull(@EndDate,cast('2050-12-31' as date)), 'yyyy-MM-dd')


--Set @begin_date = format(isnull(@BeginDate,cast('2010-01-01' as date)), 'yyyy-MM-dd')
--Set @end_date = format(isnull(@EndDate,cast('2050-12-31' as date)), 'yyyy-MM-dd')
--Set @begin_date = cast('2010-01-01' as date)
--Set @end_date = cast('2030-12-31' as date)


--select @begin_date, @end_date
	
	DECLARE @idRequest uniqueidentifier
		 ,  @OUTSTATUS VARCHAR(1000) 
		 --,  @report_num int = 0
	SET @idRequest = NEWID()  

	exec [dwh-ex].[bot].[dbo].[Get_Jira_List_Status]  @idRequest, @report_num, @begin_date, @end_date, @OUTSTATUS OUTPUT

	--select @OUTSTATUS

	drop table if exists #t;
	with first_status_date as
	( 
	  select id as id_f , min(cast(LEFT(createdStatus ,19) as datetime)) createdStatus_begin
	  from [DWH-EX].[Bot].[dbo].[dm_Jira_List_Status]
	  where toString = 'Бизнес-анализ'  or toString = 'Анализ ИБ'
	  Group by id
	)
	select original_data.*
	, Длительность =  datediff(day, createdStatus_begin, createdStatus_end)  - reports.dbo.GetHolidayInPeriod(createdStatus_begin, createdStatus_end)
	, holydays =reports.dbo.GetHolidayInPeriod(createdStatus_begin, createdStatus_end)
	, rn = row_number() over(partition by id, toString order by createdStatus_begin )
	, first_status = row_number() over(partition by id order by createdStatus_begin)
	--, first_status_date --= first_value(createdStatus_begin) over(partition by id order by createdStatus_begin)
	into #t
	From(

	select m1.id
	, idStatus
	, key_issue
	, cast(LEFT(createdStatus ,19) as datetime) createdStatus_begin
	, isnull(cast(LEFT(lead(createdStatus) over (partition by id order by idStatus ) ,19) as datetime), GetDate()) createdStatus_end
	, fromString
	, toString
	, m2.createdStatus_begin first_status_date

	 from [DWH-EX].[Bot].[dbo].[dm_Jira_List_Status] m1
	 left join first_status_date m2 on m1.id = m2.id_f
	where field = 'status' --and idStatus ='372334'
	--and not(toString ='B4B')
	and @idRequest = idRequest

	) original_data

	order by id, idstatus desc


	-- найдем все задачи, у которых статус Бизнес-анализ вне пределов запроса
	;with clear_data as 
	(
	select id   from #t
	where first_status_date	between  @begin_date_first_status and  @end_date_first_status 

	)
	delete from #t where id not in (select id from clear_data)

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

	 select *, ord_num = ROW_NUMBER() over(order by first_status_date, id, rn)   from(
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
	order by  first_status_date, id, rn--cast(id as bigint), key_issue, rn

 

END
