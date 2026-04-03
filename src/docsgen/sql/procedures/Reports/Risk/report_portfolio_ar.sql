CREATE procedure [Risk].[report_portfolio_ar]
as
begin

--ВОРОНКА
--Для выгрузки:
--	1. меняем дату отчета в блоке 0
--	2. добавляем новые периоды, в которых интересно отследить изменения в блоке 7
--	3. запускаем все 

--0. задаем дату начала выторки для отчетов
DECLARE @Date_rep date = '20231201';
SET XACT_ABORT  ON;
begin try
--1. соберем начальный дата сет из OriginationLog
drop table if exists #smpl;
SELECT distinct
		GUID
		,number									--номер заявки
		,stage									--этап стратегии
		,Next_step
		,call_date								--дата-время вызова стратегии
		,request_amount							--запрошенная клиентом сумма
		,is_installment							--флаг инстолмента
		,strategy_version			--стратегия
		,client_type_1				--тип клиента call1
		,client_type_2				--тип клиента call2
		,Decision					--решение на этапе или заявке
		,Decision_Code							--код отказа если отказ
		,COALESCE(
			case 
					when Decision_Code in
							('100.0100.001'
							,'100.0100.002'
							,'100.0100.003'
							,'100.0100.005'
							,'100.0100.113'
							,'100.0100.041'
							,'100.0070.007'
							,'100.0070.107'
							,'100.0070.207'
							)
						then '1. МИН.ТРЕБОВАНИЯ - ЗАЯВИТЕЛЬ'
					when Decision_Code in
							('100.0070.002'
							,'100.0110.006'
							,'100.0110.008'
							,'100.0110.011'
							,'100.0120.001'
							,'100.0120.071'
							,'100.0120.101'
							,'100.0120.102'
							,'100.0120.104'
							,'100.0120.091'
							)
						then '2. НЕГАТИВНАЯ ИНФОРМАЦИЯ - ВНУТРЕННИЕ ИСТОЧНИКИ'
					when Decision_Code = '100.0082.001'
						then '3.1. Федеральный розыск (XNEO)'
					when Decision_Code in
							('100.0080.005'
							,'100.0081.006'
							,'100.0081.007'
							,'100.0081.008'
							,'100.0981.006'
							,'100.0981.007'
							,'100.0781.006'
							,'100.0781.007'
							)
						then '3.2. ФССП'
					when Decision_Code in
							('100.0051.001'
							,'100.0951.001'
							,'100.0051.002'
							,'100.0051.004'
							,'100.0751.001'
							)
						then '3.3. СКОРИНГ (1) внешние модели'
					when decision_code in
							('200.0060.015'
							,'200.0061.001'
							,'200.0061.016'
							,'200.0761.002'
							,'200.0960.015'
							,'200.0961.002'
							,'200.0961.016'
							,'200.0761.016'
							,'200.0061.002'
							,'200.0760.015'
							,'200.0060.107'
							)
						then '4.1. БКИ_EQUI'
					when Decision_Code in
							('100.0060.015'
							,'100.0960.015'
							,'100.0060.107'
							,'100.0061.001'
							,'100.0061.002'
							,'100.0961.002'
							,'100.0061.003'
							,'100.0061.004'
							,'100.0961.004'
							,'100.0061.015'
							,'100.0961.015'
							,'100.0061.016'
							,'100.0961.016'
							,'100.0061.017'
							,'100.0961.017'
							,'100.0761.016'
							,'100.0760.015'
							,'100.0761.002'
							)
						then '4.2. БКИ EQUI+NBKI'
					else NULL
				end,
				case
					when Decision_Code in
							('100.0131.001'
							,'100.0131.002'
							)
						then '4.3. DTI_Платеж'
					when Decision_Code = '100.0016.002'
						then '5. СКОРИНГ (5) КОБАЛЬТ'
					when Decision_Code = '100.0861.001'
						then '6. СКОРИНГ (4) АНДЕРРАЙТИНГ'
					when Decision_Code = '100.0016.003'
						then '7???. СКОРИНГ (5) Фото паспорта'
					when decision = 'Decline' --and ol.Decision_Code is not null
						then 'Пошел быстро смотреть кто я'
			end) as Decision_description
		,APR						--
		,Branch_id					--
		,probation					--испытательный срок
		,no_probation				--
		,offername					--
		,last_name								--Фамилия клиента
		,first_name								--имя клиента
		,patronymic								--отчество клиента
		,cast(birth_date as date) birth_date	--дата рождения
		,Creation_place
		,okbscore								--Скрор от ОКБ
		,leadsource_exception_override_flg
		,personal_data_changed
		,ProductTypeCode
		,ProductTypeCode_real
		,isElligibleforFullAutoApproveChaCha
		,isFullAutoApprove
		,fl_approved_app_exist
		,declineOverrideCategory
		,case
				when active_summa is null or active_summa <= 0
					then '1. 0 RUR'
				when active_summa <= 20000
					then '2. 0-20000 RUR'
				when active_summa_total <= 50000
					then '3. 20000-50000 RUR'
				when active_summa_total > 50000
					then '5. 50000+ RUR'
			end as FSSP_CR
		,case
				when active_summa_total is null or active_summa_total <= 0
					then '1. 0 RUR'
				when active_summa_total <= 50000
					then '2. 0-50000 RUR'
				when active_summa_total <= 80000
					then '3. 50000-80000 RUR'
				when active_summa_total <= 120000
					then '4. 80000-120000 RUR'
				when active_summa_total > 120000
					then '5. 120000+ RUR'
			end as FSSP_all
	into #smpl
	from stg._loginom.originationlog with(nolock)
	where	call_date >= @Date_rep 
			and (
				number<>'19061300000088' 
				and number <> '19061300000089' 
				and number <> '20101300041806' 
				and number <> '21011900071506' 
				and number <> '21011900071507'
				)
			and username = 'service'
	;


