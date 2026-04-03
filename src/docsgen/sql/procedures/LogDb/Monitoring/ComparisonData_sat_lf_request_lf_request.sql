/*
Сравнение данных между dwh2.[sat].[ЗаявкаНаЗаймПодПТС_LeadsFlow_Заявка] и Stg._LF.request
*/

create     procedure [Monitoring].[ComparisonData_sat_lf_request_lf_request]
as
declare
	@sourceTable			NVARCHAR(255) = 'Stg._LF.request',
	@targetTable			NVARCHAR(255) ='dwh2.[sat].LF_request',
	@sourceColumns			NVARCHAR(MAX) = 'id as GuidЗаявки',
	@targetColumns			NVARCHAR(MAX) = 'GuidЗаявки',
	@periodColumns			NVARCHAR(MAX) = 'updated_at_time, created_at_time',
	@isSendToEmail			bit =1,
	@selectComparisonResult bit = 0,
	@joinCondition			NVARCHAR(MAX) = 'stg.id = subQuery.GuidЗаявки'
declare
	@emailList				nvarchar(max) =(select top(1) emails from Emails where loggerName = 'adminlog'),
	 @tableTitle			nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
	 @emailSubject			nvarchar(255) = concat_ws(' ', 'DQ dataValut', 'Сравнение', @sourceTable,'vs', @targetTable),
	 @rowsInEmail			int  = 100,
	 @isDebug				bit =0
exec  logDb.Monitoring.ComparisonDataSets
	@sourceTable				=	@sourceTable				
	,@targetTable				=	@targetTable				
	,@sourceColumns				=	@sourceColumns				
	,@targetColumns				=	@targetColumns
	,@periodColumns				=   @periodColumns
	,@isSendToEmail				=	@isSendToEmail				
	,@selectComparisonResult	=	@selectComparisonResult	
	,@emailList					=	@emailList					
	,@tableTitle				=	@tableTitle				
	,@emailSubject				=	@emailSubject				
	,@rowsInEmail				=	@rowsInEmail				
	,@isDebug					=	@isDebug	
	,@joinCondition				=	@joinCondition
