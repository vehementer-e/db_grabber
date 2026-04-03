


--exec [dbo].[append_naumen_dialer_report]

CREATE     procedure  [dbo].[append_naumen_dialer_report]
as 
begin
 --return


  set nocount on
 
 	--24.03.2020
	SET DATEFIRST 1;

 declare @now_dt datetime
IF datepart(hh, getdate()) = 0
   begin
       SET @now_dt = dateadd(hh, -1-datepart(hh, getdate()), getdate())
   end
ELSE IF datepart(hh, getdate()) between 1 and 23
   begin
       SET @now_dt = getdate()
   end

	drop table if exists #dos_temp
	select  
		[session_id], 
		[case_uuid], 
		[attempt_start], 
		[attempt_end], 
		[number_type], 
		[client_number], 
		[out_number], 
		[pickup_time], 
		[queue_time], 
		[operator_pickup_time], 
		[speaking_time], 
		[wrapup_time], 
		[login], 
		[attempt_result], 
		[voip_reason], 
		[hangup_initiator], 
		[dialer_mode], 
		[attempt_number], 
		[sort_segment], 
		[amd_pattern], 
		[project_id], 
		[holds], 
		[hold_time]
	into #dos_temp from [NaumenDbReport].[dbo].[detail_outbound_sessions]
	 where 
   --project_id in (
   --'corebo00000000000mqi35tcal14edv4', --Fedor TLS
   --'corebo00000000000mqpsrh9u28s16g8', --Fedor Автоинформатор лидген
   --'corebo00000000000mtmnhcj42ev6svs', --Триггеры
   --'corebo00000000000mtmnk1gt6gdvdc0' --Пилот
   --) and attempt_start>cast(@now_dt as date) and attempt_start<dateadd(dd, 1, cast(@now_dt as date))
   --
   --or 
   
   --project_id in (
   --  'corebo00000000000mn2eg74l4nb9950', --Докреды TLS
   --'corebo00000000000mm1tts6og6rs2fk', --Докреды
   --'corebo00000000000ms8u5urtmth4ev0', --Автоинформатор Разовая
   --'corebo00000000000mqrftq8mhigv9qo', --Докреды v2
   --'corebo00000000000ms0iggb3gbo7lv0', --Автоинформатор Докреды
   --'corebo00000000000ms6slfj341gnrd0' --Автоинформатор Докреды ПЭП
   --) 
   --and 
   attempt_start>cast(DATEADD(DD, 1 - DATEPART(DW, @now_dt), @now_dt) as date)
   and attempt_start<dateadd(dd, 7, cast(DATEADD(DD, 1 - DATEPART(DW, @now_dt), @now_dt) as date))


   drop table if exists #сс_temp
   select 
		[uuid], 
		[history], 
		[priority], 
		[creationdate], 
		[projectuuid], 
		[projecttitle], 
		[clientuuid], 
		[clienttitle], 
		[stateuuid], 
		[statetitle], 
		[operatoruuid], 
		[operatortitle], 
		[casecomment], 
		[lasthistoryitem], 
		[operatorfirstname], 
		[operatormiddlename], 
		[operatorlastname], 
		[operatoremail], 
		[operatorinternalphonenumber], 
		[operatorworkphonenumber], 
		[operatormobilephonenumber], 
		[operatorhomephonenumber], 
		[operatordateofbirth], 
		[totalnumberofphones], 
		[numberofbadphones], 
		[plannedphonetime], 
		[lastcall], 
		[removed], 
		[removaldate], 
		[phonenumbers], 
		[email], 
		[stringvalue1], 
		[stringvalue2], 
		[uploadstate], 
		[uploadeddate], 
		[modifieddate], 
		[allowedtimefrom], 
		[allowedtimeto], 
		[finisheddate], 
		[timezone]
      into #сс_temp
   from [NaumenDbReport].[dbo].[mv_call_case] with(index=NCL_idx_creationdate_projectuuid)
  -- select * from Reports.dbo.dm_NaumenProjects
    where 
   projectuuid in (
   'corebo00000000000mqi35tcal14edv4', --Fedor TLS
  -- 'corebo00000000000mqpsrh9u28s16g8', --Fedor Автоинформатор лидген
   'corebo00000000000n8i9hcja56hji2o', --РобоIVR Пилот
   'corebo00000000000n35ltu7n0jje82k', --Fedor Автоинформатор лидген 2
   'corebo00000000000mtmnhcj42ev6svs', --Триггеры
   'corebo00000000000n56bur0s6arg22o', --Пилот 2
   'corebo00000000000n56buhov4c5cjug', --Целевой
   'corebo00000000000mtmnk1gt6gdvdc0' --Пилот
   ) and creationdate>cast(@now_dt as date) and creationdate<dateadd(dd, 1, cast(@now_dt as date))
   
   or 
   
   projectuuid in (
     'corebo00000000000mn2eg74l4nb9950', --Докреды TLS
     'corebo00000000000n25qfiqhjjmogcg', --Пилот консерватор
   'corebo00000000000mm1tts6og6rs2fk', --Докреды
   'corebo00000000000ms8u5urtmth4ev0', --Автоинформатор Разовая
   'corebo00000000000mqrftq8mhigv9qo', --Докреды v2
   'corebo00000000000ms0iggb3gbo7lv0', --Автоинформатор Докреды
   'corebo00000000000ms6slfj341gnrd0' --Автоинформатор Докреды ПЭП
   )-- and creationdate>cast(@now_dt as date) and creationdate<dateadd(dd, 1, cast(@now_dt as date))
   
   and creationdate>cast(DATEADD(DD, 1 - DATEPART(DW, @now_dt), @now_dt) as date)
   and creationdate<dateadd(dd, 7, cast(DATEADD(DD, 1 - DATEPART(DW, @now_dt), @now_dt) as date))


