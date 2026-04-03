
CREATE     proc [dbo].[get_marketing_lists]
@type nvarchar(max),
@hashed int,
@system nvarchar(max),
@need_of_email int = 1,
@need_of_date int = 0

as
begin
set nocount on


declare @sql nvarchar(max) = 'select '

+ '[Дата] date, '
+ case when @system='google' and @hashed=1 then '[Телефон плюс 7 SHA2_256] phone, ' 
       when @system='google' and @hashed=0 then '[Телефон плюс 7] phone, '
       when @system='yandex' and @hashed=1 then '[Телефон 7 md5] phone, '
       when @system='yandex' and @hashed=0 then '[Телефон 7] phone, '
       when @system='fb' and @hashed=1 then '[Телефон 7 md5] phone, '
       when @system='fb' and @hashed=0 then '[Телефон 7] phone, '
	   else '[Телефон 7] phone, '
  end
+ case when @need_of_email=1 and @system='google' and @hashed=1 then '[email SHA2_256] email, '
       when @need_of_email=1 and @system='google' and @hashed=0 then '[email] email, '
       when @need_of_email=1 and @system='yandex' and @hashed=1 then '[email md5] email, '
       when @need_of_email=1 and @system='yandex' and @hashed=0 then '[email] email, '
       when @need_of_email=1 and @system='fb' and @hashed=1 then '[email md5] email, '
       when @need_of_email=1 and @system='fb' and @hashed=0 then '[email] email, '
	   else '[email] email, '
  end
+

'  Тип' +
', created' +
'  FROM [Analytics].[dbo].[v_marketing_lists] where  [Тип] = '''+@type+''''


--select @sql
exec (@sql)


--GRANT EXECUTE ON  analytics.dbo.[get_marketing_lists] TO ReportViewer;



end

