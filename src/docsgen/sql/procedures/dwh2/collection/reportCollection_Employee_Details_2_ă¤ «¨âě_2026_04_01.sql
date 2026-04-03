
--exec Proc_CreatTable_Agr_IntRate_v1
create PROC [collection].[reportCollection_Employee_Details_2] 
	-- Add the parameters for the stored procedure here

@PageNo int
--, @dtFrom date 
--, @dtTo date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;
	SET TEXTSIZE 32767;

declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255)
		--, @PageNo int 
set @dtFrom = /*'20200801'*/
			case 
			  when day(Getdate())=1 
				  then cast(dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0) as date)
			  else cast(dateadd(MONTH,datediff(MONTH,0,dateadd(month,0,Getdate())),0) as date)
			  end
			  ;	--'20190815';   

			  --cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
set @dtTo = cast(getdate() as date) /* '20200831'*/;

---------------- исходные таблицы
drop table if exists #employee_stage0
select e.[Id] as EmployeeID ,([LastName]+' '+[FirstName]+' '+[MiddleName]) fio_empl ,[NaumenUserLogin] ,s.Id as [IdCollectingStage] ,s.[Name] NameStage ,[ExtensionNumber]
into #employee_stage0 
from [Stg].[_Collection].[Employee] e
   join stg._Collection.EmployeeCollectingStage ECS with (nolock) ON ECS. EmployeeId=E.ID
   join stg._Collection.[CollectingStage] s with (nolock) on eCS.CollectingStageId=s.id
  --left join [Stg].[_Collection].[collectingStage] s on e.[IdCollectingStage]=s.id
where s.[Name] in (N'Prelegal' ,N'Hard' ,N'Исп. Производство') 