--2. расчетные показатели по заявке и входящий DTI
drop table if exists #calc_lim_call_1;
select *
		,case
			when incoming_DTI is null 
				then '00.нд'
			when incoming_DTI < 0.5
				then '01.[0; 0,5)'
			when incoming_DTI >= 0.5
					and incoming_DTI < 0.8
				then '02.[0,5; 0,8)'
			when incoming_DTI >= 0.8
				then '03.[0,8; inf)'
			else '11.error'
		end as incoming_DTI_group
		,row_number() over (partition by number, stage order by call_date DESC) as rn
	into #calc_lim_call_1
	from stg._loginom.calculated_term_and_amount_installment with (nolock)  
	where number in (select distinct number from #smpl)
		and Stage in ('Call 1', 'Call 2')
;
--select * from #calc_lim_call_1

--3. Вытащим лидсорс и группу по заявленному доходу
drop table if exists #app_ls;
select number
		,leadsource
		,case 
			when Income_amount is null    then '00. n/d'
			when Income_amount <= 25000   then '01. <= 20 000'
			when Income_amount <= 50000   then '02. (20 000; 50 000]'
			when Income_amount <= 75000   then '03. (50 000; 75 000]'
			when Income_amount <= 100000  then '04. (75 000; 100 000]'
			when Income_amount <= 125000  then '05. (100 000; 125 000]'
			when Income_amount <= 150000  then '06. (125 000; 150 000]'
			when Income_amount <= 175000  then '07. (150 000; 175 000]'
			when Income_amount <= 200000  then '08. (175 000; 200 000]'
			when Income_amount <= 225000  then '09. (200 000; 225 000]'
			when Income_amount <= 250000  then '10. (225 000; 250 000]'
			when Income_amount >  250000  then '11. > 250 000'
			else 'error'
		end as gr_income_ammount
		,request_amount
		,row_number() over (partition by number order by Stage_date DESC) as rn
	into #app_ls
	from stg._loginom.application with (nolock)  
	where number in (select distinct number from #smpl)
		and Stage = 'Call 1'
;		
--select * from #app_ls

--4. Добавим ОКБскор
drop table if exists #okb;
select number
		,[value]
		,ROW_NUMBER() OVER(PARTITION BY number ORDER BY call_date DESC) rn
	into #okb
	from [stg].[_loginom].[Origination_okbscore_parse] with(nolock) -- LoginomDB.LoginomDB.dbo.[Origination_okbscore_parse] with(nolock)
	where [key]='score' 
		and [value] is not null
		and number in (select distinct number from #smpl)
	;

--Признак количества закрытых кредитов ВСЕХ типов
drop table if exists #cnt_repeated_credits;
select distinct
		number
		,max([values]) OVER (PARTITION BY [datetime]) as closed_credit_count
	into #cnt_repeated_credits
	from stg._loginom.strategy_calc with(nolock) 
	where number in (select distinct number from #smpl)
		and names = 'closed_credit_count'
;
--Признак количества закрытых кредитов ИНСТ типов
drop table if exists #cnt_repeated_credits_INST;
select distinct
		number
		,max([values]) OVER (PARTITION BY [datetime]) as closed_credit_count
	into #cnt_repeated_credits_INST
	from stg._loginom.strategy_calc with(nolock) 
	where number in (select distinct number from #smpl)
		and names = 'cnt_closed_inst'
;
--Признак количества закрытых кредитов ПДЛ типов
drop table if exists #cnt_repeated_credits_PDL;
select distinct
		number
		,max([values]) OVER (PARTITION BY [datetime]) as closed_credit_count
	into #cnt_repeated_credits_PDL
	from stg._loginom.strategy_calc with(nolock) 
	where number in (select distinct number from #smpl)
		and names = 'cnt_closed_pdl'
;
--Признак количества закрытых кредитов ПТС типов
drop table if exists #cnt_repeated_credits_PTS;
select distinct
		number
		,max([values]) OVER (PARTITION BY [datetime]) as closed_credit_count
	into #cnt_repeated_credits_PTS
	from stg._loginom.strategy_calc with(nolock) 
	where number in (select distinct number from #smpl)
		and names = 'cnt_closed_pts'





--пересадка
drop table if exists #prod_changed;
/*with tmp as (
			select number, Value as GUID
				from stg._loginom.application with(nolock)
					CROSS APPLY STRING_SPLIT(sourceRequests, ';')
				where number in (select distinct number from #smpl)
			)
*/
select number
		,sourceRequest
		,rn = row_number() over(partition by number order by stage_date DESC)
	into #prod_changed
	from stg._loginom.application with(nolock)
	where number in (select distinct number from #smpl)
		and sourceRequest is not null
		and stage = 'Call 1'
;
--select * from #prod_changed;

/*
--продукт на преколе
drop table if exists #precall_Inst_PDL;
with tmp as (select guid, Value as Product
				from stg._loginom.originationlog with(nolock)
					CROSS APPLY STRING_SPLIT(availableProductType_code, ';')
				where call_date >= @Date_rep)
			
select guid
		,flg = 1
	into #precall_Inst_PDL
	from tmp
	where product like '%installment%'
		or product like '%pdl%'
;

--список GUID
drop table if exists #all_GUID;
select distinct guid
	into #all_GUID
	from stg._loginom.originationlog ol with(nolock)
	where guid in (select distinct guid from #smpl)
		or guid in (select distinct guid from #precall_Inst_PDL)
;



drop table if exists #smpl_guid;
select gi.guid
		,ol.stage
		,cast(ol.call_date as smalldatetime) as call_date
		,ol.decision
		,ol.decision_code
		,COALESCE(
			case 
					when Decision_Code in
							('100.0100.001'
							,'100.0100.002'
							,'100.0100.003'
							,'100.0100.005'
							,'100.0100.113'
							,'100.0100.041'
							,'100.0070.007'
							,'100.0070.107'
							,'100.0070.207'
							)
						then '1. МИН.ТРЕБОВАНИЯ - ЗАЯВИТЕЛЬ'
					when Decision_Code in
							('100.0070.002'
							,'100.0110.006'
							,'100.0110.008'
							,'100.0110.011'
							,'100.0120.001'
							,'100.0120.071'
							,'100.0120.101'
							,'100.0120.102'
							,'100.0120.104'
							,'100.0120.091'
							)
						then '2. НЕГАТИВНАЯ ИНФОРМАЦИЯ - ВНУТРЕННИЕ ИСТОЧНИКИ'
					when Decision_Code = '100.0082.001'
						then '3.1. Федеральный розыск (XNEO)'
					when Decision_Code in
							('100.0080.005'
							,'100.0081.006'
							,'100.0081.007'
							,'100.0081.008'
							,'100.0981.006'
							,'100.0981.007'
							,'100.0781.006'
							,'100.0781.007'
							)
						then '3.2. ФССП'
					when Decision_Code in
							('100.0051.001'
							,'100.0951.001'
							,'100.0051.002'
							,'100.0051.004'
							,'100.0751.001'
							)
						then '3.3. СКОРИНГ (1) внешние модели'
					when decision_code in
							('200.0060.015'
							,'200.0061.001'
							,'200.0061.016'
							,'200.0761.002'
							,'200.0960.015'
							,'200.0961.002'
							,'200.0961.016'
							,'200.0761.016'
							,'200.0061.002'
							,'200.0760.015'
							,'200.0060.107'
							)
						then '4.1. БКИ_EQUI'
					when Decision_Code in
							('100.0060.015'
							,'100.0960.015'
							,'100.0060.107'
							,'100.0061.001'
							,'100.0061.002'
							,'100.0961.002'
							,'100.0061.003'
							,'100.0061.004'
							,'100.0961.004'
							,'100.0061.015'
							,'100.0961.015'
							,'100.0061.016'
							,'100.0961.016'
							,'100.0061.017'
							,'100.0961.017'
							,'100.0761.016'
							,'100.0760.015'
							,'100.0761.002'
							)
						then '4.2. БКИ EQUI+NBKI'
					else NULL
				end,
				case
					when Decision_Code in
							('100.0131.001'
							,'100.0131.002'
							)
						then '4.3. DTI_Платеж'
					when Decision_Code = '100.0016.002'
						then '5. СКОРИНГ (5) КОБАЛЬТ'
					when Decision_Code = '100.0861.001'
						then '6. СКОРИНГ (4) АНДЕРРАЙТИНГ'
					when Decision_Code = '100.0016.003'
						then '7???. СКОРИНГ (5) Фото паспорта'
					when decision = 'Decline' --and ol.Decision_Code is not null
						then 'Пошел быстро смотреть кто я'
			end) as Decision_description

	into #smpl_guid
	from #precall_Inst_PDL as gi
		left join stg._loginom.originationlog as ol with(nolock)
			on gi.guid = ol.guid
			and ol.stage = 'Precall 1'
	where gi.flg = 1
*/



--5. Соберем общий датасет БЕЗ ДУБЛЕЙ
drop table if exists #stages;
select 
--		ag.guid
--		,
		num.number
--		,cast(isnull(c1.call_date, pre.call_date) as smalldatetime) as call_date
		,cast(c1.call_date as smalldatetime) as call_date
		,c1.client_type_1

		,case 
			when c5.Decision_Code  is not null then c5.Decision_Code
			when c3.Decision_Code  is not null then c3.Decision_Code
			when c2.Decision_Code  is not null then c2.Decision_Code
			when c15.Decision_Code is not null then c15.Decision_Code
			when c12.Decision_Code is not null then c12.Decision_Code
			when c1.Decision_Code is not null then c1.Decision_Code
			else ''
--			else pre.Decision_Code
		end as Decision_Code
		,case 
			when c5.decision = 'Accept' then 'Фин. одобрено'
			when c5.Decision_description  is not null then c5.Decision_description
			when c3.Decision_description  is not null then c3.Decision_description
			when c2.Decision_description  is not null then c2.Decision_description
			when c15.Decision_description is not null then c15.Decision_description
			when c12.Decision_description is not null then c12.Decision_description
			when c1.Decision_description is not null then c1.Decision_description
--			when pre.Decision_description is not null then pre.Decision_description
			else 'потеряшки'
		end as Decision_description		

		,c12.isElligibleforFullAutoApproveChaCha
		,c12.isFullAutoApprove
		,c12.fl_approved_app_exist
		,c1.declineOverrideCategory
		,cl.incoming_DTI_group
		,ls.leadsource
		,case
				when ls.leadsource = 'bankiru-installment-ref' or ls.leadsource = 'bankiru-deepapi' then 'ИСТИНА'
				else 'ЛОЖЬ'
			end as Banki_ru
		,case 
				when c1.call_date >= '20240101' 			and c1.call_date < '20240116 12:01'		then '01. с 01.01.2024 по 16.01.2024 12:00'
				when c1.call_date >= '20240116 12:01'		and c1.call_date < '20240119 14:24:27'	then '02. с 16.01.2024 по 19.01.2024 14:24'
				when c1.call_date >= '20240119 14:24:27'	and c1.call_date < '20240122 12:08'		then '03. с 19.01.2024 по 22.01.2024 12:08'
				when c1.call_date >= '20240122 12:08' 		and c1.call_date < '20240124 12:45'		then '04. с 22.01.2024 по 24.01.2024 12:45'
				when c1.call_date >= '20240124 12:45'		and c1.call_date < '20240201'			then '05. с 24.01.2024 по 31.01.2024'	
				when c1.call_date >= '20240201'				and c1.call_date < '20240202 11:54:40'	then '06. с 01.02.2024 по 02.02.2024 11:54'					
				when c1.call_date >= '20240202 11:54:40'	and c1.call_date < '20240206 11:45'		then '07. с 02.02.2024 по 06.02.2024 11:45'
				when c1.call_date >= '20240206 11:45'		and c1.call_date < '20240220 13:10:02'	then '08. с 06.02.2024 по 20.02.2024 13:10'
				when c1.call_date >= '20240220 13:10:02'	and c1.call_date < '20240301'			then '09. c 20.02.2024 по 29.02.2024'
				when c1.call_date >= '20240301'				and c1.call_date < '20240325 12:25'		then '10. c 01.03.2024 по 25.03.2024 12:25'
				when c1.call_date >= '20240325 12:25'		and c1.call_date < '20240401'			then '11. c 25.03.2024 по 31.03.2024'
				when c1.call_date >= '20240401'				and c1.call_date < '20240402 15:52:30'	then '12. c 01.04.2024 по 02.04.2024 15:52'
				when c1.call_date >= '20240402 15:52:30'	and c1.call_date < '20240415 14:02:48'	then '13. с 02.04.2024 по 15.04.2024 14:02'
				when c1.call_date >= '20240415 14:02:48'	and c1.call_date < '20240418 13:29:45'	then '14. с 15.04.2024 по 18.04.2024 13:29'
				when c1.call_date >= '20240418 13:29:45'	and c1.call_date < '20240425 00:00:00'	then '15. с 18.04.2024 по 24.04.2024 23:59'
				when c1.call_date >= '20240425 00:00:00'	and c1.call_date < '20240426 00:00:00'	then '16. с 25.04.2024 по 25.04.2024 23:59'
				when c1.call_date >= '20240426 00:00:00'	and c1.call_date < '20240501 00:00:00'	then '17. с 26.04.2024 по 30.04.2024 23:59'
				when c1.call_date >= '20240501 00:00:00'	and c1.call_date < '20240514 22:10:00'	then '18. с 01.05.2024 по 14.05.2024 22:10'
				when c1.call_date >= '20240514 22:10:00'	and c1.call_date < '20240601'			then '19. с 14.05.2024 по 31.05.2024'
				when c1.call_date >= '20240601'				and c1.call_date < '20240618 11:15'		then '20. с 01.06.2024 по 18.06.2024 11:15'
				when c1.call_date >= '20240618 11:15'		and c1.call_date < '20240701'			then '21. с 18.06.2024 по 30.06.2024'
				when c1.Call_date >= '20240701'				and c1.call_date < '20240801'			then '22. c 01.07.2024 по 31.07.2024'
				when c1.call_date >= '20240801'				and c1.call_date < '20240812 12:12'		then '23. c 01.08.2024 по 12.08.2024 12:12'
				when c1.call_date >= '20240812 12:12'		and c1.call_date < '20240817'			then '24. c 12.08.2024 по 16.08.2024'
				when c1.call_date >= '20240817'				and c1.call_date < '20240821 14:34'		then '25. c 17.08.2024 по 21.08.2024 14:34'
				when c1.call_date >= '20240821 14:34'		and c1.call_date < '20240824'			then '25. c 21.08.2024 по 23.08.2024'
				when c1.call_date >= '20240824'				and c1.call_date < '20240901'			then '26. c 24.08.2024 по 31.08.2024'
				when c1.call_date >= '20240901'				and c1.call_date < '20241001'			then '27. c 01.09.2024 по 30.09.2024'
				when c1.call_date >= '20241001'				and c1.call_date < '20241009 11:09'		then '28. c 01.10.2024 по 09.10.2024 11:09'
				when c1.call_date >= '20241009 11:09'		and c1.call_date < '20241015'			then '29. c 09.10.2024 по 15.10.2024'
				when c1.call_date >= '20241015'														then '30. c 15.10.2024 по today'

			 end as period_flg
		,case
					 when okb.[value] is null   then '00. null)'
					 when okb.[value] <410		then '01. <410)'
					 when okb.[value] <450 		then '02. 410-450)'
					 when okb.[value] <500 		then '03. 450-500)'
					 when okb.[value] <600 		then '04. 500-600)'
					 when okb.[value] >=600 	then '05. 600+'
			end as okb_gr
/*--PRECALL 1
		,case
			when pre.guid is not null then 1
			else 0
		end as Precall_incoming
		,case
			when pre.decision = 'Accept' then 1
			else 0
		end as Precall_accept
*/
--CALL 1
		,case
			when c1.number is not null then 1
			else 0
		end as Call1_incoming
		,case
			when c1.decision = 'Accept' then 1
			else 0
		end as Call1_accept
--CALL 1.2
		,case
			when c12.number is not null then 1
			else 0
		end as Call12_incoming
		,case
			when c12.decision = 'Accept' then 1
			else 0
		end as Call12_accept
		,c12.fl_autoapp_JS
--CALL 1.5
		,case
			when c15.number is not null then 1
			else 0
		end as Call15_incoming
		,case
			when c15.decision = 'Accept' then 1
			else 0
		end as Call15_accept
--CALL 2
		,case
			when c2.number is not null then 1
			else 0
		end as Call2_incoming
		,case
			when c2.decision = 'Accept' then 1
			else 0
		end as Call2_accept
		,c2.fl_autoapp
--CALL 3
		,case
			when c3.number is not null then 1
			else 0
		end as Call3_incoming
		,case
			when c3.decision = 'Accept' then 1
			else 0
		end as Call3_accept
--CALL 5
		,case
			when c5.number is not null then 1
			else 0
		end as Call5_incoming
		,case
			when c5.decision = 'Accept' then 1
			else 0
		end as Call5_accept

		,case when (vi.[Номер заявки] is not null) then 1 else 0 end as cheks
		,case when (vi2.[Номер заявки] is not null) then 1 else 0 end as verif

		,case when cr.external_id is not null then 1 else 0 end as fl_loan
		,case when cr.external_id is not null then cast(cr.amount as float) else 0 end as loan_amount
		,ls.gr_income_ammount
		,c1.FSSP_CR
		,c1.FSSP_ALL
		,case 
			when c5.productTypeCode  is not null then c5.productTypeCode
			when c3.productTypeCode  is not null then c3.productTypeCode
			when c2.productTypeCode  is not null then c2.productTypeCode
			when c15.productTypeCode is not null then c15.productTypeCode
			when c12.productTypeCode is not null then c12.productTypeCode
			else c1.productTypeCode
		end as product
		,cr.pdn as pdn_fact
		, case
				when cr.pdn <= 0.5
					then '1. <=0,5]'
				when cr.pdn > 0.5 and cr.pdn <= 0.8
					then '2. 0,5 - 0,8]'
				when cr.pdn > 0.8
					then '3. > 0,8'
				else 'Ошибка'
			end as pdn_fact_bucket

		,case
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) is null   then '00. n/d'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) = 0		then '01. 0'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) <= 5000   then '02. <= 5 000'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) <= 10000  then '03. (5 000; 10 000]'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) <= 15000  then '04. (10 000; 15 000]'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) <= 20000  then '05. (15 000; 20 000]'
				when isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) <= 30000  then '06. (20 000; 30 000]'
				else 'error'
			end as limit_bucket_PDL
		,case
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) is null   then '00. n/d'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) = 0		 then '01. 0'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 5000   then '02. <= 5 000'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 10000  then '03. (5 000; 10 000]'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 15000  then '04. (10 000; 15 000]'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 20000  then '05. (15 000; 20 000]'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 30000  then '06. (20 000; 30 000]'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 50000  then '07. (30 000; 50 000]'
				when isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) <= 100000 then '08. (50 000; 100 000]'
				else 'error'
			end as limit_bucket_INST

		,isnull(cl2.MAX_PMT_LIMIT_PDL, cl.MAX_PMT_LIMIT_PDL) as MAX_PMT_LIMIT_PDL
		,isnull(cl2.MAX_PMT_LIMIT_INST, cl.MAX_PMT_LIMIT_INST) as MAX_PMT_LIMIT_INST
		,ls.Request_amount
		,case
				when ls.Request_amount is null   then '00. n/d'
				when ls.Request_amount = 0		 then '01. 0'
				when ls.Request_amount < 5000   then '02. (0; 5 000)'
				when ls.Request_amount < 10000  then '03. [5 000; 10 000)'
				when ls.Request_amount <= 15000  then '04. [10 000; 15 000]'
				when ls.Request_amount <= 20000  then '05. (15 000; 20 000]'
				when ls.Request_amount <= 30000  then '06. (20 000; 30 000]'
				when ls.Request_amount <= 50000  then '07. (30 000; 50 000]'
				when ls.Request_amount <= 75000  then '08. (50 000; 75 000]'
				when ls.Request_amount <= 100000 then '09. (75 000; 100 000]'
			end as request_amount_bucket
			,cnt_rep.closed_credit_count
			,cnt_inst.closed_credit_count as cnt_inst
			,cnt_PDL.closed_credit_count as cnt_PDL
			,cnt_PTS.closed_credit_count as cnt_PTS

			,case
					when cnt_rep.closed_credit_count >= 5 then 1
					else 0
				end as IsMore5ClosedCredits
			,case
					when pc.number is not null then 1
					else 0
				end as IsChangeProduct

	into #stages
	from 
