

create proc [dbo].sp_viewRefresh 

as

begin

 


drop table if exists #sqls





SELECT DISTINCT 'EXEC sp_refreshview ''['+sc.name+'].['+so.name+']'''  [sql]  into #sqls 

FROM sys.objects AS so   

INNER JOIN sys.sql_expression_dependencies AS sed   

    ON so.object_id = sed.referencing_id   

INNER JOIN   sys.schemas sc on sc.schema_id=so.schema_id 

WHERE so.type = 'V' 		

and so.name <> 'v_repayments_�����_2022_11_02'

											  

		

										    



--select * from #sqls



declare @i int = 0

declare @sql nvarchar(max)

declare @error nvarchar(max) = ''



while (select count(*) from #sqls)>0

begin





set @sql = (select top 1 [sql] from #sqls)



--select(@sql)



begin try

exec(@sql)



end

try

begin catch

set @error = @error+@sql+' failed

'

select @error

end catch







delete from #sqls

where [sql] = @sql

end







if @error<>''

begin

exec log_email 'update_views_definition fail', default, @error



select @error

end



end