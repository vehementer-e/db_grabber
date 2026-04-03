-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 2025-10-12
-- Description:	Процедура для сбора набора данных для отчета по айпи
-- =============================================
/*
 USAGE: exec 	reports.collection.report_ip4FraudDetection @dtFrom = '2025-12-01', @dtTo = '2025-12-01'
USAGE: exec 	reports.collection.report_ip4FraudDetection @dtFrom = '2025-12-01', @dtTo = '2025-12-01', @contract_num = '25120103909502', @ip_address = '185.169.101.142' 
USAGE: exec 	reports.collection.report_ip4FraudDetection  @contract_num = '25120103909502', @ip_address = '185.169.101.142' 
USAGE:
		exec 	reports.collection.report_ip4FraudDetection  
			@ip_address = '185.169.101.142' 
USAGE:
		exec 	reports.collection.report_ip4FraudDetection  
			@contract_num = '25120103909502'
*/
-- =============================================
CREATE   PROCEDURE [collection].[report_ip4FraudDetection]
	@contract_num nvarchar(25) = null,
	@ip_address nvarchar(255) = null,
	@dtFrom datetime = null,
	@dtTo datetime = null
WITH RECOMPILE  
AS
BEGIN
	SET NOCOUNT ON;

	-- БЕЗ дат
	IF @contract_num IS NOT NULL OR @ip_address IS NOT NULL
	BEGIN
	    -- Заявки
	    SELECT
			   [Тип]          = N'Заявка'
			 , [Договор]        = st.НомерЗаявки
			 , [ФИО]          = st.[ФИО]
			 , [Статус]       = st.СтатусЗаявки
			 , [Ip]           = logOnZ.Ip
			 , [UserAgent]    = logOnZ.UserAgent
			 , [Дата и время] = logOnZ.LogOnDate
		FROM dwh2.dm.ЗаявкаНаЗаймПодПТС	    st
		INNER JOIN dwh2.sat.Заявка_LkIpLogOn logOnZ
		       ON st.GuidЗаявки = logOnZ.GuidЗаявки
		WHERE
		      ((@contract_num IS NULL OR st.НомерЗаявки = @contract_num)
		  AND (@ip_address   IS NULL OR logOnZ.Ip     = @ip_address))
		 UNION ALL
		
		-- Договоры
	    SELECT
	          [Тип]          = N'Договор'
	        , [Договор]      = dz.КодДоговораЗайма
	        , [ФИО]          = CONCAT_WS(' ', dz.Фамилия, dz.Имя, dz.Отчество)
	        , [Статус]       = dz_status.ТекущийСтатусДоговора
	        , [Ip]           = logOn.Ip
	        , [UserAgent]    = logOn.UserAgent
	        , [Дата и время] = logOn.LogOnDate
	    FROM dwh2.hub.ДоговорЗайма dz
	    LEFT JOIN dwh2.sat.ДоговорЗайма_ТекущийСтатус dz_status
	           ON dz.КодДоговораЗайма = dz_status.КодДоговораЗайма
	    INNER JOIN dwh2.sat.Договор_LkIpLogOn logOn	 --  with (index=ix_ip)
	           ON dz.GuidДоговораЗайма = logOn.GuidДоговора
	    WHERE
	          (@contract_num IS NULL OR dz.КодДоговораЗайма = @contract_num)
	      AND (@ip_address   IS NULL OR logOn.Ip             = @ip_address)
	
	    
	
	    
		 
	END
	-- ФИЛЬТР ПО ДАТАМ
	ELSE IF @dtFrom IS NOT NULL AND @dtTo IS NOT NULL
	BEGIN
	
	
	    -- Заявки
	    SELECT
			   [Тип]          = N'Заявка'
			 , [Договор]        = st.НомерЗаявки
			 , [ФИО]          = st.[ФИО]
			 , [Статус]       = st.СтатусЗаявки
			 , [Ip]           = logOnZ.Ip
			 , [UserAgent]    = logOnZ.UserAgent
			 , [Дата и время] = logOnZ.LogOnDate
		FROM dwh2.dm.ЗаявкаНаЗаймПодПТС st
		INNER JOIN dwh2.sat.Заявка_LkIpLogOn logOnZ
		       ON st.GuidЗаявки = logOnZ.GuidЗаявки
		WHERE
				logOnZ.LogOnDate >= @dtFrom
			AND logOnZ.LogOnDate <  DATEADD(DAY, 1, @dtTo)
	     UNION ALL
		-- Договоры
	    SELECT
	          [Тип]          = N'Договор'
	        , [Договор]      = dz.КодДоговораЗайма
	        , [ФИО]          = CONCAT_WS(' ', dz.Фамилия, dz.Имя, dz.Отчество)
	        , [Статус]       = dz_status.ТекущийСтатусДоговора
	        , [Ip]           = logOn.Ip
	        , [UserAgent]    = logOn.UserAgent
	        , [Дата и время] = logOn.LogOnDate
	    FROM dwh2.hub.ДоговорЗайма dz
	    LEFT JOIN dwh2.sat.ДоговорЗайма_ТекущийСтатус dz_status
	           ON dz.КодДоговораЗайма = dz_status.КодДоговораЗайма
	    INNER JOIN dwh2.sat.Договор_LkIpLogOn logOn
	           ON dz.GuidДоговораЗайма = logOn.GuidДоговора
	    WHERE
			logOn.LogOnDate >= @dtFrom
		AND logOn.LogOnDate <  DATEADD(DAY, 1, @dtTo)
	
	   
	END
END
