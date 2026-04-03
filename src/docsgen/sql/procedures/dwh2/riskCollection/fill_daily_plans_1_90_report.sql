CREATE procedure [riskCollection].[fill_daily_plans_1_90_report] as 
begin

if (select max(rep_dt_month) from riskCollection.daily_plans_1_90) < DATEFROMPARTS(year(getdate()),month(getdate()),1)
begin
	truncate table riskcollection.daily_plans_1_90_report;
	insert into riskcollection.daily_plans_1_90_report
	select 
	bucket_from,bucket_to,Сохраненный,Приведенный,Product,rep_dt_month
	from riskCollection.daily_plans_1_90
	where rep_dt_month>= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));

	insert into riskcollection.daily_plans_1_90_report
	select 
	bucket_from,bucket_to,Сохраненный,Приведенный,Product,DATEFROMPARTS(year(getdate()),month(getdate()),1) as rep_dt_month
	from riskCollection.daily_plans_1_90
	where rep_dt_month = (select max(rep_dt_month) from riskCollection.daily_plans_1_90)
	and rep_dt_month>= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));
end

else 
begin
	truncate table riskcollection.daily_plans_1_90_report;
	insert into riskcollection.daily_plans_1_90_report
	select 
	bucket_from,bucket_to,Сохраненный,Приведенный,Product,rep_dt_month
	from riskCollection.daily_plans_1_90
	where rep_dt_month>= dateadd(mm,-13,DATEFROMPARTS(year(getdate()), month(getdate()), 1));
end

end

