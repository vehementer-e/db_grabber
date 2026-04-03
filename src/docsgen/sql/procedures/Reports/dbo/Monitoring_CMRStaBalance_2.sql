-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.Monitoring_CMRStaBalance_2 
	-- Add the parameters for the stored procedure here
	@p int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if object_id('tempdb.dbo.#t') is not null drop table #t
	select  b.d, p.ДоговорНомер, b.external_id, p.ОДОплачено , b.[основной долг уплачено] , p.ПроцентыОплачено , b.[Проценты уплачено] ,  b.[ПениУплачено] ,  p.ПениОплачено 
	into #t
	from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] p
	full outer join [dbo].[dm_CMRStatBalance_2] b
	on b.external_id = p.ДоговорНомер and b.d=p.ДатаОперации
	where p.ДатаОперации >= '2018-01-01' and b.d >= '2018-01-01'

	-- по дням
	if @p=1 
	begin
			select d, sum(abs(ОДОплачено - [основной долг уплачено])) РазницаОД, sum(abs(ПроцентыОплачено-[Проценты уплачено])) РазницаПроценты, sum(abs([ПениУплачено]-ПениОплачено)) РазницаПени 
			from #t
			where (ОДОплачено <> [основной долг уплачено] or ПроцентыОплачено<>[Проценты уплачено] or [ПениУплачено] <> ПениОплачено)
			group by d
			order by d desc
	end

	-- все договора
	if @p=2
	begin
		select * from #t
		where (ОДОплачено <> [основной долг уплачено] or ПроцентыОплачено<>[Проценты уплачено] or [ПениУплачено] <> ПениОплачено) 
		order by d desc
	end

END
