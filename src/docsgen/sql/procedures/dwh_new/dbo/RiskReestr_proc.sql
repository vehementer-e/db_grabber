


--exec [dbo].[RiskReestr_proc]
CREATE    procedure  [dbo].[RiskReestr_proc]
as


drop table if exists #Clients
  select a.external_id
       , isnull(a.overdue_days_p,0)              as dpd
    into #Clients
    from stat_v_balance2 a
    
   where a.cdate = dateadd(dd,-1,cast(getdate() as date))
     and cast(a.total_rest as float) > 0
     and isnull(a.overdue_days_p,0) >0


drop table if exists #tbl_a
 select a.Номер as external_id
      , b.АдресПроживания as adress_projivaniya
      , b.АдресРегистрации as adress_registraciyi
      , row_number() over (partition by a.Номер order by a.Номер) as rn
   into #tbl_a
   from [prodsql02].[MFO].[dbo].[Документ_ГП_Договор]     a
   join #clients cl on cl.external_id  =a.Номер 
   left join [prodsql02].[MFO].[dbo].[Документ_ГП_Заявка] b on  a.Заявка=b.ссылка

drop table if exists #tbl_b
  select external_id
       , adress_projivaniya
       , adress_registraciyi
   into #tbl_b
   from #tbl_a a
  where rn = 1


drop table if exists #requests
select id, person_id into #requests from requests

drop table if exists #tbl_d
  select distinct request_id
       , person_id
       , cast(stage_time as date) end_date
    into #tbl_d
    from requests_history rh
    join #requests r on r.id = rh.request_id
   where status = 16



drop table if exists #v_persons
select * into  #v_persons from v_persons

drop table if exists #tbl_e
  select a.external_id
       , cast(a.credit_date as date) as credit_date
       , cast(a.amount as float) as credit_amount
       , ltrim(rtrim(c.first_name))  as first_name
       , ltrim(rtrim(c.middle_name)) as middle_name
       , ltrim(rtrim(c.last_name))   as last_name
       , concat(ltrim(rtrim(c.last_name)), ' ', ltrim(rtrim(c.first_name)), ' ', ltrim(rtrim(c.middle_name))) as fio
       , cast(c.birth_date as date) as birth_date
       , d.end_date
       , row_number() over (partition by a.external_id order by a.created) as rn
   into #tbl_e
   from tmp_v_credits a
    join #clients cl on cl.external_id  =a.external_id
   left join #v_persons     c on a.person_id     = c.id
   left join #tbl_d d on a.request_id = d.request_id

drop table if exists #tbl_f
  select a.external_id
       , a.credit_date
       , a.credit_amount
       , a.fio
       , a.birth_date
       , a.end_date
       , isnull(b.adress_projivaniya, 'Nan') as adress_projivaniya
       , isnull(b.adress_registraciyi,'Nan') as adress_registraciyi
       into #tbl_f
    from #tbl_e a
    join #clients cl on cl.external_id  =a.external_id
    left join #tbl_b b on a.external_id = b.external_id
   where a.rn = 1



drop table if exists #payme_a
  select cdate
       , a.external_id
       , cast(isnull(principal_cnl,    0) as float) +
         cast(isnull(percents_cnl,     0) as float) +
         cast(isnull(fines_cnl,        0) as float) +
         cast(isnull(otherpayments_cnl,0) as float) +
         cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total
    into #payme_a
    from stat_v_balance2 a
    join #clients cl on cl.external_id  =a.external_id
   where cdate <= dateadd(dd,-1,cast(getdate() as date))

;
drop table if exists #payme_b

  select external_id
       ,  sum(case when cdate >= dateadd(mm,-3,dateadd(dd,-1,cast(getdate() as date))) and cdate <= dateadd(dd,-1,cast(getdate() as date))
          then pay_total else 0 end) as pay_amount_3m
   into #payme_b
   from #payme_a a
  group by external_id


--drop table if exists #payme_c
--select * into  #payme_c from #payme_a
  /*select cdate
       , external_id
       , cast(isnull(principal_cnl,    0) as float) +
         cast(isnull(percents_cnl,     0) as float) +
         cast(isnull(fines_cnl,        0) as float) +
         cast(isnull(otherpayments_cnl,0) as float) +
         cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total
         into #payme_c
    from stat_v_balance2
   where cdate <= dateadd(dd,-1,cast(getdate() as date))

    */
