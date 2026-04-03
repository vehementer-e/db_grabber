

CREATE   proc [_birs].[Регулярные обзвоны База клиентов инстоллмент]

as

begin

drop table if exists #t1

select cdate, birth_date, clientTimeZone, FIO, phone, approved_limit, market_proposal_category_name, phoneInBlackList, case when b.isInstallment =1 then 'Инст'  when b.isInstallment =0 then 'ПТС' else '?' end [последний займ] 

into #t1
from dwh2.marketing.povt_inst	 a
join [Stg]._1cCMR.Справочник_Договоры b on b.код=a.external_id-- and b.[isInstallment последний займ]=1	    
where cdate = cast(getdate() as date) 
--order by [Дата последнего займа] desc


drop table if exists  #bl
select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 



update t
			set phoneInBlackList = 1
		from #t1 t
		where exists(select top(1) 1 from #bl BlackPhoneList where
			BlackPhoneList.UF_PHONE = t.[phone]
			)


			;with v  as (select *, row_number() over(partition by phone order by (select null)) rn from #t1 ) delete from v where rn>1

			select *, analytics.dbo.initcap(FIO) FIO_init_cap
, '8'+phone phone8
 from #t1
--where phoneInBlackList =0

end