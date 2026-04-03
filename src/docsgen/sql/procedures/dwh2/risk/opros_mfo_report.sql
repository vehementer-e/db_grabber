
CREATE PROC [risk].[opros_mfo_report]
	@rep_date date = null
AS
BEGIN
--exec [risk].[opros_mfo_report]
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

-----------------------------выбор даты обновления
declare @today date = cast(getdate() as date) --сегодняшняя дата
------максимальная дата, разница между которой и последней менее 14 дней. т.е. ищем дату, до которой еще не прошло 14 дней с предыдущей
declare @rdt date = 
(
select max(biweek_day)
from 
	(
	select 
	biweek_day
	,datediff(dd, biweek_day, lead(biweek_day) over (partition by null order by biweek_day)) as dif
	from 
		(
		select 
		distinct biweek_day 
		from risk.opros_mfo_apps
		) t
	) tt
	where dif < 14
)

if @rep_date is null	
	set @rep_date = case when datediff(dd, @rdt, @today) > 14 then @today else @rdt end --если нашел сташком старую дату, то берем сегодняшнюю

declare @msg_error NVARCHAR(255) = concat('opros_mfo_report хотел обновиться с даты ', @rep_date)
declare @subject_error  NVARCHAR(255) = 'alert opros_mfo_report';
declare @rdt_text nvarchar (255) = concat('opros_mfo_report обновляется с даты ', @rep_date);
exec CommonDb.[SendNotification].[Send2GChat_RiskCollecitonNotification] @text = @rdt_text;

--если все равно дата слишком старая, присылать алерт и ничего не делать
if datediff(dd, @rep_date, getdate()) > 15
begin
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
	,@recipients = 'ala.kurikalov@smarthorizon.ru'
	,@body = @msg_error
	,@body_format = 'TEXT'
	,@subject = @subject_error
end

else 
--если дата устраивает, то работаем
begin
BEGIN TRY
-----------------------------бивикли календарь. начинается с певого дня года, далее шаги по 14 дней
--просто создаем календарь по дням с добавлением custom_biweeknum_year (год + номер двухнеделья)
drop table if exists #cal_srs;
create table #cal_srs (CalendarDate date, custom_biweeknum int, custom_biweeknum_year nvarchar(50));
declare @vStartDate date = dateadd(dd, 1, @rep_date);
while @vStartDate <> cast(getdate() as date)
    begin
    insert into #cal_srs (CalendarDate, custom_biweeknum, custom_biweeknum_year) 
	values
        (
        @vStartDate
		,((datediff(day, datefromparts(year(@vStartDate), 1,1), @vStartDate)/7 + 1)-1)/2+1 
		,concat_ws('-', year(@vStartDate), ((datediff(day, datefromparts(year(@vStartDate), 1,1), @vStartDate)/7 + 1)-1)/2+1) 
        );
    set @vStartDate = dateadd(day,1,@vStartDate);
    end;

--выводим только custom_biweeknum_year (год + номер двухнеделья) и последнюю дату за эти 2 недели
drop table if exists #cals;
select
distinct custom_biweeknum_year
,custom_biweeknum
,first_value(CalendarDate) over(partition by custom_biweeknum_year order by CalendarDate desc) as biweek_day
into #cals
from #cal_srs
;
-----------------------------причины отказов по ПДН
drop table if exists #ref;
select
number
,Decision_Code
,row_number() over (partition by number order by call_date) as rn
into #ref
from stg._loginom.originationlog
where Decision = 'Decline'
and Decision_Code in (
'100.0131.001', --это птс и беззалог и биг
'100.0131.002', -- беззалог
'100.0130.001', --птс
'100.0130.021', --птс
'100.0130.003', --птс
'100.0130.041')--птс и биг
and cast(call_date as date) >= dateadd(dd, 1, @rep_date)
and call_date < cast(getdate() as date)
;
----------------------------канал заявки online/offline
/*
----это для сверки источника по заявкам
select 
number
,isOnlineOrigin 
from analytics.dbo.v_fa
*/
drop table if exists #channels;
select
number
,Branch_name
,case 
	when Branch_name in ('Личный кабинет клиента', 'Мобильное приложение', 'NULL', '') then 'online' 
	--when Branch_name is null then 'online'
	else 'offline' end channel
