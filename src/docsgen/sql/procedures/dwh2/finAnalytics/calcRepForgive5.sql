





CREATE PROCEDURE [finAnalytics].[calcRepForgive5]
	@repmonth date

AS
BEGIN

DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

delete from finAnalytics.repForgive5 where repmonth = @repmonth

-------------------Все продукты
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Все продукты'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Все продукты'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Все продукты'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Все продукты'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Все продукты'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71001'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +(isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0))
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
					and [Наименование счёта Дт.] like '%52802%53803%'
					and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth and [Наименование счёта Дт.] like '%52402%' 
				and upper([Есть в отчёте по акциям]) = 'НЕТ'----and [Признак мем.ордера] = 'Да'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Всего'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Все продукты'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'Все продукты'

-------------------ПТС
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71001'
			and subconto='Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) + isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'ПТС'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				--and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'ПТС'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'ПТС'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'ПТС'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'ПТС'


-------------------Автокредит
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71001'
			and subconto='Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) + isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'Автокредит'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				--and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'Автокредит'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Автокредит'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Автокредит'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'Автокредит'

-------------------IL
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71001'
			and subconto='Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'IL'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				----and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'IL'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'IL'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'IL'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'IL'



-------------------Big Installment
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71001'
			and subconto='Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'Big Installment'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				----and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'Big Installment'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'Big Installment'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Big Installment'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'Big Installment'



-------------------PDL
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71001'
			and subconto='Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull(l1.sumAll,0) - isnull(l1.sumnonColl,0)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'PDL'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				--and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'PDL'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'PDL'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'PDL'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'PDL'



-------------------БЗ
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumnonColl
,sumAll = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)+l1.sumnonColl != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = (
			select
			sumFogiveOD
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumPrc = (
			select
			sumFogivePRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = (
			select
			sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumItogo = 0
,sumnonColl = (
			select
			sumFogiveOD + sumFogivePRC + sumFogivePenia
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and spisReason = 'Не коллекшн'
		 ) 
,sumAll = 0
,comment = 'это весь Кт оборот по данному виду прочих расходов'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71802'
			and subconto='Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
			)

) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - (isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0))
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = 0
,sumPrc = (
			select
			sumSpisPRC
			from [dwh2].[finAnalytics].[repForgive2]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
		 )
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
,comment = 'это весь оборот по Дт 71001 (в т.ч.ИП и ЮЛ)'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71001'
			and subconto in ('Процентные доходы по микрозаймам, выданным ИП (31128 сч. 71001)',
							'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)',
							'Процентный доход по микрозаймам, выданным юридическим лицам (31126, сч.71001)')
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV, checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumOther
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll - l1.sumItogo
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and subconto in ('Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71701'
			and subconto='Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +(l1.sumAll - l1.sumnonColl)
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52802%53803%'
				and  [Номенклатурная группа] = 'БЗ'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and subconto in ('Прочие доходы (расходы) (52802,53803; сч.71701,71702)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71701'
			and subconto='Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV ,checkResult )

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = l1.sumAll - l1.sumnonColl
,sumItogo = l1.sumOD + l1.sumPrc + l1.sumAll - l1.sumnonColl
,sumnonColl = l1.sumnonColl
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end
from (
select
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = (
				select isnull(sum([Сумма проводки]),0) 
				from finAnalytics.repForgive3 
				where repmonth=@repmonth 
				and [Наименование счёта Дт.] like '%52402%' 
				--and [Признак мем.ордера] = 'Да'
				and  [Номенклатурная группа] = 'БЗ'
				and upper([Есть в отчёте по акциям]) = 'НЕТ'
			  )
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and subconto in ('Штрафы и пени по займам предоставленным (52402 сч.71701)')
			)
,comment = 'это весь оборот по Дт 71701'
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71701'
			and subconto='Штрафы и пени по займам предоставленным (52402 сч.71701)'
			)
) l1

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = 0
,comment = 'Дт71702 (если нет остатка на 71701)'
,emptyFld = null
,checkOSV = 0
,checkResult = 0

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = l1.pokazatel
,rowNum = l1.rowNum
,sumOD = l1.sumOD
,sumPrc = l1.sumPrc
,sumOther = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumItogo = isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumnonColl = l1.sumAll -isnull(l1.sumOD,0) +isnull( l1.sumPrc,0) +isnull( l1.sumOther,0)
,sumAll = l1.sumAll
,comment = l1.comment
,emptyFld = null
,checkOSV = l1.checkOSV
,checkResult = case when l1.sumAll != l1.checkOSV then 1 else 0 end

from (
select
pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = 0
,sumPrc = 0
,sumOther = 0
,sumItogo = 0
,sumnonColl = 0
,sumAll = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and subconto in ('Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)')
			)
,comment = ''
,checkOSV = (
			select
			isnull(SUM(sumAmount),0)
			from [dwh2].[finAnalytics].[repForgive1]
			where repmonth = @repmonth
			and nomenkGR = 'БЗ'
			and dt = '71802'
			and subconto='Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
			)
) l1


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'БЗ'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(sumOD)
,sumPrc = sum(sumPrc)
,sumOther = sum(sumOther)
,sumItogo = sum(sumItogo)
,sumnonColl = sum(sumnonColl)
,sumAll = sum(sumAll)
,comment = ''
,emptyFld = null
,checkOSV = sum(checkOSV)
,checkResult = case when sum(sumAll) != sum(checkOSV) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and nomenkGR = 'БЗ'


-------------------Контроль
insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'
,rowNum = 1
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Списание займов размещенных (прощение задолженности) - убытки (55606, сч.71802) (не НУ)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'
,rowNum = 2
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Процентный доход по микрозаймам, выданным физическим лицам (31124, сч.71001)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
,rowNum = 3
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 4
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'


insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'
,rowNum = 5
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'
,rowNum = 6
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Пени, штрафы  по займам выданным (53402, сч.71702)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'
,rowNum = 7
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)'

insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
,rowNum = 8
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'



insert into finAnalytics.repForgive5
(repmonth, nomenkGr, pokazatel, rowNum, sumOD, sumPrc, sumOther, sumItogo, sumnonColl, sumAll, comment, emptyFld, checkOSV,checkResult)

select
repmonth = @repmonth
,nomenkGr = 'Контроль'
,pokazatel = 'ИТОГО'
,rowNum = 9
,sumOD = sum(case when nomenkGR != 'Все продукты' then sumOD*-1 else sumOD end)
,sumPrc = sum(case when nomenkGR != 'Все продукты' then sumPrc*-1 else sumPrc end)
,sumOther = sum(case when nomenkGR != 'Все продукты' then sumOther*-1 else sumOther end)
,sumItogo = sum(case when nomenkGR != 'Все продукты' then sumItogo*-1 else sumItogo end)
,sumnonColl = sum(case when nomenkGR != 'Все продукты' then sumnonColl*-1 else sumnonColl end)
,sumAll = sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end)
,comment = ''
,emptyFld = null
,checkOSV = sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end)
,checkResult = case when sum(case when nomenkGR != 'Все продукты' then sumAll*-1 else sumAll end) != sum(case when nomenkGR != 'Все продукты' then checkOSV*-1 else checkOSV end) then 1 else 0 end
from finAnalytics.repForgive5
where repmonth = @repmonth
and pokazatel = 'ИТОГО'

--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END
