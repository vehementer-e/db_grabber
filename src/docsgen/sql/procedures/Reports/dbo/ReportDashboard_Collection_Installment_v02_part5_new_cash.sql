-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-05-22
-- Update date: 2020-12-24
-- Updated date: 2021-12-09
-- Description:	 Пятая часть. Cash и таблица 2 -- теперь и с переплатой
--             exec [dbo].[ReportDashboard_Collection_Installment_v02_part5_new_cash]   --1
--				2020-12-24 - учитываем переход 1-0 в течение дня кэш
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_Installment_v02_part5_new_cash
		
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- part 5 new cash
--22.05.2020
delete from [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
insert into [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
select * from [dbo].[dm_dashboard_Collection_Installment_v02] 

--- 28.04.2020

		--для учета КА
		drop table if exists #agent
		select *
		into #agent
		--DWH-257
		from (
			select
				agent_name = a.AgentName
				,reestr = RegistryNumber
				,external_id = d.Number
				,st_date  = cat.TransferDate
				,fact_end_date = cat.ReturnDate
				,plan_end_date = cat.PlannedReviewDate
				,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
			from Stg._collection.CollectingAgencyTransfer as cat
				inner join Stg._collection.Deals as d
					on d.Id = cat.DealId
				inner join Stg._collection.CollectorAgencies as a
					on a.Id = cat.CollectorAgencyId
		) as t

		-- для учета статуса legal
		drop table if exists #legal
		select Number, r_date 
		into #legal
		from  Stg._Collection.Deals_history dh
		--left join stg._Collection.DealStatus ds on ds.id = dh.IdStatus
		where -- Number = '19122910000093'
		dh.IdStatus = 10

		-- для учета договоров у которых была просрочка +91
		drop table if exists #dpd91plus
		select external_id
		into #dpd91plus
		from dbo.dm_CMRStatBalance_2
		where dpd >90
		group by external_id

		--select * from #legal
		--group by Number, r_date 
		--having count(*)>1



	-- Найдем все договора и их стадию
	if object_id('tempdb.dbo.#hard0_90') is not null drop table #hard0_90
	/*
	--OLD	
	select	distinct r.CMRContractNumber, cast(ccs.created as date) stageDate, CMRContractStage
	into #hard0_90
	from dwh_new.[Dialer].[ClientContractStage] ccs
	join dwh_new.staging.CRMClient_references r on r.CMRContractGUID=ccs.CMRContractGUID
	where ishistory=0
	*/
	--DWH-2442
	SELECT distinct ccs.CMRContractNumber, ccs.created as stageDate, ccs.CMRContractStage
	into #hard0_90
	from Stg._loginom.v_ClientContractStage_simple AS ccs
	where ishistory=0

	drop table if exists #ClosedAfterSB
	select hard.CMRContractNumber, hard.stageDate
	into #ClosedAfterSB
	from #hard0_90 hard
	 join #hard0_90 hard2 on  hard2.CMRContractNumber = hard.CMRContractNumber and dateadd(day, 1, hard2.stageDate) = hard.stageDate
	 where hard2.CMRContractStage = 'СБ' and hard.CMRContractStage = 'Closed'

	-- 02.07.2020 - по просьбе Савра
	--where CMRContractStage='Legal' and ishistory=0


	-- получим все поступления кэш за текущий и предыдущий месяц
	 drop table if exists #LMSD_tmp


		  select  b.[ДоговорНомер] external_id
			  , cast(датаоперации as date) Период
			  , датаоперации as d
			  , isnull([ОДОплачено],0)+isnull([ПроцентыОплачено],0)+isnull([ПениОплачено],0)+isnull([ПереплатаНачислено],0)-isnull([ПереплатаОплачено],0)  суммаплатежей
			  , ([ОДОплачено])  [основной долг уплачено]
			  , ([ПроцентыОплачено]) [Проценты уплачено]
			  , ([ПениОплачено])   [ПениУплачено]
			  , [ПереплатаНачислено] [ПереплатаНачислено]
			  , bucket = case   when b.[КоличествоПолныхДнейПросрочки] <= 0   then '(1)_0'
									when b.[КоличествоПолныхДнейПросрочки] <= 30  then '(2)_1_30'
									when b.[КоличествоПолныхДнейПросрочки] <= 60  then '(3)_31_60'
									when b.[КоличествоПолныхДнейПросрочки] <= 90  then '(4)_61_90'
									when b.[КоличествоПолныхДнейПросрочки] <= 360 then '(5)_91_360'
									when b.[КоличествоПолныхДнейПросрочки] > 360 then '(6)_361+' 
									else '(7)_other'  
								end
			
		 , h.CMRContractStage Стадия
		 , h.stageDate д1

		 , h_dayafter.CMRContractStage СтадияДень
		 , h_dayafter.stageDate д3
		 , iif(legal.Number is not null, 1,0) StatusLegal
		 , iif(dpd91.external_id is not null, 1,0) dpd91plus
		 , iif(cl_sb.CMRContractNumber is not null, 1,0) close_after_sb
		 , cl_sb.stageDate
		 into #LMSD_tmp
		
		 from   [dbo].dm_Telegram_Collection_Detail_Installment b with(nolock)	 
		 --dm_Telegram_Collection_Detail_New_Alternative b with(nolock)	  
	  left join #hard0_90 h on h.CMRContractNumber = b.ДоговорНомер and h.stageDate = cast(b.ДатаОперации as date)	 
	  left join #hard0_90 h_dayafter on h_dayafter.CMRContractNumber = b.ДоговорНомер and dateadd(day,1, h_dayafter.stageDate) = cast(b.ДатаОперации as date)
	  left join #legal legal on legal.Number = b.ДоговорНомер and cast(b.ДатаОперации as date) = legal.r_date
	  left join #dpd91plus dpd91 on dpd91.external_id = b.ДоговорНомер
	  left join #ClosedAfterSB cl_sb on cl_sb.CMRContractNumber = b.ДоговорНомер and cl_sb.stageDate = cast(b.ДатаОперации as date)
	  	where b.датаоперации>=cast(dateadd(month,-1,dateadd(day,-1,getdate())) as date)   -->=cast(dateadd(month,-1, @dt_begin_of_month) as date)  

		--  расчитаем хард0-90
		drop table if exists #LMSD
		select * 
		, dpd_bucket = 		case when hard0_90 >0 then 'hard_0_90' else  bucket end
		into #LMSD
		from 
		(
		select hard0_90 = case 
		when Стадия = 'Hard' and bucket in ('(2)_1_30','(3)_31_60','(4)_61_90') then 1 
		when Стадия = 'Legal' and bucket in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90') then 2 
		when Стадия = 'СБ' and bucket in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90') and (StatusLegal = 1) and dpd91plus = 1  then 4 
		when (Стадия = 'Closed' and bucket in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')  and (StatusLegal = 1) and dpd91plus = 1 and  close_after_sb = 1   and (СтадияДень = 'СБ'))	then 5 
		when agent.agent_name is not null and bucket in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90') then 3 
		else 0
		end
		, l.*
		, agent.agent_name KA		
		from #LMSD_tmp l
		left join #agent agent on l.external_id = agent.external_id and l.d between agent.st_date and agent.end_date
		) a



	if object_id('tempdb.dbo.#LMSD_report') is not null drop table #LMSD_report
	CREATE TABLE #LMSD_report(
		[суммаплатежей] [numeric](38, 2) NULL,
		[Сумма] [numeric](38, 2) NULL,
		[основной долг уплачено] [numeric](38, 2) NULL,
		[Проценты уплачено] [numeric](38, 2) NULL,
		[ПениУплачено] [numeric](38, 2) NULL,
		[Период] [date] NULL,
		[dpd_bucket] [varchar](10)  NULL,
		[seg] [nvarchar](5)  NULL
	) ON [PRIMARY]


	insert into #LMSD_report
	SELECT Sum(суммаплатежей) суммаплатежей	, sum(isnull(b.[основной долг уплачено],0)) + sum(isnull(b.[Проценты уплачено],0)) +sum(isnull(b.[ПениУплачено],0)) Сумма,  sum(b.[основной долг уплачено])  [основной долг уплачено]
		, sum(b.[Проценты уплачено])  [Проценты уплачено]
		, sum(b.[ПениУплачено]) [ПениУплачено], Период,  dpd_bucket 
		, seg = N'LMSD'
	from #LMSD b
	where d=cast(dateadd(month,-1,dateadd(day,-1,getdate())) as date) 
	group by  Период,d,  dpd_bucket
	
	union all

	SELECT Sum(суммаплатежей) суммаплатежей	, sum(isnull(b.[основной долг уплачено],0)) + sum(isnull(b.[Проценты уплачено],0)) +sum(isnull(b.[ПениУплачено],0)) Сумма,  sum(b.[основной долг уплачено])  [основной долг уплачено]
		, sum(b.[Проценты уплачено])  [Проценты уплачено]
		, sum(b.[ПениУплачено]) [ПениУплачено], Период,  dpd_bucket 
		, seg = N'CM'
	from #LMSD b
	where d=cast(dateadd(month,0,dateadd(day,-1,getdate())) as date) 
	group by  Период,d,  dpd_bucket
		
	union all

	SELECT Sum(суммаплатежей) суммаплатежей	, sum(isnull(b.[основной долг уплачено],0)) + sum(isnull(b.[Проценты уплачено],0)) +sum(isnull(b.[ПениУплачено],0)) Сумма,  sum(b.[основной долг уплачено])  [основной долг уплачено]
		, sum(b.[Проценты уплачено])  [Проценты уплачено]
		, sum(b.[ПениУплачено]) [ПениУплачено], Период,  dpd_bucket 
		, seg = N'TODAY'
	from #LMSD b
	where d=cast(dateadd(month,0,dateadd(day,0,getdate())) as date) 
	group by  Период,d,  dpd_bucket

	---------------------------------------
--- обновим данные во второй таблице
--- Таблица 2
---------------------------------------
Declare @summa numeric (15,2) 

--begin

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'LMSD' and dpd_bucket =N'(2)_1_30'),0)
--select @summa
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET [t2_1_1] =  @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'CM' and dpd_bucket =N'(2)_1_30'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_1_2] =  @summa where id = 1 	

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'TODAY' and dpd_bucket =N'(2)_1_30'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_1_3] =  @summa where id = 1 	
--------------

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'LMSD' and dpd_bucket =N'(3)_31_60'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_2_1] =  @summa where id = 1 	

