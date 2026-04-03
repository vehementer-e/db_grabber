/*
[Monitoring].[ComparisonData_sat_ЗаявкаНаЗаймПодПТС_FedorЗаявка_core_ClientRequest] 1
*/
CREATE   procedure [Monitoring].[ComparisonData_sat_ЗаявкаНаЗаймПодПТС_FedorЗаявка_core_ClientRequest]
	@isDebug bit = 0
as
begin
	declare
		@sourceTable			NVARCHAR(255) = 'Stg._fedor.core_ClientRequest',
		@targetTable			NVARCHAR(255) ='dwh2.[sat].[ЗаявкаНаЗаймПодПТС_FedorЗаявка]',
		@sourceColumns			NVARCHAR(MAX) = 'Id as GuidЗаявки, IdLead as feodor_lead_id,  isnull(AprRecommended,												PercentApproved) as РекомендованнаяСтавка',
		@targetColumns			NVARCHAR(MAX) = 'GuidЗаявки, feodor_lead_id, РекомендованнаяСтавка',
		@periodColumns			NVARCHAR(MAX) = 'CreatedOn',
		@isSendToEmail			bit = 1,
		@selectComparisonResult bit = 0,
		-- @whereCondition		nvarchar(1024)= 'RowVersion >= (select max(RowVersion) - 100 from						Stg._fedor.core_ClientRequest)',
		@sourceWhereCondition	NVARCHAR(1024) = '1=1',
		@joinCondition			NVARCHAR(MAX) = 'stg.id = subQuery.GuidЗаявки'
	declare
		@emailList				nvarchar(max) =(select top(1) emails from Emails where loggerName = 'adminlog'),
		@tableTitle				nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
		@emailSubject			nvarchar(255) = concat_ws(' ',  'DQ dataValut', 'Сравнение', @sourceTable,'vs', @targetTable),
		@rowsInEmail			int  = 100
		,@columnsToSelect		nvarchar(1024) = 'subQuery.GuidЗаявки
												, subQuery.feodor_lead_id
												, subQuery.РекомендованнаяСтавка
												, format(dateadd(hour, +3, stg.CreatedOn), ''dd.MM.yyyy hh:mm:ss'') as							CreatedOnPlus3'
	
	exec  Monitoring.ComparisonDataSets
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
		,@columnsToSelect			=	@columnsToSelect
end