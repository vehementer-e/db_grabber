
CREATE    procedure [marketing].[set_lastNaumenResult_povt_pdl]
as
begin
--Сбор данных по результатам последнего звонка по маркетинговым предложениям повторники инстолмент
	begin try
	declare @dateStartProject date ='2023-11-13' --дата старта проекта
	declare @projectIds table (project_id nvarchar(255))
		insert into @projectIds (project_id)
		select  project_id
		from (values
			('corebo00000000000oe3p1ashjvi3rho')--код проекта по повторникам инстолмент
			,('corebo00000000000oe3p4rec7ip91ks')--Перезвоны по повторникам
			--new
			,('corebo00000000000palmbv48njpfhp8') --CRM Повторники Инст
			,('corebo00000000000palmcvs9gpenh84') --CRM Повторники Инст Перезвон
			) t(project_id)
	drop table if exists #povInstClientPhone
	create table  #povInstClientPhone (client_number nvarchar(10) primary key)
	insert into #povInstClientPhone
	select client_number = right(t.phone,10) from marketing.povt_inst t
	where t.phone is not null
	group by  right(t.phone,10)

	
	drop table if exists #tNaumeResult

	drop table if exists #t_last_last_attempt_client_number
	--звонки за последние 30 дней
	select 
					--t.case_uuid, 
		client_number = right(t.client_number , 10), 
		last_attempt_start = max(t.attempt_start)  
	into #t_last_last_attempt_client_number
	from Reports.dbo.dm_report_DIP_detail_outbound_sessions t
	where cast(t.attempt_start as date)>=dateadd(dd,-30, getdate())
	and cast(t.attempt_start as date)>=@dateStartProject
	and exists(select top(1) 1 from @projectIds  t1
		where t1.project_id = t.project_id)
	and exists(select top(1) 1 from  #povInstClientPhone cp where cp.client_number  
		= right(t.client_number , 10))
	group by right(t.client_number , 10)


	select
		client_number= right(os.client_number , 10),
		isPhoned = 
				CASE 
					WHEN os.attempt_result IN ('amd', 'amd_cti', 'no_answer', 'no_answer_cti', 'abandoned', 'not_found','UNKNOWN_ERROR') or os.login is null
					THEN convert(bit, 0)
					ELSE convert(bit, 1)
				END
		, os.attempt_result 
		, os.attempt_start
	into #tNaumeResult
	from #povInstClientPhone cp
	inner join Reports.dbo.dm_report_DIP_detail_outbound_sessions os
	on cp.client_number = os.client_number
	where exists(select top(1) 1 from #t_last_last_attempt_client_number last_data
		where 1=1
			--last_data.case_uuid  = os.case_uuid
			and last_data.client_number = right(os.client_number , 10)
			and last_data.last_attempt_start = os.attempt_start
			)


	
		
	begin tran
		update pov
			set 
				lastNaumen_AttemptDate		= nr.attempt_start
				,lastNaumen_AttemptResult	= nr.attempt_result
				,lastNaumen_IsPhoned		= nr.isPhoned

		from marketing.povt_pdl pov
		left join #tNaumeResult nr on nr.client_number = pov.phone 
		where cdate = cast(getdate() as date)
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch

end