drop table if exists #payme_d
  select external_id
       , max(cdate) as max_pay_date
       into #payme_d
    from #payme_a a
   where pay_total > 0
   group by external_id

--drop table if exists #payme_e
--select * into  #payme_e from #payme_a
/*
  select cdate
       , external_id
       , cast(isnull(principal_cnl,    0) as float) +
         cast(isnull(percents_cnl,     0) as float) +
         cast(isnull(fines_cnl,        0) as float) +
         cast(isnull(otherpayments_cnl,0) as float) +
         cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total
    into #payme_e
    from stat_v_balance2
   where cdate <= dateadd(dd,-1,cast(getdate() as date))
  */
drop table if exists #payme_f
  select b.max_pay_date
       , a.external_id, a.pay_total
    into #payme_f
    from #payme_a a
    join #payme_d b on a.external_id = b.external_id and a.cdate = b.max_pay_date

drop table if exists #payme
  select a.external_id
       , a.pay_amount_3m
       , b.max_pay_date as last_pay_date
       , b.pay_total as last_pay_amount
   into #payme
   from #payme_b a
   left join #payme_f b on a.external_id = b.external_id


drop table if exists #vibor2
;
with v as (
  select cdate        as r_date
       , a.external_id
       , cast(isnull(principal_cnl,    0) as float) +
				 cast(isnull(percents_cnl,     0) as float) +
				 cast(isnull(fines_cnl,        0) as float) +
				 cast(isnull(otherpayments_cnl,0) as float) +
				 cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
				 row_number() over (partition by cdate, a.external_id order by cast(isnull(total_rest,0) as float) desc) as rn

    from stat_v_balance2 a
    join #clients cl on cl.external_id  =a.external_id
	where cdate <= dateadd(dd,-1,cast(getdate() as date))
)

