
-- =============================================
-- Author: Kirichenko Nikita
-- Create date: 21.10.2025
-- Description:	Сверяет ПДН в системах
-- =============================================



CREATE PROCEDURE [risk].[pdn_sync_diffs_kko]


AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	EXEC risk.set_debug_info @sp_name
		,'START';

	BEGIN TRY

----------------------------------------------------------------------------------------------------------------------

drop table if exists #tmp1;
select a.Код as number
, credits.startdate as startdate
, credits.credit_type
, credits.amount
, gen.pdn as pdn_gen
, cmr_logs.pdn_logs as pdn_cmr_logs
, umfo.pdn as pdn_umfo
, cmr_umfo.pdn as pdn_cmr_umfo
, case when em.number is not null then 1 end as isselfem 
, gen.need_bki
, case 
	when gen.pdn <> cmr_logs.pdn_logs and  gen.pdn <> umfo.pdn and cmr_logs.pdn_logs = umfo.pdn then 'Gen2/CMR+UMFO'
	when cmr_logs.pdn_logs <> umfo.pdn and cmr_logs.pdn_logs <> gen.pdn and gen.pdn = umfo.pdn then 'CMR/Gen2+UMFO'
	when cmr_logs.pdn_logs <> umfo.pdn and umfo.pdn <> gen.pdn and gen.pdn = cmr_logs.pdn_logs then 'UMFO/CMR+Gen2'
	when gen.pdn <> cmr_logs.pdn_logs and gen.pdn = umfo.pdn then 'Gen2/CMR'
	when gen.pdn <> umfo.pdn and gen.pdn = cmr_logs.pdn_logs then 'Gen2/UMFO'
	when cmr_logs.pdn_logs <> umfo.pdn and cmr_logs.pdn_logs = gen.pdn then 'CMR/UMFO'
	else '?'
	end as 'Расхождение'
, case
	when em.number is not null then 'СЗ, ПДН вообще не должен рассчитываться'
	when a.код in ('25092303718697','25090603669897','25091703702391','25092803736061','25092503726271','25092803736290','25090903677824','25091403691593','25092803735687','25082903639585','25091903707519','25083003643501','25090303659664','25083103647071','25090903677949','25091303688984','25091703700573','25090703671405','25092203715714','25082903640628','25091303689288','25092003709930','25092503726648') 
		then 'Пересчет Авто по левым справкам Сентябрь'
	when a.код in ('25072603541639','25080403564110') then 'Ждем пересчет в ЦМР. ТП не может пересчитать ПТС. Заведен дефект https://tracker.yandex.ru/CMR-518'
	when a.код in ('25081903606654','25082903638528','25082503624777','25082603627523','25080303563242','25081303589530','25083103647863','25080103557296','25083003643163','25082803634196','25082603627940','25081503594615','25081203585139','25081403592349','25081303588480','25081503596133','25081403591711','25081303588704','25082603627289','25081603598741','25081203587566','25081403593059','25081203585912','25080703571396','25082503624422','25082003609698','25081403591385','25073103556009','25080603569918','25080503566345','25082203615505','25082903640833','25082403619918','25080203561037','25081703601034','25072903549447','25081503594339','25082003608738','25081503595093','25082503625259','25072803547171','25082203616173','25083103646453','25082303619419','25083003643089','25082703631813','25080703572116')
		then 'Пересчет по левым справкам Авто, ПТС август'
	when a.код in ('25071703518379','25071803520634','25071903523266','25072003526129','25071103504036','25071503513193','25071603515596','25071603515741','25071403511282','25071503513048','25071103504102','25071203506879','25071303509113','25071303509323','25071003503305','25070703493480','25070703493950','25070703494719','25070503490122','25070303483453','25070103477054','25070103478547','25063003474286','25063003474466','25072803546316','25073003552741','25072503540339','25072603541506','25072703544231','25072303534844','25072003525435','25071203505963','25070603490737')
		then 'Пересчет по левым справкам Июль'
	when a.код in ('25091003680420','25090303660593','25082303618685','25082403621589','25082503623319','25082603627248','25082003610736','25082103611544','25081803604371','25081603597078','25081803604117','25081703600903','25081303589102','25080803576475','25081103584039','25081203585261','25081003580490','25081103583066','25080503566204','25080603569108','25080503566120','25072803547955','25080303562392','25072803548061','25072803546727','25072403537209','25072103529787','25072303535209','25071603515796','25072103528654','25071803521241','25071603515758','25071703518090','25070803497342','25070703494304','25071203506644','25071003503327','25071103504263','25071103505148','25070903500505','25070703494560','25070803498346','25070903499208','25070903499917','25070803497093','25070103476469')
		then 'В gen2 не подтянулся подтвержденный доход'
	when a.код in ('25080703571637')
		then 'В ЦМР не подтянулся bki_exp (расчет с БКИ)'
	when a.код in ('25083003643089','25081403591385')
		then 'Ждем пересчета в ЦМР. Передали пакет с правильным ПДН, но по факту посчитано неверно + ТП не может пересчитать ПТС. Заведен дефект https://tracker.yandex.ru/CMR-528'
	when a.код in ('25072123528693')
		then 'Разный bki_exp в gen2 и ЦМР'
	when a.код in ('25072823547878','25070703495555','25070223480436','25092403722519')
		then 'Разный credit_exp в gen2 и ЦМР'
	when a.код in ('25072103528240')
		then 'Разный Росстат доход в ЦМР и gen2 Калининградская область '
	when a.код in ('25072203531636')
		then 'Разный Росстат доход в ЦМР и gen2 Севастополь'
	--when a.код in ('25070203481425','25070923500917','25080423565605','25081903605352','25083003643298','25090603670301','25090703672986','25091123685325','25091403692563','25092523727323','25092803737265','25092903740724','25093003743705','25093003744181','25093003744901')
	--	then 'Разница 0,001 надо проверять'
	when gen.pdn <> cmr_logs.pdn_logs then case
		when gen.avg_income <> cmr_logs.avg_income then case
				when gen.application_income <> cmr_logs.application_income then 'Разный avg_income в gen2 и ЦМР. Причина: application_income'
				when gen.rosstat_income <> cmr_logs.rosstat_income then 'Разный avg_income в gen2 и ЦМР. Причина: rosstat_income'
				when gen.income_amount <> cmr_logs.income_amount then 'Разный avg_income в gen2 и ЦМР. Причина: income_amount'
				else 'Разный avg_income в gen2 и ЦМР. Причина: ?'
				end
		when gen.credit_exp <> cmr_logs.credit_exp then 'Разный credit_exp в gen2 и ЦМР'
		when gen.bki_exp_amount <> cmr_logs.bki_exp then 'Разный bki_exp в gen2 и ЦМР'
		when gen.exp_amount <> cmr_logs.exp_amount and gen.need_bki = 0 and cmr_logs.[с БКИ/нет] = 'без БКИ' then 'Разный exp_amount в gen2 и ЦМР. Расчет без БКИ'
		when gen.exp_amount <> cmr_logs.exp_amount and gen.need_bki <> 0 and cmr_logs.[с БКИ/нет] = 'без БКИ' then 'Разный exp_amount в gen2 и ЦМР. Расчет в gen2 без БКИ/в ЦМР с БКИ'
		when gen.exp_amount <> cmr_logs.exp_amount and gen.need_bki = 0 and cmr_logs.[с БКИ/нет] <> 'без БКИ' then 'Разный exp_amount в gen2 и ЦМР. Расчет в gen2 с БКИ/в ЦМР без БКИ'	
		when gen.exp_amount = cmr_logs.exp_amount and gen.need_bki = 0 and cmr_logs.[с БКИ/нет] <> 'без БКИ' then 'Одинаковый exp_amount в gen2 и ЦМР. Расчет в gen2 без БКИ/в ЦМР с БКИ'	
		when gen.exp_amount = cmr_logs.exp_amount and gen.need_bki <> 0 and cmr_logs.[с БКИ/нет] = 'без БКИ' then 'Одинаковый exp_amount в gen2 и ЦМР. Расчет в gen2 с БКИ/в ЦМР без БКИ'	
		when gen.application_income <> cmr_logs.application_income or gen.rosstat_income <> cmr_logs.rosstat_income or gen.income_amount <> cmr_logs.income_amount or gen.credit_exp <> cmr_logs.credit_exp or gen.bki_exp_amount <> cmr_logs.bki_exp then 'В gen2 и ЦМР >2 различий в переменных'
		end
	end as comment
