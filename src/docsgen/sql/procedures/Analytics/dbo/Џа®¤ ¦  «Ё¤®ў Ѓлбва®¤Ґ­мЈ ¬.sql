	CREATE       proc [dbo].[Продажа лидов Быстроденьгам]
	as

begin
	
drop table if exists #mv_loans
select [Телефон договор CMR], [Основной телефон клиента CRM], [Ссылка договор CMR] into #mv_loans from mv_loans
							
drop table if exists #fa								
								
select Номер,   [Первичная сумма],  Телефон, [Вид займа], [Группа каналов], Источник, Отказано, [Регион проживания] , [Ссылка заявка], isInstallment , Дубль , ДатаЗаявкиПолная , Аннулировано  , Одобрено , [Заем выдан]  , [Заем аннулирован] into #fa								
from reports.dbo.dm_Factor_Analysis_001  a								
								
create nonclustered index t on #fa								
(								
Телефон, ДатаЗаявкиПолная, Номер								
)								
	

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_TYPE] [varchar](128) NULL,
	[UF_SOURCE] [varchar](128) NULL,
	[UF_LOGINOM_PRIORITY] [int] NULL,
	[UF_LOGINOM_STATUS] [varchar](128) NULL,
	[UF_LOGINOM_DECLINE] [varchar](128) NULL,
	[Канал от источника] [nvarchar](255) NULL,
	[Группа каналов] [nvarchar](255) NULL,
	
)

-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = getdate()-1 , @End_Registered = getdate()


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message

drop table if exists #t1

select [PhoneNumber] Телефон, id , UF_REGISTERED_AT into #t1 from #TMP_leads
where UF_SOURCE not in 
(
'devtek'
,'devtek-installment-ref'
,'gidfinance-installment'
,'bankiru-installment'
,'bankiru-installment-ref'
,'gidfinance'
,'leadcraft-installment-ref'
,'leadcraft-ref'
,'unicom24'
,'unicom24r'
,'unicom24-installment-ref'
,'sravniru'
,'sravniru-installment-ref'
,'avtolombard-credit'
,'avtolombard-credit-ref'
) and [Группа каналов]<>'Партнеры'
and left([UF_LOGINOM_DECLINE], 4) in
(
 'D001'
,'D002'
,'D007'
,'D015'
,'D016'
,'D017' )
and analytics.[dbo].[lcrm_is_inst_lead] (uf_type, uf_source, UF_LOGINOM_priority)=1


;with v as (
select * , row_number() over (partition by Телефон order by UF_REGISTERED_AT) rn from #t1 ) delete from v where rn>1

drop table if exists #for_sale
								
;								
								
with v as (								
select a.Телефон ,a.id  ,a.UF_REGISTERED_AT 

from #t1 a								
outer apply (select top 1 *     from #fa b where b.ДатаЗаявкиПолная between dateadd(day, -5, a.UF_REGISTERED_AT ) and  dateadd(day, 5, a.UF_REGISTERED_AT ) and a.Телефон=b.Телефон and b.Аннулировано is null and b.[Заем аннулирован] is null and b.Отказано is null ) x								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.[Заем выдан] is not null ) x1								
outer apply (select top 1 Номер from #fa b where a.Телефон=b.Телефон and  b.Одобрено >=dateadd(day, -30 , a.UF_REGISTERED_AT) ) x2								
left join #mv_loans b on a.Телефон=b.[Основной телефон клиента CRM]								
left join #mv_loans b1 on a.Телефон=b1.[Телефон договор CMR]			
left join Analytics.dbo.[Продажа лидов Быстроденьгам история] p on p.Телефон=a.Телефон and p.report_d>=cast(getdate()-1 as date)

where								
b.[Ссылка договор CMR] is  null and								
b1.[Ссылка договор CMR] is  null and								
x.Номер is  null and								
x2.Номер is  null and								
x1.Номер is  null 	
and p.Телефон is  null 							
								
)								
select Телефон , UF_REGISTERED_AT, id,  getdate() as report_dt, cast(getdate() as date) report_d  into #for_sale from v --where rn=1								


--select * from dbo.[Продажа лидов Быстроденьгам история]
--where report_d>=cast(getdate()-1 as date)
--order by Отказано desc



--delete a from  #for_sale a
--join [log_telegrams_long dt>='20230624'	and dt<='2023-06-26 12:00:00'] b on a.Телефон=b.value


delete a from  #for_sale a
join [Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] b on a.Телефон=b.phonenumber and b.uf_registered_at>=getdate()-7


begin tran
--delete from dbo.[Продажа лидов Быстроденьгам история]
--drop table if exists dbo.[Продажа лидов Быстроденьгам история]
--select * into  dbo.[Продажа лидов Быстроденьгам история] from #for_sale

insert into dbo.[Продажа лидов Быстроденьгам история]
select * from #for_sale

commit tran

--alter table dbo.[Продажа лидов Быстроденьгам история]
--add  [Отказ ФССП] int


begin tran
--delete from dbo.[Продажа лидов Быстроденьгам буфер]
--drop table if exists dbo.[Продажа лидов Быстроденьгам буфер]
--select * into  dbo.[Продажа лидов Быстроденьгам буфер] from #for_sale
delete from dbo.[Продажа лидов Быстроденьгам буфер]
insert into dbo.[Продажа лидов Быстроденьгам буфер]
select * from #for_sale

commit tran

--select * from dbo.[Продажа лидов Быстроденьгам буфер]
--select * from dbo.[Продажа лидов Быстроденьгам история]

--/SalesDepartment/Продажа трафика/Sales. Продажа лидов Быстроденьгам
--Рассылка отчета
--36c6e0d4-4c7b-438a-b27b-600daf402f15
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '36C6E0D4-4C7B-438A-B27B-600DAF402F15'
--/SalesDepartment/Продажа трафика/Sales. Продажа лидов Быстроденьгам
--Публикация в sftp
--5a88d5f8-405f-4589-9ce6-1792963ae21a
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '5A88D5F8-405F-4589-9CE6-1792963AE21A'



exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '36C6E0D4-4C7B-438A-B27B-600DAF402F15'

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '5A88D5F8-405F-4589-9CE6-1792963AE21A'
end