/*		(select distinct GUID from #all_GUID) as ag
		left join 
					(
					select guid
							,stage
							,call_date
							,decision
							,decision_code
							,Decision_description
						from #smpl_guid
					) as pre
				on ag.guid = pre.guid

			left join 
*/					(select distinct /*tmp.guid, */tmp.number 
						from #smpl as tmp
							left join dbo.dm_Factor_Analysis as dbl
								on tmp.number = dbl.[Номер]
						where tmp.Is_installment=1 
							and tmp.stage = 'Call 1' 
--							and tmp.call_date >= @Date_rep
							and dbl.[Дубль] = 0
					) as num
/*				on ag.GUID = num.guid
*/
--CALL 1
			left join 
					(select number
							,stage
							,call_date
							,decision
							,Decision_Code
							,Decision_description
							,client_type_1
							,declineOverrideCategory
							,FSSP_CR
							,FSSP_ALL
							,productTypeCode				
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 1'
					) as c1
				on num.number = c1.number
					and c1.rn = 1
--CALL 1.2
			left join 
					(select number
							,stage
							,decision
							,Decision_Code
							,Decision_description
							,isElligibleforFullAutoApproveChaCha
							,isFullAutoApprove
							,fl_approved_app_exist
							,productTypeCode
							,case 
									when Decision = 'Accept' and Next_step = 'Call 5' then 1 
									else 0 
								end as fl_autoapp_JS
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 1.2'
					) as c12
				on num.number = c12.number
					and c12.rn = 1
