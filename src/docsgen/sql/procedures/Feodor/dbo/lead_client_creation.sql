CREATE proc [dbo].[lead_client_creation]	  @date1 date 	  --exec 	[dbo].[lead_client_creation]	 '20240808'exec 	[dbo].[lead_client_creation]	 '20240805' exec 	[dbo].[lead_client_creation]	 '20240806'exec 	[dbo].[lead_client_creation]	 '20240807'	  exec 	[dbo].[lead_client_creation]	 '20240425'		  exec 	[dbo].[lead_client_creation]	 '20240426'		  exec 	[dbo].[lead_client_creation]	 '20240427'	   exec 	[dbo].[lead_client_creation]	 '20240428'
as
begin

			select @date1, 'start'
				   declare @date date = @date1
				  -- declare @date1 date = '20240926'	 declare @date date = @date1
			select @date1, 'start'

				   declare @datetime datetime = getdate() 


drop table if exists #loans
select [Заем выдан] created  ,  isnull( [Заем погашен] , getdate()+10000) closed,    Телефон phone, Номер, isPts ispts into #loans 	  
from analytics.dbo.mv_dm_Factor_Analysis 
where [Заем выдан] is not null	  and [Заем выдан]<='20231129'

insert into 	 #loans
select [Дата выдачи], [Дата погашения], [Телефон договор CMR], [Номер заявки], 1- isInstallment  isPts
from analytics.dbo.mv_loans 
where [Номер заявки] not in (select Номер from #loans)


   --drop table if exists #v_request
   --select ispts, Телефон, [Верификация КЦ], Одобрено, Отказано,  ДатаЗаявки, original_lead_id  , marketing_lead_id  marketing_lead_id   into 	#v_request from Analytics.DBO.v_request
			--	  -- declare @date date = '20240425'
	 
drop table if exists #green
select cdate, phone into 	#green 
from (
select   cdate
, phone 
 
--into #green 		  select * 
from dwh2.[marketing].[povt_inst]
where  	market_proposal_category_code = 'green' 
union 		   all
select   cdate
, phone 	 
from dwh2.[marketing].[povt_pdl]
where  	market_proposal_category_code = 'green' 

 ) x
 where cdate =@date-- between   '20240601'  and '20240701'
 group by  cdate
, phone 

   drop table if exists #v_lead

 create table #v_lead (
    id nvarchar(36), 
    created datetime2(0),  
    phone nvarchar(10) 
)

 
     insert into #v_lead
     select --top (100000000)
         a.id, 
         a.UF_REGISTERED_AT created ,
		 uf_phone phone 
     
 
     from lead a with(nolock)
 	
   --  where  cast(a.created as date) = @date-- between  cast( @date as datetime2(0)) and dateadd(SECOND, -1, dateadd(day, 1, cast( @date as datetime2(0)) )  )
     where  a.UF_REGISTERED_AT   between  cast( @date as datetime2(0)) and dateadd(SECOND, -1, dateadd(day, 1, cast( @date as datetime2(0)) )  )

	   drop table if exists #phone
	   select   phone phone , max(created) created_max  , min(created) created_min  into #phone from 
	 #v_lead
	 group by  phone
 

   drop table if exists #auto_answers_by_phone

	 select    b.phone,  attempt_start  auto_answer_attempt_start

	 into #auto_answers_by_phone
	 from 
  NaumenDbReport.dbo.dm_call_auto_answer	a with(nolock)
  join 	#phone b on	  a.client_number=b.phone	--and a.attempt_start between dateadd(day, -90, cast(created_min as date)) and   b.created_max
  and a.lcrm_channel='cpa нецелевой'
--where 1=0


   
  drop table if exists #lead_decline
 select a.id 
 , case 
when  max(case when l.closed> a.created and l.ispts=1 then 'Докред ПТС' else '' end) <> '' then 	'Докред ПТС'
when  max(case when l.closed> a.created and l.ispts=0 then 'Докред БЗ' else '' end)  <>'' then    'Докред БЗ'
when  max(case when l.closed<= a.created and l.ispts=1 then 'Повт ПТС' else '' end) 	<> '' then 		'Повт ПТС'
when  max(case when l.closed<= a.created and l.ispts=0 then 'Повт БЗ' else '' end)	   	<> '' then 		'Повт БЗ'
  	 end
   
  credit_type
  ,max(case when g.cdate is not null then 1  end ) is_green_bz
  ,max(aa.auto_answer_attempt_start ) last_nontarget_auto_answer_call
 
