---------------------------------------------------------------------------------------------------
create   procedure dbo.create_say_for_jp_for_vintag_for_pivot
as
begin
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
			dbo.say_deals_all_for_jp_for_vintag
	group by 
			(case when yr_payment_StateDuty <= 2018
				 then 2018
				 else yr_payment_StateDuty
				 end)
			,type_credit
			,mob
	if object_id('dbo.say_for_jp_for_vintag_for_pivot') is null
	begin
		select top(0)
		* 
		into dbo.say_for_jp_for_vintag_for_pivot
		from #say_for_jp_for_vintag_for_pivot
	end
	begin
		delete from dbo.say_for_jp_for_vintag_for_pivot
		insert into dbo.say_for_jp_for_vintag_for_pivot
		select 
			*
		from #say_for_jp_for_vintag_for_pivot
		;
	end 
end
