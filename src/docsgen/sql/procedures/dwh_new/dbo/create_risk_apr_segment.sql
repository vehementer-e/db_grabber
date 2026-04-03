-- =============================================
-- Author:		Andrey Shubkin  
-- Create date:27.03.2020
-- Description: формирование данных в таблице [dwh_new].dbo.risk_apr_segment
-- exec dbo.[create_risk_apr_segment]
-- Изменения в рамках задачи DWH-1136
-- =============================================
CREATE     PROCEDURE [dbo].[create_risk_apr_segment]

AS
BEGIN
	SET NOCOUNT ON;

drop table if exists #t;


;with list as (
select distinct number from stg._loginom.[Workflow]
	where stage='Call 1' 
)
, cte_log as 
(
select Number, 
	isnull(client_type_2, client_type_1) as client_type,    
	ROW_NUMBER() over(partition by Number order by call_date desc )nRow
from stg.[_loginom].[Originationlog]
		where Stage in ('Call 1', 'Call 2')
		and Call_date>='2019-12-01'
), cte_last_log as
(
	select l.Number,
		return_type = case 
		when l.client_type in ('docred', 'active') then 'Докредитование'
		when l.client_type in ('parallel') then 'Параллельный'
		when l.client_type in ('repeated', 'repeat') then 'Повторный'
		else 'Первичный' end
		from cte_log l
	where nRow = 1
)
select distinct
	ll.number, 
	iif(s.Stage != 'Call 1' 
		or return_type<>'Первичный' or nullif(s.APR_SEGMENT,'') is null
		, null
		,iif( return_type='Первичный' and nullif(s.APR_SEGMENT,'') is not null
		,case
			when s.APR_SEGMENT in ('1','2','3','4') then 'GR_40/50'
			when s.APR_SEGMENT in ('10','20','21','22','23','24') then 'GR_56/66'
		else 'GR_86/96' end 
		,null)
	)as APR_SEGMENT,
	
	return_type
--into [dwh_new].dbo.risk_apr_segment
into #t
from cte_last_log  ll
left join (
select Number, min(APR_SEGMENT) APR_SEGMENT, s.Stage from  stg._loginom.score s 
	where s.Stage = 'call 1'
	and exists (select top(1) 1 from list l where l.number = s.Number)
	group by Number, Stage
	) s on ll.Number =s.Number

	


--select top 10 * from #t


begin tran
	if OBJECT_ID('dbo.risk_apr_segment') is null
	begin
		select top(0)* 
		into dbo.risk_apr_segment
		from #t
	end
	
	delete from dbo.risk_apr_segment
	insert into dbo.risk_apr_segment(number,	APR_SEGMENT,	return_type)
	select number,	APR_SEGMENT,	return_type
 
	from #t

commit tran 

END
