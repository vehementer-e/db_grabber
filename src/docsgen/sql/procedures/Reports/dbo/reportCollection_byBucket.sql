
--exec [dbo].[reportCollection_byBucket] 

CREATE      PROCEDURE [dbo].[reportCollection_byBucket] 
AS
BEGIN
	SET NOCOUNT ON;
  
  /*
Дата
Бакет  (1-30; 31-60; 61-90; 91-360; 360+)
Количество договоров в бакете +
Сумма баланса по договорам в бакете (сумма остатков займа)
Сумма просроченной задолженности в бакете (просроченный долг)
Сумма просроченных процентов в бакете
Сумма пеней в бакете
Итоговая сумма просрочки в бакете (сумма трех предпоследних значений)
*/
  declare 
	        @dtTo date,
		      @stage nvarchar(255) 
  
  declare @dtFrom date
  set @dtFrom = cast(format(getdate(),'yyyyMM01') as date)
  set @dtTo = cast(getdate() as date)
  set @dtFrom='20190101'
--  select  @dtFrom, @dtTo

--  select * from #employee_stage

/*
  drop table if exists #deals
  ; with d as (
  select *
  ,rn=row_number() over(partition by id order by updatedate desc)
  from [Stg].[_Collection].[Deals] d                   
  )
  select * into #deals from d where rn=1
  */
  /*

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
    join #deals d on d.Number=r.CMRContractNumber
	 where cast(c.[BindingDate] as date) > = @dtFrom and isHistory=0
    order by bindingdate,NaumenOperatorLogin
    */
drop table if exists #EmployeeCustomerContractWithBucket
select * 
/*
  , bucket=
            case when dpd > 0   and dpd <= 30  --and tmax_dpd.max_dpd <= 90 
                  then '(1)_1_30'
			           when dpd >= 31  and dpd <= 60 -- and tmax_dpd.max_dpd <= 90 
                  then '(2)_31_60'
			           when dpd >= 61  and dpd <= 90  --and tmax_dpd.max_dpd <= 90 
                  then '(3)_61_90'
			           when dpd >= 91  and dpd <= 360                   
                  then '(4)_91_360'
			           when dpd >= 360                                    
                  then '(5)_361+'
                  when dpd = 0
                  then 'PreDel'
                 --when   dpd=0 then 'Pre-Del'
                  /*
				         when overdue_days_p <= 90  and tmax_dpd. max_dpd > 90                   
                  then '(6)_0_90_hard'
                  */
				         else '(7)_Other' 
             end
             */
into #EmployeeCustomerContractWithBucket
from dwh2.dbo.[dm_CMRStatBalance]       b 
where b.Период> = @dtFrom  and  b.Период<= @dtTo
	and b.[Тип Продукта] = 'ПТС'

--drop table if exists dm_reportCollection_byBucket
--DWH-1764 
TRUNCATE TABLE dbo.dm_reportCollection_byBucket
	INSERT dbo.dm_reportCollection_byBucket
	(
		Период,
		bucket,
		[Количество договоров в бакете],
		[Сумма баланса по договорам в бакете (сумма остатков займа)],
		[Сумма просроченной задолженности в бакете (просроченный долг)],
		[Сумма пеней в бакете],
		[Сумма просроченных процентов в бакете],
		[Итоговая сумма просрочки в бакете (сумма трех предпоследних значений)]
	)
    select b.Период
         , bucket
         , [Количество договоров в бакете]=count(distinct b.external_id)
         , [Сумма баланса по договорам в бакете (сумма остатков займа)]=sum(b.[остаток всего])
         , [Сумма просроченной задолженности в бакете (просроченный долг)]=sum(b.[основной долг начислено нарастающим итогом]-b.[основной долг уплачено нарастающим итогом])
         
         , [Сумма пеней в бакете]=sum(b.[ПениНачислено  нарастающим итогом]-b.[ПениУплачено  нарастающим итогом])
         , [Сумма просроченных процентов в бакете]=sum(b.[Проценты начислено  нарастающим итогом]-b.[Проценты уплачено  нарастающим итогом])
         , [Итоговая сумма просрочки в бакете (сумма трех предпоследних значений)]=
           sum(b.[основной долг начислено нарастающим итогом]-b.[основной долг уплачено нарастающим итогом])+
           sum(b.[ПениНачислено  нарастающим итогом]-b.[ПениУплачено  нарастающим итогом])+
           sum(b.[Проценты начислено  нарастающим итогом]-b.[Проценты уплачено  нарастающим итогом])
      --into dbo.dm_reportCollection_byBucket
      from #EmployeeCustomerContractWithBucket b
     group by Период,bucket
     order by bucket,Период



 END
