-- =============================================
-- Author:		Aleksandr Shubkin
-- Create date: 17.01.25
-- Description: procedure-source for client-contact report
-- Exec example: EXEC [service].[client_contact_report] @StartDate = '2024-01-01', @EndDate   = '2025-01-17'

-- =============================================
create   PROCEDURE [service].[client_contact_report]
	@StartDate DATE = NULL
	, @EndDate DATE = NULL
AS
BEGIN
	
	set @StartDate = isnull(@StartDate, '2000-01-01')
	set @EndDate = dateadd(dd, 1, isnull(@EndDate, getdate()))

	SELECT DISTINCT
		[ФИО]				= hk.[ФИО]
	,	[Статус клиента]	= cst.Name
	,	[№ Договора]		= dz.КодДоговораЗайма
	,	[Дата оформления]	= dz.ДатаДоговораЗайма
	,	[Дата закрытия]		= dz.ДатаЗакрытияДоговора
 	,	[Статус договора]	= dts.ТекущийСтатусДоговора
	,	[Сумма займа]		= dz.СуммаВыдачи 
	,	[Продукт]			= dz.ПодТипПродукта
	,	[Регион проживания]	= reg.РегионФактическогоПроживания
	,	[Адрес эл. почты]	= em.Email
	,	[Телефон]			= tel.НомерТелефонаБезКодов
	,	[Часовой пояс]		= reg.GMTРегионФактическогоПроживания

	FROM  dwh2.hub.Клиенты hk
		INNER JOIN dwh2.link.Клиент_ДоговорЗайма link
	        ON hk.GuidКлиент = link.GuidКлиент
	    INNER JOIN dwh2.[hub].[ДоговорЗайма] dz
	        ON dz.КодДоговораЗайма = link.КодДоговораЗайма
		INNER JOIN dwh2.[sat].[ДоговорЗайма_ТекущийСтатус] dts
			ON dts.GuidДоговораЗайма = dz.GuidДоговораЗайма
			AND dts.ТекущийСтатусДоговора IN ('Зарегистрирован', 'Действует', 'Погашен')
		LEFT JOIN dwh2.[sat].[Клиент_РегионФактическогоПроживания] reg
			ON reg.GuidКлиент = hk.GuidКлиент
		LEFT JOIN dwh2.[sat].[Клиент_Email] em
			ON em.GuidКлиент = hk.GuidКлиент
			AND em.nRow = 1
		LEFT JOIN dwh2.[sat].[Клиент_Телефон] tel
			ON tel.GuidКлиент = hk.GuidКлиент
			AND tel.nRow = 1
		LEFT JOIN Stg._Collection.Customers c
			ON c.CrmCustomerId = hk.GuidКлиент  
		LEFT JOIN Stg._Collection.[CustomerStatus] cs
			ON c.Id = cs.CustomerId 
		LEFT JOIN Stg._Collection.CustomerState cst
			ON cs.CustomerStateId=cst.Id 
	WHERE (dz.ДатаДоговораЗайма BETWEEN @StartDate AND @EndDate)
		AND ((cs.IsActive = 1
		AND cst.Name NOT IN (
		    'Смерть подтвержденная',
		    'Смерть неподтвержденная',
		    'Отказ от взаимодействия по 230 ФЗ',
		    'Взаимодействие через представителя (230-ФЗ)',
		    'Клиент в больнице (230-ФЗ)',
		    'Инвалид 1 группы (230 ФЗ)',
		    'Отказ от обработки ПД (152-ФЗ)', 
		    'FRAUD неподтвержденный',
		    'Fraud подтвержденный', 
		    'HardFraud',
		    'Жалоба',
		    'Отсутствие согласия на обработку ПД',
		    'Алкоголик/наркоман/игроман', 
		    'Банкрот неподтверждённый', 
		    'Банкрот подтверждённый', 
		    'Банкротство завершено', 
		    'Клиент в тюрьме', 
		    'Мобилизован' 
		)) OR c.CrmCustomerId IS NULL)
	ORDER BY dz.ДатаДоговораЗайма DESC
END
