-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 27-02-2019
-- Description:	airflow etl  check_dicts_for_requests_history
--
-- exec etl.base_etl_check_dicts_for_requests_history

-- {'cols': {'staging.requests_history': {'map': {'verifier': 'verifiers', 'status': 'statuses', 'reject_reason': 'reject_reasons'}}}}

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
-- select * into dwh_new_dev.dbo.verifiers from dwh_new.dbo.verifiers v where created<'20190225'
-- select * into dwh_new_dev.dbo.statuses from dwh_new.dbo.statuses v where created<'20190225'
-- select * into dwh_new_dev.dbo.reject_reasons from dwh_new.dbo.reject_reasons where created<'20190101'
-- =============================================
CREATE procedure   [etl].[base_etl_check_dicts_for_requests_history]
as
begin
	
	SET NOCOUNT ON;
	--log
	declare @params nvarchar(1024)=''

	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',@params
	

 begin try 
	declare @maxId int
--verifiers
	select  @maxId = isnull(max(id),0) from dbo.verifiers

	if object_id ('tempdb.dbo.#verifiers') is not null 
		drop table #verifiers

	create table #verifiers(id		int identity(1,1),
							name	nvarchar(512)
						   )

	insert into #verifiers(name) 
		select  h.verifier 
		from	dbo.verifiers v
				right join 
				(select distinct verifier=upper(verifier) from staging.requests_history where verifier is not null) h 
				on upper(h.verifier) =upper(v.name)
		where v.name is null

	insert into dbo.verifiers(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from #verifiers

--statuses

	select  @maxId = isnull(max(id),0) from dbo.statuses
	if object_id ('tempdb.dbo.#statuses') is not null 
		drop table #statuses

	create table #statuses(id		int identity(1,1),
							name	nvarchar(512)
						   )

	insert into #statuses(name) 
		select  h.status 
		from	dbo.statuses v
			right join 
				(select distinct status=status from staging.requests_history where status is not null) h 
				on upper(h.status) =upper(v.name)
		where v.name is null

	insert into dbo.statuses(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from #statuses


-- reject_reason

	select  @maxId = isnull(max(id),0) from dbo.reject_reasons
	if object_id ('tempdb.dbo.#reject_reasons') is not null 
		drop table #reject_reasons

	create table #reject_reasons(id		int identity(1,1),
					 			 name	nvarchar(512)
							   )

	insert into #reject_reasons(name) 
		select  h.reject_reason
		  from	dbo.reject_reasons v
				right join 
				(select distinct reject_reason from staging.requests_history where reject_reason is not null) h 
				on upper(h.reject_reason) =upper(v.name)
		 where v.name is null

	insert into dbo.reject_reasons(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from #reject_reasons

		 declare @result nvarchar(1024)
	     set @result=N' Results:<br /><br />'+
		 'verifiers: '+isnull((select ', '+ isnull(name,'')	from	#verifiers v for xml path('')),'')+'<br />'+
		 'statuses: '+isnull((select ', '+ isnull(name,'')	from	#statuses v for xml path('')),'')+'<br />'+
		 'reject_reasons: '+isnull((select ', '+ isnull(name,'')	from	#reject_reasons v for xml path('')),'')+'<br />'
		 --select @result
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
end







