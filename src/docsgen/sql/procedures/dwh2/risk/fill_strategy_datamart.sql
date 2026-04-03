

--- ========================================================================================================

--- ========================================================================================================

---- exec [risk].[fill_strategy_datamart] @CMRClientGUID = 'CFF47A54-0809-48B8-91D1-C86A884E65EC'

CREATE PROC [risk].[fill_strategy_datamart]
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
	with recompile
as
begin
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	,@msg NVARCHAR(255)
	,@subject NVARCHAR(255)
	;
--	declare @CMRClientGUID_binary binary(16) = [dbo].[get1CIDRREF_FromGUID](@CMRClientGUID)
	set @CMRClientGUIDs = nullif(CONCAT_WS(',', @CMRClientGUID, @CMRClientGUIDs), '')
begin TRY
	DECLARE @calc_date date = cast(getdate() as date) --дата расчета

	drop table if exists #ContractIds

	create table #ContractIds (ContractId nvarchar(14) primary key, ContractIdBinary binary(16))
	if @CMRClientGUIDs is not null
	begin
		insert into #ContractIds(ContractId, ContractIdBinary)
		select distinct [Код], ССылка from [Stg].[_1cCMR].[Справочник_Договоры] d
		where (d.Клиент  in (select [dbo].[get1CIDRREF_FromGUID](trim(value)) from string_split(@CMRClientGUIDs, ',')))
		and d.ПометкаУдаления= 0x00
			
	end

-- DWH-1396
-- DWH-1397
--Берем договора у которых дата подачи иска в суд или назначен  куратор BP-1781
drop table if exists #isk_sp_space
SELECT   
		Deal.Number AS external_id
		-- СП
		--, jc.CourtClaimSendingDate 'Дата отправки иска в суд'
		--, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
		--, jc.ResultOfCourtsDecision 'Решение суда'
		--, jc.AmountJudgment 'Сумма по решению суда' 
into #isk_sp_space
FROM            Stg._Collection.Deals AS Deal 
	inner join stg._Collection.customers c on c.Id = Deal.IdCustomer
	LEFT JOIN Stg._Collection.JudicialProceeding AS jp ON jp.DealId  = Deal.Id
	LEFT JOIN Stg._Collection.JudicialClaims AS jc ON jc.JudicialProceedingId  = jp.Id
where (
	isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate)  is not null
	or 
	ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) is not null
	)
	and (exists(Select top(1) 1 from #ContractIds t where t.ContractId = Deal.Number)
		or @CMRClientGUIDs is null)
	--  and isFake = 0
group by Deal.Number


-- аннулированные данные договоров (всего 4 штуки) CMR не дает объяснений по этим договорам
drop table if exists #annul_cmr

select distinct d.код external_id 
into #annul_cmr
from [Stg].[_1cCMR].[Справочник_Договоры] d 
join [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] st on d.Ссылка = st.Договор
join stg.[_1cCMR].Справочник_СтатусыДоговоров status1 on st.Статус = status1.[Ссылка] 
where 
	status1.[Наименование] = 'Аннулирован'
	and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  d.код)
		or @CMRClientGUIDs is null)
	


-- получим даты начала и завершения договоров
drop table if exists #startend
select 
	t.external_id
	,ContractStartDate
	,ContractEndDate
	,[КоличествоПолныхДнейПросрочкиMFO]
	,[КоличествоПолныхДнейПросрочки]
	,lifetime_days_b = datediff(day, ContractStartDate, isnull(ContractEndDate,getdate())) 
	,maxDpdOver30DaysL6M
	,lastDateMaxDpdOver30DaysL6M
	into #startend
from (
	select 
		external_id, 
		ContractStartDate = min(b.ContractStartDate) ,
		ContractEndDate = max(b.ContractEndDate) ,
		[КоличествоПолныхДнейПросрочкиMFO] = max(b.dpdMFO) ,
		[КоличествоПолныхДнейПросрочки] = max(b.dpd) 
		,maxDpdOver30DaysL6M = max(iif(
			d>=dateadd(dd,-180,getdate()) and dpd_begin_day>=30
			, dpd_begin_day, null))
		,lastDateMaxDpdOver30DaysL6M=max(iif(
		d>=dateadd(dd,-180,getdate()) and dpd_begin_day>=30
			, d, null))	
	from dbo.dm_CMRStatBalance b
	where (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  b.external_id)
		or @CMRClientGUIDs is null)
	group by external_id
	) t
	option(recompile)










  -- для ускорения загрузки из МФО создали историческую таблицу
  drop table if exists #risk_criteria
  select * 
  into #risk_criteria
  from [Stg].[_1cMFO].[Документ_ГП_ЗаявкаПредставлениеКритериевРиска]

  create index ix on #risk_criteria([Номер]) include(ГП_ПредставлениеКритериевРиска)
  --select [ГП_ПредставлениеКритериевРиска], [Номер]
  ----into #risk_criteria
  --into [Stg].[_1cMFO].[Документ_ГП_ЗаявкаПредставлениеКритериевРиска]
  --from 
  --[Stg].[_1cMFO].[Документ_ГП_Заявка] z with(nolock) --r on r.[Номер] = d.Код 
  --join [dwh_new].[staging].[CRMClient_references] loans on z.Ссылка = loans.MFORequestIDRREF
  --join #startend st on st.external_id = loans.CMRContractNumber
  --where cast([ГП_ПредставлениеКритериевРиска] as nvarchar) <> '' 