drop table if exists #DateManager0
select distinct c.dt ,[Manager] mgr ,EmployeeID
into #DateManager0 --select *
from [Stg].[_Collection].[Communications] com with (nolock) 
cross join (select cast(created as date) as dt from dwh_new.[dbo].[calendar] where cast(created as date) >= @dtFrom and created <= Getdate()) c
where cast(com.[Date] as date)>=@dtFrom and EmployeeID in (select EmployeeID from #employee_stage0)


drop table if exists #communicationcall0
select 	case when CommunicationType=1 then 'Исходящий звонок'
            when CommunicationType=2 then 'Входящий звонок'
            when CommunicationType=3 then 'Выезд'
            when CommunicationType=4 then 'SKIP'
            when CommunicationType=5 then 'Смс'
            when CommunicationType=6 then 'E-mail'
            when CommunicationType=7 then 'Автоинформатор pre-del'
            when CommunicationType=8 then 'push'
			else N'Прочее'
        end   CommunicationType
		,com.[Id] as id_1 ,com.[Date] date_1 ,d.[Id] ,d.[Number] ,d.[UpdateDate] ,d.[Date] ,d.[Sum] ,d.[DebtSum] ,d.Fulldebt ,[ContactPerson] ,[PhoneNumber] ,[ContactTypeId] ,[PromiseSum] ,[PromiseDate]
		,[Manager] ,[Commentary] ,[CustomerId] ,isnull([ContactPersonType],N'') as [ContactPersonType] 
			  ,pt.[Name] PersonType  --,[FollowingStep] ,[FollowingStepDt] ,[NonPaymentReason] ,[ExpectedPaymentDt]
			  ,[IdDeal] --,[NextCallTime] ,[PaymentMethod] ,[CommunicationCustomerTypeId] ,[NaumenProjectId]
			  ,ECS.[EmployeeId] as [EmployeeId] --,[IdAnotherCustomerType]
			  ,[CallId] --,[IdAnotherNonPaymentReason]
			  ,[EndCallDt] ,[CommunicationResultId] ,res.[Name] as CommunicationResult --,[AdditionalInputField] ,[CommunicationTemplate] ,[IsTemplateCommunication] ,[MessageSubject]
			  ,[PaymentPromiseId] --,[CommunicationTemplateId] ,[NaumenCaseUuid] ,[SessionId]
			  , cust.LastName+' '+cust.Name+' '+cust.MiddleName  fio
			  , cust.CrmCustomerId
			  , s.[Name] as [EmployeeStage]
			  , datepart(ww,com.[Date]) as [Неделя]
	
	

into #communicationcall0		-- select *
from [Stg].[_Collection].[Communications] com with (nolock) 
left join [Stg].[_Collection].[CommunicationResult] res with (nolock) on res.id=com.CommunicationResultId
left join [Stg].[_Collection].[Deals] d with (nolock) on d.id=IdDeal and cast(com.[Date] as date)=cast(d.[UpdateDate] as date)
--left join [Stg].[_Collection].[CommunicationCustomerType] cct with (nolock) on cct.id=   CommunicationCustomerTypeId
left join [Stg].[_Collection].[customers] cust with (nolock) on cust.id=IdCustomer
left join [Stg].[_Collection].[ContactPersonType] pt with (nolock) on  pt.[Id]=[ContactPersonType]
left join [Stg].[_Collection].[Employee] e with (nolock) on com.EmployeeId=e.Id
   join stg._Collection.EmployeeCollectingStage ECS with (nolock) ON ECS.EmployeeId=E.ID
   join stg._Collection.[CollectingStage] s with (nolock) on eCS.CollectingStageId=s.id
  --left join [Stg].[_Collection].[collectingStage] s with (nolock) on s.Id=e.IdCollectingStage

where com.[Date] >= @dtFrom and com.EmployeeID in (select EmployeeID from #employee_stage0)

---------------------- Сотрудник - дата коммуникаций
--if object_id('tempdb.dbo.#DateManager') is not null drop table #DateManager

--select distinct cast(com.[Date] as date) dt ,[Manager] mgr ,EmployeeID
--into #DateManager --select *
--from [Stg].[_Collection].[Communications] com with (nolock) where cast(com.[Date] as date)>=@dtFrom


drop table if exists #DateManagerLoan
select distinct cast(date_1 as date) dt ,Number ,Manager as mgr ,[EmployeeId] 
into #DateManagerLoan 
from #communicationcall0 cmc with (nolock) where not Number is null --cast(date_1 as date)>=@dtFrom

--select * from #DateManagerLoan

------------------------------- ГРУППА 0. Сотрудник кол-во клиентов и договоров в работе


drop table if exists #ContractEmployee
/*
--OLD
select d.[CMRContractGUID] 
	  ,rf.CMRContractNumber external_id
	  ,[CMRContractStage] 
	  ,cast(d.[created] as date) [created] 
	  --,c0.[ProjectTitle]
	  ,c0.NaumenUserLogin 
	  ,c0.[EmployeeID]
into #ContractEmployee
from [dwh_new].[Dialer].[ClientContractStage] d 
left join (select c.CRMClientGUID ,c.[BindingDate] ,c.NaumenOperatorLogin,e.NaumenUserLogin ,e.Id as [EmployeeID] 
			 from [dwh_new].[Dialer].[ClientOperatorBinding] c /*where NaumenOperatorLogin like '%Nig%'*/
			 left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=c.NaumenOperatorLogin 
			 where cast(c.[BindingDate] as date) > = @dtFrom and isHistory=0			 
			 --where cast(c.[BindingDate] as date) > = cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) and isHistory=0
			) c0
on c0.CRMClientGUID=d.CRMClientGUID and c0.[BindingDate]=cast(d.[created] as date)
  left join [dwh_new].[staging].[CRMClient_reverse_references] rf on rf.[CMRContractGUID]=d.[CMRContractGUID]
