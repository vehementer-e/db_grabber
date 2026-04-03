--Распределение заявок по категориям отказов чекеров

create   procedure [dbo].[request_distribtion_by_cat_of_rej]
as
--выборка заявок Call 1.5
drop table if exists #r
select distinct number, requestdate,
	loginom_call1_5_date, loginom_call1_5_decision, loginom_call1_5_decision_code,
	cast(year(loginom_call1_5_date) as varchar)+'_'+cast(month(loginom_call1_5_date) as varchar) as month_call1_5
into #r
from [RiskDWH].[dbo].[fedor_report]
where requestdate>'20200920' and loginom_call1_5_date is not null

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
select B.[Канал от источника], B.[Группа каналов], B.Представление, B.UF_ROW_ID into #cnl from stg.dbo.lcrm_tbl_full_w_chanals2 B  with (nolock) where UF_ROW_ID is not null and B.UF_REGISTERED_AT >'20200920'

drop table if exists #r3
-- + источник и канал заведения
select ank.*,
B.[Канал от источника], B.[Группа каналов], B.Представление 
into #r3 
from #r2 ank
left join #cnl B 
on cast(ank.number as nvarchar(28))=B.UF_ROW_ID collate SQL_Latin1_General_CP1_CI_AS

create table #dcat(code varchar(255),name varchar(max),caregory varchar(max));
insert into #dcat values('100.0101.002','5 Подозрение на подделку документов/фотошоп/непрофильные фото','2. Документы подделка/фрод');
insert into #dcat values('100.0101.003','6 Расхождение данных в документах','1. Документы отсутствуют или плохие');
insert into #dcat values('100.0101.004','7 Документы недействительны, требуют замены','1. Документы отсутствуют или плохие');
insert into #dcat values('100.0102.002','8 ПТС взамен утраченного/утерянного менее 45 дней назад','1. Документы отсутствуют или плохие');
insert into #dcat values('100.0103.002','2 Не соответствует требваниям по продутку','5. Минимальные требования по клиенту');
insert into #dcat values('100.0103.003','3 Некорректный VIN, номер кузова в ПТС','6. Минимальные требования по авто');
insert into #dcat values('100.0103.004','4 Авто не подходит под условия займа. Коммерческий транспорт (желтые номера)','6. Минимальные требования по авто');
insert into #dcat values('100.0103.005','9Клиент не подходит под условия рефинансирования.','4. Не подходит под условия продукта "Рефин"');
insert into #dcat values('100.0103.006','5 Отечественные авто/B более 7 лет','6. Минимальные требования по авто');
insert into #dcat values('100.0103.007','6 Иностанные авто /B более 20 лет','6. Минимальные требования по авто');
insert into #dcat values('100.0103.008','7 Газель, Соболь (грузовая) категории В более 11 лет','6. Минимальные требования по авто');
insert into #dcat values('100.0103.009','8  Клиент не является собственником авто но требуется по продукту','5. Минимальные требования по клиенту');
insert into #dcat values('100.0103.015','15 Не подходит под условия продукта исптытательный срок','3. Не подходит под условия продукта "Исп.срок"');
insert into #dcat values('100.0103.016','Отсутствует регистрация клиента','5. Минимальные требования по клиенту');
insert into #dcat values('100.0107.002','Дата выпуска авто','6. Минимальные требования по авто');
insert into #dcat values('100.0108.002','Собственник авто','5. Минимальные требования по клиенту');
insert into #dcat values('100.0109.002','3 Прописка нет /Фактический да (не соответствует списку регионов расширения )','5. Минимальные требования по клиенту');
insert into #dcat values('100.0109.004','4 Прописка нет/Фактический нет','5. Минимальные требования по клиенту');
insert into #dcat values('100.0109.005','5 Прописка да /Фактический нет','5. Минимальные требования по клиенту');
insert into #dcat values('100.0109.006','6 Отсутствует регистрация клиента','1. Документы отсутствуют или плохие');
insert into #dcat values('100.0110.002','2 Регион проживания клиента отсутствует в списке допустимых','3. Не подходит под условия продукта "Исп.срок"');
insert into #dcat values('100.0110.003','3 Регион авто не соответствует региону прописки клиента','3. Не подходит под условия продукта "Исп.срок"');
insert into #dcat values('100.0110.004','4 Авто не соответствует списку допустимых по продукту','3. Не подходит под условия продукта "Исп.срок"');


drop table if exists [RiskDWH].dbo.tmp_report_requests
--Финальный отбор полей
select month_call1_5, наименование as [ФИО сотрудника], 
case	when [Группа каналов]='CPA' then [Канал от источника]
			when [Группа каналов]='CPC' then [Группа каналов]
			when [Группа каналов]='Органика' then [Группа каналов]
			when [Группа каналов]='Партнеры' then [Группа каналов]
			else 'ДРУГОЕ'
		   end as [Канал],
представление as [Источник] , дубль, loginom_call1_5_decision, loginom_call1_5_decision_code as [код отказа],
c.name,
c.caregory,
count(distinct number) as cnt
into [RiskDWH].dbo.tmp_report_requests
from #r3 r
left join #dcat c on c.code = r.loginom_call1_5_decision_code
group by month_call1_5, наименование, 
case	when [Группа каналов]='CPA' then [Канал от источника]
			when [Группа каналов]='CPC' then [Группа каналов]
			when [Группа каналов]='Органика' then [Группа каналов]
			when [Группа каналов]='Партнеры' then [Группа каналов]
			else 'ДРУГОЕ'
		   end ,
представление, дубль, loginom_call1_5_decision, loginom_call1_5_decision_code,c.name,
c.caregory
order by 1