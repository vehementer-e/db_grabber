
--exec [dbo].[Create_dm_TriggersClients]

CREATE   procedure [dbo].[Create_dm_TriggersClients] 
as
begin

set nocount on


        --- код отсюда начинается

		drop table if exists #Clients

		-- получили идендификтор клиента в системе CRM
		-- Это необходимо, чтобы связать между собой статусы по договорам и заявками клиента и списком клиентов на постановке
		-- В текущей версии дата постановки указана как первая дата загрузки пакета
		-- Сведений о принятии на постановку в данной версии нет
		-- TO DO Добавить признак постановки на мониторинг с указанием данных (возвращается от НБКИ)
		-- TO DO Добавить первый время постановки на мониторинг (возможно с номером пакета)

		select 
			CRMClientIDRREF
			, nkbi.Ссылка 'НБКИ GUID'
			--, МобильныйТелефон
			, cast('40200130' as datetime2) as 'ДатаПостановкиНаМониторинг'  
		into #Clients
		FROM [Stg].[_1CIntegration].[Справочник_КлиентыТриггерыНБКИ] nkbi
			inner join (select min(CRMClientIDRREF) CRMClientIDRREF,  [Паспорт серия] , [Паспорт номер],  CRMClientFIO, ДатаРождения  --МобильныйТелефон,
			from [dwh_new].[staging].[CRMClients_references] group by [Паспорт серия] , [Паспорт номер],  CRMClientFIO, ДатаРождения ) users  --МобильныйТелефон,
			on users.[Паспорт серия] = nkbi.[ПаспортСерия] and 	users.[Паспорт номер] = nkbi.[ПаспортНомер] 
		where len([ПаспортСерия])>0 and len([ПаспортНомер])>0 

		-- Нашли договора и последнюю заявку по клиенту
		-- Необходимо чтобы определить действующего клиента на дату постановки или время в месяцах с последней заявки
		drop table if exists #ClientsRequests
		select c.CRMClientIDRREF, c.ДатаПостановкиНаМониторинг, r.CMRContractNumber, r.CMRContractIDRREF,  r.CRMRequestIDRREF, r.CRMRequestDateTime,  iif(datediff(month,r.CRMRequestDateTime,c.ДатаПостановкиНаМониторинг)>6,1,0) 'Больше 6 месяцев c даты заявки', ROW_NUMBER() over(partition by r.CRMClientIDRREF order by r.CRMRequestDateTime desc) 'Последняя заявка'
		--,* 
		into #ClientsRequests
		from #Clients  c
		inner join [dwh_new].[staging].[CRMClient_reverse_references] r
			on c.CRMClientIDRREF = r.CRMClientIDRREF
   

        drop table if exists #ClientsRequestsActual
	   -- найдем признак статуса любого договора действующего клиента на дату постановки на мониторинг
	   Select distinct cr.CRMClientIDRREF 
	   into #ClientsRequestsActual
			from #ClientsRequests cr
   			left join
			stg._1cCMR.РегистрСведений_СтатусыДоговоров  sd
			on cr.CMRContractIDRREF = sd.Договор and sd.Период < cr.ДатаПостановкиНаМониторинг
			join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
			where ssd.Наименование='Действует'   

		drop table if exists #ClientsRequestsNotActual
	   -- найдем признак недействующего клиента на дату постановки
	   Select distinct cr.CRMClientIDRREF  
		  into #ClientsRequestsNotActual
			from #ClientsRequests cr
   			left join
			stg._1cCMR.РегистрСведений_СтатусыДоговоров  sd
			on cr.CMRContractIDRREF = sd.Договор and sd.Период < cr.ДатаПостановкиНаМониторинг
			join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
			where ssd.Наименование  in ('Аннулирован', 'Продан', 'Погашен')


		drop table if exists #ClientsActual
		-- если есть признак действующего хотя бы по одному договору то 1 
		-- Исключим недействующие договора
		SELECT клиент, max(Действует) Действует
		into  #ClientsActual
		FROM
		(
			SELECT 
				cr.CRMClientIDRREF as клиент
				, iif(ca.CRMClientIDRREF is not null and cna.CRMClientIDRREF is null,1,0) as Действует  -- Договор был действующим и не ушел в статус погашено и аннулирован, продан
				, ca.CRMClientIDRREF a1
				, cna.CRMClientIDRREF a2 
				, cr.* 
			FROM #ClientsRequests cr
			left join #ClientsRequestsActual ca
			on ca.CRMClientIDRREF =  cr.CRMClientIDRREF
			left join #ClientsRequestsNotActual cna
			on cna.CRMClientIDRREF =  cr.CRMClientIDRREF 
		) dd
		GROUP BY клиент



		drop table if exists #ClientsLastRequests
		-- теперь нужно найти у кого  дата последней заявки больше 6 месяцев с даты постановки на мониторинг
		-- выводим все данные, так как в дальнейшем нужна дополнительная очистка
		select CRMClientIDRREF, ДатаПостановкиНаМониторинг, CMRContractNumber, CMRContractIDRREF,  CRMRequestIDRREF, CRMRequestDateTime,   [Больше 6 месяцев c даты заявки], [Последняя заявка]
		--,* 
		into #ClientsLastRequests
		from #ClientsRequests 
		where [Последняя заявка]=1
		--order by CRMClientIDRREF, [Последняя заявка] desc




		drop table if exists #LoansPovt
		-- ищем вхождение в рисковые предложения по докредам и повторникам (по крайней мере одно предложение должно быть зеленое (по второму может быть красное)
		select  external_id, iif(sum(cat_not_red)=0,0,1) as inRiskBD_povt  
		into #LoansPovt
		from 
		(
			SELECT external_id, iif (category='Красный',0,1)  as cat_not_red
			--, category, first_value(category) over (partition by external_id order by case when category='Красныый' then 0 else 1 end desc) fcategory 
			FROM 
			[dwh_new].[dbo].[povt_buffer]
			--where external_id='1612083100001'
		) ss
		group by external_id


		drop table if exists #LoansDocredy
		select  external_id, iif(sum(cat_not_red)=0,0,1) as inRiskBD_docr  
		into #LoansDocredy
		from 
		(
			SELECT external_id, iif (category='Красный',0,1)  as cat_not_red
			--, category, first_value(category) over (partition by external_id order by case when category='Красныый' then 0 else 1 end desc) fcategory 
			FROM 
			[dwh_new].[dbo].[docredy_buffer]
			--where external_id='1612083100001'
		) ss
		group by external_id

		

		drop table if exists #ClientInRiskDB
		-- найдем по номерам договоров признак вхождения в признак докредов или повторников
		-- если есть хоть один подходящий, то учитываем (не красный)
		select  CRMClientIDRREF, iif((sum(isnull(LD.inRiskBD_docr,0))+ sum(isnull(LP.inRiskBD_povt,0))) =0,0,1) isRiskDB 
		into #ClientInRiskDB
		from #ClientsRequests AllLoans
			left join #LoansDocredy LD
			on LD.external_id = AllLoans.CMRContractNumber
			left join #LoansPovt LP
			on LP.external_id = AllLoans.CMRContractNumber
		group by CRMClientIDRREF

   

	-- соберем все в одну таблицу
	-- и очистим от ошибок определения клиента (первая заявка на клиента у которого указаны разные адреса или телефон)
	truncate table  dbo.dm_TriggersClients
	insert into     dbo.dm_TriggersClients
	SELECT --Код
		Ссылка
		, ДатаПостановкиНаМониторинг
		, Фамилия
		, Имя
		, Отчество
		, ДатаРождения
		, ПаспортСерия
		, ПаспортНомер
		, [Действует на дату постановки]
		, [Больше 6 месяцев c даты заявки]
		, [Есть в базе рисковых предложений]
		, NULL  as 'КлиентВсталНаМониторинг'
    --into     dbo.dm_TriggersClients
	FROM
	(
		select 
			КлиентыНБКИ.код
			,КлиентыНБКИ.Ссылка
			, КлиентыЦРМ.CRMClientIDRREF
			, КлиентыНБКИ.Фамилия
			, КлиентыНБКИ.Имя
			, КлиентыНБКИ.Отчество
			, КлиентыНБКИ.ДатаРождения
			, КлиентыНБКИ.ПаспортСерия
			, КлиентыНБКИ.ПаспортНомер
			, КлиентыЦРМ.ДатаПостановкиНаМониторинг
			--, КлиентДействующий.Действует as 'Действует на дату постановки'
			, ПоследняяЗаявка.CRMRequestDateTime 'ДатаЗаявки'
			, ПоследняяЗаявка.[Больше 6 месяцев c даты заявки]
			--, crdb.isRiskDB
			, max(crdb.isRiskDB) over(partition by КлиентыНБКИ.код) as 'Есть в базе рисковых предложений'
			, max(КлиентДействующий.Действует) over(partition by КлиентыНБКИ.код) as  'Действует на дату постановки'
			, ROW_NUMBER() over(partition by КлиентыНБКИ.код order by isnull(ПоследняяЗаявка.CRMRequestDateTime,cast('19000101' as date)) desc) as фильтр
			FROM [Stg].[_1CIntegration].[Справочник_КлиентыТриггерыНБКИ] КлиентыНБКИ
				left join #Clients КлиентыЦРМ 
				on КлиентыНБКИ.Ссылка = КлиентыЦРМ.[НБКИ GUID]
				left join #ClientsActual КлиентДействующий
				on КлиентДействующий.клиент = КлиентыЦРМ.CRMClientIDRREF

				left join #ClientsLastRequests ПоследняяЗаявка
				on ПоследняяЗаявка.CRMClientIDRREF = КлиентыЦРМ.CRMClientIDRREF

				left join #ClientInRiskDB crdb
				on crdb.CRMClientIDRREF = КлиентыЦРМ.CRMClientIDRREF
		--where Код = 1371
		)
		dd
		where фильтр = 1

end