--, cmr_logs.application_income
--, gen.application_income
into #tmp1
from stg._1cCMR.Справочник_Договоры a
left join dwh2.risk.pdn_calculation_2gen as gen on a.[Код] = gen.Number
left join dwh2.risk.logs_cmr_pdn_calculation as cmr_logs on a.[Код] = cmr_logs.number
left join dwh2.sat.ДоговорЗайма_ПДН as umfo on a.[Код]=umfo.КодДоговораЗайма and year(umfo.Дата_по) = '2999' and umfo.Система = 'УМФО'
left join dwh2.sat.ДоговорЗайма_ПДН as cmr_umfo on a.[Код]=cmr_umfo.КодДоговораЗайма and year(cmr_umfo.Дата_по) = '2999' and cmr_umfo.Система = 'CMR'
left join dwh2.risk.credits as credits on a.Код = credits.external_id
left join dwh2.risk.kko_selfemployed as em on a.Код = em.number
where 1=1
and (
   gen.pdn <> cmr_logs.pdn_logs
or gen.pdn <> umfo.pdn
or cmr_logs.pdn_logs <>  umfo.pdn
--or cmr_logs.pdn_logs <> cmr_umfo.pdn
--or umfo.pdn <> cmr_umfo.pdn
--or gen.pdn <> cmr_umfo.pdn
)
and credits.startdate >= '2025-07-01'
order by startdate desc
;

--Полная перезаливка тех, на кого в первую очередь нужно обратить внимание
drop table if exists dwh2.risk.kko_pdn_diff_gen_cmr_umfo;
select * 
into dwh2.risk.kko_pdn_diff_gen_cmr_umfo
from #tmp1
where comment not in (
'СЗ, ПДН вообще не должен рассчитываться',
'Пересчет Авто по левым справкам Сентябрь',
'Пересчет по левым справкам Авто, ПТС август',
'Пересчет по левым справкам Июль'
)
;

--Полная перезаливка full
drop table if exists dwh2.risk.kko_pdn_diff_gen_cmr_umfo_full;
select * 
into dwh2.risk.kko_pdn_diff_gen_cmr_umfo_full
from #tmp1
;





		EXEC risk.set_debug_info @sp_name
			,'FINISH';
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

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =  'Никита Кириченко <n.kirichenko@smarthorizon.ru>; Александр Голицын <a.golicyn@carmoney.ru>'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END
