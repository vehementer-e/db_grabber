-- =============================================
-- Author:		shubkin aleksandr
-- Create date: 13.02.2026
-- Description:	Процедура для сборки набора данных
--				для отчета по подписанным документам
--				за указанный период
-- =============================================
-- USAGE: exec	reports.[risk].report_signedDocs_loadedPhotos 
-- =============================================
CREATE     PROCEDURE [risk].[report_signedDocs_loadedPhotos] 
	@dtFrom  date = NULL,
	@dtTo    date = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @dtFrom is null or @dtTo is null
	begin
		SET @dtTo   = CAST(GETDATE() AS date);
		SET @dtFrom = DATEADD(day, -3, @dtTo);
	end
	
	-- только заявки дошедшие до договоров
	DROP TABLE IF EXISTS #t_base;
	SELECT
		req.GuidЗаявки,
		[Номер Заявки]  = req.НомерЗаявки,                   
		[Продукт]	    = product_type.Наименование,         
		[Сумма кредита] = cast(dz.СуммаВыдачи as money), 
		[Id точки, на которой выполнялась загрузка документов]  = link_office.Наименование
	INTO #t_base
	FROM dwh2.hub.Заявка as req
	INNER JOIN dwh2.link.ДоговорЗайма_Заявка as  link_dz_r
		ON req.GuidЗаявки = link_dz_r.GuidЗаявки
	INNER JOIN dwh2.hub.ДоговорЗайма as dz
		ON dz.КодДоговораЗайма = link_dz_r.КодДоговораЗайма
	INNER JOIN dwh2.link.ТипКредитногоПродукта_Заявка as link_product_type_req
		ON link_product_type_req.GuidЗаявки = req.GuidЗаявки
	INNER JOIN dwh2.hub.ТипКредитногоПродукта as product_type
		ON link_product_type_req.GuidТипКредитногоПродукта = product_type.GuidТипКредитногоПродукта
	LEFT JOIN dwh2.[link].[v_Офис_Заявка] link_office 
		ON req.GuidЗаявки = link_office.GuidЗаявки
	WHERE 1 = 1
	  AND req.ДатаЗаявки >= @dtFrom
	  AND req.ДатаЗаявки <  @dtTo;
	--

	-- фотки: 1 строка на 1 заявку
	DROP TABLE IF EXISTS #t_photos;
	SELECT
		b.GuidЗаявки,
		has_pass_2_3		= MAX(CASE WHEN photo_type.file_bind = 'pass2_3' THEN 1 ELSE 0 END),
		has_pass_act_reg	= MAX(CASE WHEN photo_type.file_bind = 'passActuallyRegistration' THEN 1 ELSE 0 END),
		has_foto_client		= MAX(CASE WHEN photo_type.file_bind = 'foto_client' THEN 1 ELSE 0 END)
	INTO #t_photos
	FROM #t_base as b
	LEFT JOIN dwh2.link.Заявка_ТипЗагружаемойФотографии as link_photo_type
		ON link_photo_type.GuidЗаявки = b.GuidЗаявки
	LEFT JOIN dwh2.hub.ТипЗагружаемойФотографии as photo_type
		ON link_photo_type.GuidТипЗагружаемойФотографии = photo_type.GuidТипЗагружаемойФотографии
	LEFT JOIN dwh2.sat.link_Заявка_ТипЗагружаемойФотографии as sat_request_photo_type
		ON sat_request_photo_type.GuidLink_Заявка_ТипЗагружаемойФотографии = link_photo_type.GuidLink_Заявка_ТипЗагружаемойФотографии
	  AND sat_request_photo_type.file_id IS NOT NULL
	GROUP BY b.GuidЗаявки;

	-- документы
	DROP TABLE IF EXISTS #t_docs;
	SELECT
		b.GuidЗаявки,

		--Анкета 
		MAX(CASE WHEN td.Наименование LIKE N'%Анкета%' THEN 1 ELSE 0 END) AS req_anketa,
		MAX(CASE WHEN td.Наименование LIKE N'%Анкета%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_anketa,

		--График платежей 
		MAX(CASE WHEN td.Наименование LIKE N'%График%платеж%' THEN 1 ELSE 0 END) AS req_schedule,
		MAX(CASE WHEN td.Наименование LIKE N'%График%платеж%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_schedule,

		--Индивидуальные условия 
		MAX(CASE WHEN td.Наименование LIKE N'%Индивидуальн%услов%' THEN 1 ELSE 0 END) AS req_indiv,
		MAX(CASE WHEN td.Наименование LIKE N'%Индивидуальн%услов%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_indiv,

		--Договор микрозайма
		MAX(CASE WHEN td.Наименование LIKE N'%Договор%микрозайм%' THEN 1 ELSE 0 END) AS req_micro,
		MAX(CASE WHEN td.Наименование LIKE N'%Договор%микрозайм%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_micro,

		--Согласие на передачу данных третьим лицам 
		MAX(CASE WHEN td.Наименование LIKE N'%передач%данн%третьим лиц%' THEN 1 ELSE 0 END) AS req_share_3rd,
		MAX(CASE WHEN td.Наименование LIKE N'%передач%данн%третьим лиц%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_share_3rd,

		--Согласие на получение рекламных сообщений
		MAX(CASE WHEN td.Наименование LIKE N'%рекламн%сообщ%' THEN 1 ELSE 0 END) AS req_ads,
		MAX(CASE WHEN td.Наименование LIKE N'%рекламн%сообщ%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_ads,

		-- Согласие на передачу ПД третьим лицам
		MAX(CASE WHEN td.Наименование  like N'%передач%персонал%латежн%' THEN 1 ELSE 0 END) AS req_pd_ps,
		MAX(CASE WHEN td.Наименование  like N'%передач%персонал%латежн%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_pd_ps,

		-- Договор залога
		MAX(CASE WHEN td.Наименование LIKE N'%Договор%залога%' THEN 1 ELSE 0 END) AS req_pledge,
		MAX(CASE WHEN td.Наименование LIKE N'%Договор%залога%' AND s.pep_document_status = 1 THEN 1 ELSE 0 END) AS sign_pledge

	INTO #t_docs
	FROM #t_base b
	LEFT JOIN dwh2.link.Заявка_ТипДокументаНаПодпись l
		ON l.GuidЗаявки = b.GuidЗаявки
	LEFT join dwh2.hub.ТипДокументаНаПодпись as td
			on td.GuidТипДокументаНаПодпись = l.GuidТипДокументаНаПодпись
	LEFT JOIN dwh2.sat.link_Заявка_ТипДокументаНаПодпись s
		ON s.GuidLink_Заявка_ТипДокументаНаПодпись = l.GuidLink_Заявка_ТипДокументаНаПодпись
	GROUP BY b.GuidЗаявки;

	DROP TABLE IF EXISTS #t_report;
	SELECT
		b.[Номер Заявки],
		b.[Продукт],
		b.[Сумма кредита],

		[Паспорт.Разворот с фотографией (2-3 стр)]													= CASE WHEN p.has_pass_2_3 = 1 THEN N'Фото загружено' ELSE N'Фото не загружено' END,
		[Паспорт.Прописка с последней печатью регистрации]											= CASE WHEN p.has_pass_act_reg = 1 THEN N'Фото загружено' ELSE N'Фото не загружено' END,
		[Клиент.Фотография клиента]																	= CASE WHEN p.has_foto_client = 1 THEN N'Фото загружено' ELSE N'Фото не загружено' END,

		[Анкета]																					= CASE WHEN d.req_anketa = 0 THEN N'Документ не запрашивался' WHEN d.sign_anketa = 1 THEN N'Да' ELSE N'Нет' END,
		[График платежей]																			= CASE WHEN d.req_schedule = 0 THEN N'Документ не запрашивался' WHEN d.sign_schedule = 1 THEN N'Да' ELSE N'Нет' END,
		[Индивидуальные условия]																	= CASE WHEN d.req_indiv = 0 THEN N'Документ не запрашивался' WHEN d.sign_indiv = 1 THEN N'Да' ELSE N'Нет' END,
		[Договор микрозайма]																		= CASE WHEN d.req_micro = 0 THEN N'Документ не запрашивался' WHEN d.sign_micro = 1 THEN N'Да' ELSE N'Нет' END,
		[Согласие на передачу данных третьим лицам]													= CASE WHEN d.req_share_3rd = 0 THEN N'Документ не запрашивался' WHEN d.sign_share_3rd = 1 THEN N'Да' ELSE N'Нет' END,
		[Согласие на получение рекламных сообщений]													= CASE WHEN d.req_ads = 0 THEN N'Документ не запрашивался' WHEN d.sign_ads = 1 THEN N'Да' ELSE N'Нет' END,
		[Согласие на передачу персональных данных третьим лицам (платежные системы и дом. услуги)]	= CASE WHEN d.req_pd_ps = 0 THEN N'Документ не запрашивался' WHEN d.sign_pd_ps = 1 THEN N'Да' ELSE N'Нет' END,
		[Договор залога]																			= CASE WHEN d.req_pledge = 0 THEN N'Документ не запрашивался' WHEN d.sign_pledge = 1 THEN N'Да' ELSE N'Нет' END,
		[Id точки, на которой выполнялась загрузка документов]										
	INTO #t_report
	FROM #t_base b
	LEFT JOIN #t_photos p ON p.GuidЗаявки = b.GuidЗаявки
	LEFT JOIN #t_docs   d ON d.GuidЗаявки = b.GuidЗаявки;

	SELECT *,
		--[Id точки, на которой выполнялась загрузка документов]  = NULL,
		[Логин партнера, выполнившего загрузку документов]		= NULL
	FROM #t_report
	ORDER BY [Номер Заявки];
END
