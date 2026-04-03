---------------------------------------------------------------------------------------------------
CREATE   procedure [collection].[create_say_for_jp_for_vintag_for_pivot]
as
begin


DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try





	drop table if exists #say_for_jp_for_vintag_for_pivot

	select 
			case when yr_payment_StateDuty <= 2018
				 then 2018
				 else yr_payment_StateDuty
				 end 'год оплаты госпошлины'
			,type_credit 'тип выдачи'
			,mob 'порядковый номер платежа'
			,sum(debt) 'сумма долга'
			,sum(sum_pay_cumulatively) 'сумма поступлений'
			,sum(sum_pay_cumulatively) / sum(debt) 'процент возврата'
	into #say_for_jp_for_vintag_for_pivot
	from 
			[collection].say_deals_all_for_jp_for_vintag
	group by 
			(case when yr_payment_StateDuty <= 2018
				 then 2018
				 else yr_payment_StateDuty
				 end)
			,type_credit
			,mob
	if object_id('collection.say_for_jp_for_vintag_for_pivot') is null
	begin
		select top(0)
		* 
		into [collection].say_for_jp_for_vintag_for_pivot
		from #say_for_jp_for_vintag_for_pivot
	end
	begin
	 begin TRANSACTION
		delete from [collection].say_for_jp_for_vintag_for_pivot
		insert into [collection].say_for_jp_for_vintag_for_pivot
		select 
			*
		from #say_for_jp_for_vintag_for_pivot
		;
		 COMMIT TRANSACTION
	end 


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
	
	;
