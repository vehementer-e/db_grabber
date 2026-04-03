
/*Мониторинг заявок для оценки качества андеррайтинга (Quality)*/
--exec [risk].[etl_repbi_quality_report];
CREATE PROC [risk].[etl_repbi_quality_report]
AS
BEGIN

declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @min_app_dt date;
set @min_app_dt = (
select min(min_app_dt) from 
(
	select min([дата заведения заявки]) as min_app_dt
	from reports.dbo.dm_FedorVerificationRequests_without_coll
	where cast([Дата статуса] as date) > dateadd(day, - 31, cast(getdate() as date))--dateadd(day, -day(getdate()) + 1, cast(getdate() as date))
	union all
	select min([дата заведения заявки])
	from reports.dbo.dm_FedorVerificationRequests
	where cast([Дата статуса] as date) > dateadd(day, - 31, cast(getdate() as date))--dateadd(day, -day(getdate()) + 1, cast(getdate() as date))
) t)
;

BEGIN TRY
------------------------------------------Отчет для Quality------------------------------------------
drop table if exists #ClientIncomeAdditional_SRC;
select 
number
,ClientIncomeAdditional
into #ClientIncomeAdditional_SRC
from stg._fedor.core_ClientRequest
where ClientIncomeAdditional > 0 
and CreatedOn >= dateadd(day, -day(getdate()) + 1, cast(getdate() as date))
;
------------------------------------------Call 1
drop table if exists #call1;
select 
number 
,Branch_name
,row_number() over (partition by number order by call_date desc) as rn
into #call1
from stg._loginom.Originationlog
where stage = 'Call 1'
and call_date >= @min_app_dt
;
------------------------------------------Call 1.5
drop table if exists #call15;
select 
number 
,decision
,row_number() over (partition by number order by call_date desc) as rn
into #call15
from stg._loginom.Originationlog
where stage = 'Call 1.5'
and call_date >= @min_app_dt
;
------------------------------------------Проверки верификаторов для беззалога (проводится на Call 1.5)
drop table if exists #callcheckverif;
select 
number
,isnull(Result_1_203, Result_2_103) as UW_Result_3_old --СОЦ СЕТИ старые правила
,Result_1_219 as UW_Result_3
,isnull(Result_1_209, Result_2_109) as UW_Result_9
,isnull(Result_1_207, Result_2_107) as UW_Result_7
,isnull(Result_1_216, Result_2_116) as UW_Result_16
,isnull(Result_1_215, Result_2_115) as UW_Result_15
,isnull(Result_1_214, Result_2_114) as UW_Result_14
,isnull(Result_1_213, Result_2_113) as UW_Result_13
,isnull(Result_1_211, Result_2_111) as UW_Result_11
,isnull(Result_1_212, Result_2_112) as UW_Result_12
,Result_1_206
,Result_1_26
,Result_1_113
into #callcheckverif
from stg._loginom.callcheckverif_log
where stage = 'Call 1.5'
and call_date >= @min_app_dt
;
------------------------------------------Верификация без звонка (беззалог)
drop table if exists #fvr_without_coll;
select 
distinct [Номер заявки]
,dem_fl = 1
,dor_fl = 1
,sum([ВремяЗатрачено]) over (partition by [Номер заявки],Статус, Задача) * 24 * 60 as dem_time
,ProductType_Code
,Задача
into #fvr_without_coll
from reports.dbo.dm_FedorVerificationRequests_without_coll
where Статус = 'Контроль данных' 
and [Дата статуса] > dateadd(day, - 31, cast(getdate() as date))
;
------------------------------------------Верификация (птс)
drop table if exists #fvr;
select 
distinct [Номер заявки]
,dem_fl = 1
,dor_fl = 1
,sum([ВремяЗатрачено]) over (partition by [Номер заявки],Статус, Задача) * 24 * 60 as dem_time
,Статус
,Задача
into #fvr
from reports.dbo.dm_FedorVerificationRequests
where [Дата статуса] > dateadd(day, - 31, cast(getdate() as date))
;
------------------------------------------Тип документа о доходе
drop table if exists #IncomeComponent;
select 
number
,stage
,ConfirmedIncomeComponent
,row_number() over (partition by number order by call_date) as rn
into #IncomeComponent
from stg._loginom.calculated_term_and_amount
where stage in ('Call 2', 'Call 2.2', 'Call 4')
and ConfirmedIncomeComponent is not null
and call_date >= @min_app_dt
;
insert into #IncomeComponent --RDWH-41, Тип документа о доходе Big Installment
select 
number
,stage
,ConfirmedIncomeComponent
,row_number() over (partition by number order by call_date) as rn
from stg._loginom.calculated_term_and_amount_big_installment
where stage in ('Call 2', 'Call 2.2', 'Call 4')
and ConfirmedIncomeComponent is not null
and call_date >= @min_app_dt
;
------------------------------------------Чекеры БЕЗЗАЛОГ
drop table if exists #repbi_quality_report_checkers_unsecured;
select 
f.ProductType_Code
,[Дата заведения заявки]
,[Время заведения]
,Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] as datetime)) over (partition by f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный чекер]
,sum([ВремяЗатрачено]) over (partition by f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,case 
	when call15.decision = 'Accept' then 'Одобрено' 
	when call15.decision = 'Decline' then 'Отказано' 
	else 'Аннулировано' 
	end [Решение на этапе]
,case when fv.dem_fl = 1 then 'Да' else 'Нет' end 'Отложена'
,fv.dem_time
,case when fd.dor_fl = 1 then 'Да' else 'Нет' end 'Доработка'
,fd.dem_time as dor_time
,case 
	when call15.decision = 'Accept' then 'Одобрено' 
	when call15.decision = 'Decline' then 'Отказано' 
	else 'Аннулировано' 
	end [Решение по клиенту]
,[Последний статус заявки] as [Статус по заявке]
,case when UW_Result_14 is null then 'Не назначалась проверка' else coalesce(cont_client.result, 'Другое') end [Контактность клиента]
,case 
	when UW_Result_9 is null then 'Не назначалась проверка' 
	else coalesce(work_cfocus.result, 'Другое') 
	end [Контактность работодателя по телефонам из Контур Фокуса]
,case 
	when UW_Result_11 is null then 'Не назначалась проверка' 
	else coalesce(work_internet.result, 'Другое') 
	end [Контактность работодателя по телефонам из Интернет]
,case 
	when UW_Result_12 is null then 'Не назначалась проверка' 
	else coalesce(work_survey.result, 'Другое') 
	end [Контактность работодателя по телефонам из Анкеты]		
,case 
	when UW_Result_3 is not null then soc_media.result
	when UW_Result_3_old is not null then soc_media_old.result
	when coalesce(UW_Result_3, UW_Result_3_old) is null then 'Не назначалась проверка' 
	else 'Другое'
	end [СОЦ СЕТИ]
,case when ClientIncomeAdditional is not null and f.ProductType_Code <> 'pdl' then 'Есть' else 'Нет' end [Доп.доход (есть/нет)]
,case when UW_Result_16 is null then 'Не назначалась проверка' else coalesce(antifrod.result, 'Другое') end [Проверка Антифрод]
,case when UW_Result_15 is null then 'Не назначалась проверка' else coalesce(negative.result, 'Другое') end [НЕГАТИВЫ]
,case 
	when Result_1_206 is null then 'Не назначалась проверка' 
	else coalesce(cli_phone.result, 'Другое') 
	end [Проверка телефонов по базам - телефон клиента] --Проверка телефонов по базам - телефон клиента
,case 
	when cc.Result_1_26 is not null then coalesce(income_check.result, 'Другое') 
	when cc.Result_1_113 is not null then coalesce(income_check_big.result, 'Другое') --RDWH-41
	when coalesce(cc.Result_1_26, cc.Result_1_113) is null then 'Не назначалась проверка' 
	else 'Другое'
	end [Проверка дохода]
,case 
	when cta.ConfirmedIncomeComponent like '%reference2NDFL%' then 'Справка 2-НДФЛ'
	when cta.ConfirmedIncomeComponent like '%CertificateFormBank%' then 'Справка по форме Кредитной  Организации/работодателя'
	when cta.ConfirmedIncomeComponent like '%externalBankStatementForSalary%' then 'Банковская выписка по зарплатному счету (бумажный или электронный вид)'
	when cta.ConfirmedIncomeComponent like '%referencePfrSfr%' then 'Справка из ПФР/СФР о размере установленной пенсии'
	when cta.ConfirmedIncomeComponent is null then 'Не назначалась проверка'
	when cta.ConfirmedIncomeComponent = '' then 'Не назначалась проверка'
	else 'Другое' 
	end [Тип документа о доходе]
into #repbi_quality_report_checkers_unsecured
from reports.dbo.dm_FedorVerificationRequests_without_coll f
left join #call1 call1 
	on f.[Номер заявки] = call1.Number
	and call1.rn = 1
left join #call15 call15 
	on f.[Номер заявки] = call15.Number
	and call15.rn = 1
left join #fvr_without_coll fv 
	on f.[Номер заявки] = fv.[Номер заявки]
	and fv.Задача = 'task:Отложена'
left join #fvr_without_coll fd 
	on f.[Номер заявки] = fd.[Номер заявки]
	and fd.Задача = 'task:Требуется доработка'
left join #callcheckverif cc 
	on f.[Номер заявки] = cc.Number
left join #IncomeComponent cta
	on f.[Номер заявки] = cta.number
	and cta.rn = 1
--справочник проверок
left join risk.quality_check_types cont_client
	on cont_client.code = cc.UW_Result_14
	and cont_client.check_type = 'UW_Result_14'
left join risk.quality_check_types work_cfocus
	on work_cfocus.code = cc.UW_Result_9
	and work_cfocus.check_type = 'UW_Result_9'
left join risk.quality_check_types work_internet
	on work_internet.code = cc.UW_Result_11
	and work_internet.check_type = 'UW_Result_11'
left join risk.quality_check_types work_survey
	on work_survey.code = cc.UW_Result_12
	and work_survey.check_type = 'UW_Result_12'
left join risk.quality_check_types soc_media
	on soc_media.code = cc.UW_Result_3
	and soc_media.check_type = 'UW_Result_3'
left join risk.quality_check_types soc_media_old
	on soc_media_old.code = cc.UW_Result_3_old
	and soc_media_old.check_type = 'UW_Result_3_old'
left join risk.quality_check_types antifrod
	on antifrod.code = cc.UW_Result_16
	and antifrod.check_type = 'UW_Result_16'
left join risk.quality_check_types negative
	on negative.code = cc.UW_Result_15
	and negative.check_type = 'UW_Result_15'
left join risk.quality_check_types cli_phone
	on cli_phone.code = cc.Result_1_206
	and cli_phone.check_type = 'Result_1_206'
left join risk.quality_check_types income_check
	on income_check.code = cc.Result_1_26
	and income_check.check_type = 'Result_1_26'
left join risk.quality_check_types income_check_big --RDWH-41, Проверка дохода BigInstallment
	on income_check_big.code = cc.Result_1_113
	and income_check_big.check_type = 'Result_1_113'
--
left join #ClientIncomeAdditional_SRC cf 
	on f.[Номер заявки] = cf.Number collate Cyrillic_General_CI_AS
where 1=1
and f.ProductType_Code in ('installment', 'pdl', 'bigInstallment', 'bigInstallmentMarket')
and Статус = 'Контроль данных' 
and f.Задача = 'task:В работе' 
and [Дата статуса] > dateadd(day, - 31, cast(getdate() as date))
;
------------------------------------------Чекеры ПТС
drop table if exists #repbi_quality_report_checkers_pts;
select
f.[КодТипКредитногоПродукта]
,[Дата заведения заявки]
,[Время заведения]
,Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] as datetime)) over (partition by f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный чекер]
,sum([ВремяЗатрачено]) over (partition by f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,case 
	when call15.decision = 'Accept' then 'Одобрено' 
	when call15.decision = 'Decline' then 'Отказано' 
	else 'Аннулировано' 
	end [Решение на этапе]
,fv.dem_fl
,fv.dem_time
,fd.dor_fl
,fd.dem_time as dor_time
,case when cc.Result_1_26 is null then 'Не назначалась проверка' else coalesce(income_check.result, 'Другое') end [Проверка дохода]
,case 
	when cta.ConfirmedIncomeComponent like '%reference2NDFL%' then 'Справка 2-НДФЛ'
	when cta.ConfirmedIncomeComponent like '%CertificateFormBank%' then 'Справка по форме Кредитной  Организации/работодателя'
	when cta.ConfirmedIncomeComponent like '%externalBankStatementForSalary%' then 'Банковская выписка по зарплатному счету (бумажный или электронный вид)'
	when cta.ConfirmedIncomeComponent like '%referencePfrSfr%' then 'Справка из ПФР/СФР о размере установленной пенсии'
	when cta.ConfirmedIncomeComponent is null then 'Не назначалась проверка'
	when cta.ConfirmedIncomeComponent = '' then 'Не назначалась проверка'
	else 'Другое' 
	end [Тип документа о доходе]
into #repbi_quality_report_checkers_pts
from reports.dbo.dm_FedorVerificationRequests f
left join #call1 call1 
	on f.[Номер заявки] = call1.Number
left join #call15 call15 
	on f.[Номер заявки] = call15.Number
left join #fvr fv
	on f.[Номер заявки] = fv.[Номер заявки]
	and fv.Статус = 'Контроль данных' 
	and fv.Задача = 'task:Отложена'
left join #fvr fd
	on f.[Номер заявки] = fd.[Номер заявки]
	and fd.Статус = 'Контроль данных' 
	and fd.Задача = 'task:Требуется доработка'
left join #callcheckverif cc 
	on f.[Номер заявки] = cc.Number
left join risk.quality_check_types income_check
	on income_check.code = cc.Result_1_26
	and income_check.check_type = 'Result_1_26'
left join #IncomeComponent cta
	on f.[Номер заявки] = cta.number
	and cta.rn = 1
where f.Статус = 'Контроль данных' 
and f.Задача = 'task:В работе' 
and [Дата статуса] > dateadd(day, - 31, cast(getdate() as date))
;
------------------------------------------Верификаторы ПТС
drop table if exists #repbi_quality_report_verification_pts;
select 
[Дата заведения заявки]
,[Время заведения]
,a.Branch_name as [Офис заведения заявки]
,f.[Номер заявки]
,[ФИО клиента]
,min(cast([Дата статуса] as datetime)) over (partition by f.[Номер заявки]) as [Дата статуса]
,[ФИО сотрудника верификации/чекер] as [Назначенный верификатор]
,sum([ВремяЗатрачено]) over (partition by f.[Номер заявки]) * 24 * 60 as [Затраченное время (мин сек)]
,case 
	when a2.decision = 'Accept' then 'Одобрено' 
	when a2.decision = 'Decline' then 'Отказано' 
	else 'Аннулировано' 
	end [Решение по клиенту]
,[Последний статус заявки] as [Статус по заявке]
,case when UW_Result_8 is null then 'Не назначалась проверка' else coalesce(cont_client.result, 'Другое') end [Контактность клиента]
,case 
	when UW_Result_30 is null then 'Не назначалась проверка' 
	else coalesce(work_cfocus.result, 'Другое') 
	end [Контактность работодателя по телефонам из Контур Фокуса]
,case 
	when UW_Result_32 is null then 'Не назначалась проверка' 
	else coalesce(work_internet.result, 'Другое') 
	end [Контактность работодателя по телефонам из Интернет]
,case 
	when UW_Result_33 is null then 'Не назначалась проверка' 
	else coalesce(work_survey.result, 'Другое') 
	end [Контактность работодателя по телефонам из Анкеты]
,case 
	when Result_2_40 is not null then soc_media.result
	when UW_Result_3_old is not null then soc_media_old.result
	when coalesce(Result_2_40, UW_Result_3_old) is null then 'Не назначалась проверка' 
	else 'Другое'
	end [СОЦ СЕТИ]
,case when ClientIncomeAdditional is not null then 'Есть' else 'Нет' end [Доп.доход (есть/нет)]
,case when UW_Result_22 is null then 'Не назначалась проверка' else coalesce(antifrod.result, 'Другое') end [Проверка Антифрод]
,case when UW_Result_13 is null then 'Не назначалась проверка' else coalesce(negative.result, 'Другое') end [НЕГАТИВЫ]
,case when UW_Result_vchat is null then 'Не назначалась проверка' else coalesce(vchat.result, 'Другое') end [Видеочат]
,case 
	when result_2_28 is null then 'Не назначалась проверка' 
	else coalesce(cli_phones.result, 'Другое') 
	end [Проверка телефонов по базам - телефон клиента]
,fv.dem_fl
,fv.dem_time
,fd.dor_fl
,fd.dem_time as dor_time
,f.[статус] as stage
,a.producttypecode
,a.productSubTypeCode
into #repbi_quality_report_verification_pts
from reports.dbo.dm_FedorVerificationRequests f
left join (
	select 
	number
	,Branch_name
	,producttypecode
	,productSubTypeCode
	from stg._loginom.Originationlog
	where stage = 'Call 2'
	) a 
	on f.[Номер заявки] = a.Number
LEFT JOIN (
	select 
	number
	,decision
	from stg._loginom.Originationlog
	where stage = 'Call 3'
	) 
	a2 on f.[Номер заявки] = a2.Number
LEFT JOIN (
	select 
	number
	,stage
	,case 
		when stage = 'Call 3' then 'Верификация клиента'
		when stage = 'Call 4' then 'Верификация ТС'
		else stage
		end stage2
	,Result_2_8 as UW_Result_8
	,Result_2_11 as UW_Result_11
	,Result_2_29 as UW_Result_29
	,Result_2_30 as UW_Result_30
	,Result_2_32 as UW_Result_32
	,Result_2_33 as UW_Result_33
	,Result_2_40
	,Result_2_22 as UW_Result_22
	,Result_2_13 as UW_Result_13
	,coalesce(result_2_34, result_3_3) as UW_Result_vchat
	,result_2_28
	,coalesce(Result_1_203, Result_2_103) as UW_Result_3_old --СОЦ СЕТИ старые правила
	from stg._loginom.callcheckverif_log
	where stage in ('Call 3', 'Call 4')
	) c 
	on f.[Номер заявки] = c.Number
	and c.stage2 = f.[статус]
--справочник проверок
left join risk.quality_check_types cont_client
	on cont_client.code = c.UW_Result_8
	and cont_client.check_type = 'UW_Result_8'
left join risk.quality_check_types work_cfocus
	on work_cfocus.code = c.UW_Result_30
	and work_cfocus.check_type = 'UW_Result_30'
left join risk.quality_check_types work_internet
	on work_internet.code = c.UW_Result_32
	and work_internet.check_type = 'UW_Result_32'
left join risk.quality_check_types work_survey
	on work_survey.code = c.UW_Result_33
	and work_survey.check_type = 'UW_Result_33'
left join risk.quality_check_types soc_media
	on soc_media.code = c.Result_2_40
	and soc_media.check_type = 'Result_2_40'
left join risk.quality_check_types soc_media_old
	on soc_media_old.code = c.UW_Result_3_old
	and soc_media_old.check_type = 'UW_Result_3_old'
left join risk.quality_check_types antifrod
	on antifrod.code = c.UW_Result_22
	and antifrod.check_type = 'UW_Result_22'
left join risk.quality_check_types negative
	on negative.code = c.UW_Result_13
	and negative.check_type = 'UW_Result_13'
left join risk.quality_check_types vchat
	on vchat.code = c.UW_Result_vchat
	and vchat.check_type = 'UW_Result_vchat'	
left join risk.quality_check_types cli_phones
	on cli_phones.code = c.result_2_28
	and cli_phones.check_type = 'result_2_28'	
--
left join #ClientIncomeAdditional_SRC cf 
	on f.[Номер заявки] = cf.Number collate Cyrillic_General_CI_AS
left join #fvr fv
	on f.[Номер заявки] = fv.[Номер заявки]
	and (fv.Статус = 'Верификация клиента' or fv.Статус = 'Верификация ТС')
	and fv.Задача = 'task:Отложена'
left join #fvr fd
	on f.[Номер заявки] = fd.[Номер заявки]
	and (fd.Статус = 'Верификация клиента' or fd.Статус = 'Верификация ТС')
	and fd.Задача = 'task:Требуется доработка'
where (f.Статус = 'Верификация клиента' or f.Статус = 'Верификация ТС') 
and f.Задача = 'task:В работе' 
and [Дата статуса] > dateadd(day, - 31, cast(getdate() as date))
;
---------------------------------------------------------------------------------
------------------------------------------Итог Чекеры----------------------------
---------------------------------------------------------------------------------
drop table if exists #final_checkers;
-------беззалог
select 
distinct ProductType_Code as product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,[Отложена]
,dem_time as [Время в отложенных (мин сек)]
,[Доработка]
,dor_time as [Время на доработке (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,cast('Нет' as varchar(200)) as [Доп доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Проверка телефонов по базам - телефон клиента]
,[Проверка дохода]
,[Тип документа о доходе]
,getdate() as dt_dml
into #final_checkers
from #repbi_quality_report_checkers_unsecured
;
-------PTS
insert into #final_checkers
select 
[КодТипКредитногоПродукта] as product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный чекер]
,[Затраченное время (мин сек)]
,[Решение на этапе]
,case when dem_fl = 1 then 'Да' else 'Нет' end 'Отложена'
,dem_time [Время в отложенных (мин сек)]
,case when dor_fl = 1 then 'Да' else 'Нет' end 'Доработка'
,dor_time [Время на доработке (мин сек)]
,'' as [Решение по клиенту]
,'' as [Статус по заявке]
,'' as [Контактность клиента]
,'' as [Контактность работодателя по телефонам из Контур Фокуса]
,'' as [Контактность работодателя по телефонам из Интернет]
,'' as [Контактность работодателя по телефонам из Анкеты]
,'' as [Доп доход (есть/нет)]
,'' as [Проверка Антифрод]
,'' as [НЕГАТИВЫ]
,'' as [СОЦ СЕТИ]
,'' as [Проверка телефонов по базам - телефон клиента]
,[Проверка дохода]
,[Тип документа о доходе]
,getdate() as dt_dml
from #repbi_quality_report_checkers_pts
;
---------------------------------------------------------------------------------
------------------------------------------Итог Верификаторы----------------------
---------------------------------------------------------------------------------
drop table if exists #final_verification;
select 
distinct cast('PTS' as varchar(100)) as product
,[Дата заведения заявки]
,[Время заведения]
,[Офис заведения заявки]
,[Номер заявки]
,[ФИО клиента]
,[Дата статуса]
,[Назначенный верификатор]
,[Затраченное время (мин сек)]
,[Решение по клиенту]
,[Статус по заявке]
,[Контактность клиента]
,[Контактность работодателя по телефонам из Контур Фокуса]
,[Контактность работодателя по телефонам из Интернет]
,[Контактность работодателя по телефонам из Анкеты]
,[Доп.доход (есть/нет)]
,[Проверка Антифрод]
,[НЕГАТИВЫ]
,[СОЦ СЕТИ]
,[Видеочат]
,[Проверка телефонов по базам - телефон клиента]
,case when dem_fl = 1 then 'Да' else 'Нет' end 'Отложена'
,dem_time as [Время в отложенных (мин сек)]
,case when dor_fl = 1 then 'Да' else 'Нет' end 'Доработка'
,dor_time as [Время на доработке (мин сек)]
,getdate() as dt_dml
,stage
,producttypecode
,productSubTypeCode
into #final_verification
from #repbi_quality_report_verification_pts
;
-----------------------------------------------Внесение данных
if OBJECT_ID('risk.repbi_quality_report_checkers_151225') is null
begin
	select top(0) * into risk.repbi_quality_report_checkers_151225
	from #final_checkers
end;

if OBJECT_ID('risk.repbi_quality_report_verification_151225') is null
begin
	select top(0) * into risk.repbi_quality_report_verification_151225
	from #final_verification
end;

BEGIN TRANSACTION
	delete from risk.repbi_quality_report_checkers_151225;
	insert into risk.repbi_quality_report_checkers_151225
	select * from #final_checkers
	;
	delete from risk.repbi_quality_report_verification_151225;
	insert into risk.repbi_quality_report_verification_151225
	select * from #final_verification
COMMIT TRANSACTION;

drop table if exists #ClientIncomeAdditional_SRC;
drop table if exists #call1;
drop table if exists #call15;
drop table if exists #callcheckverif;
drop table if exists #fvr_without_coll;
drop table if exists #fvr;
drop table if exists #IncomeComponent;
drop table if exists #repbi_quality_report_checkers_unsecured;
drop table if exists #repbi_quality_report_checkers_pts;
drop table if exists #repbi_quality_report_verification_pts;
drop table if exists #final_checkers;
drop table if exists #final_verification;

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
		rollback TRANSACTION;
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