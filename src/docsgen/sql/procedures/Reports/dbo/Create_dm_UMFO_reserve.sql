
-- exec [dbo].[Create_dm_UMFO_reserve]
CREATE PROC [dbo].[Create_dm_UMFO_reserve]
as
BEGIN
	SET NOCOUNT ON;
-- создаем витрину

 
  --delete from [dbo].[dm_UMFO_reserve] 

  
--
 -- Резервы
 --
 drop table if exists #reserve
 select top(0)
	[cdate], 
	[external_id], 
	[rserve_sum],
	rn = cast(0 as int)
 into #reserve
 from [dbo].[dm_UMFO_reserve] 
 insert into #reserve(cdate, external_id, rserve_sum, rn)
select cast(dateadd(yy,-2000,dr.дата) as date) as cdate, 
      d.[НомерДоговора] as external_id, 
      cast(isnull([РезервОстатокОДПо],0) as decimal(38,2)) + 
      cast(isnull([РезервОстатокПроцентыПо],0) as decimal(38,2)) as rserve_sum
	  , rn = row_number() over(partition by d.[НомерДоговора], cast(dateadd(yy,-2000,dr.дата) as date) order by  dr.дата)
--DWH-1358 Переписать Create_dm_UMFO_reserve на локальную копию данных
--into #reserve
--from [C2-VSR-SQL04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr 
--join [C2-VSR-SQL04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r on r.ссылка=dr.ссылка 
--join [C2-VSR-SQL04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] d on r.Займ=d.ссылка 

from Stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ AS dr 
join Stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ AS r on r.ссылка=dr.ссылка 
join Stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный AS d on r.Займ=d.ссылка 

BEGIN tran

	truncate table [dbo].[dm_UMFO_reserve] 

	insert into [dbo].[dm_UMFO_reserve]
	select --* 
	cdate,	external_id,	rserve_sum

	--into  [dbo].[dm_UMFO_reserve]
	from #reserve
	where rn = 1
	--and external_id = '1711189480003'
	--order by cdate desc

commit tran

END
