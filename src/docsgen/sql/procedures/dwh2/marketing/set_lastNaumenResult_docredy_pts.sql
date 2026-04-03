CREATE   procedure [marketing].[set_lastNaumenResult_docredy_pts]
	@lastDay smallint = 360
as
begin
	

--select * from [Stg].[_mds].[NaumenProjects_DokrNPovt_prod]
--Сбор данных по результатам последнего звонка по маркетинговым предложениям повторники инстолмент
	begin try
	declare @dateStartProject date ='2024-09-01'
	declare @projectIds table (project_id nvarchar(255))
		insert into @projectIds (project_id)
		select  project_id
		from (values
				('corebo00000000000mm1tts6og6rs2fk') --Докреды					--old
				,('corebo00000000000n25qgnvfnogtjf8') --Докреды Новые			--old
				,('corebo00000000000n25qereimll7884') --Докреды Перезвоны		--old
				,('corebo00000000000mn2eg74l4nb9950') --Повторные - Перезвоны	--old


				,('corebo00000000000palme673n6njdhs') --CRM Повторные					--new
				,('corebo00000000000pallp7sskqdpifo') --CRM Докреды			--new
				,('corebo00000000000pallps4t1qi8prs') --CRM Докреды Перезвоны		--new
				,('corebo00000000000palmf0r7gh7c2m8') --CRM Повторные - Перезвоны	--new


			) t(project_id)
	drop table if exists #docredy_ptsClientPhone
	create table  #docredy_ptsClientPhone (client_number nvarchar(10) primary key)
	insert into #docredy_ptsClientPhone
	select client_number = right(t.phone,10)
	from marketing.docredy_pts t
	where t.phone is not null
	group by right(t.phone,10)
	drop table if exists #tNaumeResult

	drop table if exists #t_last_last_attempt_client_number
	--результат звонков за последние 180 дней
	select 
		client_number = right(t.client_number,10)
		,attempt_result
		,attempt_start_date = cast(attempt_start as date)
		,attempt_start 
		,isPhoned = 
				CASE 
					WHEN t.attempt_result IN ('amd', 'amd_cti', 'no_answer', 'no_answer_cti', 'abandoned', 'not_found','UNKNOWN_ERROR') or t.login is null
					THEN convert(tinyint, 0)
					ELSE convert(tinyint, 1)
				END
		,last_attempt_start_on_date = max(attempt_start) over(partition by client_number, cast(attempt_start as date))
	into #t_client_number_result_on_date
	from Reports.dbo.dm_report_DIP_detail_outbound_sessions t
		where cast(t.attempt_start as date)>=dateadd(dd,-@lastDay, getdate())
	and exists(select top(1) 1 from @projectIds  t1
		where t1.project_id = t.project_id)
	and exists(select top(1) 1 from  #docredy_ptsClientPhone cp 
			where cp.client_number  =right(t.client_number,10))
	
	CREATE NONCLUSTERED INDEX ix_client_number_attempt_start
ON [#t_client_number_result_on_date]([client_number],[attempt_start])
INCLUDE ([attempt_result],[isPhoned])

	drop table if exists #tNaumeResult
	select 
					--t.case_uuid, 
		t.client_number, 
		last_attempt_start  = t.attempt_start,
		last_attempt_result = t.attempt_result,
		isPhoned			= t.isPhoned,
		totalIsNotPhoned	= last_data.totalIsNotPhoned
	into #tNaumeResult
	 	from #t_client_number_result_on_date t
		inner join (
			select 
				client_number
				,last_attempt_start = max(attempt_start)
				,totalIsNotPhoned = sum(iif(isPhoned = 0, 1, 0))
			from #t_client_number_result_on_date t
			where t.attempt_start = t.last_attempt_start_on_date
			group by client_number
		) last_data on last_data.client_number = t.client_number
			and last_data.last_attempt_start  = t.attempt_start

	begin tran
		update t
			set 
				lastNaumen_AttemptDate		= nr.last_attempt_start
				,lastNaumen_AttemptResult	= nr.last_attempt_result
				,lastNaumen_IsPhoned		= nr.isPhoned
				,[totalIsNotPhoned]			= coalesce(nr.totalIsNotPhoned, last_data.[totalIsNotPhoned], 0)
		from marketing.docredy_pts t
		left join #tNaumeResult nr on nr.client_number = t.phone 
		left join 
		(
			select 
				t.phone
				,t.[totalIsNotPhoned] 
				from (select phone, last_cdate = max(cdate)
			from marketing.docredy_pts
			where cdate<cast(getdate() as date)
			group by phone) last_data
				inner join marketing.docredy_pts t 
					on t.cdate = last_data.last_cdate
					and t.phone = last_data.phone
		) last_data on last_data.phone = t.phone
		where cdate = cast(getdate() as date)
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch

end