--- федор
-- берем данные по последней оценке верификаторов (не по договору)
   drop table if exists #feodor

   SELECT  distinct
	  cr.[Number] Collate Cyrillic_General_CI_AS  [Feodor.НомерДоговора] 
	, cr.IdClient
	, [ClientPassportSerial] = FIRST_VALUE([ClientPassportSerial]) over (partition by IdClient order by CreatedRequestDate desc) Collate Cyrillic_General_CI_AS 
	, [ClientPassportNumber] = FIRST_VALUE([ClientPassportNumber]) over (partition by IdClient order by CreatedRequestDate desc) Collate Cyrillic_General_CI_AS 
	, [ClientPassportIssuedDate]  = FIRST_VALUE([ClientPassportIssuedDate]) over (partition by IdClient order by CreatedRequestDate desc) 
	, vin Collate Cyrillic_General_CI_AS vin
	, tsYear
	, brand.Name Collate Cyrillic_General_CI_AS Brand 	
	, model.Name Collate Cyrillic_General_CI_AS Model
	-- Залог стоимость
	, [Федор.Рыночная стоимость на момент оценки] = FIRST_VALUE([TsMarketPrice]) over (partition by vin order by CreatedRequestDate desc)
	, [TsMarketPrice]  [Федор.Рыночная стоимость на момент оценки Оригинал]
	, CreatedRequestDate	
	--, cp.Name Collate Cyrillic_General_CI_AS  as product_type
	-- вариант 2021_11_23	
	, [product_type] = 	iif (pt.code is not null
		,pt.code
		,case cr.Type
			when 0 then 'PTS'
			when 2 then 'INST'
			when 4 then 'SmInst'
			when 5 then 'PDL'
		else 'PTS' end
		) Collate Cyrillic_General_CI_AS


		--не использоваь т.к. будет удален IsInstallment
	--	isnull(iif(cr.IsInstallment = 1,'INST', 'PTS'),'PTS') Collate Cyrillic_General_CI_AS
	,client_External_id = cast(c.IdExternal as nvarchar(36))
	,productSubType_Code = pst.Code Collate Cyrillic_General_CI_AS
	into #feodor
  FROM [Stg].[_fedor].[core_ClientRequest] cr
  inner join  [Stg].[_fedor].core_Client c on c.Id = cr.IdClient
  left join [Stg].[_fedor].[dictionary_TsBrand] brand on cr.idTsBrand = brand.id
  left join [Stg].[_fedor].[dictionary_TsModel] model on cr.idTsModel = model.id

  left join [Stg].[_fedor].[dictionary_ProductType] pt on pt.Id = ProductTypeId

  left join stg.[_fedor].[dictionary_ProductSubType] pst on pst.Id = cr.ProductSubTypeId
  where cr.IsNewProcess = 1
	and cr.CreatedRequestDate > ='2020-09-01'
	
	and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  cr.[Number] Collate Cyrillic_General_CI_AS)
		or @CMRClientGUIDs is null)
	--and (cr.[Number] = @external_id or @external_id is null) 
	--
	--

  --MFO
  -- проблема разных машин под один vin. 
  -- необходимо найти выданный первый займ по данному vin или по последней заявке
  drop table if exists #mfo_tmp
  select 
	  z_tc.СерияПаспорта СерияПаспортаОригинал
	  , z_tc.НомерПаспорта НомерПаспортаОригинал
	  , z_tc.ДатаВыдачиПаспорта ДатаВыдачиПаспортаОригинал
	  , z_tc.vin
	  , z_tc.Год ГодОригинал --Авто
	  , z_tc.РыночнаяСтоимостьАвтоНаМоментОценки РыночнаяСтоимостьАвтоНаМоментОценкиОригинал
	  , z_tc.Номер
	 -- , Дата
	  , dateadd(yy, -2000,d.Дата) as loan_date  -- если нет договора, то пишем будущую дату для сортировки
	  , dateadd(yy, -2000, z_tc.Дата) as request_date 
	  , z_tc.Марка
	  , z_tc.Модель
	  , z_tc.КонтрагентКлиент
	  , rn_request = row_number() over(partition by КонтрагентКлиент order by z_tc.Дата)
	  , rn_loan = row_number() over(partition by КонтрагентКлиент order by isnull(d.Дата, '2100-01-01'))
	  , pass_num = LEFT(nullif(replace(z_tc.СерияПаспорта,' ', ''),'') + ' ' + nullif(z_tc.НомерПаспорта,''),11)	
	  , [product_type] =  kp.Наименование
	  , productSubType_Code = cast(null as nvarchar(255))
  into #mfo_tmp
  FROM 
  stg._1cMFO.Документ_ГП_Заявка z_tc 
  left join stg._1cMFO.Документ_ГП_Договор d  on z_tc.Ссылка = d.Заявка
  	left join stg._1cMFO.Справочник_ГП_МаркаАвтомобиля ma on z_tc.Марка = ma.Ссылка
	left join stg._1cMFO.Справочник_ГП_МодельАвтомобиля mo on z_tc.Модель = mo.Ссылка
	left join [Stg].[_1cMFO].[Справочник_ГП_КредитныеПродукты] kp  on kp.Ссылка = z_tc.КредитныйПродукт
 where z_tc.ПометкаУдаления  = 0x00  -- бывают удаленные тестовые
 and КонтрагентКлиент <> 0x00000000000000000000000000000000
 --and (z_tc.Номер = @external_id or @external_id is null) 
 and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  z_tc.Номер)
		or @CMRClientGUIDs is null)
 CREATE CLUSTERED INDEX [ClusteredIndexPass] ON #mfo_tmp(
	[pass_num] ASC
)



  drop table if exists #mfo
  select z_tc.*
	,[РыночнаяСтоимостьАвтоНаМоментОценки] = FIRST_VALUE(РыночнаяСтоимостьАвтоНаМоментОценкиОригинал) over (partition by vin order by request_date desc) -- берем последнюю на дату заявки
	,Год = FIRST_VALUE(ГодОригинал) over (partition by vin order by  request_date desc) -- берем последнюю на дату заявки isnull(loan_date, cast('1900-01-01' as datetime)) desc,
   ,МаркаАвто = FIRST_VALUE(ma.Наименование) over (partition by vin order by request_date desc) -- берем последнюю на дату заявки isnull(loan_date, cast('1900-01-01' as datetime))desc, 
   ,МодельАвто = FIRST_VALUE(mo.Наименование) over (partition by vin order by request_date desc) -- берем последнюю на дату заявки isnull(loan_date, cast('1900-01-01' as datetime)) desc,
   ,СерияПаспорта = FIRST_VALUE(СерияПаспортаОригинал) over (partition by КонтрагентКлиент order by isnull(loan_date, cast('1900-01-01' as datetime)) desc, request_date desc) -- берем последнюю на дату заявки и договора
   ,НомерПаспорта = FIRST_VALUE(НомерПаспортаОригинал) over (partition by КонтрагентКлиент order by isnull(loan_date, cast('1900-01-01' as datetime)) desc, request_date desc) -- берем последнюю на дату заявки и договора
   ,ДатаВыдачиПаспорта = FIRST_VALUE(ДатаВыдачиПаспортаОригинал) over (partition by КонтрагентКлиент order by isnull(loan_date, cast('1900-01-01' as datetime)) desc, request_date desc) -- берем последнюю на дату заявки и договора
   
   , rn_mfo = ROW_NUMBER() over (partition by Номер order by isnull(loan_date, cast('1900-01-01' as datetime)) desc, request_date desc)
  into #mfo
  from #mfo_tmp z_tc
  left join stg._1cMFO.Справочник_ГП_МаркаАвтомобиля ma on z_tc.Марка = ma.Ссылка
  left join stg._1cMFO.Справочник_ГП_МодельАвтомобиля mo on z_tc.Модель = mo.Ссылка
 
 /*
	-- так как много случаев нулевой оценки рыночной стоимости, то берем последнюю не нулевую
	drop table if exists #mfo_vin
	select distinct
		[РыночнаяСтоимостьАвтоНаМоментОценки] = FIRST_VALUE(РыночнаяСтоимостьАвтоНаМоментОценкиОригинал) over (partition by vin order by request_date desc) -- берем последнюю на дату заявки
		, vin
	into #mfo_vin
	from #mfo
	where [РыночнаяСтоимостьАвтоНаМоментОценки]  = 0
	and vin <> ''
	and РыночнаяСтоимостьАвтоНаМоментОценкиОригинал <> 0

	-- аналогично проверить год и марку
	-- обновим для одного vin
	update m_vin 
	set m_vin.[РыночнаяСтоимостьАвтоНаМоментОценки] = vn.[РыночнаяСтоимостьАвтоНаМоментОценки]
	from #mfo m_vin
	join #mfo_vin vn on vn.vin = m_vin.vin

	
	

	
  --umfo сведения для теста. Для некоторый договоров есть только в УМФО
  drop table if exists #umfo
  SELECT
    za.НомерДоговора [УМФО.НомерДоговора]  ,ЗалоговаяСтоимость as [УМФО.ЗалоговаяСтоимость],	СправедливаяСтоимость as [УМФО.СправедливаяСтоимость],	РыночнаяСтоимость as [УМФО.РыночнаяСтоимость]
	  ,rn = row_number() over (partition by za.Ссылка order by z.Дата, oz.ЗалоговаяСтоимость desc,	СправедливаяСтоимость desc,	РыночнаяСтоимость desc)
	  into #umfo
  FROM [Stg].[_1cUMFO].[Документ_АЭ_ДоговорЗалога] z
   join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный za on z.Займ = za.Ссылка
   join [Stg].[_1cUMFO].[Документ_АЭ_ДоговорЗалога_ОбъектыЗалога] oz on oz.Ссылка = z.Ссылка
   where z.ПометкаУдаления = 0x00
   and za.ПометкаУдаления = 0x00  

  delete from #umfo where rn>1

  */
  -- есть 22 дубля

  delete from #mfo where rn_mfo >1
  --- Костыль на ОД по закрытым
  drop table if exists #balance
  select  external_id,  
	iif(b.d =  b.ContractEndDate, 0 , b.[остаток од]) [остаток од]
	, dpdMFO
	, dpd

  into #balance
  from  dbo.dm_CMRStatBalance b 
  where b.d = cast( getdate() as date)
   and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  b.external_id)
		or @CMRClientGUIDs is null)

