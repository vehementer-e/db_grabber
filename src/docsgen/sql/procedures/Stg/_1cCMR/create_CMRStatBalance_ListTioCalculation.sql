

 --exec _1cCMR.[create_CMRStatBalance_ListTioCalculation]
CREATE PROC _1cCMR.create_CMRStatBalance_ListTioCalculation
	
as

begin

set nocount on
	 declare @today datetime =getdate()
  declare @dtTo date= dateadd(year,2000,@today) 
  declare @dtFrom date = @dtTo
  if  DATENAME(WEEKDAY,@today) in( 'Monday' , 'Понедельник')
	and cast(@today as time) between '09:00' and '12:00'
	begin
		 set @dtFrom = dateadd(dd,-3, @dtTo)
	end
   -- @dtTo,@dtFrom

-- подготовка списка договоров для расчета на основе текущих платежей за день
-- в расчете баланса далее берутся только уникальные значение номеров договоров (дедубликация), поэтому допустима дополнение теми же данными
 begin tran
   Insert into dbo.CMRStatBalanceListTioCalculation(
	external_id, 
	[Comments], 
	[Договор])
   SELECT distinct  
		external_id = Dogovor.Код
		,Comments = 'Платежи CRM для расчета баланса за сегодня' 
		,Dogovor.Ссылка
		
    from [_1cCMR].[Справочник_Договоры]  Dogovor (nolock)
	left join  [_1cCMR].[документ_платеж] Payment (nolock) on Payment.Договор=Dogovor.Ссылка
   where  Payment.Дата between @dtFrom 
   and dateadd(dd,1,@dtTo)
   group by Dogovor.Код, Dogovor.Ссылка

	--DWH-539
	insert dwh2.sat.ДоговорЗайма_КоличествоДнейПросрочки_change(КодДоговораЗайма)
	SELECT distinct КодДоговораЗайма = external_id
	FROM dbo.CMRStatBalanceListTioCalculation AS C

  commit tran

end
