CREATE   procedure [Risk].[update_ReportCBLiquidity]
as
begin
	declare @srcname varchar(100) = 'Update CB Liquidity';

	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = 'START';


	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#ref_vibor_cmr';

	

		drop table if exists #ref_vibor_cmr;


	select a.d as r_date
	,      a.external_id                                                                                                                          
	,      cast(a.ContractStartDate as date) as credit_date      
	,      (case when a.ContractEndDate is not null and a.ContractEndDate <= a.d then 1 else 0 end) as closed
	,      cast(a.Сумма as float) as amount                                                                                                                             
	,      isnull(a.dpd, 0) as overdue_days
	,      cast(isnull(a.[остаток од], 0) as float) as principal_rest	
	,      cast(isnull(a.[основной долг уплачено], 0) as float) +
		cast(isnull(a.[Проценты уплачено], 0) as float) +
		cast(isnull(a.[ПениУплачено], 0) as float) +
		cast(isnull(a.[ГосПошлинаУплачено],0) as float) +
		cast(isnull(a.[ПереплатаУплачено]*(-1), 0) as float) - 
		cast(isnull(a.[ПереплатаНачислено]*(-1), 0) as float) as pay_total
	
	,      cast(isnull(a.[основной долг уплачено], 0) as float) +
	cast(isnull(a.[ПереплатаУплачено]*(-1), 0) as float) - 
	cast(isnull(a.[ПереплатаНачислено]*(-1), 0) as float) as pay_total_PRI
		
	into #ref_vibor_cmr
	from dwh2.dbo.dm_CMRStatBalance a
	where a.d <= dateadd(dd,-1,cast(getdate() as date))
		and a.d >= cast(a.ContractStartDate as date)
		and (a.d >= eomonth(cast(getdate() as date), -3))
		--and day(cdate) = day(eomonth(cdate));

	update #ref_vibor_cmr set principal_rest = 0 where principal_rest < 0.01;
	update #ref_vibor_cmr set principal_rest = 0 where closed = 1;


	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#vibor_svb2_2';

	drop table if exists #vibor_svb2_2;

	select cdate as r_date
	,      external_id                                                                                          

	,      cast(isnull(principal_cnl, 0) as float) +
	cast(isnull(percents_cnl, 0) as float) +
	cast(isnull(fines_cnl, 0) as float) +
	cast(isnull(otherpayments_cnl,0) as float) +
	cast(isnull(overpayments_cnl, 0) as float) - 
	cast(isnull(overpayments_acc, 0) as float)
	as pay_total
	
	,	cast(isnull(principal_cnl, 0) as float) +
	cast(isnull(overpayments_cnl, 0) as float) - 
	cast(isnull(overpayments_acc, 0) as float)                      
	as pay_total_PRI
	
	into #vibor_svb2_2
	from dwh_new.dbo.stat_v_balance2
	where cdate <= dateadd(dd,-1,cast(getdate() as date))
		and cdate >= cast(credit_date as date)
		and (cdate >= eomonth( cast(getdate() as date), -3)
		);


	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#ref_vibor_cmr_daily';

	drop table if exists #ref_vibor_cmr_daily;

	select a.*                                                                      
	,      isnull(b.pay_total,a.pay_total)                                           as pay_total_mfo
	,      isnull(b.pay_total_PRI,a.pay_total_PRI)                                   as pay_total_pri_mfo

		into #ref_vibor_cmr_daily
	from      #ref_vibor_cmr a
	left join #vibor_svb2_2  b on a.external_id = b.external_id
			and a.r_date = b.r_date
	;


	drop table #vibor_svb2_2;
	drop table #ref_vibor_cmr;




	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#punkt_x';

	--Пункты 1 - 1.3 - остаток основного долга

	drop table if exists #punkt_1;

	select a.r_date                                                                  as r_week
	,      sum(isnull(a.principal_rest,0)) / 1000000.0                               as total_od_1
	,      sum(iif(a.overdue_days > 0, isnull(a.principal_rest,0), 0) ) / 1000000.0  as npl_0pls_1_1
	,      sum(iif(a.overdue_days > 30, isnull(a.principal_rest,0), 0) ) / 1000000.0 as npl_30pls_1_2
	,      sum(iif(a.overdue_days > 90, isnull(a.principal_rest,0), 0) ) / 1000000.0 as npl_90pls_1_3

		into #punkt_1
	from #ref_vibor_cmr_daily a
	where a.r_date in (
		dateadd(dd,-8,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date))),
		dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)))
		)
	group by a.r_date;

	--Пункт 7 - выдачи

	drop table if exists #punkt_7;

	select cast(dateadd(dd,6,RiskDWH.dbo.date_trunc('wk', a.credit_date )) as date) as r_week
	,      sum(cast(isnull(a.amount,0) as float)) / 1000000.0                       as amount_7
		into #punkt_7
	from (select distinct a.external_id
	,                     a.credit_date
	,                     a.amount
	from #ref_vibor_cmr_daily a) a
	where a.credit_date between dateadd(dd,-14,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date))) and dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)))
	group by cast(dateadd(dd,6,RiskDWH.dbo.date_trunc('wk', a.credit_date )) as date);


	--Пункт 11 - платежи

	drop table if exists #punkt_11;

	select cast(dateadd(dd,6,RiskDWH.dbo.date_trunc('wk', a.r_date )) as date)             as r_week
	,      sum( isnull( a.pay_total_pri_mfo,0)) / 1000000.00                               as pay_od_11_1
	,      sum( isnull( a.pay_total_mfo,0) - isnull( a.pay_total_pri_mfo,0) ) / 1000000.00 as pay_rest_11_2

		into #punkt_11
	from #ref_vibor_cmr_daily a
	where a.r_date between dateadd(dd,-14,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date))) and dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)))
	group by cast(dateadd(dd,6,RiskDWH.dbo.date_trunc('wk', a.r_date )) as date)
	;




	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#base';

	--собираем все пункты в одну таблицу

	drop table if exists #base;
	select a.r_week                             
	,      a.total_od_1                         
	,      a.npl_0pls_1_1                       
	,      a.npl_30pls_1_2                      
	,      a.npl_90pls_1_3                      
	,      b.amount_7                           
	,      c.pay_od_11_1                        
	,      c.pay_rest_11_2                      
	,      ROW_NUMBER() over (order by a.r_week) as rown
		into #base
	from      #punkt_1  a
	left join #punkt_7  b on a.r_week = b.r_week
	left join #punkt_11 c on a.r_week = c.r_week
	;


	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = 'insert into risk.dm_ReportCBLiquidity';



	begin tran

	insert into risk.dm_ReportCBLiquidity
	select cast(getdate() as datetime) as dt_dml
	,      a.r_week                   
	,      a.total_od_1               
	,      a.npl_0pls_1_1             
	,      a.npl_30pls_1_2            
	,      a.npl_90pls_1_3            
	,      a.amount_7                 
	,      a.pay_od_11_1              
	,      a.pay_rest_11_2            
	from #base a
	where not exists (select 1
		from risk.dm_ReportCBLiquidity b
		where a.r_week = b.r_week)
	;

	commit tran;



	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = '#for_html';


	--вспомогательная таблица для HTML

	drop table if exists #for_html;

	with base
	as
	(
		select a.r_week
		,      a.total_od_1
		,      a.npl_0pls_1_1
		,      a.npl_30pls_1_2
		,      a.npl_90pls_1_3
		,      a.amount_7
		,      a.pay_od_11_1
		,      a.pay_rest_11_2
		,      a.rown
		from #base a
	)
	,    un
	as
	(
		select '[1]'        as punkt
		,      a.total_od_1 as firstdate
		,      b.total_od_1 as seconddate
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[1.1]'        as punkt
		,      a.npl_0pls_1_1
		,      b.npl_0pls_1_1
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[1.2]'         as punkt
		,      a.npl_30pls_1_2
		,      b.npl_30pls_1_2
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[1.3]'         as punkt
		,      a.npl_90pls_1_3
		,      b.npl_90pls_1_3
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[7]'      as punkt
		,      a.amount_7
		,      b.amount_7
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[11.1]'      as punkt
		,      a.pay_od_11_1
		,      b.pay_od_11_1
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
		union all
		select '[11.2]'        as punkt
		,      a.pay_rest_11_2
		,      b.pay_rest_11_2
		from      base a
		left join base b on b.rown = 2
		where a.rown = 1
	)

	select *
		into #for_html
	from un
	;



	declare @body nvarchar(4000) = 'Новые значения для отчета по ликвидности<br><br><table><tr><th>Пункт</th><th>';


	set @body = concat(@body,(select format(a.r_week,'dd.MM.yyyy')
	from #base a
	where rown = 1),'</th><th>');
	set @body = concat(@body,(select format(a.r_week,'dd.MM.yyyy')
	from #base a
	where rown = 2),'</th></tr>');


	declare @tmp_html varchar(4000);

	declare cur cursor for
	select concat('<tr><td>', punkt,
	'</td><td>', replace(format(firstdate,'#######.########'),'.',',') ,
	'</td><td>', replace(format(seconddate,'#######.########'),'.',','),
	'</td></tr>') as html_table_row
	from #for_html;

	open cur

	fetch next from cur into @tmp_html

	while @@FETCH_STATUS = 0
	begin


		set @body = concat(@body, @tmp_html)

		fetch next from cur into @tmp_html

	end

	close cur
	deallocate cur


	set @body = concat(@body, '</table><br>Данные также доступны в таблице Risk.dm_ReportCBLiquidity')


	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = 'send mail';


	--Оповещение по EMAIL Цыплаков Дмитрий и Борисов Артем
	--формат письма: HTML
	--текст письма: переменная @body
	--тема письма (@subject): Отчет Ликвидность ЦБ


	-- ЗДЕСЬ СКРИПТ ОТПРАВКИ --
	declare @recipients nvarchar(255) = 'a.golicyn@carmoney.ru'
	EXEC msdb.dbo.sp_send_dbmail    
			@recipients = @recipients,  
			@body = @body,  
			@body_format='HTML', 
			@subject = 'Отчет Ликвидность ЦБ'

	exec RiskDWH.dbo.prc$set_debug_info @src  = @srcname
	,                                   @info = 'FINISH';
end
