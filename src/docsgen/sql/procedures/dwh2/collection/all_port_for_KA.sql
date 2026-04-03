
CREATE   PROC [collection].[all_port_for_KA] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try


declare @rdt date = dateadd(dd,-1,cast(getdate() as date));


	drop table if exists   #vibor;        
		  select  d      as r_date, --cdate 
					  external_id,
					 ContractStartDate as credit_date,
					  (case when ContractEndDate is not null and ContractEndDate <= d then 1 else 0 end) as closed,
					  isnull(dpd_coll,  0)                        as overdue_days,
					  isnull(dpd_p_coll,0)                        as overdue_days_p,					 
					  cast(isnull(principal_cnl,    0) as float) +
	                  cast(isnull(percents_cnl,     0) as float) +
	                  cast(isnull(fines_cnl,        0) as float) +
	                  cast(isnull(otherpayments_cnl,0) as float) +
	                  cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total
               into #vibor
			   from dbo.dm_cmrstatbalance--dwh_new.dbo.stat_v_balance2
			   where d <= @rdt and d >= cast(ContractStartDate as date);




	drop table if exists   #vibor_cmr;        
		  select cdate        as r_date,
					  external_id,
					  credit_date,
					  (case when end_date is not null and end_date <= cdate then 1 else 0 end) as closed,
					  isnull(overdue_days,  0)                        as overdue_days,
					  isnull(overdue_days_p,0)                        as overdue_days_p,
					  cast(isnull(principal_rest, 0) as float) - 
					  sum(cast(isnull(principal_wo, 0) as float)) over (partition by external_id ORDER BY cdate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as principal_rest,
					  cast(isnull(percents_rest, 0) as float)         as percents_rest,
					  cast(isnull(fines_rest, 0) as float)            as fines_rest,
					  cast(isnull(other_payments_rest, 0) as float)   as other_rest,
					  cast(isnull(overdue, 0) as float)               as overdue_amount,
					  cast(isnull(total_rest, 0) as float) - 
					  sum(cast(isnull(total_rest_wo, 0) as float)) over (partition by external_id ORDER BY cdate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_rest
		
               into #vibor_cmr
			   from dwh_new.dbo.v_balance_cmr
			   where cdate <= @rdt --dateadd(dd,-1,cast(getdate() as date)) 
			   and cdate >= cast(credit_date as date);


			/*Сумма платежей за последние 30,90,180,270,360,все дней */
			drop table if exists #payments_30d;
			   		   select external_id, sum(isnull(pay_total,0)) as last_pay_amount_30d
			   into #payments_30d
			   from #vibor
			   where r_date >= dateadd(dd,-30, @rdt )
			   group by external_id;

			   drop table if exists #payments_90d;
			   	   select external_id, sum(isnull(pay_total,0)) as last_pay_amount_90d
			   into #payments_90d
			   from #vibor
			   where r_date >= dateadd(dd,-90, @rdt )
			   group by external_id;

			   drop table if exists #payments_180d;
			   	   select external_id, sum(isnull(pay_total,0)) as last_pay_amount_180d
			   into #payments_180d
			   from #vibor
			   where r_date >= dateadd(dd,-180, @rdt )
			   group by external_id;

			   drop table if exists #payments_270d;
			   select external_id, sum(isnull(pay_total,0)) as last_pay_amount_270d
			   into #payments_270d
			   from #vibor
			   where r_date >= dateadd(dd,-270, @rdt )
			   group by external_id;

			   drop table if exists #payments_360d;
			   select external_id, sum(isnull(pay_total,0)) as last_pay_amount_360d
			   into #payments_360d
			   from #vibor
			   where r_date >= dateadd(dd,-360, @rdt )
			   group by external_id;

			   drop table if exists #payments_all;
			   select external_id, sum(isnull(pay_total,0)) as all_pay_amount
			   into #payments_all
			   from #vibor
			   group by external_id;


			   drop table if exists #payments_last;
			   select aa.external_id, aa.r_date, aa.pay_total
			   into #payments_last 
			   from (
			   select a.external_id, a.r_date, a.pay_total, 
			   row_number() over (partition by a.external_id order by a.r_date desc) as rown
			   from #vibor a
			   where a.pay_total > 0) aa
			   where aa.rown = 1;
			   



				drop table if exists #last_overdue;
			   --последний выход в просрочку 
			   select external_id, r_date as date_last_overdue 
			   into #last_overdue 
			   from (
			   select *, row_number() over (partition by external_id order by r_date desc  ) rn
			   from (select r_date, external_id,
			                overdue_days as current_dpd,
					        lag(isnull(overdue_days,0)) over (partition by external_id order by r_date) as previous_dpd
			         from  #vibor_cmr --#vibor
					 ) a
					 where current_dpd>0 and previous_dpd = 0) a
					 where rn=1;



	drop table if exists #address_components;

	with base as (
	select номер, 
					cast(АдресПроживания as varchar(200)) as АдресРегистрации 
		from stg.[_1cMFO].[Документ_ГП_Заявка] a
		inner join dwh_new.dbo.tmp_v_credits b
		on a.Номер = b.external_id
		where дата >'40160228' 
		and cast(АдресПроживания as varchar(200))<>'' 
	)
	select a.Номер, a.АдресРегистрации as registration_address, c.value, c.rn 
	into #address_components
	from base a
	cross apply (
		select b.value,
		row_number() over (partition by a.Номер order by a.номер) as rn
		from string_split(a.АдресРегистрации,',') b
	) c 
;




drop table if exists #registration_address;
SELECT номер
	  ,registration_address
 --     ,case when[1]='' then NULL else [1] end    AS Country
 --     ,case when[2]='' then NULL else [2] end    AS [Index]
      ,case when[3]='' then NULL else [3] end    AS Region_reg
      ,case when[4]='' then NULL else [4] end    AS District_reg
      ,case when[5]='' then NULL else [5] end    AS City_reg
      ,case when[6]='' then NULL else [6] end    AS Locality_reg
	  ,case when[7]='' then NULL else [7] end    AS Street
--	  ,case when[8]='' then NULL else [8] end    AS House
--	  ,case when[9]='' then NULL else [9] end    AS Building
--	  ,case when[10]='' then NULL else [10] end  AS Flat
into #registration_address
From  #address_components Q			
PIVOT(
    MAX(VALUE)
    FOR RN IN([3],[4],[5],[6],[7])  
) as PVT 
;




--2022-01-21 остаточная сумма по исполнительному производству

drop table if exists #stg_judge_requirements;
with base as (
	select DISTINCT 
	a.Number as external_id,
	cast(cl.JudgmentDate as date) as JudgmentDate,
	cast(cl.AmountJudgment as float) as AmountJudgment,
	ROW_NUMBER() over (partition by a.number order by cl.JudgmentDate desc) as rown --отбираем последнее решение суда
	from stg._Collection.Deals a
	inner join stg._Collection.JudicialProceeding pr
	on a.Id = pr.DealId
	and pr.IsFake = 0
	inner join stg._Collection.JudicialClaims cl
	on pr.Id = cl.JudicialProceedingId
	where 1=1
	and cl.JudgmentDate is not null and cl.AmountJudgment > 0 --есть дата решения суда и сумма по решению суда
	and cl.JudgmentDate < cast(getdate() as date)
	and cl.JudgmentDate > '2016-01-01' --валидные даты решения суда
)
select a.external_id, a.JudgmentDate, a.AmountJudgment
into #stg_judge_requirements
from base a
where a.rown = 1
;

--declare @rdt date = dateadd(dd,-1,cast(getdate() as date));
drop table if exists #judge_requirements;
select a.external_id,
a.JudgmentDate,
a.AmountJudgment,
sum(b.pay_total) as pmt_after_court, 
round(
case when a.AmountJudgment - sum(b.pay_total) <= 0 then 0 
else a.AmountJudgment - sum(b.pay_total) end
,2) as judgement_remainder

into #judge_requirements
from #stg_judge_requirements a
left join #vibor b
on a.external_id = b.external_id
and b.r_date >= a.JudgmentDate
inner join dwh_new.dbo.tmp_v_credits c
on a.external_id = c.external_id
group by a.external_id, a.JudgmentDate, a.AmountJudgment
;


--11.02.2022 Остатки из Space

drop table if exists #space;
select a.Number as external_id, 
cast(isnull(a.DebtSum,0)	 as float) as DebtSum	, 
cast(isnull(a.[Percent],0)	 as float) as Interest	, 
cast(isnull(a.Fine,0)		 as float) as Fine		, 
cast(isnull(a.StateFee,0)	 as float) as StateFee	,
cast(isnull(a.Overpayment,0) as float) as Overpayment,
cast(isnull(a.Fulldebt,0)	 as float) as Fulldebt	,
----24.03.2022 email 
trim(case 
when a.IdCustomer = 26685 then '27dim_prozorov@mail.ru'
when a.IdCustomer = 22334 then 'bogka82@yandex.ru'
when a.IdCustomer = 30100 then 'denis.tatarskih@mail.ru'
when a.IdCustomer = 17605  then 'dv_frolov@mail.ru'
when a.IdCustomer = 23865 then 'lime6390@yandex.ru'
when a.IdCustomer = 22718 then 'lyu40119250@yandex.ru'
when b.Email not like '%@%' and b.Email like '%yandex.ru%' then REPLACE(b.email, 'yandex.ru', '@yandex.ru')
when b.Email not like '%@%' and b.Email like '%mail.ru%' then REPLACE(b.email, 'mail.ru', '@mail.ru')
when b.Email not like '%@%' and b.Email like '%gmail.com%' then REPLACE(b.email, 'gmail.com', '@gmail.com')
when b.Email not like '%@%' and b.Email like '%icloud.com%' then REPLACE(b.email, 'icloud.com', '@icloud.com')
when b.Email not like '%@%' then ''
when b.Email is null then ''
else b.Email end) as email

into #space
from stg._Collection.Deals a
left join stg._Collection.CustomerPersonalData b
on a.IdCustomer = b.IdCustomer
;

update #space set DebtSum = 0 where DebtSum < 0;
update #space set Interest = 0 where Interest < 0;
update #space set Fine = 0 where Fine < 0;
update #space set StateFee = 0 where StateFee < 0;
update #space set Fulldebt = 0 where Fulldebt < 0;

--------------------------------------------------------------------------------
--declare @rdt date = dateadd(dd,-1,cast(getdate() as date));  не позволяет зарустить так как дублирует.

		   
drop table if exists #rep_weekly_portf_coll;

			   select distinct 
			   @rdt as [Дата Выгрузки Реестр] ,
			   'ООО МФК КАРМАНИ' as [Кредитор],

			   'МФК - Займ под залог ПТС' as [Продукт (вид кредита)],
			   c.КодДоговораЗайма as [ID Кредитного Договора],

			   cast(z.Клиент as bigint) as [ID Клиента],
			   (case when isnull(ac.agent_name, 'CarMoney') in ('ACB','CarMoney') then 'CarMoney'
						 else isnull(ac.agent_name, 'CarMoney') end) as [Агент],

			   (case when isnull(agent_name, 'CarMoney') in ('ACB','CarMoney') then 0
                         else isnull(reestr, 0) end) as [agent_reestr],

			   concat(z.Фамилия, ' ', z.Имя, ' ', z.Отчество) as [ФИО],

			   dateadd(year,-2000,cast(z.ДатаРождения as date)) [Дата_рождения],
			   cast(z.МестоРождения as varchar(2000)) as [Место Рождения],

			   CONCAT(z.СерияПаспорта, ' ', z.НомерПаспорта) [серия_номер_паспорта],
			   dateadd(year,-2000,cast(ДатаВыдачиПаспорта as date)) [Дата Выдачи Паспорта],
			   z.КемВыдан as [Кем выдан Паспорт],
			   c.ДатаДоговораЗайма as [Дата Выдачи Займа],
			   dateadd(month,c.Срок,c.ДатаДоговораЗайма) [Дата Окончания КД],
			   c.Сумма as [сумма займа], --datsyplakov 13/07/2020: добавлена сумма выдачи
			   c.Срок as [Срок Займа],			   
			   d.ПроцСтавкаКредит as [ПроцСтавкаКредит],

			   kl.наименование as [Статус Контактного Лица],
			   ФИОКонтактногоЛица as [ФИОКонтактногоЛица],
			   concat(z.ФамилияСупруги, ' ', z.ИмяСупруги, ' ', ОтчествоСупруги) as [ФИО_супруга],

			   z.VIN as [VIN],
			   z.ГодАвто as [ГодАвто],
			   z.МаркаАвто as [МаркаАвто],
			   z.МодельАвто as [МодельАвто],
			   CONCAT(z.СерияПТС, ' ', z.НомерПТС) as [серия_номер_ПТС],
			   CONCAT(z.СерияСТС, ' ', z.НомерСТС) as [серия_номер_СТС],
			   РегНомер as [РегНомер],
			   ОценочнаяCтоимостьАвто as [ОценочнаяCтоимостьАвто],

			   v.overdue_days as [Кол-во дней Просрочки],
			   (case when isnull(v.overdue_days,0) <=   0 then '[01] 0'
               when isnull(v.overdue_days,0) <=  30 then '[02] 1-30'
               when isnull(v.overdue_days,0) <=  60 then '[03] 31-60'
               when isnull(v.overdue_days,0) <=  90 then '[04] 61-90'
               when isnull(v.overdue_days,0) <= 120 then '[05] 91-120'
               when isnull(v.overdue_days,0) <= 150 then '[06] 121-150'
               when isnull(v.overdue_days,0) <= 180 then '[07] 151-180'
               when isnull(v.overdue_days,0) <= 210 then '[08] 181-210'
               when isnull(v.overdue_days,0) <= 240 then '[09] 211-240'
               when isnull(v.overdue_days,0) <= 270 then '[10] 241-270'
               when isnull(v.overdue_days,0) <= 300 then '[11] 271-300'
               when isnull(v.overdue_days,0) <= 330 then '[12] 301-330'
               when isnull(v.overdue_days,0) <= 360 then '[13] 331-360'
               when isnull(v.overdue_days,0) <= 390 then '[14] 361-390'
               when isnull(v.overdue_days,0) <= 420 then '[15] 391-420'
               when isnull(v.overdue_days,0) <= 450 then '[16] 421-450'
               when isnull(v.overdue_days,0) <= 480 then '[17] 451-480'
               when isnull(v.overdue_days,0) <= 510 then '[18] 481-510'
               when isnull(v.overdue_days,0) <= 540 then '[19] 511-540'
               when isnull(v.overdue_days,0) <= 570 then '[20] 541-570'
               when isnull(v.overdue_days,0) <= 600 then '[21] 571-600'
               when isnull(v.overdue_days,0) <= 630 then '[22] 601-630'
               when isnull(v.overdue_days,0) <= 660 then '[23] 631-660'
               when isnull(v.overdue_days,0) <= 690 then '[24] 661-690'
               when isnull(v.overdue_days,0) <= 720 then '[25] 691-720'
               else '[26] 721+' end)                     as [Корзина Просрочки],
			   b.default_date [Дата Первого Выхода На Просрочку],
			   lo.date_last_overdue [Дата Последнего Выхода На Просрочку],

			   --v.principal_rest as [Остаток ОД],
			   --v.percents_rest as [Остаток %],
			   --v.fines_rest as [Остаток Пени],
			   --v.other_rest as [Остаток Комисии и Пошлины],
			   --v.total_rest as [Итого задолженность],
			   
			   case when spc.external_id is not null then isnull(spc.DebtSum,0) else v.principal_rest end as [Остаток ОД],
			   case when spc.external_id is not null then isnull(spc.Interest,0) else v.percents_rest end as [Остаток %],
			   case when spc.external_id is not null then isnull(spc.Fine,0) else v.fines_rest end as [Остаток Пени],
			   case when spc.external_id is not null then isnull(spc.StateFee,0) else v.other_rest end as [Остаток Комисии и Пошлины],
			   case when spc.external_id is not null then isnull(spc.Overpayment,0) else 0 end as [Переплата],
			   case when spc.external_id is not null then isnull(spc.Fulldebt,0) else v.total_rest end as [Итого задолженность],


			   --datsyplakov 21/01/2022 остаток суммы исполнительного производства
			   isnull(jreq.AmountJudgment,0) as [Сумма по судебному решению],
			   isnull(jreq.judgement_remainder,0) as [Остаток суммы исполнительного производства],

			   --datsyplakov 13/07/2020 дата и сумма последнего платежа из МФО
			   plst.r_date as [Дата Последнего Платежа], --last_pay_date,
			   plst.pay_total as [Сумма Последнего Платежа], --pay,
			   last_pay_amount_30d as [Сумма Платежей За 30 Дней],
			   last_pay_amount_90d as [Сумма Платежей За 90 Дней],
			   last_pay_amount_180d as [Сумма Платежей За 180 Дней],
			   last_pay_amount_270d as [Сумма Платежей За 270 Дней],
			   last_pay_amount_360d as [Сумма Платежей За 360 Дней],
			   al.all_pay_amount as [Сумма Платежей За Весь Период Займа],
			   death_flag as [Смерть Подтвержденная], 
			   UnconfirmedDeath_flag as [Смерть Неподтвержденная],
			   disabled_person_flag as [Инвалид 1 группы (230-ФЗ)],
			   hospital_flag as [В больнице (230-ФЗ)],
			   [FailureInteraction230FZ_flag] as [Отказ от взаимодествия (230-ФЗ)],
			   FailureInteractionWith3person230FZ_flag as [Отказ от взаимодействия 3-его лица (230-ФЗ)],
			   Complaint_flag as [Жалоба (230-ФЗ)],
			   FRAUD_flag as [Мошенничество],
			   case when sdm.bankrupt is not null then 1 else 0 end as [Банкрот],
			   RepresentativeInteraction230FZ_flag as [Отзыв в рамках 230-ФЗ],
			   res.Region_reg  as [Регион Проживания],
			   case when res.City_reg is null and   res.Locality_reg is null then res.Region_reg
					when res.City_reg is null and   res.Locality_reg is not  null then res.Locality_reg 
					else  res.City_reg end   as [Город Проживания],
			   Street  as [Улица Проживания],
			   ТелефонМобильный as [Телефон Мобильный],
			   ТелефонОбращения as [Телефон Обращения],
			   ТелефонАдресаПроживания as [Телефон Адреса Проживания],
			   ТелефонСупруги as [Телефон Супруги],
			   КЛТелКонтактный as [Тел Контактного Лица Контактный],
			   КЛТелМобильный as [Тел Контактного Лица Мобильный],
			   ТелефонКонтактныйОсновной as [Телефон Контактный Основной],
			   ТелефонКонтактныйДополнительный as [Телефон Контактный Дополнительный],			   
			   
			   ТелРабочийРуководителя as [Тел Рабочий Руководителя],
			   cast([АдресПроживания] as nvarchar(4000)) as [Адрес Проживания],
			   cast([АдресРегистрации] as nvarchar(4000)) as [Адрес Регистрации],
			   cast(z.АдресРаботы as nvarchar(4000)) as [Адрес Работы],
			   isnull(spc.email,'') as email

			   into #rep_weekly_portf_coll
			   from dwh2.dm.ДоговорЗайма c
			  
			 --  select * into #z from stg._1cmfo.документ_ГП_заявка

			   left join stg._1cmfo.документ_ГП_заявка z 
			   on c.КодДоговораЗайма=z.номер
			   
			  -- select * into #d from reports.[dbo].[report_Agreement_InterestRate]
			   left join reports.[dbo].[report_Agreement_InterestRate] d 
			   on c.КодДоговораЗайма=d.ДоговорНомер
			   
			   -- select * into #m from reports.[dbo].dm_maindata
			   left join reports.[dbo].dm_maindata m 
			   on c.КодДоговораЗайма=m.external_id
			   
			  --   select * into #b from dwh_new.dbo.stat_v_balance2 b
					--where b.cdate='2022-08-07' and b.end_date is null
			   left join dwh_new.dbo.stat_v_balance2 b 
			   on c.КодДоговораЗайма=b.external_id 
			   and cdate = @rdt --cast(dateadd(day,-1,current_timestamp) as date)
			   
				--DWH-257
				left join (
					select
						agent_name = a.AgentName
						,reestr = RegistryNumber
						,external_id = d.Number
						,st_date  = cat.TransferDate
						,fact_end_date = cat.ReturnDate
						,plan_end_date = cat.PlannedReviewDate
						,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
					from Stg._collection.CollectingAgencyTransfer as cat
						inner join Stg._collection.Deals as d
							on d.Id = cat.DealId
						inner join Stg._collection.CollectorAgencies as a
							on a.Id = cat.CollectorAgencyId
				) as ac
			   on c.КодДоговораЗайма = ac.external_id 
			   and @rdt /*cast(dateadd(day,-1,current_timestamp) as date)*/ >= ac.st_date 
			   and @rdt /*cast(dateadd(day,-1,current_timestamp) as date)*/ <= ac.end_date
			   
			   left join #vibor_cmr v --#vibor v 
			   on c.КодДоговораЗайма = v.external_id 
			   and v.r_date = @rdt --cast(dateadd(day,-1,current_timestamp) as date)
			   
			   left join #payments_30d  p30  on c.КодДоговораЗайма=p30.external_id
			   left join #payments_90d  p90  on c.КодДоговораЗайма=p90.external_id
			   left join #payments_180d p180 on c.КодДоговораЗайма=p180.external_id
			   left join #payments_270d p270 on c.КодДоговораЗайма=p270.external_id
			   left join #payments_360d p360 on c.КодДоговораЗайма=p360.external_id
			   left join #payments_all  al   on c.КодДоговораЗайма=al.external_id
			   left join #payments_last plst on c.КодДоговораЗайма = plst.external_id
			   
			   --left join [dwh_new].[Dialer].[StrategyDataMart2] sdm 
			   left join dm.Collection_StrategyDataMart sdm
			   on c.КодДоговораЗайма = sdm.external_id 
			   and sdm.StrategyDate = @rdt -- cast(dateadd(day,-1,current_timestamp) as date)
			   
			   left join #last_overdue lo on c.КодДоговораЗайма=lo.external_id
			   
			   left join #registration_address res on c.КодДоговораЗайма=res.номер
			   
			   left join stg._Collection.Deals cd on c.КодДоговораЗайма=cd.Number

			   left join stg._1cmfo.Справочник_ГП_СтатусПодтверждающегоЛица kl 
			   on z.КЛСтатус = kl.ссылка

			   left join #judge_requirements jreq
			   on c.КодДоговораЗайма = jreq.external_id

			   left join #space spc
			   on c.КодДоговораЗайма = spc.external_id

			  -- where b.end_date is null;


drop table if exists #vibor;
drop table if exists #vibor_cmr;
drop table if exists #payments_30d;
drop table if exists #payments_90d;
drop table if exists #payments_180d;
drop table if exists #payments_270d;
drop table if exists #payments_360d;
drop table if exists #payments_all;
drop table if exists #last_overdue;
drop table if exists #registration_address;


/*
select a.[ID Кредитного Договора]
from #rep_weekly_portf_coll a
group by a.[ID Кредитного Договора]
having count(*)>1
*/
--Финальный селект для Excel

/*
drop table if exists #space_market_price;
select a.Number, c.Vin, c.MarketPrice
into #space_market_price
from stg._Collection.Deals a
left join stg._Collection.DealPledgeItem b
on a.id = b.DealId
left join stg._Collection.PledgeItem c
on b.PledgeItemId = c.Id
;
*/


drop table if exists #space_market_price;
select a.Number, c.Vin, c.MarketPrice,stg.Name as STAGE, sts.Name as Status_deals
into #space_market_price
from stg._Collection.Deals a
left join stg._Collection.DealPledgeItem b
on a.id = b.DealId
left join stg._Collection.PledgeItem c
on b.PledgeItemId = c.Id
left join stg._Collection.collectingStage stg
on a.StageId=stg.id
left join stg._collection.DealStatus sts
on sts.id=a.IdStatus

;


	BEGIN TRANSACTION


	delete from collection.[for_KA];
	insert collection.[for_KA] (



 [Дата Выгрузки Реестр]
      ,[Кредитор]
      ,[Продукт (вид кредита)]
      ,[ID Кредитного Договора]
      ,[ID Клиента]
      ,[Агент]
      ,[agent_reestr]
      ,[ФИО]
      ,[Дата_рождения]
      ,[Место Рождения]
      ,[серия_номер_паспорта]
      ,[Дата Выдачи Паспорта]
      ,[Кем выдан Паспорт]
      ,[Дата Выдачи Займа]
      ,[Дата Окончания КД]
      ,[сумма займа]
      ,[Срок Займа]
      ,[ПроцСтавкаКредит]
      ,[Статус Контактного Лица]
      ,[ФИОКонтактногоЛица]
      ,[ФИО_супруга]
      ,[VIN]
      ,[ГодАвто]
      ,[МаркаАвто]
      ,[МодельАвто]
      ,[серия_номер_ПТС]
      ,[серия_номер_СТС]
      ,[РегНомер]
      ,[ОценочнаяCтоимостьАвто]
      ,[Кол-во дней Просрочки]
      ,[Корзина Просрочки]
      ,[Дата Первого Выхода На Просрочку]
      ,[Дата Последнего Выхода На Просрочку]
      ,[Остаток ОД]
      ,[Остаток %]
      ,[Остаток Пени]
      ,[Остаток Комисии и Пошлины]
      ,[Переплата]
      ,[Итого задолженность]
      ,[Сумма по судебному решению]
      ,[Остаток суммы исполнительного производства]
      ,[Дата Последнего Платежа]
      ,[Сумма Последнего Платежа]
      ,[Сумма Платежей За 30 Дней]
      ,[Сумма Платежей За 90 Дней]
      ,[Сумма Платежей За 180 Дней]
      ,[Сумма Платежей За 270 Дней]
      ,[Сумма Платежей За 360 Дней]
      ,[Сумма Платежей За Весь Период Займа]
      ,[Смерть Подтвержденная]
      ,[Смерть Неподтвержденная]
      ,[Инвалид 1 группы (230-ФЗ)]
      ,[В больнице (230-ФЗ)]
      ,[Отказ от взаимодествия (230-ФЗ)]
      ,[Отказ от взаимодействия 3-его лица (230-ФЗ)]
      ,[Жалоба (230-ФЗ)]
      ,[Мошенничество]
      ,[Банкрот]
      ,[Отзыв в рамках 230-ФЗ]
      ,[Регион Проживания]
      ,[Город Проживания]
      ,[Улица Проживания]
      ,[Телефон Мобильный]
      ,[Телефон Обращения]
      ,[Телефон Адреса Проживания]
      ,[Телефон Супруги]
      ,[Тел Контактного Лица Контактный]
      ,[Тел Контактного Лица Мобильный]
      ,[Телефон Контактный Основной]
      ,[Телефон Контактный Дополнительный]
      ,[Тел Рабочий Руководителя]
      ,[Адрес Проживания]
      ,[Адрес Регистрации]
      ,[Адрес Работы]
      ,[email]
      ,[MarketPrice]
	  ,[STAGE]
	  ,[Status_deals]


)
select a.*, b.MarketPrice ,b.STAGE,b.Status_deals from #rep_weekly_portf_coll a left join #space_market_price b on a.[ID Кредитного Договора] = b.Number
--where --not exists (select 1 from RiskDWH.dbo.det_crm_redzone b where a.[ID Кредитного Договора] = b.external_id and b.action_type like '%Цес%') --исключаем Цессию
--and 
--isnull([Остаток ОД],0)>0

	;
	

  COMMIT TRANSACTION

  

EXEC [collection].set_debug_info @sp_name
			,'Finish';		
			
	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
