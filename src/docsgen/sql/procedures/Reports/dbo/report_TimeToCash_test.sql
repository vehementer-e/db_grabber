
/*
exec report_TimeToCash '20210120',null,'summary_completed','byDay' with recompile
exec report_TimeToCash_test '20210124',null,'detail','byDay' with recompile
exec report_TimeToCash null,null,'detail'
*/

CREATE     procedure [dbo].[report_TimeToCash_test] 

@dt_From datetime=null
,@dt_To datetime=null
,@report_page char(50)='detail'
,@granulation char(10)='byDay'
as
begin
--dwh-741
  set nocount on 

-- declare @dt_From datetime='20201101',@dt_To datetime=null,@report_page char(50)='detail',@granulation char(10)='byDay'

  declare @dtFrom datetime='20201101'
        , @dtTo datetime=null
        , @page char(50)='detail'


  if @granulation='byMonth'
  begin
    set @dtFrom=cast(format(isnull(@dt_from,getdate()),'yyyyMM01') as date)
    set @dtTo=dateadd(day,-1,dateadd(month,1,cast(format(isnull(@dt_to,getdate()),'yyyyMM01') as date)))
  end
  if @granulation='byDay'
  begin
    set @dtFrom=isnull(@dt_from,cast(getdate() as date))
    set @dtTo=dateadd(day,1,isnull(@dt_to,cast(getdate() as date)))
  end

  set @page=@report_page

drop table if exists #s
 select  N'Черновик' Статус, 1 rn into #s
union all select  N'Верификация КЦ', 2
union all select  N'Предварительное одобрение', 3
--union all select  N'Контроль данных', 4
union all select  N'Контроль данных Ожидание', 5
--union all select  N'Контроль данных Ждет Исполнителя', 6

union all select  N'Контроль данных Отложена', 8

union all select  N'Контроль данных В работе', 10
union all select  N'Контроль данных Выполнена', 11
union all select  N'Верификация Call 1.5', 12
union all select  N'Ожидание подписи документов EDO', 13
union all select  N'Верификация Call 2', 14
--union all select  N'Верификация клиента', 15
union all select  N'Верификация клиента Ожидание', 16
--union all select  N'Верификация клиента Ждет Исполнителя', 17
union all select  N'Верификация клиента В работе', 18
union all select  N'Верификация клиента Выполнена', 19
union all select  N'Верификация Call 3', 20
union all select  N'Одобрен клиент', 21
--union all select  N'Верификация ТС', 22
union all select  N'Верификация ТС Ожидание', 23
--union all select  N'Верификация ТС Ждет Исполнителя', 24
union all select  N'Верификация ТС В работе', 25
--union all select  N'Верификация ТС Выполнена', 26
union all select  N'Одобрено', 27
union all select  N'Договор зарегистрирован', 28
union all select  N'Договор подписан', 29
union all select  N'Заем выдан', 30

union all select 'Верификация ТС Отложена',23

--union all select 'Предварительное одобрение Ожидание',3
--union all select 'Клиент передумал'                            ,40
--union all select 'Ожидание подписи документов EDO Ожидание'    ,13
--union all select 'Одобрен клиент Ожидание'                     ,21
--union all select 'Одобрен клиент В работе'                     ,21

--union all select 'Верификация ТС Отменена'                     ,26
--union all select 'Верификация клиента Отменена'                ,19
--union all select 'Верификация Call 2 В работе'                 ,14
--union all select 'Отказано'                                    ,40
--union all select 'Одобрено Ожидание'                           ,27
union all select 'Верификация клиента Отложена'                ,19
--union all select 'Верификация Call 2 Отложена'                 ,14
--union all select 'Аннулировано'                               ,40
--union all select 'Контроль данных Отменена'                    ,11
----union all select 'Заем аннулирован Ожидание'                   ,40
--union all select 'Отказано Ожидание'                           ,40
--union all select 'Верификация Call 2 Ожидание'                 ,14
--union all select 'Заем аннулирован'                           ,40
--union all select 'Договор зарегистрирован Ожидание'            ,28
--union all select 'Верификация Call 3 Ожидание'                 ,20
--union all select 'Заем выдан Ожидание'                         ,30
--union all select 'Верификация Call 1.5 В работе'               ,12
union all select 'Итого'               ,0


