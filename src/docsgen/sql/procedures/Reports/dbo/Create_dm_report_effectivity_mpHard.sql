

--exec dbo.[Create_dm_report_effectivity_mpHard] null, null
--exec dbo.[Create_dm_report_effectivity_mpHard] '2021-08-17', '2021-08-22'
CREATE procedure [dbo].[Create_dm_report_effectivity_mpHard]
--declare
@from date = null --'2021-08-01'
,@to date = null
as
begin
declare @dtFrom date = dateadd(day, 0, cast(getdate() as date))	
		, @dtTo date = dateadd(day, 0, cast(getdate() as date))	

if @from is null
begin
	set @from = @dtFrom
end

if @to is null
begin
	set @to = @dtTo
end

set @to = dateadd(day, 1, @to )

drop table if exists #success
select [Name]  
into #success
from stg._Collection.CommunicationResult where IsSuccessResult = 1


--select cast(format(getdate() ,'yyyy-MM-01') as date)
drop table if exists #tmp
;
WITH cr AS (
        select * from [Stg].[_MPHARD].contact_result 
		--where contact_date >= cast(format(getdate() ,'yyyy-MM-01') as date)  AND contact_date < cast(getdate() as date)
		WHERE dateadd(hour,3,contact_date) >= @from AND dateadd(hour,3,contact_date) < @to
		)
select
       u.login,
       (select isnull(count(cua.user_id),0) from [Stg].[_MPHARD].client c
           JOIN (select incua.target_id, incua.user_id from [Stg].[_MPHARD].client_user_assignment incua group by incua.target_id, incua.user_id) cua ON cua.target_id = c.id
           where exists(select 1 from [Stg].[_MPHARD].debt d where d.client_id = c.id) AND cua.user_id = u.id
       GROUP BY cua.user_id) as Нагрузка_клиентов,

       (select count(*) from cr in_pcr
            where in_pcr.author = u.id AND
                  ((select top 1 count(*) from [Stg].[_MPHARD].address_type where name = in_pcr.contact_type )
                       + (select top 1 count(*) from [Stg].[_MPHARD].address add1 where add1.address_string = in_pcr.phone_or_address ))  > 0
       ) as Выездов,

	   (select cast(count(*) as float) from cr in_pcr
            where in_pcr.author = u.id
		)	  as Всего,

       cast(0 as float) as [% Выездов],
       (select count(*) from cr in_pcr
            where in_pcr.author = u.id AND
                  ((select top 1 count(*) from [Stg].[_MPHARD].phone_type where name = in_pcr.contact_type ))  > 0
       ) as Звонков,
       cast(0 as float)as [% Звонков],
       (select count(*) from cr in_pcr
            where in_pcr.author = u.id AND
                  ((select top 1  count(*) from [Stg].[_MPHARD].other_contact_type where name = in_pcr.contact_type ))  > 0
       ) as Другие_контакты,
       cast(0 as float)as [% Другие_контакты],
       (select count(*) from cr in_pcr where in_pcr.author = u.id
           AND in_pcr.communication_result IN ('Залог обнаружен')
       ) as [Авто найдено],
       (select count(*) from cr in_pcr where in_pcr.author = u.id
           AND in_pcr.communication_result IN ('Автомобиль арестован', 'Автомобиль изъят на добровольной основе') -- Уточнить у бизнеса по 'Автомобиль арестован' - является ли это изъятием!
       ) as [ТС Изъято],
       cast(0 as float)as [% Изъятых ТС],
       (select count(*) from cr in_pcr 
		outer apply
				(
						select top 1
						iif(n.id is null, 0,1) cr --, *
						 from [Stg].[_MPHARD].communication_result n
						 --join [Stg].[_Collection].[Communications] com on n.external_id = com.id 
						 where
						 n.name = in_pcr.communication_result
						 AND
						n.name NOT IN
						(
						'Адрес не найден',
						'Адрес не существует',
						'Клиент в больнице',
						'Клиент в тюрьме',
						'Не знает клиента',
						'Не является клиентом',
						'Номер не принадлежит клиенту',
						'Не берет трубку',
						'Не брал займ',
						'Неверный адрес клиента',
						'Неправильный номер',
						'Несуществующий номер',
						'Нет контакта',
						'Нет ответа',
						--'Отказ от оплаты',
						--'Отказ от разговора 1-е лицо',
						'Отклонен/Cброс',
						'Смерть подтвержденная'
						) 
				) crr
		where in_pcr.author = u.id and cr > 0
       ) as [CR], --  !!!!! функция, требует внимания и корректировки - по результату коммуниации определеяется "успешный" (1) это контакт или нет(0), криетрии "неуспешности" необходимо уточнять у бизнесса (все результаты контактов указаны в таблице communication_result)
       cast(0 as float)as [% CR], -- общее количество считать как (select count(*) from cr in_pcr where in_pcr.author = u.id) (CR/всего * 100%)
       (select count(*) from cr in_pcr where in_pcr.author = u.id
           AND in_pcr.communication_result IN (select name from #success) -- !!!!! критеий у бизнеса (CR любой контакт, у RPC только с должником)
       ) as "RPC",
       cast(0 as float)as [% RPC], -- по аналогии 
       (select count(in_pcrf.value) from cr in_pcr
            join [Stg].[_MPHARD].contact_result_field in_pcrf ON in_pcrf.contact_result_id = in_pcr.id
            where in_pcr.author = u.id AND in_pcrf.field_key = 'promiseSum'
       ) as "PTP", -- коммуникация с обещанием оплатить
       cast(0 as float)as [% PTP],  -- по аналогии 
       (select sum(cast(in_pcrf.value as float)) from cr in_pcr
            join [Stg].[_MPHARD].contact_result_field in_pcrf ON in_pcrf.contact_result_id = in_pcr.id
            where in_pcr.author = u.id AND in_pcrf.field_key = 'promiseSum'
       ) as "PTP руб.",
       cast(0 as float)as [Не было выездов] -- всего считаем как (Нагрузка_клиентов  - contact_result)
	   into #tmp
from [Stg].[_MPHARD].[users] u
where u.login != 'm.gornikov'
order by u.login


update #tmp set Нагрузка_клиентов = isnull( Нагрузка_клиентов,0)
update #tmp set [% Выездов] = iif(Всего = 0, 0, 100 *(Выездов/Всего))
update #tmp set [% Звонков] = iif(Всего = 0, 0, 100 *(Звонков/Всего))
update #tmp set [% Другие_контакты] = iif(Всего = 0, 0, 100 *(Другие_контакты/Всего))
update #tmp set [% Изъятых ТС]= iif(Всего = 0, 0, 100 *([ТС Изъято]/Всего))
update #tmp set [% CR] = iif(Всего = 0, 0, 100 *(CR/Всего))
update #tmp set [% RPC] = iif(Всего = 0, 0, 100 *(RPC/Всего))
update #tmp set [% PTP]= iif(Всего = 0, 0, 100 *(PTP/Всего))
update #tmp set [Не было выездов] = iif(Всего = 0, 0, Нагрузка_клиентов -Всего)


select * from #tmp


end