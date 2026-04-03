
--exec [dbo].[reportCollection_Employee_Details_v1] 

create      PROCEDURE [dbo].[reportCollection_Employee_Details_v1] 
AS
BEGIN
	SET NOCOUNT ON;
  
  /*
Дата + (дата везде указывается за каждый  календарный день). При построении за период отчет строится в разрезе каждой даты
Коллектор (ФИО сотрудника)
Количество договоров в работе сотрудника
Количество клиентов в работе сотрудника
Сумма договоров в работе сотрудника
Количество обработанных клиентов (хотя бы одно действие в Спейс зафиксировано)
Количество действий (количество занесенных комментариев в дату по одному договору)
Количество входящих звонков
Количество исходящих звонков
Количество сообщений (СМС/е-мейл/соцсети)
Количество выездов
Количество иных действий
Количество контактов всего
Количество контактов с клиентом
Количество контактов с третьими лицами
Количество обещаний (взятых в дату)
Сумма обещаний (взятых в дату)
Всего обещаний сотрудника (открытых на дату)
Всего сумма обещаний сотрудника (открытых на дату)
Всего сумма балансов по обещаниям сотрудников (открытых на дату)
Сумма платежей сотрудника (любые платежи даже без обещаний)
Сумма сохраненного баланса сотрудника (ввод в график)
Сумма платежей сотрудника (частичные платежи без вывода клиента в график)
*/
  declare 
	        @dtTo date,
		      @stage nvarchar(255) 
  
  declare @dtFrom date
  set @dtFrom = cast(format(getdate(),'yyyyMM01') as date)
  set @dtTo = cast(getdate() as date)

--  select  @dtFrom, @dtTo


  drop table if exists #employee_stage

  select e.[Id] as EmployeeID 
       , ([LastName]+' '+[FirstName]+' '+[MiddleName]) fio_empl 
       , [NaumenUserLogin] 
       , [IdCollectingStage] 
       , s.[Name] NameStage 
       , [ExtensionNumber]
    into #employee_stage 
    from Stg._Collection.Employee e
    left join Stg._Collection.collectingStage s on e.IdCollectingStage=s.id
 --  where s.[Name] in (N'Soft' ,N'Middle') 

