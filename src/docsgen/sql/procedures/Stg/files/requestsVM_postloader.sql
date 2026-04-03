

-- Usage: запуск процедуры с параметрами
-- EXEC [files].[requestsVM_postloader] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE procedure [files].[requestsVM_postloader]

as

begin

 

  set nocount on

 

 delete from [files].[requestsVM]
--where [Номер заявки] in (select [Номер заявки] from [FilesBuffer].files.requestsVM_buffer)

INSERT INTO [files].[requestsVM]
([Дата] ,[Номер заявки] ,[created])


select distinct 
	[Дата] 
	,cast(cast([Номер заявки] as bigint) as nvarchar(50)) [Номер заявки]
	,[created] 
from files.[requestsVM_buffer_stg] 


select 0

end

-- exec [files].[requestsVM_postloader]
