CREATE procedure [riskCollection].[create_rollrates_report] as
begin

declare @rdt date = '2023-01-01';

BEGIN TRY
------------------------------балансы на начало месяца и новые входы
drop table if exists #begin;
select
d
,eomonth(d) as mes
,external_id
,bucket_p_coll as bucket_start
,bucket_p_coll_num as bucket_start_num
,ball_in_p1 as ball_start
,[Тип продукта]
,[Наименование продукта]
into #begin
from riskCollection.collection_datamart
where d>= @rdt
and ball_in_p1 >0
;
------------------------------балансы на конец месяца
drop table if exists #end;
select
d
,eomonth(d) as mes
,external_id
,bucket_coll as bucket_end
,bucket_coll_num as bucket_end_num
,ball_in_p as ball_end
,0 as MTD
into #end
from riskCollection.collection_datamart
where d>= @rdt
and d = (case when month(d) = month(getdate()) and year(d) = year(getdate()) then cast(getdate() as  date) else eomonth(d) end)
;
------------------------------балансы на дату
drop table if exists #endmtd;
select
d
,eomonth(d) as mes
,external_id
,bucket_coll as bucket_end
,bucket_coll_num as bucket_end_num
,ball_in_p as ball_end
,1 as MTD
into #endmtd
from riskCollection.collection_datamart
where d>= @rdt
and day(d) = day(getdate())
;
------------------------------итог
--к данным на первое число/входам добавляем данные на конец месяца
drop table if exists #rr;
select
bg.d
,bg.external_id
,bg.bucket_start
,bg.bucket_start_num
,bg.ball_start
,bg.[Тип продукта]

--если закрылся (или его нет на эту дату в балансах), считаем что ушел в 0 бакет
,coalesce(ed.d, eomonth(bg.d)) as enddate
,bg.mes
,coalesce(ed.bucket_end, '(1)_0') as bucket_end
,coalesce(ed.bucket_end_num, 1) as bucket_end_num
,coalesce(ed.ball_end, bg.ball_start) as ball_end
,coalesce(ed.MTD,0) as MTD
,bg.[Наименование продукта]
into #rr
from #begin bg
left join #end ed
	on bg.external_id = ed.external_id 
	and bg.mes = ed.mes
;
--к данным на первое число/входам добавляем данные на дату
insert into #rr
select
bg.d
,bg.external_id
,bg.bucket_start
,bg.bucket_start_num
,bg.ball_start
,bg.[Тип продукта]

--если закрылся (или его нет на эту дату в балансах), считаем что ушел в 0 бакет
--,coalesce(edd.d, datefromparts(year(bg.d), month(bg.d), day(getdate()))) as enddate --29/10/25
,coalesce(edd.d, (
	case 
		when day(eomonth(bg.d)) = 28 then datefromparts(year(bg.d), month(bg.d), 28)
		when day(eomonth(bg.d)) = 29 then datefromparts(year(bg.d), month(bg.d), 29)
		when day(eomonth(bg.d)) = 30 then datefromparts(year(bg.d), month(bg.d), 30)
		else datefromparts(year(bg.d), month(bg.d), day(getdate()))
		end )) as enddate
,bg.mes
,coalesce(edd.bucket_end, '(1)_0') as bucket_end
,coalesce(edd.bucket_end_num, 1) as bucket_end_num
,coalesce(edd.ball_end, bg.ball_start) as ball_end
,coalesce(edd.MTD, 1) as MTD
,bg.[Наименование продукта]
from #begin bg
left join #endmtd edd
	on bg.external_id = edd.external_id 
	and bg.mes = edd.mes
;
----------------------------------внесение данных
if OBJECT_ID('riskcollection.rr_report') is null
begin
	select top(0) * into riskcollection.rr_report
	from #rr
end;

BEGIN TRANSACTION
	delete from riskcollection.rr_report
	where d >= @rdt;

	insert into riskcollection.rr_report
	select * from #rr;
COMMIT TRANSACTION;

drop table if exists #begin;
drop table if exists #end;
drop table if exists #rr;
drop table if exists #endmtd;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;