  
 
 CREATE PROCEDURE [collection].[create_inner_legal] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try


 
	




drop table if exists #base_kk;

select
			number
into #base_kk
	from
			dbo.dm_restructurings --devdb.dbo.say_log_peredachi_kk
	group by
			number;
   /*with
	base_kk as
	(
	select
			number
	from
			dbo.dm_restructurings --devdb.dbo.say_log_peredachi_kk
	group by
			number
	)
	,*/


drop table if exists #base_problem_client;
	select
			customerId , 'Exeptation'= t2.Name
into #base_problem_client

	from 
			[Stg].[_Collection].[CustomerStatus] t1
			join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
	where 1=1
			and t1.[IsActive] = 1 
			and t2.[Name] in ('Смерть подтвержденная',
							'Банкрот подтверждённый',
						
							'Банкрот неподтверждённый',
							'Банкротство завершено',
							'HardFraud',
							'Мобилизован')
	group by 
			customerId, t2.Name;

	/*base_problem_client as
	(
	select
			customerId
	from 
			[Stg].[_Collection].[CustomerStatus] t1
			join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
	where 1=1
			and t1.[IsActive] = 1 
			and t2.[Name] in ('Смерть подтвержденная',
							'Банкрот подтверждённый',
							'Fraud подтвержденный')
	group by 
			customerId
	)
	,*/




drop table if exists #Judicial_Proceeding;
select *
into #Judicial_Proceeding
	from
	(
		select distinct
				DealId
				,number
				,jp.id
				,amountclaim
				,cast(coalesce(SubmissionClaimDate,null) as date) dt_max_submission_claim ---jp.createdate заменил на null
				,ROW_NUMBER() over (partition by DealId order by SubmissionClaimDate desc) rn
		from stg._Collection.JudicialProceeding		jp
		join stg._Collection.deals					d on d.id = jp.DealId
		where 1 = 1
				and isfake != 1
	)aa
	where rn = 1;

	/*Judicial_Proceeding as
	(
	select *
	from
	(
		select distinct
				DealId
				,number
				,jp.id
				,amountclaim
				,cast(coalesce(SubmissionClaimDate,jp.createdate) as date) dt_max_submission_claim
				,ROW_NUMBER() over (partition by DealId order by SubmissionClaimDate desc) rn
		from stg._Collection.JudicialProceeding		jp
		join stg._Collection.deals					d on d.id = jp.DealId
		where 1 = 1
				and isfake != 1
	)aa
	where rn = 1
	)
	,*/




drop table if exists #Judicial_Claims;

select id
			,cast(CourtClaimSendingDate as date) dt_Court_Claim_Sending
			,JudicialProceedingId
			,PrincipalDebtOnClaim
			,PercentageOnClaim
			,PenaltiesOnClaim
			,StateDutyOnClaim
			,AmountRequirements
			,PrincipalDebtOnJudgment
			,PercentageOnJudgment
			,PenaltiesOnJudgment
			,StateDutyOnJudgment
			,AmountJudgment
into #Judicial_Claims
	from Stg._Collection.JudicialClaims	jc;


	/*Judicial_Claims as
	(
	select id
			,cast(CourtClaimSendingDate as date) dt_Court_Claim_Sending
			,JudicialProceedingId
			,PrincipalDebtOnClaim
			,PercentageOnClaim
			,PenaltiesOnClaim
			,StateDutyOnClaim
			,AmountRequirements
			,PrincipalDebtOnJudgment
			,PercentageOnJudgment
			,PenaltiesOnJudgment
			,StateDutyOnJudgment
			,AmountJudgment
	from Stg._Collection.JudicialClaims			jc
	)
	,*/

drop table if exists #base_judgment;



select 
			number
			,JudgmentDate dt_judgment
