

CREATE   proc [_birs].[Регулярные обзвоны Отказы по лидам]

@datefrom date = null,
@dateto date = null

as

begin

declare @datefrom_ date = @datefrom /* cast( getdate() as date)*/
declare @dateto_ date = @dateto /* cast( getdate() as date)*/


drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 



select ДатаЛидаЛСРМ ДатаЛида, 	
	ВремяПоследнегоДозвона ПоследнийЗвонок, 
	UF_RC_REJECT_CM ПричинаОтказа, 
	UF_PHONE Телефон, 
	UF_NAME ФИО, 
	timezone GMT, 
	iif(IsInstallment = 0, 'ПТС','Инстоллмент') IsInstallment,
[Канал от источника],
[Группа каналов]
into #t1
from feodor.dbo.dm_leads_history  (nolock)	
where ДатаЛидаЛСРМ between @datefrom_ and @dateto_ and ФлагОтказКлиента is not null


;with v  as (select *, row_number() over(partition by Телефон order by (select null)) rn from #t1 ) delete from v where rn>1


select a.* from 	 #t1 a
left join #bl b on a.Телефон=b.UF_PHONE 
where b.UF_PHONE is null

end