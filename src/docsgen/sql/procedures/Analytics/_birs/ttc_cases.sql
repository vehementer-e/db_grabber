
CREATE      PROC-- exec
[_birs].[ttc_cases] 
@number_of_days_updated int = 3	,
@debug int = 0

as 
begin



declare  @start_date date = cast(getdate()-@number_of_days_updated as date)
--declare  @start_date date = '20240425'	declare @debug int = 1
--declare  @start_date date = getdate()-1	declare @debug int = 1
--declare  @start_date date = getdate()-0	declare @debug int = 1

--exec  [_gsheets].[load_google_sheet_to_DWH] 'dic_Проекты NAUMEN'	 
--  declare  @debug int =1 declare  @start_date date = dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01') as date))

--declare  @start_date date = '20221201'
--select min(Date) from report_TTC_on_projects2

--declare  @start_date date = cast(getdate()-2 as date)
 --declare @debug int = 0


 if   DATENAME(dw, getdate())='sunday'
  begin

 set @start_date = getdate()-7

 end

 if day(getdate())=1
 begin

	--set @start_date = '20191001'
	--DWH-1937
	SELECT @start_date =  getdate()-40

 end
drop table if exists #Справочник

--	SELECT @start_date = '20240501'


CREATE TABLE [dbo].[#Справочник]
(
      [projectid] [VARCHAR](32)
    , [Проект] [VARCHAR](62)
    , [НазваниеПроектаДляОтчета] [VARCHAR](100)
    , [ЧасСтартаКампанииПоМск] [BIGINT]
    , [ЧасОкончанияКампанииПоМск] [BIGINT]
    , [ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние] [BIGINT]
    , [ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные] [BIGINT]
    , [ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние] [BIGINT]
    , [ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные] [BIGINT]
    , [НужнаДетализация] [VARCHAR](1)
);



insert into #Справочник

select 
    a.[projectid] 
,   a.[Проект] 
,   a.[Название проекта для отчета] 
,   a.[ЧасСтартаКампанииПоМск]    *3600000	  [MSC Старт кампании]
,   a.[ЧасОкончанияКампанииПоМск] *3600000-10 [MSC Окончание кампании]	 
,   a.[ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние] 	    *3600000	 [MSC Старт клиент может говорить будние]
,   a.[ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные] 	*3600000  [MSC Старт клиент может говорить выходные]
,   a.[ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние]     *3600000-10	 [MSC Окончание клиент может говорить будние]
,   a.[ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные] 	*3600000-10  [MSC Окончание клиент может говорить выходные]
,   a.[НужнаДетализация] 		--select *
from 
analytics._gsheets.[v_dic_Проекты TTC] a


--select * from  #Справочник
--except
-- 
--
--select * from #Справочник
--order by 1
--exec select_table '#Справочник'
--exec select_table 'analytics._gsheets.[dic_Проекты NAUMEN]'


--select * from report_TTC_on_projects
--order by 1

SET DATEFIRST 1;
drop table if exists #t1, #t2,#itog, #final_for_ins, #final_for_ins_1
;
;
with ft as (
select min(dos.attempt_start) first_try
,min(case when login is not null then  dos.attempt_start end) first_suc_try
,min(   cl.connected ) connected
,      count(case when attempt_result='abandoned' and queue_time >0 and [login] is null then 1 end) abandoned_calls_count
, max(case when dos.login is not null and dos.attempt_number=1 then 1 when  dos.attempt_number=1 then 0  end) 	[first_call_success]
, dos.case_uuid
from  [NaumenDbReport].[dbo].[detail_outbound_sessions] dos with(nolock)
left join  [NaumenDbReport].[dbo].[call_legs] cl  with(nolock) on dos.session_id=cl.session_id and cl.leg_id=1
----DWH-1937
INNER JOIN [NaumenDbReport].[dbo].[mv_call_case] AS cc
	ON cc.uuid = dos.case_uuid
INNER JOIN #Справочник AS s 
	ON s.projectid = cc.projectuuid
	AND cc.creationdate >= @start_date
group by dos.case_uuid
)



select cast(cc.uuid as varchar(40))  id
,      cast(cc.creationdate as datetime2(7))              creationdate
,      ft.first_try                  called_at
,      ft.first_suc_try              called_suc_at
,      cast(null as datetime2)       UF_REGISTERED_AT
,      projecttitle                  projecttitle
,      isnull(timezone, 'GMT+03:00') timezone
,      cast(null as nvarchar(30))    Заявка
,     projectuuid
,     abandoned_calls_count
,     case when connected is not null then 1 else 0 end as [connected]
,    [first_call_success]
	into #t1
from      [NaumenDbReport].[dbo].[mv_call_case] cc --
with(nolock)
left join ft                                          on ft.case_uuid=cc.uuid
join #Справочник s on s.projectid=cc.projectuuid-- and s.источник='cc'
and cc.creationdate>=@start_date



drop table if exists #itog
select 
id
,creationdate
,called_at
,called_suc_at
,UF_REGISTERED_AT
--,projecttitle
,isnull(timezone, 'GMT+03:00') timezone
,Заявка
,projectuuid
,abandoned_calls_count
, connected
, [first_call_success]

into #itog
from #t1






drop table if exists #final_for_ins
drop table if exists #final_for_ins_1
;
with справочник as (

select НазваниеПроектаДляОтчета Проект
,projectid
, cast(ЧасСтартаКампанииПоМск                           as bigint)  ЧасСтартаКампанииПоМск                              
, cast(ЧасОкончанияКампанииПоМск 						as bigint)  ЧасОкончанияКампанииПоМск 						
, cast(ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние 		as bigint)  ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние 		
, cast(ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные 	as bigint)  ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные 	
, cast(ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние 		as bigint)  ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние 		
, cast(ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные  	as bigint)  ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные  	
, cast(НужнаДетализация 								as bigint)  НужнаДетализация 								
from (
select * from #Справочник
) x
)
, itog
as (

select *
, dateadd(hour, -3+cast(right(left(timezone, 6),2) as int), a.creationdate) МестноеВРемя
, cast(cast(dateadd(hour, -3+cast(right(left(timezone, 6),2) as int), a.creationdate)as date) as datetime) МестноеВРемя_dt_dttime
, cast(cast(creationdate as date) as datetime) [creationdate_dt_dttime]
, 3-cast(right(left(timezone, 6),2) as int) СмещениеЧасов
from #itog a  join справочник s on a.projectuuid=s.projectid
)

,  itog_v
as (

select 
id
, cc.creationdate created_at
, called_at
, UF_REGISTERED_AT
, called_suc_at
, Заявка
--, ft.first_try called_at
, Проект projecttitle
, timezone
,
 МестноеВРемя,
dateadd(MILLISECOND, ЧасСтартаКампанииПоМск , [creationdate_dt_dttime])  as ДатаСтартаКампанииПоМск,

dateadd(MILLISECOND, ЧасОкончанияКампанииПоМск ,[creationdate_dt_dttime]) as ДатаОкончанияКампанииПоМск,

dateadd(day, 1,  dateadd(MILLISECOND, ЧасСтартаКампанииПоМск , [creationdate_dt_dttime]) )  as ДатаСтартаКампанииПоМскВСледующийДень,

case 
when datepart(dw, МестноеВРемя) in (1,2,3,4,5) then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние , МестноеВРемя_dt_dttime) )
when datepart(dw, МестноеВРемя) in(6,7)        then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные , МестноеВРемя_dt_dttime) ) 	 
end	 

