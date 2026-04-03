
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[populateReportManualChecks] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE [dbo].[populateReportManualChecks]
	@reloadDay smallint =  1
AS
BEGIN
begin try
	declare @lastDay date = '2025-04-01'
	if  OBJECT_ID('dbo.reportManualChecks') is not null	
	begin
		set @lastDay = dateadd(dd, -@reloadDay, (select max([request_creation_date]) from dbo.reporManualChecks))
	end
	set @lastDay = isnull(@lastDay,  '2025-04-01')
	select @lastDay

    --=========================================
    -- 1) Prepare #request_stages
    --=========================================
	drop table if exists #request_stages;
    SELECT 
		cr.id
	  , cr.Number               AS request_number
      , cr.createdOn            AS request_creation_date
	  , concat(cr.ClientLastName, ' ', cr.ClientFirstName) as request_client_name 
	  , crh.createdOn           AS transitionDate
      , crh.IdClientRequestStatus   as request_status
    INTO #request_stages
    FROM 
		_fedor.core_ClientRequest cr    
		LEFT JOIN 
		_fedor.core_ClientRequestHistory crh ON cr.id = crh.IdClientRequest
	WHERE 
		crh.IdClientRequestStatus in(2,7,8)
		and 
		cr.createdOn  >= @lastDay
    ;
--select * from #request_stages;
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
			 th.CreatedOn as task_stage_time
            , LEAD(th.CreatedOn, 1) OVER (PARTITION BY th.idTask ORDER BY th.createdOn) AS next_task_stage_time
			, th.IdTaskStatus as task_status
			, LEAD(th.IdTaskStatus, 1) OVER (PARTITION BY th.idTask ORDER BY th.createdOn) AS next_task_status
			, th.IdOwner AS task_status_owner
			, tacr.idClientRequest
			, min(th.CreatedOn) OVER (PARTITION BY tacr.idClientRequest, tacr.idTask) AS min_date_for_task
			--, max(th.CreatedOn) OVER (PARTITION BY tacr.idClientRequest, tacr.idTask) AS max_date_for_task
		FROM
			_fedor.core_TaskHistory th
			inner join
			_fedor.core_TaskAndClientRequest tacr on th.IdTask = tacr.IdTask
		where
			exists(select 1 from #request_stages where id=tacr.IdClientRequest)
		)
--select * from joined_request_task;
--select * from _fedor.core_TaskHistory where IdTask='D854D27F-D3F6-4AA0-9180-57E5FF01524F';
--select * from _fedor.core_TaskAndClientRequest where IdClientRequest='84B5395D-BE1D-4997-BBDA-045B1954DC63';
		, numered_tasks AS (
		select
			idClientRequest
			, task_stage_time
			, next_task_stage_time
			, task_status
			, next_task_status
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
			, nt.task_stage_time
			, nt.next_task_stage_time
			, nt.task_status
			, nt.next_task_status
			, nt.task_status_owner
			, nt.IdClientRequest
			, nt.task_number
		into #task_stages
		from 
			numered_tasks nt 
			inner join
			NumStatusMap nsm on nsm.task_number = nt.task_number
    ;

	CREATE NONCLUSTERED INDEX IX_TaskStages_Id 
    ON #task_stages (IdClientRequest);
	
	CREATE NONCLUSTERED INDEX IX_TaskStages_task_number 
    ON #task_stages (task_number);

    --=========================================
    -- 3) Populate dbo.reportIncomingFlows using the temp tables
    --=========================================
--select * from #task_stages order by IdClientRequest, task_stage_time;	
	
	with tasks_with_checklist_items as (
	    select 
			ts.IdClientRequest as rs1, 
			ts.task_stage_time,
			ts.next_task_stage_time,
			ts.request_status, 
			ts.task_number,  
			ts.task_status,
			ts.next_task_status,
			ts.task_status_owner,
			cli.[id] as check_list_item_id,   
			cli.idOwner,
			cli.IdStatus as check_list_item_status,
			clit.[name] as check_list_item_name
		from
			#task_stages ts 
			left join
			_fedor.core_CheckListItem cli on cli.idClientRequest=ts.idClientRequest  
			inner join
			_fedor.dictionary_CheckListItemType clit on clit.id=cli.idType and clit.idCheckType = ts.task_number
	)
--select * from tasks_with_checklist_items order by rs1, task_stage_time;
--select * from _fedor.core_CheckListItem;
	,  final_joined AS (
		select
			rs.Id
			, rs.request_number
			, rs.request_creation_date
			, rs.request_status
			, rs.request_client_name
			, twci.task_status
			, twci.task_stage_time
			, twci.next_task_stage_time
			, twci.next_task_status
			, twci.task_status_owner
			, twci.check_list_item_id
			, twci.check_list_item_name
			, twci.check_list_item_status
		from
			#request_stages rs
			left join
			tasks_with_checklist_items twci on rs.id = twci.rs1 and rs.request_status = twci.request_status
		)
		select 
			fj.Id
			, fj.request_number
			, fj.request_creation_date
			, crs.[Name] as request_status
			, fj.request_client_name
			, dts1.[Name] as task_status
			, fj.task_stage_time
			, fj.next_task_stage_time
			, dts2.[Name] as next_task_status
			, concat(u.LastName, ' ', u.FirstName) as task_status_owner
			, fj.check_list_item_id
			, fj.check_list_item_name
			, fj.check_list_item_status
			into #result_reportManualChecks 
		from 
			final_joined fj
			inner join
			_fedor.dictionary_ClientRequestStatus crs ON fj.request_status = crs.id
			left join
			_fedor.core_User u on fj.task_status_owner = u.id
			left join
			_fedor.dictionary_TaskStatus dts1 on fj.task_status = dts1.Id
			left join
			_fedor.dictionary_TaskStatus dts2 on fj.task_status = dts2.Id
		order by
			fj.request_creation_date desc, fj.task_stage_time
		;

		if OBJECT_ID('dbo.reportManualChecks') is null
		begin
			select top(0)
				*
			into dbo.reportManualChecks
			from #result_reportManualChecks
			CREATE NONCLUSTERED INDEX IX_reportManualChecks_request_creation_date 
			ON dbo.reportManualChecks (request_creation_date);
		end

		begin tran
			delete t from dbo.reportManualChecks t
			where [request_creation_date]>=@lastDay
			
			insert into dbo.reportManualChecks
				([Id], [request_number], [request_creation_date], [request_status], [request_client_name], [task_status], [task_stage_time], [next_task_stage_time], [next_task_status], [task_status_owner], [check_list_item_id], [check_list_item_name], [check_list_item_status])
			select
				[Id], [request_number], [request_creation_date], [request_status], [request_client_name], [task_status], [task_stage_time], [next_task_stage_time], [next_task_status], [task_status_owner], [check_list_item_id], [check_list_item_name], [check_list_item_status]
			from #result_reportManualChecks			
		commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
		
END;
