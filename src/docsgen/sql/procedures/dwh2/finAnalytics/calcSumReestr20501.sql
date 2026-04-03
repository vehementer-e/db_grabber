/*Процедура на основании входных данных начала @startDate и конец @endDate период рассчитывает суммы Поступлений @inSumm и Списаний @outSumm из проводок. Корреспонденция счетов которые интересуют это:
	Поступление
	Дт'20501', 
	Кт'43108,20209,60336,10614,20601,42316,42317,43708,43808,47416,47422,47423,60305,60308,60311,60312,60322,60323,60331,60332,71001,71701,71702'
	Списание
	Дт 43109,20209,20601,42316,42317,43708,43709,43719,43808,43809,47416, 47422,47423,48501,52008,60301,60305,60307,60308,60311,60312,60320,60322,60323,60331,60332,60335,60336,71702'
	Кт '20501'
	Дополнение
	!!!Суммы по проводкам с ДТ 20501 и Кт 20501 и прибавляем к суммам Поступления и Списания
*/
CREATE PROC [finAnalytics].[calcSumReestr20501] 
		@startDate datetime
		,@endDate datetime
		,@inSumm float out
		,@outSumm float out
	
AS
BEGIN
set @startDate=dateadd(year,2000,@startDate)
set @endDate=dateadd(second,86399,dateadd(year,2000,@endDate))
declare @var20501 float


--Поступление
declare @inDt varchar(500)='20501', 
		@inKt varchar(500)='43108,20209,60336,10614,20601,42316,42317,43708,43808,47416,47422,47423,60305,60308,60311,60312,60322,60323,60331,60332,71001,71701,71702'
--Списание
declare @outDt varchar(500)='43109,20209,20601,42316,42317,43708,43709,43719,43808,43809,47416,47422,47423,48501,52008,60301,60305,60307,60308,60311,60312,60320,60322,60323,60331,60332,60335,60336,71702',
		@outKt varchar(500)='20501'

		

--Поступление
set @inSumm =isnull((select 
					sum(a.Сумма)
				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка
				where (b.Код in(select value from  string_split(@inDt,','))
						and
						c.Код in (select value from  string_split(@inKt,',')))
						
						and a.Период between @startDate and @endDate 
						and a.Активность=0x01)
					,0)
--Списание	
set @outSumm =isnull((select 
				 summ=sum(a.Сумма)
				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка
				where (b.Код in (select value from  string_split(@outDt,','))
						and
						c.Код in(select value from  string_split(@outKt,',')))
					   and a.Период between @startDate and @endDate
					   and a.Активность=0x01)
					,0)
--Дополнение
set @var20501=isnull((select 
				 summ=sum(a.Сумма)
				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка
				where (b.Код ='20501'
						and
						c.Код= '20501')
					   and a.Период between @startDate and @endDate
					   and a.Активность=0x01)
					,0)
set @inSumm=@inSumm+@var20501
set @outSumm=@outSumm+@var20501

END

