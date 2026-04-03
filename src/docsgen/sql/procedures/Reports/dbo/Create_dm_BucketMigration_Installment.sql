
-- =============================================
-- Author:		
-- Create date: 2021-12-07
-- Description:	 Общая часть. Сохраненый баланс витрина
--             exec [dbo].[Create_dm_BucketMigration_Installment] 
--DWH-1431

---- =============================================
CREATE     PROCEDURE [dbo].[Create_dm_BucketMigration_Installment]
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


----- найдем договора, которые ушли и вернулись из просрочки в течении дня
declare  @DateCalculate date = cast(getdate() as date)
declare  @dt_begin_of_month date = dateadd(dd,1,EOMONTH(@DateCalculate, -1))
declare  @dt_next_month date = dateadd(dd,1,EOMONTH(@DateCalculate, 0))

 declare @firstday date = @dt_begin_of_month
 

 drop table if exists #change_bucket
 
	  select
		cast(ap.Период as date) 'Дата'
	    , rn_by_day_begin = ROW_NUMBER()  over (partition by de.Код , cast(ap.Период as date) order by ap.Период  )
		,  rn_by_day_end = ROW_NUMBER()  over (partition by de.Код , cast(ap.Период as date) order by ap.Период  desc)	
		,  dpd_day_tomorrow =(LAG((ap.КоличествоПолныхДнейПросрочкиУМФО)) over(partition by de.Код  order by ap.Период desc))
		,  dpd_day_yesterday =(LEAD((ap.КоличествоПолныхДнейПросрочкиУМФО)) over(partition by de.Код  order by ap.Период desc))
		, external_id = de.Код 
		, ap.*
		
	  into #change_bucket
	  from    stg.dbo._1cАналитическиеПоказатели ap 
	   join stg._1cCMR.Справочник_Договоры  de on de.ссылка=ap.договор 
		inner join [Stg].[_1cCMR].[Справочник_типыПродуктов] cmr_ТипыПродуктов
			on de.ТипПродукта = cmr_ТипыПродуктов.ссылка

	   -- 23_07_2020 добавлен учет перехода из последнего дня месяца с нулевым бакетом в учетном
	   where   ap.Период >= dateadd(day,-1,@dt_begin_of_month ) and ap.Период < @dt_next_month
		--and de.IsInstallment = 0x01
		and cmr_ТипыПродуктов.ИдентификаторMDS = 'installment'

	   drop table if exists #change_bucket_by_day
		Select 
			  bucket_begin.Дата
			, bucket_begin.external_id
			-- 23072020, bucket_begin.КоличествоПолныхДнейПросрочкиУМФО dpdBegin
			, dpdBegin_Temp = bucket_begin.КоличествоПолныхДнейПросрочкиУМФО 
			, dpdEnd_Temp = bucket_end.КоличествоПолныхДнейПросрочкиУМФО 
			, dpd_day_tomorrow =bucket_end.dpd_day_tomorrow 
			, bucket_end.ДатаПоследнегоПлатежа
			, ДатаВремяПоследнегоПлатежа = bucket_end.Период 
			, dpd_day_yesterday = bucket_begin.dpd_day_yesterday 
		into #change_bucket_by_day
		from #change_bucket bucket_begin
		left join (select * from #change_bucket where rn_by_day_end =1)  bucket_end
		on bucket_begin.external_id = bucket_end.external_id and bucket_begin.Дата = bucket_end.Дата
		where bucket_begin.rn_by_day_begin=1
		
		 --select * from #change_bucket_by_day where external_id='18091009370001' order by Дата desc

		drop table if exists #change_bucket_by_day_and_tomorrow

		select * 
		-- 23_07_2020 учет перехода без перехода на дню
		, dpdBegin = iif( dpdBegin_Temp >= isnull(dpd_day_yesterday,dpdBegin_Temp), dpdBegin_Temp, dpd_day_yesterday)
		, dpdEnd = iif( dpdEnd_Temp <= isnull(dpd_day_tomorrow,dpdEnd_Temp), dpdEnd_Temp, dpd_day_tomorrow)
		into #change_bucket_by_day_and_tomorrow
		from #change_bucket_by_day

		-- 25.06.2020
		-- учет  договоров, который погашен без перехода в бакет улучшения
		 declare  @dt_today_calculate date = @DateCalculate
		 update #change_bucket_by_day_and_tomorrow
		 set dpdEnd = 0
		 where 
		 dpd_day_tomorrow is null
		 and dpdBegin>0
		 and Дата < @dt_today_calculate 
		 --1707112000003
	     --18060702360001
		 --- конец 26.06.2020
		 
		 --- внесем бакеты переходов
		 drop table if exists #change_bucket_final
		 select 
		 * 
		 , [BucketFirst]=
					case when dpdBegin > 0   and dpdBegin <= 30  
							then '(1)_1_30'
								when dpdBegin >= 31  and dpdBegin <= 60 
							then '(2)_31_60'
								when dpdBegin >= 61  and dpdBegin <= 90   
							then '(3)_61_90'
								when dpdBegin >= 91  and dpdBegin <= 360                   
							then '(4)_91_360'
								when dpdBegin >= 360                                    
							then '(5)_361+'
							when dpdBegin = 0
							then 'PreDel'
							else '(7)_Other' 
					end
		, [BucketLast]=
					case when dpdEnd > 0   and dpdEnd <= 30   
							then '(1)_1_30'
								when dpdEnd >= 31  and dpdEnd <= 60 
							then '(2)_31_60'
								when dpdEnd >= 61  and dpdEnd <= 90   
							then '(3)_61_90'
								when dpdEnd >= 91  and dpdEnd <= 360                   
							then '(4)_91_360'
								when dpdEnd >= 360                                    
							then '(5)_361+'
							when dpdEnd = 0
							then 'PreDel'
							else '(7)_Other' 
					end
	, [BucketFirstNumber]=
					case when dpdBegin > 0   and dpdBegin <= 30  
							then 1
								when dpdBegin >= 31  and dpdBegin <= 60  
							then 2
								when dpdBegin >= 61  and dpdBegin <= 90   
							then 3
								when dpdBegin >= 91  and dpdBegin <= 360                   
							then 4
								when dpdBegin >= 360                                    
							then 5
							when dpdBegin = 0
							then 0
							else null 
					end
		, [BucketLastNumber]=
	case when dpdEnd > 0   and dpdEnd <= 30  
			then 1
				when dpdEnd >= 31  and dpdEnd <= 60 
			then 2
				when dpdEnd >= 61  and dpdEnd <= 90  
			then 3
				when dpdEnd >= 91  and dpdEnd <= 360                   
			then 4
				when dpdEnd >= 360                                    
			then 5
			when dpdEnd = 0
			then 0
			else null 
    end
	, [BucketBeforeNumber]=
	case when dpd_day_yesterday > 0   and dpd_day_yesterday <= 30   
			then 1
				when dpd_day_yesterday >= 31  and dpd_day_yesterday <= 60  
			then 2
				when dpd_day_yesterday >= 61  and dpd_day_yesterday <= 90  
			then 3
				when dpd_day_yesterday >= 91  and dpd_day_yesterday <= 360                   
			then 4
				when dpd_day_yesterday >= 360                                    
			then 5
			when dpd_day_yesterday = 0
			then 0
			else null 
    end
	-- для связи со справочником рисковиков
	   , dpd_bucket=
					case when dpdBegin > 0   and dpdBegin <= 30   
							then '(2)_1_30'
								when dpdBegin >= 31  and dpdBegin <= 60  
							then '(3)_31_60'
								when dpdBegin >= 61  and dpdBegin <= 90   
							then '(4)_61_90'
								when dpdBegin >= 91  and dpdBegin <= 360                   
							then '(5)_91_360'
								when dpdBegin >= 360                                    
							then '(6)_361+'
							when dpdBegin = 0
							then '(1)_0'
							else '(7)_Other' 
					end
		, dpd_bucket_end=
					case when dpdEnd > 0   and dpdEnd <= 30   
							then '(2)_1_30'
								when dpdEnd >= 31  and dpdEnd <= 60  
							then '(3)_31_60'
								when dpdEnd >= 61  and dpdEnd <= 90   
							then '(4)_61_90'
								when dpdEnd >= 91  and dpdEnd <= 360                   
							then '(5)_91_360'
								when dpdEnd >= 360                                    
							then '(6)_361+'
							when dpdEnd = 0
							then '(1)_0'
							else '(7)_Other' 
					end
	, cast(null as date) [Дата перехода бакета] -- далее обновим
	into #change_bucket_final
	from #change_bucket_by_day_and_tomorrow


		 --- зафиксируем  переходы
		 drop table if exists #bucket_transfer

		 -- найдем все переходы на улушчение
		 select 1 type_transfer,* 
		 into #bucket_transfer
		 from #change_bucket_final
		 where 
		 -- с утра стало лучше (таких мало)
		 BucketBeforeNumber>BucketFirstNumber
		 -- -- в течение дня стало лушче
		 or 
		 BucketFirstNumber>[BucketLastNumber]
		 
		 union all
		 -- на ухудшение
		 select -1,* 
		 from #change_bucket_final
		 where 
		 -- с утра стало хуже
		 BucketBeforeNumber<BucketFirstNumber
		 or 
		 -- в течение дня стало хуже (их нет)
		 BucketFirstNumber<[BucketLastNumber]


		 --select * from #bucket_transfer
		 -- where external_id='18091009370001'

		 
--- найдем дату предыдущего перехода в другой бакет, если он был
update z
set [Дата перехода бакета] = old_change_bucket 
FROM
( SELECT a0.[Дата перехода бакета], a3.old_change_bucket  , a0.Дата, a0.external_id
--, * 
from #bucket_transfer a0
left join (
			select  
				*,
				lag(Дата) over (partition by external_id order by дата, type_transfer ) old_change_bucket
			from #bucket_transfer a1

			) a3
			on a3.external_id = a0.external_id	and a3.Дата =   a0.Дата and a3.type_transfer = a0.type_transfer
			where 
					a0.type_transfer = 1
					and old_change_bucket is not null
) z




		  -- для остальных ставим первую дату месяца
		  
		  update #bucket_transfer
		  set [Дата перехода бакета]=  @firstday
		  where type_transfer=1 and [Дата перехода бакета] is null


		  -- удалим ненужные переходы (в данном скрипте рассмотрены только улучшения)
		  delete from #bucket_transfer where type_transfer <> 1

		-- конвертируем день прошлого месяца перехода на первый день месяца
		update #bucket_transfer
		  set [Дата перехода бакета]=  @firstday
		  where [Дата перехода бакета] < @firstday		 
begin tran		 
		 --- для дальнейшенго обновления, после разработки
		delete from [dm_BucketMigration_Installment]
		where Период = Format(@dt_begin_of_month ,'yyyy-MM')


		
		 
		 -- добавим ОД
		  -- посчитаем приведенный баланс
		  --drop table if exists  dwh2.[dbo].[dm_BucketMigration]
		  insert into dbo.[dm_BucketMigration_Installment]
		  Select 
				Format(@dt_begin_of_month,'yyyy-MM') Период
				, tr.*
				, b.[остаток од] 
				  , СохрБалансПриведен = case 
				when BucketLastNumber = 0 then
							case 
								when BucketFirstNumber = 1 then [остаток од]
								when BucketFirstNumber = 2 then [остаток од]
								when BucketFirstNumber = 3 then [остаток од]
								else 0 --ОД
							end
				when BucketLastNumber = 1 then 
							case 
								when BucketFirstNumber = 2 then [остаток од]*((7.0-1.5)/7.0)
								when BucketFirstNumber = 3 then [остаток од]*((15.0-1.5)/15.0)
								else 0 --ОД
							end
				when BucketLastNumber = 2 then 
							case 							
								when BucketFirstNumber = 3 then [остаток од]*((15.0-7.0)/15.0)
								else 0 --ОД
							end
				else 0 --ОД
				end				
		  
		  from #bucket_transfer tr
		  left join [dbo].[dm_CMRStatBalance_2] b on tr.external_id = b.external_id 
			and b.d = tr.[Дата перехода бакета]
		  where tr.type_transfer = 1
		  and tr.Дата >= @firstday -- 23_07_2020 учитываем только расчетный месяц

commit tran
END