drop table if exists #t
select *, case when projectuuid in (
   'corebo00000000000mqi35tcal14edv4', --Fedor TLS
   'corebo00000000000mtmnhcj42ev6svs', --Триггеры
   'corebo00000000000mtmnk1gt6gdvdc0', --Пилот
      'corebo00000000000n56bur0s6arg22o', --Пилот 2
   'corebo00000000000n56buhov4c5cjug' --Целевой
   ) then 'Телесейлз'
   when projectuuid in 
   
   (
  'corebo00000000000n8i9hcja56hji2o', --РобоIVR Пилот
  'corebo00000000000n35ltu7n0jje82k') --Fedor Автоинформатор лидген 2

     then 'Лидген'
	 when projectuuid in (
   'corebo00000000000mn2eg74l4nb9950', --Докреды TLS
   'corebo00000000000mm1tts6og6rs2fk', --Докреды
   'corebo00000000000ms8u5urtmth4ev0', --Автоинформатор Разовая
     'corebo00000000000n25qfiqhjjmogcg', --Пилот консерватор

   'corebo00000000000mqrftq8mhigv9qo', --Докреды v2
   'corebo00000000000ms0iggb3gbo7lv0', --Автоинформатор Докреды
   'corebo00000000000ms6slfj341gnrd0' --Автоинформатор Докреды ПЭП
   ) then 'Докреды' end as [Кампания]

into #t
from #сс_temp cc
 left   join #dos_temp dos on dos.case_uuid=cc.uuid

   


   declare @start_dt datetime     



