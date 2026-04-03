CREATE proc dbo.column_get 
@search_string nvarchar(max)
as
begin




   select * from columns_dwh
   where [table & column names] like '%'+@search_string+'%'
   order by   1, 3, 4














end