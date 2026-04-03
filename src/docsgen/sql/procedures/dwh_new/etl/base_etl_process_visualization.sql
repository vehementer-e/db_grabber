-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl process_visualization

--
--  exec etl.base_etl_process_visualization

-- =============================================
CREATE PROC etl.base_etl_process_visualization
    
as
begin

	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''

 begin try

    /*
  -- убрано 15-04-2019
    insert into  tmp_v_credits
        select *     FROM v_credits
        */
-- добавлено 15-04-2019
-- для view  v_credits _ssis предварительно нужно материализовать view m_contribution_margin
--if object_id('[dbo].[mv_m_contribution_margin]') is not null drop table [dbo].[mv_m_contribution_margin]
--DWH-1764

--DWH-2514. комментарю
/*
TRUNCATE TABLE dbo.mv_m_contribution_margin

INSERT dbo.mv_m_contribution_margin
(
    external_id,
    period,
    qty,
    result,
    prc_inc,
    prc_out,
    final_loss,
    commission,
    callcentre_cost,
    opcentre_cost,
    payment_system_cost,
    dynamic_cost,
    collection90,
    collection91,
    collection,
    stage_cost_cc,
    stage_cost_oc,
    stage_cost_ov
)
SELECT  [external_id]
      ,[period]
      ,[qty]
      ,[result]
      ,[prc_inc]
      ,[prc_out]
      ,[final_loss]
      ,[commission]
      ,[callcentre_cost]
      ,[opcentre_cost]
      ,[payment_system_cost]
      ,[dynamic_cost]
      ,[collection90]
      ,[collection91]
      ,[collection]
      ,[stage_cost_cc]
      ,[stage_cost_oc]
      ,[stage_cost_ov]
      --into [dbo].[mv_m_contribution_margin]
  FROM [dbo].[m_contribution_margin]
*/

  begin tran
   delete from tmp_v_credits
        insert into  tmp_v_credits
        select *     FROM v_credits_ssis
   commit tran


  --/добавлено  15-04-2019
  /*
    if object_id('visualization.tmp1') is not null drop table visualization.tmp1
    select * into visualization.tmp1 from visualization.v_tmp1
        order by request_date ;

    truncate table visualization.tmp3;
    
        
    --select *  into visualization.tmp3 from dwh_new.visualization.v_tmp3

    insert into visualization.tmp3
    select * from visualization.v_tmp3
    order by created ;
    --select *  into visualization.tmp2 from dwh_new.visualization.v_tmp2
    truncate table visualization.tmp2;
    
    insert into visualization.tmp2 
    select * from visualization.v_tmp2
    order by created desc ;

    --select *  into visualization.tmp10 from dwh_new.visualization.tmp10
    truncate table  visualization.tmp10;

    with base as (
    select cal.created
         , r.score_group application_score
         , c.score_group2 prepayment_score
         ,/*, p.name,*/  
           count(r.id) as requests_cnt
         , count(c.id) credits_cnt
         , sum(r.accepted_amount) requests_amount
         , sum(c.amount) credits_amount
         , avg(r.accepted_amount) avg_rquests_amount
         , avg(c.amount) avg_credits_amount
         , sum(new_approve)  approve_new_cnt 
         , sum(case when reject_reason != -1 then  1 else 0 end ) reject_reason_cnt
         , count(case when new_reject_reason != -1 then  1 else 0 end ) new_reject_reason_cnt 
      from v_calendar cal 
            left join tmp_v_requests r on r.request_date_num = cal.created_num
            left join tmp_v_credits c on r.id = c.request_id --and cal.created_num = c.start_date_num
     where cal.created >= CURRENT_TIMESTAMP - 91
            and  olap_duplicate_algo !=1 
    group by cal.created 
         , r.score_group
         , c.score_group2
    ) 
    insert into visualization.tmp10
        select * from base  ;

        */
    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      ''
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch
end





