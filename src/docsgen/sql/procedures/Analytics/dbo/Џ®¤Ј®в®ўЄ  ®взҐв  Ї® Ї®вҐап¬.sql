
CREATE PROCEDURE [dbo].[Подготовка отчета по потерям] AS

begin

set datefirst  1

--ОПРЕДЕЛЯЕМ ДАТЫ ОТЧЕТА

	declare @date as date = '20221130'--getdate()
	declare @date_past as date 


	drop table if exists #fa_past

	select cast([Верификация КЦ] as date) Дата,
		sum([Выданная сумма]) 'Выданная сумма', 
		DATEPART(dw,[Верификация КЦ]) Неделя 
	into #fa_past
	from Reports.dbo.dm_Factor_Analysis_001  
	where ispts = 1
	group by cast([Верификация КЦ] as date), 
		DATEPART(dw,[Верификация КЦ])
	order by cast([Верификация КЦ] as date) desc


	drop table if exists #date

	select  top (1) Дата
	into #date
	from #fa_past
	where [Выданная сумма] > 
			(select [Займы руб] 
			from stg.files.contactcenterplans_buffer_stg  
			where 
				Дата = @date) 
				and iif(DATEPART(dw, @date) in (1,2,3,4,5), 'рабочий день', 'выходной') = iif(DATEPART(dw, Дата) in (1,2,3,4,5), 'рабочий день', 'выходной') 
	order by Дата desc


	set @date_past ='20221123' --(select * from #date)

-- ИСХОДНЫЕ ДАННЫЕ

	drop table if exists #fa

	select Телефон,
		Номер,
		[Место cоздания],
		iif([Вид займа] = 'Первичный','Новый','Повторный') [Вид займа],
		ПризнакЗаявка,
		ПризнакПредварительноеОдобрение,
		ПризнакКонтрольДанных,
		ПризнакОдобрено,
		ПризнакОтказано,
		ПризнакЗайм,
		cast([Верификация КЦ] as date) [Верификация КЦ],
		cast([Предварительное одобрение] as date) [Предварительное одобрение],
		cast([Контроль данных] as date) [Контроль данных],
		cast(Одобрено as date) Одобрено,
		cast(Отказано as date) Отказано,
		cast([Заем выдан] as date) [Заем выдан],
		[Выданная сумма],
		case
			when cast([Верификация КЦ] as date) = @date then convert(varchar(10),[Верификация КЦ],104) 
			when cast([Верификация КЦ] as date) = (select * from #date) then  convert(varchar(10),[Верификация КЦ],104) 
			else 'Прочее'
		end 'Дата для анализа'
	into #fa
	from Reports.dbo.dm_Factor_Analysis_001 
	where  cast([Верификация КЦ] as date) >= dateadd(month,-6,@date) 
		and ispts = 1
		and  Дубль = 0
	order by [Верификация КЦ]

--ДАННЫЕ ПО %ПРЕДОБОДРЕНИЯ

	drop table if exists #pd_today

	select  '%Предодобрения' Показатель,
		[Вид займа], 
		cast([Верификация КЦ] as date) Дата, 
		cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float)  'Текущая дата'
	into #pd_today
	from #fa
	where cast([Верификация КЦ] as date) = @date
	group by [Вид займа],
		cast([Верификация КЦ] as date)


	drop table if exists #pd_past
	
	select  '%Предодобрения' Показатель,
		[Вид займа], 
		cast([Верификация КЦ] as date) Дата,
		cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float)   'Прошлая дата'
	into #pd_past
	from #fa
	where cast([Верификация КЦ] as date) = @date_past
	group by  [Вид займа],
		cast([Верификация КЦ] as date)


	drop table if exists #pd_today_total

	select  '%Предодобрения' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float)  'Текущая дата'
	into #pd_today_total
	from #fa
	where cast([Верификация КЦ] as date) = @date


	drop table if exists #pd_past_total

	select  '%Предодобрения' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float)  'Прошлая дата'
	into #pd_past_total
	from #fa
	where cast([Верификация КЦ] as date) = @date_past


	drop table if exists #pd

	select '%Предодобрения' Показатель,
		t1.[Вид займа],
		t1.[Текущая дата], 
		t2.[Прошлая дата], 
		t1.[Текущая дата] - t2.[Прошлая дата] 'Дельта' 
	into #pd
	from #pd_today t1
		join #pd_past t2 on t1.[Вид займа] = t2.[Вид займа] 


	drop table if exists #pd_i

	select * 
	into #pd_i 
	from #pd 
	union
	select ptt.Показатель, 
		ptt.[Вид займа], 
		ptt.[Текущая дата],
		ppt.[Прошлая дата],
		ptt.[Текущая дата]-ppt.[Прошлая дата] 'Дельта'  
	from #pd_today_total ptt
		join #pd_past_total ppt on ptt.Показатель = ppt.Показатель


	drop table if exists #pd_itog

	select Показатель, 
		[Вид займа],
		[Текущая дата], 
		format(@date,'yyyy-MM-dd') 'Дата текст' 
	into #pd_itog  
	from #pd_i
	union
	select Показатель, 
		[Вид займа],
		[Прошлая дата], 
		format(@date_past,'yyyy-MM-dd') 'Дата текст' 
	from #pd_i
	union
	select Показатель, 
		[Вид займа],
		Дельта, 
		'Дельта' 'Дата текст' 
	from #pd_i

