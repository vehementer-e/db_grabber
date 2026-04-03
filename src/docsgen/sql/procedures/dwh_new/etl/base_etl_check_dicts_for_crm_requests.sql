-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 28-02-2019
-- Description:	airflow etl check_dicts_for_crm_requests
--
-- exec etl.base_etl_check_dicts_for_crm_requests

-- {'cols': {'staging.crm_requests': {'map': {'status': 'crm_statuses', 'reject_reason': 'crm_reject_reasons'}}}}
/*
 select * from staging.crm_requests
 select min(request_date),max(request_date),status from staging.crm_requests group by status order by 1
 select distinct status from dwh_new.staging.crm_requests
 */
/*

def processDicts(cols, **kwargs):
    ms = MsSqlHook(mssql_conn_id ='new_dwh')
    conn = ms.get_conn()
    cursor = conn.cursor()
    for tbl in cols.keys():
        for col, mapper in cols[tbl]['map'].items():
            st = "select distinct {} from {}".format(col, tbl).replace("None", "Null")
            print(st)
            cursor.execute(st)
            values = cursor.fetchall()
            values = [s[0] for s in values]
            d = getDict(ms, mapper)
            print(d)
            checkDict(values, d, cursor, mapper)
    conn.commit()
    conn.close()

*/

-- before first run
-- drop table dwh_new_dev.dbo.crm_statuses
-- select * into dwh_new_dev.dbo.crm_statuses from dwh_new.dbo.crm_statuses v where created<'20190225'
/*
 select * from dwh_new_dev.dbo.crm_statuses
  select * from dwh_new.dbo.crm_statuses
  */

-- drop table dwh_new_dev.dbo.dbo.crm_reject_reasons
-- select * into dwh_new_dev.dbo.crm_reject_reasons from dwh_new.dbo.crm_reject_reasons where created<'20190101'
-- select * from dwh_new.dbo.crm_reject_reasons 
--select * from dwh_new_dev.dbo.crm_reject_reasons 
-- =============================================
CREATE procedure   [etl].[base_etl_check_dicts_for_crm_requests]
as
begin
	
	SET NOCOUNT ON;
	--log
	

	declare @params nvarchar(1024)=''

	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params

	
begin try  
	declare @maxId int
--crm_statuses
	select  @maxId = isnull(max(id),0) from dbo.crm_statuses

	if object_id ('tempdb.dbo.#crm_statuses') is not null 
		drop table #crm_statuses

	create table #crm_statuses(	id		int identity(1,1),
								name	nvarchar(512)
							   )

	insert into #crm_statuses(name) 
		select  h.status 
		from	dbo.crm_statuses v
				right join 
				(select distinct status from staging.crm_requests where status is not null) h 
				on upper(h.status) =upper(v.name)
		where v.name is null

	insert into dbo.crm_statuses(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from #crm_statuses

-- reject_reason

    --declare @maxId int
	select  @maxId = isnull(max(id),0) from dbo.crm_reject_reasons
	if object_id ('tempdb.dbo.#crm_reject_reasons') is not null 
		drop table #crm_reject_reasons

	create table #crm_reject_reasons(id		int identity(1,1),
					 			 name	nvarchar(512)
							   )

	insert into #crm_reject_reasons(name) 
		select  h.reject_reason
		  from	dbo.crm_reject_reasons v
				right join 
				(select distinct reject_reason from staging.crm_requests where isnull(reject_reason,'')<>'') h 
				on upper(h.reject_reason) =upper(v.name)
		 where v.name is null

	insert into dbo.crm_reject_reasons(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from #crm_reject_reasons

		 declare @result nvarchar(1024)
	     set @result=N' Results:<br /><br />'+
		 'verifiers: '+isnull((select ', '+ isnull(name,'')	from	 #crm_statuses v for xml path('')),'')+'<br />'+
		 'statuses: '+isnull((select ', '+ isnull(name,'')	from	#crm_reject_reasons v for xml path('')),'')+'<br />'
		 
	

		 
		 



		 
exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
end







