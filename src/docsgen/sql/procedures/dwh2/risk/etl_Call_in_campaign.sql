
--exec [risk].[etl_Call_in_campaign]
CREATE PROCEDURE [risk].[etl_Call_in_campaign]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		--Портфель для кампаний на обзвон
		--необходимые данные данные для "урезанного" портфеля
		--№ договора 
		--ФИО 
		--Агент
		--Бакеты 
		--Количество дней ПЗ 
		--Все телефоны
		--База
-------------------------------------------КА
drop table if exists #ka;
select 
Deals.number as external_id
,cast(cat.TransferDate as date) as st_date
,coalesce(cast(cat.ReturnDate as date), '2099-01-01') as end_date
,ags.AgentName as agent_name
,row_number() over (partition by cat.DealId, cat.TransferDate order by coalesce(cast(cat.ReturnDate as date), '2099-01-01') desc) as rn
into #ka
from stg._collection.CollectingAgencyTransfer cat
left join Stg._Collection.Deals Deals
	on Deals.id = cat.DealId
left join stg._Collection.CollectorAgencies ags
	on cat.CollectorAgencyId = ags.Id
;
-------------------------------------------
		drop table if exists #base;
			SELECT a.Number AS [Номер договора]
				,CONCAT_ws (' ', b.LastName, b.[Name], b.MiddleName) AS [ФИО]
				,isnull(ka.agent_name, 'CarMoney') AS [Агент]
				,a.OverdueDays AS [Количество дней ПЗ]
				,RiskDWH.dbo.get_bucket_720(a.OverdueDays) AS [Бакет кол-ва дней ПЗ]
				--a.IdCustomer
				,b.MobilePhone AS [Телефон Мобильный]
				,e.ТелефонОбращения AS [Телефон Обращения]
				,e.ТелефонАдресаПроживания AS [Телефон Адреса Проживания]
				,e.ТелефонСупруги AS [Телефон Супруги]
				,e.КЛТелКонтактный AS [Тел Контактного Лица Контактный]
				,e.КЛТелМобильный AS [Тел Контактного Лица Мобильный]
				,e.ТелефонКонтактныйОсновной AS [Телефон Контактный Основной]
				,e.ТелефонКонтактныйДополнительный AS [Телефон Контактный Дополнительный]
				,e.ТелРабочийРуководителя AS [Тел Рабочий Руководителя]
			INTO #base
			FROM stg._Collection.Deals a
			LEFT JOIN stg._Collection.customers b ON a.IdCustomer = b.Id
			left join #ka ka
				on a.Number = ka.External_id
				and cast(getdate() as date) between ka.st_date and ka.end_date
			--LEFT JOIN dwh_new.dbo.agent_credits c 
			--	ON a.Number = c.External_id
			--	AND cast(getdate() AS DATE) BETWEEN c.st_date AND isnull(c.fact_end_date, '4444-01-01')
			LEFT JOIN stg._Collection.DealStatus d ON a.IdStatus = d.Id
			LEFT JOIN stg._1cMFO.Документ_ГП_Заявка e ON a.Number = e.Номер
			WHERE a.OverdueDays > 0
				AND isnull(d.Name, 'nnn') NOT IN (
					'Аннулирован'
					,'Погашен'
					,'Продан'
					);

		--and a.CurrentAmountOwed + a.DebtSum < 0
		--причесываем телефоны 
		UPDATE a
		SET a.[Телефон Мобильный] = trim(replace(replace(replace(replace(a.[Телефон Мобильный], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Телефон Обращения] = trim(replace(replace(replace(replace(a.[Телефон Обращения], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Телефон Адреса Проживания] = trim(replace(replace(replace(replace(a.[Телефон Адреса Проживания], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Телефон Супруги] = trim(replace(replace(replace(replace(a.[Телефон Супруги], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Тел Контактного Лица Контактный] = trim(replace(replace(replace(replace(a.[Тел Контактного Лица Контактный], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Тел Контактного Лица Мобильный] = trim(replace(replace(replace(replace(a.[Тел Контактного Лица Мобильный], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Телефон Контактный Основной] = trim(replace(replace(replace(replace(a.[Телефон Контактный Основной], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Телефон Контактный Дополнительный] = trim(replace(replace(replace(replace(a.[Телефон Контактный Дополнительный], '(', ''), ')', ''), '-', ''), ' ', ''))
			,a.[Тел Рабочий Руководителя] = trim(replace(replace(replace(replace(a.[Тел Рабочий Руководителя], '(', ''), ')', ''), '-', ''), ' ', ''))
		FROM #base a;

		DECLARE @digit INT = 0;

		WHILE @digit < 10
		BEGIN
			DECLARE @d VARCHAR(1) = cast(@digit AS VARCHAR(1));

			UPDATE a
			SET a.[Телефон Мобильный] = CASE 
					WHEN len(replace(a.[Телефон Мобильный], @d, 'AA')) = 2 * len(a.[Телефон Мобильный])
						THEN ''
					ELSE a.[Телефон Мобильный]
					END
				,a.[Телефон Обращения] = CASE 
					WHEN len(replace(a.[Телефон Обращения], @d, 'AA')) = 2 * len(a.[Телефон Обращения])
						THEN ''
					ELSE a.[Телефон Обращения]
					END
				,a.[Телефон Адреса Проживания] = CASE 
					WHEN len(replace(a.[Телефон Адреса Проживания], @d, 'AA')) = 2 * len(a.[Телефон Адреса Проживания])
						THEN ''
					ELSE a.[Телефон Адреса Проживания]
					END
				,a.[Телефон Супруги] = CASE 
					WHEN len(replace(a.[Телефон Супруги], @d, 'AA')) = 2 * len(a.[Телефон Супруги])
						THEN ''
					ELSE a.[Телефон Супруги]
					END
				,a.[Тел Контактного Лица Контактный] = CASE 
					WHEN len(replace(a.[Тел Контактного Лица Контактный], @d, 'AA')) = 2 * len(a.[Тел Контактного Лица Контактный])
						THEN ''
					ELSE a.[Тел Контактного Лица Контактный]
					END
				,a.[Тел Контактного Лица Мобильный] = CASE 
					WHEN len(replace(a.[Тел Контактного Лица Мобильный], @d, 'AA')) = 2 * len(a.[Тел Контактного Лица Мобильный])
						THEN ''
					ELSE a.[Тел Контактного Лица Мобильный]
					END
				,a.[Телефон Контактный Основной] = CASE 
					WHEN len(replace(a.[Телефон Контактный Основной], @d, 'AA')) = 2 * len(a.[Телефон Контактный Основной])
						THEN ''
					ELSE a.[Телефон Контактный Основной]
					END
				,a.[Телефон Контактный Дополнительный] = CASE 
					WHEN len(replace(a.[Телефон Контактный Дополнительный], @d, 'AA')) = 2 * len(a.[Телефон Контактный Дополнительный])
						THEN ''
					ELSE a.[Телефон Контактный Дополнительный]
					END
				,a.[Тел Рабочий Руководителя] = CASE 
					WHEN len(replace(a.[Тел Рабочий Руководителя], @d, 'AA')) = 2 * len(a.[Тел Рабочий Руководителя])
						THEN ''
					ELSE a.[Тел Рабочий Руководителя]
					END
			FROM #base a;

			SET @digit = @digit + 1
		END;

		--Финальная выборка
		TRUNCATE TABLE risk.Call_in_campaign;

		INSERT INTO risk.Call_in_campaign
		SELECT a.*, getdate() as dt_dml 

		FROM #base a;

	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