select *     into #vibor2 from v
where rn=1


  drop table if exists #vibor2_b
  select r_date, external_id, pay_total into #vibor2_b from #vibor2 a where  pay_total > 0


  drop table if exists #pay_behav
  select a.external_id
       , a.r_date
       , sign(sum(case when b.r_date >= dateadd(mm, -2,dateadd(dd,1,eomonth(a.r_date))) and b.r_date < dateadd(mm, -1,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_1
       , sign(sum(case when b.r_date >= dateadd(mm, -3,dateadd(dd,1,eomonth(a.r_date))) and b.r_date < dateadd(mm, -2,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_2
       , sign(sum(case when b.r_date >= dateadd(mm, -4,dateadd(dd,1,eomonth(a.r_date))) and b.r_date < dateadd(mm, -3,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_3
       , sign(sum(case when b.r_date >= dateadd(mm, -7,dateadd(dd,1,eomonth(a.r_date))) and b.r_date < dateadd(mm, -4,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_4_4_6
       , sign(sum(case when b.r_date >= dateadd(mm,-13,dateadd(dd,1,eomonth(a.r_date))) and b.r_date < dateadd(mm, -6,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_4_7_12
       , sign(sum(case when                                                                 b.r_date < dateadd(mm,-13,dateadd(dd,1,eomonth(a.r_date)))  then 1 else 0 end)) as pay_5
    into #pay_behav
    from #vibor2 a
		left join #vibor2_b b on a.external_id = b.external_id
	 where a.rn = 1
	 group by a.external_id, a.r_date




drop table if exists #data_tmp
  select a.external_id
       , b.fio
       , b.birth_date
       , b.credit_date
       , b.credit_amount
       , isnull(a.overdue_days_p,0)              as dpd
       , isnull(b.adress_projivaniya,  'Nan')    as adress_projivaniya
       , isnull(b.adress_registraciyi, 'Nan')    as adress_registraciyi
       , cast(isnull(principal_rest, 0) as float)        as principal_rest
       , cast(isnull(percents_rest, 0) as float)         as percents_rest
       , cast(isnull(fines_rest, 0) as float)            as fines_rest
       , cast(isnull(other_payments_rest, 0) as float)   as other_rest
       , cast(isnull(overdue, 0) as float)               as overdue_amount
       , (case when cast(isnull(total_rest, 0) as float) < cast(isnull(overdue, 0) as float) then cast(isnull(overdue, 0) as float) else cast(isnull(total_rest, 0) as float) end) as total_rest
    into #data_tmp
    from stat_v_balance2 a
    join #clients cl on cl.external_id  =a.external_id
    left join #tbl_f b on a.external_id = b.external_id
   where a.cdate = dateadd(dd,-1,cast(getdate() as date))
     and (case when b.end_date <= dateadd(dd,-1,cast(getdate() as date)) then 1 else 0 end) = 0
     and cast(a.total_rest as float) > 0
   
drop table if exists #fraudsters
select distinct external_id into #fraudsters from fraudsters


drop table if exists #tmp22_a
  select a.Номер as external_id
       , (case when a.ТелефонМобильный = ''                then 'Nan' else a.ТелефонМобильный end)                as [ТелефонМобильный]
       , (case when a.ТелефонСупруги = ''                  then 'Nan' else ТелефонСупруги end)                    as [ТелСупруги]
       , (case when a.ТелефонАдресаПроживания = ''         then 'Nan' else a.ТелефонАдресаПроживания end)         as [ТелефонАдресаПроживания]
       , (case when a.ТелефонКонтактныйОсновной = ''       then 'Nan' else a.ТелефонКонтактныйОсновной end)       as [ТелефонКонтактныйОсновной]
       , (case when a.ТелефонКонтактныйДополнительный = '' then 'Nan' else a.ТелефонКонтактныйДополнительный end) as [ТелефонКонтактныйДополнительный]
       , (case when a.КЛТелМобильный = ''                  then 'Nan' else a.КЛТелМобильный end)                  as [КонтактноеЛицоТелМобильный]
       , (case when a.КЛТелКонтактный = ''                 then 'Nan' else a.КЛТелКонтактный end)                 as [КонтактноеЛицоТелКонтактный]
       , (case when a.ТелМобильныйРуководителя = ''        then 'Nan' else a.ТелМобильныйРуководителя end)        as [ТелМобильныйРуководителя]
       , (case when a.ТелРабочийРуководителя = ''          then 'Nan' else a.ТелРабочийРуководителя end)          as [ТелРабочийРуководителя]
       , (case when a.ЭлектроннаяПочта = ''                then 'Nan' else a.ЭлектроннаяПочта end)                as email
       , row_number() over (partition by a.Номер order by a.Номер) as rn 
    into #tmp22_a
    
    from [prodsql02].[MFO].[dbo].[Документ_ГП_Заявка] a
    join #clients cl on cl.external_id  =a.Номер

drop table if exists #tmp22_b
  select a.external_id
       , max(isnull(overdue_days_p,0)) as max_dpd
    into #tmp22_b
    from stat_v_balance2 a
    join #clients cl on cl.external_id  =a.external_id
   where cdate <= dateadd(dd,-1,cast(getdate() as date))
   group by a.external_id


;
with data_tmp as (select * from #data_tmp)
,payme as (select * from #payme)
,tmp22 as (select a.*,
                         isnull(c.[ТелефонМобильный],                'Nan')      as [ТелефонМобильный],
                         isnull(c.[ТелСупруги],                      'Nan')      as [ТелСупруги],
                         isnull(c.[ТелефонАдресаПроживания],         'Nan')      as [ТелефонАдресаПроживания],
                         isnull(c.[ТелефонКонтактныйОсновной],       'Nan')      as [ТелефонКонтактныйОсновной],
                         isnull(c.[ТелефонКонтактныйДополнительный], 'Nan')      as [ТелефонКонтактныйДополнительный],
                         isnull(c.[КонтактноеЛицоТелМобильный],      'Nan')      as [КонтактноеЛицоТелМобильный],
                         isnull(c.[КонтактноеЛицоТелКонтактный],     'Nan')      as [КонтактноеЛицоТелКонтактный],
                         isnull(c.[ТелМобильныйРуководителя],        'Nan')      as [ТелМобильныйРуководителя],
                         isnull(c.[ТелРабочийРуководителя],          'Nan')      as [ТелРабочийРуководителя],
                                        isnull(c.email,                             'Nan')      as email,
                         (case when b.external_id is not null then 1 else 0 end) as fraud,
                         (case when isnull(d.agent_name, 'CarMoney') in ('ACB','CarMoney') then 0 else 1 end) as agent_flag,
                         isnull(d.agent_name, 'CarMoney')                                                     as agent_name,
                                        e.max_dpd
                  from data_tmp a
                             left join #fraudsters b on a.external_id = b.external_id
                             left join #tmp22_a c on a.external_id = c.external_id and c.rn = 1
                  left join v_agent_credits d on a.external_id = d.external_id and d.st_date <= dateadd(dd,-1,cast(getdate() as date)) and d.end_date >= dateadd(dd,-1,cast(getdate() as date))
                             left join #tmp22_b e on a.external_id = e.external_id)
    , vibor2 as (select * from #vibor2)
    , pay_behav as (select * from #pay_behav)

select a.external_id,
       a.fio,
	   a.birth_date,
	   a.credit_date,
	   a.credit_amount,
       a.fraud as fraud_flag,
       a.agent_flag,
          a.agent_name,
       a.overdue_amount,
       a.principal_rest,
	   a.percents_rest,
	   a.fines_rest,
	   a.other_rest,
       a.total_rest,
       a.dpd,
       a.dpd_bucket,
	   (case when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 1 then '(1)_Regular_(1)_1_from_3'
	         when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 2 then '(1)_Regular_(2)_2_from_3'
	         when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 3 then '(1)_Regular_(3)_3_from_3'
	         when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 0
			  and isnull(b.pay_4_4_6,0)  = 1                                    then '(2)_Non_Regular_(1)_Reanimate_4_6'
	         when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 0
			  and isnull(b.pay_4_4_6,0)  = 0
			  and isnull(b.pay_4_7_12,0) = 1                                    then '(2)_Non_Regular_(2)_Reanimate_7_12'
	         when isnull(b.pay_1,0) + isnull(b.pay_2,0) + isnull(b.pay_3,0) = 0
			  and isnull(b.pay_4_4_6,0)  = 0
			  and isnull(b.pay_4_7_12,0) = 0
			  and isnull(b.pay_5,0)      = 1                                    then '(3)_Lost_12+'
			 else '(4)_No_pay' end)     as pay_beh_seg,
       a.last_pay_date,
       a.last_pay_amount,
       a.adress_projivaniya,
       a.adress_registraciyi,
       a.[ТелефонМобильный],
       a.[ТелСупруги],
       a.[ТелефонАдресаПроживания],
       a.[ТелефонКонтактныйОсновной],
       a.[ТелефонКонтактныйДополнительный],
       a.[КонтактноеЛицоТелМобильный],
       a.[КонтактноеЛицоТелКонтактный],
       a.[ТелМобильныйРуководителя],
       a.[ТелРабочийРуководителя],
       c.tel_1_mts,
       c.tel_2_mts,
       c.tel_3_mts,
       c.tel_4_mts,
       c.tel_5_mts,
       c.tel_6_mts,
       c.tel_7_mts,
       email,
	   z.[МаркаАвто],
	   z.[МодельАвто],
	   z.[РегНомер]
from (select a.*,
             (case when a.dpd >= 4   and a.dpd <= 30  and max_dpd <= 90 then '(1)_4_30'
                   when a.dpd >= 31  and a.dpd <= 60  and max_dpd <= 90 then '(2)_31_60'
                   when a.dpd >= 61  and a.dpd <= 90  and max_dpd <= 90 then '(3)_61_90'
                   when a.dpd >= 91  and a.dpd <= 360                   then '(4)_91_360'
                   when a.dpd >= 360                                    then '(5)_361+'
                   when a.dpd <= 90  and max_dpd > 90                   then '(6)_0_90_hard'
                   else '(7)_Other' end) as dpd_bucket,
             isnull(b.pay_amount_3m,     0) as pay_amount_3m,
             b.last_pay_date,
             isnull(b.last_pay_amount,   0) as last_pay_amount
      from tmp22 a
      left join payme b on a.external_id = b.external_id
         where agent_name in ('ACB', 'CarMoney')) a
left join pay_behav         b on a.external_id = b.external_id and b.r_date = dateadd(dd,-1,cast(getdate() as date))
left join skip_mts_07032019 c on a.external_id = c.external_id
left join [prodsql02].[MFO].[dbo].[Документ_ГП_Заявка] z on a.external_id = z.[Номер]
where a.dpd_bucket <> '(7)_Other' 
  and (case when dpd_bucket in ('(1)_4_30','(2)_31_60','(3)_61_90','(4)_91_360','(5)_361+') and overdue_amount <= 0 then 0 else 1 end) = 1
 