where cast(d.[created] as date) >= @dtFrom and c0.[EmployeeID] in (select EmployeeID from #employee_stage0)
--where cast(d.[created] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) and c0.[EmployeeID] in (select EmployeeID from #employee_stage0)
		--and not e.Id is null
*/
--DWH-2442
select d.[CMRContractGUID] 
	  ,rf.CMRContractNumber external_id
	  ,[CMRContractStage] 
	  ,d.[created]
	  --,c0.[ProjectTitle]
	  ,c0.NaumenUserLogin 
	  ,c0.[EmployeeID]
into #ContractEmployee
from Stg._loginom.v_ClientContractStage_simple AS d
left join (select c.CRMClientGUID ,c.[BindingDate] ,c.NaumenOperatorLogin,e.NaumenUserLogin ,e.Id as [EmployeeID] 
			 from [dwh_new].[Dialer].[ClientOperatorBinding] c /*where NaumenOperatorLogin like '%Nig%'*/
			 left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=c.NaumenOperatorLogin 
			 where cast(c.[BindingDate] as date) > = @dtFrom and isHistory=0			 
			 --where cast(c.[BindingDate] as date) > = cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) and isHistory=0
			) c0
on c0.CRMClientGUID=d.CRMClientGUID and c0.[BindingDate]=d.[created]
  left join [dwh_new].[staging].[CRMClient_reverse_references] rf on rf.[CMRContractGUID]=d.[CMRContractGUID]
where d.[created] >= @dtFrom and c0.[EmployeeID] in (select EmployeeID from #employee_stage0)


--select * from #ContractEmployee ce where not [EmployeeID] is null

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
where cast([BindingDate] as date) >= @dtFrom and isHistory=0
--where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) and isHistory=0


drop table if exists #ClientEmployee2
select count(distinct [CRMClientGUID]) QClient ,count(distinct [CMRContractNumber]) QContract ,[BindingDate] ,[EmployeeID] 
into #ClientEmployee2 
from #ClientEmployee

where cast([BindingDate] as date) >= @dtFrom
--where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
group by [BindingDate] ,[EmployeeID]


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

where cast([BindingDate] as date) >= @dtFrom
--where cast([BindingDate] as date) >= cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date)
		and not r.[CMRContractNumber] is null and isHistory=0
group by b.[BindingDate] ,b.NaumenOperatorLogin ,e.Id ,(e.LastName+' '+e.FirstName+' '+e.MiddleName)


drop table if exists #gr0
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


drop table if exists #gr1
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
	   ,count(distinct (case when CommunicationType in (N'Прочее' ,N'SKIP' ,N'Автоинформатор pre-del' ,N'push') then id_1 else null end)) as a10	-- [Кол-во иных действий]
	   
	   ,count(distinct (case when PersonType =N'Клиент' or PersonType =N'Третье лицо' then id_1 else 0 end))+1 as a11		-- [Кол-во контактов всего есть результат действия контакт в системе]
	   ,count(distinct (case when PersonType =N'Клиент' or PersonType =N'Третье лицо' then CustomerId else null end)) as a112		-- [Кол-во уник.контактов всего есть результат действия контакт в системе]

	   ,count(distinct (case when PersonType =N'Клиент' and not CommunicationResult in ('Отправлено' ,'Автоответчик') then id_1 else 0 end)) as a12	-- [Кол-во контактов разговор с клиентом]
	   ,count(distinct (case when PersonType =N'Клиент' and not CommunicationResult in ('Отправлено' ,'Автоответчик') then CustomerId else Null end)) as a122	-- [Кол-во уник.контактов разговор с клиентом]
	   	   
	   ,count(distinct (case when PersonType =N'Третье лицо' then id_1 else 0 end)) as a13	-- [Кол-во контактов разговор с 3-ими лицами]
	   ,count(distinct (case when PersonType =N'Третье лицо' then CustomerId else Null end)) as a132	-- [Кол-во уник.контактов разговор с 3-ими лицами]
	   	
	   ,[EmployeeStage]

into #gr1	
from (select distinct * from #communicationcall0) t
--where --Manager in (N'Бавыкин Роман Алексеевич')--,N'Редькова Анастасия Николаевна') --and --cast([date_1] as date)='2019-11-20'
where cast([date_1] as date)>= @dtFrom	--'2019-11-27'
group by cast([date_1] as date) ,Manager ,[EmployeeStage] ,[EmployeeId] --,CommunicationType--,Fulldebt
--order by cast([date_1] as date) desc

--select * from #communicationcall0



---------------- подсчитаем кол-во клиентов у сотрудника за неделю
drop table if exists #gr_week
select distinct
		cast([date_1] as date) as [dt1]
	   ,datepart(ww ,[date_1]) wk
	   ,Manager
	   ,[EmployeeId]
	   ,CrmCustomerId
into #gr_week
from #communicationcall0
where not CrmCustomerId is null

drop table if exists #qty_cust_week
select 
		gw0.dt1 
		,gw0.wk 
		,gw0.EmployeeId 
		,gw0.Manager 
		,count(gw0.CrmCustomerId) as QtyCust_week
		--,gw1.*

into #qty_cust_week

from #gr_week gw0
left join #gr_week gw1 
	on		gw0.EmployeeId=gw1.EmployeeId 
		and gw0.CrmCustomerId=gw1.CrmCustomerId 
		and gw0.wk=gw1.wk 
		--and gw0.dt1>gw1.dt1 
