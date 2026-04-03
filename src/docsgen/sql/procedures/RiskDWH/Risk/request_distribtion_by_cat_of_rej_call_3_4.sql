

--Распределение заявок по категориям отказов чекеров
--exec [Reports].[Risk].[request_distribtion_by_cat_of_rej_call_3_4]
CREATE procedure [Risk].[request_distribtion_by_cat_of_rej_call_3_4]
as
--выборка заявок Call 3 и 4
drop table if exists #r
select distinct number, requestdate,
	loginom_call3_date, loginom_call3_decision, loginom_call3_decision_code,
	cast(year(loginom_call3_date) as varchar)+'_'+cast(month(loginom_call3_date) as varchar) as month_call3
	-- call 4
	,
	loginom_call4_date, loginom_call4_decision, loginom_call4_decision_code,
	cast(year(loginom_call4_date) as varchar)+'_'+cast(month(loginom_call4_date) as varchar) as month_call4
	-- последний
	, loginom_call_date = isnull(loginom_call4_date,loginom_call3_date)
	, loginom_call_decision = isnull(loginom_call4_decision, loginom_call3_decision)
	, loginom_call_decision_code = isnull(loginom_call4_decision_code, loginom_call3_decision_code)
	, month_call = isnull(cast(year(loginom_call4_date) as varchar)+'_'+cast(month(loginom_call4_date) as varchar) , cast(year(loginom_call3_date) as varchar)+'_'+cast(month(loginom_call3_date) as varchar))

into #r
from [RiskDWH].[dbo].[fedor_report_extended]
where requestdate>'20200920' and (loginom_call3_date is not null or loginom_call4_date is not null)

--select * from #r
--where loginom_call_decision = 'Decline'

drop table if exists #r2
-- + данные о сотруднике, признак Дубля
select ank.*, n.*, F.Дубль
into #r2
from #r ank
left join 
	(select z.[Номер], z.[CRM_Автор], p.adLogin, p.Наименование 
	from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
	left join stg._1cCRM.Справочник_Пользователи p
	on p.Ссылка=z.CRM_Автор) n
on cast(ank.number as nvarchar(14)) = n.[Номер] collate SQL_Latin1_General_CP1_CI_AS
left join
	(select distinct Номер, Дубль  FROM [Reports].[dbo].[dm_Factor_Analysis_001]) F
on ank.number=F.[Номер] collate SQL_Latin1_General_CP1_CI_AS

drop table if exists #cnl
select B.[Канал от источника], B.[Группа каналов], B.Представление, B.UF_ROW_ID into #cnl 
--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
--from stg.dbo.lcrm_tbl_full_w_chanals2 B 
from Stg._LCRM.lcrm_leads_full_calculated AS B (NOLOCK)
where B.UF_ROW_ID is not null and B.UF_REGISTERED_AT >'20200920'

drop table if exists #r3
-- + источник и канал заведения
select ank.*,
B.[Канал от источника], B.[Группа каналов], B.Представление 
into #r3 
from #r2 ank
left join #cnl B 
on cast(ank.number as nvarchar(28))=B.UF_ROW_ID collate SQL_Latin1_General_CP1_CI_AS


