-- =============================================
-- Author:		a.kotelevec
-- Create date: <Create Date,,>
-- Description:	DWH-805 Создание отдельных таблиц с кейсами и сессиями повторников и докредов
-- =============================================
CREATE procedure [dbo].[fill_dm_report_DIP_mv_call_case]
	@reloadDay int = 14 
as
begin

drop table if exists #t_data
drop table if exists #NaumenProjects_DokrNPovt_prod
select [ProjectUUID] into #NaumenProjects_DokrNPovt_prod FROM [Stg].[_mds].[NaumenProjects_DokrNPovt_prod]
union
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

				,('corebo00000000000oe3p1ashjvi3rho')--код проекта по повторникам инстолмент
				,('corebo00000000000oe3p4rec7ip91ks')--Перезвоны по повторникам
				--new
				,('corebo00000000000palmbv48njpfhp8') --CRM Повторники Инст
				,('corebo00000000000palmcvs9gpenh84') --CRM Повторники Инст Перезвон


			) t(project_id)
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
from naumendbreport.dbo.mv_call_case with(nolock)

where projectuuid in( 
select ProjectUUID from #NaumenProjects_DokrNPovt_prod

)
and cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)



begin try
	declare @dt datetime=getdate()
	declare @batcSize int =100000

	begin tran 
	--удаляем данные за указанный час на случай перезагрузки данных
	
	delete top(@batcSize) from dbo.dm_report_DIP_mv_call_case
	where	cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)
	
	
	WHILE @@ROWCOUNT > 0
	BEGIN
		delete top(@batcSize) from dbo.dm_report_DIP_mv_call_case
		where cast([creationdate] as date)>=cast(dateadd(dd, -@reloadDay, getdate())  as date)
	END

	insert into dbo.dm_report_DIP_mv_call_case
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

