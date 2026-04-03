--files.DeadPersons_postloader
CREATE     procedure [files].[DeadPersons_postloader]
as begin
set nocount on

 --select * into files.DeadPersons  from files.DeadPersons_buffer
 --select *   from files.DeadPersons_buffer


if (select count(*) from files.DeadPersons_buffer)>0
begin

   delete from files.DeadPersons
   insert into files.DeadPersons(
       [дата поступления]
      ,[№ вход#обращения]
      ,[ФИО]
      ,[№ договора ]
      ,[комментарий]
      ,[created]
   )
  select
       [дата поступления]
      ,[№ вход#обращения]
      ,[ФИО]
      ,[№ договора ]
      ,[комментарий]
      ,[created]  
    from files.DeadPersons_buffer

end

  select 0
  
end
