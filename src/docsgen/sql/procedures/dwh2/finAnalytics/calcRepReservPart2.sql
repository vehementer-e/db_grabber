

CREATE PROCEDURE [finAnalytics].[calcRepReservPart2] 
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


    begin try
    begin tran  

    delete from finAnalytics.repReservBuckets where REPMONTH=@repmonth

    ---Пустышка для Динамика_3бакета
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )
    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='Динамика_3бакета'


    ---Пустышка для Динамика_4бакета
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='Динамика_4бакета'


    ---Пустышка для Динамика_5бакетов
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='Динамика_5бакетов'


    ---Пустышка для 6бакетов(Открытие)
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='6бакетов(Открытие)'


    ---Пустышка для 10бакетов(ТКБ)
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='10бакетов(ТКБ)'

    ---Пустышка для 5бакетов(ТКБ)
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='5бакетов(ТКБ)'



    ---Пустышка для 10бакетов(Экспо)
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'ОД' , pokazatelOrder=1
    union all
    Select pokazatel = 'Проценты' , pokazatelOrder=2
    union all
    Select pokazatel = 'Резерв НУ' , pokazatelOrder=3
    union all
    Select pokazatel = 'Резерв БУ' , pokazatelOrder=4
    union all
    Select pokazatel = 'Резерв НУ ОД' , pokazatelOrder=5
    union all
    Select pokazatel = 'Резерв НУ Проценты' , pokazatelOrder=6
    union all
    Select pokazatel = 'Резерв БУ ОД' , pokazatelOrder=7
    union all
    Select pokazatel = 'Резерв БУ Проценты' , pokazatelOrder=8
    union all
    Select pokazatel = 'Пени' , pokazatelOrder=9
    union all
    Select pokazatel = 'Госпошлины' , pokazatelOrder=10
    union all
    Select pokazatel = 'Резервы по пене и ГП НУ' , pokazatelOrder=11
    union all
    Select pokazatel = 'Резервы по пене и ГП БУ' , pokazatelOrder=12
    )c on 1=1

    where a.sprName='10бакетов(Экспо)'

    ---Пустышка для для_факт
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup


    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'Займы выданные + %' , pokazatelOrder=1
    union all
    Select pokazatel = 'Резервы по займам + %' , pokazatelOrder=2
    )c on 1=1

    where a.sprName='для_факт'


    ---Пустышка для для_trans
    INSERT INTO finAnalytics.repReservBuckets
	    (
	     bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup, overGroupName, overGroupOrder
	     )

    select

    a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,a.loadDate
    ,@repmonth
    ,c.pokazatel
    ,0
    ,c.pokazatelOrder
    ,b.nomenkGroup
    ,c.OverGroupName
    ,c.OverGroupOrder

    from finAnalytics.SPR_bucketsForReserv a
    inner join (
    SELECT nomenkGroup = 'ПТС' 
    union all select 'Installment' 
    union all select 'Бизнес-займы' 
    union all select 'PDL'
	union all select 'Автокредит'
	union all select 'Big Installment'
    ) b on 1=1
    inner join (
    Select pokazatel = 'Займы выданные' , pokazatelOrder=1, OverGroupName = 'ЗАЙМЫ выданные + %%', OverGroupOrder = 1
    union all
    Select pokazatel = '%% начисленные' , pokazatelOrder=2, OverGroupName = 'ЗАЙМЫ выданные + %%', OverGroupOrder = 1
    union all
    Select pokazatel = 'Резервы по займам БУ' , pokazatelOrder=3, OverGroupName = 'РЕЗЕРВЫ по займам и %% БУ', OverGroupOrder = 2
    union all
    Select pokazatel = 'Резервы по %% начисленным БУ' , pokazatelOrder=4, OverGroupName = 'РЕЗЕРВЫ по займам и %% БУ', OverGroupOrder =2
    union all
    Select pokazatel = 'Резервы по займам НУ' , pokazatelOrder=5, OverGroupName = 'РЕЗЕРВЫ по займам и %% НУ', OverGroupOrder =3
    union all
    Select pokazatel = 'Резервы по %% начисленным НУ' , pokazatelOrder=6, OverGroupName = 'РЕЗЕРВЫ по займам и %% НУ', OverGroupOrder =3
    )c on 1=1

    where a.sprName='для_trans'
    

    merge into finanalytics.repReservBuckets t1
    USING(
    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 1
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end
			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'ОД'
    ,[val] = a.zadolgOD
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    --and pbr.nomenkGroup ='Бизнес-займы'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 2
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Проценты'
    ,[val] = a.zadolgPrc
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 3
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв НУ'
    ,[val] = a.reservOD + a.reservPRC
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 4
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв БУ'
    ,[val] = a.reservBUODSum + a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 5
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв НУ ОД'
    ,[val] = a.reservOD
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 6
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв НУ Проценты'
    ,[val] = a.reservPRC
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 7
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв БУ ОД'
    ,[val] = a.reservBUODSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 8
    , pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резерв БУ Проценты'
    ,[val] = a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 9
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		--case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
		--				when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
		--				when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
		--				when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
		--				when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
		--				else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Пени'
    ,[val] = a.penyaSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 10
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Госпошлины'
    ,[val] = a.gosposhlSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 11
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по пене и ГП НУ'
    ,[val] = a.reservProchSumNU
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 12
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по пене и ГП БУ'
    ,[val] = a.reservBUPenyaSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName not in ('для_факт','для_trans','Для массива')--@sprName
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    ) t2 on (t1.bucketName=t2.bucketName and t1.sprName=t2.sprName and t1.groupOrder=t2.groupOrder and t1.repmonth=t2.repmonth and t1.pokazatel=t2.pokazatel and t1.nomenkGroup=t2.nomenkGroup)
    WHEN MATCHED THEN UPDATE
    set t1.rest=t2.rest;

    --Вставка для ФАКТ
    merge into finanalytics.repReservBuckets t1
    USING(
    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 1
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Займы выданные + %'
    ,[val] = a.zadolgOD + a.zadolgPrc
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_факт'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 2
    , [nomenkGroup] = pbr.nomenkGroup
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по займам + %'
    ,[val] = a.reservBUODSum + a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_факт'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    ) t2 on (t1.bucketName=t2.bucketName and t1.sprName=t2.sprName and t1.groupOrder=t2.groupOrder and t1.repmonth=t2.repmonth and t1.pokazatel=t2.pokazatel and t1.nomenkGroup=t2.nomenkGroup)
    WHEN MATCHED THEN UPDATE
    set t1.rest=t2.rest;

    --Вставка для Trans
    merge into finanalytics.repReservBuckets t1
    USING(
    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 1
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'ЗАЙМЫ выданные + %%'
    , [overGroupOrder] = 1
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Займы выданные'
    ,[val] = a.zadolgOD-- + a.zadolgPrc
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
    [bucketName] = 'в т.ч. кредитные каникулы'
    ,[sprName] = 'для_trans'
    ,[groupOrder] = (select max(groupOrder) from finAnalytics.SPR_bucketsForReserv where sprName ='для_trans') + 1
    ,[loadDate] = @repmonth
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = isnull(sum(pbr.val),0)
    , [pokazatelOrder] = 1
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'ЗАЙМЫ выданные + %%'
    , [overGroupOrder] = 1
    from(
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Займы выданные'
    ,[val] = a.zadolgOD

    from finAnalytics.PBR_MONTHLY a
    inner join (
            SELECT 
                 [dogNum] = a.number
                ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
                ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
             FROM dbo.dm_restructurings a
             where 1=1
                and a.period_start<=EOMONTH(@REPMONTH)
                and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
                --and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
            ) kk on a.dogNum=kk.dogNum and kk.rn=1

    where a.REPMONTH =@repmonth
    and a.nomenkGroup != '-'
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Автокредит'
	,[pokazatel] = 'Займы выданные'
	,[val] = 0
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Бизнес-займы'
	,[pokazatel] = 'Займы выданные'
	,[val] = 0
    ) pbr

    group by
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 2
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'ЗАЙМЫ выданные + %%'
    , [overGroupOrder] = 1
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = '%% начисленные'
    ,[val] = a.zadolgPrc
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
    [bucketName] = 'в т.ч. кредитные каникулы'
    ,[sprName] = 'для_trans'
    ,[groupOrder] = (select max(groupOrder) from finAnalytics.SPR_bucketsForReserv where sprName ='для_trans') + 1
    ,[loadDate] = @repmonth
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = isnull(sum(pbr.val),0)
    , [pokazatelOrder] = 2
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'ЗАЙМЫ выданные + %%'
    , [overGroupOrder] = 1
    from(
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = '%% начисленные'
    ,[val] = a.zadolgPrc

    from finAnalytics.PBR_MONTHLY a
    inner join (
            SELECT 
                 [dogNum] = a.number
                ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
                ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
             FROM dbo.dm_restructurings a
             where 1=1
                and a.period_start<=EOMONTH(@REPMONTH)
                and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
                --and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
            ) kk on a.dogNum=kk.dogNum and kk.rn=1

    where a.REPMONTH =@repmonth
    and a.nomenkGroup != '-'
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Автокредит'
	,[pokazatel] = '%% начисленные'
	,[val] = 0
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Бизнес-займы'
	,[pokazatel] = '%% начисленные'
	,[val] = 0
    ) pbr

    group by
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 3
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% БУ'
    , [overGroupOrder] = 2
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по займам БУ'
    ,[val] = a.reservBUODSum --+ a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 4
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% БУ'
    , [overGroupOrder] = 2
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по %% начисленным БУ'
    ,[val] = a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
    [bucketName] = 'в т.ч. кредитные каникулы'
    ,[sprName] = 'для_trans'
    ,[groupOrder] = (select max(groupOrder) from finAnalytics.SPR_bucketsForReserv where sprName ='для_trans') + 1
    ,[loadDate] = @repmonth
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = isnull(sum(pbr.val),0)
    , [pokazatelOrder] = 4
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% БУ'
    , [overGroupOrder] = 2
    from(
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по %% начисленным БУ'
    ,[val] = a.reservBUODSum + a.reservBUpPrcSum

    from finAnalytics.PBR_MONTHLY a
    inner join (
            SELECT 
                 [dogNum] = a.number
                ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
                ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
             FROM dbo.dm_restructurings a
             where 1=1
                and a.period_start<=EOMONTH(@REPMONTH)
                and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
                --and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
            ) kk on a.dogNum=kk.dogNum and kk.rn=1

    where a.REPMONTH =@repmonth
    and a.nomenkGroup != '-'
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Автокредит'
	,[pokazatel] = 'Резервы по %% начисленным БУ'
	,[val] = 0
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Бизнес-займы'
	,[pokazatel] = 'Резервы по %% начисленным БУ'
	,[val] = 0
    ) pbr

    group by
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup

    union all


    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 5
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% НУ'
    , [overGroupOrder] = 3
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по займам НУ'
    ,[val] = a.reservOD --+ a.reservBUpPrcSum
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
     a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = sum(pbr.val)
    , [pokazatelOrder] = 6
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% НУ'
    , [overGroupOrder] = 3
    from finAnalytics.SPR_bucketsForReserv a

    left join (
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по %% начисленным НУ'
    ,[val] = a.reservPRC
    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH =@repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where 1=1
    and a.sprName ='для_trans'
    and pbr.nomenkGroup != '-'

    group by 
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

    union all

    select
    [bucketName] = 'в т.ч. кредитные каникулы'
    ,[sprName] = 'для_trans'
    ,[groupOrder] = (select max(groupOrder) from finAnalytics.SPR_bucketsForReserv where sprName ='для_trans') + 1
    ,[loadDate] = @repmonth
    , [repmonth] = pbr.repmonth
    , [pokazatel] = pbr.pokazatel
    , [rest] = isnull(sum(pbr.val),0)
    , [pokazatelOrder] = 6
    , [nomenkGroup] = pbr.nomenkGroup
    , [overGroupName] = 'РЕЗЕРВЫ по займам и %% НУ'
    , [overGroupOrder] = 3
    from(
    select
    [repmonth] = a.repmonth
    ,[nomenkGroup] = /*case when a.nomenkGroup in ('Основной','ПТС31','Рефинансирование') then 'ПТС'
          when a.nomenkGroup in ('Installment','PromoInstallment','SmartInstallment') then 'Installment'
          when a.nomenkGroup in ('Бизнес-займ') then 'Бизнес-займы'
          when a.nomenkGroup in ('PDL') then 'PDL'
		  when a.nomenkGroup in ('Автокредит') then 'Автокредит'
          else '-' end*/
		  --case when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='ПТС' then 'ПТС'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
				--		when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
				--		else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[pokazatel] = 'Резервы по %% начисленным НУ'
    ,[val] = a.reservOD + a.reservPRC

    from finAnalytics.PBR_MONTHLY a
    inner join (
            SELECT 
                 [dogNum] = a.number
                ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
                ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
             FROM dbo.dm_restructurings a
             where 1=1
                and a.period_start<=EOMONTH(@REPMONTH)
                and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
                --and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
            ) kk on a.dogNum=kk.dogNum and kk.rn=1

    where a.REPMONTH =@repmonth
    and a.nomenkGroup != '-'
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Автокредит'
	,[pokazatel] = 'Резервы по %% начисленным НУ'
	,[val] = 0
	union all 
	select 
	[repmonth] = @repmonth
	,[nomenkGroup] = 'Бизнес-займы'
	,[pokazatel] = 'Резервы по %% начисленным НУ'
	,[val] = 0
    ) pbr

    group by
     pbr.repmonth
    , pbr.pokazatel
    , pbr.nomenkGroup
    ) t2 on (t1.bucketName=t2.bucketName and t1.sprName=t2.sprName and t1.groupOrder=t2.groupOrder and t1.repmonth=t2.repmonth and t1.pokazatel=t2.pokazatel and t1.nomenkGroup=t2.nomenkGroup)
    WHEN MATCHED THEN 
    UPDATE
    set t1.rest=t2.rest
    WHEN NOT MATCHED THEN 
    INSERT (bucketName, sprName, groupOrder, loadDate, repmonth, pokazatel, rest, pokazatelOrder, nomenkGroup, overGroupName, overGroupOrder)
    VALUES (t2.bucketName, t2.sprName, t2.groupOrder, t2.loadDate, t2.repmonth, t2.pokazatel, t2.rest, t2.pokazatelOrder, t2.nomenkGroup, t2.overGroupName, t2.overGroupOrder)
    ;

    commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc


    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета Части 2 для Отчета Резервы новый срез'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры расчета Части 2 для Отчета Резервы новый срез'

	 ----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
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
