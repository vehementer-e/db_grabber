--DWH-2645
CREATE   PROC dbo.create_dm_request_dip_category
@full_update int = 0
as

begin


declare @request_date date = case when @full_update = 0 then dateadd(day, -10, getdate())  else '20160101' end
declare @dip_date date = dateadd(day, -10, @request_date)


select * into #dip_union 
from (																			    
--select '8'+ТелефонМобильный mobile, category, cdate, 'Докреды' as type , main_limit, external_id 
--from dwh_new.[dbo].[docredy_history]
--union all
--select '8'+ТелефонМобильный mobile, category, cdate, 'Повторники' as type , main_limit , external_id
--from dwh_new.[dbo].povt_history
--union all 
select '8'+ТелефонМобильный mobile, category, cdate, 'Повторники' as type , main_limit , external_id
from dwh2.marketing.povt_pts
where cdate>=@dip_date

UNION all 
select '8'+ТелефонМобильный mobile, category, cdate, 'Докреды' as type , main_limit , external_id
from dwh2.marketing.docredy_pts
where cdate>=@dip_date

union all 
select '8'+[phone] mobile,[market_proposal_category_code]  category, cdate, 'Повторники беззалог' as type ,[approved_limit] main_limit , external_id
from dwh2.marketing.povt_inst   
where cdate>=@dip_date

union all 						
select '8'+[phone] mobile,[market_proposal_category_code] category, cdate, 'Повторники беззалог' as type ,[approved_limit] main_limit , external_id
from dwh2.marketing.povt_pdl  
where cdate>=@dip_date

) x
--where cdate>=@dip_date

drop table if exists #Справочник_Договоры
select Код,  dwh2.dbo.getGUIDFrom1C_IDRREF( b.Клиент ) [guid клиента] into  #Справочник_Договоры from stg._1cCMR.Справочник_Договоры b

select a.*, b.[guid клиента] into #history from #dip_union a left join #Справочник_Договоры b on a.external_id=b.Код
					
--create nonclustered index t on #history
--(					
--[guid клиента], mobile, type, cdate
--)					
		
create index ix1
ON #history(type, [guid клиента], cdate DESC)
INCLUDE(category, main_limit)

create index ix2
ON #history(type, mobile, cdate DESC)
INCLUDE(category, main_limit)



DROP table if exists #req
select 
  dateadd(year, -2000, Дата) [Дата заявки]
, cast(dateadd(year, -2000, Дата) as date) [Дата заявки день]
, Номер
, Ссылка 
, dwh2.dbo.getGUIDFrom1C_IDRREF( Партнер ) [guid клиента]
, '8'+МобильныйТелефон Телефон

into #req
from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
where cast(dateadd(year, -2000, Дата) as date)>=@request_date


-- var 1. очень долго работают 6 штук outer apply 
/*
drop table if exists #req_category					
select 					
					
	a.[Дата заявки],
	a.[Дата заявки день],
	a.Номер,
	a.Ссылка,
	a.[guid клиента],
	a.Телефон

	  , isnull(d.category	 , d1.category	  ) category_docredy	
	  , isnull(p.category	 , p1.category	  ) category_povt	
	  , isnull(pi.category	 , pi1.category	  ) category_povt_inst	
	  , isnull(d.main_limit	 , d1.main_limit	  ) main_limit_docredy	
	  , isnull(p.main_limit	 , p1.main_limit	  ) main_limit_povt
	  , isnull(pi.main_limit	 , pi1.main_limit	  ) main_limit_povt_inst
	  
	, getdate() as created
into #req_category from #req a 					
outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Докреды'    and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d					
outer apply (select top 1 * from #history b where (b.mobile=a.Телефон                ) and b.type = 'Докреды'    and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d1	
outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p					
outer apply (select top 1 * from #history b where (b.mobile=a.Телефон                ) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p1	
 	
outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Повторники беззалог' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) pi
outer apply (select top 1 * from #history b where (b.mobile=a.Телефон                ) and b.type = 'Повторники беззалог' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) pi1
*/


--var 2
--1 d Докреды [guid клиента]
--outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента]) and b.type = 'Докреды' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d
DROP TABLE IF EXISTS #t_docred_client
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_docred_client
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Докреды'
			AND b.[guid клиента]=a.[guid клиента]
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1