as ВремяПоМскСКОторогоКЛиентМожетГоворить,

case 
when datepart(dw, МестноеВРемя) in (1,2,3,4,5) then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние , МестноеВРемя_dt_dttime) )
when datepart(dw, МестноеВРемя) in(6,7) then       dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные , МестноеВРемя_dt_dttime) ) end 	

as ВремяПоМскДоКОторогоКЛиентМожетГоворить,

case 
when datepart(dw, МестноеВРемя) in (7,1,2,3,4) then dateadd(day, 1, dateadd(hour, СмещениеЧасов, dateadd(MILLISECOND, ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние , МестноеВРемя_dt_dttime)  ))
when datepart(dw, МестноеВРемя)  in(5,6) then dateadd(day, 1, dateadd(hour, СмещениеЧасов, dateadd(MILLISECOND, ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные , МестноеВРемя_dt_dttime)  ))
end   	 
as ВремяПоМскНаСледДеньСКОторогоКЛиентМожетГоворить
, НужнаДетализация
,projectuuid
,abandoned_calls_count
, connected
, [first_call_success]

	 from


itog cc --where creationdate>=getdate()-2--cast(format(dateadd(month, -1, getdate()), 'yyyyMM01') as date) 
 -- order by created_at

 )
 , itog_v_
 as
 (
 select 
 *
 , case when itog_v.created_at<=itog_v.ДатаСтартаКампанииПоМск then 1 else 0 end [Создан не позже чем старт кампании]
 , case when itog_v.created_at>=itog_v.ДатаОкончанияКампанииПоМск then 1 else 0 end [Создан не раньше чем окончание кампании]
 , case when itog_v.created_at<=itog_v.ВремяПоМскСКОторогоКЛиентМожетГоворить then 1 else 0 end [Создан до момента когда удобно говорить]
 , case when itog_v.created_at>=itog_v.ВремяПоМскДоКОторогоКЛиентМожетГоворить then 1 else 0 end [Создан после момента когда удобно говорить]
 from itog_v
 )
 , itog_v__
 as
 (
 select 
 *
 , 
 case when [Создан не позже чем старт кампании] = 1 then itog_v.ДатаСтартаКампанииПоМск  
                 when  [Создан не раньше чем окончание кампании]=1 then ДатаСтартаКампанииПоМскВСледующийДень
				 else created_at end УдобныйСтартКампаниии
, 
 case when [Создан до момента когда удобно говорить]=1 then itog_v.ВремяПоМскСКОторогоКЛиентМожетГоворить  
                 when  [Создан после момента когда удобно говорить]=1 then ВремяПоМскНаСледДеньСКОторогоКЛиентМожетГоворить
				 else created_at end УдобноеВремяКлиенту
				 from itog_v_ itog_v
 )


  , itog_v_v as (
  select 
  id
,  created_at
, called_at
, UF_REGISTERED_AT
, called_suc_at
, Заявка
, projecttitle
, timezone
, МестноеВРемя
, ДатаСтартаКампанииПоМск
, ДатаОкончанияКампанииПоМск
, ДатаСтартаКампанииПоМскВСледующийДень
, ВремяПоМскСКОторогоКЛиентМожетГоворить
, ВремяПоМскДоКОторогоКЛиентМожетГоворить
, ВремяПоМскНаСледДеньСКОторогоКЛиентМожетГоворить
, 
  case when
  case when  УдобныйСтартКампаниии >= УдобноеВремяКлиенту
 then УдобныйСтартКампаниии
  else УдобноеВремяКлиенту    end  
  
  
  between ДатаОкончанияКампанииПоМск and ДатаСтартаКампанииПоМскВСледующийДень then 
								 -------------------------
								 ДатаСтартаКампанииПоМскВСледующийДень
								 -------------------------
       else 

 case when  УдобныйСтартКампаниии >= УдобноеВремяКлиенту
 then УдобныйСтартКампаниии
  else УдобноеВремяКлиенту    end 
				 end crd


,case when created_at between ДатаСтартаКампанииПоМск and ДатаОкончанияКампанииПоМск
--and created_at between ВремяПоМскСКОторогоКЛиентМожетГоворить and ВремяПоМскДоКОторогоКЛиентМожетГоворить 
and format( cast (created_at as date) , 'dd.MM')<>'01.01'  then 1 else 0 end as [РабочееВремя]
,НужнаДетализация
,projectuuid
,abandoned_calls_count
, connected
, [first_call_success]

  --into #t2 
  from itog_v__ itog_v
  )