--ДАННЫЕ ПО ДОЕЗДУ

	drop table if exists #doezd_today

	select  'Доезд' Показатель,
		[Вид займа],  
		cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) Доезд, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #doezd_today
	from #fa
	where cast([Верификация КЦ] as date) = @date
	group by  [Вид займа]


	drop table if exists #doezd_past

	select  'Доезд' Показатель,
		[Вид займа], 
		cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) Доезд, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #doezd_past
	from #fa
	where cast([Верификация КЦ] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #doezd_today_total

	select  'Доезд' Показатель,
		'Итого' 'Вид займа',  
		cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) Доезд, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #doezd_today_total
	from #fa
	where cast([Верификация КЦ] as date) = @date


	drop table if exists #doezd_past_total

	select  'Доезд' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) Доезд, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #doezd_past_total
	from #fa
	where cast([Верификация КЦ] as date) = @date_past


	drop table if exists #doezd

	select * into #doezd from #doezd_today
	union 
	select * from #doezd_past
	union 
	select * from #doezd_today_total
	union 
	select * from #doezd_past_total


	drop table if exists #doezd_delta_today

	select Показатель, 
		[Вид займа],
		Доезд,
		[Дата текст]
	into #doezd_delta_today 
	from #doezd
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #doezd_delta_past

	select Показатель, 
		[Вид займа],
		Доезд,
		[Дата текст]
	into #doezd_delta_past
	from #doezd
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #doezd_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.Доезд - ddp.Доезд 'Доезд', 
		'Дельта'  'Дата текст'
	into #doezd_delta
	from #doezd_delta_today ddt
		join #doezd_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #Doezd_itog

	select * into #Doezd_itog  from #doezd
	union 
	select * from #doezd_delta


--ДАННЫЕ ПО КД 


	drop table if exists #kd_today

	select  'КД' Показатель,
		[Вид займа],  
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kd_today
	from #fa
	where cast([Контроль данных] as date) = @date
	group by  [Вид займа]


	drop table if exists #kd_past

	select  'КД' Показатель,
		[Вид займа], 
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kd_past
	from #fa
	where cast([Контроль данных] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #kd_today_total

	select  'КД' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакКонтрольДанных)  'КД', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kd_today_total
	from #fa
	where cast([Контроль данных] as date) = @date


	drop table if exists #kd_past_total

	select  'КД' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kd_past_total
	from #fa
	where cast([Контроль данных] as date) = @date_past


	drop table if exists #kd

	select * into #kd from #kd_today
	union 
	select * from #kd_past
	union 
	select * from #kd_today_total
	union 
	select * from #kd_past_total


	drop table if exists #kd_delta_today

	select Показатель, 
		[Вид займа],
		k.КД,
		[Дата текст]
	into #kd_delta_today 
	from #kd k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #kd_delta_past

	select Показатель, 
		[Вид займа],
		k.КД,
		[Дата текст]
	into #kd_delta_past
	from #kd k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #kd_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.КД - ddp.КД 'Доезд', 
		'Дельта'  'Дата текст'
	into #kd_delta
	from #kd_delta_today ddt
		join #kd_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #kd_itog

	select * into #kd_itog from #kd
	union 
	select * from #kd_delta

--AR

	drop table if exists #ar_today

	select  'AR' Показатель,
		[Вид займа],  
		cast(sum(ПризнакОдобрено) as float)/cast(( cast(sum(ПризнакОдобрено) as float) + cast(sum(ПризнакОтказано) as float)) as float) AR, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #ar_today
	from #fa
	where cast([Верификация КЦ] as date) = @date
	group by  [Вид займа]


	drop table if exists #ar_past

	select  'AR' Показатель,
		[Вид займа], 
		cast(sum(ПризнакОдобрено) as float)/cast(( cast(sum(ПризнакОдобрено) as float) + cast(sum(ПризнакОтказано) as float)) as float) AR, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #ar_past
	from #fa
	where cast([Верификация КЦ] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #ar_today_total

	select  'AR' Показатель,
		'Итого' 'Вид займа',  
		cast(sum(ПризнакОдобрено) as float)/cast(( cast(sum(ПризнакОдобрено) as float) + cast(sum(ПризнакОтказано) as float)) as float) AR, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #ar_today_total
	from #fa
	where cast([Верификация КЦ] as date) = @date


	drop table if exists #ar_past_total

	select  'AR' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакОдобрено) as float)/cast(( cast(sum(ПризнакОдобрено) as float) + cast(sum(ПризнакОтказано) as float)) as float) AR, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #ar_past_total
	from #fa
	where cast([Верификация КЦ] as date) = @date_past


	drop table if exists #ar

	select * into #ar from #ar_today
	union 
	select * from #ar_past
	union 
	select * from #ar_today_total
	union 
	select * from #ar_past_total


	drop table if exists #ar_delta_today

	select Показатель, 
		[Вид займа],
		AR,
		[Дата текст]
	into #ar_delta_today 
	from #ar
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #ar_delta_past

	select Показатель, 
		[Вид займа],
		AR,
		[Дата текст]
	into #ar_delta_past
	from #ar
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #ar_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.AR - ddp.AR 'AR', 
		'Дельта'  'Дата текст'
	into #ar_delta
	from #ar_delta_today ddt
		join #ar_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 

	drop table if exists #ar_itog

	select * into #ar_itog from #ar
	union 
	select * from #ar_delta

