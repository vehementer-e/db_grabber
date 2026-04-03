CREATE  proc [dbo].[sp_birs_update]
@reportId nvarchar(max) 
as
 


  declare @id varchar(36) = newid() 
--drop table   sp_birs_update_log
--select @id id, cast('' as varchar(36)) reportId, getdate() created, 0 isSuccessfull,  cast('' as varchar(max)) descr  into sp_birs_update_log where 1=0

insert into sp_birs_update_log
select @id, @reportId, getdate() , -1, null


begin try


EXEC [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob  @reportId

 
end try
begin catch


print ERROR_MESSAGE()
select  ERROR_MESSAGE()


update sp_birs_update_log set isSuccessfull = 0, descr = ERROR_MESSAGE() where id = @id


select 0 
return
end catch 

update sp_birs_update_log set isSuccessfull = 1   where id = @id


 