/*
JOB:
LCRM. Load Launch control at 3:35
надо в первом шаге джоба проверять, что данные в таблице источнике "свежие" т.е. не более чем 24ч от текущей даты
запрос в таблице-источнике
select max(c.UF_UPDATED_AT) from carmoney_light_crm_launch_control_new c
падает по таймауту через 10 минут

в таблице-источнике есть индекс по id, поэтому сначала определяем 
max(id) в таблице DWH _LCRM.carmoney_light_crm_launch_control
а потом в таблице-источнике находим max(UF_UPDATED_AT) для id > ( max(id) - 40000000)
*/
CREATE   PROC _LCRM.Check_lcrm_launch_control_data
	@isDebug int = 0
as
BEGIN

SELECT @isDebug = isnull(@isDebug, 0)

DECLARE @max_id bigint, @max_uf_updated_at datetime2 = '2000-01-01', @max_uf_updated_at_upd datetime2
DECLARE @ErrorMessage  nvarchar(4000), @ErrorSeverity int, @ErrorState int, @ErrorNumber int
DECLARE @Error_Procedure nvarchar(128), @Error_Line int


/*
--var.1 использование линкед-сервера
DECLARE @query nvarchar(max)
declare @tsql nvarchar(max)
declare @ii bigint=0
      , @prev_i bigint =-1
	  , @countError bigint=0

set @ii =0
set @prev_i =-1
Set @countError = 0

DECLARE @text varchar(max)

SELECT @max_id =  isnull(max(L.id),-1) 
FROM _LCRM.carmoney_light_crm_launch_control AS L with(nolock)

DROP TABLE IF EXISTS #t_lcrm_data
CREATE TABLE #t_lcrm_data(CNT bigint, MAX_UF_UPDATED_AT datetime2)

while @ii<>@prev_i
begin
	begin try
		set @prev_i=@ii

		--set @query=N'select c1.* from carmoney_light_crm_launch_control c1 limit 0' 
		SET @query = N'select count(*) as CNT, max(c.UF_UPDATED_AT) as MAX_UF_UPDATED_AT '
			 + 'from carmoney_light_crm_launch_control_new c where id > ' + convert(varchar(20), @max_id - 40000000)

		set @tsql='INSERT #t_lcrm_data(CNT, MAX_UF_UPDATED_AT) '
			+'SELECT CNT, MAX_UF_UPDATED_AT FROM openquery(LCRM,'''+@query+''')'

		IF @isDebug = 1 BEGIN
			SELECT @tsql
		END

		TRUNCATE TABLE #t_lcrm_data

		EXEC (@tsql)

		IF @isDebug = 1 BEGIN
			SELECT * FROM #t_lcrm_data
		END

	END TRY
	BEGIN CATCH
		IF @isDebug = 1 BEGIN
			SELECT 'catch error!'
		END

		--set @text= 'LCRM. Load Launch control check failed:  '+ERROR_MESSAGE()
		--EXEC [LogDb].[dbo].[SendToSlack_lcrm-backup-restore-dwh-monitoring] @text;

		SET @prev_i = -1

		SET @countError = @countError + 1

		IF @isDebug = 1 BEGIN
			SELECT @countError
		END
			
		WAITFOR DELAY '00:15:00'; 

		IF @countError > 5
		BEGIN 
			-- выходим с исключением
			IF @isDebug = 1 BEGIN
				SELECT 'exit';
			END

			SELECT @ErrorNumber = error_number(), @ErrorSeverity = error_severity(), @ErrorState  = error_state()
			SELECT @Error_Procedure = error_procedure(), @Error_Line = ERROR_LINE()
			SELECT @ErrorMessage = isnull(error_message(), 'Сообщение не определено') + 
				'[' + 'Процедура ' + isnull(@Error_Procedure, 'не определена') + 
				', Строка '+isnull(convert(varchar(20), @Error_Line), 'не определена') + ']'
			--THROW;
			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
		END

	END CATCH

	SELECT @max_uf_updated_at = D.MAX_UF_UPDATED_AT
	FROM #t_lcrm_data AS D

	IF @max_uf_updated_at < dateadd(DAY, -1, getdate())
	BEGIN
		--RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
		RAISERROR('В таблице-источнике carmoney_light_crm_launch_control_new нет новых данных.', 16, 1);
	END

END
*/

--var.2 использование инф. таблицы _LCRM.info_lcrm_launch_control
/*
на пред. шаге происходит загрузка инф. в info_lcrm_launch_control :
max(ID), max(UF_UPDATED_AT) из таблицы-источника
*/

SELECT @max_uf_updated_at = D.MAX_UF_UPDATED_AT
FROM _LCRM.info_lcrm_launch_control AS D

SELECT @max_uf_updated_at = isnull(@max_uf_updated_at, '2001-01-01')

--инф. из таблицы _upd о последней загрузке
SELECT @max_uf_updated_at_upd = max(U.UF_UPDATED_AT)
FROM _LCRM.carmoney_light_crm_launch_control_upd AS U

SELECT @max_uf_updated_at_upd = isnull(@max_uf_updated_at_upd, '2000-01-01')

IF @max_uf_updated_at <= @max_uf_updated_at_upd -- данные в бэкапе старше, чем данные в таблице _upd
	OR @max_uf_updated_at < dateadd(DAY, -1, getdate()) -- старый бэкап
BEGIN
	RAISERROR('В таблице-источнике carmoney_light_crm_launch_control_new нет новых данных.', 16, 1);
END

END
