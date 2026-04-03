create proc dbo.pay_report_old 
@f date, @t date 
as 




SELECT [Дата]
      ,[ДеньПлатежа]
      ,[МесяцПлатежа]
      ,[ДатаОтражения]
      ,[ДатаСозданияДокумента]
      ,[Сумма]
      ,[ссылка]
      ,[Договор]
      ,[Код]
      ,
	  
	  case when  case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end = 'Contact' then 'Офлайн: Contact'
	       when  case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end = 'Расчетный счет' then 'р/с'
	       when  case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end ='ECommPay' then 'Онлайн: Ecomm'
		   when  case when [ПлатежнаяСистема]='Киви' then 'Contact' else [ПлатежнаяСистема] end ='Cloud payments' then 'Онлайн: Cloud'
	       else 'Остальные' end
	  
	  
	  
	  [ПлатежнаяСистема] 
      ,[Проведен]
      ,[ПометкаУдаления]
      ,[НомерПлатежа]
      ,[КомиссияCКлиента]
      ,[ДоходСКлиента]
      ,[КомиссияПШ]
      ,[created]
      ,[Прибыль]
  FROM analytics.dbo.[v_repayments] 
where ДеньПлатежа between @f and @t