,row_number() over (partition by number order by call_date) as rn
into #channels
from stg._loginom.Originationlog
where cast(call_date as date) >= dateadd(dd, 1, @rep_date)
and call_date < cast(getdate() as date)
and number is not null
and Branch_name is not null
;
----------------------------канал выдачи online/offline
drop table if exists #channels_credits;
select
ЗаймПредоставленный.номердоговора as external_id
,case when СпособыПодачиЗаявления.имя = 'Посреднический' then 'offline' else 'online' end chanel
,row_number() over (partition by ЗаймПредоставленный.номердоговора order by дата) as rn
into #channels_credits
from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный ЗаймПредоставленный
left join Stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления СпособыПодачиЗаявления
	on ЗаймПредоставленный.СпособПодачиЗаявления = СпособыПодачиЗаявления.ссылка
where ЗаймПредоставленный.СпособПодачиЗаявления <> 0x00000000000000000000000000000000
--where дата > dateadd(year, 2000, @rdt)
;
-----------------------------заявки, сгруппированные бивикли по фин.статусам, Decline pdn и каналу заявки - по датам из календаря, а не из applications
drop table if exists #apps;
select
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1) as custom_biweeknum_year
,count(app.number) as number_cnt
,app.FIN_STATUS
,case 
	when ref.Decision_Code is not null and app.pdn_income_bucket = '2. 0,5 - 0,8' then 'Decline pdn 50-80'
	when ref.Decision_Code is not null and app.pdn_income_bucket = '3. > 0,8' then 'Decline pdn >80'
	else null
	end 'Decline pdn'
,coalesce(channels.channel, 'online') as channel
into #apps
from #cal_srs cal_srs
left join risk.applications2 app
	on cal_srs.CalendarDate = app.date
left join #ref ref
	on app.number = ref.number
	and ref.rn = 1
left join #channels channels
	on app.number = channels.number
	and channels.rn = 1
where cal_srs.CalendarDate >= dateadd(dd, 1, @rep_date)
and cal_srs.CalendarDate < cast(getdate() as date)
group by 
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1) 
,app.FIN_STATUS
,case 
	when ref.Decision_Code is not null and app.pdn_income_bucket = '2. 0,5 - 0,8' then 'Decline pdn 50-80'
	when ref.Decision_Code is not null and app.pdn_income_bucket = '3. > 0,8' then 'Decline pdn >80'
	else null end
,coalesce(channels.channel, 'online')
;
-----------------------------выдачи, сгруппированные бивикли по датам из календаря, а не из credits - с указанием канала выдачи
drop table if exists #credits;
select
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1) as custom_biweeknum_year
,round(sum(c.amount/1000), 3) as limit_t_r
,coalesce(channels_credits.chanel, 'online') as channel
into #credits
from #cal_srs cal_srs
left join risk.credits c
	on cal_srs.CalendarDate = c.startdate
left join #channels_credits channels_credits
	on c.external_id = channels_credits.external_id
	and channels_credits.rn = 1
where cal_srs.CalendarDate >= dateadd(dd, 1, @rep_date)
and cal_srs.CalendarDate < cast(getdate() as date)
group by 
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1)
,coalesce(channels_credits.chanel, 'online')
;
-----------------------------цессии, сгруппированные бивикли
drop table if exists #cessions;
select
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1) as custom_biweeknum_year
,round(sum(ces.[остаток ОД]/1000), 3) as cession_sum
into #cessions
from #cal_srs cal_srs
left join riskCollection.cessions ces
	on cal_srs.CalendarDate = ces.dt
where cal_srs.CalendarDate >= dateadd(dd, 1, @rep_date)
and cal_srs.CalendarDate < cast(getdate() as date)
and ces.[Обратный выкуп] = 0
group by 
concat_ws('-', year(cal_srs.CalendarDate), ((datediff(day, datefromparts(year(cal_srs.CalendarDate), 1,1), cal_srs.CalendarDate)/7 + 1)-1)/2+1)
;
-----------------------------портфель - только по определенным датам для отчета
drop table if exists #portf;
select 
sbal.d
,sbal.external_id
,sbal.[остаток од]
,coalesce(channels_credits.chanel, 'online') as channel
into #portf
from dbo.dm_CMRStatBalance sbal
left join #channels_credits channels_credits
	on sbal.external_id = channels_credits.external_id
	and channels_credits.rn = 1
