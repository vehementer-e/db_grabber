	CREATE    proc [dbo].[Продажа трафика Маилян]
	as

begin
	
	--delete from [Продажа трафика Маилян буфер] 
	--return
drop table if exists #fa								
								
select Номер, producttype,   [Первичная сумма],  Телефон, [Вид займа], [Группа каналов], Источник, Отказано, [Регион проживания] , [Ссылка заявка], isPts ,isInstallment , Дубль , ДатаЗаявкиПолная , Аннулировано  , Одобрено , [Заем выдан]  , [Заем аннулирован] into #fa								
from v_fa  a								
where [Верификация КЦ]>=getdate()-60 or [Заем выдан] is not null
					
					

create nonclustered index t on #fa								
(								
Телефон, ДатаЗаявкиПолная, Номер								
)								
								
drop table if exists #t1								
select  Номер, [Первичная сумма], Телефон, [Вид займа], [Группа каналов], Источник , z.Марка , z.Модель, Отказано, [Регион проживания], z.ГодВыпуска				, a.isInstallment				
into #t1								
from #fa  a								
left join								
(								
select a.Ссылка, b.Наименование Марка, c.Наименование Модель, year(dateadd(year, -2000, ГодВыпуска)) ГодВыпуска from								
stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС a								
left join stg._1cCRM.Справочник_МаркиАвтомобилей b on a.МаркаМашины=b.Ссылка								
left join stg._1cCRM.Справочник_МоделиАвтомобилей c on a.Модель=c.ссылка ) z on z.Ссылка=a.[Ссылка заявка]								
								
where Отказано between cast(getdate()-1 as date) and cast(getdate()+1 as date)								
--and Дубль=1								
and producttype='PTS'								
and [Вид займа] = 'Первичный'								
and [Группа каналов] <> 'Партнеры'								
and isnull(Источник, '') not in (								
'devtek'								
,'gidfinance-installment'								
,'bankiru-installment'								
,'bankiru-installment-ref'								
,'gidfinance'								
,'leadcraft-installment-ref'								
,'leadcraft-ref'								
,'unicom24r'								
,'unicom24'								
,'unicom24-installment-ref'								
,'sravniru'								
,'sravniru-installment-ref'								
,'avtolombard-credit' 	
,'avtolombard-credit-ref'
,'psb-ref'
,'vtb-ref'

,'infoseti-deepapi-pts' 
,'infoseti-deepapi-installment' 
,'infoseti'
,'psb-deepapi'


)						
and isnull([Регион проживания], '')
not in
('Москва г'
,'Московская обл'
,'Санкт-Петербург г'
,'Ленинградская обл'
)
  and Отказано>='2025-06-17 16:00:00'


--select distinct [Регион проживания] from   #t1
			
drop table if exists #for_sale
								
;								
								
with v as (								
select a.Телефон, a.[Первичная сумма],a.[Регион проживания], a.Марка, a.Модель, a.ГодВыпуска, a.Номер,  a.Отказано, ROW_NUMBER() over(partition by a.Телефон order by a.Отказано) rn from #t1 a								
outer apply (select top 1 *     from #fa b where b.ДатаЗаявкиПолная between dateadd(day, -5, a.Отказано ) and  dateadd(day, 5, a.Отказано ) and a.Номер<>b.Номер and  a.Телефон=b.Телефон and b.Аннулировано is null and b.[Заем аннулирован] is null and b.Отказано is null ) x								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.[Заем выдан] is not null ) x1								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.Одобрено >=dateadd(day, -30 , a.Отказано) ) x2								
left join Analytics.dbo.mv_loans b on a.Телефон=b.[Основной телефон клиента CRM]								
left join Analytics.dbo.mv_loans b1 on a.Телефон=b1.[Телефон договор CMR]			
left join Analytics.dbo.[Продажа трафика Маилян история] p on p.Телефон=a.Телефон and p.report_d>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.Номер is  null and								
x2.Номер is  null and								
x1.Номер is  null and								
p.Телефон is  null --and								
								
)								
select *, getdate() as report_dt, cast(getdate() as date) report_d into #for_sale from v where rn=1								
order by Отказано								

 

-- delete a from  #for_sale a
--join [Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] b on a.Телефон=b.phonenumber and uf_registered_at>=getdate()-7


select * from #for_sale

if (select count(*) from #for_sale)>0
begin

begin tran
--delete from dbo.[Продажа трафика Маилян история]
--drop table if exists dbo.[Продажа трафика Маилян история]
--select * into  dbo.[Продажа трафика Маилян история] from #for_sale
--select * from  dbo.[Продажа трафика Маилян история] order by [report_dt]

insert into dbo.[Продажа трафика Маилян история] (телефон,[report_dt], [report_d] )
select Телефон, report_dt, report_d  from #for_sale
--select value, getdate(), getdate() from log_telegrams_long
--cross apply string_split(text, char(10) )
--where id='66853008-5AF6-4643-88D3-BEEC51036339'


--order by 1

commit tran


declare @tg_message nvarchar(max) = (select string_agg(Телефон, '
') from #for_sale)

exec [log_telegram] @tg_message, '-1001513711414'


--declare @tg_message nvarchar(max) = (select string_agg(Телефон, '
--') from  dbo.[Продажа трафика Маилян буфер])
--
--exec [log_telegram] @tg_message, '-1001513711414'



begin tran
--delete from dbo.[Продажа трафика Маилян буфер]
--drop table if exists dbo.[Продажа трафика Маилян буфер]
--select * into  dbo.[Продажа трафика Маилян буфер] from #for_sale
delete from dbo.[Продажа трафика Маилян буфер]
insert into dbo.[Продажа трафика Маилян буфер] (телефон,[report_dt], [report_d] )
select Телефон, report_dt, report_d  from #for_sale
commit tran


 



end


if (select count(*) from #for_sale)=0
begin
exec log_email 'Продажа трафика Маилян - не было трафика' , 'P.Ilin@techmoney.ru', 'gmail_mailyan'
end


--delete from dbo.[Продажа трафика Маилян буфер]
--delete from dbo.[Продажа трафика Маилян история] where report_d>getdate()-1


end