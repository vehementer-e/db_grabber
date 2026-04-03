
-- =============================================
-- Author:		Petr Ilin
-- Create date: 09042020
-- Description:	Обещания заплатить из вупры и СПЕЙСА и цмр
-- =============================================

CREATE proc [dbo].[create_dm_report_woopra_promise_date] 

as 
begin

/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/

drop table if exists #woo
SELECT [id]
      ,[rn1]
      ,cast(cast([timestamp] as nvarchar(19)) as datetime2) [Timestamp]
      ,[Name]
      ,[Action Name]
      ,[Platform]
      ,[has_arrears]
      ,[reference_id]
      ,[days_offset]
      ,[project]
      ,[report_id]
      ,[dt]
      ,[offset]
      ,[limit]
      ,[total]
	  into #woo
  FROM [Woopra].[dbo].[Report_mobile_app]
  where [Action Name]='feature_contract_pledge_ok '

  	/*	
drop table if exists #t1mob

	   select c.id, 
	   c.Date [дата регистрации обещания], 
	   Number [номер договора], 
	   PromiseSum [сумма обещания], 
	   PromiseDate [дата выполнения обещания], 
	   Commentary [комментарий]    
	   into #t1mob
	   FROM [Stg].[_Collection].[Communications] c
	   	left join  [Stg].[_Collection].[Deals] d on c.IdDeal=d.id
		where number in (select days_offset from #woo) and CommunicationType=16 and CommunicationResultId=7

		*/

drop table if exists #t1all
	   select c.id, 
	   c.Date [дата регистрации обещания], 
	   Number [номер договора], 
	   PromiseSum [сумма обещания], 
	   PromiseDate [дата выполнения обещания], 
	   Commentary [комментарий]  ,
	   CommunicationType
	  into #t1all
	   FROM [Stg].[_Collection].[Communications] c
	   	left join  [Stg].[_Collection].[Deals] d on c.IdDeal=d.id
		where number in (select days_offset from #woo) and CommunicationResultId=7

		drop table if exists #foragr

		select woo.Timestamp, woo.days_offset, case when ДатаОбещания is not null and ДатаОбещания <cast(getdate() as date) then 1 
		               when ДатаОбещания is not null and ДатаОбещания >=cast(getdate() as date) then 0
		              
		else null end флагСозревания, x.*, x1.*, x2.*, cmrd.dpd 
		into #foragr
		from #woo woo
		outer apply( select sign(count(id)) ОбещанийСпейс from #t1all c where [номер договора]=woo.days_offset and c.[дата выполнения обещания] >cast([Timestamp] as date)) x
		outer apply( select sign(count(id)) ОбещанийСпейсМП from #t1all c where [номер договора]=woo.days_offset and c.[дата регистрации обещания] >=cast([Timestamp] as date) and c.[дата регистрации обещания] <=dateadd(d, 2, cast([Timestamp] as date)) and CommunicationType=16) x1
		outer apply( select min([дата выполнения обещания]) ДатаОбещания from #t1all c where [номер договора]=woo.days_offset and c.[дата выполнения обещания] >=cast([Timestamp] as date) and c.[дата выполнения обещания] <dateadd(dd, 35, [Timestamp])) x2
		left join [dbo].[dm_CMRStatBalance_2] cmrd on cmrd.d=cast(getdate() as date) and days_offset=cmrd.external_id and ДатаОбещания is not null


			  --drop table if exists [dbo].dm_report_woopra_promise_date
			  --DWH-1764
			  TRUNCATE TABLE [dbo].dm_report_woopra_promise_date
		INSERT [dbo].dm_report_woopra_promise_date
		(
		    Дата,
		    ЧислоСобытий,
		    ЧислоОбещанийСпейс,
		    ЧислоОбещанийСпейсМП,
		    ЧислоНайденныхОбещаний,
		    НесозревшиеОбещания,
		    БезПросрочкиДозревшие,
		    СПросрочкойДозревшие
		)
		select cast(timestamp as date) Дата, 
		count(days_offset) ЧислоСобытий, 
		sum(ОбещанийСпейс) ЧислоОбещанийСпейс, 
		sum(ОбещанийСпейсМП) ЧислоОбещанийСпейсМП, 
		count(ДатаОбещания) ЧислоНайденныхОбещаний,
		count(case when флагСозревания=0 then ДатаОбещания end) НесозревшиеОбещания,
		count(case when флагСозревания=1 and dpd=0 or dpd is null then ДатаОбещания end) БезПросрочкиДозревшие,
		count(case when флагСозревания=1 and dpd>0 then ДатаОбещания end) СПросрочкойДозревшие
		--into [dbo].dm_report_woopra_promise_date 
	    from #foragr
		group by cast(timestamp as date)




end
