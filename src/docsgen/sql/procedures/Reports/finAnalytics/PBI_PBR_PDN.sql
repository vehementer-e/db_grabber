



CREATE PROCEDURE [finAnalytics].[PBI_PBR_PDN]

	
AS
BEGIN


select
*
from(

select
[repmonth] = a.REPMONTH
,[Client] = a.Client
,[ClientID] = a.ClientID
,[INN] = a.INN

,[isZaemshik] = a.isZaemshik
,[isBankrot] = case when bnkrupt.Дата is not null then 
					case when a.REPMONTH between bnkrupt.nonBunkruptStartDate and bnkrupt.nonBunkruptEndDate then null
					else 'Да' end
				end
,[isBankrotDate] = case when bnkrupt.Дата is not null then 
					case when a.REPMONTH between bnkrupt.nonBunkruptStartDate and bnkrupt.nonBunkruptEndDate then null 
					else bnkrupt.Дата end
				end
,[isKK] = case when kk.dogNum is not null then 'Да' else null end
,[isKKSVO] = case when kksvo.dogNum is not null then 'Да' else null end

,[prod] = dwh2.finAnalytics.nomenk2prod(
						case when a.nomenkGroup is null then 
						case when left(a.finProd,3) = 'ПТС' then 'Основной'
					  when left(a.finProd,10) = 'Автомобиль' then 'Основной'
					  when left(a.finProd,8) = 'Автозайм' then 'Основной'
					  when left(a.finProd,11) = 'Бизнес займ' then 'Бизнес-займ' end
				else a.nomenkGroup end)
,[nomenkGroup] = case when a.nomenkGroup is null then 
					case when left(a.finProd,3) = 'ПТС' then 'Основной'
					  when left(a.finProd,10) = 'Автомобиль' then 'Основной'
					  when left(a.finProd,8) = 'Автозайм' then 'Основной'
					  when left(a.finProd,11) = 'Бизнес займ' then 'Бизнес-займ' end
				else a.nomenkGroup end

,[finProd] = a.finProd
,[dogNum] = a.dogNum

,[dogDate] = a.dogDate
,[saleDate] = a.saleDate
,[saleType] = a.saleType
,[CloseDate] = a.CloseDate

,[pogashenieDate] = a.pogashenieDate
,[pogashenieDateDS] = a.pogashenieDateDS
,[dogPeriodDays] = a.dogPeriodDays
,[dogSum] = a.dogSum
,[PDNOnSaleDate] = a.PDNOnSaleDate
,[PDNOnRepDate] = a.PDNOnRepDate

,[isRefinance] = a.isRefinance
,[isRestruk] = a.isRestruk

,[restOD] = a.zadolgOD
,[restPRC] = a.zadolgPrc
,[restPenya] = a.penyaSum
,[restGP] = a.gosposhlSum

,[reservNU_OD] = a.reservOD
,[reservNU_PRC] = a.reservPRC
,[reservNU_other] = a.reservProchSumNU

,[reservBU_OD] = a.reservBUODSum
,[reservBU_PRC] = a.reservBUpPrcSum
,[reservBU_other] = a.reservBUPenyaSum

,[prosDaysTotal] = a.prosDaysTotal
,[dogStatus] = a.dogStatus
,[isObespechZaym] = a.isObespechZaym

,[AccODNum] = a.AccODNum
,[AccPrcNum] = a.AccPrcNum
,[NMFKDate] = case when a.saleDate <= cast('2022-02-28' as date) then 'до 28.02.2022'
                      when a.saleDate between cast('2022-03-01' as date) and cast('2022-09-30' as date) then 'от 01.03.2022 до 30.09.2022'
                      when a.saleDate between cast('2022-10-01' as date) and cast('2022-10-31' as date) then 'от 01.10.2022 до 31.10.2022'
                      --when l1.saleDate between cast('2022-11-01' as date) and cast('2023-12-31' as date) then 4
					  when a.saleDate >= cast('2022-11-01' as date) then 'после 01.11.2022'
                      else '-' end
,[NMFK_A2] = case when a.dogPeriodDays <=30 and a.dogSum<=30000 then 'A2' else '-' end
,[Вид займа] = case when [isnew] is null then 'Нет маркировки' else [isnew]	end
,[Группа каналов] = case when [finChannelGroup] is null then 'Нет маркировки' else [finChannelGroup] end	
,[Канал] = case when [finChannel] is null then 'Нет маркировки' else [finChannel] end		
,[Направление] = case when [finBusinessLine] is null then 'Нет маркировки' else [finBusinessLine] end			
,[Продукт от первичного] = case when [prodFirst] is null then 'Нет маркировки' else [prodFirst] end				
,[Продукт Финансы] = case when [productType] is null then 'Нет маркировки' else [productType] end				
,[Группа RBP] = case when [RBP_GROUP] is null then 'Нет маркировки' else [RBP_GROUP] end				
,[isNewTerrRussia] = case when 
							   upper(a.addressReg) like upper('%Донецкая %')
							or upper(a.addressReg) like upper('%Луганская %')
							or upper(a.addressReg) like upper('%Запорожская %')
							or upper(a.addressReg) like upper('%Херсонская %')
							then 1 else 0 end
from dwh2.finAnalytics.PBR_MONTHLY a

----Привязываем банкротов
        left join (
        select [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
        ,[Заемщик] = b.Наименование
		,[nonBunkruptStartDate] = c.nonBunkruptStartDate
		,[nonBunkruptEndDate] = isnull(c.nonBunkruptEndDate,getdate())
        ,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

        from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
        left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
		left join dwh2.[finAnalytics].[SPR_notBunkrupt] c on b.Наименование = c.[client]
        where 1=1
        and a.ПометкаУдаления =  0x00
        and a.Проведен=0x01
        ) bnkrupt on a.Client=bnkrupt.[Заемщик] 
					and bnkrupt.rn=1 
					and bnkrupt.[Дата]<=eomonth(a.repmonth)
					and (nonBunkruptStartDate is null or eomonth(a.repmonth) not between nonBunkruptStartDate and nonBunkruptEndDate)

        -------Привязываем КК обычные
        left join (
        SELECT 
             [dogNum] = a.number
            ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
			,[period_start] = a.period_start
            ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
         FROM dwh2.dbo.dm_restructurings a
         where 1=1
            --and a.period_start<=EOMONTH(@REP_MONTH)
            and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
        ) kk on a.dogNum=kk.dogNum 
				and kk.rn=1
				and kk.period_start <= eomonth(a.repmonth)


-------Привязываем КК СВО
        left join (
        SELECT 
             [dogNum] = a.number
            ,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)--a.period_start
			,[period_start] = a.period_start
            ,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
         FROM dwh2.dbo.dm_restructurings a
         where 1=1
            --and a.period_start<=EOMONTH(@REP_MONTH)
            and upper(a.operation_type) in (upper('Кредитные каникулы')/*,upper('Заморозка 1.0')*/)
            and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
        ) kksvo on a.dogNum=kksvo.dogNum 
					and kksvo.rn=1
					and kksvo.period_start <= eomonth(a.repmonth)

where a.REPMONTH >='2022-12-01'
) l1

END