drop table if exists  #dcat
create table #dcat(code varchar(255),name varchar(max),caregory varchar(max));
--insert into #dcat values('100.0101.002','5 Подозрение на подделку документов/фотошоп/непрофильные фото','2. Документы подделка/фрод');
--insert into #dcat values('100.0101.003','6 Расхождение данных в документах','1. Документы отсутствуют или плохие');
--insert into #dcat values('100.0101.004','7 Документы недействительны, требуют замены','1. Документы отсутствуют или плохие');
--insert into #dcat values('100.0102.002','8 ПТС взамен утраченного/утерянного менее 45 дней назад','1. Документы отсутствуют или плохие');
--insert into #dcat values('100.0103.002','2 Не соответствует требваниям по продутку','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0103.003','3 Некорректный VIN, номер кузова в ПТС','6. Минимальные требования по авто');
--insert into #dcat values('100.0103.004','4 Авто не подходит под условия займа. Коммерческий транспорт (желтые номера)','6. Минимальные требования по авто');
--insert into #dcat values('100.0103.005','9Клиент не подходит под условия рефинансирования.','4. Не подходит под условия продукта "Рефин"');
--insert into #dcat values('100.0103.006','5 Отечественные авто/B более 7 лет','6. Минимальные требования по авто');
--insert into #dcat values('100.0103.007','6 Иностанные авто /B более 20 лет','6. Минимальные требования по авто');
--insert into #dcat values('100.0103.008','7 Газель, Соболь (грузовая) категории В более 11 лет','6. Минимальные требования по авто');
--insert into #dcat values('100.0103.009','8  Клиент не является собственником авто но требуется по продукту','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0103.015','15 Не подходит под условия продукта исптытательный срок','3. Не подходит под условия продукта "Исп.срок"');
--insert into #dcat values('100.0103.016','Отсутствует регистрация клиента','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0107.002','Дата выпуска авто','6. Минимальные требования по авто');
--insert into #dcat values('100.0108.002','Собственник авто','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0109.002','3 Прописка нет /Фактический да (не соответствует списку регионов расширения )','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0109.004','4 Прописка нет/Фактический нет','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0109.005','5 Прописка да /Фактический нет','5. Минимальные требования по клиенту');
--insert into #dcat values('100.0109.006','6 Отсутствует регистрация клиента','1. Документы отсутствуют или плохие');
--insert into #dcat values('100.0110.002','2 Регион проживания клиента отсутствует в списке допустимых','3. Не подходит под условия продукта "Исп.срок"');
--insert into #dcat values('100.0110.003','3 Регион авто не соответствует региону прописки клиента','3. Не подходит под условия продукта "Исп.срок"');
--insert into #dcat values('100.0110.004','4 Авто не соответствует списку допустимых по продукту','3. Не подходит под условия продукта "Исп.срок"');
insert into #dcat values('100.0201.002','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0201.003','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0201.004','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0201.005','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0201.006','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0201.008','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0202.003','НЕГАТИВНАЯ КИ','НЕГАТИВНАЯ КИ');
insert into #dcat values('100.0203.001','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0203.002','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0204.002','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0205.002','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.002','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.004','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.005','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.006','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.007','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0206.008','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0208.002','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0208.003','МОБ ТЕЛ НЕ ПРИНАДЛЕЖИТ КЛИЕНТУ - ПЕРЕЗАВЕДЕНИЕ ЗАЯВКИ','МОБ ТЕЛ НЕ ПРИНАДЛЕЖИТ КЛИЕНТУ - ПЕРЕЗАВЕДЕНИЕ ЗАЯВКИ');
insert into #dcat values('100.0208.004','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0208.005','ОТКАЗ КЛИЕНТА','ОТКАЗ КЛИЕНТА');
insert into #dcat values('100.0208.006','КРЕДИТ ДЛЯ ТРЕТЬИХ ЛИЦ','КРЕДИТ ДЛЯ ТРЕТЬИХ ЛИЦ');
insert into #dcat values('100.0208.008','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0208.009','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0210.004','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0210.005','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0210.006','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0211.002','ПРОЧЕЕ','ПРОЧЕЕ');
insert into #dcat values('100.0211.004','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0211.007','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0212.001','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0213.001','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0213.002','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0213.003','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0213.004','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0213.006','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0213.007','ОТКАЗ В ТЕЧЕНИЕ ПОСЛЕДНИХ 7 ДНЕЙ','ОТКАЗ В ТЕЧЕНИЕ ПОСЛЕДНИХ 7 ДНЕЙ');
insert into #dcat values('100.0213.008','НЕ ПОДХОДИТ ПОД УСЛОВИЯ КРЕДИТОВАНИЯ','НЕ ПОДХОДИТ ПОД УСЛОВИЯ КРЕДИТОВАНИЯ');
insert into #dcat values('100.0214.001','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0214.004','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0214.005','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ');
insert into #dcat values('100.0215.002','ПРОЧЕЕ','ПРОЧЕЕ');
insert into #dcat values('100.0216.006','ПРОЧЕЕ','ПРОЧЕЕ');
insert into #dcat values('100.0218.001','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0218.002','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0221.002','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ');
insert into #dcat values('100.0221.003','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ','ИСПЫТАТЕЛЬНЙ СРОК: НЕ ПОДХОДИТ ПОД УСЛОВИЯ');
insert into #dcat values('100.0301.002','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0301.003','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0301.004','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0301.005','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)','АВТО (ПОВРЕЖДЕНИЯ, ЗАЛОГ, ОГРАНИЧЕНИЯ, НЕЛИКВИД)');
insert into #dcat values('100.0302.001','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0302.002','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0302.003','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0302.005','НЕГАТИВНАЯ ИНФО','НЕГАТИВНАЯ ИНФО');
insert into #dcat values('100.0302.006','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0302.007','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0216.007','НЕ ПОДХОДИТ ПОД УСЛОВИЯ КРЕДИТОВАНИЯ','НЕ ПОДХОДИТ ПОД УСЛОВИЯ КРЕДИТОВАНИЯ');
insert into #dcat values('100.0301.006','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0302.008','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ','ПРОТИВОРЕЧИВАЯ ИНФО, ПОДОЗРЕНИЕ В МОШЕННИЧЕСТВЕ');
insert into #dcat values('100.0130.001','АВТОМАТИЧЕСКИЙ ОТКАЗ','АВТОМАТИЧЕСКИЙ ОТКАЗ');
insert into #dcat values('100.0130.003','АВТОМАТИЧЕСКИЙ ОТКАЗ','АВТОМАТИЧЕСКИЙ ОТКАЗ');
insert into #dcat values('100.0130.020','АВТОМАТИЧЕСКИЙ ОТКАЗ','АВТОМАТИЧЕСКИЙ ОТКАЗ');
insert into #dcat values('100.0130.040','АВТОМАТИЧЕСКИЙ ОТКАЗ','АВТОМАТИЧЕСКИЙ ОТКАЗ');



