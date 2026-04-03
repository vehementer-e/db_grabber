

CREATE PROCEDURE [finAnalytics].[calcRepReservLena] 
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

	DECLARE @subject NVARCHAR(255)
	declare @emailList varchar(255)=''

    begin try
    begin tran  

    delete from finAnalytics.repReservMassiveLena where REPMONTH=@repmonth
    
    
	INSERT INTO finAnalytics.repReservMassiveLena
	(
	 [repmonth], [prosFrom], [prosTo], [bucketName], [sprName], [groupOrder], [restODPrc], 
	 [restODPrcPred], [reserv_NU], [reserv_NUPred], [reserv_BU], [reserv_BUPred], [AVGStavkaNU], 
	 [AVGStavkaNUPred], [AVGStavkaBU], [AVGStavkaBUPred], [nomenkGroup], [loadDate]
	 )
    ---Пустышка для всех продуктов
    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'Все продукты'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'

    ---Пустышка для ПТС
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'ПТС'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'

	---Пустышка для Автокредит
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'Автокредит'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'

    ---Пустышка для Installment
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'Installment'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'


    ---Пустышка для Бизнес-займы
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'Бизнес-займы'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'

    ---Пустышка для PDL
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'PDL'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'

	---Пустышка для Big Installment
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0
    ,'Big Installment'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива Лена'
	
	/*Данные по всем продуктам*/
	MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
					--	else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup !='-'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Все продукты'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

		/*Данные по ПТС*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='ПТС'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='ПТС'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

		/*Данные по всем Автокредит*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='Автокредит'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Автокредит'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

		/*Данные по Installment*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Installment' then 'Installment'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='PDL' then 'PDL'
					--	when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Автокредит' then 'Автокредит'
					--	else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) ='Бизнес-займ' then 'Бизнес-займы'
					when dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](a.nomenkGroup) end

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='Installment'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Installment'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

	/*Данные по Бизнес-займы*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='Бизнес-займы'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Бизнес-займы'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

		/*Данные по PDL*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Весь портфель
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='PDL'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='PDL'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];


		/*Данные по Big Installment*/
		MERGE INTO finAnalytics.repReservMassiveLena t1
    USING(
    ---Big Installment
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restODPrc] = sum(pbr.restOD) + sum(pbr.restPrc)
    , [restODPrcPred] = sum(pbr.restODPred) + sum(pbr.restPrcPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

	, [AVGStavkaNU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_NU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaNUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_NUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

	, [AVGStavkaBU] = case when (sum(pbr.restOD) + sum(pbr.restPrc)) != 0 
							then sum(pbr.reserv_BU) / (sum(pbr.restOD) + sum(pbr.restPrc))
							else 0 end
	, [AVGStavkaBUPred] = case when (sum(pbr.restODPred) + sum(pbr.restPrcPred)) != 0 
							then sum(pbr.reserv_BUPred) / (sum(pbr.restODPred) + sum(pbr.restPrcPred))
							else 0 end

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

    ,[restOD] = case when a.REPMONTH=@repmonth then a.zadolgOD else 0 end
    ,[restODPred] = case when a.REPMONTH<@repmonth then a.zadolgOD else 0 end

    ,[restPrc] = case when a.REPMONTH=@repmonth then a.zadolgPrc else 0 end
    ,[restPrcPred] = case when a.REPMONTH<@repmonth then a.zadolgPrc else 0 end

    ,[restPenya] = case when a.REPMONTH=@repmonth then a.penyaSum else 0 end
    ,[restPenyaPred] = case when a.REPMONTH<@repmonth then a.penyaSum else 0 end

    ,[restGP] = case when a.REPMONTH=@repmonth then a.gosposhlSum else 0 end
    ,[restGPPred] = case when a.REPMONTH<@repmonth then a.gosposhlSum else 0 end

    ,[reserv_NU] = case when a.REPMONTH=@repmonth then a.reservOD + a.reservPRC else 0 end
    ,[reserv_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD + a.reservPRC else 0 end

    ,[reserv_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end
    ,[reserv_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum + a.reservBUpPrcSum else 0 end

    ,[reservOD_NU] = case when a.REPMONTH=@repmonth then a.reservOD else 0 end
    ,[reservOD_NUPred] = case when a.REPMONTH<@repmonth then a.reservOD else 0 end

    ,[reservPRC_NU] = case when a.REPMONTH=@repmonth then a.reservPRC else 0 end
    ,[reservPRC_NUPred] = case when a.REPMONTH<@repmonth then a.reservPRC else 0 end

    ,[reservProch_NU] = case when a.REPMONTH=@repmonth then a.reservProchSumNU else 0 end
    ,[reservProch_NUPred] = case when a.REPMONTH<@repmonth then a.reservProchSumNU else 0 end

    ,[reservOD_BU] = case when a.REPMONTH=@repmonth then a.reservBUODSum else 0 end
    ,[reservOD_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUODSum else 0 end

    ,[reservPRC_BU] = case when a.REPMONTH=@repmonth then a.reservBUpPrcSum else 0 end
    ,[reservPRC_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUpPrcSum else 0 end

    ,[reservProch_BU] = case when a.REPMONTH=@repmonth then a.reservBUPenyaSum else 0 end
    ,[reservProch_BUPred] = case when a.REPMONTH<@repmonth then a.reservBUPenyaSum else 0 end

    ,[prosDaysTotal] = isnull(a.prosDaysTotal,0)

    from finAnalytics.PBR_MONTHLY a
    where a.REPMONTH between dateadd(month,-1,@repmonth) and @repmonth

    ) pbr on pbr.prosDaysTotal between a.prosFrom and a.prosTo


    where a.sprName='Для массива Лена'
    and pbr.nomenkGroup ='Big Installment'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate

	--order by a.groupOrder
	) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Big Installment'
            )
    WHEN MATCHED THEN UPDATE
    set t1.[restODPrc]=t2.[restODPrc],
        t1.[restODPrcPred]=t2.[restODPrcPred],
        t1.[reserv_NU]=t2.[reserv_NU],
        t1.[reserv_NUPred]=t2.[reserv_NUPred],
        t1.[reserv_BU]=t2.[reserv_BU],
        t1.[reserv_BUPred]=t2.[reserv_BUPred],
        t1.[AVGStavkaNU]=t2.[AVGStavkaNU],
        t1.[AVGStavkaNUPred]=t2.[AVGStavkaNUPred],
        t1.[AVGStavkaBU]=t2.[AVGStavkaBU],
        t1.[AVGStavkaBUPred]=t2.[AVGStavkaBUPred];

    commit tran
	
	set @subject = 'Данные для отчета ОД Резервы'
	DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры расчета данных для отчета ОД Резервы за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,(SELECT [link] FROM [dwh2].[finAnalytics].[SYS_SPR_linkReport] where repName = 'ОД Резервы (Лена)')
				)

	--declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,21,/*22,*/3,33))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;
	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета для Отчета Резервы 2'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
    set @subject = 'Ошибка выполнения процедуры расчета для Отчета Резервы 2'
	
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

	IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
    
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
