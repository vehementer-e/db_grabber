-- exec [dbo].[Create_dm_Telegram_Collection_part1] '2020-04-24'
create  PROCEDURE  [dbo].[Create_dm_Telegram_Collection_part1] 
	@DateBegin date
AS
BEGIN
	SET NOCOUNT ON;
-- запрос коллекшн финал для создания витрины
-- Данные для телеграмм генерируем на основе view

-----------------------------------------------------------------------------
--- первая часть расчет за сегодня--------------------------------------------
-----------------------------------------------------------------------------
  declare  @dt date = cast(dateadd(day,0, getdate()) as date)

  -- если дата пришла не пустая
  if (@DateBegin is not null)
	  begin
		 Set @dt = @DateBegin
	  end

    -- Временная таблица для исключения блокировки в транзакции
 if object_id('tempdb.dbo.#baket') is not null drop table #baket

CREATE TABLE #Baket(
	[baket] [nvarchar](50) NULL
) 

 insert into #baket select N'0'
 insert into #baket select N'1-3'
 insert into #baket select N'4-30'
 insert into #baket select N'31-60'
 insert into #baket select N'61-90'
 insert into #baket select N'91-360'
 insert into #baket select N'360+'

 --select * from #baket

  -- Временная таблица для исключения блокировки в транзакции
 if object_id('tempdb.dbo.#balance_today') is not null drop table #balance_today

 select * into #balance_today
 from  [dbo].[dm_CMRStatBalance_2]  balance (nolock) where balance.d = @dt

  --select *  from [dbo].[dm_Telegram_Collection] where Период=@dt
  begin tran

  delete from [dbo].[dm_Telegram_Collection] where Период=@dt

  insert into [dbo].[dm_Telegram_Collection] (Период, [Платежи по ОД], [Сумма поступлений], [Проценты], [Пени], [Бакет просрочки])
  Select @dt 'Период', Sum(isnull(sum_OD,0)) 'Платежи по ОД', Sum(isnull(sum_all,0)) [Сумма поступлений], Sum(isnull(sum_procent,0)) [Проценты], Sum(isnull(sum_penalty,0)) [Пени], bkt.baket "Бакет просрочки"
  --into [dbo].[dm_Telegram_Collection]
  FROM
  (
    select ([основной долг уплачено]) sum_OD, isnull([основной долг уплачено],0)+ isnull([Проценты уплачено],0)+ isnull(ПениУплачено,0) sum_all, [Проценты уплачено] sum_procent, ПениУплачено sum_penalty, ПереплатаУплачено sum_over
	 ,case
		when [dpd day-1]=0 or [dpd day-1] is null  then N'0'
		else
			case
				when [dpd day-1]>0 and [dpd day-1]<4 then N'от 0 до 3 дней'
				when [dpd day-1]>3 and [dpd day-1]<31 then N'от 3 до 30 дней'
				when [dpd day-1]>30 and [dpd day-1]<61 then N'от 30 до 60 дней'
				when [dpd day-1]>60 and [dpd day-1]<91 then N'от 60 до 90 дней'
				when [dpd day-1]>90 and [dpd day-1]<121 then N'от 90 до 120 дней'
				when [dpd day-1]>120 and [dpd day-1]<151 then N'от 120 до 150 дней'
				when [dpd day-1]>150 and [dpd day-1]<181 then N'от 150 до 180 дней'
				when [dpd day-1]>180 and [dpd day-1]<211 then N'от 180 до 210 дней'
				when [dpd day-1]>210 and [dpd day-1]<241 then N'от 210 до 240 дней'
				when [dpd day-1]>240 and [dpd day-1]<271 then N'от 240 до 270 дней'
				when [dpd day-1]>270 and [dpd day-1]<301 then N'от 270 до 300 дней'
				when [dpd day-1]>300 and [dpd day-1]<331 then N'от 300 до 330 дней'
				when [dpd day-1]>330 and [dpd day-1]<361 then N'от 330 до 360 дней'
				when [dpd day-1]>360 then N'от 360 дней'
			end
		end as Бакет1
		,case
		when [dpd day-1]=0 or [dpd day-1] is null  then N'0'
		else
			case
				when [dpd day-1]>0 and [dpd day-1]<4 then N'1-3'
				when [dpd day-1]>3 and [dpd day-1]<31 then N'4-30'
				when [dpd day-1]>30 and [dpd day-1]<61 then N'31-60'
				when [dpd day-1]>60 and [dpd day-1]<91 then N'61-90'
				when [dpd day-1]>90 and [dpd day-1]<121 then N'91-120'
				when [dpd day-1]>120 and [dpd day-1]<151 then N'121-150'
				when [dpd day-1]>150 and [dpd day-1]<181 then N'151-180'
				when [dpd day-1]>180 and [dpd day-1]<211 then N'181-210'
				when [dpd day-1]>210 and [dpd day-1]<241 then N'211-240'
				when [dpd day-1]>240 and [dpd day-1]<271 then N'241-270'
				when [dpd day-1]>270 and [dpd day-1]<301 then N'271-300'
				when [dpd day-1]>300 and [dpd day-1]<331 then N'301-330'
				when [dpd day-1]>330 and [dpd day-1]<361 then N'331-360'
				when [dpd day-1]>360 then N'360+'
			end
		end as Бакет2
		,case
		when [dpd day-1]=0 or [dpd day-1] is null  then N'0'
		else
			case
				when [dpd day-1]>0 and [dpd day-1]<4 then N'1-3'
				when [dpd day-1]>3 and [dpd day-1]<31 then N'4-30'
				when [dpd day-1]>30 and [dpd day-1]<61 then N'31-60'
				when [dpd day-1]>60 and [dpd day-1]<91 then N'61-90'
				when [dpd day-1]>90 and [dpd day-1]<361 then N'91-360'
				when [dpd day-1]>360 then N'360+'
			end
		end as Бакет3
		--, * 
  from  #balance_today bt

  ) sq
    right join #Baket  bkt on bkt.baket = sq.Бакет3
  group by bkt.baket

  commit tran


END
