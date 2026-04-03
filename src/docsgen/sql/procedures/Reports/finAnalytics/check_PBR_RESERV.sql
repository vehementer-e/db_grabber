


CREATE PROCEDURE [finAnalytics].[check_PBR_RESERV]
	@repMonth date
	with recompile
AS
BEGIN

DROP TABLE IF EXISTS dwh2.finAnalytics.#PBR
CREATE TABLE dwh2.finAnalytics.#PBR (
    [repmonth] date  not null,
    [dogNum] nvarchar(50) not null,
    [client] nvarchar(150) not null,
    [isZaemshik] nvarchar(50) not null,
    [isRestruk] nvarchar(10) not null,
    [isRefinance]  nvarchar(10) not null,
    [isBankrupt] nvarchar(10) not null,
    [nomenkGroup] nvarchar(300) not null,
    
    [restOD] money not null,
    [restPRC] money not null,
    [restPenya] money not null,
    [restGosPopshl] money not null,
    
    [reservOD] money not null,
    [reservPRC] money not null,
    [reservPenya] money not null,

    [allPros] int null,
    [dogStatus] nvarchar(50) not null,
    [isObespechZaym] nvarchar(10) not null,
    [isMSPbyRepDate] nvarchar(10) not null,
	[PSK_prc] float null
    /*
    CONSTRAINT [PK_PBR] PRIMARY KEY CLUSTERED 
    (
	[dogNum] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
    */
)

truncate table #PBR

insert into #PBR
select 
[REPMONTH],
[dogNum],
[client],
[isZaemshik],
[isRestruk],
[isRefinance],
[isBankrupt],
isnull([nomenkGroup],'Не определена в ПБР'),
    
[zadolgOD],
[zadolgPrc],
[penyaSum],
isnull([gosposhlSum],0),
    
[reservOD],
[reservPRC],
[reservProchSumNU],

[prosDaysTotal],
[dogStatus],
[isObespechZaym],
[isMSPbyRepDate] = isnull(a.isMSPbyRepDate,'Нет'),
[PSK_prc]
from dwh2.finAnalytics.PBR_MONTHLY a
where a.REPMONTH = @repmonth
--Исключаем закрытые договора
and upper(a.dogStatus)=upper('Действует')


--select * from #PBR

DROP TABLE IF EXISTS dwh2.finAnalytics.#RESERV
CREATE TABLE dwh2.finAnalytics.#RESERV (
    [repmonth] date not null, 
    [dogNum] nvarchar(50) not null,
    [client] nvarchar(150) not null,
    [isZaemshik] nvarchar(50) not null,
    [isRestruk] nvarchar(10) not null,
    [isRefinance]  nvarchar(10) not null,
    [isBankrupt] nvarchar(10) not null,
    [nomenkGroup] nvarchar(300) not null,
    
    [restOD] money not null,
    [restPRC] money not null,
    [restPenya] money not null,
    [restGosPopshl] money not null,
    
    [reservOD] money not null,
    [reservPRC] money not null,
    [reservPenya] money not null,

    [allPros] int not null,
    [zaymGroup] nvarchar(300) not null,
	[PSK_prc] float null
    /*
    CONSTRAINT [PK_RESERV] PRIMARY KEY CLUSTERED 
    (
	[dogNum] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
    */
)

truncate table #RESERV

insert into #RESERV
select 
[REPMONTH],
[dogNum],
[client],
[clientType],
[isRestrukt],
[isRefinance],
[isBunkrupt],
case when isnull([nomenklGroup],'Не определена в ПБР') = 'Промодни' then 'PromoInstallment' else isnull([nomenklGroup],'Не определена в ПБР') end,
    
[restOD],
[restPRC],
[restPenia],
isnull([restGosposhl],0),
    
[sumOD],
[sumPRC],
[sumPenia],

[allPros],
[zaymGroup] = isnull([zaymGroup],'-'),
[PSK_prc]
from dwh2.finAnalytics.Reserv_NU  a
where a.REPMONTH = @repmonth

--select * from #RESERV

select
[Отчетный месяц] = a.repmonth
,[Группа проверки] = 1 
,[Тип проверки] = 'Договора Резервов с остатками !=0 отсутвуют в ПБР'
,[Номер договора] = a.dogNum 
,[Состояние договора] = b.dogStatus
,[Значение в Резервы НУ] = ''
,[Значение в ПБР] = ''
,[Разница] = ''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where 
(
a.restOD+a.reservPenya+a.restPRC+a.restGosPopshl!=0
or
a.reservOD+a.reservPRC+a.reservPenya!=0
)
and b.dogNum is null

union all

select
[Отчетный месяц] = a.repmonth
,2
,'Признак реструктуризацции'
,a.dogNum 
,b.dogStatus
,a.isRestruk
,b.isRestruk
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where upper(a.isRestruk) != upper(b.isRestruk)

union all

---Убрана проверка Рефинанса по просьбе Хасаншина 06.08.2024
/*
select
[Отчетный месяц] = a.repmonth
,3
,'Признак рефинанса'
,a.dogNum 
,b.dogStatus
,a.isRefinance
,b.isRefinance
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where upper(a.isRefinance) != upper(b.isRefinance)

union all
*/