select   
id
,  created_at
, called_at
, UF_REGISTERED_AT
, called_suc_at
, Заявка
--, ft.first_try called_at
, projecttitle
, timezone
, МестноеВРемя
, ДатаСтартаКампанииПоМск
, ДатаОкончанияКампанииПоМск
, ДатаСтартаКампанииПоМскВСледующийДень
, ВремяПоМскСКОторогоКЛиентМожетГоворить
, ВремяПоМскДоКОторогоКЛиентМожетГоворить
, ВремяПоМскНаСледДеньСКОторогоКЛиентМожетГоворить 
, crd 
, case when datediff(minute, crd, called_at)<0 then 0 else  cast(datediff(minute, crd, called_at) as bigint) end creationdateCC 
, [РабочееВремя] 
, НужнаДетализация 
, projectuuid
, isnull(abandoned_calls_count, 0) abandoned_calls_count
, connected
, [first_call_success]

into #final_for_ins_1 from itog_v_v

	   --create clustered index t0 on report_ttc_details2 (id)
select * into #for_insert from 	  #final_for_ins_1
							where
case when НужнаДетализация=1 then 1
     when НужнаДетализация=0 and created_at>= dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) ) then 1
	 end = 1

delete a from #for_insert a join 	 report_TTC_details2 b on a.id=b.id and  isnull(a.creationdateCC, -1)= isnull(b.creationdateCC, -1)	   and a.РабочееВремя=b.РабочееВремя