/*
select [Дата заведения заявки],[Номер заявки],[Дата статуса],ВремяЗатрачено,r.Статус,rn
 --   into #details_KD 
    from dbo.dm_FedorVerificationRequests r
left join #s s on s.Статус=r.Статус
where [Дата заведения заявки]>=isnull(@dtFrom,cast(getdate() as date)) and [Дата заведения заявки]<dateadd(day,1,isnull(@dtTo,cast(getdate() as date)))
order by [Номер заявки],[Дата статуса]
*/

declare @s nvarchar(max)=N''
select @s=@s+'['+Статус+'],' from #s 
order by rn


--select @s
set @s=substring(@s,1,len(@s)-1)
--select @s


declare @fs nvarchar(max)=N''
select @fs=@fs+'['+Статус+']=format(cast(['+Статус+'] as datetime),''HH:mm:ss''),' from #s 
order by rn


--select @fs
set @fs=substring(@fs,1,len(@fs)-1)
--select @fs



declare @tsql nvarchar(max)
drop table if exists ##time_to_cash

drop table if exists #time_to_cash

declare @s_rows nvarchar(max)=N''
select @s_rows=@s_rows+'['+Статус+'] nvarchar(100),' from #s 
order by rn

drop table if exists #time_to_cash
create table #time_to_cash(
 [Номер заявки] nvarchar(50),[ФИО клиента]nvarchar(255),[Дата заведения заявки] date,[Последний статус заявки]nvarchar(100), [Время в последнем статусе] decimal(16,10) , [Время в последнем статусе, hh:mm:ss] nvarchar(50),[Время заведения] datetime
,[Итого]                                       nvarchar(100)
,[Черновик]                                    nvarchar(100)
,[Верификация КЦ]                              nvarchar(100)
,[Предварительное одобрение]                   nvarchar(100)
,[Контроль данных Ожидание]                    nvarchar(100)
,[Контроль данных Отложена]                    nvarchar(100)
,[Контроль данных В работе]                    nvarchar(100)
,[Контроль данных Выполнена]                   nvarchar(100)
,[Верификация Call 1.5]                        nvarchar(100)
,[Ожидание подписи документов EDO]             nvarchar(100)
,[Верификация Call 2]                          nvarchar(100)
,[Верификация клиента Ожидание]                nvarchar(100)
,[Верификация клиента В работе]                nvarchar(100)
,[Верификация клиента Выполнена]               nvarchar(100)
,[Верификация клиента Отложена]                nvarchar(100)
,[Верификация Call 3]                          nvarchar(100)
,[Одобрен клиент]                              nvarchar(100)
,[Верификация ТС Ожидание]                     nvarchar(100)
,[Верификация ТС Отложена]                     nvarchar(100)
,[Верификация ТС В работе]                     nvarchar(100)
,[Одобрено]                                    nvarchar(100)
,[Договор зарегистрирован]                     nvarchar(100)
,[Договор подписан]                            nvarchar(100)
,[Заем выдан]                                  nvarchar(100)



)





set @tsql='
drop table if exists ##time_to_cash
select [Номер заявки],[ФИО клиента],[Дата заведения заявки],[Последний статус заявки], [Время в последнем статусе] , [Время в последнем статусе, hh:mm:ss] ,[Время заведения],'+@fs+' 
/*into ##time_to_cash */

