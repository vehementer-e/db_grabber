CREATE procedure [riskCollection].[cdm_doubles_check] as 
begin

declare @cdm_doubles_cnt int;
select @cdm_doubles_cnt = 
count(*) from (
select *, row_number() over (partition by external_id, d order by (select null)) as duprunk
from riskCollection.collection_datamart
) as t
where duprunk > 1
;

declare @apps2_doubles_cnt int;
select @apps2_doubles_cnt = 
count(*) from (
select *, row_number() over (partition by number order by (select null)) as duprunk
from risk.applications2
) as t
where duprunk > 1
;

declare @cdm_text nvarchar (255) = concat('В витрине Collection обнаружено дублей - ', @cdm_doubles_cnt);
declare @apps2_text nvarchar (255) = concat('В applications2 обнаружено дублей - ', @apps2_doubles_cnt);
exec CommonDb.[SendNotification].[Send2GChat_RiskCollecitonNotification] @text = @cdm_text;
exec CommonDb.[SendNotification].[Send2GChat_RiskCollecitonNotification] @text = @apps2_text;
end