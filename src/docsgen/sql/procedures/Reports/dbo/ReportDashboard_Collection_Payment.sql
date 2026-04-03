


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-06-09
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_Payment]   
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_Payment]
	
	-- Add the parameters for the stored procedure here
--	@DateReport date
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
	Set datefirst 1





   -- для целей определения платежей
  	
	--drop table if exists [dbo].dm_Collection_IP_Payment
	--DWH-1764 
	TRUNCATE TABLE [dbo].dm_Collection_IP_Payment

	INSERT [dbo].dm_Collection_IP_Payment
	(
	    external_id,
	    Дата,
	    Сумма,
	    [Платежная система]
	)
	select aa.external_id,
           aa.Дата,
           aa.Сумма,
           aa.[Платежная система] 
	--into [dbo].dm_Collection_IP_Payment
	from
	( select d.Код external_id
                    , cast(p.дата as date) Дата
                    , Сумма=SUM(isnull(p.Сумма ,0.0))
                   -- , first_value(ps.наименование) over (partition by d.Код order by  isnull(p.Сумма ,0.0) desc) paymentSystem
					--,p.*
					,min(isnull(ps.наименование,'Р/С')) 'Платежная система'
                   
       		      from stg._1cCMR.[Документ_Платеж] p
       		      join stg._1cCMR.Справочник_Договоры d on d.ссылка=p.Договор
                 left join stg._1cCMR.[Справочник_ПлатежныеСистемы] ps on p.ПлатежнаяСистема=ps.ссылка
             where
			 p.дата>=Dateadd(day,-124,dateadd(year,2000,GetDAte()))
			 --Проведен=0x01
			 --and 
			 --d.Код in (	
				--		select  distinct Deals.Number
				--		from [Stg].[_Collection].Deals		
				--		left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
				--		left join  [Stg].[_Collection].[CollectingStage] cst  on  c.[IdCollectingStage] = cst.id
				--		where  cst.Name = 'Legal' or cst.Name = 'ИП'
				--		or cst.Name = 'Closed' or cst.Name = 'Writeoff'

				--		)

			GROUP BY d.Код, cast(p.дата as date)
			)aa
	/* 
		select * from  [dbo].dm_Collection_IP_Payment 
		where [Платежная система]  = 'БРС'
		select [Платежная система] from  [dbo].dm_Collection_IP_Payment 
		group by [Платежная система] 
	*/



END
