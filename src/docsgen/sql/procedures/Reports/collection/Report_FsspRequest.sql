CREATE   procedure [collection].[Report_FsspRequest]
	@dateBegin date = null
	,@dateEnd date = null
as
begin
select @dateBegin = isnull(@dateBegin, dateadd(dd,1, eomonth(getdate(), -1)))
	,@dateEnd = isnull(@dateEnd, getdate())
	
;with cte as (
select RequestDate = cast(CreateDate as date)
	,ResultName = Result.Name
	,TotalRequest = count(1)
	,EmployeeId = FsspRequest.EmployeeId
	,Employee = iif(FsspRequest.EmployeeId is not null,	
	concat(emp.LastName, ' ', emp.FirstName, ' ', emp.MiddleName)
		,'Система')
	from stg._Collection.FsspRequests FsspRequest
	left join stg._Collection.tvf_FsspRequests_ResultName() Result
		on Result.ID = FsspRequest.Result
	left join stg._Collection.Employee emp on emp.id = FsspRequest.EmployeeId
	where cast(CreateDate as date) between @dateBegin and @dateEnd
	group by cast(CreateDate as date)
	,Result.Name
	, FsspRequest.EmployeeId
	,iif(FsspRequest.EmployeeId is not null,	
	concat(emp.LastName, ' ', emp.FirstName, ' ', emp.MiddleName)
		,'Система')
	
)
select RequestDate
	, Employee
	, EmployeeId
	, [Какая-то ошибка] = isnull(pvt.[Какая-то ошибка],0)
	, [Отправлен запрос] = isnull(pvt.[Отправлен запрос],0)
	, [Получен ответ] = isnull(pvt.[Получен ответ],0)
	, [Ответ не поступил] = isnull(pvt.[Ответ не поступил],0)
	from cte
pivot (
	sum(TotalRequest) for ResultName in ([Какая-то ошибка], [Отправлен запрос], [Получен ответ], [Ответ не поступил])
) pvt

order by RequestDate


end