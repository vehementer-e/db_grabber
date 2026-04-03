
-- Usage: запуск процедуры с параметрами
-- EXEC [etl].[fill_Need2Reload4ContractUpdate] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [etl].[fill_Need2Reload4ContractUpdate] as
begin
begin try
	drop table if exists #t_result
	
	select top(0) ContractGuid
		into #t_result
	 from  etl.need2Reload4ContractUpdate
	begin tran
	;with cte as (
	select distinct top(100)  ContractGuid, StatusCode, ProcessType
	from etl.ReloadData4Contract t
	where ProcessType = 'contractUpdate'
	and CreatedAt > ='2024-10-26' --Дата запуска
	and StatusCode = 'New'
	)
	insert into #t_result(ContractGuid)
	select 
		ContractGuid
	from (merge etl.ReloadData4Contract t
	using cte s
		on s.ContractGuid = t.ContractGuid
		and s.StatusCode = t.StatusCode
		and s.ProcessType = t.ProcessType
	when matched then update
		set StatusCode = 'InProgress'
		,UpdatedAt = getdate()
	 OUTPUT 
        Inserted.ContractGuid
		) as c(ContractGuid)
	;
	truncate table etl.need2Reload4ContractUpdate
	insert into  etl.need2Reload4ContractUpdate(ContractGuid)
	select distinct ContractGuid
	from #t_result
	if @@ROWCOUNT=0
		throw 50001, 'Нет данных для копирования', 16
	commit tran
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
