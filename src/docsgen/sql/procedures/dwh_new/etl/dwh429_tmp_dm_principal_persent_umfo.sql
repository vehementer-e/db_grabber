-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-04-22
-- Description:	
-- exec [etl].[dwh429_tmp_persent_rest_cmr_umfo]
-- =============================================

create PROCEDURE [etl].[dwh429_tmp_dm_principal_persent_umfo]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
begin
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;


drop table if exists #res
select  cast(dateadd(yy,-2000,r_date) as date) as cdate
		, [НомерДоговора] as external_id
        , case when [ДнейПросрочки] >360 then 360 else 0 end overdue_days
             --НомерДоговора as external_id,
 
        , sum(cast(isnull([СуммаОД],0) as float)) as principal_rest_umfo
        , case when [ДнейПросрочки] >360 then sum(cast(isnull([СуммаПроценты],0) as float)) else 0 end as percents_rest_umfo

into #res
 
from (select dr.дата as r_date
			,dr.Комментарий
			,dr.типклиентов
			,d.НомерДоговора
			,d.Дата
			,d.суммазайма
			,r.*
      from [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr
      join [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r
      on r.ссылка=dr.ссылка and (cast(dateadd(yy,-2000,dr.дата)as date) >= CONVERT(datetime, '31.12.2018', 104) 
							and day(dr.дата) = day(eomonth(dr.дата))
                            or cast(dateadd(yy,-2000,dr.дата)as date) >= CONVERT(datetime, '31.03.2020', 104))
      join [prodsql01].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d on r.Займ=d.ссылка
     ) a
group by cast(dateadd(yy,-2000,r_date) as date) ,[НомерДоговора] 
			,[ДнейПросрочки]


delete from [dwh_new].[dbo].[dwh429_dm_principal_persent_umfo]


insert into [dwh_new].[dbo].[dwh429_dm_principal_persent_umfo] (cdate 
														,external_id
														,overdue_days 
														,principal_rest_umfo
														,percents_rest_umfo
														)

select *
--into [dwh_new].[dbo].[dwh429_dm_principal_persent_umfo]
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