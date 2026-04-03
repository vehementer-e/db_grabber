
CREATE   proc [dbo].[marketing_strategy_history_creation]
as

 
 --alter table marketing_strategy_history add row_created datetime2(0)
 --delete from     marketing_strategy_history
 --insert into marketing_strategy_history
 if exists (
SELECT 
    a.[id] 
,   a.[name] 
,   a.[description] 
,   a.[module_id] 
,   a.[component_id] 
,   a.[result_mode] 
,   a.[payload] 
,   a.[created_at] 
,   a.[updated_at] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.[created_at_time] 
,   a.[updated_at_time] 
,   a.[UPDATED_BY] 
,   a.[UPDATED_DT] 
,   getdate() row_created 
            FROM 

            Stg._LF.config_mms_processor a
		 left join marketing_strategy_history b on a.[updated_at_time]=b.[updated_at_time] and a.id=b.id
		 where b.id is null
		 )

 insert into marketing_strategy_history
 SELECT 
    a.[id] 
,   a.[name] 
,   a.[description] 
,   a.[module_id] 
,   a.[component_id] 
,   a.[result_mode] 
,   a.[payload] 
,   a.[created_at] 
,   a.[updated_at] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.[created_at_time] 
,   a.[updated_at_time] 
,   a.[UPDATED_BY] 
,   a.[UPDATED_DT] 
,   getdate() row_created 
            FROM 

            Stg._LF.config_mms_processor a


		 if @@rowcount>0 
	
		 
		 begin
		 
declare @result    varchar(max) 
exec exec_python 'from LF.diff_monitoring import get_dif_by_processor
result = ""
for i in run_sql("""select  distinct name   from marketing_strategy_history where updated_at_time>=cast(getdate()-1 as date)""")["name"]:
	dif =  str(get_dif_by_processor(i))
	if len(dif)>=4:
		result += i +" : "+ dif+"\n"


	
	
	',  1, @result output



select replace( replace(@result, '\n', '
'), '\"', '"')

  

  declare @html  nvarchar(max)
   exec sp_html '
select  [name], [description], [updated_at_time]  from marketing_strategy_history  where [updated_at_time]>=cast(getdate()-1 as date)' , default,  @html output	   
    select @html

	set @html = @html +'
	'+
  replace( replace(@result, '\n', '
'), '\"', '"')

	exec msdb.dbo.sp_send_dbmail   
	    @profile_name = null,  
		    @recipients = 'p.ilin@smarthorizon.ru',  
			    @body = @html,  
				    @body_format = 'html',  
					    @subject = '[!] marketing_strategy_history_creation new rows'	




exec python 'from LF.parse_lf import run_parsing
run_parsing()', 1

						end
						 
--exec sp_create_job 'analytics._marketing_strategy_history_creation each 15 min', 'exec dbo.marketing_strategy_history_creation' , '1', '90000', '15'