--CALL 1.5
			left join 
					(select number
							,stage
							,decision
							,Decision_Code
							,Decision_description
							,productTypeCode
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 1.5'
					) as c15
				on num.number = c15.number
					and c15.rn = 1
--CALL 2
			left join 
					(select number
							,stage
							,decision
							,Decision_Code
							,Decision_description
							,productTypeCode
							,case 
									when Decision = 'Accept' 
											and Next_step = 'Call 5' 
											and Call_date <= '20240514 22:10:00'
										then 1
									else 0 
								end as fl_autoapp
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 2'
					) as c2
				on num.number = c2.number
					and c2.rn = 1
--CALL 3
			left join 
					(select number
							,stage
							,decision
							,Decision_Code
							,Decision_description
							,productTypeCode
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 3'
					) as c3
				on num.number = c3.number
					and c3.rn = 1
--CALL 5
			left join 
					(select number
							,stage
							,decision
							,Decision_Code
							,Decision_description
							,productTypeCode
							,row_number() over(partition by number order by call_date DESC) as rn
						from #smpl
						where stage = 'Call 5'
					) as c5
				on num.number = c5.number
					and c5.rn = 1
--Чекеры
			left join 
				(select distinct [Номер заявки]
					from dbo.dm_FedorVerificationRequests_without_coll with(nolock)
					where [Статус]='Контроль данных' 
							and [Состояние заявки] = 'В работе' 
							and [Дата статуса] >= @Date_rep
				) vi
				on num.Number = vi.[Номер заявки]
			left join 
				(select distinct [Номер заявки]
					from dbo.dm_FedorVerificationRequests_without_coll with(nolock)
					where [Статус]='Верификация клиента' 
						and [Состояние заявки] = 'В работе' 
						and [Дата статуса] >= @Date_rep
				) vi2
				on num.Number = vi2.[Номер заявки]

--выдачи
			left join dwh2.risk.credits as cr with(nolock)
				on num.Number = cr.external_id