--ДАННЫЕ ПО КД-ОДОБРЕНО

	drop table if exists #kd_odobr_today

	select  'КД_Одобрено' Показатель,
		[Вид займа],  
		cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) КД_Одобрено,
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kd_odobr_today
	from #fa
	where cast([Верификация КЦ] as date) = @date
	group by  [Вид займа]


	drop table if exists #kd_odobr_past

	select  'КД_Одобрено' Показатель,
		[Вид займа], 
		cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) КД_Одобрено, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kd_odobr_past
	from #fa
	where cast([Верификация КЦ] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #kd_odobr_today_total

	select  'КД_Одобрено' Показатель,
		'Итого' 'Вид займа',  
		cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) КД_Одобрено, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kd_odobr_today_total
	from #fa
	where cast([Верификация КЦ] as date) = @date


	drop table if exists #kd_odobr_past_total

	select  'КД_Одобрено' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) КД_Одобрено, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kd_odobr_past_total
	from #fa
	where cast([Верификация КЦ] as date) = @date_past


	drop table if exists #kd_odobr

	select * into #kd_odobr from #kd_odobr_today
	union 
	select * from #kd_odobr_past
	union 
	select * from #kd_odobr_today_total
	union 
	select * from #kd_odobr_past_total


	drop table if exists #kd_odobr_delta_today

	select 
		Показатель, 
		[Вид займа],
		КД_Одобрено,
		[Дата текст]
	into #kd_odobr_delta_today 
	from #kd_odobr
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #kd_odobr_delta_past

	select 
		Показатель, 
		[Вид займа],
		КД_Одобрено,
		[Дата текст]
	into #kd_odobr_delta_past
	from #kd_odobr
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #kd_odobr_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.КД_Одобрено - ddp.КД_Одобрено 'КД_Одобрено', 
		'Дельта'  'Дата текст'
	into #kd_odobr_delta
	from #kd_odobr_delta_today ddt
		join #kd_odobr_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #kd_odobr_itog

	select * into #kd_odobr_itog from #kd_odobr
	union 
	select * from #kd_odobr_delta


--ДАННЫЕ ПО ОДОБРЕНО


	drop table if exists #odobr_today

	select  'Одобрено' Показатель,
		[Вид займа],  
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #odobr_today
	from #fa
	where cast([Одобрено] as date) = @date
	group by  [Вид займа]


	drop table if exists #odobr_past

	select  'Одобрено' Показатель,
		[Вид займа], 
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #odobr_past
	from #fa
	where cast([Одобрено] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #odobr_today_total

	select  'Одобрено' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакОдобрено)  'Одобрено', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #odobr_today_total
	from #fa
	where cast([Одобрено] as date) = @date


	drop table if exists #odobr_past_total

	select  'Одобрено' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #odobr_past_total
	from #fa
	where cast([Одобрено] as date) = @date_past


	drop table if exists #odobr

	select * into #odobr from #odobr_today
	union 
	select * from #odobr_past
	union 
	select * from #odobr_today_total
	union 
	select * from #odobr_past_total


	drop table if exists #odobr_delta_today

	select 
		Показатель, 
		[Вид займа],
		k.Одобрено,
		[Дата текст]
	into #odobr_delta_today 
	from #odobr k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #odobr_delta_past

	select Показатель, 
		[Вид займа],
		k.Одобрено,
		[Дата текст]
	into #odobr_delta_past
	from #odobr k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #odobr_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.Одобрено - ddp.Одобрено 'Доезд', 
		'Дельта'  'Дата текст'
	into #odobr_delta
	from #odobr_delta_today ddt
		join #odobr_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #odobr_itog

	select * into  #odobr_itog from #odobr
	union
	select * from #odobr_delta


--TU от одобренных сегодня

	drop table if exists #tu_today

	select  'tu' Показатель,
		[Вид займа],  
		cast(sum(ПризнакЗайм) as float)/ cast(sum(ПризнакОдобрено) as float) tu, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #tu_today
	from #fa
	where cast(Одобрено as date) = @date
	group by  [Вид займа]


	drop table if exists #tu_past

	select  'tu' Показатель,
		[Вид займа], 
		cast(sum(ПризнакЗайм) as float)/ cast(sum(ПризнакОдобрено) as float) tu, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #tu_past
	from #fa
	where cast(Одобрено as date) = @date_past
	group by  [Вид займа]

	drop table if exists #tu_today_total

	select  'tu' Показатель,
		'Итого' 'Вид займа',  
		cast(sum(ПризнакЗайм) as float)/ cast(sum(ПризнакОдобрено) as float) tu, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #tu_today_total
	from #fa
	where cast(Одобрено as date) = @date


	drop table if exists #tu_past_total

	select  'tu' Показатель,
		'Итого' 'Вид займа', 
		cast(sum(ПризнакЗайм) as float)/ cast(sum(ПризнакОдобрено) as float) tu, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #tu_past_total
	from #fa
	where cast(Одобрено as date) = @date_past


	drop table if exists #tu

	select * into #tu from #tu_today
	union 
	select * from #tu_past
	union 
	select * from #tu_today_total
	union 
	select * from #tu_past_total


	drop table if exists #tu_delta_today

	select 
		Показатель, 
		[Вид займа],
		tu,
		[Дата текст]
	into #tu_delta_today 
	from #tu
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #tu_delta_past

	select Показатель, 
		[Вид займа],
		tu,
		[Дата текст]
	into #tu_delta_past
	from #tu
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #tu_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.tu - ddp.tu 'tu', 
		'Дельта'  'Дата текст'
	into #tu_delta
	from #tu_delta_today ddt
		join #tu_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #tu_itog

	select * into #tu_itog from #tu
	union 
	select * from #tu_delta


