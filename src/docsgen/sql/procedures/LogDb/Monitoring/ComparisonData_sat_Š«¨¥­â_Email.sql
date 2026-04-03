-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- [Monitoring].[ComparisonData_sat_Клиент_Email] 1
-- =============================================
CREATE PROCEDURE [Monitoring].[ComparisonData_sat_Клиент_Email]
	@isDebug bit = 0
AS
BEGIN
	declare
			@sourceTable			NVARCHAR(255) = 'Stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация',
			@targetTable			NVARCHAR(255) ='[dwh2].[sat].[Клиент_Email]',
			@sourceColumns			NVARCHAR(MAX) = '[GuidКлиент] =dwh2.[dbo].[getGUIDFrom1C_IDRREF](Ссылка), АдресЭП as Email',
			@targetColumns			NVARCHAR(MAX) = '[GuidКлиент], Email',
			@periodColumns			NVARCHAR(MAX) = 'ДатаЗаписи',
			@isSendToEmail			bit = 1,
			@selectComparisonResult bit = 0,
			@sourceWhereCondition	NVARCHAR(1024) =  '1=1
													AND Актуальный = 0x01
													AND Тип = 0x82E6D573EE35D0904BF4D326A84A91D2
													AND Stg.dbo.str_ValidateEmail(АдресЭП) IS NOT NULL',
			@targetWhereCondition	NVARCHAR(1024),
			@joinCondition			NVARCHAR(MAX) = '[dwh2].[dbo].[getGUIDFrom1C_IDRREF](stg.Ссылка)  = subQuery.GuidКлиент
													 AND stg.АдресЭП = subQuery.Email'
		declare
			@emailList				nvarchar(max) = (select top(1) emails from Emails where loggerName = 'adminlog'),
			@tableTitle				nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
			@emailSubject			nvarchar(255) = concat_ws(' ',  'DQ dataValut', 'Сравнение', @sourceTable,'vs', @targetTable),
			@rowsInEmail			int  = 100,
			@columnsToSelect		nvarchar(1024) = 'subQuery.GuidКлиент
													, subQuery.Email
													,case
														when year(stg.ДатаЗаписи) > 3000
														then format(dateadd(year, -2000 , stg.ДатаЗаписи), ''dd.MM.yyyy hh:mm:ss'')
														else format(stg.ДатаЗаписи, ''dd.MM.yyyy hh:mm:ss'')
													end'
		exec LogDb.Monitoring.ComparisonDataSets
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
			,@targetWhereCondition		=	@targetWhereCondition
			,@joinCondition				=	@joinCondition
			,@columnsToSelect			=	@columnsToSelect

	END


