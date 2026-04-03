
-- =============================================
-- Author:		a.kotelevec
-- Create date: <Create Date,,>
-- Description:	DWH-1338 Создание отдельных таблиц с кейсами и сессиями по проектам "Комиссии"
-- =============================================
CREATE   procedure [dbo].[fill_dm_report_commissions_mv_call_case]
	@reloadDay int = 14 
as
begin

drop table if exists #t_data
drop table if exists #NaumenProjects
select distinct [ProjectUUID] into #NaumenProjects FROM [Stg].[_mds].[NaumenProjects_commissions_prod]

select [uuid], 
	[history], 
	[priority], 
	[creationdate], 
	[projectuuid], 
	[projecttitle], 
	[clientuuid], 
	[clienttitle], 
	[stateuuid], 
	[statetitle], 
	[operatoruuid], 
	[operatortitle], 
	[casecomment], 
	[lasthistoryitem], 
	[operatorfirstname], 
	[operatormiddlename], 
	[operatorlastname], 
	[operatoremail], 
	[operatorinternalphonenumber], 
	[operatorworkphonenumber], 
	[operatormobilephonenumber], 
	[operatorhomephonenumber], 
	[operatordateofbirth], 
	[totalnumberofphones], 
	[numberofbadphones], 
	[plannedphonetime], 
	[lastcall], 
	[removed], 
	[removaldate], 
	[phonenumbers], 
	[email], 
	[stringvalue1], 
	[stringvalue2], 
	[uploadstate], 
	[uploadeddate], 
	[modifieddate], 
	[allowedtimefrom], 
	[allowedtimeto], 
	[finisheddate], 
	[timezone]
into #t_data
from naumendbreport.dbo.mv_call_case cc with(nolock)

where exists (select top(1) 1 
from #NaumenProjects t
where cc.projectuuid = t.ProjectUUID
)
and cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)



begin try
	declare @dt datetime=getdate()
	declare @batcSize int =100000
	if OBJECT_ID('dbo.dm_report_commissions_mv_call_case') is null
	begin
		select top(0)
		*
		,[loaded_into_reports] = @dt
		into dbo.dm_report_commissions_mv_call_case
		from #t_data
	end

	begin tran 
	--удаляем данные за указанный час на случай перезагрузки данных
	
	delete top(@batcSize) from dbo.dm_report_commissions_mv_call_case
	where	cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)
	
	
	WHILE @@ROWCOUNT > 0
	BEGIN
		delete top(@batcSize) from dbo.dm_report_commissions_mv_call_case
		where cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)
	END

	insert into dbo.dm_report_commissions_mv_call_case
	(
		[uuid], 
		[history], 
		[priority], 
		[creationdate], 
		[projectuuid], 
		[projecttitle], 
		[clientuuid], 
		[clienttitle], 
		[stateuuid], 
		[statetitle], 
		[operatoruuid], 
		[operatortitle], 
		[casecomment], 
		[lasthistoryitem], 
		[operatorfirstname], 
		[operatormiddlename], 
		[operatorlastname], 
		[operatoremail], 
		[operatorinternalphonenumber], 
		[operatorworkphonenumber], 
		[operatormobilephonenumber], 
		[operatorhomephonenumber], 
		[operatordateofbirth], 
		[totalnumberofphones], 
		[numberofbadphones], 
		[plannedphonetime], 
		[lastcall], 
		[removed], 
		[removaldate], 
		[phonenumbers], 
		[email], 
		[stringvalue1], 
		[stringvalue2], 
		[uploadstate], 
		[uploadeddate], 
		[modifieddate], 
		[allowedtimefrom], 
		[allowedtimeto], 
		[finisheddate], 
		[timezone], 
		[loaded_into_reports]
	)
	select [uuid], 
		[history], 
		[priority], 
		[creationdate], 
		[projectuuid], 
		[projecttitle], 
		[clientuuid], 
		[clienttitle], 
		[stateuuid], 
		[statetitle], 
		[operatoruuid], 
		[operatortitle], 
		[casecomment], 
		[lasthistoryitem], 
		[operatorfirstname], 
		[operatormiddlename], 
		[operatorlastname], 
		[operatoremail], 
		[operatorinternalphonenumber], 
		[operatorworkphonenumber], 
		[operatormobilephonenumber], 
		[operatorhomephonenumber], 
		[operatordateofbirth], 
		[totalnumberofphones], 
		[numberofbadphones], 
		[plannedphonetime], 
		[lastcall], 
		[removed], 
		[removaldate], 
		[phonenumbers], 
		[email], 
		[stringvalue1], 
		[stringvalue2], 
		[uploadstate], 
		[uploadeddate], 
		[modifieddate], 
		[allowedtimefrom], 
		[allowedtimeto], 
		[finisheddate], 
		[timezone], 
		[loaded_into_reports] = @dt
	from #t_data
	
	commit tran
end try
begin catch
	IF XACT_STATE() <>0
	BEGIN
		ROLLBACK TRAN
	END
	;throw
end catch
end

