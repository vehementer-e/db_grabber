  
 
 CREATE PROCEDURE [collection].[create_from_timing_to_execute] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try


 
	

drop table if exists #Final_table;	
	
	

	
	
	select 
			deal.number 'Договор'
			,1 cnt
			,--devdb.dbo.dt_st_month(jc.CourtClaimSendingDate) 'Месяц отправки иска в суд'
			--DATEADD(month, DATEDIFF(month, 0, EOMONTH(cast( jc.[CourtClaimSendingDate] as date))), 0) dt_st_month
			 dateadd(mm,-1,dateadd(dd,1,EOMONTH(cast(jc.[CourtClaimSendingDate] as date)))) 'Месяц отправки иска в суд'
			,year(cast(jc.CourtClaimSendingDate as date)) 'Год отправки иска в суд'
			,concat(year(cast(jc.CourtClaimSendingDate as date)),'Q',datepart(qq,cast(jc.CourtClaimSendingDate as date))) 'Квартал отправки иска в суд'
			,cast(jc.CourtClaimSendingDate as date) 'Дата отправки иска в суд'
			,cast(jc.JudgmentDate as date) 'Дата судебного решения'
			,cast(eo.ReceiptDate as date) AS 'Дата получения ИЛ'
			,cast(epe.ExcitationDate as date) AS 'Дата возбуждения ИП'
			,datediff(dd,cast(jc.CourtClaimSendingDate as date),cast(jc.JudgmentDate as date)) 'Тайминг от иска до решения'
			,datediff(dd,cast(jc.JudgmentDate as date),cast(eo.ReceiptDate as date)) 'Тайминг от решения до получения ИЛ'
			,datediff(dd,cast(eo.ReceiptDate as date),cast(epe.ExcitationDate as date)) 'Тайминг от получения ИЛ до возбуждения ИП'
into #Final_table
	FROM           Stg._Collection.Deals AS													Deal LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS								jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS									jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS								eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceeding AS							ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
						 Stg._Collection.EnforcementProceedingExcitation as					epe on epe.EnforcementProceedingId = ep.Id

	where 1 = 1
			and jc.CourtClaimSendingDate is not null
			and jc.JudgmentDate is not null
			and eo.ReceiptDate is not null
			and epe.ExcitationDate is not null
			and epe.ExcitationDate >= eo.ReceiptDate
			and eo.ReceiptDate >= jc.JudgmentDate
			and jc.JudgmentDate >= jc.CourtClaimSendingDate 


EXEC [collection].set_debug_info @sp_name
			,'1';







					
begin transaction 

    delete from [collection].[from_timing_to_execute];
	insert [collection].[from_timing_to_execute] (

	   [Договор]
      ,[cnt]
      ,[Месяц отправки иска в суд]
      ,[Год отправки иска в суд]
      ,[Квартал отправки иска в суд]
      ,[Дата отправки иска в суд]
      ,[Дата судебного решения]
      ,[Дата получения ИЛ]
      ,[Дата возбуждения ИП]
      ,[Тайминг от иска до решения]
      ,[Тайминг от решения до получения ИЛ]
      ,[Тайминг от получения ИЛ до возбуждения ИП]

)



 select 
       [Договор]
      ,[cnt]
      ,[Месяц отправки иска в суд]
      ,[Год отправки иска в суд]
      ,[Квартал отправки иска в суд]
      ,[Дата отправки иска в суд]
      ,[Дата судебного решения]
      ,[Дата получения ИЛ]
      ,[Дата возбуждения ИП]
      ,[Тайминг от иска до решения]
      ,[Тайминг от решения до получения ИЛ]
      ,[Тайминг от получения ИЛ до возбуждения ИП]


 from #Final_table

  
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