begin tran

delete b from #for_insert a join 	 report_TTC_details2 b on a.id=b.id 

insert into Analytics.dbo.report_TTC_details2 
select id
,  created_at
, called_at
, UF_REGISTERED_AT
, called_suc_at
, Заявка
, projecttitle
, timezone
, МестноеВРемя
, ДатаСтартаКампанииПоМск
, ДатаОкончанияКампанииПоМск
, ДатаСтартаКампанииПоМскВСледующийДень
, ВремяПоМскСКОторогоКЛиентМожетГоворить
, ВремяПоМскДоКОторогоКЛиентМожетГоворить
, ВремяПоМскНаСледДеньСКОторогоКЛиентМожетГоворить 
, crd 
, creationdateCC 
, [РабочееВремя] 
, projectuuid 
, abandoned_calls_count 
, connected
, НужнаДетализация
, [first_call_success]
from #for_insert		 

--alter table Analytics.dbo.report_TTC_details2 add  [first_call_success] smallint






commit tran

if datepart(day, getdate()) =1 		 and @debug=0
begin
delete from Analytics.dbo.report_TTC_details2  where  НужнаДетализация=0 and created_at>= dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )  

delete from Analytics.dbo.report_TTC_details2  where projectuuid in ( 'corebo00000000000n35ltu7n0jje82k' --and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )
, 'corebo00000000000n8i9hcja56hji2o'  --and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )
, 'corebo00000000000nd135ldk2oc12gs'  --and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )
, 'corebo00000000000nhc39ilthenudg4'  --and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )
, 'corebo00000000000msiiqd99k5req2s'  --and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )
, 'corebo00000000000mqpsrh9u28s16g8' ) and created_at< dateadd(month , -1, cast(format(getdate(), 'yyyy-MM-01') as date) )

end

;


if @debug = 0
begin


exec msdb.dbo.sp_start_job	  'Analytics._birs TTC звонки daily'

end


drop table if exists #final_for_ins
select cast(created_at as date)                                                                           Date
,      cast(format(cast(created_at as date), 'yyyy-MM-01') as date)                                         Month
,      cast(DATEADD(DD, 1 - DATEPART(DW, cast(created_at as date)), cast(created_at as date)) as date) as Week
,      projecttitle  projecttitle                                                                                  
,      sum(creationdateCC )                                           SumTime

,      count(creationdateCC)                                                                              CountTime

-----------------------------
,      sum(case when [РабочееВремя]=1 then creationdateCC end )                                           SumTimeРабочееВремя
,      count(case when [РабочееВремя]=1  then creationdateCC end)    CountTimeРабочееВремя			
---------------------------------
,      count(id)                                                                                          ПоступилоЛидов
,      count(case when [РабочееВремя]=1  then id end)        
ПоступилоЛидовРабочееВремя