select
[Отчетный месяц] = a.repmonth
,4
,'Признак Банкротсва'
,a.dogNum 
,b.dogStatus
,a.isBankrupt
,b.isBankrupt
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
--,c.docNum
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
--left join dwh2.finAnalytics.notBunkrupt c on a.client=c.client
where upper(a.isBankrupt) != upper(b.isBankrupt)
--and c.client is null

union all

select
[Отчетный месяц] = a.repmonth
,5
,'Номенклатурная группа'
,a.dogNum 
,b.dogStatus
,a.nomenkGroup
,b.nomenkGroup
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where upper(a.nomenkGroup) != upper(b.nomenkGroup)

union all

select
[Отчетный месяц] = a.repmonth
,6
,'Остаток ОД'
,a.dogNum 
,b.dogStatus
,cast(a.restOD as varchar)
,cast(b.restOD as varchar)
,cast(a.restOD - b.restOD as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.restOD -b.restOD) >= 1

union all

select
[Отчетный месяц] = a.repmonth
,7
,'Остаток Проценты'
,a.dogNum 
,b.dogStatus
,cast(a.restPRC as varchar)
,cast(b.restPRC as varchar)
,cast(a.restPRC - b.restPRC as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.restPRC -b.restPRC) >= 1

union all

select
[Отчетный месяц] = a.repmonth
,8
,'Остаток Пени'
,a.dogNum 
,b.dogStatus
,cast(a.restPenya as varchar)
,cast(b.restPenya as varchar)
,cast(a.restPenya - b.restPenya as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.restPenya -b.restPenya) >= 1


union all

select
[Отчетный месяц] = a.repmonth
,9
,'Остаток Госпошлины'
,a.dogNum 
,b.dogStatus
,cast(a.restGosPopshl as varchar)
,cast(b.restGosPopshl as varchar)
,cast(a.restGosPopshl - b.restGosPopshl as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.restGosPopshl -b.restGosPopshl) >= 1

union all

select
[Отчетный месяц] = a.repmonth
,10
,'Резерв ОД'
,a.dogNum 
,b.dogStatus
,cast(a.reservOD as varchar)
,cast(b.reservOD as varchar)
,cast(a.reservOD - b.reservOD as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.reservOD -b.reservOD) >= 1


union all

select
[Отчетный месяц] = a.repmonth
,11
,'Резерв Проценты'
,a.dogNum 
,b.dogStatus
,cast(a.reservPRC as varchar)
,cast(b.reservPRC as varchar)
,cast(a.reservPRC - b.reservPRC as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.reservPRC -b.reservPRC) >= 1

union all

select
[Отчетный месяц] = a.repmonth
,12
,'Резерв Пени'
,a.dogNum 
,b.dogStatus
,cast(a.reservPenya as varchar)
,cast(b.reservPenya as varchar)
,cast(a.reservPenya - b.reservPenya as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(a.reservPenya -b.reservPenya) >= 1

union all

select
[Отчетный месяц] = a.repmonth
,13
,'Всего дней просрочки'
,a.dogNum 
,b.dogStatus
,cast(a.allPros as varchar)
,cast(b.allPros as varchar)
,cast(a.allPros - b.allPros as varchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where upper(a.allPros) != upper(b.allPros)

union all

select
[Отчетный месяц] = a.repmonth
,14
,'Обеспеченность'
,a.dogNum 
,b.dogStatus
,case when upper(a.zaymGroup) like '%необеспеч%' then upper('Нет')
	  when upper(a.zaymGroup) like '% обеспеч%' then upper('Да')
      end
,b.isObespechZaym
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where case when upper(a.zaymGroup) like '%необеспеч%' then upper('Нет')
	  when upper(a.zaymGroup) like '% обеспеч%' then upper('Да')
      end
	  != upper(b.isObespechZaym)


union all

select
[Отчетный месяц] = a.repmonth
,15
,'Признак МСП'
,a.dogNum 
,b.dogStatus
,case when upper(a.zaymGroup) like '%субъекту малого и среднего%' then 'Да'
           else 'Нет'
      end
,b.isMSPbyRepDate
,''

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where case when upper(a.zaymGroup) like '%субъекту малого и среднего%' then upper('Да')
           else upper('Нет')
      end      != upper(b.isMSPbyRepDate)

union all

select
[Отчетный месяц] = a.repmonth
,16
,'ПСК для РВПЗ'
,a.dogNum 
,b.dogStatus
,cast(round(a.PSK_prc,2) as nvarchar)
,cast(round(b.PSK_prc,2) as nvarchar)
,cast(round(a.PSK_prc - b.PSK_prc,2)  as nvarchar)

,[Клиент] = a.client
,[inf. остаток ОД] = b.restOD
,[inf. остаток %%] = b.restPRC
,[inf. остаток Пеня] = b.restPenya
,[inf. остаток Госпош.] = b.restGosPopshl
from #reserv a
left join #PBR b on a.dogNum=b.dogNum and a.repmonth=b.repmonth
where abs(round(a.PSK_prc,2) - round(b.PSK_prc,2)) > 0.1

end
