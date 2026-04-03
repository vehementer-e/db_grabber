
  CREATE proc [dbo].[Платежи задним числом]
  as
  begin

  select * into #t1 from stg._1cCMR.Документ_Платеж where Дата>='40210101'
  select * into analytics.dbo.[Документ_Платеж where Дата>='40210101' 2022-02-01 10:20] from #t1

  
  select * into #t2 from stg._1cCMR.Документ_Платеж where Дата>='40210101'
  select * into analytics.dbo.[Документ_Платеж where Дата>='40210101' 2022-03-02 16:32] from #t2


  

  end