,      count(case when cast(called_at as date) =cast(crd as date) then id end)                            ОбработаноДеньВДень
,      count(case when [РабочееВремя]=1  and cast(called_at as date) =cast(crd as date) then id end)                            ОбработаноДеньВДеньРабочееВремя
,      count(called_at)                                                                                   Обработано
,      count(case when [РабочееВремя]=1 then called_at end)                                                                                   ОбработаноРабочееВремя

,      count(called_suc_at)                                                                                   Дозвон
,      count(case when [РабочееВремя]=1 then  called_suc_at end)                                                                                   ДозвонРабочееВремя



,      isnull(sum(abandoned_calls_count)                                      , 0)                                                    ПотеряныхЗвонков
,      isnull(sum(case when [РабочееВремя]=1 then  abandoned_calls_count end) , 0)                                                                                  ПотеряныхЗвонковРабочееВремя

,      getdate()                                                                                       as created
,      count(case when connected=1 then 1 end)                                                                                   Соединений
,      count(case when [РабочееВремя]=1 and connected=1 then  1 end)                                                                                   СоединенийРабочееВремя 
,      count(case when [first_call_success]=1 then 1 end)                                                                                   [first_call_success]
,      count(case when [РабочееВремя]=1 and [first_call_success]=1 then  1 end)                                                                                   [first_call_success_work_time]

-----------------------------
,      sum(case when [РабочееВремя]=0 then creationdateCC end )                                           SumTimeНеРабочееВремя
,      count(case when [РабочееВремя]=0  then creationdateCC end)    CountTimeНеРабочееВремя
--,       projectuuid
	into 
	--drop table
		#final_for_ins
from #final_for_ins_1

--exec sp_rename 'report_TTC_on_projects2.[first_call_success_work_days]'	, 'first_call_success_work_time'


group by cast(created_at as date)
,        projecttitle
--,        projectuuid

--drop table if exists  Analytics.dbo.report_TTC_on_projects2
--select * into  Analytics.dbo.report_TTC_on_projects2 from #final_for_ins
begin tran
delete from  Analytics.dbo.report_TTC_on_projects2 where Date>=@start_date
insert into Analytics.dbo.report_TTC_on_projects2 --select * from #final_for_ins_1
select       a.[Date]  
,   a.[Month]   
,   a.[Week]   
,   a.[projecttitle] 
,   a.[SumTime] 
,   a.[CountTime] 
,   a.[SumTimeРабочееВремя]  
,   a.[CountTimeРабочееВремя] 
,   a.[ПоступилоЛидов]  
,   a.[ПоступилоЛидовРабочееВремя] 
,   a.[ОбработаноДеньВДень] 
,   a.[ОбработаноДеньВДеньРабочееВремя] 
,   a.[Обработано]  
,   a.[ОбработаноРабочееВремя] 
,   a.[Дозвон]  
,   a.[ДозвонРабочееВремя]
,   a.[ПотеряныхЗвонков] 
,   a.[ПотеряныхЗвонковРабочееВремя]   
,   a.[created]    
,   a.Соединений
,   a.СоединенийРабочееВремя
,   a.[first_call_success]
,   a.[first_call_success_work_time]
,   a.SumTimeНеРабочееВремя
,   a.CountTimeНеРабочееВремя
from 
 #final_for_ins a
commit tran

 
   exec ('
   use feodor
 
 declare @table  [dbo].[lead_ttc_first_caseType]
insert into    @table
 select   id	  uuid
,  created_at
, called_at		  
, creationdateCC 	[ttc_first_case]  
, [РабочееВремя] 	[is_work_time]  
from #final_for_ins_1
where creationdateCC is not null  and РабочееВремя is not null

drop table if exists #final_for_ins_1
drop table if exists #t1
drop table if exists #t1
drop table if exists #Справочник
 exec feodor.dbo.lead_ttc_first_case_creation 	 null, 	 @table
 ')
 
					   

--alter table Analytics.dbo.report_TTC_on_projects2  add CountTimeНеРабочееВремя	bigint


  end

