--	  declare @start_date date = '20240425'
--  exec [dbo].[lead_call_creation] 	 '20240425'



--	  declare @ids leadType insert into @ids  select 1 
--  exec [dbo].[lead_call_creation] 	null, @ids 



	  --declare @start_date date = '20240425'
CREATE     procedure [dbo].[lead_call_creation] 		@start_date date = null , 
@ids [carm\p.ilin].leadType	  readonly  	 


as
begin
--return
--return

   --declare @start_date date = '20240801'
--/*

drop table if exists  [#dm_feodor_projects]
select IdExternal, RecallProject, LaunchControlName,   rn_IdExternal into [#dm_feodor_projects]

from  [Feodor].[dbo].[dm_feodor_project2] where id>0

drop table if exists #mv_employee
select a.login, max( a.title) title into #mv_employee 
from 
[NaumenDbReport].[dbo].[mv_employee] a
group by a.login
   /*

   --declare @start_date date = '20240620'
drop table if exists #ref

select a.lead_id ID  ,a.statetitle, a.uuid,a.projectuuid, a.creationdate, case when b.id is null then 1 else 0 end for_upd into #ref from dm_case_uuid_to_lf_references a
left join Feodor.dbo.lead b on a.lead_id=b.ID--	and isnull( b.creationdate, '20010101') <=a.creationdate
 where   b.creationdate is null and a.creationdate>=@start_date
			and  a.lead_id is not null
 select * from #ref

 --select * from 	  dm_case_uuid_to_lf_references
 --where creationdate>=@start_date

   --declare @start_date date = '20240620'		  */

drop table if exists #calls
   select cast('' as nvarchar(36)) lead_id, cast(null as int) for_upd into #calls where 1=0

   if @start_date is not null
   begin


insert into #calls