drop table if exists #client_inn
--DWH-2889
select GuidКлиент
	,ИНН
	,ТаблицаИсточник
into #client_inn
from dm.v_Клиент_ИНН
create clustered index cix on #client_inn(GuidКлиент)
drop table if exists #client_phone
	select GuidКлиент, 
		НомерТелефонаБезКодов 
	into #client_phone	
	from sat.Клиент_Телефон t
	where  (t.GuidКлиент in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			or @CMRClientGUIDs is null)
		and t.nRow = 1
	
	create clustered index cix on #client_phone(GuidКлиент)
	/*

	drop table if exists #t_FirstPaymentSchedule
	select  
		Документ_ГрафикПлатежей.Договор
		,last_paymentDay_byFirstPaymentSchedule = dateadd(year,-2000, max(iif(year(ДанныеГрафикаПлатежей.ДатаПлатежа)>3000, cast(ДанныеГрафикаПлатежей.ДатаПлатежа as date), null)))
	into #t_FirstPaymentSchedule
	from (select 
		s.Договор, s.Ссылка
		, s.Дата
		, nRow = Row_number() over(partition by s.Договор order by s.Дата)
	from stg._1cCMR.Документ_ГрафикПлатежей s
	where ПометкаУдаления = 0x00
		and Проведен = 0x01
		 and (exists(Select top(1) 1 from #ContractIds t where t.ContractIdBinary =s.Договор)
		or @CMRClientGUIDs is null)

	) Документ_ГрафикПлатежей
	inner join stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей] ДанныеГрафикаПлатежей
		on ДанныеГрафикаПлатежей.Регистратор_Ссылка = Документ_ГрафикПлатежей.Ссылка
			and ДанныеГрафикаПлатежей.Договор = Документ_ГрафикПлатежей.Договор
	where Документ_ГрафикПлатежей.nRow = 1
	group by Документ_ГрафикПлатежей.Договор
	
create clustered index cix on #t_FirstPaymentSchedule(Договор)
*/

  drop table if exists #strategy_datamart_CMR
    SELECT 
	  cast(d.Клиент as bigint) person_id
      --, cast(dateadd(year, -2000,d.[Дата]) as date) ДатаДоговора
      
	  --, fio = Concat(Клиент.Фамилия, ' ', 	Клиент.Имя, ' ', Клиент.Отчество)
