/*
	DWH-180 Процедура загрузки данных по план по переобслуживанию и списанию долга
	
*/
create   procedure collection.fill_plan_debtreliefrefinance as
begin
begin try
	drop table if exists #t_result
	select t.* 
	,created_at = getdate()
	into #t_result
	from (select 
		period = try_cast(Период as date)
		,planValue = try_cast([План руб] as money )
	
	from stg.[files].[plan_debtreliefrefinance_buffer]
	) t 
	where period is not null 
	and PlanValue is not null
	
	if OBJECT_ID('collection.plan_debtreliefrefinance') is null
	begin
		select top(0)
			period
			,planValue
			,created_at
		into collection.plan_debtreliefrefinance
		from #t_result
	end
	
	if exists(select top(1) 1 from   #t_result)
	begin
		begin tran
			merge collection.plan_debtreliefrefinance t
			using  #t_result s
				on s.period = t.period
			when not matched then insert (period, planValue, created_at)
			values(s.period, s.planValue, s.created_at)
			when matched and s.planValue!=t.planValue
			then update
				set planValue = s.planValue
				,created_at = s.created_at
			;
		commit tran
	end
		else 
			throw 50000, 'Нет данных', 16
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end