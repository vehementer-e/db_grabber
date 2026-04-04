--checked 12.03.2020
--exec [_LCRM].[LaunchControl2DWH]
-- Usage: запуск процедуры с параметрами
-- EXEC [_LCRM].[LaunchControl2DWH];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE     procedure [_LCRM].[LaunchControl2DWH]
as
begin

set nocount on

       
declare @query nvarchar(max)
declare @tsql nvarchar(max)
declare @ii bigint=0
      , @prev_i bigint =-1
	  , @countError bigint=0

--set @ii=cast(isnull((select min(id) from staging.lcrm_tbl_full  where UF_UPDATED_AT>@dt ),'0') as bigint)
set @ii=cast(isnull((select max(id) from _lcrm.b_user_field_enum ),'0') as bigint)
select @ii

while @ii<>@prev_i
begin
begin try
set @prev_i=@ii
       begin tran
    set @query=N'select c1.* 
                   from  b_user_field_enum c1
                   join  (select id from b_user_field_enum   c2  
                           where  c2.id> '''''+format(@ii,'0')+'''''     
                           order by c2.id
                           limit 100000) c2 
                     on c2.id=c1.id
                ' 
set @tsql='insert INTO _lcrm.b_user_field_enum select *   from OPENQUERY(LCRM,'''+@query+''')'
--select @tsql

exec (@tsql)
/*
 
*/
set @ii=cast(isnull((select max(id) from _lcrm.b_user_field_enum ),'0') as bigint)

select @ii
commit tran

end try
begin catch
--if @@TRANCOUNT>0 commit tran
set @prev_i=-1

	if @@TRANCOUNT>0 ROLLBACK TRANSACTION;

	Set @countError = @countError + 1
	select @countError
	-- для теста укажем 10
	if (@countError>10)
		begin 

	

			-- даем время сохранить лог
			WAITFOR DELAY '00:00:03'; 
			--1exec LogDb.[dbo].[LogAndSendMailToAdmin] ' etl.load_lcrm_data_full_2d','Error','procedure load data b_user_field_enum cycle exceeded ','';

			-- выходим с исключением
			THROW;

		end

end catch



IF @@TRANCOUNT > 0  
	begin
		COMMIT TRANSACTION; 
		--select 'COMMIT TRANSACTION; '
		--return
	end

end




  set  @ii =0
  set  @prev_i =-1
  Set @countError = 0


--set @ii=cast(isnull((select min(id) from staging.lcrm_tbl_full  where UF_UPDATED_AT>@dt ),'0') as bigint)
--set @ii=cast(isnull((select max(id) from _lcrm.carmoney_light_crm_launch_control ),'0') as bigint)

----test
--declare @query nvarchar(max)
--declare @tsql nvarchar(max)
--declare @ii bigint=0
--      , @prev_i bigint =-1
--	  , @countError bigint=0

-- 21.02.2020 
-- перепишем код, для того, чтобы перетереть данные за последние 2 дня 
declare @dt datetime
set @dt= dateadd(hour, 20, cast(dateadd(day,-3,cast(getdate() as date)) as datetime2) ) 

set @ii=cast(isnull((select max(id) from _lcrm.carmoney_light_crm_launch_control where UF_UPDATED_AT<@dt),'795411491') as bigint) -1
--202842084

--select @ii   --203951934 202887779

--test

--delete  from _lcrm.carmoney_light_crm_launch_control_upd where id>@ii
truncate table  _lcrm.carmoney_light_crm_launch_control_upd 

while @ii<>@prev_i
begin
begin try
set @prev_i=@ii
       begin tran
    set @query=N'select c1.* 
                   from  carmoney_light_crm_launch_control c1
                   join  (select id from carmoney_light_crm_launch_control   c2  
                           where  c2.id> '''''+format(@ii,'0')+'''''     
                           order by c2.id
                           limit 100000) c2 
                     on c2.id=c1.id
                ' 

 set @tsql='INSERT INTO _lcrm.carmoney_light_crm_launch_control_upd with(tablockx)  select *  from OPENQUERY(LCRM,'''+@query+''')'

--select @tsql

exec (@tsql)
/*
 
*/

set @ii=cast(isnull((select max(id) from _lcrm.carmoney_light_crm_launch_control_upd ),'795411491') as bigint)

--set @ii=cast(isnull((select max(id) from staging.lcrm_tbl_full),'0') as bigint)
select @ii
commit tran


end try
begin catch
select 'catch error!'
--if @@TRANCOUNT>0 commit tran
set @prev_i=-1

	if @@TRANCOUNT>0 ROLLBACK TRANSACTION;

	Set @countError = @countError + 1
	select @countError
	-- для теста укажем 10
	if (@countError>10)
		begin 

	

			-- даем время сохранить лог
			WAITFOR DELAY '00:00:03'; 
			--1exec LogDb.[dbo].[LogAndSendMailToAdmin] ' etl.load_lcrm_data_full_2d','Error','procedure load data carmoney_light_crm_launch_control cycle exceeded ','';

			-- выходим с исключением
			THROW;

		end

end catch



IF @@TRANCOUNT > 0  
	begin
		COMMIT TRANSACTION; 
		--select 'COMMIT TRANSACTION; '
		--return
	end

end



begin tran

delete
--select 
--count(*)
from _lcrm.carmoney_light_crm_launch_control
where id in (select id from   _lcrm.carmoney_light_crm_launch_control_upd)

insert into _lcrm.carmoney_light_crm_launch_control
select * from _lcrm.carmoney_light_crm_launch_control_upd

commit tran 

--1exec LogDb.[dbo].[LogAndSendMailToAdmin] ' etl.load_lcrm_data_full_2d','info','procedure load data carmoney_light_crm_launch_control finished ','';

end
