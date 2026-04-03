 

CREATE procedure [files].[requestsVM_postloader_old]

as

begin
 

  set nocount on
 

 

delete from files.requestsVM
where [Номер заявки] in (select [Номер заявки] from files.requestsVM_buffer)

INSERT INTO [files].requestsVM
([Номер заявки]  ,[created])

select distinct cast([Номер заявки] as varchar(30)) [Номер заявки],

[created] 
from files.requestsVM_buffer 

select 0

end
