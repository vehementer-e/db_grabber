/*
Сравнение данных между dwh2.[sat].[ЗаявкаНаЗаймПодПТС_LK_Заявка] и Stg._LK.requests
*/
CREATE    procedure [Monitoring].[ComparisonData_sat_ЗаявкаНаЗаймПодПТС_LK_Заявка_lk_requests]
	@isDebug bit =0
as
declare
	@sourceTable			NVARCHAR(255) = 'Stg._LK.requests',
	@targetTable			NVARCHAR(255) ='[dwh2].[sat].[ЗаявкаНаЗаймПодПТС_LK_Заявка]',
	@sourceColumns			NVARCHAR(MAX) ='try_cast(guid as uniqueidentifier) as GuidЗаявки, Id as lk_request_id, code as lk_request_code, promo_code as lk_promocode',
	@targetColumns			NVARCHAR(MAX) = 'GuidЗаявки,lk_request_id,lk_request_code,lk_promocode',
	@periodColumns			NVARCHAR(MAX) = 'created_at, updated_at',
	@isSendToEmail			bit = 1,
	@selectComparisonResult bit = 1,
	@sourceWhereCondition	nvarchar(1024) = CONCAT_WS(' AND '
		, 'updated_at <= dateadd(hour, -3, getdate())'
		, 'try_cast(Stg._LK.requests.guid AS uniqueidentifier) IS NOT NULL'
		, 'charindex(''СДRC'', num_1c) = 0'
		, 'charindex(''СЗRC'', num_1c) = 0'
		),
	@joinCondition			NVARCHAR(MAX) = 'stg.id = subQuery.lk_request_id'

declare
	@emailList				nvarchar(max) =(select top(1) emails from Emails where loggerName = 'adminlog'),
	@tableTitle				nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
	@emailSubject			nvarchar(255) = concat_ws(' ', 'DQ dataValut', 'Сравнение', @sourceTable,'vs', @targetTable),
	@rowsInEmail			int  = 100
	 
exec  logDb.Monitoring.ComparisonDataSets
	@sourceTable				=	@sourceTable				
	,@targetTable				=	@targetTable				
	,@sourceColumns				=	@sourceColumns				
	,@targetColumns				=	@targetColumns
	,@periodColumns				=	@periodColumns
	,@isSendToEmail				=	@isSendToEmail				
	,@selectComparisonResult	=	@selectComparisonResult	
	,@emailList					=	@emailList					
	,@tableTitle				=	@tableTitle				
	,@emailSubject				=	@emailSubject				
	,@rowsInEmail				=	@rowsInEmail				
	,@isDebug					=	@isDebug
	,@sourceWhereCondition		=	@sourceWhereCondition
	,@joinCondition				=	@joinCondition

