



CREATE proc [dbo].[sale_report_repayment_offline] 

AS
BEGIN

	SET NOCOUNT ON;


	with e as (	
	select
		number,
		email,
		ROW_NUMBER() over(partition by number order by created) as rn
	from v_email
)

	select 
		r.loanNumber as Number,
		rp.Дата,
		r.ФИО, 
		r.phone as Phone,
		e.email as Email,
		rp.сумма as Сумма, 
		rp.ПлатежнаяСистема 
	from v_request as r
	inner join mv_repayments as rp on rp.number = r.loanNumber and rp.Дата >= DATEADD(DAY, -5, CAST(GETDATE() AS DATE)) and rp.ПлатежнаяСистема in ('Расчетный счет', 'Золотая корона')
	left join e on e.number = r.loanNumber and rn = 1
	where r.loanNumber <> '' 

END
