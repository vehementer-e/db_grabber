-- Andrey Shubkin
-- check dwh calendar for values
-- 2020 03 02
-- exec dwh_new.dbo.CheckDWHStructure
-- select max(created) from calendar

CREATE PROC dbo.CheckDWHStructure
as
begin
set nocount on 



--
 -- Проверяем календарь 
 --
if  (
SELECT count(*)
  FROM [dwh_new].[dbo].[calendar]
  where created>cast(getdate() as date)
  )=0

  BEGIN
	  with cal as (
		   select dateadd(day,1,cast(getdate() as date)) dt
		   union all select dateadd(day,1,dt) 
		   from cal 
		   where dt<dateadd(day,-1,format(dateadd(month,1,cast(getdate() as date)),'yyyyMM01'))
	  )
	  INSERT INTO dwh_new.dbo.calendar
	  --select * from cal 
	  SELECT DISTINCT C.dt 
	  FROM cal AS C
		LEFT JOIN dwh_new.dbo.calendar AS A 
			ON A.created = C.dt
	  WHERE A.created IS NULL
  END
  
--
-- Проверка и удаление дублей
--
  ; with doubles as 
  (
  select created,rn=row_number() over (partition by created order by created) from calendar
  ) 
  delete
  from doubles
  where rn>1


/*
--
-- удаление дублей из ClientContractStage
--
;
with c as (

  select * 
       , case when  lag(created) over(partition by CRMClientGUID,CMRContractGUID order by created)=created then 1 else 0 end l
    from [dwh_new].[Dialer].[ClientContractStage] where --CRMClientGUID='5C7CD276-1566-11E8-814E-00155D01BF07'
         ishistory=0
     and CRMClientGUID in(
                          select crmclientguid 
                            from ( 
                                  select CRMClientGUID,CMRContractGUID,count(*) с,count(distinct created) с1
                                    from [dwh_new].[Dialer].[ClientContractStage] where ishistory=0
                                   group by CRMClientGUID,CMRContractGUID
                                  having count(*)<>count(distinct created)
                          )q
                           
 )
 )
 delete  from c
 where l=1
*/
  


end

