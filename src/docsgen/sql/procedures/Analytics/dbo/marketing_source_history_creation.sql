
CREATE   proc [dbo].[marketing_source_history_creation]
as

 --exec sp_create_job 'analytics. marketing source_history_creation each day at 10:00', 'exec [marketing_source_history_creation]' , '1', '100000'
--drop table if exists marketing_source_history
--select id, source,  channel,  created, updated, 
--   getdate() row_created 
--into marketing_source_history from v_source

insert into marketing_source_history 
select a.id, a.source,  a.channel,  a.created, a.updated, 
getdate() row_created    from v_source a left join marketing_source_history b on a.id=b.id and a.updated=b.updated
where b.updated is null
		 
		 if @@rowcount>0 
	 
		  begin

	   
								  
declare @sql    varchar(max) =   ( select string_agg('
exec exec_python ''sql_to_gmail("""
exec marketing_mail_report_leadgen '''''+source +'''''
""", name = "'+source +'", include_sql = False) '' , 0 ',

 
 ''
 
 
 ) from v_source where created>=getdate()-10 )
  exec  (@sql)




  end