IF datepart(hh, @now_dt) between 0 and 9
   begin
       SET @start_dt = dateadd(hh, 0 , cast(cast(@now_dt as date) as datetime))
  --     SET @end_dt = dateadd(hh, 8 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 10 and 11) 
   begin
       SET @start_dt = dateadd(hh, 0 , cast(cast(@now_dt as date) as datetime))
 --      SET @end_dt = dateadd(hh, 10 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 12 and 13) 
   begin
       SET @start_dt = dateadd(hh, 10 , cast(cast(@now_dt as date) as datetime))
   --    SET @end_dt = dateadd(hh, 12 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 14 and 15) 
   begin
       SET @start_dt = dateadd(hh, 12 , cast(cast(@now_dt as date) as datetime))
   --    SET @end_dt = dateadd(hh, 14 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 16 and 17) 
   begin
       SET @start_dt = dateadd(hh, 14 , cast(cast(@now_dt as date) as datetime))
   --    SET @end_dt = dateadd(hh, 16 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 18 and 22) 
   begin
       SET @start_dt = dateadd(hh, 16 , cast(cast(@now_dt as date) as datetime))
   --    SET @end_dt = dateadd(hh, 18 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 23 and 23) 
   begin
       SET @start_dt = dateadd(hh, 18 , cast(cast(@now_dt as date) as datetime))
    --   SET @end_dt = dateadd(hh, 24 , cast(cast(@now_dt as date) as datetime))
   end

   declare @end_dt datetime
   IF datepart(hh, @now_dt) between 0 and 9
   begin
   --    SET @start_dt = dateadd(hh, 0 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 8 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 10 and 11) 
   begin
  --     SET @start_dt = dateadd(hh, 0 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 10 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 12 and 13) 
   begin
  --     SET @start_dt = dateadd(hh, 10 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 12 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 14 and 15) 
   begin
   --    SET @start_dt = dateadd(hh, 12 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 14 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 16 and 17) 
   begin
  --     SET @start_dt = dateadd(hh, 14 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 16 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 18 and 20) 
   begin
   --    SET @start_dt = dateadd(hh, 16 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 18 , cast(cast(@now_dt as date) as datetime))
   end
