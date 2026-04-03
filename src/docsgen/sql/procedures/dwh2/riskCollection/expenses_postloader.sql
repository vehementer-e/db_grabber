CREATE procedure [riskCollection].[expenses_postloader] as
begin 

BEGIN TRY

if OBJECT_ID('riskCollection.expenses') is null
begin
	select top(0) * into riskCollection.expenses
	from stg.[files].[expenses]
end;

BEGIN TRANSACTION

insert into riskCollection.expenses
select 
Компания
,[Код статьи расхода]
,[Статья расхода]
,[Группа расходов]
,[ЦФО]
,[Структурное подразделение]
,[Региональное подразделение / Офис]
,[Наименование Контрагента]
,[Наименование Мероприятия / Проекта]
,[Наименование закупаемых ресурсов: ТМЦ, товары, работы услуги] as [Наименование закупаемых ресурсов]
,cast([Период CF] as date) as [Период CF]
,cast(replace ([Факт, руб# (в т#ч# НДС)], ',', '.') as float) as [Факт руб]
,created
from stg.[files].[expenses] b
--where not exists (select [Период CF] from riskCollection.expenses a where a.[Период CF] = b.[Период CF])

COMMIT TRANSACTION;
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
end;