create proc dbo.[droptmp]
as
begin

declare @sql nvarchar(max)
select @sql = (
 
SELECT string_agg(  'DROP TABLE  if exists  ' + LEFT([name], CHARINDEX('_', [name]) -1) ,  ';')
FROM tempdb.sys.objects
WHERE [name] LIKE '#%'
and  [name] not LIKE '##%'
AND CHARINDEX('_', [name]) > 0
AND [type] = 'U'
AND NOT object_id('tempdb..' + [name]) IS NULL )
 exec (@sql )



 end