into #base_judgment
	from
	(
	select 
			d.number
			,cast(jc.JudgmentDate as date) JudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.JudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.JudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1;



	/*base_judgment as
	(
	select 
			number
			,JudgmentDate dt_judgment
	from
	(
	select 
			d.number
			,cast(jc.JudgmentDate as date) JudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.JudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.JudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1
	)
	,*/

drop table if exists #base_receipt_judgmen;

select 
			number
			,ReceiptOfJudgmentDate dt_receipt_judgment
into #base_receipt_judgmen
	from
	(
	select 
			d.number
			,cast(jc.ReceiptOfJudgmentDate as date) ReceiptOfJudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.ReceiptOfJudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ReceiptOfJudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1;




	/*base_receipt_judgmen as
	(
	select 
			number
			,ReceiptOfJudgmentDate dt_receipt_judgment
	from
	(
	select 
			d.number
			,cast(jc.ReceiptOfJudgmentDate as date) ReceiptOfJudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.ReceiptOfJudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ReceiptOfJudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1
	)
	,*/


drop table if exists #Enforcement_Orders;

select DealId
			,id id_IL
			,dt_Receipt_IL
			,amount sum_IL
			,[Дата возбуждения ИП]--добавил поле запрос Николаевой
			,[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
			
into #Enforcement_Orders
	from
	(
		select eo.id
				,jp.DealId
				,eo.amount
				,cast(eo.ReceiptDate as date) dt_Receipt_IL
				,ROW_NUMBER() over (partition by jp.DealId order by eo.ReceiptDate desc) rn
				,cast(epe.ExcitationDate as  date) 'Дата возбуждения ИП' --добавил поле запрос Николаевой
			    ,case when epe.ExcitationDate is not null then 1 else 0 end 'Флаг Дата возбуждения ИП' --добавил поле запрос Николаевой
		from Stg._Collection.EnforcementOrders			eo
		join  Stg._Collection.JudicialClaims			jc on jc.id = eo.JudicialClaimId
		join Stg._Collection.JudicialProceeding			jp on jp.Id = jc.JudicialProceedingId
		left join Stg._Collection.EnforcementProceeding AS							ep ON eo.Id = ep.EnforcementOrderId --добавил поле запрос Николаевой
		LEFT OUTER JOIN  Stg._Collection.EnforcementProceedingExcitation as					epe on epe.EnforcementProceedingId = ep.Id --добавил поле запрос Николаевой
		where eo.[Type] != 1
	)aa
	where rn = 1;


	/*Enforcement_Orders as
	(
	select DealId
			,id id_IL
			,dt_Receipt_IL
			,amount sum_IL
	from
	(
		select eo.id
				,jp.DealId
				,eo.amount
				,cast(eo.ReceiptDate as date) dt_Receipt_IL
				,ROW_NUMBER() over (partition by jp.DealId order by eo.ReceiptDate desc) rn
		from Stg._Collection.EnforcementOrders			eo
		join  Stg._Collection.JudicialClaims			jc on jc.id = eo.JudicialClaimId
		join Stg._Collection.JudicialProceeding			jp on jp.Id = jc.JudicialProceedingId
		where eo.[Type] != 1
	)aa
	where rn = 1
	)
	,*/


drop table if exists #base_dt_jp;

select
			jp.number
			,jp.dt_max_submission_claim
			,case when jc.dt_Court_Claim_Sending is not null 
				  then jc.dt_Court_Claim_Sending
				  when bjm.dt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,bjm.dt_judgment) / 2),jp.dt_max_submission_claim)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / 3),jp.dt_max_submission_claim)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / 4),jp.dt_max_submission_claim)
				  end dt_Court_Claim_Sending
			,case when bjm.dt_judgment is not null 
				  then bjm.dt_judgment
				  when brjm.dt_receipt_judgment is not null and jc.dt_Court_Claim_Sending is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,brjm.dt_receipt_judgment) / 2),jc.dt_Court_Claim_Sending)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / (3 / 2)),jp.dt_max_submission_claim)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / 3),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 2)),jp.dt_max_submission_claim)
				  end dt_max_judgment
			,case when brjm.dt_receipt_judgment is not null 
				  then brjm.dt_receipt_judgment
				  when bjm.dt_judgment is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,bjm.dt_judgment,eo.dt_Receipt_IL) / 2),bjm.dt_judgment)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / (3 / 2)),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 3)),jp.dt_max_submission_claim)
				  end dt_max_receipt_judgment
			,eo.dt_Receipt_IL dt_max_Receipt_IL
			,eo.[Дата возбуждения ИП]--добавил поле запрос Николаевой
			,eo.[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
into #base_dt_jp
	from
			#Judicial_Proceeding							jp
			left join #Judicial_Claims					jc on jc.JudicialProceedingId = jp.id
			left join #base_judgment						bjm on bjm.Number = jp.Number
			left join #base_receipt_judgmen				brjm on brjm.Number = jp.Number
			left join #Enforcement_Orders				eo on eo.DealId = jp.DealId
	


;


	

drop table if exists #type_product;

select 	 external_id,
			[Тип Продукта]
			--[сумма поступлений]--=sum([сумма поступлений])
into #type_product
 from dbo.dm_cmrstatbalance
 	--where  [Тип Продукта]---<>'Инстоллмент' --убрал инстолмент
	group by external_id,
		[Тип Продукта] 

/*
drop table if exists #StrategyActionTask;

select  t.CustomerId,	
        t.DealId,
		t2.[Description]


into #StrategyActionTask
from [C2-VSR-CL-SQL].[collection_night00].dbo.TaskActionsView t

left join [C2-VSR-CL-SQL].[collection_night00].dbo.StrategyActionTask t2 on t2.id=t.strategyactiontaskid
where strategyactiontaskid in (10,13)

*/

--расчет данных  до иска 
drop table if exists #StrategyActionTask_rn_pause_isk_rn;
select  t.CustomerId,	
        t.DealId,
		t2.[Description]
		,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn
		,t.Employeeid
		,concat(e.LastName, ' ', e.FirstName, ' ', e.MiddleName) [Фио сотрудника ИСК]
		,t.DateSettingsTask [ActualDateOfDecision]--ActualDateOfDecision сминил на дату создания по метологии из письма Николаевой О

into #StrategyActionTask_rn_pause_isk_rn
from Stg._Collection.TaskActionsView t

left join Stg._Collection.StrategyActionTask t2 on t2.id=t.strategyactiontaskid
left join stg._Collection.Employee e on e.id=t.employeeid
where strategyactiontaskid in (47) and t.DateSettingsTask > '2024-04-01' --and  DealId in('98357','14887','35968','30797')  заменил strategyactiontaskid 47 на 4 (ожидание)так как очередь обновили с 03.04.2024 , расчет начинаем с этой даты



drop table if exists #StrategyActionTask_rn_pause_isk;
select CustomerId,DealId, ActualDateOfDecision [ActualDateOfDecision_pause_isk]
into #StrategyActionTask_rn_pause_isk
from #StrategyActionTask_rn_pause_isk_rn
where rn=1
;







drop table if exists #StrategyActionTask_rn;--для исключения дублей

select  t.CustomerId,	
        t.DealId,
		t2.[Description]
		,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn
		,concat(e.LastName, ' ', e.FirstName, ' ', e.MiddleName) [Фио сотрудника]
		,t.ActualDateOfDecision

into #StrategyActionTask_rn
from Stg._Collection.TaskActionsView t

left join Stg._Collection.StrategyActionTask t2 on t2.id=t.strategyactiontaskid
left join stg._Collection.Employee e on e.id=t.employeeid--добавил данные по сотрудников для расчета премирования
where strategyactiontaskid in (10,13)



drop table if exists #StrategyActionTask_isk_10_13;--для исключения дублей

select  CustomerId,	
        DealId,
		[Description]
	,[Фио сотрудника]
		--,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn
		,ActualDateOfDecision

into #StrategyActionTask_isk_10_13
from #StrategyActionTask_rn
where rn=1




/*

---таблица для расчета получения решения мотивация сотрудников с 1 марта 
drop table if exists #StrategyActionTask_isk_10_13_from_1_mart;
select CustomerId,	
        DealId,
		[Description]
	,[Фио сотрудника] [Фио сотрудника отправившего иск с 1 марта]
		
		,cast(ActualDateOfDecision as date)[Дата отправки иска с 1 марта]
into #StrategyActionTask_isk_10_13_from_1_mart
from #StrategyActionTask_isk_10_13
where cast(ActualDateOfDecision as date) >='2024-03-01'

*/






---таблица для расчета получения решения мотивация сотрудников с 1 марта 
drop table if exists #StrategyActionTask_isk_10_13_from_1_mart_first;
select CustomerId,	
        DealId,
		[Description]
	--,[Фио сотрудника] [Фио сотрудника отправившего иск с 1 марта] --замена сотрудника из задачи 17
		
		,cast(ActualDateOfDecision as date)[Дата отправки иска с 1 марта]
into #StrategyActionTask_isk_10_13_from_1_mart_first
from #StrategyActionTask_isk_10_13
where cast(ActualDateOfDecision as date) >='2024-03-01'



--данные из задачи 17  для вынесения решения суда, вытыскиваю сотрудника 
drop table if exists #StrategyActionTask_isk_10_13_task_17;
select rn.DealId
,concat(e.LastName, ' ', e.FirstName, ' ', e.MiddleName) [Фио сотрудника осуществляющий мониторинг дела в суде]
into #StrategyActionTask_isk_10_13_task_17
from 
(

select DealId
,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn 
,CustomerId
,EmployeeId




from Stg._Collection.TaskActionsView t


where strategyactiontaskid in (17) and DateSettingsTask >='2024-03-01' 

) rn
left join stg._Collection.Employee e on e.id=rn.employeeid
where rn.rn=1

------присоединяю сотрудников из задачи 17 мониторинг для решения суда
drop table if exists #StrategyActionTask_isk_10_13_from_1_mart
  select
  m.CustomerId,	
       m.DealId,
		m.[Description],
  
   task_17.[Фио сотрудника осуществляющий мониторинг дела в суде] [Фио сотрудника отправившего иск с 1 марта] --сотрудник из задачи 17 название поля оставил прежним чтобы не менять назввние в целевом источнике
   ,m.[Дата отправки иска с 1 марта]
   into #StrategyActionTask_isk_10_13_from_1_mart
from #StrategyActionTask_isk_10_13_from_1_mart_first m 
left join #StrategyActionTask_isk_10_13_task_17  task_17 on m.DealId=task_17.DealId
  





















drop table if exists #StrategyActionTask_il_rn;--для исключения дублей

select  t.CustomerId,	
        t.DealId,
		t2.[Description]
		,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn
		,concat(e.LastName, ' ', e.FirstName, ' ', e.MiddleName) [Фио сотрудника]
		,t.ActualDateOfDecision

into #StrategyActionTask_il_rn
from Stg._Collection.TaskActionsView t

left join Stg._Collection.StrategyActionTask t2 on t2.id=t.strategyactiontaskid
left join stg._Collection.Employee e on e.id=t.employeeid--добавил данные по сотрудников для расчета премирования
where strategyactiontaskid in (22)



drop table if exists #StrategyActionTask_take_il_22;--для исключения дублей

select  CustomerId,	
        DealId,
		[Description]
	,[Фио сотрудника] [Фио сотрудника ИЛ]
		--,ROW_NUMBER() over (partition by t.DealId order by ActualDateOfDecision desc) rn
		,ActualDateOfDecision

into #StrategyActionTask_take_il_22
from #StrategyActionTask_il_rn
where rn=1 and ActualDateOfDecision>'2024-03-01'







drop table if exists #StrategyActionTask_isk;

select 

isk.CustomerId,	isk.DealId,	
t.[Description],	
t.[Фио сотрудника],	
cast(t.ActualDateOfDecision as date)[Дата отправки иска] , 
cast(isk.ActualDateOfDecision_pause_isk as date) [Дата паузы отправки иска]
----il.[Фио сотрудника] [Фио сотрудника ИЛ] убрал сотрудников ил чтобы посчитать их с 1 марта 


into #StrategyActionTask_isk
--, case when (cast(ActualDateOfDecision as datetime) - cast (ActualDateOfDecision_pause_isk as datetime )) <=35  then 'timing' else 'notiming' end [kpi for isk 35]
--, case when (cast(ActualDateOfDecision as datetime) - cast (ActualDateOfDecision_pause_isk as datetime )) <=70 then 'timing' else 'notiming' end [kpi for isk 70]
from #StrategyActionTask_rn_pause_isk isk 


left join #StrategyActionTask_isk_10_13 t on t.DealId=isk.DealId

--left join #StrategyActionTask_take_il_22 il on il.DealId=isk.DealId  убрал сотрудников ил чтобы посчитать их с 1 марта 
where cast(t.ActualDateOfDecision as date)>cast(isk.ActualDateOfDecision_pause_isk as date) --добавил условие для нового расчета отправка иска меньше даты паузы
--завершение расчета данных  до иска и получения ил



	/*base_dt_jp as
	(
	select
			jp.number
			,jp.dt_max_submission_claim
			,case when jc.dt_Court_Claim_Sending is not null 
				  then jc.dt_Court_Claim_Sending
				  when bjm.dt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,bjm.dt_judgment) / 2),jp.dt_max_submission_claim)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / 3),jp.dt_max_submission_claim)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / 4),jp.dt_max_submission_claim)
				  end dt_Court_Claim_Sending
			,case when bjm.dt_judgment is not null 
				  then bjm.dt_judgment
				  when brjm.dt_receipt_judgment is not null and jc.dt_Court_Claim_Sending is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,brjm.dt_receipt_judgment) / 2),jc.dt_Court_Claim_Sending)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / (3 / 2)),jp.dt_max_submission_claim)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / 3),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 2)),jp.dt_max_submission_claim)
				  end dt_max_judgment
			,case when brjm.dt_receipt_judgment is not null 
				  then brjm.dt_receipt_judgment
				  when bjm.dt_judgment is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,bjm.dt_judgment,eo.dt_Receipt_IL) / 2),bjm.dt_judgment)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / (3 / 2)),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 3)),jp.dt_max_submission_claim)
				  end dt_max_receipt_judgment
			,eo.dt_Receipt_IL dt_max_Receipt_IL
	from
			Judicial_Proceeding							jp
			left join Judicial_Claims					jc on jc.JudicialProceedingId = jp.id
			left join base_judgment						bjm on bjm.Number = jp.Number
			left join base_receipt_judgmen				brjm on brjm.Number = jp.Number
			left join Enforcement_Orders				eo on eo.DealId = jp.DealId
	)*/


	

drop table if exists #Final_table;

	select distinct --убираю дубли
			cast(getdate() as smalldatetime) 'Дата_время формирования реестра'
			,d.number 'Договор'
			,collection.customer_fio(d.IdCustomer) 'Клиент'
			,d.OverdueDays 'Срок просрочки'
			,collection.bucket_dpd(d.OverdueDays) 'Бакет просрочки'
			,cs.name 'Стадия коллектинга договора'
			,bdjp.dt_max_submission_claim 'Дата отправки последнего требования'
			,bdjp.dt_Court_Claim_Sending 'Дата отправки в суд поледнего иска'
			,bdjp.dt_max_judgment 'Дата вынесения последнего решения'
			,bdjp.dt_max_receipt_judgment 'Дата получения последнего решения'
			,bdjp.dt_max_Receipt_IL 'Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")'
			,case when bdjp.dt_max_submission_claim is not null then 1 else 0 end 'Флаг отправки последнего требования'
			,case when bdjp.dt_Court_Claim_Sending  is not null then 1 else 0 end 'Флаг отправки в суд поледнего иска'
			,case when bdjp.dt_max_judgment  is not null then 1 else 0 end 'Флаг вынесения последнего решения'
			,case when bdjp.dt_max_receipt_judgment is not null then 1 else 0 end 'Флаг получения последнего решения'
			,case when bdjp.dt_max_Receipt_IL is not null then 1 else 0 end 'Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")'
			,bdjp.[Дата возбуждения ИП]--добавил поле запрос Николаевой
			,bdjp.[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
			,t_p.[Тип Продукта] --добавил тип продукта
			,strt.[Description] -- способ подачи иска
			,strt.[Фио сотрудника]
			,strt.[Дата отправки иска]
			,strt.[Дата паузы отправки иска]
			,IL_mart.[Фио сотрудника ИЛ]
			,mart.[Дата отправки иска с 1 марта]
			,mart.[Фио сотрудника отправившего иск с 1 марта]

    into #Final_table
	from
			stg._collection.Deals									d
			join stg._Collection.collectingStage					cs on cs.id = d.StageId
			left join #base_kk										bkk on bkk.number = d.Number
			left join #base_problem_client							bpc on bpc.customerId = d.IdCustomer
			left join #base_dt_jp									bdjp on bdjp.Number = d.Number
			left join #type_product                                 t_p  on t_p.external_id=d.Number
			left join #StrategyActionTask_isk                           strt on d.id = strt.DealId
			left join #StrategyActionTask_isk_10_13_from_1_mart     mart on  mart.DealId =d.id
			left join #StrategyActionTask_take_il_22                IL_mart on IL_mart.DealId =d.id  and bdjp.dt_max_judgment<bdjp.dt_max_Receipt_IL and bdjp.dt_max_judgment >'2024-03-01'
	where 1=1
			and d.OverdueDays >= 61  ---сменил 91
			and d.StageId not in (9,14)
			and (case when bkk.number is not null
					  then 0
					  when coalesce(d.Probation,0) = 1
					  then 0
					  when bpc.customerId is not null
					  then 0
					  else 1 end) = 1;






drop table if exists #Final_table_exeptation;

select distinct --убираю дубли
			cast(getdate() as smalldatetime) 'Дата_время формирования реестра'
			,d.number 'Договор'
			,collection.customer_fio(d.IdCustomer) 'Клиент'
			,d.OverdueDays 'Срок просрочки'
			,collection.bucket_dpd(d.OverdueDays) 'Бакет просрочки'
			,cs.name 'Стадия коллектинга договора'
			,bdjp.dt_max_submission_claim 'Дата отправки последнего требования'
			,bdjp.dt_Court_Claim_Sending 'Дата отправки в суд поледнего иска'
			,bdjp.dt_max_judgment 'Дата вынесения последнего решения'
			,bdjp.dt_max_receipt_judgment 'Дата получения последнего решения'
			,bdjp.dt_max_Receipt_IL 'Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")'
			,case when bdjp.dt_max_submission_claim is not null then 1 else 0 end 'Флаг отправки последнего требования'
			,case when bdjp.dt_Court_Claim_Sending  is not null then 1 else 0 end 'Флаг отправки в суд поледнего иска'
			,case when bdjp.dt_max_judgment  is not null then 1 else 0 end 'Флаг вынесения последнего решения'
			,case when bdjp.dt_max_receipt_judgment is not null then 1 else 0 end 'Флаг получения последнего решения'
			,case when bdjp.dt_max_Receipt_IL is not null then 1 else 0 end 'Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")'
			,bdjp.[Дата возбуждения ИП]--добавил поле запрос Николаевой
			,bdjp.[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
			,t_p.[Тип Продукта] --добавил тип продукта
			,bpc.Exeptation
    into #Final_table_exeptation
	from
			stg._collection.Deals									d
			join stg._Collection.collectingStage					cs on cs.id = d.StageId
			left join #base_kk										bkk on bkk.number = d.Number
			join #base_problem_client							bpc on bpc.customerId = d.IdCustomer
			left join #base_dt_jp									bdjp on bdjp.Number = d.Number
			left join #type_product                                 t_p  on t_p.external_id=d.Number
	where 1=1
			and d.OverdueDays >= 61  ---сменил 91
			and d.StageId not in (9,14)
			and (case when bkk.number is not null
					  then 0
					  when coalesce(d.Probation,0) = 1
					  then 0
					  when bpc.customerId is not null
					  then 0
					  else 1 end) = 0;









begin transaction 

    delete from [collection].[inner_legal];
	insert [collection].[inner_legal] (


	[Дата_время формирования реестра]
      ,[Договор]
      ,[Клиент]
      ,[Срок просрочки]
      ,[Бакет просрочки]
      ,[Стадия коллектинга договора]
      ,[Дата отправки последнего требования]
      ,[Дата отправки в суд поледнего иска]
      ,[Дата вынесения последнего решения]
      ,[Дата получения последнего решения]
      ,[Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
      ,[Флаг отправки последнего требования]
      ,[Флаг отправки в суд поледнего иска]
      ,[Флаг вынесения последнего решения]
      ,[Флаг получения последнего решения]
      ,[Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
	  ,[Дата возбуждения ИП]--добавил поле запрос Николаевой
      ,[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
	  ,[Тип Продукта] --добавил тип продукта
	  ,[Description] --способ подачи иска
	  ,[Фио сотрудника]
	  ,[Дата отправки иска]
	  ,[Дата паузы отправки иска]
	  ,[Фио сотрудника ИЛ]
	  ,[Дата отправки иска с 1 марта]
	  ,[Фио сотрудника отправившего иск с 1 марта]

	  )




	  select 
      [Дата_время формирования реестра]
      ,[Договор]
      ,[Клиент]
      ,[Срок просрочки]
      ,[Бакет просрочки]
      ,[Стадия коллектинга договора]
      ,[Дата отправки последнего требования]
      ,[Дата отправки в суд поледнего иска]
      ,[Дата вынесения последнего решения]
      ,[Дата получения последнего решения]
      ,[Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
      ,[Флаг отправки последнего требования]
      ,[Флаг отправки в суд поледнего иска]
      ,[Флаг вынесения последнего решения]
      ,[Флаг получения последнего решения]
      ,[Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
	  ,[Дата возбуждения ИП]--добавил поле запрос Николаевой
      ,[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
	  ,[Тип Продукта] --добавил тип продукта
	  ,[Description] --способ подачи иска
	  ,[Фио сотрудника]
	  ,[Дата отправки иска]
	  ,[Дата паузы отправки иска]
	  ,[Фио сотрудника ИЛ]
	  ,[Дата отправки иска с 1 марта]
	  ,[Фио сотрудника отправившего иск с 1 марта]
 from #Final_table






  delete from [collection].[report_inner_legal_exeptation];
	insert [collection].[report_inner_legal_exeptation] (


	[Дата_время формирования реестра]
      ,[Договор]
      ,[Клиент]
      ,[Срок просрочки]
      ,[Бакет просрочки]
      ,[Стадия коллектинга договора]
      ,[Дата отправки последнего требования]
      ,[Дата отправки в суд поледнего иска]
      ,[Дата вынесения последнего решения]
      ,[Дата получения последнего решения]
      ,[Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
      ,[Флаг отправки последнего требования]
      ,[Флаг отправки в суд поледнего иска]
      ,[Флаг вынесения последнего решения]
      ,[Флаг получения последнего решения]
      ,[Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
	  ,[Дата возбуждения ИП]--добавил поле запрос Николаевой
      ,[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
	  ,[Тип Продукта] --добавил тип продукта
	  ,Exeptation

	  )




	  select 
      [Дата_время формирования реестра]
      ,[Договор]
      ,[Клиент]
      ,[Срок просрочки]
      ,[Бакет просрочки]
      ,[Стадия коллектинга договора]
      ,[Дата отправки последнего требования]
      ,[Дата отправки в суд поледнего иска]
      ,[Дата вынесения последнего решения]
      ,[Дата получения последнего решения]
      ,[Дата получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
      ,[Флаг отправки последнего требования]
      ,[Флаг отправки в суд поледнего иска]
      ,[Флаг вынесения последнего решения]
      ,[Флаг получения последнего решения]
      ,[Флаг получения последнего ИЛ (кроме ИЛ "Обеспечительные меры")]
	  ,[Дата возбуждения ИП]--добавил поле запрос Николаевой
      ,[Флаг Дата возбуждения ИП] --добавил поле запрос Николаевой
	  ,[Тип Продукта] --добавил тип продукта
	  ,Exeptation

 from #Final_table_exeptation




  
  commit transaction 





EXEC [collection].set_debug_info @sp_name
			,'Finish';		
			
	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