--  select * from #employee_stage


  drop table if exists #deals
  ; with d as (
  select *
  ,rn=row_number() over(partition by id order by updatedate desc)
  from [Stg].[_Collection].[Deals] d                   
  )
  select * into #deals from d where rn=1


  -- select * from #deals where number='19040807660002'
  
  
  -- Платежи
  if object_id('tempdb.dbo.#payments') is not null drop table #payments
 
  SELECT de.Number external_id
       , dateadd(year,-2000,cast(g.Дата as date)) dt
       , sum(g.Сумма) summ
    into #payments
    from [C1-VSR-SQL06].[cmr].[dbo].[документ_платеж] g
    join stg._1cCMR.Справочник_Договоры d on d.ссылка= g.Договор
    join #deals de on de.Number=d.Код
   where g.Дата>=dateadd(year,2000,@dtFrom) and g.Дата<dateadd(day,1,dateadd(year,2000,@dtTo))
   group by de.Number,dateadd(year,-2000,cast(g.Дата as date))



  drop table if exists #communicationcall
  select distinct 
          case  when CommunicationType=1 then 'Исходящий звонок'
                when CommunicationType=2 then 'Входящий звонок'
                when CommunicationType=3 then 'Выезд'
                when CommunicationType=4 then 'SKIP'
                when CommunicationType=5 then 'Смс'
                when CommunicationType=6 then 'E-mail'
                when CommunicationType=7 then 'Автоинформатор pre-del'
                when CommunicationType=8 then 'push'
                when CommunicationType=9 then 'Личная встреча в офисе'
                when CommunicationType=10 then 'Мессенджеры'
                when CommunicationType=11 then 'Соц. сети'
                when CommunicationType=12 then 'Внутренний результат'
                when CommunicationType=13 then 'Верификация контактов СКИП'
                when CommunicationType=14 then 'Система'
                else format(CommunicationType,'0')
          end   CommunicationType
       , com.[Id] as id_1 
       , cast(com.[Date] as date) CommunicationDate
       , com.[Date]  CommunicationDateTime
       , d.[Id] 
       , d.[Number] 
       , d.[UpdateDate] 
       , d.[Date] 
       , d.[Sum] 
       , d.[DebtSum] 
       , d.Fulldebt 
       , [ContactPerson] 
       , [PhoneNumber] 
       , [ContactTypeId] 
       , [PromiseSum] 
       , [PromiseDate]
			 , [Manager] 
       , [Commentary] 
       , [CustomerId] 
       , [ContactPersonType] 
       , pt.[Name] PersonType
			 , [IdDeal] 
			 , [EmployeeId]
			 , [CallId] 
			 , [EndCallDt] 
       , [CommunicationResultId] 
       , res.[Name] as CommunicationResult 
			 , [PaymentPromiseId] 
			 , cust.LastName+' '+cust.Name+' '+cust.MiddleName  fio
			 , cust.CrmCustomerId
			 , s.[Name] as [EmployeeStage]
       , b.[остаток од] [остаток на дату коммуникации]
       , ptp_b.[остаток од] [остаток на дату обещания]
       , b.overdue [задолжность на дату коммуникации]
       , ptp_b.overdue [задолжность на дату обещания]
       ,col.success_PTP
       ,col.succes_partial_ptp
       ,col.ptpDateBalance
       ,col.СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания
	  into #communicationcall		-- select *
    from [Stg].[_Collection].[Communications]  com            with (nolock) 
    left join [Stg].[_Collection].[CommunicationResult] res   with (nolock) on res.id=com.CommunicationResultId
    left join  #Deals d with (nolock) on d.id=IdDeal --and cast(com.[Date] as date)=cast(d.[UpdateDate] as date)
    left join [Stg].[_Collection].[customers] cust            with (nolock) on cust.id=IdCustomer
    left join [Stg].[_Collection].[ContactPersonType] pt      with (nolock) on  pt.[Id]=[ContactPersonType]
    left join [Stg].[_Collection].[Employee] e                with (nolock) on com.EmployeeId=e.Id
    left join [Stg].[_Collection].[collectingStage] s         with (nolock) on s.Id=e.IdCollectingStage
    left join [Reports].[dbo].[dm_CMRStatBalance]       b on  d.Number=b.external_id  and cast(com.[Date] as date)=b.Период
    left join [Reports].[dbo].[dm_CMRStatBalance]       ptp_b on  d.Number=ptp_b.external_id  and com.PromiseDate=ptp_b.Период
    left join [Reports].[dbo].[dm_CollectionKPIByMonth] col on col.дата=cast(com.[Date] as date) and col.НомерДоговора=d.Number and col.Сотрудник=com.Manager
   where com.[Date] >= @dtFrom and com.EmployeeID in (select EmployeeID from #employee_stage)

   ---select * from  [Reports].[dbo].[dm_CollectionKPIByMonth]

drop table if exists #EmployeeCustomerContract
--declare @dtFrom date
  set @dtFrom = cast(format(getdate(),'yyyyMM01') as date)
  
    select c.BindingDate
         , c.NaumenOperatorLogin
         , c.CRMClientGUID 
         , e.NaumenUserLogin 
         ,   EmployeeID               =e.Id
         , r.CMRContractNumber
  into #EmployeeCustomerContract
    from [dwh_new].[Dialer].[ClientOperatorBinding] c 
		left join [Stg].[_Collection].[Employee] e on e.NaumenUserLogin=c.NaumenOperatorLogin 
    left join [dwh_new].[staging].CRMClient_references r on r.crmClientGuid=c.crmClientGuid
	 where cast(c.[BindingDate] as date) > = @dtFrom and isHistory=0
    order by bindingdate,NaumenOperatorLogin


drop table if exists #EmployeeCustomerContractByDate
    select BindingDate
         , NaumenOperatorLogin
         , NaumenUserLogin 
         , EmployeeID         
         
         , count( distinct CRMClientGUID) NoOfClients
         , count( distinct CMRContractNumber) NoOfContracts
      into #EmployeeCustomerContractByDate
      from #EmployeeCustomerContract
      group by  BindingDate
         , NaumenOperatorLogin
         , NaumenUserLogin 
         , EmployeeID       



--[Сумма платежей сотрудника (любые платежи даже без обещаний)]


drop table if exists #res
  select [Коллектор (ФИО сотрудника)]=manager
       , Стадия=EmployeeStage
       , Дата=communicationDate
       , [Количество клиентов в работе сотрудника]=sum(ccbd.NoOfClients)
       , [Количество договоров в работе сотрудника]=sum(ccbd.NoOfContracts)
       , [Сумма договоров в работе сотрудника]=sum([остаток на дату коммуникации])
        --number
       , [Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]=count(*)--count(distinct CommunicationDateTime )
-- по клиенту
       , [Количество входящих звонков]=count (distinct case when CommunicationType='Входящий звонок' then CommunicationDateTime else null end) 
       , [Количество исходящих звонков]=count (distinct case when CommunicationType='Исходящий звонок' then CommunicationDateTime else null end)
       , [Количество отправленных сообщений (СМС, е-мейл, соцсети)] =count (distinct case when CommunicationType in ('Смс','Мессенджеры','Соц. сети') then CommunicationDateTime else null end)
       , [Количество выездов] =count (distinct case when CommunicationType in ('Смс','Мессенджеры','Соц. сети') then CommunicationDateTime else null end)
       , [Количество иных действий]=count (distinct case when CommunicationType not in ('Входящий звонок','Исходящий звонок','Смс','Мессенджеры','Соц. сети') then CommunicationDateTime else null end)
       , [Количество контактов всего (есть результат действия контакт в системе)]=count (distinct case when PersonType<>'Нет контакта' then CommunicationDateTime else null end)
       , [Количество контактов с клиентом (разговор с клиентом)]=count(distinct case when PersonType='Клиент' then CommunicationDateTime else null end)
       , [Количество контактов с третьими лицами (разговор с третьим лицом)]=count(distinct case when PersonType='Третье лицо' then CommunicationDateTime else null end)
-- по договору       
       , [Количество обещаний (взятых в дату)]=sum(case when CommunicationResult='Обещание оплатить' then 1 else 0 end)
       , [Сумма обещаний (взятых в дату)]=sum(case when CommunicationResult='Обещание оплатить' then PromiseSum else 0.0 end)
        
       --, [Всего обещаний сотрудника (открытых на дату)] =null --, =sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then 1 else 0 end)
       --, [Всего сумма обещаний сотрудника (открытых на дату)]=null--sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then PromiseSum else 0.0 end)
