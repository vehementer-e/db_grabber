
--    exec [dbo].[create_dm_leads_history]	 0,  'by_hour'


CREATE    procedure [dbo].[create_dm_leads_history] @debug int = 0		,  @mode nvarchar(max) = 'run_job'
as
begin
return
declare @msg nvarchar(max) 
--exec analytics.dbo.Джобы   0, 1
--exec analytics.dbo.Джобы   0, 1

--exec analytics.dbo.запросы	 'temp analytics job'


--select * from Analytics.dbo.config


if @mode='run_job'
begin
EXEC msdb.dbo.sp_start_job 'temp analytics job'
end

if @mode='lh'
begin

--return
--835E00EC-7C9E-4C88-BCA2-43BF209BDA0E
--drop table if exists #start_creating_lh 
--select getdate() id into #start_creating_lh
--drop table if exists #start_creating_lh  select cast(null as smalldatetime ) id into #start_creating_lh --для отладки --delete from dm_leads_history_update_log where id is null

/*
delete from  Feodor.dbo.dm_leads_history_update_log where id in (
select id  from Feodor.dbo.dm_leads_history_update_log
group by id
having count(case when param='depth_id' then 1 end)=0
--order by 1 
)                
*/

--------
--declare @debug int=0

declare @start_creating_lh datetime = getdate()
--declare @debug int=1
set datefirst 1
declare @proceed_only_requested_ids int=0
if  @debug>0
begin
set @proceed_only_requested_ids=1

--delete from #start_creating_lh
end

set @msg	=  'create_dm_leads_history start, @mode='+@mode+' ;@debug=' +format(@debug, '0')
exec analytics.dbo.log_email @msg

