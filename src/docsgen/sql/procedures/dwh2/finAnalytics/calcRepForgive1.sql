

CREATE PROCEDURE [finAnalytics].[calcRepForgive1]
	@repmonth date

AS
BEGIN

declare @dateFrom datetime = cast(DATEADD(year,2000,@repmonth) as datetime)
declare @dateToTMP datetime = dateadd(DAY,1,cast(DATEADD(year,2000,eomonth(@repmonth)) as datetime))
declare @dateTo datetime = dateadd(SECOND,-1,@dateToTMP)
--select * from Stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a where a.Период between @dateFrom and @dateTo

DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc


DROP TABLE IF EXISTS #prov

select
repmonth = @repmonth
, Dt = Dt.Код
, Kt = Kt.Код
,[dogNum] = isnull(crkt.Номер,dc.Номер)
--,[dogNumPBR] = pbr.dogNum
,[nomenkGR] = /*case when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%основной%')
					or  upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%ПТС31%')
					or  upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%Рефинансирование%') then 'ПТС'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%installment%') then 'IL'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%PDL%') then 'PDL'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%бизнес%займ%') then 'БЗ'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%Автокредит%') then 'Автокредит'
				   else '-' end*/
			  --case when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'ПТС' then 'ПТС'
				 --  when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Installment' then 'IL'
				 --  when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'PDL' then 'PDL'
				 --  when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Бизнес-займ' then 'БЗ'
				 --  when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Автокредит' then 'Автокредит'
				 --  else 'ПТС' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Бизнес-займ' then 'БЗ'
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Installment' then 'IL'
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) end

				
,subconto = sp1.Наименование
,sumBU = a.Сумма
--,sumNU = a.СуммаНУДт
,nazn = a.Содержание
,a.СубконтоCt1_Ссылка
,a.СубконтоCt2_Ссылка
,a.СубконтоCt3_Ссылка
,a.СубконтоDt1_Ссылка
,a.СубконтоDt2_Ссылка
,a.СубконтоDt3_Ссылка
,a.Регистратор_Ссылка

into #prov

from Stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomKT on crkt.АЭ_НоменклатурнаяГруппа=nomkT.Ссылка and nomKT.ПометкаУдаления=0x00
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dc on a.СубконтоCt2_Ссылка=dc.Ссылка
--left join finAnalytics.PBR_MONTHLY pbr on isnull(crkt.Номер,dc.Номер)=pbr.dogNum and pbr.repmonth=@repmonth
left join 
(select
dognum
,nomenkGroup
,[rn] = row_number() over (Partition by dognum order by repmonth desc)
from dwh2.finAnalytics.PBR_MONTHLY) pbr on isnull(crkt.Номер,dc.Номер)=pbr.dogNum and pbr.rn =1

left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sp1 on a.СубконтоDt1_Ссылка=sp1.Ссылка and sp1.ПометкаУдаления=0x00



where 1=1
--and a.Регистратор_Ссылка=0xA3050050568397CF11EFBB77A7D5F99E
and a.Период between @dateFrom and @dateTo
and a.Активность=0x01
and (
	Dt.Код = '71001' and Kt.Код='49402'
	or
	Dt.Код = '71001' and Kt.Код='48802'
	or
	Dt.Код = '71001' and Kt.Код='48702'
	or
	Dt.Код = '71701' and Kt.Код='60323'
	or
	Dt.Код = '71802' and Kt.Код='48801'
	or
	Dt.Код = '71802' and Kt.Код='60323'
	or
	Dt.Код = '71802' and Kt.Код='48802'
)
and sp1.Наименование IN (
'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)'
,'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)'
,'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
)


DROP TABLE IF EXISTS #rep1
CREATE TABLE #rep1	(
	repmonth date not null,
	subconto varchar(500) not null,
	dt varchar(10) not null,
	kt varchar(10) not null,
	nomenkGR varchar(50) not null,
	sumAmount money not null,
	rowNum int not Null,
	colNum int not Null
	)


insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'Всего', 0 ,1 ,1
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'Всего', 0 ,2 ,1
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'Всего', 0 ,3 ,1
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'Всего', 0 ,4 ,1
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'Всего', 0 ,5 ,1
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'Всего', 0 ,6 ,1
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'Всего', 0 ,7 ,1
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'Всего', 0 ,8 ,1
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'Всего', 0 ,9 ,1
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'Всего', 0 ,10 ,1

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'ПТС', 0 ,1 ,2
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'ПТС', 0 ,2 ,2
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'ПТС', 0 ,3 ,2
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'ПТС', 0 ,4 ,2
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'ПТС', 0 ,5 ,2
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'ПТС', 0 ,6 ,2
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'ПТС', 0 ,7 ,2
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'ПТС', 0 ,8 ,2
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'ПТС', 0 ,9 ,2
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'ПТС', 0 ,10 ,2

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'IL', 0 ,1 ,3
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'IL', 0 ,2 ,3
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'IL', 0 ,3 ,3
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'IL', 0 ,4 ,3
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'IL', 0 ,5 ,3
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'IL', 0 ,6 ,3
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'IL', 0 ,7 ,3
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'IL', 0 ,8 ,3
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'IL', 0 ,9 ,3
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'IL', 0 ,10 ,3

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'PDL', 0 ,1 ,4
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'PDL', 0 ,2 ,4
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'PDL', 0 ,3 ,4
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'PDL', 0 ,4 ,4
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'PDL', 0 ,5 ,4
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'PDL', 0 ,6 ,4
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'PDL', 0 ,7 ,4
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'PDL', 0 ,8 ,4
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'PDL', 0 ,9 ,4
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'PDL', 0 ,10 ,4

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'БЗ', 0 ,1 ,7
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'БЗ', 0 ,2 ,7
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'БЗ', 0 ,3 ,7
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'БЗ', 0 ,4 ,7
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'БЗ', 0 ,5 ,7
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'БЗ', 0 ,6 ,7
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'БЗ', 0 ,7 ,7
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'БЗ', 0 ,8 ,7
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'БЗ', 0 ,9 ,7
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'БЗ', 0 ,10 ,7

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'Автокредит', 0 ,1 ,5
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'Автокредит', 0 ,2 ,5
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'Автокредит', 0 ,3 ,5
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'Автокредит', 0 ,4 ,5
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'Автокредит', 0 ,5 ,5
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'Автокредит', 0 ,6 ,5
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'Автокредит', 0 ,7 ,5
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'Автокредит', 0 ,8 ,5
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'Автокредит', 0 ,9 ,5
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'Автокредит', 0 ,10 ,5

insert into #rep1 select @repmonth, 'Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)', '71001', '49402', 'Big Installment', 0 ,1 ,6
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)', '71001', '48802', 'Big Installment', 0 ,2 ,6
insert into #rep1 select @repmonth, 'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)', '71001', '48702', 'Big Installment', 0 ,3 ,6
insert into #rep1 select @repmonth, 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)', '71701', '60323', 'Big Installment', 0 ,4 ,6
insert into #rep1 select @repmonth, 'Штрафы и пени по займам предоставленным (52402 сч.71701)', '71701', '60323', 'Big Installment', 0 ,5 ,6
insert into #rep1 select @repmonth, 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)', '71701', '60323', 'Big Installment', 0 ,6 ,6
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48801', 'Big Installment', 0 ,7 ,6
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '60323', 'Big Installment', 0 ,8 ,6
insert into #rep1 select @repmonth, 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)', '71802', '48802', 'Big Installment', 0 ,9 ,6
insert into #rep1 select @repmonth, 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)', '71802', '48802', 'Big Installment', 0 ,10 ,6


MERGE INTO #rep1 t1
using(
select
repmonth = @repmonth
,subconto = a.subconto
,dt = a.dt
,kt = a.kt
,nomenkGR = 'Всего'
,sumAmount = SUM(a.sumBU)

from #prov a
group by 
subconto
,dt
,kt

union all

select
repmonth = @repmonth
,subconto = a.subconto
,dt = a.dt
,kt = a.kt
,nomenkGR = a.nomenkGR
,sumAmount = SUM(a.sumBU)

from #prov a
group by 
subconto
,dt
,kt
,nomenkGR
) t2 on (t1.repmonth=t2.repmonth and t1.subconto=t2.subconto and t1.nomenkGR=t2.nomenkGR and t1.dt=t2.dt and t1.kt=t2.kt)
when matched then update
set t1.sumAmount=t2.sumAmount;


insert into #rep1
select 
repmonth,
subconto,
dt,
kt,
nomenkGR = 'Контроль',
sumAmount = SUM(case when nomenkGR!= 'Всего' then sumAmount*-1 else sumAmount end),
rowNum,
colNum = 8
from #rep1
group by 
repmonth,
subconto,
dt,
kt,
rowNum


Delete from finAnalytics.repForgive1 where repmonth = @repmonth
Insert into finAnalytics.repForgive1
(repmonth, subconto, dt, kt, nomenkGR, sumAmount, rowNum, colNum)

select 
repmonth,
subconto,
dt,
kt,
nomenkGR,
sumAmount,
rowNum,
colNum
from #rep1

--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END
