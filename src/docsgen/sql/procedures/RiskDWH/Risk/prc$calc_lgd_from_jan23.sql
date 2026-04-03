
/**************************************************************************
Расчет LGD с учетом рекавери и списаний для новой методики по БУ (с янв 2023)

Revisions:
dt			user				version		description
07/02/23	datsyplakov			v1.0		Создание процедуры
11/05/23	datsyplakov			v1.1		Уменьшение шага дисконта с 0.1 на 0.05
09/07/24	datsyplakov			v1.2		Добавление параметра @mod_dt_from - 
											ограничение снизу по дате рекавери 
											(не путать с датой выхода в дефолт!!!)

*************************************************************************/

CREATE procedure [Risk].[prc$calc_lgd_from_jan23]
@repdate date = null,
@vers int = null,
@mod_dt_from date = '2018-01-01'

as

begin try


exec dbo.prc$set_debug_info @src = 'calc_lgd_from_jan23', @info = 'begin try';

if @vers is null begin

	select @vers = isnull(max(vers),0) + 1 from (
		select distinct a.vers
		from risk.prov2_lgd a
		where a.rep_dt = @repdate
	) a

end


	declare @srcname varchar(100) = 'БУ резервы новая методика (с янв 2023)';

	declare @vinfo varchar(1000) = 'START rep_dt = ' + convert(varchar(10),@repdate,104)
									+ ' , vers = ' + cast(@vers as varchar(5))
									+ ' , mod_dt_from = ' + format(@mod_dt_from,'dd.MM.yyyy')
									;

	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'PART 1 (91+) LGD';


	/****************** средневзвешенные рекавери-рейты и списания ******************/




	drop table if exists #avg_recovery_and_wo;
	select a.mod_num,
	sum(a.pay_od) / sum(b.principal_rest) as recovery_rate,
	sum(a.writeoff_od) / sum(b.principal_rest) as wo_rate
	into #avg_recovery_and_wo
	from risk.lgd_payments_agg a
	left join risk.lgd_od_before_npl_agg b
	on a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	and a.generation = b.generation
	where a.dt_to = @repdate
	and a.dt_from = '2018-01-01'
	and a.mod_num <= 24
	and a.mod_dt >= @mod_dt_from
	group by a.mod_num
	;




	/****************** коэффициенты степенной регрессии y = a * x ^ b - рекавери ******************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#power_OLS_recovery';


	drop table if exists #power_OLS_recovery;

	with base as (
		select 
		cast(a.mod_num as float) as init_x,
		a.recovery_rate as init_y,
		log(a.mod_num) as x, 
		log(a.recovery_rate) as y
		from #avg_recovery_and_wo a
	),
	stage1 as (
		select 
		cast(sum(b.x * b.y) as float) as sum_xy, 
		cast(sum(b.x) as float) as sum_x, 
		cast(sum(b.y) as float) as sum_y, 
		cast(sum(power(b.x,2)) as float) as sum_x_sq, 
		cast(power( sum(b.x), 2) as float) as sq_sum_x,
		count(*) as n
		from base b
	),
	stage2 as (
		select (s.n * s.sum_xy - s.sum_x * s.sum_y) / (s.n * s.sum_x_sq - s.sq_sum_x) as koef_a
		from stage1 s
	),
	koefs as (
		select ss.koef_a, (s.sum_y - ss.koef_a * s.sum_x) / s.n as koef_b from stage1 s
		left join stage2 ss
		on 1=1
	)
	select * 
	into #power_OLS_recovery
	from koefs a
	
	--,model_values as (
	--	select 
	--	bs.init_x,
	--	bs.init_y,
	--	bs.y, 
	--	bs.x, 
	--	k.koef_a, 
	--	k.koef_b, 
	--	case 
	--	when k.koef_a < 0 then exp(k.koef_b) / power(bs.init_x, -1.0 * k.koef_a)
	--	when k.koef_a >= 0 then exp(k.koef_b) * power(bs.init_x, k.koef_a)
	--	end as y_model
	--	from base bs
	--	left join koefs k
	--	on 1=1
	--)
	--select 
	--mv.init_x,
	--mv.init_y,
	--mv.koef_a,
	--mv.koef_b,
	--mv.y_model
	--into #power_OLS_recovery
	--from model_values mv
	--;



	/****************** коэффициенты степенной регрессии y = a * x ^ b - списания ******************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#power_OLS_wo';

	drop table if exists #power_OLS_wo;

	
	with base as (
		select 
		cast(a.mod_num as float) as init_x,
		a.wo_rate as init_y,
		log(a.mod_num) as x, 
		log(a.wo_rate) as y
		from #avg_recovery_and_wo a
	),
	stage1 as (
		select 
		cast(sum(b.x * b.y) as float) as sum_xy, 
		cast(sum(b.x) as float) as sum_x, 
		cast(sum(b.y) as float) as sum_y, 
		cast(sum(power(b.x,2)) as float) as sum_x_sq, 
		cast(power( sum(b.x), 2) as float) as sq_sum_x,
		count(*) as n
		from base b
	),
	stage2 as (
		select (s.n * s.sum_xy - s.sum_x * s.sum_y) / (s.n * s.sum_x_sq - s.sq_sum_x) as koef_a
		from stage1 s
	),
	koefs as (
		select ss.koef_a, (s.sum_y - ss.koef_a * s.sum_x) / s.n as koef_b from stage1 s
		left join stage2 ss
		on 1=1
	)
	select a.*
	into #power_OLS_wo
	from koefs a
	--,model_values as (
	--	select 
	--	bs.init_x,
	--	bs.init_y,
	--	bs.y, 
	--	bs.x, 
	--	k.koef_a, 
	--	k.koef_b, 
	--	case 
	--	when k.koef_a < 0 then exp(k.koef_b) / power(bs.init_x, -1.0 * k.koef_a)
	--	when k.koef_a >= 0 then exp(k.koef_b) * power(bs.init_x, k.koef_a)
	--	end as y_model
	--	from base bs
	--	left join koefs k
	--	on 1=1
	--)
	--select 
	--mv.init_x,
	--mv.init_y,
	--mv.koef_a,
	--mv.koef_b,
	--mv.y_model
	--into #power_OLS_wo
	--from model_values mv
	--;



	/****************** объединение факт статистики до 24 МоБ (вкл) и степенного тренда с 25 по 100 ******************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg1_lgd';


	drop table if exists #stg1_lgd;
	create table #stg1_lgd (
		mod_num int,
		recovery_rate_new float,
		wo_rate_new float
	)


	declare @i int = 1;

	while @i <= 100 begin


	with base as (	select cast(@i as float) as mod_num )
	insert into #stg1_lgd
	select a.mod_num, 
	case 
	when a.mod_num <= 24 then b.recovery_rate
	when a.mod_num between 24 and 100 then 
		case  
		 when c.koef_a < 0 then exp(c.koef_b) / power(a.mod_num, -1.0 * c.koef_a)
		 when c.koef_a >= 0 then exp(c.koef_b) * power(a.mod_num, c.koef_a)
		 end
	when a.mod_num > 100 then 1.0 
	end as recovery_rate_new,

	case 
	when a.mod_num <= 24 then b.wo_rate
	when a.mod_num between 24 and 100 then 
		case  
		 when d.koef_a < 0 then exp(d.koef_b) / power(a.mod_num, -1.0 * d.koef_a)
		 when d.koef_a >= 0 then exp(d.koef_b) * power(a.mod_num, d.koef_a)
		 end
	when a.mod_num > 100 then 1.0 
	end as wo_rate_new


	from base a
	left join #avg_recovery_and_wo b
	on a.mod_num = b.mod_num
	left join #power_OLS_recovery c
	on 1=1
	left join #power_OLS_wo d
	on 1=1
	
	set @i = @i + 1

	end;



	/****************** дисконтирование рекавери-рейтов ******************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg2_lgd';

	drop table if exists #stg2_lgd;
	create table #stg2_lgd (
		mod_num int,
		discount float,
		recovery_rate_new_disc float,
		wo_rate_new float
	);


	declare @disc float = 0.0;

	while @disc <= 15.0 begin

	insert into #stg2_lgd
	select a.mod_num, @disc as discount, 
	1.0 / power(1.0 + @disc / 100.0, cast(a.mod_num as float)/ 12.0) * a.recovery_rate_new as recovery_rate_new_disc,
	a.wo_rate_new
	from #stg1_lgd a
	;

	set @disc = round(@disc + 0.05,2)

	end;

	/*
	select a.mod_num, a.discount
	from #stg2_lgd a
	group by a.mod_num, a.discount
	having count(*)>1
	*/


	/****************** вычисление LGD ******************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg3_lgd';

	drop table if exists #stg3_lgd;
	with base as (
		select 
		a.mod_num,
		a.discount,
		a.wo_rate_new,
		a.recovery_rate_new_disc,
		isnull(sum(a.wo_rate_new) over (partition by a.discount order by a.mod_num rows between unbounded preceding and 1 preceding),0) as wo_rate_acc,
		isnull(sum(a.recovery_rate_new_disc) over (partition by a.discount order by a.mod_num rows between unbounded preceding and 1 preceding),0) as rec_rate_acc1,
		isnull(sum(a.recovery_rate_new_disc) over (partition by a.discount order by a.mod_num rows between current row and unbounded following),0) as rec_rate_acc2
		from #stg2_lgd a
	)
	select a.mod_num, a.discount,
	1.0 - a.rec_rate_acc2 / (1.0 - a.rec_rate_acc1 - a.wo_rate_acc) as LGD_WO
	into #stg3_lgd
	from base a
	;



	declare @j int = 101;

	while @j <= 500 begin

	insert into #stg3_lgd
	select @j, a.discount, 1.0 
	from #stg3_lgd a
	where a.mod_num = 1;

	set @j = @j + 1;

	end;



	/*
	select a.mod_num, a.discount
	from #stg3_lgd a
	group by a.mod_num, a.discount
	having count(*)>1
	*/


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into risk.prov2_lgd';

	begin transaction;

		delete from risk.prov2_lgd where rep_dt = @repdate and vers = @vers;

		insert into risk.prov2_lgd
	
		select 
		@repdate as rep_dt,
		@vers as vers,
		cast(getdate() as datetime) as dt_dml,
		a.mod_num, a.discount, a.LGD_WO
		from #stg3_lgd a
		;


	commit transaction;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';


end try



begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch

