CREATE   proc [dbo].[lead_ttc_first_case_creation]
@start_date date = null 	 ,
@table  [lead_ttc_first_caseType] readonly

-- declare @start_date  date =  getdate()-3	 exec lead_ttc_first_case_creation 	 @start_date

as
begin

   select 'ok'


declare @start_dt datetime = getdate()
declare @id nvarchar(36) = newid()

--select @id id, @start_dt start_dt, @@ROWCOUNT RC, cast('' as nvarchar(max)) description, getdate()  dt into    lead_ttc_first_case_log
--insert into    lead_ttc_first_case_log
--select @id id, @start_dt start_dt, @@ROWCOUNT RC, cast('' as nvarchar(max)) description, getdate()  dt  


--declare @start_date  date = '20240425'
--declare @start_date  date =  getdate()-3	

declare @exists int		= 0 

if  exists (select top 1 * from 	 @table)
set   @exists = 1

drop table if exists #t1

select id, created_at, called_at, creationdatecc ttc_first_case, РабочееВремя is_work_time into #t1 from  Analytics.dbo.report_TTC_details2
where 	created_at>=	@start_date		  and creationdatecc is not null    and РабочееВремя is not null
		and 0=@exists

		if 	@exists>0
		insert into #t1 
		select 	uuid id	 , created_at,  called_at	, ttc_first_case	, is_work_time from 	@table


   select 'ok'


drop table if exists #t3

select   a.*,  isnull(b.original_lead_id, c.lead_id ) lead_id into #t3  from  #t1 a
left join Analytics.dbo. lead_case_crm b on a.id=b.uuid	   and b.creationdate>= isnull(@start_date, '20240425')
left join naumendbreport.dbo.mv_custom_form c on c.owneruuid=a.id	 and c.creationdate>= isnull(@start_date, '20240425')
 

--select top 100 * from report_TTC_details2

;
with v as (select * , row_number() over(partition by  lead_id order by  	isnull(called_at, getdate())  ) rn  from #t3 ) delete from v where rn>1 or 	 lead_id is null


 
drop table if exists #changed


select a.id into #changed from #t3	a  
left join lead b with(nolock) on a.lead_id=b.id
where b.id is null

declare @a leadtype 

insert into  @a
  select  id from 	#changed
  if exists(select top 1 * from #changed where id is not null)
exec lead_creation 		@a, null


delete a from  #t3 a  join 	 [lead] b with(nolock) on a.lead_id=b.id and a.ttc_first_case=b.ttc_first_case  and a.is_work_time=b.is_work_time
 
--where b.id is not null or 
;


begin tran
DECLARE @Result INT;
EXEC @Result = sp_getapplock @Resource = 'MergeLock', @LockMode = 'Exclusive'--, @LockTimeout = 300000; -- 5 минут


IF @Result >= 0
BEGIN
    BEGIN TRY
 ;  
	    MERGE feodor.dbo.[lead] AS target
    USING (
select 
    a.lead_id id 
,   a.ttc_first_case
,   a.is_work_time	   is_work_time

from 

#t3 a	   ) AS source
    ON target.ID = source.ID	 and format(source.ttc_first_case, '0')+'\'+format(source.is_work_time, '0')<> format(isnull(target.ttc_first_case, -1), '0') 	+'\'+format(isnull(target.is_work_time, -1), '0')
    WHEN MATCHED THEN
        UPDATE SET
    target.ttc_first_case 				=  source.ttc_first_case 								
,   target.is_work_time 						=  source.is_work_time				  
,   target.row_updated 						= getdate()						  
 
  ;
 select @@ROWCOUNT	  , 'lead - TTC updated'
 	EXEC sp_releaseapplock @Resource = 'MergeLock';

commit tran



	    END TRY
    BEGIN CATCH
        -- Освобождение блокировки в случае ошибки
        EXEC sp_releaseapplock @Resource = 'MergeLock';
        exec analytics.dbo.log_email 'lead_creation error transaction'
        -- Обработка ошибок
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
ELSE
BEGIN
    -- Не удалось получить блокировку, обработка ошибки
    PRINT 'Не удалось получить блокировку';
     exec analytics.dbo.log_email 'lead_creation critical error Не удалось получить блокировку'

    ROLLBACK TRANSACTION;
END

--alter table [lead] add 	  ttc_first_case bigint
--alter table [lead] add 	  is_work_time tinyint



 end


