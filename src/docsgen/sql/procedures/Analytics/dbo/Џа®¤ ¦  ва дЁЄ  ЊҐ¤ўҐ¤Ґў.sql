
CREATE          proc [dbo].[Продажа трафика Медведев]
as

begin
	
drop table if exists #fa								
								
select Номер,   [Первичная сумма],  Телефон, [Вид займа], [Группа каналов], Источник, Отказано, [Регион проживания] , [Ссылка заявка], isInstallment , Дубль , ДатаЗаявкиПолная , Аннулировано  , Одобрено , [Заем выдан]  , [Заем аннулирован] into #fa								
from reports.dbo.dm_Factor_Analysis_001  a								
								
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
and Отказано>=   dateadd(hour, 15, cast(cast(getdate() as date) as datetime2))
--and Дубль=1								
and isInstallment=0								
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
, 'avtolombard-credit'
,'avtolombard-credit-ref'

)						
and [Регион проживания]
in
('Москва г'
,'Московская обл'
--,'Санкт-Петербург г'
--,'Ленинградская обл'
)
--select distinct [Регион проживания] from   #t1
				


--select cast(getdate()-2 as date)								
								
drop table if exists #for_sale
								
;								
								
with v as (								
select a.Телефон, a.[Первичная сумма],a.[Регион проживания], a.Марка, a.Модель, a.ГодВыпуска, a.Номер,  a.Отказано, ROW_NUMBER() over(partition by a.Телефон order by a.Отказано desc) rn
, a.isInstallment

from #t1 a								
outer apply (select top 1 *     from #fa b where b.ДатаЗаявкиПолная between dateadd(day, -5, a.Отказано ) and  dateadd(day, 5, a.Отказано ) and a.Номер<>b.Номер and  a.Телефон=b.Телефон and b.Аннулировано is null and b.[Заем аннулирован] is null and b.Отказано is null ) x								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.[Заем выдан] is not null ) x1								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.Одобрено >=dateadd(day, -30 , a.Отказано) ) x2								
left join Analytics.dbo.mv_loans b on a.Телефон=b.[Основной телефон клиента CRM]								
left join Analytics.dbo.mv_loans b1 on a.Телефон=b1.[Телефон договор CMR]			
left join Analytics.dbo.[Продажа трафика Медведев история] p on p.Телефон=a.Телефон and p.report_d>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.Номер is  null and								
x2.Номер is  null and								
x1.Номер is  null 	and								
p.Телефон is  null 							
								
)								
select Телефон,  getdate() as report_dt, cast(getdate() as date) report_d  into #for_sale from v where rn=1								
order by Отказано								


--delete a from  #for_sale a
--join [log_telegrams_long dt>='20230624'	and dt<='2023-06-26 12:00:00'] b on a.Телефон=b.value

delete a from  #for_sale a
join [Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] b on a.Телефон=b.phonenumber and uf_registered_at>=getdate()-7




if (select count(*) from #for_sale)>0
begin

begin tran
--delete from dbo.[Продажа трафика Медведев история]
--drop table if exists dbo.[Продажа трафика Медведев история]
--select * into  dbo.[Продажа трафика Медведев история] from  dbo.[Продажа трафика Московский капитал история]

insert into dbo.[Продажа трафика Медведев история]
select * from #for_sale

commit tran

declare @tg_message nvarchar(max) = (select string_agg(Телефон, '
') from #for_sale)
exec [log_telegram] @tg_message, '-1001824547809'
--exec [log_telegram] 'test', '-1001824547809'

begin tran
--delete from dbo.[Продажа трафика Медведев буфер]
--drop table if exists dbo.[Продажа трафика Медведев буфер]
--select * into  dbo.[Продажа трафика Медведев буфер] from [Продажа трафика Медведев буфер]
delete from dbo.[Продажа трафика Медведев буфер]
insert into dbo.[Продажа трафика Медведев буфер]
select * from #for_sale

commit tran


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'DE912951-6F0F-4BFC-9CDC-7446DBAE536E'

end



if (select count(*) from #for_sale)=0
begin
exec log_email 'Продажа трафика Медведев - не было трафика' , 'P.Ilin@techmoney.ru', 'gmail_medvedev'
end


end
