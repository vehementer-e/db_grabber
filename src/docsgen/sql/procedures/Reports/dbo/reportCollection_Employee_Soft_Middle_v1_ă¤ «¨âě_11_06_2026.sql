
--exec [dbo].[reportCollection_Employee_Soft_Middle_v1] 
CREATE    PROCEDURE [dbo].[reportCollection_Employee_Soft_Middle_v1] 
AS
BEGIN
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

  set @dtFrom = cast(format(getdate(),'yyyyMM01') as date)
  set @dtTo = cast(getdate() as date)

--  select  @dtFrom, @dtTo


  drop table if exists #employee_stage

  select e.[Id] as EmployeeID 
       , ([LastName]+' '+[FirstName]+' '+[MiddleName]) fio_empl 
       , [NaumenUserLogin] 
       , CollectingStageId 
       , s.[Name] NameStage 
       , [ExtensionNumber]
    into #employee_stage 
    FROM stg._Collection.[Employee] e
   join stg._Collection.EmployeeCollectingStage ECS ON ECS. EmployeeId=E.ID
   join stg._Collection.[CollectingStage] s on eCS.CollectingStageId=s.id
   where s.[Name] in (N'Soft' ,N'Middle') 

--  select * from #employee_stage


  drop table if exists #deals
  ; with d as (
  select *
  ,rn=row_number() over(partition by id order by updatedate desc)
  from [Stg].[_Collection].[Deals] d                   
  )
  select * into #deals from d where rn=1


  --select * from #deals where number='19040807660002'



  drop table if exists #communicationcall
  select distinct
         com.CommunicationType
       , id_1 
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
       , com.PersonType

			 , [IdDeal] 
			 , EmployeeId
			 , [CallId] 
			 , [EndCallDt] 
       , [CommunicationResultId] 
       , CommunicationResult 
			 , [PaymentPromiseId] 
			 , fio
			 , CrmCustomerId
			 , [EmployeeStage]
       , b.[остаток од] [остаток на дату коммуникации]
       , ptp_b.[остаток од] [остаток на дату обещания]
       , b.overdue [задолжность на дату коммуникации]
       , ptp_b.overdue [задолжность на дату обещания]
       ,col.success_PTP
       ,col.succes_partial_ptp
       ,col.ptpDateBalance
       ,col.СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания
	  into #communicationcall		-- select *
    from [Stg].[_Collection].[v_Communications]  com            with (nolock) 
    left join  #Deals d with (nolock) on d.id=IdDeal --and cast(com.[Date] as date)=cast(d.[UpdateDate] as date)
    /*
    left join [Stg].[_Collection].[CommunicationResult] res   with (nolock) on res.id=com.CommunicationResultId
    
    left join [Stg].[_Collection].[customers] cust            with (nolock) on cust.id=IdCustomer
    left join [Stg].[_Collection].[ContactPersonType] pt      with (nolock) on  pt.[Id]=[ContactPersonType]
    left join [Stg].[_Collection].[Employee] e                with (nolock) on com.EmployeeId=e.Id
    left join [Stg].[_Collection].[EmployeecollectingStage] ecs         with (nolock) on ecs.EmployeeId =e.Id
    left join [Stg].[_Collection].[collectingStage] s         with (nolock) on s.Id=ecs.CollectingStageId
*/    
    left join  [dbo].[dm_CMRStatBalance_2] b on  com.Number=b.external_id  and cast(com.[Date] as date)=b.Период
    left join  [dbo].[dm_CMRStatBalance_2] ptp_b on  com.Number=ptp_b.external_id  and com.PromiseDate=ptp_b.Период
    left join collection.[dm_CollectionKPIByMonth] col on col.дата=cast(com.[Date] as date) and col.НомерДоговора=com.Number and col.Сотрудник=com.Manager
   where com.[Date] >= @dtFrom and com.EmployeeID in (select EmployeeID from #employee_stage)



   /*
select distinct * from #communicationcall where CommunicationDate>='20191210'
and Manager='Михайлова Лилия Викторовна'
order by CommunicationDate,number,CommunicationDateTime
*/
/*
drop table if exists #statBalance
select * into #statBalance from [dbo].[dm_CMRStatBalance] b
join (select distinct number,CommunicationDate from  #communicationcall) d on d.Number=b.external_id  and d.CommunicationDate=b.Период
*/

/*
select * from [dbo].[dm_CMRStatBalance]
where external_id='19110810000199'
select  * from #communicationcall where number='19110810000199' order by CommunicationDate,number,CommunicationDateTime
*/
/*
select * from [dbo].[dm_CollectionKPIByMonth] where НомерДоговора='19110810000199'
order by 1

*/
--select  ДатаОкончания-ДатаНачалаЗамера,*  from [c1-vsr-sql04].crm.dbo.РегистрСведений_ЗамерыВремени


drop table if exists #res
  select [Коллектор (ФИО сотрудника)]=manager
       , Стадия=EmployeeStage
       , Дата=communicationDate
        --number
       , [Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]=count(*)--count(distinct CommunicationDateTime )
-- по клиенту
       , [Количество входящих звонков]=count (distinct case when CommunicationType='Входящий звонок' then CommunicationDateTime else null end) 
       , [Количество исходящих звонков]=count (distinct case when CommunicationType='Исходящий звонок' then CommunicationDateTime else null end)
       , [Количество отправленных сообщений (СМС, е-мейл, соцсети)] =count (distinct case when CommunicationType in ('Смс','Мессенджеры','Соц. сети') then CommunicationDateTime else null end)
       , [Количество иных действий]=count (distinct case when CommunicationType not in ('Входящий звонок','Исходящий звонок','Смс','Мессенджеры','Соц. сети') then CommunicationDateTime else null end)
       , [Количество контактов всего (есть результат действия контакт в системе)]=count (distinct case when PersonType<>'Нет контакта' then CommunicationDateTime else null end)
       , [Количество контактов с клиентом (разговор с клиентом)]=count(distinct case when PersonType='Клиент' then CommunicationDateTime else null end)
       , [Количество контактов с третьими лицами (разговор с третьим лицом)]=count(distinct case when PersonType='Третье лицо' then CommunicationDateTime else null end)
-- по договору       
       , [Количество обещаний (взятых в дату)]=sum(case when CommunicationResult='Обещание оплатить' then 1 else 0 end)
       , [Сумма обещаний (взятых в дату)]=sum(case when CommunicationResult='Обещание оплатить' then PromiseSum else 0.0 end)
--       , [Всего обещаний сотрудника (открытых на дату)] =null --, =sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then 1 else 0 end)
 --      , [Всего сумма обещаний сотрудника (открытых на дату)]=null--sum(case when CommunicationResult='Обещание оплатить' and cast(promiseDate as date)>=communicationDate then PromiseSum else 0.0 end)
       , [Сумма сохраненного баланса сотрудника]=sum(case when success_ptp=1        then [остаток на дату обещания] else 0 end)
       , [Сумма платежей сотрудника ]=sum(case when succes_partial_ptp=1        then СуммаПлатежейМеждуДатойВзятияОбещанияИДатойОбещания else 0 end)
     --  ,c=count(*)
       into #res