--select * from #dcat

 --select * from [RiskDWH].dbo.tmp_report_requests where [код отказа] = '100.0213.007'
 --select * from [devdb].dbo.tmp_report_requests_call4 where [код отказа] = '100.0213.007'

--drop table if exists [RiskDWH].dbo.tmp_report_requests
drop table if exists [reports].Risk.dm_report_requests_call_3_4
--Финальный отбор полей
select month_call, наименование as [ФИО сотрудника], 
case	when [Группа каналов]='CPA' then [Канал от источника]
			when [Группа каналов]='CPC' then [Группа каналов]
			when [Группа каналов]='Органика' then [Группа каналов]
			when [Группа каналов]='Партнеры' then [Группа каналов]
			else 'ДРУГОЕ'
		   end as [Канал],
isnull(представление, 'Н/Д') as [Источник] , дубль, loginom_call_decision, loginom_call_decision_code as [код отказа],
c.name,
caregory = iif(len(loginom_call_decision_code) > 0, isnull(c.caregory, 'ПРОЧЕЕ'),
c.caregory),
count(distinct number) as cnt
--into [RiskDWH].dbo.tmp_report_requests
into [reports].Risk.dm_report_requests_call_3_4
from #r3 r
left join #dcat c on c.code = r.loginom_call_decision_code
group by month_call, наименование, 
case	when [Группа каналов]='CPA' then [Канал от источника]
			when [Группа каналов]='CPC' then [Группа каналов]
			when [Группа каналов]='Органика' then [Группа каналов]
			when [Группа каналов]='Партнеры' then [Группа каналов]
			else 'ДРУГОЕ'
		   end ,
представление, дубль, loginom_call_decision, loginom_call_decision_code,c.name,
c.caregory
order by 1

