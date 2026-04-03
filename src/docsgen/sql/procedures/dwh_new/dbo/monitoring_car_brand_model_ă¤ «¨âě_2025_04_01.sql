
CREATE procedure [dbo].[monitoring_car_brand_model]  as

declare @srcname varchar(100) = 'MONITORING DET_CAR_MODEL_MAPPING';
declare @vinfo varchar(1000);
declare @cnt int;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';


--сборка выдач за последний месяц

drop table if exists #stg_cred;
with base as (
	select a.Код as external_id, 
	dateadd(yy,-2000,cast(c.Период as datetime)) as status_dt,
	d.Наименование as status_name,
	ROW_NUMBER() over (partition by a.Код order by c.Период desc) as rown 
	from stg._1cCMR.Справочник_Договоры a
	left join stg._1cCMR.РегистрСведений_СтатусыДоговоров c
	on a.Ссылка = c.Договор
	left join stg._1cCMR.Справочник_СтатусыДоговоров d
	on c.Статус = d.Ссылка
	where dateadd(yy,-2000,cast(a.Дата as date)) >= dateadd(dd,-30,cast(getdate() as date))
	and dateadd(yy,-2000,cast(a.Дата as date)) < dateadd(dd,0,cast(getdate() as date)) --cast(getdate() as date)
	and a.ПометкаУдаления = 0
	and a.Тестовый = 0
)
select a.external_id, a.status_dt, a.status_name 
into #stg_cred
from base a
where 1=1
and a.rown = 1 
and a.status_name not in ('Аннулирован','Зарегистрирован')
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_cred';



--залог
drop table if exists #cred_pledge;
select distinct 
a.external_id,
b.vin as VIN
into #cred_pledge
from #stg_cred a
inner join dwh2.risk.strategy_datamart b
on a.external_id = b.external_id
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#cred_pledge';


--------------FEDOR------------------------------------------------------------------------------



drop table if exists #stg_fedor;
select 
a.VIN, 
b.CreatedOn as app_dt,
b.Number as app_id,
br.[Name] as brand,
mdl.[Name] as model,
cast(1 as bit) as flag_significant

into #stg_fedor
from (select distinct VIN from #cred_pledge) a
inner join stg._fedor.core_ClientRequest b
on a.VIN = b.Vin collate Cyrillic_General_CI_AS
inner join stg._fedor.core_ClientAssetTs c
on b.IdAsset = c.Id

left join stg._fedor.dictionary_TsBrand br --марка
on b.IdTsBrand = br.Id
left join stg._fedor.dictionary_TsModel mdl --модель
on b.IdTsModel = mdl.Id
where cast(b.CreatedOn as date) < cast(getdate() as date)
;

update #stg_fedor set flag_significant = 0 where brand is null and model is null;
delete from #stg_fedor where flag_significant = 0;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_fedor';



-------------- МФО ------------------------------------------------------------------------------

drop table if exists #stg_MFO;
select a.VIN, 
a.Номер as app_id,
dateadd(yy,-2000,cast(a.Дата as date)) as app_date,
a.МаркаАвто as brand,
a.МодельАвто as model,
cast(1 as bit) as flag_significant 

into #stg_MFO
from stg._1cMFO.Документ_ГП_Заявка a
inner join (select distinct vin from #cred_pledge) b
on a.VIN = b.VIN
where dateadd(yy,-2000,cast(a.Дата as date)) < cast(getdate() as date)

;

update #stg_MFO set flag_significant = 0 where brand is null and model is null;
delete from #stg_MFO where flag_significant = 0;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_mfo';



---объединение всех источников

drop table if exists #stg_total;
select 
a.VIN, a.app_dt as dt1, a.app_dt as dt2, 'FEDOR' as src,
a.brand collate Cyrillic_General_CI_AS as brand, 
a.model collate Cyrillic_General_CI_AS as model
into #stg_total
from #stg_fedor a
union all
select a.VIN, a.app_date as dt1, a.app_date as dt2, 'MFO' as src,
a.brand, a.model
from #stg_MFO a
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#stg_total';


-- Марка + модель
drop table if exists #final_brand_model;
with base2 as (
select a.VIN, a.brand, a.model, 
ROW_NUMBER () over (partition by a.vin order by case when concat(a.brand, a.model) not like '%[а-яА-Я]%' then 1 else 0 end desc, a.dt1 desc) as rown
from #stg_total a
where a.brand is not null and a.model is not null
)
select a.VIN, a.brand, a.model
into #final_brand_model
from base2 a
where a.rown = 1
;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#final_brand_model';



drop table if exists #new_brandmodel;
select distinct a.brand, a.model
into #new_brandmodel
from #final_brand_model a
left join RiskDWH.dbo.det_car_model_mapping b
on a.brand = b.portf_brand
and a.model = b.portf_model
where b.portf_brand is null
;


select @cnt = count(*) from #new_brandmodel;
select @vinfo = case when @cnt = 0 then 'No new brand-model' else concat('New brand-model cnt = ', @cnt) end;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



if @cnt > 0 
	begin

		exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'MERGE Into DET';

		begin transaction;

			merge into RiskDWH.dbo.det_car_model_mapping dst
			using #new_brandmodel src
			on (src.brand = dst.portf_brand and src.model = dst.portf_model)
			when not matched then insert (portf_brand, portf_model) values (src.brand, src.model)
			;

		commit transaction;


	--Оповещение по Email d.cyplakov@carmoney.ru 
	declare @subject nvarchar(255) = 'Появились новые записи в справочнике DET_CAR_MODEL_MAPPING'
	declare @body nvarchar(1024) = 'Появились новые записи в справочнике DET_CAR_MODEL_MAPPING - ' + cast(@cnt as nvarchar(255))
	EXEC msdb.dbo.sp_send_dbmail  
			@profile_name = 'Default',  
			@recipients = 'd.cyplakov@carmoney.ru',  
			@body = @body,  
			@body_format='HTML', 
			@subject = '@subject' 
	end


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';