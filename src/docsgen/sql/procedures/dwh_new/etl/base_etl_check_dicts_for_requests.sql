-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 28-02-2019
-- Description:	airflow etl  check_dicts_for_requests
--
-- exec etl.base_etl_check_dicts_for_requests


/*
{'cols': {'staging.v_requests': {'map': {'product': 'products', 'point_of_sale': 'points_of_sale', 'prelending': 'prelending', 'chanel': 'chanels', 'method_of_issuing': 'methods_of_issuing'}}}}

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
-- drop table dwh_new_dev.dbo.products
-- select * into dwh_new_dev.dbo.products from dwh_new.dbo.products v where created<'20190225'
-- select * from products
--
-- select distinct point_of_sale from staging.v_requests
-- insert into  dwh_new_dev.dbo.points_of_sale select   *  from dwh_new.dbo.points_of_sale
-- truncate table  dbo.points_of_sale
-- =============================================
CREATE procedure [etl].[base_etl_check_dicts_for_requests]
as
begin

	SET NOCOUNT ON;
	--log
	declare @params nvarchar(1024)=''

	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      @params


	begin try

	declare @maxId int
	--products
	select @maxId = isnull(max(id),0)
	from dbo.products

	if object_id ('tempdb.dbo.#products') is not null
		drop table #products

	create table #products ( id   int identity(1,1)
	,                        name nvarchar(512) )

	insert into #products ( name )
	select h.name
	from       dbo.products           v
	right join (select distinct name=product
		from staging.v_requests
		where isnull(product,'')<>'') h on upper(h.name) =upper(v.name)
	where v.name is null

	insert into dbo.products ( id, name, created, is_active )
	select @maxid+id
	,      name
	,      current_timestamp
	,      1
	from #products

	--select * into dwh_new_dev.dbo.prelending from dwh_new.dbo.prelending


	declare @result nvarchar(max)
	declare @r table ( res nvarchar(max) )
	declare @DictTable     nvarchar(max)
	,       @refTableField nvarchar(max)
	,       @refTable      nvarchar(max)


	set @result=N' Results:<br /><br />'


	SET @refTable ='staging.v_requests'
	SET @refTableField ='prelending'
	SET @DictTable ='dbo.prelending'



	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'

	SET @refTable ='staging.v_requests'
	SET @refTableField ='point_of_sale'
	SET @DictTable ='dbo.points_of_sale'

	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'




	--select distinct chanel from staging.v_requests
	--select * into dbo.chanels from dwh_new.dbo.chanels

	SET @refTable ='staging.v_requests'
	SET @refTableField ='chanel'
	SET @DictTable ='dbo.chanels'

	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'
	--select @result





	--select distinct chanel from staging.v_requests
	--select * into dbo.chanels from dwh_new.dbo.chanels

	SET @refTable ='staging.v_requests'
	SET @refTableField ='chanel'
	SET @DictTable ='dbo.chanels'

	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'
	--select @result

	--select distinct method_of_issuing from staging.v_requests
	--select * into dbo.methods_of_issuing from dwh_new.dbo.methods_of_issuing

	SET @refTable ='staging.v_requests'
	SET @refTableField ='method_of_issuing'
	SET @DictTable ='dbo.methods_of_issuing'

	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'
	--select @result




	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                        'Info'
	,                                        'procedure finished'
	,                                        @result
	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch
end







