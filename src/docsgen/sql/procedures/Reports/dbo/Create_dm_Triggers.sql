
--exec [dbo].[Create_dm_Triggers]

CREATE   procedure [dbo].[Create_dm_Triggers] 
as
begin

set nocount on


	-- соберем все в одну таблицу

	--truncate table  dbo.dm_Triggers

	delete from dbo.dm_Triggers where Year(ДатаСработки) >= 4020

	insert into     dbo.dm_Triggers
   -- витрина по триггерам НБКИ
	Select  
		'НБКИ' as  'Бюро'
		, trigg.Дата as  'ДатаСработки'
		, clients.Ссылка 'КлиентСсылка'
		, trigg.НомерТриггера 'Тип триггера'
		, 0 as 'Сумма запроса'
		, NULL as 'Назначение'
		, NULL as 'Валюта'
	--into     dbo.dm_Triggers
	FROM   [Stg].[_1CIntegration].[РегистрСведений_ТриггерыНБКИ] trigg
	left join  [Stg].[_1CIntegration].[Справочник_КлиентыТриггерыНБКИ] clients
	on trigg.Клиент = clients.Ссылка
	where Year(trigg.Дата) >=4020
	group by trigg.Дата, clients.Ссылка,  trigg.НомерТриггера


	-- данные по сигналу 16 из НБКИ
	insert into     dbo.dm_Triggers
		Select  
		'НБКИ' as  'Бюро'
		, trigg.Дата as  'ДатаСработки'
		, clients.Ссылка 'КлиентСсылка'
		, trigg.НомерТриггера 'Тип триггера'
		, Сумма as 'Сумма запроса'
		, НазначениеКод as 'Назначение'
		, Валюта as 'Валюта'
	--into     dbo.dm_Triggers
	FROM   stg.[_1cIntegration].РегистрСведений_ТриггерыНБКИЗапросы  trigg
	left join  [Stg].[_1CIntegration].[Справочник_КлиентыТриггерыНБКИ] clients
	on trigg.Клиент = clients.Ссылка
	where Year(trigg.Дата) >=4020
	--group by trigg.Дата, clients.Ссылка,  trigg.НомерТриггера
	


		-- Эквифакс
	insert into     dbo.dm_Triggers
	SELECT  --top 100 
	'Эквифакс' as  'Бюро'
	, ЭквифаксТриггеры.Период  as  'ДатаСработки'
    , Клиент.Ссылка'КлиентСсылка'
	, ЭквифаксТриггеры.ИдТриггера 'Тип триггера'
	, 0 as 'Сумма запроса'
	, NULL as 'Назначение'
	, NULL as 'Валюта'
	from  [Stg].[_1CIntegration].[РегистрСведений_ДанныеПоЗолотымКлиентам] ЭквифаксТриггеры
	left join [Stg].[_1CIntegration].[Справочник_КлиентыТриггерыНБКИ] Клиент
	on  (Клиент.[Паспортсерия] + Клиент.[Паспортномер])  = ЭквифаксТриггеры.СерияИНомерДокумента
	
	where  year(ЭквифаксТриггеры.Период) = 4020
	--and СерияИНомерДокумента <> ''
    group by ЭквифаксТриггеры.Период , Клиент.Ссылка, ЭквифаксТриггеры.ИдТриггера
	


end
