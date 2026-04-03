create procedure _collection.DWH2Collection_dm_MPUsers
as
begin
	
execute as login='sa'
declare @dt_space datetime = (select max_d from 
 OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL;Trusted_Connection=yes;','
    select 
max(date_active) max_d

      from [collection].dbo.[dm_MPUsers] b
'       )
)
select @dt_space
 insert into   
 
-- select * from 
 OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL;Trusted_Connection=yes;','
    select *
      from [collection].dbo.[dm_MPUsers] b
'       )

select 
login,name=isnull(name,''),	date_active,	agreement_num,	agreement_date

 from Reports.dbo.dm_MPUsersAuthDt where date_active>@dt_space
end