from (

select [Номер заявки],[ФИО клиента],[Дата заведения заявки],[Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]  ,[Время заведения],'+@s+'
from(
select [Номер заявки],[ФИО клиента],[Дата заведения заявки],[Последний статус заявки], [Время в последнем статусе] , [Время в последнем статусе, hh:mm:ss] ,[Время заведения]=cast([Время заведения] as datetime),ВремяЗатрачено,r.Статус+N'' ''+case when [Состояние заявки] in (''Статус изменен'') then '''' else [Состояние заявки] end  Статус
 --   into #details_KD 
    from dbo.dm_FedorVerificationRequests r
--left join #s s on s.Статус=r.Статус
where''21012400072618''=[Номер заявки] and [Дата заведения заявки]>='''+format(isnull(@dtFrom,cast(getdate() as date)),'yyyy-MM-dd')+''' and [Дата заведения заявки]<'''+format(dateadd(day,1,isnull(@dtTo,cast(getdate() as date))),'yyyy-MM-dd')+'''
union all 

select [Номер заявки],[ФИО клиента],[Дата заведения заявки],[Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]  ,[Время заведения]=cast([Время заведения] as datetime),sum(ВремяЗатрачено) ВремяЗатрачено,''Итого'' Статус
 --   into #details_KD 
    from dbo.dm_FedorVerificationRequests r
--left join #s s on s.Статус=r.Статус
where ''21012400072618''=[Номер заявки] and [Дата заведения заявки]>='''+format(isnull(@dtFrom,cast(getdate() as date)),'yyyy-MM-dd')+''' and [Дата заведения заявки]<'''+format(dateadd(day,1,isnull(@dtTo,cast(getdate() as date))),'yyyy-MM-dd')+'''
group by  [Номер заявки],[ФИО клиента],[Дата заведения заявки],[Время заведения],[Последний статус заявки], [Время в последнем статусе] , [Время в последнем статусе, hh:mm:ss] 
) p
pivot 
(
sum(ВремяЗатрачено)
for Статус in ('+@s+')
) pvt

)
q

'
--select(@tsql)
insert into #time_to_cash exec (@tsql)


--select * from #time_to_cash where [Договор подписан] is  not null

--drop table devdb.dbo.time_to_cash


  if @page='detail' 
    select distinct cash.*
         , [клиентское время] = cast(isnull([Предварительное одобрение]                 ,'00:00:00') as datetime)
                              + cast(isnull([Контроль данных Отложена]                  ,'00:00:00') as datetime)
                              + cast(isnull([Ожидание подписи документов EDO]           ,'00:00:00') as datetime)
                              + cast(isnull([Одобрен клиент]                            ,'00:00:00') as datetime)
                              + cast(isnull([Верификация ТС Отложена]                   ,'00:00:00') as datetime)
                              + cast(isnull([Одобрено]                                  ,'00:00:00') as datetime)
                              + cast(isnull([Договор зарегистрирован]                   ,'00:00:00') as datetime)
                              + cast(isnull([Договор подписан]                          ,'00:00:00') as datetime)
                              + cast(isnull([Верификация клиента Отложена]              ,'00:00:00') as datetime)
                              
          , [системное время] = cast(isnull([Верификация Call 3]                        ,'00:00:00') as datetime)
                              + cast(isnull([Верификация клиента Выполнена]             ,'00:00:00') as datetime)
                              + cast(isnull([Верификация Call 2]                        ,'00:00:00') as datetime)
                              + cast(isnull([Верификация Call 1.5]                      ,'00:00:00') as datetime)
                              + cast(isnull([Контроль данных Выполнена]                 ,'00:00:00') as datetime)
                              + cast(isnull([Верификация КЦ]                            ,'00:00:00') as datetime)
                            

    , [верификационное время] = cast(isnull([Черновик]                                  ,'00:00:00') as datetime)
                              + cast(isnull([Контроль данных В работе]                  ,'00:00:00') as datetime)
                              + cast(isnull([Контроль данных Ожидание]                  ,'00:00:00') as datetime)
                              + cast(isnull([Верификация клиента Ожидание]              ,'00:00:00') as datetime)
                              + cast(isnull([Верификация клиента В работе]              ,'00:00:00') as datetime)
                              + cast(isnull([Верификация ТС Ожидание]                   ,'00:00:00') as datetime)
                              + cast(isnull([Верификация ТС В работе]                   ,'00:00:00') as datetime)
                            







      from #time_to_cash cash 
     order by [Дата заведения заявки],cash.[Время заведения]
     
 if @page='summary'  or @page ='summary_completed' 
 begin
 drop table if exists #p
 select [Дата заведения заявки],Показатель,cnt
 ,КатегорияПоказателя=case when Показатель in ('Предварительное одобрение','Контроль данных Отложена','Ожидание подписи документов EDO','Одобрен клиент','Верификация ТС Отложена','Одобрено','Договор зарегистрирован','Договор подписан','Верификация клиента Отложена'   )
                           then 'клиентское время'
                           when Показатель in( 'Верификация Call 3','Верификация клиента Выполнена','Верификация Call 2','Верификация Call 1.5','Контроль данных Выполнена','Верификация КЦ')
                           then 'системное время'
                           when Показатель in ('Черновик','Контроль данных В работе','Контроль данных Ожидание','Верификация клиента Ожидание','Верификация клиента В работе','Верификация ТС Ожидание','Верификация ТС В работе')
                           then 'верификационное время'
                      end


 into #p
 from (
 select [Дата заведения заявки],
  
 КоличествоЗаявок=cast(КоличествоЗаявок as nvarchar(50))
 , [Черновик]                           =  cast(format(cast([Черновик]                         as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация КЦ]                     =  cast(format(cast([Верификация КЦ]                   as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Предварительное одобрение]          =  cast(format(cast([Предварительное одобрение]        as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Контроль данных Ожидание]           =  cast(format(cast([Контроль данных Ожидание]         as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Контроль данных Отложена]           =  cast(format(cast([Контроль данных Отложена]         as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Контроль данных В работе]           =  cast(format(cast([Контроль данных В работе]         as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Контроль данных Выполнена]          =  cast(format(cast([Контроль данных Выполнена]        as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация Call 1.5]               =  cast(format(cast([Верификация Call 1.5]             as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Ожидание подписи документов EDO]    =  cast(format(cast([Ожидание подписи документов EDO]  as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация Call 2]                 =  cast(format(cast([Верификация Call 2]               as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация клиента Ожидание]       =  cast(format(cast([Верификация клиента Ожидание]     as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация клиента В работе]       =  cast(format(cast([Верификация клиента В работе]     as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация клиента Выполнена]      =  cast(format(cast([Верификация клиента Выполнена]    as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация клиента Отложена]       =  cast(format(cast([Верификация клиента Отложена]     as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация Call 3]                 =  cast(format(cast([Верификация Call 3]               as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Одобрен клиент]                     =  cast(format(cast([Одобрен клиент]                   as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация ТС Ожидание]            =  cast(format(cast([Верификация ТС Ожидание]          as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация ТС Отложена]            =  cast(format(cast([Верификация ТС Отложена]          as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Верификация ТС В работе]            =  cast(format(cast([Верификация ТС В работе]          as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , Одобрено                             =  cast(format(cast(Одобрено                           as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Договор зарегистрирован]            =  cast(format(cast([Договор зарегистрирован]          as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , [Договор подписан]                   =  cast(format(cast([Договор подписан]                 as datetime)  ,'HH:mm:ss')as nvarchar(50))
-- , [Заем выдан]                         =  cast(format(cast([Заем выдан]                       as datetime)  ,'HH:mm:ss')as nvarchar(50))
 , Итого                              =   cast(format(cast(case when КоличествоЗаявок<>0 then ( [Черновик]                       
                                           + isnull([Верификация КЦ]                 ,0)
                                           + isnull([Предварительное одобрение]      ,0)
                                           + isnull([Контроль данных Ожидание]       ,0)
                                           + isnull([Контроль данных Отложена]       ,0)
                                           + isnull([Контроль данных В работе]       ,0)
                                           + isnull([Контроль данных Выполнена]      ,0)
                                           + isnull([Верификация Call 1.5]           ,0)
                                           + isnull([Ожидание подписи документов EDO],0)
                                           + isnull([Верификация Call 2]             ,0)
                                           + isnull([Верификация клиента Ожидание]   ,0)
                                           + isnull([Верификация клиента В работе]   ,0)
                                           + isnull([Верификация клиента Выполнена]  ,0)
                                           + isnull([Верификация клиента Отложена]   ,0)
                                           + isnull([Верификация Call 3]             ,0)
                                           + isnull([Одобрен клиент]                 ,0)
                                           + isnull([Верификация ТС Ожидание]        ,0)
                                           + isnull([Верификация ТС Отложена]        ,0)
                                           + isnull([Верификация ТС В работе]        ,0)
                                           + isnull(Одобрено                         ,0)
                                           + isnull([Договор зарегистрирован]        ,0)
                                       --    + isnull([Договор подписан]               ,0)
                                            ) else 0 end      as datetime)  ,'HH:mm:ss')as nvarchar(50))              
 
 
 
 from(
  select 
    [Дата заведения заявки]=case when @granulation='byMonth' then format( [Дата заведения заявки],'yyyyMM01') else  [Дата заведения заявки] end
  , format(count(distinct [Номер заявки]),'0')                                                                                              КоличествоЗаявок
  , avg(cast(cast([Черновик]                               as datetime)as decimal(15,10)) )  [Черновик]      
  , avg(cast(cast([Верификация КЦ]                         as datetime)as decimal(15,10)) )  [Верификация КЦ]      
  , avg(cast(cast([Предварительное одобрение]              as datetime)as decimal(15,10)) )  [Предварительное одобрение]      
  , avg(cast(cast([Контроль данных Ожидание]               as datetime)as decimal(15,10)) )  [Контроль данных Ожидание]       
  , avg(cast(cast([Контроль данных Отложена]               as datetime)as decimal(15,10)) )  [Контроль данных Отложена]       
  , avg(cast(cast([Контроль данных В работе]               as datetime)as decimal(15,10)) )  [Контроль данных В работе]       
  , avg(cast(cast([Контроль данных Выполнена]              as datetime)as decimal(15,10)) )  [Контроль данных Выполнена]      
  , avg(cast(cast([Верификация Call 1.5]                   as datetime)as decimal(15,10)) )  [Верификация Call 1.5]           
  , avg(cast(cast([Ожидание подписи документов EDO]        as datetime)as decimal(15,10)) )  [Ожидание подписи документов EDO]
  , avg(cast(cast([Верификация Call 2]                     as datetime)as decimal(15,10)) )  [Верификация Call 2]             
  , avg(cast(cast([Верификация клиента Ожидание]           as datetime)as decimal(15,10)) )  [Верификация клиента Ожидание]   
  , avg(cast(cast([Верификация клиента В работе]           as datetime)as decimal(15,10)) )  [Верификация клиента В работе]   
  , avg(cast(cast([Верификация клиента Выполнена]          as datetime)as decimal(15,10)) )  [Верификация клиента Выполнена]  
  , avg(cast(cast([Верификация клиента Отложена]           as datetime)as decimal(15,10)) )  [Верификация клиента Отложена]   
  , avg(cast(cast([Верификация Call 3]                     as datetime)as decimal(15,10)) )  [Верификация Call 3]             
  , avg(cast(cast([Одобрен клиент]                         as datetime)as decimal(15,10)) )  [Одобрен клиент]                 
  , avg(cast(cast([Верификация ТС Ожидание]                as datetime)as decimal(15,10)) )  [Верификация ТС Ожидание]        
  , avg(cast(cast([Верификация ТС Отложена]                as datetime)as decimal(15,10)) )  [Верификация ТС Отложена]        
  , avg(cast(cast([Верификация ТС В работе]                as datetime)as decimal(15,10)) )  [Верификация ТС В работе]        
  , avg(cast(cast(Одобрено                                 as datetime)as decimal(15,10)) )  Одобрено                         
  , avg(cast(cast([Договор зарегистрирован]                as datetime)as decimal(15,10)) )  [Договор зарегистрирован]        
  , avg(cast(cast([Договор подписан]                       as datetime)as decimal(15,10)) )  [Договор подписан]               
 -- , avg(cast(cast([Заем выдан]                             as datetime)as decimal(15,10)) )  [Заем выдан]                     
  from #time_to_cash cash where 
  case when @page='summary_completed' and  [Договор подписан] is  not null then 1 
       when @page='summary' then 1 
  else 0 end =1
  group by  case when @granulation='byMonth' then format( [Дата заведения заявки],'yyyyMM01') else  [Дата заведения заявки] end
) p
)p1
UNPIVOT  
   (cnt FOR Показатель IN   
      (
        КоличествоЗаявок
        
       ,[Черновик]      
       ,[Верификация КЦ]
       ,[Предварительное одобрение]      
       ,[Контроль данных Ожидание]       
       ,[Контроль данных Отложена]       
       ,[Контроль данных В работе]       
       ,[Контроль данных Выполнена]      
       ,[Верификация Call 1.5]           
       ,[Ожидание подписи документов EDO]
       ,[Верификация Call 2]             
       ,[Верификация клиента Ожидание]   
       ,[Верификация клиента В работе]   
       ,[Верификация клиента Выполнена]  
       ,[Верификация клиента Отложена]   
       ,[Верификация Call 3]             
       ,[Одобрен клиент]                 
       ,[Верификация ТС Ожидание]        
       ,[Верификация ТС Отложена]        
       ,[Верификация ТС В работе]        
       ,Одобрено                         
       ,[Договор зарегистрирован]        
       ,[Договор подписан]               
     --  ,[Заем выдан] 
       , Итого
      )  
)AS unpvt; 
select 
rn=isnull(rn,0),p.*  
from #p p left  join #s s on p.Показатель=s.Статус 
order by p.[Дата заведения заявки], isnull(rn,0)

end

end
