
--exec Proc_CreatTable_Agr_IntRate_v1
CREATE  PROCEDURE [dbo].[reportCollection_Employee_Soft_Middle_2] 
	-- Add the parameters for the stored procedure here

@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*

Строится на конкретную дату в разрезе каждого сотрудника подразделения (стадия Софт и стадия Миддл).
Фильтр ставится на стадию
При построении за период отчет строится в разрезе каждой даты
Коллектор (ФИО сотрудника)
Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)
Количество действий (количество занесенных комментариев в дату по одному договору)
Количество входящих звонков
Количество исходящих звонков
Количество отправленных сообщений (СМС, е-мейл, соцсети)
Количество иных действий
Количество контактов всего (есть результат действия контакт в системе)
Количество контактов с клиентом (разговор с клиентом)
Количество контактов с третьими лицами (разговор с третьим лицом)
Количество обещаний (взятых в дату)
Сумма обещаний (взятых в дату)
Всего обещаний сотрудника (открытых на дату)
Всего сумма обещаний сотрудника (открытых на дату)
Сумма сохраненного баланса сотрудника (все суммы сохраненного баланса (остаток займа на момент наличия просрочки) , которые зачтены за сотрудником по его выполненным обещаниям – если договор вошел в график платежей и просрочка полностью погашена)
Сумма платежей сотрудника (частичные платежи без вывода клиента в график) (все суммы платежей, которые зачтены за сотрудником по его выполненным обещаниям и после которых договор не вошел в график платежей, то есть любые частичные платежи по выполненным обещаниям)

*/
declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255) 
set @dtFrom = cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date);	--'20190815';   
set @dtTo = cast(getdate() as date)

drop table if exists #employee_stage
select e.[Id] as EmployeeID ,([LastName]+' '+[FirstName]+' '+[MiddleName]) fio_empl ,[NaumenUserLogin] ,[IdCollectingStage] ,s.[Name] NameStage ,[ExtensionNumber]
into #employee_stage 
from [Stg].[_Collection].[Employee] e
  left join [Stg].[_Collection].[collectingStage] s on e.[IdCollectingStage]=s.id
where s.[Name] in (N'Soft' ,N'Middle') 

--select * from #employee_stage

 if object_id('tempdb.dbo.#DateManager') is not null drop table #DateManager

select distinct c.dt ,com.[Manager] mgr ,com.EmployeeID --,es.NameStage
into #DateManager --select *
from [Stg].[_Collection].[Communications] com with (nolock) --where [Date] >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
--left join #employee_stage es on com.EmployeeID=es.EmployeeID
cross join (select cast(created as date) as dt from dwh_new.[dbo].[calendar] where cast(created as date) >= @dtFrom and created <= Getdate()) c
where /*cast(com.[Date] as date)>=@dtFrom and*/ EmployeeID in (select EmployeeID from #employee_stage)
--select * from #DateManager

--)