into #lead_decline
from #v_lead	a	 
left join #loans  l on a.phone=l.phone and l.created<=a.created
left join #green g on g.phone=a.phone and g.cdate=cast(a.created as date)
left join #auto_answers_by_phone aa on aa.phone=a.phone and aa.auto_answer_attempt_start<a.created	--and aa.auto_answer_attempt_start>=dateadd(day, -90, cast(a.created as date))
group by a.id

 
 

   drop table if exists #lead_source


select a.id id_
, a.credit_type
 
, is_green_bz
, last_nontarget_auto_answer_call
 
 

, HASHBYTES('SHA2_256',  
'|'+isnull(cast( a.credit_type				       as nvarchar(36))		, '') +
 
'|'+isnull(cast( is_green_bz			   as nvarchar(36))	, '') +
'|'+isnull(cast( last_nontarget_auto_answer_call			   as nvarchar(36))	, '') --+
 

)hash_client

	into #lead_source
from 	 #lead_decline a
--join   #v_lead3 b on a.ID=b.ID

declare @total  bigint = (select count(*) cnt from 	#lead_source)	 
--select * from #lead_source
--select * from #ids_for_upd 

--delete  a from #lead_source a join feodor.dbo.lead b with(nolock) on a.id_=b.id and a.hash_client=b.hash_client

--select @@rowcount, 'УДАЛЕНО ТАК КАК УЖЕ СОХРАНЕНЫ'
	 -- select * from #lead_source
 
				
declare @rc  bigint = 0		 
declare @total_done  bigint = 0			 
declare @sql nvarchar(max) =  '
drop table if exists #ids_for_upd
select top 200000 * into #ids_for_upd from #lead_source 
if @@rowcount=0 select 1/0 
begin tran

DECLARE @Result INT;
EXEC @Result = sp_getapplock @Resource = ''MergeLock'', @LockMode = ''Exclusive'' 


IF @Result >= 0
BEGIN
    BEGIN TRY
; MERGE feodor.dbo.[lead] AS target
    USING ( select    	 a.* from  #ids_for_upd  a  ) AS source
    ON target.ID = source.ID_ --and isnull(target.hash_client, '''')<>source.hash_client
    WHEN MATCHED THEN  UPDATE SET
	  target.is_green_bz  =		source.is_green_bz 
,	 target.last_nontarget_auto_answer_call  =		source.last_nontarget_auto_answer_call 
,   target.row_updated 						= getdate()		
,   target.credit_type  				  =   source.credit_type  			
,   target.hash_client 				    =	  source.hash_client 
; declare @rc_dynamic  bigint = @@rowcount
 ; EXEC sp_releaseapplock @Resource = ''MergeLock'';

        COMMIT TRANSACTION;
      --  exec analytics.dbo.log_email ''loop ok''

	    END TRY
    BEGIN CATCH
        -- Освобождение блокировки в случае ошибки
        EXEC sp_releaseapplock @Resource = ''MergeLock'';
        exec analytics.dbo.log_email ''lead_client error transaction''
        -- Обработка ошибок
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
ELSE
BEGIN
    -- Не удалось получить блокировку, обработка ошибки
    PRINT ''Не удалось получить блокировку'';
     exec analytics.dbo.log_email ''lead_client critical error Не удалось получить блокировку''

    ROLLBACK TRANSACTION;
END

delete  a from #lead_source a join #ids_for_upd b on a.id_=b.id_ 

'

exec (@sql)
set @rc = @@ROWCOUNT
set @total_done = @total_done +@rc


while @rc>0 
begin
exec (@sql )
set @rc = @@ROWCOUNT
set @total_done = @total_done +@rc
select 'loop goes on',  getdate(), @total_done/ (@total+0.0) as completed
exec analytics.dbo.sp_message
if @rc = 0 return 



 end
 

 end