--drop table if exists dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, cast('start'  as nvarchar(max)) param , (select top 1 id from #start_creating_lh) dt , cast('start'  as nvarchar(max)) value into dm_leads_history_update_log
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'start'  param , (select top 1 id from #start_creating_lh) dt , 'start' as value
--select * from dm_leads_history_update_log
declare @job int = 1
--------
drop table if exists [#lcrm_id_sold] --insert into [#lcrm_id_sold] select 1
CREATE TABLE [dbo].[#lcrm_id_sold]
(
      [id] [NUMERIC]
);
--insert into   [#lcrm_id_sold] select  1051420192

--select Мес from reports.dbo.dm_factor_analysis_001
--exec analytics.dbo.select_table 'reports.dbo.dm_factor_analysis_001'
--select 	distinct [Место cоздания]
--from 
--
--reports.dbo.dm_factor_analysis_001 a


 drop table if exists #fa_tmp
 select ДатаЗаявкиПолная, [Заем выдан], Номер, Телефон, [Вид займа], [Предварительное одобрение], Одобрено, [Контроль данных], [Выданная сумма], [LCRM ID], case when  [Место cоздания] in ( 'Ввод операторами LCRM', 'ЛКК клиента')  then 1 else 0 end [is_lcrm], 1-isPts IsInstallment, isPdl into #fa_tmp from [Reports].[dbo].[dm_Factor_Analysis_001]

 drop table if exists #dm_Lead_tmp
 select [Дата лида]
 , [Номер  телефона], [Номер заявки (договор)], [Причина непрофильности],[Статус лида], [ID LCRM], [ID лида Fedor] 
 , [id проекта naumen]
 , [Флаг отправлен в МП]
 , IsInstallment
 , isPdl
 , [Дата заявки] 
 , [Результат коммуникации]

 into #dm_Lead_tmp
 
 from Feodor.dbo.dm_Lead
  where ISNUMERIC([ID LCRM])=1 and [id проекта naumen] is not null

 drop table if exists #returns

  select  
        r.Номер [Возврат]
 ,      r.id [id возврат]
 ,      r.IsInstallment [IsInstallment возврат]
 ,      r.[Заем выдан] [Заем выдан возврат]
 ,      r.[Выданная сумма] [Выданная сумма возврат]
 
 into #returns

 from analytics.dbo.returns_references2	r
  where id is not null


 -- exec feodor.[dbo].Create_dm_case_uuid_to_lcrm_references


 if @proceed_only_requested_ids=0 
 begin

			declare @start_id numeric = (select max(id)
					from stg.[_LCRM].[lcrm_leads_full_calculated])
			 
			declare @depth_id int
				set @depth_id=	   300000

					--case when datepart(dw, getdate()) >5 and datepart(hh, getdate())>=22  and (select count(*) from Feodor.dbo.dm_leads_history_monitoring where depth_id>=1000000  and start_creating_lh>=cast(getdate() as date))=0   then 6000000
					--     when datepart(hh, getdate())<22 then 300000
					--     when datepart(hh, getdate())>=22
					--	and (select count(*) from Feodor.dbo.dm_leads_history_monitoring where depth_id>=1000000  and start_creating_lh>=cast(getdate() as date))=0 then 4000000
					--     else 300000 end
			
			--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'depth_id'  param , getdate() dt , cast(@depth_id as nvarchar(max) ) as value
			--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'getting ids to update'  param , getdate() dt , null as value
			
			
			
			insert into [#lcrm_id_sold] 
				select id from stg.[_LCRM].[lcrm_leads_full_calculated] where id >@start_id-@depth_id
			
			
			--select @depth_id
			
			if @depth_id<1000000--2000000
						begin
						
						
							--insert into [#lcrm_id_sold]
							--select lcrm_id from Feodor.dbo.dm_case_uuid_to_lcrm_references
							--where creationdate>=cast(getdate() as date)
							---- by 2
							--
							--insert into [#lcrm_id_sold]
							--select lcrm_id from Feodor.dbo.dm_calls_history
							--where attempt_start>=cast(getdate() as date)
							----order by 2
							
while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end

							insert into [#lcrm_id_sold]
							  SELECT id from stg._LCRM.lcrm_leads_full_calculated
							    where id>@start_id-4*@depth_id 
							  except
							  SELECT id FROM [Feodor].[dbo].[dm_leads_history] lh 
							   where id>@start_id-4*@depth_id 
							

while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end

							insert into #lcrm_id_sold
							  SELECT  id 
							    
							  FROM [Feodor].[dbo].[dm_leads_history] lh with(nolock)
							  left join Feodor.dbo.dm_case_uuid_to_lcrm_references rr with(nolock) on rr.lcrm_id=lh.id
							  left join Feodor.dbo.dm_calls_history ch with(nolock) on ch.lcrm_id=lh.id
							  left join #dm_Lead_tmp lead on try_cast(lead.[ID LCRM] as numeric)=lh.id
							  where id>@start_id-@depth_id*5 and
							  ( (ch.lcrm_id is not null and ВремяПервойПопытки is null)
							   or (rr.creationdate is not null and lh.creationdate is null)
							   or (ch.login is not null and ВремяПервогоДозвона is null)
							   or (lead.[ID LCRM] is not null and FedorLCRMID is null) 
							   or (ch.attempt_start > ДатаОбновленияСтроки) or (ch.attempt_start>lh.ВремяПоследнейПопытки)
							   )
							
							insert into #lcrm_id_sold
							SELECT  try_cast(a.[ID LCRM] as numeric)
							FROM #dm_Lead_tmp a join #fa_tmp b on a.[Номер заявки (договор)]=b.Номер and b.ДатаЗаявкиПолная>=getdate()-2
							
							insert into #lcrm_id_sold
							SELECT  try_cast(a.[ID LCRM] as numeric)
							FROM #dm_Lead_tmp a join #fa_tmp b on a.[Номер заявки (договор)]=b.Номер and b.[Заем выдан]>=getdate()-2
							
							
							
							  
							  insert into #lcrm_id_sold
							  select top 1000000 id from feodor.dbo.dm_leads_history_ids_to_update order by id desc
			
						end
			
			  if @depth_id>=1000000--2000000
						begin
						
while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end

								insert into #lcrm_id_sold
  SELECT distinct id 
    
  FROM [Feodor].[dbo].[dm_leads_history] lh with(nolock)
  left join Feodor.dbo.dm_case_uuid_to_lcrm_references rr with(nolock) on rr.lcrm_id=lh.id
  left join Feodor.dbo.dm_calls_history ch with(nolock) on ch.lcrm_id=lh.id
  left join #dm_Lead_tmp lead on try_cast(lead.[ID LCRM] as numeric)=lh.id
  where  
  (ch.lcrm_id is not null and ВремяПервойПопытки is null)
  or (ch.login is not null and ВремяПервогоДозвона is null) 
  or (lead.[ID LCRM] is not null and FedorLCRMID is null) 
   or (rr.creationdate is not null and lh.creationdate is null)
  or (ch.attempt_start > ДатаОбновленияСтроки) 
  or (ch.attempt_start>lh.ВремяПоследнейПопытки)
								
								  insert into #lcrm_id_sold
  select a.id from analytics.dbo.v_feodor_leads a with(nolock) left join Feodor.dbo.dm_leads_history b on a.id=b.ID
  where [Заем Выдан] is not null and b.ЗаемВыдан is null
								
																	   								  
  insert into #lcrm_id_sold
  select top 2000000 id from feodor.dbo.dm_leads_history_ids_to_update order by id desc
							  
								
						  
			
							end
			
			
  end

  else
			begin
			
						insert into #lcrm_id_sold
						select top (@debug) id from feodor.dbo.dm_leads_history_ids_to_update order by id desc
			

			end
  

 ;with v  as (select *, row_number() over(partition by id order by (select null)) rn from #lcrm_id_sold ) delete from v where rn>1 or id is null 


declare @start_of_collecting_from_lcrm datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'collecting_from_lcrm'  param , getdate() dt , null as value

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	  [ID] numeric(10,0)
	--, [UF_NAME] [VARCHAR](512)
	, PhoneNumber [VARCHAR](128)
	, [UF_REGISTERED_AT] [DATETIME2](7)
	, [UF_ROW_ID] [VARCHAR](128)
	, [UF_TYPE] [VARCHAR](128)
	, [UF_RC_REJECT_CM] [VARCHAR](512)
	, [UF_LOGINOM_CHANNEL] [VARCHAR](128)
	, [UF_LOGINOM_GROUP] [VARCHAR](128)
	, [UF_LOGINOM_PRIORITY] [INT]
	, [UF_LOGINOM_STATUS] [VARCHAR](128)
	, [UF_SOURCE] [VARCHAR](128)
	, [Канал от источника] [NVARCHAR](255)
	, [Группа каналов] [NVARCHAR](255)
	, [UF_PARTNER_ID] [NVARCHAR](256)
	, [UF_LOGINOM_DECLINE] [varchar](128) 
	, UF_STAT_AD_TYPE [varchar](128) 
	,UF_APPMECA_TRACKER [varchar](128) 
	,uf_stat_source [varchar](128) 
	,uf_regions_composite [varchar](128) 
	,[UF_STAT_CAMPAIGN] [varchar](512) 

)

DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
--название таблицы со списком ID
SELECT @ID_Table_Name = '#lcrm_id_sold'
--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение





  declare @end_of_collecting_from_lcrm datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'clustering #TMP_leads'  param , getdate() dt , null as value

      CREATE CLUSTERED INDEX [Cl_Idx_id] ON #TMP_leads
(
	id ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

--select * from #TMP_leads

  declare @end_of_clustering_lcrm datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'getting calls_hisory'  param , getdate() dt , null as value

--  declare @max_dt_lead datetime = (select min(UF_REGISTERED_AT) from #TMP_leads)
--
--drop table if exists #ch
--select 
--        a.attempt_start
--      , a.projectuuid 
--      , a.phonenumbers  
--      , a.projecttitle 
--      , a.lcrm_id 
--      , a.attempt_result 
--      , a.speaking_time 
--      , a.creationdate 
--      , a.unblocked_time  
--      , a.timezone
--      , a.uuid 
--      , a.login 
--      into #ch 
--from [Feodor].[dbo].[dm_calls_history] a 
--join #TMP_leads b on a.lcrm_id=b.ID and attempt_start>=@max_dt_lead

declare @min_dt_lead datetime = (select min(UF_REGISTERED_AT) from #TMP_leads)
declare @max_dt_lead datetime = getdate()
--test
--SELECT @min_dt_lead = '2022-07-01', @max_dt_lead = '2022-08-11'

DECLARE @min_partition_id int, @max_partition_id int, @partition_id int

SELECT @min_partition_id = $PARTITION.pfn_date_part(@min_dt_lead)
SELECT @max_partition_id = $PARTITION.pfn_date_part(@max_dt_lead)

--print
--SELECT @min_partition_id, @max_partition_id


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
	  , case when a.connected is not null then 1 end connected
	  , datediff(second,  connected, attempt_end) seconds_to_pay
into #ch 
from [Feodor].[dbo].[dm_calls_history] a 


SELECT @partition_id = @min_partition_id
WHILE @partition_id <= @max_partition_id
BEGIN
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
		  , case when a.connected is not null then 1 end connected
	      , datediff(second,  connected, attempt_end) seconds_to_pay

	from [Feodor].[dbo].[dm_calls_history] a 
		JOIN #TMP_leads b on a.lcrm_id=b.ID
	WHERE $PARTITION.pfn_date_part(a.attempt_start) = @partition_id

	SELECT @partition_id = @partition_id + 1
END

--select count(*) from #TMP_leads
--select count(*) from #ch
--select  *  from #ch

--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'main join'  param , getdate() dt , null as value

				 
drop table if exists [#b_user_field_enum]
select ID, VALUE into [#b_user_field_enum] 
from 
stg._LCRM.[b_user_field_enum] a



drop table if exists  [#dm_feodor_projects]
select IdExternal, RecallProject, LaunchControlName, LaunchControlID , rn_IdExternal into [#dm_feodor_projects]

from  [Feodor].[dbo].[dm_feodor_projects]

drop table if exists #mv_employee
select a.login, a.title into #mv_employee 
from 
[NaumenDbReport].[dbo].[mv_employee] a

drop table if exists #ref
select a.lcrm_id,a.statetitle, a.uuid,a.projectuuid, a.creationdate into #ref from dm_case_uuid_to_lcrm_references a
join #TMP_leads b on a.lcrm_id=b.ID


drop table if exists #lcun

select a.uf_lcrm_id, a.uf_type, a.UF_UPDATED_AT into #lcun from 	   [Reports].[dbo].[dm_LCMR_LaunchControl_Unique] a
join   #TMP_leads b on a.uf_lcrm_id=b.id

drop table if exists #forw
  select 
       lcrm.[ID]
    --  ,cast(null as varchar(512) ) [UF_NAME]
      ,lcrm.PhoneNumber [UF_PHONE]
      ,lcrm.[UF_REGISTERED_AT]
      ,lcrm.[UF_ROW_ID]
      ,lcrm.[UF_TYPE]
      ,lcrm.[UF_RC_REJECT_CM]
      ,lcrm.[UF_LOGINOM_CHANNEL]
      ,lcrm.[UF_LOGINOM_GROUP]
      ,lcrm.[UF_LOGINOM_PRIORITY]
      ,lcrm.[UF_LOGINOM_STATUS]
	  ,lcrm.[UF_SOURCE]
      ,lcrm.[Канал от источника]
      ,lcrm.[Группа каналов]
      --,isnull(fp_id.[LaunchControlName], isnull(isnull(isnull(fp.[LaunchControlName], fp_ref.LaunchControlName), fp_f.LaunchControlName)  ,isnull(enum.VALUE ,case when UF_LOGINOM_STATUS='accepted' or lcun.UF_LCRM_ID is not null or ch.lcrm_id is not null or fl.[ID LCRM] is not null then 'Не определен' else 'Non-Feodor' end))) [CompanyNaumen]
	  , [CompanyNaumen] = case 
	  when lcrm.PhoneNumber='9644473227' and cast(lcrm.[UF_REGISTERED_AT] as date)=	'20230401' then   'Отп. в никуда (VoidCC)' --
	  when fp_id.[LaunchControlName] is not null then fp_id.[LaunchControlName]
	  when fp.[LaunchControlName] is not null then fp.[LaunchControlName]
	  when fp_ref.LaunchControlName is not null then fp_ref.LaunchControlName
	  when fp_f.LaunchControlName is not null then fp_f.LaunchControlName
	  when enum.VALUE='Отп. в никуда (VoidCC)' then 'Отп. в никуда (VoidCC)'
	  when enum.VALUE='depr. - mfo (lcrm_cc)' then 'depr. - mfo (lcrm_cc)'
	  when UF_LOGINOM_STATUS='accepted' then 'Не определен' 
	  else 'Non-Feodor' end
	 -- ,null QueueDecision
	 ,lcun.UF_UPDATED_AT QueueDecision
      ,isnull(ch.creationdate, ref.creationdate) creationdate
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
      ,isnull(ch.uuid, ref.uuid) uuid
	  ,case when ref.statetitle = 'Выполнено' and ch.attempt_start is null then 1 else 0 end as [Удален из обзвона]
	  , [UF_PARTNER_ID]  
	  , ch.connected  
	  , [UF_LOGINOM_DECLINE]
	  , UF_STAT_AD_TYPE
	  , UF_APPMECA_TRACKER
	  , uf_stat_source
	  , uf_regions_composite
	  , [UF_STAT_CAMPAIGN]
	  --,is_inst_lead =  Analytics.dbo.lcrm_is_inst_lead(lcrm.UF_TYPE, lcrm.UF_SOURCE, lcrm.UF_LOGINOM_PRIORITY)

	--, [UF_PARTNER_ID аналитический] = case when  Analytics.dbo.lcrm_признак_корректного_заполнения_вебмастера(UF_SOURCE, UF_REGISTERED_AT)=1 then [UF_PARTNER_ID] end 

  into #forw
  from #TMP_leads lcrm 
  
  left join 
  --[Feodor].[dbo].[dm_calls_history] ch 
  #ch ch on lcrm.id=ch.lcrm_id
  left join  #lcun lcun   on lcrm.id=lcun.uf_lcrm_id
  left join #ref ref on lcrm.id=ref.lcrm_id
  --left join  [Feodor].[dbo].[dm_case_uuid_to_lcrm_references] ref on lcrm.id=ref.lcrm_id
  left join [#mv_employee] naulogins on naulogins.login=ch.login
 -- left join [NaumenDbReport].[dbo].[mv_employee] naulogins on naulogins.login=ch.login
  left join #dm_Lead_tmp fl on try_cast(fl.[ID LCRM] as numeric)=lcrm.id
  left join  [#b_user_field_enum] enum on enum.ID=lcun.UF_TYPE
  left join [#dm_feodor_projects] fp on fp.[IdExternal]=ch.projectuuid and  fp.[rn_IdExternal]=1
  left join [Feodor].[dbo].[dm_feodor_projects] fp_id on fp_id.[LaunchControlID]=lcun.UF_TYPE and fp_id.recallproject=0
  left join [#dm_feodor_projects]fp_ref on fp_ref.[IdExternal]=ref.[projectuuid] and  fp_ref.[rn_IdExternal]=1
  left join [#dm_feodor_projects] fp_f on fp_f.[IdExternal]=fl.[id проекта naumen]  and  fp_f.[rn_IdExternal]=1
 -- where UF_LOGINOM_STATUS='accepted' or lcun.UF_LCRM_ID is not null or ch.lcrm_id is not null or fl.[ID LCRM] is not null

  declare @end_of_main_join datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'window functions'  param , getdate() dt , null as value

  --select top 100 * from [Feodor].[dbo].[dm_case_uuid_to_lcrm_references] ref
  --order by lcrm_id desc
  --select * from #forw

  /*

    CREATE CLUSTERED INDEX [Cl_Idx_id] ON #forw
(
	id ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

*/
  drop table if exists #forj
  
  select 
       [ID]
    --  ,[UF_NAME]
      ,[UF_PHONE]
      ,[UF_REGISTERED_AT]
      ,[UF_ROW_ID]
      ,[UF_TYPE]
      ,[UF_RC_REJECT_CM]
      ,[UF_LOGINOM_CHANNEL]
      ,[UF_LOGINOM_GROUP]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
	  ,[UF_SOURCE]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[CompanyNaumen] 
	  ,QueueDecision
      ,min(creationdate) over (partition by id ) creationdate
      ,phonenumbers
      ,projecttitle
      ,lcrm_id
      ,attempt_start
      ,attempt_result
      ,speaking_time
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
  FIRST_VALUE([title]) over (partition by id order by case when [title] is null then 1 else 0 end, attempt_start desc) [ЛогинПоследнегоСотрудника]
  ,
  [Удален из обзвона]
  ,
  UF_PARTNER_ID
  ,case when count(connected) over(partition by id)>0  then 1 end  [Флаг технический дозвон]
  ,[UF_LOGINOM_DECLINE]
  ,UF_STAT_AD_TYPE
  ,UF_APPMECA_TRACKER
  ,uf_stat_source
  ,uf_regions_composite
  ,sum(seconds_to_pay) over (partition by id) [seconds_to_pay]
  ,[UF_STAT_CAMPAIGN]
  --,is_inst_lead =  Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, UF_LOGINOM_PRIORITY)
  --,[UF_PARTNER_ID аналитический] = case when  Analytics.dbo.lcrm_признак_корректного_заполнения_вебмастера(UF_SOURCE, UF_REGISTERED_AT)=1 then [UF_PARTNER_ID] end 
  into #forj
  from #forw forw
  
 delete from #forj where rn<>1

 declare @end_of_window_part datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'lead-loan colmns'  param , getdate() dt , null as value

 drop table if exists #finalforins
 select 
 getdate() as [ДатаОбновленияСтроки],
 cast(uf_registered_at as date) as [ДатаЛидаЛСРМ]

 ,[ID]
 --,[UF_NAME]
 ,[UF_PHONE]
 ,[UF_REGISTERED_AT]
 ,case 
 when [UF_ROW_ID] is not null then [UF_ROW_ID]
 when fa_blank.Номер is not null then  fa_blank.Номер
 end [UF_ROW_ID]

 ,[UF_TYPE]
 ,[UF_RC_REJECT_CM]
 ,[UF_LOGINOM_CHANNEL]
 ,[UF_LOGINOM_GROUP]
 ,[UF_LOGINOM_PRIORITY]
 ,[UF_LOGINOM_STATUS]
 ,[UF_SOURCE]
 ,[Канал от источника]
 ,[Группа каналов]
 ,[CompanyNaumen] = case when fa_lcrm.Номер is not null then 'Полная заявка' else [CompanyNaumen] end
 ,QueueDecision
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
  rn,
  [ЧислоПопыток],
  [ВремяПервойПопытки],
  [ВремяПоследнейПопытки],
  [ВремяПервогоДозвона],
  [ВремяПоследнегоДозвона],
  [ЧислоРазблокированныхСессий],
  [ФлагРазблокированнаяСессия],
  [ЧислоДозвонов],
  [ФлагДозвонПоЛиду],
  [ФлагНедозвонПоЛиду],
  cast([ЛогинПоследнегоСотрудника] as nvarchar(256)) [ЛогинПоследнегоСотрудника]
 ,feodor.[ID лида Fedor] [FedorID]
 ,feodor.[ID LCRM] [FedorLCRMID]
 ,dateadd(hour, 3, feodor.[Дата лида]) [FedorДатаЛида]
 ,feodor.[Номер заявки (договор)] [FeodorReq]
 ,feodor.[Статус лида] [СтатусЛидаФедор]
 ,feodor.[Причина непрофильности] [ПричинаНепрофильности]
 ,case when attempt_result='recallRequest' then 1 end as [ПерезвонПоПоследнемуЗвонку]
 ,case when [Статус лида] = 'Непрофильный' then 1 end as [ФлагНепрофильный]
 ,case when [Флаг отправлен в МП] =  1 then 1 end as [ФлагОтправленВМП]
 ,case when [Статус лида] in ('Отказ клиента с РСВ', 'Отказ клиента без РСВ')  then 1 end as [ФлагОтказКлиента]
 ,case when [Статус лида] ='Новый' then 1 end as [ФлагНовый]
 ,case when [Статус лида] = 'Профильный' then 1 end as [ФлагПрофильный]
 ,case when [Статус лида] in ('Отправлен в ЛКК','Отправлен в МП','Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) then 1 end as [ФлагПрофильныйИтог]
 ,case when [Статус лида] ='Думает' then 1 end as [ФлагДумает] 
 ,case when isnull(fa_lcrm.Номер, [Номер заявки (договор)]) is not null  then 1 end as [ФлагЗаявка]
 ,isnull(fa_lcrm.Номер,  fa.Номер)  Номер
 ,isnull(fa_lcrm.ДатаЗаявкиПолная, isnull(feodor.[Дата заявки], fa.ДатаЗаявкиПолная)) ДатаЗаявкиПолная
 ,Телефон =  isnull(fa_lcrm.Телефон,  fa.Телефон)  
 ,isnull(fa_lcrm.[Вид займа],  fa.[Вид займа])  [ВидЗайма]
 ,isnull(fa_lcrm.[Предварительное одобрение],  fa.[Предварительное одобрение])  [ПредварительноеОдобрение]
 ,isnull(fa_lcrm.[Контроль данных],  fa.[Контроль данных])   [КонтрольДанных]
 ,isnull(fa_lcrm.Одобрено,  fa.Одобрено)  Одобрено
 ,isnull(fa_lcrm.[Заем выдан],  fa.[Заем выдан])  [ЗаемВыдан]
 ,isnull(fa_lcrm.[Выданная сумма],  fa.[Выданная сумма])   [ВыданнаяСумма]
 ,ROW_NUMBER() over(partition by id order by [UF_PHONE] desc) rn_ins
 --,ROW_NUMBER() over(partition by id order by (select null)) rn_ins
 ,[Удален из обзвона]
 ,is_inst_lead = Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, UF_LOGINOM_PRIORITY)
 ,isnull(isnull(fa_lcrm.IsInstallment ,feodor.IsInstallment), Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, UF_LOGINOM_PRIORITY)) IsInstallment
 , [UF_PARTNER_ID аналитический] = case when  Analytics.dbo.lcrm_признак_корректного_заполнения_вебмастера(UF_SOURCE, UF_REGISTERED_AT)=1 then [UF_PARTNER_ID] end
 ,isnull(fa_blank.IsInstallment ,  Analytics.dbo.lcrm_is_inst_lead(UF_TYPE, UF_SOURCE, UF_LOGINOM_PRIORITY)) [IsInstallment crm]
, [Флаг технический дозвон]  
, [UF_LOGINOM_DECLINE]  
, [Результат коммуникации]  
, UF_STAT_AD_TYPE  
, UF_APPMECA_TRACKER  
, uf_stat_source  
 ,uf_regions_composite
 ,isnull(isnull(fa_lcrm.isPdl ,feodor.isPdl), 0) IsPdl
 ,lcrmnau.[seconds_to_pay]
 ,[Возврат] = r.[Возврат] 
 ,[IsPts возврат] = 1-r.[IsInstallment Возврат] 
 ,[Заем выдан возврат] = r.[Заем выдан Возврат]  
 ,[Выданная сумма возврат] = r.[Выданная сумма Возврат] 
 , [UF_STAT_CAMPAIGN]
 into #finalforins
 from
 #forj lcrmnau
 left join 
 #dm_Lead_tmp feodor on lcrmnau.id=try_cast(feodor.[ID LCRM] as numeric)
 left join #fa_tmp fa_lcrm on fa_lcrm.[LCRM ID]=lcrmnau.id and [is_lcrm]=1 and lcrmnau.UF_TYPE<>'api'
 left join 
 #fa_tmp fa on feodor.[Номер заявки (договор)]=fa.Номер and fa_lcrm.Номер is null
 left join 
 #fa_tmp fa_blank on fa_blank.[LCRM ID]=lcrmnau.id
 left join #returns    r   on r.[id возврат]=lcrmnau.id


 --select * from #finalforins
 --where companynaumen='Полная заявка'
--alter table feodor.dbo.dm_leads_history
--alter column [ЛогинПоследнегоСотрудника] nvarchar(256)
--
--alter table feodor.dbo.dm_leads_history add  [uuid] nvarchar(32)
--alter table feodor.dbo.dm_leads_history add  [ДатаЗаявкиПолная] datetime
--alter table feodor.dbo.dm_leads_history add  [Удален из обзвона] tinyint
--alter table feodor.dbo.dm_leads_history add  [is_inst_lead] tinyint
--alter table feodor.dbo.dm_leads_history add  [IsInstallment] bit
--alter table feodor.dbo.dm_leads_history add  [IsInstallment crm] tinyint
--ALTER TABLE feodor.dbo.dm_leads_history ADD  [IsInstallment crm] tinyint NOT NULL DEFAULT(1)
--ALTER TABLE feodor.dbo.dm_leads_history ADD  [Флаг технический дозвон] tinyint NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD  [UF_LOGINOM_DECLINE] nvarchar(128) NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD  [Результат коммуникации] nvarchar(255) NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD UF_STAT_AD_TYPE nvarchar(128) NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD UF_APPMECA_TRACKER nvarchar(128) NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD uf_stat_source varchar(128) NULL  
--alter table feodor.dbo.dm_leads_history add  [isPdl] tinyint
--ALTER TABLE feodor.dbo.dm_leads_history ADD uf_region_composite varchar(128) NULL  
--EXEC sp_RENAME 'dm_leads_history.uf_region_composite' , 'uf_regions_composite', 'column'
-- DROP INDEX [NCl_Idx_DateLeadLCRM] ON [dbo].[dm_leads_history]
--GO
--select distinct [Статус лида] from Feodor.dbo.dm_Lead

--ALTER TABLE feodor.dbo.dm_leads_history ADD [seconds_to_pay] bigint NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD [Возврат] [nvarchar](100) NULL  
--ALTER TABLE feodor.dbo.dm_leads_history ADD [IsPts возврат] [int] NULL 
--ALTER TABLE feodor.dbo.dm_leads_history ADD [Заем выдан возврат] [datetime] NULL 
--ALTER TABLE feodor.dbo.dm_leads_history ADD [Выданная сумма возврат] [numeric](15, 0) NULL 
--ALTER TABLE feodor.dbo.dm_leads_history ADD [UF_STAT_CAMPAIGN] varchar(512) NULL 






 declare @end_of_second_join datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'final clean'  param , getdate() dt , null as value


 delete from #finalforins where rn_ins<>1

 declare @end_of_second_final_clean datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'deleting from lh'  param , getdate() dt , null as value


while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin

waitfor delay '00:00:20'

end

 drop table if exists #finalforins2
 select a.* into #finalforins2 from #finalforins a
 join (
  select 
      [ID] [ID_]
      ,[UF_PHONE]
      ,[UF_ROW_ID]
      ,[UF_RC_REJECT_CM]
      ,[UF_LOGINOM_CHANNEL]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[creationdate]
      ,ЧислоПопыток
      ,[ВремяПоследнейПопытки]
      ,[FedorID]
      ,[FeodorReq]
      ,[СтатусЛидаФедор]
      ,[ПричинаНепрофильности]
      ,[Номер]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
	  ,uuid
	  ,[Удален из обзвона]
	  ,is_inst_lead
      ,IsInstallment
      ,[UF_PARTNER_ID аналитический]
      ,[IsInstallment crm]
      ,[Флаг технический дозвон]
      ,uf_appmeca_tracker
      ,uf_stat_source
      ,IsPdl
      ,uf_regions_composite
      ,[seconds_to_pay]
      ,[Возврат]  


	     from #finalforins
	  except
 select 
      [ID]
      ,[UF_PHONE]
      ,[UF_ROW_ID]
      ,[UF_RC_REJECT_CM]
      ,[UF_LOGINOM_CHANNEL]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[creationdate]
      ,ЧислоПопыток
      ,[ВремяПоследнейПопытки]
      ,[FedorID]
      ,[FeodorReq]
      ,[СтатусЛидаФедор]
      ,[ПричинаНепрофильности]
      ,[Номер]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
	  ,uuid
	  ,[Удален из обзвона]
	  ,is_inst_lead
      ,IsInstallment
      ,[UF_PARTNER_ID аналитический]
      ,[IsInstallment crm]
      ,[Флаг технический дозвон]
      ,uf_appmeca_tracker
      ,uf_stat_source
      ,IsPdl
      ,uf_regions_composite	 
      ,[seconds_to_pay]
      ,[Возврат]  

	  from Feodor.dbo.dm_leads_history a join (select id id_ from #finalforins) b on a.id=b.id_
	  where 1=1
	  ) x on x.id_=a.id
--alter table analytics.dbo.config add lh_lock_dt datetime2
	if exists( select top 1 1 d from  #finalforins2) 	   	  
	begin

begin try

while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end


update analytics.dbo.config set    lh_lock_dt = getdate()

 begin tran
 
 
--delete  a from feodor.dbo.dm_leads_history  a join #finalforins b on a.id=b.id
delete a from feodor.dbo.dm_leads_history_ids_to_update  a join #finalforins b on a.id=b.id
delete top(100000) a from feodor.dbo.dm_leads_history  a join #finalforins2 b on a.id=b.id	
while @@ROWCOUNT > 0
BEGIN
	delete top(100000) a from feodor.dbo.dm_leads_history  a join #finalforins2 b on a.id=b.id

END


 declare  @end_of_deleting_from_lh datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'inserting into lh'  param , getdate() dt , null as value

 insert into feodor.dbo.dm_leads_history
 select [ДатаОбновленияСтроки]
      ,[ДатаЛидаЛСРМ]
      ,[ID]
      ,cast(null as varchar(512) ) [UF_NAME]
      ,[UF_PHONE]
      ,[UF_REGISTERED_AT]
      ,[UF_ROW_ID]
      ,[UF_TYPE]
      ,[UF_RC_REJECT_CM]
      ,[UF_LOGINOM_CHANNEL]
      ,[UF_LOGINOM_GROUP]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[creationdate]
      ,[phonenumbers]
      ,[projecttitle]
      ,[lcrm_id]
      ,[attempt_start]
      ,[attempt_result]
      ,[speaking_time]
      ,[login]
      ,[title]
      ,[unblocked_time]
      ,[rn]
      ,[ЧислоПопыток]
      ,[ВремяПервойПопытки]
      ,[ВремяПоследнейПопытки]
      ,[ВремяПервогоДозвона]
      ,[ВремяПоследнегоДозвона]
      ,[ЧислоРазблокированныхСессий]
      ,[ФлагРазблокированнаяСессия]
      ,[ЧислоДозвонов]
      ,[ФлагДозвонПоЛиду]
      ,[ФлагНедозвонПоЛиду]
      ,[ЛогинПоследнегоСотрудника]
      ,[FedorID]
      ,[FedorLCRMID]
      ,[FeodorReq]
      ,[СтатусЛидаФедор]
      ,[ПричинаНепрофильности]
      ,[ПерезвонПоПоследнемуЗвонку]
      ,[ФлагНепрофильный]
      ,[ФлагОтправленВМП]
      ,[ФлагОтказКлиента]
      ,[ФлагНовый]
      ,[ФлагПрофильный]
      ,[ФлагПрофильныйИтог]
      ,[ФлагДумает]
      ,[ФлагЗаявка]
      ,[Номер]
      ,[Телефон]
      ,[ВидЗайма]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
	  ,[UF_SOURCE]
	  ,QueueDecision QueueDecision
	  ,[FedorДатаЛида]
	  ,ДатаЗаявкиПолная
	  ,timezone
	  ,uuid
	  ,[Удален из обзвона]
	  ,is_inst_lead
  ,IsInstallment
  ,[UF_PARTNER_ID аналитический]
  ,[IsInstallment crm]
  ,[Флаг технический дозвон]
  ,[UF_LOGINOM_DECLINE]
  ,[Результат коммуникации]
  , UF_STAT_AD_TYPE  
  , UF_APPMECA_TRACKER  
  , uf_stat_source  
  , uf_regions_composite  
  , IsPdl  
  
, [seconds_to_pay]
, [Возврат]  
, [IsPts возврат]  
, [Заем выдан возврат]  
, [Выданная сумма возврат]  
, [UF_STAT_CAMPAIGN]  


	  from #finalforins2
--exec tempdb..sp_help '#finalforins'
--  select * into finalforins  from #finalforins
 
 commit tran



  begin tran
 																				  				  
delete top(100000) a from feodor.dbo.dm_leads_history_light  a join #finalforins2 b on a.id=b.id	
while @@ROWCOUNT > 0
BEGIN
	delete top(100000) a from feodor.dbo.dm_leads_history_light  a join #finalforins2 b on a.id=b.id

END
		    
 insert into feodor.dbo.dm_leads_history_light
 select [ДатаОбновленияСтроки]
      ,[ДатаЛидаЛСРМ]
      ,[ID]
      ,cast(null as varchar(512) ) [UF_NAME]
      ,[UF_PHONE]
      ,[UF_REGISTERED_AT]
      ,[UF_ROW_ID]
      ,[UF_TYPE]
      ,[UF_RC_REJECT_CM]
      ,[UF_LOGINOM_CHANNEL]
      ,[UF_LOGINOM_GROUP]
      ,[UF_LOGINOM_PRIORITY]
      ,[UF_LOGINOM_STATUS]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,[creationdate]
      ,[phonenumbers]
      ,[projecttitle]
      ,[lcrm_id]
      ,[attempt_start]
      ,[attempt_result]
      ,[speaking_time]
      ,[login]
      ,[title]
      ,[unblocked_time]
      ,[rn]
      ,[ЧислоПопыток]
      ,[ВремяПервойПопытки]
      ,[ВремяПоследнейПопытки]
      ,[ВремяПервогоДозвона]
      ,[ВремяПоследнегоДозвона]
      ,[ЧислоРазблокированныхСессий]
      ,[ФлагРазблокированнаяСессия]
      ,[ЧислоДозвонов]
      ,[ФлагДозвонПоЛиду]
      ,[ФлагНедозвонПоЛиду]
      ,[ЛогинПоследнегоСотрудника]
      ,[FedorID]
      ,[FedorLCRMID]
      ,[FeodorReq]
      ,[СтатусЛидаФедор]
      ,[ПричинаНепрофильности]
      ,[ПерезвонПоПоследнемуЗвонку]
      ,[ФлагНепрофильный]
      ,[ФлагОтправленВМП]
      ,[ФлагОтказКлиента]
      ,[ФлагНовый]
      ,[ФлагПрофильный]
      ,[ФлагПрофильныйИтог]
      ,[ФлагДумает]
      ,[ФлагЗаявка]
      ,[Номер]
      ,[Телефон]
      ,[ВидЗайма]
      ,[ПредварительноеОдобрение]
      ,[КонтрольДанных]
      ,[Одобрено]
      ,[ЗаемВыдан]
      ,[ВыданнаяСумма]
	  ,[UF_SOURCE]
	  ,QueueDecision QueueDecision
	  ,[FedorДатаЛида]
	  ,ДатаЗаявкиПолная
	  ,timezone
	  ,uuid
	  ,[Удален из обзвона]
	  ,is_inst_lead
  ,IsInstallment
  ,[UF_PARTNER_ID аналитический]
  ,[IsInstallment crm]
  ,[Флаг технический дозвон]
  ,[UF_LOGINOM_DECLINE]
  ,[Результат коммуникации]
  , UF_STAT_AD_TYPE  
  , UF_APPMECA_TRACKER  
  , uf_stat_source  
  , uf_regions_composite  
  , IsPdl  
  
, [seconds_to_pay]
, [Возврат]  
, [IsPts возврат]  
, [Заем выдан возврат]  
, [Выданная сумма возврат]  
, [UF_STAT_CAMPAIGN]  


	  from #finalforins2
	  where [Канал от источника]<>'CPA нецелевой'
--exec tempdb..sp_help '#finalforins'
--  select * into finalforins  from #finalforins
 
 commit tran



 --drop table dm_leads_history_light
 --select top 0 * into dm_leads_history_light from feodor.dbo.dm_leads_history 









update analytics.dbo.config set    lh_lock_dt = null


 end try 
 begin	  catch
	select @@TRANCOUNT
	if @@TRANCOUNT>0
		rollback transaction
	
	;
update analytics.dbo.config set    lh_lock_dt = null
set @msg	=  'create_dm_leads_history error, @mode='+@mode+' ;@debug=' +format(@debug, '0')
exec analytics.dbo.log_email @msg
	;
	throw 


 end catch

 
 
	--create table feodor.dbo.[dm_leads_history_cube_days_to_update]
	--(
	-- [ДатаЛидаЛСРМ для обновления] date, created_at datetime2
	--)

 

end
else 
begin



delete a from feodor.dbo.dm_leads_history_ids_to_update  a join #finalforins b on a.id=b.id


end



insert
into feodor.dbo.[dm_leads_history_cube_days_to_update]

		   
select   a.[ДатаЛидаЛСРМ] [ДатаЛидаЛСРМ для обновления], getdate() created_at 
from #finalforins2			a
left join 	  feodor.dbo.[dm_leads_history_cube_days_to_update] b on a.[ДатаЛидаЛСРМ]=b.[ДатаЛидаЛСРМ для обновления]
	 where b.[ДатаЛидаЛСРМ для обновления] is null
group by [ДатаЛидаЛСРМ]


set @msg	=  'create_dm_leads_history finish, @mode='+@mode+' ;@debug=' +format(@debug, '0')

declare @text nvarchar(max) = 	   
@msg+
+char(10)
+char(10)+format((select count(*) from #finalforins), '0')+' in #finalforins'+
+char(10)+format((select count(*) from #finalforins2), '0')+' in #finalforins2'+
+char(10)+'dates in #finalforins '  +isnull((select 'from:'+format(min([ДатаЛидаЛСРМ]), 'dd-MM-yyyy')+'; to:' + format(max([ДатаЛидаЛСРМ]), 'dd-MM-yyyy')   from #finalforins)  , '')+
+char(10)+'dates in #finalforins2 ' +isnull((select 'from:'+format(min([ДатаЛидаЛСРМ]), 'dd-MM-yyyy')+'; to:' + format(max([ДатаЛидаЛСРМ]), 'dd-MM-yyyy')   from #finalforins2), '')
 
		  
exec analytics.dbo.log_email    @msg , default, @letter = 	  @text

							 							 							
if (select [notify_lh] from analytics.dbo.config)=1
select 1 d--exec analytics.dbo.log_email 'create_dm_leads_history @mode=lh'


if (select [notify_lh_once] from analytics.dbo.config)=1 and (select [notify_lh] from analytics.dbo.config)=1
update a set a.[notify_lh]=0 from analytics.dbo.config a

return


 
end


if @mode='cube'

begin


--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'aggregate lh'  param , getdate() dt , null as value



drop table if exists #days_to_Update
select  [ДатаЛидаЛСРМ для обновления] into #days_to_Update
from   feodor.dbo.[dm_leads_history_cube_days_to_update]
	group by [ДатаЛидаЛСРМ для обновления]




while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end

--declare @depth_id bigint = 1000000
--declare @date_update_cube date = cast(case when @depth_id>=1000000  then getdate()-1000
--	                                                else getdate()-30 end as date)
drop table if exists #dm_leads_history_cube_by_ДатаЛидаЛСРМ
select --top 100
       [ДатаЛидаЛСРМ]
      ,[UF_TYPE]
      ,uf_source
	  ,[UF_LOGINOM_PRIORITY]
	  ,[UF_LOGINOM_STATUS] 
	  ,[Канал от источника]
	  ,[ЛогинПоследнегоСотрудника]
      ,[Группа каналов]
      ,[CompanyNaumen]
	  ,count(id) ID
	  ,count(case when [CompanyNaumen]='Полная заявка' then getdate() else [creationdate] end) [creationdate]
	  ,count(case when [CompanyNaumen]='Полная заявка' then getdate() else ВремяПервойПопытки end) ВремяПервойПопытки
	  ,sum(case when [CompanyNaumen]='Полная заявка' then  1 else [ФлагРазблокированнаяСессия] end) [ФлагРазблокированнаяСессия]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then  1 else [ФлагДозвонПоЛиду]           end) [ФлагДозвонПоЛиду]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНедозвонПоЛиду]         end) [ФлагНедозвонПоЛиду]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ЧислоПопыток]               end) [ЧислоПопыток]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ПерезвонПоПоследнемуЗвонку] end) [ПерезвонПоПоследнемуЗвонку]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНепрофильный]           end) [ФлагНепрофильный]
      ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагНовый]                  end) [ФлагНовый]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагПрофильныйИтог]         end) [ФлагПрофильныйИтог]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагПрофильный]             end) [ФлагПрофильный]
	  ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагОтправленВМП]           end) [ФлагОтправленВМП]
      ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагОтказКлиента]           end) [ФлагОтказКлиента]
      ,sum(case when [CompanyNaumen]='Полная заявка' then null else [ФлагДумает]                 end) [ФлагДумает]
      ,sum(case when [CompanyNaumen]='Полная заявка' then 1 else [ФлагЗаявка]                 end) [ФлагЗаявка]
	  ,count([ПредварительноеОдобрение]                        ) [ПредварительноеОдобрение]
	  ,count([КонтрольДанных]) [КонтрольДанных]
	  ,count([Одобрено]) [Одобрено]
      ,count([ЗаемВыдан]) [ЗаемВыдан]
      ,sum([ВыданнаяСумма]) [ВыданнаяСумма]
	  ,sum(cast(datediff(minute, creationdate, [ВремяПервойПопытки]) as bigint)) DateDiff$creationdate$ВремяПервойПопытки
	  ,sum(cast(datediff(minute, [UF_REGISTERED_AT], [QueueDecision]) as bigint)) DateDiff$uf_registered_at$QueueDecision
	  ,sum(cast(datediff(minute, [UF_REGISTERED_AT], creationdate) as bigint)) DateDiff$uf_registered_at$creationdate
	  ,count(case when cast([creationdate] as date) = cast([ВремяПервойПопытки] as date) or ( [Удален из обзвона]=1) then [creationdate] end) [creationdate_day_in_day]
	  ,count(case when cast([creationdate] as date) = cast([ВремяПервойПопытки] as date) then [creationdate] end) [ВремяПервойПопытки_day_in_day]
	  ,count(case when [ВремяПервойПопытки] <= dateadd(second, 120, creationdate) then [creationdate] end) [ВремяПервойПопытки_0min_to_2min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 120, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 300 , creationdate) then [creationdate] end) [ВремяПервойПопытки_2min_to_5min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 300, creationdate) and [ВремяПервойПопытки] <= dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_5min_to_30min]
	  ,count(case when [ВремяПервойПопытки] > dateadd(second, 1800, creationdate) then [creationdate] end) [ВремяПервойПопытки_30min_and_more]
	  ,getdate() as created_at
	  ,login
	  ,cast(creationdate as date) [creationdate день]
	  ,[is_inst_lead]
	  ,IsInstallment
	  ,[UF_PARTNER_ID аналитический]
	  ,[ПричинаНепрофильности]
	  ,case when [ФлагДозвонПоЛиду]=1 then 1 else 0 end [ФлагДозвонПоЛиду 1/0]
	  ,case when [ФлагЗаявка]=1 then 1 else 0 end [ФлагЗаявка 1/0]
	  ,[СтатусЛидаФедор]
	  ,case when [ФлагПрофильныйИтог] =1 then 1 else 0 end [Флаг профильный итог 1/0]
	  ,sum([Флаг технический дозвон]) [Флаг технический дозвон]
	  , IsPdl
	  ,sum([seconds_to_pay]) [seconds_to_pay]
	  ,[IsPts возврат]  
      ,count([Выданная сумма возврат]  ) [Заем выдан возврат]
      ,sum([Выданная сумма возврат]  ) [Выданная сумма возврат]
	  , min(id) example_of_leadid
	  ,[UF_STAT_CAMPAIGN]

	  into #dm_leads_history_cube_by_ДатаЛидаЛСРМ
	  FROM [Feodor].[dbo].[dm_leads_history] l --with(index=[NCL_idx_date_chanel_company])
	  join #days_to_Update d on d.[ДатаЛидаЛСРМ для обновления]=l.[ДатаЛидаЛСРМ]
	  
	-- where ДатаЛидаЛСРМ >= getdate()-1
	  group by 
	  [ДатаЛидаЛСРМ]
      ,[UF_TYPE]
      ,uf_source
	  ,[UF_LOGINOM_PRIORITY]
	  ,[UF_LOGINOM_STATUS] 
	  ,[Канал от источника]
	  ,[ЛогинПоследнегоСотрудника]
	  ,login
      ,[Группа каналов]
      ,[CompanyNaumen]
      ,cast(creationdate as date) 
      ,[is_inst_lead]
      ,IsInstallment
      ,[UF_PARTNER_ID аналитический]
      ,[ПричинаНепрофильности]
      ,case when [ФлагДозвонПоЛиду]=1 then 1 else 0 end 
	  ,case when [ФлагЗаявка]=1 then 1 else 0 end 
	  ,[СтатусЛидаФедор]
	  ,case when [ФлагПрофильныйИтог] =1 then 1 else 0 end
	  , IsPdl
	  , [IsPts возврат]
	  ,[UF_STAT_CAMPAIGN]

	
	--exec analytics.dbo.create_table '#dm_leads_history_cube_by_ДатаЛидаЛСРМ'

-- begin tran
--	  drop table if exists  [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
--	  select * into  [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] from #dm_leads_history_cube_by_ДатаЛидаЛСРМ
--
--
--CREATE CLUSTERED INDEX [ClusteredIndex-20200831-171325] ON [dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
--(
--[ДатаЛидаЛСРМ]
--,[UF_TYPE]
--,uf_source
--,[UF_LOGINOM_PRIORITY]
--,[UF_LOGINOM_STATUS] 
--,[Канал от источника]
--,[ЛогинПоследнегоСотрудника]
--,login
--,[Группа каналов]
--,[CompanyNaumen]
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
--commit tran
	--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
	--alter column [ФлагДозвонПоЛиду 1/0] int
	
	--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
	--alter column [СтатусЛидаФедор] int

	--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
	--add [is_inst_lead] tinyint
	
	--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
	--add [IsInstallment] bit

	
	--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
	----drop Constraint_name --tinyint CONSTRAINT Constraint_name DEFAULT 1 WITH VALUES
	--drop column [IsInstallment crm] --tinyint CONSTRAINT Constraint_name DEFAULT 1 WITH VALUES

	
--alter table feodor.dbo.dm_leads_history add [UF_PARTNER_ID аналитический] nvarchar(128)
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [UF_PARTNER_ID аналитический] nvarchar(128)
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [ПричинаНепрофильности] nvarchar(255)
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] drop column [ФлагДозвонПоЛиду 1/0] 
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] drop column [ФлагЗаявка 1/0] 
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] drop column [СтатусЛидаФедор] 
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [ФлагДозвонПоЛиду 1/0] int
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [ФлагЗаявка 1/0] int
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [СтатусЛидаФедор] nvarchar(255)
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [Флаг профильный итог 1/0] int
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [Флаг технический дозвон] int
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [isPdl] tinyint
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [seconds_to_pay] bigint
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [IsPts возврат] tinyint
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [Заем выдан возврат]  int
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [Выданная сумма возврат]  numeric(38,0)
--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add example_of_leadid  numeric(38,0)

--alter table [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] add [UF_STAT_CAMPAIGN] nvarchar(512)

	 


--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'delete from lh_cube'  param , getdate() dt , null as value

	  begin tran
	  
delete l from  [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ] l join #days_to_Update d on d.[ДатаЛидаЛСРМ для обновления]=l.[ДатаЛидаЛСРМ] --where ДатаЛидаЛСРМ >= @date_update_cube
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'insert into lh_cube'  param , getdate() dt , null as value

insert into  [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
select * from #dm_leads_history_cube_by_ДатаЛидаЛСРМ

commit tran
--select * from   feodor.dbo.[dm_leads_history_cube_days_to_update]
delete a from 	   feodor.dbo.[dm_leads_history_cube_days_to_update]	a
join  #days_to_Update b on a.[ДатаЛидаЛСРМ для обновления]=b.[ДатаЛидаЛСРМ для обновления]

set @msg	=  'create_dm_leads_history finish, @mode='+@mode+' ;@debug=' +format(@debug, '0') + ' ;days count'+format(@@rowcount, '0')
exec analytics.dbo.log_email @msg

return


											 
	end

--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'calculate dm_leads_history_by_hours'  param , getdate() dt , null as value


if @mode = 'by_hour'
begin

	  drop table if exists #hours_of_day

select cast('00:00:00' as time) h into #hours_of_day union all
select cast('01:00:00' as time)	union all
select cast('02:00:00' as time)	union all
select cast('03:00:00' as time)	union all
select cast('04:00:00' as time)	union all
select cast('05:00:00' as time)	union all
select cast('06:00:00' as time)	union all
select cast('07:00:00' as time)	union all
select cast('08:00:00' as time)	union all
select cast('09:00:00' as time)	union all
select cast('10:00:00' as time)	union all
select cast('11:00:00' as time)	union all
select cast('12:00:00' as time)	union all
select cast('13:00:00' as time)	union all
select cast('14:00:00' as time)	union all
select cast('15:00:00' as time)	union all
select cast('16:00:00' as time)	union all
select cast('17:00:00' as time)	union all
select cast('18:00:00' as time)	union all
select cast('19:00:00' as time)	union all
select cast('20:00:00' as time)	union all
select cast('21:00:00' as time)	union all
select cast('22:00:00' as time)	union all
select cast('23:00:00' as time) union all
select cast('23:59:59' as time)


	  drop table if exists #dates_calendar

 select дата  d into #dates_calendar from Analytics.dbo.v_Calendar
 where дата between getdate()-3 and cast(getdate() -1 as date)
 ;
 drop table if exists #rez

 
while (select max(lh_lock_dt) from analytics.dbo.config )  is not null

begin waitfor delay '00:00:20'--ожидание 	lh_lock_dt в analytics.dbo.config  
end

 ;
 with v as (

 select [creationdate] 
 ,CompanyNaumen
 ,[Канал от источника]
 ,[Группа каналов]
 , is_inst_lead
 , IsInstallment
 , [FedorДатаЛида] [Дата лида]
 , [ДатаЗаявкиПолная] [Дата Заявки]
 ,[СтатусЛидаФедор] [Статус лида]
 ,[ФлагОтправленВМП]  [Отправлен в МП]
 , id 
 , uf_source
 , [uf_partner_id аналитический]
 ,  [ВремяПервойПопытки]
 , [ВремяПервогоДозвона]
 , isPdl
  from Feodor.dbo.dm_leads_history

 )

 select crd_d,  end_t, [Группа каналов], [Канал от источника]
 , is_inst_lead
 ,IsInstallment
 ,CompanyNaumen
 , count(creationdate) [Поступило лидов]
 , COUNT(ВремяПервойПопытки) [Обработано лидов]
 , COUNT(ВремяПервогоДозвона) [Дозвонились]
 , COUNT(FedorДатаЛида) [Лидов Feodor]
 , COUNT(FedorДатаПрофильногоЛида) [Профильных лидов Feodor]
 , COUNT([Дата Заявки]) [Создано заявок]
 , uf_source
 , [uf_partner_id аналитический]
 , isPdl

 into #rez 
 
 from (
 select  cast(c.creationdate as date) crd_d
 
 ,  id
 ,  creationdate
 , case when cast(ВремяПервойПопытки        as date)= cast(c.creationdate as date) and cast(ВремяПервойПопытки          as time)<=b.h then ВремяПервойПопытки       end  ВремяПервойПопытки         
 , case when cast(ВремяПервогоДозвона		as date)= cast(c.creationdate as date) and cast(ВремяПервогоДозвона		    as time)<=b.h then ВремяПервогоДозвона		end  ВремяПервогоДозвона		
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h then [Дата лида]			end FedorДатаЛида				
  ,case when cast([Дата лида]				as date)= cast(c.creationdate as date) and cast([Дата лида]				as time)<=b.h and  ([Статус лида] in ('Отправлен в ЛКК','Отправлен в МП', 'Отказ клиента с РСВ', 'Отказ клиента без РСВ', 'Профильный', 'Заявка'/*, 'Думает'*/) or [Отправлен в МП]=1) then [Дата лида]			end FedorДатаПрофильногоЛида				
 , case when cast([Дата Заявки]			as date)= cast(c.creationdate as date) and cast([Дата Заявки] 			as time)<=b.h then [Дата Заявки]			end  [Дата Заявки]			


 , b.h  end_t
 , [Группа каналов]
 , [Канал от источника]
 , CompanyNaumen
 , is_inst_lead
 , IsInstallment
 , uf_source
 , [uf_partner_id аналитический]
 , isPdl
 from #hours_of_day  b 
 cross join #dates_calendar  d
 left join  v--#lh
 c --with(nolock) 
 on cast(c.creationdate as date)= cast(d.d as date) and cast( c.creationdate as time) < b.h
   where --cast(c.creationdate as date)>=cast(getdate()-2 as date) and
 --and [Канал от источника]<>'cpa нецелевой'
 --order by a.h, b.h, c.creationdate
   cast(d.d  as datetime) + cast(b.h  as datetime)<getdate()

-- and id=525324345
) x
group by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment ,CompanyNaumen, [uf_partner_id аналитический], uf_source	  , isPdl
order by crd_d,  end_t, [Группа каналов], [Канал от источника], is_inst_lead,IsInstallment ,CompanyNaumen, [uf_partner_id аналитический], uf_source	  , isPdl
 --order by a.h, b.h, c.creationdate

begin tran

--drop table if exists feodor.dbo.dm_leads_history_by_hours
--DWH-1764
delete a from  dbo.dm_leads_history_by_hours a
left join #rez b on a.crd_d=b.crd_d
where b.crd_d is not null or a.crd_d<getdate()-14
--alter TABLE dbo.dm_leads_history_by_hours
--add UF_SOURCE nvarchar(128) 
--alter TABLE dbo.dm_leads_history_by_hours
--add [uf_partner_id аналитический] nvarchar(128)  
--alter TABLE dbo.dm_leads_history_by_hours
--add isPdl tinyint
DROP INDEX IF EXISTS [ClusteredIndex-hour-and-date] ON feodor.dbo.dm_leads_history_by_hours

INSERT feodor.dbo.dm_leads_history_by_hours
(
    crd_d,
    end_t,
    [Группа каналов],
    [Канал от источника],
    is_inst_lead,
    IsInstallment,
    CompanyNaumen,
    [Поступило лидов],
    [Обработано лидов],
    Дозвонились,
    [Лидов Feodor],
    [Профильных лидов Feodor],
    [Создано заявок]
	,
	uf_source
	,	[uf_partner_id аналитический]
	,	isPdl
)
SELECT 
	crd_d,
    end_t,
    [Группа каналов],
    [Канал от источника],
    is_inst_lead,
    IsInstallment,
    CompanyNaumen,
    [Поступило лидов],
    [Обработано лидов],
    Дозвонились,
    [Лидов Feodor],
    [Профильных лидов Feodor],
    [Создано заявок] ,
	uf_source,
	[uf_partner_id аналитический]					,
	isPdl
--INTO feodor.dbo.dm_leads_history_by_hours
from #rez




commit tran
	
	  CREATE CLUSTERED INDEX [ClusteredIndex-hour-and-date] ON feodor.dbo.dm_leads_history_by_hours
(
	[crd_d] ASC,
	[end_t] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]


			   

set @msg	=  'create_dm_leads_history finish, @mode='+@mode+' ;@debug=' +format(@debug, '0') + ' ;days count'+format(@@rowcount, '0')
exec analytics.dbo.log_email @msg


	  	  declare @end_of_inserting_lh datetime = getdate()
--insert into dm_leads_history_update_log select (select top 1 id from #start_creating_lh) id, 'end'  param , getdate() dt , null as value




--alter table feodor.dbo.dm_leads_history alter  column uf_name  varchar(512)

return


end
		   

if @mode = 'get_ids'
begin
  drop table if exists #ids_to_update_
  SELECT  a.id 
    into #ids_to_update_
  FROM 
  stg._LCRM.lcrm_leads_full_calculated a with(nolock)
  left join [Feodor].[dbo].[dm_leads_history] lh with(nolock) on a.id=lh.id
  left join Feodor.dbo.dm_case_uuid_to_lcrm_references rr with(nolock) on rr.lcrm_id=lh.id
  left join Feodor.dbo.dm_calls_history ch with(nolock) on ch.lcrm_id=lh.id
 --left join #dm_Lead_tmp lead on try_cast(lead.[ID LCRM] as numeric)=lh.id
  where  
  (
  (a.id is not null and lh.id is null)
  or (ch.lcrm_id is not null and ВремяПервойПопытки is null)
  or (ch.login is not null and ВремяПервогоДозвона is null) 
  or (rr.creationdate is not null and lh.creationdate is null)
  or (a.UF_UPDATED_AT > ДатаОбновленияСтроки) 
  or (ch.attempt_start > ДатаОбновленияСтроки) 
  or (ch.attempt_start>lh.ВремяПоследнейПопытки)
  or (ch.connected is not null and lh.[Флаг технический дозвон]  is null)
  )

  insert into dm_leads_history_ids_to_update
  select a.id from #ids_to_update_	a
  left join dm_leads_history_ids_to_update b on a.id=b.id
  group by a.id

end


if @mode = 'get_ids_2_days'
begin
  drop table if exists #ids_to_update_2
  SELECT  a.id 
  into #ids_to_update_2
  FROM 
  stg._LCRM.lcrm_leads_full_calculated a with(nolock)
  left join [Feodor].[dbo].[dm_leads_history] lh with(nolock) on a.id=lh.id
  left join Feodor.dbo.dm_case_uuid_to_lcrm_references rr with(nolock) on rr.lcrm_id=lh.id
  left join Feodor.dbo.dm_calls_history ch with(nolock) on ch.lcrm_id=lh.id
  where  
  a.UF_REGISTERED_AT_date>=getdate()-2 and (
  (a.id is not null and lh.id is null)
  or (ch.lcrm_id is not null and ВремяПервойПопытки is null)
  or (ch.login is not null and ВремяПервогоДозвона is null) 
   or (rr.creationdate is not null and lh.creationdate is null)
  or (a.UF_UPDATED_AT > ДатаОбновленияСтроки) 
  or (ch.attempt_start > ДатаОбновленияСтроки) 
  or (ch.attempt_start>lh.ВремяПоследнейПопытки)
  or (ch.connected is not null and lh.[Флаг технический дозвон]  is null)
  )
  and 1=0

  insert into dm_leads_history_ids_to_update
  select a.id from #ids_to_update_2	a
  left join dm_leads_history_ids_to_update b on a.id=b.id


  group by a.id


  
set @msg	=  'create_dm_leads_history finish, @mode='+@mode+' ;@debug=' +format(@debug, '0') + ' ;days count'+format(@@rowcount, '0')
exec analytics.dbo.log_email @msg


end


 end