--ДАННЫЕ ПО ВЫДАННЫМ В ДЕНЬ ОДОБРЕНИЯ


	drop table if exists #zaim_today

	select  'Выдан в день одобрения' Показатель,
		[Вид займа],  
		sum(ПризнакЗайм) 'Займов', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #zaim_today
	from #fa
	where cast([Одобрено] as date) = @date and cast([Одобрено] as date) = cast([Заем выдан] as date)
	group by  [Вид займа]


	drop table if exists #zaim_past

	select  'Выдан в день одобрения' Показатель,
		[Вид займа], 
		sum(ПризнакЗайм) 'Займов', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #zaim_past
	from #fa
	where  cast([Одобрено] as date) = @date_past 
		and cast([Одобрено] as date) = cast([Заем выдан] as date)
	group by  [Вид займа]


	drop table if exists #zaim_today_total

	select  'Выдан в день одобрения' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакЗайм)  'Займов', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #zaim_today_total
	from #fa
	where  cast([Одобрено] as date) = @date 
		and cast([Одобрено] as date) = cast([Заем выдан] as date)


	drop table if exists #zaim_past_total

	select  'Выдан в день одобрения' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакЗайм) 'Займов', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #zaim_past_total
	from #fa
	where  cast([Одобрено] as date) = @date_past 
		and cast([Одобрено] as date) = cast([Заем выдан] as date)


	drop table if exists #zaim

	select * into #zaim from #zaim_today
	union 
	select * from #zaim_past
	union 
	select * from #zaim_today_total
	union 
	select * from #zaim_past_total


	drop table if exists #zaim_delta_today

	select Показатель, 
		[Вид займа],
		k.Займов,
		[Дата текст]
	into #zaim_delta_today 
	from #zaim k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #zaim_delta_past

	select Показатель, 
		[Вид займа],
		k.Займов,
		[Дата текст]
	into #zaim_delta_past
	from #zaim k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #zaim_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.Займов - ddp.Займов 'Доезд', 
		'Дельта'  'Дата текст'
	into #zaim_delta
	from #zaim_delta_today ddt
		join #zaim_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #zaim_itog

	select * into #zaim_itog from #zaim
	union 
	select * from #zaim_delta

--ДАННЫЕ ПО ВЫДАННЫМ С ПРЕДЫДУЩИХ ДНЕЙ


	drop table if exists #zaimpr_today

	select  'Выдан с предыдущих дней' Показатель,
		[Вид займа],  
		sum(ПризнакЗайм) 'Займов', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #zaimpr_today
	from #fa
	where cast([Одобрено] as date) != @date 
		and  cast([Заем выдан] as date) = @date
	group by  [Вид займа]


	drop table if exists #zaimpr_past

	select  'Выдан с предыдущих дней' Показатель,
		[Вид займа], 
		sum(ПризнакЗайм) 'Займов', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #zaimpr_past
	from #fa
	where  cast([Одобрено] as date) != @date_past 
		and @date_past = cast([Заем выдан] as date)
	group by  [Вид займа]


	drop table if exists #zaimpr_today_total

	select  'Выдан с предыдущих дней' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакЗайм)  'Займов', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #zaimpr_today_total
	from #fa
	where  cast([Одобрено] as date) != @date 
		and @date = cast([Заем выдан] as date)


	drop table if exists #zaimpr_past_total

	select  'Выдан с предыдущих дней' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакЗайм) 'Займов', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #zaimpr_past_total
	from #fa
	where  cast([Одобрено] as date) != @date_past 
		and @date_past = cast([Заем выдан] as date)


	drop table if exists #zaimpr

	select * into #zaimpr from #zaimpr_today
	union 
	select * from #zaimpr_past
	union 
	select * from #zaimpr_today_total
	union 
	select * from #zaimpr_past_total


	drop table if exists #zaimpr_delta_today

	select Показатель, 
		[Вид займа],
		k.Займов,
		[Дата текст]
	into #zaimpr_delta_today 
	from #zaimpr k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #zaimpr_delta_past

	select Показатель, 
		[Вид займа],
		k.Займов,
		[Дата текст]
	into #zaimpr_delta_past
	from #zaimpr k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #zaimpr_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.Займов - ddp.Займов 'Доезд', 
		'Дельта'  'Дата текст'
	into #zaimpr_delta
	from #zaimpr_delta_today ddt
		join #zaimpr_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #zaimpr_itog

	select * into #zaimpr_itog from #zaimpr
	union 
	select * from #zaimpr_delta