--OKB_score
			left join #okb as okb
				on num.Number = okb.Number
					and okb.rn = 1
			left join #calc_lim_call_1 as cl
				on num.Number = cl.Number
					and cl.rn = 1
					and cl.stage = 'Call 1'
			left join #calc_lim_call_1 as cl2
				on num.Number = cl2.Number
					and cl2.rn = 1
					and cl2.stage = 'Call 2'
			left join #app_ls as ls
				on num.number = ls.number
					and ls.rn = 1
			
			left join #cnt_repeated_credits as cnt_rep
				on num.number=cnt_rep.number
			left join #prod_changed as pc
				on num.number = pc.number
				and pc.rn = 1



			left join #cnt_repeated_credits_INST as cnt_inst
				on num.number = cnt_inst.number
			left join #cnt_repeated_credits_PDL as cnt_PDL
				on num.number = cnt_PDL.number
			left join #cnt_repeated_credits_PTS as cnt_PTS
				on num.number = cnt_PTS.number;



drop table if exists #stage1;
--6. Итогвый датасет дял построения отчета
select 
		period_flg
		,datepart(ww, call_date) as week_of_year
		,concat(FORMAT( DATEADD(WEEK, DATEDIFF(WEEK, 0, call_date), 0), 'dd.MM') , ' - ' ,-- Начало недели (понедельник)
			FORMAT(DATEADD(WEEK, DATEDIFF(WEEK, 0, call_date), 6),'dd.MM')) AS [week]   -- Конец недели (воскресенье)
--		,guid
		,number
		,product
		,case
				when product = 'PDL' then MAX_PMT_LIMIT_PDL
				when product = 'INST' then MAX_PMT_LIMIT_INST
			end as MAX_PMT_LIMIT
		,case
				when request_amount is null or request_amount = 0 then 0
				when product = 'PDL' then (MAX_PMT_LIMIT_PDL / isnull(request_amount, 0))
				when product = 'INST' then (MAX_PMT_LIMIT_INST / isnull(request_amount, 0))
			end as Cust_Satisfaction
		,case
				when request_amount is null or request_amount = 0 then '00. null'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.1  then '01. [0-0.1)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.2  then '02. [0.1-0.2)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.3  then '03. [0.2-0.3)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.4  then '04. [0.3-0.4)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.5  then '05. [0.4-0.5)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.6  then '06. [0.5-0.6)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.7  then '07. [0.6-0.7)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.8  then '08. [0.7-0.8)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.9  then '09. [0.8-0.9)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 1.0  then '10. [0.9-1.0)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount >= 1.0 then '11. [1.0-inf)'

				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.1  then '01. [0-0.1)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.2  then '02. [0.1-0.2)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.3  then '03. [0.2-0.3)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.4  then '04. [0.3-0.4)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.5  then '05. [0.4-0.5)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.6  then '06. [0.5-0.6)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.7  then '07. [0.6-0.7)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.8  then '08. [0.7-0.8)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.9  then '09. [0.8-0.9)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 1.0  then '10. [0.9-1.0)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount >= 1.0 then '11. [1.0-inf)'
				
				else 'something wrong'
			end as gr_Cust_Satisfaction
		,cast(call_date as date) as dt
		,okb_gr
		,Decision_Code
		,Decision_description
		,incoming_DTI_group
		,client_type_1
		,isElligibleforFullAutoApproveChaCha
		,isFullAutoApprove
		,declineOverrideCategory
		,leadsource
		,Banki_ru
		,limit_bucket_PDL
		,limit_bucket_INST
		,request_amount_bucket
		,case
				when leadsource = 'bankiru-installment-ref' then 'Old'
				when leadsource = 'bankiru-deepapi' then 'API'
				else ''
			end as Banki_Type
		,gr_income_ammount
		,pdn_fact_bucket
--		,sum(Precall_incoming) as Precall_incoming
--		,sum(Precall_accept) as Precall_accept
		,sum(Call1_incoming) as Call1_incoming
		,sum(Call1_accept) as Call1_accept
		,sum(Call12_incoming) as Call12_incoming
		,sum(Call12_accept) as Call12_accept
		,sum(fl_autoapp_JS) as fl_autoapp_JS
		,sum(cheks) as cheks
		,sum(Call15_incoming) as Call15_incoming
		,sum(Call15_accept) as Call15_accept
		,sum(Call2_incoming) as Call2_incoming
		,sum(Call2_accept) as Call2_accept
		,sum(fl_autoapp) as autoapp
		,sum(verif) as verif
		,sum(Call3_incoming) as Call3_incoming
		,sum(Call3_accept) as Call3_accept
		,sum(Call5_incoming) as Call5_incoming
		,sum(Call5_accept) as Call5_accept
		,sum(fl_loan) as cnt_loan
		,sum(cast(loan_amount as float)) as sum_loans
		,sum(case when Banki_ru = 'ЛОЖЬ' then Call1_incoming else 0 end) as Other_LG_call1
		,sum(case when Banki_ru = 'ЛОЖЬ' then Call5_accept else 0 end) as Other_LG_call5acc

		,sum(case when Banki_ru = 'ИСТИНА' then Call1_incoming  else 0 end) as BankiRu_All_call1
		,sum(case when Banki_ru = 'ИСТИНА' then Call5_accept else 0 end) as BankiRu_All_call5acc

		,sum(case when Banki_ru = 'ИСТИНА' and declineOverrideCategory is null then Call1_incoming else 0 end) as BankiRu_noAdd_call1
		,sum(case when Banki_ru = 'ИСТИНА' and declineOverrideCategory is null then Call5_accept else 0 end) as BankiRu_noAdd_call5acc

		,sum(case when 	leadsource = 'bankiru-installment-ref' then Call1_incoming  else 0 end) as BankiRu_Old_call1
		,sum(case when 	leadsource = 'bankiru-installment-ref' then Call5_accept  else 0 end) as BankiRu_Old_call5acc

		,sum(case when 	leadsource = 'bankiru-deepapi' then Call1_incoming  else 0 end) as BankiRu_API_call1
		,sum(case when 	leadsource = 'bankiru-deepapi' then Call5_accept  else 0 end) as BankiRu_API_call5acc

--выдачи
		,sum(case when Banki_ru = 'ЛОЖЬ' then fl_loan else 0 end) as Other_cnt_loan
		,sum(case when Banki_ru = 'ЛОЖЬ' then cast(loan_amount as float) else 0 end) as Other_sum_loan

		,sum(case when leadsource = 'bankiru-installment-ref' and declineOverrideCategory is null then fl_loan  else 0 end) as BankiRu_Old_cnt_loan
		,sum(case when leadsource = 'bankiru-installment-ref' and declineOverrideCategory is null then cast(loan_amount as float) else 0 end) as BankiRu_Old_sum_loan
		,sum(case when leadsource = 'bankiru-installment-ref' and declineOverrideCategory = '001_extendedAgressiveApproval' then fl_loan  else 0 end) as BankiRu_Old_cnt_loan_ADD
		,sum(case when leadsource = 'bankiru-installment-ref' and declineOverrideCategory = '001_extendedAgressiveApproval' then cast(loan_amount as float) else 0 end) as BankiRu_Old_sum_loan_ADD

		,sum(case when leadsource = 'bankiru-deepapi' and declineOverrideCategory is null then fl_loan  else 0 end) as BankiRu_API_cnt_loan
		,sum(case when leadsource = 'bankiru-deepapi' and declineOverrideCategory is null then cast(loan_amount as float) else 0 end) as BankiRu_API_sum_loan
		,sum(case when leadsource = 'bankiru-deepapi' and declineOverrideCategory = '001_extendedAgressiveApproval' then fl_loan  else 0 end) as BankiRu_API_cnt_loan_ADD
		,sum(case when leadsource = 'bankiru-deepapi' and declineOverrideCategory = '001_extendedAgressiveApproval' then cast(loan_amount as float) else 0 end) as BankiRu_API_sum_loan_ADD


		,closed_credit_count
		,cnt_inst
		,cnt_PDL
		,cnt_PTS
		,IsMore5ClosedCredits
		,IsChangeProduct
		,cast(getdate() as date) as date_upd