--       , [Всего сумма балансов по обещаниям сотрудников (открытых на дату)]=sum(case when CommunicationResult='Обещание оплатить' then c.[остаток на дату коммуникации] else 0.0 end)
       , [Сумма сохраненного баланса сотрудника]=sum(case when success_ptp=1        then [остаток на дату обещания] else 0 end)
       , [Сумма платежей сотрудника ]=sum(case when succes_partial_ptp=1        then СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания else 0 end)
       , [Сумма платежей сотрудника (любые платежи даже без обещаний)] =sum(p.summ)
     --  ,c=count(*)
       into #res
from #communicationcall c --where CommunicationDate>='20191216'
left join #EmployeeCustomerContractByDate ccbd on  ccbd.EmployeeID=c.EmployeeId and ccbd.BindingDate=c.CommunicationDate
left join #payments p on p.dt=c.CommunicationDate and p.external_id=c.Number
group by 
c.manager,c.EmployeeStage,c.EmployeeID,communicationDate--,number


drop table if exists #res_promises

  select * 
        , res_promises_count= (select sum(1) from #communicationcall cc where cc.manager=r.[Коллектор (ФИО сотрудника)]	
                                                          and cc.EmployeeStage=r.Стадия and cast(cc.promiseDate as date)>=r.Дата)

        , res_promises_sum= (select sum(promiseSum) from #communicationcall cc where cc.manager=r.[Коллектор (ФИО сотрудника)]	
                                                          and cc.EmployeeStage=r.Стадия and cast(cc.promiseDate as date)>=r.Дата)
        , [Всего сумма балансов по обещаниям сотрудников (открытых на дату)]=(select sum(cc.[остаток на дату коммуникации])from #communicationcall cc where cc.manager=r.[Коллектор (ФИО сотрудника)]	
                                                          and cc.EmployeeStage=r.Стадия and cast(cc.promiseDate as date)>=r.Дата)
   into #res_promises
