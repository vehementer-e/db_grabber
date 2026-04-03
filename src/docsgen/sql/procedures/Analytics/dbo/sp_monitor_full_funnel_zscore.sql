create   procedure sp_monitor_full_funnel_zscore
    @period_type nvarchar(20) = 'day', 
    @history_periods int = 30,
    @ignore_days int = 1,
    @date_column nvarchar(128) = NULL 
as
begin
    set nocount on;

create table #funnel_results (
    report_date nvarchar(20),
    step_order int,
    step_name nvarchar(128),
    next_step_name nvarchar(128),
    vol int,
	base_vol int,
    cr float,
	base_cr float,
    t_min float,
	base_t_min float,
    z_v float,
	z_c float,
	z_t float,
    rows_hist int
);

declare @steps table (id int identity(1,1), col_name nvarchar(128));
insert into @steps (col_name) values 
('_profilePts'), ('_subQueryInfoPts'), ('_docPhotoPts'), ('_docPhotoLoadedPts'), ('_pack1Pts'),
('_pack1SignedPts'), ('_clientAndDocPhoto2Pts'), ('_additionalInfoPTS'), ('_carDocPhotoPTS'),
('_incomeOfferSelectionPTS'), ('_proofOfIncomePTS'), ('_proofOfIncomeLoadedPTS'), ('_payMethodPts'),
('_cardLinkedPTS'), ('_carPhotoPTS'), ('_fullRequestPTS'), ('_approvalPTS'), ('_pack2PTS'),
('_pack2ProfileSignedPTS'), ('_pack2SignedPTS');

declare @i int = 1, @max int = (select max(id) from @steps);
declare @curr nvarchar(128), @next nvarchar(128);

while @i <= @max
begin
    select @curr = col_name from @steps where id = @i;
    select @next = col_name from @steps where id = @i + 1;

    insert into #funnel_results (report_date, vol, cr, t_min, z_v, z_c, z_t, rows_hist, base_vol, base_cr, base_t_min)
    exec sp_monitor_step_full_analytics 
        @current_step = @curr, @next_step = @next, 
        @period_type = @period_type, @history_periods = @history_periods, 
        @ignore_days = @ignore_days, @date_column = @date_column;

    update #funnel_results set step_order = @i, step_name = @curr, next_step_name = isnull(@next, 'FINISH') 
    where step_order is null;
    set @i = @i + 1;
end

insert into monitor_funnel_log (
    report_date, period_type, step_order, step_name, next_step_name,
    vol, cr, t_min, z_v, z_c, z_t, history_periods_used, 
    base_vol, base_cr, base_t_min, status_vol, status_cr, status_time
)
select 
    report_date, @period_type, step_order, step_name, next_step_name,
    vol, cr, t_min, z_v, z_c, z_t, @history_periods, 
    base_vol, base_cr, base_t_min,
    case when rows_hist < @history_periods then N'Мало данных' when z_v < -2.0 then N'Обвал трафика' when z_v > 2.0 then N'Рост притока' else N'Норма' end,
    case when rows_hist < @history_periods then N'Мало данных' when isnull(z_c, 0) < -1.5 then N'Падение конверсии' when isnull(z_c, 0) > 1.5 then N'Рост эффективности' else N'Норма' end,
    case when rows_hist < @history_periods then N'Мало данных' when z_t < -2.0 then N'Аномально быстро' when z_t > 2.0 then N'Зависание' else N'Норма' end
from #funnel_results;

	declare @rep_date nvarchar(20) = (select top 1 report_date from #funnel_results);
declare @email_body nvarchar(max) = N'<b>📊 Отчет по воронке PTS за ' + isnull(@rep_date, '') + N'</b><br>' + 
                                    N'(Сравнение: ' + cast(@history_periods as nvarchar) + N' ' + @period_type + N')<br><br>';

select @email_body = @email_body + 
    N'<b>🔹 ШАГ: ' + step_name + N' -> ' + next_step_name + N'</b><br>' + 

    case when z_v < -2.0 then N'⚠️' when z_v > 2.0 then N'🚀' else N'📥' end +
    N' Приток: ' + case when z_v < -2.0 then N'<b>' + cast(vol as nvarchar) + N'</b>' 
		when z_v > 2.0 then N'<b>' + cast(vol as nvarchar) + N'</b>' else cast(vol as nvarchar) end + 
    N' (норма: ' + cast(base_vol as nvarchar) + N') ' +
    case when z_v < -2.0 then N'<b>🔴 ОБВАЛ</b>' when z_v > 2.0 then N'<b>🟢 РОСТ</b>' else N'⚪' end + N'<br>' +

    case when isnull(z_c,0) < -1.5 then N'📉' when isnull(z_c,0) > 1.5 then N'📈' else N'📊' end +
    N' Конверсия: ' + case when isnull(z_c,0) < -1.5 then N'<b>' + cast(round(cr,1) as nvarchar) + N'%</b>' 
		when isnull(z_c,0) > 1.5 then N'<b>' + cast(round(cr,1) as nvarchar) + N'%</b>' else cast(round(cr,1) as nvarchar) + N'%' end + 
    N' (норма: ' + cast(round(base_cr,1) as nvarchar) + N'%) ' +
    case when isnull(z_c,0) < -1.5 then N'<b>🔴 ПАДЕНИЕ</b>' when isnull(z_c,0) > 1.5 then N'<b>🟢 РОСТ</b>' else N'⚪' end + N'<br>' +

    case when z_t > 2.0 then N'🐢' when z_t < -2.0 then N'⚡' else N'⏱' end +
    N' Время: ' + case when z_t > 2.0 then N'<b>' + cast(round(t_min,1) as nvarchar) + N' мин</b>' 
		when z_t < -2.0 then N'<b>' + cast(round(t_min,1) as nvarchar) + N' мин</b>' else cast(round(t_min,1) as nvarchar) + N' мин' end + 
    N' (норма: ' + cast(round(base_t_min,1) as nvarchar) + N' мин) ' +
    case when z_t > 2.0 then N'<b>🔴 ЗАВИСАНИЕ</b>' when z_t < -2.0 then N'<b>🟢 АНОМАЛЬНО БЫСТРО</b>' else N'⚪' end + N'<br>' +
        
    N'---<br>'
from #funnel_results
where (abs(z_v) > 2.0 OR abs(isnull(z_c,0)) > 1.5 OR abs(z_t) > 2.0);

if len(@email_body) < 300 
    set @email_body = @email_body + N'<b>✅ Аномалий не обнаружено. Все показатели в норме.</b>';

declare @subject nvarchar(max) = N'📊 Мониторинг воронки PTS: ' + isnull(@rep_date, '');
    
exec [notify_html] @subject, 'a.buntova@smarthorizon.ru;p.ilin@smarthorizon.ru;o.kolosova@carmoney.ru;e.markin@smarthorizon.ru;a.malkova@smarthorizon.ru', @email_body;

select 
    report_date as [Дата],
	step_order as [Порядок],
	step_name + ' -> ' + next_step_name as [Шаг],
    vol,
	base_vol as [Норма притока],
	cr,
	base_cr as [Норма конверсии],
	t_min,
	base_t_min as [Норма времени],
    z_v,
	z_c,
	z_t 
from #funnel_results order by step_order;

    drop table #funnel_results;
end