-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-04-22
-- Description:	
-- exec [etl].[dwh429_tmp_persent_rest_cmr_umfo]
-- =============================================

CREATE PROCEDURE [etl].[dwh429_tmp_persent_rest_cmr_umfo]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
begin
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;



-- временная ЦМР
drop table if exists #stg1
select * 
into #stg1 
from v_balance_cmr a

where datepart(yyyy ,cdate) = 2020
/*             where a.external_id in (
             18100120020001
,18080121200001
,18071823830001
,18072418460003
,18112402150001
,18082410260002
)
*/
order by a.external_id, cDate;
 
 
-- Временная УМФО
drop table if exists #stg2
select dr.дата as r_date,dr.Комментарий,dr.типклиентов,d.НомерДоговора,d.Дата,d.суммазайма,r.*
into #stg2
             from [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ] dr
             join [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r on r.ссылка=dr.ссылка
             join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный]  d on r.Займ=d.ссылка

where datepart(yyyy ,dr.[дата]) = 4020   
/*             
			 where d.НомерДоговора in
             (
             '18100120020001'
,'18080121200001'
,'18071823830001'
,'18072418460003'
,'18112402150001'
,'18082410260002'
             );
*/
 /*
 select * from [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ]
 select * from [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ]
 */


--Итог
drop table if exists #res
             select a.cdate, a.external_id
             , a.overdue_days
             , a.writeoff_status
 
             --, cast(a.principal_rest as float) as principal_rest_CMR
             , cast(a.percents_rest as float) as percents_rest_CMR
             --, cast(b.[СуммаОД] as float)  as principal_rest_UMFO
             , cast(b.[СуммаПроценты] as float) as percents_rest_UMFO
            
 
 
             , cast(isnull(principal_cnl,    0) as float) +
                         cast(isnull(percents_cnl,     0) as float) +
                         cast(isnull(fines_cnl,        0) as float) +
                         cast(isnull(otherpayments_cnl,0) as float) +
                         cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total
 
             , round(cast(b.[СуммаПроценты] as float)- cast(a.percents_rest as float),0) as prc_delta

into #res            
			 from
             #stg1 a left join #stg2 b on a.external_id = b.НомерДоговора and cast(dateadd(yy,-2000,b.r_date) as date) = a.cdate
             where a.overdue_days >300
             order by 2, 1


insert into [dwh_new].[dbo].[dwh429_persent_rest_cmr_umfo] (cdate 
														,external_id
														,overdue_days 
														,writeoff_status 
														,percents_rest_CMR
														,percents_rest_UMFO 
														,pay_total 
														,prc_delta 
														)
select *
--into 
from #res



end



--select * from [dwh_new].[dbo].[dwh429_persent_rest_cmr_umfo]
--where external_id  in
--             (
--             '18100120020001'
--,'18080121200001'
--,'18071823830001'
--,'18072418460003'
--,'18112402150001'
--,'18082410260002'
--             )