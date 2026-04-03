 CREATE       proc  [dbo].[kpi_hr] 
as
begin



if day(GETDATE())<>1 and not exists(select * from v_Calendar where [Признак понедельник]=1 and Дата=cast(getdate() as date) )
return
	   
	--select 1 d



	declare  @report_date as date = getdate()-1



	declare  @datestart as date = cast(format( @report_date,  'yyyy-MM-01') as date)
	--declare @dateend as date = getdate()-1


	drop table if exists #t1
	--  
	--
 

	select 'Выданная сумма ПТС' Показатель,
	sum([Выданная сумма]) Значение
	into #t1
	FROM v_fa (nolock)
	WHERE cast([Заем выдан] as date) between @datestart and @report_date  and isPts=1

	union 
	select 'Займов на миллион ПТС' Показатель,
	count(Номер) Значение
 
	FROM v_fa (nolock)
	WHERE cast([Заем выдан] as date) between @datestart and @report_date  and isPts=1	 and 	 [Выданная сумма]=1000000

	union

	select 
	 'КП NET' Показатель,
	SUM([сумма дополнительных услуг carmoney net]) 'КП NET'
	FROM v_fa (nolock) -- exec select_table 'Reports.dbo.dm_Factor_Analysis_001'

	WHERE cast([Заем выдан] as date) between @datestart and @report_date and isPts=1

	union

	select 
	 'Доля КП' Показатель,
	SUM([сумма дополнительных услуг carmoney net])/sum([Выданная сумма]) 'Доля КП'
	FROM v_fa (nolock)
	WHERE cast([Заем выдан] as date) between @datestart and  @report_date  and isPts=1

	union 

	select 'План для RR ПТС' Показатель,
	sum(ptsSum) 'План ПТС'
	from sale_plan
	where date between @datestart and @report_date
																			


	union 

	select 'План месяц ИНСТ' Показатель,
	sum(bezzalogSum) 'План'
	from sale_plan
	where format(date , 'yyyy-MM-01')=@datestart
	union 

	select 'План месяц ПТС' Показатель,
	sum(ptsSum) 'План'
	from sale_plan
	where format(date , 'yyyy-MM-01')=@datestart


	union 

	select 'Выданная сумма Инст' Показатель,
	sum([Выданная сумма]) 'Выдано'
	FROM v_fa  (nolock)
	WHERE cast([Заем выдан] as date) between @datestart and @report_date  and Дубль=0  and isPts=0


	union 

	select 'План для RR Инст' Показатель,
	sum(bezzalogSum) 'План'
	from sale_plan
	where date between @datestart and @report_date

	set language russian

	declare @month nvarchar(max) = format(@datestart, 'MMMM')
	declare @millions_pts nvarchar(max) = (select top 1 format(значение, '0') from #t1 where Показатель='Займов на миллион ПТС')
	declare @plan_pts nvarchar(max) = (select top 1 format(значение/1000000.0, '0.0') from #t1 where Показатель='План месяц ПТС')
	declare @plan_inst nvarchar(max) = (select top 1 format(значение/1000000.0, '0.0') from #t1 where Показатель='План месяц Инст')
	declare @fact_pts nvarchar(max) = (select top 1 format(значение/1000000.0, '0.0') from #t1 where Показатель='Выданная сумма ПТС')
	declare @fact_inst nvarchar(max) = (select top 1 format(значение/1000000.0, '0.0') from #t1 where Показатель='Выданная сумма Инст')
	declare @since_till nvarchar(max) = format(@datestart, 'dd.MM')+' - '+ format(@report_date, 'dd.MM')
	declare @fact_perc_pts nvarchar(max) = format((select top 1 значение from #t1 where Показатель='Выданная сумма ПТС')/ (select top 1  значение  from #t1 where Показатель='План месяц ПТС') , '0%')
	declare @fact_perc_inst nvarchar(max) = format((select top 1 значение from #t1 where Показатель='Выданная сумма Инст')/ (select top 1  значение  from #t1 where Показатель='План месяц Инст'), '0%')
	declare @rr_perc_pts  nvarchar(max) = format( (select top 1 значение from #t1 where Показатель='Выданная сумма ПТС')/ ( (select top 1  значение  from #t1 where Показатель='План для RR ПТС') ) , '0%')
	declare @rr_perc_inst nvarchar(max) = format( (select top 1 значение from #t1 where Показатель='Выданная сумма ИНСТ')/ ( (select top 1  значение  from #t1 where Показатель='План для RR ИНСТ') ) , '0%')
	declare @rr_pts nvarchar(max) =   format((select top 1  значение  from #t1 where Показатель='План месяц ПТС') * (	(select top 1 значение from #t1 where Показатель='Выданная сумма ПТС')/  (select top 1  значение  from #t1 where Показатель='План для RR ПТС'))/1000000.0 , '0.0')
	declare @rr_inst nvarchar(max) =   format((select top 1  значение  from #t1 where Показатель='План месяц ИНСТ') * (	(select top 1 значение from #t1 where Показатель='Выданная сумма ИНСТ')/  (select top 1  значение  from #t1 where Показатель='План для RR ИНСТ'))/1000000.0 , '0.0')
	declare @kp_pts nvarchar(max) = format( (select top 1 значение from #t1 where Показатель='КП NET'), '# ### ###')
	declare @kp_pts_perc nvarchar(max) = format( (select top 1 значение from #t1 where Показатель='Доля КП'), '0.0%')
	declare @fact_pts_inst_float float =   isnull((select top 1 значение  from #t1 where Показатель='Выданная сумма ПТС'), 0) + isnull( (select top 1 значение  from #t1 where Показатель='Выданная сумма Инст')	, 0)
	declare @plan_pts_inst_float float =   isnull((select top 1 значение  from #t1 where Показатель='План месяц ПТС'), 0) + isnull( (select top 1 значение  from #t1 where Показатель='План месяц Инст')	, 0)
	declare @rr_pts_inst_float float = 
	(select top 1  значение  from #t1 where Показатель='План месяц ПТС') * (	(select top 1 значение from #t1 where Показатель='Выданная сумма ПТС')/  (select top 1  значение  from #t1 where Показатель='План для RR ПТС'))
	+ (select top 1  значение  from #t1 where Показатель='План месяц ИНСТ') * (	(select top 1 значение from #t1 where Показатель='Выданная сумма ИНСТ')/  (select top 1  значение  from #t1 where Показатель='План для RR ИНСТ'))
	 declare @perc_rr_pts_inst_float float = 
	 @rr_pts_inst_float /@plan_pts_inst_float
	declare @perc_plan_fact_pts_inst_float float = 
	 @fact_pts_inst_float /@plan_pts_inst_float


	 declare @new_format nvarchar(max) = (
	 select  
 
	 @since_till+'
	% выполнения - '+ format(@perc_plan_fact_pts_inst_float, '0%')+'
	 '+'% RR - '+ format(@perc_rr_pts_inst_float, '0%')+ 				   +'
	 '+'План ПТС+ИНСТ - '+ format(@plan_pts_inst_float/1000000, '0.0')  +'
	 '+'Факт ПТС+ИНСТ - '+ format(@fact_pts_inst_float/1000000, '0.0') +'
	 '+'RR ПТС+ИНСТ - '+ format(@rr_pts_inst_float/1000000, '0.0')  
	 )  



   

	declare @old_format nvarchar(max)= (
	select 'Статистика по ПТС:
	План на '+@month+' по выдачам - '+@plan_pts+' млн руб.
	Факт - '+@month+ ' '+@fact_pts+' млн руб.' +' '+@fact_perc_pts+' выполнения.
	Run Rate (RR) - '+@rr_pts+' млн. руб. ('+@rr_perc_pts+')'+
	'
	Объем комиссионных доходов за '+ @month +' , Net - '+ @kp_pts+' руб.
	Доля комиссионных продуктов, Net '+@kp_pts_perc+' от всех продаж.
	Займов на сумму 1 млн. руб - ' +@millions_pts+ '

	Статистика по Инстоллмент:
	План на '+@month+' по выдачам - '+@plan_inst+' млн руб.
	Факт - '+@fact_inst+' млн руб. за период '+@since_till+'
	RR - '+ @rr_inst	 +' млн. руб.	 ('+@rr_perc_inst  +')
	'+
	@fact_perc_inst+' выполнения.'
	)

	declare  @result  nvarchar(max) =  @new_format +'
	-------------------
	-------------------
	'+   @old_format

	--exec  log_telegram @message, default 

	--select * from #t1
	--order by 1




 
--	exec log_email 	'Результаты недели для HR' , 'p.ilin@techmoney.ru', @result 
exec log_email 	'Результаты недели для HR' , 'zvereva_n_v@carmoney.ru; ek.novikova@techmoney.ru; p.ilin@techmoney.ru', @result 




end
