Create procedure [etl].[_dictProcess]

 @refTable		nvarchar(max)='staging.v_requests',
 @refTableField nvarchar(max)='point_of_sale',
 @DictTable		nvarchar(max)='dbo.points_of_sale'
 as 
 begin

 set nocount on;

declare @tsql nvarchar(max)=''
set @tsql='
declare @maxId int
	select  @maxId = isnull(max(id),0) from '+@DictTable+'
	
	;with  h as (select distinct name='+@refTableField+' from '+@refTable+' where isnull('+@refTableField+','''')<>'''') 
	,dict as(  select  row_number() over (order by (select null)) id 
					  , h.name
				from	'+@DictTable+' v 
						right join  h on upper(h.name) =upper(v.name)
				where	v.name is null
			)
	insert into '+@DictTable+'(id,name,created,is_active)
		select @maxid+id,name,current_timestamp,1 from dict

'

--select @tsql
exec (@tsql)


set  @tsql=' select isnull(
						(
						 select '', ''+ isnull(name,'''')	
						 from	'+@DictTable+' v for xml path('''')
						 )
					,''''
					)
'

--select @tsql
exec (@tsql)


end
