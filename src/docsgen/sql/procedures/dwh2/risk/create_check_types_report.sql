CREATE PROCEDURE [risk].[create_check_types_report] as 
begin

--Разбивка по типам проверок для андеров
DECLARE @rdt date = dateadd(dd,-3,cast(GETDATE() as date)); --обновляем данные за последние три дня

BEGIN TRY
-----------------------------------------выборка одобренных заявок inst на Call 1 и добавление типов верификации
drop table if exists #smpl;
SELECT 
distinct ol.number
,case when ver.[Номер заявки] is not null then 1 else 0 end as is_verif
,cast([Дата статуса] as smalldatetime) as dt_verif
into #smpl
from stg._loginom.originationlog ol --все заявки
left join reports.dbo.dm_FedorVerificationRequests_without_coll ver --из Федора по верификации
	on ol.Number = ver.[Номер заявки]
	and ver.[Статус] in ('Контроль данных', 'Верификация клиента')
	and ver.[Состояние заявки] = 'В работе'       
where ol.call_date >= @rdt 
and ol.number not in ('19061300000088', '19061300000089', '20101300041806', '21011900071506', '21011900071507')
and ol.username = 'service' --искл. тестовых заявок
and ol.stage = 'Call 1'
and ol.decision = 'Accept'
;
-----------------------------------------тип проверки для ПТС и автокред на Call 2
drop table if exists #pts_verif;
select 
number
,uw_segment
,row_number() over (partition by number order by call_date desc) as rn
into #pts_verif
from stg.[_loginom].[Originationlog] aa
where stage = 'Call 2'
and Is_installment !=1
and exists (select number from #smpl where #smpl.number = aa.number)
;
-----------------------------------------признак пилота installment на Call 1.2
drop table if exists #inst_verif;
select number
,IsPilot = case when isElligibleforFullAutoApproveChaCha = 1 then 'Pilot' else null end
,TypePilotFlow = case 
		when isFullAutoApprove = 1 then '1. Old pilot 2024' 
		when isFullAutoApprove = 2 then '2. New pilot. FullApprove'
		when isFullAutoApprove = 3 then '3. New pilot. minVerification'
		else null
	end
into #inst_verif
from stg._loginom.Originationlog aa 
where exists (select number from #smpl where #smpl.number = aa.number)
and stage = 'Call 1.2'
and Is_installment = 1
and username = 'service'
;
-----------------------------------------change_to_doc_check
/*drop table if exists #cd;
select distinct number
into #cd
from stg._loginom.Originationlog as aa
where exists (select number from #smpl where #smpl.number = aa.number)
and stage = 'Call 1.5'
and is_installment = 1
and username = 'service'
and Decision = 'Decline'
and (Decision_Code like '100.07%' or Decision_Code like '100.08%')
;*/
-----------------------------------------
drop table if exists #check_under;
select 
ol.number
,cast(ol.call_date as date) as call_date
,ol.is_installment
,ol.productTypeCode
,ol.IsSimplifiedVerification
,ol.IsDocumentalVerification

,smpl.is_verif
,smpl.dt_verif

,inst_verif.IsPilot -- признак пилота
,inst_verif.TypePilotFlow
,pts_verif.uw_segment

,case 
	when smpl.is_verif = 1 and ol.IsDocumentalVerification = 1 and inst_verif.TypePilotFlow is null 
	then 1 else 0 end IsDocumentalVerification_NEW
,case 
	when smpl.is_verif = 1 and ol.IsDocumentalVerification = 0 and ol.IsSimplifiedVerification = 1 and inst_verif.TypePilotFlow is null 
	then 1 else 0 end IsSimplifiedVerification_NEW
,case 
	when smpl.is_verif = 1 and ol.IsDocumentalVerification = 0 and ol.IsSimplifiedVerification = 0 and inst_verif.TypePilotFlow is null 
	then 1 else 0 end IsFullVerification_NEW
--,change_to_doc_check = case when cd.Number is not null then 1 else 0 end
,row_number() over (partition by ol.number order by smpl.dt_verif desc, ol.call_date) as rn
into #check_under
from stg._loginom.originationlog ol
left join #pts_verif pts_verif
	on ol.number = pts_verif.number
	and pts_verif.rn = 1
left join #inst_verif inst_verif
	on ol.number = inst_verif.number
--left join #cd cd 
--	on ol.number = cd.number
left join #smpl smpl
	on ol.number = smpl.Number
where exists (select number from #smpl where #smpl.number = ol.number)
and ol.username = 'service'
and ol.stage = 'Call 1'
;
-----------------------------------------
drop table if exists #final;
select 
number
,call_date
,is_installment
,productTypeCode
,case 
	when is_installment !=1 and uw_segment in (100, 102) then 'Упрощенная верификация'
	when is_installment !=1 and uw_segment not in (100, 102) then 'Полная верификация'
	when is_installment = 1 and TypePilotFlow is not null then 'Автоаппрув'
	when is_installment = 1 and IsDocumentalVerification_NEW = 1 then 'Проверка документов'
	when is_installment = 1 and IsSimplifiedVerification_NEW = 1 then 'Упрощенная верификация'
	when is_installment = 1 and IsFullVerification_NEW = 1 then 'Полная верификация'
	else 'Не дошло до верификации'
	end verif_type
into #final
from #check_under
where rn = 1 
;
-----------------------------------------
if OBJECT_ID('risk.check_types_report') is null
begin
	select top(0) * into risk.check_types_report
	from #final
end;

BEGIN TRANSACTION
	delete from risk.check_types_report
	where call_date >= @rdt

	insert into risk.check_types_report
	select * from #final;
COMMIT TRANSACTION;

drop table if exists #smpl;
drop table if exists #av;
drop table if exists #cd;
drop table if exists #check_under;
drop table if exists #final;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;