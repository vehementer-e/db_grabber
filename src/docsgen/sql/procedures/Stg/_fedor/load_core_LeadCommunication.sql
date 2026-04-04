-- =============================================
-- Author:		Anatoly Kotelevets
-- Create date: 06-11-2020
-- Description:	прогрузка данных из [Fedor.Core].[core].[LeadCommunication]  в stg _fedor.core_LeadCommunication
-- exec _fedor.load_core_LeadCommunication @reloadDay = 10 -- (reloadDay за сколько дней нужно перегрузить данные default = 10)
-- select * from _fedor.core_LeadCommunication

-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC _fedor.load_core_LeadCommunication @reloadDay = 10;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure _fedor.load_core_LeadCommunication
	@reloadDay int = 10
as
begin
set nocount on

	declare @reloadDateStart date =  dateadd(day, -@reloadDay, cast(getdate() as date))
	drop table if exists tmp.fedor_core_LeadCommunication

	select top(0)
		[Id], 
		[CreatedOn], 
		[IdOwner], 
		[IsDeleted], 
		[IdLead], 
		[IdLeadCommunicationType], 
		[IdLeadCommunicationResult], 
		[Comment], 
		[CommunicationEnd], 
		[IdLeadRejectReason], 
		getdate()  as [DWHInsertedDate] 
	into tmp.fedor_core_LeadCommunication
	from  [PRODSQL02].[Fedor.Core].[core].[LeadCommunication] 
	
begin try
	insert into tmp.fedor_core_LeadCommunication (
		[Id], 
		[CreatedOn], 
		[IdOwner], 
		[IsDeleted], 
		[IdLead], 
		[IdLeadCommunicationType], 
		[IdLeadCommunicationResult], 
		[Comment], 
		[CommunicationEnd], 
		[IdLeadRejectReason],
		[DWHInsertedDate]
	)
	select
		[Id], 
		[CreatedOn], 
		[IdOwner], 
		[IsDeleted], 
		[IdLead], 
		[IdLeadCommunicationType], 
		[IdLeadCommunicationResult], 
		[Comment], 
		[CommunicationEnd], 
		[IdLeadRejectReason], 
		getdate()  as [DWHInsertedDate] 
	from  [PRODSQL02].[Fedor.Core].[core].[LeadCommunication] 
	where  cast([CreatedOn] as date) >=@reloadDateStart

	if exists(select top(1) 1 from tmp.fedor_core_LeadCommunication)
	begin
		delete from _fedor.core_LeadCommunication where  cast([CreatedOn] as date) >=@reloadDateStart
		insert into _fedor.core_LeadCommunication
		(
			[Id], 
			[CreatedOn], 
			[IdOwner], 
			[IsDeleted], 
			[IdLead], 
			[IdLeadCommunicationType], 
			[IdLeadCommunicationResult], 
			[Comment], 
			[CommunicationEnd], 
			[IdLeadRejectReason],
			[DWHInsertedDate]
		)
		select 
			[Id], 
			[CreatedOn], 
			[IdOwner], 
			[IsDeleted], 
			[IdLead], 
			[IdLeadCommunicationType], 
			[IdLeadCommunicationResult], 
			[Comment], 
			[CommunicationEnd], 
			[IdLeadRejectReason],
			[DWHInsertedDate]
		
		from tmp.fedor_core_LeadCommunication
	end
end try
begin catch
	;throw
end catch
end


