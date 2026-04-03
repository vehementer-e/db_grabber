
CREATE PROCEDURE [finAnalytics].[calcRepReservPart1] 
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

    delete from finAnalytics.repReservMassive where REPMONTH=@repmonth
    
    INSERT INTO finAnalytics.repReservMassive
	(
	 repmonth, prosFrom, prosTo, bucketName, sprName, groupOrder, restOD, restODPred, 
     restPrc, restPrcPred, restPenya, restPenyaPred, restGP, restGPPred, reserv_NU, 
     reserv_NUPred, reserv_BU, reserv_BUPred, reservOD_NU, reservOD_NUPred, reservPRC_NU, 
     reservPRC_NUPred, reservOD_BU, reservOD_BUPred, reservPRC_BU, reservPRC_BUPred, 
     reservProch_NU, reservProch_NUPred, reservProch_BU, reservProch_BUPred, 
     c16restODPRC, c17restChange, c18reservBUChange, c19reservNUChange, c20AVGStavkaBU, c21AVGStavkaBUChange, 
     c22AVGStavkaNU, c23AVGStavkaNUChange, c24FA_BU_1, c25FA_BU_2, c26Check1, c27FA_NU_1, c28FA_NU_2, 
     c29Check2, c30Check3, c30Check4, nomenkGroup, loadDate
	 )
    ---Пустышка для всех продуктов
    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'Все продукты'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

    ---Пустышка для ПТС
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'ПТС'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

	---Пустышка для Автокредит
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'Автокредит'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

    ---Пустышка для Installment
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'Installment'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'


    ---Пустышка для Бизнес-займы
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'Бизнес-займы'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

    ---Пустышка для PDL
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'PDL'
    ,a.loadDate

	from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

	---Пустышка для Big Installment
    union all

    select
    @repmonth
    ,a.prosFrom
    ,a.prosTo
    ,a.bucketName
    ,a.sprName
    ,a.groupOrder
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ,'Big Installment'
    ,a.loadDate

    from finAnalytics.SPR_bucketsForReserv a
    where a.sprName='Для массива'

    ---Весь портфель
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup !='-'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Все продукты'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;


        ---ПТС
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='ПТС'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='ПТС'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;

		---Автокредит
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='Автокредит'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Автокредит'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;


        ---Installment
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='Installment'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Installment'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;
    


    ---Бизнес-займы
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='Бизнес-займы'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Бизнес-займы'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;


        ---PDL
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='PDL'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='PDL'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;


		---Big Installment
    MERGE INTO finAnalytics.repReservMassive t1
    USING(
    select
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate
    --, pbr.nomenkGroup
    , [repmonth] = @repmonth--pbr.repmonth

    , [restOD] = sum(pbr.restOD)
    , [restODPred] = sum(pbr.restODPred)

    , [restPrc] = sum(pbr.restPrc)
    , [restPrcPred] = sum(pbr.restPrcPred)

    , [restPenya] = sum(pbr.restPenya)
    , [restPenyaPred] = sum(pbr.restPenyaPred)

    , [restGP] = sum(pbr.restGP)
    , [restGPPred] = sum(pbr.restGPPred)

    , [reserv_NU] = sum(pbr.reserv_NU)
    , [reserv_NUPred] = sum(pbr.reserv_NUPred)

    , [reserv_BU] = sum(pbr.reserv_BU)
    , [reserv_BUPred] = sum(pbr.reserv_BUPred)

    , [reservOD_NU] = sum(pbr.reservOD_NU)
    , [reservOD_NUPred] = sum(pbr.reservOD_NUPred)

    , [reservPRC_NU] = sum(pbr.reservPRC_NU)
    , [reservPRC_NUPred] = sum(pbr.reservPRC_NUPred)

    , [reservOD_BU] = sum(pbr.reservOD_BU)
    , [reservOD_BUPred] = sum(pbr.reservOD_BUPred)

    , [reservPRC_BU] = sum(pbr.reservPRC_BU)
    , [reservPRC_BUPred] = sum(pbr.reservPRC_BUPred)

    , [reservProch_NU] = sum(pbr.reservProch_NU)
    , [reservProch_NUPred] = sum(pbr.reservProch_NUPred)

    , [reservProch_BU] = sum(pbr.reservProch_BU)
    , [reservProch_BUPred] = sum(pbr.reservProch_BUPred)

    , [c16restODPRC] = sum(pbr.restOD + pbr.restPrc)
    , [c17restChange] = sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred)
    , [c18reservBUChange] = sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred)
    , [c19reservNUChange] = sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred)
    , [c20AVGStavkaBU] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c21AVGStavkaBUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc) 
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end 
    , [c22AVGStavkaNU] = case when sum(pbr.restOD + pbr.restPrc) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc) else 0 end
    , [c23AVGStavkaNUChange] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred) else 0 end
    , [c24FA_BU_1] =case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c25FA_BU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) != 0 then 
                       sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c26Check1] = case when sum(pbr.restODPred + pbr.restPrcPred) != 0 and sum(pbr.restOD + pbr.restPrc) != 0 then 
                     round((sum(pbr.reserv_BU) - sum(pbr.reserv_BUPred))
                    - ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                     + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                     * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    - (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_BU + pbr.reservPRC_BU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_BUPred + pbr.reservPRC_BUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2), 2) else 0 end
    , [c27FA_NU_1] = case when sum(pbr.restODPred + pbr.restPrcPred) !=0 and sum(pbr.restOD + pbr.restPrc) !=0 then
                    (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c28FA_NU_2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2 else 0 end
    , [c29Check2] = case when sum(pbr.restOD + pbr.restPrc) != 0 and sum(pbr.restODPred + pbr.restPrcPred) !=0 then 
                    round((sum(pbr.reserv_NU) - sum(pbr.reserv_NUPred))
                    -
                    ((sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2)
                    -
                    (sum(pbr.restODPred + pbr.restPrcPred)
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred))
                    + (sum(pbr.restOD + pbr.restPrc) - sum(pbr.restODPred + pbr.restPrcPred))
                    * (sum(pbr.reservOD_nU + pbr.reservPRC_nU) / sum(pbr.restOD + pbr.restPrc)
                            - sum(pbr.reservOD_NUPred + pbr.reservPRC_NUPred) / sum(pbr.restODPred + pbr.restPrcPred)) / 2),2) else 0 end
    , [c30Check3] = round(sum(pbr.reserv_BU)
                    - sum(pbr.reservOD_BU)
                    - sum(pbr.reservPRC_BU)
                    ,2)
    , [c30Check4] = round(sum(pbr.reserv_NU)
                    - sum(pbr.reservOD_NU)
                    - sum(pbr.reservPRC_NU)
                    ,2)

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


    where a.sprName='Для массива'
    and pbr.nomenkGroup ='Big Installment'
    group by 
    a.prosFrom
    , a.prosTo
    , a.bucketName
    , a.sprName
    , a.groupOrder
    , a.loadDate


    ) t2 on (
            t1.repmonth=t2.repmonth 
            and t1.prosFrom=t2.prosFrom 
            and t1.prosTo=t2.prosTo 
            and t1.bucketName=t2.bucketName
            and t1.sprName=t2.sprName
            and t1.groupOrder=t2.groupOrder
            and t1.groupOrder=t2.groupOrder
            and t1.nomenkGroup='Big Installment'
            )
    WHEN MATCHED THEN UPDATE
    set t1.restOD=t2.restOD,
        t1.restODPred=t2.restODPred,
        t1.restPrc=t2.restPrc,
        t1.restPrcPred=t2.restPrcPred,
        t1.restPenya=t2.restPenya,
        t1.restPenyaPred=t2.restPenyaPred,
        t1.restGP=t2.restGP,
        t1.restGPPred=t2.restGPPred,
        t1.reserv_NU=t2.reserv_NU,
        t1.reserv_NUPred=t2.reserv_NUPred,
        t1.reserv_BU=t2.reserv_BU,
        t1.reserv_BUPred=t2.reserv_BUPred,
        t1.reservOD_NU=t2.reservOD_NU,
        t1.reservOD_NUPred=t2.reservOD_NUPred,
        t1.reservPRC_NU=t2.reservPRC_NU,
        t1.reservPRC_NUPred=t2.reservPRC_NUPred,
        t1.reservOD_BU=t2.reservOD_BU,
        t1.reservOD_BUPred=t2.reservOD_BUPred,
        t1.reservPRC_BU=t2.reservPRC_BU,
        t1.reservPRC_BUPred=t2.reservPRC_BUPred,
        t1.reservProch_NU=t2.reservProch_NU,
        t1.reservProch_NUPred=t2.reservProch_NUPred,
        t1.reservProch_BU=t2.reservProch_BU,
        t1.reservProch_BUPred=t2.reservProch_BUPred,
        t1.c16restODPRC=t2.c16restODPRC,
        t1.c17restChange=t2.c17restChange,
        t1.c18reservBUChange=t2.c18reservBUChange,
        t1.c19reservNUChange=t2.c19reservNUChange,
        t1.c20AVGStavkaBU=t2.c20AVGStavkaBU,
        t1.c21AVGStavkaBUChange=t2.c21AVGStavkaBUChange,
        t1.c22AVGStavkaNU=t2.c22AVGStavkaNU,
        t1.c23AVGStavkaNUChange=t2.c23AVGStavkaNUChange,
        t1.c24FA_BU_1=t2.c24FA_BU_1,
        t1.c25FA_BU_2=t2.c25FA_BU_2,
        t1.c26Check1=t2.c26Check1,
        t1.c27FA_NU_1=t2.c27FA_NU_1,
        t1.c28FA_NU_2=t2.c28FA_NU_2,
        t1.c29Check2=t2.c29Check2,
        t1.c30Check3=t2.c30Check3,
        t1.c30Check4=t2.c30Check4;

    commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета Части 1 для Отчета Резервы новый срез'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
    DECLARE @subject NVARCHAR(255) = 'Выполнение процедуры расчета Части 1 для Отчета Резервы новый срез'
    
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
