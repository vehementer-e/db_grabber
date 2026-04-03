 --exec [mail_report_leadgen] 'vsegdada-ref', 1
--drop proc [mail_report_leadgen]   @source   varchar(max) =   null ,   @add_ts  bigint = 0, @add_subj    varchar(max) =   ''
CREATE   proc [dbo].[marketing_mail_report_leadgen]   @source   varchar(max) =   null
as 

--drop table if exists #t1

--select id, seconds_to_pay, phone, attempt_result   from v_lead2
--where date ='20240924' and channel='cpa нецелевой'
--and attempted is not null


--select * from   [История запросов] where 	[log_datetime]>=getdate()-1 and session_id=468 and 	[login_name]='CM\P.Ilin' and 	[host_name]='C2-VSR-DWH2' order by 1


--create synonym lead_cube for feodor.dbo.lead_cube

if @source <> '' and @source in (select source from v_source)
begin
declare @source_date date = (select created from v_source where source = @source)
drop table if exists #t1

select   даталидалсрм date, sum(id) lead_cnt into #t1 from lead_cube where uf_source=@source
group by  даталидалсрм

drop table if exists #t2

select cast( call1  as date) date 
, count(case when ispts=1 then call1 end)   call1_pts 
, count(case when ispts=0 then call1 end)   call1_nopts 
, count(case when ispts=1 then issued end)  issued_pts 
, count(case when ispts=0 then issued end)  issued_nopts
, sum(case when ispts=1 then issuedSum end) issuedSum_pts 
, sum(case when ispts=0 then issuedSum end) issuedSum_nopts

into #t2


from v_fa where source = @source and call1>='20240425'
 group by cast( call1  as date) 
 
 --begin
 
   SELECT TOP 30 
  format(  ISNULL(a.date, b.date), 'yyyy-MM-dd') AS дата,
    a.lead_cnt AS колво,
    b.call1_pts AS кол1_птс,
    b.issued_pts AS выдано_птс,
    b.issuedSum_pts AS сумма_птс,
    b.call1_nopts AS кол1_беззалог,
    b.issued_nopts AS выдано_беззалог,
    b.issuedSum_nopts AS сумма_беззалог
FROM #t1 a 
FULL OUTER JOIN #t2 b ON a.date = b.date
UNION ALL

SELECT 
  'month - '+ format(cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    ISNULL(a.date, b.date)       ), 0) as date) , 'yyyy-MM-dd') 
   AS дата,
    SUM(a.lead_cnt) AS колво,
    SUM(b.call1_pts) AS кол1_птс,
    SUM(b.issued_pts) AS выдано_птс,
    SUM(b.issuedSum_pts) AS сумма_птс,
    SUM(b.call1_nopts) AS кол1_беззалог,
    SUM(b.issued_nopts) AS выдано_беззалог,
    SUM(b.issuedSum_nopts) AS сумма_беззалог
FROM #t1 a 
FULL OUTER JOIN #t2 b ON a.date = b.date
 where  ISNULL(a.date, b.date)>='20240501'
 
 group by 
  'month - '+ format(cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    ISNULL(a.date, b.date)       ), 0) as date) , 'yyyy-MM-dd') 

ORDER BY 1 --DESC;
   
   
   
   
 --  , default,  @html output	   
 --   select @html

	--exec msdb.dbo.sp_send_dbmail   
	--    @profile_name = null,  
	--	    @recipients = 'p.ilin@smarthorizon.ru',  
	--		    @body = @html,  
	--			    @body_format = 'html',  
	--				    @subject = @subject
	--					end
end


