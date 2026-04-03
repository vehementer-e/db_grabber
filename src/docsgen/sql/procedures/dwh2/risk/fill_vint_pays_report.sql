CREATE procedure [risk].[fill_vint_pays_report] as
begin
--exec [risk].[fill_vint_pays_report]
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @rdt date = dateadd(mm, -2, dateadd(dd, 1, eomonth(GETDATE())))
BEGIN TRY
--------------------------------определение наличия промо по договору
drop table if exists #promo;
select
number
,1 as promo
,row_number() over(partition by number order by call_date desc) as rn
into #promo
from stg._loginom.originationlog
where promoPeriodRepayment != 0
and Call_date >= @rdt
;
---------------------------------платежи
drop table if exists #pays;
select
d
,external_id
,pay_total
into #pays
from dbo.dm_CMRStatBalance
where ContractStartDate >= @rdt
;
--------------------------------свод
drop table if exists #total;
select 
credits.external_id
,credits.generation
,credits.startdate
,credits.amount
,credits.client_type
,credits.credit_type
,pays.d
,pays.pay_total
,app.leadsource
,app.rbp_gr
,case 
	when app.leadsource = 'vbr-crossoffer' then '"Желтый" - канал vbr-crossoffer'
	when app.leadsource in ('bankiru-deepapi', 'sravniru-deepapi', 'finuslugi-deepapi', 'finkort-api') then '"Красные" - Худшие по одобрению и риску'
	else '"Белые" - лучшие по одобрению и риску'
	end leadsource_colour
,coalesce(promo.promo, 0) as promo_flg
,datediff(dd, credits.startdate, dateadd(dd, -1, pays.d))/30+1 as [Месяц оплаты]
into #total
from risk.credits credits
left join #pays pays
	on pays.external_id = credits.external_id
left join risk.applications2 app
	on app.number = credits.external_id
	--and cdm.pay_total>0
left join #promo promo
	on promo.number = credits.external_id
	and promo.rn = 1
where credits.generation >= @rdt
;
--------------------------------внесение данных
if OBJECT_ID('risk.vint_pays_report') is null
begin
	select top(0) * into risk.vint_pays_report
	from #total
end;

BEGIN TRANSACTION
	delete from risk.vint_pays_report
	where generation >= @rdt;

	insert into risk.vint_pays_report
	select * from #total;
COMMIT TRANSACTION;

drop table if exists #promo;
drop table if exists #pays;
drop table if exists #total;

END TRY

begin catch
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

	if @@TRANCOUNT>0
		rollback TRANSACTION;
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'ala.kurikalov@smarthorizon.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;