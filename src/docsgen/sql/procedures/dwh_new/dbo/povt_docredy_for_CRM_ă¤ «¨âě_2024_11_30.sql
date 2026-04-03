
create   procedure povt_docredy_for_CRM as

begin

	set nocount on

exec povt
exec dokredy
if object_id('dwh_new.dbo.CRM_loyals') is not null truncate table CRM_loyals
if object_id('dwh_new.dbo.check_loyals') is not null truncate table check_loyals;


;
with tablePrWeekDokr as (select sum(main_limit) ml1, count( external_id) cr1, category, type, dr1
from (select *, dense_rank() over (order by cdate) dr1 from docredy_history) dh
where dr1 = 1
group by category, type, dr1),

tableCurWeekDokr as (select sum(main_limit) ml2, count( external_id) cr2, category, type, dr2
from (select *, dense_rank() over (order by cdate) dr2 from docredy_history) dh2
where dr2 = 2
group by category, type, dr2),

tablePrWeekPovt as (select sum(main_limit) mlp1, count( external_id) crp1, category, type, dr3
from (select *, dense_rank() over (order by cdate) dr3 from povt_history) dh3
where dr3 = 1
group by category, type, dr3),

tableCurWeekPovt as (select sum(main_limit) mlp2, count( external_id) crp2, category, type, dr4
from (select *, dense_rank() over (order by cdate) dr4 from povt_history) dh4
where dr4 = 2
group by category, type, dr4)


insert into check_loyals
select tpp.category, tpp.type, mlp1, mlp2,  
case when mlp1=0 then 0 else (cast(mlp1 as numeric(11,1))-cast(mlp2 as numeric(11,1)))/cast(mlp2 as numeric(11,1)) end limCoeff, 
crp1, crp2,
case when crp1=0 then 0 else (cast(crp1 as numeric(6,1))-cast(crp2 as numeric(6,1)))/cast(crp2 as numeric(6,1)) end cntCoeff
--into check_loyals
from tablePrWeekPovt tpp full join tableCurWeekPovt tcp_ on tpp.category=tcp_.category and tpp.type=tcp_.type
union all
select tpd.category, tpd.type, ml1, ml2,  
case when ml1=0 then 0 else (cast(ml1 as numeric(14,3))-cast(ml2 as numeric(14,3)))/cast(ml2 as numeric(14,3)) end limCoeff, 
cr1, cr2,
case when cr1=0 then 0 else (cast(cr1 as numeric(7,3))-cast(cr2 as numeric(7,3)))/cast(cr2 as numeric(7,3)) end cntCoeff
from tablePrWeekDokr tpd full join tableCurWeekDokr tcd on tpd.category=tcd.category and tpd.type=tcd.type

if isnull((select count(*) from check_loyals where cntCoeff >0.07 or limCoeff >0.07),0) <> 0
return 1


insert into CRM_loyals
select  CRMClientGUID guid,	category type_mp,	TYPE  category_mp,	main_limit sum_mp,
	[Ставка %] rate_mp,	[Сумма платежа] payment, null validity,
[Рекомендуемая дата повторного обращения] second_date,	ТелефонМобильный telefon 
--into CRM_loyals
 from povt_buffer p join staging.CRMClient_references rr on rr.MFOContractNumber=p.external_id

insert into CRM_loyals
select  CRMClientGUID guid,	category type_mp,	TYPE  category_mp,	main_limit sum_mp,
	[Ставка %] rate_mp,	[Сумма платежа] payment, null validity,
[Рекомендуемая дата повторного обращения] second_date,	ТелефонМобильный telefon 
 from docredy_buffer p join staging.CRMClient_references rr on rr.MFOContractNumber=p.external_id

end





--select * from CRM_loyals
--drop table check_loyals


--select * from [staging].[CRMClient_references]