--ДАННЫЕ ПО СРЕДНЕМУ ЧЕКУ

	drop table if exists #srchek_today

	select  'СрЧек' Показатель,
		[Вид займа],  
		sum([Выданная сумма])/sum([ПризнакЗайм]) СрЧек, 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #srchek_today
	from #fa
	where cast([Заем выдан] as date) = @date
	group by  [Вид займа]


	drop table if exists #srchek_past

	select  'СрЧек' Показатель,
		[Вид займа], 
		sum([Выданная сумма])/sum([ПризнакЗайм]) СрЧек, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #srchek_past
	from #fa
	where cast([Заем выдан] as date) = @date_past
	group by  [Вид займа]


	drop table if exists #srchek_today_total

	select  'СрЧек' Показатель,
		'Итого' 'Вид займа',  
		sum([Выданная сумма])/sum([ПризнакЗайм]) СрЧек,
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #srchek_today_total
	from #fa
	where cast([Заем выдан] as date) = @date


	drop table if exists #srchek_past_total

	select  'СрЧек' Показатель,
		'Итого' 'Вид займа', 
		sum([Выданная сумма])/sum([ПризнакЗайм]) СрЧек, 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #srchek_past_total
	from #fa
	where cast([Заем выдан] as date) = @date_past


	drop table if exists #srchek

	select * into #srchek from #srchek_today
	union 
	select * from #srchek_past
	union 
	select * from #srchek_today_total
	union 
	select * from #srchek_past_total


	drop table if exists #srchek_delta_today

	select Показатель, 
		[Вид займа],
		СрЧек,
		[Дата текст]
	into #srchek_delta_today 
	from #srchek
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #srchek_delta_past

	select Показатель, 
		[Вид займа],
		СрЧек,
		[Дата текст]
	into #srchek_delta_past
	from #srchek
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #srchek_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.СрЧек - ddp.СрЧек 'СрЧек', 
		'Дельта'  'Дата текст'
	into #srchek_delta
	from #srchek_delta_today ddt
		join #srchek_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа] 


	drop table if exists #srchek_itog

	select * into #srchek_itog from #srchek
	union 
	select * from #srchek_delta

--ДАННЫЕ ПО КД С ПРЕДЫДУЩИХ ДНЕЙ


	drop table if exists #kdpr_today

	select  'КД с предыдущих дней' Показатель,
		[Вид займа],  
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kdpr_today
	from #fa
	where cast([Контроль данных] as date) = @date 
		and cast([Верификация КЦ] as date) != @date
	group by  [Вид займа]


	drop table if exists #kdpr_past

	select  'КД с предыдущих дней' Показатель,
		[Вид займа], 
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kdpr_past
	from #fa
	where  cast([Контроль данных] as date) = @date_past 
		and cast([Верификация КЦ] as date) != @date_past
	group by  [Вид займа]


	drop table if exists #kdpr_today_total

	select  'КД с предыдущих дней' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакКонтрольДанных)  'КД', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #kdpr_today_total
	from #fa
	where  cast([Контроль данных] as date) = @date
		and cast([Верификация КЦ] as date) != @date


	drop table if exists #kdpr_past_total

	select  'КД с предыдущих дней' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакКонтрольДанных) 'КД', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #kdpr_past_total
	from #fa
	where  cast([Контроль данных] as date) = @date_past 
		and cast([Верификация КЦ] as date) != @date_past


	drop table if exists #kdpr

	select * into #kdpr from #kdpr_today
	union 
	select * from #kdpr_past
	union 
	select * from #kdpr_today_total
	union 
	select * from #kdpr_past_total


	drop table if exists #kdpr_delta_today

	select Показатель, 
		[Вид займа],
		k.КД,
		[Дата текст]
	into #kdpr_delta_today 
	from #kdpr k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #kdpr_delta_past

	select Показатель, 
		[Вид займа],
		k.КД,
		[Дата текст]
	into #kdpr_delta_past
	from #kdpr k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #kdpr_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.КД - ddp.КД 'Доезд', 
		'Дельта'  'Дата текст'
	into #kdpr_delta
	from #kdpr_delta_today ddt
		join #kdpr_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа]


	drop table if exists #kdpr_itog

	select * into #kdpr_itog from #kdpr
	union 
	select * from #kdpr_delta

