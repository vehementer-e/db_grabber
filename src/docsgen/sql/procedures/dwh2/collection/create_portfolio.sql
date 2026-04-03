  
 
 CREATE PROCEDURE [collection].[create_portfolio] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try
	








		
	drop table if exists #base_bucket_dpd_max_;	
		
		select Number
				,fl_dpd_91
    into #base_bucket_dpd_max_
		from
		(
			select d.Number
					,1 fl_dpd_91
					,ROW_NUMBER() over (partition by dh.ObjectId order by cast(dh.newvalue as int), dh.changedate) rn
			from stg._Collection.dealhistory dh
			join stg._Collection.deals d on d.Id = dh.ObjectId 
			where 1 = 1
					and dh.field = 'Количество дней просрочки'
					and cast(dh.newvalue as int) between 91 and 95
		)bb
		where rn = 1
		union
		select Number
				,fl_dpd_91
		from
		(
			select external_id Number
					,1 fl_dpd_91
					,ROW_NUMBER() over (partition by external_id order by dpd_p_coll, d) rn  --change overdue_days_p   --cdate on d
			from dbo.dm_cmrstatbalance -- change dwh_new.dbo.v_balance_cmr
			where 1 = 1
					and dpd_p_coll  between 91 and 95 --change overdue_days_p
		)bb
		where rn = 1
	/*)*/;


	EXEC [collection].set_debug_info @sp_name
			,'1';



   drop table if exists #Final_table;


	select 
			case when datepart(yy,dt_st_credit) <= 2020
				  then '2020'
				  when  datepart(yy,dt_st_credit) = 2021
				  then '2021'
				  when  datepart(yy,dt_st_credit) = 2022
				  then '2022'
				  else concat(datepart(yy,dt_st_credit),'M',datepart(mm,dt_st_credit)) end 'период выдачи кредита'
			,type_credit 'тип выдачи'
			,sum(cnt) 'кол-во выданных кредитов'
			,sum(fl_Court_Claim_Sending) 'кол-во кредитов с поданным иском'
			,isnull(cast(sum(fl_Court_Claim_Sending) as float) / nullif(cast(sum(cnt) as float),0),0) 'доля кредитов с поданным иском'
			,fl_dpd_91
    into #Final_table
	from
	(
		select
				d.number
				,1 cnt
				,d.date dt_st_credit
				,case when md.client_type = 'Параллельный' ---return_type
					  then '2. Докредитование'
					  when md.client_type = 'Докредитование'---return_type
					  then '2. Докредитование'
					  when md.client_type = 'Первичный'---return_type
					  then '1. Первичный'
					  when md.client_type = 'Повторный'---return_type
					  then '3. Повторный'
					  else md.client_type---return_type
					  end type_credit
				,jc.dt_min_Court_Claim_Sending
				,coalesce(jc.fl_Court_Claim_Sending,0) fl_Court_Claim_Sending
				,coalesce(bbm.fl_dpd_91,0) fl_dpd_91
		from 
				Stg._Collection.Deals									d
				left join (select jp_1.DealId
									,cast(min(jc_1.CourtClaimSendingDate) as date) dt_min_Court_Claim_Sending
									,1 fl_Court_Claim_Sending
							from Stg._Collection.JudicialClaims				jc_1
							join Stg._Collection.JudicialProceeding			jp_1 on jp_1.Id = jc_1.JudicialProceedingId
							where jc_1.id in (select ObjectId
												from stg._collection.JudicialClaimHistory
												group by ObjectId)
							group by jp_1.DealId)
																		jc on jc.DealId = d.Id
				join [dbo].[v_risk_apr_segment]					md on md.number = d.number --reports.dbo.dm_maindata--applications 	заменил
				left join #base_bucket_dpd_max_							bbm on bbm.Number = d.number
		where 1 = 1
				and d.date is not null
	)base
	group by
			(case when datepart(yy,dt_st_credit) <= 2020
				  then '2020'
				  when  datepart(yy,dt_st_credit) = 2021
				  then '2021'
				  when  datepart(yy,dt_st_credit) = 2022
				  then '2022'
				  else concat(datepart(yy,dt_st_credit),'M',datepart(mm,dt_st_credit)) end)
			,type_credit
			,fl_dpd_91