Set @summa =isnull((select max(суммаплатежей) from #LMSD_report   where seg=N'CM' and dpd_bucket =N'(3)_31_60'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_2_2] = @summa where id = 1 

Set @summa =isnull((select max(суммаплатежей) from #LMSD_report   where seg=N'TODAY' and dpd_bucket =N'(3)_31_60'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_2_3] = @summa where id = 1 

--select (суммаплатежей) from #LMSD_report   where seg=N'TODAY' and dpd_bucket =N'(3)_31_60'
-------------------

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'LMSD' and dpd_bucket =N'(4)_61_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3_1] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'CM' and dpd_bucket =N'(4)_61_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3_2] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'TODAY' and dpd_bucket =N'(4)_61_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3_3] = @summa where id = 1 
-----------------------

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'LMSD' and dpd_bucket =N'hard_0_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3a_1] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'CM' and dpd_bucket =N'hard_0_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3a_2] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report  where seg=N'TODAY' and dpd_bucket =N'hard_0_90'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_3a_3] = @summa where id = 1 
-----------------------


Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'LMSD' and dpd_bucket =N'(5)_91_360'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_4_1] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'CM' and dpd_bucket =N'(5)_91_360'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_4_2] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'TODAY' and dpd_bucket =N'(5)_91_360'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_4_3] = @summa where id = 1 
----------------------------------

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'LMSD' and dpd_bucket =N'(6)_361+'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_5_1] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'CM' and dpd_bucket =N'(6)_361+'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_5_2] = @summa where id = 1 