---------------------- Количество общений
--,	communicationcall as
--(
if object_id('tempdb.dbo.#communicationcall') is not null drop table #communicationcall
select 	case when CommunicationType=1 then 'Исходящий звонок'
            when CommunicationType=2 then 'Входящий звонок'
            when CommunicationType=3 then 'Выезд'
            when CommunicationType=4 then 'SKIP'
            when CommunicationType=5 then 'Смс'
            when CommunicationType=6 then 'E-mail'
            when CommunicationType=7 then 'Автоинформатор pre-del'
            when CommunicationType=8 then 'push'
        end   CommunicationType
		,com.[Id] as id_1 ,com.[Date] date_1 ,d.[Id] ,d.[Number] ,d.[UpdateDate] ,d.[Date] ,d.[Sum] ,d.[DebtSum] ,d.Fulldebt ,[ContactPerson] ,[PhoneNumber] ,[ContactTypeId] ,[PromiseSum] ,[PromiseDate]
			  ,[Manager] ,[Commentary] ,[CustomerId] ,[ContactPersonType] ,pt.[Name] PersonType  --,[FollowingStep] ,[FollowingStepDt] ,[NonPaymentReason] ,[ExpectedPaymentDt]
			  ,[IdDeal] --,[NextCallTime] ,[PaymentMethod] ,[CommunicationCustomerTypeId] ,[NaumenProjectId]
			  ,[EmployeeId] --,[IdAnotherCustomerType]
			  ,[CallId] --,[IdAnotherNonPaymentReason]
			  ,[EndCallDt] ,[CommunicationResultId] ,res.[Name] as CommunicationResult --,[AdditionalInputField] ,[CommunicationTemplate] ,[IsTemplateCommunication] ,[MessageSubject]
			  ,[PaymentPromiseId] --,[CommunicationTemplateId] ,[NaumenCaseUuid] ,[SessionId]
			  , cust.LastName+' '+cust.Name+' '+cust.MiddleName  fio
			  , cust.CrmCustomerId
			  , s.[Name] as [EmployeeStage]
				
into #communicationcall		-- select *
from [Stg].[_Collection].[Communications] com with (nolock) 
left join [Stg].[_Collection].[CommunicationResult] res with (nolock) on res.id=com.CommunicationResultId
left join [Stg].[_Collection].[Deals] d with (nolock) on d.id=IdDeal and cast(com.[Date] as date)=cast(d.[UpdateDate] as date)
--left join [Stg].[_Collection].[CommunicationCustomerType] cct with (nolock) on cct.id=   CommunicationCustomerTypeId
left join [Stg].[_Collection].[customers] cust with (nolock) on cust.id=IdCustomer
left join [Stg].[_Collection].[ContactPersonType] pt with (nolock) on  pt.[Id]=[ContactPersonType]
left join [Stg].[_Collection].[Employee] e with (nolock) on com.EmployeeId=e.Id
  left join [Stg].[_Collection].[collectingStage] s with (nolock) on s.Id=e.IdCollectingStage

where com.[Date] >= @dtFrom and com.EmployeeID in (select EmployeeID from #employee_stage)

---- select * from #communicationcall where [Manager]=N'Борзова Снежана Вячеславовна' and cast(date_1 as date)='2019-11-20' and CommunicationType=N''
--)
--------------------------------------------------------------

--------------------------------------------------------------

--------------------------------------------------------------	
				
---------------------- Сотрудник - дата коммуникаций - договор
--,	DateManagerLoan as
--(
if object_id('tempdb.dbo.#DateManagerLoan') is not null drop table #DateManagerLoan
select distinct cast(date_1 as date) dt ,Number ,Manager as mgr ,[EmployeeId] 
into #DateManagerLoan 
from #communicationcall cmc with (nolock)-- where not Number is null --cast(date_1 as date)>=@dtFrom
--)
--select * from #DateManagerLoan

------------------------------- ГРУППА 0. Сотрудник кол-во клиентов и договоров в работе
/*
--,	ContractEmployee as 
--(
drop table if exists #ContractEmployee
select [CMRContractGUID] 
	  ,[CMRContractStage] 
	  ,cast(d.[created] as date) [created] 
	  --,c0.[ProjectTitle]
	  ,c0.NaumenUserLogin 
	  ,c0.[EmployeeID]
into #ContractEmployee
from [dwh_new].[Dialer].[ClientContractStage] d 
left join (select c.CRMClientGUID ,c.[BindingDate] ,e.NaumenUserLogin ,e.Id as [EmployeeID] 
			 from [dwh_new].[Dialer].[ClientOperatorBinding] c 
			 left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=c.NaumenOperatorLogin 
			 where cast(c.[BindingDate] as date) > = cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
			) c0
on c0.CRMClientGUID=d.CRMClientGUID and c0.[BindingDate]=cast(d.[created] as date)
where cast(d.[created] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
		--and not e.Id is null
--)

--select * from #ContractEmployee ce where not [EmployeeID] is null


--,	ContractEmployee2 as
--(
drop table if exists #ContractEmployee2
select count([QContract]) as [QContract]
		,sum([debt])  [debt]
		,sum([fulldebt]) [fulldebt]  --,[ProjectTitle] 
		,[created] 
		,[EmployeeID]
into #ContractEmployee2
from (
select distinct rf.[CMRContractNumber] as QContract
		,isnull(sb.[principal_rest],0) debt 
		,isnull(sb.[total_rest],0) fulldebt 
		--,ce.[ProjectTitle] 
		,[created] ,[EmployeeID]
		--ce.* 
from #ContractEmployee ce
  left join [dwh_new].[staging].[CRMClient_reverse_references] rf on rf.[CMRContractGUID]=ce.[CMRContractGUID]
  left join [dwh_new].[dbo].[stat_v_balance2] sb on sb.[external_id]=rf.[CMRContractNumber] and sb.[cdate]=ce.[created]
where not rf.[CMRContractNumber] is null
) tt
group by [created] ,[EmployeeID] --,[ProjectTitle] 
--order by [EmployeeID] desc ,[created] desc
--select * from #ContractEmployee2
--)
--,	ClientEmployee as
--(
drop table if exists #ClientEmployee
select [ProjectUUID]
      ,[ProjectTitle]
      ,[BindingDate]
      ,c.[CRMClientGUID]
      ,[NaumenOperatorLogin]
	  ,e.Id as [EmployeeID]
	  ,r.[CMRContractNumber]
into #ClientEmployee
from [dwh_new].[Dialer].[ClientOperatorBinding] c
left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=c.NaumenOperatorLogin
left join [dwh_new].[staging].[CRMClient_reverse_references] r on c.[CRMClientGUID]=r.[CRMClientGUID]
where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
--)



--,	ClientEmployee2 as
--(
drop table if exists #ClientEmployee2
select count(distinct [CRMClientGUID]) QClient ,count(distinct [CMRContractNumber]) QContract ,[BindingDate] ,[EmployeeID] 
into #ClientEmployee2 
from #ClientEmployee 
where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
group by [BindingDate] ,[EmployeeID]
--)

--,	ClientEmployee22 as
--(
drop table if exists #ClientEmployee22
select count(distinct r.[CMRContractNumber]) QContract 
	  ,count(distinct b.[CRMClientGUID]) QClient 
	  ,[BindingDate] 
	  ,NaumenOperatorLogin 
	  ,e.Id as [EmployeeID] 
	  ,(e.LastName+' '+e.FirstName+' '+e.MiddleName) fio_employee
into #ClientEmployee22
from [dwh_new].[Dialer].[ClientOperatorBinding] b
left join [dwh_new].[staging].[CRMClient_reverse_references] r on b.[CRMClientGUID]=r.[CRMClientGUID]
left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=b.NaumenOperatorLogin 
where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
		and not r.[CMRContractNumber] is null
group by b.[BindingDate] ,b.NaumenOperatorLogin ,e.Id ,(e.LastName+' '+e.FirstName+' '+e.MiddleName)
--)

--,	gr0 as
--(
if object_id('tempdb.dbo.#gr1') is not null drop table #gr0
select --* 
cl.QClient
,cl.[QContract]
,[debt]
,[fulldebt]
,cl.[EmployeeID]
,cl.fio_employee
,cl.[BindingDate] dt
into #gr0
from #ClientEmployee22 cl 
left join #ContractEmployee2 ce on cl.[EmployeeID]=ce.[EmployeeID] and cl.[BindingDate]=ce.[created] 
--order by [BindingDate] desc ,[EmployeeID] desc
--)

*/
------------------------------- ГРУППА 1. количество звонков иных действий сегодня
--,	gr1 as
--(
if object_id('tempdb.dbo.#gr1') is not null drop table #gr1

select cast([date_1] as date) as [dt1]
	   ,Manager
	   ,[EmployeeId]
	   ,count(distinct PhoneNumber) a0 
	   ,count(distinct (case when PersonType =N'Клиент' then fio else Null end)) a01
	   ,count(distinct Number) as a1
	   ,count(distinct CrmCustomerId) as a2
	   ,sum(Fulldebt) as a3
	    ,count(distinct fio) as a4	-- [Кол-во обработанных клиентов]	
	   --,count(distinct (case when PersonType =N'Клиент' and CommunicationResult<>N'Отклонен/Cброс' then fio else Null end)) as a4	-- [Кол-во обработанных клиентов]	

	   ,sum(case when CommunicationType is null then 0 else 1 end) as a5	-- [Занесенных комментариев в дату по одному договору]
	   ,count(distinct (case when CommunicationType =N'Входящий звонок' then id_1 else null end)) as a6	-- [Кол-во входящих звонков]

	   ,count(distinct (case when CommunicationType =N'Исходящий звонок' then id_1 else null end)) as a7	-- [Кол-во исходящих звонков]
	   ,count(distinct (case when CommunicationType =N'Смс' or CommunicationType =N'E-mail' then id_1 else null end))  as a8	-- [Кол-во отправленных сообщений СМС е мейл соцсети]
	   ,count(distinct (case when CommunicationType =N'Выезд' then id_1 else null end)) as a9	-- [Кол-во выездов]
	   ,count(distinct (case when not CommunicationType in (N'Входящий звонок' ,N'Исходящий звонок' ,N'Смс' ,N'E-mail' ,N'Выезд') then id_1 else null end)) as a10	-- [Кол-во иных действий]
	   
	   ,count(distinct (case when PersonType =N'Клиент' or PersonType =N'Третье лицо' then id_1 else 0 end)) as a11		-- [Кол-во контактов всего есть результат действия контакт в системе]
	   ,count(distinct (case when PersonType =N'Клиент' then CustomerId else Null end)) as a12	-- [Кол-во контактов разговор с клиентом]	   
	   ,count(distinct (case when PersonType =N'Третье лицо' then CustomerId else Null end)) as a13	-- [Кол-во контактов разговор с 3-ими лицами]	
	   ,[EmployeeStage]

into #gr1
from #communicationcall t
--where --Manager in (N'Бавыкин Роман Алексеевич')--,N'Редькова Анастасия Николаевна') --and --cast([date_1] as date)='2019-11-20'
where cast([date_1] as date)>= @dtFrom --and t.EmployeeID in (select EmployeeID from #employee_stage) --'2019-11-27'
group by cast([date_1] as date) ,t.Manager ,t.[EmployeeStage] ,t.[EmployeeId] --,CommunicationType--,Fulldebt
--order by cast([date_1] as date) desc
--)
--select * from #gr1



------------------------------- ГРУППА 2. взятые обещаний сегодня
--,	gr2 as
--(
if object_id('tempdb.dbo.#gr2') is not null drop table #gr2
select  cast([date_1] as date) as [dt1]
	    ,Manager
		,[EmployeeId]
		--,count(distinct [Number]) a014	-- [] 
		,sum(case when [CommunicationResult]=N'Обещание оплатить' then 1 else 0 end) as a14	-- [Кол-во обещаний взятых в дату] 	
		--,count([PromiseDate]) as a14	-- [Кол-во обещаний взятых в дату] 	
		--,sum(distinct [PromiseSum]) as a15	-- [Сумма обещаний взятых в дату]  
		,sum(case when [CommunicationResult]=N'Обещание оплатить' then [PromiseSum] else 0 end ) as a15	-- [Сумма обещаний взятых в дату] 	
	  -- *
into #gr2
from #communicationcall 
where  not [PromiseDate] is null --and cast([PromiseDate] as date)=cast([date_1] as date)--'2019-11-27' 
		and cast([date_1] as date) >= @dtFrom	-- '2019-11-20'

group by cast([date_1] as date) ,Manager ,[EmployeeId] 
--order by cast([date_1] as date) desc
--)

------------------------------- открытых обещаний на сегодня (сегодня и в будущем)
--,	gr3 as
--(
if object_id('tempdb.dbo.#gr3') is not null drop table #gr3
select	cast([date_1] as date) as [dt1]
	    ,Manager
		,[EmployeeId]
		,count(distinct [Number])  a16	-- [Всего обещаний сотрудника открытых на дату]	
		,sum(distinct [PromiseSum]) as a17	-- [Всего сумма обещаний сотрудника открытых на дату ] 
		,sum(distinct [DebtSum]) as a18	-- [Всего сумма балансов по обещаниям сотрудников открытых на дату ]	

into #gr3
from #communicationcall 
where not [PromiseDate] is null and cast([PromiseDate] as date)>=cast([date_1] as date)--'2019-11-27' 
		and cast([date_1] as date)>=@dtFrom -- '2019-11-20'

group by cast([date_1] as date) ,Manager ,[EmployeeId] 
--order by cast([date_1] as date) desc
--)

--,	deals as
--(
if object_id('tempdb.dbo.#deals') is not null drop table #deals
select distinct  Number 
into #deals 
from #communicationcall
--)


--,	payments as
--(
if object_id('tempdb.dbo.#payments') is not null drop table #payments

select d.код external_id
       , dateadd(year,-2000,cast(g.Дата as date)) dt
       , sum(g.Сумма) summ
    into #payments
   from [C1-VSR-SQL06].[cmr].[dbo].[документ_платеж] g with (nolock)
              join [C1-VSR-SQL06].[cmr].[dbo].Справочник_Договоры d with (nolock) on g.Договор=d.Ссылка
                  join #deals de on de.Number=d.код

   where cast(g.Дата as date)>=dateadd(year,2000,@dtFrom) and cast(g.Дата as date)<dateadd(day,1,dateadd(year,2000,@dtTo))
   group by d.код,dateadd(year,-2000,cast(g.Дата as date))
   --select * from #payments
--)
--,	paydebt as
--(
if object_id('tempdb.dbo.#paydebt') is not null drop table #paydebt
select distinct dt dt_call ,mgr ,ts.Number as numdog ,cast(PromiseDate as date) PromiseDate ,PromiseSum
	   ,[cdate] 
	   ,(isnull([principal_cnl],0) +isnull([percents_cnl],0)+isnull([fines_cnl],0) +isnull([otherpayments_cnl],0)) pay_cnl
	   ,PromiseSum-(isnull([principal_cnl],0) +isnull([percents_cnl],0)+isnull([fines_cnl],0) +isnull([otherpayments_cnl],0)) delta_pay
	   ,([principal_acc_run] +[percents_acc_run] +[fines_acc_run] +[otherpayments_acc_run])-([principal_cnl_run] +[percents_cnl_run]+[fines_cnl_run] +[otherpayments_cnl_run])  curr_debt
	   ,(amount - isnull([principal_cnl_run],0)) debt

into #paydebt

from (
select date_1 as dt ,[Manager] as mgr ,Number ,PromiseSum ,PromiseDate 
from #communicationcall where not PromiseDate is null) ts
left join (
			select * from dwh_new.dbo.stat_v_balance2 with (nolock) where not [principal_cnl] is null or not [percents_cnl] is null or not [fines_cnl] is null or not [otherpayments_cnl] is null
			) sb 
on sb.[external_id]=ts.Number and cast([cdate] as date) between cast(ts.dt as date) and cast(ts.PromiseDate as date)
--where  PromiseSum-(isnull([principal_cnl],0) +isnull([percents_cnl],0)+isnull([fines_cnl],0) +isnull([otherpayments_cnl],0)) <= 0
--)
--select * from #paydebt

--------------------------------------------------------
--------------------Группа 4. Исполнение и задолженности по договрам и сотрудникам и датам
--,	gr4 as
--(
 if object_id('tempdb.dbo.#gr4') is not null drop table #gr4
select tq.dt 
	   ,tq.mgr
	   ,tq.[EmployeeId] 
	   ,sum(tq.a1) a1 
	   ,sum(tq.a2) a2 
	   ,sum(tq.a3) a3
into #gr4 
from 
(select c.dt ,c.mgr  --,c.Number
		,c.[EmployeeId]
		,sum(isnull(p.summ,0)) a1 
		,sum(isnull(pd.debt,0)) a2 
		,sum(isnull(pd1.pay,0)) a3
from #DateManagerLoan c
 left join #payments p on cast(c.dt as date)=p.dt and c.Number=p.external_id
 left join (select mgr ,debt ,numdog from #paydebt pp where delta_pay < 0 and curr_debt <= 0) pd on c.mgr=pd.mgr and c.number=pd.numdog
 left join (select mgr ,pay_cnl pay ,pp1.numdog from #paydebt pp1 where pay_cnl > 0 and debt > 0 /*and mgr in (N'Самородов Василий Васильевич')*/ ) pd1 on c.mgr=pd1.mgr and c.number=pd1.numdog
group by c.dt ,c.Number ,c.mgr ,c.[EmployeeId]
) tq
group by tq.dt ,tq.mgr ,tq.[EmployeeId]
order by tq.mgr ,tq.dt



 --select --*
 --dt 
 --,mgr 
 --,sum(a1) a1 
 --,sum(a2) a2 
 --,sum(a3) a3
 --from #gr4
 --group by dt ,mgr
--)
--,	employee as
--(
if object_id('tempdb.dbo.#employee') is not null drop table #employee
select
 [дата]=dm.dt
,[ID Сотрудника]=dm.EmployeeID
,[Коллектор (ФИО сотрудника)]=dm.mgr --g0.fio_employee

-------- показатели группы 1
,[Договоров в работе сотрудника] = 0--g0.QContract
,[Кол-во клиентов в работе сотрудника] = N''	--g0.QClient --count(distinct CrmCustomerId)
,[Сумма договоров в работе сотрудника] = N''	--g0.debt--sum(Fulldebt)

,[Кол-во обработанных клиентов] = g1.a4
--,[Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]=count(*)
,[Количество действий (количество занесенных комментариев в дату по одному договору)] = g1.a5
,[Кол-во входящих звонков] = g1.a6
,[Кол-во исходящих звонков] = g1.a7
,[Кол-во отправленных сообщений (СМС, е-мейл, соцсети)] = g1.a8
,[Кол-во выездов] = g1.a9
,[Кол-во иных действий] = g1.a10
,[Кол-во контактов всего (есть результат действия контакт в системе)] = g1.a11 --sum(cast(IsSuccessResult as int))
-------- показатели группы 2
,[Кол-во контактов с клиентом (разговор с клиентом)] = g1.a12
,[Коли-во контактов с третьими лицами (разговор с третьим лицом)] = g1.a13
,[Кол-во обещаний (взятых в дату)] = g2.a14
,[Сумма обещаний (взятых в дату)]= g2.a15

-------- показатели группы 3
,[Всего обещаний сотрудника (открытых на дату)] = g3.a16
,[Всего сумма обещаний сотрудника (открытых на дату)] = g3.a17
,[Всего сумма балансов по обещаниям сотрудников (открытых на дату)] = g3.a18
--,[Сумма платежей сотрудника (любые платежи даже без обещаний)]=

-------- показатели группы 4
,[Сумма сохраненного баланса сотр.(по исполн.обещаниям с выходом из просрочки)] = g4.a2 --для prelegal
,[Сумма платежей сотр.(по исполн.обещаниям без выхода из просрочки)] = g4.a3 --для hard исп.производство

, s=0 --sum(summ)

, [Collection Stage]=g1.EmployeeStage
into #employee
 from #DateManager  dm 
 --left join #gr0 g0 on dm.dt=g0.dt and dm.EmployeeId=g0.EmployeeID 
  
 left join #gr1 g1 on dm.dt=g1.dt1 and dm.mgr=g1.Manager  
 left join #gr2 g2 on dm.dt=g2.dt1 and dm.mgr=g2.Manager  
 left join #gr3 g3 on dm.dt=g3.dt1 and dm.mgr=g3.Manager  
 left join #gr4 g4 on dm.dt=g4.dt and dm.mgr=g4.mgr  


 set @PageNo=1

 -------------------------------------------------------
 -------------------------------------------------------
 ---------------------- SOFT

if @PageNo=1

with empl_soft as
(
select * 
--sum([Договоров в работе сотрудника]) a1
--,sum([Кол-во клиентов в работе сотрудника]) a2 --count(distinct CrmCustomerId)
--,sum([Сумма договоров в работе сотрудника]) a3
from #employee e
where /*not [Коллектор (ФИО сотрудника)] is null --=N'Лебедев Александр Дмитриевич'	-- not [Коллектор (ФИО сотрудника)] is null--=N'Бавыкин Роман Алексеевич' 
		--and [дата]='2019-11-27'
		and */
		[Collection Stage] in (N'Soft')
 )

select * from empl_soft order by 2,1 desc

 -------------------------------------------------------
 -------------------------------------------------------
 ---------------------- MIDDLE
 
set @PageNo=2

if @PageNo=2


with empl_middle as
(
select * 
--sum([Договоров в работе сотрудника]) a1
--,sum([Кол-во клиентов в работе сотрудника]) a2 --count(distinct CrmCustomerId)
--,sum([Сумма договоров в работе сотрудника]) a3
from #employee e
where /*not [Коллектор (ФИО сотрудника)] is null --=N'Лебедев Александр Дмитриевич'	-- not [Коллектор (ФИО сотрудника)] is null--=N'Бавыкин Роман Алексеевич' 
		--and [дата]='2019-11-27'
		and*/ [Collection Stage] in (N'Middle')
 
 --order by 2,1 desc
 )

 select * from empl_middle order by 2,1 desc
 
 END