--ДАННЫЕ ПО ОДОБРЕНО С ПРЕДЫДУЩИХ ДНЕЙ


	drop table if exists #odobrpr_today

	select  'Одобрено с предыдущих дней' Показатель,
		[Вид займа],  
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #odobrpr_today
	from #fa
	where cast([Одобрено] as date) = @date 
		and cast([Верификация КЦ] as date) != @date
	group by  [Вид займа]


	drop table if exists #odobrpr_past

	select  'Одобрено с предыдущих дней' Показатель,
		[Вид займа], 
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #odobrpr_past
	from #fa
	where  cast([Одобрено] as date) = @date_past 
		and cast([Верификация КЦ] as date) != @date_past
	group by  [Вид займа]


	drop table if exists #odobrpr_today_total

	select  'Одобрено с предыдущих дней' Показатель,
		'Итого' 'Вид займа',  
		sum(ПризнакОдобрено)  'Одобрено', 
		format(@date,'yyyy-MM-dd')  'Дата текст'
	into #odobrpr_today_total
	from #fa
	where  cast([Одобрено] as date) = @date 
		and cast([Верификация КЦ] as date) != @date


	drop table if exists #odobrpr_past_total

	select  'Одобрено с предыдущих дней' Показатель,
		'Итого' 'Вид займа', 
		sum(ПризнакОдобрено) 'Одобрено', 
		format(@date_past,'yyyy-MM-dd')  'Дата текст'
	into #odobrpr_past_total
	from #fa
	where  cast([Одобрено] as date) = @date_past 
		and cast([Верификация КЦ] as date) != @date_past


	drop table if exists #odobrpr

	select * into #odobrpr from #odobrpr_today
	union 
	select * from #odobrpr_past
	union 
	select * from #odobrpr_today_total
	union 
	select * from #odobrpr_past_total


	drop table if exists #odobrpr_delta_today

	select Показатель, 
		[Вид займа],
		k.Одобрено,
		[Дата текст]
	into #odobrpr_delta_today 
	from #odobrpr k
	where [Дата текст] = format(@date,'yyyy-MM-dd')


	drop table if exists #odobrpr_delta_past

	select Показатель, 
		[Вид займа],
		k.Одобрено,
		[Дата текст]
	into #odobrpr_delta_past
	from #odobrpr k
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')


	drop table if exists #odobrpr_delta

	select ddt.Показатель, 
		ddt.[Вид займа], 
		ddt.Одобрено - ddp.Одобрено 'Доезд', 
		'Дельта'  'Дата текст'
	into #odobrpr_delta
	from #odobrpr_delta_today ddt
		join #odobrpr_delta_past ddp on ddt.[Вид займа] = ddp.[Вид займа]

	drop table if exists #odobrpr_itog

	select * into #odobrpr_itog from #odobrpr
	union 
	select * from #odobrpr_delta

--ПОТЕРИ