/*		,FSSP_CR
		,FSSP_ALL*/
		,case
		when Decision_code = '100.0016.002' then 'Другое'
		when Decision_code = '100.0016.003' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0051.001' then 'Отказ по скору'
		when Decision_code = '100.0051.002' then 'Отказ по скору'
		when Decision_code = '100.0060.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0060.107' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.001' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0070.002' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0070.007' then 'Другое'
		when Decision_code = '100.0070.207' then 'Другое'
		when Decision_code = '100.0080.005' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0081.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0081.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0082.001' then 'Другое'
		when Decision_code = '100.0100.001' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.005' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.041' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.113' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0110.008' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0110.011' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.001' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.071' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.091' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.101' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0131.001' then 'Отказ по лимиту'
		when Decision_code = '100.0131.002' then 'Отказ по лимиту'
		when Decision_code = '100.0701.003' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0701.004' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0702.002' then 'Другое'
		when Decision_code = '100.0702.003' then 'Другое'
		when Decision_code = '100.0702.004' then 'Другое'
		when Decision_code = '100.0702.005' then 'Другое'
		when Decision_code = '100.0702.006' then 'Другое'
		when Decision_code = '100.0703.002' then 'Другое'
		when Decision_code = '100.0703.003' then 'Другое'
		when Decision_code = '100.0703.004' then 'Другое'
		when Decision_code = '100.0703.005' then 'Другое'
		when Decision_code = '100.0704.002' then 'Другое'
		when Decision_code = '100.0704.003' then 'Другое'
		when Decision_code = '100.0704.004' then 'Другое'
		when Decision_code = '100.0705.002' then 'Другое'
		when Decision_code = '100.0705.003' then 'Другое'
		when Decision_code = '100.0705.004' then 'Другое'
		when Decision_code = '100.0705.005' then 'Другое'
		when Decision_code = '100.0705.006' then 'Другое'
		when Decision_code = '100.0706.002' then 'Другое'
		when Decision_code = '100.0707.003' then 'Другое'
		when Decision_code = '100.0709.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0712.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0712.003' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0751.001' then 'Отказ по скору'
		when Decision_code = '100.0760.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0761.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0761.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0781.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0781.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0801.004' then 'Другое'
		when Decision_code = '100.0801.005' then 'Другое'
		when Decision_code = '100.0801.006' then 'Другое'
		when Decision_code = '100.0801.007' then 'Другое'
		when Decision_code = '100.0802.003' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0802.004' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0808.005' then 'Другое'
		when Decision_code = '100.0809.007' then 'Другое'
		when Decision_code = '100.0809.008' then 'Другое'
		when Decision_code = '100.0809.010' then 'Другое'
		when Decision_code = '100.0810.007' then 'Другое'
		when Decision_code = '100.0811.008' then 'Другое'
		when Decision_code = '100.0811.009' then 'Другое'
		when Decision_code = '100.0811.010' then 'Другое'
		when Decision_code = '100.0812.006' then 'Другое'
		when Decision_code = '100.0812.007' then 'Другое'
		when Decision_code = '100.0812.008' then 'Другое'
		when Decision_code = '100.0812.009' then 'Другое'
		when Decision_code = '100.0812.010' then 'Другое'
		when Decision_code = '100.0813.004' then 'Другое'
		when Decision_code = '100.0813.005' then 'Другое'
		when Decision_code = '100.0813.006' then 'Другое'
		when Decision_code = '100.0814.004' then 'Другое'
		when Decision_code = '100.0814.005' then 'Другое'
		when Decision_code = '100.0814.006' then 'Другое'
		when Decision_code = '100.0814.007' then 'Другое'
		when Decision_code = '100.0814.008' then 'Другое'
		when Decision_code = '100.0814.009' then 'Другое'
		when Decision_code = '100.0814.010' then 'Другое'
		when Decision_code = '100.0814.011' then 'Другое'
		when Decision_code = '100.0814.013' then 'Другое'
		when Decision_code = '100.0814.014' then 'Другое'
		when Decision_code = '100.0814.015' then 'Другое'
		when Decision_code = '100.0814.016' then 'Другое'
		when Decision_code = '100.0814.118' then 'Другое'
		when Decision_code = '100.0815.002' then 'Другое'
		when Decision_code = '100.0815.003' then 'Другое'
		when Decision_code = '100.0815.004' then 'Другое'
		when Decision_code = '100.0815.007' then 'Другое'
		when Decision_code = '100.0815.008' then 'Другое'
		when Decision_code = '100.0815.009' then 'Другое'
		when Decision_code = '100.0815.010' then 'Другое'
		when Decision_code = '100.0815.011' then 'Другое'
		when Decision_code = '100.0815.012' then 'Другое'
		when Decision_code = '100.0817.002' then 'Другое'
		when Decision_code = '100.0861.001' then 'Другое'
		when Decision_code = '100.0951.001' then 'Отказ по скору'
		when Decision_code = '100.0960.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.017' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0981.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0981.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '200.0060.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0060.107' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.001' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0760.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0761.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0761.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0960.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0961.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0961.016' then 'Негативная информациия (БКИ)'
		else 'error'
	end as Decision_description_BIG
	into #stage1
	from #stages
	group by 	
		period_flg
		,datepart(ww, call_date)