from #res r


drop table if exists #res_comments
  select [Коллектор (ФИО сотрудника)]=manager
       , Стадия=EmployeeStage
       , Дата=communicationDate
       , number
       , [Количество действий (количество занесенных комментариев в дату по одному договору)]=count(distinct CommunicationDateTime )

     into #res_comments
from #communicationcall c 


where --CommunicationDate>='20191216' and 
     isnull(Commentary,'')<>''
group by 
manager,EmployeeStage,communicationDate,number

drop table if exists #res_comments1
select 
         [Коллектор (ФИО сотрудника)]
       , Стадия
       , Дата
       
       , [Количество действий (количество занесенных комментариев в дату по одному договору)]=sum( [Количество действий (количество занесенных комментариев в дату по одному договору)] )
into #res_comments1
from #res_comments 
group by 
         [Коллектор (ФИО сотрудника)]
       , Стадия
       , Дата

    --drop table if exists reports.dbo.dm_CollectionEmployeeDetails
       delete from reports.dbo.dm_CollectionEmployeeDetails --CollectionEmployeeSoftMiddle 
       where Дата>cast(format(getdate(),'yyyyMM01') as date)

    insert into  reports.dbo.dm_CollectionEmployeeDetails
    select R.[Коллектор (ФИО сотрудника)]
             , R.Стадия
             , R.Дата
             , R.[Количество клиентов в работе сотрудника]
             , R.[Количество договоров в работе сотрудника]
             , r.[Сумма договоров в работе сотрудника]
             , R.[Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]
             , R.[Количество входящих звонков]
             , R.[Количество исходящих звонков]
             , R.[Количество отправленных сообщений (СМС, е-мейл, соцсети)]
             , R.[Количество выездов]
             , R.[Количество иных действий]
             , R.[Количество контактов всего (есть результат действия контакт в системе)]
             , R.[Количество контактов с клиентом (разговор с клиентом)]
             , R.[Количество контактов с третьими лицами (разговор с третьим лицом)]
             , R.[Количество обещаний (взятых в дату)]
             , R.[Сумма обещаний (взятых в дату)]
             , R.[Сумма сохраненного баланса сотрудника]
             , R.[Сумма платежей сотрудника ]
             , [Всего обещаний сотрудника (открытых на дату)] =p.res_promises_count --, =sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then 1 else 0 end)
             , [Всего сумма обещаний сотрудника (открытых на дату)]=p.res_promises_sum--sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then PromiseSum else 0.0 end)
             , p.[Всего сумма балансов по обещаниям сотрудников (открытых на дату)]
             , R.[Сумма платежей сотрудника (любые платежи даже без обещаний)]
             , c.[Количество действий (количество занесенных комментариев в дату по одному договору)]
    --      into reports.dbo.dm_CollectionEmployeeDetails
          from #res r
          left join #res_promises p on r.[Коллектор (ФИО сотрудника)]=p.[Коллектор (ФИО сотрудника)] and r.Дата=p.Дата and r.Стадия=p.Стадия
          left join #res_comments1 c on c.[Коллектор (ФИО сотрудника)]=p.[Коллектор (ФИО сотрудника)] and c.Дата=p.Дата and c.Стадия=p.Стадия
      where r.Дата>cast(format(getdate(),'yyyyMM01') as date)
   --order by 1,2,3



 END