EXEC [collection].set_debug_info @sp_name
			,'2';


			/*
	drop table if exists #Final_table_1;
	select 
			case when datepart(yy,dt_st_credit) <= 2020
				  then '2020'
				  when  datepart(yy,dt_st_credit) = 2021
				  then '2021'
				  when  datepart(yy,dt_st_credit) = 2022
				  then '2022'
				  else concat(datepart(yy,dt_st_credit),'M',datepart(mm,dt_st_credit)) end 'период выдачи кредита'
			,type_credit 'тип выдачи'
			,sum(cnt) 'кол-во выданных кредитов'
			,sum(fl_Court_Claim_Sending) 'кол-во кредитов с поданным иском'
			,isnull(cast(sum(fl_Court_Claim_Sending) as float) / nullif(cast(sum(cnt) as float),0),0) 'доля кредитов с поданным иском'
			into #Final_table_1
	from
	(
		select
				d.number
				,1 cnt
				,d.date dt_st_credit
				,case when md.client_type_for_sales = 'Параллельный' --return_type
					  then '2. Докредитование'
					  when md.client_type_for_sales = 'Докредитование' --return_type
					  then '2. Докредитование'
					  when md.client_type_for_sales = 'Первичный' --return_type
					  then '1. Первичный'
					  when md.client_type_for_sales = 'Повторный' --return_type
					  then '3. Повторный'
					  else md.client_type_for_sales --return_type
					  end type_credit
				,jc.dt_min_Court_Claim_Sending
				,coalesce(jc.fl_Court_Claim_Sending,0) fl_Court_Claim_Sending
				,coalesce(bbm.fl_dpd_91,0) fl_dpd_91
		from 
				Stg._Collection.Deals									d
				left join (select jp_1.DealId
									,cast(min(jc_1.CourtClaimSendingDate) as date) dt_min_Court_Claim_Sending
									,1 fl_Court_Claim_Sending
							from Stg._Collection.JudicialClaims				jc_1
							join Stg._Collection.JudicialProceeding			jp_1 on jp_1.Id = jc_1.JudicialProceedingId
							where jc_1.id in (select ObjectId
												from stg._collection.JudicialClaimHistory
												group by ObjectId)
							group by jp_1.DealId)
																		jc on jc.DealId = d.Id
				join risk.applications 						md on md.number = d.number --reports.dbo.dm_maindata	
				left join #base_bucket_dpd_max_							bbm on bbm.Number = d.number
		where 1 = 1
				and d.date is not null
				and fl_dpd_91 = 1
	)base
	group by
			(case when datepart(yy,dt_st_credit) <= 2020
				  then '2020'
				  when  datepart(yy,dt_st_credit) = 2021
				  then '2021'
				  when  datepart(yy,dt_st_credit) = 2022
				  then '2022'
				  else concat(datepart(yy,dt_st_credit),'M',datepart(mm,dt_st_credit)) end)
			,type_credit

			*/
EXEC [collection].set_debug_info @sp_name
			,'3';


			/*
				case when datepart(yy,dt_st_credit) <= 2020
				  then '2020'
				  when  datepart(yy,dt_st_credit) = 2021
				  then '2021'
				  when  datepart(yy,dt_st_credit) = 2022
				  then '2022'
				  else concat(datepart(yy,dt_st_credit),'M',datepart(mm,dt_st_credit)) end 'период выдачи кредита'
			,type_credit 'тип выдачи'
			,sum(cnt) 'кол-во выданных кредитов'
			,sum(fl_Court_Claim_Sending) 'кол-во кредитов с поданным иском'
			,[доля кредитов с поданным иском] = cast(0 as float)
			--,isnull(cast(sum(fl_Court_Claim_Sending) as float) / nullif(cast(sum(cnt) as float),0),0) 'доля кредитов с поданным иском'
			,fl_dpd_91
			*/

begin transaction 

    delete from [collection].[portfolio_all];
	insert [collection].[portfolio_all] (
	[период выдачи кредита]
      ,[тип выдачи]
      ,[кол-во выданных кредитов]
      ,[кол-во кредитов с поданным иском]
      ,[доля кредитов с поданным иском]
	  )
select 
       [период выдачи кредита]				= [период выдачи кредита]
       ,[тип выдачи]						= [тип выдачи]
       ,[кол-во выданных кредитов]			=  sum([кол-во выданных кредитов])
       ,[кол-во кредитов с поданным иском]	=  sum([кол-во кредитов с поданным иском])
       ,[доля кредитов с поданным иском]	=  isnull(cast(sum([кол-во кредитов с поданным иском]) as float) / nullif(cast(sum([кол-во выданных кредитов]) as float),0),0) 
 from #Final_table

 group by [период выдачи кредита], [тип выдачи]



  delete from [collection].[portfolio_91+];
	insert [collection].[portfolio_91+] (
	   [период выдачи кредита]
      ,[тип выдачи]
      ,[кол-во выданных кредитов]
      ,[кол-во кредитов с поданным иском]
      ,[доля кредитов с поданным иском]
	)
 select 
       [период выдачи кредита]
       ,[тип выдачи]
       ,[кол-во выданных кредитов]
       ,[кол-во кредитов с поданным иском]
       ,[доля кредитов с поданным иском]
 from #Final_table
 where fl_dpd_91 = 1

  
  commit transaction 

  EXEC [collection].set_debug_info @sp_name
			,'Finish';		



end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