group by gw0.dt1 ,gw0.wk ,gw0.EmployeeId ,gw0.Manager
order by 1 desc

---------------- конец подсчитаем кол-во клиентов у сотрудника за неделю



drop table if exists #gr2
select  cast([date_1] as date) as [dt1]
	    ,Manager
		,[EmployeeId]
		--,count(distinct [Number]) a014	-- [] 
		,sum(case when [CommunicationResult]=N'Обещание оплатить' then 1 else 0 end) as a14	-- [Кол-во обещаний взятых в дату] 	
		,count(distinct((case when [CommunicationResult]=N'Обещание оплатить' then CustomerId else null end))) as a142	-- [Кол-во обещаний взятых в дату] 
		--,count([PromiseDate]) as a14	-- [Кол-во обещаний взятых в дату] 	
		--,sum(distinct [PromiseSum]) as a15	-- [Сумма обещаний взятых в дату]  
		,sum(case when [CommunicationResult]=N'Обещание оплатить' then [PromiseSum] else 0 end ) as a15	-- [Сумма обещаний взятых в дату] 	
	  -- *
into #gr2
from (select distinct * from #communicationcall0) t1 
where  not [PromiseDate] is null --and cast([PromiseDate] as date)=cast([date_1] as date)--'2019-11-27' 
		and cast([date_1] as date) >= @dtFrom	-- '2019-11-20'

group by cast([date_1] as date) ,Manager ,[EmployeeId] 

drop table if exists #gr3
select	cast([date_1] as date) as [dt1]
	    ,Manager
		,[EmployeeId]
		,count(distinct [Number])  a16	-- [Всего обещаний сотрудника открытых на дату]	
		,sum(distinct [PromiseSum]) as a17	-- [Всего сумма обещаний сотрудника открытых на дату ] 
		,sum(distinct [DebtSum]) as a18	-- [Всего сумма балансов по обещаниям сотрудников открытых на дату ]	

into #gr3
from (select distinct * from #communicationcall0) t2
where not [PromiseDate] is null and cast([PromiseDate] as date)>=cast([date_1] as date)--'2019-11-27' 
		and cast([date_1] as date)>=@dtFrom-- '2019-11-20'
group by cast([date_1] as date) ,Manager ,[EmployeeId] 


drop table if exists #deals
select distinct  Number 
into #deals 
from (select distinct * from #communicationcall0) t3


drop table if exists #payments
select d.код external_id
       , dateadd(year,-2000,cast(g.Дата as date)) dt
       , sum(g.Сумма) summ
into #payments 
from stg._1cCMR.[документ_платеж] g with (nolock)
              join stg._1cCMR.Справочник_Договоры d with (nolock) on g.Договор=d.Ссылка
                  join #deals de on de.Number=d.код

where cast(g.Дата as date)>=dateadd(year,2000,@dtFrom) and cast(g.Дата as date)<dateadd(day,1,dateadd(year,2000,@dtTo)) 
			and d.код in (select distinct external_id from #ContractEmployee)
group by d.код ,dateadd(year,-2000,cast(g.Дата as date))
   --select * from #payments


drop table if exists #stat_v_balance2
select cdate ,external_id ,principal_rest 
into #stat_v_balance2
from dwh_new.dbo.stat_v_balance2 with (nolock) 
where external_id in (select distinct external_id from #ContractEmployee) and cdate between dateadd(day,-1,@dtFrom) and @dtTo


drop table if exists #EmployeeDatePay
select dt 
	  ,p.external_id
	  ,summ
	  ,e.[EmployeeID]
	  ,sb.principal_rest
into #EmployeeDatePay
from #payments p
left join (select distinct external_id ,[EmployeeID] from #ContractEmployee) e on e.external_id=p.external_id
left join #stat_v_balance2 sb on sb.[external_id]=p.external_id and dateadd(day,-1,p.dt)=cdate
--group by dt ,e.[EmployeeID]

--select * from #EmployeeDatePay


drop table if exists #paydebt
select distinct dt dt_call ,mgr ,ts.Number as numdog ,cast(PromiseDate as date) PromiseDate ,PromiseSum
	   ,[cdate] 
	   ,(isnull([principal_cnl],0) +isnull([percents_cnl],0)+isnull([fines_cnl],0) +isnull([otherpayments_cnl],0)) pay_cnl
	   ,PromiseSum-(isnull([principal_cnl],0) +isnull([percents_cnl],0)+isnull([fines_cnl],0) +isnull([otherpayments_cnl],0)) delta_pay
	   ,([principal_acc_run] +[percents_acc_run] +[fines_acc_run] +[otherpayments_acc_run])-([principal_cnl_run] +[percents_cnl_run]+[fines_cnl_run] +[otherpayments_cnl_run])  curr_debt
	   ,(amount - isnull([principal_cnl_run],0)) debt

into #paydebt

from (
select date_1 as dt ,[Manager] as mgr ,Number ,PromiseSum ,PromiseDate 
from (select distinct * from #communicationcall0) t4 where not PromiseDate is null) ts
left join (
			select * from dwh_new.dbo.stat_v_balance2 with (nolock) where not [principal_cnl] is null or not [percents_cnl] is null or not [fines_cnl] is null or not [otherpayments_cnl] is null
			) sb 
on sb.[external_id]=ts.Number and cast([cdate] as date) between cast(ts.dt as date) and cast(ts.PromiseDate as date)

--select * from #paydebt

--------------------------------------------------------
--------------------Группа 4. Исполнение и задолженности по договрам и сотрудникам и датам

drop table if exists #gr4
select tq.dt 
	   ,tq.mgr
	   ,tq.[EmployeeId] 
	   ,sum(tq.a1) a1 
	   ,sum(tq.a2) a2 
	   ,sum(tq.a3) a3
	   ,sum(isnull(ep.summ,0)) a4 --сумма платежей на дату, поступившая по сотруднику
	   ,sum(isnull(ep.principal_rest,0)) a5	-- сумма задолженности по ОД по договорам, по которым поступила оплата, на дату предшествующую дате платежа (за день до платежа)
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
 left join (select mgr ,pay_cnl pay ,pp1.numdog from #paydebt pp1 where pay_cnl > 0 and debt > 0) pd1 on c.mgr=pd1.mgr and c.number=pd1.numdog
group by c.dt ,c.Number ,c.mgr ,c.[EmployeeId]
) tq
left join #EmployeeDatePay ep on tq.[EmployeeId]=ep.EmployeeID and tq.dt=ep.dt
group by tq.dt ,tq.mgr ,tq.[EmployeeId]


drop table if exists #gr5
select dt 
	   --,tq.mgr
	   ,[EmployeeId] 
	   ,sum(isnull(ep.summ,0)) a4 --сумма платежей на дату, поступившая по сотруднику
	   ,sum(isnull(ep.principal_rest,0)) a5	-- сумма задолженности по ОД по договорам, по которым поступила оплата, на дату предшествующую дате платежа (за день до платежа)
into #gr5 
from #EmployeeDatePay ep
group by dt ,[EmployeeId]


drop table if exists #employee
select
 [дата]=dm.dt
 ,[Неделя] = datepart(ww ,dm.dt)
,[ID Сотрудника]=g0.EmployeeID
,[Коллектор (ФИО сотрудника)]=g0.fio_employee

-------- показатели группы 1
,[Договоров в работе сотрудника] = g0.QContract
,[Кол-во клиентов в работе сотрудника] = g0.QClient --count(distinct CrmCustomerId)
,[Сумма договоров в работе сотрудника] = g0.debt--sum(Fulldebt)

,[Кол-во обработанных клиентов] = g1.a4
--,[Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]=count(*)
,[Количество действий (количество занесенных комментариев в дату по одному договору)] = g1.a5
,[Кол-во входящих звонков] = g1.a6
,[Кол-во исходящих звонков] = g1.a7
,[Кол-во отправленных сообщений (СМС, е-мейл, соцсети)] = g1.a8
,[Кол-во выездов] = g1.a9
,[Кол-во иных действий] = g1.a10

,[Кол-во контактов всего (есть результат действия контакт в системе)] = g1.a11 --sum(cast(IsSuccessResult as int))
,[Кол-во уник.контактов всего (есть результат действия контакт в системе)] = g1.a112

-------- показатели группы 2
,[Кол-во контактов с клиентом (разговор с клиентом)] = g1.a12
,[Кол-во уник.контактов с клиентом (разговор с клиентом)] = g1.a122

,[Коли-во контактов с третьими лицами (разговор с третьим лицом)] = g1.a13
,[Коли-во уник.контактов с третьими лицами (разговор с третьим лицом)] = g1.a132

,[Кол-во обещаний (взятых в дату)] = g2.a14
,[Кол-во обещаний уник.клиентов (взятых в дату)] = g2.a142

,[Сумма обещаний (взятых в дату)]= g2.a15

-------- показатели группы 3
,[Всего обещаний сотрудника (открытых на дату)] = g3.a16
,[Всего сумма обещаний сотрудника (открытых на дату)] = g3.a17
,[Всего сумма балансов по обещаниям сотрудников (открытых на дату)] = g3.a18


-------- показатели группы 4
,[Сумма сохраненного баланса сотр.(по исполн.обещаниям с выходом из просрочки)] = g4.a2 --для prelegal
,[Сумма платежей сотр.(по исполн.обещаниям без выхода из просрочки)] = g4.a3 --для hard исп.производство

, s=0 --sum(summ)

, [Collection Stage]=g1.EmployeeStage

,[Сумма платежей сотрудника (любые платежи даже без обещаний)]=g5.a4
,[Сумма сохраненного баланса на дату. предшестувующую плату(любые платежи)]=g5.a5


,[Кол-во уник.клиентов в работе сотрудника за неделю] = gr1_w.QtyCust_week

into #employee
 from #DateManager0  dm 
 left join #gr0 g0 on dm.dt=g0.dt and dm.EmployeeId=g0.EmployeeID 
  

 left join #gr1 g1 on dm.dt=g1.dt1 and dm.mgr=g1.Manager 
 left join #qty_cust_week gr1_w on dm.dt=gr1_w.dt1 and dm.mgr=gr1_w.Manager 

 left join #gr2 g2 on dm.dt=g2.dt1 and dm.mgr=g2.Manager  
 left join #gr3 g3 on dm.dt=g3.dt1 and dm.mgr=g3.Manager  
 left join #gr4 g4 on dm.dt=g4.dt and dm.mgr=g4.mgr  
 left join #gr5 g5 on dm.dt=g5.dt and dm.EmployeeId=g5.EmployeeID 


--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------	


 if @PageNo=1

select distinct * 
--sum([Договоров в работе сотрудника]) a1
--,sum([Кол-во клиентов в работе сотрудника]) a2 --count(distinct CrmCustomerId)
--,sum([Сумма договоров в работе сотрудника]) a3
from #employee e
where /*not [Коллектор (ФИО сотрудника)] is null --=N'Лебедев Александр Дмитриевич'	-- not [Коллектор (ФИО сотрудника)] is null--=N'Бавыкин Роман Алексеевич' 
		--and [дата]='2019-11-27'
		and*/ [Collection Stage] in (N'Prelegal' ,N'Hard' ,N'Исп. Производство')
 
 order by 2,1 desc
 
  
 ------------------------------------------
 ------------------------------------------
 if @PageNo=2

select distinct /*d.Id ,d.Number */
	  c.CommunicationType 
	  ,id_1 
	  ,date_1 
	  ,c.[Id] 
	  ,case when c.[Number] is null then d.Number else c.Number end Number
	  ,[UpdateDate] 
	  ,[Date] 
	  ,[Sum] 
	  ,[DebtSum] 
	  ,Fulldebt 
	  ,[ContactPerson] 
	  ,[PhoneNumber] 
	  ,[ContactTypeId] 
	  ,[PromiseSum] 
	  ,[PromiseDate]
	  ,[Manager] 
	  ,[Commentary] 
	  ,[CustomerId] 
	  ,[ContactPersonType] 
	  ,PersonType  --,[FollowingStep] ,[FollowingStepDt] ,[NonPaymentReason] ,[ExpectedPaymentDt]
	  ,[IdDeal]
	  ,[EmployeeId]
	  ,[CallId]
	  ,[EndCallDt] 
	  ,[CommunicationResultId] 
	  ,CommunicationResult
	  ,[PaymentPromiseId]
	  ,fio
	  ,CrmCustomerId
	  ,[EmployeeStage]
	  ,[Неделя] 
from #communicationcall0 c /* where Number is not null*/
left join (select Id ,Number from stg._Collection.Deals) d on c.IdDeal=d.Id

END