ELSE IF (datepart(hh, @now_dt) between 20 and 23) 
   begin
   --    SET @start_dt = dateadd(hh, 18 , cast(cast(@now_dt as date) as datetime))
       SET @end_dt = dateadd(hh, 24 , cast(cast(@now_dt as date) as datetime))
   end







  begin tran

   
  --delete from  feodor.dbo.naumen_dialer_report   where [UF_REGISTERED_AT]>cast(getdate()-3 as date)
  insert into  feodor.dbo.naumen_dialer_report
   select 
   cast([Время] as date) as [Дата],
   cast(getdate() as smalldatetime) as [Время выполнения запроса],
   case when datepart(hh,cast([Время] as time))=23 then cast('Итог' as varchar) else replace(cast(cast([Время] as date) as varchar) +' ' + cast(cast([Время] as time) as varchar), '.0000000',   '') end as [Время],
   t0.projecttitle, 
   isnull([Кейсов новых], 0)-isnull([Кейсов обработано], 0) as [Осталось прозвонить кейсов],
   isnull([Кейсов новых], 0) as [Кейсов новых],
   isnull([Кейсов обработано], 0) as [Кейсов обработано],


   isnull([Лидов (телефонных номеров) поступило], 0) as [Лидов (телефонных номеров) поступило],
   isnull([Лидов (телефонных номеров) обработано], 0) as [Лидов (телефонных номеров) обработано],
   isnull([Лидов (телефонных номеров) поступило],0)-isnull([Лидов (телефонных номеров) обработано],0) as [Осталось прозвонить лидов (телефонных номеров)],

   isnull([Успешных консультаций (по номерам телефонов)], 0) as [Успешных консультаций (по номерам телефонов)],

   cast(
   100*round(
   isnull(cast(isnull([Успешных консультаций (по номерам телефонов)], 0) as float) / cast(nullif([Лидов (телефонных номеров) обработано], 0) as float), 0)
   , 4) as varchar)+'%' as [Контактность по номерам телефонов],


   isnull([Потерянные вызовы], 0) as [Потерянные вызовы],

      cast(
   100*round(
   isnull(cast(isnull([Потерянные вызовы], 0) as float) / cast(nullif([Кейсов обработано], 0) as float), 0)
   , 4) as varchar)+'%' as [% потерянных от всех],


   isnull([Среднее время ожидания клиента по потерянным], 0) as [Среднее время ожидания клиента по потерянным],

   isnull([Средний wrap time], 0) as [Средний wrap time], 

   isnull([Средний call time], 0) as [Средний call time],

   isnull([Среднее время обработки на кейс], 0) as [Среднее время обработки на кейс],

   cast(
   100*round(
   isnull(cast(isnull([Кейсов обработано], 0) as float) / cast(nullif([Кейсов новых], 0) as float), 0) 
   , 3) as varchar)+'%' as [Penetration],

   isnull(t7.dialer_mode, 'Не было звонков') as [Режим обзвона],
   isnull([Кол-во операторов], 0) as [Кол-во операторов],
   isnull([Кол-во обработанных кейсов на 1 оператора], 0) as [Кол-во обработанных кейсов на 1 оператора],
   isnull([Кол-во попыток], 0) as [Кол-во попыток],

      cast(
   100*round(
   isnull(cast(isnull([Кол-во попыток], 0) as float) / cast(nullif([Кейсов новых], 0) as float), 0)
   , 2) as varchar)+'%' as [Spin]



   from (

   select 
		@now_dt [Время], 
		count(distinct uuid) as [Кейсов новых], 
				count(session_id) as [Кол-во попыток],
		projecttitle  
   from #t t0
   group by projecttitle) t0

   left join (
   select 
		count(distinct uuid) as [Кейсов обработано], 
		projecttitle 
   from #t t1
   where session_id is not null 
   group by projecttitle) t1 on t0.projecttitle=t1.projecttitle

   left join (
   select 
		count(distinct phonenumbers) as [Лидов (телефонных номеров) поступило], 
		projecttitle
   from #t t2
   group by projecttitle) t2 on t0.projecttitle=t2.projecttitle
   
   left join (
   select 
		count(distinct phonenumbers) as [Лидов (телефонных номеров) обработано], 
		projecttitle 
   from #t t3 
   where session_id is not null 
   group by projecttitle) t3 on t0.projecttitle=t3.projecttitle

   left join (
   select 
   count(distinct phonenumbers) as [Успешных консультаций (по номерам телефонов)], 
   projecttitle 
   from #t t4 
   where session_id is not null and speaking_time>0 
   group by projecttitle) t4 on t0.projecttitle=t4.projecttitle

      left join (
   select 
   count(distinct session_id) as [Потерянные вызовы],
   avg(queue_time)  as [Среднее время ожидания клиента по потерянным],
   projecttitle 
   from #t t5 
   where attempt_result ='abandoned' and queue_time>20
   group by projecttitle) t5 on t0.projecttitle=t5.projecttitle

      left join (
   select 
   avg(wrapup_time) as [Средний wrap time], 
   avg(speaking_time) as [Средний call time],
   isnull(avg(wrapup_time), 0) +
   isnull(avg(speaking_time), 0) as [Среднее время обработки на кейс],

   projecttitle 
   from #t t6 
   group by projecttitle) t6 on t0.projecttitle=t6.projecttitle

   outer  apply (select top 1 dialer_mode from #t t7 where t7.projecttitle=t0.projecttitle and dialer_mode is not null) t7

   left join (
   select round(isnull(isnull(cast(count(distinct phonenumbers) as float),0) / nullif(cast(count(distinct login) as float), 0), 0), 1) as [Кол-во обработанных кейсов на 1 оператора],
   count(distinct login) as [Кол-во операторов],
   projecttitle from #t t8
   where attempt_start>=@start_dt and attempt_start<=@end_dt and ((session_id is not null and projecttitle
   not in 
    (
  'corebo00000000000n8i9hcja56hji2o', --РобоIVR Пилот
  'corebo00000000000n35ltu7n0jje82k') --Fedor Автоинформатор лидген 2

   ) or (speaking_time is not null and projecttitle in
    (
  'corebo00000000000n8i9hcja56hji2o', --РобоIVR Пилот
  'corebo00000000000n35ltu7n0jje82k') --Fedor Автоинформатор лидген 2

   
   ))
   group by projecttitle) t8 on t0.projecttitle=t8.projecttitle

  



  commit tran

       


end
 