Set @summa = isnull((select max(суммаплатежей) from #LMSD_report where seg=N'TODAY' and dpd_bucket =N'(6)_361+'),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_5_3] = @summa where id = 1 
-------------------------


-- сборы таблицы 2
--1-90
Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'LMSD' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90')),0) --OR dpd_bucket =N'hard_0_90'
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_6_1] = @summa where id = 1 

Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'CM' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90')),0) -- OR dpd_bucket =N'hard_0_90')
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_6_2] = @summa where id = 1 

Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'TODAY' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90')),0) --OR dpd_bucket =N'hard_0_90'
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_6_3] = @summa where id = 1 
---------------------
--91+
Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'LMSD' and (dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+' )),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_7_1] = @summa where id = 1 

Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'CM' and (dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+' )),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_7_2] = @summa where id = 1 

Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'TODAY' and (dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+' )),0)
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_7_3] = @summa where id = 1 
-----------------------

--1+
Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'LMSD' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90' OR dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+'  OR dpd_bucket =N'hard_0_90')),0) ---
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_8_1] = @summa where id = 1 

--declare @summa numeric (15,2) 
Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'CM' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90' OR dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+' OR dpd_bucket =N'hard_0_90')),0) -- 
--Select @summa
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_8_2] = @summa where id = 1 

--declare @summa numeric (15,2) 
Set @summa = isnull((select sum(суммаплатежей) from #LMSD_report where seg=N'TODAY' and (dpd_bucket =N'(2)_1_30' OR dpd_bucket =N'(3)_31_60' OR dpd_bucket =N'(4)_61_90' OR dpd_bucket =N'(5)_91_360' OR dpd_bucket =N'(6)_361+' OR dpd_bucket =N'hard_0_90')),0) --
--Select @summa
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] 
SET  [t2_8_3] = @summa where id = 1 


-- перепишем, так как имеем выше все данные--
-- 29042020
--- ========= День =================================


-- 90-360 - за день 
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] SET  [t1_4_2_fact_to_day] = [t2_4_3] where id = 1 
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] SET  [t1_4_3_fact_to_day_percent] = case when isnull([t1_4_1_plan_to_day],0)<> 0 then [t1_4_2_fact_to_day]/[t1_4_1_plan_to_day] else 0 end where id = 1
---- 361+ -за день
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] SET  [t1_5_2_fact_to_day] = [t2_5_3] where id = 1 
update [dbo].[dm_dashboard_Collection_Installment_v02_new_cash] SET  [t1_5_3_fact_to_day_percent] = case when isnull([t1_5_1_plan_to_day],0)<>0 then  [t1_5_2_fact_to_day]/[t1_5_1_plan_to_day] else 0 end where id = 1

END