declare @chek as int
set  @chek = (select sum([Выданная сумма])/sum([ПризнакЗайм])  from #fa where format( [Заем выдан], 'yyyy-MM-01') = format(@date, 'yyyy-MM-01'))

declare @conversion as float
set @conversion = iif((cast((select sum([ПризнакЗайм]) from #fa where [Заем выдан] = @date) as float)/ cast((select sum([ПризнакЗаявка]) from #fa where [Верификация КЦ] = @date)as float)) > (cast((select sum([ПризнакЗайм]) from #fa where [Заем выдан] = @date_past) as float)/ cast((select sum([ПризнакЗаявка]) from #fa where [Верификация КЦ] = @date_past)as float)),
	(cast((select sum([ПризнакЗайм]) from #fa where [Заем выдан] = @date) as float)/ cast((select sum([ПризнакЗаявка]) from #fa where [Верификация КЦ] = @date)as float)),
	(cast((select sum([ПризнакЗайм]) from #fa where [Заем выдан] = @date_past) as float)/ cast((select sum([ПризнакЗаявка]) from #fa where [Верификация КЦ] = @date_past)as float)))

declare @predodobr as float
set @predodobr = ( iif( (select cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float) from #fa where cast([Верификация КЦ] as date) = @date) > (select cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float) from #fa where cast([Верификация КЦ] as date) = @date_past),
	(select cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float) from #fa where cast([Верификация КЦ] as date) = @date) ,
	(select cast(sum(ПризнакПредварительноеОдобрение) as float)/cast(sum(ПризнакЗаявка) as float) from #fa where cast([Верификация КЦ] as date) = @date_past) 
	))

declare @predodobr_kd as float
set @predodobr_kd = ( iif( (select cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) from #fa where cast([Верификация КЦ] as date) = @date) > (select cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) from #fa where cast([Верификация КЦ] as date) = @date_past),
	(select cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) from #fa where cast([Верификация КЦ] as date) = @date) ,
	(select cast(sum(ПризнакКонтрольДанных) as float)/cast(sum(ПризнакПредварительноеОдобрение) as float) from #fa where cast([Верификация КЦ] as date) = @date_past) 
	))

declare @kd_odobr as float
set @kd_odobr = ( iif( (select cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) from #fa where cast([Верификация КЦ] as date) = @date) > (select cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) from #fa where cast([Верификация КЦ] as date) = @date_past),
	(select cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) from #fa where cast([Верификация КЦ] as date) = @date) ,
	(select cast(sum(ПризнакОдобрено) as float)/cast(sum(ПризнакКонтрольДанных) as float) from #fa where cast([Верификация КЦ] as date) = @date_past) 
	))

declare @tu as float
set @tu = ( iif( (select cast(sum(ПризнакЗайм) as float)/cast(sum(ПризнакОдобрено) as float) from #fa where cast([Верификация КЦ] as date) = @date) > (select cast(sum(ПризнакЗайм) as float)/cast(sum(ПризнакОдобрено) as float) from #fa where cast([Верификация КЦ] as date) = @date_past),
	(select cast(sum(ПризнакЗайм) as float)/cast(sum(ПризнакОдобрено) as float) from #fa where cast([Верификация КЦ] as date) = @date) ,
	(select cast(sum(ПризнакЗайм) as float)/cast(sum(ПризнакОдобрено) as float) from #fa where cast([Верификация КЦ] as date) = @date_past) 
	))


drop table if exists #poteri

 select 1 'Номер',
	'%Предодобрения' 'Показатель',
	'Итого' 'Вид', 
	iif((@predodobr * (select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date) - (select sum([ПризнакПредварительноеОдобрение]) from #fa where cast([Верификация КЦ] as date) = @date)) * @predodobr_kd * @kd_odobr * @tu * @chek < 0,0,
	(@predodobr * (select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date) - (select sum([ПризнакПредварительноеОдобрение]) from #fa where cast([Верификация КЦ] as date) = @date)) * @predodobr_kd * @kd_odobr * @tu * @chek)	'Потерянные ПрОд' 
	into #poteri
union 
 select 2 'Номер', 
	'Доезд%' 'Показатель',
	'Итого' 'Вид',
	iif(((select sum([ПризнакПредварительноеОдобрение]) from #fa where cast([Верификация КЦ] as date) = @date) * @predodobr_kd - (select sum([ПризнакКонтрольДанных]) from #fa where cast([Верификация КЦ] as date) = @date)) * @kd_odobr * @tu * @chek <0,0,
	((select sum([ПризнакПредварительноеОдобрение]) from #fa where cast([Верификация КЦ] as date) = @date) * @predodobr_kd - (select sum([ПризнакКонтрольДанных]) from #fa where cast([Верификация КЦ] as date) = @date)) * @kd_odobr * @tu * @chek)	'Потерянные Доезд'
 union 
 select 6 'Номер',
	'КД_Одобрено%' 'Показатель',
	'Итого' 'Вид',
	iif(((select sum([ПризнакКонтрольДанных]) from #fa where cast([Верификация КЦ] as date) = @date) * @kd_odobr - (select sum([ПризнакОдобрено]) from #fa where cast([Верификация КЦ] as date) = @date)) * @tu * @chek <0,0,
	((select sum([ПризнакКонтрольДанных]) from #fa where cast([Верификация КЦ] as date) = @date) * @kd_odobr - (select sum([ПризнакОдобрено]) from #fa where cast([Верификация КЦ] as date) = @date)) * @tu * @chek)	'Потерянные КД-Одобрено'
 union 
 select 9 'Номер', 
	'tu%' 'Показатель',
	'Итого' 'Вид',
	iif((select sum([ПризнакОдобрено]) from #fa where cast(Одобрено as date) = @date) * @tu - (select sum([ПризнакЗайм]) from #fa where cast(Одобрено as date) = @date and cast([Заем выдан] as date) = @date) * @chek > 0,0,
	(select sum([ПризнакОдобрено]) from #fa where cast(Одобрено as date) = @date) * @tu - (select sum([ПризнакЗайм]) from #fa where cast(Одобрено as date) = @date and cast([Заем выдан] as date) = @date) * @chek*(-1))	'Потерянные TU'
 union
 select 4 'Номер',
	'КД с предыдущих дней шт' 'Показатель',
	'Итого' 'Вид',
	iif(((select КД from #kdpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select КД from #kdpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd'))) < 0, 
	((select КД from #kdpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select КД from #kdpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd'))) * @kd_odobr * @tu * @chek *(-1),0) 'Потерянные КД с предыдуших дней'
 union 
 select 8 'Номер',
	'Одобрено с предыдущих дней шт' 'Показатель',
	'Итого' 'Вид',
	iif(((select Одобрено from #odobrpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select Одобрено from #odobrpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd'))) < 0, ((select Одобрено from #odobrpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select Одобрено from #odobrpr_itog where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd'))) * @kd_odobr * @tu * @chek *(-1) ,0) 'Потерянные Одобренные с предыдуших дней'
union
 select 12 'Номер',
	'СрЧек руб.' 'Показатель',
	'Итого' 'Вид',
	iif(((select t.СрЧек from #srchek_itog t where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select t.СрЧек from #srchek_itog t where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd'))) >0,0,
	((select t.СрЧек from #srchek_itog t where [Вид займа] = 'Итого' and [Дата текст] = format(@date,'yyyy-MM-dd')) - (select t.СрЧек from #srchek_itog t where [Вид займа] = 'Итого' and [Дата текст] = format(@date_past,'yyyy-MM-dd')))*(-1) * (select sum(ПризнакЗайм) from #fa where cast([Заем выдан] as date) = @date)
	)
	

-- ДЛЯ ТАБЛИЦЫ С ЗАЯВКАМИ

	drop table if exists #z_today

	select  [Место cоздания],
		[Вид займа],  
		sum(ПризнакЗаявка) 'Заявок', 
		@date Дата
	into #z_today
	from #fa
	where cast([Верификация КЦ] as date) = @date
	group by  [Место cоздания],
		[Вид займа]


	drop table if exists #z_past

	select  [Место cоздания], 
		[Вид займа],  
		sum(ПризнакЗаявка) 'Заявок', 
		@date_past Дата
	into #z_past
	from #fa
	where cast([Верификация КЦ] as date) = @date_past
	group by  [Место cоздания], 
		[Вид займа]


	drop table if exists #itog_z

	select [Место cоздания], [Вид займа],Заявок , format(@date,'yyyy-MM-dd') 'Дата текст' into #itog_z from #z_today
	union 
	select [Место cоздания], [Вид займа],Заявок ,format(@date_past,'yyyy-MM-dd') 'Дата текст' from #z_past
	union 
	select  [Место cоздания], 'Итого', sum(ПризнакЗаявка) 'Заявок', format(@date,'yyyy-MM-dd') 'Дата текст'
		from #fa
		where  cast([Верификация КЦ] as date) = @date
		group by  [Место cоздания]
	union 
	select  [Место cоздания], 'Итого', sum(ПризнакЗаявка) 'Заявок', format(@date_past,'yyyy-MM-dd') 'Дата текст' 
		from #fa
		where cast([Верификация КЦ] as date) = @date_past 
		group by  [Место cоздания]


	drop table if exists #dz_today

	select [Место cоздания], 
		[Вид займа], 
		sum(Заявок)'Заявок', 
		'Дельта' 'Дата текст' 
	into #dz_today
	from #itog_z
	where [Дата текст] = format(@date,'yyyy-MM-dd')
	group by [Место cоздания], [Вид займа]
	

	drop table if exists #dz_past

	select [Место cоздания], 
		[Вид займа], 
		sum(Заявок)'Заявок', 
		'Дельта' 'Дата текст' 
	into #dz_past
	from #itog_z
	where [Дата текст] = format(@date_past,'yyyy-MM-dd')
	group by [Место cоздания], [Вид займа]
	

	drop table if exists #z_itog

	select dt.[Место cоздания], 
		dt.[Вид займа], 
		iif(sum(dp.Заявок) is null,sum(dt.Заявок),sum(dt.Заявок) - sum(dp.Заявок)) 'Заявок', 
		'Дельта' 'Дата текст' 
	into #z_itog
	from #dz_today dt
		left join #dz_past dp on dt.[Вид займа] = dp.[Вид займа] and dt.[Место cоздания] = dp.[Место cоздания] 
	group by dt.[Место cоздания], 
		dt.[Вид займа]
	union 
	select [Место cоздания], 
		[Вид займа], 
		isnull(Заявок,0),
		[Дата текст] 
	from #itog_z 


--ИТОГОВАЯ ТАБЛИЦА--

drop table if exists #itog_table

select 1 'Номер', t.Показатель, t.[Вид займа], t.[Текущая дата]*100 'Значение', t.[Дата текст] 
into #itog_table
from #pd_itog t 
union 
select 2 'Номер', t.Показатель + '%', t.[Вид займа], t.Доезд*100 'Значение', t.[Дата текст] from #Doezd_itog t 
union
select 6 'Номер',t.Показатель + '%', t.[Вид займа], t.КД_Одобрено, t.[Дата текст] from #kd_odobr_itog t where t.[Вид займа] = 'Итого'
union
select 9 'Номер',t.Показатель + '%', t.[Вид займа],t.tu *100,t.[Дата текст] from #tu_itog t where t.[Вид займа] = 'Итого'
union 
select 3 'Номер', t.Показатель + ' шт', t.[Вид займа],t.КД,t.[Дата текст]  from #kd_itog t
union
select 5 'Номер', t.Показатель + '%', t.[Вид займа], t.AR*100, t.[Дата текст] from #ar_itog t
union
select 7 'Номер',t.Показатель + ' шт', t.[Вид займа], t.Одобрено, t.[Дата текст] from #odobr_itog t where t.[Вид займа] = 'Итого'
union
select 10 'Номер',t.Показатель + ' шт', t.[Вид займа],t.Займов, t.[Дата текст] from #zaim_itog t where t.[Вид займа] = 'Итого'
union
select 11 'Номер',t.Показатель + ' шт', t.[Вид займа],t.Займов, t.[Дата текст] from #zaimpr_itog t where t.[Вид займа] = 'Итого'
union
select 12 'Номер',t.Показатель + ' руб.', t.[Вид займа],t.СрЧек, t.[Дата текст] from #srchek_itog t where t.[Вид займа] = 'Итого'
union
select 4 'Номер',t.Показатель+ ' шт', t.[Вид займа], t.КД, t.[Дата текст] from #kdpr_itog t where t.[Вид займа] = 'Итого'
union
select 8 'Номер',t.Показатель + ' шт', t.[Вид займа],t.Одобрено, t.[Дата текст] from #odobrpr_itog t where t.[Вид займа] = 'Итого'
union 
select p.Номер, p.Показатель, p.Вид, p.[Потерянные ПрОд], 'Потери'  from #poteri p
union
select 13 'Номер',* from #z_itog
union
select 14 'Номер', 'Потери' Показатель, 'Итого' 'Вид займа', iif(((select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date) - (select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date_past)) > 0,0, 
((select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date) - (select sum(ПризнакЗаявка) from #fa where cast([Верификация КЦ] as date) = @date_past)) * @conversion * (-1)*(select sum([Выданная сумма])/sum([ПризнакЗайм]) from #fa where month(cast([Заем выдан] as date))= month(@date) and year(cast([Заем выдан] as date))= year(@date))) 'Значение', 'Потери заявки' 'Дата текст'
union 
select 15 'Номер', 'Потери' Показатель, 'Итого' 'Вид займа', sum([Выданная сумма]), 'Выдачи' 'Дата текст' from #fa where cast([Заем выдан] as date) = @date 


begin tran

delete from Analytics.[dbo].[Отчет по потерям] 
insert into Analytics.[dbo].[Отчет по потерям] 
select * from #itog_table

commit tran

end 