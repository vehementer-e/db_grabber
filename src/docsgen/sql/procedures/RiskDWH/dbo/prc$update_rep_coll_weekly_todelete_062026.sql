CREATE procedure [dbo].[prc$update_rep_coll_weekly] 

as 

declare @srcname varchar(100) = 'Collection weekly report';

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Usual Calc';


/*КК корректируются в первый месяц*/
	--Recovery, Activation, средний чек, средний портфель
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part1 @excludecredholid = 1, @flag_kk_total = 0;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part1_2 @excludecredholid = 1, @flag_kk_total = 0;

	--Переходы по бакетам (новые бакеты: 91-360 разбит на 91-120, 121-150, 151-180, 181-360)
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part2 @excludecredholid = 1, @flag_kk_total = 0;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part2_2 @excludecredholid = 1, @flag_kk_total = 0;

	--Переходы по бакетам (стандартные бакеты: 1-30, 31-60, 61-90, 91-360, 361+)
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part3 @excludecredholid = 1, @flag_kk_total = 0;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part3_2 @excludecredholid = 1, @flag_kk_total = 0;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Full exclusion cred holid';

/*КК исключаются полностью - на все отчетные даты*/
	--Recovery, Activation, средний чек, средний портфель
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part1 @excludecredholid = 0, @flag_kk_total = 1;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part1_2 @excludecredholid = 0, @flag_kk_total = 1;

	--Переходы по бакетам (новые бакеты: 91-360 разбит на 91-120, 121-150, 151-180, 181-360)
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part2 @excludecredholid = 0, @flag_kk_total = 1;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part2_2 @excludecredholid = 0, @flag_kk_total = 1;

	--Переходы по бакетам (стандартные бакеты: 1-30, 31-60, 61-90, 91-360, 361+)
	--exec RiskDWH.dbo.prc$update_rep_coll_weekly_part3 @excludecredholid = 0, @flag_kk_total = 1;
	exec RiskDWH.dbo.prc$update_rep_coll_weekly_part3_2 @excludecredholid = 0, @flag_kk_total = 1;

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'Plans';


--Планы для сохраненного и приведенного баланса
exec RiskDWH.dbo.prc$update_rep_coll_weekly_part4;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH'