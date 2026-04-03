CREATE PROCEDURE [dbo].[sale_rating_call] as 

BEGIN 
	
	DECLARE @date_from AS DATE = getdate()-4
	DECLARE @date_to AS DATE = getdate()

	 drop table if exists #oper
 
	
		 select replace(title,'Убушаева  Наталья Владимировна','Убушаева Наталья Владимировна') oper,
			'CM\' + login login,
			Направление,
			РГ
					into #oper
		from  [NaumenDbReport].dbo.mv_employee e
			join analytics.dbo.employee s on replace(e.title,'Убушаева  Наталья Владимировна','Убушаева Наталья Владимировна') = s.Сотрудник
		order by title


	-- Подготовка таблицы Время работы операторов

	--	drop table if exists Analytics.dbo.[Отчет по тематикам Время работы]

		drop table if exists #VZ

			SELECT cast(leaved as date) Дата, 
				oper Оператор, 
				convert(nvarchar(8),max(leaved),114) Время_завершения
			into #VZ
			FROM [NaumenDbReport].[dbo].[status_changes] s
				join #oper p on 'CM\'+ s.LOGIN=p.Login
			where  ENTERED between @date_from and @date_to
				and status !='offline'
			group by p.oper,
				cast(leaved as date)
			order by Дата

				drop table if exists #vremya

			SELECT cast(entered as date) Дата, 
				case 
					when cast(entered as date) = cast(dateadd(d,-1,getdate()) as date) then 'Вчера'
					else cast(entered as varchar(10))
				end 'Дата текст',
				p.oper Оператор, 
				p.Направление,
				p.РГ,
				convert(nvarchar(8),min(ENTERED),114) Время_начала,
				Время_завершения,
				ld.Перерыв Перерыв,
				ld.Готов Готов,
				ld.Постобработка Постобработка,
				ld.[Время диалога] ВремяДиалога,
				ld.[Звонит] Звонит,
				ld.[Онлайн] Онлайн
			-- INTO Analytics.dbo.[Отчет по тематикам Время работы]
			into #vremya
			FROM [NaumenDbReport].[dbo].[status_changes] s
				join #oper  p on 'CM\'+ s.LOGIN=p.Login
				join #VZ t on t.Дата = cast(s.entered as date)  and t.Оператор = p.oper
				join [Analytics].[dbo].[report_naumen_activity_by_login_day] ld on ld.d = cast(entered as date) and ld.title = p.oper
			where ENTERED  between @date_from and @date_to
				and status='online'
			group by p.oper,
				cast(entered as date),
				case 
					when cast(entered as date) = cast(dateadd(d,-1,getdate()) as date) then 'Вчера'
					else cast(entered as varchar(10))
				end ,
				Время_завершения,
				p.Направление,
				p.РГ,
				ld.Перерыв,
				ld.Готов,
				ld.Постобработка,
				ld.[Время диалога],
				ld.[Звонит],
				ld.[Онлайн] 
			order by 1


	-- Подготовка таблицы тематики 1С

	--	drop table if exists Analytics.dbo.[Отчет по тематикам Детализация 1С]

			drop table if exists #pred

			select		
				dateadd(year,-2000,kc.ВремяНачала) as ВремяНачала,
				dateadd(year,-2000,kc.ВремяЗавершения) as ВремяЗавершения,
				kc.Время,
				per.Наименование as Перерыв,
				oz.Имя as Статус,
				o.oper,
				o.РГ,
				o.Направление,
				kc.Телефон,
				ISNULL(z.session_id,z1.Session_id) as session_id,
				ISNULL(ts.Наименование, t.Наименование) as Тематика
			into #pred
			from
				Stg._1cCRM.РегистрСведений_УчетВремениКЦ kc (nolock)	
				inner join Stg._1cCRM.Справочник_Пользователи p (nolock) on kc.Оператор = p.Ссылка
				inner join #oper o on o.login = p.adLogin
				inner join Stg._1cCRM.Перечисление_ОписанияЗатраченногоВремениОперацтораКЦ oz (nolock) on oz.Ссылка = kc.Описание
				left join Stg.[_1cCRM].[Справочник_ПричиныПерерывовОператоровКЦ] per (nolock) on per.Ссылка = kc.ЦельПерерыва
				left join Stg.[_1cCRM].[Документ_ТелефонныйЗвонок] z (nolock) on z.Автор = kc.Оператор
					and kc.ВремяНачала between dateadd(ss,-1,z.Дата) and dateadd(ss,z.сфпДлительностьЗвонка,z.Дата) 
				left join Stg.[_1cCRM].[Документ_CRM_Взаимодействие] v (nolock) on v.Ссылка = z.ВзаимодействиеОснование_Ссылка
				left join Stg.[_1cCRM].[Справочник_ТемыОбращений] ts (nolock) on ts.Ссылка = v.ТемаСсылка
				left join Stg.[_1cCRM].[Документ_CRM_Взаимодействие] vp (nolock) on vp.Ссылка = kc.Взаимодействие
				left join Stg.[_1cCRM].[Документ_ТелефонныйЗвонок] z1 (nolock) on z1.ВзаимодействиеОснование_Ссылка = vp.Ссылка
				left join Stg.[_1cCRM].[Справочник_ТемыОбращений] t (nolock) on t.Ссылка = vp.ТемаСсылка
			where
				cast(dateadd(year,-2000,kc.ВремяНачала) as date) between @date_from and cast(dateadd(d,-1,@date_to) as date)
			order by
				kc.ВремяНачала


			--подтягиваем потерянные хвосты 
			drop table if exists #pred1
			select	
				p.ВремяНачала,
				p.ВремяЗавершения,
				p.Время,
				p.Перерыв,
				p.Статус,
				p.oper,
				p.РГ,
				p.Направление,
				p.Телефон,
				ISNULL(p.Session_id,p1.Session_id) as Session_id,
				ISNULL(p.Тематика,p1.Тематика) as Тематика
			into #pred1
			from
				#pred p
				left join #pred p1 on p.oper = p1.oper
					and p.ВремяЗавершения = p1.ВремяНачала
					and (p1.Статус = 'Разговор' or p1.Статус = 'Вызов')
			where
				p.Статус in ('Разговор','Вызов')
				and p.session_id is NULL
			order by
				p.ВремяНачала

			drop table if exists #pred2
			select
				p.ВремяНачала,
				p.ВремяЗавершения,
				p.Время,
				p.Перерыв,
				p.Статус,
				p.oper,
				p.РГ,
				p.Направление,
				p.Телефон,
				ISNULL(p.Session_id,p1.Session_id) as Session_id,
				ISNULL(p.Тематика,p1.Тематика) as Тематика
			into #pred2
			from
				#pred1 p
				left join #pred1 p1 on p.oper = p1.oper
					and p.ВремяЗавершения = p1.ВремяНачала
			where
				p.Session_id is NULL
			order by
				p.ВремяНачала

			drop table if exists #pred3
			select
				p.ВремяНачала,
				p.ВремяЗавершения,
				p.Время,
				p.Перерыв,
				p.Статус,
				p.oper,
				p.РГ,
				p.Направление,
				p.Телефон,
				ISNULL(p.Session_id,p1.Session_id) as Session_id,
				ISNULL(p.Тематика,p1.Тематика) as Тематика
			into #pred3
			from
				#pred2 p
				left join #pred p1 on p.oper = p1.oper
					and dateadd(ss,1,p.ВремяЗавершения) = p1.ВремяНачала
			where
				p.Session_id is NULL
			-- игнорируем огрызки по которым не нашли звонка для статы по операторам
			drop table if exists #raz

			select
				*
			into #raz
			from
				(select
					*
				from
					#pred p
				where
					p.Статус in ('Разговор','Вызов')
					and p.session_id is not NULL
				union all
				select
					*
				from
					#pred1 p1
				where
					p1.session_id is not NULL
				union all
				select
					*
				from
					#pred2 p2
				where
					p2.session_id is not NULL
				union all
				select
					*
				from
					#pred3 p3)d
			where 
				d.session_id is not NULL

			drop table if exists #final
			select
				ВремяНачала,
				ВремяЗавершения,
				Время,
				Перерыв,
				IIF(Статус in ('Вызов','Разговор'),'Разговор',Статус) as Статус,
				oper,
				РГ,
				Направление,
				Телефон,
				max(Session_id) as Session_id,
				Тематика
			into #final
			from	
				(select
					p.ВремяНачала,
					p.ВремяЗавершения,
					p.Время,
					p.Перерыв,
					p.Статус,
					p.oper,
					p.РГ,
					p.Направление,
					p.Телефон,
					IIF(p.Статус!='ПостОбработка',NULL,p.session_id) as Session_id,
					IIF(p.Статус!='ПостОбработка',NULL,p.Тематика) as Тематика
				from
					#pred p
				where
					p.Статус not in ('Разговор','Вызов')
				union all
					select
						*
					from
						#raz r)d
			group by
				ВремяНачала,
				ВремяЗавершения,
				Время,
				Перерыв,
				Статус,
				oper,
				РГ,
				Направление,
				Телефон,
				Тематика
			order by
				ВремяНачала

			drop table if exists #raz5
			select
				cast(f.ВремяНачала as date) as Дата,
				f.oper,	
				f.РГ,
				f.Направление,
				f.Статус,
				ISNULL(f.тематика,'без тематики') as Тематика,
				f.session_id,
				sum(f.Время) as Время
			into #raz5
			from
				#final f
				inner join (
					select
						session_id,
						sum(Время) as [Длительность всего]
					from
						#final
					where
						Статус = 'Разговор'
					group by
						session_id
					having 
						sum(Время)<=5
				)r5 on f.session_id = r5.session_id		
			where
				f.Статус = 'ПостОбработка'
			group by
				cast(f.ВремяНачала as date),
				f.oper,
				f.РГ,
				f.Направление,
				f.Статус,
				ISNULL(f.тематика,'без тематики'),
				f.session_id

drop table if exists #itog

			select
				distinct s.*
				--c.Штуки
			INTO #itog
			from 
				(select
					cast(ВремяНачала as date) as Дата,
					oper,
					РГ,
					Направление,
					Статус,
					case
						when Статус='Перерыв' then ISNULL(Перерыв,'без статуса')
						when Статус in ('Offline','Ожидание') then ''
						else ISNULL(тематика,'без тематики')
					end as Тематика,
					sum(Время)/3600.00/24.00 as Время
				from
					#final
				group by
					cast(ВремяНачала as date),
					oper,	
					РГ,
					Направление,
					Статус,
					case
						when Статус='Перерыв' then ISNULL(Перерыв,'без статуса')
						when Статус in ('Offline','Ожидание') then ''
						else ISNULL(тематика,'без тематики')
					end
				having sum(Время)/3600.00/24.00>=0)s
				left join
				(select
					cast(ВремяНачала as date) as Дата,
					oper,	
					РГ,
					Направление,
					Статус,
					case
						when Статус='Перерыв' then ISNULL(Перерыв,'без статуса')
						when Статус in ('Offline','Ожидание') then ''
						else ISNULL(тематика,'без тематики')
					end as Тематика,
					count(distinct(session_id)) as Штуки
				from
					#final
				group by
					cast(ВремяНачала as date),
					oper,	
					РГ,
					Направление,
					Статус,
					case
						when Статус='Перерыв' then ISNULL(Перерыв,'без статуса')
						when Статус in ('Offline','Ожидание') then ''
						else ISNULL(тематика,'без тематики')
					end)c on s.Дата = c.Дата
						and s.Статус = c.Статус
						and s.Тематика = c.Тематика
	
			union all		
			select
				Дата,
				oper,
				РГ,
					Направление,
				'ПостОбработка разговоров до 5 сек' as Статус,
				Тематика,
				sum(Время)/3600.00/24.00 as Время
				--count(distinct(session_id))as Штуки
			from
				#raz5
			group by
				Дата,
				oper,
				РГ,
					Направление,
				Статус,
				Тематика

drop table if exists #1c

select *,
	case 
					when cast(Дата as date) = cast(dateadd(d,-1,getdate()) as date) then 'Вчера'
					else cast(Дата as varchar(10))
				end 'Дата текст'
--into Analytics.dbo.[Отчет по тематикам Детализация 1С]
into #1c
from #itog where Время >=0

	-- Подготовка таблицы детализация перерывов
	
--	drop table if exists Analytics.dbo.[Отчет по тематикам Перерыв]
drop table if exists #pereryv

			SELECT cast(entered as date) Дата, 
				case 
					when cast(entered as date) = cast(dateadd(d,-1,getdate()) as date) then 'Вчера'
					else cast(entered as varchar(10))
				end 'Дата текст',
				p.oper,
				p.РГ,
				p.Направление,
				case 
					when REASON = 'Технический перерыв (ТПРВ)' then 'Прочее'
					when REASON = 'Доп. Работа (ДРТ)' then 'Доп. Работа'
					when REASON = 'Другое (ДР)' then 'Прочее'
					when REASON = 'Обед (ОБД)' then 'Обед'
					when REASON = 'Перерыв (ПРВ)' then 'Перерыв'
					when REASON = 'Тренинг (ТРН)' then 'Тренинг'
					when REASON = 'CustomAwayReason1' then 'Прочее'
					when REASON = 'CustomAwayReason2' then 'Прочее'
					when REASON = 'CustomAwayReason3' then 'Прочее'
					when REASON = 'CustomAwayReason4' then 'Прочее'
					when REASON = 'CustomAwayReason5' then 'Прочее'
					when REASON IS NULL then 'Прочее'
					when REASON = 'ComputerLocked' then 'Прочее'
					when REASON = 'initializing' then 'Прочее'
					when REASON = 'PrepareToWork' then 'Прочее'
					when REASON = '' then ''
					else REASON
				end ПричинаПерерыва,
				DURATION
		--	INTO Analytics.dbo.[Отчет по тематикам Перерыв]
		INTO #pereryv
			FROM [NaumenDbReport].[dbo].[status_changes] s
				join #oper p on 'CM\' + s.LOGIN=p.login
			where ENTERED between @date_from and @date_to
				and STATUS = 'away' 
			order by Дата

	-- Подготовка таблицы детализация Fedor

--	drop table if exists Analytics.dbo.[Отчет по тематикам Детализация Fedor]

	 	drop table if exists #tem
  
  SELECT NaumenCallId, Name
  into #tem
   FROM  [Stg].[_fedor].[core_LeadCommunicationCall] clc 
   join [Stg].[_fedor].[core_LeadCommunication] cl on cl.Id=clc.Id
  join [Stg].[_fedor].[dictionary_LeadCommunicationResult] dr on cl.IdLeadCommunicationResult = dr.Id
 where CreatedOn between @date_from and @date_to
 
 drop table if exists #fedor

SELECT convert(varchar(10),attempt_start,104) Дата,
case 
					when cast(attempt_start as date) = cast(dateadd(d,-1,getdate()) as date) then 'Вчера'
					else  cast(attempt_start as varchar(10))
				end 'Дата текст',
	oper,
	РГ,
	o.Направление,
	speaking_time speaking_time,
	wrapup_time wrapup_time,
	replace(calldispositiontitle,'Обрыв связи','Обрыв звонка' ) calldispositiontitle
	,dos.session_id
	,iif(calldispositiontitle = 'Консультация',ТипОбращения,'') ТипОбращения
	,tem.Name Тематика
into  #fedor
  FROM [NaumenDbReport].[dbo].[detail_outbound_sessions] dos (nolock)
	 join [NaumenDbReport].[dbo].[mv_phone_call] mpc (nolock) on dos.session_id = mpc.sessionid
	 join #oper o on o.login = 'CM\' + dos.Login
	 left join  [Reports].[dbo].[dm_Все_коммуникации_На_основе_отчета_из_crm] n on n.Session_id= dos.session_id 
	 left join #tem tem on tem.NaumenCallId=dos.session_id  collate SQL_Latin1_General_CP1_CI_AS
  where attempt_start between '20220901' and @date_to
  order by attempt_start

   drop table if exists #fedor2

  select *,
	case 
		when (Тематика  is null  and calldispositiontitle  collate SQL_Latin1_General_CP1_CI_AS is null)  then 'Ручной обзвон'
		when Тематика  is null then calldispositiontitle  collate SQL_Latin1_General_CP1_CI_AS
		else Тематика 
	end ТематикаИтог
	into #fedor2
  from #fedor

   drop table if exists #fedor3

  select Дата,
	[Дата текст]
	,oper
	,РГ
	,Направление
	,speaking_time
	,wrapup_time
	,ТематикаИтог
	,case
		when ТематикаИтог = 'Консультация' then ТипОбращения
		when ТипОбращения = '' then ''
		else ''
	end ТипОбращенияИтог 
--	into Analytics.dbo.[Отчет по тематикам Детализация Fedor]
into #fedor3
  from #fedor2
  order by Дата

 -- exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob 'AD256032-749B-4828-8F4C-E82C512A2C5E'

 begin tran


delete from Analytics.dbo.[Отчет по тематикам Детализация Fedor] --where Дата >= @date_from
insert into Analytics.dbo.[Отчет по тематикам Детализация Fedor]
select * 
from #fedor3

delete from Analytics.dbo.[Отчет по тематикам Перерыв] where Дата >= @date_from
insert into Analytics.dbo.[Отчет по тематикам Перерыв]
select * 
from #pereryv

delete from Analytics.dbo.[Отчет по тематикам Детализация 1С] where Дата >= @date_from
insert into Analytics.dbo.[Отчет по тематикам Детализация 1С]
select * 
from #1c

commit tran

delete from Analytics.dbo.[Отчет по тематикам Время работы] where Дата >= @date_from
insert into Analytics.dbo.[Отчет по тематикам Время работы]
select * 
from #vremya



END