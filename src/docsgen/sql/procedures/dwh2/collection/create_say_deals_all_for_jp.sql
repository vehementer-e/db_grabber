

CREATE   procedure [collection].[create_say_deals_all_for_jp]

as
begin



DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



 begin try

---------------------------------------------------------------------------------------------------
	--госпошлина оплачена
	drop table if exists #sum_dt_StateDuty;
	select 
			d.number
			,collection.customer_fio(d.IdCustomer) fio_customer
			,max(cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date)) dt_payment_StateDuty
			
			,max(dateadd(mm,-1,dateadd(dd,1,EOMONTH(cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date ))))) mn_payment_StateDuty --,max(devdb.dbo.dt_st_month(cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date))) mn_payment_StateDuty
			--,cast(coalesce(jc.StateDutyOnJudgment,jc.StateDutyOnClaim) as numeric) sum_StateDuty
			--,row_number() over (partition by d.number order by cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date) desc) rn
	into #sum_dt_StateDuty
	from Stg._Collection.JudicialClaims							jc
	join Stg._Collection.JudicialProceeding						jp on jp.Id = jc.JudicialProceedingId
	join stg._Collection.Deals									d on d.id = jp.dealid
	where 1 = 1
			and cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date) is not null
			and  exists  (select top(1) 1 
							from stg._Collection.[JudicialClaimHistory]
							where ObjectId =jc.id 
							) -- отсекаются иски, которые создаются системой в момент направления ЗТ. то есть сущность иск создается, но фактически иск в суд еще не отправлялся. у такой сущности нет истории изменений/заполнений, поэттому в таблице истории по ней нет данных.
			and cast(coalesce(jc.StateDutyOnJudgment,jc.StateDutyOnClaim) as numeric) > 0
			and datepart(yy,cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date)) <= datepart(yy,getdate())
	group by d.number
			,collection.customer_fio(d.IdCustomer)
	;


	EXEC [collection].set_debug_info @sp_name
			,'1';
---------------------------------------------------------------------------------------------------
	-- база договоров с оплаченной гп
	drop table if exists #say_deals_all_for_jp;
	select distinct
			d.id id_deal_space
			,d.number
			,dateadd(mm,-1,dateadd(dd,1,EOMONTH(cast(d.date as date)))) mn_st_credit --,devdb.dbo.dt_st_month(d.date) mn_st_credit
			--,d.interestrate rate_in_space
			--,vc.[percent] rate_in_v_credits
			,case when coalesce(d.interestrate,0) < 20 then coalesce(cast(cmr.[ПроцентнаяСтавкаНаТекущийДень] as numeric(38,2)),0)  else coalesce(d.interestrate,0) end rate_agg  --добавил as numeric
			,case when md.client_type_for_sales  = 'Параллельный'--return_type
				  then 'Докредитование'
				  else md.client_type_for_sales --return_type
				  end type_credit
			,case when sdsd.number is not null then 1 else 0 end fl_payment_StateDuty
			,sdsd.dt_payment_StateDuty
			,sdsd.mn_payment_StateDuty
			,datepart(yy,sdsd.mn_payment_StateDuty) yr_payment_StateDuty
			,cmr.[остаток всего] debt_all
			--,bp.sum_pay
			--,datediff(mm,sdsd.mn_payment_StateDuty,devdb.dbo.dt_st_month(bp.dt_pay)) period_pay
	into #say_deals_all_for_jp
	from stg._collection.deals					d
	--left join dbo.dm_overdueindicators  /*dwh_new.dbo.tmp_v_credits*/			vc on vc.external_id = d.number поле с процентной ставкой взял из цмр стат баланс
	left join #sum_dt_StateDuty					sdsd on sdsd.number = d.number
	join dbo.dm_cmrstatbalance /*reports.dbo.dm_CMRStatBalance_2*/		cmr on cmr.external_id = d.number -- несколько договоров с оплатой гп в нужную дату не ищутся в этой таблице, поэтому я использовал это соединение, чтобы исключить эти договора из выборки, а не указывать им нулевой долг
													and cmr.d = sdsd.dt_payment_StateDuty
													and cmr.[остаток всего] > 0 --Добавление 28.09 согласованос с Николаем.
	join risk.applications 				md on md.number = d.number  --reports.dbo.dm_maindata
	where 1 = 1
			and (case when coalesce(d.interestrate,0) < 20 then coalesce(cmr.[ПроцентнаяСтавкаНаТекущийДень],0) else coalesce(d.interestrate,0) end) > 0
			and (case when sdsd.number is not null then 1 else 0 end) = 1
	;

	EXEC [collection].set_debug_info @sp_name
			,'finish';

	if OBJECT_ID('[collection].say_deals_all_for_jp') is null
	begin
		select top(0) 
		*
		into [collection].say_deals_all_for_jp
		from #say_deals_all_for_jp
	end
	begin
		delete from [collection].say_deals_all_for_jp
		insert into [collection].say_deals_all_for_jp
		select * from #say_deals_all_for_jp
	end

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

end