--		,guid
		,number
		,product
		,case
				when product = 'PDL' then MAX_PMT_LIMIT_PDL
				when product = 'INST' then MAX_PMT_LIMIT_INST
			end 
		,case
				when request_amount is null or request_amount = 0 then 0
				when product = 'PDL' then (MAX_PMT_LIMIT_PDL / isnull(request_amount, 0))
				when product = 'INST' then (MAX_PMT_LIMIT_INST / isnull(request_amount, 0))
			end 
		,case
				when request_amount is null or request_amount = 0 then '00. null'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.1  then '01. [0-0.1)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.2  then '02. [0.1-0.2)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.3  then '03. [0.2-0.3)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.4  then '04. [0.3-0.4)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.5  then '05. [0.4-0.5)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.6  then '06. [0.5-0.6)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.7  then '07. [0.6-0.7)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.8  then '08. [0.7-0.8)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 0.9  then '09. [0.8-0.9)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount < 1.0  then '10. [0.9-1.0)'
				when product = 'PDL' and MAX_PMT_LIMIT_PDL / request_amount >= 1.0 then '11. [1.0-inf)'

				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.1  then '01. [0-0.1)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.2  then '02. [0.1-0.2)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.3  then '03. [0.2-0.3)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.4  then '04. [0.3-0.4)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.5  then '05. [0.4-0.5)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.6  then '06. [0.5-0.6)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.7  then '07. [0.6-0.7)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.8  then '08. [0.7-0.8)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 0.9  then '09. [0.8-0.9)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount < 1.0  then '10. [0.9-1.0)'
				when product = 'INST' and MAX_PMT_LIMIT_INST / request_amount >= 1.0 then '11. [1.0-inf)'
				
				else 'something wrong'
			end
		,cast(call_date as date)
		,okb_gr
		,Decision_Code
		,Decision_description
		,incoming_DTI_group
		,client_type_1
		,isElligibleforFullAutoApproveChaCha
		,isFullAutoApprove
		,declineOverrideCategory
		,leadsource
		,Banki_ru
		,limit_bucket_PDL
		,limit_bucket_INST
		,request_amount_bucket
		,case
				when leadsource = 'bankiru-installment-ref' then 'Old'
				when leadsource = 'bankiru-deepapi' then 'API'
				else ''
			end 
		,gr_income_ammount
		,pdn_fact_bucket
		,concat(FORMAT( DATEADD(WEEK, DATEDIFF(WEEK, 0, call_date), 0), 'dd.MM') , ' - ' ,-- Начало недели (понедельник)
			FORMAT(DATEADD(WEEK, DATEDIFF(WEEK, 0, call_date), 6),'dd.MM'))

		,closed_credit_count
		,cnt_inst
		,cnt_PDL
		,cnt_PTS
		,IsMore5ClosedCredits
		,IsChangeProduct
		,case
		when Decision_code = '100.0016.002' then 'Другое'
		when Decision_code = '100.0016.003' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0051.001' then 'Отказ по скору'
		when Decision_code = '100.0051.002' then 'Отказ по скору'
		when Decision_code = '100.0060.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0060.107' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.001' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0061.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0070.002' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0070.007' then 'Другое'
		when Decision_code = '100.0070.207' then 'Другое'
		when Decision_code = '100.0080.005' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0081.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0081.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0082.001' then 'Другое'
		when Decision_code = '100.0100.001' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.005' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.041' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0100.113' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0110.008' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0110.011' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.001' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.071' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.091' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0120.101' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0131.001' then 'Отказ по лимиту'
		when Decision_code = '100.0131.002' then 'Отказ по лимиту'
		when Decision_code = '100.0701.003' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0701.004' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0702.002' then 'Другое'
		when Decision_code = '100.0702.003' then 'Другое'
		when Decision_code = '100.0702.004' then 'Другое'
		when Decision_code = '100.0702.005' then 'Другое'
		when Decision_code = '100.0702.006' then 'Другое'
		when Decision_code = '100.0703.002' then 'Другое'
		when Decision_code = '100.0703.003' then 'Другое'
		when Decision_code = '100.0703.004' then 'Другое'
		when Decision_code = '100.0703.005' then 'Другое'
		when Decision_code = '100.0704.002' then 'Другое'
		when Decision_code = '100.0704.003' then 'Другое'
		when Decision_code = '100.0704.004' then 'Другое'
		when Decision_code = '100.0705.002' then 'Другое'
		when Decision_code = '100.0705.003' then 'Другое'
		when Decision_code = '100.0705.004' then 'Другое'
		when Decision_code = '100.0705.005' then 'Другое'
		when Decision_code = '100.0705.006' then 'Другое'
		when Decision_code = '100.0706.002' then 'Другое'
		when Decision_code = '100.0707.003' then 'Другое'
		when Decision_code = '100.0709.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0712.002' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0712.003' then 'Минимальные требования (заявитель)'
		when Decision_code = '100.0751.001' then 'Отказ по скору'
		when Decision_code = '100.0760.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0761.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0761.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0781.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0781.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0801.004' then 'Другое'
		when Decision_code = '100.0801.005' then 'Другое'
		when Decision_code = '100.0801.006' then 'Другое'
		when Decision_code = '100.0801.007' then 'Другое'
		when Decision_code = '100.0802.003' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0802.004' then 'Негативная информация (внутренние источники)'
		when Decision_code = '100.0808.005' then 'Другое'
		when Decision_code = '100.0809.007' then 'Другое'
		when Decision_code = '100.0809.008' then 'Другое'
		when Decision_code = '100.0809.010' then 'Другое'
		when Decision_code = '100.0810.007' then 'Другое'
		when Decision_code = '100.0811.008' then 'Другое'
		when Decision_code = '100.0811.009' then 'Другое'
		when Decision_code = '100.0811.010' then 'Другое'
		when Decision_code = '100.0812.006' then 'Другое'
		when Decision_code = '100.0812.007' then 'Другое'
		when Decision_code = '100.0812.008' then 'Другое'
		when Decision_code = '100.0812.009' then 'Другое'
		when Decision_code = '100.0812.010' then 'Другое'
		when Decision_code = '100.0813.004' then 'Другое'
		when Decision_code = '100.0813.005' then 'Другое'
		when Decision_code = '100.0813.006' then 'Другое'
		when Decision_code = '100.0814.004' then 'Другое'
		when Decision_code = '100.0814.005' then 'Другое'
		when Decision_code = '100.0814.006' then 'Другое'
		when Decision_code = '100.0814.007' then 'Другое'
		when Decision_code = '100.0814.008' then 'Другое'
		when Decision_code = '100.0814.009' then 'Другое'
		when Decision_code = '100.0814.010' then 'Другое'
		when Decision_code = '100.0814.011' then 'Другое'
		when Decision_code = '100.0814.013' then 'Другое'
		when Decision_code = '100.0814.014' then 'Другое'
		when Decision_code = '100.0814.015' then 'Другое'
		when Decision_code = '100.0814.016' then 'Другое'
		when Decision_code = '100.0814.118' then 'Другое'
		when Decision_code = '100.0815.002' then 'Другое'
		when Decision_code = '100.0815.003' then 'Другое'
		when Decision_code = '100.0815.004' then 'Другое'
		when Decision_code = '100.0815.007' then 'Другое'
		when Decision_code = '100.0815.008' then 'Другое'
		when Decision_code = '100.0815.009' then 'Другое'
		when Decision_code = '100.0815.010' then 'Другое'
		when Decision_code = '100.0815.011' then 'Другое'
		when Decision_code = '100.0815.012' then 'Другое'
		when Decision_code = '100.0817.002' then 'Другое'
		when Decision_code = '100.0861.001' then 'Другое'
		when Decision_code = '100.0951.001' then 'Отказ по скору'
		when Decision_code = '100.0960.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0961.017' then 'Негативная информациия (БКИ)'
		when Decision_code = '100.0981.006' then 'Негативная информациия (ФССП)'
		when Decision_code = '100.0981.007' then 'Негативная информациия (ФССП)'
		when Decision_code = '200.0060.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0060.107' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.001' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0061.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0760.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0761.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0761.016' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0960.015' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0961.002' then 'Негативная информациия (БКИ)'
		when Decision_code = '200.0961.016' then 'Негативная информациия (БКИ)'
		else 'error'
	end 
;


drop table if exists #add_param;
select distinct  t.number
--		,okbscore
--		,active_summa
--		,active_summa_total
--		,isnull(SUM_DQ_PMTS, SUM_DQ_PMTS_EQUI) as SUM_DQ_PMTS
--		,isnull(CNT_DQ_ACCS, CNT_DQ_ACCS_EQUI) as CNT_DQ_ACCS
--		,isnull(CNT_DQ_ACCS_R, CNT_DQ_ACCS_R_EQUI) as CNT_DQ_ACCS_R
		,case when a.max_CNT_DQ_ACCS=0 then 1 else 0 end as no_daley