select distinct	a.lead_id, case when b.id is null  then 1 end for_upd  from [Feodor].[dbo].[dm_calls_history_lf] a  with(nolock)
join [#dm_feodor_projects] fp on fp.idexternal=a.projectuuid
left  join lead b with(nolock) on a.lead_id=b.id-- and b.[ВРемяПоследнейПопытки]<=a.attempt_start
 where ( b.[ВРемяПоследнейПопытки] <a.attempt_start or b.[ВРемяПоследнейПопытки] is null  	) and a.attempt_start>=@start_date

 
insert into #calls

select distinct	 top 100000 a.lead_id, case when b.id is null  then 1 end for_upd  from [Feodor].[dbo].[dm_calls_history_lf] a  with(nolock)
join [#dm_feodor_projects] fp on fp.idexternal=a.projectuuid
left  join lead b with(nolock) on a.lead_id=b.id-- and b.[ВРемяПоследнейПопытки]<=a.attempt_start
left join  #calls c on c.lead_id = a.lead_id
 where ( b.connected_last <a.connected or b.connected_last is null  	) and a.attempt_start>=@start_date
 and a.connected is not null
 and c.lead_id  is null


-- --create synonym v_lead_call for analytics.dbo.v_lead_call 

-- insert into #calls

--select  	a.lead_id, cast(null as int) for_upd  from  v_lead_call a 
--join lead b with(nolock) on a.lead_id=b.id-- and b.[ВРемяПоследнейПопытки]<=a.attempt_start
-- where  b.uf_registered_at>=@start_date
-- group by a.lead_id
-- --order by
-- having isnull(sum(a.pay_seconds), 0) <>isnull(max(b.seconds_to_pay) , 0)



 end

 begin
 
insert into #calls

select distinct	a.lead_id, case when b.id is null  then 1 end for_upd  from [Feodor].[dbo].[dm_calls_history_lf] a with(nolock)
join [#dm_feodor_projects] fp on fp.idexternal=a.projectuuid

left  join lead b  with(nolock)  on a.lead_id=b.id-- and b.[ВРемяПоследнейПопытки]<=a.attempt_start
join @ids ids on ids.id=a.lead_id

insert into #calls
select a.id , case when b.id is null  then 1 end for_upd from @ids   a
left  join lead b  with(nolock)  on a.id=b.id-- and b.[ВРемяПоследнейПопытки]<=a.attempt_start
 left join #calls c on c.lead_id=a.id 
 where c.lead_id is null


 end

 --select *  from #calls
drop table if exists #changed


select distinct lead_id into #changed from #calls	a  
where lead_id is not null	  and for_upd=1
  /*
union
select distinct ID from #ref	a  
where ID is not null	  and for_upd=1
							   */
declare @a [carm\p.ilin].leadtype 

insert into  @a
  select  lead_id from 	#changed
exec lead_creation 		@a, null
 


--select * from  #calls a
--left join 	 #ref b on a.lead_id=b.id
--where b.ID is null

DROP table if exists #ch
select TOP 0
        a.attempt_start
      , a.projectuuid 
      , a.phonenumbers  
      , a.projecttitle 
      , a.lcrm_id 
      , a.attempt_result 
      , a.speaking_time 
      , a.creationdate 
      , a.unblocked_time  
      , a.timezone
      , a.uuid 
      , a.login 
	  , connected connected
	  , datediff(second,  connected, attempt_end) seconds_to_pay
	  , lead_id
	  
      , case when queue_time>0 and attempt_result='abandoned' then 1 else 0 end is_abandoned
	  , case when datediff(SECOND, connected, attempt_end) in (32,33) and hangup_initiator='queue_script' then 1 else 0 end is_autoanswer
into #ch 
from [Feodor].[dbo].[dm_calls_history_lf] a 


	INSERT #ch
	select 
			a.attempt_start
		  , a.projectuuid 
		  , a.phonenumbers  
		  , a.projecttitle 
		  , a.lcrm_id 
		  , a.attempt_result 
		  , a.speaking_time 
		  , a.creationdate 
		  , a.unblocked_time  
		  , a.timezone
		  , a.uuid 
		  , a.login 
		  ,   connected
	      , datediff(second,  connected, attempt_end) seconds_to_pay
		  , a.lead_id
		  
      , case when queue_time>0 and attempt_result='abandoned' then 1 else 0 end is_abandoned
	  , case when datediff(SECOND, connected, attempt_end) in (32,33) and hangup_initiator='queue_script' then 1 else 0 end is_autoanswer
	from [Feodor].[dbo].[dm_calls_history_lf] a 
		JOIN #calls b on a.lead_id=b.lead_id	  and isnumeric(b.lead_id)=0
join [#dm_feodor_projects] fp on fp.idexternal=a.projectuuid


  /*
	insert into  #calls
	select id, null from #ref a
	left join #calls b on a.id=b.lead_id
	where b.lead_id is null		;
  */

		
-- with v as (
-- select *  ,ROW_NUMBER() over(partition by lead_id order by lead_id desc) rn_ins from    #calls )
  
-- delete from v where rn_ins<>1

----and isnumeric(b.id )=0
 
--delete from  @a
----declare @a leadtype 

--insert into  @a
--select lead_id from #calls	a
--left  join lead b on a.lead_id=b.id  

--where lead_id is not null	  and b.id is null
--exec lead_creation 		@a

--select * from 	#lcun


  drop table if exists #calls_weighted_attribution

  select idexternal id    into #calls_weighted_attribution
  FROM [Analytics].[dbo].[v_communication_feodor] a join #calls b on b.lead_id=a.IdExternal
  where  has_call_weighted_attribution=1 and a.created>='20250301'
 group by  idexternal


drop table if exists #forw
select 
       lcrm.lead_id [ID]
  
 
 	  , [CompanyNaumen] = 
	  case 
--	   when fp_id.[LaunchControlName] is not null then fp_id.[LaunchControlName]
	  when fp.[LaunchControlName] is not null then fp.[LaunchControlName]
	--  when fp_ref.LaunchControlName is not null then fp_ref.LaunchControlName
 end

    --  ,isnull(ch.creationdate, ref.creationdate) creationdate
      , ch.creationdate  creationdate
      ,ch.phonenumbers
      ,ch.projecttitle
      ,ch.lcrm_id
      ,ch.attempt_start
      ,ch.attempt_result
      ,ch.speaking_time
      ,ch.seconds_to_pay
      ,ch.login
      ,naulogins.title
      ,ch.unblocked_time
      ,ch.timezone
      , ch.uuid uuid
    --  ,isnull(ch.uuid, ref.uuid) uuid
	--  ,case when ref.statetitle = 'Выполнено' and ch.attempt_start is null then 1 else 0 end as [Удален из обзвона]
 
	  , ch.connected  
	  , case when cw.id is not null then 1 end  has_call_weighted_attribution
	  ,ch.is_abandoned
	  ,ch.is_autoanswer
 
  into #forw
  from #calls lcrm 
  
  left join      #ch ch on lcrm.lead_id=ch.lead_id
  -- left join #ref ref on lcrm.lead_id=ref.ID
   left join [#mv_employee] naulogins on naulogins.login=ch.login
 
  left join [#dm_feodor_projects] fp on fp.[IdExternal]=ch.projectuuid and  fp.[rn_IdExternal]=1
  left join #calls_weighted_attribution cw on cw.id=lcrm.lead_id
  -- left join [#dm_feodor_projects]fp_ref on fp_ref.[IdExternal]=ref.[projectuuid] and  fp_ref.[rn_IdExternal]=1
 												  
 
-- select * from lead_failed_creation
--
-- select ' db272f86-b3cc-4b8b-a995-76dce1b3cc6'


 -- exec Analytics.dbo.create_table '#forj'
  drop table if exists [#forj]
 CREATE TABLE  [#forj]
(
      [ID] [NVARCHAR](36)
    , [CompanyNaumen] [NVARCHAR](255)
    , [creationdate] [DATETIME2](7)
    , [phonenumbers] [NVARCHAR](4000)
    , [projecttitle] [NVARCHAR](4000)
    , [lcrm_id] [NVARCHAR](50)
    , [attempt_start] [DATETIME2](7)
    , [attempt_result] [NVARCHAR](50)
    , [speaking_time] [INT]
    , [login] [NVARCHAR](50)
    , [title] [NVARCHAR](4000)
    , [unblocked_time] [DATETIME2](7)
    , [timezone] [NVARCHAR](32)
    , [uuid] [NVARCHAR](32)
    , [rn] [BIGINT]
    , [ЧислоПопыток] [INT]
    , [ВремяПервойПопытки] [DATETIME2](7)
    , [ВремяПоследнейПопытки] [DATETIME2](7)
    , [ВремяПервогоДозвона] [DATETIME2](7)
    , [ВремяПоследнегоДозвона] [DATETIME2](7)
    , [ЧислоРазблокированныхСессий] [INT]
    , [ФлагРазблокированнаяСессия] [INT]
    , [ЧислоДозвонов] [INT]
    , [ФлагДозвонПоЛиду] [INT]
    , [ФлагНедозвонПоЛиду] [INT]
    , [ЛогинПоследнегоСотрудника] [NVARCHAR](4000)
   -- , [Удален из обзвона] [INT]
    --, [Флаг технический дозвон] [INT]
    , [seconds_to_pay] [BIGINT]
    , has_call_weighted_attribution tinyint
     , is_abandoned tinyint
     , is_autoanswer tinyint
     , connected_last datetime2
);

	 
	 

 DECLARE @minID VARCHAR(50), @maxID VARCHAR(50), @batchSize INT;
SET @minID = (SELECT MIN(ID) FROM #forw);
SET @maxID = (SELECT MAX(ID) FROM #forw);
SET @batchSize = 500000; -- Размер каждой части

WHILE @minID <= @maxID
BEGIN
    -- Выполните расчеты для текущей части данных
    INSERT INTO #forj
	select 
     [ID]
 
    --  ,   FIRST_VALUE([CompanyNaumen] ) 	  over (partition by id   order by 	   case when uuid is null then 1 else 0 end, creationdate )	 [CompanyNaumen]
      ,FIRST_VALUE([CompanyNaumen]) over (partition by id order by case when attempt_result is null then 1 else 0 end, attempt_start,  case when uuid is null then 1 else 0 end, creationdate  )    [CompanyNaumen] 
 
	
      ,min(creationdate) over (partition by id ) creationdate
      ,phonenumbers
      ,projecttitle
      ,lcrm_id
      ,attempt_start
      ,attempt_result
      ,sum(speaking_time)   over (partition by id)  speaking_time
      ,FIRST_VALUE(login) over (partition by id order by case when login is null then 1 else 0 end, attempt_start desc) login
      ,title
      ,unblocked_time
      ,timezone
      ,FIRST_VALUE(uuid) over (partition by id order by  case when uuid is null then 1 else 0 end, creationdate) uuid
	  ,
  row_number() over (partition by id order by attempt_start desc) rn,
  count(attempt_start) over (partition by id) [ЧислоПопыток],
  min(attempt_start)  over (partition by id) [ВремяПервойПопытки],
  max(attempt_start)  over (partition by id) [ВремяПоследнейПопытки],
  min(case when [login] is not null then attempt_start end)  over (partition by id) [ВремяПервогоДозвона],
  max(case when [login] is not null then attempt_start end)  over (partition by id) [ВремяПоследнегоДозвона],
  case when creationdate is not null then count(case when unblocked_time is not null then unblocked_time end) over (partition by id) end [ЧислоРазблокированныхСессий],
  case when creationdate is not null then sign(count(case when unblocked_time is not null then unblocked_time end) over (partition by id)) end [ФлагРазблокированнаяСессия],
  count(case when [login] is not null then attempt_start end) over (partition by id) [ЧислоДозвонов],
  case when creationdate is not null then sign(count(case when [login] is not null then attempt_start end) over (partition by id)) end [ФлагДозвонПоЛиду],
  case when creationdate is not null then 1-sign(count(case when [login] is not null then attempt_start end) over (partition by id)) end [ФлагНедозвонПоЛиду],
  try_cast(FIRST_VALUE([title])  over (partition by id order by case when [title] is null then 1 else 0 end, attempt_start desc) as nvarchar(256)) [ЛогинПоследнегоСотрудника]
 -- ,
 -- [Удален из обзвона]
 
  --,case when count(connected) over(partition by id)>0  then 1 end  [Флаг технический дозвон]

  ,sum(seconds_to_pay) over (partition by id) [seconds_to_pay]
  ,has_call_weighted_attribution
  
     ,max( is_abandoned )  over (partition by id) is_abandoned
     ,max( is_autoanswer )  over (partition by id)  is_autoanswer
     ,max( connected )  over (partition by id)  connected_last
    FROM #forw 
    WHERE ID >= @minID AND ID <= @maxID;
    
    -- Увеличить минимальное значение для следующей части
    SET @minID = (SELECT TOP 1 ID FROM #forw WHERE ID > @maxID ORDER BY ID);
    IF @minID IS NULL BREAK; -- Проверка на конец данных
    SET @maxID = (SELECT TOP 1 ID FROM #forw WHERE ID > @minID ORDER BY ID);
    IF @maxID IS NULL SET @maxID = (SELECT MAX(ID) FROM #forw);
END;
  delete from #forj where rn<>1


  select 'hello',  * from #forj

   ;


 		    MERGE feodor.dbo.[lead] AS target
    USING (
 select 
  [ID]
 
 ,[CompanyNaumen] [CompanyNaumen]

 ,creationdate
 ,phonenumbers
 ,projecttitle
 ,lcrm_id
 ,attempt_start
 ,attempt_result
 ,speaking_time
 ,login
 ,title
 ,unblocked_time
 ,timezone
 ,uuid
,
 -- rn,
  [ЧислоПопыток],
  [ВремяПервойПопытки],
  [ВремяПоследнейПопытки],
  [ВремяПервогоДозвона],
  [ВремяПоследнегоДозвона],
  [ЧислоРазблокированныхСессий],
  [ФлагРазблокированнаяСессия],
  [ЧислоДозвонов],
  [ФлагДозвонПоЛиду],
  [ФлагНедозвонПоЛиду]
,  [ЛогинПоследнегоСотрудника] 
--,  [Флаг технический дозвон]  
,  lcrmnau.[seconds_to_pay]
,  lcrmnau.has_call_weighted_attribution
,  lcrmnau.is_abandoned
,  lcrmnau.is_autoanswer
,  lcrmnau.connected_last
  
 from
 #forj lcrmnau) AS source
    ON target.ID = source.ID
    WHEN MATCHED THEN
        UPDATE SET
  target.[CompanyNaumen]    			 =source.[CompanyNaumen]    
 ,target.creationdate					 =case when target.creationdate is null then  source.creationdate else 	 target.creationdate  end 
 ,target.phonenumbers					 =source.phonenumbers
 ,target.projecttitle					 =source.projecttitle
 ,target.lcrm_id						 =source.lcrm_id
 ,target.attempt_start					 =source.attempt_start
 ,target.attempt_result					 =source.attempt_result
 ,target.speaking_time					 =source.speaking_time
 ,target.login							 =source.login
 ,target.title							 =source.title
 ,target.unblocked_time					 =source.unblocked_time
 ,target.timezone						 =source.timezone
 ,target.uuid							 =case when target.creationdate is null then  source.uuid else 	 target.uuid  end 
, target.[ЧислоПопыток]					 =source.[ЧислоПопыток]
, target.[ВремяПервойПопытки]			 =source.[ВремяПервойПопытки]
, target.[ВремяПоследнейПопытки]		 =source.[ВремяПоследнейПопытки]
, target.[ВремяПервогоДозвона]			 =source.[ВремяПервогоДозвона]
, target.[ВремяПоследнегоДозвона]		 =source.[ВремяПоследнегоДозвона]
, target.[ЧислоРазблокированныхСессий]	 =source.[ЧислоРазблокированныхСессий]
, target.[ФлагРазблокированнаяСессия]	 =source.[ФлагРазблокированнаяСессия]
, target.[ЧислоДозвонов]				 =source.[ЧислоДозвонов]
, target.[ФлагДозвонПоЛиду]				 =source.[ФлагДозвонПоЛиду]
, target.[ФлагНедозвонПоЛиду]			 =source.[ФлагНедозвонПоЛиду]
, target. [ЛогинПоследнегоСотрудника] 	 =source. [ЛогинПоследнегоСотрудника] 
, target. [Флаг технический дозвон]  	  = case when   source. connected_last    is not null then 1  end 
, target.   [Удален из обзвона]  	 = case when target.   [Удален из обзвона]=1 then  0 else 	target.   [Удален из обзвона] end
, target. [seconds_to_pay]		 =source.[seconds_to_pay]
, target. row_updated		 =getdate()
, target. has_call_weighted_attribution		 =source. has_call_weighted_attribution
, target. is_abandoned		 =source. is_abandoned
, target. is_autoanswer		 =source. is_autoanswer 
, target. connected_last		 =source. connected_last 

 --   WHEN NOT MATCHED BY TARGET THEN
 --       INSERT (
 --           [ДатаОбновленияСтроки],
 --           [ДатаЛидаЛСРМ],
 --           [ID],
 --           [UF_PHONE],
 --           [UF_REGISTERED_AT],
 --           [UF_TYPE],
 --           [UF_LOGINOM_CHANNEL],
 --           [UF_LOGINOM_GROUP],
 --           [UF_LOGINOM_PRIORITY],
 --           [UF_LOGINOM_STATUS],
 --           [Канал от источника],
 --           [Группа каналов],
 --           [UF_PARTNER_ID аналитический],
 --           [UF_LOGINOM_DECLINE],
 --           [UF_STAT_AD_TYPE],
 --           [UF_APPMECA_TRACKER],
 --           [uf_stat_source],
 --           [UF_SOURCE],
 --           [uf_regions_composite],
 --           [UF_STAT_CAMPAIGN],
 --           [entrypoint],
 --           [is_inst_lead],
 --           [IsInstallment]
 --       )
 --       VALUES (
 --           source.[ДатаОбновленияСтроки],
 --             source.[ДатаЛидаЛСРМ],
 --           source.[ID],
 --           source.[UF_PHONE],
 --           source.[UF_REGISTERED_AT],
 --           source.[UF_TYPE],
 --           source.[UF_LOGINOM_CHANNEL],
 --           source.[UF_LOGINOM_GROUP],
 --           source.[UF_LOGINOM_PRIORITY],
 --           source.[UF_LOGINOM_STATUS],
 --           source.[Канал от источника],
 --           source.[Группа каналов],
 --           source.[UF_PARTNER_ID аналитический],
 --           source.[UF_LOGINOM_DECLINE],
 --           source.[UF_STAT_AD_TYPE],
 --           source.[UF_APPMECA_TRACKER],
 --           source.[uf_stat_source],
 --           source.[UF_SOURCE],
 --           source.[uf_regions_composite],
 --           source.[UF_STAT_CAMPAIGN],
 --           source.[entrypoint],
 --           source.[is_inst_lead],
 --           source.[IsInstallment] 															   
 --       );
  ;
 select @@ROWCOUNT	  , 'case - call updated'
  
 -- alter table lead add has_call_weighted_attribution tinyint
 -- alter table lead add is_abandoned tinyint
 -- alter table lead add is_autoanswer tinyint
 -- alter table lead add connected_last datetime2
 --*/
end