--2 d1 Докреды mobile
--outer apply (select top 1 * from #history b where (b.mobile=a.Телефон) and b.type = 'Докреды' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d1
DROP TABLE IF EXISTS #t_docred_mobile
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_docred_mobile
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Докреды'
			AND b.mobile = a.Телефон
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1

--3 p Повторники [guid клиента]
--outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p
DROP TABLE IF EXISTS #t_povt_client
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_povt_client
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Повторники'
			AND b.[guid клиента]=a.[guid клиента]
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1

--4 p1 Повторники mobile
--outer apply (select top 1 * from #history b where (b.mobile=a.Телефон) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p1
DROP TABLE IF EXISTS #t_povt_mobile
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_povt_mobile
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Повторники'
			AND b.mobile = a.Телефон
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1

--5 pi Повторники беззалог [guid клиента]
--outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Повторники беззалог' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) pi					
DROP TABLE IF EXISTS #t_povt_i_client
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_povt_i_client
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Повторники беззалог'
			AND b.[guid клиента]=a.[guid клиента]
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1

--6 pi1 Повторники беззалог mobile
--outer apply (select top 1 * from #history b where (b.mobile=a.Телефон) and b.type = 'Повторники беззалог' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) pi1
DROP TABLE IF EXISTS #t_povt_i_mobile
SELECT 
	T.Ссылка,
	T.category,
	T.main_limit
INTO #t_povt_i_mobile
FROM (
	SELECT
		a.Ссылка,
		b.category, 
		b.main_limit,
		rn = row_number() OVER(PARTITION BY a.Ссылка ORDER BY b.cdate DESC)
	FROM #req AS a
		INNER JOIN #history AS b
			ON b.type = 'Повторники беззалог'
			AND b.mobile = a.Телефон
			AND b.cdate between dateadd(day, -10, a.[Дата заявки день]) and a.[Дата заявки день]
	) AS T
WHERE T.rn = 1


drop table if exists #req_category					
select 					
	a.[Дата заявки],
	a.[Дата заявки день],
	a.Номер,
	a.Ссылка,
	a.[guid клиента],
	a.Телефон

	, isnull(d.category	 , d1.category	  ) category_docredy	
	, isnull(p.category	 , p1.category	  ) category_povt	
	, isnull([pi].category	 , pi1.category	  ) category_povt_inst	
	, isnull(d.main_limit	 , d1.main_limit	  ) main_limit_docredy	
	, isnull(p.main_limit	 , p1.main_limit	  ) main_limit_povt
	, isnull([pi].main_limit	 , pi1.main_limit	  ) main_limit_povt_inst
	  
	, getdate() as created
into #req_category from #req AS a
	LEFT JOIN #t_docred_client AS d ON d.Ссылка = a.Ссылка
	LEFT JOIN #t_docred_mobile AS d1 ON d1.Ссылка = a.Ссылка
	LEFT JOIN #t_povt_client AS p ON p.Ссылка = a.Ссылка
	LEFT JOIN #t_povt_mobile AS p1 ON p1.Ссылка = a.Ссылка
	LEFT JOIN #t_povt_i_client AS [pi] ON [pi].Ссылка = a.Ссылка
	LEFT JOIN #t_povt_i_mobile AS pi1 ON pi1.Ссылка = a.Ссылка


--USE reports
--GO
--
--SET ANSI_NULLS ON
--GO
--
--SET QUOTED_IDENTIFIER ON
--GO
--
--CREATE TABLE [dbo].[dm_request_dip_category](
--	[Дата заявки] [datetime2](0) NULL,
--	[Дата заявки день] [date] NULL,
--	[Номер] [nchar](14) NOT NULL,
--	[Ссылка] [binary](16) NOT NULL,
--	[guid клиента] [char](36) NULL,
--	[Телефон] [nvarchar](17) NOT NULL,
--	[category_docredy] [varchar](50) NULL,
--	[category_povt] [varchar](50) NULL,
--	[category_povt_inst] [varchar](50) NULL,
--	[main_limit_docredy] int NULL,
--	[main_limit_povt] int NULL,
--	[main_limit_povt_inst] int NULL,
--	[created] [datetime] NOT NULL
--) ON [PRIMARY]
--GO
--
begin tran
	delete from dbo.dm_request_dip_category
	where [Дата заявки день]>=@request_date

	insert into dbo.dm_request_dip_category
	(
		[Дата заявки],
		[Дата заявки день],
		Номер,
		Ссылка,
		[guid клиента],
		Телефон,
		category_docredy,
		category_povt,
		category_povt_inst,
		main_limit_docredy,
		main_limit_povt,
		main_limit_povt_inst,
		created
	)
	select 
		[Дата заявки],
		[Дата заявки день],
		Номер,
		Ссылка,
		[guid клиента],
		Телефон,
		category_docredy,
		category_povt,
		category_povt_inst,
		main_limit_docredy,
		main_limit_povt,
		main_limit_povt_inst,
		created
	FROM #req_category
commit tran





end
