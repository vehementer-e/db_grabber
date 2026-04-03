-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 21-03-2019
-- Description:	Insert values into table agent_credits withot access to insert
/*
exec dbo.InsertInto_agent_credits
	@External_id = 17081610170002,
	@group  = 1,
	@date = '20190204',
	@agent_name = 'Prime Collection',
	@end_date =null
    select * from  dbo.agent_credits where External_id = 17081610170002 and [group]  = 1 and date = '20190204' and 	agent_name = 'Prime Collection' and end_date is null
*/
-- =============================================
CREATE PROCEDURE [dbo].[InsertInto_agent_credits]
	@External_id bigint ,
	@group [int] ,
	@date [datetime] ,
	@agent_name [nvarchar](20),
	@end_date [date] 

    WITH EXECUTE AS 'dbo'
AS
BEGIN

    SET NOCOUNT ON;
     
    declare @tsql nvarchar(max)
     
    if object_id('tempdb.dbo.#t') is not null drop table #t
    create table #t (id int)

    set @tsql='
    select  count(*) from dwh_new.dbo.agent_credits
    where 	External_id '           + case when @External_id    is null then    ' is null ' else ' = '      + cast  (@External_id  as nvarchar(50))     end +   ' 
       and [group] '                + case when @group          is null then    ' is null ' else ' = '      + cast  (@group as nvarchar(50))            end +   '
       and cast([date] as date) '   + case when @date           is null then    ' is null ' else ' = '''    + format(@date ,'yyyy-MM-dd')  + ''''       end + ' 
	   and [agent_name] '           + case when @agent_name     is null then    ' is null ' else ' = '''    + cast  (@agent_name as nvarchar(20)) + ''''       end + ' 
	   and [end_date] '             + case when @end_date       is null then    ' is null ' else ' = '''    + format(@end_date ,'yyyy-MM-dd')     + ''''       end 
         
    -- select @tsql
    insert into #t exec (@tsql)

    declare @i int
    select @i=id from #t
    
    if @i>0
    begin
        select 'Запись существует'
        return
    end
       
    insert into dwh_new.dbo.agent_credits
        select @External_id
             , @group
             , @date
             , @agent_name 
             , @end_date

    
END
