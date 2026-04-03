
-- =============================================
-- Author:		Petr Ilin
-- Create date: 07042020
-- Description:	Переносы даты платежей из вупры и цмр
-- =============================================

CREATE proc [dbo].[create_dm_report_woopra_pay_date] 

as 
begin

	  drop table if exists #tmpmar
	 	  select cast(Время as date) Дата, count(distinct days_offset) [Событий в МП], 
	  count(distinct case when ДатаЗаписи is not null and ПометкаУдаления =0 and Проведен=1 then НомерДоговора end) [Событий в ЦМР + отмененные], 	  
	  count(distinct case when ДатаЗаписи is not null and ПометкаУдаления =0 and Проведен=1 then НомерДоговора end) [Событий в ЦМР], 
	  count( distinct case when (dpd=0 or dpd is null) and ДатаЗаписи is not null and ПометкаУдаления =0 and Проведен=1 then НомерДоговора end) [Событий в ЦМР dpd0], 
	  count( distinct case when (dpd=0 or dpd is null) and ДатаЗаписи is not null and НоваяДатаПлатежа<cast(getdate() as date) and ПометкаУдаления =0 and Проведен=1  then НомерДоговора end) [Событий в ЦМР dpd0 и дозревшие], 
	  count(distinct case when Перенос=28 and ДатаЗаписи is not null and ПометкаУдаления =0 and Проведен=1 then НомерДоговора end) [Событий в ЦМР28], 
	  getdate() as created_at
		into #tmpmar
	from 
	  (  
	 select 
	 cast(cast([timestamp] as nvarchar(19)) as datetime2) Время,
	 [days_offset],
	 dog.Код НомерДоговора,
	 per.ПометкаУдаления,
	 per.Проведен,
	 stb.dpd,
	 dateadd(yy, -2000, per.Дата) ДатаЗаписи, 
	 dateadd(yy, -2000, per.НоваяДатаПлатежа) НоваяДатаПлатежа, 	
	 dateadd(yy, -2000, per.СледующаяДатаПлатежа) СледующаяДатаПлатежа, 	
	 dateadd(yy, -2000, per.МаксимальнаяДатаПлатежа) МаксимальнаяДатаПлатежа, 	
	 DATEDIFF(DAY, per.СледующаяДатаПлатежа, per.НоваяДатаПлатежа) Перенос

	from [Woopra].[dbo].[Report_mobile_app] woo
	left join  stg.[_1cCMR].[Справочник_Договоры] dog on woo.[days_offset]=dog.Код
	left join [Stg].[_1cCMR].Документ_ОбращениеНаИзменениеДатыПлатежа per on  per.договор=dog.Ссылка and   dateadd(yy, -2000, per.Дата) <getdate()
	left join [dbo].[dm_CMRStatBalance_2] stb on stb.external_id=dog.Код and stb.d=cast(getdate() as date)
	  where [action name]='feature_contract_date_transfer_success' and cast(cast([timestamp] as nvarchar(19)) as datetime2)>'2020-04-02T12:00:00'
	  ) cc
	  group by  cast(Время as date)
	

	  --drop table if exists [dbo].dm_report_woopra_pay_date
	  --DWH-1764 
	  TRUNCATE TABLE [dbo].dm_report_woopra_pay_date

	  INSERT [dbo].dm_report_woopra_pay_date
	  (
	      Дата,
	      [Событий в МП],
	      [Событий в ЦМР + отмененные],
	      [Событий в ЦМР],
	      [Событий в ЦМР dpd0],
	      [Событий в ЦМР dpd0 и дозревшие],
	      [Событий в ЦМР28],
	      created_at
	  )
	  select 
		Дата,
        [Событий в МП],
        [Событий в ЦМР + отмененные],
        [Событий в ЦМР],
        [Событий в ЦМР dpd0],
        [Событий в ЦМР dpd0 и дозревшие],
        [Событий в ЦМР28],
        created_at
	  --INTO [dbo].dm_report_woopra_pay_date
	  FROM #tmpmar

end
