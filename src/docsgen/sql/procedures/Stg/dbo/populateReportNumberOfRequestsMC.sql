--656483
/*
select max(request_creation_date), min(request_creation_date) from dbo.reportIncomingFlows t
			where [request_creation_date]>=@lastDay
declare @reloadDay smallint =  1
 declare @lastDay date = '2020-01-01'
	if  OBJECT_ID('dbo.reportIncomingFlows') is not null	
	begin
		set @lastDay = dateadd(dd, -@reloadDay, (select max([request_creation_date]) from reportIncomingFlows))
	end
	set @lastDay = isnull(@lastDay,  '2020-01-01')
	select @lastDay

select  t.* from dbo.reportIncomingFlows t
			where [request_creation_date]>=@lastDay
			*/

create   PROCEDURE [dbo].[pupulateReportNumberOfRequestsMC]
	@reloadDay smallint =  1
AS
BEGIN
begin try
	declare @lastDay date = '2020-01-01'
	if  OBJECT_ID('dbo.reportIncomingFlows') is not null	
	begin
		set @lastDay = dateadd(dd, -@reloadDay, (select max([request_creation_date]) from reportIncomingFlows))
	end
	set @lastDay = isnull(@lastDay,  '2020-01-01')
	select @lastDay

    --=========================================
    -- 1) Prepare #request_stages
    --=========================================
	drop table if exists #request_stages;
    SELECT 
		cr.id
	  , cr.Number               AS request_number
      , cr.createdOn            AS request_creation_date
	  , crh.createdOn           AS transitionDate
      , crh.IdClientRequestStatus   as request_status
	 , LAST_VALUE(crh.IdClientRequestStatus) 
            OVER (PARTITION BY cr.id ORDER BY crh.createdOn ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS request_status_on_unload
    INTO #request_stages
    FROM 
		_fedorUAT.core_ClientRequest cr    
		LEFT JOIN 
		_fedorUAT.core_ClientRequestHistory crh ON cr.id = crh.IdClientRequest
	WHERE cr.createdOn  >=@lastDay
    ;

	CREATE NONCLUSTERED INDEX IX_RequestStages_Id 
    ON #request_stages (Id);

	CREATE NONCLUSTERED INDEX IX_RequestStages_RequestStatus 
    ON #request_stages (request_status);

    --=========================================
    -- 2) Prepare #task_stages
    --=========================================
    drop table if exists #task_stages;

	WITH joined_request_task AS (
		SELECT
			 th.CreatedOn
			, th.IdTaskStatus
			, th.IdOwner AS task_status_owner
			, tacr.idClientRequest
			, min(th.CreatedOn) OVER (PARTITION BY tacr.idClientRequest, tacr.idTask) AS min_date_for_task
		FROM
			_fedorUAT.core_TaskHistory th
			inner join
			_fedorUAT.core_TaskAndClientRequest tacr on th.IdTask = tacr.IdTask
		)
		, numered_tasks AS (
		select
			idClientRequest
			, CreatedOn
			, idTaskStatus
			, task_status_owner
			, DENSE_RANK() OVER (PARTITION BY idClientRequest ORDER BY min_date_for_task) AS task_number
		from
			joined_request_task	
		)
		,
		NumStatusMap AS ( 
			select 2 as request_status, 1 as task_number
			union all
			select 7 as request_status, 2 as task_number
			union all
			select 8 as request_status, 3 as task_number		
		)
		select
			nsm.request_status
			, nt.CreatedOn
			, nt.IdTaskStatus
			, nt.task_status_owner
			, nt.IdClientRequest
		into #task_stages
		from 
			numered_tasks nt 
			inner join
			NumStatusMap nsm on nsm.task_number = nt.task_number
    ;

	CREATE NONCLUSTERED INDEX IX_TaskStages_Id 
    ON #task_stages (IdClientRequest);
	
	CREATE NONCLUSTERED INDEX IX_TaskStages_request_status 
    ON #task_stages (request_status);

    --=========================================
    -- 3) Populate dbo.reportIncomingFlows using the temp tables
    --=========================================
	
	
	
	with final_joined AS (
		select
			rs.Id
			, rs.request_number
			, rs.request_creation_date
			, rs.request_status
			, rs.request_status_on_unload
			, ts.IdTaskStatus
			, ts.task_status_owner
			, ts.CreatedOn as task_status_date
		from
			#request_stages rs
			left join
			#task_stages ts on rs.id = ts.IdClientRequest and rs.request_status = ts.request_status
		--where rs.request_status in(2,7,8)
		)
		--select * from final_joined where id='E8B8D362-D0BF-461E-9C3E-967CE53FD633';
		, final_grouped AS (
		SELECT 
			  f.Id
			, MIN(f.request_number)         AS request_number
			, MIN(f.request_creation_date)  AS request_creation_date
			, MIN(CASE WHEN f.request_status = 2 AND f.IdTaskStatus = 1 
					   THEN f.task_status_date 
				  END) 
				  AS first_checker_date
		  
			, MAX(CASE WHEN f.request_status = 2 AND f.IdTaskStatus > 1 
					   THEN f.task_status_date 
				  END) 
				  AS last_checker_date

			, MIN(CASE WHEN f.request_status = 7 AND f.IdTaskStatus = 1 
					   THEN f.task_status_date 
				  END) 
				  AS first_verifier_date

			, MAX(CASE WHEN f.request_status IN (7,8) AND f.IdTaskStatus <> 1 
					   THEN f.task_status_date 
				  END) 
				  AS last_verifier_date
			, (
				SELECT TOP 1 ff.task_status_owner 
				FROM final_joined ff
				WHERE ff.Id = f.Id --and ff.request_status=f.request_status
				  AND ff.request_status = 2
				ORDER BY ff.task_status_date DESC
			  )
			  AS last_checker_owner_id

			, (
				SELECT TOP 1 ff.task_status_owner 
				FROM final_joined ff
				WHERE ff.Id = f.Id
				  AND ff.request_status IN (7, 8)
				ORDER BY ff.task_status_date DESC
			  )
			  AS last_verifier_owner_id
			 , min(f.request_status_on_unload) as request_status_on_unload 

		FROM 
			final_joined f
		GROUP BY 
			f.Id
		) 
		select
			fg.Id
			, fg.request_number
			, fg.request_creation_date
			, fg.first_checker_date
			, fg.last_checker_date
			, fg.first_verifier_date
			, fg.last_verifier_date
			, u1.LastName AS last_checker_name
			, u2.LastName AS last_verifier_name
			, crs.Name AS request_status_on_unload
		into #result_reportIncomingFlows
		from
			final_grouped fg
			inner join
			_fedorUAT.dictionary_ClientRequestStatus crs   ON fg.request_status_on_unload = crs.id
			left join
			_fedorUAT.core_User u1 on fg.last_checker_owner_id = u1.id
			left join
			_fedorUAT.core_User u2 on fg.last_verifier_owner_id = u2.id
		order by
			fg.request_creation_date desc
		;

		if OBJECT_ID('dbo.reportIncomingFlows') is null
		begin
			select top(0)
				*
			into dbo.reportIncomingFlows
			from #result_reportIncomingFlows
			CREATE NONCLUSTERED INDEX IX_reportIncomingFlows_request_creation_date 
			ON dbo.reportIncomingFlows (request_creation_date);

		end

		begin tran
			--truncate table dbo.reportIncomingFlows

			
			delete t from dbo.reportIncomingFlows t
			where [request_creation_date]>=@lastDay
			
			insert into dbo.reportIncomingFlows
				([Id], [request_number], [request_creation_date], [first_checker_date], [last_checker_date], [first_verifier_date], [last_verifier_date], [last_checker_name], [last_verifier_name], [request_status_on_unload])
			select
				[Id], [request_number], [request_creation_date], [first_checker_date], [last_checker_date], [first_verifier_date], [last_verifier_date], [last_checker_name], [last_verifier_name], [request_status_on_unload]
				
			from #result_reportIncomingFlows
			
		commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
		
END;
