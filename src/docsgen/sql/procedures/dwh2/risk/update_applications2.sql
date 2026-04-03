CREATE PROCEDURE [risk].[update_applications2] as 
begin
--exec [risk].[update_applications2]
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
BEGIN TRY
------------------------------------пдн по выданным за последние 3 мес, не считая текущего
drop table if exists #pdn;
select 
applications2.number
,coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН.pdn, ДоговорЗайма_ПДН_risk.pdn) as pdn_cmr
,case
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН.pdn, ДоговорЗайма_ПДН_risk.pdn) <= 0.5 then '1. <=0,5'
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН.pdn, ДоговорЗайма_ПДН_risk.pdn) > 0.5 
		and coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН.pdn, ДоговорЗайма_ПДН_risk.pdn) <= 0.8 then '2. 0,5 - 0,8'
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН.pdn, ДоговорЗайма_ПДН_risk.pdn) > 0.8 then '3. > 0,8'
	else 'Не рассчитан'
	end pdn_cmr_bucket
into #pdn
from risk.applications2 applications2
left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН_УМФО --в УМФО ПДН вернее
	on cast(applications2.number as nvarchar) = ДоговорЗайма_ПДН_УМФО.КодДоговораЗайма
	and ДоговорЗайма_ПДН_УМФО.Система = 'УМФО'
	and year(ДоговорЗайма_ПДН_УМФО.Дата_по) = 2999
left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН --ПДН в ЦМР, если нет в УМФО (в УМФО запись появляется не сразу), берем ЦМР
	on cast(applications2.number as nvarchar) = ДоговорЗайма_ПДН.КодДоговораЗайма
	and ДоговорЗайма_ПДН.Система = 'CMR'
	and year(ДоговорЗайма_ПДН.Дата_по) = 2999 --признак актуальности расчета
	and ДоговорЗайма_ПДН.pdn != -999 --значение -999 невалидно
left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН_risk --последний шанс для ПДН
	on cast(applications2.number as nvarchar) = ДоговорЗайма_ПДН.КодДоговораЗайма
	and ДоговорЗайма_ПДН.Система = 'risk'
where applications2.[date] >= dateadd(dd, 1, eomonth(getdate(), -4))
;
------------------------------------обновление
BEGIN TRANSACTION
	merge into risk.applications2 dm
	using #pdn cmr
		on dm.number = cmr.number
	when matched then update set 
	dm.pdn_cmr = cmr.pdn_cmr
	,dm.pdn_cmr_bucket = cmr.pdn_cmr_bucket;
COMMIT TRANSACTION;

drop table if exists #pdn;

END TRY

begin catch
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
	if @@TRANCOUNT>0
		rollback TRANSACTION
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'ala.kurikalov@smarthorizon.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;