--		,case when isnull( max(IsDecl30_any) over( partition by t.number),max(t.IsDecl30_equi) over( partition by t.number)) =0 then 1 else 0 end  as noDecl30_any		--наличие просрочки 30+
--		,micro_ever				--наличие кредитов МФО
--		,Reg_number
--		,Region
--		,rn = row_number() over(partition by number, stage order by call_date)
,fl_check= cast(null as varchar(100))
,bki=1
,EqxScore= cast( null as int)
	into #add_param
	from Stg._loginom.Origination_equifax_aggregates_4 t with(nolock)
	left join (select distinct t.number, max(CNT_DQ_ACCS) as max_CNT_DQ_ACCS from stg._loginom.originationlog as t with(nolock) 
	join #stage1 a 
	on t.number=a.number
where t.stage in ('Call 1', 'Call 2') and CNT_DQ_ACCS is not null
group by t.number,CNT_DQ_ACCS 
having max(CNT_DQ_ACCS)<1) a
on t.number=a.number
	where t.number in (select distinct number from #stage1)


update t 
set 
	fl_check= case
			when a.auto_approve_fl = 1 then 'Документы'
			when a.auto_approve_fl = 0 and a.IsSimplifiedVerification = 1 then 'Упрощенная верификация'
			else 'Полная верификация' end 
from #add_param t
join stg._loginom.originationlog as a with(nolock)
on t.number=a.number
where Call_date >='20231201' and Call_date <'20240515'

update t 
set 
	fl_check= case
			when a.isFullAutoApprove = 1 then 'Полный АА'
			when a.IsDocumentalVerification = 1 and (a.isFullAutoApprove = 0 or a.isFullAutoApprove is null) then 'Документы'
			when a.IsDocumentalVerification = 0 and a.IsSimplifiedVerification = 1 then 'Упрощенная верификация'
			else 'Полная верификация' end 
from #add_param t
join stg._loginom.originationlog as a with(nolock)
on t.number=a.number
where Call_date >='20240515'

update t 
set 
	t.EqxScore= a.EqxScore
from #add_param t
join stg._loginom.originationlog as a with(nolock)
on t.number=a.number
where a.EqxScore is not null


begin tran
truncate table risk.v_portfolio_ar;

insert into risk.v_portfolio_ar
(
	[period_flg]
	, [week_of_year]
	, [week]
	, [number]
	, [product]
	, [MAX_PMT_LIMIT]
	, [Cust_Satisfaction]
	, [gr_Cust_Satisfaction]
	, [dt]
	, [okb_gr]
	, [Decision_Code]
	, [Decision_description]
	, [incoming_DTI_group]
	, [client_type_1]
	, [isElligibleforFullAutoApproveChaCha]
	, [isFullAutoApprove]
	, [declineOverrideCategory]
	, [leadsource]
	, [Banki_ru]
	, [limit_bucket_PDL]
	, [limit_bucket_INST]
	, [request_amount_bucket]
	, [Banki_Type]
	, [gr_income_ammount]
	, [pdn_fact_bucket]
	, [Call1_incoming]
	, [Call1_accept]
	, [Call12_incoming]
	, [Call12_accept]
	, [fl_autoapp_JS]
	, [cheks]
	, [Call15_incoming]
	, [Call15_accept]
	, [Call2_incoming]
	, [Call2_accept]
	, [autoapp]
	, [verif]
	, [Call3_incoming]
	, [Call3_accept]
	, [Call5_incoming]
	, [Call5_accept]
	, [cnt_loan]
	, [sum_loans]
	, [Other_LG_call1]
	, [Other_LG_call5acc]
	, [BankiRu_All_call1]
	, [BankiRu_All_call5acc]
	, [BankiRu_noAdd_call1]
	, [BankiRu_noAdd_call5acc]
	, [BankiRu_Old_call1]
	, [BankiRu_Old_call5acc]
	, [BankiRu_API_call1]
	, [BankiRu_API_call5acc]
	, [Other_cnt_loan]
	, [Other_sum_loan]
	, [BankiRu_Old_cnt_loan]
	, [BankiRu_Old_sum_loan]
	, [BankiRu_Old_cnt_loan_ADD]
	, [BankiRu_Old_sum_loan_ADD]
	, [BankiRu_API_cnt_loan]
	, [BankiRu_API_sum_loan]
	, [BankiRu_API_cnt_loan_ADD]
	, [BankiRu_API_sum_loan_ADD]
	, [closed_credit_count]
	, [cnt_inst]
	, [cnt_PDL]
	, [cnt_PTS]
	, [IsMore5ClosedCredits]
	, [IsChangeProduct]
	, [date_upd]
	, [no_daley]
	, [no_daley_apr]
	, [no_daley_loan]
	, [start_exp_fun]
	, [end_exp_fun]
	, [fl_check]
	, [bki]
	, [EqxScore]
	, [Decision_description_BIG]
)
select t.[period_flg]
	, t.[week_of_year]
	, t.[week]
	, t.[number]
	, t.[product]
	, t.[MAX_PMT_LIMIT]
	, t.[Cust_Satisfaction]
	, t.[gr_Cust_Satisfaction]
	, t.[dt]
	, t.[okb_gr]
	, t.[Decision_Code]
	, t.[Decision_description]
	, t.[incoming_DTI_group]
	, t.[client_type_1]
	, t.[isElligibleforFullAutoApproveChaCha]
	, t.[isFullAutoApprove]
	, t.[declineOverrideCategory]
	, t.[leadsource]
	, t.[Banki_ru]
	, t.[limit_bucket_PDL]
	, t.[limit_bucket_INST]
	, t.[request_amount_bucket]
	, t.[Banki_Type]
	, t.[gr_income_ammount]
	, t.[pdn_fact_bucket]
	, t.[Call1_incoming]
	, t.[Call1_accept]
	, t.[Call12_incoming]
	, t.[Call12_accept]
	, t.[fl_autoapp_JS]
	, t.[cheks]
	, t.[Call15_incoming]
	, t.[Call15_accept]
	, t.[Call2_incoming]
	, t.[Call2_accept]
	, t.[autoapp]
	, t.[verif]
	, t.[Call3_incoming]
	, t.[Call3_accept]
	, t.[Call5_incoming]
	, t.[Call5_accept]
	, t.[cnt_loan]
	, t.[sum_loans]
	, t.[Other_LG_call1]
	, t.[Other_LG_call5acc]
	, t.[BankiRu_All_call1]
	, t.[BankiRu_All_call5acc]
	, t.[BankiRu_noAdd_call1]
	, t.[BankiRu_noAdd_call5acc]
	, t.[BankiRu_Old_call1]
	, t.[BankiRu_Old_call5acc]
	, t.[BankiRu_API_call1]
	, t.[BankiRu_API_call5acc]
	, t.[Other_cnt_loan]
	, t.[Other_sum_loan]
	, t.[BankiRu_Old_cnt_loan]
	, t.[BankiRu_Old_sum_loan]
	, t.[BankiRu_Old_cnt_loan_ADD]
	, t.[BankiRu_Old_sum_loan_ADD]
	, t.[BankiRu_API_cnt_loan]
	, t.[BankiRu_API_sum_loan]
	, t.[BankiRu_API_cnt_loan_ADD]
	, t.[BankiRu_API_sum_loan_ADD]
	, t.[closed_credit_count]
	, t.[cnt_inst]
	, t.[cnt_PDL]
	, t.[cnt_PTS]
	, t.[IsMore5ClosedCredits]
	, t.[IsChangeProduct]
	, t.[date_upd]
	, [no_daley] = case when (no_daley=1) and bki =1 then 1 else 0 end
	, [no_daley_apr] = case when (no_daley=1) and Call5_accept= 1 then 1 else 0 end
	, [no_daley_loan] =case when (no_daley=1) and cnt_loan =1  then 1 else 0 end
	, [start_exp_fun] = cast ('20240709' as date)
	, [end_exp_fun] = cast ('20240911' as date)
	, [fl_check] = a.fl_check
	, [bki] = a.bki
	, [EqxScore] = a.EqxScore
	, [Decision_description_BIG] 
from #stage1 t 
left join ( select distinct  t.number,fl_check,bki,no_daley,EqxScore
		from #add_param t
		join #stage1 a
		on t.number=a.number
		) a
on t.number=a.number

commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
