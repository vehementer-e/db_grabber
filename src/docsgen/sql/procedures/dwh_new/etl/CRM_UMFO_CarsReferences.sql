
--exec etl.CRM_UMFO_CarsReferences

CREATE   procedure [etl].[CRM_UMFO_CarsReferences]
as

set nocount on

  Declare @IsSwitchedUmfo bigint=0;

  -- 1 - новый серврер, 0 - старый линкованный сервер
  set @IsSwitchedUmfo=cast(isnull((SELECT max([IsSwitched]) FROM [Stg].[dbo].[Db_Switch] where id=1),'0') as bigint)

  if (@IsSwitchedUmfo=1)
  begin
	-- выполняем скрипт на новом связанном сервере
	   exec [etl].[CRM_UMFO_CarsReferences_NewDPC]
  end
  else
  begin
	-- выполняем скрипт на старом связанном сервере
		exec [etl].[CRM_UMFO_CarsReferences_OldDPC]
  end


return

-- ниже код который не должен выполняться

SELECT 'Ошибка'
