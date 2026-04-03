
CREATE PROC [finAnalytics].[calcPDNrepData_Monthly] 
    @REP_MONTH date,
    @CALC_DATE date
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,'Данные для отчета ПДН'
				)
       
    begin try

    DROP TABLE IF EXISTS #ID_LIST

        Create table #ID_LIST(
            [ID] bigint NOT NULL
            )

        insert into #ID_LIST
        select
        a.ID
        from finAnalytics.PBR_MONTHLY a
        where a.REPMONTH=@REP_MONTH


        DROP TABLE IF EXISTS #rep_result

        Create table #rep_result(
            [ProductByNGroup] int NOT NULL,
            [L] int NOT NULL,
            [iBRPT] int NOT NULL,
            [KK] int NOT NULL,
            [KKSVO] int NOT NULL,
            [iDPD] int NOT NULL,
            [iDI] int NOT NULL,
            [isA2] int NOT NULL,
            [AccODNum] nvarchar(10) NOT NULL,
            [isZaemshik] nvarchar(10) NOT NULL,
            [client] nvarchar(500) NULL,
            [dogNum] nvarchar(20) NOT NULL,
            [saleDate] date NOT NULL,
            [IssueSum] float NOT NULL,
            [PDNOnRepDate] float NULL,
            [prosDaysTotal] int NULL,
            [isMicroziam] int NOT NULL,
            [restOD] float NOT NULL,
            [restPRC] float NOT NULL,
            [nomenkGroup] nvarchar(50) NOT NULL,
            [reservBUODSum] float NOT NULL,
            [reservBUpPrcSum] float NOT NULL,
            [reservOD] float NOT NULL,
            [reservPRC] float NOT NULL,
            [isBunkrupt] nvarchar(10) NOT NULL,
            [restPenia] float NOT NULL,
            [reservProch] float NOT NULL,
            [dogPeriodDays] int null,
			[addrReg] nvarchar(500) NOT NULL
            )
        -------------------------------------------------------------------

        insert into #rep_result

        select
        [ProductByNGroup] = case when l1.isMicroziam=0 then 9 
                                 when l1.isMicroziam=1 and upper(l1.isZaemshik)='ФЛ' then 
                                    case when upper(l1.nomenkGroup) in (upper('Installment'), upper('PromoInstallment')) then 1 
                                         when upper(l1.nomenkGroup) =upper('SmartInstallment') then 2
                                         when upper(l1.nomenkGroup) =upper('PDL') then 5
                                    else 0
                                    end
                                 else 7 end
        ,[L] =case when l1.isMicroziam=0 then 9 else l1.L end
        ,[iBRPT] =case when l1.isMicroziam=0 then 3 else l1.iBRPT end
        ,[KK] = case when l1.isMicroziam=0 then 3 else case when l1.KK=1 and l1.iBRPT=1 then 2 else l1.KK end end
        ,[KKSVO] = case when l1.isMicroziam=0 then 3 else case when l1.KK_SVO=1 and l1.iBRPT=1 then 2 else l1.KK_SVO end end
        ,[iDPD] = case when l1.isMicroziam=0 then 26 else l1.iDPD end
        ,[iDI] = case when l1.isMicroziam=0 then 9 
                      when l1.saleDate <= cast('2022-02-28' as date) then 1
                      when l1.saleDate between cast('2022-03-01' as date) and cast('2022-09-30' as date) then 2
                      when l1.saleDate between cast('2022-10-01' as date) and cast('2022-10-31' as date) then 3
                      --when l1.saleDate between cast('2022-11-01' as date) and cast('2023-12-31' as date) then 4
					  when l1.saleDate >= cast('2022-11-01' as date) then 4
                      else 0 
                end
        ,[isA2] = case when l1.dogPeriodDays <=30 and l1.dogSum<=30000 then 1 else 0 end
        ,l1.AccODNum
        ,l1.isZaemshik
        ,l1.client
        ,l1.dogNum
        ,l1.saleDate
        ,l1.dogSum--[IssueSum] = 0--case when cast(l1.saleDate as date)=@REP_DATE then l1.dogSum else 0 end
        ,l1.PDNOnRepDate
        ,l1.prosDaysTotal
        ,l1.isMicroziam
        ,l1.restOD
        ,l1.restPRC
        ,[nomenkGroup] = isnull(l1.nomenkGroup,'-')
        ,l1.reservBUODSum
        ,l1.reservBUpPrcSum
        ,l1.reservOD
        ,l1.reservPRC
        ,l1.isBunkrupt
        ,l1.restPenia
        ,l1.reservProch
        ,l1.dogPeriodDays
		,l1.[addrReg]
        from(
        select
        [isMicroziam] = case when substring(a.AccODNum,1,5) in ('48701', '48801', '49001', '49401') then 1 else 0 end
        ,[L] = case when (a.PDNOnRepDate=0 or a.PDNOnRepDate is null) then case when a.dogSum < 10000 and a.isZaemshik='ФЛ' then 3 ELSE 0 END
                    when a.PDNOnRepDate!=0 then case when a.PDNOnRepDate >0 and a.PDNOnRepDate <=0.5 then 0 
                                                     when a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <=0.8 then 1 
                                                     when a.PDNOnRepDate > 0.8 then 2 
                                                     ELSE 0 end 
               END
        ,[iBRPT] = case when bnkrupt.[Заемщик] is not null and bnkrupt.[Исключить] = 0 then 1
                             when bnkrupt.[Заемщик] is null and upper(a.isBankrupt) = upper('Да') then 1
                             else 0 end
        ,[KK] = case when kk.dogNum is not null then 1 else 0 end
        ,[KK_SVO] = case when kksvo.dogNum is not null then 1 else 0 end
        ,[iDPD] = case when (a.prosDaysTotal is null or a.prosDaysTotal=0) then 0
                       when a.prosDaysTotal between 1 and 30 then 1
                       when a.prosDaysTotal between 31 and 60 then 2
                       when a.prosDaysTotal between 61 and 90 then 3
                       when a.prosDaysTotal between 91 and 120 then 4
                       when a.prosDaysTotal between 121 and 150 then 5
                       when a.prosDaysTotal between 151 and 180 then 6
                       when a.prosDaysTotal between 181 and 210 then 7
                       when a.prosDaysTotal between 211 and 240 then 8
                       when a.prosDaysTotal between 241 and 270 then 9
                       when a.prosDaysTotal between 271 and 300 then 10
                       when a.prosDaysTotal between 301 and 330 then 11
                       when a.prosDaysTotal between 331 and 360 then 12
                       when a.prosDaysTotal between 361 and 390 then 13
                       when a.prosDaysTotal between 391 and 420 then 14
                       when a.prosDaysTotal between 421 and 450 then 15
                       when a.prosDaysTotal between 451 and 480 then 16
                       when a.prosDaysTotal between 481 and 510 then 17
                       when a.prosDaysTotal between 511 and 540 then 18
                       when a.prosDaysTotal between 541 and 570 then 19
                       when a.prosDaysTotal between 571 and 600 then 20
                       when a.prosDaysTotal between 601 and 630 then 21
                       when a.prosDaysTotal between 631 and 660 then 22
                       when a.prosDaysTotal between 661 and 690 then 23
                       when a.prosDaysTotal between 691 and 720 then 24
                       when a.prosDaysTotal >=721 then 25
                       else 0 end

        ,[AccODNum]= substring(a.AccODNum,1,5) 
        ,[isZaemshik] = a.isZaemshik
        ,[dogSum] = a.dogSum
        ,[PDNOnRepDate] = a.PDNOnRepDate
        ,[client] = a.client
        ,[dogNum] = a.dogNum
        ,[saleDate] = a.saleDate
        ,[prosDaysTotal] = a.prosDaysTotal
        ,[restOD] = a.zadolgOD
        ,[restPRC] = a.zadolgPrc
        ,[nomenkGroup] = a.nomenkGroup
        ,[reservBUODSum] = a.reservBUODSum
        ,[reservBUpPrcSum] = a.reservBUpPrcSum
        ,[reservOD] = a.reservOD
        ,[reservPRC] = a.reservPRC
        ,[isBunkrupt] =  a.isBankrupt
        ,[restPenia] = a.penyaSum
        ,[reservProch] = a.reservProchSumNU
        ,[dogPeriodDays] = a.dogPeriodDays
		,[addrReg] = a.addressReg
        from finAnalytics.PBR_MONTHLY a
        inner join #ID_LIST b on a.id=b.ID

        ----Привязываем банкротов
        left join (
        select [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
        ,[Заемщик] = b.Наименование
        ---Признак исключения для проброски в ПБР
        --,[Исключить] = case when a.Номер in ('00БП-0266','00БП-0302','00БП-0496','00БП-0637','00БП-0733') then 1 else 0 end
		,[Исключить] = case when 
							c.[client] is not null and @REP_MONTH between c.nonBunkruptStartDate and isnull(c.nonBunkruptEndDate,getdate())
							then 1 else 0 end
        ---Считаем дубли и берем максимальное по дате в кореляции с отчетной датой
        ,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

        from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
        left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
		left join dwh2.[finAnalytics].[SPR_notBunkrupt] c on b.Наименование = c.[client]
        where 1=1
        and a.ПометкаУдаления =  0x00
        and a.Проведен=0x01
        and cast(dateadd(year,-2000,a.Дата) as date) <=EOMONTH(@REP_MONTH)
        ) bnkrupt on a.Client=bnkrupt.[Заемщик] and bnkrupt.rn=1 --bnkrupt.[Дата]<=eomonth(a.repmonth)

        ----Первый вариант расчета КК
        /*
        -------Привязываем КК обычные
        left join (
        SELECT 
              [dogNum]
              ,[KKBegDate]
              --,[vacationType]
              ,ROW_NUMBER() over (partition by [dogNum] order by [KKBegDate] desc) rn
          FROM [dwh2].[finAnalytics].[CredVacation]
          where 1=1
          --and upper(isnull([vacationType],'')) != upper('КК СВО')
          and [KKBegDate]<=EOMONTH(@REP_MONTH)
        ) kk on a.dogNum=kk.dogNum and kk.rn=1
        */

        ----Новый вариант расчета КК на основе витрины Рисков
        -------Привязываем КК обычные
        left join (
        SELECT 
             [dogNum] = a.number
            ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
            ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
         FROM dbo.dm_restructurings a
         where 1=1
            and a.period_start<=EOMONTH(@REP_MONTH)
            and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
            --and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
        ) kk on a.dogNum=kk.dogNum and kk.rn=1
        

        ----Первый вариант расчета КК СВО
        /*
        -------Привязываем КК СВО
        left join (
        SELECT 
              [dogNum]
              ,[KKBegDate]
              --,[vacationType]
              ,ROW_NUMBER() over (partition by [dogNum] order by [KKBegDate] desc) rn
          FROM [dwh2].[finAnalytics].[CredVacation]
          where upper(isnull([vacationType],'')) = upper('КК СВО')
          and [KKBegDate]<=EOMONTH(@REP_MONTH)
        ) kksvo on a.dogNum=kksvo.dogNum and kksvo.rn=1
        */

        --Отбор: Столбец "Счёт учёта основного долга" (BZ) начинается с 487*; 488*; 494*
        --where substring(a.AccODNum,1,3) in ('487','488','494')

        ----Новый вариант расчета КК на основе витрины Рисков
        -------Привязываем КК СВО
        left join (
        SELECT 
             [dogNum] = a.number
            ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)--a.period_start
            ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
         FROM dbo.dm_restructurings a
         where 1=1
            and a.period_start<=EOMONTH(@REP_MONTH)
            and upper(a.operation_type) in (upper('Кредитные каникулы')/*,upper('Заморозка 1.0')*/)
            and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
        ) kksvo on a.dogNum=kksvo.dogNum and kksvo.rn=1

        ) l1

        --select * from #rep_result


        DROP TABLE IF EXISTS #rep_days

        Create table #rep_days(
            [DT] date NOT NULL
            )

        Insert into #rep_days
        select
        c.DT
        from Dictionary.calendar c
        where c.DT between @REP_MONTH and EOMONTH(@REP_MONTH)
        order by c.DT

        --select * from #rep_days



        DROP TABLE IF EXISTS #rep_rest

        Create table #rep_rest(
            [DT] date NOT NULL
            ,[dogNum] nvarchar(30) not null
            ,[restOD] money  not null
            ,[restPRC] money  not null
            ,[restPenya] money  not null
            ,[restReservBU_OD] money  not null
            ,[restReservBU_PRC] money  not null
            ,[restReservBU_Penya] money  not null
            ,[restReservNU_OD] money  not null
            ,[restReservNU_PRC] money  not null
            ,[restReservNU_Penya] money  not null
    
            
            
            /*
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
            */
            )
			create clustered index cix on #rep_rest
			           (
				[DT] ASC
				,[dogNum] asc
            )
        insert into #rep_rest

        select
        l1.dt
        ,l1.dogNum
        ,l1.ОстатокОДвсего
        ,l1.ОстатокПроцентовВсего
        ,l1.ОстатокПени
        ,l1.РезервБУОД
        ,l1.РезервБУПроценты
        ,l1.РезервБУПрочие
        ,l1.РезервНУОД
        ,l1.РезервНУПроценты
        ,l1.РезервНУПрочие
        from (
        select 
        ROW_NUMBER() over (partition by d.dt,acc.dogNum order by d.dt,acc.dogNum) rn
        ,d.dt
        ,acc.dogNum
        ,r.ОстатокОДвсего
        ,r.ОстатокПроцентовВсего
        ,r.ОстатокПени
        ,r.РезервБУОД
        ,r.РезервБУПроценты
        ,r.РезервНУОД
        ,r.РезервНУПроценты
        ,r.РезервБУПрочие
        ,r.РезервНУПрочие

        --r.*
        from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных r
        inner join #rep_days d on r.ДатаОтчета=DATEADD(year,2000,d.dt)
        inner join #rep_result acc on r.НомерДоговора=acc.dogNum
        ) l1

        where 1=1
        and l1.rn=1

  begin tran  
        delete from finAnalytics.repPDN where Repmonth=@REP_MONTH
        delete from finAnalytics.repPDNcheck where Repmonth=@REP_MONTH

        --Проверка заполненности ПДН в ПБР
        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek0'
        ,[checkMethod] = 'Отсутствие данных по ПДН за отчётный период: Количество пустых ячеек в столбце "ПДН на отчетную дату" должно быть =0.'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) = 0 then 'OK' else concat('Ошибка: Есть пустые ПДН: ',cast(l1.[repValue]-l1.[UMFOValue] as varchar),' шт.') end 
        from (
        select
        [repValue] = (
                        select
                        count(*)
                        from #rep_result r 
                        where (r.PDNOnRepDate is null or r.PDNOnRepDate=0)
							  and r.saleDate between @REP_MONTH and EOMONTH(@REP_MONTH)
							  and r.isZaemshik='ФЛ'
							  and upper(r.nomenkGroup) not like upper('%Самозанят%')
							  and (
								upper(r.[addrReg]) not like upper('%Донецкая %')
								and upper(r.[addrReg]) not like upper('%Луганская %')
								and upper(r.[addrReg]) not like upper('%Запорожская %')
								and upper(r.[addrReg]) not like upper('%Херсонская %')
							)
                      )
        ,[UMFOValue] = 0
        ) l1

        ----Таблица 1 - Выдачи

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Выдано, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                           when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                           when r.L =2 then 'в т.ч. ПДН >80%'
                           when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                      end
        ,[groupSort] = case when r.L =0 then 1
                           when r.L =1 then 2
                           when r.L =2 then 3
                           when r.L =3 then 4
                      end
        ,[amount] = case when r.saleDate=d.dt then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]
        
        ----Таблица 2 - Выдачи накопительно

        insert into finAnalytics.repPDN
        select
         [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Выдано накопительно за месяц, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                           when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                           when r.L =2 then 'в т.ч. ПДН >80%'
                           when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                      end
        ,[groupSort] = case when r.L =0 then 1
                           when r.L =1 then 2
                           when r.L =2 then 3
                           when r.L =3 then 4
                      end
        ,[amount] = case when r.saleDate<=d.dt and YEAR(r.saleDate)=YEAR(@REP_MONTH) and MONTH(r.saleDate)=MONTH(@REP_MONTH) then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]




        ---Проверка Таблица 1 Выдачи

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek1'
        ,[checkMethod] = 'ВЫДАЧИ: Сумма дебетового оборота за отчётный период с начала отчётного месяца по счетам 48701, 48801 и 49401 по БУ минус строка 19 должно быть =0'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: выдачи не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(case when r.saleDate=d.dt then cast (r.IssueSum as money) else 0 end)
                        from #rep_days d
                        left join #rep_result r on d.dt=r.saleDate
						where AccODNum in ('48801','48701','49401')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(a.Сумма)
                        from Stg.[_1cUMFO].РегистрБухгалтерии_БНФОБанковский a
                        left join Stg.[_1cUMFO].ПланСчетов_БНФОБанковский b1 on a.СчетДт=b1.ссылка
                        left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.Субконтоct3_Ссылка=ces.Ссылка
                        where 1=1
                        and cast(Период as date) between dateadd(year,2000,@rep_month) and dateadd(year,2000,eomonth(@rep_month))
                        and b1.Код in ('48801','48701','49401')
                        and a.Активность = 0x01
                        and (upper(ces.Представление) is null or upper(ces.Представление)not like upper('%передача прав требований%'))
                        and upper(a.Содержание) not like upper('%Корректировка%')
                        and upper(a.Содержание) not like upper('%Возврат%')
						and upper(a.Содержание) not like upper('%отмена погашения%')
						and upper(a.Содержание) not like upper('%Восстановление договора%')
                        )
        ) l1



        ----Таблица 3 - Остатки ОД + %%

        insert into finAnalytics.repPDN
        select
         [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 3

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek3'
        ,[checkMethod] = 'ОСТАТКИ ОД+%%: Остатки ОД+%% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD+re.restPRC)
                        from #rep_rest re
                        where re.DT=EOMONTH(@REP_MONTH)
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD+r.restPRC)
                        from #rep_result r
                        )
        ) l1


        ----Таблица 4 - Остатки ОД

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /* +isnull(re.restPRC,0) */) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 4

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek4'
        ,[checkMethod] = 'ОСТАТКИ ОД: Остатки ОД из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD/*+re.restPRC*/)
                        from #rep_rest re
                        where re.DT=EOMONTH(@REP_MONTH)
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD/*+r.restPRC*/)
                        from #rep_result r
                        )
        ) l1

        ----Таблица 5 - Остатки %%

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 5

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek5'
        ,[checkMethod] = 'ОСТАТКИ %%: Остатки %% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(/*re.restOD+*/re.restPRC)
                        from #rep_rest re
                        where re.DT=EOMONTH(@REP_MONTH)
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(/*r.restOD+*/r.restPRC)
                        from #rep_result r
                        )
        ) l1

        ----Таблица 6 - Резервы БУ

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservBU_OD,0) + ISNULL(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 6

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek6'
        ,[checkMethod] = 'Резервы БУ: Резервы БУ из ПБР на конец месяца = Резервы БУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservBU_OD + re.restReservBU_PRC)
                        from #rep_rest re
                        where re.DT=EOMONTH(@REP_MONTH)
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservBUODSum+r.reservBUpPrcSum)
                        from #rep_result r
                        )
        ) l1

        ----Таблица 7 - Резервы НУ

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab1'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + ISNULL(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 7

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek7'
        ,[checkMethod] = 'Резервы НУ: Резервы НУ из ПБР на конец месяца = Резервы НУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservNU_OD + re.restReservNU_PRC)
                        from #rep_rest re
                        where re.DT=EOMONTH(@REP_MONTH)
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservOD+r.reservPRC)
                        from #rep_result r
                        )
        ) l1

        
        ----Таблица 8 - Выдачи Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Выдано, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1
        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = case when r.saleDate=d.dt then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r
        where upper(r.nomenkGroup) like upper('%installment%')


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 9 - Выдачи накопительно Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Выдано накопительно за месяц, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = case when r.saleDate<=d.dt and YEAR(r.saleDate)=YEAR(@REP_MONTH) and MONTH(r.saleDate)=MONTH(@REP_MONTH) then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]




        ---Проверка Таблица 8 Выдачи Installment

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek8'
        ,[checkMethod] = 'ВЫДАЧИ Installment: Сумма дебетового оборота за отчётный период с начала отчётного месяца по счетам 48701, 48801 и 49401 по БУ минус строка 19 должно быть =0'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: выдачи не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(case when r.saleDate=d.dt then cast (r.IssueSum as money) else 0 end)
                        from #rep_days d
                        left join #rep_result r on d.dt=r.saleDate
                        where upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(a.Сумма)
                        from Stg.[_1cUMFO].РегистрБухгалтерии_БНФОБанковский a
                        left join Stg.[_1cUMFO].ПланСчетов_БНФОБанковский b1 on a.СчетДт=b1.ссылка
                        left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.Субконтоct3_Ссылка=ces.Ссылка
                        left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
                        inner join #rep_result r on r.dogNum=crdt.Номер
                        where 1=1
                        and cast(Период as date) between dateadd(year,2000,@rep_month) and dateadd(year,2000,eomonth(@rep_month))
                        and b1.Код in ('48801','48701','49401')
                        and a.Активность = 0x01
                        and (upper(ces.Представление) is null or upper(ces.Представление)not like upper('%передача прав требований%'))
                        and upper(a.Содержание) not like upper('%Корректировка%')
                        and upper(a.Содержание) not like upper('%Возврат%')
                        and upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1



        ----Таблица 10 - Остатки ОД + %% Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3
        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 10

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek10'
        ,[checkMethod] = 'ОСТАТКИ ОД+%% Installment: Остатки ОД+%% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD+re.restPRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD+r.restPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1


        ----Таблица 11 - Остатки ОД Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /* +isnull(re.restPRC,0) */) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 11

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek11'
        ,[checkMethod] = 'ОСТАТКИ ОД Installment: Остатки ОД из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD/*+re.restPRC*/)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD/*+r.restPRC*/)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1

        ----Таблица 12 - Остатки %% Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 12

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek12'
        ,[checkMethod] = 'ОСТАТКИ %% Installment: Остатки %% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(/*re.restOD+*/re.restPRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(/*r.restOD+*/r.restPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1

        ----Таблица 13 - Резервы БУ Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservBU_OD,0) + ISNULL(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 13

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek13'
        ,[checkMethod] = 'Резервы БУ Installment: Резервы БУ из ПБР на конец месяца = Резервы БУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservBU_OD + re.restReservBU_PRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservBUODSum+r.reservBUpPrcSum)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1

        ----Таблица 14 - Резервы НУ Installment

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab2'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + ISNULL(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%installment%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 14

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek14'
        ,[checkMethod] = 'Резервы НУ Installment: Резервы НУ из ПБР на конец месяца = Резервы НУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservNU_OD + re.restReservNU_PRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%installment%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservOD+r.reservPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%installment%')
                        )
        ) l1


        ----Таблица 15 - Выдачи PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Выдано, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = case when r.saleDate=d.dt then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r
        where upper(r.nomenkGroup) like upper('%pdl%')


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 16 - Выдачи накопительно PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Выдано накопительно за месяц, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = case when r.saleDate<=d.dt and YEAR(r.saleDate)=YEAR(@REP_MONTH) and MONTH(r.saleDate)=MONTH(@REP_MONTH) then cast (r.IssueSum/*/1000000*/ as money) else 0 end
        from #rep_days d,#rep_result r
        where upper(r.nomenkGroup) like upper('%pdl%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]




        ---Проверка Таблица 15 Выдачи PDL

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek15'
        ,[checkMethod] = 'ВЫДАЧИ PDL: Сумма дебетового оборота за отчётный период с начала отчётного месяца по счетам 48701, 48801 и 49401 по БУ минус строка 19 должно быть =0'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: выдачи не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(case when r.saleDate=d.dt then cast (r.IssueSum as money) else 0 end)
                        from #rep_days d
                        left join #rep_result r on d.dt=r.saleDate
                        where upper(r.nomenkGroup) like upper('%pdl%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(a.Сумма)
                        from Stg.[_1cUMFO].РегистрБухгалтерии_БНФОБанковский a
                        left join Stg.[_1cUMFO].ПланСчетов_БНФОБанковский b1 on a.СчетДт=b1.ссылка
                        left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.Субконтоct3_Ссылка=ces.Ссылка
                        left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
                        inner join #rep_result r on r.dogNum=crdt.Номер
                        where 1=1
                        and cast(Период as date) between dateadd(year,2000,@rep_month) and dateadd(year,2000,eomonth(@rep_month))
                        and b1.Код in ('48801','48701','49401')
                        and a.Активность = 0x01
                        and (upper(ces.Представление) is null or upper(ces.Представление)not like upper('%передача прав требований%'))
                        and upper(a.Содержание) not like upper('%Корректировка%')
                        and upper(a.Содержание) not like upper('%Возврат%')
                        and upper(r.nomenkGroup) like upper('%pdl%')
                        )
        ) l1



        ----Таблица 17 - Остатки ОД + %% PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%PDL%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 17

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek17'
        ,[checkMethod] = 'ОСТАТКИ ОД+%% PDL: Остатки ОД+%% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD+re.restPRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%PDL%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD+r.restPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%PDL%')
                        )
        ) l1


        ----Таблица 18 - Остатки ОД PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /* +isnull(re.restPRC,0) */) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%PDL%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 18

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek11'
        ,[checkMethod] = 'ОСТАТКИ ОД PDL: Остатки ОД из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restOD/*+re.restPRC*/)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%pdl%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.restOD/*+r.restPRC*/)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%pdl%')
                        )
        ) l1

        ----Таблица 19 - Остатки %% PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%pdl%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 19

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek19'
        ,[checkMethod] = 'ОСТАТКИ %% PDL: Остатки %% из ПБР на конец месяца = Остатки РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(/*re.restOD+*/re.restPRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%PDL%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(/*r.restOD+*/r.restPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%PDL%')
                        )
        ) l1

        ----Таблица 20 - Резервы БУ PDL

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservBU_OD,0) + ISNULL(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%pdl%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 20

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek20'
        ,[checkMethod] = 'Резервы БУ PDL: Резервы БУ из ПБР на конец месяца = Резервы БУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservBU_OD + re.restReservBU_PRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%pdl%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservBUODSum+r.reservBUpPrcSum)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%pdl%')
                        )
        ) l1

        ----Таблица 21 - Резервы НУ PDL

        insert into finAnalytics.repPDN
        SELECT
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab3'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount]) /*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.L =0 then 'в т.ч. ПДН <=50%'
                            when r.L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when r.L =2 then 'в т.ч. ПДН >80%'
                            when r.L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when r.L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when r.L =0 then 1
                            when r.L =1 then 2
                            when r.L =2 then 3
                            when r.L =3 then 4
                            when r.L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + ISNULL(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where upper(r.nomenkGroup) like upper('%pdl%')

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ---Проверка Таблица 21

        insert into finAnalytics.repPDNcheck
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[blockName] = 'Chek21'
        ,[checkMethod] = 'Резервы НУ PDL: Резервы НУ из ПБР на конец месяца = Резервы НУ РегистрСЗД УМФО на конец месяца'
        ,[repValue] = l1.repValue
        ,[UMFOValue] = l1.UMFOValue
        ,[diff] = case when abs(l1.repValue-l1.UMFOValue) <= 0.99 then 'OK' else concat('Ошибка: Остатки не совпадают ',cast(cast(l1.[repValue]-l1.[UMFOValue] as money) as varchar)) end 
        from (
        select
        [repValue] = (
                        select
                        sum(re.restReservNU_OD + re.restReservNU_PRC)
                        from #rep_rest re
                        inner join #rep_result r on re.dogNum=r.dogNum
                        where re.DT=EOMONTH(@REP_MONTH)
                        and upper(r.nomenkGroup) like upper('%pdl%')
                      )
        ,[UMFOValue] = (
                        SELECT 
                        sum(r.reservOD+r.reservPRC)
                        from #rep_result r
                        where upper(r.nomenkGroup) like upper('%pdl%')
                        )
        ) l1


        ----Таблица 22 - Остатки ОД + %% KK

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab4'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.KK =0 then 'в т.ч. не КК'
                            when r.KK =1 then 'в т.ч. КК'
                            when r.KK =2 then 'из них КК-банкроты'
                            when r.KK is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when r.KK =0 then 1
                            when r.KK =1 then 2
                            when r.KK =2 then 3
                            when r.KK is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        ,[amountBnkrpt] = sum( case when KK=2 then re.restOD+re.restPRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 23 - Остатки ОД KK

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab4'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.KK =0 then 'в т.ч. не КК'
                            when r.KK =1 then 'в т.ч. КК'
                            when r.KK =2 then 'из них КК-банкроты'
                            when r.KK is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when r.KK =0 then 1
                            when r.KK =1 then 2
                            when r.KK =2 then 3
                            when r.KK is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)/*  +isnull(re.restPRC,0)*/ ) 
        ,[amountBnkrpt] = sum( case when KK=2 then re.restOD/*+re.restPRC*/ else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 24 - Остатки %% KK

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab4'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.KK =0 then 'в т.ч. не КК'
                            when r.KK =1 then 'в т.ч. КК'
                            when r.KK =2 then 'из них КК-банкроты'
                            when r.KK is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when r.KK =0 then 1
                            when r.KK =1 then 2
                            when r.KK =2 then 3
                            when r.KK is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        ,[amountBnkrpt] = sum( case when KK=2 then /*re.restOD+*/re.restPRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 25 - Резервы БУ KK

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab4'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.KK =0 then 'в т.ч. не КК'
                            when r.KK =1 then 'в т.ч. КК'
                            when r.KK =2 then 'из них КК-банкроты'
                            when r.KK is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when r.KK =0 then 1
                            when r.KK =1 then 2
                            when r.KK =2 then 3
                            when r.KK is null then 1
                       end
        ,[amount] = (isnull(re.restReservBU_OD,0)  +isnull(re.restReservBU_PRC,0)) 
        ,[amountBnkrpt] = sum( case when KK=2 then re.restReservBU_OD+re.restReservBU_PRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 26 - Резервы НУ KK

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab4'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when r.KK =0 then 'в т.ч. не КК'
                            when r.KK =1 then 'в т.ч. КК'
                            when r.KK =2 then 'из них КК-банкроты'
                            when r.KK is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when r.KK =0 then 1
                            when r.KK =1 then 2
                            when r.KK =2 then 3
                            when r.KK is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0)  +isnull(re.restReservNU_PRC,0)) 
        ,[amountBnkrpt] = sum( case when KK=2 then re.restReservNU_OD+re.restReservNU_PRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 27 - Остатки ОД + %% KK SVO

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab5'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] =1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                            when KKSVO =1 then 'в т.ч. КК'
                            when KKSVO =2 then 'из них КК-банкроты'
                            when KKSVO is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when KKSVO =0 then 1
                            when KKSVO =1 then 2
                            when KKSVO =2 then 3
                            when KKSVO is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        ,[amountBnkrpt] = sum( case when KKSVO=2 then re.restOD+re.restPRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 28 - Остатки ОД KK SVO

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab5'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] =2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                            when KKSVO =1 then 'в т.ч. КК'
                            when KKSVO =2 then 'из них КК-банкроты'
                            when KKSVO is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when KKSVO =0 then 1
                            when KKSVO =1 then 2
                            when KKSVO =2 then 3
                            when KKSVO is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0)/*  +isnull(re.restPRC,0)*/ ) 
        ,[amountBnkrpt] = sum( case when KKSVO=2 then re.restOD/*+re.restPRC*/ else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 29 - Остатки %% KK SVO

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab5'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] =3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                            when KKSVO =1 then 'в т.ч. КК'
                            when KKSVO =2 then 'из них КК-банкроты'
                            when KKSVO is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when KKSVO =0 then 1
                            when KKSVO =1 then 2
                            when KKSVO =2 then 3
                            when KKSVO is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        ,[amountBnkrpt] = sum( case when KKSVO=2 then /*re.restOD+*/re.restPRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 30 - Резервы БУ KK SVO

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab5'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] =4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                            when KKSVO =1 then 'в т.ч. КК'
                            when KKSVO =2 then 'из них КК-банкроты'
                            when KKSVO is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when KKSVO =0 then 1
                            when KKSVO =1 then 2
                            when KKSVO =2 then 3
                            when KKSVO is null then 1
                       end
        ,[amount] = (isnull(re.restReservBU_OD,0)  +isnull(re.restReservBU_PRC,0)) 
        ,[amountBnkrpt] = sum( case when KKSVO=2 then re.restReservBU_OD+re.restReservBU_PRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 31 - Резервы НУ KK SVO

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab5'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = case when l1.[groupName]='в т.ч. КК' then sum(l1.[amount])/*/1000000*/ + max(l1.amountBnkrpt)/*/1000000*/ else sum(l1.[amount])/*/1000000*/ end
        ,[groupSort] = l1.groupSort
        ,[blockSort] =5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when KKSVO =0 then 'в т.ч. не КК'
                            when KKSVO =1 then 'в т.ч. КК'
                            when KKSVO =2 then 'из них КК-банкроты'
                            when KKSVO is null then 'в т.ч. не КК'
                       end
        ,[groupSort] = case when KKSVO =0 then 1
                            when KKSVO =1 then 2
                            when KKSVO =2 then 3
                            when KKSVO is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0)  +isnull(re.restReservNU_PRC,0)) 
        ,[amountBnkrpt] = sum( case when KKSVO=2 then re.restReservNU_OD+re.restReservNU_PRC else 0 end) over (partition by d.DT)
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 


        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 32 - Остатки ОД + %% DPD

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab6'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                            when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                            when iDPD between 4 and 25 then 'в т.ч. 90+'
                            when iDPD is null then 'в т.ч. непросроченные'
                       end
        ,[groupSort] = case when iDPD =0 then 1
                            when iDPD in (1,2,3) then 2
                            when iDPD between 4 and 25 then 3
                            when iDPD is null then 1
                        end
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 33 - Остатки ОД DPD

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab6'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                            when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                            when iDPD between 4 and 25 then 'в т.ч. 90+'
                            when iDPD is null then 'в т.ч. непросроченные'
                       end
        ,[groupSort] = case when iDPD =0 then 1
                            when iDPD in (1,2,3) then 2
                            when iDPD between 4 and 25 then 3
                            when iDPD is null then 1
                        end
        ,[amount] = (isnull(re.restOD,0)/*  +isnull(re.restPRC,0)*/ ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 34 - Остатки %% DPD

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab6'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                            when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                            when iDPD between 4 and 25 then 'в т.ч. 90+'
                            when iDPD is null then 'в т.ч. непросроченные'
                       end
        ,[groupSort] = case when iDPD =0 then 1
                            when iDPD in (1,2,3) then 2
                            when iDPD between 4 and 25 then 3
                            when iDPD is null then 1
                        end
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 35 - Резервы БУ DPD

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab6'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                            when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                            when iDPD between 4 and 25 then 'в т.ч. 90+'
                            when iDPD is null then 'в т.ч. непросроченные'
                       end
        ,[groupSort] = case when iDPD =0 then 1
                            when iDPD in (1,2,3) then 2
                            when iDPD between 4 and 25 then 3
                            when iDPD is null then 1
                        end
        ,[amount] = (isnull(re.restReservBU_OD,0)  +isnull(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 36 - Резервы НУ DPD

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab6'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when iDPD =0 then 'в т.ч. непросроченные'
                            when iDPD in (1,2,3) then 'в т.ч. 1-90 дней'
                            when iDPD between 4 and 25 then 'в т.ч. 90+'
                            when iDPD is null then 'в т.ч. непросроченные'
                       end
        ,[groupSort] = case when iDPD =0 then 1
                            when iDPD in (1,2,3) then 2
                            when iDPD between 4 and 25 then 3
                            when iDPD is null then 1
                        end
        ,[amount] = (isnull(re.restReservNU_OD,0)  +isnull(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 37 - Остатки ОД + %% Банкроты

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab7'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iBRPT=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 38 - Остатки ОД Банкроты

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab7'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restOD,0)/*  +isnull(re.restPRC,0)*/ ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iBRPT=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 39 - Остатки %% Банкроты

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab7'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iBRPT=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 40 - Резервы БУ Банкроты

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab7'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restReservBU_OD,0)  +isnull(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iBRPT=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 41 - Резервы НУ Банкроты

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab7'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restReservNU_OD,0)  +isnull(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iBRPT=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 42 - Остатки ОД + %% Займы

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab8'
        ,[blockName] = 'Портфель (ОД+%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restOD,0)  +isnull(re.restPRC,0) ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.ProductByNGroup=9
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 43 - Остатки ОД Займы

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab8'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restOD,0)/*  +isnull(re.restPRC,0)*/ ) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.ProductByNGroup=9
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 44 - Остатки %% Займы

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab8'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (/*isnull(re.restOD,0)  +*/isnull(re.restPRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.ProductByNGroup=9
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 45 - Резервы БУ Займы

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab8'
        ,[blockName] = 'Резерв БУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restReservBU_OD,0)  +isnull(re.restReservBU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.ProductByNGroup=9
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 46 - Резервы НУ Займы

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab8'
        ,[blockName] = 'Резерв НУ, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = 1
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = ''
        ,[groupSort] = 1
        ,[amount] = (isnull(re.restReservNU_OD,0)  +isnull(re.restReservNU_PRC,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.ProductByNGroup=9
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 47 - Остатки ОД + %% + Пени НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1
        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 48 - Остатки ОД НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 49 - Остатки %% НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 50 - Прочие требования НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
       ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 51 - Резервы всего НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 52 - Резервы ОД НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 53 - Резервы %% НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 54 - Резервы Прочее НМФК1

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab9'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 55 - Остатки ОД + %% + Пени НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1
        
        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 56 - Остатки ОД НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =2

        from(

        select
        [Отчетная дата] = d.DT
       ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d

        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 57 - Остатки %% НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 58 - Прочие требования НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 59 - Резервы всего НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 60 - Резервы ОД НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 61 - Резервы %% НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 62 - Резервы Прочее НМФК1 по 28.02.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab10'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 1

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 63 - Остатки ОД + %% + Пени НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =1

        from(

        select
        [Отчетная дата] = d.DT
       ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 64 - Остатки ОД НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =2

        from(

        select
        [Отчетная дата] = d.DT
       ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 65 - Остатки %% НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 66 - Прочие требования НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
       [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 67 - Резервы всего НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 68 - Резервы ОД НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 69 - Резервы %% НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 70 - Резервы Прочее НМФК1 с 01.03.2022 по 30.09.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab11'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 2

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 71 - Остатки ОД + %% + Пени НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 72 - Остатки ОД НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 73 - Остатки %% НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 74 - Прочие требования НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 75 - Резервы всего НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 76 - Резервы ОД НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 77 - Резервы %% НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 78 - Резервы Прочее НМФК1 с 01.10.2022 по 31.10.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab12'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] = 8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 3

        ----Пустышка для не существующей группы
        union all
        select
        [Отчетная дата] = d.DT
        ,[groupName] = 'в т.ч. без ПДН (до 10 тыс.руб.)'
        ,[groupSort] =4
        ,0
        from #rep_days d
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 79 - Остатки ОД + %% + Пени НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 80 - Остатки ОД НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 81 - Остатки %% НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 82 - Прочие требования НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =4

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 83 - Резервы всего НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 84 - Резервы ОД НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 85 - Резервы %% НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 86 - Резервы Прочее НМФК1 с 01.11.2022

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab13'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.iDI = 4
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 87 - Остатки ОД + %% + Пени НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Требования, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =1

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) + isnull(re.restPRC,0) + isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 88 - Остатки ОД НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Портфель (ОД), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =2

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restOD,0) /*+ isnull(re.restPRC,0) + isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]



        ----Таблица 89 - Остатки %% НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Портфель (%%), млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =3

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) +*/ isnull(re.restPRC,0) /*+ isnull(re.restPenya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 90 - Прочие требования НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Прочие требования, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =4

        from(

        select
        [Отчетная дата] = d.DT
       ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restOD,0) + isnull(re.restPRC,0) +*/ isnull(re.restPenya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]


        ----Таблица 91 - Резервы всего НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Резерв, всего, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =5

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 92 - Резервы ОД НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Резерв ОД, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =6

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (isnull(re.restReservNU_OD,0) /*+ isnull(re.restReservNU_PRC,0) + isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 93 - Резервы %% НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Резерв %%, млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =7

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) +*/ isnull(re.restReservNU_PRC,0) /*+ isnull(re.restReservNU_Penya,0)*/) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]

        ----Таблица 94 - Резервы Прочее НМФК1 A2

        insert into finAnalytics.repPDN
        select
        [Repmonth] = @REP_MONTH
        ,[calcDate] = @CALC_DATE
        ,[Repdate] = l1.[Отчетная дата]
        ,[tabName] = 'Tab14'
        ,[blockName] = 'Резерв проч., млн руб.'
        ,[groupName] = l1.[groupName]
        ,[amount] = sum(l1.[amount])/*/1000000*/
        ,[groupSort] = l1.groupSort
        ,[blockSort] =8

        from(

        select
        [Отчетная дата] = d.DT
        ,[groupName] = case when L =0 then 'в т.ч. ПДН <=50%'
                            when L =1 then 'в т.ч. ПДН >50% и <=80%'
                            when L =2 then 'в т.ч. ПДН >80%'
                            when L =3 then 'в т.ч. без ПДН (до 10 тыс.руб.)'
                            when L is null then 'в т.ч. ПДН <=50%'
                       end
        ,[groupSort] = case when L =0 then 1
                            when L =1 then 2
                            when L =2 then 3
                            when L =3 then 4
                            when L is null then 1
                       end
        ,[amount] = (/*isnull(re.restReservNU_OD,0) + isnull(re.restReservNU_PRC,0) +*/ isnull(re.restReservNU_Penya,0)) 
        from #rep_days d
        left join #rep_rest re on d.dt=re.dt
        left join #rep_result r on r.DogNum=re.DogNum 
        where r.isA2=1
        ) l1
        where l1.[groupName] is not null
        group by l1.[groupName],l1.groupSort,l1.[Отчетная дата]  


        -----Запись расхождений по договорам
        delete from finAnalytics.repPDNcheckDetail where repMonth=@REP_MONTH --and calcDate=@CALC_DATE and repType='MONTHLY'

        INSERT INTO  finAnalytics.repPDNcheckDetail 
          select
          *
          from (
          select
          [repMonth] = @REP_MONTH
          ,[calDate] =  @CALC_DATE
          ,[repType] = 'MONTHLY'
          ,pbr.dogNum
          ,[pbr_restOD] = pbr.restOD
          ,[umfo_restOD] = umfo.restOD
          ,[diff_restOD] = case when abs(pbr.restOD - umfo.restOD) > 100 then 1 else 0 end

          ,[pbr_restPRC] = pbr.restPRC
          ,[umfo_restPRC] = umfo.restPRC
          ,[diff_restPRC] = case when abs(pbr.restPRC - umfo.restPRC) > 100 then 1 else 0 end

        --  ,[pbr_restPenia] = pbr.restPenia
        --  ,[umfo_restPenya] = umfo.restPenya
        --  ,[diff_restPenya] = case when pbr.restPenia != umfo.restPenya then 1 else 0 end

          ,[pbr_reservOD_NU] = pbr.reservOD
          ,[umfo_reservOD_NU] = umfo.restReservNU_OD
          ,[diff_reservOD_NU] = case when abs(pbr.reservOD - umfo.restReservNU_OD) > 100 then 1 else 0 end

          ,[pbr_reservPRC_NU] = pbr.reservPRC
          ,[umfo_reservPRC_NU] = umfo.restReservNU_PRC
          ,[diff_reservPRC_NU] = case when abs(pbr.reservPRC - umfo.restReservNU_PRC) > 100 then 1 else 0 end

        --  ,[pbr_reservProch_NU] = pbr.reservProch
        --  ,[umfo_reservProch_NU] = umfo.restReservNU_Penya
        --  ,[diff_reservProch_NU] = case when pbr.reservProch != umfo.restReservNU_Penya then 1 else 0 end
  
          ,[pbr_reservOD_BU] = pbr.reservBUODSum
          ,[umfo_reservOD_BU] = umfo.restReservBU_OD
          ,[diff_reservOD_BU] = case when abs(pbr.reservBUODSum - umfo.restReservBU_OD) > 100 then 1 else 0 end

          ,[pbr_reservPrc_BU] = pbr.reservBUpPrcSum
          ,[umfo_reservPrc_BU] = umfo.restReservBU_PRC  
          ,[diff_reservPrc_BU] = case when abs(pbr.reservBUpPrcSum - umfo.restReservBU_PRC) > 100 then 1 else 0 end
  
          from #rep_result pbr
          left join #rep_rest umfo on pbr.dogNum=umfo.dogNum and umfo.DT=@CALC_DATE
          ) l1

  
          where 
          l1.diff_restOD
          +l1.diff_restPRC
        --  +l1.diff_restPenya
          +l1.diff_reservOD_NU
          +l1.diff_reservPRC_NU
        --  +l1.diff_reservProch_NU
          +l1.diff_reservOD_BU
          +l1.diff_reservPrc_BU 
        >0
        
  commit tran
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(CalcDATE) from finAnalytics.repPDN ) as varchar)
    
	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID] in (12,13)

	
	--/*Обновление данных PBI*/
	--EXEC [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
	--@subscription_id = '6d5ed7ad-0727-4303-9213-7a29e3724874',
	--@await_success = 0

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Расчет месячных данных для отчета ПДН за '
                ,FORMAT( @REP_MONTH, 'MMMM yyyy', 'ru-RU' )
				--,@sp_name
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                --,'Максимальная дата остатков: '
                --,@maxDateRest
				)
	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,3))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
    

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,3))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