from #communicationcall --where CommunicationDate>='20191216'
group by 
manager,EmployeeStage,communicationDate--,number





drop table if exists #res_promises
  select * 
        , res_promises_count= (select sum(1) from #communicationcall cc where cc.manager=r.[Коллектор (ФИО сотрудника)]	
                                                          and cc.EmployeeStage=r.Стадия and cast(cc.promiseDate as date)>=r.Дата)

        , res_promises_sum= (select sum(promiseSum) from #communicationcall cc where cc.manager=r.[Коллектор (ФИО сотрудника)]	
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
from #communicationcall where --CommunicationDate>='20191216' and 
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

    
       delete from dbo.dm_CollectionEmployeeSoftMiddle where Дата>cast(format(getdate(),'yyyyMM01') as date)

    insert into  dbo.dm_CollectionEmployeeSoftMiddle
    select R.[Коллектор (ФИО сотрудника)]
             , R.Стадия
             , R.Дата
             , R.[Количество обработанных счетов (зафиксировано хотя бы одно действие в Space)]
             , R.[Количество входящих звонков]
             , R.[Количество исходящих звонков]
             , R.[Количество отправленных сообщений (СМС, е-мейл, соцсети)]
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
             , c.[Количество действий (количество занесенных комментариев в дату по одному договору)]
          
          from #res r
          left join #res_promises p on r.[Коллектор (ФИО сотрудника)]=p.[Коллектор (ФИО сотрудника)] and r.Дата=p.Дата and r.Стадия=p.Стадия
          left join #res_comments1 c on c.[Коллектор (ФИО сотрудника)]=p.[Коллектор (ФИО сотрудника)] and c.Дата=p.Дата and c.Стадия=p.Стадия
          where r.Дата>cast(format(getdate(),'yyyyMM01') as date)



 END