where exists (select biweek_day from #cals where biweek_day = d)
;

-----------------------------
-----------своды-------------
-----------------------------

-----------------------------свод по заявкам
drop table if exists #total_apps;
select 
apps.custom_biweeknum_year --номер двухнеделья и год
,coalesce(apps.number_cnt, 0) as number_cnt
,apps.FIN_STATUS
,apps.[Decline pdn]
,apps.channel
,cals.biweek_day --дата окончания двухнеделья
into #total_apps
from #apps apps
left join #cals cals
	on apps.custom_biweeknum_year = cals.custom_biweeknum_year
;
-----------------------------свод по выдачам
drop table if exists #total_credits;
select 
credits.custom_biweeknum_year
,coalesce(credits.limit_t_r, 0) as limit_t_r
,credits.channel
,cals.biweek_day
into #total_credits
from #credits credits
left join #cals cals
	on credits.custom_biweeknum_year = cals.custom_biweeknum_year
;
-----------------------------свод по цессиям
drop table if exists #total_ces;
select 
cessions.custom_biweeknum_year
,cessions.cession_sum
,cals.biweek_day
into #total_ces
from #cessions cessions
left join #cals cals
	on cessions.custom_biweeknum_year = cals.custom_biweeknum_year
;
-----------------------------свод портфель
drop table if exists #total_portf;
select 
d
,channel
,round(sum([остаток од])/1000, 3) as 'Текущий портфель т_р'
into #total_portf
from #portf
group by d, channel
;
-----------------------------внесение данных
if OBJECT_ID('risk.opros_mfo_apps') is null
begin
	select top(0) * into risk.opros_mfo_apps
	from #total_apps
end;

if OBJECT_ID('risk.opros_mfo_credits') is null
begin
	select top(0) * into risk.opros_mfo_credits
	from #total_credits
end;

if OBJECT_ID('risk.opros_mfo_cessions') is null
begin
	select top(0) * into risk.opros_mfo_cessions
	from #total_ces
end;

if OBJECT_ID('risk.opros_mfo_portf') is null
begin
	select top(0) * into risk.opros_mfo_portf
	from #total_portf
end;

BEGIN TRANSACTION
delete from risk.opros_mfo_apps
where biweek_day >= dateadd(dd, 1, @rep_date); 
insert into risk.opros_mfo_apps
select * from #total_apps;
insert into risk.opros_mfo_apps_history --добавляем данные в историческую таблицу
select *, getdate() from #total_apps;

delete from risk.opros_mfo_credits
where biweek_day >= dateadd(dd, 1, @rep_date); 
insert into risk.opros_mfo_credits
select * from #total_credits;
insert into risk.opros_mfo_credits_history --добавляем данные в историческую таблицу
select *, getdate() from #total_credits;

delete from risk.opros_mfo_cessions
where biweek_day >= dateadd(dd, 1, @rep_date); 
insert into risk.opros_mfo_cessions
select * from #total_ces;
insert into risk.opros_mfo_cessions_history --добавляем данные в историческую таблицу
select *, getdate() from #total_ces;

delete from risk.opros_mfo_portf
where d >= dateadd(dd, 1, @rep_date);
insert into risk.opros_mfo_portf
select * from #total_portf;
insert into risk.opros_mfo_portf_history --добавляем данные в историческую таблицу
select *, getdate() from #total_portf;

COMMIT TRANSACTION;

drop table if exists #cal_srs;
drop table if exists #cals;
drop table if exists #ref;
drop table if exists #channels;
drop table if exists #channels_credits;
drop table if exists #apps;
drop table if exists #credits;
drop table if exists #cessions;
drop table if exists #portf;
drop table if exists #total_apps;
drop table if exists #total_credits;
drop table if exists #total_ces;
drop table if exists #total_portf;

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
end
END;