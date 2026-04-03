-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 28-02-2019
-- Description:	airflow etl  check_dicts_for_persons
--
-- exec etl.base_etl_check_dicts_for_persons


/*


{'cols': {'staging.v_persons': {'map': {'gender': 'gender'}}}}

*/
-- =============================================
CREATE procedure [etl].[base_etl_check_dicts_for_persons]
as
begin

	SET NOCOUNT ON;
	declare @params nvarchar(1024)=''

	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)

	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      @params

	--log
	begin try



	declare @maxId int

	declare @result nvarchar(max)
	declare @r table ( res nvarchar(max) )
	declare @DictTable     nvarchar(max)
	,       @refTableField nvarchar(max)
	,       @refTable      nvarchar(max)


	set @result=N' Results:<br /><br />'

	--select * from dbo.gender
	SET @refTable ='staging.v_persons'
	SET @refTableField ='gender'
	SET @DictTable ='dbo.gender'



	delete from @r
	insert into @r
	exec etl._dictProcess
	@refTable = @refTable,
	@refTableField = @refTableField,
	@DictTable = @dicttable

	set @result=@result+@DictTable+': '+(select res
	from @r)+'<br />'



	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
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