--	  isnull(d.[Фамилия],'') + ' ' + isnull(d.[Имя],'') + ' ' + isnull(d.[Отчество],'') fio
	  ,	last_name = trim(isnull(Клиент.Фамилия, d.[Фамилия]))
	  ,	first_name = trim(isnull(Клиент.Имя, d.[Имя]))
	  , patronymic = trim(isnull(Клиент.Отчество, d.[Отчество]))

      , birth_date = cast(dateadd(year, -2000, isnull(nullif(Клиент.[ДатаРождения],'2000-01-01'),d.ДатаРождения)
			) as date)  --[ДатаРождения]
      , passport_number = coalesce(  
				nullif(replace(Клиент.ПаспортСерия,' ', ''),'') +' ' + nullif(replace(Клиент.ПаспортНомер,' ', ''),'')
				,nullif(replace(f_client.[ClientPassportSerial],' ', ''),'') +' ' + nullif(replace(f_client.[ClientPassportNumber],' ', ''),'')
				,nullif(replace(z_tc.СерияПаспорта,' ', ''),'') + ' ' + nullif(z_tc.НомерПаспорта,'')		
				, null) 		
			
	  , passport_date = coalesce( 
				 nullif(iif(year(Клиент.ПаспортДатаВыдачи) > 3000, dateadd(year, -2000, Клиент.ПаспортДатаВыдачи),null),'')
				, nullif((f_client.[ClientPassportIssuedDate]),'')
				, nullif(iif(year(z_tc.ДатаВыдачиПаспорта) > 3000, dateadd(year, -2000,z_tc.ДатаВыдачиПаспорта),null),'')
	   			, null)
	  , vin = coalesce(nullif(f.vin,'')
			    , nullif(z_tc.vin, '')  				
				, null) 
	  , brand = coalesce(nullif(f.brand,'') 
			    , nullif(z_tc.МаркаАвто , '')  			
				, null) 
	   ,model = coalesce(nullif(f.Model,'') 
			    , nullif(z_tc.МодельАвто, '')  				
				, null)
	  ,[year] = coalesce(f.tsYear 
	             ,z_tc.Год				 
				 ,  Null)
	  , market_price = coalesce((f.[Федор.Рыночная стоимость на момент оценки])
				, z_tc.РыночнаяСтоимостьАвтоНаМоментОценки				
				, null)
	  , d.[Код] external_id
	  , is_active = iif(b.external_id is null or startend.ContractEndDate <= cast(getdate() as date) , 0,1)
	  , [start_date] = startend.ContractStartDate
	  , [end_date] = startend.ContractEndDate 
	  , risk_criteria = r.[ГП_ПредставлениеКритериевРиска]
	  , overdue_days = b.dpdMFO
	  , overdue_days_cmr			= b.dpd
	  , overdue_days_max_cmr		= startend.КоличествоПолныхДнейПросрочки
	  , client_overdue_days_max_cmr = max(startend.КоличествоПолныхДнейПросрочки) over (partition by d.Клиент)
	  , overdue_days_max = startend.КоличествоПолныхДнейПросрочкиMFO
	  , client_overdue_days_max =max(startend.КоличествоПолныхДнейПросрочкиMFO) over (partition by d.Клиент)
	  , total_rest = isnull(b.[остаток од], 0) 
	  , total_rest_client = sum(b.[остаток од]) over (partition by d.Клиент)  	 
	  , lifetime_days = sum(isnull(startend.lifetime_days_b,0)) over (partition by d.Клиент) 
	  
	  -- вариант от 2021_11_23
	  , [product_type] = coalesce(
		  nullif(cmr_ТипыДоговоров.ИдентификаторMDS,'')
		, nullif(f.[product_type],'')
		)
		, productSubType_Code = cmr_ПодтипыПродуктов.ИдентификаторMDS		
				
				
				
	  , is_Claim = iif(sp.external_id is null, 0,1) 
	  , [CMRClientGUID]  = [dbo].[getGUIDFrom1C_IDRREF]( d.Клиент)
	  , amount  = d.Сумма --DWH-1905
	  , row_version_CMRClient= Клиент.ВерсияДанных
	  , uid218Fz = isnull(BKI.УникальныйИдентификаторОбъектаБКИ, BKI2.УникальныйИдентификаторДоговора) --DWH-2596
	  , averageMonthlyPayment = AP.CреднемесячныйПлатеж
	  , client_inn = clinet_inn.ИНН							--DWH-2889
	  , client_phone = client_phone.НомерТелефонаБезКодов	--DWH-2889
	  , is_Sold = iif(ДоговорЗайма_ТекущийСтатус.ТекущийСтатусДоговора = 'Продан',1,0) --DWH-2889
	 
	  , initial_end_date = oi.[InitialEndDate] --DWH-2889
	  , startend.maxDpdOver30DaysL6M		--DWH-289
	  , startend.lastDateMaxDpdOver30DaysL6M--DWH-289
  INTO #strategy_datamart_CMR
  FROM [Stg].[_1cCMR].[Справочник_Договоры] d
  inner join [Stg].[_1cCMR].[Справочник_Заявка] cmr_Заявка
	on cmr_Заявка.Ссылка = d.Заявка
  left join [Stg].[_1cCMR].Справочник_ТипыПродуктов cmr_ТипыДоговоров
		on cmr_Заявка.ТипПродукта = cmr_ТипыДоговоров.ссылка
  left join [Stg].[_1cCMR].[Справочник_ПодтипыПродуктов] cmr_ПодтипыПродуктов
		on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
  inner join #startend startend on d.Код = startend.external_id -- только то что есть в балансе
  left join #balance b on b.external_id = d.Код 
  left join stg._1cCMR.Справочник_Клиенты Клиент on Клиент.Ссылка = d.Клиент
  left join #feodor f_client on f_client.[Feodor.НомерДоговора] 	 = d.Код --Collate Cyrillic_General_CI_AS
  left join (select * from #feodor where vin is not null) f on f.[Feodor.НомерДоговора] = d.Код --Collate Cyrillic_General_CI_AS
  left join #mfo z_tc on z_tc.Номер = d.Код
  left join #risk_criteria r on r.[Номер] = d.Код  
  -- 2021_11_16
  left join #isk_sp_space sp on sp.external_id = d.Код
	--DWH-2532
	LEFT JOIN (
			SELECT
				T.ДоговорЗайма
				,УникальныйИдентификаторОбъектаБКИ = T.Значение_Строка
				,RN = row_number() OVER(PARTITION BY T.ДоговорЗайма ORDER BY T.Период DESC)
			FROM Stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров AS T
				INNER JOIN Stg._1cCMR.Справочник_ВидыДополнительнойИнформацииДоговоры AS S
					ON S.Ссылка = T.ВидДополнительнойИнформации
					AND S.Наименование ='Уникальный идентификатор объекта БКИ'
			WHERE T.Значение_Строка IS NOT NULL
		) AS BKI
		ON BKI.ДоговорЗайма = d.Ссылка
		AND BKI.RN = 1
	--DWH-2596
	LEFT JOIN Stg._1cIntegration.РегистрСведений_УникальныеИдентификаторыДоговоров AS BKI2
		ON BKI2.ОбъектЗайма = d.Код

	--DWH-2536
	LEFT JOIN (
		SELECT 
			Код = B.external_id,
			CреднемесячныйПлатеж = 
			CASE 
				--если в балансе есть ContractEndDate И overdue <= 0, то CреднемесячныйПлатеж := 0
				WHEN S2.ContractEndDate IS NOT NULL AND isnull(B.overdue, 0) <= 0 THEN 0
				--в качестве Даты окончания договора берется ДатаПоследнегоПлатежа из Графика
				ELSE 
					round(
						iif(
							isnull(G.СуммаПлатежей, 0) <> 0,

							--A.Borisov 17.05.24 06:19
							--Т должен считаться по формуле от ЦБ, но слегка не такой, как в комменте выше, а вот такой:
							--WHEN ДатаРасчета > ДатаОкончанияДоговора 
							--THEN 1
							--WHEN DAY(ДатаОкончанияДоговора) > DAY(ДатаРасчета)
							--THEN MONTH(ДатаОкончанияДоговора) - MONTH(ДатаРасчета) + 12 * YEAR(ДатаОкончанияДоговора) - 12 * YEAR(ДатаРасчета) + 1
							--ELSE MONTH(ДатаОкончанияДоговора) - MONTH(ДатаРасчета) + 12 * YEAR(ДатаОкончанияДоговора) - 12 * YEAR(ДатаРасчета)
							--END
							isnull(G.СуммаПлатежей, 0) / 
								CASE
									WHEN G.ДатаПоследнегоПлатежа IS NULL
										THEN 1
									WHEN @calc_date > G.ДатаПоследнегоПлатежа
										THEN 1
									WHEN day(G.ДатаПоследнегоПлатежа) > day(@calc_date)
										THEN month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date) + 1
									WHEN month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date) = 0
										THEN 1
									ELSE month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date)
								END,
							0
						)
						+
						iif(isnull(B.overdue, 0) >= 0, isnull(B.overdue, 0), 0)
					, 0)
			END
		FROM dbo.dm_CMRStatBalance AS B
			INNER JOIN #startend AS S2
				ON B.external_id = S2.external_id
				
			LEFT JOIN (
				SELECT 
					R.Код,
					СуммаПлатежей = sum(R.СуммаПлатежа), --сумма оставшихся платежей по графику
					ДатаПоследнегоПлатежа = max(R.ДатаПлатежа)
					--T - количество месяцев, оставшихся до дня прекращения обязательства по договору
					--КоличествоМесяцев = datediff(MONTH, cast(getdate() as date), max(R.ДатаПлатежа))
				FROM dm.CMRExpectedRepayments AS R
				WHERE R.ДатаПлатежа >= cast(getdate() as date)
				GROUP BY R.Код
			) AS G
			ON B.external_id = G.Код
		WHERE 1=1
			AND B.d = @calc_date
		
	) AP
	ON AP.Код = d.Код
	left join #client_inn clinet_inn on clinet_inn.GuidКлиент = [dbo].[getGUIDFrom1C_IDRREF]( d.Клиент)
	left join #client_phone client_phone on client_phone.GuidКлиент = [dbo].[getGUIDFrom1C_IDRREF]( d.Клиент)
	left join sat.ДоговорЗайма_ТекущийСтатус ДоговорЗайма_ТекущийСтатус on 
		ДоговорЗайма_ТекущийСтатус.КодДоговораЗайма =  d.Код
	left join [dbo].[dm_OverdueIndicators] oi on oi.Договор = d.Ссылка
  where d.ПометкаУдаления = 0x00
  
  and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  d.[Код])
		or @CMRClientGUIDs is null)
  --select * from stg._1cCMR.Справочник_Клиенты
  -- удаляем аннулированные
  delete from #strategy_datamart_CMR where external_id in ( select external_id from #annul_cmr)

   --обновим сведения по модели и марке по vin - данные по последнему договору - Машина может быть уже у другого владельца. Данные отличаются
  -- Также обновим данные на основании сведений федор.
  update t 
  set 
  t.model = t2.model
  , t.brand = t2.brand
  , t.year = t2.year
  , t.market_price = t2.market_price
  from #strategy_datamart_CMR t
  join  (select vin , market_price = FIRST_VALUE(market_price) over (partition by vin order by [start_date] desc)
		  , model = FIRST_VALUE(model) over (partition by vin order by [start_date] desc)
		  , brand = FIRST_VALUE(brand) over (partition by vin order by [start_date] desc)
		  , year = FIRST_VALUE(year) over (partition by vin order by [start_date] desc)
		  from #strategy_datamart_CMR) t2
  on t2.vin = t.vin
  
 

  -- обновим данные по клиенту. Паспорт, дата рождения
  update t 
  set --t.market_price = t2.market_price
  t.passport_number = t2.passport_number
  , t.passport_date = t2.passport_date
  , t.birth_date = t2.birth_date
  , t.last_name = t2.last_name
  , t.first_name = t2.first_name
  , t.patronymic = t2.patronymic
  , t.row_version_CMRClient = t2.row_version_CMRClient

  from #strategy_datamart_CMR t
  join  (select person_id
		  , passport_number = FIRST_VALUE(passport_number) over (partition by person_id order by [start_date] desc)
		  , passport_date = FIRST_VALUE(passport_date) over (partition by person_id order by [start_date] desc)  
		  , birth_date = FIRST_VALUE(birth_date) over (partition by person_id order by [start_date] desc)  
		  , last_name =  FIRST_VALUE(last_name)  over (partition by person_id order by [start_date] desc)  
		  , first_name =  FIRST_VALUE(first_name)  over (partition by person_id order by [start_date] desc)  
		  , patronymic =  FIRST_VALUE(patronymic)  over (partition by person_id order by [start_date] desc)  
		  , row_version_CMRClient = FIRST_VALUE(row_version_CMRClient) over (partition by person_id order by [start_date] desc)  
		 -- , fio = FIRST_VALUE(fio) over (partition by person_id order by [start_date] desc)  
		  from #strategy_datamart_CMR) t2
  on t2.person_id = t.person_id


  -- --проверка на дубли
  --select * from
  --(
  -- SELECT *
  -- , rn1 = row_number() over( partition by external_id order by [start_date] desc ) FROM #strategy_datamart_CMR
  -- )s
  -- where rn1 >1

  
  update #strategy_datamart_CMR
		set last_name  = 'СЕВОСТЬЯНОВА'
		,first_name = 'ИРИНА'
		,patronymic = 'ВИТАЛЬЕВНА'
	where vin='X7MCF41GP8A200816';
	
	

	update #strategy_datamart_CMR
		set last_name  = 'МУРАШОВА'
		,first_name = 'ЕКАТЕРИНА'
		,patronymic = 'АЛЕКСЕЕВНА'
	where vin='W0L0SDL68E4067214';

	update #strategy_datamart_CMR
		  set last_name  = 'КУРОЧКИНА'
			,first_name = 'ТАТЬЯНА'
			,patronymic = 'АЛЕКСЕЕВНА'
		  where vin='JMZKE197600113853'
	update #strategy_datamart_CMR
		  set last_name  = 'КУРОЧКИНА'
			,first_name = 'ТАТЬЯНА'
			,patronymic = 'АЛЕКСЕЕВНА'
		  where vin='JMZKE197600113853'
	--По согласованию с А. Ставничая и А.Кузнецов т.к клиент сменил фио
	update #strategy_datamart_CMR
		set last_name = 'ЩУРОВА'
	where   person_id=5236739649218366765

	--person_id = 5250702209421663589 Сменил ФИО Назарова ->РАЗОРЕНОВА 20.10 по договорености с Ставничей.
	update #strategy_datamart_CMR
		set last_name = 'РАЗОРЕНОВА'
		where person_id = 5250702209421663589
	
	--По договореностям с Полиной Прокопенко 17.03 Сменила ФИО 
	update	#strategy_datamart_CMR
		set last_name = 'НЕХОРОШЕВА'
	--	, FIO  = 'НЕХОРОШЕВА ЕЛЕНА ЕВГЕНЬЕВНА'
	where person_id =  4961375496307103640 
	--По договореностям с Полиной Прокопенко 07.04 Сменила ФИО 
	update	#strategy_datamart_CMR
		set last_name = 'ГЕРАСИМОВА'
	--	, FIO  = 'НЕХОРОШЕВА ЕЛЕНА ЕВГЕНЬЕВНА'
	where person_id =  5562840887529455354 
	--По договореностям с Полиной Прокопенко 16.04 Сменила ФИО 
	update	#strategy_datamart_CMR
		set last_name = 'ДЯТЛОВА'
	--	, FIO  = 'НЕХОРОШЕВА ЕЛЕНА ЕВГЕНЬЕВНА'
	where person_id =  5519289912718488675 


  --- собственно само обновление
  begin tran
  
  delete t from risk.strategy_datamart t
  where (exists(Select top(1) 1 from #ContractIds s where s.ContractId =  t.external_id)
		or @CMRClientGUIDs is null) 
  --drop table if exists   [LoginomDB].[dbo].[strategy_datamart_CMR]
  /*
	alter table risk.strategy_datamart
		add amount money
alter table risk.strategy_datamart
	 add overdue_days_cmr	smallint
	, overdue_days_max_cmr		  smallint
	, client_overdue_days_max_cmr smallint
alter table risk.strategy_datamart
 	add client_inn varchar(12)
alter table  risk.strategy_datamart
	add client_phone nvarchar(20)
alter table  risk.strategy_datamart
	add is_Sold bit

alter table risk.strategy_datamart
	add loan_term_in_days int 
alter table risk.strategy_datamart
	add last_paymentDay_byFirstPaymentSchedule date

	alter table risk.strategy_datamart
			add productSubType_Code nvarchar(255) 
	alter table risk.strategy_datamart
		add maxDpdOver30DaysL6M		 smallint
		,lastDateMaxDpdOver30DaysL6M date
		

  */
  insert into risk.strategy_datamart
  (
	
		[person_id] 
		,[fio] 
		,[birth_date] 
		,[passport_number] 
		,[passport_date] 
		,[vin] 
		,[brand] 
		,[model] 
		,[year] 
		,[market_price] 
		,[external_id] 
		,[is_active] 
		,[start_date] 
		,[end_date] 
		,[risk_criteria] 
		,[overdue_days] 
		,[overdue_days_max] 
		,[client_overdue_days_max] 
		,[total_rest] 
		,[total_rest_client] 
		,[lifetime_days] 
		,[product_type] 
		,[is_Claim] 
		,last_name
		,first_name
		,patronymic
		,CMRClientGUID
		,[created_at]
		,amount
		,row_version_CMRClient
		,uid218Fz --УникальныйИдентификаторОбъектаБКИ
		,averageMonthlyPayment --CреднемесячныйПлатеж
		,overdue_days_cmr
		,overdue_days_max_cmr
		,client_overdue_days_max_cmr
		,client_inn
		,client_phone
		,is_Sold
		,initial_end_date
		,productSubType_Code
		,maxDpdOver30DaysL6M		
		,lastDateMaxDpdOver30DaysL6M
  )
  select 
		[person_id], 
		[fio] = concat(last_name, ' ', first_name, ' ', patronymic),
		[birth_date], 
		[passport_number], 
		[passport_date], 
		[vin], 
		[brand], 
		[model], 
		[year], 
		[market_price], 
		[external_id], 
		[is_active], 
		[start_date], 
		[end_date], 
		[risk_criteria], 
		[overdue_days], 
		[overdue_days_max], 
		[client_overdue_days_max], 
		[total_rest], 
		[total_rest_client] = isnull([total_rest_client],0), 
		[lifetime_days], 
		[product_type], 
		[is_Claim], 
		last_name,
		first_name,
		patronymic,
		CMRClientGUID,
		created_at = GEtdate()
		,amount
		,Row_version_CMRClient
		,uid218Fz --УникальныйИдентификаторОбъектаБКИ
		,averageMonthlyPayment --CреднемесячныйПлатеж 
		,overdue_days_cmr
		,overdue_days_max_cmr
		,client_overdue_days_max_cmr
		,client_inn
		,client_phone
		,is_Sold
		,initial_end_date
		,productSubType_Code
		,maxDpdOver30DaysL6M		
		,lastDateMaxDpdOver30DaysL6M
  from #strategy_datamart_CMR
  commit tran


  

end try
begin catch
	SET @msg = CONCAT (
			'Ошибка выполнения процедуры - '
			,@sp_name
			,'. Ошибка '
			,ERROR_MESSAGE()
			)
	SET @subject = CONCAT (
			'Ошибка выполнение процедуры '
			,@sp_name
			)
	if @@TRANCOUNT<>0
		rollback tran;
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ala.kurikalov@smarthorizon.ru'
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;
	throw
end catch

end
