CREATE procedure [riskCollection].[fot_expenses_postloader] as
begin 

BEGIN TRY
BEGIN TRANSACTION

insert into riskCollection.fot_expenses
select 
cast([Период] as date) as [Период]
,Отдел
,cast([Сумма по полю Итого] as money) as [ФОТ руб]
,created
from stg.[files].[fot_expenses] b
where not exists (select [Период] from riskCollection.fot_expenses a where a.[Период] = b.[Период])

COMMIT TRANSACTION;
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
end;